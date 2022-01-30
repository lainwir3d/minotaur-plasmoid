import QtQuick 2.15
import org.kde.plasma.components 3.0 as PlasmaComponents
import QtQuick.Layouts 1.1
import org.kde.plasma.core 2.0 as PlasmaCore

import QtCharts 2.15

Item {
    Layout.minimumWidth: 500
    Layout.minimumHeight: 300

    property QtObject market;
    property QtObject market_value;

    Component.onCompleted: function () {
        last_update.default_color = last_update.color

        market = engine.market
        market_value = engine.market_value
    }

    TickerEngine {
        id: engine
    }

    GridLayout {
        id: main_column

        columns: 1

        anchors {
            top: parent.top
            right: parent.right
            bottom: parent.bottom
            left: parent.left
            leftMargin: 5
            rightMargin: 5
        }

        RowLayout {
            spacing: 3

            PlasmaComponents.Label {
                id: base
                text: market.display_base + '-' + market.display_target

                font.weight: Font.Bold
            }

            PlasmaComponents.Label {
                text: "|"
            }

            PlasmaComponents.Label {
                id: exchange
                text: market.display_exchange
            }

            PlasmaComponents.Label {
                text: "|"
            }

            PlasmaComponents.Label {
                id: last_update
                text: market_value.last_update

                color: market_value.update_failed ? '#F00' : PlasmaCore.ColorScope.textColor

                property string default_color: ""
            }

            Item { Layout.fillWidth: true }

            PlasmaComponents.SpinBox {
                id: rangeSB

                from: 0
                to: items.length - 1
                value: 0 // Full

                editable: false

                onValueChanged: {
                    xAxis.determineMinMax();
                }

                property var items: [
                    { text: "Full", hours: -1, days: -1, weeks: -1, months: -1},
                    { text: "1 hour", hours: 1, days: 0, weeks: 0, months: 0},
                    { text: "12 hours", hours: 12, days: 0, weeks: 0, months: 0},
                    { text: "1 day", hours: 0, days: 1, weeks: 0, months: 0},
                    { text: "3 days", hours: 0, days: 3, weeks: 0, months: 0},
                    { text: "1 week", hours: 0, days: 0, weeks: 1, months: 0},
                    { text: "2 weeks", hours: 0, days: 0, weeks: 2, months: 0},
                    { text: "1 month", hours: 0, days: 0, weeks: 0, months: 1},
                    { text: "2 months", hours: 0, days: 0, weeks: 0, months: 2}
                ]

                validator: RegExpValidator {
                    regExp: new RegExp("^[1-9]+ (hour|day|week|month)[s]?$", "i")
                }

                textFromValue: function(value) {
                    return items[value].text;
                }

                valueFromText: function(text) {
                    for (var i = 0; i < items.length; ++i) {
                        if (items[i].text.toLowerCase().indexOf(text.toLowerCase()) === 0)
                            return i
                    }
                    return sb.value
                }

            }
        }

        ChartView {
            id: chartView

            Layout.fillHeight: true
            Layout.fillWidth: true

            opacity: 0.5

            animationOptions: ChartView.SeriesAnimations

            legend.visible: false
            antialiasing: true

            margins {
                top: 5
                right: 5
                bottom: 5
                left: 5
            }

            property date firstDate: new Date()

            Connections {
                target: plasmoid.configuration
                onExchangeChanged: configChanged()
                onTargetChanged: configChanged()
                onBaseChanged: configChanged()

                function configChanged () {
                    priceSeries.clear();
                    xAxis.determineMinMax();
                }
            }

            Connections{
                target: market_value
                onRequestOk: {
                    var now = new Date();
                    if(now.getTime() < 100000){
                        print("weird date. ignoring");
                        return; // first call returns weird date (really low, <100)
                    }

                    if(priceSeries.count == 0){
                        priceSeries.append(now.getTime(), market_value.last);
                        xAxis.determineMinMax();
                        return;
                    }

                    var lastDate = priceSeries.at(priceSeries.count - 1).x;
                    if(now > lastDate){
                        priceSeries.append(now, market_value.last);
                        xAxis.determineMinMax();
                    }else{
                        print("new point date error!");
                    }
                }
            }

            backgroundColor: PlasmaCore.Theme.viewBackgroundColor

            DateTimeAxis {
                id: xAxis

                format: "hh:mm:ss"
                tickCount: 0

                labelsColor: PlasmaCore.Theme.textColor
                labelsFont {
                    family: PlasmaCore.Theme.defaultFont.family
                    pointSize: base.font.pointSize * 0.66
                }
                labelsAngle: -45

                function determineMinMax(){
                    var newMin = new Date();
                    if(priceSeries.count > 0) newMin = new Date(priceSeries.at(0).x);

                    if(rangeSB.value > 0){
                        var r = rangeSB.items[rangeSB.value];

                        newMin = new Date();
                        newMin.setHours(newMin.getHours() + r.hours * -1);
                        newMin.setHours(newMin.getHours() + r.days * -24);
                        newMin.setHours(newMin.getHours() + r.weeks * 7 * -24);
                        newMin.setMonth(newMin.getMonth() + r.months * -1);

                        if(r.months > 0){
                            format = "MMM yyyy";
                            tickCount = Math.max(3, r.months + 1);
                        }else if(r.weeks > 0){
                            format = "dd MMM";
                            tickCount = Math.max(3, r.weeks + 1);
                        }
                        else if(r.days > 0){
                            format = "dd MMM";
                            tickCount = Math.max(3, r.days + 1);
                        }
                        else{
                            format = "hh:mm:ss";
                            tickCount = Math.max(3, r.hours + 1);
                        }
                    }else {
                        format = "hh:mm:ss";
                        tickCount = 5; // TODO
                    }

                    var newMax = new Date();
                    if(priceSeries.count > 0){
                        newMax = new Date(priceSeries.at(priceSeries.count - 1).x); // get last value in series
                    }
                    newMax.setSeconds(newMax.getSeconds() + plasmoid.configuration.interval);

                    if(newMax != max){
                        max = newMax;
                        min = newMin;
                    }
                }

            }

            ValueAxis {
                id: yAxis
                min: market_value.low
                max: market_value.high

                labelsColor: PlasmaCore.Theme.textColor

                labelsFont {
                    family: PlasmaCore.Theme.defaultFont.family
                    pointSize: base.font.pointSize * 0.66
                }
            }

            SplineSeries {
                id: priceSeries
                axisX: xAxis
                axisY: yAxis
            }

            MouseArea {
                id: plotMouseArea

                x: chartView.plotArea.x
                y: chartView.plotArea.y
                width: chartView.plotArea.width
                height: chartView.plotArea.height

                hoverEnabled: true

                Rectangle {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    x: parent.mouseX

                    width: 2

                    visible: plotMouseArea.containsMouse

                    color: PlasmaCore.Theme.highlightColor

                    PlasmaComponents.ToolTip {
                        //x: 0
                        y: parent.height + 3

                        property point mousePos: Qt.point(plotMouseArea.mouseX, plotMouseArea.mouseY)

                        onMousePosChanged: {
                            if(priceSeries.count > 0){
                                var firstValue = priceSeries.at(0);
                                var lastValue = priceSeries.at(priceSeries.count - 1);

                                var mouseValue = chartView.mapToValue(mousePos, priceSeries);

                                if(mouseValue.x < firstValue.x) mouseValue = firstValue;
                                else if(mouseValue.x > lastValue.x) mouseValue = lastValue;

                                currentPlotPoint = mouseValue;
                            }
                        }


                        property point currentPlotPoint: Qt.point(-1, -1)
                        /*
                        onCurrentPlotPointChanged: {
                            print("pointChanged")
                            print(currentPlotPoint);
                        }
                        */

                        visible: parent.visible && (priceSeries.count > 0)
                        delay: 0
                        timeout: 0

                        text: new Date(currentPlotPoint.x).toLocaleString(Qt.locale(), xAxis.format) + " -> " + currentPlotPoint.y.toFixed(
                                  Math.max(9 - currentPlotPoint.y.toFixed(0).length, 0)
                                  )
                    }

                }


            }


        }

        Row {

            spacing: 10

            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

            Column {
                height: parent.height

                PlasmaComponents.Label {
                    id: low
                    text: "" + market_value.high
                    height: value.height * 3 / 5

                    anchors.right: parent.right
                }

                PlasmaComponents.Label {
                    id: high
                    text: "" + market_value.low
                    height: value.height * 2 / 5

                    anchors.right: parent.right
                }

            }

            PlasmaComponents.Label {
                id: value

                text: market_value.last
                .toFixed(
                Math.max(9 - market_value.last.toFixed(0).length, 0)
                )
                .toLocaleString()

                font.pointSize: base.font.pointSize * 2.5
                minimumPointSize: 24

                fontSizeMode: Text.VerticalFit

                TextMetrics {
                    id: value_metrics
                    font: value.font
                    text: value.text
                }
            }

            Column {
                id: value_label

                height: parent.height
                Layout.alignment: Qt.AlignVCenter

                PlasmaComponents.Label {
                    text: market.display_base
                    height: value.height * 3 / 5

                    anchors.left: parent.left
                }

                PlasmaComponents.Label {

                    id: change
                    color: market_value.day_change > 0
                           ? "#090"
                           : market_value.day_change < 0
                             ? "#900"
                             : "#666"
                    text: Number(market_value.day_change)
                    .toFixed(2)
                    .toLocaleString() + "%"
                    height: value.height * 2 / 5

                    anchors.left: parent.left
                }
            }

        }
    }
}
