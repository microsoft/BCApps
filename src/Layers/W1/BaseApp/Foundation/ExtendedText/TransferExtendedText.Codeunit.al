// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.ExtendedText;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Reminder;

codeunit 378 "Transfer Extended Text"
{

    trigger OnRun()
    begin
    end;

    var
        GLAcc: Record "G/L Account";
        Item: Record Item;
        Res: Record Resource;
        TempExtTextLine: Record "Extended Text Line" temporary;
        NextLineNo: Integer;
        LineSpacing: Integer;
        MakeUpdateRequired: Boolean;
        AutoText: Boolean;

    procedure SalesCheckIfAnyExtText(var SalesLine: Record "Sales Line"; Unconditionally: Boolean): Boolean
    var
        SalesHeader: Record "Sales Header";
    begin
        exit(SalesCheckIfAnyExtText(SalesLine, Unconditionally, SalesHeader));
    end;

    procedure SalesCheckIfAnyExtText(var SalesLine: Record "Sales Line"; Unconditionally: Boolean; SalesHeader: Record "Sales Header") Result: Boolean
    var
        ExtTextHeader: Record "Extended Text Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesCheckIfAnyExtText(SalesLine, SalesHeader, Unconditionally, MakeUpdateRequired, AutoText, Result, IsHandled);
        if IsHandled then
            exit(Result);

        MakeUpdateRequired := false;
        if IsDeleteAttachedLines(SalesLine."Line No.", SalesLine."No.", SalesLine."Attached to Line No.") and not SalesLine.IsExtendedText() then
            MakeUpdateRequired := DeleteSalesLines(SalesLine);

        AutoText := false;

        if Unconditionally then
            AutoText := true
        else
            case SalesLine.Type of
                SalesLine.Type::" ":
                    AutoText := true;
                SalesLine.Type::"G/L Account":
                    if GLAcc.Get(SalesLine."No.") then
                        AutoText := GLAcc."Automatic Ext. Texts";
                SalesLine.Type::Item:
                    if Item.Get(SalesLine."No.") then
                        AutoText := Item."Automatic Ext. Texts";
                SalesLine.Type::Resource:
                    if Res.Get(SalesLine."No.") then
                        AutoText := Res."Automatic Ext. Texts";
            end;

        OnSalesCheckIfAnyExtTextOnBeforeSetFilters(SalesLine, AutoText, Unconditionally);

        if AutoText then begin
            SalesLine.TestField("Document No.");

            if SalesHeader."No." = '' then
                SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

            ExtTextHeader.SetRange("Table Name", SalesLine.Type);
            ExtTextHeader.SetRange("No.", SalesLine."No.");
            case SalesLine."Document Type" of
                SalesLine."Document Type"::Quote:
                    ExtTextHeader.SetRange("Sales Quote", true);
                SalesLine."Document Type"::"Blanket Order":
                    ExtTextHeader.SetRange("Sales Blanket Order", true);
                SalesLine."Document Type"::Order:
                    ExtTextHeader.SetRange("Sales Order", true);
                SalesLine."Document Type"::Invoice:
                    ExtTextHeader.SetRange("Sales Invoice", true);
                SalesLine."Document Type"::"Return Order":
                    ExtTextHeader.SetRange("Sales Return Order", true);
                SalesLine."Document Type"::"Credit Memo":
                    ExtTextHeader.SetRange("Sales Credit Memo", true);
            end;
            OnSalesCheckIfAnyExtTextAutoText(ExtTextHeader, SalesHeader, SalesLine, Unconditionally, MakeUpdateRequired);
            exit(ReadExtTextLines(ExtTextHeader, SalesHeader."Document Date", SalesHeader."Language Code"));
        end;
    end;

    procedure ReminderCheckIfAnyExtText(var ReminderLine: Record "Reminder Line"; Unconditionally: Boolean): Boolean
    var
        ReminderHeader: Record "Reminder Header";
        ExtTextHeader: Record "Extended Text Header";
    begin
        MakeUpdateRequired := false;
        if IsDeleteAttachedLines(ReminderLine."Line No.", ReminderLine."No.", ReminderLine."Attached to Line No.") then
            MakeUpdateRequired := DeleteReminderLines(ReminderLine);

        if Unconditionally then
            AutoText := true
        else
            case ReminderLine.Type of
                ReminderLine.Type::" ":
                    AutoText := true;
                ReminderLine.Type::"G/L Account":
                    if GLAcc.Get(ReminderLine."No.") then
                        AutoText := GLAcc."Automatic Ext. Texts";
            end;

        OnReminderCheckIfAnyExtTextOnBeforeSetFilters(ReminderLine, AutoText, Unconditionally);

        if AutoText then begin
            ReminderLine.TestField("Reminder No.");
            ReminderHeader.Get(ReminderLine."Reminder No.");
            ExtTextHeader.SetRange("Table Name", ReminderLine.Type);
            ExtTextHeader.SetRange("No.", ReminderLine."No.");
            ExtTextHeader.SetRange(Reminder, true);
            OnReminderCheckIfAnyExtTextAutoText(ExtTextHeader, ReminderHeader, ReminderLine, Unconditionally, MakeUpdateRequired);
            exit(ReadExtTextLines(ExtTextHeader, ReminderHeader."Document Date", ReminderHeader."Language Code"));
        end;
    end;

    procedure FinChrgMemoCheckIfAnyExtText(var FinChrgMemoLine: Record "Finance Charge Memo Line"; Unconditionally: Boolean): Boolean
    var
        FinChrgMemoHeader: Record "Finance Charge Memo Header";
        ExtTextHeader: Record "Extended Text Header";
    begin
        MakeUpdateRequired := false;
        if IsDeleteAttachedLines(FinChrgMemoLine."Line No.", FinChrgMemoLine."No.", FinChrgMemoLine."Attached to Line No.") then
            MakeUpdateRequired := DeleteFinChrgMemoLines(FinChrgMemoLine);

        if Unconditionally then
            AutoText := true
        else
            case FinChrgMemoLine.Type of
                FinChrgMemoLine.Type::" ":
                    AutoText := true;
                FinChrgMemoLine.Type::"G/L Account":
                    if GLAcc.Get(FinChrgMemoLine."No.") then
                        AutoText := GLAcc."Automatic Ext. Texts";
            end;

        OnFinChrgMemoCheckIfAnyExtTextOnBeforeSetFilters(FinChrgMemoLine, AutoText, Unconditionally);

        if AutoText then begin
            FinChrgMemoLine.TestField("Finance Charge Memo No.");
            FinChrgMemoHeader.Get(FinChrgMemoLine."Finance Charge Memo No.");
            ExtTextHeader.SetRange("Table Name", FinChrgMemoLine.Type);
            ExtTextHeader.SetRange("No.", FinChrgMemoLine."No.");
            ExtTextHeader.SetRange("Finance Charge Memo", true);
            OnFinChrgMemoCheckIfAnyExtTextAutoText(ExtTextHeader, FinChrgMemoHeader, FinChrgMemoLine, Unconditionally, MakeUpdateRequired);
            exit(ReadExtTextLines(ExtTextHeader, FinChrgMemoHeader."Document Date", FinChrgMemoHeader."Language Code"));
        end;
    end;

    procedure PurchCheckIfAnyExtText(var PurchaseLine: Record "Purchase Line"; Unconditionally: Boolean): Boolean
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        exit(PurchCheckIfAnyExtText(PurchaseLine, Unconditionally, PurchaseHeader));
    end;

    procedure PurchCheckIfAnyExtText(var PurchLine: Record "Purchase Line"; Unconditionally: Boolean; PurchaseHeader: Record "Purchase Header") Result: Boolean
    var
        ExtTextHeader: Record "Extended Text Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchCheckIfAnyExtText(PurchLine, PurchaseHeader, Unconditionally, MakeUpdateRequired, AutoText, Result, IsHandled);
        if IsHandled then
            exit(Result);

        MakeUpdateRequired := false;
        if IsDeleteAttachedLines(PurchLine."Line No.", PurchLine."No.", PurchLine."Attached to Line No.") and not PurchLine.IsExtendedText() then
            MakeUpdateRequired := DeletePurchLines(PurchLine);

        AutoText := false;

        if Unconditionally then
            AutoText := true
        else
            case PurchLine.Type of
                PurchLine.Type::" ":
                    AutoText := true;
                PurchLine.Type::"G/L Account":
                    if GLAcc.Get(PurchLine."No.") then
                        AutoText := GLAcc."Automatic Ext. Texts";
                PurchLine.Type::Item:
                    if Item.Get(PurchLine."No.") then
                        AutoText := Item."Automatic Ext. Texts";
                PurchLine.Type::Resource:
                    if Res.Get(PurchLine."No.") then
                        AutoText := Res."Automatic Ext. Texts";
            end;

        OnPurchCheckIfAnyExtTextOnBeforeSetFilters(PurchLine, AutoText, Unconditionally);

        if AutoText then begin
            PurchLine.TestField("Document No.");
            if PurchaseHeader."No." = '' then
                PurchaseHeader.Get(PurchLine."Document Type", PurchLine."Document No.");
            ExtTextHeader.SetRange("Table Name", PurchLine.Type);
            ExtTextHeader.SetRange("No.", PurchLine."No.");
            case PurchLine."Document Type" of
                PurchLine."Document Type"::Quote:
                    ExtTextHeader.SetRange("Purchase Quote", true);
                PurchLine."Document Type"::"Blanket Order":
                    ExtTextHeader.SetRange("Purchase Blanket Order", true);
                PurchLine."Document Type"::Order:
                    ExtTextHeader.SetRange("Purchase Order", true);
                PurchLine."Document Type"::Invoice:
                    ExtTextHeader.SetRange("Purchase Invoice", true);
                PurchLine."Document Type"::"Return Order":
                    ExtTextHeader.SetRange("Purchase Return Order", true);
                PurchLine."Document Type"::"Credit Memo":
                    ExtTextHeader.SetRange("Purchase Credit Memo", true);
            end;
            OnPurchCheckIfAnyExtTextAutoText(ExtTextHeader, PurchaseHeader, PurchLine, Unconditionally, MakeUpdateRequired);
            exit(ReadExtTextLines(ExtTextHeader, PurchaseHeader."Document Date", PurchaseHeader."Language Code"));
        end;
    end;

    procedure PrepmtGetAnyExtText(GLAccNo: Code[20]; TabNo: Integer; DocumentDate: Date; LanguageCode: Code[10]; var ExtTextLine: Record "Extended Text Line" temporary)
    var
        GLAcc: Record "G/L Account";
        ExtTextHeader: Record "Extended Text Header";
    begin
        ExtTextLine.DeleteAll();

        GLAcc.Get(GLAccNo);
        if not GLAcc."Automatic Ext. Texts" then
            exit;

        ExtTextHeader.SetRange("Table Name", ExtTextHeader."Table Name"::"G/L Account");
        ExtTextHeader.SetRange("No.", GLAccNo);
        case TabNo of
            Database::"Sales Invoice Line":
                ExtTextHeader.SetRange("Prepmt. Sales Invoice", true);
            Database::"Sales Cr.Memo Line":
                ExtTextHeader.SetRange("Prepmt. Sales Credit Memo", true);
            Database::"Purch. Inv. Line":
                ExtTextHeader.SetRange("Prepmt. Purchase Invoice", true);
            Database::"Purch. Cr. Memo Line":
                ExtTextHeader.SetRange("Prepmt. Purchase Credit Memo", true);
        end;
        OnPrepmtGetAnyExtTextBeforeReadLines(ExtTextHeader, DocumentDate, LanguageCode);
        if ReadExtTextLines(ExtTextHeader, DocumentDate, LanguageCode) then begin
            OnPrepmtGetAnyExtTextAfterReadLines(ExtTextHeader, TempExtTextLine);
            TempExtTextLine.Find('-');
            repeat
                ExtTextLine := TempExtTextLine;
                ExtTextLine.Insert();
            until TempExtTextLine.Next() = 0;
        end;
    end;

    procedure InsertSalesExtText(var SalesLine: Record "Sales Line")
    var
        DummySalesLine: Record "Sales Line";
    begin
        InsertSalesExtTextRetLast(SalesLine, DummySalesLine);
    end;

    procedure InsertSalesExtTextRetLast(var SalesLine: Record "Sales Line"; var LastInsertedSalesLine: Record "Sales Line")
    var
        ToSalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        OnBeforeInsertSalesExtText(SalesLine, TempExtTextLine, IsHandled, MakeUpdateRequired, LastInsertedSalesLine);
        if IsHandled then
            exit;

        LineSpacing := 10; // New fixed Line Spacing method
        OnInsertSalesExtTextRetLastOnAfterSetLineSpacing(LineSpacing);

        ToSalesLine.Reset();
        ToSalesLine.SetRange("Document Type", SalesLine."Document Type");
        ToSalesLine.SetRange("Document No.", SalesLine."Document No.");
        ToSalesLine := SalesLine;
        OnInsertSalesExtTextRetLastOnBeforeToSalesLineFind(ToSalesLine);

        NextLineNo := SalesLine."Line No." + LineSpacing;

        TempExtTextLine.Reset();
        OnInsertSalesExtTextRetLastOnBeforeFindTempExtTextLine(TempExtTextLine, SalesLine);
        if TempExtTextLine.Find('-') then begin
            repeat
                ToSalesLine.Init();
                ToSalesLine."Document Type" := SalesLine."Document Type";
                ToSalesLine."Document No." := SalesLine."Document No.";
                ToSalesLine."Line No." := NextLineNo;
                NextLineNo := NextLineNo + LineSpacing;
                ToSalesLine.Description := TempExtTextLine.Text;
                ToSalesLine."Attached to Line No." := SalesLine."Line No.";

                IsHandled := false;
                OnInsertSalesExtTextRetLastOnBeforeToSalesLineInsert(ToSalesLine, SalesLine, TempExtTextLine, NextLineNo, LineSpacing, IsHandled);
                if not IsHandled then
                    ToSalesLine.Insert();
            until TempExtTextLine.Next() = 0;
            MakeUpdateRequired := true;
        end;
        TempExtTextLine.DeleteAll();
        LastInsertedSalesLine := ToSalesLine;
    end;

    procedure InsertReminderExtText(var ReminderLine: Record "Reminder Line")
    var
        ToReminderLine: Record "Reminder Line";
        IsHandled: Boolean;
    begin
        OnBeforeInsertReminderExtText(ReminderLine, TempExtTextLine, IsHandled, MakeUpdateRequired);
        if IsHandled then
            exit;

        LineSpacing := 10; // New fixed Line Spacing method

        NextLineNo := ReminderLine."Line No." + LineSpacing;

        TempExtTextLine.Reset();
        OnInsertReminderExtTextOnBeforeFindTempExtTextLine(TempExtTextLine, ReminderLine);
        if TempExtTextLine.Find('-') then begin
            repeat
                ToReminderLine.Init();
                ToReminderLine."Reminder No." := ReminderLine."Reminder No.";
                ToReminderLine."Line No." := NextLineNo;
                NextLineNo := NextLineNo + LineSpacing;
                ToReminderLine.Description := TempExtTextLine.Text;
                ToReminderLine."Attached to Line No." := ReminderLine."Line No.";
                ToReminderLine."Line Type" := ReminderLine."Line Type";

                IsHandled := false;
                OnBeforeToReminderLineInsert(ToReminderLine, ReminderLine, TempExtTextLine, NextLineNo, LineSpacing, IsHandled);
                if not IsHandled then
                    ToReminderLine.Insert();
            until TempExtTextLine.Next() = 0;
            MakeUpdateRequired := true;
        end;
        TempExtTextLine.DeleteAll();
    end;

    procedure InsertFinChrgMemoExtText(var FinChrgMemoLine: Record "Finance Charge Memo Line")
    var
        ToFinChrgMemoLine: Record "Finance Charge Memo Line";
        IsHandled: Boolean;
    begin
        OnBeforeInsertFinChrgMemoExtText(FinChrgMemoLine, TempExtTextLine, IsHandled, MakeUpdateRequired);
        if IsHandled then
            exit;

        LineSpacing := 10; // New fixed Line Spacing method

        NextLineNo := FinChrgMemoLine."Line No." + LineSpacing;

        TempExtTextLine.Reset();
        if TempExtTextLine.Find('-') then begin
            repeat
                ToFinChrgMemoLine.Init();
                ToFinChrgMemoLine."Finance Charge Memo No." := FinChrgMemoLine."Finance Charge Memo No.";
                ToFinChrgMemoLine."Line No." := NextLineNo;
                NextLineNo := NextLineNo + LineSpacing;
                ToFinChrgMemoLine.Description := TempExtTextLine.Text;
                ToFinChrgMemoLine."Attached to Line No." := FinChrgMemoLine."Line No.";

                IsHandled := false;
                OnInsertFinChrgMemoExtTextOnBeforeToFinChrgMemoLineInsert(ToFinChrgMemoLine, FinChrgMemoLine, TempExtTextLine, NextLineNo, LineSpacing, IsHandled);
                if not IsHandled then
                    ToFinChrgMemoLine.Insert();
            until TempExtTextLine.Next() = 0;
            MakeUpdateRequired := true;
        end;
        TempExtTextLine.DeleteAll();
    end;

    procedure InsertPurchExtText(var PurchLine: Record "Purchase Line")
    var
        DummyPurchLine: Record "Purchase Line";
    begin
        InsertPurchExtTextRetLast(PurchLine, DummyPurchLine);
    end;

    procedure InsertPurchExtTextRetLast(var PurchLine: Record "Purchase Line"; var LastInsertedPurchLine: Record "Purchase Line")
    var
        ToPurchLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        OnBeforeInsertPurchExtText(PurchLine, TempExtTextLine, IsHandled, MakeUpdateRequired, LastInsertedPurchLine);
        if IsHandled then
            exit;

        LineSpacing := 10; // New fixed Line Spacing method

        ToPurchLine.Reset();
        ToPurchLine.SetRange("Document Type", PurchLine."Document Type");
        ToPurchLine.SetRange("Document No.", PurchLine."Document No.");
        ToPurchLine := PurchLine;
        InsertPurchExtTextRetLastOnBeforeToPurchLineFind(ToPurchLine);

        NextLineNo := PurchLine."Line No." + LineSpacing;

        TempExtTextLine.Reset();
        OnInsertPurchExtTextRetLastOnBeforeFindTempExtTextLine(TempExtTextLine, PurchLine);
        if TempExtTextLine.Find('-') then begin
            repeat
                ToPurchLine.Init();
                ToPurchLine."Document Type" := PurchLine."Document Type";
                ToPurchLine."Document No." := PurchLine."Document No.";
                ToPurchLine."Line No." := NextLineNo;
                NextLineNo := NextLineNo + LineSpacing;
                ToPurchLine.Description := TempExtTextLine.Text;
                ToPurchLine."Attached to Line No." := PurchLine."Line No.";

                IsHandled := false;
                OnBeforeToPurchLineInsert(ToPurchLine, PurchLine, TempExtTextLine, NextLineNo, LineSpacing, IsHandled);
                if not IsHandled then
                    ToPurchLine.Insert();
            until TempExtTextLine.Next() = 0;
            MakeUpdateRequired := true;
        end;
        TempExtTextLine.DeleteAll();
        LastInsertedPurchLine := ToPurchLine;
    end;

    local procedure DeleteSalesLines(var SalesLine: Record "Sales Line"): Boolean
    var
        SalesLine2: Record "Sales Line";
        IsHandled: Boolean;
        Found: Boolean;
    begin
        SalesLine2.SetRange("Document Type", SalesLine."Document Type");
        SalesLine2.SetRange("Document No.", SalesLine."Document No.");
        SalesLine2.SetRange("Attached to Line No.", SalesLine."Line No.");
        OnDeleteSalesLinesOnAfterSetFilters(SalesLine2, SalesLine);
        SalesLine2 := SalesLine;
        Found := false;
        if SalesLine2.Find('>') then begin
            repeat
                IsHandled := false;
                OnDeleteSalesLinesOnBeforeDelete(SalesLine, SalesLine2, IsHandled);
                if not IsHandled then begin
                    SalesLine2.Delete(true);
                    Found := true;
                end;
            until SalesLine2.Next() = 0;
            exit(Found);
        end;
    end;

    local procedure DeleteReminderLines(var ReminderLine: Record "Reminder Line"): Boolean
    var
        ReminderLine2: Record "Reminder Line";
    begin
        ReminderLine2.SetRange("Reminder No.", ReminderLine."Reminder No.");
        ReminderLine2.SetRange("Attached to Line No.", ReminderLine."Line No.");
        OnDeleteReminderLinesOnAfterReminderLine2SetFilters(ReminderLine2, ReminderLine);
        ReminderLine2 := ReminderLine;
        if ReminderLine2.Find('>') then begin
            repeat
                ReminderLine2.Delete();
            until ReminderLine2.Next() = 0;
            exit(true);
        end;
    end;

    local procedure DeleteFinChrgMemoLines(var FinChrgMemoLine: Record "Finance Charge Memo Line"): Boolean
    var
        FinChrgMemoLine2: Record "Finance Charge Memo Line";
    begin
        FinChrgMemoLine2.SetRange("Finance Charge Memo No.", FinChrgMemoLine."Finance Charge Memo No.");
        FinChrgMemoLine2.SetRange("Attached to Line No.", FinChrgMemoLine."Line No.");
        OnDeleteFinChrgMemoLinesOnAfterFinChrgMemoLine2SetFilters(FinChrgMemoLine2, FinChrgMemoLine);
        FinChrgMemoLine2 := FinChrgMemoLine;
        if FinChrgMemoLine2.Find('>') then begin
            repeat
                FinChrgMemoLine2.Delete();
            until FinChrgMemoLine2.Next() = 0;
            exit(true);
        end;
    end;

    local procedure DeletePurchLines(var PurchLine: Record "Purchase Line"): Boolean
    var
        PurchLine2: Record "Purchase Line";
    begin
        PurchLine2.SetRange("Document Type", PurchLine."Document Type");
        PurchLine2.SetRange("Document No.", PurchLine."Document No.");
        PurchLine2.SetRange("Attached to Line No.", PurchLine."Line No.");
        OnDeletePurchLinesOnAfterSetFilters(PurchLine2, PurchLine);
        PurchLine2 := PurchLine;
        if PurchLine2.Find('>') then begin
            repeat
                PurchLine2.Delete(true);
            until PurchLine2.Next() = 0;
            exit(true);
        end;
    end;

    procedure MakeUpdate(): Boolean
    begin
        exit(MakeUpdateRequired);
    end;

    procedure SetMakeUpdateRequired(NewMakeUpdateRequired: Boolean)
    begin
        MakeUpdateRequired := NewMakeUpdateRequired;
    end;

    procedure ReadExtTextLines(var ExtTextHeader: Record "Extended Text Header"; DocDate: Date; LanguageCode: Code[10]) Result: Boolean
    var
        ExtTextLine: Record "Extended Text Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReadLines(ExtTextHeader, DocDate, LanguageCode, IsHandled, Result, TempExtTextLine);
        if IsHandled then
            exit(Result);

        ExtTextHeader.SetCurrentKey(
          "Table Name", "No.", "Language Code", "All Language Codes", "Starting Date", "Ending Date");
        ExtTextHeader.SetRange("Starting Date", 0D, DocDate);
        OnReadExtTextLinesOnBeforeSetFilters(ExtTextHeader);
        ExtTextHeader.SetFilter("Ending Date", '%1..|%2', DocDate, 0D);
        if LanguageCode = '' then begin
            ExtTextHeader.SetRange("Language Code", '');
            if not ExtTextHeader.FindSet() then
                exit;
        end else begin
            ExtTextHeader.SetRange("Language Code", LanguageCode);
            if not ExtTextHeader.FindSet() then begin
                ExtTextHeader.SetRange("All Language Codes", true);
                ExtTextHeader.SetRange("Language Code", '');
                if not ExtTextHeader.FindSet() then
                    exit;
            end;
        end;
        TempExtTextLine.DeleteAll();
        repeat
            ExtTextLine.SetRange("Table Name", ExtTextHeader."Table Name");
            ExtTextLine.SetRange("No.", ExtTextHeader."No.");
            ExtTextLine.SetRange("Language Code", ExtTextHeader."Language Code");
            ExtTextLine.SetRange("Text No.", ExtTextHeader."Text No.");
            if ExtTextLine.FindSet() then begin
                repeat
                    TempExtTextLine := ExtTextLine;
                    OnReadExtTextLinesOnBeforeTempExtTextLineInsert(TempExtTextLine, ExtTextHeader);
                    TempExtTextLine.Insert();
                until ExtTextLine.Next() = 0;
                Result := true;
            end;
        until ExtTextHeader.Next() = 0;

        OnAfterReadLines(TempExtTextLine, ExtTextHeader, LanguageCode);
    end;

#if not CLEAN25
    [Obsolete('Replaced by procedure in Service codeunit', '25.0')]
    procedure ServCheckIfAnyExtText(var ServiceLine: Record Microsoft.Service.Document."Service Line"; Unconditionally: Boolean) Result: Boolean
    var
        ServHeader: Record Microsoft.Service.Document."Service Header";
        ExtTextHeader: Record "Extended Text Header";
        ServCost: Record Microsoft.Service.Pricing."Service Cost";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServCheckIfAnyExtText(ServiceLine, Unconditionally, MakeUpdateRequired, AutoText, Result, IsHandled);
        if IsHandled then
            exit(Result);

        MakeUpdateRequired := false;
        if IsDeleteAttachedLines(ServiceLine."Line No.", ServiceLine."No.", ServiceLine."Attached to Line No.") then
            MakeUpdateRequired := DeleteServiceLines(ServiceLine);

        AutoText := false;
        if Unconditionally then
            AutoText := true
        else
            case ServiceLine.Type of
                ServiceLine.Type::" ":
                    AutoText := true;
                ServiceLine.Type::Cost:
                    if ServCost.Get(ServiceLine."No.") then
                        if GLAcc.Get(ServCost."Account No.") then
                            AutoText := GLAcc."Automatic Ext. Texts";
                ServiceLine.Type::Item:
                    if Item.Get(ServiceLine."No.") then
                        AutoText := Item."Automatic Ext. Texts";
                ServiceLine.Type::Resource:
                    if Res.Get(ServiceLine."No.") then
                        AutoText := Res."Automatic Ext. Texts";
                ServiceLine.Type::"G/L Account":
                    if GLAcc.Get(ServiceLine."No.") then
                        AutoText := GLAcc."Automatic Ext. Texts";
            end;

        OnServCheckIfAnyExtTextOnBeforeSetFilters(ServiceLine, AutoText, Unconditionally);

        if AutoText then begin
            case ServiceLine.Type of
                ServiceLine.Type::" ":
                    begin
                        ExtTextHeader.SetRange("Table Name", ExtTextHeader."Table Name"::"Standard Text");
                        ExtTextHeader.SetRange("No.", ServiceLine."No.");
                    end;
                ServiceLine.Type::Item:
                    begin
                        ExtTextHeader.SetRange("Table Name", ExtTextHeader."Table Name"::Item);
                        ExtTextHeader.SetRange("No.", ServiceLine."No.");
                    end;
                ServiceLine.Type::Resource:
                    begin
                        ExtTextHeader.SetRange("Table Name", ExtTextHeader."Table Name"::Resource);
                        ExtTextHeader.SetRange("No.", ServiceLine."No.");
                    end;
                ServiceLine.Type::Cost:
                    begin
                        ExtTextHeader.SetRange("Table Name", ExtTextHeader."Table Name"::"G/L Account");
                        ServCost.Get(ServiceLine."No.");
                        ExtTextHeader.SetRange("No.", ServCost."Account No.");
                    end;
                ServiceLine.Type::"G/L Account":
                    begin
                        ExtTextHeader.SetRange("Table Name", ExtTextHeader."Table Name"::"G/L Account");
                        ExtTextHeader.SetRange("No.", ServiceLine."No.");
                    end;
            end;

            case ServiceLine."Document Type" of
                ServiceLine."Document Type"::Quote:
                    ExtTextHeader.SetRange("Service Quote", true);
                ServiceLine."Document Type"::Order:
                    ExtTextHeader.SetRange("Service Order", true);
                ServiceLine."Document Type"::Invoice:
                    ExtTextHeader.SetRange("Service Invoice", true);
                ServiceLine."Document Type"::"Credit Memo":
                    ExtTextHeader.SetRange("Service Credit Memo", true);
            end;
            ServHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
            OnServCheckIfAnyExtTextAutoText(ExtTextHeader, ServHeader, ServiceLine, Unconditionally, MakeUpdateRequired);
            exit(ReadExtTextLines(ExtTextHeader, ServHeader."Order Date", ServHeader."Language Code"));
        end;
    end;
#endif

#if not CLEAN25
    local procedure DeleteServiceLines(var ServiceLine: Record Microsoft.Service.Document."Service Line"): Boolean
    var
        ServiceLine2: Record Microsoft.Service.Document."Service Line";
    begin
        ServiceLine2.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine2.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine2.SetRange("Attached to Line No.", ServiceLine."Line No.");
        OnDeleteServiceLinesOnAfterSetFilers(ServiceLine2, ServiceLine);
        ServiceLine2 := ServiceLine;
        if ServiceLine2.Find('>') then begin
            repeat
                ServiceLine2.Delete();
            until ServiceLine2.Next() = 0;
            exit(true);
        end;
    end;
#endif

    procedure GetTempExtTextLine(var ToTempExtendedTextLine: Record "Extended Text Line" temporary)
    begin
        ToTempExtendedTextLine.Copy(TempExtTextLine, true);
    end;

#if not CLEAN25
    [Obsolete('Replaced by procedure in Service codeunit', '25.0')]
    procedure InsertServExtText(var ServiceLine: Record Microsoft.Service.Document."Service Line")
    var
        ToServiceLine: Record Microsoft.Service.Document."Service Line";
        IsHandled: Boolean;
    begin
        OnBeforeInsertServExtText(ServiceLine, TempExtTextLine, IsHandled, MakeUpdateRequired);
        if IsHandled then
            exit;

        LineSpacing := 10; // New fixed Line Spacing method

        NextLineNo := ServiceLine."Line No." + LineSpacing;

        TempExtTextLine.Reset();
        if TempExtTextLine.Find('-') then begin
            repeat
                ToServiceLine.Init();
                ToServiceLine."Document Type" := ServiceLine."Document Type";
                ToServiceLine."Document No." := ServiceLine."Document No.";
                ToServiceLine."Service Item Line No." := ServiceLine."Service Item Line No.";
                ToServiceLine."Line No." := NextLineNo;
                NextLineNo := NextLineNo + LineSpacing;
                ToServiceLine.Description := TempExtTextLine.Text;
                ToServiceLine."Attached to Line No." := ServiceLine."Line No.";
                ToServiceLine."Service Item No." := ServiceLine."Service Item No.";

                IsHandled := false;
                OnInsertServExtTextOnBeforeToServiceLineInsert(ServiceLine, ToServiceLine, TempExtTextLine, NextLineNo, LineSpacing, IsHandled);
                if not IsHandled then
                    ToServiceLine.Insert(true);
            until TempExtTextLine.Next() = 0;
            MakeUpdateRequired := true;
        end;
        TempExtTextLine.DeleteAll();
    end;
#endif

    procedure JobCheckIfAnyExtText(var JobPlanningLine: Record "Job Planning Line"; Unconditionally: Boolean): Boolean
    var
        Job: Record Job;
    begin
        exit(JobCheckIfAnyExtText(JobPlanningLine, Unconditionally, Job));
    end;

    procedure JobCheckIfAnyExtText(var JobPlanningLine: Record "Job Planning Line"; Unconditionally: Boolean; Job: Record Job) Result: Boolean
    var
        ExtTextHeader: Record "Extended Text Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeJobCheckIfAnyExtText(JobPlanningLine, Unconditionally, MakeUpdateRequired, AutoText, Result, IsHandled);
        if IsHandled then
            exit(Result);

        MakeUpdateRequired := false;
        if IsDeleteAttachedLines(JobPlanningLine."Line No.", JobPlanningLine."No.", JobPlanningLine."Attached to Line No.") and not JobPlanningLine.IsExtendedText() then
            MakeUpdateRequired := DeleteJobPlanningLines(JobPlanningLine);

        AutoText := false;

        if Unconditionally then
            AutoText := true
        else
            case JobPlanningLine.Type of
                JobPlanningLine.Type::Text:
                    AutoText := true;
                JobPlanningLine.Type::"G/L Account":
                    if GLAcc.Get(JobPlanningLine."No.") then
                        AutoText := GLAcc."Automatic Ext. Texts";
                JobPlanningLine.Type::Item:
                    if Item.Get(JobPlanningLine."No.") then
                        AutoText := Item."Automatic Ext. Texts";
                JobPlanningLine.Type::Resource:
                    if Res.Get(JobPlanningLine."No.") then
                        AutoText := Res."Automatic Ext. Texts";
            end;

        OnJobCheckIfAnyExtTextOnAfterCheckAutoText(JobPlanningLine, AutoText, Unconditionally);

        if not AutoText then
            exit;

        JobPlanningLine.TestField("Job No.");
        if Job."No." = '' then
            Job.Get(JobPlanningLine."Job No.");

        case JobPlanningLine.Type of
            JobPlanningLine.Type::Text:
                ExtTextHeader.SetRange("Table Name", ExtTextHeader."Table Name"::"Standard Text");
            JobPlanningLine.Type::Item:
                ExtTextHeader.SetRange("Table Name", ExtTextHeader."Table Name"::Item);
            JobPlanningLine.Type::Resource:
                ExtTextHeader.SetRange("Table Name", ExtTextHeader."Table Name"::Resource);
            JobPlanningLine.Type::"G/L Account":
                ExtTextHeader.SetRange("Table Name", ExtTextHeader."Table Name"::"G/L Account");
        end;
        ExtTextHeader.SetRange("No.", JobPlanningLine."No.");
        ExtTextHeader.SetRange(Job, true);
        OnJobCheckIfAnyExtTextOnBeforeReadExtTextLines(ExtTextHeader, Job, JobPlanningLine, Unconditionally, MakeUpdateRequired);
        exit(ReadExtTextLines(ExtTextHeader, JobPlanningLine."Document Date", Job."Language Code"));
    end;

    local procedure DeleteJobPlanningLines(var JobPlanningLine: Record "Job Planning Line"): Boolean
    var
        JobPlanningLine2: Record "Job Planning Line";
    begin
        JobPlanningLine2.SetRange("Job No.", JobPlanningLine."Job No.");
        JobPlanningLine2.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        JobPlanningLine2.SetRange("Attached to Line No.", JobPlanningLine."Line No.");
        OnDeleteJobPlanningLinesOnAfterSetFilters(JobPlanningLine2, JobPlanningLine);
        JobPlanningLine2 := JobPlanningLine;
        if JobPlanningLine2.Find('>') then begin
            repeat
                JobPlanningLine2.Delete(true);
            until JobPlanningLine2.Next() = 0;
            exit(true);
        end;
    end;

    procedure InsertJobExtText(var JobPlanningLine: Record "Job Planning Line")
    var
        DummyJobPlanningLine: Record "Job Planning Line";
    begin
        InsertJobExtTextRetLast(JobPlanningLine, DummyJobPlanningLine);
    end;

    procedure InsertJobExtTextRetLast(var JobPlanningLine: Record "Job Planning Line"; var LastInsertedJobPlanningLine: Record "Job Planning Line")
    var
        ToJobPlanningLine: Record "Job Planning Line";
        IsHandled: Boolean;
    begin
        OnBeforeInsertJobExtTextRetLast(JobPlanningLine, TempExtTextLine, MakeUpdateRequired);

        LineSpacing := 10; // New fixed Line Spacing method
        NextLineNo := JobPlanningLine."Line No." + LineSpacing;

        TempExtTextLine.Reset();
        if TempExtTextLine.Find('-') then begin
            repeat
                ToJobPlanningLine.Init();
                ToJobPlanningLine.Validate("Line Type", JobPlanningLine."Line Type");
                ToJobPlanningLine.Type := ToJobPlanningLine.Type::Text;
                ToJobPlanningLine."Job No." := JobPlanningLine."Job No.";
                ToJobPlanningLine."Job Task No." := JobPlanningLine."Job Task No.";
                ToJobPlanningLine."Line No." := NextLineNo;
                NextLineNo := NextLineNo + LineSpacing;
                ToJobPlanningLine."Planning Date" := JobPlanningLine."Planning Date";
                ToJobPlanningLine."Planned Delivery Date" := JobPlanningLine."Planned Delivery Date";
                ToJobPlanningLine."Document No." := JobPlanningLine."Document No.";
                ToJobPlanningLine.Description := TempExtTextLine.Text;
                ToJobPlanningLine."Attached to Line No." := JobPlanningLine."Line No.";

                IsHandled := false;
                OnInsertJobExtTextRetLastOnBeforeToJobPlanningLineInsert(ToJobPlanningLine, JobPlanningLine, TempExtTextLine, NextLineNo, LineSpacing, IsHandled);
                if not IsHandled then
                    ToJobPlanningLine.Insert(true);
            until TempExtTextLine.Next() = 0;
            MakeUpdateRequired := true;
        end;
        TempExtTextLine.DeleteAll();
        LastInsertedJobPlanningLine := ToJobPlanningLine;
    end;

    procedure IsDeleteAttachedLines(LineNo: Integer; No: Code[20]; AttachedToLineNo: Integer): Boolean
    begin
        exit((LineNo <> 0) and (AttachedToLineNo = 0) and (No <> ''));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReadLines(var TempExtendedTextLine: Record "Extended Text Line" temporary; var ExtendedTextHeader: Record "Extended Text Header"; LanguageCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReadLines(var ExtendedTextHeader: Record "Extended Text Header"; DocDate: Date; LanguageCode: Code[10]; var IsHandled: Boolean; var Result: Boolean; var TempExtTextLine: Record "Extended Text Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeToPurchLineInsert(var ToPurchLine: Record "Purchase Line"; var PurchLine: Record "Purchase Line"; TempExtTextLine: Record "Extended Text Line" temporary; var NextLineNo: Integer; LineSpacing: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertSalesExtTextRetLastOnBeforeToSalesLineInsert(var ToSalesLine: Record "Sales Line"; var SalesLine: Record "Sales Line"; TempExtTextLine: Record "Extended Text Line" temporary; var NextLineNo: Integer; LineSpacing: Integer; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnInsertServExtTextOnBeforeToServiceLineInsert(var ServLine: Record Microsoft.Service.Document."Service Line"; var ToServLine: Record Microsoft.Service.Document."Service Line"; TempExtTextLine: Record "Extended Text Line" temporary; var NextLineNo: Integer; LineSpacing: Integer; var IsHandled: Boolean)
    begin
        OnInsertServExtTextOnBeforeToServiceLineInsert(ServLine, ToServLine, TempExtTextLine, NextLineNo, LineSpacing, IsHandled);
    end;

    [Obsolete('Replaced by same event in codeunit ServiceTransferextText', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnInsertServExtTextOnBeforeToServiceLineInsert(var ServLine: Record Microsoft.Service.Document."Service Line"; var ToServLine: Record Microsoft.Service.Document."Service Line"; TempExtTextLine: Record "Extended Text Line" temporary; var NextLineNo: Integer; LineSpacing: Integer; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeToReminderLineInsert(var ToReminderLine: Record "Reminder Line"; ReminderLine: Record "Reminder Line"; TempExtTextLine: Record "Extended Text Line" temporary; var NextLineNo: Integer; LineSpacing: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteFinChrgMemoLinesOnAfterFinChrgMemoLine2SetFilters(var FinChrgMemoLine2: Record "Finance Charge Memo Line"; var FinChrgMemoLine: Record "Finance Charge Memo Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeletePurchLinesOnAfterSetFilters(var ToPurchaseLine: Record "Purchase Line"; FromPurchaseLine: Record "Purchase Line")
    begin
    end;

#if not CLEAN25
    internal procedure RunOnDeleteServiceLinesOnAfterSetFilers(var ServiceLine2: Record Microsoft.Service.Document."Service Line"; var ServiceLine: Record Microsoft.Service.Document."Service Line")
    begin
        OnDeleteServiceLinesOnAfterSetFilers(ServiceLine2, ServiceLine);
    end;

    [Obsolete('Replaced by same event in codeunit ServiceTransferextText', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnDeleteServiceLinesOnAfterSetFilers(var ServiceLine2: Record Microsoft.Service.Document."Service Line"; var ServiceLine: Record Microsoft.Service.Document."Service Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnDeleteSalesLinesOnAfterSetFilters(var ToSalesLine: Record "Sales Line"; FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteReminderLinesOnAfterReminderLine2SetFilters(var ReminderLine2: Record "Reminder Line"; var ReminderLine: Record "Reminder Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinChrgMemoCheckIfAnyExtTextAutoText(var ExtendedTextHeader: Record "Extended Text Header"; var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; var FinanceChargeMemoLine: Record "Finance Charge Memo Line"; Unconditionally: Boolean; var MakeUpdateRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepmtGetAnyExtTextAfterReadLines(var ExtendedTextHeader: Record "Extended Text Header"; var TempExtendedTextLine: Record "Extended Text Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepmtGetAnyExtTextBeforeReadLines(var ExtendedTextHeader: Record "Extended Text Header"; DocumentDate: Date; LanguageCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchCheckIfAnyExtTextAutoText(var ExtendedTextHeader: Record "Extended Text Header"; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Unconditionally: Boolean; var MakeUpdateRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReminderCheckIfAnyExtTextAutoText(var ExtendedTextHeader: Record "Extended Text Header"; var ReminderHeader: Record "Reminder Header"; var ReminderLine: Record "Reminder Line"; Unconditionally: Boolean; var MakeUpdateRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesCheckIfAnyExtTextAutoText(var ExtendedTextHeader: Record "Extended Text Header"; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Unconditionally: Boolean; var MakeUpdateRequired: Boolean)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnServCheckIfAnyExtTextAutoText(var ExtendedTextHeader: Record "Extended Text Header"; var ServiceHeader: Record Microsoft.Service.Document."Service Header"; var ServiceLine: Record Microsoft.Service.Document."Service Line"; Unconditionally: Boolean; var MakeUpdateRequired: Boolean)
    begin
        OnServCheckIfAnyExtTextAutoText(ExtendedTextHeader, ServiceHeader, ServiceLine, Unconditionally, MakeUpdateRequired);
    end;

    [Obsolete('Replaced by same event in codeunit ServiceTransferextText', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnServCheckIfAnyExtTextAutoText(var ExtendedTextHeader: Record "Extended Text Header"; var ServiceHeader: Record Microsoft.Service.Document."Service Header"; var ServiceLine: Record Microsoft.Service.Document."Service Line"; Unconditionally: Boolean; var MakeUpdateRequired: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSalesExtText(var SalesLine: Record "Sales Line"; var TempExtTextLine: Record "Extended Text Line" temporary; var IsHandled: Boolean; var MakeUpdateRequired: Boolean; var LastInsertedSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertReminderExtText(var ReminderLine: Record "Reminder Line"; var TempExtTextLine: Record "Extended Text Line" temporary; var IsHandled: Boolean; var MakeUpdateRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertFinChrgMemoExtText(var FinChrgMemoLine: Record "Finance Charge Memo Line"; var TempExtTextLine: Record "Extended Text Line" temporary; var IsHandled: Boolean; var MakeUpdateRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPurchExtText(var PurchLine: Record "Purchase Line"; var TempExtTextLine: Record "Extended Text Line" temporary; var IsHandled: Boolean; var MakeUpdateRequired: Boolean; var LastInsertedPurchLine: Record "Purchase Line")
    begin
    end;

#if not CLEAN25
    internal procedure RunOnBeforeInsertServExtText(var ServiceLine: Record Microsoft.Service.Document."Service Line"; var TempExtTextLine: Record "Extended Text Line" temporary; var IsHandled: Boolean; var MakeUpdateRequired: Boolean)
    begin
        OnBeforeInsertServExtText(ServiceLine, TempExtTextLine, IsHandled, MakeUpdateRequired);
    end;

    [Obsolete('Replaced by same event in codeunit ServiceTransferextText', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertServExtText(var ServiceLine: Record Microsoft.Service.Document."Service Line"; var TempExtTextLine: Record "Extended Text Line" temporary; var IsHandled: Boolean; var MakeUpdateRequired: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure InsertPurchExtTextRetLastOnBeforeToPurchLineFind(var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertSalesExtTextRetLastOnBeforeToSalesLineFind(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchCheckIfAnyExtTextOnBeforeSetFilters(var PurchaseLine: Record "Purchase Line"; var AutoText: Boolean; Unconditionally: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesCheckIfAnyExtTextOnBeforeSetFilters(var SalesLine: Record "Sales Line"; var AutoText: Boolean; Unconditionally: Boolean)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnServCheckIfAnyExtTextOnBeforeSetFilters(var ServiceLine: Record Microsoft.Service.Document."Service Line"; var AutoText: Boolean; Unconditionally: Boolean)
    begin
        OnServCheckIfAnyExtTextOnBeforeSetFilters(ServiceLine, AutoText, Unconditionally);
    end;

    [Obsolete('Replaced by same event in codeunit ServiceTransferextText', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnServCheckIfAnyExtTextOnBeforeSetFilters(var ServiceLine: Record Microsoft.Service.Document."Service Line"; var AutoText: Boolean; Unconditionally: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnReminderCheckIfAnyExtTextOnBeforeSetFilters(var ReminderLine: Record "Reminder Line"; var AutoText: Boolean; Unconditionally: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinChrgMemoCheckIfAnyExtTextOnBeforeSetFilters(var FinChrgMemoLine: Record "Finance Charge Memo Line"; var AutoText: Boolean; Unconditionally: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReadExtTextLinesOnBeforeSetFilters(var ExtTextHeader: Record "Extended Text Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertFinChrgMemoExtTextOnBeforeToFinChrgMemoLineInsert(var ToFinanceChargeMemoLine: Record "Finance Charge Memo Line"; FinanceChargeMemoLine: Record "Finance Charge Memo Line"; TempExtendedTextLine: Record "Extended Text Line" temporary; var NextLineNo: Integer; LineSpacing: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReadExtTextLinesOnBeforeTempExtTextLineInsert(var TempExtendedTextLine: Record "Extended Text Line" temporary; ExtendedTextHeader: Record "Extended Text Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertSalesExtTextRetLastOnBeforeFindTempExtTextLine(var TempExtendedTextLine: Record "Extended Text Line" temporary; SalesLine: Record "Sales Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertReminderExtTextOnBeforeFindTempExtTextLine(var TempExtendedTextLine: Record "Extended Text Line" temporary; ReminderLine: Record "Reminder Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPurchExtTextRetLastOnBeforeFindTempExtTextLine(var TempExtendedTextLine: Record "Extended Text Line" temporary; PurchaseLine: Record "Purchase Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesCheckIfAnyExtText(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Unconditionally: Boolean; var MakeUpdateRequired: Boolean; var AutoText: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchCheckIfAnyExtText(var PurchLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Unconditionally: Boolean; var MakeUpdateRequired: Boolean; var AutoText: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnBeforeServCheckIfAnyExtText(var ServiceLine: Record Microsoft.Service.Document."Service Line"; Unconditionally: Boolean; var MakeUpdateRequired: Boolean; var AutoText: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
        OnBeforeServCheckIfAnyExtText(ServiceLine, Unconditionally, MakeUpdateRequired, AutoText, Result, IsHandled);
    end;

    [Obsolete('Replaced by same event in codeunit ServiceTransferextText', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeServCheckIfAnyExtText(var ServiceLine: Record Microsoft.Service.Document."Service Line"; Unconditionally: Boolean; var MakeUpdateRequired: Boolean; var AutoText: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnDeleteSalesLinesOnBeforeDelete(var SalesLine: Record "Sales Line"; var SalesLineToDelete: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertJobExtTextRetLast(var JobPlanningLine: Record "Job Planning Line"; var TempExtendedTextLine: Record "Extended Text Line" temporary; var MakeUpdateRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnJobCheckIfAnyExtTextOnBeforeReadExtTextLines(var ExtendedTextHeader: Record "Extended Text Header"; var Job: Record Job; var JobPlanningLine: Record "Job Planning Line"; Unconditionally: Boolean; var MakeUpdateRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertJobExtTextRetLastOnBeforeToJobPlanningLineInsert(var ToJobPlanningLine: Record "Job Planning Line"; var JobPlanningLine: Record "Job Planning Line"; TempExtendedTextLine: Record "Extended Text Line" temporary; var NextLineNo: Integer; LineSpacing: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteJobPlanningLinesOnAfterSetFilters(var ToJobPlanningLine: Record "Job Planning Line"; FromJobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnJobCheckIfAnyExtTextOnAfterCheckAutoText(var JobPlanningLine: Record "Job Planning Line"; var AutoText: Boolean; Unconditionally: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertSalesExtTextRetLastOnAfterSetLineSpacing(var LineSpacing: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeJobCheckIfAnyExtText(var JobPlanningLine: Record "Job Planning Line"; Unconditionally: Boolean; var MakeUpdateRequired: Boolean; var AutoText: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}
