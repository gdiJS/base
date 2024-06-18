
/* global __ser, VM, _serial, vm */

var Serial = function () {
    var T = this, A = arguments;
    const api = _serial;

    T._port = null;
    T._baud;
    T.active = false;
    T.id = null;
    T.AutoFree = false;
    T.inTmr = null;
    T.outTmr = null;
    T.reading = false;

    T.timeout = 30; // stop read timer if nothing received in xx sec
    T.tts = 1000;   // time to stabilise
    T.interval = 25;     // cycle interval, reduce to process faster  
    T.cache = 30;   // sec

    var pbuf = [];
    T.lastenum = 0;
    T.rec = 0;

    T.wrt = 0;
    T.rdy = false;
    T.recent = null;
    var sbuf = [];
    T.rbuf = "";

    const init = function (port, baud) {
        T.id = api.open(port, baud);
        if (T.id > -1) {
            T._port = port;
            T._baud = baud;
            T.active = true;
        } else {
            return false;
        }
        T.lt = time(true);
        T._baud = baud;
        T._port = port;

        T.outTmr = setInterval(function () {
            if (!T.rdy) {
                if ((time(true) - T.lt) > T.tts) {
                    T.rdy = true;
                }
            } else {
                for (var i = 0; i < sbuf.length; i++) {
                    if (typeof sbuf[i] === "undefined") {
                        continue;
                    }
                    if (sbuf[i].sent === false) {
                        sbuf[i].cb(api.write(T.id, sbuf[i].data));
                        sbuf[i].sent = true;
                    } else {
                        delete sbuf[i];
                    }
                }
            }
        }, T.interval);
        vm.release(function () {
            T.close();
        });
        return true;
    };

    T.open = function (port, baud) {
        if (!port.startsWith('COM')) {
            T.find(port, function (p) {
                if (p !== null && p.busy === false) {
                    return init(p.port, baud);
                }
                return false;
            });
        } else {
            return init(port, baud);
        }
    };

    T.available = function () {
        if (T.active === false) {
            return false;
        }

        if (api.inbuf(T.id) > 0) {
            return true;
        }
        return false;
    };

    T.close = function () {
        if (T.active === false) {
            return false;
        }
        if (T.reading) {
            T.stop();
        }
        clearInterval(T.outTmr);
        api.close(T.id);
        T._port = null;
        T._baud = null;
        T.active = false;
        T.id = null;
        if (T.AutoFree === true) {
            delete T;
        }
    };

    T.read = function () {
        if (T.active === false) {
            return "";
        }
        return api.read(T.id);
    };

    T.write = function (q, cb) {
        if (T.active === false) {
            return false;
        }
        if (typeof cb === "boolean" && cb === true) {
            api.write(T.id, q);
            return true;
        }

        if (typeof cb === "undefined") {
            cb = function () {};
        }
        sbuf.push({
            data: q,
            sent: false,
            cb: cb
        });
        return true;
    };

    T.start = function (cb, delimiter) {
        if (T.active === false) {
            return false;
        }
        if (T.reading === true) {
            return false;
        }
        T.rec = time();
        if (!isset(delimiter)) {
            delimiter = "\n";
        }
        T.inTmr = setInterval(function () {
            if (T.available() === false) {
                return;
            }

            T.rbuf += T.read();
            if (T.rbuf === "") {
                return;
            }
            var str = "";
            T.rbuf.split("").forEach(function (c) {
                if (((c === delimiter))) {
                    if (str !== "") {
                        cb(str.clean());
                    }
                    str = "";
                } else {
                    str += c;
                }
            });
            T.rbuf = str;
            var t = time();
            if ((t - T.rec) > T.timeout) {
                T.stop();
            }
            T.rec = t;
        }, T.interval);
        T.reading = true;
        return true;
    };

    T.stop = function () {
        if (T.reading === false) {
            return false;
        }
        clearInterval(T.inTmr);
        T.reading = false;
    };

    T.enum = function () {
        pbuf = JSON.parse(api.enum());
        return pbuf;
    };

    T.find = function (d, cb) {
        T.enum(function (arr) {
            for (var i = 0; i < arr.length; i++) {
                if (arr[i].desc.toString().indexOf(d) !== -1) {
                    cb(arr[i]);
                    return;
                }
            }
            cb(null);
        });
    };

    if (A.length === 2) {
        if (T.open(A[0], A[1]) === true) {
            T.AutoFree = true;
            return T;
        } else {
            return null;
        }
    }

    return T;
};


