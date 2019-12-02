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
      raw_item['data'] = build_session_series(raw_item['data'])
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

def build_session_series(data)
  address = OpenActive::Models::PostalAddress.new(
    street_address: data['location']['address']['streetAddress'],
    address_locality: data['location']['address']['addressLocality'],
    address_region: data['location']['address']['addressRegion'],
    postal_code: data['location']['address']['postalCode'],
    address_country: data['location']['address']['addressCountry'],
  )
  location = OpenActive::Models::Place.new(
    id: data['location']['id'],
    name: data['location']['name'],
    address: address,
  )
  activities = data['activity'].map do |activity_data|
    OpenActive::Models::Concept.new(
      id: activity_data['id'],
      in_scheme: activity_data['inScheme'],
      pref_label: activity_data['prefLabel']
    )
  end
  event_schedule = data['eventSchedule'].map do |event_schedule_data|
    OpenActive::Models::PartialSchedule.new(
      repeat_frequency: event_schedule_data['repeatFrequency'],
      start_time: event_schedule_data['startTime'],
      end_time: event_schedule_data['endTime'],
      by_day: event_schedule_data['byDay'],
      # by_day: event_schedule_data['byDay'].map { |d| DayOfWeek.find_by_value(d) },
    )
  end
  organizer = OpenActive::Models::Organization.new(
    id: data['organizer']['id'],
    name: data['organizer']['name'],
  )
  offers = data['offers'].map do |offer_data|
    puts offer_data
    OpenActive::Models::Offer.new(
      id: offer_data['id'],
      price: offer_data['price'],
      price_currency: offer_data['price_currency'],
    )
  end

  OpenActive::Models::SessionSeries.new(
    name: data['name'],
    start_date: data['startDate'],
    end_date: data['endDate'],
    duration: data['duration'],
    location: location,
    activity: activities,
    event_schedule: event_schedule,
    organizer: organizer,
    offers: offers,
  )
end

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
