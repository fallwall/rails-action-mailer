class UserMailer < ApplicationMailer
  default from: "fallwall19@gmail.com"
  #above optional if not differnt from application

  def welcome_email(user)
    @user = user
    mail(to: @user.email, subject: "Welcome #{@user.name}")
  end
end
