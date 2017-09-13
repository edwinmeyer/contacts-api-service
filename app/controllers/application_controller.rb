class ApplicationController < ActionController::API
  require './lib/error/error_handler.rb'
  include Error::ErrorHandler

  def routing_error
    raise(ActionController::RoutingError.new("No route matches [#{request.method}] #{request.path}") )
  end
end
