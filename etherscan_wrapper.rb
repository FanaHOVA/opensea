require 'httparty'

class EtherscanWrapper
  ETHERSCAN_API_ENDPOINT = 'https://api.etherscan.io/api'

  def initialize
  end

  def fetch_contract_name(contract_address)
    query = {
      module: 'contract',
      action: 'getsourcecode',
      address: contract_address,
      apikey: ENV.fetch('ETHERSCAN_API_KEY')
    }

    res = HTTParty.get("#{ETHERSCAN_API_ENDPOINT}?#{URI.encode_www_form(query)}").parsed_response
    
    puts res

    return unless res['message'] == 'OK'

    puts res['result']

    res['result'].first['ContractName']
  end
end