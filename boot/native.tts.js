
/* global $tts, _tts */

var TTS = function () {
    var T = this;

    T.enum = function (cb) {

    };

    T.speak = function (sentence, speaker) {

    };

    T.render = function (sentence, speaker, target, cb) {
        _tts.render(sentence, speaker, target, function (file, t) {
            cb(file, t);
        });
    };

    return T;
};