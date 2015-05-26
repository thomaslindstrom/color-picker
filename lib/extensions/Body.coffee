# ----------------------------------------------------------------------------
#  Color Picker/extensions: Body
#  The Color Picker Body, serves as the container for color controls
# ----------------------------------------------------------------------------

    module.exports = (colorPicker) ->
        element: null

    # -------------------------------------
    #  Create and activate Body
    # -------------------------------------
        activate: ->
            @element =
                el: do ->
                    _classPrefix = colorPicker.element.el.className
                    _el = document.createElement 'div'
                    _el.classList.add "#{ _classPrefix }-body"

                    return _el
                # Utility functions
                height: -> @el.offsetHeight

                # Add a child on the Body element
                add: (element, weight) ->
                    if weight
                        if weight > @el.children.length
                            @el.appendChild element
                        else @el.insertBefore element, @el.children[weight]
                    else @el.appendChild element

                    return this
            colorPicker.element.add @element.el

        #  Increase Color Picker height
        # ---------------------------
            setTimeout =>
                _newHeight = colorPicker.element.height() + @element.height()
                colorPicker.element.setHeight _newHeight

            return this
