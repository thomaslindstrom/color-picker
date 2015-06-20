"use babel";

// ---------------------------------------------------------------------------
//  modules: debounce
//  prevent a function from calling too often
// ---------------------------------------------------------------------------

    module.exports = function (callback, wait) {
        var Timeout = {
            timeout: null,

            reset: function() { this.timeout = null; },
            set: function(to) { this.timeout = to; },
            isSet: function() { return !!this.timeout; }
        };


        var _function; return _function = function() {
            let _this = this, _arguments = arguments;

            // If Timeout is set, fire wait function to try again in a bit
            if (Timeout.isSet()) {
                if (typeof wait === 'number') {
                    setTimeout(function() {
                        _function.apply(_this, _arguments);
                    }, wait);
                } else if (typeof wait === 'function') {
                    wait(function() {
                        _function.apply(_this, _arguments);
                    }); }
                return;
            }

            // Timeout is not set
            if (typeof wait === 'number') {
                Timeout.set(setTimeout(function() {
                    Timeout.reset();
                }, wait));
            } else if (typeof wait === 'function') {
                Timeout.set(wait(function() {
                    Timeout.reset();
                }));
            }

            // Fire function
            callback.apply(this, _arguments);
        };
    }
