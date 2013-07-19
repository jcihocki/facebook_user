require 'mongoid'
require_relative 'facebook_user/cookie'

module StartupGiraffe
  module FacebookUser
    def self.included base
      #raise StandardError, "Our facebook user module only works with mongoid at the moment" unless base.is_a? Mongoid::Document

      base.field :facebook_uid, type: String
      base.attr_protected :facebook_uid
      base.scope :by_facebook_uid, ->( uid ) { base.where( facebook_uid: uid ) }
      base.validates_uniqueness_of :facebook_uid, :unless => ->() { self.facebook_uid.nil? }

      base.index( { facebook_uid: 1 }, { sparse: true, unique: true} )
      
      class << base
        attr_accessor :cookie_cache_attrs
      end
      base.cookie_cache_attrs = []
      
      base.extend ClassMethods
    end

    module ClassMethods
      def register_via_facebook token, params = {}, &block
        user = FbGraph::User.me( token ).fetch
        new_user =  self.new( params )
        new_user.facebook_uid = user.identifier
        if block_given?
          block.call new_user, user.name, user.email, user.picture
        end
        return new_user
      end

      def from_facebook_cookie client, cookie
        begin
          cookie_parts = FbGraph::Auth::Cookie.parse( client, cookie )
          if cookie_parts['user_id']
            return self.by_facebook_uid( cookie_parts['user_id'] ).first
          end
        rescue FbGraph::Auth::VerificationFailed
          # This is reasonable, user not authed.
        end
        return nil
      end
      
      def logged_in_user client, request
        if request && request.cookies && request.cookies[facebook_cookie_name]
          user = from_facebook_cookie client, request.cookies[facebook_cookie_name]
          set_facebook_cookie_cache request if user
          request[:logged_in_user] ||= user
        end
      end
      
      def cookie_cache request
        cookie = facebook_cookie( request )
        if request && request.cookies && cookie
          if cookie.cache
            cookie.cache
          else
            cookie = set_facebook_cookie_cache request
            cookie.cache
          end
        end
      end
      
      def set_facebook_cookie_cache request
        user = from_facebook_cookie( FbGraph::Auth.new( ENV['FACEBOOK_APP_ID'], ENV['FACEBOOK_SECRET'] ).client, request.cookies[facebook_cookie_name] )
        if request && request.cookies && user
          new_cookie = facebook_cookie request
          new_cookie.add_to_cache self.cookie_cache_attrs.each_with_object({}) { |attr, hash| hash[attr] = user.public_send( attr ).to_s }
          request.cookies[facebook_cookie_name] = new_cookie.to_s
          return new_cookie
        end
      end
      
      def facebook_cookie( request )
        return Cookie.new request.cookies[facebook_cookie_name], ENV['FACEBOOK_SECRET'] if request.cookies[facebook_cookie_name]
        nil
      end
      
      def facebook_cookie_name
        "fbsr_#{ENV['FACEBOOK_APP_ID']}"
      end
      
      def cache_in_cookie *args
        args.each do |arg|
          self.cookie_cache_attrs << arg
        end
      end
    end
  end
end