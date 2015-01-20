# ----------------------------------------------------------------------------
#  ColorPicker: Alpha selector
# ----------------------------------------------------------------------------

    module.exports = (picker) ->
        Convert = require './ColorPicker-convert'

        _el = picker.querySelector '#ColorPicker-alphaSelector'
        _selection = picker.querySelector '#ColorPicker-alphaSelection'
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

        #  Draw the alpha selector gradient
        # ---------------------------
            render: (color) ->
                _gradient = _context.createLinearGradient 0, 0, 1, _height
                _context.clearRect 0, 0, _width, _height

                _rgbString = color.join ', '
                _gradient.addColorStop 0, "rgba(#{ _rgbString }, 1)"
                _gradient.addColorStop 1, "rgba(#{ _rgbString }, 0)"

                _context.fillStyle = _gradient
                _context.fillRect 0, 0, _width, _height

        #  Set the selector position
        # ---------------------------
            setPosition: ({top}) ->
                _selection.style['top'] = (top / _height) * 100 + '%'
        }
