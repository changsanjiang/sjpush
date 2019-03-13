#!/usr/bin/env ruby

content = IO.readlines(".git/HEAD").first;
puts content
content.sub!(/ref: refs\/heads\//, "")
puts content
