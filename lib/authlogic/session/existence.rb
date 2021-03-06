# frozen_string_literal: true

module Authlogic
  module Session
    # Provides methods to create and destroy objects. Basically controls their
    # "existence".
    module Existence
      class SessionInvalidError < ::StandardError # :nodoc:
        def initialize(session)
          message = I18n.t(
            "error_messages.session_invalid",
            default: "Your session is invalid and has the following errors:"
          )
          message += " #{session.errors.full_messages.to_sentence}"
          super message
        end
      end

      def self.included(klass)
        klass.class_eval do
          extend ClassMethods
          include InstanceMethods
          attr_accessor :new_session, :record
        end
      end

      # :nodoc:
      module ClassMethods
        # A convenience method. The same as:
        #
        #   session = UserSession.new(*args)
        #   session.save
        #
        # Instead you can do:
        #
        #   UserSession.create(*args)
        def create(*args, &block)
          session = new(*args)
          session.save(&block)
          session
        end

        # Same as create but calls create!, which raises an exception when validation fails.
        def create!(*args)
          session = new(*args)
          session.save!
          session
        end
      end

      # :nodoc:
      module InstanceMethods
        # Clears all errors and the associated record, you should call this
        # terminate a session, thus requiring the user to authenticate again if
        # it is needed.
        def destroy
          run_callbacks :before_destroy
          save_record
          errors.clear
          @record = nil
          run_callbacks :after_destroy
          true
        end

        # Returns true if the session is new, meaning no action has been taken
        # on it and a successful save has not taken place.
        def new_session?
          new_session != false
        end

        # After you have specified all of the details for your session you can
        # try to save it. This will run validation checks and find the
        # associated record, if all validation passes. If validation does not
        # pass, the save will fail and the errors will be stored in the errors
        # object.
        def save
          result = nil
          if valid?
            self.record = attempted_record

            run_callbacks :before_save
            run_callbacks(new_session? ? :before_create : :before_update)
            run_callbacks(new_session? ? :after_create : :after_update)
            run_callbacks :after_save

            save_record
            self.new_session = false
            result = true
          else
            result = false
          end

          yield result if block_given?
          result
        end

        # Same as save but raises an exception of validation errors when
        # validation fails
        def save!
          result = save
          raise SessionInvalidError, self unless result
          result
        end
      end
    end
  end
end
