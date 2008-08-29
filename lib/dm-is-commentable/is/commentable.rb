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

        # properties

        property :id, Integer, :serial => true
        
        # comments need timestamps anyway
        property :created_at, DateTime
        property :updated_at, DateTime
        
      end

      def is_commentable(options = {})
        
        extend  DataMapper::Is::Commentable::ClassMethods
        include DataMapper::Is::Commentable::InstanceMethods
        
        options = {
          # options for generated remixable
          :commenter => { :name => :user_id, :type => Integer, :nullable => false }, 
          :body      => { :type => DataMapper::Types::Text, :nullable => false },
          :rateable  => false,
          # options for remixer
          :as        => nil
        }.merge(options)
        
        @comments_rateable = options[:rateable]
        
        @comment_remixable = DataMapper::Is::Commentable::Comment
        class_inheritable_reader :comment_remixable
        
        # use dm-is-remixable for storage and api
        remix n, @comment_remixable, :as => options[:as]
        
        remixables_key = Extlib::Inflection.demodulize(@comment_remixable.name).snake_case.to_sym
        @remixed_comment = remixables[remixables_key]
        class_inheritable_reader :remixed_comment

        self.class_eval(<<-EOS, __FILE__, __LINE__ + 1)
          alias :comments #{@remixed_comment[:reader]}
        EOS

        def commenter_fk(name)
          name ? Extlib::Inflection.foreign_key(name.to_s.singular).to_sym : :user_id
        end
      
        c_opts = options[:commenter]
        c_name = c_opts.is_a?(Hash) ? (c_opts.delete(:name) || :user_id) : commenter_fk(c_opts)
        c_type = c_opts.is_a?(Hash) ? (c_opts.delete(:type) || Integer)  : Integer
        c_property_opts = c_opts.is_a?(Hash) ? c_opts : { :nullable => false }
        c_association = c_name.to_s.gsub(/_id/, '').to_sym

        b_opts = options[:body]
        b_name = b_opts.is_a?(Hash) ? (b_opts.delete(:name) || :body) : :body
        b_type = b_opts.is_a?(Hash) ? (b_opts.delete(:type) || DataMapper::Types::Text)  : DataMapper::Types::Text
        b_property_opts = b_opts.is_a?(Hash) ? b_opts : { :nullable => false }

        # block for enhance gets class evaled in remixable scope
        rateable_commenting_togglable = self.rateable_commenting_togglable?
        
        enhance :comment do
          
          property c_name, c_type, c_property_opts # commenter
          property b_name, b_type, b_property_opts # body
          
          belongs_to c_association
          
          if rateable_commenting_togglable || @comments_rateable
            # pass all supported dm-is-rateable options
            # is :rateable #, options[:rateable].is_a?(Hash) ? options[:rateable] : {}
          end
        
        end
        
      end

      module ClassMethods
        
        def commentable_fk
          demodulized_name = Extlib::Inflection.demodulize(self.name)
          Extlib::Inflection.foreign_key(demodulized_name).to_sym
        end
        
                
        def commenting_togglable?
          self.properties.has_property? :commenting_enabled
        end
                
        def anonymous_commenting_togglable?
          self.properties.has_property? :anonymous_commenting_enabled
        end
        
        def rateable_commenting_togglable?
          self.properties.has_property? :rateable_commenting_enabled
        end
        
        
        def commenting_rateable?
          rateable_commenting_togglable? || @comments_rateable
        end
        
      end
  
      module InstanceMethods
        
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
        
        
        def disable_commenting
          if self.commenting_togglable?
            if attribute_get(:commenting_enabled)
              self.update_attributes(:commenting_enabled => false)
            end
          else
            raise TogglableCommentingDisabled, "Commenting cannot be toggled for #{self}"
          end
        end
        
        def enable_commenting
          if self.commenting_togglable?
            unless attribute_get(:commenting_enabled)
              self.update_attributes(:commenting_enabled => true)
            end
          else
            raise TogglableCommentingDisabled, "Commenting cannot be toggled for #{self}"
          end
        end
        
        
        def disable_anonymous_commenting
          if self.anonymous_commenting_togglable?
            if attribute_get(:anonymous_commenting_enabled)
              self.update_attributes(:anonymous_commenting_enabled => false)
            end
          else
            raise TogglableAnonymousCommentingDisabled, "Anonymous Commenting cannot be toggled for #{self}"
          end
        end
        
        def enable_anonymous_commenting
          if self.anonymous_commenting_togglable?
            unless attribute_get(:anonymous_commenting_enabled)
              self.update_attributes(:anonymous_commenting_enabled => true)
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
        
        def user_comments(user)
          self.comments :user_id => user.id
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
          msg = "Comments must have at least one character"
          raise AnonymousCommentingDisabled unless valid_commenting_user?(user)
        end
        
      end
      
    end
  end
end