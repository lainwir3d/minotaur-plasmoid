import QtQuick 2.15
import org.kde.plasma.components 2.0 as PlasmaComponents
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

        Row {
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
        }

        ChartView {
            id: chartView

            Layout.fillHeight: true
            Layout.fillWidth: true

            opacity: 0.5

            animationOptions: ChartView.SeriesAnimations
            legend.visible: false
            antialiasing: true

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
                    if(priceSeries.count == 0){
                        chartView.firstDate = new Date();
                    }

                    var currentDate = new Date().getTime();
                    var lastDate = priceSeries.at(priceSeries.count - 1).x;

                    if(currentDate > lastDate){
                        priceSeries.append(currentDate, market_value.last);
                        xAxis.determineMinMax();
                    }
                }
            }

            backgroundColor: PlasmaCore.Theme.viewBackgroundColor

            DateTimeAxis {
                id: xAxis

                format: "hh:mm:ss"
                tickCount: 0

                labelsColor: PlasmaCore.Theme.textColor
                labelsFont: PlasmaCore.Theme.defaultFont

                function determineMinMax(){
                    var d = new Date();
                    var h = d.getHours();

                    var newMin = chartView.firstDate;
                    var newMax = new Date(); newMax.setSeconds(newMax.getSeconds() + plasmoid.configuration.interval);

                    if(newMax != max){
                        max = newMax;
                        min = newMin;
                    }
                }

                Component.onCompleted: {
                    determineMinMax();
                }
            }

            ValueAxis {
                id: yAxis
                min: market_value.low
                max: market_value.high

                labelsColor: PlasmaCore.Theme.textColor
                labelsFont: PlasmaCore.Theme.defaultFont
            }

            SplineSeries {
                id: priceSeries
                axisX: xAxis
                axisY: yAxis
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

                width: paintedWidth

                text: market_value.last
                .toFixed(
                Math.max(9 - market_value.last.toFixed(0).length, 0)
                )
                .toLocaleString()

                font.pointSize: 100
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

    /*
        RowLayout{
            Layout.minimumHeight: base.height * 3
            Layout.maximumHeight: base.height * 3

            spacing: 5

            Column {
                height: parent.height
                Layout.alignment: Qt.AlignVCenter

                PlasmaComponents.Label {
                    id: low
                    text: "L:" + market_value.low
                    height: value.height * 3 / 5
                }

                PlasmaComponents.Label {
                    id: high
                    text: "H:" + market_value.high
                    height: value.height * 2 / 5
                }

            }

            PlasmaComponents.Label {
                id: value

                Layout.alignment: Qt.AlignVCenter
                Layout.maximumHeight: parent.height / 2

                text: market_value.last
                .toFixed(
                Math.max(9 - market_value.last.toFixed(0).length, 0)
                )
                .toLocaleString()

                font.pointSize: 100
                //minimumPointSize: 24

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
                }
            }

        }
        */

    }
}
