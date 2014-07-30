# ----------------------------------------------------------------------------
#  ColorPicker: Saturation selector
# ----------------------------------------------------------------------------
        Convert = require './ColorPicker-convert'

        $el = atom.workspaceView.find '#ColorPicker-saturationSelector'
        $selection = atom.workspaceView.find '#ColorPicker-saturationSelection'
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

            # Draw the saturation selector
            render: (hex) ->
                _hsl = Convert.hexToHsl hex
                _context.clearRect 0, 0, _width, _height

                # Draw the hue channel
                _gradient = _context.createLinearGradient 0, 0, _width, 1
                _gradient.addColorStop .01, '#fff'
                _gradient.addColorStop .99, "hsl(#{ _hsl[0] }, 100%, 50%)"

                _context.fillStyle = _gradient
                _context.fillRect 0, 0, _width, _height

                # Draw the saturation channel
                _gradient = _context.createLinearGradient 0, 0, 1, _height
                _gradient.addColorStop .01, 'rgba(0, 0, 0, 0)'
                _gradient.addColorStop .99, '#000'

                _context.fillStyle = _gradient
                _context.fillRect 0, 0, _width, _height

            # Returns a color from a position on the canvas
            getColorAtPosition: (positionX, positionY) ->
                _data = (_context.getImageData (positionX - 1), (positionY - 1), 1, 1).data

                return {
                    color: '#' + Convert.rgbToHex _data
                    type: 'hex'
                }
