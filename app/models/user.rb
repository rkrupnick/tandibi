# == Schema Information
#
# Table name: users
#
#  id         :bigint           not null, primary key
#  email      :string           not null
#  first_name :string           not null
#  is_public  :boolean          default(TRUE), not null
#  last_name  :string
#  username   :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_users_on_email     (email) UNIQUE
#  index_users_on_username  (username) UNIQUE
#
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         authentication_keys: [:login]
    
    attr_writer :login
    validates_uniqueness_of :email

    has_many :posts

    validates :email, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :username, uniqueness: true
    validates :first_name, presence: true

    has_many :bonds
    has_many :followings,
        -> { Bond.following },
        through: :bonds,
        source: :friend
    has_many :follow_requests,
        -> { Bond.requesting },
        through: :bonds,
        source: :friend
    has_many :inward_bonds,
        class_name: "Bond",
        foreign_key: :friend_id
    has_many :followers,
        -> { where("bonds.state = ?", Bond::FOLLOWING ) },
        through: :inward_bonds,
        source: :user

    def self.find_authenticatable(login)
        where("username = :value OR email = :value", value: login).first
    end

    def self.find_for_database_authentication(conditions)
        conditions = conditions.dup
        login = conditions.delete(:login).downcase
        find_authenticatable(login)
    end

    def login
        @login || username || email
    end

    before_save :ensure_proper_name_case
    private
        def ensure_proper_name_case
            self.first_name = first_name.capitalize

        end
end
