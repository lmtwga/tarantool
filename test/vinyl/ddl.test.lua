-- space secondary index create
space = box.schema.space.create('test', { engine = 'vinyl' })
index1 = space:create_index('primary')
index2 = space:create_index('secondary')
space:drop()

-- space index create hash
space = box.schema.space.create('test', { engine = 'vinyl' })
index = space:create_index('primary', {type = 'hash'})
space:drop()

-- ensure alter is not supported
space = box.schema.space.create('test', { engine = 'vinyl' })
index = space:create_index('primary')
index:alter({parts={1,'unsigned'}})
space:drop()

-- new indexes on not empty space are unsupported
space = box.schema.space.create('test', { engine = 'vinyl' })
index = space:create_index('primary')
space:insert({1})
-- fail because of wrong tuple format {1}, but need {1, ...}
index2 = space:create_index('secondary', { parts = {2, 'unsigned'} })
#box.space._index:select({space.id})
space:drop()

space = box.schema.space.create('test', { engine = 'vinyl' })
index = space:create_index('primary')
space:insert({1, 2})
index2 = space:create_index('secondary', { parts = {2, 'unsigned'} })
#box.space._index:select({space.id})
space:drop()

space = box.schema.space.create('test', { engine = 'vinyl' })
index = space:create_index('primary')
space:insert({1, 2})
index2 = space:create_index('secondary', { parts = {2, 'unsigned'} })
#box.space._index:select({space.id})
space:delete({1})
--
-- Must fail because there are statements in vy_mems.
--
index2 = space:create_index('secondary', { parts = {2, 'unsigned'} })
box.snapshot()
--
-- After a dump REPLACE + DELETE = nothing, so the space is
-- naturaly empty now and can be altered.
--
index2 = space:create_index('secondary', { parts = {2, 'unsigned'} })
#box.space._index:select({space.id})
space:insert({1, 2})
index:select{}
index2:select{}
space:drop()

space = box.schema.space.create('test', { engine = 'vinyl' })
index = space:create_index('primary', { run_count_per_level = 2 })
space:insert({1, 2})
box.snapshot()
space:delete({1})
box.snapshot()
--
-- Must fail because there are statements on disk.
--
index2 = space:create_index('secondary', { parts = {2, 'unsigned'} })
--
-- Make compaction. During compaction the
-- REPLACE + DELETE + DELETE = nothing, so the space can be
-- altered.
--
space:delete({1})
box.snapshot()
index2 = space:create_index('secondary', { parts = {2, 'unsigned'} })

box.begin()
space:replace({1, 2, 3})
index3 = space:create_index('third', { parts = {3, 'unsigned'} })
box.commit()

space:drop()

--
-- gh-1632: index:bsize()
--
space = box.schema.space.create('test', { engine = 'vinyl' })
pk = space:create_index('primary', { type = 'tree', parts = {1, 'unsigned'}  })
for i=1,10 do box.space.test:replace({i}) end
box.space.test.index.primary:bsize() > 0

box.snapshot()

box.space.test.index.primary:bsize() == 0

space:drop()

--
-- gh-1709: need error on altering space
--
space = box.schema.space.create('test', {engine='vinyl'})
pk = space:create_index('pk', {parts = {1, 'unsigned'}})
space:auto_increment{1}
space:auto_increment{2}
space:auto_increment{3}
box.space._index:replace{space.id, 0, 'pk', 'tree', {unique=true}, {{0, 'unsigned'}, {1, 'unsigned'}}}
space:select{}
space:drop()
