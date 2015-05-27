# ----------------------------------------------------------------------------
#  Color Picker/extensions: Return
#  The element showing the initial color value, enabling the user to return
#  to it at any time
# ----------------------------------------------------------------------------

    module.exports = (colorPicker) ->
        Emitter: (require '../modules/Emitter')()

        element: null
        color: null

    # -------------------------------------
    #  Set up events and handling
    # -------------------------------------
        # Visibility event
        emitVisibility: (visible=true) ->
            @Emitter.emit 'visible', visible
        onVisibility: (callback) ->
            @Emitter.on 'visible', callback

    # -------------------------------------
    #  Create and activate Return element
    # -------------------------------------
        activate: ->
            View = this

        #  Build the element
        # ---------------------------
            @element =
                el: do ->
                    _classPrefix = colorPicker.element.el.className
                    _el = document.createElement 'div'
                    _el.classList.add "#{ _classPrefix }-return"

                    return _el
                # Utility functions
                addClass: (className) -> @el.classList.add className; return this
                removeClass: (className) -> @el.classList.remove className; return this
                hasClass: (className) -> @el.classList.contains className

                hide: -> @removeClass 'is--visible'; View.emitVisibility false
                show: -> @addClass 'is--visible'; View.emitVisibility true

                # Add a child on the Return element
                add: (element) ->
                    @el.appendChild element
                    return this

                # Set the Return element background color
                setColor: (smartColor) ->
                    @el.style.backgroundColor = smartColor.toRGBA()
            colorPicker.element.add @element.el

        #  Return color on click
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
                return unless _isClicking and @color
                colorPicker.emitInputColor @color

        #  Show the element when the input color isn't the current color
        # ---------------------------
            setTimeout =>
                Alpha = colorPicker.getExtension 'Alpha'

                # Reset on colorPicker open
                colorPicker.onBeforeOpen =>
                    @color = null

                # Save the current color
                colorPicker.onInputColor (smartColor, wasFound) =>
                    @color = smartColor if wasFound

                # Do the check on Alpha change
                Alpha.onColorChanged (smartColor) =>
                    return @element.hide() unless @color

                    if smartColor.equals @color
                        @element.hide()
                    else @element.show()
                return

        #  Set background element color on input color
        # ---------------------------
            setTimeout =>
                colorPicker.onInputColor (smartColor, wasFound) =>
                    @element.setColor smartColor if wasFound
                return

        #  Create Return text element
        # ---------------------------
            setTimeout =>
                # Create text element
                _text = document.createElement 'p'
                _text.classList.add "#{ @element.el.className }-text"

                # Set the text element to contain the Return data
                setColor = (smartColor) =>
                    _text.innerText = smartColor.value

                colorPicker.onInputColor (smartColor, wasFound) ->
                    setColor smartColor if wasFound
                @element.add _text
            return this
