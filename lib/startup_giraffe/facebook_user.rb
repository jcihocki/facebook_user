require 'mongoid'

module StartupGiraffe
  module FacebookUser
    def self.included base
      #raise StandardError, "Our facebook user module only works with mongoid at the moment" unless base.is_a? Mongoid::Document

      base.field :facebook_uid, type: String
      base.attr_protected :facebook_uid
      base.scope :by_facebook_uid, ->( uid ) { where( facebook_uid: uid ) }
      base.validates_uniqueness_of :facebook_uid, :unless => ->() { self.facebook_uid.nil? }

      base.index( { facebook_uid: 1 }, { sparse: true, unique: true} )
      base.extend ClassMethods
    end

    module ClassMethods
      def register_via_facebook token, params = {}, &block
        user = FbGraph::User.me( token ).fetch
        new_user =  self.new( params )
        new_user.facebook_uid = user.identifier
        if block_given?
          block.call new_user, user.name, user.email
        end
        return new_user
      end
    end
  end
end