class NonUserDoc ; end

class User
  include Mongoid::Document
  include StartupGiraffe::FacebookUser

  field :email, type: String
end

User.create_indexes

FactoryGirl.define do
  factory :facebook_test_user do

  end
end


