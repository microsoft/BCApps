// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Ledger;

report 5813 "Clean Up Post Value Entries"
{
    Caption = 'Clean Up Value Entries to Post to G/L';
    ToolTip = 'Delete entries from the list of value entries to post to the general ledger when their cost is already fully posted or the value entry no longer exists.';
    ApplicationArea = Basic, Suite;
    ProcessingOnly = true;
    Permissions = tabledata "Post Value Entry to G/L" = rd,
                  tabledata "Value Entry" = r;

    dataset
    {
        dataitem(PostValueEntryToGL; "Post Value Entry to G/L")
        {
            DataItemTableView = sorting("Value Entry No.");
            RequestFilterFields = "Item No.", "Posting Date", "Value Entry No.";

            trigger OnPreDataItem()
            begin
                // Only consider entries committed by other sessions, so that entries of an ongoing posting are left untouched.
                PostValueEntryToGL.ReadIsolation := IsolationLevel::ReadCommitted;
                TotalCount := PostValueEntryToGL.Count();
                if GuiAllowed() then begin
                    Window.Open(ProgressTxt);
                    Window.Update(2, TotalCount);
                    LastWindowUpdate := CurrentDateTime();
                end;
            end;

            trigger OnAfterGetRecord()
            begin
                CheckedCount += 1;
                if PostValueEntryToGL.HasNothingToPostToGL() then
                    if CountOnly then
                        DeletedCount += 1
                    else
                        AddEntryToDelete(PostValueEntryToGL."Value Entry No.");

                UpdateProgress(false);
            end;

            trigger OnPostDataItem()
            begin
                DeleteEntries();
                if GuiAllowed() then begin
                    UpdateProgress(true);
                    Window.Close();
                end;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';

                    field("Count Only"; CountOnly)
                    {
                        Caption = 'Count only';
                        ToolTip = 'Specifies if the report only counts the entries that can be deleted, without deleting them.';
                    }
                }
            }
        }
    }

    trigger OnPostReport()
    begin
        if not GuiAllowed() then
            exit;

        if CountOnly then
            Message(CountOnlyCompletedMsg, CheckedCount, DeletedCount, CheckedCount - DeletedCount)
        else
            Message(CompletedMsg, CheckedCount, DeletedCount, CheckedCount - DeletedCount);
    end;

    var
        TempPostValueEntryToGLToDelete: Record "Post Value Entry to G/L" temporary;
        Window: Dialog;
        TotalCount: Integer;
        CheckedCount: Integer;
        DeletedCount: Integer;
        LastWindowUpdate: DateTime;
        CountOnly: Boolean;
        ProgressTxt: Label 'Checking entry #1######## of #2########\Entries to delete: #3########\@4@@@@@@@@@@@@@@@@@@@@@@@@@', Comment = '#1: number of checked entries, #2: total number of entries, #3: number of entries deleted or to delete, @4: progress bar';
        CompletedMsg: Label '%1 entries were checked.\%2 entries were deleted.\%3 entries still have cost to post to the general ledger.', Comment = '%1, %2, %3: number of entries';
        CountOnlyCompletedMsg: Label '%1 entries were checked.\%2 entries can be deleted.\%3 entries still have cost to post to the general ledger.', Comment = '%1, %2, %3: number of entries';

    local procedure AddEntryToDelete(ValueEntryNo: Integer)
    begin
        TempPostValueEntryToGLToDelete.Init();
        TempPostValueEntryToGLToDelete."Value Entry No." := ValueEntryNo;
        TempPostValueEntryToGLToDelete.Insert();
        if TempPostValueEntryToGLToDelete.Count() >= 1000 then
            DeleteEntries();
    end;

    local procedure DeleteEntries()
    var
        PostValueEntryToGLToDelete: Record "Post Value Entry to G/L";
        ValueEntryNoFilters: List of [Text];
        ValueEntryNoFilter: Text;
    begin
        // Entries are checked first without holding locks and deleted afterwards in ascending order, the same order report "Post Inventory Cost to G/L" uses.
        // The clean-up therefore never waits for a value entry while it holds locks on entries it has deleted, which avoids deadlocks with posting.
        // The batch is deleted by filters instead of one entry at a time. Committing after each batch keeps the locks short, so that item posting,
        // which inserts into the same table, is not blocked.
        if TempPostValueEntryToGLToDelete.IsEmpty() then
            exit;

        PostValueEntryToGLToDelete.GetValueEntryNoFilters(TempPostValueEntryToGLToDelete, ValueEntryNoFilters);
        foreach ValueEntryNoFilter in ValueEntryNoFilters do begin
            PostValueEntryToGLToDelete.SetFilter("Value Entry No.", ValueEntryNoFilter);
            DeletedCount += PostValueEntryToGLToDelete.Count();
            PostValueEntryToGLToDelete.DeleteAll();
        end;
        TempPostValueEntryToGLToDelete.DeleteAll();
        Commit();
    end;

    local procedure UpdateProgress(Force: Boolean)
    begin
        if not GuiAllowed() then
            exit;
        if not Force and (CurrentDateTime() - LastWindowUpdate < 1000) then
            exit;

        Window.Update(1, CheckedCount);
        Window.Update(3, DeletedCount);
        if TotalCount > 0 then
            Window.Update(4, Round(CheckedCount / TotalCount * 10000, 1));
        LastWindowUpdate := CurrentDateTime();
    end;
}
