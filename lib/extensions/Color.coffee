# ----------------------------------------------------------------------------
#  Color Picker/extensions: Color
#  The element showing the current color
# ----------------------------------------------------------------------------

    module.exports = (colorPicker) ->
        Emitter: (require '../modules/Emitter')()

        element: null
        color: null

    # -------------------------------------
    #  Set up events and handling
    # -------------------------------------
        # Output format event
        emitOutputFormat: (format) ->
            @Emitter.emit 'outputFormat', format
        onOutputFormat: (callback) ->
            @Emitter.on 'outputFormat', callback

    # -------------------------------------
    #  Create and activate Color element
    # -------------------------------------
        activate: ->
            @element =
                el: do ->
                    _classPrefix = colorPicker.element.el.className
                    _el = document.createElement 'div'
                    _el.classList.add "#{ _classPrefix }-color"

                    return _el
                # Utility functions
                addClass: (className) -> @el.classList.add className; return this
                removeClass: (className) -> @el.classList.remove className; return this

                height: -> @el.offsetHeight

                # Add a child on the Color element
                add: (element) ->
                    @el.appendChild element
                    return this

                # Set the Color element background color
                previousColor: null
                setColor: (smartColor) ->
                    _color = smartColor.toRGBA()
                    return if @previousColor and @previousColor is _color
                    
                    @el.style.backgroundColor = _color
                    return @previousColor = _color
            colorPicker.element.add @element.el

        #  Increase Color Picker height
        # ---------------------------
            setTimeout =>
                _newHeight = colorPicker.element.height() + @element.height()
                colorPicker.element.setHeight _newHeight

        #  Set or replace Color on click
        # ---------------------------
            hasChild = (element, child) ->
                if child and _parent = child.parentNode
                    if child is element
                        return true
                    else return hasChild element, _parent
                return false

            _isClicking = no

            colorPicker.onMouseDown (e, isOnPicker) =>
                return unless isOnPicker and hasChild @element.el, e.target
                e.preventDefault()
                _isClicking = yes

            colorPicker.onMouseMove (e) ->
                _isClicking = no

            colorPicker.onMouseUp (e) =>
                return unless _isClicking
                colorPicker.replace @color
                colorPicker.element.close()

        #  Set or replace Color on key press enter
        # ---------------------------
            colorPicker.onKeyDown (e) =>
                return unless e.which is 13
                e.stopPropagation()
                colorPicker.replace @color

        #  Set background element color on Alpha change
        # ---------------------------
            setTimeout => # wait for the DOM
                Alpha = colorPicker.getExtension 'Alpha'

                Alpha.onColorChanged (smartColor) =>
                    @element.setColor do ->
                        if smartColor then return smartColor
                        # Default to #f00 red
                        else return colorPicker.SmartColor.HEX '#f00'
                    return
                return

        #  Create Color text element
        # ---------------------------
            setTimeout =>
                Alpha = colorPicker.getExtension 'Alpha'
                Return = colorPicker.getExtension 'Return'
                Format = colorPicker.getExtension 'Format'

                # Create text element
                _text = document.createElement 'p'
                _text.classList.add "#{ @element.el.className }-text"

                # Reset before color picker open
                colorPicker.onBeforeOpen => @color = null

                # Keep track of the input color (for its format)
                _inputColor = null

                colorPicker.onInputColor (smartColor, wasFound) ->
                    _inputColor = if wasFound
                        smartColor
                    else null

                # Keep track of the Format element format
                _formatFormat = null
                Format.onFormatChanged (format) -> _formatFormat = format
                colorPicker.onInputColor -> _formatFormat = null

                # Set the text element to contain the Color data
                setColor = (smartColor) =>
                    _preferredFormat = atom.config.get 'color-picker.preferredFormat'
                    _format = _formatFormat or _inputColor?.format or _preferredFormat or 'RGB'

                    # TODO: This is very fragile
                    _function = if smartColor.getAlpha() < 1
                        (smartColor["to#{ _format }A"] or smartColor["to#{ _format }"])
                    else smartColor["to#{ _format }"]

                    # If a color was input, and the value hasn't changed since,
                    # show the inital value not to confuse the user, but only
                    # if the input color format is still the same
                    _outputColor = do ->
                        if _inputColor and (_inputColor.format is _format or _inputColor.format is "#{ _format }A")
                            if smartColor.equals _inputColor
                                return _inputColor.value
                        return _function.call smartColor

                    # Finish here if the _outputColor is the same as the
                    # current color
                    return unless _outputColor isnt @color

                    # Automatically replace color in editor if
                    # `automaticReplace` is true, but only if there was an
                    # input color and if it is different from before
                    if _inputColor and atom.config.get 'color-picker.automaticReplace'
                        colorPicker.replace _outputColor

                    # Set and save the output color
                    @color = _outputColor
                    _text.innerText = _outputColor

                    return @emitOutputFormat _format

                # Update on alpha change, keep track of current color
                _currentColor = null

                Alpha.onColorChanged (smartColor) =>
                    setColor _currentColor = do ->
                        if smartColor then return smartColor
                        # Default to #f00 red
                        else return colorPicker.SmartColor.HEX '#f00'
                    return

                # When Format is changed, update color
                Format.onFormatChanged -> setColor _currentColor

                # When the `Return` element is visible, add a class to allow
                # the text to be pushed up or down a bit
                Return.onVisibility (visibility) =>
                    if visibility then @element.addClass 'is--returnVisible'
                    else @element.removeClass 'is--returnVisible'
                @element.add _text
            return this
