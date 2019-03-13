#require "sjpush/version"
#!/usr/bin/env ruby

class Git
    # 定义类方法
    class << self
        # 获取当前的分支
        def getBranch()
            # strip! 删除开头和末尾的空白字符
            commands = IO.readlines(".git/HEAD").first.strip!;
            commands.sub!(/ref: refs\/heads\//, "")
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
        if @commitInfo == nil
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
        addCommand "git push origin #{Git.getBranch()}"
    end
    
    def addNewTagAction()
        puts "请输入新的标签:"
        newTag = gets.strip!
        
        submit = submitInfoAction()
        addCommand "git tag -a '#{newTag}' -m '#{submit}'"
        addCommand "git push origin #{newTag}"
    end
    
    def deleteTagAction()
        puts "请输入要删除的标签:"
        tag = gets.strip!
        addCommand "git tag -d #{tag}"
        addCommand "git push origin :#{tag}"
    end
    
    def podReleaseAction()
        currentDir = Dir["*.podspec"].last
        if currentDir.nil?
            puts "已退出, 未搜索到 podspec 文件"
            exit
        end
        addCommand "pod repo push lanwuzheRepo #{currentDir} --allow-warnings --use-libraries"
    end
    
    def exec
        puts <<-DESC
        
        
        =========================正则执行, 请稍等...=========================
        =========================正则执行, 请稍等...=========================
        
        
        DESC
        system @commands
        puts "操作完成"
    end
end


class Pods
    class << self
        def updateSubspecVersion()
        end
    end
end


def whetherToPushOrigin(git)
    # 询问是否推送到主干上
    # Git - Push
    puts "\n是否推送到 #{Git.getBranch()}? [ Yes / NO ]"
    needPush = gets
    if needPush.casecmp("Yes") != 1
        git.exec
        exit
    end
    git.pushAction()
end

def whetherAddNewTag(git)
    # 询问是否添加新的标签
    # Git - Add Tag
    puts "\n是否添加标签? [ Yes / NO ]"
    needAddTag = gets
    if needAddTag.casecmp("Yes") != 1
        git.exec
        exit
    end
    git.addNewTagAction()
end

def whetherReleasePod(git)
    # 询问是否发布pod
    # Pod - Release
    puts "\n是否发布pod版本? [ Yes / NO ]"
    needRelease = gets
    if needRelease.casecmp("Yes") != 1
        git.exec
        exit
    end
    git.podReleaseAction()
end

def considerNextTask(beforeSeq, git)
    if beforeSeq == $seq_git_commit
        handleSeq($seq_git_push_current_branch)
    elsif beforeSeq == $seq_git_push_current_branch
        handleSeq($seq_git_add_tag)
    elsif beforeSeq == $seq_git_add_tag
        handleSeq($seq_pod_release)
    elsif beforeSeq == $seq_pod_updateSubspecVersion
        handleSeq($seq_git_commit)
    end
end

seqs = [
$seq_git_commit                 = "1. 提交变更",
$seq_git_push_current_branch    = "2. 推送到当前分支(#{Git.getBranch()})",
$seq_git_add_tag                = "3. 添加新的标签",
$seq_pod_release                = "4. pod发布(pod repo push ..repo ..podspec)",
$seq_git_delete_tag             = "5. 删除标签",
$seq_pod_updateSubspecVersion   = "6. subspec版本+1",
]

other = [
$seq_lazy_protocol              = "7. 自动写协议",
$seq_lazy_property              = "8. 自动补全懒加载",
]

require "pp"

# - seqs -
puts "请输入操作序号:"
pp seqs
puts "\n"

# - other -
puts "补全代码:"
pp other
puts "\n"

# - exit -
puts "输入`exit`退出脚本"

puts "\n"
puts "\033[31m================== 等待操作 ==================\033[0m\n"

seq = gets

exit if seq.casecmp('exit') == 1

def handleSeq(seq)
    git = Git.new
    if seq == $seq_git_commit.to_i
        git.commitAction()
    elsif seq == $seq_git_push_current_branch.to_i
        git.pushAction()
    elsif seq == $seq_git_add_tag.to_i
        git.addNewTagAction()
    elsif seq == $seq_pod_release.to_i
        git.podReleaseAction()
    elsif seq == $seq_git_delete_tag.to_i
        git.deleteTagAction()
    elsif seq == $seq_pod_updateSubspecVersion.to_i
        Pods.updateSubspecVersion()
    elsif seq == $seq_lazy_protocol.to_i
        require 'sjProtocol'
        exit
    elsif seq == $seq_lazy_property.to_i
        require 'sjScript'
        exit
    end

    considerNextTask(seq, git)
    git.exec
end

puts "\n\n"
handleSeq(seq.to_i)
