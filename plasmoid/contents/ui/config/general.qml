import QtQuick 2.1
import QtQuick.Controls 2.5
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import QtQuick.Layouts 1.1

Item {
    Layout.fillWidth: true

    property string cfg_exchange

    property alias cfg_base: base_field.text
    property alias cfg_target: target_field.text
    property alias cfg_interval: interval_field.value

    GridLayout {
        Layout.fillWidth: true
        columns: 2

        PlasmaComponents.Label {
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

            text: "Base Currency"
        }

        PlasmaComponents.TextField {
            id: base_field

            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

            placeholderText: "USD"

            text: base_currency
        }

        PlasmaComponents.Label {
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

            text: "Target Currency"
        }

        PlasmaComponents.TextField {
            id: target_field

            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

            placeholderText: "ETH"

            text: target_currency
        }

        PlasmaComponents.Label {
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

            text: "Exchange"
        }

        PlasmaComponents.ComboBox {
            id: current_exchange;

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

            function getCurrentExchangeId() {
                return current_exchange.find(cfg_exchange);
            }

            model: ['Bittrex', 'Binance']

            onActivated: function(index) {
                cfg_exchange = current_exchange.currentText;
            }

            currentIndex: getCurrentExchangeId()
        }

        PlasmaComponents.Label {
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

            text: "Interval"
        }

        PlasmaComponents.SpinBox {
            id: interval_field

            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

            from: 1
            to: 86400
            stepSize: 1
            textFromValue: function(value) {
                return `${value} s`;
            }
        }
    }
}
