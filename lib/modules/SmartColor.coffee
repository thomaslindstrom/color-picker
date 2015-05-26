# ----------------------------------------------------------------------------
#  SmartColor
#  Easily convert between color types
# ----------------------------------------------------------------------------

    module.exports = ->
        # Make ColorRegexes a more “this module” friendly object
        # TODO: Ugly.
        ColorRegexes = {}; ColorRegexes[value.type] = value.regex for value in (require './ColorRegexes')

        Convert = (require './Convert')()

        # Function to prepare number values that can be abbreviated
        n = (number) ->
            number = "#{ number }"

            # Abbreviate if `abbreviateValues` option is true
            if atom.config.get 'color-picker.abbreviateValues'
                if number[0] is '0' and number[1] is '.'
                    number = number.substring 1 # TODO or `substr`?
            return number

        return {
        # -------------------------------------
        #  Base color object, all colors are versions of this object
        #  - type {String}: an identifier
        #  - value {String|Array}: The color value
        #  - RGBAArray {Array}: The color value in RGBAArray format
        # -------------------------------------
            color: (type, value, RGBAArray) ->
                type: type
                value: value
                RGBAArray: RGBAArray

                # Compare two smart colors
                equals: (smartColor) ->
                    return false unless smartColor

                    return smartColor.RGBAArray[0] is @RGBAArray[0] and smartColor.RGBAArray[1] is @RGBAArray[1] and
                    smartColor.RGBAArray[2] is @RGBAArray[2] and
                    smartColor.RGBAArray[3] is @RGBAArray[3]

                getAlpha: -> return @RGBAArray[3]

            #  RGB
            # ---------------------------
                toRGB: -> "rgb(#{ @toRGBArray().join ', ' })"
                toRGBArray: -> [@RGBAArray[0], @RGBAArray[1], @RGBAArray[2]]

                # RGBA
                toRGBA: ->
                    _rgbaArray = @toRGBAArray()
                    "rgba(#{ _rgbaArray[0] }, #{ _rgbaArray[1] }, #{ _rgbaArray[2] }, #{ n _rgbaArray[3] })"
                toRGBAArray: -> @RGBAArray

            #  HSL
            # ---------------------------
                toHSL: ->
                    _hslArray = @toHSLArray()
                    return "hsl(#{ _hslArray[0] }, #{ _hslArray[1] }%, #{ _hslArray[2] }%)"
                toHSLArray: -> Convert.rgbToHsl @toRGBArray()

                # HSLA
                toHSLA: ->
                    _hslaArray = @toHSLAArray()
                    return "hsla(#{ _hslaArray[0] }, #{ _hslaArray[1] }%, #{ _hslaArray[2] }%, #{ n _hslaArray[3] })"
                toHSLAArray: -> @toHSLArray().concat [@getAlpha()]

            #  HSV
            # ---------------------------
                toHSV: ->
                    _hsvArray = @toHSVArray()
                    return "hsv(#{ Math.round _hsvArray[0] }, #{ (_hsvArray[1] * 100) << 0 }%, #{ (_hsvArray[2] * 100) << 0 }%)"
                toHSVArray: -> Convert.rgbToHsv @toRGBArray()

                # HSVA
                toHSVA: ->
                    _hsvaArray = @toHSVAArray()
                    return "hsva(#{ Math.round _hsvaArray[0] }, #{ (_hsvaArray[1] * 100) << 0 }%, #{ (_hsvaArray[2] * 100) << 0 }%, #{ n _hsvaArray[3] })"
                toHSVAArray: -> @toHSVArray().concat [@getAlpha()]

            #  VEC
            # ---------------------------
                toVEC: ->
                    _vecArray = @toVECArray()
                    return "vec3(#{ _vecArray[0] }, #{ _vecArray[1] }, #{ _vecArray[2] })"
                toVECArray: -> Convert.rgbToVec @toRGBArray()

                # VECA
                toVECA: ->
                    _vecaArray = @toVECAArray()
                    return "vec4(#{ _vecaArray[0] }, #{ _vecaArray[1] }, #{ _vecaArray[2] }, #{ n _vecaArray[3] })"
                toVECAArray: -> @toVECArray().concat [@getAlpha()]

            #  HEX
            # ---------------------------
                toHEX: ->
                    _hex = Convert.rgbToHex @RGBAArray

                    # Abbreviate if `abbreviateValues` option is true
                    if atom.config.get 'color-picker.abbreviateValues'
                        if _hex[0] is _hex[1] and _hex[2] is _hex[3] and _hex[4] is _hex[5]
                            _hex = "#{ _hex[0] }#{ _hex[2] }#{ _hex[4] }"

                    # Uppercase color values if `uppercaseColorValues` option is true
                    if atom.config.get 'color-picker.uppercaseColorValues'
                        _hex = _hex.toUpperCase()

                    return '#' + _hex

                # HEXA
                toHEXA: -> "rgba(#{ @toHEX() }, #{ n @getAlpha() })"

        # -------------------------------------
        #  Color input formats...
        # -------------------------------------
            # RGB
            RGB: (value) -> @color 'RGB', value, do ->
                _match = value.match new RegExp ColorRegexes['rgb'].source, 'i'

                return ([
                    parseInt _match[1], 10
                    parseInt _match[2], 10
                    parseInt _match[3], 10
                ]).concat [1] # add default alpha
            RGBArray: (value) -> @color 'RGBArray', value, do ->
                return value.concat [1]

            # RGBA
            RGBA: (value) -> @color 'RGBA', value, do ->
                _match = value.match new RegExp ColorRegexes['rgba'].source, 'i'

                return ([
                    parseInt _match[1], 10
                    parseInt _match[2], 10
                    parseInt _match[3], 10
                ]).concat [parseFloat _match[4], 10]
            RGBAArray: (value) -> @color 'RGBAArray', value, value

            # HSL
            HSL: (value) -> @color 'HSL', value, do ->
                _match = value.match new RegExp ColorRegexes['hsl'].source, 'i'

                return (Convert.hslToRgb [
                    parseInt _match[1], 10
                    parseInt _match[2], 10
                    parseInt _match[3], 10
                ]).concat [1] # add default alpha
            HSLArray: (value) -> @color 'HSLArray', value, do ->
                return (Convert.hslToRgb value).concat [1]

            # HSLA
            HSLA: (value) -> @color 'HSLA', value, do ->
                _match = value.match new RegExp ColorRegexes['hsla'].source, 'i'

                return (Convert.hslToRgb [
                    parseInt _match[1], 10
                    parseInt _match[2], 10
                    parseInt _match[3], 10
                ]).concat [parseFloat _match[4], 10]
            HSLAArray: (value) -> @color 'HSLAArray', value, do ->
                return (Convert.hslToRgb value).concat [value[3]]

            # HSV
            HSV: (value) -> @color 'HSV', value, do ->
                _match = value.match new RegExp ColorRegexes['hsv'].source, 'i'

                return (Convert.hsvToRgb [
                    parseInt _match[1], 10
                    parseInt _match[2], 10
                    parseInt _match[3], 10
                ]).concat [1]
            HSVArray: (value) -> @color 'HSVArray', value, do ->
                return (Convert.hsvToRgb value).concat [1]

            # HSVA
            HSVA: (value) -> @color 'HSVA', value, do ->
                _match = value.match new RegExp ColorRegexes['hsva'].source, 'i'

                return (Convert.hsvToRgb [
                    parseInt _match[1], 10
                    parseInt _match[2], 10
                    parseInt _match[3], 10
                ]).concat [parseFloat _match[4], 10]
            HSVAArray: (value) -> @color 'HSVAArray', value, do ->
                return (Convert.hsvToRgb value).concat [value[3]]

            # VEC
            VEC: (value) -> @color 'VEC', value, do ->
                _match = value.match new RegExp ColorRegexes['vec3'].source, 'i'

                return (Convert.vecToRgb [
                    (parseFloat _match[1], 10).toFixed 2
                    (parseFloat _match[2], 10).toFixed 2
                    (parseFloat _match[3], 10).toFixed 2
                ]).concat [1]
            VECArray: (value) -> @color 'VECArray', value, do ->
                return (Convert.vecToRgb value).concat [1]

            # VECA
            VECA: (value) -> @color 'VECA', value, do ->
                _match = value.match new RegExp ColorRegexes['vec4'].source, 'i'

                return (Convert.vecToRgb [
                    (parseFloat _match[1], 10).toFixed 2
                    (parseFloat _match[2], 10).toFixed 2
                    (parseFloat _match[3], 10).toFixed 2
                ]).concat [parseFloat _match[4], 10]
            VECAArray: (value) -> @color 'VECAArray', value, do ->
                return (Convert.vecToRgb value).concat [value[3]]

            # HEX
            HEX: (value) -> @color 'HEX', value, do ->
                return (Convert.hexToRgb value).concat [1]

            # HEXA
            HEXA: (value) -> @color 'HEXA', value, do ->
                _match = value.match new RegExp ColorRegexes['hexa'].source, 'i'
                return (Convert.hexToRgb _match[1]).concat [parseFloat _match[2], 10]
        }
