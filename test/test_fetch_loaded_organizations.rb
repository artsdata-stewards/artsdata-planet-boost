require 'minitest/autorun'
require 'set'
require_relative '../src/fetch_organizations_service/fetch_organizations'
require_relative '../src/fetch_organizations_service/fetch_loaded_organizations'

class FetchLoadedOrganizationsTest < Minitest::Test

  class StubFetchLoadedOrganizations < FetchOrganizationsService::FetchLoadedOrganizations
    def initialize(rows:, **kwargs)
      super(**kwargs)
      @stub_rows = rows
    end

    private

    def fetch_rows
      @stub_rows
    end
  end

  def make_fetcher(rows:, already_crawled_urls: Set.new)
    StubFetchLoadedOrganizations.new(
      rows: rows,
      already_crawled_urls: already_crawled_urls,
      already_existing_urls: Set.new,   # recrawl ignores this
      only_uri_to_crawl: nil
    )
  end

  def test_record_shape
    rows = [{ website: 'https://thecultch.com/' }]
    data = make_fetcher(rows: rows).fetch

    assert_equal 1, data.size
    record = data.first

    assert_equal 'metadata_recrawl_spider_child_thecultch-com.jsonld', record['file_name']
    assert_equal 'https://thecultch.com/',                              record['url']
    assert_equal 'thecultch-com',                                       record['artifact']
    assert_equal '',                                                     record['same_as']
    assert_equal 'thecultch-com',                                       record['name']
    assert_equal 'urn:datafeed:artsdata-organizer-websites-recrawl',    record['datafeed_uri']
    assert_equal 'Re-crawl of loaded Artsdata organizer websites',      record['datafeed_title']
    assert_equal '',                                                     record['artsdata_uri']
    assert_equal false,                                                  record['skip_crawl']
  end

  def test_same_as_is_always_empty
    rows = [
      { website: 'https://thecultch.com/' },
      { website: 'https://levivier.ca/fr' }
    ]
    data = make_fetcher(rows: rows).fetch

    data.each do |record|
      assert_equal '', record['same_as'],
        "Expected same_as to be empty for #{record['url']}"
      assert_equal '', record['artsdata_uri'],
        "Expected artsdata_uri to be empty for #{record['url']}"
    end
  end

  def test_skip_crawl_is_never_set
    rows = [
      { website: 'https://thecultch.com/' },
      { website: 'https://northernlightsfc.ca/' },
      { website: 'https://raagmala.ca' }
    ]
    data = make_fetcher(rows: rows).fetch

    data.each do |record|
      assert_equal false, record['skip_crawl'],
        "Expected skip_crawl to be false for #{record['url']}"
      refute record.key?('crawl_name'),
        "Expected no crawl_name for #{record['url']}"
      refute record.key?('crawl_description'),
        "Expected no crawl_description for #{record['url']}"
    end
  end

  def test_deduplicates_same_website_from_multiple_boost_graphs
    rows = [
      { website: 'https://thecultch.com/' },  # loaded from wikidata source
      { website: 'https://thecultch.com/' }   # loaded from artsdata source
    ]
    data = make_fetcher(rows: rows).fetch

    assert_equal 1, data.size,
      'Expected duplicate website URLs to be deduplicated'
    assert_equal 'https://thecultch.com/', data.first['url']
  end


  def test_artifact_strips_www_and_replaces_dots
    rows = [{ website: 'https://www.kingstongrand.ca/' }]
    data = make_fetcher(rows: rows).fetch

    assert_equal 'kingstongrand-ca', data.first['artifact']
    assert_equal 'metadata_recrawl_spider_child_kingstongrand-ca.jsonld',
                 data.first['file_name']
  end

  def test_returns_all_distinct_websites
    rows = [
      { website: 'https://thecultch.com/' },
      { website: 'https://levivier.ca/fr' },
      { website: 'https://raagmala.ca' },
      { website: 'https://calgaryphil.com' }
    ]
    data = make_fetcher(rows: rows).fetch

    assert_equal 4, data.size
    urls = data.map { |d| d['url'] }
    assert_includes urls, 'https://thecultch.com/'
    assert_includes urls, 'https://levivier.ca/fr'
    assert_includes urls, 'https://raagmala.ca'
    assert_includes urls, 'https://calgaryphil.com'
  end


  def test_incremental_has_no_effect
    rows = [
      { website: 'https://thecultch.com/' },
      { website: 'https://levivier.ca/fr' }
    ]

    already_crawled = Set.new(['https://thecultch.com/'])

    data = make_fetcher(rows: rows, already_crawled_urls: already_crawled).fetch

    assert_equal 2, data.size,
      'Expected recrawl to ignore already_crawled_urls and return all records'
  end

end