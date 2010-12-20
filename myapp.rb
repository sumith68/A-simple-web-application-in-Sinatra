require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'datamapper'
require 'dm-timestamps'

helpers do

  def protected!
    unless authorized?
      response['WWW-Authenticate'] = %(Basic realm="Testing HTTP Auth")
      throw(:halt, [401, "Not authorized\n"])
    end
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == ['admin', 'admin']
  end
end


DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/data.db") 

class Manager
  include DataMapper::Resource
  
  property :id,        Serial
  property :title,     String
  property :status,    String
  property :deadline,  String
  property :assignsto, String
end 

class Validate
  include DataMapper::Resource
 
  property :id,       Serial
  property :u_name,   String
  property :p_word,   String

end
   
DataMapper.auto_upgrade!

before do
 headers "Content-Type" => "text/html; charset=utf-8" 
end

get '/usage' do
@title="Usage"
 erb:usage, :layout => false
end 

get '/' do
 @title="welcome"
 erb:welcome
end

get '/authen_manager' do
 @title="Manager authentication"
 erb:authen_manager
end

post '/access' do
 @man_name="#{params[:m_name]}"
 @man_passwd="#{params[:pas_word]}"
 if @man_name=="admin" and @man_passwd=="admin"
    redirect("/manager_roles")
 else
    erb:not_authorized
 end
end

get '/manager_roles' do
 @title="manager roles"
 erb:manager_roles
end

get '/new_user' do
 @title="Create user"
 erb:create_user
end

post '/task' do
 @task=Validate.new
 @task.attributes={:u_name=> params[:u_name],
		:p_word=> params[:p_word] }
 if @task.save
   redirect("/manager_roles")
 end
end

get '/authen_user' do
 erb:authen_user
end

post '/user' do
 @collect=[]
 @title="user"
 @name="#{params[:u_name]}"
 @passwd="#{params[:p_word]}"
 puts @name.inspect
 puts @passwd.inspect
 id=repository(:default).adapter.query('SELECT p_word FROM validates where validates.u_name="'+@name+'" ;')
 puts id[0].inspect
 if id[0]==@passwd
      identity=repository(:default).adapter.query('SELECT id FROM managers where assignsto= "'+@name+'";' )
   for i in identity do
     @collect.push(Manager.get(i))
   end
   erb:task1
 else
     erb:not_authorized
 end
end

get '/screen_manager' do
 protected!
 @title="screen_manager"
 @id=repository(:default).adapter.query('SELECT u_name FROM validates ;') 
 erb:screen_manager
end

get '/manager' do
 protected!
 @title="manager"
 @id=repository(:default).adapter.query('SELECT u_name FROM validates ;')
 erb:manager
end

post '/create' do
  @man=Manager.new
  @man.attributes={:title=> params[:title],
		:deadline=> params[:deadline],
                :status=> params[:status],
		:assignsto=> params[:emp_name] }
 if @man.save
    erb:updated
 end
end

post '/articles' do
   @man=[]
   @check="#{params[:emp_name]}"
   puts @check.inspect
   id=repository(:default).adapter.query('SELECT id FROM managers where managers.assignsto="'+@check+'" ;')
   for i in id do
     @man.push(Manager.get(i))
   end
   if @man
       erb:article
   end
end

post '/updation' do
   @stat="#{params[:cmbstatus]}"
   @id="#{params[:h_id]}"
   st=repository(:default).adapter.query('UPDATE managers SET status="'+@stat+'" WHERE id="'+@id+'";')
   if st
      erb:updated
   end
end

