#!/usr/bin/env ruby

# This pre-push hook is meant to run when you push your changes to a remote repository.
# If the script does not run automatically, please check that you enabled this git hook by:
#   1) removing the .sample extension from the file
#   2) `chmod +x pre-push` without the backticks in your .git/hooks folder

# run_scripts is called at the end of this file. It will run each of the style checks on every committed file in the push
def run_scripts(committed_files)
  # keep this STDIN.reopen line to allow for reading user input
  STDIN.reopen("/dev/tty")
  # for each of the files in the committed_files array, call the different style checks
  committed_files.each { |file_name|
    # you can specify which code style checks you want to enforce through this hook
    # you would add/remove any rules here. For example: new_style_rule(file_name)
    debugger_check(file_name)
    whitespace_check(file_name)
    newline_check(file_name)
  }
  # we want to keep this check_for_file_edits method to see if any files were modified as a result of running these hook
  check_for_file_edits(committed_files)
end

# get_committed_files returns an array of committed files that are part of the push you're doing
def get_committed_files
  # set the current branch name to be the current branch you're on --> need to check that this works as part of push
  curr_branch_name = `git rev-parse --abbrev-ref HEAD`

  # raw_sha_list lists all the local, unpushed commit SHAs from your current branch
  raw_sha_list = `git log --graph --pretty=format:'%H' #{curr_branch_name}`

  committed_files = []
  # loop through the raw_sha_list and push properly formatted SHAs into the all_shas arr
  raw_sha_list.each_line { |sha|
    # using the .tr method on the sha makes a copy of the sha and replaces instances that matches with the to_str (second arg),
    # unless the range starts with a ^ carrot, in which case, it replaces on matches outside the range
    curr_sha = sha.tr('^A-Za-z0-9', '')

    # this `git diff-tree --no-commit-id --name-only -r <SHA>` will list the files of an individual commit when you add the SHA
    # on each iteration, set the changed_files variable to be the list of files from a particular commit, based its SHA
    changed_files =  `git diff-tree --no-commit-id --name-only -r #{curr_sha}`

    # loop over the changed_files and add in each file that's part of a commit and add into the committed_files arr
    changed_files.each_line { |file|
      # remove any trailing whitespace from the file name and add into our arr
      committed_files << file.rstrip()
    }
  }
  # return the final, no-repeat array of committed files in this push
  return committed_files.uniq
end

# debugger_check checks for any leftover debugger statements in your JS and CoffeeScript files
def debugger_check(file_name)
  # File.extname method will grab the extension. If the extension is for a JS/CoffeeScript file, we want to do a check for debugger statements
  if File.extname(file_name) === '.js' || File.extname(file_name) === '.coffee'
    puts "Checking for debugger statements left behind..."

    # open each JS file and run through prompt
    File.open(file_name, 'r').each_with_index { |line, idx|
      # skip over file if the lines begin with a comment, single quote, or double quote
      next if line =~  /^$|\"|\'|\/|\#/

      #if we find a debugger statement
      if line =~ /debugger/
        # give an opportunity for user to view the debugger statement for context
        print " found debugger in #{file_name} would you like to see instance [y/n]: "
        response = STDIN.gets.chomp.downcase
        case response
        when 'y'
          print file_name + ":#{idx+1} "
          # if the instance is towards the beginning or end of file (so there are not 2 lines above or 2 lines below), then print just the single line
          if idx < 2 || idx > IO.readlines(file_name).size-2
            puts line
          else
            # print two lines and two lines below debugger statement
            puts IO.readlines(file_name)[idx-2..idx+2].join()
          end
        end

        # ask user if they want to automatically remove the debugger statement
        print "> Remove this debugger statement? [y/n] Ctrl-c to exit and abort push at any time: "
        response = STDIN.gets.chomp.downcase

        case response
        # if the user wants to automatically make a change, this block will open up the current file and sub 'debugger' or 'debugger;' with an empty string.
        # This does not currently remove the new line created by the debugger statement in the first place
        when 'y'
          newer_contents = File.read(file_name).gsub(/debugger;|debugger/, "")
            File.open(file_name, "w") {|file| file.puts newer_contents }
            puts 'replaced!'
            file_changes_made = true
        end
      end
    }
  end # end statement for JS/CoffeeScript extension conditional
end

# newline_check makes sure there is only a single newline at the end of each file
def newline_check(file_name)
  # check if the file has no newline or multiple newlines
  lines = File.open(file_name, 'r').to_a
  # if the last character of the last line with code is a newline character AND there is additional text on that line, set hasSingleNewline to true; otherwise set it to false
  hasSingleNewline = lines.last[-1] == "\n" && lines.last.length > 1
  # if there isn't already a single newline at the end of the file, call the process(text) method to add one in (or delete multiple ones and add a newline in)
  if !hasSingleNewline
    text = File.read(file_name)
    # re-write the file with the final file text returned by the process(text) method
    File.open(file_name, "w") { |file| file.puts process(text) }
  end
end

def process(text)
  # if the last character is a newline
  if text[-1] == "\n"
    # set the text to be all the code without the last newline character
    text = text[0..-2]
    # recursively call the function to delete newlines, one at a time
    process(text)
  else
    # add the single newline character
    text = text+"\n"
    # return the new text with just one newline at the end
    text
  end
end

# whitespace_check removes any trailing whitespace from a file
def whitespace_check(file_name)
  # this handles trailing whitespace removal
  puts "Removing any trailing whitespace..."
  # skip over markdown files that need trailing whitespace
  if File.extname(file_name) != '.md' && File.extname(file_name) != '.markdown'
    # sed is a stream editor => the -i flag does inplace editing
    # '' => empty extension: removing this will cause errors unless you provide an extension to the -i flag
    # s/ => substitute command followed by regex
    # last argument is the target file
    system("sed -i '' 's/[ \t]*$//' #{file_name}")
  end
end

# check_for_file_edits determines whether there are unstaged files from running this script
def check_for_file_edits(committed_files)
  check_for_changes = `git ls-files --modified`

  if check_for_changes.each_line { |line|
  # if the user modified any files while executing this hook, then ask for a re-commit and abort the user push
    if committed_files.include?(line.rstrip())
      puts "**File have been edited. Please stage/re-commit your changes and push again**"
      exit(1)
    end
  }
  else
    exit(0)
  end
end

# ADDITIONAL RULES:


# ADD ANY NEW STYLE RULE ABOVE ^^^

# *******************************************************************************************************
# Keep this run_scripts(get_committed_files) call if you want the hook to run
run_scripts(get_committed_files)
