import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.mauikit.controls as Maui
import org.mauikit.filebrowsing as FB

Maui.ContextualMenu
{
    id: control

    property int index : -1
    property Maui.BaseModel model : null
    readonly property string currentItemPath:
    {
        if(!control.model || control.index < 0 || control.index >= control.model.count)
            return ""

        const item = control.model.get(control.index)
        return item && item.path ? String(item.path) : ""
    }

    MenuItem
    {
        text: i18n("Open")
        icon.name: "document-open"
        onTriggered: openFile(control.currentItemPath)
    }

    MenuSeparator{}

    MenuItem
    {
        enabled: !Maui.Handy.isAndroid
        text: i18n("Show in Folder")
        icon.name: "folder-open"
        onTriggered: FB.FM.openLocation([control.currentItemPath])
    }
}
