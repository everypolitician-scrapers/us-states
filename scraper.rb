#!/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'rest-client'
require 'scraperwiki'

WIKIDATA_SPARQL_URL = 'https://query.wikidata.org/sparql'

def sparql(query)
  result = RestClient.get WIKIDATA_SPARQL_URL, params: { query: query, format: 'json' }
  json = JSON.parse(result, symbolize_names: true)
  json[:results][:bindings].map { |res| res.map { |k, v| [k, v[:value]] }.to_h }
rescue RestClient::Exception => e
  raise "Wikidata query #{query} failed: #{e.message}"
end

#-------
# Labels
#-------

label_query = <<LABELSPARQL
  SELECT DISTINCT (STRAFTER(STR(?item), STR(wd:)) AS ?id) ?name (GROUP_CONCAT(DISTINCT ?lang) AS ?langs) (COUNT(DISTINCT ?lang) AS ?count) WITH {
    SELECT DISTINCT ?item { ?item wdt:P31 wd:Q35657 }
  } AS %query
  WHERE {
    INCLUDE %query
    ?item rdfs:label ?label .
    BIND (lang(?label) as ?lang) .
    BIND (str(?label) as ?name) .
  }
  GROUP BY ?item ?name
  ORDER BY ?item DESC(?count)
LABELSPARQL

label_data = sparql(label_query).group_by { |row| row[:id] }.map do |state, rows|
  [state, rows.flat_map do |row|
    row[:langs].split(' ').map { |lang| ["name__#{lang.tr('-', '_')}", row[:name]] }
  end.to_h,]
end.to_h

#-----
# Info
#-----

query = <<QUERY
  SELECT (STRAFTER(STR(?item), STR(wd:)) AS ?id)
      (GROUP_CONCAT(DISTINCT ?flag; separator=";") AS ?flag)
      (GROUP_CONCAT(DISTINCT ?coat_of_arms; separator=";") AS ?coat_of_arms)
      (GROUP_CONCAT(DISTINCT ?iso_code; separator=";") AS ?iso_code)
      (GROUP_CONCAT(DISTINCT (SUBSTR(STR(?inception), 1, 10)); separator=";") AS ?start_date)
      (GROUP_CONCAT(DISTINCT (SUBSTR(STR(?abolished), 1, 10)); separator=";") AS ?end_date)
      (GROUP_CONCAT(DISTINCT ?website; separator=";") AS ?website)
      (GROUP_CONCAT(DISTINCT ?identifier__viaf; separator=";") AS ?identifier__viaf)
      (GROUP_CONCAT(DISTINCT ?identifier__gnd; separator=";") AS ?identifier__gnd)
      (GROUP_CONCAT(DISTINCT ?identifier__lcauth; separator=";") AS ?identifier__lcauth)
      (GROUP_CONCAT(DISTINCT ?identifier__bnf; separator=";") AS ?identifier__bnf)
      (GROUP_CONCAT(DISTINCT ?identifier__openstreetmap; separator=";") AS ?identifier__openstreetmap)
      (GROUP_CONCAT(DISTINCT ?identifier__freebase; separator=";") AS ?identifier__freebase)
      (GROUP_CONCAT(DISTINCT ?identifier__gss; separator=";") AS ?identifier__gss)
      (GROUP_CONCAT(DISTINCT ?identifier__fips; separator=";") AS ?identifier__fips)
      (GROUP_CONCAT(DISTINCT ?identifier__dmoz; separator=";") AS ?identifier__dmoz)
      (GROUP_CONCAT(DISTINCT ?identifier__britannica; separator=";") AS ?identifier__britannica)
      (GROUP_CONCAT(DISTINCT ?identifier__geonames; separator=";") AS ?identifier__geonames)
      (GROUP_CONCAT(DISTINCT ?identifier__bbc_things; separator=";") AS ?identifier__bbc_things)
      (GROUP_CONCAT(DISTINCT ?identifier__tgn; separator=";") AS ?identifier__tgn)
      (GROUP_CONCAT(DISTINCT ?identifier__guardian; separator=";") AS ?identifier__guardian)
      (GROUP_CONCAT(DISTINCT ?identifier__newyorktimes; separator=";") AS ?identifier__newyorktimes)
      (GROUP_CONCAT(DISTINCT ?identifier__quora; separator=";") AS ?identifier__quora)
  WHERE {
      ?item wdt:P31 wd:Q35657 .
      OPTIONAL { ?item wdt:P41 ?flag }
      OPTIONAL { ?item wdt:P94 ?coat_of_arms }
      OPTIONAL { ?item wdt:P300 ?iso_code }
      OPTIONAL { ?item wdt:P571 ?inception }
      OPTIONAL { ?item wdt:P576 ?abolished }
      OPTIONAL { ?item wdt:P580 ?start_date }
      OPTIONAL { ?item wdt:P582 ?end_date }
      OPTIONAL { ?item wdt:P856 ?website }
      OPTIONAL { ?item wdt:P214 ?identifier__viaf }
      OPTIONAL { ?item wdt:P227 ?identifier__gnd }
      OPTIONAL { ?item wdt:P244 ?identifier__lcauth }
      OPTIONAL { ?item wdt:P268 ?identifier__bnf }
      OPTIONAL { ?item wdt:P402 ?identifier__openstreetmap }
      OPTIONAL { ?item wdt:P646 ?identifier__freebase }
      OPTIONAL { ?item wdt:P836 ?identifier__gss }
      OPTIONAL { ?item wdt:P901 ?identifier__fips }
      OPTIONAL { ?item wdt:P998 ?identifier__dmoz }
      OPTIONAL { ?item wdt:P1417 ?identifier__britannica }
      OPTIONAL { ?item wdt:P1566 ?identifier__geonames }
      OPTIONAL { ?item wdt:P1617 ?identifier__bbc_things }
      OPTIONAL { ?item wdt:P1667 ?identifier__tgn }
      OPTIONAL { ?item wdt:P3106 ?identifier__guardian }
      OPTIONAL { ?item wdt:P3221 ?identifier__newyorktimes }
      OPTIONAL { ?item wdt:P3417 ?identifier__quora }
  }
  GROUP BY ?item
QUERY

data = sparql(query).map do |row|
  row.merge(label_data[row[:id]])
end
data.each { |mem| puts mem.reject { |_, v| v.to_s.empty? }.sort_by { |k, _| k.to_s }.to_h } if ENV['MORPH_DEBUG']

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil
ScraperWiki.save_sqlite(%i[id], data)
