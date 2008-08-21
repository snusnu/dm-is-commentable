require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

if HAS_SQLITE3 || HAS_MYSQL || HAS_POSTGRES
  
  module ModelSetup
    
    def unload_commenting_infrastructure(remixer_name, user_model_name = nil)
      Object.send :remove_const, "#{remixer_name}Comment" if Object.const_defined? "#{remixer_name}Comment"
      Object.send :remove_const, "#{remixer_name}" if Object.const_defined? "#{remixer_name}"
      Object.send :remove_const, "#{user_model_name}" if Object.const_defined? "#{user_model_name}" if user_model_name
    end
    
  end
  
  describe DataMapper::Is::Commentable do
    
    include ModelSetup
    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
  
    describe "every commenting", :shared => true do

      it "should define a remixed model that can be auto_migrated" do
        # once it's migrated it stays in the database and can be used by the other specs
        Object.const_defined?("TripComment").should be_true
        lambda { TripComment.auto_migrate! }.should_not raise_error
      end

      it "should define a 'allow_togglable_commenting' class_level accessor on the remixing model" do
        Trip.respond_to?(:allow_togglable_commenting).should be_true
      end
      
      it "should define a 'commentable_fk' class_level reader on the remixing model" do
        Trip.respond_to?(:commentable_fk).should be_true
      end
       
      it "should use DataMapper foreign_key naming conventions for naming the 'commentable_fk' in the remixing model" do
        Trip.commentable_fk.should == :trip_id
      end
      
      
      it "should respond_to?(:comments)" do
        @t1.respond_to?(:comments).should be_true
      end
      
      it "should respond_to?(:commenting_enabled?)" do
        @t1.respond_to?(:comments_enabled?).should be_true
      end
      
      it "should store a collection of comments" do
        @t1.comments.should be_empty
      end

    end
    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
      
    describe "every togglable commenting", :shared => true do
      
      it "should return true when 'allow_toggleable_commenting' class_level reader is called" do
        Trip.allow_togglable_commenting.should be_true
      end
    
      it "should allow to disable and reenable commenting for itself (but not others)" do
        @t1.disable_comments
        @t1 = Trip.get(1)
        @t1.comments_enabled?.should == false
        @t1.enable_comments
        @t1 = Trip.get(1)
        @t1.comments_enabled?.should == true
      end
    
    end
    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
    
    describe "every non-togglable commenting", :shared => true do
      
      it "should return false when 'allow_togglable_commenting' class_level reader is called" do
        Trip.allow_togglable_commenting.should be_false
      end
    
      it "should raise 'DataMapper::Is::Commentable::TogglableCommentingDisabled' when 'disable_comments' is called" do
        lambda { @t1.disable_comments }.should raise_error(DataMapper::Is::Commentable::TogglableCommentingDisabled)
      end
          
      it "should raise 'DataMapper::Is::Commentable::TogglableCommentingDisabled' when 'enable_comments' is called" do
        lambda { @t1.enable_comments }.should raise_error(DataMapper::Is::Commentable::TogglableCommentingDisabled)
      end
    
    end
      
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------

    describe "every aliased commenting", :shared => true do
    
      it "should set the specified alias on the 'comments' reader" do
        @t1.respond_to?(:my_trip_comments).should be_true
      end
  
    end

    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
  
    describe "every enabled commenting", :shared => true do
      
      it "should have comments enabled" do
        @t1.comments_enabled?.should be_true
      end
      
    end
            
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
  
    describe "every disabled commenting", :shared => true do
      
      it "should have comments disabled" do
        @t1.comments_enabled?.should be_false
      end
      
    end
                    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
  
    describe "every anonymized commenting", :shared => true do
      
      it "should not respond_to?(:user_comments)" do
        @t1.respond_to?(:user_comments).should be_false
      end
      
      it "should keep track of timestamps" do
        if @t1.comments_enabled?
          @t1.comment("hey ho let's go")
          @t1.comments[0].should respond_to(:created_at)
          @t1.comments[0].should respond_to(:updated_at)
        end
      end
      
    end
        
                    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
  
    describe "every personalized commenting", :shared => true do
      
      it "should respond_to?(:user_comments)" do
        @t1.respond_to?(:user_comments).should be_true
      end
      
      it "should keep track of timestamps" do
        if @t1.comments_enabled?
          @t1.comment("hey ho let's go", @u1)
          @t1.comments[0].should respond_to(:created_at)
          @t1.comments[0].should respond_to(:updated_at)
        end
      end
      
    end
        
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
  
    describe "every enabled anonymized commenting", :shared => true do
    
      it_should_behave_like "every commenting"
      it_should_behave_like "every enabled commenting"
      it_should_behave_like "every anonymized commenting"
      
      it "should accept comment bodies of arbitrary length (at least 1 character)" do
        null_body = nil
        empty_body = ""
        short_body = "yes I think so too"
        long_body = <<-EOS
        Lorem ipsum dolor sit amet, consectetuer adipiscing elit. 
        Suspendisse facilisis eros ullamcorper urna placerat ultricies.
        Maecenas ligula justo, ornare quis, faucibus ut, rhoncus a, sapien. 
        Praesent mi. Quisque lorem. Duis lacus. Sed vel turpis a magna faucibus pharetra. 
        Fusce fermentum, est ac volutpat pretium, ligula tortor consectetuer dolor, 
        in volutpat urna lectus a quam. Nulla eget dui. Mauris mattis. 
        Nulla iaculis libero ac nisl. Mauris laoreet dolor vitae mauris. 
        Aliquam aliquam. Nulla congue sem a erat. 
        Suspendisse luctus metus ut nulla. Donec urna. 
        Nulla porttitor hendrerit nisl.

        Nullam eros pede, semper in, gravida at, suscipit id, nulla. 
        In quis turpis. Class aptent taciti sociosqu ad litora torquent per conubia nostra, 
        per inceptos himenaeos. Mauris vel lectus eu metus fermentum viverra. 
        Aenean a sem et mi posuere accumsan. Phasellus arcu risus, dictum eget, gravida eu, 
        vehicula at, velit. Praesent a risus. Nulla scelerisque commodo enim. Suspendisse potenti. 
        Morbi eget mi eu lorem dapibus semper. Curabitur tellus ligula, sollicitudin vitae, 
        porttitor pulvinar, lobortis eu, tellus. Nullam volutpat diam ut velit. 
        Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. 
        Integer arcu lorem, pulvinar quis, aliquet quis, consectetuer nec, sem. 
        Fusce lobortis. Cras at ante.

        Curabitur vitae nibh et tortor dictum accumsan. Nulla sagittis tempor eros. Maecenas libero. 
        Mauris lorem dolor, tristique in, interdum et, tincidunt ut, sem. In semper hendrerit tortor. 
        Nulla leo nibh, adipiscing quis, venenatis a, placerat tristique, elit. Suspendisse potenti. 
        Aliquam bibendum erat. Sed laoreet ante a quam. Maecenas ac libero non mauris iaculis mattis.

        Cras dignissim, erat ut feugiat consequat, felis velit euismod augue, 
        condimentum tincidunt magna ante at magna. Duis et diam sit amet quam facilisis dictum. 
        Donec nisi erat, porttitor quis, commodo sit amet, placerat in, mauris. 
        Nulla arcu. Etiam nunc tortor, tincidunt nec, tempor in, porta vel, ligula. 
        Praesent sagittis, leo ut laoreet consequat, ipsum purus adipiscing nisi, ut tristique urna 
        ligula eget magna. Nullam sem urna, porta vulputate, hendrerit vitae, interdum sed, neque. 
        Fusce pellentesque. Vestibulum ac felis eget purus varius rutrum. 
        Nulla vitae nisi iaculis lorem adipiscing aliquet. Donec velit. 
        Cras libero felis, dapibus vitae, consequat sit amet, sollicitudin in, sapien. 
        Sed luctus enim non lacus. Duis enim nisl, aliquet volutpat, molestie ut, tristique at, massa. 
        Donec quis magna eget neque lobortis aliquam. Donec volutpat cursus nunc.

        In mollis ante nec elit. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices 
        posuere cubilia Curae; Praesent mauris ligula, varius id, pulvinar ut, bibendum eu, urna. 
        Maecenas sapien. Mauris congue magna eu lectus. Proin sed odio. Vestibulum egestas pulvinar diam. 
        Maecenas sollicitudin tellus vitae magna. Donec aliquam erat eget tortor. 
        Nam elit urna, adipiscing vel, vestibulum quis, vehicula eu, ante. Sed sodales massa id magna. 
        Sed placerat ornare mauris.
        EOS
        
        lambda { @t1.comment(null_body) }.should raise_error(DataMapper::Is::Commentable::InvalidComment)
        lambda { @t1.comment(empty_body) }.should raise_error(DataMapper::Is::Commentable::InvalidComment)
        lambda { @t1.comment(short_body) }.should_not raise_error
        lambda { @t1.comment(long_body) }.should_not raise_error
      end
      
      it "should allow to access all comment_bodies for any commentable model" do
        @t1.comment_bodies.should be_empty
        @t1.comment("yes I think so too")
        TripComment.count.should == 1
        @t1.comment_bodies.include?("yes I think so too").should be_true
        @t1.comment("me too")
        TripComment.count.should == 2
        @t1.comment_bodies.include?("yes I think so too").should be_true
        @t1.comment_bodies.include?("me too").should be_true
      end
            
      it "should allow to pass conditions into the 'comment_bodies' reader" do
        @t1.comment("datamapper is cool")
        @t1.comment("activerecord is cool")
        @t1.comment_bodies(:body.like => "%datamapper%").length == 1
        @t1.comment_bodies(:body.like => "%datamapper%").include?("datamapper is cool").should be_true
      end
      
    end
    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
     
    describe "every disabled anonymized commenting", :shared => true do
    
      it_should_behave_like "every commenting"
      it_should_behave_like "every disabled commenting"
      it_should_behave_like "every anonymized commenting"
      
      it "should not allow any comments" do
        lambda { @t1.comment("yes") }.should raise_error(DataMapper::Is::Rateable::CommentingDisabled)
      end
    
    end
  
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
    
    describe "every enabled personalized commenting", :shared => true do
    
      it_should_behave_like "every commenting"
      it_should_behave_like "every enabled commenting"
      it_should_behave_like "every personalized commenting"
      
      it "should accept comment bodies of arbitrary length (at least 1 character)" do
        empty_body = ""
        short_body = "yes I think so too"
        long_body = <<-EOS
        Lorem ipsum dolor sit amet, consectetuer adipiscing elit. 
        Suspendisse facilisis eros ullamcorper urna placerat ultricies.
        Maecenas ligula justo, ornare quis, faucibus ut, rhoncus a, sapien. 
        Praesent mi. Quisque lorem. Duis lacus. Sed vel turpis a magna faucibus pharetra. 
        Fusce fermentum, est ac volutpat pretium, ligula tortor consectetuer dolor, 
        in volutpat urna lectus a quam. Nulla eget dui. Mauris mattis. 
        Nulla iaculis libero ac nisl. Mauris laoreet dolor vitae mauris. 
        Aliquam aliquam. Nulla congue sem a erat. 
        Suspendisse luctus metus ut nulla. Donec urna. 
        Nulla porttitor hendrerit nisl.

        Nullam eros pede, semper in, gravida at, suscipit id, nulla. 
        In quis turpis. Class aptent taciti sociosqu ad litora torquent per conubia nostra, 
        per inceptos himenaeos. Mauris vel lectus eu metus fermentum viverra. 
        Aenean a sem et mi posuere accumsan. Phasellus arcu risus, dictum eget, gravida eu, 
        vehicula at, velit. Praesent a risus. Nulla scelerisque commodo enim. Suspendisse potenti. 
        Morbi eget mi eu lorem dapibus semper. Curabitur tellus ligula, sollicitudin vitae, 
        porttitor pulvinar, lobortis eu, tellus. Nullam volutpat diam ut velit. 
        Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. 
        Integer arcu lorem, pulvinar quis, aliquet quis, consectetuer nec, sem. 
        Fusce lobortis. Cras at ante.

        Curabitur vitae nibh et tortor dictum accumsan. Nulla sagittis tempor eros. Maecenas libero. 
        Mauris lorem dolor, tristique in, interdum et, tincidunt ut, sem. In semper hendrerit tortor. 
        Nulla leo nibh, adipiscing quis, venenatis a, placerat tristique, elit. Suspendisse potenti. 
        Aliquam bibendum erat. Sed laoreet ante a quam. Maecenas ac libero non mauris iaculis mattis.

        Cras dignissim, erat ut feugiat consequat, felis velit euismod augue, 
        condimentum tincidunt magna ante at magna. Duis et diam sit amet quam facilisis dictum. 
        Donec nisi erat, porttitor quis, commodo sit amet, placerat in, mauris. 
        Nulla arcu. Etiam nunc tortor, tincidunt nec, tempor in, porta vel, ligula. 
        Praesent sagittis, leo ut laoreet consequat, ipsum purus adipiscing nisi, ut tristique urna 
        ligula eget magna. Nullam sem urna, porta vulputate, hendrerit vitae, interdum sed, neque. 
        Fusce pellentesque. Vestibulum ac felis eget purus varius rutrum. 
        Nulla vitae nisi iaculis lorem adipiscing aliquet. Donec velit. 
        Cras libero felis, dapibus vitae, consequat sit amet, sollicitudin in, sapien. 
        Sed luctus enim non lacus. Duis enim nisl, aliquet volutpat, molestie ut, tristique at, massa. 
        Donec quis magna eget neque lobortis aliquam. Donec volutpat cursus nunc.

        In mollis ante nec elit. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices 
        posuere cubilia Curae; Praesent mauris ligula, varius id, pulvinar ut, bibendum eu, urna. 
        Maecenas sapien. Mauris congue magna eu lectus. Proin sed odio. Vestibulum egestas pulvinar diam. 
        Maecenas sollicitudin tellus vitae magna. Donec aliquam erat eget tortor. 
        Nam elit urna, adipiscing vel, vestibulum quis, vehicula eu, ante. Sed sodales massa id magna. 
        Sed placerat ornare mauris.
        EOS
        
        lambda { @t1.comment(nil, @u1)        }.should raise_error(DataMapper::Is::Commentable::InvalidComment)
        lambda { @t1.comment(empty_body, @u1) }.should raise_error(DataMapper::Is::Commentable::InvalidComment)
        lambda { @t1.comment(short_body, @u1) }.should_not raise_error
        lambda { @t1.comment(long_body, @u1)  }.should_not raise_error
      end
    
      it "should allow to access any user's current remixed comment model instance" do
        @t1.user_comments(@u1).should be_empty
        @t1.user_comments(@u2).should be_empty
        @t1.comment("yes", @u1)
        @t1.user_comments(@u1).first.should == TripComment.get(1)
        @t1.user_comments(@u2).should be_empty
        @t1.comment("no", @u2)
        @t1.user_comments(@u1).first.should == TripComment.get(1)
        @t1.user_comments(@u2).first.should == TripComment.get(2)
      end
    
      it "should allow to access any user's current comment bodies" do
        @t1.user_comment_bodies(@u1).should be_empty
        @t1.user_comment_bodies(@u2).should be_empty
        @t1.comment("yes", @u1)
        @t1.user_comment_bodies(@u1).first.should == "yes"
        @t1.user_comment_bodies(@u2).should be_empty
        @t1.comment("no", @u2)
        @t1.user_comment_bodies(@u1)[0].should == "yes"
        @t1.user_comment_bodies(@u2)[0].should == "no"
      end
    
      it "should allow any user to comment multiple times" do
        @t1.comment("yes", @u1)
        @t1.comment("no", @u1)
        TripComment.count.should == 2
        @t1.comment("yes yes", @u2)
        @t1.comment("no no", @u2)
        TripComment.count.should == 4
      end
    
      it "should allow to pass conditions into the 'comment_bodies' reader" do
        @t1.comment("datamapper is cool", @u1)
        @t1.comment("activerecord is cool", @u2)

        @t1.comment_bodies(:body.like => "%datamapper%").length == 1
        @t1.comment_bodies(:body.like => "%datamapper%").include?("datamapper is cool").should be_true
      end
      
    end
    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
  
    describe "every disabled personalized commenting", :shared => true do
    
      it_should_behave_like "every commenting"
      it_should_behave_like "every disabled commenting"
      it_should_behave_like "every personalized commenting"
    
      it "should not allow any comments" do
        lambda { @t1.comment("yes", @u1) }.should raise_error(DataMapper::Is::Rateable::CommentingDisabled)
      end
    
    end
    
    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
    
    
    describe "Trip.is :commentable" do
    
      before do
      
        unload_commenting_infrastructure "Trip", "User"
        
        class User
          include DataMapper::Resource
          property :id, Serial
        end
      
        class Trip
          include DataMapper::Resource
          property :id, Serial
        
          # will define TripComment
          is :commentable
        end
        
        User.auto_migrate!
        Trip.auto_migrate!
        TripComment.auto_migrate!

        @u1 = User.create(:id => 1)
        @u2 = User.create(:id => 2)
        @t1 = Trip.create(:id => 1)
        @t2 = Trip.create(:id => 2)
      
      end
    
      it_should_behave_like "every enabled personalized commenting"
      it_should_behave_like "every togglable commenting"
    
    end

    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
        
    describe "Trip.is :commentable, :as => :my_trip_comments" do
    
      before do
      
        unload_commenting_infrastructure "Trip", "User"
        
        class User
          include DataMapper::Resource
          property :id, Serial
        end
      
        class Trip
          include DataMapper::Resource
          property :id, Serial
        
          # will define TripComment
          is :commentable, :as => :my_trip_comments
        end
        
        User.auto_migrate!
        Trip.auto_migrate!
        TripComment.auto_migrate!
    
        @u1 = User.create(:id => 1)
        @u2 = User.create(:id => 2)
        @t1 = Trip.create(:id => 1)
        @t2 = Trip.create(:id => 2)
      
      end
    
      it_should_behave_like "every enabled personalized commenting"
      it_should_behave_like "every togglable commenting"
      it_should_behave_like "every aliased commenting"
    
    end
    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
    
    describe "Trip.is :commentable, :allow_deactivation => false" do
    
      before do
      
        unload_commenting_infrastructure "Trip", "User"
        
        class User
          include DataMapper::Resource
          property :id, Serial
        end
      
        class Trip
          include DataMapper::Resource
          property :id, Serial
        
          # will define TripRating
          is :commentable, :allow_deactivation => false
        end
        
        User.auto_migrate!
        Trip.auto_migrate!
        TripComment.auto_migrate!
    
        repository do
          @u1 = User.create(:id => 1)
          @u2 = User.create(:id => 2)
          @t1 = Trip.create(:id => 1)
          @t2 = Trip.create(:id => 2)
        end
      
      end
    
      it_should_behave_like "every enabled personalized commenting"
      it_should_behave_like "every non-togglable commenting"
    
    end

    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
      
    describe "Trip.is :commentable, :anonymous => true" do
      
      before do
        
        unload_commenting_infrastructure "Trip"
      
        class Trip
          include DataMapper::Resource
          property :id, Serial
    
          # will define TripRating
          is :commentable, :anonymous => true
        end
        
        Trip.auto_migrate!
        TripComment.auto_migrate!
    
        repository do
          @t1 = Trip.create(:id => 1)
          @t2 = Trip.create(:id => 2)
        end
      
      end
      
      it_should_behave_like "every enabled anonymized commenting"
      it_should_behave_like "every togglable commenting"
      
    end
    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
      
    describe "Trip.is :rateable, :anonymous => true, :as => :my_trip_ratings" do
      
      before do
        
        unload_commenting_infrastructure "Trip"
      
        class Trip
          include DataMapper::Resource
          property :id, Serial
    
          # will define TripRating
          is :commentable, :anonymous => true, :as => :my_trip_comments
        end
        
        Trip.auto_migrate!
        TripComment.auto_migrate!
    
        repository do
          @t1 = Trip.create(:id => 1)
          @t2 = Trip.create(:id => 2)
        end
      
      end
      
      it_should_behave_like "every enabled anonymized commenting"
      it_should_behave_like "every togglable commenting"
      it_should_behave_like "every aliased commenting"
      
    end
  
  end
  
end
