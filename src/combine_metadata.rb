#!/usr/bin/env ruby

require 'linkeddata'
require 'pathname'

def combine_jsonld(regex_pattern, input_dir: 'metadata', output_file: 'combined.jsonld')
  pattern = Regexp.new(regex_pattern)
  graph   = RDF::Graph.new

  input_path = Pathname.new(input_dir)

  unless input_path.directory?
    raise "Input directory not found: #{input_dir}"
  end

  matched_files = input_path.children.select do |path|
    path.file? &&
      path.extname == '.jsonld' &&
      path.basename.to_s.match?(pattern)
  end

  if matched_files.empty?
    warn "No files matched pattern: #{regex_pattern}"
    return
  end

  matched_files.each do |file|
    puts "Loading #{file}"
    graph << RDF::Graph.load(file.to_s)
    File.delete(file)
    puts "Deleted #{file}"
  end
  if File.exist?(output_file)
    existing_graph = RDF::Graph.load(output_file)
  else
    existing_graph = RDF::Graph.new
  end

  graph << existing_graph

  puts "Writing combined graph to #{output_file}"

  File.open(output_file, 'w') do |f|
    f.puts(graph.dump(:jsonld))
  end

  puts "Done. Statements: #{graph.count}"
end

if ARGV.empty?
  abort "Usage: ruby combine_jsonld.rb '<regex>' [output_file]"
end

regex       = ARGV[0]
output_file = ARGV[1] || 'combined.jsonld'

combine_jsonld(regex, output_file: output_file)
