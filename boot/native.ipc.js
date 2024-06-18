/* global $dde, _ipc */

var IPC = function (win) {
    var T = this;
    T.hwnd = 0;
    const api = _ipc;

    T.refresh = function () {
        if (typeof win === "number") {
            T.hwnd = win;
            return;
        }
        T.hwnd = api.find(win);
    };

    T.write = function (string) {
        api.send(T.hwnd, string);
    };
    T.refresh();
    return T;
};