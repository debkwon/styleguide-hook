## Styling Tool - testing git hooks checklist ##  

* Check for debugger statements.
* Check for trailing whitespace.
* Check for a single new line at the end of each file.
* Provide flexibility in configuring existing rules or adding new rules.
* Include comments to explain usage.
* Bonus: Enforce consistent use of double quotes instead of single quotes (except when nested)


## Tools being tested ##

Integrating a custom pre-push git hook with a repo.

This line tells git where to look for executable scripts: git config --global init.templatedir '~/.git_hooks'

core.hooksPath is available to configure the paths for hooks..implemented in git version 2.9


If you want to copy over the script and implement it locally, go to your repo and then in your terminal:

* cd .git/hooks/
* open up the 'pre-push.sample' file
* remove the .sample extension (it should just be 'pre-push') from the file name
* while in the 'pre-push' file, copy/paste the script from this location, and save the file
* chmod +x pre-push (to make script executable)
* if you're pushing up changes for a new branch, you will need to push with the '-u flag' in order for this pre-push hook to run as intended:
	git push -u origin <your-new-branch-name>

#Possible ways to move forward:
1) Each dev will have to copy/paste the script from a set location (TBD) and edit their pre-push.sample default file in the .git/hooks folder
2) symlinking so that we point to a specfic folder with our hooks.

 * You will need to remove the .sample extension from your .git/hooks/pre-push.sample file

 * These relative to your .git/hooks path. These are examples of symlinking your pre-commit and pre-push hooks.  While in the .git/hooks folder and in your command line:
  	ln -s -f ../../.git_hooks/pre-commit ./pre-commi
  	ln -s -f ../../.git_hooks/pre-push ./pre-push

* set up default dir for hooks..not sure if working, but it's added:
	git config --global init.templatedir .git_hooks/

#RANDO notes:
* exclude '.md' or '.markdown' extensions for checking for trailing whitespace
