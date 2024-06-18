
/* global __db, VM, __aud, nil, vm, $audio, _audio */

var Audio = function () {
    var T = this, A = arguments;
    T.api = _audio;

    T.rate = A[0] || 44100;
    T.id = T.api.init(T.rate);
    T.samples = [];
    var virgin = true;
    var events = [];
    var reinit = function () {
        T.api.kill(T.id);
        T.id = T.api.init(T.rate);
    };

    T.release = function () {
        T.api.kill(T.id);
    };

    T.loadSample = function (file, cb) {
        if (typeof cb === "undefined") {
            cb = nil;
        }
        var tag = file.toString().lastDelimiter("/").toString().ignorelastDelimiter(".");
        if (this.api.sload(T.id, file, tag) > 0) {
            T.samples.push(tag);
            cb(tag);
        }
    };

    T.play = function (path) {
        return T.api.stream(T.id, path);
    };

    T.playSample = function (tag) {
        if (T.samples.indexOf(tag) > -1) {
            return T.api.splay(T.id, tag);
        } else {
            return -1;
        }
    };
    T.playDSP = function (f) {
        return T.api.playd(T.id, f);
    };
    T.on = function (e, cb) {
        events.push({E: e, C: cb});
    };

    var callback = function (e, p) {
        events.forEach(function (o) {
            if (e === o.E) {
                o.C(p);
            }
        });
    };
    T.muted = false;

    T.api.monitor(function (e) {
        switch (e) {
            case 0:
                callback("activity", false);
                break;
            case 1:
                callback("activity", true);
                break;
            case 2:
                if (virgin === false) {
                    console.log("reinitializing Audio output..");
                    reinit();
                    virgin = true;
                    setTimeout(function () {
                        callback("reinit");
                    }, 3000);
                }
                callback("device", "change");
                T.muted = false;
                callback("mute", false);
                break;
            case 3:
                T.muted = true;
                callback("mute", true);
                break;
            case 4:
                T.muted = true;
                virgin = false;
                callback("mute", true);
                callback("device", "disconnect");
                break;
            case 5:
                if (virgin === false) {
                    console.log("reinitializing Audio output..");
                    virgin = true;
                    reinit();
                    setTimeout(function () {
                        callback("reinit");
                    }, 3000);
                }
                callback("device", "connect");
                T.muted = false;
                callback("mute", false);
                break;
            case 6:
                T.muted = true;
                virgin = false;
                callback("device", "stall");
                callback("mute", true);
                break;
            case 7:
                T.muted = false;
                callback("mute", false);
                break;
            default:
                if (e >= 1000) {
                    var volume = e - 1000;
                    if (T.muted === true && volume > 0) {
                        T.muted = false;
                        callback("mute", false);
                    }
                    if (volume === 0) {
                        T.muted === true;
                        callback("mute", true);
                    } else {
                        T.muted = false;
                        callback("mute", false);
                    }
                    callback("volume", e - 1000);
                }
                break;
        }
    });
    vm.release(function () {
        T.release();
    });
    return T;
};