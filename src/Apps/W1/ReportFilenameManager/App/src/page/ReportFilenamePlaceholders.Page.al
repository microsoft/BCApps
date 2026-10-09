// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
page 50113 "Report Filename Placeholders"
{
    // Answers "which fields can I use?" at setup time, from compiled metadata only. A
    // placeholder that could not be filled in is never offered, so an administrator cannot build
    // a pattern that silently declines later.
    //
    // Placeholder, not token: Business Central says token only for sign-in tokens, and says
    // placeholder for exactly this - a name in braces or brackets that a value replaces, as in
    // the {PASSWORD} placeholder CRM Connection Setup asks for in a connection string.

    Caption = 'Available Placeholders';
    PageType = List;
    ApplicationArea = All;
    SourceTable = "Report Filename Plh. Buffer";
    SourceTableTemporary = true;
    // Grouping before indenting is what makes the tree hold together; the key's own comment
    // records why sorting by the placeholder text cannot do it.
    SourceTableView = sorting("Sort Order", Source, "Group Name", Indentation, Placeholder);
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            group(Scope)
            {
                Caption = 'Report and Table';
                InstructionalText = 'These are the placeholders the selected report and table can supply. Anything that cannot always be read reliably is not offered.';

                field(ScopeDescription; ScopeDescription)
                {
                    ShowCaption = false;
                    Caption = 'Report and Table';
                    ToolTip = 'Specifies the report and table that the list of placeholders is based on.';
                    ApplicationArea = All;
                    Editable = false;
                    MultiLine = true;
                }
            }
            repeater(Placeholders)
            {
                ShowAsTree = true;
                IndentationColumn = Rec.Indentation;
                IndentationControls = Placeholder;
                // Collapsed, because the point of the tree is that the administrator chooses a
                // relation before they are shown its fields. Opened expanded it would be the
                // flat list again, only taller.
                TreeInitialState = CollapseAll;

                // The placeholder first: it is the column the tree indents, and a tree reads from
                // its first column. Source used to come first and the tree hung off the second.
                field(Placeholder; Rec.Placeholder)
                {
                    ApplicationArea = All;
                }
                field(Source; Rec.Source)
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Width = 30;
                }
                field(OverSeveralRecords; Rec."Over Several Records")
                {
                    ApplicationArea = All;
                }
                field(Example; Rec.Example)
                {
                    ApplicationArea = All;
                    Width = 25;
                }
            }
        }
    }

    /// <summary>
    /// Refuses a table row rather than accepting it and quietly inserting nothing. A branch of
    /// the tree names a relation, not a value, so there is no placeholder to hand back; the page stays
    /// open on the row the administrator chose, which is the row they need to expand.
    /// </summary>
    /// <param name="CloseAction">How the page is being closed.</param>
    /// <returns>False to keep the page open when a table row was chosen.</returns>
    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction <> Action::LookupOK then
            exit(true);

        if Rec.IsRelatedTableRow() then begin
            Message(ChooseAFieldMsg, Rec.Placeholder);
            exit(false);
        end;

        exit(true);
    end;

    /// <summary>
    /// Builds the placeholder list for a pattern.
    /// </summary>
    /// <param name="Pattern">The pattern whose report and table decide what is available.</param>
    internal procedure SetContext(var Pattern: Record "Report Filename Pattern")
    var
        FilenamePlaceholderMgt: Codeunit "Report Filename Plh. Mgt.";
    begin
        Rec.DeleteAll();
        FilenamePlaceholderMgt.BuildPlaceholders(Pattern, Rec);
        ScopeDescription := FilenamePlaceholderMgt.DescribeScope(Pattern);
        // Positioned under the order the tree is shown in, not under the primary key, so the
        // list opens on its first row rather than part-way down. This key has to match the
        // page's own SourceTableView exactly - it is set after it and wins, so leaving "Sort
        // Order" out of it here silently undid the ordering the page asked for and the computed
        // values went on appearing third.
        Rec.SetCurrentKey("Sort Order", Source, "Group Name", Indentation, Placeholder);
        if Rec.FindFirst() then;
    end;

    var
        ScopeDescription: Text;
        ChooseAFieldMsg: Label '%1 is a related table, not a value. Expand it and choose one of its fields.', Comment = '%1 the related table as it is shown in the list';
}
