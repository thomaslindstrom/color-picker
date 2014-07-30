# ----------------------------------------------------------------------------
#  ColorPicker: View
# ----------------------------------------------------------------------------
    { View } = require 'atom'
    Convert = require './ColorPicker-convert'

    ColorPicker = null
    SaturationSelector = null
    HueSelector = null
    AlphaSelector = null

    module.exports = class ColorPickerView extends View
        @content: ->
            c = 'ColorPicker-'

            @div id: 'ColorPicker', class: 'ColorPicker', =>
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
            (atom.workspaceView.find '.vertical').append this

            ColorPicker = require './ColorPicker'
            SaturationSelector = require './ColorPicker-saturationSelector'
            AlphaSelector = require './ColorPicker-alphaSelector'
            HueSelector = require './ColorPicker-hueSelector'

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

            _pane = atom.workspaceView.getActivePaneView()
            _paneOffset = top: _pane[0].offsetTop, left: _pane[0].offsetLeft
            _tabBarHeight = (_pane.find '.tab-bar').height()

            @storage.activeView = _view = _pane.activeView
            _position = _view.pixelPositionForScreenPosition _view.getEditor().getCursorScreenPosition()
            _gutterWidth = (_view.find '.gutter').width()

            _scroll = top: _view.scrollTop(), left: _view.scrollLeft()
            _scrollbar = _view.verticalScrollbar
            if _scrollbar then _scrollbar.on 'scroll.color-picker', => @scroll()

            # Add 15 to account for the arrow on top of the color picker
            _top = 15 + _position.top - _scroll.top + _view.lineHeight + _tabBarHeight
            _left = _position.left - _scroll.left + _gutterWidth

            # Make adjustments based on view size: don't let the color picker
            # disappear or overflow
            _viewWidth = _view.width()
            _viewHeight = _view.height()

            # Remove 15 to ignore the arrow on top of the color picker
            if _top + _colorPickerHeight - 15 > _viewHeight
                _top = _viewHeight + _tabBarHeight - _colorPickerHeight - 20
                @addClass 'no--arrow'
            _top += _paneOffset.top

            if _left + _halfColorPickerWidth > _viewWidth
                _left = _viewWidth - _halfColorPickerWidth - 20
                @addClass 'no--arrow'
            _left += _paneOffset.left - _halfColorPickerWidth

            this # Place the color picker
                .css 'top', Math.max 20, _top
                .css 'left', Math.max 20, _left

        close: ->
            @isOpen = false
            @removeClass 'is--visible is--initial is--searching is--error'

            return unless @storage.activeView and @storage.activeView.verticalScrollbar
            @storage.activeView.verticalScrollbar.off 'scroll.color-picker'

        error: ->
            @storage.selectedColor = null

            this
                .removeClass 'is--searching'
                .addClass 'is--error'

        scroll: -> if @isOpen then @close()

    # -------------------------------------
    #  Bind controls
    # -------------------------------------
        bind: ->
            window.onresize = => if @isOpen then @close()
            atom.workspaceView.on 'pane:active-item-changed', => @close()

            $body = @parents 'body'

            do => # Bind the color output control
                $body.on 'mousedown', (e) =>
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
                .on 'keydown', (e) =>
                    return unless @isOpen
                    return @close() unless e.which is 13

                    e.preventDefault()
                    e.stopPropagation()

                    @replaceColor()
                    @close()

            do => # Bind the saturation selector controls
                _isGrabbingSaturationSelection = false

                $body.on 'mousedown mousemove mouseup', (e) =>
                    _offset = SaturationSelector.$el.offset()
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

            do => # Bind the alpha selector controls
                _isGrabbingAlphaSelection = false

                $body.on 'mousedown mousemove mouseup', (e) =>
                    _offsetTop = AlphaSelector.$el.offset().top
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

            do => # Bind the hue selector controls
                _isGrabbingHueSelection = false

                $body.on 'mousedown mousemove mouseup', (e) =>
                    _offsetTop = HueSelector.$el.offset().top
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

    # -------------------------------------
    #  Saturation
    # -------------------------------------
        setSaturation: (positionX, positionY) ->
            @storage.saturation.x = positionX
            @storage.saturation.y = positionY

            _percentageTop = (positionY / SaturationSelector.height) * 100
            _percentageLeft = (positionX / SaturationSelector.width) * 100

            SaturationSelector.$selection
                .css 'top', _percentageTop + '%'
                .css 'left', _percentageLeft + '%'

        refreshSaturationCanvas: ->
            _color = HueSelector.getColorAtPosition @storage.hue
            SaturationSelector.render _color.color

    # -------------------------------------
    #  Alpha
    # -------------------------------------
        setAlpha: (positionY) ->
            @storage.alpha = positionY
            AlphaSelector.$selection
                .css 'top', (positionY / AlphaSelector.height) * 100 + '%'

        refreshAlphaCanvas: ->
            _saturation = @storage.saturation
            _color = SaturationSelector.getColorAtPosition _saturation.x, _saturation.y
            AlphaSelector.render Convert.hexToRgb _color.color

    # -------------------------------------
    #  Hue
    # -------------------------------------
        setHue: (positionY) ->
            @storage.hue = positionY
            HueSelector.$selection
                .css 'top', (positionY / HueSelector.height) * 100 + '%'

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
