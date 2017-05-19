minimatch = require 'minimatch'
child_process = require 'child_process'
path = require 'path'
S = require 'string'
spawn = require 'cross-spawn-async'
_ = require 'underscore'
fs = require 'fs'
async = require 'async'

AtomSaveCommandsGlobals = require './atom-save-commands-globals'
AtomSaveCommandsView = require './atom-save-commands-view'
{CompositeDisposable,Disposable,Directory,File} = require 'atom'

module.exports = AtomSaveCommands =
	atomSaveCommandsView: null
	atomSaveCommandsGlobals: new AtomSaveCommandsGlobals
	modalPanel: null
	subscriptions: null

	config:
		# saveCommands:
		# 	type: 'array'
		# 	default: []
		# 	items:
		# 		type: 'string'
		# 	title: 'Glob : command'
		# 	description: '''
		# 		Executes commands on save for files matching the glob.
		# 		Command can contain parameters:
		# 		{absPath}: absolute path of the saved file (without file name)
		# 		{relPath}: relative path of the saved file (without file name)
		# 		{relFullPath}: like relPath but with filename
		# 		{relPathNoRoot}: relative path without top folder
		# 		{filename}: file name and extension
		# 		{name}: file name without extension
		# 		{ext}: file extension
		# 		{sep}: os specific path separator
		#
		# 		To configure multiple globs, use File -> Open your config
		# 	'''
		# timeoutDuration:
		# 	type: 'integer'
		# 	default: '4000'
		# 	title: 'Output panel timeout duration in ms'

		suppressPanel:
			type: 'boolean'
			default: 'false'
			title: 'Only display command output panel on error'

	showError: (gc)->
		epanel = atom.workspace.addBottomPanel(
			item: document.createElement('div')
			visible: true
			priority: 100
		)
		@resultDiv = document.createElement('div')
		@resultDiv.classList.add('save-result')
		@resultDiv.classList.add('save-result-visible')
		@resultDiv.classList.add('save-result-error') 
		epanel.item.appendChild(@resultDiv)
		setTimeout ()->
			epanel.destroy()
		, @config.timeout

	convertCommand: (eventPath, command) ->
			relativePath = atom.project.relativize(eventPath)
			apo = path.parse eventPath
			rpo = path.parse relativePath
			model = {}
			model.absPath = apo.dir + path.sep
			model.relPath = rpo.dir
			index = rpo.dir.indexOf(path.sep)
			model.relPathNoRoot = rpo.dir.substr(index) if index isnt -1
			model.relPathNoRoot = '' if index is -1
			if model.relPath isnt ''
				model.relPath += path.sep
			if model.relPathNoRoot isnt ''
				model.relPathNoRoot += path.sep
			model.name = rpo.name
			model.ext = rpo.ext
			model.filename = rpo.base
			model.relFullPath = model.relPath + model.filename
			model.sep = path.sep
			for key,value of model
				fkey = '{' + key + '}'
				command = S(command).replaceAll(fkey,value).s
			command

	executeCommand: (command, callback) ->
		# console.log "COMMAND #{command}"
		
		@atomSaveCommandsView.addData(command, 'command-name', false)
		
		cmdarr = command.split(' ')
		command = cmdarr[0]
		args = _.rest(cmdarr)
		cspr = spawn command, args ,
			cwd: @config.cwd

		suppress = atom.config.get('save-commands.suppressPanel')
		if suppress is false
			@display true

		div = atom.views.getView(atom.workspace).getElementsByClassName('save-result')[0]

		cspr.stdout.on 'data', (data)=>
			# console.log "STD OUT: #{data}"
			
			@atomSaveCommandsView.addData(data.toString(), 'save-result-out', false)

		cspr.stderr.on 'data', (data)=>
			# console.log "ERR OUT: #{data}"
			@display true
			@hasError = true
			
			@atomSaveCommandsView.addData(data.toString(), 'save-result-error', false)

		cspr.stdout.on 'close', (code,signal)=>
			# console.log "STD CLOSE"
			# callback()

		cspr.stderr.on 'close', (code,signal)=>
			# console.log "ERR CLOSE"
			setTimeout ()=>
				callback()
			,100

	activate: () ->
		@atomSaveCommandsView = new AtomSaveCommandsView
		# @modalPanel = atom.workspace.addModalPanel(item: @atomSaveCommandsView.getElement(), visible: false)

		# Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
		@subscriptions = new CompositeDisposable

		# Register command that toggles this view
		# @subscriptions.add atom.commands.add 'atom-workspace',
		# 	'save-commands:executeOn': =>
		# 		treeView = atom.packages.getLoadedPackage('tree-view')
		# 		if treeView
		# 			treeView = require(treeView.mainModulePath)
		# 			packageObj = treeView.serialize()
		# 			source = packageObj.selectedPath
		# 			@executeOn(source,'save-commands.json')
		#
		# @subscriptions.add atom.commands.add 'atom-workspace',
		# 	'save-commands:executeBatchOn': =>
		# 		treeView = atom.packages.getLoadedPackage('tree-view')
		# 		if treeView
		# 			treeView = require(treeView.mainModulePath)
		# 			packageObj = treeView.serialize()
		# 			source = packageObj.selectedPath
		# 			@executeOn(source,'batch-save-commands.json')

		@subscriptions.add atom.workspace.addOpener (uri) =>			
			if uri == @atomSaveCommandsGlobals.getURI()
				@atomSaveCommandsView 
				
				
		@subscriptions.add new Disposable(-> 
			atom.workspace.getPaneItems().forEach (item) ->
				if item instanceof AtomSaveCommandsView
					item.destroy()
		)
			
		@subscriptions.add atom.workspace.observeTextEditors (editor)=>
			# Try should prevent json file from being required
			@subscriptions.add editor.onDidSave (event)=>
				try
					@executeOn(event.path,'save-commands.json') 
				catch error
					console.log error
					
		# @display true

		@atomSaveCommandsView.addData(null, 'save-result', true)

		@subscriptions.add atom.commands.add 'atom-workspace',
			'core:cancel': =>
				@display false

	display: (bool)->
		if typeof bool == "boolean"
			if bool
				atom.workspace.open(@atomSaveCommandsGlobals.getURI())
			else
				atom.workspace.hide(@atomSaveCommandsGlobals.getURI())

	tap: (o, fn) -> fn(o); o

	merge: (xs...) ->
		if xs?.length > 0
			@tap {}, (m) -> m[k] = v for k, v of x for x in xs

	loadConfig: (editorPath, filename,callback)->
		dir = new File(editorPath).getParent()
		while (true)
			confFile = dir.getPath() + path.sep + filename
			file = new File(confFile)
			exists = file.existsSync()
			isRoot = dir.isRoot()
			if isRoot and exists is false
				throw "Missing config file #{filename} on the path"
			break if isRoot or exists
			dir = dir.getParent()

		timeout 	= atom.config.get('save-commands.timeout')	# Load global configurations
		commands 	= atom.config.get('save-commands.commands')
		@config = {}
		# @config.timeout 	= timeout ? 4000
		# @config.commands	= commands ? []

		splitOnce = (text,sep)->
			components = text.split(sep)
			return [components.shift(), components.join(sep)]

		fs.readFile confFile, (err,data)=>
			if data
				try
					parsed = JSON.parse(data)
				catch e
					alert("Your config file is not a valid JSON")
					return
				@config = @merge @config, parsed

			@config.cwd = dir.getPath()

			splitOnce = (str,sep)->
				components = str.split(sep)
				[components.shift(), components.join(sep)]

			modCommands = []
			for gc in @config.commands
				kv = splitOnce(gc,':')
				modCommands.push
					glob: kv[0].trim()
					command: kv[1].trim()

			@config.commands = modCommands
			callback @config

	deactivate: ->
		@subscriptions.dispose()

	executeOn: (path,configFile)->
		@display false
		suppressPanel = atom.config.get('save-commands.suppressPanel')	# Load global configurations
		@loadConfig path, configFile, ()=>
			@getFilesOn path, (files)=>
				commands = []
				for file in files
					commands = _.union commands, @getCommandsFor(file)
				if commands.length > 0
					if !suppressPanel
						@display true
					@hasError = false

					cleanup = (err)->
						setTimeout ()=>
							@atomSaveCommandsView.addData('Done.', 'command-name', false)
						,100

					async.eachSeries commands, @executeCommand.bind(@), cleanup.bind(@)


	getFilesOn: (absPath, callback)->
		fs.lstat absPath, (err,stats)=>
			if stats.isDirectory()
				fs.readdir absPath, (err,files)=>
					f = []
					async.eachSeries files, (file,fileCb)=>
						@getFilesOn "#{absPath}#{path.sep}#{file}", (filesX)->
							f = _.union f, filesX
							fileCb()
					, (err)->
						# console.log "Folder #{absPath} contains #{f.length} files"
						callback(f)

			if stats.isFile()
				callback [absPath]

	getCommandsFor: (file)->
		# console.log "Commands for #{file}:"
		commands = []
		for cmd in @config.commands
			relativePath = atom.project.relativize(file)
			if minimatch(relativePath, cmd.glob)
				commands.push @convertCommand(file, cmd.command)

		# for com in commands
		# 	console.log "  #{com}"
		return commands
