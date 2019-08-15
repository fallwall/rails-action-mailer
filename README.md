# Rails ActionMailer with Gmail
In this lesson, we're going to use Rails ActionMailer to have an app automatically send a user a welcome email after they've registered a new account. I used the following guides as support while creating this lesson: 
- https://guides.rubyonrails.org/action_mailer_basics.html
- https://launchschool.com/blog/handling-emails-in-rails

## Before You Begin
### Gmail security settings
You will get an authentication error unless you adjust the security on your Gmail account at `https://myaccount.google.com/security`

If you don't already have it set up, you'll need to add 2 step verification to your Gmail account. You can do this by adjusting the security settings at `myaccount.google.com`. Once you've completed setting up 2-step verification, you'll see a new option just below where you can add an app password. 

![](https://res.cloudinary.com/briandanger/image/upload/v1565878978/Screen_Shot_2019-08-15_at_10.22.15_AM_vt4e5a.png)

Click on this option. For app, select "mail" and for device, select "custom". Type whatever name you want for the app; it doesn't have to match the name of your rails app. Just name it anything that you'll remember. This will give you a new app-specific gmail password that you should use in your credentials instead of your actual gmail password.

COPY THIS PASSWORD and write it down somewhere. It will be difficult to access later if you don't (although you can always just make a new one).

### Gmail credentials
You'll need to user your email address and your new app specific password to access Gmail from your Rails app. Hide these in your credentials so that they're secure. You can edit your credentials by typing the following in the terminal (this is for VS Code; if using a different text editor, double check this command):

`EDITOR='code --wait' rails credentials:edit`

This will open a new file. In that file, enter the following:

```
gmail_username: 'username@gmail.com'
gmail_password: 'app password that you just created'
```

Save the file and close the editor to complete the process. 

To learn more about credentials, check out this article: https://medium.com/@jonathanmines/hiding-your-secrets-in-rails-5-using-credentials-e37174eede99

## Getting Started
You can clone the app attached to this repository as a starting point. It already has a user model and several views, so that will save us some time. Make sure to run `bundle install` after cloning it to ensure everything runs properly. 

### Updating Your User Model
Next, you'll need to add an email column to your user model. To do so, in the terminal type:
```
rails g migration AddEmailToUser email:string
```

Check your migration file before you migrate it to the database. It should look like this:
```
class AddEmailToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :email, :string
  end
end
```

It might look like it's saying "add a column called 'users' to the email model," but it's actually the opposite. This will add a column called `email` to your `user` model. 

Once everything's good, run `rails db:reset`. Next, add `:email` to the user_params in your `users_controller.rb`:
```
  def user_params
    params.require(:user).permit(:name, :bio, :password, :email)
  end
```

Finally, add an email input to `_form.html.erb` in your users views:
```
<%= form_for @user do |f| %>
  <%= f.text_field :name, placeholder: "Name" %>
  <%= f.text_area :bio, placeholder: "Bio" %>
  
  <%= f.email_field :email, placeholder: "Email" %>
  
  <%= f.password_field :password, placeholder: "Password" %>
  <%= f.submit "Submit"%>
<% end %>
```

Great! Now let's get started on ActionMailer.

## 1 - Create UserMailer
First, let's create our mailer by entering the following command in the terminal:

```
rails g mailer user_mailer
```

Although we're using `rails g`, it's worth nothing that the mailer isn't a model, and there will be **NO** `rails db:migrate` step necessary.

That said, your UserMailer it will act somewhat like a model. It's where we're going to put the methods that control what emails we send and what data is available to those emails. This command will also generate a view folder for our user emails. 

You don't have to use the name `user_mailer` for it to be able to work with your User model — you can call it whatever you want; however, this is a solid convention and recommended, as it will make your app more organized, readable, and accessable to new developers. 

## 2 - Set Up Default Source Email
Heade to you `mailers/application_mailer.rb` and set up a default email. This will be the source that your app sends emails from and should be the account for which you created an app specific password earlier. Depending on the security you want, you can either hide it by using the credentials reference or you can just write it out.

```
class ApplicationMailer < ActionMailer::Base
  default from: "your_email@gmail.com"
  layout 'mailer'
end
```

## 3 - Set up UserMailer
Now, head to `mailers/user_mailer.rb`. You shouldn't need to add a default from email here; however, I'm including it just to show you that you can also assign defaults here (plus, it doesn't really hurt to be redundant here).

Next, we create a method that we're going to call `welcome_email` that takes a user as an parameter. This method will assign that user to an instance variable and use Rails built in mail method to ensure the email is sent to that user with a welcoming subject line:

```
class UserMailer < ApplicationMailer
  default from: "bdflynny@gmail.com"

  def welcome_email(user)
    @user = user
    mail(to: @user.email, subject: "Welcome #{@user.name}")
  end
end
```

In the future, you can create additional emails using this same pattern. 

## 4 - Setting Up Our Email View
Okay, we've got our mail method set, and we know who the email will be from, that it will send to a user (to be assigned when the method is called), and what the subject line says. Next, we need to create a view to set up the body of the email.

Create the following file `views/user_mailer/welcome_email.html.erb`. It's important here that the name of the view `welcome_email` matches up with the name of our method.

Inside of this file, we can user HTML erb to write whatever information we want users to see when they receive our email. We'll keep it simple:

```
<h1>Hi <%= @user.name %></h1>
<p>Welcome to my awesome new app!</p>
```

**NOTE:** If you want to style your email, you'll have to use HTML inline styles. This applies to virtually all HTML emails, not just ones sent through ActionMailer on Rails.

## 5 - Configuring ActionMailer Settings:
Head to `config/environments/development.rb` and add the following code:

```
  config.action_mailer.default_url_options = {:host =>'localhost:3000'}
  config.action_mailer.delivery_method = :smtp
  
# SMTP settings for gmail
  config.action_mailer.smtp_settings = {
   :address              => "smtp.gmail.com",
   :port                 => 587,
   :user_name            => Rails.application.credentials.gmail_username,
   :password             => Rails.application.credentials.gmail_password,
   :authentication       => "plain",
   :enable_starttls_auto => true
  }
  ```
  
This sets up the default URL for the source of the email and the delivery method. Further, it ensures that the delivery is specifically through Gmail and that it uses the user name and password that you set up in your credentials earlier. For security, make sure to use the config variables you established while setting up credentials instead of actually writing out your password.

If you want to set up a mailer for your production environment, just head to `config/environments/production.rb` and add the same code, changing the host in the line `config.action_mailer.default_url_options = {:host =>'localhost:3000'}` to the URL of your deployed app.

While in develpment, you'll also want to change the line `config.action_mailer.raise_delivery_errors = false` to `true`. This will let Rails raise errors if the email doesn't send. **Do not do this in production.rb**. Raising errors in development can be very helpful; however, in production it will risk crashing the app on your users. 
  
## 6 - Calling Your Email Method
Okay, we've set up our credentials, configurations, mail method, and views. Now we just need to do the dang thing. Since we want this email to send just after a new user is registered, head to `users_controller.rb` and add the line `UserMailer.welcome_email(@user).deliver` just after a new user is saved in your create method.

The syntax here is basically `MailerName` + `method_name(arguments)` + `deliver`

```
  def create
    @user = User.new(user_params)
    if @user.save
      UserMailer.welcome_email(@user).deliver
      redirect_to @user
    end
  end
```

## 7 - Try It Out!
Fire up your rails server and visit `/users/new`. Create a new user with a valid email that you can check. After you've clicked the submit button, the user's email address should receive your new welcome email. Great job!

  
