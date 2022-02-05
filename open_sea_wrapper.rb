require 'csv'
require 'httparty'

class OpenSeaWrapper
  attr_accessor :collections_by_items_owned, :collections_by_number_of_owners, :addresses_looked_at

  OPENSEA_PAGE_SIZE = 50.freeze

  def initialize
    @collections_by_items_owned = {}
    @collections_by_number_of_owners = {}
    @addresses_looked_at = []
  end

  def fetch_assets(address, number_of_items = 50)
    pages = [(number_of_items.to_f / OPENSEA_PAGE_SIZE).ceil, 1].max

    items = []

    pages.times do |page_number|
      query = {
        limit: OPENSEA_PAGE_SIZE,
        owner: address,
        offset: page_number * OPENSEA_PAGE_SIZE # page_number is 0 indexed
      }

      res = HTTParty.get("https://api.opensea.io/api/v1/assets?#{URI.encode_www_form(query)}").parsed_response['assets']
      items << res
    end

    items.flatten.uniq
  rescue => e
    puts e
    return []
  end

  def fetch_collections(address, number_of_items = 50)
    pages = [(number_of_items.to_f / OPENSEA_PAGE_SIZE).ceil, 1].max

    items = []

    pages.times do |page_number|
      query = {
        limit: OPENSEA_PAGE_SIZE,
        asset_owner: address,
        offset: page_number * OPENSEA_PAGE_SIZE # page_number is 0 indexed
      }

      res = HTTParty.get("https://api.opensea.io/api/v1/collections?#{URI.encode_www_form(query)}").parsed_response
      items << res
    end

    items.flatten.uniq
  rescue => e
    puts e
    return
  end

  def fetch_orders(address)
    addresses_looked_at << address

    query = {
      bundled: false,
      include_bundled: false,
      include_invalid: false,
      limit: 50,
      offset: 0,
      order_by: 'created_date',
      order_direction: 'desc',
      maker: address
    }

    orders = HTTParty.get("https://api.opensea.io/wyvern/v1/orders?#{URI.encode_www_form(query)}")

    collections_owned = orders.parsed_response['orders'].map { |o| o['asset']['collection']['name'] }

    accounted_for = {}

    collections_owned.each do |collection|
      collections_by_number_of_owners[collection] ||= 0
      collections_by_number_of_owners[collection] += 1 unless accounted_for[collection]
      accounted_for[collection] = true

      collections_by_items_owned[collection] ||= 0
      collections_by_items_owned[collection] += 1
    end
  rescue => e
    puts e
    return
  end

  def show_assets_ownership_stats(data)
    first_bought = {}
  
    collections = data.each do |item| 
      date_bought = item.dig('last_sale', 'event_timestamp')
  
      unless date_bought.nil?
        first_bought[item['collection']['name']] ||= date_bought
  
        if first_bought[item['collection']['name']] > date_bought
          first_bought[item['collection']['name']] = date_bought
        end
      end
    end
  
    puts first_bought.sort_by { |_, v| -v }.to_h
  
    puts data.map { |i| i['collection']['name'] }.count_of_each
  end

  def export_assets_to_csv(data, file_name)
    # We want to take all the potential attributes here, so we loop the whole array
    clean_keys = data.each.map do |asset|
      asset.map do |attribute, value|
        value.is_a?(Hash) ? 
          value.keys.map { |attribute_value| "#{attribute}__#{attribute_value}" } : 
          attribute
      end.flatten
    end.flatten.uniq
  
    CSV.open(file_name, 'w') do |csv|
      csv << clean_keys
  
      data.each do |asset|
        csv << clean_keys.map do |key|
          puts key
          if key.include?('__')
            attribute, sub_attribute = key.split('__')
            asset.dig(attribute, sub_attribute)
          else
            asset[key]
          end
        end
      end
    end
  rescue => e
    puts e.message
    return
  end
  
  def export_collections_to_csv(data, file_name)
    # We want to take all the potential attributes here, so we loop the whole array
    clean_keys = data.each.map do |asset|
      asset.map do |attribute, value|
        value.is_a?(Hash) ? 
          value.keys.map { |attribute_value| "#{attribute}__#{attribute_value}" } : 
          attribute
      end.flatten
    end.flatten.uniq
  
    CSV.open(file_name, 'w') do |csv|
      csv << clean_keys
  
      data.each do |asset|
        csv << clean_keys.map do |key|
          value_to_store = if key.include?('__')
            attribute, sub_attribute = key.split('__')
            asset.dig(attribute, sub_attribute)
          else
            asset[key]
          end
  
          value_to_store.to_s
        end
      end
    end
  end

  def mass_import
    CSV.parse(File.read('./seeding_database.csv').scrub, headers: true).each_with_index do |data_row, _|
      fetch_nfts(data_row['Address'])
    end
  end
end