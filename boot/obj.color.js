const Color = {
    random: function () {
        return '#' + (((1 << 24) * Math.random()) | 0).toString(16).padStart(6, 0);
    },
    fade: function (col, amount) {
        const min = Math.min, max = Math.max;
        const num = parseInt(col.replace(/#/g, ''), 16);
        const r = min(255, max((num >> 16) + amount, 0));
        const g = min(255, max((num & 0x0000FF) + amount, 0));
        const b = min(255, max(((num >> 8) & 0x00FF) + amount, 0));
        return '#' + (g | (b << 8) | (r << 16)).toString(16).padStart(6, 0);
    },
    hexToRgb: function (hex) {
        const match = hex.replace(/#/, '').match(/.{1,2}/g);
        return {
            r: parseInt(match[0], 16),
            g: parseInt(match[1], 16),
            b: parseInt(match[2], 16)
        };
    },
    rgbToHex: function (r, g, b) {
        return '#' + [r, g, b].map(x => {
            return x.toString(16).padStart(2, 0);
        }).join('');
    }
};

