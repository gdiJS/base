
/* global __tcp, _tcp */

tcp.listen = function (port, cb) {
    this._listen(port, function (d) {
        cb(d.data, {
            remoteAddr: d.ip,
            close: function () {
                return tcp.kick(d.id, d.socket);
            },
            send: function (data) {
                var p = {};
                p.id = d.id;
                p.sock = d.socket;
                return tcp.write(JSON.stringify({
                    id: d.id,
                    sock: d.socket,
                    data: data
                }));
            }
        });
    });
};