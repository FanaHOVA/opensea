require 'dotenv/load'
require 'sinatra'
require 'zip'

require './monkey_patches'
require 'byebug'

require './open_sea_wrapper'
require './etherscan_wrapper'

get '/' do
  erb :index
end

get '/contracts' do
  erb :contracts
end

post '/export' do
  os_wrapper = OpenSeaWrapper.new

  assets_csv_name = "./#{params[:address]}_assets.csv"
  collections_csv_name = "./#{params[:address]}_collections.csv"

  assets = os_wrapper.fetch_assets(params[:address], params[:number_of_items].to_i)
  assets_csv = os_wrapper.export_assets_to_csv(assets, assets_csv_name)
  
  collections = os_wrapper.fetch_collections(params[:address], params[:number_of_items].to_i)
  collections_csv = os_wrapper.export_collections_to_csv(collections, collections_csv_name)
  
  zip_file = File.new("./#{params[:address]}-exporter.zip", 'w')

  Zip::File.open(zip_file.path, Zip::File::CREATE) do |zip|
    [assets_csv_name, collections_csv_name].each { |file_name| zip.add(file_name, file_name) }
  end
  
  send_file zip_file, filename: "OpenSea Exporter #{params[:address]}.zip"
end

get '/what_did_i_use/:address' do
  contracts_interacted_with = HTTParty.post("https://api.luabase.com/run?uuid=45c563265b4c414ea1dd20e94e1d682c&address=#{params[:address]}")
                                      .parsed_response['data'].map { |r| r['to_address'] }
                                    
  @table_data = contracts_interacted_with.uniq.map do |addy| 
    { 
      name: EtherscanWrapper.new.fetch_contract_name(addy),
      address: addy,
      times_used: contracts_interacted_with.count(addy)
    }
  end 
  
  erb :display_contracts
end

post '/redirect_to_usage' do
  redirect "/what_did_i_use/#{params[:address]}"
end