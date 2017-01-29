#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraperwiki'
require 'wikidata/area'
require 'wikidata/fetcher'

query = <<QUERY
  SELECT DISTINCT ?item
  WHERE { ?item wdt:P31 wd:Q35657 }
QUERY

wanted = EveryPolitician::Wikidata.sparql(query)
raise 'No ids' if wanted.empty?

data = Wikidata::Areas.new(ids: wanted).data
ScraperWiki.save_sqlite(%i(id), data)
