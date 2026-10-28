#!/usr/bin/env ruby
require "json"

path, dep_name, version = ARGV
abort "usage: patch_pubcache_path_dep.rb <versions.json> <dep-name> <version>" unless path && dep_name && version

data = JSON.parse(File.read(path))
changed = 0
(data["versions"] || []).each do |entry|
  deps = (entry["pubspec"] || {})["dependencies"] || {}
  dep = deps[dep_name]
  if dep.is_a?(Hash) && dep.key?("path")
    deps[dep_name] = version
    changed += 1
  end
end
File.write(path, JSON.generate(data))
puts "#{path}: rewrote #{changed} entries (#{dep_name} -> #{version})"
