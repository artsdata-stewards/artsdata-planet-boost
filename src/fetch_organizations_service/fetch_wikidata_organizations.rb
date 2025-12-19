module FetchOrganizationsService
  class FetchWikidataOrganizations < FetchOrganizationsService::FetchOrganizations
    WIKIDATA_SPARQL_ENDPOINT = 'https://query.wikidata.org/sparql'.freeze
    WIKIDATA_SPARQL_PATH = 'sparql/wikidata_query.sparql'.freeze

    def initialize(already_existing:, only_uri_to_crawl:, do_not_load: nil)
      super(
        already_existing: already_existing, 
        only_uri_to_crawl: only_uri_to_crawl, 
        do_not_load: do_not_load
      )
    end
    
    def fetch
      wikidata_sparql = File.read(WIKIDATA_SPARQL_PATH)

      wikidata_client = SPARQL::Client.new(
        WIKIDATA_SPARQL_ENDPOINT,
        method: :get,
        headers: { 'User-Agent' => Config::GENERAL_CONFIG[:user_agent] }
      )

      rows = wikidata_client.query(wikidata_sparql)

      data = rows.map do |row|
        url = row[:url].to_s
        meta = {
          "file_name" => "metadata_wikidata_spider_child_#{artifact_from_url(url)}.jsonld",
          "url" => url,
          "artifact" => artifact_from_url(url),
          "same_as" => row[:org].to_s,
          "name" => row[:orgLabel].to_s,
          "datafeed_uri" => "urn:datafeed:wikidata-presenter-websites",
          "datafeed_title" => "Collection of Wikidata presenter websites",
          "artsdata_uri" => "http://kg.artsdata.ca/resource/#{row[:artsdataID].to_s}"
        }
        meta['skip_crawl'] = false
        if @already_existing.include?(url)
          meta['crawl_name'] = "Skipped Crawl: Website Loaded Elsewhere"
          meta['crawl_description'] = "Skipped crawl because website is already loaded by another activity. See https://github.com/artsdata-stewards/artsdata-planet-boost/blob/main/sparql/artsdata_already_existing.sparql"
          meta['skip_crawl'] = true
        end

        if @do_not_load.include?(url)
          meta['crawl_name'] = "Skipped Crawl: Do Not Load Flag"
          meta['crawl_description'] = "This website has been flagged to not be loaded. See https://github.com/artsdata-stewards/artsdata-planet-boost/blob/main/src/config.rb"
          meta['skip_crawl'] = true
        end
        meta
      end
      data = data.uniq { |d| d["url"] }
      data = data.uniq { |d| d["same_as"] }
      data = data.reject do |d|
        if @already_existing.include?(d["url"]) || (d["same_as"] != @only_uri_to_crawl && @only_uri_to_crawl)
          true
        else
          false
        end
      end
      data
    end

    private
    def artifact_from_url(url)
      host = URI.parse(url).host rescue nil
      return nil unless host
      host = host.sub(/^www\./, '')
      host.gsub('.', '-')
    end
  end
end