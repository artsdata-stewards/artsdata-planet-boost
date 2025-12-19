module ArtsdataService
  class Artsdata
    ARTSDATA_SPARQL_ENDPOINT = 'https://db.artsdata.ca/repositories/artsdata'.freeze
    ARTSDATA_SPARQL_PATH = 'sparql/artsdata_already_existing.sparql'.freeze

    def get_already_existing_urls
      uri = URI(ARTSDATA_SPARQL_ENDPOINT)
      artsdata_sparql = File.read(ARTSDATA_SPARQL_PATH)
      response = Net::HTTP.post_form(uri, { "query" => artsdata_sparql })
      response.body.lines[1..].map(&:chomp).to_set
    end
  end
end