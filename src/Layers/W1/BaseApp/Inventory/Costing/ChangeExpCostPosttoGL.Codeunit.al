// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Setup;
using System.Globalization;

codeunit 5811 "Change Exp. Cost Post. to G/L"
{
    Permissions = TableData "Value Entry" = rm,
                  TableData "Avg. Cost Adjmt. Entry Point" = id,
                  TableData "Post Value Entry to G/L" = id;
    TableNo = "Inventory Setup";

    trigger OnRun()
    begin
    end;

    var
        ExpCostEnableTxt: Label 'If you enable the %1, the program must update table %2.', Comment = '%1 - Expected Cost Posting to G/L; %2 - Post Value Entry to G/L';
        ExpCostDisableTxt: Label 'If you disable the %1, the program must update table %2.', Comment = '%1 - Expected Cost Posting to G/L; %2 - Post Value Entry to G/L';
        TakeHoursTxt: Label 'This can take several hours.\';
        ConfirmChangeTxt: Label 'Do you really want to change the %1?', Comment = '%1 - Expected Cost Posting to G/L';
#pragma warning disable AA0074
        Text003: Label 'The change has been cancelled.';
        Text004: Label 'Processing entries...\\';
#pragma warning disable AA0470
        Text005: Label 'Item No. #1########## @2@@@@@@@@@@@@@';
        Text007: Label '%1 has been changed to %2. You should now run %3.';
        Text008: Label 'Deleting %1 entries...';
#pragma warning restore AA0470
#pragma warning restore AA0074
        DisableWarningTxt: Label 'This will not change amounts on the interim accounts and the eventual clean-up in the G/L must be done manually.\';
        Window: Dialog;
        EntriesModified: Boolean;

    procedure ChangeExpCostPostingToGL(var InventorySetup: Record "Inventory Setup"; ExpCostPostingToGL: Boolean)
    var
        PostValueEntryToGL: Record "Post Value Entry to G/L";
        ConfirmMessage: Text;
    begin
        if ExpCostPostingToGL then
            ConfirmMessage := ExpCostEnableTxt + TakeHoursTxt + ConfirmChangeTxt
        else
            ConfirmMessage := ExpCostDisableTxt + TakeHoursTxt + DisableWarningTxt + ConfirmChangeTxt;

        if not
           Confirm(
             StrSubstNo(
                ConfirmMessage, InventorySetup.FieldCaption("Expected Cost Posting to G/L"), PostValueEntryToGL.TableCaption()), false)
        then
            Error(Text003);

        if ExpCostPostingToGL then
            EnableExpCostPostingToGL()
        else
            DisableExpCostPostingToGL();

        UpdateInvtSetup(InventorySetup, ExpCostPostingToGL)
    end;

    local procedure EnableExpCostPostingToGL()
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        PostValueEntryToGL: Record "Post Value Entry to G/L";
        OldItemNo: Code[20];
        LastUpdateDateTime: DateTime;
        RecordNo: Integer;
        NoOfRecords: Integer;
    begin
        Window.Open(
          Text004 +
          Text005);

        ValueEntry.LockTable();
        LastUpdateDateTime := CurrentDateTime;

        if PostValueEntryToGL.FindSet() then
            repeat
                ValueEntry.Get(PostValueEntryToGL."Value Entry No.");
                UpdatePostValueEntryToGL(ValueEntry."Item Ledger Entry No.");
            until PostValueEntryToGL.Next() = 0;

        ItemLedgEntry.SetCurrentKey("Item No.", "Entry Type");
        ItemLedgEntry.SetFilter("Entry Type", '%1|%2|%3', ItemLedgEntry."Entry Type"::Sale, ItemLedgEntry."Entry Type"::Purchase, ItemLedgEntry."Entry Type"::Output);
        NoOfRecords := ItemLedgEntry.Count;
        OldItemNo := '';
        if ItemLedgEntry.Find('-') then
            repeat
                RecordNo := RecordNo + 1;

                if ItemLedgEntry."Item No." <> OldItemNo then begin
                    Window.Update(1, ItemLedgEntry."Item No.");
                    OldItemNo := ItemLedgEntry."Item No.";
                end;

                if CurrentDateTime - LastUpdateDateTime >= 1000 then begin
                    Window.Update(2, Round(RecordNo / NoOfRecords * 10000, 1));
                    LastUpdateDateTime := CurrentDateTime;
                end;

                if (ItemLedgEntry.Quantity <> ItemLedgEntry."Invoiced Quantity") and (ItemLedgEntry.Quantity <> 0) then
                    UpdatePostValueEntryToGL(ItemLedgEntry."Entry No.");

            until ItemLedgEntry.Next() = 0;

        Window.Close();
    end;

    local procedure UpdatePostValueEntryToGL(ItemLedgEntryNo: Integer)
    var
        PostValueEntryToGL: Record "Post Value Entry to G/L";
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
        if ValueEntry.Find('-') then
            repeat
                if not EntriesModified then
                    EntriesModified := true;
                if not PostValueEntryToGL.Get(ValueEntry."Entry No.") and
                   ((ValueEntry."Cost Amount (Expected)" <> ValueEntry."Expected Cost Posted to G/L") or
                    (ValueEntry."Cost Amount (Expected) (ACY)" <> ValueEntry."Exp. Cost Posted to G/L (ACY)"))
                then begin
                    PostValueEntryToGL."Value Entry No." := ValueEntry."Entry No.";
                    PostValueEntryToGL."Item No." := ValueEntry."Item No.";
                    PostValueEntryToGL."Posting Date" := ValueEntry."Posting Date";
                    OnBeforePostValueEntryToGLInsert(PostValueEntryToGL, ValueEntry);
                    PostValueEntryToGL.Insert();
                end;
            until ValueEntry.Next() = 0;
    end;

    local procedure DisableExpCostPostingToGL()
    var
        PostValueEntryToGL: Record "Post Value Entry to G/L";
        ValueEntry: Record "Value Entry";
    begin
        Window.Open(StrSubstNo(Text008, PostValueEntryToGL.TableCaption));
        if PostValueEntryToGL.FindSet(true) then
            repeat
                ValueEntry.Get(PostValueEntryToGL."Value Entry No.");
                if ValueEntry."Expected Cost" then
                    PostValueEntryToGL.Delete();

            until PostValueEntryToGL.Next() = 0;
        Window.Close();
    end;

    local procedure UpdateInvtSetup(var InvtSetup: Record "Inventory Setup"; ExpCostPostingToGL: Boolean)
    var
        ObjTransl: Record "Object Translation";
    begin
        InvtSetup."Expected Cost Posting to G/L" := ExpCostPostingToGL;
        InvtSetup.Modify();
        if EntriesModified then
            Message(
              Text007, InvtSetup.FieldCaption("Expected Cost Posting to G/L"), InvtSetup."Expected Cost Posting to G/L",
              ObjTransl.TranslateObject(ObjTransl."Object Type"::Report, REPORT::"Post Inventory Cost to G/L"));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostValueEntryToGLInsert(var PostValueEntryToGL: Record "Post Value Entry to G/L"; ValueEntry: Record "Value Entry")
    begin
    end;
}

