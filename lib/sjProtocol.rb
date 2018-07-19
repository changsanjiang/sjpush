puts "请输入文件路径:"
input = gets

# chomp 删除尾部的换行
# strip 删除开头结尾的空格
filePath = input.chomp!.strip!

contents = String.new
obj_class = String.new
obj_delegate = String.new

File.new(filePath, "r").each_line do |line|
	if ( /@interface/ =~ line ) then
		obj_class = line.split[1]
		puts "获取到类名: #{obj_class}"
		# 准备生成代理
		obj_delegate = obj_class + "Delegate"
		contents << "@protocol #{obj_delegate};\n\n"

		line = "#{line}\n@property (nonatomic, weak, readwrite, nullable) id<#{obj_delegate}> delegate;\n"
	end

	contents << line

	if ( /@end/ =~ line && !(obj_delegate.empty?) ) then
		contents << "\n"

		obj_method = ""
		if ( /cell/i =~ obj_delegate ) 
			obj_method = "- (void)tabCell:(#{obj_class} *)cell <#method#>"
		else
			obj_method = "- (void)<#method#>"
		end
		contents << (<<~"EOB")
@protocol #{obj_delegate} <NSObject>
			
@optional
#{obj_method}

@end
EOB
	end
end

puts "生成完毕, 正在写入..."
file = File.new(filePath, "w")
file.syswrite(contents)
file.close
puts "写入完成"
