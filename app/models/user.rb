class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, :confirmable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :confirmed_at
  # attr_accessible :title, :body
  has_many :identities, dependent: :destroy

  has_many :user_project_memberships
  has_many :projects, through: :user_project_memberships

  def self.by_email(email)
    User.find_or_create_by_email! email
  end
end
