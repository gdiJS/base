const Location = {
    milesToKMH: function (miles) {
        return Math.round(miles * 1.609344);
    },
    knotsToKMH: function (knots) {
        return Math.round(knots * 1.852);
    },
    time: function (distance, speed) {  // kilometer, km/h
        return Math.round((distance / speed) * 60); // minutes
    },
    speed: function (distance, minutes) { // kilometer, minutes
        return Math.round(distance / (minutes / 60));
    },
    distance: function (lat1, lon1, lat2, lon2) {
        var R = 6378137; // Radius of the earth in meters
        var dLat = this._toRad(lat2 - lat1);
        var dLon = this._toRad(lon2 - lon1);
        var a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                Math.cos(this._toRad(lat1)) * Math.cos(this._toRad(lat2)) *
                Math.sin(dLon / 2) * Math.sin(dLon / 2);
        var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        var d = R * c;
        return d;
    },
    bearing: function (lat1, lng1, lat2, lng2) {
        var dLon = (lng2 - lng1);
        var y = Math.sin(dLon) * Math.cos(lat2);
        var x = Math.cos(lat1) * Math.sin(lat2) - Math.sin(lat1) * Math.cos(lat2) * Math.cos(dLon);
        var brng = this._toDeg(Math.atan2(y, x));
        return 360 - ((brng + 360) % 360);
    },
    _toRad: function (deg) {
        return deg * Math.PI / 180;
    },
    _toDeg: function (rad) {
        return rad * 180 / Math.PI;
    }
};