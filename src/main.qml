import QtQuick
import QtCore

import QtQuick.Controls


import org.mauikit.controls as Maui
import org.mauikit.filebrowsing as FB

import org.maui.nota as Nota

import "views"
import "views/editor"
import "views/widgets" as Widgets

Maui.ApplicationWindow
{
    id: root
    color: "transparent"
    background: null

    title: currentEditor ? currentTab.title : ""

    readonly property alias currentTab : editorView.currentTab
    readonly property alias currentEditor: editorView.currentEditor
    property bool debugSidebarFlow: true
    property bool debugTabTitles: true

    readonly property font defaultFont : Maui.Style.monospacedFont
    readonly property alias appSettings: settings

    Settings
    {
        id: settings

        property bool enableSidebar : false
        property bool showLineNumbers : true
        property bool showWordCount: false
        property bool autoSave : true
        property bool restoreSession: true
        property bool enableSyntaxHighlighting : true
        property bool showSyntaxHighlightingLanguages: false
        property bool supportSplit :true
        property double tabSpace: 8
        property string theme : ""
        property string backgroundColor : "white"
        property string textColor : "black"
        property alias sideBarWidth : _sideBarView.sideBar.preferredWidth
        property font font : defaultFont
        property bool wrapText: true
        property string sessionState: ""
    }

    onCurrentEditorChanged:
    {
        if(debugSidebarFlow)
        {
            console.log("[nota-debug] current editor changed", String(currentEditor ? currentEditor.fileUrl : ""))
        }

        syncSidebar(currentEditor ? currentEditor.fileUrl : "")
    }

    onTitleChanged:
    {
        if(debugTabTitles)
        {
            console.log("[nota-debug-tab] window title changed",
                        "windowTitle=", String(title),
                        "tabTitle=", String(currentTab ? currentTab.title : ""),
                        "editorTitle=", String(currentEditor ? currentEditor.title : ""),
                        "editorFile=", String(currentEditor ? currentEditor.fileUrl : ""))
        }
    }

    onClosing: (close) =>
               {
                   _closeDialog.callback = function ()
                   {
                       _closeDialog.discard = true
                       root.close()
                   }

                   if(!_closeDialog.discard)
                   {
                       for(var i = 0; i < editorView.count; i++)
                       {
                           if(editorView.tabHasUnsavedFiles(i))
                           {
                               close.accepted = false
                               _closeDialog.open()
                               return
                           }
                       }
                   }

                   close.accepted = true
               }

    Nota.History
    {
        id: historyList
    }

    Maui.InfoDialog
    {
        id: _closeDialog
        property bool discard : false
        property var callback : ({})

        title: i18n("Unsaved files")
        message: i18n("You have unsaved files. You can go back and save them or choose to discard all changes and exit.")

        template.iconSource: "dialog-warning"
        template.iconVisible: true

        standardButtons: Dialog.Ok | Dialog.Discard
        onDiscarded:
        {
            close()

            if(callback instanceof Function)
            {
                callback()
            }
        }
        onAccepted: close()
    }


    Component
    {
        id: _settingsDialogComponent
        Widgets.SettingsDialog
        {
            onClosed: destroy()
        }
    }

    Component
    {
        id: _shortcutsDialogComponent
        Widgets.ShortcutsDialog
        {
            onClosed: destroy()
        }
    }

    Shortcut
    {
        sequence: "Ctrl+O"
        context: Qt.WindowShortcut
        onActivated: openFileDialog()
    }

    Shortcut
    {
        sequence: "Ctrl+Shift+R"
        context: Qt.WindowShortcut
        onActivated: openRecentFilesDialog()
    }

    Shortcut
    {
        sequence: "Ctrl+N"
        context: Qt.WindowShortcut
        onActivated: openTab()
    }

    Shortcut
    {
        sequence: "Ctrl+W"
        context: Qt.WindowShortcut
        enabled: editorView.count > 0
        onActivated: editorView.closeCurrentTab()
    }

    Shortcut
    {
        sequence: "Ctrl+S"
        context: Qt.WindowShortcut
        enabled: !!currentEditor
        onActivated: saveCurrentFile()
    }

    Shortcut
    {
        sequence: "Ctrl+Shift+S"
        context: Qt.WindowShortcut
        enabled: !!currentEditor
        onActivated: saveCurrentFileAs()
    }

    Shortcut
    {
        sequence: "Ctrl+F"
        context: Qt.WindowShortcut
        enabled: !!currentEditor
        onActivated: toggleFindBar()
    }

    Shortcut
    {
        sequence: "Ctrl+L"
        context: Qt.WindowShortcut
        enabled: !!currentEditor
        onActivated: editorView.openGoToLineDialog()
    }

    Shortcut
    {
        sequence: "Ctrl+J"
        context: Qt.WindowShortcut
        enabled: !!currentEditor
        onActivated: settings.showWordCount = !settings.showWordCount
    }

    Shortcut
    {
        sequence: "F3"
        context: Qt.WindowShortcut
        enabled: !!currentTab
        onActivated: editorView.toggleSplitView()
    }

    Shortcut
    {
        sequence: "Ctrl+/"
        context: Qt.WindowShortcut
        onActivated: openShortcutsDialog()
    }

    Shortcut
    {
        sequence: "Ctrl+,"
        context: Qt.WindowShortcut
        onActivated: openSettingsDialog()
    }

    Shortcut
    {
        sequence: "Escape"
        context: Qt.WindowShortcut
        enabled: _stackView.depth > 1
        onActivated: _stackView.pop()
    }

    Component
    {
        id: _fileDialogComponent
        FB.FileDialog
        {
            browser.settings.onlyDirs: false
            browser.settings.filterType: FB.FMList.TEXT
            browser.settings.sortBy: FB.FMList.MODIFIED

            onClosed: destroy()
        }
    }

    property FB.TagsDialog tagsDialog : null
    Component
    {
        id: _tagsDialogComponent
        FB.TagsDialog
        {
            onTagsReady: (tags) => composerList.updateToUrls(tags)
            composerList.strict: false
            taglist.strict: false
        }
    }

    Maui.WindowBlur
    {
        view: root
        geometry: Qt.rect(0, 0, root.width, root.height)
        windowRadius: Maui.Style.radiusV
        enabled: true
    }

    Rectangle
    {
        anchors.fill: parent
        color: Maui.Theme.backgroundColor
        opacity: 0.76
        radius: Maui.Style.radiusV
    }

    StackView
    {
        id: _stackView
        anchors.fill: parent
        background: null

        initialItem: Maui.SideBarView
        {
            id: _sideBarView
            visible: StackView.status !== StackView.Inactive
            sideBar.enabled: settings.enableSidebar
            sideBar.autoHide: true
            sideBar.autoShow: false
            background: null
            sideBarContent: PlacesSidebar
            {
                id : _drawer
                anchors.fill: parent
                anchors.margins: Maui.Style.contentMargins
            }

            Item
            {
                anchors.fill: parent
                clip: true

                EditorView
                {
                    id: editorView
                    anchors.fill: parent
                }
            }
        }
    }

    Component.onCompleted: Qt.callLater(restoreStartupSession)

    Component
    {
        id: historyViewComponent

        RecentView {}
    }

    function syncSidebar(path)
    {
        if(path && FB.FM.fileExists(path) && settings.enableSidebar)
        {
            const targetDir = String(FB.FM.fileDir(path))
            const currentSidebarDir = _drawer.page && _drawer.page.browser
                    ? String(FB.FM.fileDir(_drawer.page.browser.currentPath))
                    : ""

            if(debugSidebarFlow)
            {
                console.log("[nota-debug] syncSidebar",
                            "file=", String(path),
                            "targetDir=", targetDir,
                            "sidebarDir=", currentSidebarDir)
            }

            if(_drawer.page && _drawer.page.browser && currentSidebarDir !== targetDir)
            {
                if(debugSidebarFlow)
                {
                    console.log("[nota-debug] syncSidebar opening folder", targetDir)
                }

                _drawer.page.browser.openFolder(targetDir)
            }
        }
    }

    function openFileDialog()
    {
        const editorUrl = currentEditor ? String(root.currentEditor.fileUrl) : ""
        const currentPath = editorUrl.length > 0 && FB.FM.fileExists(editorUrl)
                ? FB.FM.fileDir(editorUrl)
                : FB.FM.homePath()
        var props = ({'mode' : FB.FileDialog.Modes.Open,
                         'currentPath' : currentPath,
                         'callback' : (urls) =>
                                      {
                             console.log("ASKIGN TO OPEN URLS", urls)
                             root.openFiles(urls)
                         }})

        var dialog = _fileDialogComponent.createObject(root, props)
        dialog.open()
    }

    function copyFilesTo(urls)
    {
        var props = ({'browser.settings.onlyDirs' : true,
                         'mode' : FB.FileDialog.Modes.Save,
                         'singleSelection' : true,
                         'suggestedFileName' : FB.FM.getFileInfo(urls[0]).label,
                         'callback' : function(paths)
                         {
                             FB.FM.copy(urls, paths[0])
                         }})
        var dialog = _fileDialogComponent.createObject(root, props)
        dialog.open()
    }

    function activateWindow()
    {
        console.log("RAISE WINDOW FORM QML")
        root.raise()
        //        root.requ
    }

    function openSettingsDialog()
    {
        const dialog = _settingsDialogComponent.createObject(root)
        dialog.open()
    }

    function openShortcutsDialog()
    {
        const dialog = _shortcutsDialogComponent.createObject(root)
        dialog.open()
    }

    function openRecentFilesDialog()
    {
        _stackView.push(historyViewComponent)
    }

    function saveCurrentFile()
    {
        if(currentEditor)
            editorView.saveFile(currentEditor.fileUrl, currentEditor)
    }

    function saveCurrentFileAs()
    {
        if(currentEditor)
            editorView.saveFile("", currentEditor)
    }

    function toggleFindBar()
    {
        if(currentEditor)
            currentEditor.showFindBar = !currentEditor.showFindBar
    }

    function restoreStartupSession()
    {
        if(editorView.count > 0)
            return

        if(settings.restoreSession && editorView.restoreSession())
            return
    }

    function openFile(url : string)
    {
        if(debugSidebarFlow)
        {
            console.log("[nota-debug] root openFile", String(url))
        }

        editorView.openTab(url)
    }

    function openFiles(urls : variant)
    {
        if(debugSidebarFlow)
        {
            console.log("[nota-debug] root openFiles", JSON.stringify(urls))
        }

        for(var url of urls)
        {
            root.openFile(url)
        }
    }

    function openTab()
    {
        editorView.openTab("")
    }

    function isUrlOpen(url : string) : bool
    {
        return editorView.isUrlOpen(url)
    }

    function focusFile(url : string)
    {
        editorView.openTab(url)
    }
}
