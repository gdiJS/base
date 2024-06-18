/* global _desktop */

var Desktop = function () {
    var T = this;
    var _ = _desktop;
    T.hotkeys = [];
    T._keys = [];
    T.wintrack = [];

    var timer = null;
    var w = 0;
    var f = 0;
    var pause = false;

    T.pause = function () {
        pause = true;
    };

    T.resume = function () {
        pause = false;
    };

    T.procHotkey = function (c) {
        if (pause) {
            return;
        }
        for (var i = 0; i < T.hotkeys.length; i++) {
            if (T.hotkeys[i].id === c) {
                T.hotkeys[i].cb(T.hotkeys[i].param);
                break;
            }
        }
    };

    T.prockey = function (c) {
        if (pause) {
            return;
        }
        for (var i = 0; i < T._keys.length; i++) {
            if (T._keys[i].id === c) {
                T._keys[i].cb(T._keys[i].param);
                break;
            }
        }
    };

    T.getIdle = function () {
        return _.idle();
    };

    T.name = function () {
        return _.name();
    };

    T.sendkey = function (k) {
        if (pause) {
            return;
        }
        return _.sendkey(k);
    };

    T.toggleMonitor = function (e) {
        if (e) {
            _.toggleMonitor(1);
        } else {
            _.toggleMonitor(0);
        }
    };
    T.screenshot = function (f, cb) {
        if (typeof cb === "undefined") {
            cb = nil;
        }
        var i = _.screenshot(f);
        if (i === 1) {
            cb();
        }
    };

    // listens for a specific key
    T.key = function (c, cb, param) {
        var k = {};
        k.id = c;
        k.cb = cb;
        k.param = param || {};
        if (parseInt(_.key(k.id, function (e) {
            T.prockey(e);
        })) === 1) {
            T._keys.push(k);
        }
    };

    // listens for all keys
    T.keys = function (cb) {
        return _.keys(function (e, s) {
            cb(parseInt(e), parseInt(s));
        });
    };

    T.lock = function () {
        _.lock();
        return true;
    };

    // stop listening for keys, (*) for all
    T.stopKeys = function (e) {
        return parseInt(_.nokeys(e));
    };

    T.hotkey = function (c, cb, param) {
        var hk = {};
        hk.id = random(9999);
        hk.cb = cb;
        hk.param = param || {};
        if (parseInt(_.hotkey(hk.id, c.ignorelastDelimiter('+'), c.lastDelimiter('+'), function (e) {
            T.procHotkey(e);
        })) === 1) {
            T.hotkeys.push(hk);
        }
    };

    T.getForegroundWindow = function () {
        return _.getActiveWin();
    };

    T.getCurrentApp = function () {
        return JSON.parse(_.getActiveApp());
    };

    vm.release(function () {
        T.hotkeys = [];
    });

    T.onEvent = function (cb) {
        _.onEvent(function (c) {
            cb(c);
        });
    };

    T.onMessage = function (cb) {
        _.onMessage(function (m) {
            cb(m);
        });
    };

    T.onWindowChanged = function (cb) {
        if (timer === null) {
            timer = setInterval(function () {
                var c = T.getForegroundWindow();
                if (c <= 0) {
                    return;
                }
                if (c !== w) {
                    w = c;
                    cb(T.getCurrentApp());
                } else {
                    var F = _.isFullScreen(c);
                    if (f !== F) {
                        cb(T.getCurrentApp());
                        f = F;
                    }
                }
            }, 25);
        }
        T.wintrack.push(cb);
    };
};

