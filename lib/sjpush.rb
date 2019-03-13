#require "sjpush/version"
#!/usr/bin/env ruby

class ActionHandler
    # 定义类方法
    class << self
        # 获取当前的分支
        def getCurBranch()
            # strip! 删除开头和末尾的空白字符
            commands = IO.readlines(".git/HEAD").first.strip!;
            commands.sub!(/ref: refs\/heads\//, "")
        end
    end

    class << self
        def getPodspec()
            Dir["*.podspec"].last
        end

        def updatePodspecVerAction()
            s = ActionHandler.getPodspec()
            if s.nil?
                puts "已退出, 未搜索到 podspec 文件"
                exit
            end
            
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
            
            puts "podspec 版本已更新"
        end

        def getPodspecVersion()
            s = ActionHandler.getPodspec()
            if s.nil?
                puts "已退出, 未搜索到 podspec 文件"
                exit
            end
            
            File.new(s, "r").each_line do |line|
                regex = "s.version([^']+)'([^']+)'*"
                if /#{regex}/ =~ line
                    @version = $2.to_i
                    break
                end
            end
            
            return @version
        end
    end

    def initialize()
        @commands = String.new
    end
    

    # - Actions -

    def addCommand(order)
        if @commands.length == 0
            @commands << order
        else
            @commands << " && #{order}"
        end
    end

    def submitInfoAction()
        if @commitInfo.nil?
            puts "请输入提交信息:"
            @commitInfo = gets.strip!
        end
        return @commitInfo
    end

    def commitAction()
        submit = submitInfoAction()
        addCommand "git add ."
        addCommand "git commit -m '#{submit}'"
    end
    
    def pushAction()
        addCommand "git push origin #{ActionHandler.getCurBranch()}"
    end
    
    def addNewTagAction()
        puts "请输入新的标签:"
        newTag = gets.strip!
        
        submit = submitInfoAction()
        addCommand "git tag -a '#{newTag}' -m '#{submit}'"
        addCommand "git push origin #{newTag}"
    end

    def addNewTagForPodspecVersionAction()
        version = ActionHandler.getPodspecVersion()
        submit = submitInfoAction()
        addCommand "git tag -a '#{version}' -m '#{submit}'"
        addCommand "git push origin #{version}"
    end
    
    def deleteTagAction()
        puts "请输入要删除的标签:"
        tag = gets.strip!
        addCommand "git tag -d #{tag}"
        addCommand "git push origin :#{tag}"
    end
    
    def podReleaseAction()
        s = ActionHandler.getPodspec()
        if s.nil?
            puts "已退出, 未搜索到 podspec 文件"
            exit
        end
        addCommand "pod repo push lanwuzheRepo #{s} --allow-warnings --use-libraries"
    end

    def executeCommands
        puts <<-DESC
        
        
        =========================正则执行, 请稍等...=========================
        =========================正则执行, 请稍等...=========================
        
        
        DESC
        system @commands
        puts "操作完成"
    end


    def handleSeq(seq)
        if seq == $seq_commit.to_i
            commitAction()
        elsif seq == $seq_push_current_branch.to_i
            pushAction()
        elsif seq == $seq_add_tag.to_i
            puts "\n是否使用Podspec中的版本作为标签? [ Yes / NO ]"
            r = gets
            if r.casecmp("Yes") == 1
                addNewTagForPodspecVersionAction()
            else
                addNewTagAction()
            end
        elsif seq == $seq_release.to_i
            podReleaseAction()
        elsif seq == $seq_delete_tag.to_i
            deleteTagAction()
        elsif seq == $seq_update_podspec_version.to_i
            ActionHandler.updatePodspecVerAction()
        elsif seq == $seq_lazy_protocol.to_i
            require 'sjProtocol'
            exit
        elsif seq == $seq_lazy_property.to_i
            require 'sjScript'
            exit
        end
        
        nextCommand(seq)
    end


    def nextCommand(beforeSeq)
        if beforeSeq == $seq_commit.to_i
            # 询问是否推送到主干上
            # ActionHandler - Push
            puts "\n是否推送到 #{ActionHandler.getCurBranch()}? [ Yes / NO ]"
            r = gets
            if r.casecmp("Yes") == 1
                handleSeq($seq_push_current_branch.to_i)
            end
        elsif beforeSeq == $seq_push_current_branch.to_i
            puts "\n是否添加标签? [ Yes / NO ]"
            r = gets
            if r.casecmp("Yes") == 1
                handleSeq($seq_add_tag.to_i)
            end
        elsif beforeSeq == $seq_add_tag.to_i
            # 询问是否发布pod
            # Pod - Release
            puts "\n是否发布pod版本? [ Yes / NO ]"
            r = gets
            if r.casecmp("Yes") == 1
                handleSeq($seq_release.to_i)
            end
        elsif beforeSeq == $seq_update_podspec_version.to_i
            puts "\n是否提交变更? [ Yes / NO ]"
            r = gets
            if r.casecmp("Yes") == 1
                handleSeq($seq_commit.to_i)
            end
        end
    end
end

seqs = [
$seq_update_podspec_version = "0. Podspec版本+1",
$seq_commit                 = "1. 提交变更",
$seq_push_current_branch    = "2. 推送到当前分支(#{ActionHandler.getCurBranch()})",
$seq_add_tag                = "3. 添加新的标签",
$seq_release                = "4. pod发布(pod repo push ..repo ..podspec)",
$seq_delete_tag             = "5. 删除标签",
$seq_lazy_protocol          = "6. 自动写协议",
$seq_lazy_property          = "7. 自动补全懒加载",
]

require "pp"

# - seqs -
puts "\n"
puts "请输入操作序号:"
puts "\n"
seqs.each do |s|
    puts s
end
puts "\n"

# - exit -
puts "输入`exit`退出脚本"

puts "\n"
puts "================== 等待操作 =================="

seq = gets

exit if seq.casecmp('exit') == 1

handler = ActionHandler.new
puts "\n\n"
handler.handleSeq(seq.to_i)
handler.executeCommands()
