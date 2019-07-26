# Contacts API Service &ndash; A Ruby on Rails 5 Sample Application 
## with Rbenv, Postgres or MySQL, JSON, Active Model Serializers, and Git
### *Edwin W. Meyer*
### Updated July 20-23, 2019

## Background
*Contacts API Service* is a sample Ruby on Rails 5 'api-only' application that maintains a simple contact list and serves it to an API client. Its goal is to build in a fairly concise step-wise fashion a multi-featured  API structure. The problem domain demonstrates basic API features &ndash; it is not intended to be a practical contact list application. 

- No RSpec or other tests are described. While repeatable automated testing is an important part of application development, no tests are included here to avoid distracting from main line of the tutorial. Instead, the curl command is used to generate requests for manual testing.
- Similarly, features that are an important part of any practical application but which are not directly related to API features are omitted. For example, only a few model validations are implemented.
- Setting up the basic Rails application environment is not covered here. Refer to "Basic Setup for Ruby on Rails 5 Development" at https://github.com/edwinmeyer/rails-5-setup for this.
- The package versions listed were current as of July 20, 2019. Later versions of Rails or Ruby may have different behaviors.

## Documentation Conventions
Except where specially noted:
- "$" at the beginning of a line represents the terminal command prompt.
- ">" at the beginning of a line denotes a URL to be entered into a web browser.
- "#" represents the beginning of a comment.
- "-->" at the end of a terminal command indicates that the following text on the same or subsequent lines is the expected output.
- "\-" at the beginning of a line denotes instructions to be executed.


## First Commit &ndash; Rails Application Structure
***Create Project Directory***  
This is often prescribed as to be done during Rails app creation. However, doing this initially allows more flexibility.
```bash
$ mkdir contacts-api-service
$ cd contacts-api-service # further work done inside project directory
```

***Rbenv Setup for App / Install Rails***
```bash
# Create a .ruby-version file that specifies the Ruby version 2.6.3 to be used
$ rbenv local 2.6.3 
# Install latest version of Rails into <home dir>/rbenv/versions/2.6.3/bin/rails
$ gem install rails  
$ rails -v --> Rails 5.2.3  # released March 28, 2019
```

***Create Rails App Structure*** 
Perform "rails new" with these options:  
- "--api" to create a headless API Rails app that omits support for HTML output
- "-d postgresql" or "-d mysql" to use Postgres or MySQL respectively rather than the default MySQL, and
- "-T" (optional) to omit unit/mini-test file generation if you want to instead use Rspec.  

_Note:_ While performing tests is a best practice, it is not covered here. 
To use Postgres as the database server:
```bash 
$ rails new . --api -d postgresql -T
```
To use MySQL as the database server:
```bash 
$ rails new . --api -d mysql -T
```
If you get the error "Could not find gem 'mysql2 (>= 0.4.4, < 0.6.0)' ...", execute `bundle install`, then continue with next steps.

*Note 1:* The period after "new" indicates that the application is to be created in the current directory.
*Note 2:* 'rails new' runs 'bundle install' as the last step

***Set Up the App for Postgres***  
Add to database.yml within the  
`default: &default`  
section, used by all environments:
```bash 
username: rails_user # otherwise rails looks for the user name of the currently logged in user
password: rails_user_pwd # see https://gist.github.com/p1nox/4953113 for how to omit password
host: localhost # Otherwise get : FATAL: Peer authentication failed for user "rails_user"
```  

***Create the Rails User in Postgres***  
Perform this only if not previously done.   
_Note:_ In the below commands, '#' represents the Postgres client prompt 
```bash 
$ sudo -u postgres createuser -s rails_user 
$ sudo -u postgres psql # Enter Postgres client
# \password rails_user 
Set password & confirmation at prompt as 'rails_user_pwd'
# \q
```

***Set Up the App for MySQL***  
Add to database.yml under the  
`default: &default`  
section, used by all environments:
```bash 
username: rails_user # otherwise rails looks for the user name of the currently logged in user
password: rails_user_pwd
host: localhost # Otherwise get : FATAL: Peer authentication failed for user "rails_user"
```  
_Note:_ Change the username & password to whatever user you have previously created for the rails app

***Create the Rails User in MySQL***  
Perform this and the subsequent step only if not previously done.   
_Note:_ In the below commands, 'mysql>' represents the MySQL client prompt 
```bash 
$ sudo mysql # Enter the MySQL client as the root user - 'sudo' is required
mysql> CREATE USER 'rails_user'@'localhost'IDENTIFIED WITH mysql_native_password BY 'rails_user_pwd';
-- Select your own values for 'rails_user' and 'rails_user_pwd'
```
***Grant Privileges and Create Development Database***  
`rails_user` needs privileges to be able to do anything. Additionally, the development database needs be created before running `rails db:migrate`
```bash 
mysql> GRANT ALL PRIVILEGES ON *.* TO 'rails_user'@'localhost';
mysql> CREATE DATABASE IF NOT EXISTS `contacts-api-service_development`; # Note the backtick quotes
exit # from MySQL to command line
```
***Create a Git Repository and Perform the First Commit***  
Now that the basic structure of the app has been created, create a Git repository for the project and make the first commit. 

```bash
$ git init . # Performed in the 'contacts-api-service' app root directory 
$ git add . 
$ git commit -m "Initial commit of rails app structure"
```
You will likely want to push this repo to a Git repository hosting service such as Github, Bitbucket, or GitLab. However, we do not cover this here.

_Note:_ If you ever need to start over, simply do a 'hard' git reset specifying the id of this first commit:
```bash
$ git reset --hard <commit id of first commit>
```

## Second Commit &ndash; Application With Basic Features
The previous section for the first commit created the foundation for a generic Rails API application. Now we begin to create an API application for a contact manager.
  
Keep in mind that this application serves as a foundation for presenting API features &ndash; it is not intended to be a practical contact manager.

***Create Application Elements Using Rails Generate Commands***  

The Rails generate command suite is a simple way of creating a basic functional app with controllers and models from the command line.

```bash
$ rails generate scaffold Contact first_name:string last_name:string phone:string email:string
$ rails generate scaffold Note note_date:datetime content:text contact:references
```

***Update and Move Controllers to Prepare for Subdomain Access & Versioning***  
Later we will implement the ability for a client to specify a specific API version and for access using a subdomain (e.g. api.example.com). To prepare for this, the two controllers have to be modified to specify these nested namespaces and moved to the corresponding directories.

The scaffold generator created app/controllers/contacts_controller.rb with the following class definition:  
**`class ContactsController < ApplicationController`**

**&ndash;** Insert the module specifiers **`Api::V1::`** so the line reads:  
**`class Api::V1::ContactsController < ApplicationController`**

Create subdirectories for these namespaces and move the controller into place.  
```bash
$ mkdir -p app/controllers/api/v1
$ mv app/controllers/contacts_controller.rb app/controllers/api/v1
```

Do the same for notes_controller.rb

The generator has created routes to the controllers in their original top-level locations. config/routes.rb contains the following lines:
```ruby
  resources :notes
  resources :contacts
```

Embed these within nested namespaces so that routes.rb contains:
```ruby
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :notes
      resources :contacts
    end
  end
end
```

We will further modify these routes when we deal with subdomains and versioning, but this will do for now.  
_Note:_ It should be possible to directly generate name-spaced resources using the scaffold generator,  
e.g. **`rails generate scaffold Api::V1::Contact ...`**.  
However, I encountered some problems with this. Manually making the namespace chnges is also more instructive.

***Create Special Controller Index Methods for Smoketest***  
For the purpose of performing a fairly simple application smoketest, replace the index method of contacts_controller.rb with the following: 
 
```ruby
  def index
    @contacts = [
      { first_name: 'Abraham', last_name: 'Lincoln', 
          phone: '555-555-5551', email: 'abraham_lincoln@example.com' }
    ]
    render json: @contacts
  end
```

Do something similar for notes_controller.rb if you wish.

***Run Database Migrations***  
The generators for contacts and notes created several "migration" files in db/migrate that set up the DB tables. Although the smoke tests performed here don't actually read from the database, we still need to run these migrations to create the tables:  

```bash
$ rails db:migrate
```

***Smoke Test the Skeletal Rails App***  
Start rails server from a separate terminal window:
```bash
$ rails s 
```

In a web browser: 
```bash
> http://localhost:3000 
```  
The "Yay! You’re on Rails!" static page is displayed. (even though this is an API-only app.)

```bash
> http://localhost:3000/api/v1/contacts
```  
The following JSON output is displayed in the browser:
```bash  
[{"first_name":"Abraham","last_name":"Lincoln",
  "phone":"555-555-5551","email":"abraham_lincoln@example.com"}]
```  
This smoke test displays only canned output without invoking the database, and the output is sent to a browser and not an api client. Still this verifies that our routing to the controller works.

Now is a good time to perform a second commit with commit message "contacts-api-service app with basic features".

## Third Commit &ndash; Hook Up App to the Database
Our smoke testing did not actually reference the database. We'll change that in this step.

***Associate the Content Model With Note***  
While the generator properly associated the Note model with the Content model, it did not create the inverse relation in contact.rb.  
 **&ndash;** Insert the **`has_many :notes`** line as follows:   
```ruby 
class Contact < ApplicationRecord
  has_many :notes
end
```

***Create Seeded Data For Testing the API***  
The file db/seeds.rb is used to create test data and store it in the database. It is initially empty except for some comments. 
speciallyReplace it with the following code that creates two contacts records, each with two associated notes records:

```ruby 
  contact = Contact.create(first_name: "Abraham", last_name: "Lincoln", 
    phone: "555-555-5551", email: "abraham_lincoln@example.com")
  contact.notes.create(note_date: "2017-12-1", content: "Note to Abraham")
  contact.notes.create(note_date: "2017-12-2", content: "Second Note to Abraham")

  contact = Contact.create(first_name: "Herbert", last_name: "Hoover", 
    phone: "555-555-5552", email: "herbert_hoover@example.com")
  contact.notes.create(note_date: "2018-2-1", content: "Note to Herbert")
  contact.notes.create(note_date: "2018-2-2", content: "Second Note to Herbert")
```  
_Note:_ The Faker gem is often used to create seed data for testing. I avoid it because it is not repeatable &ndash; the data values it produces are different for each run.

***Create, Migrate &amp; Seed the Database***  
Create the database with the contacts and notes tables containing the data defined in seeds.rb:  
```bash
$ rails db:drop # If DB exists and you want to start over
$ rails db:create # both development and test dbs are created
$ rails db:migrate 
$ rails db:seed 
```  

***Implement the Index Action***   
In the previous section we rendered fake data without interacting with the database as a smoke test. Now we are ready to render database records.

**&ndash;** Replace the index action of contacts_controller.rb with the following:  
```ruby
def index
  @contacts = Contact.order('last_name, first_name')  
  render json: @contacts
end
```  
**&ndash;** Similarly replace the index action of notes_controller.rb:
```ruby
  def index
    @notes = Note.order('id')
    render json: @notes
  end
```  

***The Show Action &ndash; No Change Needed***  
The show action as generated needs no change:  
```ruby
  # GET /contacts/1
  def show
    render json: @contact
  end
```  
The show action will raise an exception if the requested contact is not found. We'll handle that later.

_Note:_ @contact is set by set_contact() at the bottom of the file.

***Render Json Data From the Database***  
Now let's test this, using curl, a command line program that sends a url over the internet and outputs the resulting response.

```bash
$ curl http://localhost:3000/api/v1/contacts
-->
[{"id":2,"first_name":"Herbert","last_name":"Hoover","phone":"555-555-5552",
  "email":"herbert_hoover@example.com","created_at":"2017-08-29T06:09:17.794Z",
  "updated_at":"2017-08-29T06:09:17.794Z"},
  {"id":1,"first_name":"Abraham","last_name":"Lincoln","phone":"555-555-5551",
  "email":"abraham_lincoln@example.com","created_at":"2017-08-29T06:09:17.620Z",
  "updated_at":"2017-08-29T06:09:17.620Z"}]

$ curl http://localhost:3000/api/v1/notes
-->
[{"id":1,"note_date":"2017-12-01T00:00:00.000Z","content":"Note to Abraham","contact_id":1,
  "created_at":"2017-08-29T06:09:17.696Z","updated_at":"2017-08-29T06:09:17.696Z"},
  {"id":2,"note_date":"2017-12-02T00:00:00.000Z","content":"Second Note to Abraham","contact_id":1,
  "created_at":"2017-08-29T06:09:17.728Z","updated_at":"2017-08-29T06:09:17.728Z"},
  {"id":3,"note_date":"2018-02-01T00:00:00.000Z","content":"Note to Herbert","contact_id":2,
  "created_at":"2017-08-29T06:09:17.803Z","updated_at":"2017-08-29T06:09:17.803Z"},
  {"id":4,"note_date":"2018-02-02T00:00:00.000Z","content":"Second Note to Herbert","contact_id":2,
  "created_at":"2017-08-29T06:09:17.811Z","updated_at":"2017-08-29T06:09:17.811Z"}]

$ curl http://localhost:3000/api/v1/contacts/1
-->
{"id":1,"first_name":"Abraham","last_name":"Lincoln","phone":"555-555-5551",
  "email":"abraham_lincoln@example.com","created_at":"2017-08-29T06:09:17.620Z",
  "updated_at":"2017-08-29T06:09:17.620Z"}

$ curl http://localhost:3000/api/v1/notes/1
-->
{"id":1,"note_date":"2017-12-01T00:00:00.000Z","content":"Note to Abraham","contact_id":1,
  "created_at":"2017-08-29T06:09:17.696Z","updated_at":"2017-08-29T06:09:17.696Z"}
```  
_Note:_ This output is not in an accepted JSON format. We'll fix that shortly. Also, we describe only the index and show actions to concentrate on the core features. The new, create, update, and destroy actions are implemented later.

At this time perform a third commit with the message "Connect to database".

## Fourth Commit &ndash; Add the active_model_serializers gem
***Create Custom JSON Responses Using Active Model Serializers***  
The response that is returned by the index and show actions we created above is in a JSON format, but it still needs tweaking to be a correct API response. Additionally, we want to be able to generate customized responses, not merely JSON representations of all record fields.  

There are two popular choices for returning JSON, the JBuilder gem that is preferred by the Rails team, and the Active Model Serializers gem, which is gaining popularity. The JBuilder gem utilizes .json.jbuilder view files in the app/views/ hierarchy, while Active Model Serializers uses special serializer classes in the app/serializers/ hierarchy instead of view files. Here we will use Active Model Serializers. If you choose to instead use the JBuilder gem, other aspects of this tutorial still apply.

**&ndash;** First update Gemfile by replacing the commented lines
```ruby
  # Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
  # gem 'jbuilder', '~> 2.5'
```  
with 
```ruby
  gem 'active_model_serializers'
```  
Then run bundler:
```bash
$ bundle
```

***Create serializers for the Contact and Note controllers***  
 While there are generators that could create these classes for us (e.g. **`$ rails g serializer contact`**), it is simpler to manually create them given the customization necessary.

**&ndash;** Create the serializer subdirectory parallel to that for the namespaced controllers (app/controllers/api/v1/)
```bash
$ mkdir -p app/serializers/api/v1/
```
**&ndash;** Create the namespaced contact serializer contact_serializer.rb in this directory:
```ruby
class Api::V1::ContactSerializer < ActiveModel::Serializer
  attributes :id, :first_name, :last_name, :email
end
```

Only the fields listed in the attributes method are returned. Here created_at and updated_at are omitted.

**&ndash;** Similarly create the note serializer app/serializers/api/v1/note_serializer.rb

```ruby
class Api::V1::NoteSerializer < ActiveModel::Serializer
  attributes :id, :note_date, :content
end
```

***Test the Modified Endpoints Again With Curl***

```bash
$ curl http://localhost:3000/api/v1/contacts
--> 
[{"id":2,"first_name":"Herbert","last_name":"Hoover","email":"herbert_hoover@example.com"},
  {"id":1,"first_name":"Abraham","last_name":"Lincoln","email":"abraham_lincoln@example.com"}]
```
```bash
$ curl http://localhost:3000/api/v1/contacts/1
-->
{"id":1,"first_name" : "Abraham","last_name":"Lincoln","email":"abraham_lincoln@example.com"}
```

The output now includes only the listed attributes, and as in the above examples, it is formatted using the default :attributes adapter. This adapter is so named because it presents the model attributes in a simple style. 
However the :attributes adapter does not produce a generally accepted JSON output. Let's fix that now. 

***Create an Initializer That Sets the Adapter to :json***  
**&ndash;** Create config/initializers/active_model_serializers.rb with the contents
```ruby
require 'active_model_serializers'
ActiveModelSerializers.config.adapter = :json
```

**&ndash;** Then restart the rails server so this and other initializers can be executed.

***Run curl again to see the JSON format output***
```bash
$ curl http://localhost:3000/api/v1/contacts 
-->
{"contacts":[{"id":2,"first_name":"Herbert","last_name":"Hoover",
  "email":"herbert_hoover@example.com"},
  {"id":1,"first_name":"Abraham","last_name":"Lincoln",
  "email":"abraham_lincoln@example.com"}]}

$ curl http://localhost:3000/api/v1/contacts/1 
-->
{"contact":{"id":1,"first_name" : "Abraham","last_name":"Lincoln",
  "email":"abraham_lincoln@example.com"}}
```  
Now the output encapsulates the attributes within an extra level that indicates the resource. 

***Output Conforming to the JSON API standard***  
In addition to the :attributes and :json adapter specifiers, there is also a :json_api specifier that produces output conforming to the emerging JSON API standard. (See http://jsonapi.org/.) If the adapter is changed to :json_api in active_model_serializers.rb, the following output is produced:

```bash
$ curl http://localhost:3000/api/v1/contacts 
-->
{"data":[{"id":"2","type":"contacts","attributes":{"first-name":"Herbert",
  "last-name":"Hoover", "email":"herbert_hoover@example.com"}},
  {"id":"1","type":"contacts","attributes":{"first-name":"Abraham",
  "last-name":"Lincoln","email":"abraham_lincoln@example.com"}}]}

$ curl http://localhost:3000/api/v1/contacts/1 
-->
{"data":{"id":"1","type":"contacts","attributes":{"first_name":"Abraham",
  "last-name":"Lincoln","email":"abraham_lincoln@example.com"}}}
```

The output it produces has provisions for including fairly complex meta-data that the simpler :json adapter format lacks. Depending upon the audience for your api and the content you need to convey, :json_api may be the best choice. However, this tutorial will stick with :json format output.

We will further customize these serializers and implement the other actions when advanced Active Model Serializer options are discussed (to be provided). But next we will look at api versioning.

At this time perform a fourth commit with the message "Add the active_model_serializers gem"

## Fifth Commit &ndash; Api Versioning Using Request Headers
Next we turn to the topic of creating multiple API versions, a very useful if not totally essential feature. A version is a specific implementation of the API, which can co-exist with other versions, such that the client can specify a specific version to be accessed. This allows new API versions to be deployed without breaking the clients which use an existing API version.

In fact, we've already implemented the basic structure underlying versioning. The segments "api/v1" in the url **`http://localhost:3000/api/v1/contacts`** maps to controllers (and serializers) in the **`Api::V1`** namespace. It is simple enough to implement a second version of the API in a new namespace, e.g. **`Api::V2`**. The corresponding url that the client would access for the contacts resource would be **`http://localhost:3000/api/v2/contacts`**.

A number of prominent public APIs implement versioning by embedding the version in the URL. If this is good enough for you, you can skip this section &ndash; you won't need it. Just make appropriate adjustments to the examples in subsequent sections.

This section describes a technique where the API version is specified in an "ACCEPTS" request header, and not as part of the url. In the view of many including myself, this avoids polluting the url with a component that has nothing to do with the resource being accessed. It also allows a client to access the current default version by not providing a version header. In this way users of the new api service can be transitioned to a newer backward compatible version without requiring changes on the client end.

***Update routes.rb for ACCEPTS Header Dependencies***  
**&ndash;** Replace config/routes.rb with the following:
```ruby
  require './lib/api_constraints' 

  Rails.application.routes.draw do
    namespace :api, constraints: {format: 'json'} do
      scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true)  do
        resources :notes
        resources :contacts
      end

      scope module: :v2, constraints: ApiConstraints.new(version: 2) do
        resources :notes
        resources :contacts
      end
    end
  end
```

Routes for a new version 'v2' have been added so that we have an additional version to test with. The controllers and serializers are created below by copying and modifying the 'v1' code. With these routes, version 2 is accessed only if the client request specifically requests it. The default version 1 is accessed if specified by the request or if no version is specified.

Of special note:  

1. The **`constraints: {format: 'json'}`** option added to the namespace method specifies that this path is valid only if the 'json' format is specified in the request header or as the '.json' url suffix. Additionally, 'json' is assumed if no format is specified.
2. The **`default: true`** option in the constraint for version 1 indicates that this is the default route to use when the request does not specify the version.
3. With the **`scope module: :v1`** the url 'api/contacts' is mapped to Api::V1::ContactsController. This is the same mapping as performed for the url 'api/v1/contacts' by the previous **`namespace :v1`** line.
4. The scope method option **`constraints: ApiConstraints.new(version: 1)`** specifies that the match?() method of an ApiConstraints instance must return true, which it does only if the version supplied to match?() is 1.
5. The **`scope module: :v2 do`** block is similar.

**ApiConstraints**  
**&ndash;** Place the following into a new file api_constraints.rb in the 'lib' directory:
```ruby
  class ApiConstraints
    def initialize(options)
      @version = options[:version]
      @default = options[:default]
    end
      
    def matches?(req)
      return true if req.headers['Accept'].include?("application/vnd.contacts.v#{@version}") # a match
      return false if req.headers['Accept'].include?("application/vnd.contacts.v") # specifies a different version
      @default # no version Accept header found
    end
  end
```

This class is placed lib directory. While the contents of app are always auto-loaded, 'lib' is not automatically loaded in production. (This is a change in Rails 5.)  There are various techniques to load 'lib', but simplest for our purposes is simply to require the file where we need it. That is the purpose of the line **`require './lib/api_constraints'`** previously placed into config/routes.rb.
  
***Creating the Version 2 Controllers and Serializers***  
It's rather simple. First copy the v1 directories into a new directory v2:
```bash
$ cp -pr app/controllers/api/v1/ app/controllers/api/v2/
$ cp -pr app/serializers/api/v1/ app/serializers/api/v2/
```

Then, in each of the four version 2 files change the 'V1' namespace in the 'class' statement at the top of each file to 'V2'.

Finally, we need a way to distinguish between the output of the version 1 and version 2 ContactsController show methods.  
**&ndash;** Remove the :email attribute from the attributes method in app/serializers/api/v2/contact_serializer.rb so that it reads:
```ruby
  class Api::V2::ContactSerializer < ActiveModel::Serializer
    attributes :id, :first_name, :last_name
  end
```
That's it.

***Manual Testing With Curl***  

***&mdash; Accesses the version 1 API when no version is specified***
```bash
$ curl http://localhost:3000/api/contacts/1 
-->
{"contact":{"id":1,"first_name" : "Abraham","last_name":"Lincoln",
  "email":"abraham_lincoln@example.com"}}
```
***&mdash; Also accesses the version 1 API when an Accept header specifies version 1***
```bash
$ curl -H 'Accept: application/vnd.contacts.v1' http://localhost:3000/api/contacts/1 
-->
{"contact":{"id":1,"first_name" : "Abraham","last_name":"Lincoln",
  "email":"abraham_lincoln@example.com"}}
```
_Note:_ '-H' is the abbreviated form of the '--header' option. 'Accept: application/vnd.contacts.v1' is added to the request headers

***&mdash; Accesses the version 2 API when an Accept header specifies version 2***
```bash
$ curl -H 'Accept: application/vnd.contacts.v2' http://localhost:3000/api/contacts/1 
-->
{"contact":{"id":1,"first_name" : "Abraham","last_name":"Lincoln"}}
```
_Note:_ The email field is not included.

***&mdash; Raises ActionController::RoutingError when an Accept header specifies non-existant version 3***
```bash
$ curl -H 'Accept: application/vnd.contacts.v3' http://localhost:3000/api/contacts/1
```
The request raises the error `ActionController::RoutingError (No route matches [GET] "/api/contacts/1")`, which is written to the console output and to the log file. What we instead want is for the request to return a concise JSON error. We will fix that below.

At this time perform a fifth commit with the message "Add Api Versioning Using Request Headers"


## Sixth Commit &ndash; Error Handling
When we sent a request to a non-existant api version, the json request raised an `ActionController::RoutingError` instead of a json response specifying the error. Let's fix that now.

**&ndash;** Insert a **`match '*unknown_path'`** method into config/routes.rb, so that the file reads as follows:

```ruby
require './lib/api_constraints'

Rails.application.routes.draw do
  namespace :api, constraints: {format: 'json'} do
    scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
      resources :notes
      resources :contacts
    end

    scope module: :v2, constraints: ApiConstraints.new(version: 2) do
      resources :notes
      resources :contacts
    end
  end

  # Must be the last route
  match '*unknown_path', :to => 'application#routing_error', via: :all
end
```

The leading asterisk in **`'*unknown_path`'** employs the route globbing technique. If the path portion of request url is 'some/api_path.json', then params[:unknown_path] would be set to 'some/api_path.json'. Note that this match line is placed outside the **`namespace :api`** block so all unknown paths will be handled. 

An unknown path is directed to 'application#routing_error', where 'application' is interpreted as ApplicationController.

**&ndash;** Update app/controllers/application_controller.rb so that the file reads as follows:

```ruby
class ApplicationController < ActionController::API
  require './lib/error/error_handler.rb'
  include Error::ErrorHandler

  def routing_error
    raise(ActionController::RoutingError.new("No route matches [#{request.method}] #{request.path}") )
  end
end
```

routing_error() creates and raises an ActionController::RoutingError instance with info about the unknown request. This exception will be caught and processed in the Error::ErrorHandler class, which is included by ApplicationController. 

***The Error::ErrorHandler class***   
**&ndash;** Since this class resides within the Error namespace, we first create the lib/error subdirectory:
```bash
$ mkdir lib/error
```

**&ndash;** Next create lib/error/error_handler.rb as follows:  
```ruby
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
```

- The included() class method is called by every class (ApplicationController in this app) that includes the file. klass.class_eval evaluates the **`rescue_from StandardError`** method in the context of the ApplicationController class (klass). 'with: :render_error' fragment refers to the render_error method defined here.
- All errors we should catch are subclasses of StandardError, and so render_error() is called with the exception. A status code is generated based upon the error class. 
- A special case is the default handler for errors not listed, for which the status_code is set to :internal_server_error (500). We don't want to reveal internal implementation details in production, so in this case the somewhat cheeky exception message is set to "We're sorry, but something went wrong", similar to the default message rendered to a browser for a 500 error. (The actual error is provided in the development environment.)
- Finally a JSON-formatted error message and the status code are rendered.

***Exception Class to HTTP Status Code Mapping***  
The error_to_status_code() method maps the actual exception class to an HTTP status code that is to be returned in the response. We have here defined three mappings:
- ActiveRecord::RecordNotFound to :not_found (404) &ndash; Returned whenever a resource does not exist.
- ActionController::RoutingError to :unprocessable_entity (422) &ndash; Returned when a url does not map to any defined route.
- ActiveRecord::RecordInvalid to :unprocessable_entity (422) &ndash; Returned for a Active Record validation error. 
- Default to :internal_server_error (500) &ndash; Returned when an exception is raised that does not have a specific mapping. 

We have specified only a small number of potential errors that can potentially raised in a Rails API app. If you want the response status to be other than a 500 internal server error, add the exception to the case statement in error_to_status_code() with the desired HTTP status code.

Also note that this implementation can only catch errors that occur at the application level. Errors that occur at the middleware level before the app gets control still won't be caught. See the 'More Error Handling' section below for an example.

***Manual Testing With Curl***

***&mdash; Request to the version 1 api for an existing Contact record***  
```bash  
$ curl http://localhost:3000/api/contacts/1 
-->
{"contact":{"id":1,"first_name":"Abraham","last_name":"Lincoln","email":"abraham_lincoln@example.com"}}
```

***&mdash; Request to the version 1 api for a non-existant Contact record***  
```bash  
$ curl http://localhost:3000/api/contacts/3 
-->
{"error":"Couldn't find Contact with 'id'=3"}
```

***&mdash; Request for an existing Contact record to a non-existant version 3 api***  
```bash  
$ curl -H 'Accept: application/vnd.contacts.v3' http://localhost:3000/api/contacts/1 
-->
{"error":"No route matches [GET] /api/contacts/1"}
```

***&mdash; Test the internal_server_error (500) error***  
A bit of a kludge is required to manually test the internal_server_error. (This is where an automated test suite would prove helpful.) Temporarily add **`test_internal_server_error()`** as the first line of the show method of app/controllers/api/v1/contacts_controller.rb as follows:  
```ruby
  def show
    test_internal_server_error()
    render json: @contact
  end
```
Then:
```bash  
$ curl -i http://localhost:3000/api/contacts/1 
-->
{"error":"undefined method `test_internal_server_error' for 
  #\u003cApi::V1::ContactsController:0x007fef44723158\u003e"}
```
The '-i' option includes the response headers, one of which is the status line:  
  **`HTTP/1.1 500 Internal Server Error`**  
Finally, delete the **`test_internal_server_error()`** line we temporarily added to contacts_controller.rb.

_Note:_ The following line is logged in the case of errors and other situations where no JSON output is rendered:  
  **`[active_model_serializers] Rendered ActiveModel::Serializer::Null with Hash`**  
This is not an error indication, and to suppress it is more trouble than it's worth.

Now remove the "test_internal_server_error()" we just added to Api::V1::ContactsController#show.
Then perform a sixth commit with the message "Add Error Handling"


## Seventh Commit &ndash; Accessing the Api Through a Subdomain
Up to now we have been accessing the API using an "api" path component, e.g.  
  **`example.com/api/contacts/1`**  
This section implements API access through a subdomain, e.g.   
  **`api.example.com/contacts/1`**

If you're satisfied with specifying API access as an "api" path component, you can simply skip this section. However, implementing the "api" subdomain is almost trivial, since we've already done the heavy lifting when we implemented the "api/vx" directory structure Api::Vx (e.g. "api/v1" / Api::V1) above.

**&ndash;** In the config/routes.rb file, simply change the `namespace` line from:  
  **`namespace :api, constraints: {format: 'json'} do`**  
to:  
  **`namespace :api, constraints: {format: 'json', subdomain: 'api'}, path: '/' do`**

_Notes:_
- The **`subdomain: 'api'`** key/value pair in the constraints hash specifies that a subdomain rather than a path component maps to the 'Api' namespace.
- The **`path: '/'`** key/value pair specifies that the path to the controller resource indeed starts at the root (i.e. 'app/controllers/'). It is a required companion to the subdomain constraint.

**Testing a Subdomin With Curl and a Loop-Back Domain**  
Having implemented the 'api' subdomain, we are now able to access the api with a url of the form **`api.example.com/contacts/1`**. We might expect that  
```bash
$ curl http://api.localhost:3000/contacts/1
```
would work, but it instead returns  
**`{"error":"No route matches [GET] /contacts/1"}`**

The problem is that the default hostname to ip address mapping file /etc/hosts (on Linux & Mac systems) has a line **`127.0.0.1 localhost`** which maps 'localhost' to the loopback ip address `127.0.0.1`, but nothing for api.localhost. Simply adding the line **`127.0.0.1 api.localhost`** is said to work if Passenger is the standalone web server (per http://railscasts.com/episodes/221), but it seems not to work using the current default Rails 5 Puma standalone server.

Fortunately there's a simple solution that allows testing an arbitrary subdomain without any modifications to /etc/hosts. Levi Cook has registered the domain name lvh.me, which is associated with a DNS hack that simply reflects back to 127.0.0.1 on the development computer. (No non-local server is involved &ndash; The HTTP request does not leave the local workstation.) The following works as expected:

```bash
$ curl http://api.lvh.me:3000/contacts/1 
-->
{"contact":{"id":1,"first_name" : "Abraham","last_name":"Lincoln","email":"abraham_lincoln@example.com"}} 
```

The domain lvh.me is really useful for testing web apps locally. It resolves itself and all its subdomains to 127.0.0.1. So you can easily test subdomains such as xxx.lvh.me without setting up your own DNS or touching /etc/hosts.

_Note:_ The 'subdomain' parameter of the GET request is set to 'api', which the **`constraints: { subdomain: 'api' }`** term in routes.rb uses to match to **`namespace :api`**.

The GET request to retrieve all Contact records is similar:  
```bash
$ curl http://api.lvh.me:3000/contacts 
-->
{"contacts":[{"id":2,"first_name":"Herbert","last_name":"Hoover",
  "email":"herbert_hoover@example.com"},{"id":1,"first_name":"Abraham",
  "last_name":"Lincoln","email":"abraham_lincoln@example.com"}]}
```

At this time perform a seventh commit with the message "Implement 'api' subdomain".


## (Optional) Delete the Version 2 Api
We created Api Version 2 strictly in order to test Api Versioning, and we will not be further interacting with it in this tutorial. Feel free to delete it as follows:
- Delete the **`scope module: :v2`** block from config/routes.rb
- Delete the 'app/serializers/api/v2' subdirectory and its contents
- Delete the 'app/controller/api/v2' subdirectory and its contents  
However, the git repository for this tutorial code retains the version 2 API.

## Eighth Commit &ndash; Implement all API Actions
Up to now, we have worked strictly with the GET request type to retrieve a collection of resources and a specific resource through the 'index' and 'show' actions, respectively. Now we will implement the entire complement of request types and the associated controller actions: GET ('index', 'show'), POST ('create'), PATCH or PUT ('update'), and DELETE ('destroy').
Note that the 'new' and 'edit' helper actions used in a regular web application for human interaction are omitted.

Now let's update the Contacts controller app/controllers/api/v1/contacts_controller.rb to implement these actions. (We will later similarly update the Notes controller.)

### Index and Show Actions
These actions have already been implemented above.  

***Index Action &ndash; Process GET Request for a Collection***  
```bash
$ curl http://api.lvh.me:3000/contacts 
-->
{"contacts":[{"id":2,"first_name":"Herbert","last_name":"Hoover",
  "email":"herbert_hoover@example.com"},{"id":1,"first_name":"Abraham",
  "last_name":"Lincoln","email":"abraham_lincoln@example.com"}]}
```  

***Show Action &ndash; Process GET Request for a Single Resource***  
```bash
$ curl http://api.lvh.me:3000/contacts/1 
-->
{"contact":{"id":1,"first_name":"Abraham","last_name":"Lincoln",
  "email":"abraham_lincoln@example.com"}}
```
### Create Action
Replace the create method with the following:
```ruby
  def create
    contact = Contact.new(contact_params)
    render json: contact, status: :created if contact.save!
  end
```

***Create Action &ndash; Process POST Request***  
```bash
$ curl -H "Content-Type: application/json" -X POST -d '{"contact": {"first_name":"George", "last_name":"Washington", "email":"george_washington@example.com"}}' http://api.lvh.me:3000/contacts 
   -->
{"contact":{"id":3,"first_name":"George","last_name":"Washington",
  "email":"george_washington@example.com"}}
```

Some new curl syntax is required:  
**-X** (a shortcut for '--request') &ndash; The next token on the line is the request to be dispatched, here 'POST'. Note: If omitted, a GET request is generated, which is the reason why we haven't previously used it.  
**-d** (a shortcut for '--data') &ndash; The next text on the line between quote marks is added to the request.  
**-H "Content-Type: application/json"** &ndash; This header must be included in order for the request data to be recognized as JSON instead of plain text.

Other useful options:  
**-v** (a shortcut for '--verbose') &ndash; Output the request headers generated by the curl command.  
**-i** (a shortcut for '--include') &ndash; Output the response headers in addition to the response itself.  
These options are used only sparingly in this tutorial to avoid extra verbosity. But they can be added to any curl command and can be quite illuminating.

### Update Action
Replace the update method with the following:
```ruby
  def update
    @contact.update!(contact_params)
    render json: @contact, status: :ok
  end
```

***Update Action - Process PUT Request***  
```bash
$ curl -H "Content-Type: application/json" -X PUT -d '{"contact":{"last_name":"Bush", "email":"george_bush@example.com"}}' http://api.lvh.me:3000/contacts/3 
-->
{"contact":{"id":3,"first_name":"George","last_name":"Bush","email":"george_bush@example.com"}}
```

_Note:_ The Update action serves both the PUT and PATCH requests, so if "PUT" is replaced by "PATCH" in the above command, the result is identical. All fields in the request replace existing values in the record, but fields not updated by the request retain their existing values.

### Destroy Action
No change to the existing destroy method is required:
```ruby
  def destroy
    @contact.destroy
  end
```

***Destroy Action - Process DELETE Request***  
```bash
$ curl -i -X DELETE http://api.lvh.me:3000/contacts/3 
```  
Outputs a **`HTTP/1.1 204 No Content`** header, but no json output.

_Note:_ The above is a non-"idempotent" implementation of destroy(). Send a DELETE request to a resource and it is gone; send the same request to a now non-existant resource, and a "not found" response is returned:
```bash
$ curl -X DELETE http://api.lvh.me:3000/contacts/3  
-->
{"error":"Couldn't find Contact with 'id'=3"}
```

The following is an idempotent implementation, which is prefered by some:
```ruby
  def destroy
    contact = Contact.where(id: params[:id]).first
    contact.destroy if contact
  end
```
  
(Also delete **`:destroy`** in the before_action method at the top of the controller.)

No matter how many times this DELETE request is issued, the response is the same as when the resource is deleted &ndash; a :no_content (204) status code is returned. 

### Implement all API Actions in NotesContoller  
Similarly modify app/controllers/api/v1/notes_controller.rb as follows to implement all actions:

```ruby
class Api::V1::NotesController < ApplicationController
  before_action :set_note, only: [:show, :update, :destroy]

  # GET /notes
  def index
    notes = Note.order('id')
    render json: notes
  end

  # GET /notes/1
  def show
    render json: @note
  end

  # POST /notes
  def create
    note = Note.new(note_params)
    render json: note, status: :created if note.save!
  end

  # PATCH/PUT /notes/1
  def update
    @note.update!(note_params)
    render json: @note, status: :ok
  end

  # DELETE /notes/1
  def destroy
    @note.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_note
      @note = Note.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def note_params
      params.require(:note).permit(:note_date, :content, :contact_id)
    end
end
```

### Curl Commands that Exercise the Notes Controller
```bash
$ curl http://api.lvh.me:3000/notes 
--> 
{"notes":[{"id":1,"note_date":"2017-12-01T00:00:00.000Z","content":"Note to Abraham"},
  {"id":2,"note_date":"2017-12-15T00:00:00.000Z","content":"Second Note to Abraham"},
  {"id":3,"note_date":"2018-02-02T00:00:00.000Z","content":"Note to Herbert"},
  {"id":4,"note_date":"2018-02-02T00:00:00.000Z","content":"Second Note to Herbert"}]}
```

```bash
$ curl http://api.lvh.me:3000/notes/1 
-->
{"note":{"id":1,"note_date":"2017-12-01T00:00:00.000Z","content":"Note to Abraham"}}
```

```bash
$ curl -H "Content-Type: application/json" -X POST -d '{"note":{"contact_id":"1", "note_date":"2017-12-01", "content":"Third Note to Abraham"}}' http://api.lvh.me:3000/notes 
-->
{"note":{"id":5,"note_date":"2017-12-01T00:00:00.000Z","content":"Third Note to Abraham"}}
```

```bash
$ curl -H "Content-Type: application/json" -X PUT -d '{"note":{"content":"Third Note to President Lincoln"}}' http://api.lvh.me:3000/notes/5 
-->
{"note":{"id":5,"note_date":"2017-12-01T00:00:00.000Z","content":"Third Note to President Lincoln"}}
```

```bash
$ curl -i -X DELETE http://api.lvh.me:3000/notes/5 
```  
Outputs a **`HTTP/1.1 204 No Content`** header, but no json output.

***Update Contact Class for Further Action Testing***  
We added a ActiveRecord::RecordInvalid term to the case statement in error_handler.rb above. Let's now update contact.rb as follows in order to test both this and model validations:

```ruby
  class Contact < ApplicationRecord
    has_many :notes, dependent: :destroy

    validates :first_name, :last_name, presence: true
  end
```

***A DELETE Request That Also Destroys Associated Records***  
The `dependent: :destroy` option that we added to the has_many method in the Contact class will cause notes records that belong to a destroyed contacts record to also be destroyed.  
```bash
$ curl -X DELETE http://api.lvh.me:3000/contacts/2
```
Deletes the Herbert Hoover contact record. 

The SQL that implements this action (as written to the log):
```bash
  SQL (0.5ms)  DELETE FROM "notes" WHERE "notes"."id" = $1  [["id", 3]]
  SQL (0.4ms)  DELETE FROM "notes" WHERE "notes"."id" = $1  [["id", 4]]
  SQL (49.3ms)  DELETE FROM "contacts" WHERE "contacts"."id" = $1  [["id", 2]]
   (55.1ms)  COMMIT
```
   
shows that the two associated notes records are also deleted.

At this time perform a eighth commit with the message "Implement all API Actions"

## Ninth Commit &ndash; More Error Handling 
***A POST Request That Causes a Validation Failure***  
In the Error Handling section above, we implemented validation error handling. However, we were not prepared to demonstrate it until we implemented the Create action and added a validation to the Contact model. Let's test it now.  
```bash
$ curl -i -H "Content-Type: application/json" -X POST -d '{"contact":{ "last_name":"Eisenhower", "email":"dwight_eisenhower@example.com"}}' http://api.lvh.me:3000/contacts 
-->
{"error":"Validation failed: First name can't be blank"}  
```  
An **`HTTP/1.1 422 Unprocessable Entity`** header is also returned.  

This is an example of how the JSON API reports validation errors. Although validations are an important part of Rails, we won't be dealing with them further in this tutorial.

***A POST Request That Causes a Parse Failure***  
The data in the following POST request omits one of two closing braces "}" after ".com"
```bash
$ curl -i -H "Content-Type: application/json" -X POST -d '{"contact":{ "first_name":"Dwight", "last_name":"Eisenhower", "email":"dwight_eisenhower@example.com"}' http://api.lvh.me:3000/contacts 
```
The error is rendered as a voluminous HTML error message, something we thought we had fixed with the error handling code we implemented above. 
The reason is that JSON parsing is performed at the middleware level before the error handling code is activated.  
So we must add separate code at the middleware level to be able to catch a JSON parse error and render a concise error message.  
 
**&ndash;** Create a new subdirectory 'app/middleware' and create a new file catch_json_parse_errors.rb therein with these contents:  

```ruby
# from https://robots.thoughtbot.com/catching-json-parse-errors-with-custom-middleware
class CatchJsonParseErrors
  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      @app.call(env)
    rescue ActionDispatch::Http::Parameters::ParseError => error
      if env['HTTP_ACCEPT'] =~ /application\/json/ ||
          env['CONTENT_TYPE'] =~ /application\/json/
        error_output = "Malformed JSON content: #{error}"
        return [
            400, { "Content-Type" => "application/json" },
            [ { status: 400, error: error_output }.to_json ]
        ]
      else
        raise error
      end
    end
  end
end
```

Next modify 'config/application.rb' so that CatchJsonParseErrors will be invoked upon a parse error:

**&ndash;** After the line **`require_relative 'boot'`**, insert:  
**`require './app/middleware/catch_json_parse_errors'`**

**&ndash;** After the line **`config.api_only = true`**, insert:  
**`config.middleware.use CatchJsonParseErrors`**

Now we get an expected concise JSON response with a 400 Bad Request status when we issue a malformed JSON request:  
```bash
$ curl -H "Content-Type: application/json" -X POST -d '{"contact":{ "first_name":"Dwight", 
  "last_name":"Eisenhower", "email":"dwight_eisenhower@example.com"}' http://api.lvh.me:3000/contacts
-->
{"status":400,"error":"Malformed JSON content: 743: unexpected token at '{\"contact\":{ \"first_name\":\"Dwight\", 
  \"last_name\":\"Eisenhower\", \"email\":\"dwight_eisenhower@example.com\"}'"}%
```

At this time perform a ninth commit with the message "More Error Handling".

That's all for now, folks. I hope to be able to add more topics to this tutorial in the future. 

# References
The following references may be helpful.

***Comprehenive Discussions***  
https://code.tutsplus.com/articles/crafting-apis-with-rails--cms-27695  
Covers both jbuilder and active_model_serializer for generating JSON responses; User registration and restricting resources based upon a per-user token;  Cross-Origin Resource Sharing (CORS) ; Rack-Attack gem. 

http://apionrails.icalialabs.com/book/_single-page  
Very comprehensive, but based upon Rails 4. Subdomains with Pow or Prax; Git; URL Patterns; Versioning; Users with Devise; RSpec; Curl and alternatives; Authentication; Token Authorization; advanced Serialization; Pagination; Background Jobs; Caching.

***Austin Kabiru's Tutorial in Three Parts***  
https://scotch.io/tutorials/build-a-restful-json-api-with-rails-5-part-one  
Very comprehensive tutorial, with "simplified" json, rather than more complex json-api. Includes RSpec tests. Exception handler concern; json response concern. Uses HTTPie, a command line HTTP client rather than curl.

https://scotch.io/tutorials/build-a-restful-json-api-with-rails-5-part-two  
User model with secure password using bcrypt. 
Token-based authentication with JSON Web Tokens (JWT). 
User creation; Authentication token sent in HTTP header.

https://scotch.io/tutorials/build-a-restful-json-api-with-rails-5-part-three  
Versioning specified in URL; media types for Accept header; active_model_serializer; Pagination.

***Aaron Krauss' Tutorial in Five Parts***  
https://thesocietea.org/2015/02/building-a-json-api-with-rails-part-1-getting-started/  

https://thesocietea.org/2015/03/building-a-json-api-with-rails-part-2-serialization/  

https://thesocietea.org/2015/04/building-a-json-api-with-rails-part-3-authentication-strategies/  

https://thesocietea.org/2015/04/building-a-json-api-with-rails-part-4-implementing-authentication/  

https://thesocietea.org/2015/12/building-a-json-api-with-rails-part-5-afterthoughts/  
Flat vs nested routes; Cross-Origin Resource Sharing (CORS); Resource filtering, RSpec.

https://thesocietea.org/2017/02/building-a-json-api-with-rails-part-6-the-json-api-spec-pagination-and-versioning/  

***Specialized Discussions***  
http://www.thegreatcodeadventure.com/building-a-super-simple-rails-api/  
active-model-serializers; versioning; controller actions; CORS.

https://blog.codeship.com/building-a-json-api-with-rails-5/  
Based on Rails 5 release candidate &ndash; some info has changed. Includes useful active_model_serializers example; Caching; Rate Limiting; Rack::Attack. 

http://ntam.me/building-the-perfect-rails-5-api-only-app/  
Versioning; RSpec; Serializing API Output; CORS; Versioning; Rate Limiting and Throttling; Authentication; API documentation using Swagger. Has associated github project. 

https://www.nopio.com/blog/rails-api-active-model-serializers/  
With Github source code.
Serializers; Versioning; Rack-Cors; Rack-Attack; Token authentication; Authorization with Pundit.

https://learn.co/lessons/rails-5-json-api  
Discusses json-api with initializer including mime types; CORS. Advanced serializer example. Completed example:   https://github.com/learn-co-curriculum/rails-5-json-api-example-app

https://www.nopio.com/blog/rails-api-tests-rspec/  
RSpec testing.

http://guides.rubyonrails.org/api_app.html  
The official scoop on setting up a bare api-only Rails 5 app.

http://www.vinaysahni.com/best-practices-for-a-pragmatic-restful-api  
A series of short informative paragraphs on different topics. 

http://railscasts.com/episodes/350-rest-api-versioning?view=asciicast  
API versioning &ndash; The inspiration for the present tutorial's versioning schema.

https://stackoverflow.com/questions/389169/best-practices-for-api-versioning  
Discussion of different approaches to versioning.

https://www.dailydrip.com/blog/rails-002-1-setting-up-your-rails-api  
Has complete api controller example.

https://hackernoon.com/how-to-setup-and-deploy-a-rails-5-app-on-aws-beanstalk-with-postgresql-redis-and-more-88a38355f1ea  
Deploy a Rails API service on Amazon Web Services.

***JSON API***  
http://jsonapi.org/  
http://jsonapi.org/format/  
Specifies a prominent contender for the JSON api format standard.

https://blog.codeship.com/the-json-api-spec/  
Build Rails APIs Following the json:api spec. Setting mime types in initializer; Routing; Format of data posted; custom json-api RSpec matcher; error response format; Sorting Results and Pagination.

***Active Model Serializers / JBuilder***  
https://github.com/rails-api/active_model_serializers/tree/0-10-stable
Official Active Model Serializer documentation &ndash; latest stable version 0.10 as of August, 2017.

https://www.sitepoint.com/active-model-serializers-rails-and-json-oh-my/  
active-model-serializer with some advanced topics. HATEOAS; Uses 'json' adapter.

https://github.com/rails/jbuilder  
Overview of using jbuilder, the principal alternative to active_model_serializer.

https://blog.engineyard.com/2015/active-model-serializers  
Develop a rails-api app with emphasis on active-model-serializers features.

***CURL***  
https://github.com/Codingpedia/codingpedia.github.io/blob/master/_posts/2014-12-03-how-to-test-a-rest-api-from-command-line-with-curl.md  

https://gist.github.com/joyrexus/85bf6b02979d8a7b0308  
An introduction to Curl using GitHub's API as the target.

***Error Handling***  
https://rubytutorial.io/rails-rescue_from/  
Discusses the rescue_from class method.

http://blog.honeybadger.io/ruby-exception-vs-standarderror-whats-the-difference/  
Rescuing from StandardError, not Exception.


## Contact Me
Comments and/or corrections are welcome. Please contact me at **`edwin@edwinmeyer.com`**.

## Licensing
All code in the accompanying code repository is licensed under the terms of the MIT License, and any part may be freely incorporated into any software without charge or attribution.  
_Note:_ Some code segments may have other sources with different licensing terms.
  
This README text is copyright &copy; 2017-2019 Edwin Meyer Software Engineering. 
However it may be reproduced in whole or in part if the copyright legend is included.
