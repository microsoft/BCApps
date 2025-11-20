// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension.Correction;

page 2585 "Dim Correct Selection Criteria"
{
    PageType = List;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    SourceTable = "Dim Correct Selection Criteria";
    Caption = 'Entry selection criteria';

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(FilterType; Rec."Filter Type")
                {
                    ApplicationArea = All;
                    Caption = 'Type';
                    ToolTip = 'Specifies the type of the selection.';
                }

                field(SelectionCriteriaText; SelectionCriteriaText)
                {
                    ApplicationArea = All;
                    Caption = 'Selection Criteria';
                    ToolTip = 'Specifies the rule used to include ledger entries in the correction.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Delete)
            {
                ApplicationArea = All;
                Visible = not ReadOnlyMode;
                Caption = 'Delete';
                Image = Delete;
                ToolTip = 'Remove selection criteria. This removes all entries added by the rule.';

                trigger OnAction()
                begin
                    EntriesToDelete.Add(Rec.SystemId);
                    UpdateFilter();
                end;
            }

            action(Undo)
            {
                ApplicationArea = All;
                Visible = not ReadOnlyMode;
                Caption = 'Undo';
                Image = Undo;
                ToolTip = 'Undo the last step.';

                trigger OnAction()
                var
                    LastDeletedRecordSystemId: Guid;
                begin
                    if EntriesToDelete.Count() = 0 then
                        Error(ThereIsNothingToUndoErr);

                    EntriesToDelete.Get(EntriesToDelete.Count(), LastDeletedRecordSystemId);
                    EntriesToDelete.RemoveAt(EntriesToDelete.Count());
                    UpdateFilter();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Delete_Promoted; Delete)
                {
                }
                actionref(Undo_Promoted; Undo)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.GetSelectionDisplayText(SelectionCriteriaText);
    end;

    procedure GetEntriesToDelete(var SelectedEntriesToDelete: List of [Guid])
    begin
        SelectedEntriesToDelete := EntriesToDelete;
    end;

    local procedure UpdateFilter()
    var
        EntriesToDeleteFilter: Text;
        EntryToDelete: Guid;
    begin
        Rec.FilterGroup(4);

        if EntriesToDelete.Count > 0 then begin
            foreach EntryToDelete in EntriesToDelete do begin
                if EntriesToDeleteFilter <> '' then
                    EntriesToDeleteFilter += '&';

                EntriesToDeleteFilter += StrSubstNo(EntriesToDeletePlaceholderTxt, EntryToDelete);
            end;
            Rec.SetFilter(SystemId, EntriesToDeleteFilter);
        end else
            Rec.SetRange(SystemId);

        Rec.FilterGroup(0);
    end;

    procedure SetReadOnly()
    begin
        ReadOnlyMode := true;
    end;

    var
        ReadOnlyMode: Boolean;
        EntriesToDelete: List of [Guid];
        SelectionCriteriaText: Text;
        ThereIsNothingToUndoErr: Label 'There is nothing to undo.';
        EntriesToDeletePlaceholderTxt: Label '<>%1', Locked = true;
}
