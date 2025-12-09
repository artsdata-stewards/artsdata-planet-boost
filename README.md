# artsdata-planet-boost

**Industry-Wide Search for Structured Data.**

This workflow retrieves a subset of performing arts organizations from Wikidata, spider crawls their website, and computes a [structured data score](https://github.com/culturecreates/artsdata-score) for each one. This workflow was designed to identify potential sources of event data for ETL to Artsdata.

Crawled website can be consulted in [this report](https://kg.artsdata.ca/query/show?sparql=https://raw.githubusercontent.com/artsdata-stewards/artsdata-actions/main/queries/website_spider_crawls.sparql).

## Instructions for adding a site to the databus

1. Go to the [Website Spider Crawls](https://kg.artsdata.ca/query/show?sparql=https://raw.githubusercontent.com/artsdata-stewards/artsdata-actions/main/queries/website_spider_crawls.sparql) report;
2. Filter sources by “structured_data_score” to identify sources that good enough to load;
3. Under the “View events” column, click on “Load using databus”;
4. Click “Push latest”. It will take 10-15 seconds for the graph to appear in the list of data sources;
5. Proceed with data quality validation and nested entity reconciliation activities;
6. If the data is good enough to turn auto-minting on and to set a schedule, add a GitHub workflow in the [Artsdata-Orion](https://github.com/artsdata-stewards/artsdata-orion) repo.
