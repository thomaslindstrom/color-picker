# ----------------------------------------------------------------------------
#  Color Picker/extensions: Definition
#  The element showing the current variable definition
# ----------------------------------------------------------------------------

    module.exports = (colorPicker) ->
        element: null
        pointer: null

    # -------------------------------------
    #  Create and activate Definition element
    # -------------------------------------
        activate: ->
            @element =
                el: do ->
                    _classPrefix = colorPicker.element.el.className
                    _el = document.createElement 'div'
                    _el.classList.add "#{ _classPrefix }-definition"

                    return _el
                # Utility functions
                height: -> @el.offsetHeight

                # Add a child on the Definition element
                add: (element) ->
                    @el.appendChild element
                    return this

                # Set the Definition element background color
                setColor: (smartColor) ->
                    @el.style.backgroundColor = smartColor.toRGBA()
            colorPicker.element.add @element.el

        #  Set Color Picker height
        # ---------------------------
            setTimeout =>
                Arrow = colorPicker.getExtension 'Arrow'
                $colorPicker = colorPicker.element

                # Change view mode when a variable is input
                colorPicker.onInputVariable =>
                    _oldHeight = $colorPicker.height()
                    $colorPicker.addClass 'view--definition'

                    _newHeight = @element.height() + Arrow.element.height()
                    $colorPicker.setHeight _newHeight

                    # Reset current element background color
                    @element.setColor colorPicker.SmartColor.RGBAArray [0, 0, 0, 0]

                    # Reset picker on close, and clear the event
                    # TODO handle this on the ColorPicker itself, maybe?
                    onClose = ->
                        colorPicker.canOpen = no

                        onTransitionEnd = ->
                            $colorPicker.setHeight _oldHeight
                            $colorPicker.el.removeEventListener 'transitionend', onTransitionEnd
                            $colorPicker.removeClass 'view--definition'
                            colorPicker.canOpen = yes
                        $colorPicker.el.addEventListener 'transitionend', onTransitionEnd

                        # TODO: This kinda goes against the 'no strings' thing
                        colorPicker.Emitter.off 'close', onClose
                    colorPicker.onClose onClose

                # Make sure the class is never set when a color is input
                colorPicker.onInputColor ->
                    $colorPicker.removeClass 'view--definition'
                return

        #  Set background element color on change
        # ---------------------------
            colorPicker.onInputVariableColor (smartColor) =>
                return unless smartColor
                @element.setColor smartColor

        #  Set or replace selection on click
        # ---------------------------
            colorPicker.onInputVariableColor (..., pointer) =>
                # Keep track of the current pointer for when the color is
                # supposed to be replaced
                @pointer = pointer

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
                return unless _isClicking and @pointer

                atom.workspace.open(@pointer.filePath).then =>
                    Editor = atom.workspace.getActiveTextEditor()
                    Editor.clearSelections()
                    Editor.setSelectedBufferRange @pointer.range
                    Editor.scrollToCursorPosition()

                    colorPicker.close()
                return

        #  Create Definition definition text element
        # ---------------------------
            setTimeout =>
                # Create definition text element
                _definition = document.createElement 'p'
                _definition.classList.add "#{ @element.el.className }-definition"

                # Remove the definition when a new variable is input
                colorPicker.onInputVariable ->
                    _definition.innerText = ''

                # Set definition when the definition is found
                colorPicker.onInputVariableColor (color) ->
                    # If a color definition is found
                    if color then _definition.innerText = color.value
                    # If no definition is found, show an error
                    else _definition.innerText = 'No color found.'

                # Add to Definition element
                @element.add _definition

        #  Create Definition variable text element
        # ---------------------------
            setTimeout =>
                # Create variable text element
                _variable = document.createElement 'p'
                _variable.classList.add "#{ @element.el.className }-variable"

                # Set variable when the variable is input
                colorPicker.onInputVariable (match) ->
                    _variable.innerText = match.match

                # Add to Definition element
                @element.add _variable
            return this
