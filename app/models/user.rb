class User < ApplicationRecord
  has_many :memberships
  has_many :teams, through: :memberships

  has_secure_password

  validates :email, uniqueness: true
  validates :email, presence: true
end
