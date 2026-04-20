module FetchOrganizationsService
  class FetchListOrganizations < FetchOrganizationsService::FetchOrganizations
    LIST_PATH = 'recrawl_list.txt'.freeze

    def initialize(already_crawled_urls:, already_existing_urls:, only_uri_to_crawl:, do_not_load: nil)
      super(
        already_crawled_urls: already_crawled_urls,
        already_existing_urls: already_existing_urls,
        only_uri_to_crawl: only_uri_to_crawl,
        do_not_load: do_not_load
      )
    end

    def fetch
      urls = File.readlines(LIST_PATH, chomp: true)
                 .map(&:strip)
                 .reject { |line| line.empty? || line.start_with?('#') }

      data = urls.map do |url|
        {
          "file_name"      => "metadata_list_spider_child_#{artifact_from_url(url)}.jsonld",
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