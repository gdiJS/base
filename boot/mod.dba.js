/* global sqlite */

const DBA = function (db) {
    var T = this;
    var t;
    if (typeof db === "string") {
        t = true;
    }

    T.get = function (table, cb) {
        var q = "select * from " + table;
        if (t) {
            sqlite().query(db, q, function (r) {
                cb(r);
            });
            return;
        }
        var r = db.query(q);
        cb(r);
    };

    T.query = function (table, key, val) {
        if (typeof val === "string") {
            val = "'" + val + "'";
        }
        var q = "select * from " + table + " where " + key + "=" + val;
        if (t) {
            sqlite().query(db, q, function (r) {
                cb(r);
            });
            return;
        }
        return db.query(q);
    };

    T.insert = function (table, data, cb) {
        cb = cb || function () {};
        var s = "INSERT INTO " + table + "(";
        var v = "VALUES(";
        data.forEach(function (k, i) {
            s += k + ",";
            if (typeof data[k] === "string") {
                v += "'" + (data[k]) + "',";
            } else {
                if (isNaN(data[k]) || typeof data[k] === "undefined" || data[k] === null) {
                    v += ",";
                } else {
                    v += "" + (data[k]).toString() + ",";
                }
            }
        });

        if (v.slice(-1) === ",") {
            v = v.slice(0, -1);
        }
        var query = s.replaceAt(s.length - 1, ')') + " " + v + ')' + ";";
        if (t) {
            sqlite().query(db, query, function (r) {
                cb(r);
            });
            return;
        }
        return db.query(query);
    };

    return T;
};


