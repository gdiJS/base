/* global http */

http.post = function (url, payload, callback) {
    var mime;
    url = url.toString().trim();
    if (url === "") {
        return false;
    }

    if (typeof payload !== "object") {
        return false;
    }

    if (Array.isArray(payload)) {
        mime = "application/x-www-form-urlencoded";
        payload = payload.map(function (e) {
            return e.split("=").map(function (k) {
                return encodeURIComponent(k);
            }).join("=");
        }).join("&");
    } else {
        mime = "application/json";
        payload = JSON.stringify(payload);
    }
    this._post(url, payload, callback, mime);
    return true;
};