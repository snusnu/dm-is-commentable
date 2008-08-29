require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

if HAS_SQLITE3 || HAS_MYSQL || HAS_POSTGRES
  
  # constants for use in examples
  
  SHORT_COMMENT = "yes I think so too"
  
  LONG_COMMENT = <<-EOS
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
  
  module ModelSetup
    
    # clean model environments after each example run
    def unload_commenting_infrastructure(remixer_name, user_model_name = nil)
      Object.send :remove_const, "#{remixer_name}Comment" if Object.const_defined? "#{remixer_name}Comment"
      Object.send :remove_const, "#{remixer_name}CommentRating" if Object.const_defined? "#{remixer_name}CommentRating"
      Object.send :remove_const, "#{remixer_name}" if Object.const_defined? "#{remixer_name}"
      Object.send :remove_const, "#{user_model_name}" if Object.const_defined? "#{user_model_name}" if user_model_name
    end
    
  end
  
  describe DataMapper::Is::Commentable do
    
    include ModelSetup
    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
  
    describe "every commentable", :shared => true do

      it "should define a remixed model that can be auto_migrated" do
        # once it's migrated it stays in the database and can be used by the other specs
        Object.const_defined?("TripComment").should be_true
        lambda { TripComment.auto_migrate! }.should_not raise_error
      end
      
      
      it "should define a 'remixed_comment' class_level reader on the remixing model" do
        Trip.respond_to?(:remixed_comment).should be_true
        Trip.remixed_comment[:model].should == TripComment
      end
      
      it "should define a 'commenting_togglable?' class_level reader on the remixing model" do
        Trip.respond_to?(:commenting_togglable?).should be_true
      end
      
      it "should define a 'anonymous_commenting_togglable?' class_level reader on the remixing model" do
        Trip.respond_to?(:anonymous_commenting_togglable?).should be_true
      end
            
      it "should define a 'rateable_commenting_togglable?' class_level reader on the remixing model" do
        Trip.respond_to?(:rateable_commenting_togglable?).should be_true
      end


      it "should respond_to?(:valid_comment_body?)" do
        @t1.respond_to?(:valid_comment_body?).should be_true
      end
      
      it "should respond_to?(:valid_commenting_user?)" do
        @t1.respond_to?(:valid_commenting_user?).should be_true
      end
            
      
      it "should respond_to?(:comments)" do
        @t1.respond_to?(:comments).should be_true
      end
      
      it "should respond_to?(:user_comments)" do
        @t1.respond_to?(:user_comments).should be_true
      end
            
      it "should allow to pass conditions into the :user_comments method" do
        @t1.comment SHORT_COMMENT, @u1
        @t1.user_comments(@u1, :body.like => "%no%").should be_empty
        @t1.user_comments(@u1, :body.like => "%yes%").should_not be_empty
      end
      
      
      it "should respond_to?(:commenting_togglable?)" do
        @t1.respond_to?(:commenting_togglable?).should be_true
      end
      
      it "should respond_to?(:anonymous_commenting_togglable?)" do
        @t1.respond_to?(:anonymous_commenting_togglable?).should be_true
      end
            
      it "should respond_to?(:rateable_commenting_togglable?)" do
        @t1.respond_to?(:rateable_commenting_togglable?).should be_true
      end
      
      
      it "should respond_to?(:commenting_enabled?)" do
        @t1.respond_to?(:commenting_enabled?).should be_true
      end
      
      it "should respond_to?(:commenting_disabled?)" do
        @t1.respond_to?(:commenting_disabled?).should be_true
      end
      
                  
      it "should respond_to?(:anonymous_commenting_enabled?)" do
        @t1.respond_to?(:anonymous_commenting_enabled?).should be_true
      end
            
      it "should respond_to?(:anonymous_comments_disabled?)" do
        @t1.respond_to?(:anonymous_commenting_disabled?).should be_true
      end
      
      
      it "should store a collection of comments" do
        @t1.comments.should be_empty
      end
            
      it "should allow to pass conditions into the comments collection accessor" do
        lambda { @t1.comments :body.like => "%datamapper%" }.should_not raise_error
      end
      
      
      it "should keep track of timestamps" do
        if @t1.commenting_enabled?
          @t1.comment("hey ho let's go")
          @t1.comments[0].should respond_to(:created_at)
          @t1.comments[0].should respond_to(:updated_at)
        end
      end

    end
    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------

    describe "every commentable that has an alias on the comments association", :shared => true do

      it "should set the specified alias on the 'comments' reader" do
        @t1.respond_to?(:my_trip_comments).should be_true
        Trip.remixed_comment[:reader].should == :my_trip_comments
        Trip.remixed_comment[:writer].should == :my_trip_comments=
      end

    end
    
    describe "every commentable that has no alias on the comments association", :shared => true do

      it "should set the specified alias on the 'comments' reader" do
        @t1.respond_to?(:trip_comments).should be_true
        Trip.remixed_comment[:reader].should == :trip_comments
        Trip.remixed_comment[:writer].should == :trip_comments=
      end

    end
    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------

    describe "every commentable for which ratings can be (de)activated", :shared => true do

      it "should return true when 'rateable_commenting_togglable?' is called" do
        @t1.rateable_commenting_togglable?.should be_true
      end

    end

    describe "every commentable for which ratings can't be (de)activated", :shared => true do

      it "should return false when 'rateable_commenting_togglable?' is called" do
        @t1.rateable_commenting_togglable?.should be_false
      end

    end
    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
      
    describe "every commentable for which comments can be (de)activated", :shared => true do
      
      it "should return true when 'commenting_togglable?' class_level reader is called" do
        Trip.commenting_togglable?.should be_true
      end
    
      it "should allow to disable and reenable commenting" do
        @t1.disable_commenting
        @t1.commenting_disabled?.should == true
        @t1.commenting_enabled?.should == false
        lambda { @t1.comment(SHORT_COMMENT, @u1) }.should raise_error(DataMapper::Is::Commentable::CommentingDisabled)
        @t1.comments.size.should == 0
        
        @t1.enable_commenting
        @t1.commenting_enabled?.should == true
        @t1.commenting_disabled?.should == false
        lambda { @t1.comment(SHORT_COMMENT, @u1) }.should_not raise_error(DataMapper::Is::Commentable::CommentingDisabled)
        @t1.comments.size.should == 1
      end
    
    end
    
    describe "every commentable for which comments can't be (de)activated", :shared => true do
      
      it "should return false when 'commenting_togglable?' class_level reader is called" do
        Trip.commenting_togglable?.should be_false
      end
    
      it "should raise 'DataMapper::Is::Commentable::TogglableCommentingDisabled' when 'disable_comments' is called" do
        lambda { @t1.disable_commenting }.should raise_error(DataMapper::Is::Commentable::TogglableCommentingDisabled)
      end
          
      it "should raise 'DataMapper::Is::Commentable::TogglableCommentingDisabled' when 'enable_comments' is called" do
        lambda { @t1.enable_commenting }.should raise_error(DataMapper::Is::Commentable::TogglableCommentingDisabled)
      end
    
    end
     
                    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
  
    describe "every commentable for which anonymity can be (de)activated", :shared => true do
      
      it "should return true when 'anonymous_commenting_togglable?' is called" do
        @t1.anonymous_commenting_togglable?.should be_true
      end
      
      it "should allow to disable and reenable anonymous commenting" do
        @t1.disable_anonymous_commenting
        @t1.anonymous_commenting_disabled?.should == true
        @t1.anonymous_commenting_enabled?.should == false
        lambda { @t1.comment(SHORT_COMMENT) }.should raise_error(DataMapper::Is::Commentable::AnonymousCommentingDisabled)
        @t1.comments.size.should == 0
        
        @t1.enable_anonymous_commenting
        @t1.anonymous_commenting_enabled?.should == true
        @t1.anonymous_commenting_disabled?.should == false
        lambda { @t1.comment(SHORT_COMMENT) }.should_not raise_error(DataMapper::Is::Commentable::AnonymousCommentingDisabled)
        @t1.comments.size.should == 1
      end
      
    end
  
    describe "every commentable for which anonymity can't be (de)activated", :shared => true do
      
      it "should return false when 'anonymous_commenting_togglable?' is called" do
        @t1.anonymous_commenting_togglable?.should be_false
      end
      
      it "should not allow to disable and reenable anonymous commenting" do
        lambda { @t1.disable_anonymous_commenting }.should raise_error(DataMapper::Is::Commentable::TogglableAnonymousCommentingDisabled)
        lambda { @t1.enable_anonymous_commenting  }.should raise_error(DataMapper::Is::Commentable::TogglableAnonymousCommentingDisabled)
      end
      
    end

    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------

    describe "every commentable with comments enabled", :shared => true do

      it "should have comments enabled" do
        @t1.commenting_enabled?.should be_true
      end

    end

    describe "every commentable with comments disabled", :shared => true do

      it "should have comments disabled" do
        @t1.commenting_enabled?.should be_false
      end

    end
          
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
  
    describe "every commentable that allows anonymous comments", :shared => true do
      
      it "should allow anonymous comments with at least one character" do
        lambda { @t1.comment(nil) }.should raise_error(DataMapper::Is::Commentable::InvalidComment)
        lambda { @t1.comment('') }.should raise_error(DataMapper::Is::Commentable::InvalidComment)
        lambda { @t1.comment(SHORT_COMMENT) }.should_not raise_error
        lambda { @t1.comment(LONG_COMMENT) }.should_not raise_error
      end
      
      it "should allow multiple anonymous comments" do
        @t1.comment(SHORT_COMMENT)
        @t1.comment(SHORT_COMMENT)
        @t1.comments.size.should == 2
        @t1.comment(SHORT_COMMENT)
        @t1.comment(SHORT_COMMENT)
        @t1.comments.size.should == 4
      end
      
    end
    
    describe "every commentable that doesn't allow anonymous comments", :shared => true do
      
      it "should not allow anonymous comments" do
        lambda { @t1.comment(SHORT_COMMENT) }.should raise_error(DataMapper::Is::Rateable::CommentingDisabled)
      end
    
    end
  
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
    
    describe "every commentable that allows personalized comments", :shared => true do
      
      it "should allow personalized comments with at least one character" do
        lambda { @t1.comment(nil, @u1) }.should raise_error(DataMapper::Is::Commentable::InvalidComment)
        lambda { @t1.comment('', @u1) }.should raise_error(DataMapper::Is::Commentable::InvalidComment)
        lambda { @t1.comment(SHORT_COMMENT, @u1) }.should_not raise_error
        lambda { @t1.comment(LONG_COMMENT, @u1) }.should_not raise_error
      end
      
      it "should allow to filter comments by user" do
        @t1.user_comments(@u1).should be_empty
        @t1.user_comments(@u2).should be_empty
        @t1.comment(SHORT_COMMENT, @u1)
        @t1.user_comments(@u1).first.should == TripComment.get(1)
        @t1.user_comments(@u2).should be_empty
        @t1.comment(SHORT_COMMENT, @u2)
        @t1.user_comments(@u1).first.should == TripComment.get(1)
        @t1.user_comments(@u2).first.should == TripComment.get(2)
      end
      
      it "should allow any user to comment multiple times" do
        @t1.comment(SHORT_COMMENT, @u1)
        @t1.comment(SHORT_COMMENT, @u1)
        @t1.comments.size.should == 2
        @t1.comment(SHORT_COMMENT, @u2)
        @t1.comment(SHORT_COMMENT, @u2)
        @t1.comments.size.should == 4
      end
      
    end
    
    describe "every commentable that doesn't allow personalized comments", :shared => true do
      
      it "should not allow any comments" do
        lambda { 
          @t1.comment(SHORT_COMMENT, @u1) 
        }.should raise_error(DataMapper::Is::Rateable::CommentingDisabled)
      end
      
    end
        
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------

    describe "every commentable that allows comment ratings", :shared => true do

      it "should return true when 'rateable_commenting_enabled?' is called" do
        @t1.rateable_commenting_enabled?.should be_true
      end
      
      it "should return false when 'rateable_commenting_disabled?' is called" do
        @t1.rateable_commenting_disabled?.should be_false
      end

    end

    describe "every commentable that doesn't allow comment ratings", :shared => true do

      it "should return false when 'rateable_commenting_enabled?' is called" do
        @t1.rateable_commenting_enabled?.should be_false
      end
      
      it "should return true when 'rateable_commenting_disabled?' is called" do
        @t1.rateable_commenting_disabled?.should be_true
      end

    end
    
    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
    
    
    describe "Trip.is(:commentable) without additional properties" do
    
      before do
      
        unload_commenting_infrastructure "Trip", "User"
        
        class User
          include DataMapper::Resource
          property :id, Serial
        end
      
        class Trip
          include DataMapper::Resource
          
          property :id, Serial
          
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
    
      it_should_behave_like "every commentable"
      it_should_behave_like "every commentable with comments enabled"
      it_should_behave_like "every commentable for which comments can't be (de)activated"
      it_should_behave_like "every commentable for which anonymity can't be (de)activated"
      it_should_behave_like "every commentable for which ratings can't be (de)activated"
      it_should_behave_like "every commentable that allows anonymous comments"
      it_should_behave_like "every commentable that allows personalized comments"
      it_should_behave_like "every commentable that doesn't allow comment ratings"
      it_should_behave_like "every commentable that has no alias on the comments association"
    
    end

    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
        
    describe "Trip.is(:commentable, :as => :my_trip_comments) without additional properties" do
    
      before do
      
        unload_commenting_infrastructure "Trip", "User"
        
        class User
          include DataMapper::Resource
          property :id, Serial
        end
      
        class Trip
          include DataMapper::Resource
          
          property :id, Serial
          
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
    
      it_should_behave_like "every commentable"
      it_should_behave_like "every commentable with comments enabled"
      it_should_behave_like "every commentable for which comments can't be (de)activated"
      it_should_behave_like "every commentable for which anonymity can't be (de)activated"
      it_should_behave_like "every commentable for which ratings can't be (de)activated"
      it_should_behave_like "every commentable that allows anonymous comments"
      it_should_behave_like "every commentable that allows personalized comments"
      it_should_behave_like "every commentable that doesn't allow comment ratings"
      it_should_behave_like "every commentable that has an alias on the comments association"
    
    end
    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
      
    describe "Trip.is(:commentable) with properties :comments_enabled, :anonymous_comments_enabled, :comment_ratings_enabled" do
      
      before do
        
        unload_commenting_infrastructure "Trip", "User"
        
        class User
          include DataMapper::Resource
          property :id, Serial
        end
      
        class Trip
          include DataMapper::Resource
          
          property :id, Serial
          property :commenting_enabled,           Boolean, :nullable => false, :default => true
          property :anonymous_commenting_enabled, Boolean, :nullable => false, :default => true
          property :rateable_commenting_enabled,  Boolean, :nullable => false, :default => true
          
          is :commentable
        end
        
        User.auto_migrate!
        Trip.auto_migrate!
        TripComment.auto_migrate!
        TripCommentRating.auto_migrate!
    
        repository do
          @u1 = User.create(:id => 1)
          @u2 = User.create(:id => 2)
          @t1 = Trip.create(:id => 1)
          @t2 = Trip.create(:id => 2)
        end
      
      end
      
      it_should_behave_like "every commentable"
      it_should_behave_like "every commentable with comments enabled"
      it_should_behave_like "every commentable for which comments can be (de)activated"
      it_should_behave_like "every commentable for which anonymity can be (de)activated"
      it_should_behave_like "every commentable for which ratings can be (de)activated"
      it_should_behave_like "every commentable that allows anonymous comments"
      it_should_behave_like "every commentable that allows personalized comments"
      it_should_behave_like "every commentable that allows comment ratings"
      it_should_behave_like "every commentable that has no alias on the comments association"
      
    end
  
  end
  
end
