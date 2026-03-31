module FetchOrganizationsService
  class FetchLoadedOrganizations < FetchOrganizationsService::FetchOrganizations
    ARTSDATA_SPARQL_ENDPOINT = 'https://db.artsdata.ca/repositories/artsdata'.freeze
    ARTSDATA_SPARQL_PATH     = 'sparql/artsdata_loaded_orgs_query.sparql'.freeze

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
      client = SPARQL::Client.new(
        ARTSDATA_SPARQL_ENDPOINT,
        method: :get,
        headers: { 'User-Agent' => Config::GENERAL_CONFIG[:user_agent] }
      )
      client.query(File.read(ARTSDATA_SPARQL_PATH))
    end

    def fetch_and_build(rows)
      data = rows.map do |row|
        url = row[:website].to_s

        {
          "file_name"      => "metadata_recrawl_spider_child_#{artifact_from_url(url)}.jsonld",
          "url"            => url,
          "artifact"       => artifact_from_url(url),
          "same_as"        => "",
          "name"           => artifact_from_url(url),
          "datafeed_uri"   => "urn:datafeed:artsdata-organizer-websites-recrawl",
          "datafeed_title" => "Re-crawl of loaded Artsdata organizer websites",
          "artsdata_uri"   => "",
          "skip_crawl"     => false
        }
      end

      # Deduplicate by URL — multiple boost_graph entries may share the same website
      data.uniq { |d| d["url"] }
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