## 0.9.1
* Added 'Delete old command' setting to potentially preserve log
* Made panel close on save if suppress panel is enabled

## 0.9.0
* Fixed issue with not deleting old results
* Fixed issue preventing errors from displaying
* Added proper handling of multiple commands being run
* Error result will now open when the errors only setting is enabled
* Pane is now always being logged to but only automatically opens when supposed to
* Added unique identifiers to each result set for better management

## 0.8.0
* Forked original project by Jason Hunt (JsonHunt) to create a package with new functionality, and more user friendly features.
* Added proper auto scrolling
* Now using dock instead of panel for easier handling of display

## 0.6.8
* removed menu items from file tree

## 0.6.7
* fixed issues with special characters in linux shell commands
* fixed issues with : in commands
* fixed issues with multiple project folders
* fixed bugs causing package to crash while executing
* removed configuration via atom settings
* changed how package looks for configuration file

## 0.6.1
* fixed issues with behavior of notification panel
* added 'suppress panel' setting

## 0.5.4
* panel will automatically hide after specified timeout if no errors were generates

## 0.5.2
* Removed output from stdout, kept output from stderr
* Removed panel header
* Added auto scrolling

## 0.5.1
* added batch commands for folders
* only one panel is now displayed
* removed fake options from menus

## 0.4.1
* configuration moved to save-commands.json
* commands now executed in sequence one after another
* using win-spawn for better command output
* added cwd config option

## 0.3.1
* Fixed path error for top-level project files
* relPath, absPath and relPathNoRoot now contain trailing separator
* added sep and relFullPath command options
* panel timeout moved out of the child process callback
* added better config description
* updated Readme.md
* added panel timeout duration to config
* added better handling of malformed configuration
* added newline support for output panels
* Fixed error when no commands are configured

## 0.1.0 - First Release
