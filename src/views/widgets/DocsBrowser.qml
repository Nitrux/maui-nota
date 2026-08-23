import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.mauikit.controls as Maui
import org.mauikit.filebrowsing as FB

Maui.AltBrowser
{
    id: control
    signal keyPress(var event)
    background: null

    gridView.itemSize: Math.min(200, Math.max(100, Math.floor(width* 0.3)))
    gridView.itemHeight: gridView.itemSize + Maui.Style.rowHeight

    viewType: root.isWide ? Maui.AltBrowser.ViewType.Grid : Maui.AltBrowser.ViewType.List

    readonly property alias menu : _menu

    ItemMenu
    {
        id: _menu
        index: control.currentIndex
        model: control.model
    }

    Keys.enabled: true
    Keys.onPressed: (event) =>
    {
        control.keyPress(event)
        event.accepted = false
    }

    Connections
    {
        target: control

        function onKeyPress(event)
        {
            const index = control.currentIndex
            const item = control.model.get(index)

            if(event.key === Qt.Key_Return)
            {
                openFile(item.path)
            }

            if(event.key === Qt.Key_Escape)
            {
                control.StackView.view.pop()
            }
        }
    }

    headBar.middleContent: Maui.SearchField
    {
        Layout.fillWidth: true
        Layout.maximumWidth: 500
        Layout.alignment: Qt.AlignCenter
        placeholderText: i18n("Filter...")
        onAccepted: control.model.filter = text
        onCleared:  control.model.filter = text
    }

    gridDelegate: Item
    {
        height: GridView.view.cellHeight
        width: GridView.view.cellWidth

        Maui.GridBrowserDelegate
        {
            id: _gridItemDelegate

            template.imageWidth: control.gridView.itemSize
            template.imageHeight: control.gridView.itemSize

            anchors.margins: Maui.Handy.isMobile ? Maui.Style.space.small : Maui.Style.space.medium
            anchors.fill: parent

            draggable: true
            Drag.keys: ["text/uri-list"]

            Drag.mimeData: Drag.active ?
                               {
                                   "text/uri-list": model.path
                               } : {}


            isCurrentItem: parent.GridView.isCurrentItem
            label1.text: model.label
            imageSource: model.thumbnail
            iconSource: model.icon
            template.fillMode: Image.PreserveAspectFit
            iconSizeHint: height * 0.6
            onClicked: (mouse) =>
            {
                control.currentIndex = index
                if(Maui.Handy.singleClick)
                {
                    openFile(model.path)
                }
            }

            onDoubleClicked:
            {
                control.currentIndex = index
                if(!Maui.Handy.singleClick)
                {
                    openFile(model.path)
                }
            }

            onRightClicked:
            {
                control.currentIndex = index
                _menu.show()
            }

            onPressAndHold:
            {
                control.currentIndex = index
                _menu.show()
            }
        }
    }

    listDelegate: Maui.ListBrowserDelegate
    {
        id: _listDelegate

        isCurrentItem: ListView.isCurrentItem

        height: Maui.Style.rowHeight *1.5
        width: ListView.view.width
        draggable: true
        Drag.keys: ["text/uri-list"]
        Drag.mimeData: Drag.active ?
                           {
                               "text/uri-list": model.path
                           } : {}

    label1.text: model.label
    label2.text: model.path
    label3.text: Maui.Handy.formatDate(model.modified, "MM/dd/yyyy")
    label4.text: model.mime
    iconSource: model.icon
    iconSizeHint: Maui.Style.iconSizes.medium
    onClicked: (mouse) =>
    {
        control.currentIndex = index
        if(Maui.Handy.singleClick)
        {
            openFile(model.path)
        }
    }

    onDoubleClicked:
    {
        control.currentIndex = index
        if(!Maui.Handy.singleClick)
        {
           openFile(model.path)
        }
    }

    onRightClicked:
    {
        control.currentIndex = index
        _menu.show()
    }

    onPressAndHold:
    {
        control.currentIndex = index
        _menu.show()
    }
}

}
