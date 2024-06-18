const reduce = Function.bind.call(Function.call, Array.prototype.reduce);
const isEnumerable = Function.bind.call(Function.call, Object.prototype.propertyIsEnumerable);
const concat = Function.bind.call(Function.call, Array.prototype.concat);
const keys = Reflect.ownKeys;

Object.values = function (O) {
    return reduce(keys(O), (v, k) => concat(v, typeof k === 'string' && isEnumerable(O, k) ? [O[k]] : []), []);
};
Object.entries = function (O) {
    return reduce(keys(O), (e, k) => concat(e, typeof k === 'string' && isEnumerable(O, k) ? [[k, O[k]]] : []), []);
};
Object.prototype.sortKey = function (key) {
    return Object.values(this).sort(function (a, b) {
        if (isset(a[key]) && isset(b[key])) {
            return a[key] - b[key];
        }
    });
};
Array.prototype.group = function (c) {
    var r = {};
    for (var i = 0; i < this.length; i++) {
        var cat = this[i][c];
        delete this[i][c];
        if (!r.hasOwnProperty(cat)) {
            r[cat] = [];
        }
        r[cat].push(this[i]);
    }
    return r;
};
// removes duplicates and empty items
Array.prototype.prune = function () {
    var data = this;
    return (data.filter(function (v, i) {
        if (v !== null && v !== "") {
            return data.indexOf(v) === i;
        }
    }));
};
Array.prototype.random = function () {
    return this[Math.floor(Math.random() * this.length)];
};
// populates an array with string, number or a function
Array.prototype.fill = function (content, size) {
    for (var i = 0; i < size; i++) {
        if (typeof content === "function") {
            this.push(content());
        } else {
            this.push(content);
        }
    }
    return this;
};
// returns the array indexes of matching key=value items
// 3 modes available, key, value or key=val
Array.prototype.Find = function (key, val) {
    var results = [];
    if (isset(val) && isset(key)) {
        for (var i = 0; i < this.length; i++) {
            if (this[i][key] === val) {
                results.push(i);
            }
        }
        return results;
    }

    if (isset(val) && !isset(key)) {
        for (var i = 0; i < this.length; i++) {
            var k = Object.keys(this[i]);
            for (var z = 0; z < k.length; z++) {
                if (this[i][k[z]] === val) {
                    results.push(i);
                }
            }
        }
        return results;
    }

    if (!isset(val) && isset(key)) {
        for (var i = 0; i < this.length; i++) {
            if (this[i].hasOwnProperty(key)) {
                results.push(i);
            }
        }
        return results;
    }
};
Array.prototype.findFirst = function (key, val) {
    return (this.Find(key, val)[0] || -1);
};
Array.prototype.getFirst = function (key, val) {
    var data = this;
    var id = data.findFirst(key, val);
    if (id > -1) {
        return data[id];
    }
};
Array.prototype.get = function (key, val) {
    var result = [];
    var data = this;
    var idx = data.find(key, val);
    for (var i = 0; i < idx.length; i++) {
        result.push(data[idx[i]]);
    }
    return result;
};
Array.prototype.delete = function (key, val) {
    let newArray = this.slice();
    var idx = newArray.find(key, val);
    for (var i = 0; i < idx.length; i++) {
        newArray.splice(idx[i], 1);
    }
    return newArray;
};
Array.prototype.each = function (icb, ecb) {
    var i = 0;
    var a = this;
    var done = false;
    a.forEach(function (e) {
        if (done === true) {
            return;
        }
        icb(e, {"break": function () {
                done = true;
                ecb();
            }});
        i++;
        if (i === a.length) {
            if (done === true) {
                return;
            }
            ecb();
        }
    });
};
Object.prototype.extend = function (o) {
    var O = this;
    for (var i in o) {
        O[i] = o[i];
    }
    return O;
};
Object.prototype.forEach = function (cb) {
    Object.keys(this).forEach(cb);
};
Object.prototype.each = function (cb) {
    for (var key in this) {
        if (this.hasOwnProperty(key)) {
            cb(key, this[key]);
        }
    }
};
// extracts a key value from an array of objects, like a fetching a table's single column
Array.prototype.extract = function (key) {
    var buf = [];
    for (var i = 0; i < this.length; i++)
        buf.push(this[i][key]);
    return buf;
};
// converts array of bits (true/false) to decimal
Array.prototype.toDecimal = function () {
    var buf = "";
    for (var i = 0; i < this.length; i++) {
        buf += (this[i] === true ? "1" : "0");
    }
    return buf.toDecimal();
};
Array.prototype.last = function () {
    return this[this.length - 1];
};

