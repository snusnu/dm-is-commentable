module DataMapper
  module Is
    module Commentable
      
      class DmIsCommentableException < Exception; end
      
      class InvalidComment < DmIsCommentableException; end
      class CommentingDisabled < DmIsCommentableException; end
      class AnonymousCommentingDisabled < DmIsCommentableException; end
      class TogglableCommentingDisabled < DmIsCommentableException; end
      class TogglableAnonymousCommentingDisabled < DmIsCommentableException; end
      
      module Comment

        include DataMapper::Resource

        is :remixable

        property :id,         Serial
        property :created_at, DateTime
        property :updated_at, DateTime
        
      end
      
      
      # Options for generated remixable:
      #
      # Use :name and :type to name the fk property and give it a type.
      # Pass all other options on to the 'property' call.
      # 
      # :commenter => { :name => :user_id, :type => Integer }, 
      #
      # Use :type to change the type of the comment body property.
      # Pass all other options on to the 'property' call.
      # 
      # :body      => { :type => Text },
      #
      # Set this to true to make all comments rateable (but not togglable)
      # If 'property :rateable_commenting_enabled' is defined on this model,
      # it will take precedence over the option defined here.
      # Alternatively, you can also pass all options supported by dm-is-rateable.
      # 
      # :rateable  => false,
      #
      # Options for remixer:
      #
      # Set the specified alias (Symbol) on the 'comments' association
      #
      # :as        => nil
      def is_commentable(options = {})
        
        extend  ClassMethods
        include InstanceMethods
        
        options = {
          :commenter  => { :name => :user_id, :type => Integer },
          :body       => { :type => DataMapper::Types::Text, :required => true },
          :rateable   => false,
          :as         => nil,
          :model => "#{self}Comment"
        }.merge(options)
        
        # allow non togglable ratings
        @comments_rateable = options[:rateable]
        
        class_attribute :commentable_class_name
        commentable_class_name = options[:model]
        
        class_attribute :commentable_key
        commentable_key = commentable_class_name.underscore.to_sym
        
        remix n, Comment, :as => options[:as], :model => commentable_class_name
        
        class_attribute :remixed_comment
        remixed_comment = remixables[:comment]

        self.class_eval(<<-EOS, __FILE__, __LINE__ + 1)
          alias :comments #{remixed_comment[commentable_key][:reader]}
        EOS

        def commenter_fk(name)
          name ? ActiveSupport::Inflector.foreign_key(name.to_s.singular).to_sym : :user_id
        end
      
        c_opts = options[:commenter]
        c_name = c_opts.is_a?(Hash) ? (c_opts.delete(:name) || :user_id) : commenter_fk(c_opts)
        c_type = c_opts.is_a?(Hash) ? (c_opts.delete(:type) || Integer)  : Integer
        c_property_opts = c_opts.is_a?(Hash) ? c_opts : { :required => true }
        c_property_opts.merge!(:min => 0) if c_type == Integer # Match referenced column type
        c_association = c_name.to_s.gsub(/_id/, '').to_sym

        b_opts = options[:body]
        b_name = b_opts.is_a?(Hash) ? (b_opts.delete(:name) || :body) : :body
        b_type = b_opts.is_a?(Hash) ? (b_opts.delete(:type) || DataMapper::Types::Text) : DataMapper::Types::Text
        b_property_opts = b_opts.is_a?(Hash) ? b_opts : { :required => true }

        # block for enhance gets class_eval'ed in remixable scope
        commenting_rateable = self.commenting_rateable?
        
        enhance :comment, commentable_class_name do
          
          property c_name, c_type, c_property_opts # commenter
          property b_name, b_type, b_property_opts # body
          
          belongs_to c_association
          
          if commenting_rateable
            is :rateable, options[:rateable].is_a?(Hash) ? options[:rateable] : {}
          end
        
        end
        
      end

      module ClassMethods
                
        def commenting_togglable?
          self.properties.named? :commenting_enabled
        end
                
        def anonymous_commenting_togglable?
          self.properties.named? :anonymous_commenting_enabled
        end
        
        def rateable_commenting_togglable?
          self.properties.named? :rateable_commenting_enabled
        end
        
        def commenting_rateable?
          rateable_commenting_togglable? || @comments_rateable
        end
        
      end
  
      module InstanceMethods

        def commentable_class
          Object.full_const_get(self.commentable_class_name)
        end
        
        def commenting_rateable?
          self.class.commenting_rateable?
        end
             
        def commenting_togglable?
          self.class.commenting_togglable?
        end
                
        def anonymous_commenting_togglable?
          self.class.anonymous_commenting_togglable?
        end       
        
        def rateable_commenting_togglable?
          self.class.rateable_commenting_togglable?
        end
        
          
        def commenting_enabled?
          (commenting_togglable? && attribute_get(:commenting_enabled)) || true
        end
                  
        def anonymous_commenting_enabled?
          (anonymous_commenting_togglable? && attribute_get(:anonymous_commenting_enabled)) || true
        end
                          
        def rateable_commenting_enabled?
          (rateable_commenting_togglable? && attribute_get(:rateable_commenting_enabled)) || commenting_rateable?
        end
        
        
        # convenience method
        def commenting_disabled?
          !self.commenting_enabled?
        end
        
        # convenience method
        def anonymous_commenting_disabled?
          !self.anonymous_commenting_enabled?
        end
                
        # convenience method
        def rateable_commenting_disabled?
          !self.rateable_commenting_enabled?
        end
        
        
        def disable_commenting!
          if self.commenting_togglable?
            if attribute_get(:commenting_enabled)
              self.update(:commenting_enabled => false)
            end
          else
            raise TogglableCommentingDisabled, "Commenting cannot be toggled for #{self}"
          end
        end
        
        def enable_commenting!
          if self.commenting_togglable?
            unless attribute_get(:commenting_enabled)
              self.update(:commenting_enabled => true)
            end
          else
            raise TogglableCommentingDisabled, "Commenting cannot be toggled for #{self}"
          end
        end
        
        
        def disable_anonymous_commenting!
          if self.anonymous_commenting_togglable?
            if attribute_get(:anonymous_commenting_enabled)
              self.update(:anonymous_commenting_enabled => false)
            end
          else
            raise TogglableAnonymousCommentingDisabled, "Anonymous Commenting cannot be toggled for #{self}"
          end
        end
        
        def enable_anonymous_commenting!
          if self.anonymous_commenting_togglable?
            unless attribute_get(:anonymous_commenting_enabled)
              self.update(:anonymous_commenting_enabled => true)
            end
          else
            raise TogglableAnonymousCommentingDisabled, "Anonymous Commenting cannot be toggled for #{self}"
          end
        end
        
        
        def valid_comment_body?(body)
          body && !body.empty?
        end
            
        def valid_commenting_user?(user)
          user.nil? ? self.anonymous_commenting_enabled? : true
        end
        
        
        def comment(body, user = nil)
          if self.commenting_enabled?
            raise_if_invalid_comment!(body, user)
            self.comments.create(:body => body, :user => user)
          else
            raise CommentingDisabled, "Commenting is not enabled for #{self}"
          end
        end
        
        def user_comments(user, conditions = {})
          self.comments conditions.merge(:user_id => user.id)
        end
        
        private
        
        def raise_if_invalid_comment!(body, user)
          raise_unless_valid_commenting_user!(user)
          raise_unless_valid_comment_body!(body)
        end
        
        def raise_unless_valid_comment_body!(body)
          msg = "Comments must have at least one character"
          raise InvalidComment, msg unless valid_comment_body?(body)
        end
                
        def raise_unless_valid_commenting_user!(user)
          msg = "Anonymous Commenting is not enabled for #{self}"
          raise AnonymousCommentingDisabled, msg unless valid_commenting_user?(user)
        end
        
      end
      
    end
  end
end
