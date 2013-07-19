require 'spec_helper'

describe StartupGiraffe::FacebookUser do
  before {
    @fb_app = $fb_app
    User.create_indexes
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

      it "provides profile picture to the block" do
        User.register_via_facebook( @token ) do |user, name, email, profile_pic|
          profile_pic.index( "https" ).should_not be_nil
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
    }.to change { User.count }.from( 0 ).to 2
  end

  context "when checking authorization" do
    before {
      @fb_auth = $fb_auth
      @cookie = "v9bnGapRWTmAbgNsPZDt0aEtTwdIf4kuaqt5MRsC1Gk.eyJhbGdvcml0aG0iOiJITUFDLVNIQTI1NiIsImNvZGUiOiJBUUNDZVZ2N09pMDY4NTE1Z0lReGM0UGpmWHZBN3RFbXZ2VHJ4V3U5SHphMTFTSlVvUmV4TDVLUGdKQjJaM2JoemEtZkE2RHhjUTNvQ1FZeGNQek8zS1BlcHdrU1hiMmFucC1PcEh1ME9FTlVCUWQxenVXQzdQVHFkaDVCdGljZWM4X1o4X3Yzb1gtOGpVQVFuV3lHOVc5VG91bmF3czdTQkVrNkYtUU54akJVdzdDOXZrS2FOQk5TX3R3VmVwOFlacmNJZUczWjVoakhlQUhBazFjb1hKWnpqU1lpTTVoTDFxZ0ctZENCSlhtZC14NjdpYTlvNDhGcjRRbUlybUtYSW5OdVNreFBqWDYtWTRISV9XakczZ1FHRW9NeFpmRTM5NXJhTnBzLTNoc01EUDZwNjlDSFVrYWR3R2xnWTNtWWFPR05xN3RBeWVESnh4NEYwQXZDWWhnYSIsImlzc3VlZF9hdCI6MTM2OTI2ODMxNywidXNlcl9pZCI6IjEwMDAwMTQyMjQ2MDk2NiJ9"
    }

    context "if cookie not present" do
      it "returns nil" do
        User.from_facebook_cookie( @fb_auth.client, {} ).should be_nil
      end
    end

    context "if cookie malformed" do
      it "returns nil" do
        User.from_facebook_cookie( @fb_auth.client, "JEAH!" ).should be_nil
      end
    end

    it "returns a user with UID 100001422460966" do
      expect {
        user = User.new( email: "murr@slurr.com" )
        user.facebook_uid = "100001422460966"
        user.save!
      }.to change { User.from_facebook_cookie( @fb_auth.client, @cookie ).try( :facebook_uid ) }.from( nil ).to( "100001422460966" )
    end
    
    context "if the cookie has extra data cached in it" do
      
      before {
        @ctlr = FudgedController.new
        @ctlr.cookies["fbsr_#{ENV['FACEBOOK_APP_ID']}"] = "v9bnGapRWTmAbgNsPZDt0aEtTwdIf4kuaqt5MRsC1Gk.eyJhbGdvcml0aG0iOiJITUFDLVNIQTI1NiIsImNvZGUiOiJBUUNDZVZ2N09pMDY4NTE1Z0lReGM0UGpmWHZBN3RFbXZ2VHJ4V3U5SHphMTFTSlVvUmV4TDVLUGdKQjJaM2JoemEtZkE2RHhjUTNvQ1FZeGNQek8zS1BlcHdrU1hiMmFucC1PcEh1ME9FTlVCUWQxenVXQzdQVHFkaDVCdGljZWM4X1o4X3Yzb1gtOGpVQVFuV3lHOVc5VG91bmF3czdTQkVrNkYtUU54akJVdzdDOXZrS2FOQk5TX3R3VmVwOFlacmNJZUczWjVoakhlQUhBazFjb1hKWnpqU1lpTTVoTDFxZ0ctZENCSlhtZC14NjdpYTlvNDhGcjRRbUlybUtYSW5OdVNreFBqWDYtWTRISV9XakczZ1FHRW9NeFpmRTM5NXJhTnBzLTNoc01EUDZwNjlDSFVrYWR3R2xnWTNtWWFPR05xN3RBeWVESnh4NEYwQXZDWWhnYSIsImlzc3VlZF9hdCI6MTM2OTI2ODMxNywidXNlcl9pZCI6IjEwMDAwMTQyMjQ2MDk2NiJ9"
        @user = User.new( email: "murr@slurr.com" )
        @user.facebook_uid = "100001422460966"
        @user.save!
        User.cache_in_cookie :id
        User.logged_in_user( @fb_auth.client, @ctlr.request ) # sets the cookie cache
      }
      
      after {
        User.cookie_cache_attrs = []
      }
      
      it "still returns the user" do
        User.from_facebook_cookie( @fb_auth.client, @ctlr.cookies["fbsr_#{ENV['FACEBOOK_APP_ID']}"] ).should == @user
      end
      
    end
    
    describe "logged_in_user" do
      
      before {
        @ctlr = FudgedController.new
      }
      
      context "if theres no fb_cookie" do
        
        it "is nil" do
          User.logged_in_user( @fb_auth.client, @ctlr.request ).should be_nil
        end
        
      end
      
      context "if there is a fb cookie" do
        
        before {
          @ctlr.cookies["fbsr_#{ENV['FACEBOOK_APP_ID']}"] = "v9bnGapRWTmAbgNsPZDt0aEtTwdIf4kuaqt5MRsC1Gk.eyJhbGdvcml0aG0iOiJITUFDLVNIQTI1NiIsImNvZGUiOiJBUUNDZVZ2N09pMDY4NTE1Z0lReGM0UGpmWHZBN3RFbXZ2VHJ4V3U5SHphMTFTSlVvUmV4TDVLUGdKQjJaM2JoemEtZkE2RHhjUTNvQ1FZeGNQek8zS1BlcHdrU1hiMmFucC1PcEh1ME9FTlVCUWQxenVXQzdQVHFkaDVCdGljZWM4X1o4X3Yzb1gtOGpVQVFuV3lHOVc5VG91bmF3czdTQkVrNkYtUU54akJVdzdDOXZrS2FOQk5TX3R3VmVwOFlacmNJZUczWjVoakhlQUhBazFjb1hKWnpqU1lpTTVoTDFxZ0ctZENCSlhtZC14NjdpYTlvNDhGcjRRbUlybUtYSW5OdVNreFBqWDYtWTRISV9XakczZ1FHRW9NeFpmRTM5NXJhTnBzLTNoc01EUDZwNjlDSFVrYWR3R2xnWTNtWWFPR05xN3RBeWVESnh4NEYwQXZDWWhnYSIsImlzc3VlZF9hdCI6MTM2OTI2ODMxNywidXNlcl9pZCI6IjEwMDAwMTQyMjQ2MDk2NiJ9"
          @user = User.new( email: "murr@slurr.com" )
          @user.facebook_uid = "100001422460966"
          @user.save!
        }
        
        it "returns a user associated with that cookie" do
          User.logged_in_user( @fb_auth.client, @ctlr.request ).should == @user
        end
        
      end
      
    end
    
  end

  describe "cookie_cache" do
    
    before {
      @ctlr = FudgedController.new
    }
    
    context "if the fb cookie is nil" do
      
      it "is nil" do
        User.cookie_cache( @ctlr.request ).should be_nil
      end
      
    end
    
    context "if the fb cookie is not nil" do
      
      before {
        @ctlr.cookies["fbsr_#{ENV['FACEBOOK_APP_ID']}"] = "v9bnGapRWTmAbgNsPZDt0aEtTwdIf4kuaqt5MRsC1Gk.eyJhbGdvcml0aG0iOiJITUFDLVNIQTI1NiIsImNvZGUiOiJBUUNDZVZ2N09pMDY4NTE1Z0lReGM0UGpmWHZBN3RFbXZ2VHJ4V3U5SHphMTFTSlVvUmV4TDVLUGdKQjJaM2JoemEtZkE2RHhjUTNvQ1FZeGNQek8zS1BlcHdrU1hiMmFucC1PcEh1ME9FTlVCUWQxenVXQzdQVHFkaDVCdGljZWM4X1o4X3Yzb1gtOGpVQVFuV3lHOVc5VG91bmF3czdTQkVrNkYtUU54akJVdzdDOXZrS2FOQk5TX3R3VmVwOFlacmNJZUczWjVoakhlQUhBazFjb1hKWnpqU1lpTTVoTDFxZ0ctZENCSlhtZC14NjdpYTlvNDhGcjRRbUlybUtYSW5OdVNreFBqWDYtWTRISV9XakczZ1FHRW9NeFpmRTM5NXJhTnBzLTNoc01EUDZwNjlDSFVrYWR3R2xnWTNtWWFPR05xN3RBeWVESnh4NEYwQXZDWWhnYSIsImlzc3VlZF9hdCI6MTM2OTI2ODMxNywidXNlcl9pZCI6IjEwMDAwMTQyMjQ2MDk2NiJ9"
        @user = User.new( email: "murr@slurr.com" )
        @user.facebook_uid = "100001422460966"
        @user.save!
      }
      
      it "is a hash containing the cached attributes" do
        User.cookie_cache( @ctlr.request ).should == {}
      end
      
      context "if attributes are added to cache_in_cookie" do
        
        before {
          User.cache_in_cookie :id
        }
        
        after {
          User.cookie_cache_attrs = []
        }
        
        it "returns all the attributes added to the cache" do
          User.cookie_cache( @ctlr.request )[:id].should == @user.id.to_s
        end
        
      end
      
    end
    
  end

end