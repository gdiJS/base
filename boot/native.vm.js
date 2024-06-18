/* global vm, fs */


Object.keys(vm.env).forEach(function (k) {
    if (isNumeric(vm.env[k])) {
        vm.env[k] = parseNumber(vm.env[k]);
    }
    if (vm.env[k].toString().indexOf(";") > -1) {
        vm.env[k] = vm.env[k].split(";").map(function (e) {
            if (e.toString().length > 0) {
                return e;
            }
        });
    }
});

/*
 vm._events = [];
 vm._sync = [];
 vm.uptime = 0;
 
 
 vm.sync = function (cb) {
 vm._sync.push({"c": cb, p: false});
 };
 
 vm.onTick = function (cb) {
 vm._events.push(cb);
 };
 
 vm._tick = function (tick) {
 for (var i = 0; i < vm._sync.length; i++) {
 if (vm._sync[i].p === false) {
 vm._sync[i].p = true;
 vm._sync[i].c();
 vm._sync.splice(i, 1);
 }
 }
 vm._events.forEach(function (e) {
 e(tick);
 });
 vm.uptime = tick;
 };
 * 
 */