# ----------------------------------------------------------------------------
#  ColorPicker: View
# ----------------------------------------------------------------------------

    {View} = require 'atom'
    Convert = require './ColorPicker-convert'

    SaturationSelector = null
    HueSelector = null
    AlphaSelector = null

    module.exports = class ColorPickerView extends View
        @content: ->
            i = 'ColorPicker'
            c = "#{ i }-"

            @div id: i, class: i, =>
                @div id: "#{ c }loader", class: "#{ c }loader", =>
                    @div class: "#{ c }loaderDot"
                    @div class: "#{ c }loaderDot"
                    @div class: "#{ c }loaderDot"

                @div id: "#{ c }color", class: "#{ c }color", =>
                    @div id: "#{ c }value", class: "#{ c }value"

                @div id: "#{ c }initialWrapper", class: "#{ c }initialWrapper", =>
                    @div id: "#{ c }initial", class: "#{ c }initial"

                @div id: "#{ c }picker", class: "#{ c }picker", =>
                    @div id: "#{ c }saturationSelectorWrapper", class: "#{ c }saturationSelectorWrapper", =>
                        @div id: "#{ c }saturationSelection", class: "#{ c }saturationSelection"
                        @canvas id: "#{ c }saturationSelector", class: "#{ c }saturationSelector", width: '180px', height: '180px'
                    @div id: "#{ c }alphaSelectorWrapper", class: "#{ c }alphaSelectorWrapper", =>
                        @div id: "#{ c }alphaSelection", class: "#{ c }alphaSelection"
                        @canvas id: "#{ c }alphaSelector", class: "#{ c }alphaSelector", width: '20px', height: '180px'
                    @div id: "#{ c }hueSelectorWrapper", class: "#{ c }hueSelectorWrapper", =>
                        @div id: "#{ c }hueSelection", class: "#{ c }hueSelection"
                        @canvas id: "#{ c }hueSelector", class: "#{ c }hueSelector", width: '20px', height: '180px'

        initialize: ->
            atom.views.getView(atom.workspace)
                .querySelector '.vertical'
                .appendChild @element

            SaturationSelector = (require './ColorPicker-saturationSelector')(@element)
            AlphaSelector = (require './ColorPicker-alphaSelector')(@element)
            HueSelector = (require './ColorPicker-hueSelector')(@element)

            HueSelector.render()
            @bind()

        # Tear down any state and detach
        destroy: ->
            @close()
            @remove()
            @detach()

    # -------------------------------------
    #  Controller state storage
    # -------------------------------------
        storage: {
            activeView: null
            selectedColor: null
            pickedColor: null

            saturation: x: 0, y: 0
            hue: 0
            alpha: 0
        }

    # -------------------------------------
    #  Show or hide color picker
    # -------------------------------------
        isOpen: false

        reset: ->
            @addClass 'is--visible is--initial'
            @removeClass 'no--arrow is--pointer is--searching'

            (@find '#ColorPicker-color')
                .css 'background-color', ''
                .css 'border-bottom-color', ''
            (@find '#ColorPicker-value')
                .attr 'data-variable', ''
                .html ''

        open: ->
            @isOpen = true
            _selectedColor = @storage.selectedColor

            if not _selectedColor or _selectedColor.hasOwnProperty 'pointer'
                @addClass 'is--pointer'
            if not _selectedColor then @addClass 'is--searching'

            _colorPickerWidth = @width()
            _colorPickerHeight = @height()
            _halfColorPickerWidth = _colorPickerWidth / 2

            _Editor = atom.workspace.getActiveTextEditor()
            _ScrollView = (atom.views.getView _Editor).shadowRoot.querySelector '.scroll-view'
            _position = _Editor.pixelPositionForScreenPosition _Editor.getCursorScreenPosition()
            _offset = @getOffsetWith (atom.views.getView atom.workspace.getActivePane()), _ScrollView

            # Add 15 to account for the arrow on top of the color picker
            _top = 15 + _position.top - _Editor.$scrollTop.value + _Editor.$lineHeightInPixels.value + _offset.top
            # Remove half the color picker width to center it
            _left = _position.left - _Editor.$scrollLeft.value + _offset.left - _halfColorPickerWidth

            # Make adjustments based on view size: don't let the color picker
            # disappear or overflow
            _viewWidth = _Editor.$width.value
            _viewHeight = _Editor.$height.value

            # Remove 15 to ignore the arrow on top of the color picker
            if _top + _colorPickerHeight - 15 > _viewHeight
                _top = _viewHeight + _offset.top - _colorPickerHeight - 20
                @addClass 'no--arrow'

            if _left + _colorPickerWidth > _viewWidth
                _left = _viewWidth + _offset.left - _colorPickerWidth - 20
                @addClass 'no--arrow'

            @addClass 'no--arrow' if _top < 20
            @addClass 'no--arrow' if _left < 20

            this # Place the color picker
                .css 'top', Math.max 20, _top
                .css 'left', Math.max 20, _left

        close: ->
            @isOpen = false
            @removeClass 'is--visible is--initial is--searching is--error'

        error: ->
            @storage.selectedColor = null

            this
                .removeClass 'is--searching'
                .addClass 'is--error'

        scroll: -> if @isOpen then @close()

        getOffsetWith: (target, element) ->
            _el = element
            _offset = top: 0, left: 0

            until (_el is target) or not _el
                _offset.top += _el.offsetTop
                _offset.left += _el.offsetLeft
                _el = _el.offsetParent
            _offset.top += target.offsetTop
            _offset.left += target.offsetLeft

            return _offset

    # -------------------------------------
    #  Bind controls
    # -------------------------------------
        bind: ->
            Emitter = new (require 'event-kit').Emitter
            Emitter.onMouseDown = (callback) -> Emitter.on 'mousedown', callback
            Emitter.onMouseMove = (callback) -> Emitter.on 'mousemove', callback
            Emitter.onMouseUp = (callback) -> Emitter.on 'mouseup', callback

            window.addEventListener 'mousedown', (e) -> Emitter.emit 'mousedown', e
            window.addEventListener 'mousemove', (e) -> Emitter.emit 'mousemove', e
            window.addEventListener 'mouseup', (e) -> Emitter.emit 'mouseup', e

            window.onresize = => @close()

            _workspace = atom.workspace
            _workspace.getActivePane().onDidChangeActiveItem => @close()

            do => # Bind the color output control
                Emitter.onMouseDown (e) =>
                    _target = e.target
                    _className = _target.className

                    # Close unless the click target is something related to
                    # the color picker
                    return @close() unless /ColorPicker/.test _className

                    _color = @storage.selectedColor

                    switch _className
                        when 'ColorPicker-color'
                            if (_color?.hasOwnProperty 'pointer') and _pointer = _color.pointer
                                (atom.workspace.open _pointer.filePath).finally =>
                                    _editor = atom.workspace.activePaneItem
                                    _editor.clearSelections()
                                    _editor.setSelectedBufferRange _pointer.range
                            else @replaceColor()

                            @close()
                        when 'ColorPicker-initialWrapper'
                            @inputColor _color
                            @addClass 'is--initial'

                atom.views.getView(_workspace).addEventListener 'keydown', (e) =>
                    return unless @isOpen
                    return @close() unless e.which is 13

                    e.preventDefault()
                    e.stopPropagation()

                    @replaceColor()
                    @close()

            do => # Bind the saturation selector controls
                _isGrabbingSaturationSelection = false

                updateSaturationSelection = (e) =>
                    return unless @isOpen

                    _offset = @getOffsetWith @element.offsetParent, SaturationSelector.el
                    _offsetY = Math.max 1, (Math.min SaturationSelector.height, (e.pageY - _offset.top))
                    _offsetX = Math.max 1, (Math.min SaturationSelector.width, (e.pageX - _offset.left))

                    switch e.type
                        when 'mousedown'
                            return unless e.target.className is 'ColorPicker-saturationSelector'
                            e.preventDefault()
                            _isGrabbingSaturationSelection = true
                        when 'mousemove'
                            return unless _isGrabbingSaturationSelection
                            e.preventDefault()
                        when 'mouseup'
                            _isGrabbingSaturationSelection = false
                    return unless _isGrabbingSaturationSelection

                    @setSaturation _offsetX, _offsetY
                    @refreshColor 'saturation'

                Emitter.onMouseDown updateSaturationSelection
                Emitter.onMouseMove updateSaturationSelection
                Emitter.onMouseUp updateSaturationSelection

            do => # Bind the alpha selector controls
                _isGrabbingAlphaSelection = false

                updateAlphaSelector = (e) =>
                    return unless @isOpen

                    _offsetTop = (@getOffsetWith @element.offsetParent, AlphaSelector.el).top
                    _offsetY = Math.max 1, (Math.min AlphaSelector.height, (e.pageY - _offsetTop))

                    switch e.type
                        when 'mousedown'
                            return unless e.target.className is 'ColorPicker-alphaSelector'
                            e.preventDefault()
                            _isGrabbingAlphaSelection = true
                        when 'mousemove'
                            return unless _isGrabbingAlphaSelection
                            e.preventDefault()
                        when 'mouseup'
                            _isGrabbingAlphaSelection = false
                    return unless _isGrabbingAlphaSelection

                    @setAlpha _offsetY
                    @refreshColor 'alpha'

                Emitter.onMouseDown updateAlphaSelector
                Emitter.onMouseMove updateAlphaSelector
                Emitter.onMouseUp updateAlphaSelector

            do => # Bind the hue selector controls
                _isGrabbingHueSelection = false

                updateHueControls = (e) =>
                    return unless @isOpen

                    _offsetTop = (@getOffsetWith @element.offsetParent, HueSelector.el).top
                    _offsetY = Math.max 1, (Math.min HueSelector.height, (e.pageY - _offsetTop))

                    switch e.type
                        when 'mousedown'
                            return unless e.target.className is 'ColorPicker-hueSelector'
                            e.preventDefault()
                            _isGrabbingHueSelection = true
                        when 'mousemove'
                            return unless _isGrabbingHueSelection
                            e.preventDefault()
                        when 'mouseup'
                            _isGrabbingHueSelection = false
                    return unless _isGrabbingHueSelection

                    @setHue _offsetY
                    @refreshColor 'hue'

                Emitter.onMouseDown updateHueControls
                Emitter.onMouseMove updateHueControls
                Emitter.onMouseUp updateHueControls

    # -------------------------------------
    #  Saturation
    # -------------------------------------
        setSaturation: (positionX, positionY) ->
            @storage.saturation.x = positionX
            @storage.saturation.y = positionY
            SaturationSelector.setPosition top: positionY, left: positionX

        refreshSaturationCanvas: ->
            _color = HueSelector.getColorAtPosition @storage.hue
            SaturationSelector.render _color.color

    # -------------------------------------
    #  Alpha
    # -------------------------------------
        setAlpha: (positionY) ->
            @storage.alpha = positionY
            AlphaSelector.setPosition top: positionY

        refreshAlphaCanvas: ->
            _saturation = @storage.saturation
            _color = SaturationSelector.getColorAtPosition _saturation.x, _saturation.y
            AlphaSelector.render Convert.hexToRgb _color.color

    # -------------------------------------
    #  Hue
    # -------------------------------------
        setHue: (positionY) ->
            @storage.hue = positionY
            HueSelector.setPosition top: positionY

    # -------------------------------------
    #  Color
    # -------------------------------------

        # Set the current color after control interaction
        setColor: (color, preferredColorType) ->
            unless color then @removeClass 'is--initial'
            else _setInitialColor = true

            _saturation = @storage.saturation
            color ?= SaturationSelector.getColorAtPosition _saturation.x, _saturation.y
            _color = _displayColor = color.color

            _alphaValue = 100 - (((@storage.alpha / AlphaSelector.height) * 100) << 0)
            _alphaFactor = _alphaValue / 100

            # Spit the same color type as the input (selected) color
            if preferredColorType
                if preferredColorType is 'hsl' or preferredColorType is 'hsla'
                    _hsl = Convert.hsvToHsl Convert.rgbToHsv Convert.hexToRgb _color
                    _h = (_hsl[0]) << 0
                    _s = (_hsl[1] * 100) << 0
                    _l = (_hsl[2] * 100) << 0
                else _hexRgbFragments = (Convert.hexToRgb _color).join ', '

                if _alphaValue is 100 then _displayColor = switch preferredColorType
                    when 'rgb', 'rgba' then "rgb(#{ _hexRgbFragments })"
                    when 'hsl', 'hsla' then "hsl(#{ _h }, #{ _s }%, #{ _l }%)"
                    else _color
                else _displayColor = switch preferredColorType
                    when 'rgb', 'rgba', 'hex' then "rgba(#{ _hexRgbFragments }, #{ _alphaFactor })"
                    when 'hexa' then "rgba(#{ _color }, #{ _alphaFactor })"
                    when 'hsl', 'hsla' then "hsla(#{ _h }, #{ _s }%, #{ _l }%, #{ _alphaFactor })"

            # Translate the color to rgba if an alpha value is set
            if _alphaValue isnt 100
                _rgb = switch color.type
                    when 'hexa' then Convert.hexaToRgb _color
                    when 'hex' then Convert.hexToRgb _color
                    when 'rgb' then _color
                if _rgb then _color = "rgba(#{ _rgb.join ', ' }, #{ _alphaFactor })"

            @storage.pickedColor = _displayColor

            # Set the color
            (@find '#ColorPicker-color')
                .css 'background-color', _color
                .css 'border-bottom-color', _color
            (@find '#ColorPicker-value').html _displayColor

            # Save the initial color this function is given it
            if _setInitialColor
                (@find '#ColorPicker-initial')
                    .css 'background-color', _color
                    .html _displayColor

            # The color is a variable
            if color.hasOwnProperty 'pointer'
                @removeClass 'is--searching'
                    .find '#ColorPicker-value'
                    .attr 'data-variable', color.match

        refreshColor: (trigger) ->
            if trigger is 'hue' then @refreshSaturationCanvas()
            if trigger is 'hue' or trigger is 'saturation' then @refreshAlphaCanvas()

            # Send the preferred color type as well
            @setColor undefined, @storage.selectedColor.type

        # User selects a new color, reflect the change
        inputColor: (color) ->
            return unless this
            _hasClass = this[0].className.match /(is\-\-color\_(\w+))\s/

            @removeClass _hasClass[1] if _hasClass
            @addClass "is--color_#{ color.type }"

            _color = color.color

            # Convert the color to HSV
            # _hsv needs to be an array [h, s, v]
            _hsv = switch color.type
                when 'hex' then Convert.rgbToHsv Convert.hexToRgb _color
                when 'hexa' then Convert.rgbToHsv Convert.hexaToRgb _color
                when 'rgb', 'rgba' then Convert.rgbToHsv _color
                when 'hsl', 'hsla' then Convert.hslToHsv [
                    (parseInt color.regexMatch[1], 10)
                    (parseInt color.regexMatch[2], 10) / 100
                    (parseInt color.regexMatch[3], 10) / 100]
            return unless _hsv

            # Set all controls in the right place to reflect the input color

            # Get the hue. 360 is the H max
            @setHue (HueSelector.height / 360) * _hsv[0]

            # Get the saturation
            _saturationX = Math.max 1, SaturationSelector.width * _hsv[1]
            _saturationY = Math.max 1, SaturationSelector.height * (1 - _hsv[2])
            @setSaturation _saturationX, _saturationY
            @refreshSaturationCanvas()

            # Get the alpha
            _alpha = switch color.type
                when 'rgba' then color.regexMatch[7]
                when 'hexa' then color.regexMatch[4]
                when 'hsla' then color.regexMatch[4]
            # Set the alpha
            if _alpha then @setAlpha AlphaSelector.height * (1 - parseFloat _alpha)
            else if not _alpha then @setAlpha 0

            @refreshAlphaCanvas()
            @setColor color

    # -------------------------------------
    #  Selection
    # -------------------------------------

        # Select the color in the editor
        selectColor: ->
            _color = @storage.selectedColor
            _editor = atom.workspace.getActiveEditor()

            return unless _color

            # Clear selections and select the color
            _editor.clearSelections()
            _editor.addSelectionForBufferRange
                start:
                    column: _color.index
                    row: _color.row
                end:
                    column: _color.end
                    row: _color.row

        replaceColor: ->
            _color = @storage.selectedColor
            _newColor = @storage.pickedColor
            _editor = atom.workspace.getActiveEditor()

            return unless _color

            @selectColor()

            # Replace the text
            _editor.replaceSelectedText null, => return _newColor

            # Clear selections and select the color
            _editor.clearSelections()
            _editor.addSelectionForBufferRange
                start:
                    column: _color.index
                    row: _color.row
                end:
                    column: _color.index + _newColor.length
                    row: _color.row
