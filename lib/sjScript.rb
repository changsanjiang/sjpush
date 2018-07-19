
class Property
    attr_accessor :type, :field

    def initialize(type:, field:)
        @type, @field = type, field
    end

    def to_s
        "type: #{type}, field: #{field}"
    end
end



class Recorder
    attr_accessor :contents,
                  :trimPropertyFields,
                  :parseInterface,
                  :parseImplementation,
                  :parseImpPhaseOneFinished,
                  :parseImpPhaseTwoFinished

    def initialize()
    
        # 存放所有内容
        @contents = String.new
    
        # 存放变更的字段. (里面是 Property 对象)
        @trimPropertyFields = Array.new
    
        # 记录解析的阶段
        @parseInterface = false
        @parseImplementation = false
    
        # 第一阶段解析完毕, 开头添加 @syn name = _name
        @parseImpPhaseOneFinished = false
    
        # 第二阶段解析完毕, 底部添加 - (type)filed {}
        @parseImpPhaseTwoFinished = false
    end

    def parsing(line:)
        # 记录解析阶段
        if /@interface/ =~ line then
            self.parseInterface = true
        end
    
        # imp
        if /@implementation/ =~ line then
            self.parseImplementation = true
        end
    
        # end
        if /@end/ =~ line then
            if self.parseInterface then
                self.parseInterface = false
            end
        
            if self.parseImplementation then
                self.parseImplementation = false
            end
        end

        # 如果正在解析 interface
        if self.parseInterface then
        # [^readonly|readwrite] 匹配除 readonly|readwrite 以外的字符串
            if /\(nonatomic.*[^readonly|readwrite]\)/ =~ line then
                # 将此行添加 readonly
                line.gsub!(/\)/, ", readonly)")
            
                # 记录 属性, imp 生成时需要.
            
                # 记录 type
                arr = line.split
                type = arr[-2] + " *"
            
                # 记录 field
                field = arr.last.gsub!(/\*|;/, "")
                self.trimPropertyFields.push(Property.new(type:type, field:field))
            end
        end

        # 如果正在解析 imp
        if self.parseImplementation then
            if !self.parseImpPhaseOneFinished then
                self.parseImpPhaseOneFinished = true
                self.trimPropertyFields.each do |property|
                    line << "@synthesize " + property.field + " = _" + property.field + ";\n";
                end
            end
        end

        # 如果解析到了最后 imp
        if /@end/ =~ line && !self.parseImplementation && self.parseImpPhaseOneFinished then
            self.parseImpPhaseTwoFinished = true;

            self.trimPropertyFields.each do |property|
                # - (type *)name {\n
                # \t  if ( _name ) return _name; \n
                # \t    \n
                # \t  return _name; \n
                # }
                type = property.type
                field = property.field
    #            self.contents << "\n- (#{type})#{field} {\n\tif ( _#{field} ) return _#{field};\n\t\n\treturn _#{field};\n}\n\n"
                self.contents << (<<~"EOB")
                - (#{type})#{field} {
                    if ( _#{field} ) return _#{field};
                
                    return _#{field};
                }
                EOB
            end
            puts "全部解析完毕"
        end

        self.contents += line;
    end


    def parseInterface=(result)
        @parseInterface = result
    
        if result then
            puts "开始解析 interface"
        else
            puts "解析完毕 interface"
        end
    end

    def parseImplementation=(result)
        @parseImplementation = result
    
        if result then
            puts "开始解析 implementation"
        else
            puts "解析完毕 implementation"
        end
    end

end



# -------------------

BEGIN {

}


puts "请输入文件路径:"
input = gets

# strip 删除字符串开头和末尾的空白字符
filePath = input.chomp!.strip!
recorder = Recorder.new

# generate
File.new(filePath, "r").each_line do |line|
    recorder.parsing(line: line)
end

# write
file = File.new(filePath, "w")
file.syswrite(recorder.contents)
file.close

END {

}
