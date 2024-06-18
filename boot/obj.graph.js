var GraphWatcher = function () {
    var T = this;
    var callbacks = [];
    var events = {};

    T.add = function (key, obj, cb) {
        obj.active = false;
        obj.state = 2;
        obj._state = 2;
        obj.timestamp = 0;
        obj.value = 0;
        
        if (typeof cb === "function") {
            obj.callback = cb;
        }
        
        if (typeof obj.ttl === "undefined") {
            obj.ttl = 3600;
        }
        
        events[key] = obj;
    };
    
    var callback = function (e, p) {
        callbacks.forEach(function (o) {
            if (e === o.E) {
                o.C(p);
            }
        });
    };

    var _update = function (event, val) {
        var now = Date.unix();
        if (now - events[event].timestamp >= events[event].ttl) {
            events[event].state = 2;
            events[event]._state = 2;
            events[event].active = false;
            console.log("-- event reset: " + event);
        }

        events[event].value = val;
        events[event].timestamp = now;

        if (events[event].value <= events[event].low) {
            events[event].state = -1;
            events[event].active = false;
        }
        if (events[event].value >= events[event].high) {
            events[event].state = 1;
            events[event].active = false;
        }
        if (events[event].value >= events[event].low && events[event].value <= events[event].high) {
            events[event].state = 0;
            events[event].active = true;
        }

        if (events[event].state !== events[event]._state) {
            if (events[event].active === true) {
                console.log("event triggered: " + event);
                callback(event, {"name": event, "state": events[event].state, "value": events[event].value});
                if (typeof events[event].callback === "function") {
                    events[event].callback({"name": event, "value": events[event].value});
                }
            }
            events[event]._state = events[event].state;
        }
    };

    T.update = function (event, val) {
        if (Array.isArray(event)) {
            event.forEach(function (e) {
                _update(e, val);
            });
            return;
        }
        _update(event, val);
    };

    return T;
};
