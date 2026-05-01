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
    readonly property TE.CodeEditor currentEditor: currentTab ? currentTab.currentItem.editor : null

    readonly property alias listView: _tabView
    readonly property alias model : _tabView.contentModel
    readonly property alias tabView : _tabView
    property bool restoringSession: false

    padding: 0
    background: null

    contentItem: Item
    {
        Maui.TabView
        {
            id: _tabView

            anchors.fill: parent

            Maui.Controls.showCSD: true

            altTabBar: !root.isWide
            tabBarMargins: Maui.Style.contentMargins

            background: null

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
            tabBar.leftContent: [
                Loader
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
                },

                ToolButton
                {
                    action: newFileAction
                    display: ToolButton.IconOnly
                },

                ToolButton
                {
                    action: openFileAction
                    display: ToolButton.IconOnly
                },

                ToolSeparator
                {
                    visible: !!currentEditor
                    bottomPadding: 10
                    topPadding: 10
                },

                ToolButton
                {
                    action: undoAction
                    display: ToolButton.IconOnly
                    visible: !!currentEditor
                },

                ToolButton
                {
                    action: redoAction
                    display: ToolButton.IconOnly
                    visible: !!currentEditor
                },

                ToolButton
                {
                    action: saveAction
                    display: ToolButton.IconOnly
                    visible: !!currentEditor
                },

                ToolButton
                {
                    action: saveAsAction
                    display: ToolButton.IconOnly
                    visible: !!currentEditor
                },

                ToolSeparator
                {
                    visible: !!currentEditor
                    bottomPadding: 10
                    topPadding: 10
                },

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
                }
            ]

            tabBar.rightContent: [
                ToolSeparator
                {
                    bottomPadding: 10
                    topPadding: 10
                },

                Loader
                {
                    asynchronous: true
                    sourceComponent: Maui.ToolButtonMenu
                    {
                        icon.name: "overflow-menu"

                        MenuItem { action: openRecentFileAction }

                        MenuSeparator
                        {
                            visible: !!currentEditor
                            height: visible ? implicitHeight : -Maui.Style.defaultSpacing
                        }

                        MenuItem
                        {
                            action: findAction
                            visible: !!currentEditor
                            height: visible ? implicitHeight : -Maui.Style.defaultSpacing
                        }

                        MenuItem
                        {
                            action: goToLineAction
                            visible: !!currentEditor
                            height: visible ? implicitHeight : -Maui.Style.defaultSpacing
                        }

                        MenuItem
                        {
                            action: toggleSplitViewAction
                            visible: !!currentEditor
                            height: visible ? implicitHeight : -Maui.Style.defaultSpacing
                        }

                        MenuSeparator
                        {
                            visible: !!currentEditor
                            height: visible ? implicitHeight : -Maui.Style.defaultSpacing
                        }

                        MenuItem
                        {
                            action: toggleLineNumbersAction
                            visible: !!currentEditor
                            height: visible ? implicitHeight : -Maui.Style.defaultSpacing
                        }

                        MenuItem
                        {
                            action: toggleWrapTextAction
                            visible: !!currentEditor
                            height: visible ? implicitHeight : -Maui.Style.defaultSpacing
                        }

                        MenuItem
                        {
                            action: toggleDocumentStatsAction
                            visible: !!currentEditor
                            height: visible ? implicitHeight : -Maui.Style.defaultSpacing
                        }

                        MenuItem
                        {
                            action: toggleLanguageSelectorAction
                            visible: !!currentEditor
                            height: visible ? implicitHeight : -Maui.Style.defaultSpacing
                        }

                        MenuSeparator
                        {
                            visible: !!currentEditor
                            height: visible ? implicitHeight : -Maui.Style.defaultSpacing
                        }

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
                    _tabView.setCurrentIndex(_tabButton.mindex)
                    _tabView.currentItem.forceActiveFocus()
                }

                onCloseClicked:
                {
                    _tabView.closeTabClicked(_tabButton.mindex)
                }
            }

            onNewTabClicked: control.openTab("")
            onCloseTabClicked: (index) => requestCloseTab(index)
        }

        Maui.Holder
        {
            z: 1
            anchors.fill: parent
            visible: _tabView.count === 0
            emoji: "document-new"
            title: i18n("Start Writing")
            body: i18n("Create or open a text file.")
        }
    }

    Component
    {
        id: _editorLayoutComponent
        EditorLayout {}
    }

    Component
    {
        id: _goToLineDialogComponent

        Maui.InputDialog
        {
            title: i18n("Go to Line")
            textEntry.text: currentEditor ? currentEditor.document.currentLineIndex + 1 : ""
            textEntry.placeholderText: i18n("Line number")
            onFinished: currentEditor.goToLine(text)
            onClosed: destroy()
        }
    }

    readonly property Action openFileAction: Action
    {
        icon.name: "document-open"
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
        icon.name: "document-new"
        text: i18n("New")
        onTriggered: editorView.openTab("")
    }

    readonly property Action undoAction: Action
    {
        icon.name: "edit-undo"
        text: i18n("Undo")
        enabled: !!currentEditor && currentEditor.body.canUndo
        onTriggered: currentEditor.body.undo()
    }

    readonly property Action redoAction: Action
    {
        icon.name: "edit-redo"
        text: i18n("Redo")
        enabled: !!currentEditor && currentEditor.body.canRedo
        onTriggered: currentEditor.body.redo()
    }

    readonly property Action saveAction: Action
    {
        icon.name: "document-save"
        text: i18n("Save")
        enabled: !!currentEditor && currentEditor.document.modified
        onTriggered: saveFile(currentEditor.fileUrl, currentEditor)
    }

    readonly property Action saveAsAction: Action
    {
        icon.name: "document-save-as"
        text: i18n("Save As")
        enabled: !!currentEditor
        onTriggered: saveFile("", currentEditor)
    }

    readonly property Action findAction: Action
    {
        icon.name: "edit-find"
        text: i18n("Find and Replace")
        enabled: !!currentEditor
        onTriggered: currentEditor.showFindBar = !currentEditor.showFindBar
    }

    readonly property Action goToLineAction: Action
    {
        icon.name: "go-jump"
        text: i18n("Go to Line")
        enabled: !!currentEditor
        onTriggered: openGoToLineDialog()
    }

    readonly property Action toggleSplitViewAction: Action
    {
        text: i18n("Split View")
        icon.name: root.currentTab && root.currentTab.orientation === Qt.Horizontal ? "view-split-left-right" : "view-split-top-bottom"
        enabled: settings.supportSplit && !!root.currentTab
        checkable: true
        checked: root.currentTab && root.currentTab.count === 2
        onTriggered: toggleSplitView()
    }

    readonly property Action toggleLineNumbersAction: Action
    {
        text: i18n("Line Numbers")
        icon.name: "format-list-ordered"
        enabled: !!currentEditor
        checkable: true
        checked: settings.showLineNumbers
        onTriggered: settings.showLineNumbers = !settings.showLineNumbers
    }

    readonly property Action toggleWrapTextAction: Action
    {
        text: i18n("Wrap Text")
        icon.name: "format-text-direction-horizontal"
        enabled: !!currentEditor
        checkable: true
        checked: settings.wrapText
        onTriggered: settings.wrapText = !settings.wrapText
    }

    readonly property Action toggleDocumentStatsAction: Action
    {
        text: i18n("Document Stats")
        icon.name: "document-edit"
        enabled: !!currentEditor
        checkable: true
        checked: settings.showWordCount
        onTriggered: settings.showWordCount = !settings.showWordCount
    }

    readonly property Action toggleLanguageSelectorAction: Action
    {
        text: i18n("Language Selector")
        icon.name: "code-context"
        enabled: !!currentEditor
        checkable: true
        checked: settings.showSyntaxHighlightingLanguages
        onTriggered: settings.showSyntaxHighlightingLanguages = !settings.showSyntaxHighlightingLanguages
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

        if(shouldReuseCurrentScratchTab(path))
        {
            currentEditor.fileUrl = path
            currentEditor.forceActiveFocus()

            if(_stackView.depth === 2 && !options.keepRecentView)
            {
                _stackView.pop()
            }

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

    function requestCloseTab(index)
    {
        if(index < 0 || index >= control.count)
            return

        if(tabHasUnsavedFiles(index))
        {
            _closeDialog.callback = function () { closeTab(index) }
            _closeDialog.open()
            return
        }

        closeTab(index)
    }

    function shouldReuseCurrentScratchTab(path)
    {
        if(!path || path.length === 0 || !currentEditor || !currentTab)
            return false

        if(currentTab.count !== 1)
            return false

        return String(currentEditor.fileUrl).length === 0
                && !currentEditor.document.modified
                && currentEditor.body.length === 0
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

    function closeCurrentTab()
    {
        requestCloseTab(_tabView.currentIndex)
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
