require 'faker'

FEED_KIND = "SessionSeries"

def generate_session_series(id)
  {
    "@context": [
      "https://openactive.io/",
      "https://openactive.io/ns-beta"
    ],
    type: FEED_KIND,
    id: "https://example.com/session-series##{id}",
    url: "https://example.com/session-series##{id}",
    name: Faker::Company.industry,
    startDate: Faker::Time.between(from: Time.mktime(2019,12,6), to: Time.mktime(2019,12,7)).iso8601,
    endDate: Faker::Time.between(from: Time.mktime(2019,12,7), to: Time.mktime(2019,12,8)).iso8601,
    duration: "PT1H30M",
    location: {
      type: "Place",
      id: "https://example.com/place###{Faker::Alphanumeric.alpha(number: 10)}",
      name: Faker::Company.name,
      address: {
        type: "PostalAddress",
        streetAddress: Faker::Address.street_address,
        addressLocality: Faker::Address.street_name,
        addressRegion: Faker::Address.city,
        postalCode: Faker::Address.postcode,
        addressCountry: Faker::Address.country_code,
      }
    },
    activity: [
      {
        type: "Concept",
        id: "https://example.com/activity-list##{Faker::Alphanumeric.alpha(number: 10)}",
        inScheme: "https://openactive.io/activity-list",
        prefLabel: Faker::Esport.game,
      },
    ],
    eventSchedule: [
      {
        type: "PartialSchedule",
        repeatFrequency: "P7D",
        startTime: "20:15:00",
        endTime: "20:45:00",
        byDay: [
          "https://schema.org/Monday",
          "https://schema.org/Wednesday",
          "https://schema.org/Friday",
        ],
      },
    ],
    organizer: {
      type: "Organization",
      id: "https://example.com/organization##{Faker::Alphanumeric.alpha(number: 10)}",
      name: Faker::Company.name,
    },
    offers: [
      {
        type: "Offer",
        id: "https://example.com/offer##{Faker::Alphanumeric.alpha(number: 10)}",
        price: Faker::Number.between(from: 1, to: 100),
        price_currency: Faker::Currency.code,
      },
      {
        type: "Offer",
        id: "https://example.com/offer##{Faker::Alphanumeric.alpha(number: 10)}",
        price: Faker::Number.between(from: 200, to: 500),
        price_currency: Faker::Currency.code,
      },
    ],
  }
end

items = 5.times.map do |i|
  id = (i+1).to_s
  modified = Time.mktime(2019,11,6).to_i + i*60
  item = {
    id: id,
    modified: modified,
    kind: FEED_KIND,
  }

  # mark 1 in 10 as deleted
  if i % 10 == 2
    item[:state] = "deleted"
  else
    item[:state] = "updated"
    item[:data] = generate_session_series(id)
  end

  item
end

puts items.to_json
