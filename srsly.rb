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
  property :link, String
end

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
  @link = make_link(params[:link])
  prev = URL.first(:link => @link)
  if prev
    @id = to_base36 prev.id
  else
    url = URL.new :link => @link
    url.save!
    @id = to_base36 url.id
  end
  
  haml :created 
end

get '/:id' do
  @id = params[:id]
  @url = URL.get(@id)
  if @url
    redirect @url.link
  else
    haml :unknown_link
  end
end

get '/view/:id' do 
  @url = URL.get(to_base10(params[:id]).to_i)
  @id = params[:id]
  if @url
    haml :view
  else
    haml :unknown_link
  end
end
