// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Journal;

using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Setup;
using Microsoft.Utilities;

codeunit 5899 "Calc. Inventory Value-Check"
{
    Permissions = TableData "Avg. Cost Adjmt. Entry Point" = r;

    trigger OnRun()
    begin
    end;

    var
        InvtSetup: Record "Inventory Setup";
        TempErrorBuf: Record "Error Buffer" temporary;
        PostingDate: Date;
        CalculatePer: Enum "Inventory Value Calc. Per";
        ByLocation: Boolean;
        ByVariant: Boolean;
        ShowDialog: Boolean;
        TestMode: Boolean;
        ErrorCounter: Integer;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text004: Label 'Checking items #1##########';
        Text007: Label 'You have to run the Adjust Cost - Item Entries batch job, before you can revalue item %1.';
        Text009: Label 'You must not revalue items with Costing Method %1, if Calculate Per is Item Ledger Entry.';
        Text011: Label 'You must not enter a %1 if you revalue items with Costing Method %2 and if Average Cost Calc. Type is %3 in Inventory Setup.';
        Text012: Label 'The By Location field must not be filled in if you revalue items with Costing Method %1 and if Average Cost Calc. Type is %2 in Inventory Setup.';
        Text014: Label 'The By Variant field must not be filled in if you revalue items with Costing Method %1 and if Average Cost Calc. Type is %2 in Inventory Setup.';
        Text015: Label 'You must fill in a Location filter and a Variant filter or select the By Location field and the By Variant field, if you revalue items with Costing Method %1, and if Average Cost Calc. Type is %2 in Inventory Setup.';
        Text018: Label 'The Item %1 cannot be revalued because there is at least one open outbound item ledger entry.';
        Text020: Label 'Open Outbound Entry %1 found.';
#pragma warning restore AA0470
#pragma warning restore AA0074


    procedure SetParameters(NewPostingDate: Date; NewCalculatePer: Enum "Inventory Value Calc. Per"; NewByLocation: Boolean; NewByVariant: Boolean; NewShowDialog: Boolean; NewTestMode: Boolean)
    begin
        TempErrorBuf.DeleteAll();
        ClearAll();

        PostingDate := NewPostingDate;
        CalculatePer := NewCalculatePer;
        ByLocation := NewByLocation;
        ByVariant := NewByVariant;
        ShowDialog := NewShowDialog;
        TestMode := NewTestMode;

        InvtSetup.Get();
    end;

    procedure RunCheck(var Item: Record Item; var NewErrorBuf: Record "Error Buffer")
    var
        Item2: Record Item;
        Window: Dialog;
        IsHandled: Boolean;
    begin
        Item2.Copy(Item);

        CheckCalculatePer(Item2);

        if Item2.FindSet() then begin
            if ShowDialog then
                Window.Open(Text004, Item2."No.");
            repeat
                if ShowDialog then
                    Window.Update(1, Item2."No.");

                IsHandled := false;
                OnBeforeFindOpenOutboundEntry(Item2, PostingDate, TestMode, TempErrorBuf, ErrorCounter, IsHandled);
                if not IsHandled then begin
                    if FindOpenOutboundEntry(Item2) then
                        if not TestMode then
                            Error(Text018, Item2."No.");
                    if not CheckAdjusted(Item2) then
                        AddError(
                          StrSubstNo(Text007, Item2."No."), DATABASE::Item, Item2."No.", 0);
                end;
            until Item2.Next() = 0;
            if ShowDialog then
                Window.Close();
        end;

        TempErrorBuf.Reset();
        if TempErrorBuf.FindSet() then
            repeat
                NewErrorBuf := TempErrorBuf;
                NewErrorBuf.Insert();
            until TempErrorBuf.Next() = 0;
    end;

    local procedure CheckAdjusted(Item: Record Item): Boolean
    var
        AvgCostEntryPointHandler: Codeunit "Avg. Cost Entry Point Handler";
        IsAdjusted: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAdjusted(Item, IsAdjusted, IsHandled);
        if IsHandled then
            exit(IsAdjusted);

        if Item."Costing Method" = Item."Costing Method"::Average then
            exit(AvgCostEntryPointHandler.IsEntriesAdjusted(Item."No.", PostingDate));

        exit(true);
    end;

    local procedure CheckCalculatePer(var Item: Record Item)
    var
        Item2: Record Item;
    begin
        Item2.CopyFilters(Item);

        Item2.FilterGroup(2);
        Item2.SetRange("Costing Method", Item2."Costing Method"::Average);
        Item2.FilterGroup(0);

        OnCheckCalculatePerOnAfterSetFilters(Item2, Item, PostingDate);

        if Item2.FindFirst() then
            case CalculatePer of
                CalculatePer::"Item Ledger Entry":
                    AddError(
                      StrSubstNo(Text009, Item2."Costing Method"), DATABASE::Item, Item2."No.", 0);
                CalculatePer::Item:
                    if InvtSetup."Average Cost Calc. Type" = InvtSetup."Average Cost Calc. Type"::Item then begin
                        if Item2.GetFilter("Location Filter") <> '' then
                            AddError(
                                StrSubstNo(
                                Text011,
                                Item2.FieldCaption("Location Filter"), Item2."Costing Method", InvtSetup."Average Cost Calc. Type"), DATABASE::Item, Item2."No.", 0);
                        if Item2.GetFilter("Variant Filter") <> '' then
                            AddError(
                                StrSubstNo(
                                Text011,
                                Item2.FieldCaption("Variant Filter"), Item2."Costing Method", InvtSetup."Average Cost Calc. Type"), DATABASE::Item, Item2."No.", 0);
                        if ByLocation then
                            AddError(
                                StrSubstNo(
                                Text012,
                                Item2."Costing Method", InvtSetup."Average Cost Calc. Type"), DATABASE::Item, Item2."No.", 0);
                        if ByVariant then
                            AddError(
                                StrSubstNo(
                                Text014,
                                Item2."Costing Method", InvtSetup."Average Cost Calc. Type"), DATABASE::Item, Item2."No.", 0);
                    end else
                        CheckItemLocationVariantFilters(Item2);
            end;

        OnAfterCheckCalculatePer(Item);
    end;

    local procedure FindOpenOutboundEntry(var Item: Record Item) Result: Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindOpenOutboundEntry2(Item, Result, IsHandled);
        if IsHandled then
            exit(Result);

        ItemLedgEntry.Reset();
        ItemLedgEntry.SetCurrentKey("Item No.", Open, "Variant Code", Positive, "Location Code", "Posting Date", "Entry No.");
        ItemLedgEntry.SetRange("Item No.", Item."No.");
        ItemLedgEntry.SetRange(Open, true);
        ItemLedgEntry.SetRange(Positive, false);
        ItemLedgEntry.SetRange("Posting Date", 0D, PostingDate);

        Item.CopyFilter("Variant Filter", ItemLedgEntry."Variant Code");
        Item.CopyFilter("Location Filter", ItemLedgEntry."Location Code");

        if ItemLedgEntry.FindSet() then begin
            repeat
                AddError(
                  StrSubstNo(Text020, ItemLedgEntry."Entry No."),
                  DATABASE::"Item Ledger Entry", ItemLedgEntry."Item No.", ItemLedgEntry."Entry No.");
            until ItemLedgEntry.Next() = 0;
            exit(true);
        end;

        exit(false);
    end;

    local procedure AddError(Text: Text; SourceTable: Integer; SourceNo: Code[20]; SourceRefNo: Integer)
    begin
        if TestMode then begin
            ErrorCounter := ErrorCounter + 1;
            TempErrorBuf.Init();
            TempErrorBuf."Error No." := ErrorCounter;
            TempErrorBuf."Error Text" := CopyStr(Text, 1, MaxStrLen(TempErrorBuf."Error Text"));
            TempErrorBuf."Source Table" := SourceTable;
            TempErrorBuf."Source No." := SourceNo;
            TempErrorBuf."Source Ref. No." := SourceRefNo;
            TempErrorBuf.Insert();
        end else
            Error(Text);
    end;

    local procedure CheckItemLocationVariantFilters(var Item: Record Item)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemLocationVariantFilters(Item, TempErrorBuf, ErrorCounter, TestMode, ByLocation, ByVariant, IsHandled);
        if IsHandled then
            exit;

        if ((Item.GetFilter("Location Filter") = '') and (not ByLocation)) or
           ((Item.GetFilter("Variant Filter") = '') and (not ByVariant))
        then
            AddError(StrSubstNo(Text015, Item."Costing Method", InvtSetup."Average Cost Calc. Type"), DATABASE::Item, Item."No.", 0);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckCalculatePer(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAdjusted(Item: Record Item; var IsAdjusted: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindOpenOutboundEntry(Item: Record Item; PostingDate: Date; TestMode: Boolean; var TempErrorBuffer: Record "Error Buffer" temporary; var ErrorCounter: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCalculatePerOnAfterSetFilters(var Item2: Record Item; var Item: Record Item; PostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemLocationVariantFilters(var Item: Record Item; var TempErrorBuf: Record "Error Buffer" temporary; var ErrorCounter: Integer; TestMode: Boolean; ByLocation: Boolean; ByVariant: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindOpenOutboundEntry2(var Item: Record Item; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}
