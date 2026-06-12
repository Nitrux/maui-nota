import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.mauikit.controls as Maui
import org.mauikit.texteditor as TE

Maui.SettingsDialog
{
    id: control

    Component
    {
        id:_fontPageComponent

        Maui.SettingsPage
        {
            title: i18n("Font")

            Maui.FontPicker
            {
                Layout.fillWidth: true

                mfont: settings.font
                model.onlyMonospaced: true
                showStyle: false

                onFontModified:
                {
                    settings.font = font
                }
            }
        }
    }

    Maui.SectionGroup
    {
        title: i18n("General")

        Maui.FlexSectionItem
        {
            label1.text: i18n("Places Sidebar")
            label2.text: i18n("Browse your file system from the sidebar.")

            Switch
            {
                checkable: true
                checked: settings.enableSidebar
                onToggled: settings.enableSidebar = !settings.enableSidebar
            }
        }

        Maui.FlexSectionItem
        {
            label1.text:  i18n("Auto Save")
            label2.text: i18n("Auto saves your file every few seconds.")

            Switch
            {
                checkable: true
                checked: settings.autoSave
                onToggled: settings.autoSave = !settings.autoSave
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Restore Session")
            label2.text: i18n("Reopen the previously saved files and tab layout when launching Nota.")

            Switch
            {
                checkable: true
                checked: settings.restoreSession
                onToggled: settings.restoreSession = !settings.restoreSession
            }
        }
    }

    Maui.SectionGroup
    {
        title: i18n("Editor")

        Maui.FlexSectionItem
        {
            label1.text: i18n("Line Numbers")
            label2.text: i18n("Display the line numbers on the left side.")

            Switch
            {
                checkable: true
                checked: settings.showLineNumbers
                onToggled: settings.showLineNumbers = checked
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Wrap Text")
            label2.text: i18n("Wrap the text into new lines.")

            Switch
            {
                checkable: true
                checked: settings.wrapText
                onToggled: settings.wrapText = checked
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Language Selector")
            label2.text: i18n("Display the active syntax-highlighting language selector in the editor footer.")

            Switch
            {
                checkable: true
                checked: settings.showSyntaxHighlightingLanguages
                onToggled: settings.showSyntaxHighlightingLanguages = !settings.showSyntaxHighlightingLanguages
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Syntax Highlighting")
            label2.text: i18n("Enable syntax highlighting for supported languages.")

            Switch
            {
                checkable: true
                checked: settings.enableSyntaxHighlighting
                onToggled: settings.enableSyntaxHighlighting = !settings.enableSyntaxHighlighting
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Color Scheme")
            label2.text: i18n("Configure the color scheme of the editor.")
            enabled: settings.enableSyntaxHighlighting

            ToolButton
            {
                checkable: true
                onToggled: control.addPage(_stylePageComponent)
                icon.name: "go-next"
            }
        }
    }

    Maui.SectionGroup
    {
        title: i18n("Display")
        //        description: i18n("Configure the font and display options.")

        Maui.FlexSectionItem
        {
            label1.text: i18n("Font")
            label2.text: i18n("Font family and size.")

            ToolButton
            {
                checkable: true
                icon.name: "go-next"
                onToggled: control.addPage(_fontPageComponent)
            }
        }

        Maui.FlexSectionItem
        {
            label1.text:  i18n("Tab Space")

            SpinBox
            {
                from: 2; to : 500
                value: settings.tabSpace
                onValueChanged: settings.tabSpace = value
            }
        }
    }

    Component
    {
        id:_stylePageComponent
        Maui.SettingsPage
        {
            id: _stylePage
            title: i18n("Color Scheme")
            enabled: settings.enableSyntaxHighlighting

            property string currentTheme: appSettings.theme
            property color backgroundColor: appSettings.backgroundColor

            function contrastTextColor(colorValue)
            {
                const luma = (0.299 * colorValue.r) + (0.587 * colorValue.g) + (0.114 * colorValue.b)
                return luma >= 0.55 ? "#1f2329" : "#f5f7fa"
            }

            function applyBackgroundColor(colorValue)
            {
                const textColor = contrastTextColor(colorValue)
                backgroundColor = colorValue
                root.appSettings.backgroundColor = colorValue
                root.appSettings.textColor = textColor
            }

            onCurrentThemeChanged: appSettings.theme = currentTheme

            Maui.InfoDialog
            {
                id: _backgroundColorDialog
                title: i18n("Select Editor Background")
                standardButtons: Dialog.Ok | Dialog.Cancel
                property color pendingColor: _stylePage.backgroundColor

                onOpened:
                {
                    pendingColor = _stylePage.backgroundColor
                    _hexField.text = String(pendingColor)
                }

                onAccepted:
                {
                    _stylePage.applyBackgroundColor(pendingColor)
                }

                Maui.SectionGroup
                {
                    title: i18n("Color")
                    description: i18n("Choose one of the presets or type a hex color.")
                    Layout.fillWidth: true

                    Maui.ColorsRow
                    {
                        Layout.fillWidth: true
                        currentColor: _backgroundColorDialog.pendingColor
                        colors: [
                            "#1e2030",
                            "#26283a",
                            "#2d2f45",
                            "#333333",
                            "#f5f5f5",
                            "#fff3e6",
                            "#dbe7ff",
                            "#e9f7ef"
                        ]
                        onColorPicked: (color) =>
                        {
                            _backgroundColorDialog.pendingColor = color
                            _hexField.text = String(color)
                        }
                    }

                    Maui.FlexSectionItem
                    {
                        label1.text: i18n("Hex")
                        label2.text: i18n("Use #RRGGBB format.")

                        Maui.TextField
                        {
                            id: _hexField
                            Layout.fillWidth: true
                            placeholderText: "#1e2030"
                            onTextEdited:
                            {
                                const value = text.trim()
                                if (/^#([0-9a-fA-F]{6})$/.test(value))
                                    _backgroundColorDialog.pendingColor = value
                            }
                        }
                    }
                }

            }

            Maui.FlexSectionItem
            {
                label1.text: i18n("Editor Background")
                label2.text: i18n("Current: %1", String(_stylePage.backgroundColor))

                RowLayout
                {
                    spacing: Maui.Style.space.small

                    Rectangle
                    {
                        implicitWidth: Maui.Style.iconSizes.medium
                        implicitHeight: Maui.Style.iconSizes.medium
                        radius: Maui.Style.radiusV
                        color: _stylePage.backgroundColor
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.15)
                    }

                    Button
                    {
                        text: i18n("Select Color")
                        onClicked: _backgroundColorDialog.open()
                    }
                }
            }


            Maui.FlexSectionItem
            {
                label1.text: i18n("Syntax Highlight Colors")
                label2.text: i18n("Select a color scheme for the syntax highlight.")

            }

            GridLayout
            {
                columns: 2
                Layout.fillWidth: true
                opacity: enabled ? 1 : 0.5

                Repeater
                {
                    model: TE.ColorSchemesModel {}

                    delegate: Maui.GridBrowserDelegate
                    {
                        Layout.fillWidth: true
                        checked: model.name === _stylePage.currentTheme
                        onClicked: _stylePage.currentTheme = model.name
                        label1.text: model.name

                        template.iconComponent: Rectangle
                        {
                            implicitHeight: Math.max(_layout.implicitHeight + topPadding + bottomPadding, 64)
                            color: _stylePage.backgroundColor
                            radius: Maui.Style.radiusV

                            Column
                            {
                                id: _layout
                                anchors.fill: parent
                                anchors.margins: Maui.Style.space.small
                                spacing: 2

                                Text
                                {
                                    wrapMode: Text.NoWrap
                                    elide: Text.ElideLeft
                                    width: parent.width
                                    text: "QWERTY { @ }"
                                    color: model.foreground
                                    font.family: "Monospace"
                                }

                                Rectangle
                                {
                                    radius: 2
                                    height: 8
                                    width: parent.width
                                    color: model.highlight
                                }

                                Rectangle
                                {
                                    radius: 2
                                    height: 8
                                    width: parent.width
                                    color: model.color3
                                }

                                Rectangle
                                {
                                    radius: 2
                                    height: 8
                                    width: parent.width
                                    color: model.color4
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
