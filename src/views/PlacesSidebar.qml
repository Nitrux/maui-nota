import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.mauikit.controls as Maui
import org.mauikit.filebrowsing as FB

Loader
{
    id: control

    property alias page : control.item

    onLoaded:
    {
        if(currentEditor)
            syncSidebar(currentEditor.fileUrl)
    }

    asynchronous: true
    active: control.visible || item

    sourceComponent: Maui.Page
    {
        property alias browser : browserView
        property int contextMenuIndex: -1

        function isNamedPlace(place)
        {
            return !!place && String(place.label).length > 0
        }

        function openFileFromSidebar(path)
        {
            const filePath = String(path)

            if(root.debugSidebarFlow)
            {
                console.log("[nota-debug] sidebar open file request",
                            "file=", filePath,
                            "browserDir=", String(browserView.currentPath))
            }

            Qt.callLater(() =>
            {
                if(root.debugSidebarFlow)
                {
                    console.log("[nota-debug] sidebar open file dispatch", filePath)
                }

                editorView.openTab(filePath)

                if(_sideBarView.sideBar.collapsed)
                    _sideBarView.sideBar.close()
            })
        }

        function currentContextItem()
        {
            if(contextMenuIndex < 0 || !browserView.currentFMModel || contextMenuIndex >= browserView.currentFMModel.count)
                return null

            return browserView.currentFMModel.get(contextMenuIndex)
        }

        function contextItemPath()
        {
            const item = currentContextItem()
            return item ? String(item.path) : ""
        }

        function contextItemIsDir()
        {
            const item = currentContextItem()
            return item ? item.isdir == "true" : false
        }

        function openContextItem()
        {
            const item = currentContextItem()
            if(!item)
                return

            if(item.isdir == "true")
            {
                browserView.openFolder(item.path)
            } else
            {
                openFileFromSidebar(item.path)
            }
        }

        clip: true
        Maui.Theme.colorSet: Maui.Theme.Window
        background: Rectangle
        {
            color: Maui.Theme.backgroundColor
            radius: Maui.Style.radiusV
        }

        footerMargins: Maui.Style.defaultPadding
        footBar.middleContent: ComboBox
        {
            Layout.fillWidth: true
            model: Maui.BaseModel
            {
                list: FB.PlacesList
                {
                    groups: [FB.FMList.PLACES_PATH]
                }
            }

            textRole: "label"
            delegate: ItemDelegate
            {
                required property string label
                required property string path

                width: parent ? parent.width : implicitWidth
                visible: label.length > 0
                height: visible ? implicitHeight : 0
                text: label
            }
            onActivated:
            {
                const place = model.get(index)
                if(!isNamedPlace(place))
                    return

                if(root.debugSidebarFlow)
                {
                    console.log("[nota-debug] sidebar place activated", String(place.path), String(place.label))
                }

                currentIndex = index
                browserView.openFolder(place.path)
            }
        }
        headerMargins: Maui.Style.defaultPadding
        headBar.leftContent: Maui.ToolActions
        {
            expanded: true
            autoExclusive: false
            checkable: false
            display: ToolButton.IconOnly

            Action
            {
                text: i18n("Previous")
                icon.name: "go-previous"
                onTriggered : browserView.goBack()
            }

            Action
            {
                text: i18n("Up")
                icon.name: "go-up"
                onTriggered : browserView.goUp()
            }


            Action
            {
                text: i18n("Next")
                icon.name: "go-next"
                onTriggered: browserView.goForward()
            }
        }

        headBar.rightContent: [

            ToolButton
            {
                icon.name: "edit-find"
                checked: browserView.headBar.visible
                onClicked:
                {
                    browserView.headBar.visible = !browserView.headBar.visible
                }
            },

            Maui.ToolButtonMenu
            {
                icon.name: "view-sort"

                MenuItem
                {
                    text: i18n("Show Folders First")
                    checked: browserView.settings.foldersFirst
                    checkable: true
                    onTriggered: browserView.settings.foldersFirst = !browserView.settings.foldersFirst
                }

                MenuSeparator {}

                MenuItem
                {
                    text: i18n("Type")
                    checked: browserView.settings.sortBy === FB.FMList.MIME
                    checkable: true
                    onTriggered: browserView.settings.sortBy = FB.FMList.MIME
                    autoExclusive: true
                }

                MenuItem
                {
                    text: i18n("Date")
                    checked:browserView.settings.sortBy === FB.FMList.DATE
                    checkable: true
                    onTriggered: browserView.settings.sortBy = FB.FMList.DATE
                    autoExclusive: true
                }

                MenuItem
                {
                    text: i18n("Modified")
                    checkable: true
                    checked: browserView.settings.sortBy === FB.FMList.MODIFIED
                    onTriggered: browserView.settings.sortBy = FB.FMList.MODIFIED
                    autoExclusive: true
                }

                MenuItem
                {
                    text: i18n("Size")
                    checkable: true
                    checked: browserView.settings.sortBy === FB.FMList.SIZE
                    onTriggered: browserView.settings.sortBy = FB.FMList.SIZE
                    autoExclusive: true
                }

                MenuItem
                {
                    text: i18n("Name")
                    checkable: true
                    checked: browserView.settings.sortBy === FB.FMList.LABEL
                    onTriggered: browserView.settings.sortBy = FB.FMList.LABEL
                    autoExclusive: true
                }

                MenuSeparator{}

                MenuItem
                {
                    id: groupAction
                    text: i18n("Group")
                    checkable: true
                    checked: browserView.settings.group
                    onTriggered:
                    {
                        browserView.settings.group = !browserView.settings.group
                    }
                }
            }
        ]

        FB.FileBrowser
        {
            id: browserView
            anchors.fill: parent
            currentPath: FB.FM.homePath()
            settings.viewType : FB.FMList.LIST_VIEW
            settings.filterType: FB.FMList.TEXT
            headBar.rightLayout.visible: false
            headBar.rightLayout.width: 0
            floatingFooter: false
            listItemSize: 22
            clip: true
            background: Rectangle
            {
                color: Maui.Theme.backgroundColor
                radius: Maui.Style.radiusV
            }
            browser.background: Rectangle
            {
                color: Maui.Theme.backgroundColor
                radius: Maui.Style.radiusV
            }

            onCurrentPathChanged:
            {
                if(root.debugSidebarFlow)
                {
                    console.log("[nota-debug] sidebar current path changed", String(currentPath))
                }
            }

            onItemClicked: (index) =>
                           {
                               const item = currentFMModel.get(index)
                               if(root.debugSidebarFlow)
                               {
                                   console.log("[nota-debug] sidebar item clicked",
                                               "path=", String(item.path),
                                               "dir=", String(item.isdir),
                                               "browserDir=", String(currentPath))
                               }

                               if(Maui.Handy.singleClick)
                               {
                                   if(item.isdir == "true")
                                   {
                                       openFolder(item.path)
                                   }else
                                   {
                                       openFileFromSidebar(item.path)
                                   }
                               }
                           }

            onItemDoubleClicked: (index) =>
                                 {
                                     const item = currentFMModel.get(index)
                                     if(root.debugSidebarFlow)
                                     {
                                         console.log("[nota-debug] sidebar item double clicked",
                                                     "path=", String(item.path),
                                                     "dir=", String(item.isdir),
                                                     "browserDir=", String(currentPath))
                                     }

                                     if(!Maui.Handy.singleClick)
                                     {
                                         if(item.isdir == "true")
                                         {
                                             openFolder(item.path)
                                         }else
                                         {
                                             openFileFromSidebar(item.path)
                                         }
                                     }
                                 }

            onItemRightClicked: (index) =>
                                {
                                    const item = currentFMModel.get(index)

                                    if(root.debugSidebarFlow)
                                    {
                                        console.log("[nota-debug] sidebar item right clicked",
                                                    "path=", String(item.path),
                                                    "dir=", String(item.isdir),
                                                    "browserDir=", String(currentPath))
                                    }

                                    contextMenuIndex = index
                                    _itemContextMenu.show()
                                }
        }

        Maui.ContextualMenu
        {
            id: _itemContextMenu

            MenuItem
            {
                text: contextItemIsDir() ? i18n("Open Folder") : i18n("Open")
                icon.name: contextItemIsDir() ? "folder-open" : "document-open"
                enabled: !!currentContextItem()
                onTriggered: openContextItem()
            }

            MenuItem
            {
                text: i18n("Open in New Split")
                icon.name: "view-split-left-right"
                enabled: !!currentContextItem() && !contextItemIsDir() && currentTab.count <= 1 && settings.supportSplit
                visible: !contextItemIsDir()
                height: visible ? implicitHeight : 0
                onTriggered: currentTab.split(contextItemPath())
            }

            MenuSeparator
            {
                visible: !!currentContextItem()
                height: visible ? implicitHeight : 0
            }

            MenuItem
            {
                text: i18n("Show in Folder")
                icon.name: "folder-open"
                enabled: !!currentContextItem() && !Maui.Handy.isAndroid
                onTriggered: FB.FM.openLocation([contextItemPath()])
            }

            MenuItem
            {
                text: i18n("Copy Location")
                icon.name: "edit-copy"
                enabled: !!currentContextItem()
                onTriggered: Maui.Handy.copyToClipboard({"urls": [contextItemPath()]}, false)
            }
        }
    }
}
