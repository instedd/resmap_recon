# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Project.find_or_initialize_by_name('Bcardiff Test 1').tap do |p|
  p.master_collection_id = 927
  p.source_collection_ids = [928, 929]
  p.save!
end
