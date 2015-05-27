# ----------------------------------------------------------------------------
#  Color Picker/extensions: Format
#  The element providing UI to convert between color formats
# ----------------------------------------------------------------------------

    module.exports = (colorPicker) ->
        Emitter: (require '../modules/Emitter')()

        element: null
        color: null

    # -------------------------------------
    #  Set up events and handling
    # -------------------------------------
        # Format Changed event
        emitFormatChanged: (format) ->
            @Emitter.emit 'formatChanged', format
        onFormatChanged: (callback) ->
            @Emitter.on 'formatChanged', callback

    # -------------------------------------
    #  Create and activate Format element
    # -------------------------------------
        activate: ->
            @element =
                el: do ->
                    _classPrefix = colorPicker.element.el.className
                    _el = document.createElement 'div'
                    _el.classList.add "#{ _classPrefix }-format"

                    return _el

                # Add a child on the Color element
                add: (element) ->
                    @el.appendChild element
                    return this
            colorPicker.element.add @element.el

        #  Add conversion buttons #ff0
        # ---------------------------
            setTimeout =>
                Color = colorPicker.getExtension 'Color'

                _buttons = []
                _activeButton = null

                # On color picker open, reset
                colorPicker.onBeforeOpen -> for _button in _buttons
                    _button.deactivate()

                # On Color element output format, activate applicable button
                Color.onOutputFormat (format) -> for _button in _buttons
                    # TODO this is inefficient. There should be a way to easily
                    # check if `format` is in `_button.format`, including the
                    # alpha channel
                    if format is _button.format or format is "#{ _button.format }A"
                        _button.activate()
                        _activeButton = _button
                    else _button.deactivate()

                # Create formatting buttons
                # TODO same as setting, globalize
                for _format in ['RGB', 'HEX', 'HSL', 'HSV', 'VEC'] then do (_format) =>
                    Format = this

                    # Create the button
                    _button =
                        el: do ->
                            _el = document.createElement 'button'
                            _el.classList.add "#{ Format.element.el.className }-button"
                            _el.innerHTML = _format
                            return _el
                        format: _format

                        # Utility functions
                        addClass: (className) -> @el.classList.add className; return this
                        removeClass: (className) -> @el.classList.remove className; return this

                        activate: -> @addClass 'is--active'
                        deactivate: -> @removeClass 'is--active'
                    _buttons.push _button

                    # Set initial format
                    unless _activeButton
                        if _format is atom.config.get 'color-picker.preferredFormat'
                            _activeButton = _button
                            _button.activate()

                    # Change color format on click
                    hasChild = (element, child) ->
                        if child and _parent = child.parentNode
                            if child is element
                                return true
                            else return hasChild element, _parent
                        return false
                    _isClicking = no

                    colorPicker.onMouseDown (e, isOnPicker) =>
                        return unless isOnPicker and hasChild _button.el, e.target
                        e.preventDefault()
                        _isClicking = yes

                    colorPicker.onMouseMove (e) ->
                        _isClicking = no

                    colorPicker.onMouseUp (e) =>
                        return unless _isClicking

                        _activeButton.deactivate() if _activeButton
                        _button.activate()
                        _activeButton = _button

                        @emitFormatChanged _format

                    # Add button to the parent Format element
                    @element.add _button.el
            return this
