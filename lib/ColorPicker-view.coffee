# ----------------------------------------------------------------------------
#  Color Picker
# ----------------------------------------------------------------------------
    {View} = require 'atom'

    Convert = require './ColorPicker-convert'
    ColorPicker = undefined
    SaturationSelector = undefined
    HueSelector = undefined

    module.exports = class ColorPickerView extends View
        @content: ->
            c = 'ColorPicker-'

            @div id: 'ColorPicker', class: 'ColorPicker', =>
                @div id: c + 'picker', class: c + 'picker', =>
                    @div id: c + 'saturationSelectorWrapper', class: c + 'saturationSelectorWrapper', =>
                        @div id: c + 'saturationSelection', class: c + 'saturationSelection'
                        @canvas id: c + 'saturationSelector', class: c + 'saturationSelector', width: '180px', height: '180px'
                    @div id: c + 'hueSelectorWrapper', class: c + 'hueSelectorWrapper', =>
                        @div id: c + 'hueSelection', class: c + 'hueSelection'
                        @canvas id: c + 'hueSelector', class: c + 'hueSelector', width: '20px', height: '180px'
                @div id: c + 'color', class: c + 'color', =>
                    @div id: c + 'value', class: c + 'value'

        initialize: ->
            (atom.workspaceView.find '.vertical').append this

            ColorPicker = require './ColorPicker'
            SaturationSelector = require './ColorPicker-saturationSelector'
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

            _pane = atom.workspaceView.getActivePaneView()
            _tabBarHeight = (_pane.find '.tab-bar').height()
            _gutterWidth = (_pane.find '.gutter').width()

            _view = (_pane.find '.editor').view()
            _position = _view.pixelPositionForScreenPosition _view.getEditor().getCursorBufferPosition()

            _top = 20 + _position.top - _view.scrollTop() + _view.lineHeight + _tabBarHeight
            _left = _position.left - _view.scrollLeft() - (this.width() / 2) + _gutterWidth

            this
                .css 'top', Math.max 1, _top
                .css 'left', Math.max 1, _left

        close: ->
            @isOpen = false
            this.removeClass 'is--visible'

    # -------------------------------------
    #  Bind controls
    # -------------------------------------
        bind: ->
            $body = this.parents 'body'

            do => # Bind the color output control
                $body.on 'click', (e) =>
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

    # -------------------------------------
    #  Controller state storage
    # -------------------------------------
        storage: {
            selectedColor: null
            currentColor: null
            hue: y: 0
            saturation: x: 0, y: 0
        }

    # -------------------------------------
    #  Hue
    # -------------------------------------
        setHue: (positionY) ->
            @storage.hue.y = positionY
            HueSelector.$selection
                .css 'top', (positionY / HueSelector.height) * 100 + '%'

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
            _color = HueSelector.getColorAtPosition @storage.hue.y
            SaturationSelector.render _color.color

    # -------------------------------------
    #  Color
    # -------------------------------------

        # Set the current color after control interaction
        setColor: (color) ->
            # TODO: Translate HEXA to RGBA

            _saturation = @storage.saturation
            _color = color or (SaturationSelector.getColorAtPosition _saturation.x, _saturation.y).color

            @storage.currentColor = _color

            (this.find '#ColorPicker-value').html _color
            (this.find '#ColorPicker-color')
                .css 'background', _color
                .css 'border-bottom-color', _color

        refreshColor: (trigger) ->
            if trigger is 'hue' then @refreshSaturationCanvas()
            @setColor()

        # User selects a new color => reflect the change
        inputColor: (color) ->
            _color = color.color

            # Convert the color to HSV
            _hsv = switch color.type
                when 'hex' then Convert.rgbToHsv Convert.hexToRgb _color
                when 'rgb' then Convert.rgbToHsv _color.match /(\d+)/g
            return unless _hsv

            # Set all controls in the right place to reflect the new color

            @setHue (HueSelector.height / 360) * _hsv[0]

            _saturationX = Math.max 1, SaturationSelector.width * _hsv[1]
            _saturationY = Math.max 1, SaturationSelector.height * (1 - _hsv[2])
            @setSaturation _saturationX, _saturationY
            @refreshSaturationCanvas()

            @setColor _color

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
