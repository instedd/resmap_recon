class SessionsController < ApplicationController
  def new
  end

  def create
    begin
      api = ResmapApi.basic(params[:email], params[:password])
      api.json('/collections')

      session[:email] = params[:email]
      session[:password] = params[:password]

      User.by_email(params[:email])
      redirect_to root_path
    rescue
      flash.now.alert = 'Invalid credentials'
      render 'new'
    end
  end

  def destroy
    session[:email] = nil
    session[:password] = nil

    redirect_to root_path
  end
end
