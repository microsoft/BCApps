// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Purchases.Setup;

codeunit 5005271 "Create Delivery Reminder"
{

    trigger OnRun()
    begin
    end;

    var
        Text1140000: Label 'There is not enough space to insert the text.';
        DeliveryReminderLine: Record "Delivery Reminder Line";
        DeliveryReminderLevel: Record "Delivery Reminder Level";
        DeliveryReminderText: Record "Delivery Reminder Text";
        PurchaseSetup: Record "Purchases & Payables Setup";
        LineOffset: Integer;
        NextLineNo: Integer;
        OK: Boolean;
        RemindingDate: Date;
        LineLevel: Integer;
        MaxLineLevel: Integer;

    procedure Remind(PurchLine: Record "Purchase Line"; DeliveryReminderTerms: Record "Delivery Reminder Term"; var DeliveryReminderLevel: Record "Delivery Reminder Level"; DateOfTheCurrentDay: Date) RetValue: Boolean
    var
        DelivReminLedgerEntries: Record "Delivery Reminder Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRemind(PurchLine, DeliveryReminderTerms, DeliveryReminderLevel, DateOfTheCurrentDay, LineLevel, RetValue, IsHandled);
        if IsHandled then
            exit(RetValue);

        PurchaseSetup.Get();
        PurchaseSetup.TestField("Default Del. Rem. Date Field");
        case PurchaseSetup."Default Del. Rem. Date Field" of
            PurchaseSetup."Default Del. Rem. Date Field"::"Requested Receipt Date":
                RemindingDate := PurchLine."Requested Receipt Date";
            PurchaseSetup."Default Del. Rem. Date Field"::"Promised Receipt Date":
                RemindingDate := PurchLine."Promised Receipt Date";
            PurchaseSetup."Default Del. Rem. Date Field"::"Expected Receipt Date":
                RemindingDate := PurchLine."Expected Receipt Date";
        end;

        if (RemindingDate = 0D) or (RemindingDate >= DateOfTheCurrentDay) then
            exit(false);
        if PurchLine."Outstanding Quantity" <= 0 then
            exit(false);

        MaxLineLevel := 0;
        DelivReminLedgerEntries.Reset();
        DelivReminLedgerEntries.SetCurrentKey("Order No.", "Order Line No.", "Posting Date");
        DelivReminLedgerEntries.SetRange("Order No.", PurchLine."Document No.");
        DelivReminLedgerEntries.SetRange("Order Line No.", PurchLine."Line No.");
        OnRemindOnAfterDelivReminLedgerEntriesSetFilters(DelivReminLedgerEntries);
        if DelivReminLedgerEntries.FindLast() then begin
            RemindingDate := DelivReminLedgerEntries."Document Date";
            LineLevel := DelivReminLedgerEntries."Reminder Level" + 1
        end else
            LineLevel := 1;

        if LineLevel > MaxLineLevel then
            MaxLineLevel := LineLevel;

        if (MaxLineLevel > DeliveryReminderTerms."Max. No. of Delivery Reminders")
           and (DeliveryReminderTerms."Max. No. of Delivery Reminders" <> 0)
        then
            exit(false);

        DeliveryReminderLevel.SetRange("Reminder Terms Code", DeliveryReminderTerms.Code);
        DeliveryReminderLevel.SetRange("No.", 1, MaxLineLevel);
        if not DeliveryReminderLevel.Find('+') then
            DeliveryReminderLevel.Init();

        exit(CalcDate(DeliveryReminderLevel."Due Date Calculation", RemindingDate) < DateOfTheCurrentDay);
    end;

    procedure CreateDelivReminHeader(var DeliveryReminderHeader: Record "Delivery Reminder Header"; PurchHeader: Record "Purchase Header"; DeliveryReminderTerms: Record "Delivery Reminder Term"; DeliveryReminderLevel: Record "Delivery Reminder Level"; DateOfTheCurrentDay: Date)
    begin
        DeliveryReminderHeader.Init();
        DeliveryReminderHeader."No." := '';
        DeliveryReminderHeader.Insert(true);
        DeliveryReminderHeader.Validate("Vendor No.", PurchHeader."Buy-from Vendor No.");
        DeliveryReminderHeader."Posting Date" := WorkDate();
        DeliveryReminderHeader."Document Date" := WorkDate();
        OnCreateDelivReminHeaderOnBeforeDeliveryReminderHeaderModify(DeliveryReminderHeader, PurchHeader);
        DeliveryReminderHeader.Modify();
        OnCreateDelivReminHeaderOnAfterDeliveryReminderHeaderModify(DeliveryReminderHeader, PurchHeader);
    end;

    procedure CreateDelivRemindLine(DeliveryReminderHeader: Record "Delivery Reminder Header"; PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; DeliveryReminderTerms: Record "Delivery Reminder Term"; DeliveryReminderLevel: Record "Delivery Reminder Level"; DateOfTheCurrentDay: Date)
    var
        DeliveryReminderLine: Record "Delivery Reminder Line";
        NextLineNo: Integer;
        IsHandled: Boolean;
    begin
        PurchaseSetup.Get();
        PurchaseSetup.TestField("Default Del. Rem. Date Field");

        IsHandled := false;
        OnCreateDelivRemindLineOnBeforeSetNextLineNo(DeliveryReminderHeader, PurchHeader, IsHandled);
        if IsHandled then
            exit;

        DeliveryReminderLine.Reset();
        DeliveryReminderLine.SetRange("Document No.", DeliveryReminderHeader."No.");
        if DeliveryReminderLine.FindLast() then
            NextLineNo := DeliveryReminderLine."Line No." + 10000
        else
            NextLineNo := 10000;

        DeliveryReminderLine.Init();
        DeliveryReminderLine."Document No." := DeliveryReminderHeader."No.";
        DeliveryReminderLine."Line No." := NextLineNo;
        DeliveryReminderLine."Order No." := PurchLine."Document No.";
        DeliveryReminderLine."Order Line No." := PurchLine."Line No.";
        DeliveryReminderLine.Type := PurchLine.Type.AsInteger();
        DeliveryReminderLine."No." := PurchLine."No.";
        DeliveryReminderLine.Description := PurchLine.Description;
        DeliveryReminderLine."Description 2" := PurchLine."Description 2";
        DeliveryReminderLine."Vendor Item No." := PurchLine."Vendor Item No.";
        DeliveryReminderLine."Unit of Measure" := PurchLine."Unit of Measure";
        DeliveryReminderLine."Reorder Quantity" := PurchLine.Quantity;
        DeliveryReminderLine."Remaining Quantity" := PurchLine."Outstanding Quantity";
        DeliveryReminderLine.Quantity := PurchLine."Outstanding Quantity";
        DeliveryReminderLine.Validate("Reminder Level", LineLevel);
        DeliveryReminderLine."Order Date" := PurchHeader."Order Date";
        DeliveryReminderLine."Requested Receipt Date" := PurchLine."Requested Receipt Date";
        DeliveryReminderLine."Promised Receipt Date" := PurchLine."Promised Receipt Date";
        DeliveryReminderLine."Expected Receipt Date" := PurchLine."Expected Receipt Date";
        DeliveryReminderLine."Del. Rem. Date Field" := PurchaseSetup."Default Del. Rem. Date Field";
        case DeliveryReminderLine."Del. Rem. Date Field" of
            DeliveryReminderLine."Del. Rem. Date Field"::"Requested Receipt Date":
                if PurchLine."Requested Receipt Date" <> 0D then
                    DeliveryReminderLine."Days overdue" := DateOfTheCurrentDay - PurchLine."Requested Receipt Date";
            DeliveryReminderLine."Del. Rem. Date Field"::"Promised Receipt Date":
                if PurchLine."Promised Receipt Date" <> 0D then
                    DeliveryReminderLine."Days overdue" := DateOfTheCurrentDay - PurchLine."Promised Receipt Date";
            DeliveryReminderLine."Del. Rem. Date Field"::"Expected Receipt Date":
                if PurchLine."Expected Receipt Date" <> 0D then
                    DeliveryReminderLine."Days overdue" := DateOfTheCurrentDay - PurchLine."Expected Receipt Date";
        end;
        OnBeforeDeliveryReminderLineInsert(DeliveryReminderLine, PurchLine);
        DeliveryReminderLine.Insert();
        OnAfterDeliveryReminderLineInsert(DeliveryReminderLine, PurchLine);
    end;

    procedure HeaderReminderLevelRefresh(var DeliveryReminderHeader: Record "Delivery Reminder Header")
    var
        DeliveryReminderLine: Record "Delivery Reminder Line";
    begin
        DeliveryReminderHeader."Reminder Level" := 0;
        DeliveryReminderLine.Reset();
        DeliveryReminderLine.SetRange("Document No.", DeliveryReminderHeader."No.");
        if DeliveryReminderLine.Find('-') then
            repeat
                if DeliveryReminderLine."Reminder Level" > DeliveryReminderHeader."Reminder Level" then
                    DeliveryReminderHeader."Reminder Level" := DeliveryReminderLine."Reminder Level";
            until DeliveryReminderLine.Next() = 0;
        DeliveryReminderHeader.Validate("Reminder Level");
        DeliveryReminderHeader.Modify();
    end;

    procedure SuggestLines(var DeliveryReminderHeader: Record "Delivery Reminder Header")
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        DeliveryReminderTerms: Record "Delivery Reminder Term";
        DeliveryReminderLevel: Record "Delivery Reminder Level";
        DateOfTheCurrentDay: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSuggestLines(DeliveryReminderHeader, IsHandled);
        if IsHandled then
            exit;
        DeliveryReminderHeader.TestField("Vendor No.");
        DeliveryReminderHeader.TestField("Reminder Terms Code");
        DeliveryReminderTerms.Get(DeliveryReminderHeader."Reminder Terms Code");
        DateOfTheCurrentDay := WorkDate();

        PurchHeader.Reset();
        PurchHeader.SetCurrentKey("Document Type", "Buy-from Vendor No.");
        PurchHeader.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchHeader.SetRange("Buy-from Vendor No.", DeliveryReminderHeader."Vendor No.");
        OnSuggestLinesOnAfterPurchHeaderSetFilters(PurchHeader, DeliveryReminderHeader);
        if PurchHeader.Find('-') then
            repeat
                PurchLine.Reset();
                PurchLine.SetRange("Document No.", PurchHeader."No.");
                if PurchLine.Find('-') then
                    repeat
                        if Remind(PurchLine, DeliveryReminderTerms, DeliveryReminderLevel, DateOfTheCurrentDay) then
                            CreateDelivRemindLine(DeliveryReminderHeader, PurchHeader, PurchLine, DeliveryReminderTerms, DeliveryReminderLevel,
                              DateOfTheCurrentDay);
                    until PurchLine.Next() = 0;
            until PurchHeader.Next() = 0;

        HeaderReminderLevelRefresh(DeliveryReminderHeader);
        InsertBeginTexts(DeliveryReminderHeader);
        InsertEndTexts(DeliveryReminderHeader);
    end;

    procedure UpdateLines(DeliveryReminder: Record "Delivery Reminder Header")
    begin
        DeliveryReminderLine.Reset();
        DeliveryReminderLine.SetRange("Document No.", DeliveryReminder."No.");
        OK := DeliveryReminderLine.Find('-');
        while OK do begin
            OK :=
              (DeliveryReminderLine.Type = DeliveryReminderLine.Type::" ") and
              (DeliveryReminderLine."Attached to Line No." = 0);
            if OK then begin
                DeliveryReminderLine.Delete(true);
                OK := DeliveryReminderLine.Next() <> 0;
            end;
        end;
        OK := DeliveryReminderLine.Find('+');
        while OK do begin
            OK :=
              (DeliveryReminderLine.Type = DeliveryReminderLine.Type::" ") and
              (DeliveryReminderLine."Attached to Line No." = 0);
            if OK then begin
                DeliveryReminderLine.Delete(true);
                OK := DeliveryReminderLine.Next(-1) <> 0;
            end;
        end;

        InsertBeginTexts(DeliveryReminder);
        InsertEndTexts(DeliveryReminder);
    end;

    local procedure InsertBeginTexts(DeliveryReminder: Record "Delivery Reminder Header")
    begin
        DeliveryReminderLevel.SetRange("Reminder Terms Code", DeliveryReminder."Reminder Terms Code");
        DeliveryReminderLevel.SetRange("No.", 1, DeliveryReminder."Reminder Level");
        if DeliveryReminderLevel.FindLast() then begin
            DeliveryReminderText.Reset();
            DeliveryReminderText.SetRange("Reminder Terms Code", DeliveryReminder."Reminder Terms Code");
            DeliveryReminderText.SetRange("Reminder Level", DeliveryReminderLevel."No.");
            DeliveryReminderText.SetRange(Position, DeliveryReminderText.Position::Beginning);

            DeliveryReminderLine.Reset();
            DeliveryReminderLine.SetRange("Document No.", DeliveryReminder."No.");
            DeliveryReminderLine."Document No." := DeliveryReminder."No.";
            if DeliveryReminderLine.Find('-') then begin
                LineOffset := DeliveryReminderLine."Line No." div (DeliveryReminderText.Count + 2);
                if LineOffset = 0 then
                    Error(Text1140000);
            end else
                LineOffset := 10000;
            NextLineNo := 0;
            InsertTextLines(DeliveryReminder);
        end;
    end;

    local procedure InsertEndTexts(DeliveryReminder: Record "Delivery Reminder Header")
    begin
        DeliveryReminderLevel.SetRange("Reminder Terms Code", DeliveryReminder."Reminder Terms Code");
        DeliveryReminderLevel.SetRange("No.", 1, DeliveryReminder."Reminder Level");
        if DeliveryReminderLevel.FindLast() then begin
            DeliveryReminderText.SetRange("Reminder Terms Code", DeliveryReminder."Reminder Terms Code");
            DeliveryReminderText.SetRange("Reminder Level", DeliveryReminderLevel."No.");
            DeliveryReminderText.SetRange(Position, DeliveryReminderText.Position::Ending);
            DeliveryReminderLine.Reset();
            DeliveryReminderLine.SetRange("Document No.", DeliveryReminder."No.");
            DeliveryReminderLine."Document No." := DeliveryReminder."No.";
            if DeliveryReminderLine.Find('+') then
                NextLineNo := DeliveryReminderLine."Line No."
            else
                NextLineNo := 0;
            LineOffset := 10000;
            InsertTextLines(DeliveryReminder);
        end;
    end;

    local procedure InsertTextLines(DeliveryReminder: Record "Delivery Reminder Header")
    begin
        if DeliveryReminderText.FindSet() then begin
            if DeliveryReminderText.Position = DeliveryReminderText.Position::Ending then
                InsertBlankLine();
            repeat
                NextLineNo := NextLineNo + LineOffset;
                DeliveryReminderLine.Init();
                DeliveryReminderLine."Line No." := NextLineNo;
                DeliveryReminderLine.Type := DeliveryReminderLine.Type::" ";
                DeliveryReminderLine.Description :=
                  CopyStr(
                    StrSubstNo(
                      DeliveryReminderText.Description,
                      DeliveryReminder."Document Date",
                      DeliveryReminder."Due Date",
                      DeliveryReminder."Reminder Terms Code"),
                    1,
                    MaxStrLen(DeliveryReminderLine.Description));
                OnBeforeDeliveryReminderTextLineInsert(DeliveryReminderLine, DeliveryReminderText);
                DeliveryReminderLine.Insert();
            until DeliveryReminderText.Next() = 0;
            if DeliveryReminderText.Position = DeliveryReminderText.Position::Beginning then
                InsertBlankLine();
        end;
    end;

    procedure InsertBlankLine()
    begin
        NextLineNo := NextLineNo + LineOffset;
        DeliveryReminderLine.Init();
        DeliveryReminderLine."Line No." := NextLineNo;
        DeliveryReminderLine.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeliveryReminderLineInsert(var DeliveryReminderLine: Record "Delivery Reminder Line"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeliveryReminderLineInsert(var DeliveryReminderLine: Record "Delivery Reminder Line"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeliveryReminderTextLineInsert(var DeliveryReminderLine: Record "Delivery Reminder Line"; DeliveryReminderText: Record "Delivery Reminder Text")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRemind(PurchaseLine: Record "Purchase Line"; DeliveryReminderTerm: Record "Delivery Reminder Term"; var DeliveryReminderLevel: Record "Delivery Reminder Level"; DateOfTheCurrentDay: Date; var LineLevel: Integer; var RetValue: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateDelivReminHeaderOnAfterDeliveryReminderHeaderModify(var DeliveryReminderHeader: Record "Delivery Reminder Header"; PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateDelivReminHeaderOnBeforeDeliveryReminderHeaderModify(var DeliveryReminderHeader: Record "Delivery Reminder Header"; PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSuggestLinesOnAfterPurchHeaderSetFilters(var PurchHeader: Record "Purchase Header"; DeliveryReminderHeader: Record "Delivery Reminder Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRemindOnAfterDelivReminLedgerEntriesSetFilters(var DelivReminLedgerEntries: Record "Delivery Reminder Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSuggestLines(var DeliveryReminderHeader: Record "Delivery Reminder Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateDelivRemindLineOnBeforeSetNextLineNo(DeliveryReminderHeader: Record "Delivery Reminder Header"; PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;
}

