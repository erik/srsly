require 'rubygems'
require 'sinatra'
require 'sass'

get '/' do
  haml :index
end

get '/stylesheet.css' do 
  scss :stylesheet
end
