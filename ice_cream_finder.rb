require 'addressable/uri'
require 'rest-client'
require 'json'
require_relative 'api_key.rb'
require 'nokogiri'

class IceCreamFinder
  attr_accessor :lat_lng, :ice_cream_places

  def self.run(address)
    ice = self.new(address)
    places = ice.get_ice_cream_places
    directions = ice.get_all_directions
    ice.display(places, directions)
  end

  def initialize(address)
    start = formulate_geocode_search(address)
    @lat_lng = geocode_address(start)
  end

  def display(places, directions)
    places.each_with_index do |place, i|
      puts place.join(" | ")
      directions[i][-1] = directions[i][-1].sub(/Destination/, "\nDestination")
      puts directions[i]
      puts "\n ************ \n\n"
    end

  end

  def get_ice_cream_places
    @ice_cream_places = parse_place(RestClient.get(formulate_place_search))
  end

  def formulate_geocode_search(address)
    Addressable::URI.new(
      :scheme => "https",
      :host => "maps.googleapis.com",
      :path => "maps/api/geocode/json",
      :query_values => {:address => address,
                        :sensor => false}).to_s
  end

  def geocode_address(start)
    parse_geocode(RestClient.get(start))
  end

  def parse_geocode(json)
    hash = JSON.parse(json)
    location = hash["results"][0]["geometry"]["location"]
    "#{location["lat"]},#{location["lng"]}"
  end

  def formulate_place_search
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

  def parse_place(json)
    hash = JSON.parse(json)
    hash["results"].map do |place_hash|
      [place_hash["name"],
      place_hash["vicinity"],
      place_hash["rating"]]
    end
  end

  def formulate_directions_search(ice_cream_address)
    Addressable::URI.new(
      :scheme => "https",
      :host => "maps.googleapis.com",
      :path => "maps/api/directions/json",
      :query_values => {:origin => @lat_lng,
                        :destination => ice_cream_address,
                        :sensor => false,
                        :mode => "walking",
                        }).to_s
  end

  def get_all_directions
    @ice_cream_places.map do |place|
      begin
        directions(place[1])
      rescue
        retry
      end
    end
  end

  def directions(destination)
    parse_directions(RestClient.get(formulate_directions_search(destination)))
  end

  def parse_directions(json)
    hash = JSON.parse(json)
    hash["routes"][0]["legs"][0]["steps"].map do |step|
      Nokogiri::HTML(step["html_instructions"]).text
    end
  end
end

#Sample irb call:
#load 'ice_cream_finder.rb'; IceCreamFinder.run("770 Broadway")