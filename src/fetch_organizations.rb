# gem install sparql
# http://www.rubydoc.info/github/ruby-rdf/sparql/frames

require 'sparql/client'
require 'json'
require 'uri'
require 'securerandom'

endpoint = "https://query.wikidata.org/sparql"
sparql = <<'SPARQL'.chop
SELECT ?org ?artsdataID ?url ?name WHERE {
  ?org wdt:P31/wdt:P279* wd:Q7168296 .
  ?org wdt:P7627 ?artsdataID .
  ?org wdt:P856 ?url .
  ?org rdfs:label ?name .
}
SPARQL

client = SPARQL::Client.new(
  endpoint,
  method: :get,
  headers: { 'User-Agent' => 'artsdata-crawler/3.3' }
)

rows = client.query(sparql)

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
  {
    "file_name" => "metadata_config_wikidata_#{uuid}",
    "url" => url,
    "artifact" => artifact_from_url(url),
    "same_as" => row[:org].to_s,
    "name" => row[:name].to_s,
    "datafeed_uri" => "urn:datafeed:#{uuid}",
    "datafeed_title" => "Collection of Wikidata presenter websites",
    "metadata_artifact" => "wikidata-crawl-metadata"
  }
end
data = data.uniq { |d| d["url"] }
data = data.uniq { |d| d["same_as"] }
data = data[0, 5] #limit to first 5 for testing
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
