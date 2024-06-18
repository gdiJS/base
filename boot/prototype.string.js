
/* global parseInt */

String.random = function (len) {
    len = len || 6;
    var text = "";
    var l = "abcdefghijklmnopqrstuvwxyz";
    for (var i = 0; i < len; i++)
        text += l.charAt(Math.floor(Math.random() * l.length));
    return text;

};

String.prototype.count = function (search) {
    var m = this.match(new RegExp(search.toString().replace(/(?=[.\\+*?[^\]$(){}\|])/g, "\\"), "g"));
    return m ? m.length : 0;
};

String.prototype.extract = function (a, b) {
    var pattern = new RegExp(escapeRegExp(a) + "(.*?)" + escapeRegExp(b), "is");
    var match = pattern.exec(this);
    return match ? match[1] : '';
};

String.prototype.capitalize = function (all) {
    if (all && this.indexOf(" ") > -1) {
        return this.split(" ").map(function (e) {
            if (e.length < 3) {
                return e;
            }
            return e.charAt(0).toUpperCase() + e.slice(1);
        }).join(" ");
    } else {
        if (this.length < 3) {
            return this;
        }
        return this.charAt(0).toUpperCase() + this.slice(1);
    }
};

String.prototype.render = function (v) {
    var s = this, m;
    while (m = /{([^}]+)?}/g.exec(s)) {
        s = s.replace(m[0], v[m[1]]);
    }
    return s;
};

String.prototype.eval = function () {
    return eval('(' + this + ")");
};

String.prototype.removeLastChar = function () {
    return this.slice(0, -1);
};

String.prototype.replaceAt = function (n, c) {
    return this.substr(0, n) + c + this.substr(n + 1);
};

String.prototype.getByteLen = function () {
    var byteLen = 0;
    for (var i = 0; i < this.length; i++) {
        var c = this.charCodeAt(i);
        byteLen += c < (1 << 7) ? 1 :
                c < (1 << 11) ? 2 :
                c < (1 << 16) ? 3 :
                c < (1 << 21) ? 4 :
                c < (1 << 26) ? 5 :
                c < (1 << 31) ? 6 : Number.NaN;
    }
    return byteLen;
};

String.prototype.pad = function (w, c) {
    var n = this;
    c = c || '0';
    n = n + '';
    return n.length >= w ? n : new Array(w - n.length + 1).join(c) + n;
};

String.prototype.clean = function () {
    var c = this.charCodeAt(0);
    var str = this;
    if ((c === 65535) || (c === 0)) {
        str = str.substring(1);
    }
    c = this.slice(-1).toCharCode();
    if ((c === 65535) || (c === 0)) {
        str = str.slice(0, -1);
    }
    return str.trim();
};

// splits a string and returns nth piece
String.prototype.explode = function (c, n) {
    return this.split(c)[n];
};

// splits a string and returns all except nth piece
String.prototype.ignore = function (c, n) {
    var i = this.split(c);
    delete i[n];
    return i.join(c);
};

String.prototype.trimAll = function () {
    return this.replace(/^\s+|\s+$/gm, '').replace(/\0/g, '');
};

String.prototype.reverse = function () {
    return this.split("").reverse().join("");
};

String.prototype.toDecimal = function () {
    return parseInt(this.trim().reverse(), 2);
};

String.prototype.toBool = function () {
    return parseInt(this).toBool();
};

String.prototype.toFloat = function () {
    if (this.indexOf(".") < 0) {
        return parseInt(this);
    }

    if (this.indexOf(".00") >= 0) {
        return parseInt(this);
    }

    return parseFloat(this);
};

String.prototype.toBitArray = function () {
    var a = [];
    this.split("").forEach(function (c) {
        a.push(c.toBool());
    });
    return a;
};

// useful when getting filenames & extensions from a path
String.prototype.lastDelimiter = function (e) {
    return this.split(e).slice(-1)[0];
};

String.prototype.ignorelastDelimiter = function (e) {
    var a = this.split(e);
    a.pop();
    return a.join(e);
};

