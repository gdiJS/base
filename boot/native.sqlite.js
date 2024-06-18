
/* global __db, VM, vm, _sqlite */

var Sqlite = function () {
    var T = this, A = arguments;
    const api = _sqlite;

    T.id = null;
    T.open = function (f) {
        T.id = api.open(f);
        vm.release(function () {
            T.close();
        });
    };

    T.close = function () {
        if (T.id > -1) {
            T.id = -1;
            return api.close(T.id);
        }
    };

    T.query = function () {
        var A = arguments;
        if (A.length > 2) {
            api.queryEx(A[0], A[1], function (r) {
                A[2](r);
            });
            return;
        }
        var r = api.query(T.id, A[0]).toString().parse();
        if (typeof A[1] === "undefined") {
            return r;
        }
        A[1](r);
    };

    T.exec = function (sql) {
        return parseInt(api.exec(T.id, sql));
    };

    if (A.length > 0) {
        T.open(A[0]);
    }

    return T;
};