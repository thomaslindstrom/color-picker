# ----------------------------------------------------------------------------
#  ColorPicker: Hue selector
# ----------------------------------------------------------------------------
        Convert = require './ColorPicker-convert'
        _hexes = ['FF0000', 'FFFF00', '00FF00', '00FFFF', '0000FF', 'FF00FF', 'FF0000']

        $el = atom.workspaceView.find '#ColorPicker-hueSelector'
        $selection = atom.workspaceView.find '#ColorPicker-hueSelection'
        _context = $el[0].getContext '2d'
        _width = $el.width()
        _height = $el.height()

    # -------------------------------------
    #  Public functionality
    # -------------------------------------
        module.exports =
            $el: $el
            $selection: $selection
            width: _width
            height: _height

            # Draw the hue selector gradient
            render: ->
                _gradient = _context.createLinearGradient 0, 0, 1, _height
                _step = 1 / (_hexes.length - 1)

                _gradient.addColorStop (_step * i), hex for hex, i in _hexes
                _context.fillStyle = _gradient
                _context.fillRect 0, 0, _width, _height

            # Returns a color from a position on the canvas
            getColorAtPosition: (positionY) ->
                _data = (_context.getImageData 1, (positionY - 1), 1, 1).data

                return {
                    color: ('#' + Convert.rgbToHex _data),
                    type: 'hex'
                }
