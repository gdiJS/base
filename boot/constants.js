const nil = function () {};
const nl = "\r\n";

const _1h = 3600;
const _1d = 86400;
const _1m = 86400 * 30;
const _1y = 86400 * 365;

var isset = function (value) {
    return value !== undefined && value !== null;
};

function isJson(str) {
    try {
        JSON.parse(str);
    } catch (e) {
        return false;
    }
    return true;
}

const isPrime = num => {
    for (let i = 2, s = Math.sqrt(num); i <= s; i++) {
        if (num % i === 0)
            return false;
    }
    return num > 1;
};

function isDate(myDate) {
    return myDate.constructor === Date;
}

function isArray(myArray) {
    return myArray.constructor === Array;
}

var isFloat = function (n) {
    return n === +n && n !== (n | 0);
};

// checks is a string is an integer (including negative)
var isInt = function (value) {
    return /^-?[0-9]+$/.test(value.toString());
};

// checks is a string numeric or not
function isNumeric(str) {
    return /^\s*[+-]?((\d+(\.\d*)?)|(\.\d+))([eE][+-]?\d+)?\s*$|^\s*0[xX][0-9a-fA-F]+\s*$/.test(str.toString());
}

var isAlphabetic = function (e) {
    return /^[a-zA-Z]+$/.test(e);
};

/////////////////////////////////////////////////////////////////////////////

var parseBit = function (n) {
    if (n === 1 || n === "1" || n === true) {
        return 1;
    }
    return 0;
};

var parseBool = function (n) {
    if (n === 1 || n === "1" || n === true) {
        return true;
    }
    return false;
};

var parseNumber = function (str) {
    if (str.startsWith('0x') || str.startsWith('0X')) {
        return parseInt(str, 16);
    } else if (str.includes('.')) {
        return parseFloat(str);
    } else {
        return parseInt(str, 10);
    }
};
/////////////////////////////////////////////////////////////////////////////

function extractFileExt(filename) {
    if (typeof filename === "undefined") {
        return "";
    }

    if (filename.toString().indexOf(".") === -1) {
        return "";
    }
    return filename.split('.').pop().toLowerCase();
}

function extractFileName(path) {
    return path.split('\\').pop().split('/').pop();
}

function extractFilePath(path) {
    path = path.replace(/\\/g, '/');
    const lastSlashIndex = path.lastIndexOf('/');
    return path.substring(0, lastSlashIndex);
}

/////////////////////////////////////////////////////////////////////////////

var urlEncode = function (s) {
    return encodeURIComponent(s);
};

var urlDecode = function (s) {
    return decodeURIComponent(s);
};

function escapeRegExp(string) {
    return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

Boolean.random = function () {
    return Math.random() >= 0.5;
};

var inspect = function (obj, _it) {
    _it = _it || 0;
    _it++;
    var d = {};
    if (_it >= 32) {
        return "<...>";
    }
    if (obj === null) {
        return null;
    }
    if (Array.isArray(obj)) {
        return JSON.pretty(obj);
    }
    var k = Object.keys(obj);
    var v = Object.values(obj);
    for (var i = 0; i < k.length; i++) {
        var type = typeof v[i];
        if (type === "object") {
            d[k[i]] = inspect(v[i], _it);
            continue;
        }
        switch (type) {
            case "function":
                d[k[i]] = "<func>";
                break;
            case "string":
            case "number":
            case "boolean":
                d[k[i]] = v[i];
                break;
            default:
                d[k[i]] = type;
        }
    }
    return d;
};
