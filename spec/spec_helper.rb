$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "rspec"
require "startup_giraffe/facebook_user"
require "factory_girl"
require "fb_graph"

# Set the database that the spec suite connects to.
Mongoid.configure do |config|
  config.connect_to("facebook_user_test", consistency: :strong)
end

FactoryGirl.definition_file_paths << File.expand_path("../factories", __FILE__)
FactoryGirl.find_definitions

RSpec.configure do |config|
  config.order = "random"
  
  # Drop all collections and clear the identity map before each spec.
  config.before(:each) do
    Mongoid.purge!
    Mongoid::IdentityMap.clear
  end
end


ENV['FACEBOOK_APP_ID'] ||= "582610595105782"
ENV['FACEBOOK_SECRET'] ||= "bb6671ae47cad793658d5a5816e6f43a"
$fb_app = FbGraph::Application.new( ENV['FACEBOOK_APP_ID'], :secret => ENV['FACEBOOK_SECRET'] )
$fb_auth = FbGraph::Auth.new( ENV['FACEBOOK_APP_ID'], ENV['FACEBOOK_SECRET'] )

