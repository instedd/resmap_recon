class User < ActiveRecord::Base
  attr_accessible :email

  has_many :user_project_memberships
  has_many :projects, through: :user_project_memberships

  def self.by_email(email)
    User.find_or_create_by_email! email
  end
end
