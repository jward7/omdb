require 'sinatra'
require 'sinatra/reloader'
require 'pg' # for postgresql database
require 'pry'
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
  db = PG.connect(:host=> 'localhost', :user => 'postgres', :password => 'postgres', :dbname => 'omdb')
  rows = db.exec("SELECT * FROM movies WHERE Title = '#{params[:movie_name]}'")

  if rows.count > 0 # movie exists in database
    @result = rows.first
    @multi = @result
    #raise 'found in database'
    @source = 'local database'
  else # fetch from OMDB
    raw_result = HTTParty.get(URI.escape(url)) # ("http://www.omdbapi.com/?t=rocky&y=&plot=short&r=json")
    @source = 'OMDb'
    @url = url

    @multi = @result
    @result = {}
    raw_result.each do |key, value|
      @result[key.downcase] = value
    end
    # save to database
    sql = "INSERT INTO movies (Title, Year, Poster) VALUES ('#{ @result['title'] }', '#{ @result['year'] }', '#{ @result['poster'] }');"
    db.exec(sql)
  end

  db.close
  erb :json_view
end

get '/movies/new' do
  erb :new
end

get '/movies/:id/edit' do
  sql = "SELECT * FROM movies WHERE id = #{params[:id]}"
  rows = run_sql(sql)
  @movie = rows[0]
  erb :edit
end

=begin
#create new movie
post '/movies' do
  #binding.pry
  sql = "INSERT INTO movies (title,image,url) VALUES ('#{params['title']}', '#{params['image_url']}')"

  run_sql(sql)
  redirect to '/'
end
=end

#update existing movie
=begin
post '/movies/:id' do

  sql = "UPDATE movies SET name='#{params[:name]}', image_url='#{params[:image_url]}' WHERE id = #{params[:id]};"
  run_sql(sql)
  redirect to '/'
end

get 'movies/:id/delete' do
  sql = "DELETE from movies WHERE id = #{params[:id]}"

  run_sql(sql)
  redirect to '/'
end
=end

get '/search' do
  erb :search
end

post '/search' do
  # need to formulate the link below
  # handle if title has spaces
  title_plus = params[:'title'].tr(" ","+")
  construct_search_url = "http://www.omdbapi.com/?t=#{title_plus}&plot=short&r=json"
  construct_search_url = URI.escape(construct_search_url)
  @omdb_movie_search = HTTParty.get construct_search_url # ("http://www.omdbapi.com/?t=rocky&y=&plot=short&r=json")
  #redirect to '/search'
  @p = title_plus
  erb :movie
end

get '/about' do
  erb :about
end

def run_sql(sql)
  #db = PG.connect(:dbname => 'omdb')
  db = PG.connect(:host=> 'localhost', :user => 'postgres', :password => 'postgres', :dbname => 'omdb')
  @rows = db.exec(sql)
  db.close
  return rows
end

