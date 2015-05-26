# ----------------------------------------------------------------------------
#  Convert
# ----------------------------------------------------------------------------

    module.exports = ->
        # TODO: I don't like this file. It's ugly and feels weird

    # -------------------------------------
    #  HEX to RGB
    # -------------------------------------
        hexToRgb: (hex) ->
            hex = hex.replace '#', ''
            hex = hex.replace /(.)(.)(.)/, "$1$1$2$2$3$3" if hex.length is 3

            return [
                parseInt (hex.substr 0, 2), 16
                parseInt (hex.substr 2, 2), 16
                parseInt (hex.substr 4, 2), 16]

    # -------------------------------------
    #  HEXA to RGB
    # -------------------------------------
        hexaToRgb: (hexa) ->
            return @hexToRgb (hexa.match /rgba\((\#.+),/)[1]

    # -------------------------------------
    #  HEX to HSL
    # -------------------------------------
        hexToHsl: (hex) ->
            return @rgbToHsl @hexToRgb hex.replace '#', ''

    # -------------------------------------
    #  RGB to HEX
    # -------------------------------------
        rgbToHex: (rgb) ->
            _componentToHex = (component) ->
                _hex = component.toString 16
                return if _hex.length is 1 then "0#{ _hex }" else _hex

            return [
                (_componentToHex rgb[0])
                (_componentToHex rgb[1])
                (_componentToHex rgb[2])
            ].join ''

    # -------------------------------------
    #  RGB to HSL
    # -------------------------------------
        rgbToHsl: ([r, g, b]) ->
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
                Math.floor _l * 100]

    # -------------------------------------
    #  RGB to HSV
    # -------------------------------------
        rgbToHsv: ([r, g, b]) ->
            computedH = 0
            computedS = 0
            computedV = 0

            if not r? or not g? or not b? or isNaN(r) or isNaN(g) or isNaN(b)
                return
            if r < 0 or g < 0 or b < 0 or r > 255 or g > 255 or b > 255
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
                    computedV]

            # Colors other than black-gray-white:
            d = (if (r is minRGB) then g - b else ((if (b is minRGB) then r - g else b - r)))
            h = (if (r is minRGB) then 3 else ((if (b is minRGB) then 1 else 5)))

            computedH = 60 * (h - d / (maxRGB - minRGB))
            computedS = (maxRGB - minRGB) / maxRGB
            computedV = maxRGB

            return [
                computedH
                computedS
                computedV]

    # -------------------------------------
    #  HSV to HSL
    # -------------------------------------
        hsvToHsl: ([h, s, v]) -> [
            h
            s * v / (if (h = (2 - s) * v) < 1 then h else 2 - h)
            h / 2]

    # -------------------------------------
    #  HSV to RGB
    # -------------------------------------
        hsvToRgb: ([h, s, v]) ->
            h /= 60 # 0 to 5
            s /= 100
            v /= 100

            # Achromatic grayscale
            if s is 0 then return [
                Math.round v * 255
                Math.round v * 255
                Math.round v * 255]

            _i = Math.floor h
            _f = h - _i
            _p = v * (1 - s)
            _q = v * (1 - s * _f)
            _t = v * (1 - s * (1 - _f))

            _result = switch _i
                when 0 then [v, _t, _p]
                when 1 then [_q, v, _p]
                when 2 then [_p, v, _t]
                when 3 then [_p, _q, v]
                when 4 then [_t, _p, v]
                when 5 then [v, _p, _q]
                else [v, _t, _p]

            return [
                Math.round _result[0] * 255
                Math.round _result[1] * 255
                Math.round _result[2] * 255]

    # -------------------------------------
    #  HSL to HSV
    # -------------------------------------
        hslToHsv: ([h, s, l]) ->
            s /= 100
            l /= 100

            s *= if l < .5 then l else 1 - l

            return [
                h
                (2 * s / (l + s)) or 0
                l + s]

    # -------------------------------------
    #  HSL to RGB
    # -------------------------------------
        hslToRgb: (input) ->
            [h, s, v] = @hslToHsv input
            return @hsvToRgb [h, (s * 100), (v * 100)]

    # -------------------------------------
    #  VEC to RGB
    # -------------------------------------
        vecToRgb: (input) -> return [
            (input[0] * 255) << 0
            (input[1] * 255) << 0
            (input[2] * 255) << 0]

    # -------------------------------------
    #  RGB to VEC
    # -------------------------------------
        rgbToVec: (input) -> return [
            (input[0] / 255).toFixed 2
            (input[1] / 255).toFixed 2
            (input[2] / 255).toFixed 2]
