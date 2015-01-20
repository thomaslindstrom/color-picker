# ----------------------------------------------------------------------------
#  ColorPicker: Hue selector
# ----------------------------------------------------------------------------

    module.exports = (picker) ->
        Convert = require './ColorPicker-convert'
        _hexes = ['#FF0000', '#FFFF00', '#00FF00', '#00FFFF', '#0000FF', '#FF00FF', '#FF0000']
        _hexesLength = _hexes.length

        _el = picker.querySelector '#ColorPicker-hueSelector'
        _selection = picker.querySelector '#ColorPicker-hueSelection'
        _context = _el.getContext '2d'
        _width = _el.offsetWidth
        _height = _el.offsetHeight

    # -------------------------------------
    #  Public functionality
    # -------------------------------------
        return {
            el: _el
            width: _width
            height: _height

        #  Draw the hue selector gradient
        # ---------------------------
            render: ->
                _gradient = _context.createLinearGradient 0, 0, 1, _height
                _step = 1 / (_hexesLength - 1)

                _gradient.addColorStop (_step * i), hex for hex, i in _hexes
                _context.fillStyle = _gradient
                _context.fillRect 0, 0, _width, _height
                return

        #  Set the selector position
        # ---------------------------
            setPosition: ({top}) ->
                _selection.style['top'] = (top / _height) * 100 + '%'
                return

        #  Returns a color from a position on the canvas
        # ---------------------------
            getColorAtPosition: (positionY) ->
                _data = (_context.getImageData 1, (positionY - 1), 1, 1).data

                return {
                    color: '#' + Convert.rgbToHex _data
                    type: 'hex'
                }
        }
