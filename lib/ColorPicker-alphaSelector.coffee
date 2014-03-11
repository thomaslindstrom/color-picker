# ----------------------------------------------------------------------------
#  ColorPicker: Alpha selector
# ----------------------------------------------------------------------------
        Convert = require './ColorPicker-convert'

        $el = atom.workspaceView.find '#ColorPicker-alphaSelector'
        $selection = atom.workspaceView.find '#ColorPicker-alphaSelection'
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

            # Draw the alpha selector gradient
            render: (color) ->
                _gradient = _context.createLinearGradient 0, 0, 1, _height
                _context.clearRect 0, 0, _width, _height

                _rgbString = color.join ', '
                _gradient.addColorStop 0, "rgba(#{ _rgbString }, 1)"
                _gradient.addColorStop 1, "rgba(#{ _rgbString }, 0)"

                _context.fillStyle = _gradient
                _context.fillRect 0, 0, _width, _height
