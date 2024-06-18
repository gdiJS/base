const Bio = {
    bmi: function (weight, height) {
        return (weight / ((height * height) / 10000)).toFixed(2);
    }
};