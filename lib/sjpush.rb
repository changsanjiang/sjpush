#require "sjpush/version"

# Your code goes here...
puts <<-DESC
===============================================
请输入操作序号:
1. 提交变更(git commit -m '..')
2. 推送到主干上(git push origin master)
3. 添加新的标签(git tag -a '..' -m '..')
4. pod发布(pod repo push ..repo ..podspec)
5. 删除标签(git -d .., git push origin :..)

输入`exit`退出脚本
===============================================
DESC

$seq_git_commit         = 1
$seq_git_push_master    = 2
$seq_git_add_tag        = 3
$seq_pod_release        = 4
$seq_git_delete_tag     = 5

seq = gets

exit if seq.casecmp('exit') == 1

class Git
    def initialize()
        @content = String.new
    end
    
    def appendExeorder(order)
        if @content.length == 0
            @content << order
            else
            @content << " && #{order}"
        end
    end
    
    def commit()
        puts "请输入此次提交信息:"
        @commitInfo = gets.strip!
        appendExeorder "git add ."
        appendExeorder "git commit -m '#{@commitInfo}'"
    end
    
    def pushMaster()
        appendExeorder "git push origin master"
    end
    
    def addNewTag()
        puts "请输入新的标签:"
        newTag = gets.strip!
        appendExeorder "git tag -a '#{newTag}' -m '#{@commitInfo}'"
        appendExeorder "git push origin #{newTag}"
    end
    
    def deleteTag()
        puts "请输入要删除的标签:"
        tag = gets.strip!
        appendExeorder "git tag -d #{tag}"
        appendExeorder "git push origin :#{tag}"
    end
    
    def podRelease()
        currentDir = Dir["*.podspec"].last
        if currentDir.nil?
            puts "已退出, 未搜索到 podsspec 文件"
            exit
        end
        appendExeorder "pod repo push lanwuzheRepo #{currentDir} --allow-warnings"
    end
    
    def exec
        puts <<-DESC
        
        
        =========================正则执行, 请稍等...=========================
        =========================正则执行, 请稍等...=========================
        
        
        DESC
        system @content
        puts "操作完成"
    end
end


def whetherToPushMaster(git)
    # 询问是否推送到主干上
    # Git - Push
    puts "\n是否推送到 Master? [ Yes / NO ]"
    needPush = gets
    if needPush.casecmp("Yes") != 1
        git.exec
        exit
    end
    git.pushMaster
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
    git.addNewTag
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
    git.podRelease
end

def considerNextTask(beforeSeq, git)
    if beforeSeq == $seq_git_commit
        whetherToPushMaster(git)
        whetherAddNewTag(git)
        whetherReleasePod(git)
    end
    
    if beforeSeq == $seq_git_push_master
        whetherAddNewTag(git)
        whetherReleasePod(git)
    end
    
    if beforeSeq == $seq_git_add_tag
        whetherReleasePod(git)
    end
end

def handleSeq(seq)
    puts "\n\n"
    
    git = Git.new
    if seq == $seq_git_commit
        git.commit
        elsif seq == $seq_git_push_master
        git.pushMaster
        elsif seq == $seq_git_add_tag
        git.addNewTag
        elsif seq == $seq_pod_release
        git.podRelease
        elsif seq == $seq_git_delete_tag
        git.deleteTag
    end
    
    considerNextTask(seq, git)
    git.exec
end

handleSeq(seq.to_i)
