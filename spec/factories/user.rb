class NonUserDoc ; end

class User
  include Mongoid::Document
  include StartupGiraffe::FacebookUser

  field :email, type: String
end

FactoryGirl.define do
  factory :facebook_test_user do

  end
end

class FudgedController
  attr_accessor :request

  def initialize
    @request = FudgedRequest.new
  end
  
  def cookies
    @request.cookies
  end
  
end

class FudgedRequest < Hash
  attr_accessor :cookies
  
  def initialize
    @cookies = {}
  end
  
end