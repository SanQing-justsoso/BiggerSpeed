// View.mc - BiggerSpeed 速度分区颜色字段（左右分栏版）
// 左半：速度整数（个位十位）大字
// 右半上：平均速度（无单位）
// 右半下：实时速度小数位 + 单位
// 整格背景随当前速度区间变色（热到冷）
import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

class BiggerSpeedView extends WatchUi.DataField {

    private var _thresholds as Array;   // 6 个阈值（当前单位速度）
    private var _colors as Array;       // 7 个颜色 0xRRGGBB
    private var _currentSpeed as Float?; // m/s
    private var _averageSpeed as Float?; // m/s
    private var _unit as String;
    private var _speedFactor as Float;

    function initialize() {
        DataField.initialize();

        // 硬编码默认档位（热到冷）
        _thresholds = [10, 20, 30, 40, 50, 60];
        _colors = [
            0xFF0000,  // 档1 0-10 红
            0xFF7F00,  // 档2 10-20 橙
            0xFFFF00,  // 档3 20-30 黄
            0x00FF00,  // 档4 30-40 绿
            0x00FFFF,  // 档5 40-50 青
            0x0000FF,  // 档6 50-60 蓝
            0x7F00FF   // 档7 60+ 紫
        ];

        var settings = System.getDeviceSettings();
        var isMetric = (settings.paceUnits == System.UNIT_METRIC);
        _unit = isMetric ? "km/h" : "mph";
        _speedFactor = isMetric ? 3.6 : 2.23694;
    }

    function compute(info as Activity.Info) as Numeric or Duration or String or Null {
        _currentSpeed = info.currentSpeed;
        _averageSpeed = info.averageSpeed;
        return null;
    }

    // 当前速度所在档位索引 0~6
    function zoneIndex(speedMps) {
        var v = speedMps * _speedFactor;
        for (var i = 0; i < _thresholds.size(); i++) {
            if (v < _thresholds[i]) {
                return i;
            }
        }
        return _thresholds.size();
    }

    // 背景亮度（0~255），用于文字色自适应
    function luminance(color) {
        var r = (color / 0x10000) % 0x100;
        var g = (color / 0x100) % 0x100;
        var b = color % 0x100;
        return (r * 299 + g * 587 + b * 114) / 1000;
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        // 背景色：当前速度所在区间
        var bg;
        if (_currentSpeed == null) {
            bg = 0x808080;  // 未定位灰
        } else {
            bg = _colors[zoneIndex(_currentSpeed)];
        }
        dc.setColor(bg, bg);
        dc.clear();

        // 文字色自适应：深背景白字，浅背景黑字
        var fg = (luminance(bg) > 128) ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;

        // 字号：整数大字，右半小字
        var intFont = Graphics.FONT_NUMBER_HOT;
        var smallFont = Graphics.FONT_SMALL;
        if (h < 55) {
            intFont = Graphics.FONT_MEDIUM;
            smallFont = Graphics.FONT_XTINY;
        }

        // 布局坐标
        var midX = w / 2;            // 中线（整数/小数分界）
        var baseline = h * 85 / 100; // 底部对齐基线
        var avgX = w * 3 / 4;        // 平均速度（右半上）
        var avgY = h * 28 / 100;

        if (_currentSpeed == null) {
            // 未定位：左半 "--"
            dc.setColor(fg, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 4, h / 2, intFont,
                "--",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            // 拆分速度 "32.5" → "32" + ".5"
            var speedText = formatSpeed(_currentSpeed);
            var dotIdx = speedText.find(".");
            var intPart;
            var decPart;
            if (dotIdx == null) {
                intPart = speedText;
                decPart = "";
            } else {
                intPart = speedText.substring(0, dotIdx);
                decPart = speedText.substring(dotIdx, speedText.length());
            }

            // 底部对齐：按 baseline（数字视觉底部）对齐
            var intAsc = Graphics.getFontAscent(intFont);
            var intDesc = Graphics.getFontDescent(intFont);
            var smallAsc = Graphics.getFontAscent(smallFont);
            var smallDesc = Graphics.getFontDescent(smallFont);
            var intY = baseline - (intAsc - intDesc) / 2;
            var decY = baseline - (smallAsc - smallDesc) / 2;

            // 整数：右对齐贴中线，大字
            dc.setColor(fg, Graphics.COLOR_TRANSPARENT);
            dc.drawText(midX - 3, intY, intFont,
                intPart,
                Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);

            // 平均速度：右半上（无单位）
            dc.setColor(fg, Graphics.COLOR_TRANSPARENT);
            dc.drawText(avgX, avgY, smallFont,
                formatSpeed(_averageSpeed),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            // 小数 + 单位：左对齐贴中线
            dc.setColor(fg, Graphics.COLOR_TRANSPARENT);
            dc.drawText(midX + 3, decY, smallFont,
                decPart + " " + _unit,
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    private function formatSpeed(speed) {
        if (speed == null) {
            return "--";
        }
        return (speed * _speedFactor).format("%.1f");
    }
}
