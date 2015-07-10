# ----------------------------------------------------------------------------
#  Color Picker/extensions: Arrow
#  An arrow pointing at the current selection
# ----------------------------------------------------------------------------

    module.exports = (colorPicker) ->
        element: null

    # -------------------------------------
    #  Create and activate Arrow
    # -------------------------------------
        activate: ->
            _halfArrowWidth = null

        #  Create element
        # ---------------------------
            @element =
                el: do ->
                    _classPrefix = colorPicker.element.el.className
                    _el = document.createElement 'div'
                    _el.classList.add "#{ _classPrefix }-arrow"

                    return _el
                # Utility functions
                addClass: (className) -> @el.classList.add className; return this
                removeClass: (className) -> @el.classList.remove className; return this
                hasClass: (className) -> @el.classList.contains className

                width: -> @el.offsetWidth
                height: -> @el.offsetHeight

                # Set Arrow position
                # - x {Number}
                setPosition: (x) ->
                    @el.style.left = "#{ x }px"
                    return this

                # Set the Color element background color
                previousColor: null
                setColor: (smartColor) ->
                    _color = smartColor.toRGBA?() or 'none'
                    return if @previousColor and @previousColor is _color

                    @el.style.borderTopColor = _color
                    @el.style.borderBottomColor = _color
                    return @previousColor = _color
            colorPicker.element.add @element.el

        #  Get and save arrow width
        # ---------------------------
            setTimeout => _halfArrowWidth = (@element.width() / 2) << 0

        #  Increase Color Picker height
        # ---------------------------
            setTimeout =>
                _newHeight = colorPicker.element.height() + @element.height()
                colorPicker.element.setHeight _newHeight

        #  Set Arrow color on Alpha change
        # ---------------------------
            setTimeout => # wait for the DOM
                Alpha = colorPicker.getExtension 'Alpha'

                Alpha.onColorChanged (smartColor) =>
                    if smartColor then @element.setColor smartColor
                    # Default to #f00 red
                    else colorPicker.SmartColor.HEX '#f00'
                return

        #  Set Arrow color to transparent when a variable is input
        # ---------------------------
            colorPicker.onInputVariable =>
                @element.setColor colorPicker.SmartColor.RGBAArray [0, 0, 0, 0]

        #  ... but set it to the variable color when that is found
        # ---------------------------
            colorPicker.onInputVariableColor (smartColor) =>
                return unless smartColor
                @element.setColor smartColor

        #  Place the Arrow
        # ---------------------------
            colorPicker.onPositionChange (position, colorPickerPosition) =>
                @element.setPosition position.x - colorPickerPosition.x
            return this
