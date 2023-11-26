#!/usr/bin/env ruby

require "bundler/inline"
require "csv"
require "optparse"

gemfile do
  source "https://rubygems.org"
  gem "bugsnag-api", require: "bugsnag/api"
  gem "deepsort"
end

# https://stackoverflow.com/questions/10712679/flatten-a-nested-json-object
module Enumerable
  def flatten_with_path(parent_prefix = nil)
    res = {}

    self.each_with_index do |elem, i|
      if elem.is_a?(Array)
        k, v = elem
      else
        k, v = i, elem
      end

      key = parent_prefix ? "#{parent_prefix}.#{k}" : k # assign key name for result hash

      if v.is_a? Enumerable
        res.merge!(v.flatten_with_path(key)) # recursive call to flatten child elements
      else
        res[key] = v
      end
    end

    res
  end
end

def auto_retry
  yield
rescue Bugsnag::Api::RateLimitExceeded => e
  STDERR.puts "Rate limit exceeded, sleeping for 15 seconds..."
  sleep 15
  retry
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: script.rb [options]"

  opts.on("-tTOKEN", "--token=TOKEN", "Bugsnag Auth Token") do |t|
    options[:token] = t
  end

  opts.on("-oORG", "--organization=ORG", "Bugsnag Organization Name") do |o|
    options[:organization_name] = o
  end

  opts.on("-pPROJECT", "--project=PROJECT", "Bugsnag Project Name") do |p|
    options[:project_name] = p
  end

  opts.on("-eERROR_ID", "--error-id=ERROR_ID", "Error ID") do |e|
    options[:error_id] = e
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

raise OptionParser::MissingArgument if options[:token].nil? || options[:error_id].nil?

client = Bugsnag::Api::Client.new(auth_token: options[:token])

organization = client.organizations.find do |org|
  options[:organization_name].nil? || org.name == options[:organization_name]
end

project = client.projects(organization.id).find do |proj|
  options[:project_name].nil? || proj.name == options[:project_name]
end

# Get the first page of events, we can only get 30 per page
events = client.error_events(project.id, options[:error_id])

# This is definitely not threadsafe

last_response = client.last_response
until last_response.rels[:next].nil?
  last_response = auto_retry { last_response.rels[:next].get }
  events.concat last_response.data
end

CSV(STDOUT) do |csv|
  events.each.with_index do |event_summary, i|
    event_full = auto_retry { client.event(options[:error_id], event_summary.id) }
    row = event_full.to_h.slice(:id, :received_at, :user, :metaData).deep_sort.flatten_with_path

    csv << row.keys if i == 0
    csv << row.values
  end
end
