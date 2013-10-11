class SessionsController < ApplicationController
  def new
  end

  def create
    if AppContext.resmap_api.users.valid?(params[:email], params[:password])
      session[:email] = params[:email]
      session[:password] = params[:password]

      User.find_or_create_by_email!(params[:email])
      redirect_to root_path
    else
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
