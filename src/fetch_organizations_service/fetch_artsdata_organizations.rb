module FetchOrganizationsService
  class FetchArtsdataOrganizations < FetchOrganizationsService::FetchOrganizations
    ARTSDATA_SPARQL_ENDPOINT = 'https://db.artsdata.ca/repositories/artsdata'.freeze
    ARTSDATA_SPARQL_PATH = 'sparql/artsdata_orgs_query.sparql'.freeze

    def initialize(already_crawled_urls:, already_existing_urls:, only_uri_to_crawl:, do_not_load: nil)
      super(
        already_crawled_urls: already_crawled_urls,
        already_existing_urls: already_existing_urls,
        only_uri_to_crawl: only_uri_to_crawl,
        do_not_load: do_not_load
      )
    end

    def fetch
      fetch_and_build(fetch_rows)
    end

    def fetch_rows
      artsdata_sparql = File.read(ARTSDATA_SPARQL_PATH)
      artsdata_client = SPARQL::Client.new(
        ARTSDATA_SPARQL_ENDPOINT,
        method: :get,
        headers: { 'User-Agent' => Config::GENERAL_CONFIG[:user_agent] }
      )
      artsdata_client.query(artsdata_sparql)
    end

    def fetch_and_build(rows)
      data = rows.map do |row|
        url     = row[:url].to_s
        org_uri = row[:org].to_s

        meta = {
          "file_name"      => "metadata_artsdata_spider_child_#{artifact_from_url(url)}.jsonld",
          "url"            => url,
          "artifact"       => artifact_from_url(url),
          "same_as"        => "",
          "name"           => artifact_from_url(url),
          "datafeed_uri"   => "urn:datafeed:artsdata-organizer-websites",
          "datafeed_title" => "Collection of Artsdata Organization websites",
          "artsdata_uri"   => org_uri,
          "skip_crawl"     => false
        }

        if @already_existing_urls.include?(url)
          meta['crawl_name']        = "Skipped Crawl: Website Loaded Elsewhere"
          meta['crawl_description'] = "Skipped crawl because website is already loaded by another activity. See https://github.com/artsdata-stewards/artsdata-planet-boost/blob/main/sparql/artsdata_already_existing.sparql"
          meta['skip_crawl']        = true
        end

        if @do_not_load.include?(url)
          meta['crawl_name']        = "Skipped Crawl: Do Not Load Flag"
          meta['crawl_description'] = "This website has been flagged to not be loaded. See https://github.com/artsdata-stewards/artsdata-planet-boost/blob/main/src/config.rb"
          meta['skip_crawl']        = true
        end

        meta
      end


      data = data.uniq { |d| d["url"] }

      data = data.reject do |d|
        @already_crawled_urls.include?(d["url"]) ||
          (@only_uri_to_crawl && d["artsdata_uri"] != @only_uri_to_crawl)
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