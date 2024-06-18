const Temp = {
    toCelcius: function (fahrenheit) {
        return (5 / 9) * (fahrenheit - 32);
    },
    toFahrenheit: function (celcius) {
        return (celcius * 1.8) + 32;
    }
};