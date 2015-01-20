# ----------------------------------------------------------------------------
#  ColorPicker
# ----------------------------------------------------------------------------

        Convert = require './ColorPicker-convert'
        VariableInspector = require './variable-inspector'
        _regexes = require './ColorPicker-regexes'

    # -------------------------------------
    #  Public functionality
    # -------------------------------------
        module.exports =
            view: null
            match: null

        #  Activate package
        # ---------------------------
            activate: ->
                atom.commands.add 'atom-text-editor',
                    'color-picker:open': => @open true

                atom.contextMenu.add '.editor': [{
                    label: 'Color picker'
                    command: 'color-picker:open'

                    shouldDisplay: => return true if @match = @getMatchAtCursor()
                }]

                return @view = new (require './ColorPicker-view')

            deactivate: -> @view.destroy()

        #  Get a match at the current cursor position
        # ---------------------------
            getMatchAtCursor: ->
                return unless _editor = atom.workspace.getActiveEditor()

                _line = _editor.getCursor().getCurrentBufferLine()
                _cursorBuffer = _editor.getCursorBufferPosition()
                _cursorRow = _cursorBuffer.row
                _cursorColumn = _cursorBuffer.column

                return @matchAtPosition _cursorColumn, (@matchesOnLine _line, _cursorRow)

        #  Match the current line against the regexes
        #  - line {String}
        #  - cursorRow {Number}
        # ---------------------------
            matchesOnLine: (line, cursorRow) ->
                return unless line and typeof cursorRow is 'number'

                _filteredMatches = []; for { type, regex } in _regexes
                    continue unless _matches = line.match regex

                    for match in _matches
                        # Skip if the match has “been used” already
                        continue if (_index = line.indexOf match) is -1

                        _filteredMatches.push
                            match: match
                            regexMatch: match.match RegExp regex.source, 'i'
                            type: type
                            index: _index
                            end: _index + match.length
                            row: cursorRow

                        # Make sure the indices are correct by removing
                        # the instances from the string after use
                        line = line.replace match, (Array match.length + 1).join ' '
                return unless _filteredMatches.length > 0

                return _filteredMatches

        #  Get a single match on a position based on a match array
        #  as seen in matchesOnLine
        #  - column {Number}
        #  - matches {Array}
        # ---------------------------
            matchAtPosition: (column, matches) ->
                return unless column and matches

                _match = do -> for match in matches
                    if match.index <= column and match.end >= column
                        return match
                return _match

            open: (getMatch = false) ->
                return unless _editor = atom.workspace.getActiveEditor()
                @match = @getMatchAtCursor() if getMatch

                if not @match
                    randomRGBFragment = -> (Math.random() * 255) << 0

                    _line = '#' + Convert.rgbToHex [randomRGBFragment(), randomRGBFragment(), randomRGBFragment()]
                    _cursorBuffer = _editor.getCursorBufferPosition()
                    _cursorRow = _cursorBuffer.row
                    _cursorColumn = _cursorBuffer.column

                    _match = (@matchesOnLine _line, _cursorRow)[0]
                    _match.index = _cursorColumn
                    _match.end = _cursorColumn

                    @match = _match
                return unless @match

                @view.reset()
                @setMatchColor()
                @view.open()

        #  Set the color of a match to its object, and then send it
        #  to the color picker view
        #  - match {Object}
        #  - callback {Function}
        # ---------------------------
            setMatchColor: ->
                return unless @match

                @view.storage.selectedColor = null

                if @match.hasOwnProperty 'color'
                    @view.storage.selectedColor = @match
                    @view.inputColor @match
                    return

                _callback = => @setMatchColor()

                switch @match.type
                    when 'variable:sass' then @setVariableDefinitionColor @match, _callback
                    when 'variable:less' then @setVariableDefinitionColor @match, _callback
                    else do => @match.color = @match.match; _callback @match
                return

        #  Set the variable definition by sending it through a
        #  provided callback when found
        #  - match {Object}
        #  - callback {Function}
        # ---------------------------
            setVariableDefinitionColor: (match, callback) ->
                return unless match and callback

                _matchRegex = regex for { type, regex } in _regexes when type is match.type
                _variableName = (match.match.match RegExp _matchRegex.source, 'i')[2] # hahaha

                (@findVariableDefinition _variableName, match.type).then ({ color, pointer }) ->
                    match.color = color.match
                    match.type = color.type
                    match.pointer = pointer

                    callback match
                return

        #  Find variable definition by searching recursively until a
        #  non-variable (a color) is found
        #  - name {String}
        #  - type {String}
        # ---------------------------
            findVariableDefinition: (name, type, pointer) ->
                return (VariableInspector.findDefinition name, type).then (definition) =>
                    pointer ?= definition.pointer # remember the initial pointer
                    _matches = @matchesOnLine definition.definition, 1

                    return @view.error() unless _matches and _color = _matches[0]

                    # Continue digging for the truth and real definition
                    if (_color.type.split ':')[0] is 'variable'
                        return @findVariableDefinition _color.regexMatch[2], _color.type, pointer

                    return { color: _color, pointer: pointer }
