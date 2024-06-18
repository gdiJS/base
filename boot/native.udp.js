
/* global $udp, _udp */

udp.send = function (uri, data) {
    return this._send(uri.toString().explode(":", 0), uri.toString().explode(":", 1), data);
};

udp.listen = function (port, cb) {
    var handle = this._listen(port, function (d) {
        cb(d.data, {
            remoteAddr: d.ip,
            stop: function () {
                return udp.stop(handle);
            }
        });
    });
    return handle;
};
