#!/usr/bin/env ruby

# keep this STDIN.reopen line to allow for reading user input
STDIN.reopen("/dev/tty")

# track if any changes were made as part of running this pre-push hook. if so, the user will need to re-commit their files
file_changes_made = false

#set the current branch name to be the current branch you're on --> need to check that this works as part of push
# curr_branch_name = `git symbolic-ref -q --short HEAD`
curr_branch_name = `git rev-parse --abbrev-ref HEAD`
# `git cherry` will display the SHAs for commits not applied to the upstream..this doesn't work on the first
# push, even with -u upstream specified
# raw_sha_list = `git cherry origin/#{curr_branch_name}`

# detected changes files changed in other branches will prompt for a re-commit
# if it's for other than trailing whitespace

# raw_sha_list lists all the local, unpushed commit SHAs from your crrent branch
# raw_sha_list = `git log --graph #{curr_branch_name} --not --remotes --pretty-format="format:%h"`
# git log --graph try_dry --format=%H

raw_sha_list = `git log --graph --pretty=format:'%H' #{curr_branch_name}`

committed_files = []
# loop through the raw_sha_list and push properly formatted SHAs into the all_shas arr
raw_sha_list.each_line { |sha|
  # using the .tr method on the sha makes a copy of the sha and replaces instances that matches with the to_str (second arg),
  # unless the range starts with a ^ carrot, in which case, it replaces on matches outside the range
  curr_sha = sha.tr('^A-Za-z0-9', '')

  # this `git diff-tree --no-commit-id --name-only -r <SHA>` will list the files of an individual commit when you add the SHA
  # on each iteration, set the changed_files variable to be the list of files from a particular commit, based its SHA
  changed_files =  `git diff-tree --name-only -r #{curr_sha}`
# d4cd1e17d7e6429700310a9661b270db92d40fd2
  # loop over the changed_files and add in each file that's part of a commit and add into the committed_files arr
  changed_files.each_line { |file|
    # remove any trailing whitespace from the file name and add into our arr
    committed_files << file.rstrip()
  }
}

# this statement should later be REMOVED. this is just print out all the uniq file names that have been committed
puts "All committed files: #{committed_files.uniq}"

# loop over unique committed_files
committed_files.uniq.each { |file_name|
  # we want to do a check for the file extension
  # if the file is a JS/CoffeeScript file, we want to do a check for debeugger statements

  # File.extname method will grab the extension
  if File.extname(file_name) === '.js' || File.extname(file_name) === '.coffee'
    puts "Checking for debugger statements left behind..."

    # open each JS file that was changed and run through prompt
    File.open(file_name, 'r').each_with_index { |line, idx|
      #skip over file if the lines begin with comments
      next if line =~  /^$|\"/
      next if line =~  /^$|\'/
      next if line =~ /^$|\//
      next if line =~  /^$|\#/

      #if we find a debugger statement
      if line =~ /debugger/

        print " found debugger in #{file_name} would you like to see instance [y/n]: "
        response = STDIN.gets.chomp.downcase
        case response
        when 'y'
          print file_name + ":#{idx+1} "
          if idx <2 || idx > IO.readlines(file_name).size-2
            puts line
          else
            puts IO.readlines(file_name)[idx-2..idx+2].join()
          end
        end

        print "> Remove this debugger statement? [y/n] Ctrl-c to exit and abort push at any time: "
        response = STDIN.gets.chomp.downcase

        case response
        when 'y'
          newer_contents = File.read(file_name).gsub(/debugger;|debugger/, "")
            File.open(file_name, "w") {|file| file.puts newer_contents }
            puts 'replaced!'
            file_changes_made = true
        when 'n'
          puts 'suit yourself!'
        else
          puts 'nothing to do here'
        end
      end
    }
  end # end statement for JS/CoffeeScript extension

  # ****Non-JS specific checks (newline and trailing whitespace)****

  # adding a newline at the end of a file based on reading the last line of the file
  last = IO.readlines(file_name).size

  # we can eventually remove this puts statement for reading existing new lines and append when there's not one
  if IO.readlines(file_name)[last-1] =~ /\n/
    puts 'blank line present'
  # if the last line isn't a newline, open the file and append one
  else
    open(file_name, 'a') { |f|
    f.puts "\n"}
    puts 'Adding newline to end of your file...'
    file_changes_made = true
  end

  # this handles trailing whitespace removal
  puts "Removing any trailing whitespace..."
  # skip over markdown files that need trailing whitespace
  next if File.extname(file_name) === '.md' || File.extname(file_name) === '.markdown'

  puts "Checking test file: #{file_name}"

  # the -i flag saves in place
  # '' => empty extension: removing this will cause errors unless you provide an extension to the -i flag
  # s/ => substitute command followed by regex
  # last part is the target file
  system("sed -i '' 's/[ \t]*$//' #{file_name}")
}

# if the user made any changes while executing this hook, then ask for a re-commit and abort the user push
if file_changes_made
  puts "**File edits were made. Please re-commit your changes and push again.**"
  exit(1)
else
  # exit 0 for a successful push
  exit(0)
end