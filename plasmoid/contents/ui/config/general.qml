import QtQuick 2.1
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.1
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.4 as Kirigami

Item {
    width: childrenRect.width
    height: childrenRect.height

    property string cfg_exchange

    property alias cfg_base: base_field.text
    property alias cfg_target: target_field.text
    property alias cfg_interval: interval_field.value
    property alias cfg_chartAnimation: chartAnimation_field.checked

    Kirigami.FormLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        TextField {
            id: base_field

            Kirigami.FormData.label: i18n("Base currency")
            placeholderText: "USD"
            text: base_currency
        }

        TextField {
            id: target_field

            Kirigami.FormData.label: i18n("Target currency")
            placeholderText: "ETH"
            text: target_currency
        }

        ComboBox {
            id: current_exchange;

            Kirigami.FormData.label: i18n("Exchange")

            function getCurrentExchangeId() {
                return current_exchange.find(cfg_exchange);
            }

            model: ['Bittrex', 'Binance']

            onActivated: function(index) {
                cfg_exchange = current_exchange.currentText;
            }

            currentIndex: getCurrentExchangeId()
        }

        SpinBox {
            id: interval_field

            Kirigami.FormData.label: i18n("Interval (secs)")

            editable: true

            from: 1
            to: 86400
            stepSize: 1
        }

        CheckBox {
            id: chartAnimation_field

            Kirigami.FormData.label: i18n("Chart animation")
            tristate: false
        }
    }
}
