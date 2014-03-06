# ----------------------------------------------------------------------------
#  Color Picker
# ----------------------------------------------------------------------------

    # -------------------------------------
    #  Color regex matchers
    # -------------------------------------
        COLOR_REGEXES = [
            # Matches HEX + A: eg
            # rgba(#fff, 0.3)
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

            activate: ->
                atom.workspaceView.command "color-picker:open", => @open()
                ColorPickerView = require './ColorPicker-view'
                @view = new ColorPickerView

            open: ->
                _editor = atom.workspace.getActiveEditor()
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

                        # Make sure the indexes are correct by removing
                        # the instances from the string after use
                        _line = _line.replace color, (new Array color.length + 1).join ' '

                # Find the "selected" color by looking at caret position
                _color = do -> for color in _matches
                    if color.index <= _cursorColumn and color.end >= _cursorColumn
                        return color
                return unless _color

                @view.open()
                @view.storage.selectedColor = _color
                @view.inputColor _color
                @view.selectColor()
