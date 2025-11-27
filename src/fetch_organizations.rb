# gem install sparql
# http://www.rubydoc.info/github/ruby-rdf/sparql/frames

require 'sparql/client'
require 'json'
require 'uri'
require 'securerandom'
require_relative 'config'

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

do_not_load = Config::WIKIDATA_CONFIG[:do_not_load_websites].to_set

def artifact_from_url(url)
  host = URI.parse(url).host rescue nil
  return nil unless host
  host = host.sub(/^www\./, '')
  host.gsub('.', '-')
end

date = Time.now.strftime("%Y-%m-%d-%H:%M")
uuid = SecureRandom.uuid
data = rows.map do |row|
  url = row[:url].to_s
  meta = {
    "file_name" => "metadata_wikidata_spider.jsonld",
    "url" => url,
    "artifact" => artifact_from_url(url),
    "same_as" => row[:org].to_s,
    "name" => row[:orgLabel].to_s,
    "datafeed_uri" => "urn:datafeed:#{uuid}",
    "datafeed_title" => "Collection of Wikidata presenter websites",
    "metadata_artifact" => "wikidata-spider-crawl-metadata"
  }
  if already_existing.include?(url)
    meta['crawl_name'] = "Website skipped",
    meta['crawl_description'] = "Skipped crawl because website is already loaded by another activity."
    meta['skip_crawl'] = true
  end

  if do_not_load.include?(url)
    meta['crawl_name'] = "Website flagged to not load",
    meta['crawl_description'] = "This website has been flagged to not be loaded."
    meta['skip_crawl'] = true
  end
  meta
end
data = data.uniq { |d| d["url"] }
data = data.uniq { |d| d["same_as"] }
data = data[0, 20] #limit to first 20 for testing
batch_size = 5
batches = data.each_slice(batch_size).to_a

batches.each_with_index do |batch, i|
  file_index = i + 1
  file_name = "wikidata_orgs_#{file_index}.json"
  File.write(file_name, JSON.pretty_generate(batch))
  puts "Saved #{batch.size} rows to #{file_name}"
end

puts "Total records: #{data.size}"
puts "Total batch files created: #{batches.size}"
