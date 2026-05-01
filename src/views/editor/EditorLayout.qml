import QtQuick
import QtQuick.Controls

import org.mauikit.controls as Maui

Item
{
    id: control

    Maui.Controls.title: title
    Maui.Controls.toolTipText:  currentItem.fileUrl

    property url path
    property var paths: []
    property int restoredCurrentIndex: 0

    property alias currentIndex : _splitView.currentIndex
    property alias orientation : _splitView.orientation

    readonly property alias count : _splitView.count
    readonly property alias currentItem : _splitView.currentItem
    readonly property alias model : _splitView.contentModel
    readonly property string title : count === 2 ?  model.get(0).title + "  -  " + model.get(1).title : currentItem.title

    readonly property alias editor : _splitView.currentItem

    Maui.SplitView
    {
        id: _splitView

        anchors.fill: parent
        orientation : width >= 600 ? Qt.Horizontal : Qt.Vertical
        background: null
        clip: false

        onCurrentIndexChanged: editorView.persistSession()
        Component.onCompleted: restoreSplits()
    }

    Component
    {
        id: _editorComponent
        Editor {}
    }

    function restoreSplits()
    {
        const initialPaths = paths.length ? paths : [path]

        for (const initialPath of initialPaths)
        {
            if(_splitView.count === 0 || String(initialPath).length > 0)
                split(initialPath)
        }

        if(_splitView.count === 0)
        {
            split("")
        }

        if(_splitView.count > 0)
        {
            _splitView.currentIndex = Math.min(restoredCurrentIndex, _splitView.count - 1)
        }

        editorView.persistSession()
    }

    function split(path)
    {
        if(_splitView.count === 1 && !settings.supportSplit)
        {
            return
        }

        if(_splitView.count === 2)
        {
            return
        }

        _splitView.addSplit(_editorComponent, {'fileUrl': path})
        editorView.persistSession()
    }

    function pop()
    {
        if(_splitView.count === 1)
        {
            return //can not pop all the browsers, leave at leats 1
        }

        closeSplit(_splitView.currentIndex === 1 ? 0 : 1)
    }

    function closeSplit(index) //closes a split but triggering a warning before
    {
        if(index >= _splitView.count)
        {
            return
        }

        const item = _splitView.itemAt(index)
        if( item.editor.document.modified)
        {
            _closeDialog.callback = function () { destroyItem(index) }
            _closeDialog.open()
            return
        } else
        {
            destroyItem(index)
        }
    }

    function destroyItem(index) //deestroys a split view withouth warning
    {
        _splitView.closeSplit(index)
        editorView.persistSession()
    }

    function forceActiveFocus()
    {
        control.currentItem.forceActiveFocus()
    }

    function sessionState()
    {
        const state = {
            paths: [],
            currentIndex: Math.max(0, _splitView.currentIndex)
        }

        for(var i = 0; i < _splitView.count; i++)
        {
            const splitItem = _splitView.itemAt(i)
            const splitPath = String(splitItem.fileUrl)

            if(splitPath.length > 0)
                state.paths.push(splitPath)
        }

        if(state.paths.length === 0)
            return null

        state.currentIndex = Math.min(state.currentIndex, state.paths.length - 1)
        return state
    }
}
