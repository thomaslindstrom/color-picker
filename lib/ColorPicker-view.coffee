# ----------------------------------------------------------------------------
#  Color Picker: view
# ----------------------------------------------------------------------------

    module.exports = ->
        Parent: null

        SmartColor: (require './modules/SmartColor')()
        SmartVariable: (require './modules/SmartVariable')()
        Emitter: (require './modules/Emitter')()

        extensions: {}
        getExtension: (extensionName) -> @extensions[extensionName]

        isFirstOpen: yes
        canOpen: yes
        element: null
        selection: null

        listeners: []

    # -------------------------------------
    #  Create and activate Color Picker view
    # -------------------------------------
        activate: ->
            _workspace = atom.workspace
            _workspaceView = atom.views.getView _workspace

        #  Create element
        # ---------------------------
            @element =
                el: do ->
                    _el = document.createElement 'div'
                    _el.classList.add 'ColorPicker'

                    return _el
                # Utility functions
                remove: -> @el.parentNode.removeChild @el

                addClass: (className) -> @el.classList.add className; return this
                removeClass: (className) -> @el.classList.remove className; return this
                hasClass: (className) -> @el.classList.contains className

                width: -> @el.offsetWidth
                height: -> @el.offsetHeight

                setHeight: (height) -> @el.style.height = "#{ height }px"

                hasChild: (child) ->
                    if child and _parent = child.parentNode
                        if child is @el
                            return true
                        else return @hasChild _parent
                    return false

                # Open & Close the Color Picker
                isOpen: -> @hasClass 'is--open'
                open: -> @addClass 'is--open'
                close: -> @removeClass 'is--open'

                # Flip & Unflip the Color Picker
                isFlipped: -> @hasClass 'is--flipped'
                flip: -> @addClass 'is--flipped'
                unflip: -> @removeClass 'is--flipped'

                # Set Color Picker position
                # - x {Number}
                # - y {Number}
                setPosition: (x, y) ->
                    @el.style.left = "#{ x }px"
                    @el.style.top = "#{ y }px"
                    return this

                # Add a child on the ColorPicker element
                add: (element) ->
                    @el.appendChild element
                    return this
            @loadExtensions()

        #  Close the Color Picker on any activity unrelated to it
        #  but also emit events on the Color Picker
        # ---------------------------
            @listeners.push ['mousedown', onMouseDown = (e) =>
                return unless @element.isOpen()

                _isPickerEvent = @element.hasChild e.target
                @emitMouseDown e, _isPickerEvent
                return @close() unless _isPickerEvent]
            window.addEventListener 'mousedown', onMouseDown, true

            @listeners.push ['mousemove', onMouseMove = (e) =>
                return unless @element.isOpen()

                _isPickerEvent = @element.hasChild e.target
                @emitMouseMove e, _isPickerEvent]
            window.addEventListener 'mousemove', onMouseMove, true

            @listeners.push ['mouseup', onMouseUp = (e) =>
                return unless @element.isOpen()

                _isPickerEvent = @element.hasChild e.target
                @emitMouseUp e, _isPickerEvent]
            window.addEventListener 'mouseup', onMouseUp, true

            @listeners.push ['mousewheel', onMouseWheel = (e) =>
                return unless @element.isOpen()

                _isPickerEvent = @element.hasChild e.target
                @emitMouseWheel e, _isPickerEvent]
            window.addEventListener 'mousewheel', onMouseWheel

            _workspaceView.addEventListener 'keydown', (e) =>
                return unless @element.isOpen()

                _isPickerEvent = @element.hasChild e.target
                @emitKeyDown e, _isPickerEvent
                return @close()

            # Close it on scroll also
            atom.workspace.observeTextEditors (editor) =>
                _editorView = atom.views.getView editor
                _subscriptionTop = _editorView.onDidChangeScrollTop => @close()
                _subscriptionLeft = _editorView.onDidChangeScrollLeft => @close()

                editor.onDidDestroy ->
                    _subscriptionTop.dispose()
                    _subscriptionLeft.dispose()
                @onBeforeDestroy ->
                    _subscriptionTop.dispose()
                    _subscriptionLeft.dispose()
                return

            # Close it when the window resizes
            @listeners.push ['resize', onResize = =>
                @close()]
            window.addEventListener 'resize', onResize

            # Close it when the active item is changed
            _workspace.getActivePane().onDidChangeActiveItem => @close()

        #  Place the Color Picker element
        # ---------------------------
            @close()
            @canOpen = yes

            # TODO: Is this really the best way to do this? Hint: Probably not
            (@Parent = (atom.views.getView atom.workspace).querySelector '.vertical')
                .appendChild @element.el
            return this

    # -------------------------------------
    #  Destroy the view and unbind events
    # -------------------------------------
        destroy: ->
            @emitBeforeDestroy()

            for [_event, _listener] in @listeners
                window.removeEventListener _event, _listener

            @element.remove()
            @canOpen = no

    # -------------------------------------
    #  Load Color Picker extensions // more like dependencies
    # -------------------------------------
        loadExtensions: ->
            # TODO: This is really stupid. Should this be done with `fs` or something?
            # TODO: Extension files have pretty much the same base. Simplify?
            for _extension in ['Arrow', 'Color', 'Body', 'Saturation', 'Alpha', 'Hue', 'Definition', 'Return', 'Format']
                _requiredExtension = (require "./extensions/#{ _extension }")(this)
                @extensions[_extension] = _requiredExtension
                _requiredExtension.activate?()
            return

    # -------------------------------------
    #  Set up events and handling
    # -------------------------------------
        # Mouse events
        emitMouseDown: (e, isOnPicker) ->
            @Emitter.emit 'mouseDown', e, isOnPicker
        onMouseDown: (callback) ->
            @Emitter.on 'mouseDown', callback

        emitMouseMove: (e, isOnPicker) ->
            @Emitter.emit 'mouseMove', e, isOnPicker
        onMouseMove: (callback) ->
            @Emitter.on 'mouseMove', callback

        emitMouseUp: (e, isOnPicker) ->
            @Emitter.emit 'mouseUp', e, isOnPicker
        onMouseUp: (callback) ->
            @Emitter.on 'mouseUp', callback

        emitMouseWheel: (e, isOnPicker) ->
            @Emitter.emit 'mouseWheel', e, isOnPicker
        onMouseWheel: (callback) ->
            @Emitter.on 'mouseWheel', callback

        # Key events
        emitKeyDown: (e, isOnPicker) ->
            @Emitter.emit 'keyDown', e, isOnPicker
        onKeyDown: (callback) ->
            @Emitter.on 'keyDown', callback

        # Position Change
        emitPositionChange: (position, colorPickerPosition) ->
            @Emitter.emit 'positionChange', position, colorPickerPosition
        onPositionChange: (callback) ->
            @Emitter.on 'positionChange', callback

        # Opening
        emitOpen: ->
            @Emitter.emit 'open'
        onOpen: (callback) ->
            @Emitter.on 'open', callback

        # Before opening
        emitBeforeOpen: ->
            @Emitter.emit 'beforeOpen'
        onBeforeOpen: (callback) ->
            @Emitter.on 'beforeOpen', callback

        # Closing
        emitClose: ->
            @Emitter.emit 'close'
        onClose: (callback) ->
            @Emitter.on 'close', callback

        # Before destroying
        emitBeforeDestroy: ->
            @Emitter.emit 'beforeDestroy'
        onBeforeDestroy: (callback) ->
            @Emitter.on 'beforeDestroy', callback

        # Input Color
        emitInputColor: (smartColor, wasFound=true) ->
            @Emitter.emit 'inputColor', smartColor, wasFound
        onInputColor: (callback) ->
            @Emitter.on 'inputColor', callback

        # Input Variable
        emitInputVariable: (match) ->
            @Emitter.emit 'inputVariable', match
        onInputVariable: (callback) ->
            @Emitter.on 'inputVariable', callback

        # Input Variable Color
        emitInputVariableColor: (smartColor, pointer) ->
            @Emitter.emit 'inputVariableColor', smartColor, pointer
        onInputVariableColor: (callback) ->
            @Emitter.on 'inputVariableColor', callback

    # -------------------------------------
    #  Open the Color Picker
    # -------------------------------------
        open: (Editor=null, Cursor=null) ->
            return unless @canOpen
            @emitBeforeOpen()

            Editor = atom.workspace.getActiveTextEditor() unless Editor
            EditorView = atom.views.getView Editor

            return unless EditorView
            EditorRoot = EditorView.shadowRoot or EditorView

            # Reset selection
            @selection = null

        #  Find the current cursor
        # ---------------------------
            Cursor = Editor.getLastCursor() unless Cursor

            # Fail if the cursor isn't visible
            _visibleRowRange = EditorView.getVisibleRowRange()
            _cursorScreenRow = Cursor.getScreenRow()
            _cursorBufferRow = Cursor.getBufferRow()

            return if (_cursorScreenRow < _visibleRowRange[0]) or (_cursorScreenRow > _visibleRowRange[1])

            # Try matching the contents of the current line to color regexes
            _lineContent = Cursor.getCurrentBufferLine()

            _colorMatches = @SmartColor.find _lineContent
            _variableMatches = @SmartVariable.find _lineContent, Editor.getPath()
            _matches = _colorMatches.concat _variableMatches

            # Figure out which of the matches is the one the user wants
            _cursorColumn = Cursor.getBufferColumn()
            _match = do -> for _match in _matches
                return _match if _match.start <= _cursorColumn and _match.end >= _cursorColumn

            # If we've got a match, we should select it
            if _match
                Editor.clearSelections()

                _selection = Editor.addSelectionForBufferRange [
                    [_cursorBufferRow, _match.start]
                    [_cursorBufferRow, _match.end]]
                @selection = match: _match, row: _cursorBufferRow
            # But if we don't have a match, center the Color Picker on last cursor
            else
                _cursorPosition = Cursor.getPixelRect()
                @selection = column: Cursor.getBufferColumn(), row: _cursorBufferRow

        #  Emit
        # ---------------------------
            if _match
                # The match is a variable. Look up the definition
                if _match.isVariable?
                    _match.getDefinition()
                        .then (definition) =>
                            _smartColor = (@SmartColor.find definition.value)[0].getSmartColor()
                            @emitInputVariableColor _smartColor, definition.pointer
                        .catch (error) =>
                            @emitInputVariableColor false
                    @emitInputVariable _match
                # The match is a color
                else @emitInputColor _match.getSmartColor()
            # No match, but `randomColor` option is set
            else if atom.config.get 'color-picker.randomColor'
                _randomColor = @SmartColor.RGBArray [
                    ((Math.random() * 255) + .5) << 0
                    ((Math.random() * 255) + .5) << 0
                    ((Math.random() * 255) + .5) << 0]

                # Convert to `preferredColor`, and then emit it
                _preferredFormat = atom.config.get 'color-picker.preferredFormat'
                _convertedColor = _randomColor["to#{ _preferredFormat }"]()
                _randomColor = @SmartColor[_preferredFormat](_convertedColor)

                @emitInputColor _randomColor, false
            # No match, and it's the first open
            else if @isFirstOpen
                _redColor = @SmartColor.HEX '#f00'

                # Convert to `preferredColor`, and then emit it
                _preferredFormat = atom.config.get 'color-picker.preferredFormat'

                if _redColor.format isnt _preferredFormat
                    _convertedColor = _redColor["to#{ _preferredFormat }"]()
                    _redColor = @SmartColor[_preferredFormat](_convertedColor)
                @isFirstOpen = no

                @emitInputColor _redColor, false

        #  After (& if) having selected text (as this might change the scroll
        #  position) gather information about the Editor
        # ---------------------------
            PaneView = atom.views.getView atom.workspace.getActivePane()
            _paneOffsetTop = PaneView.offsetTop
            _paneOffsetLeft = PaneView.offsetLeft

            _editorOffsetTop = EditorView.parentNode.offsetTop
            _editorOffsetLeft = EditorRoot.querySelector('.scroll-view').offsetLeft
            _editorScrollTop = EditorView.getScrollTop()

            _lineHeight = Editor.getLineHeightInPixels()
            _lineOffsetLeft = EditorRoot.querySelector('.line').offsetLeft

            # Center it on the middle of the selection range
            # TODO: There can be lines over more than one row
            if _match
                _rect = EditorView.pixelRectForScreenRange(_selection.getScreenRange())
                _right = _rect.left + _rect.width
                _cursorPosition = Cursor.getPixelRect()
                _cursorPosition.left = _right - (_rect.width / 2)

        #  Figure out where to place the Color Picker
        # ---------------------------
            _totalOffsetTop = _paneOffsetTop + _cursorPosition.height - _editorScrollTop + _editorOffsetTop
            _totalOffsetLeft = _paneOffsetLeft + _editorOffsetLeft + _lineOffsetLeft

            _position =
                x: _cursorPosition.left + _totalOffsetLeft
                y: _cursorPosition.top + _totalOffsetTop

        #  Figure out where to actually place the Color Picker by
        #  setting up boundaries and flipping it if necessary
        # ---------------------------
            _colorPickerPosition =
                x: do =>
                    _colorPickerWidth = @element.width()
                    _halfColorPickerWidth = (_colorPickerWidth / 2) << 0

                    # Make sure the Color Picker isn't too far to the left
                    _x = Math.max 10, _position.x - _halfColorPickerWidth
                    # Make sure the Color Picker isn't too far to the right
                    _x = Math.min (@Parent.offsetWidth - _colorPickerWidth - 10), _x

                    return _x
                y: do =>
                    @element.unflip()

                    # TODO: It's not really working out great

                    # If the color picker is too far down, flip it
                    if @element.height() + _position.y > @Parent.offsetHeight - 32
                        @element.flip()
                        return _position.y - _lineHeight - @element.height()
                    # But if it's fine, keep the Y position
                    else return _position.y

            # Set Color Picker position and emit events
            @element.setPosition _colorPickerPosition.x, _colorPickerPosition.y
            @emitPositionChange _position, _colorPickerPosition

            # Open the Color Picker
            requestAnimationFrame => # wait for class delay
                @element.open()
                @emitOpen()
            return true

    # -------------------------------------
    #  Replace selected color
    # -------------------------------------
        canReplace: yes
        replace: (color) ->
            return unless @canReplace
            @canReplace = no

            Editor = atom.workspace.getActiveTextEditor()
            Editor.clearSelections()

            if @selection.match
                _cursorStart = @selection.match.start
                _cursorEnd = @selection.match.end
            else _cursorStart = _cursorEnd = @selection.column

            # Select the color we're going to replace
            Editor.addSelectionForBufferRange [
                [@selection.row, _cursorStart]
                [@selection.row, _cursorEnd]]
            Editor.replaceSelectedText null, => color

            # Select the newly inserted color and move the cursor to it
            setTimeout =>
                Editor.setCursorBufferPosition [
                    @selection.row, _cursorStart]
                Editor.clearSelections()

                # Update selection length
                @selection.match?.end = _cursorStart + color.length

                Editor.addSelectionForBufferRange [
                    [@selection.row, _cursorStart]
                    [@selection.row, _cursorStart + color.length]]
                return setTimeout ( => @canReplace = yes), 100
            return

    # -------------------------------------
    #  Close the Color Picker
    # -------------------------------------
        close: ->
            @element.close()
            @emitClose()
