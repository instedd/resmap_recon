class User < ActiveRecord::Base
  attr_accessible :email

  has_many :user_project_memberships
  has_many :projects, through: :user_project_memberships
end
