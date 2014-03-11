# ----------------------------------------------------------------------------
#  ColorPicker: Convert
# ----------------------------------------------------------------------------

    module.exports =
    # -------------------------------------
    #  HEX to RGB
    # -------------------------------------
        hexToRgb: (hex) ->
            hex = hex.replace '#', ''
            if hex.length is 3 then hex = hex.replace /(.)(.)(.)/, "$1$1$2$2$3$3"

            return [
                (parseInt (hex.substr 0, 2), 16),
                (parseInt (hex.substr 2, 2), 16),
                (parseInt (hex.substr 4, 2), 16)
            ]

    # -------------------------------------
    #  HEX to HSL
    # -------------------------------------
        hexToHsl: (hex) ->
            hex = hex.replace '#', ''
            return @rgbToHsl @hexToRgb hex

    # -------------------------------------
    #  RGB to HEX
    # -------------------------------------
        rgbToHex: (rgb) ->
            _componentToHex = (component) ->
                _hex = component.toString 16
                return if _hex.length is 1 then "0#{ _hex }" else _hex

            return [
                (_componentToHex rgb[0]),
                (_componentToHex rgb[1]),
                (_componentToHex rgb[2])
            ].join ''

    # -------------------------------------
    #  RGB to HSL
    # -------------------------------------
        rgbToHsl: (rgb) ->
            [r, g, b] = rgb

            r /= 255
            g /= 255
            b /= 255

            _max = Math.max r, g, b
            _min = Math.min r, g, b

            _l = (_max + _min) / 2

            if _max is _min then return [0, 0, Math.floor _l * 100]

            _d = _max - _min
            _s = if _l > 0.5 then _d / (2 - _max - _min) else _d / (_max + _min)

            switch _max
                when r then _h = (g - b) / _d + (if g < b then 6 else 0)
                when g then _h = (b - r) / _d + 2
                when b then _h = (r - g) / _d + 4

            _h /= 6

            return [
                Math.floor _h * 360
                Math.floor _s * 100
                Math.floor _l * 100
            ]

    # -------------------------------------
    #  RGB to HSV
    # -------------------------------------
        rgbToHsv: (rgb) ->
            if typeof rgb is 'string' then rgb = rgb.match /(\d+)/g

            [r, g, b] = rgb

            computedH = 0
            computedS = 0
            computedV = 0

            #remove spaces from input RGB values, convert to int
            r = parseInt(("" + r).replace(/\s/g, ""), 10)
            g = parseInt(("" + g).replace(/\s/g, ""), 10)
            b = parseInt(("" + b).replace(/\s/g, ""), 10)

            if not r? or not g? or not b? or isNaN(r) or isNaN(g) or isNaN(b)
                alert "Please enter numeric RGB values!"
                return
            if r < 0 or g < 0 or b < 0 or r > 255 or g > 255 or b > 255
                alert "RGB values must be in the range 0 to 255."
                return

            r = r / 255
            g = g / 255
            b = b / 255

            minRGB = Math.min(r, Math.min(g, b))
            maxRGB = Math.max(r, Math.max(g, b))

            # Black-gray-white
            if minRGB is maxRGB
                computedV = minRGB
                return [
                    0
                    0
                    computedV
                ]

            # Colors other than black-gray-white:
            d = (if (r is minRGB) then g - b else ((if (b is minRGB) then r - g else b - r)))
            h = (if (r is minRGB) then 3 else ((if (b is minRGB) then 1 else 5)))
            computedH = 60 * (h - d / (maxRGB - minRGB))
            computedS = (maxRGB - minRGB) / maxRGB
            computedV = maxRGB

            return [
                computedH
                computedS
                computedV
            ]
