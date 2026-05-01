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
                onToggled: settings.showLineNumbers = !settings.showLineNumbers
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
                onToggled: settings.wrapText = !settings.wrapText
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
            label1.text: i18n("Colors")
            label2.text: i18n("Configure the color scheme of the syntax highlighting. This configuration is not applied for rich text formats.")
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
        TE.ColorSchemesPage
        {
            enabled: settings.enableSyntaxHighlighting

            currentTheme: appSettings.theme
            backgroundColor: appSettings.backgroundColor

            onColorsPicked: (background, text) =>
                            {
                                root.appSettings.backgroundColor = background
                                root.appSettings.textColor = text
                            }

            onCurrentThemeChanged: appSettings.theme = currentTheme
        }
    }
}
