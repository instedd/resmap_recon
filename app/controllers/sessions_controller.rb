class SessionsController < ApplicationController
  def new
  end

  def create
    begin
      api = ResourceMap::Api.basic_auth(params[:email], params[:password], Settings.resource_map.host, Settings.resource_map.https)
      api.json('/collections')

      session[:email] = params[:email]
      session[:password] = params[:password]

      User.by_email(params[:email])
      redirect_to root_path
    # rescue
    #   flash.now.alert = 'Invalid credentials'
    #   render 'new'
    end
  end

  def destroy
    session[:email] = nil
    session[:password] = nil

    redirect_to root_path
  end
end
