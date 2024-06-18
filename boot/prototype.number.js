
/* global parseInt */
Number.prototype.add = function (v) {
    return this + v;
};

Number.prototype.substract = function (v) {
    return  this - v;
};

Number.prototype.multiply = function (v) {
    return this * v;
};

Number.prototype.divide = function (v) {
    return this / v;
};

Number.prototype.round = function (precision) {
    if (typeof precision === "undefined") {
        return Math.round(this);
    }
    var multiplier = Math.pow(10, precision || 0);
    return Math.round(this * multiplier) / multiplier;
};

Number.prototype.toTime = function () {
    var seconds = this;
    var levels = [
        [Math.floor(seconds / 31536000), 'Year'],
        [Math.floor((seconds % 31536000) / 2592000), 'Month'],
        [Math.floor((seconds % 31536000 % 2592000) / 86400), 'Day'],
        [Math.floor(((seconds % 31536000) % 2592000 % 86400) / 3600), 'Hour'],
        [Math.floor((((seconds % 31536000) % 2592000 % 86400) % 3600) / 60), 'Minutes']
    ];
    var returntext = '';
    for (var i = 0, max = levels.length; i < max; i++) {
        if (levels[i][0] === 0)
            continue;
        returntext += ' ' + levels[i][0] + ' ' + levels[i][1];
    }
    return returntext.trim();
};

Number.primes = function (min, max) {
    min = min || 1;
    max = max || 255;
    var result = Array.apply(null, Array(max + 1)).map(function (_, i) {
        return i;
    });
    for (var i = 2; i <= Math.sqrt(max + 1); i++) {
        for (var j = i * i; j < max + 1; j += i) {
            delete result[j];
        }
    }
    return result.filter(function (x) {
        return x >= min && x !== null;
    });
};

Number.randPrime = function (min, max) {
    const primes = Number.primes(min, max);
    return primes[randInt(0, primes.length - 1)];
};

Number.random = function (min, max) {
    min = min || 1;
    max = max || 9999;
    return Math.floor((Math.random() * max) + min);
};

Number.randomFloat = function (min, max) {
    return Math.random() * (max - min) + min;
};

Number.prototype.pad = function (w, c) {
    return this.toString().pad(w, c);
};

Number.prototype.toBinary = function (l) {
    return parseInt(this, 10).toString(2).pad(l).reverse();
};

Number.prototype.toBool = function () {
    return Boolean(Number(this));
};

Number.prototype.toBitArray = function () {
    return this.toBinary().toBitArray();
};

Number.prototype.setPercent = function (percentage) {
    return Math.round((this / 100) * percentage);
};

Number.prototype.getPercent = function (value) {
    return ((value / this) * 100).toFixed(2);
};

Number.prototype.price = function () {
    var amount = this;
    const decimalCount = 2;
    const decimal = ".";
    const thousands = ",";
    const negativeSign = amount < 0 ? "-" : "";
    let i = parseInt(amount = Math.abs(Number(amount) || 0).toFixed(decimalCount)).toString();
    let j = (i.length > 3) ? i.length % 3 : 0;
    return (negativeSign + (j ? i.substr(0, j) + thousands : '') + i.substr(j).replace(/(\d{3})(?=\d)/g, "$1" + thousands) + (decimalCount ? decimal + Math.abs(amount - i).toFixed(decimalCount).slice(2) : ""));
};

Number.prototype.map = function (in_min, in_max, out_min, out_max) {
    return (((this - in_min) * (out_max - out_min)) / (in_max - in_min) + out_min);
};
