module Error
  module ErrorHandler
    def self.included(klass)
      klass.class_eval do
        rescue_from StandardError, with: :render_error
      end
    end

    protected
    def error_to_status_code(exception)
      case exception
        when ActiveRecord::RecordNotFound
          :not_found
        when ActionController::RoutingError,
            ActiveRecord::RecordInvalid
          :unprocessable_entity
        else :internal_server_error
      end
    end

    def render_error(exception)
      status_code = error_to_status_code(exception)
      exception_msg = exception.message
      if status_code == :internal_server_error
        exception_msg = "We're sorry, but something went wrong." unless Rails.env.development?
      end
      
      json = {error: exception_msg}
      render json: json, status: status_code
    end
  end
end
