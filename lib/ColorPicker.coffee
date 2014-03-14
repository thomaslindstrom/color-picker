# ----------------------------------------------------------------------------
#  ColorPicker
# ----------------------------------------------------------------------------

        ConditionalContextMenu = require './conditional-contextmenu'
        VariableInspector = require './variable-inspector'

        _regexes = require './ColorPicker-regexes.coffee'

    # -------------------------------------
    #  Public functionality
    # -------------------------------------
        module.exports =
            view: null
            match: null

            activate: ->
                atom.workspaceView.command "color-picker:open", => @open true

                ConditionalContextMenu.item {
                    label: 'Color picker'
                    command: 'color-picker:open',
                }, => return true if @match = @getMatchAtCursor()

                ColorPickerView = require './ColorPicker-view'
                @view = new ColorPickerView

            deactivate: -> @view.destroy()

            # Get a match at the current cursor position
            getMatchAtCursor: ->
                _editor = atom.workspace.getActiveEditor()
                return unless _editor

                _line = _editor.getCursor().getCurrentBufferLine()
                _cursorBuffer = _editor.getCursorBufferPosition()
                _cursorRow = _cursorBuffer.row
                _cursorColumn = _cursorBuffer.column

                return @matchAtPosition _cursorColumn, (@matchesOnLine _line, _cursorRow)

            # Match the current line against the regexes
            # @String line
            # @Number cursorRow
            matchesOnLine: (line, cursorRow) ->
                return unless line and cursorRow

                _filteredMatches = []; for { type, regex } in _regexes
                    continue unless _matches = line.match regex

                    for match in _matches
                        # Skip if the match has “been used” already
                        continue if (_index = line.indexOf match) is -1

                        _filteredMatches.push
                            match: match
                            type: type
                            index: _index
                            end: _index + match.length
                            row: cursorRow

                        # Make sure the indices are correct by removing
                        # the instances from the string after use
                        line = line.replace match, (Array match.length + 1).join ' '
                return unless _filteredMatches.length > 0

                return _filteredMatches

            # Get a single match on a position based on a match array
            # as seen in matchesOnLine
            # @Number column
            # @Array matches
            matchAtPosition: (column, matches) ->
                return unless column and matches

                _match = do -> for match in matches
                    if match.index <= column and match.end >= column
                        return match
                return _match

            open: (getMatch = false) ->
                if getMatch then @match = @getMatchAtCursor()

                return unless @match
                @view.reset()
                @setMatchColor()
                @view.open()

            # Set the color of a match to its object, and then send it
            # to the color picker view
            # @Object match
            # @Function callback
            setMatchColor: ->
                return unless @match

                @view.storage.selectedColor = null

                if @match.hasOwnProperty 'color'
                    @view.storage.selectedColor = @match
                    @view.inputColor @match
                    return

                _callback = => @setMatchColor()

                return switch @match.type
                    when 'variable:sass' then @setVariableDefinitionColor @match, _callback
                    when 'variable:less' then @setVariableDefinitionColor @match, _callback
                    else do => @match.color = @match.match; _callback @match

            # Look up a variable definition, and if the definition is a
            # color, return it
            # @Object match
            # @Function callback
            setVariableDefinitionColor: (match, callback) ->
                return unless match and callback

                _matchRegex = regex for { type, regex } in _regexes when type is match.type
                _variableName = (match.match.match RegExp _matchRegex.source, 'i')[2] # hahaha

                (VariableInspector.findDefinition _variableName, match.type).then (definition) =>
                    _matches = @matchesOnLine definition.definition, 1

                    return @view.error() unless _matches and _color = _matches[0]
                    return @view.error() if (_color.type.split ':')[0] is 'variable'

                    match.color = _color.match
                    match.type = _color.type
                    match.pointer = definition.pointer
                    callback match
