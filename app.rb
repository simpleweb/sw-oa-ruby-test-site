require 'sinatra'
require 'sinatra/json'
require 'sinatra/reloader' if development?

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
    .select { |item| item["modified"] > change_number }
    .sort do |item1, item2|
      if item1["modified"] == item2["modified"]
        item1["id"] <=> item2["id"]
      else
        item1["modified"] <=> item2["modified"]
      end
    end
    .take(per_page)
end

def all_data
  JSON.parse(
    File.read(
      File.join(__dir__, 'session-series-feed-items.json')
    )
  )
end
