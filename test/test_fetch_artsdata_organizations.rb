require 'logger'
require 'minitest/autorun'
require 'ostruct'
require 'uri'
require 'set'


module Config
  GENERAL_CONFIG = {
    user_agent: 'test-agent',
    do_not_load_websites: []
  }.freeze
end

module FetchOrganizationsService
  class FetchOrganizations
    def initialize(already_crawled_urls:, already_existing_urls:, only_uri_to_crawl:, do_not_load: nil)
      @already_crawled_urls  = already_crawled_urls
      @already_existing_urls = already_existing_urls
      @only_uri_to_crawl     = only_uri_to_crawl
      @do_not_load           = (do_not_load || Config::GENERAL_CONFIG[:do_not_load_websites]).to_set
    end

    def fetch
      raise NotImplementedError
    end
  end
end

require_relative '../src/fetch_organizations_service/fetch_artsdata_organizations'

ROW_A = OpenStruct.new(
  org: OpenStruct.new(to_s: 'http://kg.artsdata.ca/resource/K10-184'),
  url: OpenStruct.new(to_s: 'http://laubergine.qc.ca/en/')
)

ROW_B = OpenStruct.new(
  org: OpenStruct.new(to_s: 'http://kg.artsdata.ca/resource/K10-29'),
  url: OpenStruct.new(to_s: 'https://canadasballetjorgen.ca')
)

ROW_A_DUPLICATE = OpenStruct.new(
  org: OpenStruct.new(to_s: 'http://kg.artsdata.ca/resource/K10-999'),
  url: OpenStruct.new(to_s: 'http://laubergine.qc.ca/en/') 
)

class FetchArtsdataOrganizationsTest < Minitest::Test

  def build_fetcher_with_rows(rows,
                               already_existing_urls: Set.new,
                               already_crawled_urls: Set.new,
                               only_uri_to_crawl: nil)
    fetcher = FetchOrganizationsService::FetchArtsdataOrganizations.new(
      already_crawled_urls:  already_crawled_urls,
      already_existing_urls: already_existing_urls,
      only_uri_to_crawl:     only_uri_to_crawl
    )
    # Stub the SPARQL call so tests run offline
    fetcher.define_singleton_method(:fetch_rows) { rows }
    fetcher
  end

  def test_duplicate_urls_produce_single_record
    fetcher = build_fetcher_with_rows([ROW_A, ROW_A_DUPLICATE])
    data = fetcher.fetch_and_build(fetcher.fetch_rows)

    urls = data.map { |d| d["url"] }
    assert_equal 1, urls.count('http://laubergine.qc.ca/en/'),
      "Expected exactly one record for a duplicated URL"
  end

  def test_already_existing_url_is_skipped
    fetcher = build_fetcher_with_rows(
      [ROW_A, ROW_B],
      already_existing_urls: Set.new(['http://laubergine.qc.ca/en/'])
    )
    data = fetcher.fetch_and_build(fetcher.fetch_rows)

    laubergine = data.find { |d| d["url"] == 'http://laubergine.qc.ca/en/' }
    ballet      = data.find { |d| d["url"] == 'https://canadasballetjorgen.ca' }

    assert laubergine['skip_crawl'],  "Expected skip_crawl true for already-existing URL"
    refute ballet['skip_crawl'],      "Expected skip_crawl false for non-existing URL"
  end

  # only_uri_to_crawl filter
  def test_only_uri_to_crawl_filters_other_orgs
    fetcher = build_fetcher_with_rows(
      [ROW_A, ROW_B],
      only_uri_to_crawl: 'http://kg.artsdata.ca/resource/K10-29'
    )
    data = fetcher.fetch_and_build(fetcher.fetch_rows)

    assert_equal 1, data.size, "Expected only one org when only_uri_to_crawl is set"
    assert_equal 'http://kg.artsdata.ca/resource/K10-29', data.first["artsdata_uri"]
  end

end