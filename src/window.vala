/* window.vala
 *
 * Copyright 2021 liferooter
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace Textpieces {
    [GtkTemplate (ui = "/com/github/liferooter/textpieces/ui/window.ui")]
    public class MainWindow : Hdy.ApplicationWindow {
        [GtkChild]
        private Gtk.ListBox tool_listbox;
        [GtkChild]
        private Gtk.Entry tool_name;
        [GtkChild]
        private Gtk.Popover tool_popover;
        [GtkChild]
        private Gtk.SourceBuffer text_buffer;
        [GtkChild]
        private Gtk.SourceView text_view;
        [GtkChild]
        private Gtk.Button apply_button;
        [GtkChild]
        private Gtk.Popover copied_popover;
        [GtkChild]
        private Gtk.Button undo_button;
        [GtkChild]
        private Gtk.Button redo_button;

        Tool? current_tool = null;

        public const string ACTION_UNDO = "undo";
        public const string ACTION_REDO = "redo";
        public const string ACTION_APPLY = "apply";
        public const string ACTION_SHORTCUTS = "show-keybindings";
        public const string ACTION_PREFERENCES = "show-preferences";
        public const string ACTION_ABOUT = "about";
        public const string ACTION_COPY = "copy";

        private const ActionEntry[] ACTION_ENTRIES = {
            { ACTION_UNDO, action_undo },
            { ACTION_REDO, action_redo },
            { ACTION_APPLY, action_apply },
            { ACTION_SHORTCUTS, action_shortcuts },
            { ACTION_PREFERENCES, action_preferences },
            { ACTION_ABOUT, action_about },
            { ACTION_COPY, action_copy }
        };

        public SimpleActionGroup actions;

        public MainWindow (Gtk.Application app) {
            Object (application: app);
        }

        construct {
            // Get tools
            var TOOLS = get_tools ();

            // Generate tool list
            for (int i = 0; i < TOOLS.length; i++) {

                // model_button.show();
                var row = new Textpieces.ToolRow (TOOLS[i], i);
                tool_listbox.add (row);
            }

            // Set dark theme if needed
            Textpieces.Application.settings.changed.connect (update_from_settings);
            update_from_settings ();


            // Setup keybindings

            var keybindings = new Gtk.AccelGroup ();

            // Show shortcuts window (Ctrl+?)
            keybindings.connect (
                Gdk.keyval_from_name ("question"),
                Gdk.ModifierType.CONTROL_MASK,
                0,
                () => {
                    action_shortcuts ();
                    return true;
                }
            );

            // Show preferences window (Ctrl+,)
            keybindings.connect (
                Gdk.keyval_from_name ("comma"),
                Gdk.ModifierType.CONTROL_MASK,
                0,
                () => {
                    action_preferences ();
                    return true;
                }
            );

            add_accel_group (keybindings);

            // Setup actions
            actions = new SimpleActionGroup ();
            actions.add_action_entries (ACTION_ENTRIES, this);
            insert_action_group ("win", actions);


            // Setup handlers

            // Set text changed handler
            text_buffer.changed.connect (check_whether_can_do_actions);
            check_whether_can_do_actions ();

            // Show tool popover on click
            tool_name.grab_focus.connect ((e) => {
                tool_popover.popup ();
            });

            // Select tool on click
            tool_listbox.row_activated.connect ((row) => {
                var tool_row = (ToolRow) row;
                current_tool = Tool () {
                    name = tool_row.name,
                    icon = tool_row.tool_image.icon_name,
                    func = tool_row.func
                };
                tool_name.primary_icon_name = current_tool.icon;
                tool_name.set_text (current_tool.name);
                check_whether_can_do_actions ();
                tool_popover.popdown  ();
            });
        }

        void update_from_settings () {
            var settings = Textpieces.Application.settings;

            // Setup SourceView
            with (text_view) {
                show_line_numbers = settings.get_boolean ("show-line-numbers");
                background_pattern = settings.get_boolean ("show-grid")
                    ? Gtk.SourceBackgroundPatternType.GRID
                    : Gtk.SourceBackgroundPatternType.NONE;
                tab_width = settings.get_uint ("tab-width");
                indent_width = (int) settings.get_uint ("tab-width");
                insert_spaces_instead_of_tabs = settings.get_boolean ("tab-to-spaces");
            }

            Gtk.Settings.get_default ().gtk_application_prefer_dark_theme
                = settings.get_boolean("prefer-dark");

        }

        void check_whether_can_do_actions () {
            apply_button.set_sensitive (text_buffer.text != "" && current_tool != null);
            Idle.add (() => {
                undo_button.set_sensitive (text_buffer.can_undo);
                redo_button.set_sensitive (text_buffer.can_redo);
                return false;
            });
        }

        void action_undo () {
            if (text_buffer.can_undo)
                text_buffer.undo ();
        }

        void action_redo () {
            if (text_buffer.can_redo)
                text_buffer.redo ();
        }
        void action_apply () {
            text_buffer.begin_user_action ();
            if (text_buffer.has_selection) {
                Gtk.TextIter start, end;
                text_buffer.get_selection_bounds (out start, out end);

                var result = current_tool.func (text_buffer.get_text (start, end, false));

                text_buffer.@delete (ref start, ref end);
                text_buffer.insert (ref start, result, -1);
            }
            else
                text_buffer.text = current_tool.func (text_buffer.text);
            text_buffer.end_user_action ();
        }
        void action_shortcuts () {
            var shortcuts_window = new Textpieces.ShortcutsWindow (this);
            shortcuts_window.show_all ();
            shortcuts_window.present ();
        }
        void action_preferences () {
            var prefs = new Textpieces.Preferences (this);

            prefs.show_all ();
            prefs.present ();
        }

        void action_about () {
            var about = new Textpieces.AboutDialog (this);

            about.show_all ();
            about.present ();
        }

        void action_copy () {
            var clipboard = Gtk.Clipboard.get_default (Gdk.Display.get_default ());
            clipboard.set_text (text_buffer.text, -1);

            copied_popover.popup ();
        }
    }
}
