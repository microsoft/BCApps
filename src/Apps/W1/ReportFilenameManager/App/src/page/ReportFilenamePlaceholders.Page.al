// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

page 8128 "Report Filename Placeholders"
{
    // Lists the placeholders a pattern can use; which ones are listed depends on metadata only.
    // FlowFilter fields and types with no file name form (Blob, Media, MediaSet, Time) are not offered.

    Caption = 'Available Placeholders';
    PageType = List;
    ApplicationArea = All;
    SourceTable = "Report Filename Plh. Buffer";
    SourceTableTemporary = true;
    // Must match the key set in SetContext; see the key's comment on the buffer table.
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
                TreeInitialState = CollapseAll;

                // First column, because the tree indents its first column.
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
    /// Keeps the page open when a related-table row is chosen: it names a relation, not a value.
    /// </summary>
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

    internal procedure SetContext(var Pattern: Record "Report Filename Pattern")
    var
        FilenamePlaceholderMgt: Codeunit "Report Filename Plh. Mgt.";
    begin
        Rec.DeleteAll();
        FilenamePlaceholderMgt.BuildPlaceholders(Pattern, Rec);
        ScopeDescription := FilenamePlaceholderMgt.DescribeScope(Pattern);
        // Must match the page's SourceTableView exactly, so both set the same sort order.
        Rec.SetCurrentKey("Sort Order", Source, "Group Name", Indentation, Placeholder);
        if Rec.FindFirst() then;
    end;

    var
        ScopeDescription: Text;
        ChooseAFieldMsg: Label '%1 is a related table, not a value. Expand it and choose one of its fields.', Comment = '%1 the related table as it is shown in the list';
}
