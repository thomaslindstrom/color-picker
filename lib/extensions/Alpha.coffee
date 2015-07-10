# ----------------------------------------------------------------------------
#  Color Picker/extensions: Alpha
#  Color Alpha controller
# ----------------------------------------------------------------------------

    module.exports = (colorPicker) ->
        Emitter: (require '../modules/Emitter')()

        element: null
        control: null
        canvas: null

    # -------------------------------------
    #  Set up events and handling
    # -------------------------------------
        # Selection Changed event
        emitSelectionChanged: ->
            @Emitter.emit 'selectionChanged', @control.selection
        onSelectionChanged: (callback) ->
            @Emitter.on 'selectionChanged', callback

        # Color Changed event
        emitColorChanged: ->
            @Emitter.emit 'colorChanged', @control.selection.color
        onColorChanged: (callback) ->
            @Emitter.on 'colorChanged', callback

    # -------------------------------------
    #  Create and activate Alpha controller
    # -------------------------------------
        activate: ->
            Body = colorPicker.getExtension 'Body'

        #  Create element
        # ---------------------------
            @element =
                el: do ->
                    _classPrefix = Body.element.el.className
                    _el = document.createElement 'div'
                    _el.classList.add "#{ _classPrefix }-alpha"

                    return _el
                # Utility functions
                width: 0
                height: 0
                getWidth: -> return @width or @el.offsetWidth
                getHeight: -> return @height or @el.offsetHeight

                rect: null
                getRect: -> return @rect or @updateRect()
                updateRect: -> @rect = @el.getClientRects()[0]

                # Add a child on the Alpha element
                add: (element) ->
                    @el.appendChild element
                    return this
            Body.element.add @element.el, 1

        #  Update element rect position when Color Picker opens
        # ---------------------------
            colorPicker.onOpen => @element.updateRect()

        #  Create and draw canvas
        # ---------------------------
            setTimeout => # wait for the DOM
                Alpha = this
                Saturation = colorPicker.getExtension 'Saturation'

                # Prepare some variables
                _elementWidth = @element.getWidth()
                _elementHeight = @element.getHeight()

                # Create canvas element
                @canvas =
                    el: do ->
                        _el = document.createElement 'canvas'
                        _el.width = _elementWidth
                        _el.height = _elementHeight
                        _el.classList.add "#{ Alpha.element.el.className }-canvas"

                        return _el
                    # Utility functions
                    context: null
                    getContext: -> @context or (@context = @el.getContext '2d')

                    # Render Alpha canvas
                    previousRender: null
                    render: (smartColor) ->
                        _rgb = ( do ->
                            unless smartColor
                                return colorPicker.SmartColor.HEX '#f00'
                            else return smartColor
                        ).toRGBArray().join ','

                        return if @previousRender and @previousRender is _rgb

                        # Get context and clear it
                        _context = @getContext()
                        _context.clearRect 0, 0, _elementWidth, _elementHeight

                        # Draw alpha channel
                        _gradient = _context.createLinearGradient 0, 0, 1, _elementHeight
                        _gradient.addColorStop .01, "rgba(#{ _rgb },1)"
                        _gradient.addColorStop .99, "rgba(#{ _rgb },0)"

                        _context.fillStyle = _gradient
                        _context.fillRect 0, 0, _elementWidth, _elementHeight
                        return @previousRender = _rgb

                # Render again on Saturation color change
                Saturation.onColorChanged (smartColor) =>
                    @canvas.render smartColor
                @canvas.render()

                # Add to Alpha element
                @element.add @canvas.el

        #  Create Alpha control element
        # ---------------------------
            setTimeout => # wait for the DOM
                hasChild = (element, child) ->
                    if child and _parent = child.parentNode
                        if child is element
                            return true
                        else return hasChild element, _parent
                    return false

                # Create element
                Alpha = this
                Saturation = colorPicker.getExtension 'Saturation'

                @control =
                    el: do ->
                        _el = document.createElement 'div'
                        _el.classList.add "#{ Alpha.element.el.className }-control"

                        return _el
                    isGrabbing: no

                    previousControlPosition: null
                    updateControlPosition: (y) ->
                        _joined = ",#{ y }"
                        return if @previousControlPosition and @previousControlPosition is _joined

                        requestAnimationFrame =>
                            @el.style.top = "#{ y }px"
                        return @previousControlPosition = _joined

                    selection:
                        y: 0
                        color: null
                        alpha: null
                    setSelection: (e, alpha=null, offset=null) ->
                        _rect = Alpha.element.getRect()
                        _width = Alpha.element.getWidth()
                        _height = Alpha.element.getHeight()

                        if e then _y = e.pageY - _rect.top
                        # Set the alpha directly
                        else if (typeof alpha is 'number')
                            _y = _height - (alpha * _height) # reversed, 1 is top
                        # Handle scroll
                        else if (typeof offset is 'number')
                            _y = @selection.y + offset
                        # Default to previous values
                        else _y = @selection.y

                        _y = @selection.y = Math.max 0, (Math.min _height, _y)

                        _alpha = 1 - (_y / _height) # reversed, 1 is top
                        @selection.alpha = (Math.round _alpha * 100) / 100 # 2 decimal precision

                        # Update the smartColor (if any)
                        if _smartColor = @selection.color
                            _RGBAArray = _smartColor.toRGBAArray()
                            _RGBAArray[3] = @selection.alpha

                            @selection.color = colorPicker.SmartColor.RGBAArray _RGBAArray
                            Alpha.emitColorChanged()
                        # Or set a default red
                        else @selection.color = colorPicker.SmartColor.RGBAArray [255, 0, 0, @selection.alpha]

                        _position =
                            y: Math.max 3, (Math.min (_height - 6), _y)
                        @updateControlPosition _position.y

                        return Alpha.emitSelectionChanged()

                    refreshSelection: -> @setSelection()
                @control.refreshSelection()

                # If the Color Picker is fed a color, set it
                colorPicker.onInputColor (smartColor) =>
                    @control.setSelection null, smartColor.getAlpha()

                # Reset
                colorPicker.onOpen => @control.isGrabbing = no
                colorPicker.onClose => @control.isGrabbing = no

                # Bind controller events
                Saturation.onColorChanged (smartColor) =>
                    @control.selection.color = smartColor
                    @control.refreshSelection()

                colorPicker.onMouseDown (e, isOnPicker) =>
                    return unless isOnPicker and hasChild Alpha.element.el, e.target
                    e.preventDefault()
                    @control.isGrabbing = yes
                    @control.setSelection e

                colorPicker.onMouseMove (e) =>
                    return unless @control.isGrabbing
                    @control.setSelection e

                colorPicker.onMouseUp (e) =>
                    return unless @control.isGrabbing
                    @control.isGrabbing = no
                    @control.setSelection e

                colorPicker.onMouseWheel (e, isOnPicker) =>
                    return unless isOnPicker and hasChild Alpha.element.el, e.target
                    e.preventDefault()
                    @control.setSelection null, null, (e.wheelDeltaY * .33) # make it a bit softer

                # Add to Alpha element
                @element.add @control.el
            return this
