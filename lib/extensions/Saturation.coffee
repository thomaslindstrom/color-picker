# ----------------------------------------------------------------------------
#  Color Picker/extensions: Saturation
#  Color Saturation controller
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
    #  Create and activate Saturation controller
    # -------------------------------------
        activate: ->
            Body = colorPicker.getExtension 'Body'

        #  Create element
        # ---------------------------
            @element =
                el: do ->
                    _classPrefix = Body.element.el.className
                    _el = document.createElement 'div'
                    _el.classList.add "#{ _classPrefix }-saturation"

                    return _el
                # Utility functions
                width: 0
                height: 0
                getWidth: -> return @width or @el.offsetWidth
                getHeight: -> return @height or @el.offsetHeight

                rect: null
                getRect: -> return @rect or @updateRect()
                updateRect: -> @rect = @el.getClientRects()[0]

                # Add a child on the Saturation element
                add: (element) ->
                    @el.appendChild element
                    return this
            Body.element.add @element.el, 0

        #  Update element rect when Color Picker opens
        # ---------------------------
            colorPicker.onOpen =>
                return unless @element.updateRect() and _rect = @element.getRect()
                @width = _rect.width
                @height = _rect.height

        #  Create and draw canvas
        # ---------------------------
            setTimeout => # wait for the DOM
                Saturation = this
                Hue = colorPicker.getExtension 'Hue'

                # Prepare some variables
                _elementWidth = @element.getWidth()
                _elementHeight = @element.getHeight()

                # Create element
                @canvas =
                    el: do ->
                        _el = document.createElement 'canvas'
                        _el.width = _elementWidth
                        _el.height = _elementHeight
                        _el.classList.add "#{ Saturation.element.el.className }-canvas"

                        return _el
                    # Utility functions
                    context: null
                    getContext: -> @context or (@context = @el.getContext '2d')

                    getColorAtPosition: (x, y) -> return colorPicker.SmartColor.HSVArray [
                        Hue.getHue()
                        x / Saturation.element.getWidth() * 100
                        100 - (y / Saturation.element.getHeight() * 100)]

                    # Render Saturation canvas
                    previousRender: null
                    render: (smartColor) ->
                        _hslArray = ( do ->
                            unless smartColor
                                return colorPicker.SmartColor.HEX '#f00'
                            else return smartColor
                        ).toHSLArray()

                        _joined = _hslArray.join ','
                        return if @previousRender and @previousRender is _joined

                        # Get context and clear it
                        _context = @getContext()
                        _context.clearRect 0, 0, _elementWidth, _elementHeight

                        # Draw hue channel on top
                        _gradient = _context.createLinearGradient 0, 0, _elementWidth, 1
                        _gradient.addColorStop .01, 'hsl(0,100%,100%)'
                        _gradient.addColorStop .99, "hsl(#{ _hslArray[0] },100%,50%)"

                        _context.fillStyle = _gradient
                        _context.fillRect 0, 0, _elementWidth, _elementHeight

                        # Draw saturation channel on the bottom
                        _gradient = _context.createLinearGradient 0, 0, 1, _elementHeight
                        _gradient.addColorStop .01, 'rgba(0,0,0,0)'
                        _gradient.addColorStop .99, 'rgba(0,0,0,1)'

                        _context.fillStyle = _gradient
                        _context.fillRect 0, 0, _elementWidth, _elementHeight
                        return @previousRender = _joined

                # Render again on Hue selection change
                Hue.onColorChanged (smartColor) =>
                    @canvas.render smartColor
                @canvas.render()

                # Add to Saturation element
                @element.add @canvas.el

        #  Create Saturation control element
        # ---------------------------
            setTimeout => # wait for the DOM
                hasChild = (element, child) ->
                    if child and _parent = child.parentNode
                        if child is element
                            return true
                        else return hasChild element, _parent
                    return false

                # Create element
                Saturation = this
                Hue = colorPicker.getExtension 'Hue'

                @control =
                    el: do ->
                        _el = document.createElement 'div'
                        _el.classList.add "#{ Saturation.element.el.className }-control"

                        return _el
                    isGrabbing: no

                    previousControlPosition: null
                    updateControlPosition: (x, y) ->
                        _joined = "#{ x },#{ y }"
                        return if @previousControlPosition and @previousControlPosition is _joined

                        requestAnimationFrame =>
                            @el.style.left = "#{ x }px"
                            @el.style.top = "#{ y }px"
                        return @previousControlPosition = _joined

                    selection:
                        x: null
                        y: 0
                        color: null
                    setSelection: (e, saturation=null, key=null) ->
                        return unless Saturation.canvas and _rect = Saturation.element.getRect()

                        _width = Saturation.element.getWidth()
                        _height = Saturation.element.getHeight()

                        if e
                            _x = e.pageX - _rect.left
                            _y = e.pageY - _rect.top
                        # Set saturation and key directly
                        else if (typeof saturation is 'number') and (typeof key is 'number')
                            _x = _width * saturation
                            _y = _height * key
                        # Default to previous values
                        else
                            if (typeof @selection.x isnt 'number')
                                @selection.x = _width
                            _x = @selection.x
                            _y = @selection.y

                        _x = @selection.x = Math.max 0, (Math.min _width, Math.round _x)
                        _y = @selection.y = Math.max 0, (Math.min _height, Math.round _y)

                        _position =
                            x: Math.max 6, (Math.min (_width - 7), _x)
                            y: Math.max 6, (Math.min (_height - 7), _y)

                        @selection.color = Saturation.canvas.getColorAtPosition _x, _y
                        @updateControlPosition _position.x, _position.y
                        return Saturation.emitSelectionChanged()

                    refreshSelection: -> @setSelection()
                @control.refreshSelection()

                # If the Color Picker is fed a color, set it
                colorPicker.onInputColor (smartColor) =>
                    [h, s, v] = smartColor.toHSVArray()
                    @control.setSelection null, s, (1 - v)

                # When the selection changes, the color has changed
                Saturation.onSelectionChanged -> Saturation.emitColorChanged()

                # Reset
                colorPicker.onOpen => @control.refreshSelection()
                colorPicker.onOpen => @control.isGrabbing = no
                colorPicker.onClose => @control.isGrabbing = no

                # Bind controller events
                Hue.onColorChanged => @control.refreshSelection()

                colorPicker.onMouseDown (e, isOnPicker) =>
                    return unless isOnPicker and hasChild Saturation.element.el, e.target
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

                # Add to Saturation element
                @element.add @control.el
            return this
