// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Pricing;

using Microsoft.Finance.Currency;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Service.Document;
using System.Utilities;

codeunit 6080 "Service Price Management"
{

    trigger OnRun()
    begin
    end;

    var
        ServHeader: Record "Service Header";
        Currency: Record Currency;
        TotalAmount: Decimal;

#pragma warning disable AA0074
        Text001: Label 'There are no Service Lines to adjust.';
        Text002: Label 'Perform price adjustment?';
        Text003: Label 'This will remove all discounts on the Service Lines. Continue?';
#pragma warning disable AA0470
        Text004: Label 'No Service Lines were found for %1 no. %2.';
#pragma warning restore AA0470
        Text008: Label 'Perform price adjustment?';
#pragma warning restore AA0074

    procedure ShowPriceAdjustment(ServItemLine: Record "Service Item Line")
    var
        ServPriceGrSetup: Record "Serv. Price Group Setup";
        ServLinePriceAdjmt: Record "Service Line Price Adjmt.";
        ServLine: Record "Service Line";
        ConfirmManagement: Codeunit "Confirm Management";
        ServPriceAdjmtForm: Page "Service Line Price Adjmt.";
    begin
        ServItemLine.TestField("Service Price Group Code");

        if ServItemLine."Serv. Price Adjmt. Gr. Code" = '' then
            Error(Text001);

        ServLinePriceAdjmt."Document Type" := ServItemLine."Document Type";
        ServLinePriceAdjmt."Document No." := ServItemLine."Document No.";
        GetServHeader(ServLinePriceAdjmt);
        GetServPriceGrSetup(ServPriceGrSetup, ServHeader, ServItemLine);
        ServLinePriceAdjmt.Reset();
        ServLinePriceAdjmt.SetRange("Document Type", ServItemLine."Document Type");
        ServLinePriceAdjmt.SetRange("Document No.", ServItemLine."Document No.");
        ServLinePriceAdjmt.SetRange("Service Item Line No.", ServItemLine."Line No.");
        if ServLinePriceAdjmt.FindFirst() then
            ServLinePriceAdjmt.DeleteAll();
        ServLine.Reset();
        ServLine.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.");
        ServLine.SetRange("Document Type", ServItemLine."Document Type");
        ServLine.SetRange("Document No.", ServItemLine."Document No.");
        ServLine.SetRange("Service Item Line No.", ServItemLine."Line No.");
        if not ServLine.Find('-') then
            Error(Text004, ServItemLine.TableCaption(), ServItemLine."Line No.");

        if not ServPriceGrSetup."Include Discounts" then
            if not ConfirmManagement.GetResponseOrDefault(Text003, true) then
                exit;
        repeat
            OnShowPriceAdjustmentOnBeforeLineWithinFilter(ServLine);
            if LineWithinFilter(ServLine, ServItemLine."Serv. Price Adjmt. Gr. Code") and
               (ServItemLine."Serv. Price Adjmt. Gr. Code" <> '')
            then begin
                ServLinePriceAdjmt."Vat %" := ServLine."VAT %";
                if ServHeader."Prices Including VAT" then
                    ServLine."VAT %" := 0;
                if not ServPriceGrSetup."Include Discounts" then begin
                    ServLine.TestField(Warranty, false);
                    ServLine.Validate("Line Discount %", 0);
                    OnShowPriceAdjustmentAfterValidateLineDiscountPercentage(ServLine);
                end;
                ServLinePriceAdjmt."Document Type" := ServLine."Document Type";
                ServLinePriceAdjmt."Document No." := ServLine."Document No.";
                ServLinePriceAdjmt."Service Line No." := ServLine."Line No.";
                ServLinePriceAdjmt."Service Item Line No." := ServLine."Service Item Line No.";
                ServLinePriceAdjmt."Service Item No." := ServLine."Service Item No.";
                ServLinePriceAdjmt."Serv. Price Adjmt. Gr. Code" := ServItemLine."Serv. Price Adjmt. Gr. Code";
                ServLinePriceAdjmt.Type := ServLine.Type;
                ServLinePriceAdjmt."No." := ServLine."No.";
                ServLinePriceAdjmt.Description := ServLine.Description;
                ServLinePriceAdjmt.Quantity := ServLine.Quantity - ServLine."Quantity Consumed" - ServLine."Qty. to Consume";

                ServLinePriceAdjmt.Amount := ServLine."Line Amount";
                ServLinePriceAdjmt."New Amount" := ServLine."Line Amount";
                ServLinePriceAdjmt."Unit Price" := ServLine."Unit Price";
                ServLinePriceAdjmt."New Unit Price" := ServLine."Unit Price";
                ServLinePriceAdjmt."Unit Cost" := ServLine."Unit Cost";
                ServLinePriceAdjmt."Discount %" := ServLine."Line Discount %";
                ServLinePriceAdjmt."Discount Amount" := ServLine."Line Discount Amount";
                ServLinePriceAdjmt."Amount incl. VAT" := ServLine."Amount Including VAT";
                ServLinePriceAdjmt."New Amount incl. VAT" := ServLine."Amount Including VAT";
                ServLinePriceAdjmt."New Amount Excl. VAT" :=
                  Round(
                    ServLine."Amount Including VAT" / (1 + ServLinePriceAdjmt."Vat %" / 100),
                    Currency."Amount Rounding Precision");
                ServLinePriceAdjmt."Adjustment Type" := ServPriceGrSetup."Adjustment Type";
                ServLinePriceAdjmt."Service Price Group Code" := ServItemLine."Service Price Group Code";
                OnShowPriceAdjustmentOnBeforeServLinePriceAdjmtInsert(ServLine, ServLinePriceAdjmt);
                ServLinePriceAdjmt.Insert();
            end;
        until ServLine.Next() = 0;
        CalculateWeight(ServLinePriceAdjmt, ServPriceGrSetup);

        if ServLinePriceAdjmt.FindFirst() then begin
            Commit();
            Clear(ServPriceAdjmtForm);
            ServPriceAdjmtForm.SetVars(ServPriceGrSetup.Amount, ServPriceGrSetup."Include VAT");
            ServPriceAdjmtForm.SetTableView(ServLinePriceAdjmt);
            if ServPriceAdjmtForm.RunModal() = ACTION::OK then
                if ConfirmManagement.GetResponseOrDefault(Text002, true) then
                    PerformAdjustment(ServLinePriceAdjmt, ServPriceGrSetup."Include VAT");
            ServLinePriceAdjmt.Reset();
            ServLinePriceAdjmt.SetRange("Document Type", ServItemLine."Document Type");
            ServLinePriceAdjmt.SetRange("Document No.", ServItemLine."Document No.");
            ServLinePriceAdjmt.SetRange("Service Item Line No.", ServItemLine."Line No.");
            if ServLinePriceAdjmt.FindFirst() then
                ServLinePriceAdjmt.DeleteAll();
        end else
            Error(Text001);
    end;

    procedure AdjustLines(ServLinePriceAdjmt: Record "Service Line Price Adjmt."; ServPriceGrSetup: Record "Serv. Price Group Setup")
    var
        ConfirmManagement: Codeunit "Confirm Management";
        TotalAmount: Decimal;
    begin
        if not ConfirmManagement.GetResponseOrDefault(Text008, true) then
            exit;
        if ServPriceGrSetup."Adjustment Type" = ServPriceGrSetup."Adjustment Type"::Fixed then
            AdjustFixed(ServLinePriceAdjmt, ServPriceGrSetup.Amount, ServPriceGrSetup."Include VAT")
        else begin
            ServLinePriceAdjmt.Reset();
            ServLinePriceAdjmt.SetRange("Document Type", ServLinePriceAdjmt."Document Type");
            ServLinePriceAdjmt.SetRange("Document No.", ServLinePriceAdjmt."Document No.");
            ServLinePriceAdjmt.SetRange("Service Item Line No.", ServLinePriceAdjmt."Service Item Line No.");
            OnAdjustLinesOnBeforeCalcSums(ServLinePriceAdjmt);
            ServLinePriceAdjmt.CalcSums(Amount, "Amount incl. VAT");
            TotalAmount := ServLinePriceAdjmt.Amount;
            if ServPriceGrSetup."Include VAT" then
                TotalAmount := ServLinePriceAdjmt."Amount incl. VAT";
            if ServPriceGrSetup."Adjustment Type" = ServPriceGrSetup."Adjustment Type"::Maximum then begin
                if TotalAmount > ServPriceGrSetup.Amount then
                    AdjustFixed(ServLinePriceAdjmt, ServPriceGrSetup.Amount, ServPriceGrSetup."Include VAT");
            end else
                if TotalAmount < ServPriceGrSetup.Amount then
                    AdjustFixed(ServLinePriceAdjmt, ServPriceGrSetup.Amount, ServPriceGrSetup."Include VAT");
        end;
    end;

    local procedure AdjustFixed(ServLinePriceAdjmt: Record "Service Line Price Adjmt."; FixedPrice: Decimal; InclVat: Boolean)
    begin
        GetServHeader(ServLinePriceAdjmt);
        ServLinePriceAdjmt.Reset();
        ServLinePriceAdjmt.SetRange("Document Type", ServLinePriceAdjmt."Document Type");
        ServLinePriceAdjmt.SetRange("Document No.", ServLinePriceAdjmt."Document No.");
        OnAdjustFixedOnBeforeFind(ServLinePriceAdjmt, InclVat, FixedPrice);
        if ServLinePriceAdjmt.Find('-') then
            repeat
                if ServHeader."Prices Including VAT" and not InclVat then
                    FixedPrice := Round(FixedPrice + FixedPrice * ServLinePriceAdjmt."Vat %" / 100, 0.00001);
                if InclVat then
                    ServLinePriceAdjmt.Validate("New Amount incl. VAT", Round(FixedPrice * ServLinePriceAdjmt.Weight / 100, Currency."Amount Rounding Precision"))
                else
                    ServLinePriceAdjmt.Validate("New Amount", Round(FixedPrice * ServLinePriceAdjmt.Weight / 100, Currency."Amount Rounding Precision"));
                ServLinePriceAdjmt.Modify();
            until ServLinePriceAdjmt.Next() = 0;
    end;

    local procedure CalculateWeight(ServLinePriceAdjmt: Record "Service Line Price Adjmt."; ServPriceGrSetup: Record "Serv. Price Group Setup")
    begin
        ServLinePriceAdjmt.Reset();
        ServLinePriceAdjmt.SetRange("Document Type", ServLinePriceAdjmt."Document Type");
        ServLinePriceAdjmt.SetRange("Document No.", ServLinePriceAdjmt."Document No.");
        ServLinePriceAdjmt.SetRange("Service Item Line No.", ServLinePriceAdjmt."Service Item Line No.");
        OnCalculateWeightOnBeforeCalcSums(ServLinePriceAdjmt);
        ServLinePriceAdjmt.CalcSums(Amount, "Amount incl. VAT");
        if ServPriceGrSetup."Include VAT" then
            TotalAmount := ServLinePriceAdjmt."Amount incl. VAT"
        else
            TotalAmount := ServLinePriceAdjmt.Amount;
        if not ServLinePriceAdjmt.Find('-') then
            exit;
        repeat
            if ServPriceGrSetup."Include VAT" then begin
                if TotalAmount <> 0 then
                    ServLinePriceAdjmt.Weight := Round(ServLinePriceAdjmt."Amount incl. VAT" * 100 / TotalAmount, 0.00001);
            end else
                if TotalAmount <> 0 then
                    ServLinePriceAdjmt.Weight := Round(ServLinePriceAdjmt.Amount * 100 / TotalAmount, 0.00001);
            ServLinePriceAdjmt.Modify();
        until ServLinePriceAdjmt.Next() = 0;
    end;

    procedure GetServPriceGrSetup(var ServPriceGrSetup: Record "Serv. Price Group Setup"; ServHeader: Record "Service Header"; ServItemLine: Record "Service Item Line")
    begin
        ServPriceGrSetup.Reset();
        ServPriceGrSetup.SetRange("Service Price Group Code", ServItemLine."Service Price Group Code");
        ServPriceGrSetup.SetFilter("Fault Area Code", '%1|%2', ServItemLine."Fault Area Code", '');
        ServPriceGrSetup.SetFilter("Cust. Price Group Code", '%1|%2', ServHeader."Customer Price Group", '');
        ServPriceGrSetup.SetRange("Currency Code", ServHeader."Currency Code");
        ServPriceGrSetup.SetRange("Starting Date", 0D, ServHeader."Posting Date");
        if not ServPriceGrSetup.Find('+') then
            Clear(ServPriceGrSetup);
    end;

    local procedure LineWithinFilter(ServLine: Record "Service Line"; ServPriceAdjmtGrCode: Code[10]) Result: Boolean
    var
        Resource: Record Resource;
        ServPriceAdjmtDetail: Record "Serv. Price Adjustment Detail";
        IsHandled: Boolean;
    begin
        if ServLine.Type = ServLine.Type::" " then
            exit(false);
        if ServLine.Warranty then
            exit(false);

        IsHandled := false;
        OnLineWithinFilterOnBeforeSetFilters(ServLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        ServPriceAdjmtDetail.Reset();
        ServPriceAdjmtDetail.SetRange("Serv. Price Adjmt. Gr. Code", ServPriceAdjmtGrCode);
        if ServPriceAdjmtDetail.IsEmpty() then
            exit(true);
        case ServLine.Type of
            ServLine.Type::Item:
                ServPriceAdjmtDetail.SetRange(Type, ServPriceAdjmtDetail.Type::Item);
            ServLine.Type::Resource:
                ServPriceAdjmtDetail.SetRange(Type, ServPriceAdjmtDetail.Type::Resource);
            ServLine.Type::Cost:
                ServPriceAdjmtDetail.SetRange(Type, ServPriceAdjmtDetail.Type::"Service Cost");
            ServLine.Type::"G/L Account":
                ServPriceAdjmtDetail.SetRange(Type, ServPriceAdjmtDetail.Type::"G/L Account");
            else
                exit(false);
        end;
        ServPriceAdjmtDetail.SetFilter("No.", '%1|%2', ServLine."No.", '');
        ServPriceAdjmtDetail.SetFilter("Work Type", '%1|%2', ServLine."Work Type Code", '');
        ServPriceAdjmtDetail.SetFilter("Gen. Prod. Posting Group", '%1|%2', ServLine."Gen. Prod. Posting Group", '');
        if not ServPriceAdjmtDetail.IsEmpty() then
            exit(true);
        if ServLine.Type = ServLine.Type::Resource then begin
            Resource.Get(ServLine."No.");
            ServPriceAdjmtDetail.SetRange(Type, ServPriceAdjmtDetail.Type::"Resource Group");
            ServPriceAdjmtDetail.SetFilter("No.", '%1|%2', Resource."Resource Group No.", '');
            exit(not ServPriceAdjmtDetail.IsEmpty());
        end;
    end;

    local procedure PerformAdjustment(ServLinePriceAdjmt: Record "Service Line Price Adjmt."; InclVat: Boolean)
    var
        ServHeader: Record "Service Header";
        ServLine: Record "Service Line";
        OldVatPct: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePerformAdjustment(ServLinePriceAdjmt, InclVat, IsHandled);
        if IsHandled then
            exit;

        ServHeader.Get(ServLinePriceAdjmt."Document Type", ServLinePriceAdjmt."Document No.");
        ServLinePriceAdjmt.Reset();
        ServLinePriceAdjmt.SetRange("Document Type", ServLinePriceAdjmt."Document Type");
        ServLinePriceAdjmt.SetRange("Document No.", ServLinePriceAdjmt."Document No.");
        ServLinePriceAdjmt.SetRange("Service Item Line No.", ServLinePriceAdjmt."Service Item Line No.");
        if ServLinePriceAdjmt.Find('-') then
            repeat
                ServLine.Get(ServLinePriceAdjmt."Document Type", ServLinePriceAdjmt."Document No.", ServLinePriceAdjmt."Service Line No.");
                if ServHeader."Prices Including VAT" then begin
                    OldVatPct := ServLine."VAT %";
                    ServLine."VAT %" := 0;
                end;
                ServLine.Validate("Unit Price", ServLinePriceAdjmt."New Unit Price");
                if ServLinePriceAdjmt."Discount %" = 0 then
                    ServLine.Validate("Line Discount %", 0);
                if ServLinePriceAdjmt."New Amount incl. VAT" <> 0 then begin
                    if InclVat then
                        ServLine.Validate("Amount Including VAT", ServLinePriceAdjmt."New Amount incl. VAT")
                    else
                        ServLine.Validate("Line Amount", ServLinePriceAdjmt."New Amount");
                end else
                    ServLine.Validate("Unit Price", 0);
                if ServLinePriceAdjmt."Manually Adjusted" then
                    ServLine."Price Adjmt. Status" := ServLine."Price Adjmt. Status"::Modified
                else
                    ServLine."Price Adjmt. Status" := ServLine."Price Adjmt. Status"::Adjusted;
                if ServHeader."Prices Including VAT" then begin
                    ServLine."VAT %" := OldVatPct;
                    OldVatPct := 0;
                end;
                ServLine.Modify();
            until ServLinePriceAdjmt.Next() = 0;
    end;

    procedure ResetAdjustedLines(ServLine: Record "Service Line")
    begin
        ServLine.Reset();
        ServLine.SetRange("Document Type", ServLine."Document Type");
        ServLine.SetRange("Document No.", ServLine."Document No.");
        ServLine.SetRange("Service Item Line No.", ServLine."Service Item Line No.");
        ServLine.SetRange("Price Adjmt. Status", ServLine."Price Adjmt. Status"::Adjusted);
        if ServLine.Find('-') then
            repeat
                OnResetAdjustedLinesOnBeforeSetHideReplacementDialog(ServLine);
                ServLine.SetHideReplacementDialog(true);
                ServLine.UpdateUnitPrice(ServLine.FieldNo("Unit Price"));
                ServLine."Price Adjmt. Status" := ServLine."Price Adjmt. Status"::" ";
                OnResetAdjustedLinesOnBeforeModify(ServLine);
                ServLine.Modify();
            until ServLine.Next() = 0;
    end;

    procedure CheckServItemGrCode(var ServLine: Record "Service Line")
    var
        ServItemLine: Record "Service Item Line";
    begin
        if ServItemLine.Get(ServItemLine."Document Type"::Order, ServLine."Document No.", ServLine."Service Item Line No.") then
            ServItemLine.TestField("Service Price Group Code");

        if ServItemLine."Serv. Price Adjmt. Gr. Code" = '' then
            Error(Text001);
    end;

    local procedure GetServHeader(ServLinePriceAdjmt: Record "Service Line Price Adjmt.")
    begin
        ServHeader.Get(ServLinePriceAdjmt."Document Type", ServLinePriceAdjmt."Document No.");
        if ServHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else begin
            ServHeader.TestField("Currency Factor");
            Currency.Get(ServHeader."Currency Code");
            Currency.TestField("Amount Rounding Precision");
        end;
    end;

    procedure IsLineToAdjustFirstInvoiced(var ServLine: Record "Service Line"): Boolean
    var
        ServLine2: Record "Service Line";
    begin
        ServLine2 := ServLine;
        ServLine.Reset();
        ServLine.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.");
        ServLine.SetRange("Document Type", ServLine2."Document Type");
        ServLine.SetRange("Document No.", ServLine2."Document No.");
        ServLine.SetRange("Service Item Line No.", ServLine2."Service Item Line No.");
        ServLine.SetRange("Price Adjmt. Status", ServLine."Price Adjmt. Status"::" ");
        ServLine.SetRange("Quantity Invoiced", 0);
        OnIsLineToAdjustFirstInvoicedOnAfterSetFilters(ServLine);
        if ServLine.Find('-') then begin
            ServLine := ServLine2;
            exit(true);
        end;
        ServLine := ServLine2;
        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowPriceAdjustmentOnBeforeLineWithinFilter(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowPriceAdjustmentAfterValidateLineDiscountPercentage(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowPriceAdjustmentOnBeforeServLinePriceAdjmtInsert(ServiceLine: Record "Service Line"; var ServiceLinePriceAdjmt: Record "Service Line Price Adjmt.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAdjustLinesOnBeforeCalcSums(var ServiceLinePriceAdjmt: Record "Service Line Price Adjmt.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAdjustFixedOnBeforeFind(var ServiceLinePriceAdjmt: Record "Service Line Price Adjmt."; InclVat: Boolean; var FixedPrice: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateWeightOnBeforeCalcSums(var ServiceLinePriceAdjmt: Record "Service Line Price Adjmt.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLineWithinFilterOnBeforeSetFilters(ServiceLine: Record "Service Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePerformAdjustment(var ServiceLinePriceAdjmt: Record "Service Line Price Adjmt."; InclVat: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnResetAdjustedLinesOnBeforeSetHideReplacementDialog(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnResetAdjustedLinesOnBeforeModify(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsLineToAdjustFirstInvoicedOnAfterSetFilters(var ServiceLine: Record "Service Line")
    begin
    end;
}

