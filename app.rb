require 'sinatra'
require 'sinatra/json'
require 'sinatra/reloader' if development?

require 'openactive'

get '/' do
  "Hello World! #{request.base_url}/feed/session-series for a feed"
end

disable :strict_paths

get '/feed/session-series' do
  base_url = request.base_url+request.path
  change_number = params['afterChangeNumber'].to_i || 0
  per_page = 3

  page_items_data = data_for_page(change_number, per_page).map do |raw_item|
    if raw_item.has_key?('data')
      raw_item['data'] = OpenActive::Models::SessionSeries.deserialize(JSON.dump(raw_item['data']))
    end

    raw_item
  end

  page_items = page_items_data.map do |raw_item|
    args = {
      Id:  raw_item["id"],
      State: raw_item["state"],
      Kind: raw_item["kind"],
      Modified: raw_item["modified"],
    }
    args[:Data] = raw_item["data"] if args[:State] == "updated"

    OpenActive::Rpde::RpdeItem.new(**args)
  end

  # page = RpdeBody::createFromNextChangeNumber($baseUrl, $changeNumber, pageItems);

  page = OpenActive::Rpde::RpdeBody.create_from_next_change_number(
    base_url, change_number, page_items)

  json page
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
