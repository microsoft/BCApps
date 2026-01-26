// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.ExtendedText;

codeunit 5005272 "Deliv.-Rem. Ext. Text Transfer"
{

    trigger OnRun()
    begin
    end;

    var
        Text1140000: Label 'There is not enough space to insert extended text lines.';
        GLAcc: Record "G/L Account";
        TmpExtTextLine: Record "Extended Text Line" temporary;
        NextLineNo: Integer;
        LineSpacing: Integer;
        MakeUpdateRequired: Boolean;
        AutoText: Boolean;

    procedure ReminderCheckIfAnyExtText(var DeliveryReminderLine: Record "Delivery Reminder Line"; Unconditionally: Boolean): Boolean
    var
        DeliveryReminder: Record "Delivery Reminder Header";
        ExtTextHeader: Record "Extended Text Header";
    begin
        MakeUpdateRequired := false;
        if DeliveryReminderLine."Line No." <> 0 then
            MakeUpdateRequired := DeleteDellivReminLine(DeliveryReminderLine);

        if Unconditionally then
            AutoText := true
        else
            case DeliveryReminderLine.Type of
                DeliveryReminderLine.Type::" ":
                    AutoText := true;
                DeliveryReminderLine.Type::"Account (G/L)":
                    if GLAcc.Get(DeliveryReminderLine."No.") then
                        AutoText := GLAcc."Automatic Ext. Texts";
            end;

        OnReminderCheckIfAnyExtTextOnBeforeReadLinesAutoText(DeliveryReminderLine, AutoText, Unconditionally);
        if AutoText then begin
            DeliveryReminderLine.TestField("Document No.");
            DeliveryReminder.Get(DeliveryReminderLine."Document No.");
            ExtTextHeader.SetRange("Table Name", DeliveryReminderLine.Type);
            ExtTextHeader.SetRange("No.", DeliveryReminderLine."No.");
            ExtTextHeader.SetRange("Delivery Reminder", true);
            OnReminderCheckIfAnyExtTextOnBeforeReadLinesForAutoText(ExtTextHeader, DeliveryReminder, DeliveryReminderLine, Unconditionally, MakeUpdateRequired);
            exit(ReadLines(ExtTextHeader, DeliveryReminder."Document Date", DeliveryReminder."Language Code"));
        end;
    end;

    procedure DelivReminInsertExtendedText(var DeliveryReminderLine: Record "Delivery Reminder Line")
    var
        ForDeliveryReminderLine: Record "Delivery Reminder Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDelivReminInsertExtendedText(DeliveryReminderLine, TmpExtTextLine, IsHandled, MakeUpdateRequired);
        if IsHandled then
            exit;

        ForDeliveryReminderLine.Reset();
        ForDeliveryReminderLine.SetRange("Document No.", DeliveryReminderLine."Document No.");
        ForDeliveryReminderLine := DeliveryReminderLine;
        if ForDeliveryReminderLine.Find('>') then begin
            LineSpacing :=
              (ForDeliveryReminderLine."Line No." - DeliveryReminderLine."Line No.") div
              (1 + TmpExtTextLine.Count);
            if LineSpacing = 0 then
                Error(Text1140000);
        end else
            LineSpacing := 10000;

        NextLineNo := DeliveryReminderLine."Line No." + LineSpacing;

        TmpExtTextLine.Reset();
        if TmpExtTextLine.Find('-') then begin
            repeat
                ForDeliveryReminderLine.Init();
                ForDeliveryReminderLine."Document No." := DeliveryReminderLine."Document No.";
                ForDeliveryReminderLine."Line No." := NextLineNo;
                NextLineNo := NextLineNo + LineSpacing;
                ForDeliveryReminderLine.Description := TmpExtTextLine.Text;
                ForDeliveryReminderLine."Attached to Line No." := DeliveryReminderLine."Line No.";

                OnDelivReminInsertExtendedTextOnBeforeInsertForDeliveryReminderLine(ForDeliveryReminderLine, DeliveryReminderLine, TmpExtTextLine, NextLineNo, LineSpacing);
                ForDeliveryReminderLine.Insert();
            until TmpExtTextLine.Next() = 0;
            MakeUpdateRequired := true;
        end;
        TmpExtTextLine.DeleteAll();
    end;

    procedure DeleteDellivReminLine(var DeliveryReminderLine: Record "Delivery Reminder Line"): Boolean
    var
        DeliveryReminderLine2: Record "Delivery Reminder Line";
    begin
        DeliveryReminderLine2.SetRange("Document No.", DeliveryReminderLine."Document No.");
        DeliveryReminderLine2.SetRange("Attached to Line No.", DeliveryReminderLine."Line No.");

        OnDeleteDellivReminLineOnAfterSetFilters(DeliveryReminderLine2, DeliveryReminderLine);
        DeliveryReminderLine2 := DeliveryReminderLine;
        if DeliveryReminderLine2.Find('>') then begin
            repeat
                DeliveryReminderLine2.Delete();
            until DeliveryReminderLine2.Next() = 0;
            exit(true);
        end;
    end;

    procedure MakeUpdate(): Boolean
    begin
        exit(MakeUpdateRequired);
    end;

    procedure ReadLines(var ExtTextHeader: Record "Extended Text Header"; DocDate: Date; LanguageCode: Code[10]): Boolean
    var
        ExtTextLine: Record "Extended Text Line";
        IsHandled, Result : Boolean;
    begin
        IsHandled := false;
        Result := false;
        OnBeforeReadLines(ExtTextHeader, DocDate, LanguageCode, IsHandled, Result, TmpExtTextLine);
        if IsHandled then
            exit(Result);

        ExtTextHeader.SetCurrentKey(
          "Table Name", "No.", "Language Code", "All Language Codes", "Starting Date", "Ending Date");
        ExtTextHeader.SetRange("Starting Date", 0D, DocDate);
        ExtTextHeader.SetFilter("Ending Date", '%1..|%2', DocDate, 0D);
        if LanguageCode = '' then begin
            ExtTextHeader.SetRange("Language Code", '');
            if not ExtTextHeader.Find('+') then
                exit;
        end else begin
            ExtTextHeader.SetRange("Language Code", LanguageCode);
            if not ExtTextHeader.Find('+') then begin
                ExtTextHeader.SetRange("All Language Codes", true);
                ExtTextHeader.SetRange("Language Code", '');
                if not ExtTextHeader.Find('+') then
                    exit;
            end;
        end;

        ExtTextLine.SetRange("Table Name", ExtTextHeader."Table Name");
        ExtTextLine.SetRange("No.", ExtTextHeader."No.");
        ExtTextLine.SetRange("Language Code", ExtTextHeader."Language Code");
        ExtTextLine.SetRange("Text No.", ExtTextHeader."Text No.");
        if ExtTextLine.Find('-') then begin
            TmpExtTextLine.DeleteAll();
            repeat
                TmpExtTextLine := ExtTextLine;
                TmpExtTextLine.Insert();
            until ExtTextLine.Next() = 0;
            exit(true);
        end;
        OnAfterReadLines(TmpExtTextLine, ExtTextHeader, LanguageCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReminderCheckIfAnyExtTextOnBeforeReadLinesForAutoText(var ExtendedTextHeader: Record "Extended Text Header"; var DeliveryReminderHeader: Record "Delivery Reminder Header"; var DeliveryReminderLine: Record "Delivery Reminder Line"; Unconditionally: Boolean; var MakeUpdateRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReadLines(var TempExtendedTextLine: Record "Extended Text Line" temporary; var ExtendedTextHeader: Record "Extended Text Header"; LanguageCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReadLines(var ExtendedTextHeader: Record "Extended Text Header"; DocDate: Date; LanguageCode: Code[10]; var IsHandled: Boolean; var Result: Boolean; var TempExtendedTextLine: Record "Extended Text Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDelivReminInsertExtendedTextOnBeforeInsertForDeliveryReminderLine(var ToDeliveryReminderLine: Record "Delivery Reminder Line"; DeliveryReminderLine: Record "Delivery Reminder Line"; TempExtendedTextLine: Record "Extended Text Line" temporary; var NextLineNo: Integer; LineSpacing: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReminderCheckIfAnyExtTextOnBeforeReadLinesAutoText(var DeliveryReminderLine: Record "Delivery Reminder Line"; var AutoText: Boolean; Unconditionally: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDelivReminInsertExtendedText(var DeliveryReminderLine: Record "Delivery Reminder Line"; var TempExtTextLine: Record "Extended Text Line" temporary; var IsHandled: Boolean; var MakeUpdateRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteDellivReminLineOnAfterSetFilters(var DeliveryReminderLineToDelete: Record "Delivery Reminder Line"; FromDeliveryReminderLine: Record "Delivery Reminder Line")
    begin
    end;
}

