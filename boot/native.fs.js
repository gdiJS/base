
/* global fs, vm */

fs.browse = function (p) {
    return JSON.parse(fs._browse(p));
};

fs.write = function (fn, data) {
    if (typeof data === "object") {
        data = JSON.stringify(data);
    } else {
        data = data.toString();
    }
    fs._write(fn, data);
};

var include_dir = function (l) {
    fs.browse(l).forEach(function (e) {
        include(e);
        vm.log(e);
    });
};

JSON.load = function (data, cb) {
    var c = fs.read(data);
    let json = ((new Function("return " + c))());
    cb(json);
};

JSON.pretty = function (d) {
    return JSON.stringify(d, null, 2);
};