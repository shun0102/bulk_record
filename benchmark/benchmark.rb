here = File.dirname(__FILE__)
$LOAD_PATH << File.expand_path(File.join(here, '../lib'))
require 'bulk_record'
require 'yaml'
require 'benchmark'
require 'active_record'

dbconfig = YAML::load_file('database.yml')
ActiveRecord::Base.configurations = dbconfig
ActiveRecord::Base.establish_connection "development"

ActiveRecord::Schema.define do
  create_table :counts, :options=>'ENGINE=InnoDb', :force=>true, :id => false do |t|
    t.column :name, :string, :null=>false
    t.column :count, :integer, :null => false, :default => 0
    t.column :count2, :integer, :null => false, :default => 0
  end

  execute("ALTER TABLE `counts` ADD PRIMARY KEY(`name`)")
end

BulkRecord::Base.configurations = dbconfig
BulkRecord::Base.establish_connection('development')

class Count < BulkRecord::Base
end

count = Count.new(:fix_columns => [:name])
row = { :name => 'test', :count => 1}

number = 10
start_time = Time.now
Benchmark.bm do |x|
  x.report("import") {
    count.add({ :name => 'test', :count2 => nil})
    number.times.each do |i|
      count.add(row)
    end
    count.add({ :name => 'test', :count2 => nil})
    count.import(:on_duplicate_key_update => true)
  }
end

puts "#{number / (Time.now - start_time)} req / sec"

ActiveRecord::Schema.define do
  drop_table :counts
end
