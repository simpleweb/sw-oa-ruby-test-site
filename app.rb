require 'sinatra'
require 'sinatra/json'
require 'sinatra/reloader' if development?

require 'openactive'
require 'openactive/dataset'

get '/' do
  feed_types = [
    OpenActive::Dataset::FeedType::SESSION_SERIES,
  ]

  settings = OpenActive::Dataset::Settings.new(
    open_data_feed_base_url: request.base_url + "/feed/",
    dataset_site_url: request.base_url,
    dataset_discussion_url: "https://github.com/simpleweb/sw-oa-ruby-test-site",
    dataset_documentation_url: "https://developer.openactive.io/",
    dataset_languages: ["en-GB"],
    organisation_name: "Simpleweb",
    organisation_url: "https://simpleweb.co.uk/",
    organisation_legal_entity: "Simpleweb Ltd",
    organisation_plain_text_description: "Simpleweb is a purpose driven software company that specialises in new "\
                                         "technologies, product development, and human interaction.",
    organisation_logo_url: "https://simpleweb.co.uk/wp-content/uploads/2015/07/facebook-default.png",
    organisation_email: "spam@simpleweb.co.uk",
    background_image_url: "https://simpleweb.co.uk/wp-content/uploads/2017/06/IMG_8994-500x500-c-default.jpg",
    date_first_published: "2019-11-05", # remember, remember the fifth of November...
    data_feed_types: feed_types,
  )

  renderer = OpenActive::Dataset::TemplateRenderer.new(settings)

  renderer.render
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
