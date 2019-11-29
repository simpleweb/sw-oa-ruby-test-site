require 'sinatra'
require 'sinatra/json'
require "sinatra/reloader" if development?

get '/' do
  "Hello World!"
end

get '/feed/session-series/' do
  # base_url = ???
  change_number = params['afterChangeNumber'] || 0
  per_page = 3

  page_items_data = data_for_page(change_number, per_page)

  json page_items_data
end

private

def data_for_page(change_number, per_page)
  all_data
end


def all_data
  return {hello: 'world'}
  JSON.parse(
    File.read(
      File.join(__dir__, 'session-series-feed-items.json')
    )
  )
end
