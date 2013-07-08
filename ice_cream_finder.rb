require 'addressable/uri'
require 'rest-client'
require 'json'
require_relative 'api_key.rb'

class IceCreamFinder
  attr_accessor :lat_lng, :ice_cream_places

  def initialize(address)
    start =
    Addressable::URI.new(
      :scheme => "https",
      :host => "maps.googleapis.com",
      :path => "maps/api/geocode/json",
      :query_values => {:address => address,
                        :sensor => false}).to_s

    @lat_lng = geocode_address(start)
  end

  def get_ice_cream_places
    @ice_cream_places = parse_place(RestClient.get(formulate_search))
  end

  def parse_place(json)
    hash = JSON.parse(json)
    puts hash
    hash["results"].map do |place_hash|
      [place_hash["name"],
      place_hash["vicinity"],
      place_hash["rating"]]
    end
  end

  def formulate_search
    Addressable::URI.new(
      :scheme => "https",
      :host => "maps.googleapis.com",
      :path => "maps/api/place/nearbysearch/json",
      :query_values => {:key => API::KEY,
                        :location => @lat_lng,
                        :sensor => false,
                        :keyword => "ice cream",
                        :rankby => "distance"}).to_s
  end

  def geocode_address(start)
    parse_geocode(RestClient.get(start))
  end

  def parse_geocode(json)
    hash = JSON.parse(json)
    location = hash["results"][0]["geometry"]["location"]
    "#{location["lat"]},#{location["lng"]}"
  end


end