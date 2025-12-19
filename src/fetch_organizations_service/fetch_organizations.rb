module FetchOrganizationsService
  class FetchOrganizations
    def initialize(already_existing:,only_uri_to_crawl:, do_not_load: nil)
      @already_existing = already_existing
      @only_uri_to_crawl = only_uri_to_crawl
      @do_not_load =
        (do_not_load || Config::GENERAL_CONFIG[:do_not_load_websites]).to_set
    end
    def fetch
      raise NotImplementedError, 'Subclasses must implement fetch'
    end
  end
end