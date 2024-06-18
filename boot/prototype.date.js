Date.prototype.millis = function () {
    return +this;
};

Date.unix = function () {
    return ~~(Date.now() / 1000);
};

Date.clock = function (d) {
    d = d || new Date();
    return d.getHours().pad(2) + ":" + d.getMinutes().pad(2);
};

Date.get = function (d, div) {
    d = d || new Date();
    div = div || "/";
    return (d.getMonth() + 1).pad(2) + div + d.getDate().pad(2) + div + d.getFullYear();
};

Date.prototype.addHour = function (h) {
    this.setTime(this.getTime() + (h * 60 * 60 * 1000));
    return this;
};