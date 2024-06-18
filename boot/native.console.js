console.log = function (a) {
    var type = typeof a;
    switch (type) {
        case "string":
        case "number":
        case "boolean":
            console.write(a);
            break;
        case "function":
        case "null":
        case "undefined":
            console.write("<" + type + ">");
            break;
        case "object":
            if (Array.isArray(a)) {
                console.write("[" + a.join(",") + "]");
            } else {
                console.write(JSON.stringify(inspect(a), null, 2));
            }
            break;
        default:
            console.write(a);
    }
    return;
};