module FetchOrganizationsService
  class FetchOrganizations
    def initialize(already_crawled_urls:, already_existing_urls:, only_uri_to_crawl:, do_not_load: nil)
      @already_crawled_urls = already_crawled_urls
      @already_existing_urls = already_existing_urls
      @only_uri_to_crawl = only_uri_to_crawl
      @do_not_load =
        (do_not_load || Config::GENERAL_CONFIG[:do_not_load_websites]).to_set
    end
    def fetch
      raise NotImplementedError, 'Subclasses must implement fetch'
    end
  end
end