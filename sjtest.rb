#!/usr/bin/env ruby

s = Dir["*.podspec"].last
if s.nil?
    puts "已退出, 未搜索到 podspec 文件"
    exit
end


contents = String.new

contents = String.new
File.new(s, "r").each_line do |line|
    regex = "s.version([^']+)'([^']+)'*"
    if /#{regex}/ =~ line
        v = ($2.to_i + 1).to_s
        regex = "'[^']+'"
        line = line.sub!(/#{regex}/, "'#{v}'")
    end
    
    contents += line
end
file = File.new(s, "w")
file.syswrite(contents)
file.close

