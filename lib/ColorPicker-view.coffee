# ----------------------------------------------------------------------------
#  Color Picker
# ----------------------------------------------------------------------------
    {View} = require 'atom'
    Convert = require './ColorPicker-convert'

    ColorPicker = undefined
    SaturationSelector = undefined
    HueSelector = undefined
    AlphaSelector = undefined

    module.exports = class ColorPickerView extends View
        @content: ->
            c = 'ColorPicker-'

            @div id: 'ColorPicker', class: 'ColorPicker', =>
                @div id: c + 'color', class: c + 'color', =>
                    @div id: c + 'value', class: c + 'value'

                @div id: c + 'picker', class: c + 'picker', =>
                    @div id: c + 'saturationSelectorWrapper', class: c + 'saturationSelectorWrapper', =>
                        @div id: c + 'saturationSelection', class: c + 'saturationSelection'
                        @canvas id: c + 'saturationSelector', class: c + 'saturationSelector', width: '180px', height: '180px'
                    @div id: c + 'alphaSelectorWrapper', class: c + 'alphaSelectorWrapper', =>
                        @div id: c + 'alphaSelection', class: c + 'alphaSelection'
                        @canvas id: c + 'alphaSelector', class: c + 'alphaSelector', width: '20px', height: '180px'
                    @div id: c + 'hueSelectorWrapper', class: c + 'hueSelectorWrapper', =>
                        @div id: c + 'hueSelection', class: c + 'hueSelection'
                        @canvas id: c + 'hueSelector', class: c + 'hueSelector', width: '20px', height: '180px'

        initialize: ->
            (atom.workspaceView.find '.vertical').append this

            ColorPicker = require './ColorPicker'
            SaturationSelector = require './ColorPicker-saturationSelector'
            AlphaSelector = require './ColorPicker-alphaSelector'
            HueSelector = require './ColorPicker-hueSelector'

            HueSelector.render()

            @bind()

        # Tear down any state and detach
        destroy: -> @detach()

    # -------------------------------------
    #  Show or hide color picker
    # -------------------------------------
        open: ->
            @isOpen = true
            this.addClass 'is--visible'
            this.removeClass 'no--arrow'

            _colorPickerWidth = this.width()
            _colorPickerHeight = this.height()
            _halfColorPickerWidth = _colorPickerWidth / 2

            _pane = atom.workspaceView.getActivePaneView()
            _tabBarHeight = (_pane.find '.tab-bar').height()

            _view = _pane.activeView
            _position = _view.pixelPositionForScreenPosition _view.getEditor().getCursorScreenPosition()
            _gutterWidth = (_view.find '.gutter').width()

            _top = 15 + _position.top - _view.scrollTop() + _view.lineHeight + _tabBarHeight
            _left = _position.left - _view.scrollLeft() + _gutterWidth

            # Make adjustments based on view size: don't let
            # the color picker disappear
            _viewWidth = _view.width()
            _viewHeight = _view.height()

            if _top + _colorPickerHeight - 15 > _viewHeight
                _top = _viewHeight + _tabBarHeight - _colorPickerHeight - 20
                this.addClass 'no--arrow'

            if _left + _halfColorPickerWidth > _viewWidth
                _left = _viewWidth - _halfColorPickerWidth - 20
                this.addClass 'no--arrow'

            # Place the color picker
            this
                .css 'top', Math.max 1, _top
                .css 'left', Math.max 1, _left - _halfColorPickerWidth

        close: ->
            @isOpen = false
            this.removeClass 'is--visible'

    # -------------------------------------
    #  Bind controls
    # -------------------------------------
        bind: ->
            $body = this.parents 'body'

            do => # Bind the color output control
                $body.on 'mousedown', (e) =>
                    return @close() unless /ColorPicker/.test e.target.className
                    return unless e.target.className is 'ColorPicker-color'

                    @replaceColor()
                    @close()
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
    #  Controller state storage
    # -------------------------------------
        storage: {
            selectedColor: null
            currentColor: null
            saturation: x: 0, y: 0
            hue: 0
            alpha: 0
        }

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
        setColor: (color) ->
            # TODO: Translate HEXA to RGBA

            _saturation = @storage.saturation
            color ?= SaturationSelector.getColorAtPosition _saturation.x, _saturation.y
            _color = color.color

            _alphaValue = 100 - (((@storage.alpha / AlphaSelector.height) * 100) << 0)

            if _alphaValue isnt 100
                _rgb = switch color.type
                    when 'hex' then Convert.hexToRgb color.color
                    when 'rgb' then color.color
                if _rgb then _color = "rgba(#{ _rgb.join ', ' }, #{ _alphaValue / 100 })"

            @storage.currentColor = _color

            (this.find '#ColorPicker-value').html _color
            (this.find '#ColorPicker-color')
                .css 'background', _color
                .css 'border-bottom-color', _color

        refreshColor: (trigger) ->
            if trigger is 'hue' then @refreshSaturationCanvas()
            if trigger is 'hue' or trigger is 'saturation' then @refreshAlphaCanvas()

            @setColor()

        # User selects a new color => reflect the change
        inputColor: (color) ->
            _color = color.color

            # TODO: Don't do this
            if color.type is 'hexa'
                _hex = (_color.match /rgba\((\#.+),/)[1]
                color.type = 'rgba'
                _color = color.color = _color.replace _hex, (Convert.hexToRgb _hex).join ', '

            # Convert the color to HSV
            _hsv = switch color.type
                when 'rgba' then Convert.rgbToHsv _color.match /(\d+)/g
                when 'rgb' then Convert.rgbToHsv _color.match /(\d+)/g
                when 'hex' then Convert.rgbToHsv Convert.hexToRgb _color
            return unless _hsv

            # Set all controls in the right place to reflect the new color

            # Get the hue. 360 is the H max
            @setHue (HueSelector.height / 360) * _hsv[0]

            # Get the saturation
            _saturationX = Math.max 1, SaturationSelector.width * _hsv[1]
            _saturationY = Math.max 1, SaturationSelector.height * (1 - _hsv[2])
            @setSaturation _saturationX, _saturationY
            @refreshSaturationCanvas()

            # Get the alpha
            if color.type is 'rgba'
                _alpha = parseFloat (_color.match /rgba\((.+),(.+),(.+),(.+)\)/)[4]
                if _alpha isnt 1 then @setAlpha AlphaSelector.height * (1 - _alpha)
            if not _alpha then @setAlpha 0

            @refreshAlphaCanvas()

            @setColor color

    # -------------------------------------
    #  Selection
    # -------------------------------------

        # Select the color in the editor
        selectColor: ->
            _color = @storage.selectedColor
            _editor = atom.workspace.getActiveEditor()

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
            _editor = atom.workspace.getActiveEditor()

            # Replace the text
            _editor.replaceSelectedText null, =>
                return @storage.currentColor

            # Clear selections and select the color
            _editor.clearSelections()
            _editor.addSelectionForBufferRange
                start:
                    column: _color.index
                    row: _color.row
                end:
                    column: _color.index + @storage.currentColor.length
                    row: _color.row
