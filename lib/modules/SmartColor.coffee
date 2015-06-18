# ----------------------------------------------------------------------------
#  SmartColor
#  Easily find colors, and convert between color formats
# ----------------------------------------------------------------------------

    module.exports = ->
        Convert = (require './Convert')()

    # -------------------------------------
    #  Color Regexes
    # -------------------------------------
        COLOR_REGEXES =
            # Matches HSL: eg
            # hsl(320, 100%, 100%) and hsl(26, 57, 32) and hsl(      36   ,    67   ,   16 )
            HSL: /hsl\s*?\(\s*([0-9]|[1-9][0-9]|[1|2][0-9][0-9]|3[0-5][0-9]|360)\s*?,\s*?([0-9]|[1-9][0-9]|100)\%?\s*?,\s*?([0-9]|[1-9][0-9]|100)\%?\s*\)/i

            # Matches HSL + A: eg
            # hsla(320, 100%, 38%, 0.3) and hsla(26, 57, 32, .3) and hsla(      36 ,    67   ,   16   , 1.0 ) and hsla(0, 0%, 0%, 0.42)
            HSLA: /hsla\s*?\(\s*([0-9]|[1-9][0-9]|[1|2][0-9][0-9]|3[0-5][0-9]|360)\s*?,\s*?([0-9]|[1-9][0-9]|100)\%?\s*?,\s*?([0-9]|[1-9][0-9]|100)\%?\s*?,\s*?(0|1|1.0|0*\.\d+)\s*?\)/i

            # Matches HSV: eg
            # hsv(320, 100%, 100%) and hsv(26, 57, 32) and hsv(      36   ,    67   ,   16 )
            HSV: /hsv\s*?\(\s*([0-9]|[1-9][0-9]|[1|2][0-9][0-9]|3[0-5][0-9]|360)\s*?,\s*?([0-9]|[1-9][0-9]|100)\%?\s*?,\s*?([0-9]|[1-9][0-9]|100)\%?\s*\)/i

            # Matches HSV + A: eg
            # hsva(320, 100%, 38%, 0.3) and hsva(26, 57, 32, .3) and hsva(      36 ,    67   ,   16   , 0.3 ) and hsva(0, 0%, 0%, 1.0)
            HSVA: /hsva\s*?\(\s*([0-9]|[1-9][0-9]|[1|2][0-9][0-9]|3[0-5][0-9]|360)\s*?,\s*?([0-9]|[1-9][0-9]|100)\%?\s*?,\s*?([0-9]|[1-9][0-9]|100)\%?\s*?,\s*?(0|1|1.0|0*\.\d+)\s*?\)/i

            # Matches VEC: eg
            # vec3(0.44f, 0.3, 0) and vec3(1.0, 0.42, .4) and vec3(      1f  ,    0.4   ,   1.0 )
            VEC: /vec3\s*?\(\s*?([0]?\.[0-9]*|1\.0|1|0)[f]?\s*?\,\s*?([0]?\.[0-9]*|1\.0|1|0)[f]?\s*?\,\s*?([0]?\.[0-9]*|1\.0|1|0)[f]?\s*?\)/i

            # Matches VECA: eg
            # vec4(0.4, 0.33, 0f, 0.5) and vec4(1.0, 0.4121231f, .4, 1.0f) and vec4(      1f   ,    0.4   ,   1.0, 0 )
            VECA: /vec4\s*?\(\s*?([0]?\.[0-9]*|1\.0|1|0)[f]?\s*?\,\s*?([0]?\.[0-9]*|1\.0|1|0)[f]?\s*?\,\s*?([0]?\.[0-9]*|1\.0|1|0)[f]?\s*?\,\s*?([0]?\.[0-9]*|1\.0|1|0)[f]?\s*?\)/i

            # Matches RGB: eg.
            # rgb(0, 99, 199) and rgb ( 255   , 180   , 255 )
            RGB:  /rgb\s*?\(\s*?([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\s*?,\s*?([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\s*?,\s*?([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\s*?\)/i

            # Matches RGB + A: eg.
            # rgba(0, 99, 199, 0.3) and rgba ( 82   ,    121,    0,     .68  )
            RGBA: /rgba\s*?\(\s*?([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][<0-9]|25[0-5])\s*?,\s*?([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\s*?,\s*?([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\s*?,\s*?(0|1|1.0|0*\.\d+)\s*?\)/i

            # Matches HEX:
            # eg. #000 and #ffffff
            HEX: /(\#[a-f0-9]{6}|\#[a-f0-9]{3})/i

            # Matches HEX + A: eg
            # rgba(#fff, 0.3) and rgba(#000000, .8) and rgba ( #000    , .8)
            HEXA: /rgba\s*?\(\s*(\#[a-f0-9]{6}|\#[a-f0-9]{3})\s*?,\s*?(0|1|1.0|0*\.\d+)\s*?\)/i
        MATCH_ORDER = ['HSL', 'HSLA', 'HSV', 'HSVA', 'VEC', 'VECA', 'RGB', 'RGBA', 'HEXA', 'HEX']

    # -------------------------------------
    #  Abbreviation functions
    # -------------------------------------
        n = (number) ->
            number = "#{ number }"

            # Abbreviate if `abbreviateValues` option is true
            if atom.config.get 'color-picker.abbreviateValues'
                if number[0] is '0' and number[1] is '.'
                    return number.substring 1 # TODO or `substr`?
                else if (parseFloat number, 10) is 1
                    return '1'
            return number
        f = (number) ->
            number = "#{ number }"

            if number[3] and number[3] is '0'
                return number.substring 0, 3 # TODO or `substr`?
            return number

        s = (string) ->
            if atom.config.get 'color-picker.abbreviateValues'
                return string.replace /\s/g, ''
            return string

    # -------------------------------------
    #  Public functionality
    # -------------------------------------
        return {
        # -------------------------------------
        #  Find colors in string
        #  - string {String}
        #
        #  @return String
        # -------------------------------------
            find: (string) ->
                SmartColor = this
                _colors = []

                for _format in MATCH_ORDER when _regExp = COLOR_REGEXES[_format]
                    _matches = string.match (new RegExp _regExp.source, 'ig')
                    continue unless _matches

                    for _match in _matches then do (_format, _match) ->
                        return if (_index = string.indexOf _match) is -1

                        _colors.push
                            match: _match
                            format: _format
                            start: _index
                            end: _index + _match.length

                            getSmartColor: -> SmartColor[_format](_match)
                            isColor: true

                        # Remove the match from the line content string to
                        # “mark it” as having been “spent”. Be careful to keep the
                        # correct amount of characters in the string as this is
                        # later used to see which match fits best, if any
                        string = string.replace _match, (new Array _match.length + 1).join ' '
                return _colors

        # -------------------------------------
        #  Base color object, all colors are versions of this object
        #  - format {String}: the color format
        #  - value {String|Array}: The color value
        #  - RGBAArray {Array}: The color value in RGBAArray format
        # -------------------------------------
            color: (format, value, RGBAArray) ->
                format: format
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
                toRGB: -> return s "rgb(#{ @toRGBArray().join ', ' })"
                toRGBArray: -> [@RGBAArray[0], @RGBAArray[1], @RGBAArray[2]]

                # RGBA
                toRGBA: ->
                    _rgbaArray = @toRGBAArray()
                    return s "rgba(#{ _rgbaArray[0] }, #{ _rgbaArray[1] }, #{ _rgbaArray[2] }, #{ n _rgbaArray[3] })"
                toRGBAArray: -> @RGBAArray

            #  HSL
            # ---------------------------
                toHSL: ->
                    _hslArray = @toHSLArray()
                    return s "hsl(#{ _hslArray[0] }, #{ _hslArray[1] }%, #{ _hslArray[2] }%)"
                toHSLArray: -> Convert.rgbToHsl @toRGBArray()

                # HSLA
                toHSLA: ->
                    _hslaArray = @toHSLAArray()
                    return s "hsla(#{ _hslaArray[0] }, #{ _hslaArray[1] }%, #{ _hslaArray[2] }%, #{ n _hslaArray[3] })"
                toHSLAArray: -> @toHSLArray().concat [@getAlpha()]

            #  HSV
            # ---------------------------
                toHSV: ->
                    _hsvArray = @toHSVArray()
                    return s "hsv(#{ Math.round _hsvArray[0] }, #{ (_hsvArray[1] * 100) << 0 }%, #{ (_hsvArray[2] * 100) << 0 }%)"
                toHSVArray: -> Convert.rgbToHsv @toRGBArray()

                # HSVA
                toHSVA: ->
                    _hsvaArray = @toHSVAArray()
                    return s "hsva(#{ Math.round _hsvaArray[0] }, #{ (_hsvaArray[1] * 100) << 0 }%, #{ (_hsvaArray[2] * 100) << 0 }%, #{ n _hsvaArray[3] })"
                toHSVAArray: -> @toHSVArray().concat [@getAlpha()]

            #  VEC
            # ---------------------------
                toVEC: ->
                    _vecArray = @toVECArray()
                    return s "vec3(#{ f _vecArray[0] }, #{ f _vecArray[1] }, #{ f _vecArray[2] })"
                toVECArray: -> Convert.rgbToVec @toRGBArray()

                # VECA
                toVECA: ->
                    _vecaArray = @toVECAArray()
                    return s "vec4(#{ f _vecaArray[0] }, #{ f _vecaArray[1] }, #{ f _vecaArray[2] }, #{ f _vecaArray[3] })"
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
                toHEXA: -> s "rgba(#{ @toHEX() }, #{ n @getAlpha() })"

        # -------------------------------------
        #  Color input formats...
        # -------------------------------------
            # RGB
            RGB: (value) -> @color 'RGB', value, do ->
                _match = value.match COLOR_REGEXES.RGB

                return ([
                    parseInt _match[1], 10
                    parseInt _match[2], 10
                    parseInt _match[3], 10
                ]).concat [1] # add default alpha
            RGBArray: (value) -> @color 'RGBArray', value, do ->
                return value.concat [1]

            # RGBA
            RGBA: (value) -> @color 'RGBA', value, do ->
                _match = value.match COLOR_REGEXES.RGBA

                return ([
                    parseInt _match[1], 10
                    parseInt _match[2], 10
                    parseInt _match[3], 10
                ]).concat [parseFloat _match[4], 10]
            RGBAArray: (value) -> @color 'RGBAArray', value, value

            # HSL
            HSL: (value) -> @color 'HSL', value, do ->
                _match = value.match COLOR_REGEXES.HSL

                return (Convert.hslToRgb [
                    parseInt _match[1], 10
                    parseInt _match[2], 10
                    parseInt _match[3], 10
                ]).concat [1] # add default alpha
            HSLArray: (value) -> @color 'HSLArray', value, do ->
                return (Convert.hslToRgb value).concat [1]

            # HSLA
            HSLA: (value) -> @color 'HSLA', value, do ->
                _match = value.match COLOR_REGEXES.HSLA

                return (Convert.hslToRgb [
                    parseInt _match[1], 10
                    parseInt _match[2], 10
                    parseInt _match[3], 10
                ]).concat [parseFloat _match[4], 10]
            HSLAArray: (value) -> @color 'HSLAArray', value, do ->
                return (Convert.hslToRgb value).concat [value[3]]

            # HSV
            HSV: (value) -> @color 'HSV', value, do ->
                _match = value.match COLOR_REGEXES.HSV

                return (Convert.hsvToRgb [
                    parseInt _match[1], 10
                    parseInt _match[2], 10
                    parseInt _match[3], 10
                ]).concat [1]
            HSVArray: (value) -> @color 'HSVArray', value, do ->
                return (Convert.hsvToRgb value).concat [1]

            # HSVA
            HSVA: (value) -> @color 'HSVA', value, do ->
                _match = value.match COLOR_REGEXES.HSVA

                return (Convert.hsvToRgb [
                    parseInt _match[1], 10
                    parseInt _match[2], 10
                    parseInt _match[3], 10
                ]).concat [parseFloat _match[4], 10]
            HSVAArray: (value) -> @color 'HSVAArray', value, do ->
                return (Convert.hsvToRgb value).concat [value[3]]

            # VEC
            VEC: (value) -> @color 'VEC', value, do ->
                _match = value.match COLOR_REGEXES.VEC

                return (Convert.vecToRgb [
                    (parseFloat _match[1], 10).toFixed 2
                    (parseFloat _match[2], 10).toFixed 2
                    (parseFloat _match[3], 10).toFixed 2
                ]).concat [1]
            VECArray: (value) -> @color 'VECArray', value, do ->
                return (Convert.vecToRgb value).concat [1]

            # VECA
            VECA: (value) -> @color 'VECA', value, do ->
                _match = value.match COLOR_REGEXES.VECA

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
                _match = value.match COLOR_REGEXES.HEXA
                return (Convert.hexToRgb _match[1]).concat [parseFloat _match[2], 10]
        }
