import QtQuick
import QtQuick.Controls

import org.mauikit.controls as Maui
import org.mauikit.texteditor as TE

Maui.SplitViewItem
{
    id: control

    property alias editor : _editor
    property alias fileUrl : _editor.fileUrl
    property alias title : _editor.title
    readonly property int wordCount:
        {
            const text = _editor.body.text.trim()
            return text.length === 0 ? 0 : text.split(/\s+/).length
        }

    Maui.Controls.title : title
    Maui.Controls.badgeText: editor.document.modified ? "*" : ""
    clip: false

    TE.TextEditor
    {
        id: _editor
        anchors.fill: parent

        showLineNumbers: settings.showLineNumbers
        property alias showLineCount : _linesCount.visible

        body.color: settings.textColor
        body.font.family: settings.font.family
        body.font.pointSize: settings.font.pointSize
        body.wrapMode: settings.wrapText ? Text.Wrap : Text.NoWrap

        document.backgroundColor: settings.backgroundColor
        Maui.Theme.backgroundColor: settings.backgroundColor

        document.theme: settings.theme
        document.enableSyntaxHighlighting: settings.enableSyntaxHighlighting
        document.autoSave: settings.autoSave
        document.tabSpace: ((settings.tabSpace+1) * body.font.pointSize) / 2
        spellcheckEnabled: false
        showSpellingContextMenu: false

        onFileUrlChanged:
        {
            _languageSelector.syncCurrentIndex()

            if(String(_editor.fileUrl).length > 0)
            {
                historyList.append(_editor.fileUrl)
                editorView.persistSession()
            }
        }
        onTitleChanged: _languageSelector.syncCurrentIndex()

        Loader
        {
            asynchronous: true
            anchors.fill: parent

            sourceComponent: DropArea
            {
                id: _dropArea
                property var urls : []
                onDropped: (drop) =>
                {
                    if(drop.urls)
                    {
                        var m_urls = drop.urls.join(",")
                        _dropArea.urls = m_urls.split(",")
                        _dropAreaMenu.show()
                    }
                }

                Maui.ContextualMenu
                {
                    id: _dropAreaMenu

                    MenuItem
                    {
                        text: i18n("Open Here")
                        icon.name : "open-for-editing"
                        onTriggered:
                        {
                            _editor.fileUrl = _dropArea.urls[0]
                        }
                    }

                    MenuItem
                    {
                        text: i18n("Open in New Tab")
                        icon.name: "tab-new"
                        onTriggered:
                        {
                           openFiles( _dropArea.urls )
                        }
                    }

                    MenuItem
                    {
                        enabled: _dropArea.urls.length === 1 && currentTab.count <= 1 && settings.supportSplit
                        text: i18n("Open in New Split")
                        icon.name: "view-split-left-right"
                        onTriggered:
                        {
                            currentTab.split(_dropArea.urls[0])
                        }
                    }

                    MenuSeparator{}

                    MenuItem
                    {
                        text: i18n("Cancel")
                        icon.name: "dialog-cancel"
                        onTriggered:
                        {
                            _dropAreaMenu.close()
                        }
                    }

                    onClosed: _editor.forceActiveFocus()
                }
            }
        }

        Maui.Chip
        {
            id: _linesCount
            visible: settings.showWordCount
            text: i18n("%1 lines / %2 words", _editor.body.lineCount, control.wordCount)
            color: _editor.body.color

            anchors
            {
                right: parent.right
                top: parent.top
                margins: Maui.Style.space.medium
            }

            opacity: 0.5
        }
    }

    ComboBox
    {
        id: _languageSelector
        visible: settings.showSyntaxHighlightingLanguages
        model: _editor.document.getLanguageNameList()
        currentIndex: -1
        z: 2

        anchors
        {
            right: parent.right
            bottom: parent.bottom
            margins: Maui.Style.space.medium
        }

        function syncCurrentIndex()
        {
            const languages = _editor.document.getLanguageNameList()
            const currentLanguage = _editor.document.formatName
            const nextIndex = languages.indexOf(currentLanguage)
            currentIndex = nextIndex
        }

        onActivated: _editor.document.formatName = model[index]
        Component.onCompleted: syncCurrentIndex()
    }

    Component.onCompleted:
    {
        _editor.forceActiveFocus()
    }
}
