// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Foundation.Period;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Setup;

codeunit 5810 "Change Average Cost Setting"
{
    TableNo = "Inventory Setup";

    trigger OnRun()
    begin
        WindowUpdateDateTime := CurrentDateTime;
        WindowIsOpen := false;

        AvgCostEntryPointHandler.LockBuffer();
        Rec.LockTable();
        AccPeriod.LockTable();

        Rec.Modify();

        if AccPeriod.IsEmpty() then
            StartingValuationDate := CalcDate('<-CY>', WorkDate())
        else begin
            AccPeriod.SetRange("New Fiscal Year", true);
            AccPeriod.Find('-');
            if AccPeriod.Closed then begin
                AccPeriod.SetRange(Closed, false);
                AccPeriod.Find('-');
                StartingValuationDate := AccPeriod."Starting Date";
            end;
            repeat
                AccPeriod."Average Cost Period" := Rec."Average Cost Period";
                AccPeriod."Average Cost Calc. Type" := Rec."Average Cost Calc. Type";
                AccPeriod.Modify();
            until AccPeriod.Next() = 0;
        end;

        ProcessItemsFromDate(StartingValuationDate);

        if WindowIsOpen then
            Window.Close();

        Commit();
    end;

    var
        AccPeriod: Record "Accounting Period";
        ValueEntry: Record "Value Entry";
        Item: Record Item;
        InvtSetup: Record "Inventory Setup";
        AvgCostEntryPointHandler: Codeunit "Avg. Cost Entry Point Handler";
        Window: Dialog;
        StartingValuationDate: Date;
        WindowIsOpen: Boolean;
        WindowNo: Text[20];
        WindowPostingDate: Date;
        WindowUpdateDateTime: DateTime;
#pragma warning disable AA0074
        Text000: Label 'Processing Item...\\';
#pragma warning disable AA0470
        Text001: Label 'Item No.       #1######\';
        Text002: Label 'Valuation Date #2######';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure UpdateAvgCostFromAccPeriodChg(AccPeriod: Record "Accounting Period")
    var
        StartingValuationDate: Date;
    begin
        if not InvtSetup.Get() then
            exit;

        if not (AccPeriod."New Fiscal Year" or
                (InvtSetup."Average Cost Period" = InvtSetup."Average Cost Period"::"Accounting Period"))
        then
            exit;

        StartingValuationDate := 0D;

        if AccPeriod.Next(-1) <> 0 then
            StartingValuationDate := AccPeriod."Starting Date";
        ProcessItemsFromDate(StartingValuationDate);
    end;

    local procedure ProcessItemsFromDate(StartingValuationDate: Date)
    begin
        if Item.Find('-') then
            repeat
                if Item."Costing Method" = Item."Costing Method"::Average then
                    ProcessItemAvgCostPoint(Item, StartingValuationDate);
            until Item.Next() = 0;
    end;

    local procedure ProcessItemAvgCostPoint(var Item: Record Item; StartingValuationDate: Date)
    begin
        InvtSetup.Get();

        AvgCostEntryPointHandler.DeleteBuffer(Item."No.", StartingValuationDate);

        ValueEntry.Reset();
        ValueEntry.SetCurrentKey("Item No.", "Valuation Date", "Location Code", "Variant Code", "Entry No.");

        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.SetFilter("Valuation Date", '>=%1', StartingValuationDate);
        if ValueEntry.Find('-') then begin
            repeat
                UpDateWindow(ValueEntry."Item No.", ValueEntry."Valuation Date");

                AvgCostEntryPointHandler.UpdateValuationDate(ValueEntry);

                ValueEntry.SetRange("Valuation Date", ValueEntry."Valuation Date");
                if InvtSetup."Average Cost Calc. Type" =
                   InvtSetup."Average Cost Calc. Type"::"Item & Location & Variant"
                then begin
                    ValueEntry.SetRange("Location Code", ValueEntry."Location Code");
                    ValueEntry.SetRange("Variant Code", ValueEntry."Variant Code");
                end;
                OnProcessItemAvgCostPointOnBeforeFindLastValueEntry(ValueEntry);
                if ValueEntry.Find('+') then;
                ValueEntry.SetRange("Valuation Date");
                ValueEntry.SetRange("Location Code");
                ValueEntry.SetRange("Variant Code");
            until ValueEntry.Next() = 0;
            Item."Cost is Adjusted" := false;
            Item.Modify();
        end;
    end;

    local procedure OpenWindow()
    begin
        Window.Open(
          Text000 +
          Text001 +
          Text002);
        WindowIsOpen := true;
        WindowUpdateDateTime := CurrentDateTime;
    end;

    local procedure UpDateWindow(NewWindowNo: Code[20]; NewWindowPostingDate: Date)
    begin
        WindowNo := NewWindowNo;
        WindowPostingDate := NewWindowPostingDate;

        if IsTimeForUpdate() then begin
            if not WindowIsOpen then
                OpenWindow();
            Window.Update(1, WindowNo);
            Window.Update(2, WindowPostingDate);
        end;
    end;

    local procedure IsTimeForUpdate(): Boolean
    begin
        if WindowUpdateDateTime = 0DT then
            WindowUpdateDateTime := CurrentDateTime;
        if CurrentDateTime - WindowUpdateDateTime >= 1000 then begin
            WindowUpdateDateTime := CurrentDateTime;
            exit(true);
        end;
        exit(false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Accounting Period", 'OnAfterDeleteEvent', '', false, false)]
    local procedure UpdateAvgCostOnAfterDeleteAccountingPeriod(var Rec: Record "Accounting Period"; RunTrigger: Boolean)
    begin
        if not RunTrigger or Rec.IsTemporary then
            exit;

        UpdateAvgCostFromAccPeriodChg(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Accounting Period", 'OnAfterInsertEvent', '', false, false)]
    local procedure UpdateAvgCostOnAfterInsertAccountingPeriod(var Rec: Record "Accounting Period"; RunTrigger: Boolean)
    begin
        if not RunTrigger or Rec.IsTemporary then
            exit;

        UpdateAvgCostFromAccPeriodChg(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Accounting Period", 'OnAfterModifyEvent', '', false, false)]
    local procedure UpdateAvgCostOnAfterModifyAccountingPeriod(var Rec: Record "Accounting Period"; var xRec: Record "Accounting Period"; RunTrigger: Boolean)
    begin
        if not RunTrigger or Rec.IsTemporary then
            exit;

        UpdateAvgCostFromAccPeriodChg(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Accounting Period", 'OnAfterRenameEvent', '', false, false)]
    local procedure UpdateAvgCostOnAfterRenameAccountingPeriod(var Rec: Record "Accounting Period"; var xRec: Record "Accounting Period"; RunTrigger: Boolean)
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        if not RunTrigger or Rec.IsTemporary then
            exit;

        if not (Rec."New Fiscal Year" or xRec."New Fiscal Year") then
            exit;

        if (xRec."Starting Date" < Rec."Starting Date") and (xRec."Starting Date" <> 0D) then
            AccountingPeriod := xRec
        else
            AccountingPeriod := Rec;

        UpdateAvgCostFromAccPeriodChg(AccountingPeriod);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessItemAvgCostPointOnBeforeFindLastValueEntry(var ValueEntry: Record "Value Entry")
    begin
    end;
}

