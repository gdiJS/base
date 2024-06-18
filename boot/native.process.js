

/* global __proc, nil, _proc */
var proc = {
    _: _proc,
    interval: 500,
    list: [],
    cache: [],
    tmr: null,
    act: false,
    buf: {
        current: "",
        path: ""
    },
    path: function () {
        if (this.buf.path !== "") {
            return this.buf.path;
        }

        if (this.buf.current === "") {
            this.buf.current = this._.current();
        }
        this.buf.path = this.buf.current.ignorelastDelimiter("/");
        return this.buf.path;
    },
    enum: function () {
        this.cache = this._.list().toString().parse();
        return this.cache;
    },
    exists: function (p) {
        if (this.enum().indexOf(p) > -1) {
            return true;
        }
        return false;
    },
    current: function () {
        if (this.buf.current !== "") {
            return this.buf.current;
        }
        this.buf.current = this._.current();
        return this.buf.current;
    },
    add: function (e, cb) {
        var T = this;
        e.cb = cb;
        T.list.push(e);
        if (!T.act) {
            T.act = true;
            T.tmr = setInterval(function () {
                T.list.forEach(function (i, k) {
                    if (typeof i !== "undefined") {
                        if (i.running === true) {
                            if ((T._.ping(i.id)) === 0) {
                                T.list[k].cb(i.path);
                                T.list[k].running = false;
                                T._.release(i.id);
                            }
                        } else {
                            delete T.list[k];
                        }
                    }
                });
            }, T.interval);
        }
    }
};


var process = function () {
    var T = this;
    const api = proc;

    T.meta = {};
    T.create = function (path, onCreate, onClose) {
        if (typeof onCreate === "undefined")
            onCreate = nil;

        if (typeof onClose === "undefined")
            onClose = nil;
        var params = "";

        T.meta = JSON.parse(T._.create(path, params, 0));
        if (T.meta.running === true) {
            onCreate(T.meta.pid);
            T.meta.path = path;
            proc.add(T.meta, onClose);
            return true;
        } else {
            return false;
        }
    };
    return T;
};


