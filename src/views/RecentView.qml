import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.mauikit.controls as Maui
import org.mauikit.filebrowsing as FB

import "widgets"

DocsBrowser
{
    id: control

    altHeader: Maui.Handy.isMobile
    headerMargins: Maui.Style.defaultPadding
    headBar.forceCenterMiddleContent: false
    floatingFooter: true
    holder.visible: historyList.count === 0
    holder.emoji: "dialog-information"
    holder.title : i18n("No Recent Files")
    holder.body: i18n("Here you will see your recently opened files")

    StackView.onStatusChanged:
    {
        if(StackView.status === StackView.Active)
            Qt.callLater(() => control.currentView.forceActiveFocus())
    }

    headBar.farLeftContent: RowLayout
    {
        spacing: 0

        ToolButton
        {
            icon.name: "go-previous"
            onClicked: control.StackView.view.pop()
        }

        ToolSeparator
        {
            topPadding: 10
            bottomPadding: 10
        }
    }

    model: Maui.BaseModel
    {
        id: _historyModel

        list: historyList

        sort: "modified"
        sortOrder: Qt.DescendingOrder
        recursiveFilteringEnabled: true
        sortCaseSensitivity: Qt.CaseInsensitive
        filterCaseSensitivity: Qt.CaseInsensitive
    }

    property string typingQuery

    Maui.Chip
    {
        z: control.z + 99999
        Maui.Theme.colorSet:Maui.Theme.Complementary
        visible: _typingTimer.running
        label.text: typingQuery
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        showCloseButton: false
        anchors.margins: Maui.Style.space.medium
    }

    Loader
    {
        asynchronous: true
        visible: historyList.count > 0
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: Maui.Style.space.big
        sourceComponent: Button
        {
            padding: Maui.Style.defaultPadding * 2
            text: i18n("Clear All")
            onClicked: historyList.clear()
        }
    }

    Timer
    {
        id: _typingTimer
        interval: 250
        onTriggered:
        {
            const index = historyList.indexOfName(typingQuery)
            if(index > -1)
            {
                control.currentIndex = _historyModel.mappedFromSource(index)
            }

            typingQuery = ""
        }
    }

    Connections
    {
        target: control

        function onKeyPress(event)
        {
            const index = control.currentIndex
            const item = control.model.get(index)

            var pat = /^([a-zA-Z0-9 _-]+)$/
            if(event.count === 1 && pat.test(event.text))
            {
                typingQuery += event.text
                _typingTimer.restart()
            }
        }
    }

}
