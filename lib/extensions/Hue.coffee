# ----------------------------------------------------------------------------
#  Color Picker/extensions: Hue
#  Color Hue controller
# ----------------------------------------------------------------------------

    module.exports = (colorPicker) ->
        Emitter: (require '../modules/Emitter')()

        element: null
        control: null
        canvas: null

    # -------------------------------------
    #  Utility function to get the current hue
    # -------------------------------------
        getHue: ->
            if (@control and @control.selection) and @element
                return @control.selection.y / @element.getHeight() * 360
            else return 0

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
    #  Create and activate Hue controller
    # -------------------------------------
        activate: ->
            Body = colorPicker.getExtension 'Body'

        #  Create the element
        # ---------------------------
            @element =
                el: do ->
                    _classPrefix = Body.element.el.className
                    _el = document.createElement 'div'
                    _el.classList.add "#{ _classPrefix }-hue"

                    return _el
                # Utility functions
                width: 0
                height: 0
                getWidth: -> return @width or @el.offsetWidth
                getHeight: -> return @height or @el.offsetHeight

                rect: null
                getRect: -> return @rect or @updateRect()
                updateRect: -> @rect = @el.getClientRects()[0]

                # Add a child on the Hue element
                add: (element) ->
                    @el.appendChild element
                    return this
            Body.element.add @element.el, 2

        #  Update element rect when Color Picker opens
        # ---------------------------
            colorPicker.onOpen =>
                return unless @element.updateRect() and _rect = @element.getRect()
                @width = _rect.width
                @height = _rect.height

        #  Create and draw canvas
        # ---------------------------
            setTimeout => # wait for the DOM
                Hue = this

                # Prepare some variables
                _elementWidth = @element.getWidth()
                _elementHeight = @element.getHeight()

                # Red through all the main colors and back to red
                _hexes = ['#f00', '#ff0', '#0f0', '#0ff', '#00f', '#f0f', '#f00']

                # Create canvas element
                @canvas =
                    el: do ->
                        _el = document.createElement 'canvas'
                        _el.width = _elementWidth
                        _el.height = _elementHeight
                        _el.classList.add "#{ Hue.element.el.className }-canvas"

                        return _el
                    # Utility functions
                    context: null
                    getContext: -> @context or (@context = @el.getContext '2d')

                    getColorAtPosition: (y) -> return colorPicker.SmartColor.HSVArray [
                        y / Hue.element.getHeight() * 360
                        100
                        100]

                # Draw gradient
                _context = @canvas.getContext()

                _step = 1 / (_hexes.length - 1)
                _gradient = _context.createLinearGradient 0, 0, 1, _elementHeight
                _gradient.addColorStop (_step * _i), _hex for _hex, _i in _hexes

                _context.fillStyle = _gradient
                _context.fillRect 0, 0, _elementWidth, _elementHeight

                # Add to Hue element
                @element.add @canvas.el

        #  Create Hue control element
        # ---------------------------
            setTimeout => # wait for the DOM
                hasChild = (element, child) ->
                    if child and _parent = child.parentNode
                        if child is element
                            return true
                        else return hasChild element, _parent
                    return false

                # Create element
                Hue = this

                @control =
                    el: do ->
                        _el = document.createElement 'div'
                        _el.classList.add "#{ Hue.element.el.className }-control"

                        return _el
                    isGrabbing: no

                    # Set control selection
                    selection:
                        y: 0
                        color: null
                    setSelection: (e, y=null, offset=null) ->
                        return unless Hue.canvas and _rect = Hue.element.getRect()

                        _width = Hue.element.getWidth()
                        _height = Hue.element.getHeight()

                        if e then _y = e.pageY - _rect.top
                        # Set the y directly
                        else if (typeof y is 'number')
                            _y = y
                        # Handle scroll
                        else if (typeof offset is 'number')
                            _y = @selection.y + offset
                        # Default to top
                        else _y = @selection.y

                        _y = @selection.y = Math.max 0, (Math.min _height, _y)
                        @selection.color = Hue.canvas.getColorAtPosition _y

                        _position = y: Math.max 3, (Math.min (_height - 6), _y)

                        requestAnimationFrame =>
                            @el.style.top = "#{ _position.y }px"
                        return Hue.emitSelectionChanged()

                    refreshSelection: -> @setSelection()
                @control.refreshSelection()

                # If the Color Picker is fed a color, set it
                colorPicker.onInputColor (smartColor) =>
                    _hue = smartColor.toHSVArray()[0]
                    @control.setSelection null, (@element.getHeight() / 360) * _hue

                # When the selection changes, the color has changed
                Hue.onSelectionChanged -> Hue.emitColorChanged()

                # Reset
                colorPicker.onOpen => @control.refreshSelection()
                colorPicker.onOpen => @control.isGrabbing = no
                colorPicker.onClose => @control.isGrabbing = no

                # Bind controller events
                colorPicker.onMouseDown (e, isOnPicker) =>
                    return unless isOnPicker and hasChild Hue.element.el, e.target
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
                    return unless isOnPicker and hasChild Hue.element.el, e.target
                    e.preventDefault()
                    @control.setSelection null, null, (e.wheelDeltaY * .33) # make it a bit softer

                # Add to Hue element
                @element.add @control.el
            return this
