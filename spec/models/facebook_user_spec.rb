require 'spec_helper'
require 'fb_graph'

describe StartupGiraffe::FacebookUser do
  before {
    @fb_app = FbGraph::Application.new( "582610595105782", :secret => "bb6671ae47cad793658d5a5816e6f43a" )
  }

  it "doesn't allow inclusion in non mongoid docs" do
    expect {
      NonUserDoc.send( :include, StartupGiraffe::FacebookUser )
    }.to raise_error
  end

  context "when registering" do
    before {
      @test_user = @fb_app.test_user!( :installed => true, :permissions => :email )
      @token = @test_user.access_token
    }

    after {
      @fb_app.test_users.collect(&:destroy)
    }

    describe "the user" do
      it "isn't saved" do
        User.register_via_facebook( @token ).should be_new_record
      end

      it "copies params passed in" do
        User.register_via_facebook( @token, { email: "hurk@shurk.com" } ).email.should == "hurk@shurk.com"
      end

      it "has facebook uid set to test user id" do
        User.register_via_facebook( @token ).facebook_uid.should ==  @test_user.identifier
      end

      it "doesn't allow mass assignment of facebook uid" do
        user = User.register_via_facebook( @token )
        user.save!
        expect {
          user.update_attributes( facebook_uid: 'raaaaaa' )
        }.not_to change { user.facebook_uid }
      end

      it "provides new user to a block" do
        block_user = nil
        returned_user = User.register_via_facebook( @token ) do |user|
          block_user = user
        end
        block_user.should == returned_user
      end

      it "provides facebook user name to the block" do
        User.register_via_facebook( @token ) do |user, name|
          name.match( /[^ ]+( [^ ]+)+/ ).should_not be_nil
        end
      end

      it "provides facebook email to the block" do
        User.register_via_facebook( @token ) do |user, name, email|
          email.index( "@" ).should_not be_nil
        end
      end

      context "if facebook user already registered" do
        before {
          @user = User.register_via_facebook( @token )
          @user.save!
        }

        it "is invalid" do
          User.register_via_facebook( @token ).should be_invalid
        end
      end
    end

  end

  it "allows facebook uid to be nil" do
    expect {
      User.create!( email: 'yurr@hurr.com' )
      User.create!( email: 'ra@ya.com' )
    }.to change { User.where( :facebook_uid => nil ).count }.from( 0 ).to 2
  end

  context "when authenticating" do
    before {
      @cookie = "v9bnGapRWTmAbgNsPZDt0aEtTwdIf4kuaqt5MRsC1Gk.eyJhbGdvcml0aG0iOiJITUFDLVNIQTI1NiIsImNvZGUiOiJBUUNDZVZ2N09pMDY4NTE1Z0lReGM0UGpmWHZBN3RFbXZ2VHJ4V3U5SHphMTFTSlVvUmV4TDVLUGdKQjJaM2JoemEtZkE2RHhjUTNvQ1FZeGNQek8zS1BlcHdrU1hiMmFucC1PcEh1ME9FTlVCUWQxenVXQzdQVHFkaDVCdGljZWM4X1o4X3Yzb1gtOGpVQVFuV3lHOVc5VG91bmF3czdTQkVrNkYtUU54akJVdzdDOXZrS2FOQk5TX3R3VmVwOFlacmNJZUczWjVoakhlQUhBazFjb1hKWnpqU1lpTTVoTDFxZ0ctZENCSlhtZC14NjdpYTlvNDhGcjRRbUlybUtYSW5OdVNreFBqWDYtWTRISV9XakczZ1FHRW9NeFpmRTM5NXJhTnBzLTNoc01EUDZwNjlDSFVrYWR3R2xnWTNtWWFPR05xN3RBeWVESnh4NEYwQXZDWWhnYSIsImlzc3VlZF9hdCI6MTM2OTI2ODMxNywidXNlcl9pZCI6IjEwMDAwMTQyMjQ2MDk2NiJ9"
    }
#   User.check_facebook_auth( )

    it "returns a user with UID 124721440918604" do
      expect {
        user = User.new( email: "murr@slurr.com" )
        user.facebook_uid = "124721440918604"
      }
      User.from_facebook_cookie( @cookie )
    end
  end
end