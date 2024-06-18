/* global __hw, VM, vm, $hw, _hw */

var Hardware = function () {
    var T = this;
    const api = _hw;
   // delete _hw;

    var buf = [];
    T.active = false;
    T.delay = 250;
    var events = [];
    var act = false;

    const IsinBuf = function (id, buf) {
        for (var i = 0; i < buf.length; i++) {
            if (id === buf[i].id) {
                return true;
            }
        }
        return false;
    };

    const parsePath = function (str) {
        var res = [];
        if (typeof str === "undefined" || str === "") {
            return res;
        }
        if (str.indexOf(',') > -1) {
            var items = str.split(',');
            for (var i = 0; i < items.length; i++) {
                res.push(items[i].split('\\'));
            }
        } else {
            res.push(str.split('\\'));
            cb(res);
        }

    };

    const devFilter = function (list, o) {
        if (list.length > 0) {
            if (typeof o.d === "undefined") {
                o.c(list);
            } else {
                for (var I = 0; I < list.length; I++) {
                    if (list[I].name.indexOf(o.d) > -1) {
                        o.c(list[I]);
                        return;
                    }
                }
            }
        }
    };

    const CheckNew = function (tmp, res) {
        if (buf.length === tmp.length) {
            return;
        }
        var list = [];
        var I = 0;
        tmp.forEach(function (i) {
            I++;
            if (IsinBuf(i.id, buf) === false) {
                //i.path = T.parsePath(i.path);
                list.push(i);
            }
            if (I >= tmp.length) {
                buf = tmp;
                res(list);
                return;
            }
        });
    };

    const CheckGone = function (tmp, res) {
        if (buf.length === tmp.length) {
            return;
        }
        var list = [];
        var I = 0;
        buf.forEach(function (i) {
            I++;
            if (IsinBuf(i.id, tmp) === false) {
                //i.path = T.parsePath(i.path);
                list.push(i);
            }
            if (I >= buf.length) {
                buf = tmp;
                res(list);
                return;
            }
        });
    };

    const Callback = function (incoming) {
        setTimeout(function () {
            var tmp = T.list();
            events.forEach(function (o, i) {
                if (o.e === "arrival" && incoming === 1) {
                    CheckNew(tmp, function (list) {
                        devFilter(list, o);
                    });
                }
                if (o.e === "removal" && incoming === 0) {
                    CheckGone(tmp, function (list) {
                        devFilter(list, o);
                    });
                }
            });
        }, T.delay);
    };

    T.list = function () {
        return api.list().toString().parse();
    };

    T.exists = function (devname) {
        for (var i = 0; i < T.buf.length; i++) {
            if (buf[i].name.indexOf(devname) > -1) {
                return true;
            }
        }
        return false;
    };


    T.free = function () {
        T.active = false;
        T.buf = null;
        events = null;
    };

    T.on = function (event, callback, devId) {
        events.push({e: event, c: callback, d: devId});
        if (act === false) {
            act = true;
            api.onDevice(function (e) {
                if (T.active === true) {
                    Callback(parseInt(e));
                }
            });
        }
    };

    T.active = true;
    T.buf = T.enum();
    return T;
};

