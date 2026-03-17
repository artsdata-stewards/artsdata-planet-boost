# gem install sparql
# http://www.rubydoc.info/github/ruby-rdf/sparql/frames

require 'sparql/client'
require 'json'
require 'uri'
require_relative 'config'
require 'linkeddata'
require_relative 'fetch_organizations_service/fetch_organizations'
require_relative 'fetch_organizations_service/fetch_wikidata_organizations'
require_relative 'fetch_organizations_service/fetch_artsdata_organizations'
require_relative 'artsdata_service/artsdata'

FETCHERS = {
  'wikidata'  => FetchOrganizationsService::FetchWikidataOrganizations,
  'artsdata'  => FetchOrganizationsService::FetchArtsdataOrganizations,
}.freeze

source = ARGV.find { |arg| arg.start_with?('--source=') }
if source
  source = source.split('=', 2)[1]
else
  puts "Please provide a source with --source=SOURCE"
  exit 1
end
incremental = ARGV.include?('--incremental')
organization_uri_arg = ARGV.find { |arg| arg.start_with?('--organization_uri=') }
if organization_uri_arg
  incremental = false # override incremental if specific organization is requested
end
only_uri_to_crawl = organization_uri_arg ? organization_uri_arg.split('=', 2)[1] : nil

artsdata_service = ArtsdataService::Artsdata.new
already_existing = artsdata_service.get_already_existing_urls

already_crawled_urls = Set.new
if incremental
  metadata_file = "metadata/metadata_#{source}_spider.jsonld"
  if File.exist?(metadata_file)
    existing_metadata = RDF::Graph.load(metadata_file, format: :jsonld)
    already_crawled_urls = existing_metadata
      .query([nil, RDF::URI.new('http://schema.org/dataFeedElement'), nil])
      .objects
      .map(&:to_s)
  end
end

organizer_fetcher =
  FETCHERS.fetch(source).new(
    already_crawled_urls: already_crawled_urls,
    only_uri_to_crawl: only_uri_to_crawl,
    already_existing_urls: already_existing
  )

data = organizer_fetcher.fetch

File.write("#{source}_orgs_all.json", JSON.pretty_generate(data))

puts "Total records: #{data.size}"
