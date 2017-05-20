AtomSaveCommandsGlobals = require './atom-save-commands-globals'

module.exports =
class AtomSaveCommandsView
	constructor: () ->
		# Config globals 
		@atomSaveCommandsGlobals = new AtomSaveCommandsGlobals
		
		# Create root element
		@element = document.createElement('div')
		@element.classList.add('atom-save-commands')
		@resultSetObj = {}

	# Content {Optional} - string of content you want to display
	# clsList {Required} - string of classes you want to display (separated by space)
	addData: (params) ->
		# Id is a required paramter
		# If this is not a new result the id must already exist
		id = params.id
		
		# Initial params and default values
		content = params.content || null
		clsList = params.clsList || ''
		newResult = params.newResult || false
		done = params.done || false
		
		clsList = clsList.split(" ")
		atBottom = @getIsScrolledToBottom()
		
		newDiv = document.createElement('div')
		newDiv.textContent = content
		
		# Apply is used because clsList becomes an array
		# First argument is required in order to keep context
		newDiv.classList.add.apply(newDiv.classList, clsList)
		
		# Append to base container if new result (or first item)
		# Otherwise append to the previously made result
		if newResult
			@resultSetObj[id] = {el: newDiv, done: false, id: id}
			
			@element.appendChild(newDiv)
		else
			@findResultSetEl(id, (obj) ->
				obj.el.appendChild(newDiv)
				if done
					@markCommandAsDone(obj.id)
			)
			
		@autoScrollBottom(atBottom)
	
	getIsScrolledToBottom: () ->
		# allow 1px inaccuracy by adding 1
		return @element.scrollHeight - (@element.clientHeight) <= @element.scrollTop + 1
		
	autoScrollBottom: (isScrolledToBottom) ->
		# scroll to bottom if isScrolledToBottom
		if isScrolledToBottom
			@element.scrollTop = @element.scrollHeight - (@element.clientHeight)
	
	traverseResultSetObj: (callback) ->
		for own i,child of @resultSetObj
			callback.call(@, child, i)
	
	findResultSetEl: (id, callback) ->
		@traverseResultSetObj((obj, i)->
			if obj.id == id
				callback.call(@, obj)
		)
	
	# Marks a result set as done
	markCommandAsDone: (id) ->
		@findResultSetEl(id, (obj) ->
			obj.done = true
		)
	
	# Removes all result sets that have had 'done' marked to true
	removeFinishedCommands: () ->
		@traverseResultSetObj((obj, id)->
			if obj.done
				obj.el.remove()
				delete @resultSetObj[id]
		)	
	
	# Removes all nodes from main element (container)
	clearData: ->
		@element.innerHTML = "" 
		@resultSetObj = {}
		
	# Returns an object that can be retrieved when package is activated
	serialize: ->

	# Tear down any state and detach
	destroy: ->
		@element.remove()
		
	getElement: ->
		return @element
		
	getTitle: ->
		# Used by Atom for tab text
		return 'Save Commands'
		
	getURI: ->
    	# Used by Atom to identify the view when toggling.
    	return @atomSaveCommandsGlobals.getURI()
  
  	getDefaultLocation: ->
    	# This location will be used if the user hasn't overridden it by dragging the item elsewhere.
    	return 'bottom'

  	getAllowedLocations: ->
    	# The locations into which the item can be moved.
    	return ['right', 'bottom', 'left']
