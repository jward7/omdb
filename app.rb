require 'sinatra'
require 'sinatra/reloader'
require 'pg' # for postgresql database
#require 'pry' not installed on desktop
require 'httparty'
require 'uri'

get '/' do
  sql = 'SELECT * FROM movie order by title;'
  #@rows = run_sql(sql)
  erb :index
  #redirect to '/' #erb :index, :layout => false
end

post '/movie' do
  url = "http://www.omdbapi.com/?s=#{params[:movie_name]}"


  #check database first. If movie exist then fetch from database else fetch from omdb
  db = PG.connect(:host=> 'localhost', :user => 'postgres', :password => 'drexler69', :dbname => 'omdb')
  rows = db.exec("SELECT * FROM movies WHERE Title = '#{params[:movie_name]}'")

  if rows.count > 0 # movie exists in database
    @result = rows.first
    @source = 'local database'
  else # fetch from OMDB
    raw_result = HTTParty.get(URI.escape(url))
    @source = 'OMDb'

    @result = {}
    raw_result.each do |key, value|
      @result[key.downcase] = value
    end

    @title_year = @result['search'].collect {|x| "#{x['Title']}, #{x['Year']}"}
    # save to database
    #sql = "INSERT INTO movies (Title, Year, Poster) VALUES ('#{ @result['title'] }', '#{ @result['year'] }', '#{ @result['poster'] }');"
    #db.exec(sql)
  end

  db.close
  erb :movie
end

get '/about' do
  erb :about
end

def run_sql(sql)
  #db = PG.connect(:dbname => 'omdb')
  db = PG.connect(:host=> 'localhost', :user => 'postgres', :password => 'drexler69', :dbname => 'omdb')
  @rows = db.exec(sql)
  db.close
  return rows
end

