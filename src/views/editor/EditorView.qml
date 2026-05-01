import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.mauikit.controls as Maui
import org.mauikit.filebrowsing as FB
import org.mauikit.texteditor as TE

Pane
{
    id: control

    readonly property alias count: _tabView.count

    readonly property alias currentTab : _tabView.currentItem
    readonly property bool currentFileExistsLocally : currentEditor ? FB.FM.fileExists(control.currentEditor.fileUrl) : false
    readonly property TE.TextEditor currentEditor: currentTab ? currentTab.currentItem.editor : null

    readonly property alias listView: _tabView
    readonly property alias model : _tabView.contentModel
    readonly property alias tabView : _tabView
    property bool restoringSession: false

    padding: 0
    background: null

    contentItem: ColumnLayout
    {
        spacing: 0

        Maui.TabView
        {
            id: _tabView

            Layout.fillWidth: true
            Layout.fillHeight: true

            Maui.Controls.showCSD: true

            altTabBar: !root.isWide
            tabBarMargins: Maui.Style.contentMargins

            background: null

            holder.emoji: "qrc:/img/document-edit.svg"

            holder.title: i18n("Create a New Document")
            holder.body: i18n("You can create or open a new document.")
            holder.actions: [newFileAction, openFileAction, openRecentFileAction]

            onCurrentIndexChanged: persistSession()

            Connections
            {
                target: _tabView.holder
                function onContentDropped(drop)
                {
                    if(drop.urls)
                    {
                        for(var url of drop.urls)
                            control.openTab(url)
                    }
                }
            }

            tabBar.visible: true
            tabBar.showNewTabButton: false
            tabBar.leftContent: Loader
            {
                active: settings.enableSidebar
                visible: active
                asynchronous: true

                sourceComponent: ToolButton
                {
                    icon.name: _sideBarView.sideBar.visible ? "sidebar-collapse" : "sidebar-expand"
                    onClicked: _sideBarView.sideBar.toggle()

                    display: isWide ? ToolButton.TextBesideIcon : ToolButton.IconOnly

                    checked: _sideBarView.sideBar.visible

                    ToolTip.delay: 1000
                    ToolTip.timeout: 5000
                    ToolTip.visible: hovered
                    ToolTip.text: i18n("Toggle side bar")
                }
            }

            tabBar.rightContent: [

                ToolButton
                {
                    text: _tabView.count
                    visible: _tabView.count > 1
                    font.bold: true
                    font.pointSize: Maui.Style.fontSizes.small
                    onClicked: _tabView.openOverview()
                    background: Rectangle
                    {
                        color: Maui.Theme.alternateBackgroundColor
                        radius: Maui.Style.radiusV
                    }
                },

                Loader
                {
                    asynchronous: true
                    sourceComponent: Maui.ToolButtonMenu
                    {
                        icon.name: "list-add"

                        MenuItem { action: newFileAction }
                        MenuItem { action: openFileAction }
                        MenuItem { action: openRecentFileAction }

                        MenuSeparator {}

                        MenuItem
                        {
                            enabled: settings.supportSplit && !!root.currentTab
                            text: i18n("Split View")
                            icon.name: root.currentTab && root.currentTab.orientation === Qt.Horizontal ? "view-split-left-right" : "view-split-top-bottom"
                            checkable: true
                            checked: root.currentTab && root.currentTab.count === 2
                            onTriggered: toggleSplitView()
                        }

                        MenuSeparator {}

                        MenuItem
                        {
                            text: i18n("Shortcuts")
                            icon.name: "configure-shortcuts"
                            onTriggered: openShortcutsDialog()
                        }

                        MenuItem
                        {
                            text: i18n("Settings")
                            icon.name: "settings-configure"
                            onTriggered: openSettingsDialog()
                        }

                        MenuItem
                        {
                            text: i18n("About")
                            icon.name: "documentinfo"
                            onTriggered: Maui.App.aboutDialog()
                        }
                    }
                }
            ]

            tabViewButton: Maui.TabViewButton
            {
                id:  _tabButton
                tabView: _tabView
                onClicked:
                {
                    if(_tabButton.mindex === _tabView.currentIndex)
                    {
                        _docMenuLoader.item.show((width*0.5)-(_docMenuLoader.item.width*0.5), height + Maui.Style.space.medium)
                        return
                    }

                    _tabView.setCurrentIndex(_tabButton.mindex)
                    _tabView.currentItem.forceActiveFocus()
                }

                rightContent: Maui.Icon
                {
                    visible: _tabButton.checked
                    source: "overflow-menu"
                    height: Maui.Style.iconSizes.small
                    width: height
                }

                onCloseClicked:
                {
                    _tabView.closeTabClicked(_tabButton.mindex)
                }

                Component
                {
                    id: _infoDialogComponent

                    Maui.PopupPage
                    {
                        id: _infoDialog
                        property var info: FB.FM.getFileInfo(currentEditor.fileUrl)

                        onClosed: destroy()
                        Maui.SectionItem
                        {
                            label1.text: i18n("Name")
                            label2.text: _infoDialog.info.name
                        }

                        Maui.SectionItem
                        {
                            label1.text: i18n("Date")
                            label2.text: _infoDialog.info.date
                        }

                        Maui.SectionItem
                        {
                            label1.text: i18n("Modified")
                            label2.text: _infoDialog.info.modified
                        }

                        Maui.SectionItem
                        {
                            label1.text: i18n("Size")
                            label2.text: Maui.Handy.formatSize(_infoDialog.info.size)
                        }

                        Maui.SectionItem
                        {
                            label1.text: i18n("Type")
                            label2.text:_infoDialog.info.mime
                        }
                    }
                }

                Component
                {
                    id: _goToLineDialogComponent

                    Maui.InputDialog
                    {
                        title: i18n("Go to Line")
                        textEntry.text: currentEditor.document.currentLineIndex+1
                        textEntry.placeholderText: i18n("Line number")
                        onFinished: currentEditor.goToLine(text)
                        onClosed: destroy()
                    }
                }

                Component
                {
                    id: _removeDialogComponent

                    Maui.InfoDialog
                    {

                        // title: i18n("Delete File?")
                        message: i18n("Are sure you want to delete \n%1", currentEditor.fileUrl)

                        standardButtons: Dialog.Yes | Dialog.Cancel

                        template.iconSource: "dialog-question"
                        template.iconVisible: true

                        onRejected: close()
                        onAccepted:
                        {
                            FB.FM.removeFiles([currentEditor.fileUrl])
                        }

                        onClosed: destroy()
                    }
                }

                Loader
                {
                    id: _docMenuLoader
                    asynchronous: true
                    sourceComponent: Maui.ContextualMenu
                    {
                        Maui.MenuItemActionRow
                        {
                            Action
                            {
                                icon.name: "edit-undo"
                                text: i18n("Undo")
                                enabled: currentEditor.body.canUndo
                                onTriggered: currentEditor.body.undo()
                            }

                            Action
                            {
                                icon.name: "edit-redo"
                                text: i18n("Redo")
                                enabled: currentEditor.body.canRedo
                                onTriggered: currentEditor.body.redo()
                            }


                            Action
                            {
                                text: i18n("Save")
                                icon.name: "document-save"
                                enabled: currentEditor ? currentEditor.document.modified : false
                                onTriggered: saveFile(currentEditor.fileUrl, currentEditor)
                            }

                            Action
                            {
                                icon.name: "document-save-as"
                                text: i18n("Save as")
                                onTriggered: saveFile("", currentEditor)
                            }
                        }

                        MenuSeparator {}

                        MenuItem
                        {
                            icon.name: "edit-find"
                            text: i18n("Find and Replace")
                            checkable: true
                            action: Action
                            {
                                shortcut: "Ctrl+R"
                            }
                            onTriggered:
                            {
                                currentEditor.showFindBar = !currentEditor.showFindBar
                            }
                            checked: currentEditor.showFindBar
                        }

                        MenuItem
                        {

                            action: Action
                            {
                                icon.name: "document-edit"
                                text: i18n("Line/Word Counter")
                                checkable: true
                                shortcut: "Ctrl+J"
                                checked: settings.showWordCount

                                onTriggered:
                                {
                                    settings.showWordCount = !settings.showWordCount
                                }
                            }

                        }

                        MenuSeparator {}

                        Maui.MenuItemActionRow
                        {
                            Action
                            {
                                property bool isFav: FB.Tagging.isFav(currentEditor.fileUrl)
                                text: i18n(isFav ? "UnFav it": "Fav it")
                                checked: isFav
                                checkable: true
                                icon.name: "love"
                                enabled: currentFileExistsLocally
                                onTriggered:
                                {
                                    FB.Tagging.toggleFav(currentEditor.fileUrl)
                                    isFav = FB.Tagging.isFav(currentEditor.fileUrl)
                                }
                            }

                            Action
                            {
                                enabled: currentFileExistsLocally
                                text: i18n("Info")
                                icon.name: "documentinfo"
                                onTriggered:
                                {

                                    var dialog = _infoDialogComponent.createObject(control)
                                    dialog.open()

                                }
                            }

                            Action
                            {
                                text: i18n("Share")
                                enabled: currentFileExistsLocally
                                icon.name: "document-share"
                                onTriggered: Maui.Platform.shareFiles([currentEditor.fileUrl])

                            }
                        }

                        MenuSeparator {}

                        MenuItem
                        {
                            action: Action
                            {
                                icon.name: "go-jump"
                                text: i18n("Go to Line")
                                shortcut: "Ctrl+L"
                                onTriggered:
                                {
                                    var dialog = _goToLineDialogComponent.createObject(root)
                                    dialog.open()
                                }
                            }
                        }

                        MenuItem
                        {
                            enabled: currentFileExistsLocally
                            text: i18n("Show in Folder")
                            icon.name: "folder-open"
                            onTriggered:
                            {
                                FB.FM.openLocation([currentEditor.fileUrl])
                            }
                        }

                        MenuItem
                        {
                            text: i18n("Delete File")
                            icon.name: "edit-delete"
                            enabled: currentFileExistsLocally
                            Maui.Controls.status: Maui.Controls.Negative

                            onTriggered:
                            {
                                var dialog = _removeDialogComponent.createObject(root)
                                dialog.open()
                            }
                        }
                    }
                }
            }

            onNewTabClicked: control.openTab("")
            onCloseTabClicked: (index) =>
                               {
                                   if( tabHasUnsavedFiles(index))
                                   {
                                       _closeDialog.callback = function () { closeTab(index) }

                                       if(tabHasUnsavedFiles(index))
                                       {
                                           _closeDialog.open()
                                           return
                                       }
                                   }
                                   else
                                   {
                                       closeTab(index)
                                   }
                               }
        }
    }

    Component
    {
        id: _editorLayoutComponent
        EditorLayout {}
    }

    readonly property Action openFileAction: Action
    {
        icon.name: "folder-open"
        text: i18n("Open Files")
        onTriggered: openFileDialog()
    }

    readonly property Action openRecentFileAction: Action
    {
        icon.name: "folder-recent"
        text: i18n("Recent Files")
        onTriggered: openRecentFilesDialog()
    }

    readonly property Action newFileAction: Action
    {
        icon.name: "list-add"
        text: i18n("New")
        onTriggered: editorView.openTab("")
    }

    function unsavedTabSplits(index) //which split indexes are unsaved
    {
        var indexes = []
        const tab =  control.model.get(index)
        for(var i = 0; i < tab.count; i++)
        {
            if(tab.model.get(i).editor.document.modified)
            {
                indexes.push(i)
            }
        }
        return indexes
    }

    function tabHasUnsavedFiles(index) //if a tab has at least one unsaved file in a split
    {
        return unsavedTabSplits(index).length
    }

    function fileIndex(path) //find the [tab, split] index for a path
    {
        if(path.length === 0)
        {
            return [-1, -1]
        }

        for(var i = 0; i < control.count; i++)
        {
            const tab =  control.model.get(i)
            for(var j = 0; j < tab.count; j++)
            {
                const doc = tab.model.get(j)
                if(doc.fileUrl.toString() === path)
                {
                    return [i, j]
                }
            }
        }
        return [-1,-1]
    }

    function openTab(path, options)
    {
        options = options || {}

        const index = fileIndex(path)

        if(index[0] >= 0)
        {
            _tabView.currentIndex = index[0]
            currentTab.currentIndex = index[1]
            persistSession()
            return
        }

        const tabProps = options.tabProps || {"path": path}
        _tabView.addTab(_editorLayoutComponent, tabProps)

        if(path && !options.skipHistory)
            historyList.append(path)

        if(_stackView.depth === 2 && !options.keepRecentView)
        {
            _stackView.pop()
        }

        if(!options.skipPersist)
            persistSession()
    }

    function closeTab(index) //no questions asked
    {
        _tabView.closeTab(index)
        persistSession()
    }

    function saveFile(path, item)
    {
        if(!item)
            return

        if (path && FB.FM.fileExists(path))
        {
            item.document.saveAs(path)
        } else
        {
            var props = ({'mode' : FB.FileDialog.Save,
                             'singleSelection' : true,
                             'suggestedFileName' : FB.FM.getFileInfo(item.fileUrl).label,
                             'callback' : function (paths)
                             {
                                 item.document.saveAs(paths[0])
                                 historyList.append(paths[0])
                                 persistSession()
                             }})

            var dialog = _fileDialogComponent.createObject(root, props)
            dialog.open()
        }
    }

    function isUrlOpen(url : string) : bool
    {
        return fileIndex(url)[0] >= 0;
    }

    function openGoToLineDialog()
    {
        if(!currentEditor)
            return

        const dialog = _goToLineDialogComponent.createObject(root)
        dialog.open()
    }

    function toggleSplitView()
    {
        if(!currentTab || !settings.supportSplit)
            return

        if(currentTab.count === 2)
        {
            currentTab.pop()
            return
        }

        currentTab.split("")
    }

    function sessionState()
    {
        const state = {
            currentTabIndex: Math.max(0, _tabView.currentIndex),
            tabs: []
        }

        for(var i = 0; i < control.count; i++)
        {
            const tab = control.model.get(i)
            const tabState = tab.sessionState()

            if(tabState)
                state.tabs.push(tabState)
        }

        if(state.tabs.length === 0)
            return null

        state.currentTabIndex = Math.min(state.currentTabIndex, state.tabs.length - 1)
        return state
    }

    function persistSession()
    {
        if(restoringSession)
            return

        const state = sessionState()
        settings.sessionState = state ? JSON.stringify(state) : ""
    }

    function restoreSession()
    {
        if(!settings.sessionState || settings.sessionState.length === 0)
            return false

        let state = null

        try
        {
            state = JSON.parse(settings.sessionState)
        } catch (error)
        {
            console.warn("Failed to parse session state", error)
            settings.sessionState = ""
            return false
        }

        if(!state || !state.tabs || state.tabs.length === 0)
            return false

        restoringSession = true

        for(const tabState of state.tabs)
        {
            if(!tabState.paths || tabState.paths.length === 0)
                continue

            openTab(tabState.paths[0], {
                skipHistory: true,
                skipPersist: true,
                keepRecentView: true,
                tabProps: {
                    paths: tabState.paths,
                    restoredCurrentIndex: tabState.currentIndex || 0
                }
            })
        }

        restoringSession = false

        if(control.count === 0)
            return false

        _tabView.currentIndex = Math.min(state.currentTabIndex || 0, control.count - 1)
        persistSession()
        return true
    }
}
