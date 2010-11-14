require 'rubygems'
require 'sinatra'
require 'haml'
require 'sass'
require 'datamapper'
require 'uri'

DataMapper::setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/srsly.db")

class URL 
  include DataMapper::Resource
  property :id, Serial
  property :link, String, :length => 7...512,
    :messages => {
      :length => "URL is too long! Must be less than 512 characters"
    }     
end

DataMapper::Model.raise_on_save_failure = true

DataMapper.finalize
DataMapper.auto_upgrade!

helpers do
  def to_base36(dec)
    dec.to_s.to_i.to_s(36)
  end

  def to_base10(b36) 
    b36.to_s.to_i(36).to_s
  end

  def make_link(base)    
    base = "http://" + base unless base[0..6] == "http://"
    base[6..-1]  = URI.escape(base[6..-1])
    return base
  end
end

get '/' do
  haml :index
end

get '/stylesheet.css' do 
  scss :stylesheet
end

get '/about' do 
  haml :about
end

get '/view' do
  if params[:id]
    redirect "/view/#{params[:id]}"
    return
  end
  haml :view_form
end

post '/' do
  link = params[:link].strip
  if link.size == 0
    @errors = ["URL can't be empty!"]
    redirect '/'
    return
  end
  @link = make_link(link)
  prev = URL.get(:link => @link)
  error = false
  if prev
    @id = to_base36(prev.id)
  else
    begin
      url = URL.new(:link => @link)
      url.save
    rescue Exception => e
      redirect '/'
    end
  end
  haml :created 
end

get '/:id' do
  @id = params[:id]
  @url = URL.get(to_base10(@id))
  if @url
    redirect @url.link
  else
    haml :unknown_link
  end
end

get '/view/:id' do 
  @id = params[:id]
  @url = URL.get(to_base10(@id))
  if @url
    haml :view
  else
    haml :unknown_link
  end
end
