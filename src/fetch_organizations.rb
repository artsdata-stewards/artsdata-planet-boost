# gem install sparql
# http://www.rubydoc.info/github/ruby-rdf/sparql/frames

require 'sparql/client'
require 'json'
require 'uri'
require_relative 'config'
require 'linkeddata'

incremental = ARGV.include?('--incremental')
organization_uri_arg = ARGV.find { |arg| arg.start_with?('--organization_uri=') }
if organization_uri_arg
  incremental = false # override incremental if specific organization is requested
end
only_uri_to_crawl = organization_uri_arg ? organization_uri_arg.split('=', 2)[1] : nil

wikidata_endpoint = Config::WIKIDATA_CONFIG[:wikidata_endpoint]
wikidata_sparql = File.read(Config::WIKIDATA_CONFIG[:wikidata_sparql])

wikidata_client = SPARQL::Client.new(
  wikidata_endpoint,
  method: :get,
  headers: { 'User-Agent' => Config::GENERAL_CONFIG[:user_agent] }
)

rows = wikidata_client.query(wikidata_sparql)

uri = URI(Config::WIKIDATA_CONFIG[:artsdata_endpoint])
artsdata_sparql = File.read(Config::WIKIDATA_CONFIG[:artsdata_sparql])
response = Net::HTTP.post_form(uri, { "query" => artsdata_sparql })
already_existing = response.body.lines[1..].map(&:chomp).to_set

already_crawled_urls = Set.new
if incremental
  metadata_file = 'metadata/metadata_wikidata_spider.jsonld'
  if File.exist?(metadata_file)
    existing_metadata = RDF::Graph.load(metadata_file, format: :jsonld)
    already_crawled_urls = existing_metadata
      .query([nil, RDF::URI.new('http://schema.org/dataFeedElement'), nil])
      .objects
      .map(&:to_s)
  end
end

do_not_load = Config::WIKIDATA_CONFIG[:do_not_load_websites].to_set

def artifact_from_url(url)
  host = URI.parse(url).host rescue nil
  return nil unless host
  host = host.sub(/^www\./, '')
  host.gsub('.', '-')
end

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
  if already_existing.include?(url)
    meta['crawl_name'] = "Skipped Crawl: Website Loaded Elsewhere"
    meta['crawl_description'] = "Skipped crawl because website is already loaded by another activity. See https://github.com/artsdata-stewards/artsdata-planet-boost/blob/main/sparql/artsdata_already_existing.sparql"
    meta['skip_crawl'] = true
  end

  if do_not_load.include?(url)
    meta['crawl_name'] = "Skipped Crawl: Do Not Load Flag"
    meta['crawl_description'] = "This website has been flagged to not be loaded. See https://github.com/artsdata-stewards/artsdata-planet-boost/blob/main/src/config.rb"
    meta['skip_crawl'] = true
  end
  meta
end
data = data.uniq { |d| d["url"] }
data = data.uniq { |d| d["same_as"] }
data = data.reject do |d|
  if already_crawled_urls.include?(d["url"]) || (d["same_as"] != only_uri_to_crawl && only_uri_to_crawl)
    true
  else
    false
  end
end
data = data[0, 10] #limit to first 10 for testing
batch_size = 10
batches = data.each_slice(batch_size).to_a

batches.each_with_index do |batch, i|
  file_index = i + 1
  file_name = "wikidata_orgs_#{file_index}.json"
  File.write(file_name, JSON.pretty_generate(batch))
  puts "Saved #{batch.size} rows to #{file_name}"
end

puts "Total records: #{data.size}"
puts "Total batch files created: #{batches.size}"
