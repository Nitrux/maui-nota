import QtQuick.Controls

import org.mauikit.controls as Maui

Maui.SettingsDialog
{
    id: control

    Maui.Controls.title: i18n("Shortcuts")

    Maui.SectionGroup
    {
        title: i18n("General")
        description: i18n("Window-level shortcuts for opening files, browsing recents, and opening Nota dialogs.")

        Maui.FlexSectionItem
        {
            label1.text: i18n("Open Files")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false

                Action { text: "Ctrl" }
                Action { text: "O" }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Recent Files")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false

                Action { text: "Ctrl" }
                Action { text: "Shift" }
                Action { text: "R" }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("New Document")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false

                Action { text: "Ctrl" }
                Action { text: "N" }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Show Shortcuts")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false

                Action { text: "Ctrl" }
                Action { text: "/" }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Settings")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false

                Action { text: "Ctrl" }
                Action { text: "," }
            }
        }
    }

    Maui.SectionGroup
    {
        title: i18n("Document")
        description: i18n("Editing shortcuts that operate on the active document.")

        Maui.FlexSectionItem
        {
            label1.text: i18n("Save")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false

                Action { text: "Ctrl" }
                Action { text: "S" }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Save As")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false

                Action { text: "Ctrl" }
                Action { text: "Shift" }
                Action { text: "S" }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Find and Replace")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false

                Action { text: "Ctrl" }
                Action { text: "R" }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Go to Line")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false

                Action { text: "Ctrl" }
                Action { text: "L" }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Toggle Line and Word Counter")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false

                Action { text: "Ctrl" }
                Action { text: "J" }
            }
        }
    }

    Maui.SectionGroup
    {
        title: i18n("View")

        Maui.FlexSectionItem
        {
            label1.text: i18n("Toggle Split View")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false

                Action { text: "F3" }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Close Recent Files View")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false

                Action { text: "Esc" }
            }
        }
    }
}
