module Config
  WIKIDATA_CONFIG = {
    wikidata_endpoint: "https://query.wikidata.org/sparql",
    wikidata_sparql: "sparql/wikidata_query.sparql",
    artsdata_sparql: "sparql/artsdata_already_existing.sparql",
    artsdata_endpoint: "https://db.artsdata.ca/repositories/artsdata",
    do_not_load_websites: [
      "https://www.ville.lamalbaie.qc.ca"
    ]
  }.freeze

  GENERAL_CONFIG = {
    user_agent: 'artsdata-crawler/3.3'
  }.freeze
end
