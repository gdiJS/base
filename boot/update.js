/* global fs, http, vm */

(function () {
    const server = "https://gdi.sh/version/";
    http.get(server + vm.arch, function (data, code) {
        if (code !== 200) {
            console.log("-- unable to access gdi.js server");
            return;
        }
        console.log(data);

        if (data.latest > vm.version) {
            console.log("-- downloading v" + data.latest);
            var local = vm.path["temp"] + extractFileName(data.src);
            http.download(data.src, local, function (e) {
                if (e && e.result === true) {
                    var installer = fs.run(local);
                    console.log(installer);
                    if (installer >= 1) {
                        vm.terminate();
                    }
                } else {
                    console.log("l-- unable to download installer, please visit https://gdi.sh to get latest version");
                }
            });
        } else {
            console.log("-- gdi.js up to date");
        }
    });
})();