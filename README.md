## Styleguide Tool ##  

The current rules include:  

* No debugger statements left behind in JavaScript/CoffeeScript files
* No trailing whitespace
* A single newline at the end of each file

## Using the git hook locally ##

Go to your repo in the command line:  

* cd .git/hooks/
* open up the 'pre-push.sample' file
* remove the .sample extension from the file name and save so that it's just 'pre-push'
* while in the 'pre-push' file, copy/paste the script from this location, and save the file
* to make the script executable, type chmod +x pre-push
* you're all set -- if you're pushing up changes for a new branch, you should push with the '-u flag':
	git push -u origin <your-new-branch-name>



















