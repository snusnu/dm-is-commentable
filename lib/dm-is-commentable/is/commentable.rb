module DataMapper
  module Is
    module Commentable
      
      class DmIsCommentableException < Exception; end
      
      class InvalidComment < DmIsCommentableException; end
      class CommentingDisabled < DmIsCommentableException; end
      class TogglableCommentingDisabled < DmIsCommentableException; end
      
      module Comment

        include DataMapper::Resource

        is :remixable

        # properties

        property :id, Integer, :serial => true
        
        property :body, Text, :nullable => false
        
      end

      def is_commentable(options = {})
        
        extend  DataMapper::Is::Commentable::ClassMethods
        include DataMapper::Is::Commentable::CommonInstanceMethods
        
        # merge default options
        options = {
          :comment_remixable => nil, # only enhance if this is nil
          :anonymous => false,
          :rateable => true,
          :commenter => { :fk => :user_id, :fk_type => Integer },
          :allow_deactivation => true,
          :as => nil
        }.merge(options)
        
        @comment_remixable = options[:comment_remixable] || DataMapper::Is::Commentable::Comment
        class_inheritable_reader :comment_remixable
        
        @allow_togglable_commenting = options[:allow_deactivation]
        class_inheritable_accessor :allow_togglable_commenting
        
        # use dm-is-remixable for storage and api
        remix n, @comment_remixable, :as => options[:as]
        
        @remixed_comment = remixables[Extlib::Inflection.demodulize(@comment_remixable.name).snake_case.to_sym]
        class_inheritable_reader :remixed_comment

        self.class_eval(<<-EOS, __FILE__, __LINE__ + 1)
          alias :comments #{@remixed_comment[:reader]}
        EOS
        
        # allow to disable comments
        property :comments_enabled, DataMapper::Types::Boolean, :nullable => false, :default => true
        
        if options[:anonymous]
          include DataMapper::Is::Commentable::AnonymousCommentInstanceMethods
        else
          include DataMapper::Is::Commentable::PersonalizedCommentInstanceMethods
        end

        unless options[:comment_remixable]
          
          enhance :comment do
          
            commenter = options[:commenter]
            fk      = commenter.is_a?(Hash) ? commenter[:fk]      || :user_id : commenter.to_s.snake_case.to_sym
            fk_type = commenter.is_a?(Hash) ? commenter[:fk_type] || Integer  : Integer

            property fk, fk_type, :nullable => options[:anonymous]
            
            # comments need timestamps anyway
            property :created_at, DateTime
            property :updated_at, DateTime
            
            belongs_to fk.to_s.gsub(/_id/, '').to_sym
            
            if options[:rateable]
              
              # remix rateable and pass all supported dm-is-rateable options
              # is :rateable, options[:rateable].is_a?(Hash) ? options[:rateable] : {}
              
            end
          
          end
        
        end
        
      end

      module ClassMethods
        
        def commentable_fk
          demodulized_name = Extlib::Inflection.demodulize(self.name)
          Extlib::Inflection.foreign_key(demodulized_name).to_sym
        end
        
      end
  
      module CommonInstanceMethods
        
        def comments_enabled?
          self.respond_to?(:comments_enabled) && self.comments_enabled
        end
        
        def disable_comments
          if self.class.allow_togglable_commenting
            if self.comments_enabled?
              self.comments_enabled = false
              self.save
            end
          else
            raise TogglableCommentingDisabled, "Commenting cannot be toggled for #{self}"
          end
        end
        
        def enable_comments
          if self.class.allow_togglable_commenting
            unless self.comments_enabled?
              self.comments_enabled = true
              self.save
            end
          else
            raise TogglableCommentingDisabled, "Commenting cannot be toggled for #{self}"
          end
        end
        
        def comment_bodies(conditions = {})
          self.comments(conditions).map { |c| c.body }
        end
        
        def valid_comment_body?(body)
          body && !body.empty?
        end
        
      end
      
      module AnonymousCommentInstanceMethods
        
        def comment(body)
          if self.comments_enabled?
            raise unless valid_comment_body?(body)
            self.comments.create(:body => body)
          else
            raise CommentingDisabled, "Commenting is not enabled for #{self.name}"
          end
        rescue
          raise InvalidComment, "Comments must have at least one character"
        end
        
      end
      
      module PersonalizedCommentInstanceMethods
        
        def comment(body, user)
          if self.comments_enabled?
            raise unless valid_comment_body?(body)
            self.comments.create(:body => body, :user => user)
          else
            raise CommentingDisabled, "Commenting is not enabled for #{self.name}"
          end
        rescue
          raise InvalidComment, "Comments must have at least one character"
        end

        def user_comments(user)
          self.comments(:user_id => user.id)
        end
                
        def user_comment_bodies(user)
          (cs = user_comments(user)).empty? ? cs : cs.map { |c| c.body }
        end
        
      end
      
    end
  end
end