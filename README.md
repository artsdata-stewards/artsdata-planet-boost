# artsdata-planet-boost

**Industry-Wide Search for Structured Data.**

This workflow retrieves a subset of performing arts organizations from Wikidata, spider crawls their website, and computes a [structured data score](https://github.com/culturecreates/artsdata-score) for each one. This workflow was designed to identify potential sources of event data for ETL to Artsdata.

Crawled website can be consulted in [this report](https://kg.artsdata.ca/query/show?sparql=https://raw.githubusercontent.com/artsdata-stewards/artsdata-actions/main/queries/website_spider_crawls.sparql).


## Instructions for loading a Boost website into Artsdata

1. Go to the [Website Spider Crawls](https://kg.artsdata.ca/query/show?sparql=https://raw.githubusercontent.com/artsdata-stewards/artsdata-actions/main/queries/website_spider_crawls.sparql) report;
2. Filter sources by “structured_data_score” to identify sources that good enough to load;
3. Under the “View events” column, click on “Load using databus”. This navigates your browser to the related Artifact view of the Databus.
4. Click “Load Artifact”. It will take 10-15 seconds for the graph to appear in the list of Artsdata data feeds.
5. Proceed with data quality validation and nested entity reconciliation activities;
6. If the data is good enough to turn on auto-minting add a GitHub workflow in the [Artsdata-Orion](https://github.com/artsdata-stewards/artsdata-orion) repo.

### Example workflow:
If you are crawling an organiation with website URL https://duceppe.com/ then:
- Replace WEBSITE-ARTIFACT with `duceppe-com`
- Replace WEBSITE-URL with `https://duceppe.com/`
- Name the workflow file duceppe-com.yml

```
name: Spider WEBSITE-ARTIFACT

on:
  workflow_dispatch:
  schedule:
    - cron: '0 6 * * 4' # At 6:00 GMT every Thursday (day 4)
    
jobs:
  artsdata-fetch-and-push:
    runs-on: ubuntu-latest
    steps:
      - name: Action setup
        uses: culturecreates/artsdata-pipeline-action@v4
        with:
          mode: "fetch-push"
          artifact: "WEBSITE-ARTIFACT"
          publisher: "${{ vars.CAPACOA_BOT }}"
          page-url: "WEBSITE-URL"
          token: "${{ secrets.GITHUB_TOKEN }}"
          cloudflare-private-key: ${{ secrets.CLOUDFLARE_PRIVATE_KEY }}
```

## Instructions to re-crawl a Boost organization

You can manually re-crawl any source in the Boost program by going to the action and clicking run, and entering the associate URL of the organization.

1. Go here https://github.com/artsdata-stewards/artsdata-planet-boost/actions/workflows/controller.yml
2. Click “run”
3. Enter the exact URL of the organization to re-crawl. For example https://duceppe.com/. It should be the exact same URL as the previous boost crawl which you can find in this report https://kg.artsdata.ca/query/show?sparql=https://raw.githubusercontent.com/artsdata-stewards/artsdata-actions/main/queries/website_spider_crawls.sparql
4. Enter "artsdata" in the Source of organizations to fetch (ignore the other fields).
