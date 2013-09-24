# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Project.find_or_initialize_by_name('Bcardiff Test 1').tap do |p|
  p.master_collection_id = 927
  p.master_collection_target_field_id = 3417 # cat

  p.source_lists.find_or_initialize_by_collection_id(928).tap do |source|
    source.mapping_property_id = 3422 # kind
    source.save!
  end

  p.source_lists.find_or_initialize_by_collection_id(929).tap do |source|
    source.mapping_property_id = 3423 # type
    source.save!
  end

  p.save!
end
