require 'machinist/active_record'
require 'sham'
require 'faker'

Sham.define do
  name { Faker::Name.name }
  email { Faker::Internet.email }
  password { Faker::Name.name }
  username { Faker::Internet.user_name }
end

Project.blueprint do
  name
end

SourceList.blueprint do
  project
end

SiteMapping.blueprint do
  source_list
  name
end
