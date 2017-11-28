class Legacy::Server
  def self.url_for(resource_name:, action:)
    URI.join(self.host, ENDPOINTS[resource_name][action]).to_s
  end

  def self.get(path)
    url = URI::join(host, path).to_s
    get_json url
  end

  def self.headers
    { Authorization: ENV.fetch('LEGACY_API_KEY') }
  end

  private

  def self.host
    ENV.fetch('LEGACY_HOST')
  end

  def self.get_json(url)
    response = RestClient.get url
    return JSON.parse(response.body)
  rescue RestClient::ExceptionWithResponse
    Raven.capture_exception "Failed to make the request to #{url}"
    return nil
  end
end
