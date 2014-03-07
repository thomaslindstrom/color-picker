# ----------------------------------------------------------------------------
#  Color Picker
# ----------------------------------------------------------------------------

        ConditionalContextMenu = require './conditional-contextmenu'

    # -------------------------------------
    #  Color regex matchers
    # -------------------------------------
        COLOR_REGEXES = [
            # Matches HEX + A: eg
            # rgba(#fff, 0.3) and rgba(#000000, .8)
            { type: 'hexa', regex: /(rgba\(((\#[a-f0-9]{6}|\#[a-f0-9]{3}))\s*,\s*(0|1|0*\.\d+)\))/ig }

            # Matches RGB + A: eg.
            # rgba(0, 99, 199, 0.3)
            { type: 'rgba', regex: /(rgba\(((([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\s*,\s*([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\s*,\s*([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])))\s*,\s*(0|1|0*\.\d+)\))/ig }

            # Matches RGB: eg.
            # rgb(0, 99, 199)
            { type: 'rgb', regex: /(rgb\(([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\s*,\s*([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\s*,\s*([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\))/ig }

            # Matches HEX:
            # eg. #000 and #ffffff
            { type: 'hex', regex: /(\#[a-f0-9]{6}|\#[a-f0-9]{3})/ig }
        ]

    # -------------------------------------
    #  Public functionality
    # -------------------------------------
        module.exports =
            view: null
            color: null

            activate: ->
                atom.workspaceView.command "color-picker:open", => @open()

                ConditionalContextMenu.item {
                    label: 'Color picker'
                    command: 'color-picker:open',
                }, => return true if @color = @getColorAtCursor()

                ColorPickerView = require './ColorPicker-view'
                @view = new ColorPickerView

            deactivate: -> @view.destroy()

            getColorAtCursor: ->
                _editor = atom.workspace.getActiveEditor()
                return unless _editor

                _line = _editor.getCursor().getCurrentBufferLine()
                _cursorBuffer = _editor.getCursorBufferPosition()
                _cursorRow = _cursorBuffer.row
                _cursorColumn = _cursorBuffer.column

                _matches = []

                # Match the current line against the regexes to get the colors
                for colorRegex in COLOR_REGEXES
                    type = colorRegex.type
                    regex = colorRegex.regex

                    continue unless _colors = _line.match regex

                    for color in _colors
                        continue if (_index = _line.indexOf color) is -1

                        _matches.push
                            color: color
                            type: type
                            index: _index
                            end: _index + color.length
                            row: _cursorRow

                        # Make sure the indices are correct by removing
                        # the instances from the string after use
                        _line = _line.replace color, (new Array color.length + 1).join ' '
                return unless _matches.length > 0

                # Find the "selected" color by looking at caret position
                _color = do -> for color in _matches
                    if color.index <= _cursorColumn and color.end >= _cursorColumn
                        return color
                return _color

            open: ->
                return unless @color

                @view.open()
                @view.storage.selectedColor = @color
                @view.inputColor @color
                @view.selectColor()
