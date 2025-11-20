// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Finance.Currency;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;

codeunit 60 "Sales-Calc. Discount"
{
    Permissions = tabledata "Sales Header" = rm,
                  tabledata "Sales Line" = rm;
    TableNo = "Sales Line";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        SalesLine.Copy(Rec);

        TempSalesHeader.Get(Rec."Document Type", Rec."Document No.");
        UpdateHeader := true;

        IsHandled := false;
        OnRunOnBeforeCalculateInvoiceDiscount(SalesLine, TempSalesHeader, TempSalesLine, UpdateHeader, IsHandled);
        if not IsHandled then
            CalculateInvoiceDiscount(TempSalesHeader, TempSalesLine);

        if Rec.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.") then;
    end;

    var
        TempSalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line";
        CustInvDisc: Record "Cust. Invoice Disc.";
        CustPostingGr: Record "Customer Posting Group";
        Currency: Record Currency;
        InvDiscBase: Decimal;
        ChargeBase: Decimal;
        CurrencyDate: Date;
        UpdateHeader: Boolean;
        CustInvDiscFound: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Service Charge';
#pragma warning restore AA0074

    local procedure CalculateInvoiceDiscount(var SalesHeader: Record "Sales Header"; var SalesLine2: Record "Sales Line")
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        SalesSetup: Record "Sales & Receivables Setup";
        TempServiceChargeLine: Record "Sales Line" temporary;
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        DiscountNotificationMgt: Codeunit "Discount Notification Mgt.";
        ShouldGetCustInvDisc: Boolean;
        IsHandled: Boolean;
        ProgressDialog: Dialog;
        CalculatingInvoiceDiscountMsg: Label 'Calculating Invoice Discount...\';
        DocumentMsg: Label 'Document #1##################\', Comment = '#1=Sales Header."No."';
        StepMsg: Label '#2##################', Comment = '#2=Step description';
        ProcessingServiceChargesMsg: Label 'Processing Service Charges...';
        CalculatingVATAmountsMsg: Label 'Calculating VAT Amounts...';
        ProcessingDiscountsMsg: Label 'Processing Discounts...';
        UpdatingHeaderMsg: Label 'Updating Header...';
        FinalizingMsg: Label 'Finalizing...';
    begin
        OnBeforeCalculateInvoiceDiscount(SalesHeader, SalesLine2, UpdateHeader);

        // Initialize progress dialog
        if GuiAllowed() then begin
            ProgressDialog.Open(
                CalculatingInvoiceDiscountMsg +
                DocumentMsg +
                StepMsg);
            ProgressDialog.Update(1, SalesHeader."No.");
        end;

        SalesSetup.Get();
        if UpdateHeader then
            SalesHeader.Find(); // To ensure we have the latest - otherwise update fails.

        IsHandled := false;
        OnBeforeCalcSalesDiscount(SalesHeader, IsHandled, SalesLine2, UpdateHeader);
        if IsHandled then
            exit;

        SalesLine.LockTable();
        SalesHeader.TestField("Customer Posting Group");
        CustPostingGr.Get(SalesHeader."Customer Posting Group");

        // Update progress - Processing Service Charges
        UpdateProgressDialog(ProgressDialog, ProcessingServiceChargesMsg);

        SalesLine2.Reset();
        SalesLine2.SetRange("Document Type", SalesLine."Document Type");
        SalesLine2.SetRange("Document No.", SalesLine."Document No.");
        SalesLine2.SetRange("System-Created Entry", true);
        SalesLine2.SetRange(Type, SalesLine2.Type::"G/L Account");
        SalesLine2.SetRange("No.", CustPostingGr."Service Charge Acc.");
        SalesLine2.SetLoadFields("Unit Price", "Shipment No.", "Qty. Shipped Not Invoiced");
        if SalesLine2.FindSet(true) then
            repeat
                SalesLine2."Unit Price" := 0;
                SalesLine2.Modify();
                TempServiceChargeLine := SalesLine2;
                TempServiceChargeLine.Insert();
            until SalesLine2.Next() = 0;

        SalesLine2.Reset();
        SalesLine2.SetLoadFields();
        SalesLine2.SetRange("Document Type", SalesLine."Document Type");
        SalesLine2.SetRange("Document No.", SalesLine."Document No.");
        SalesLine2.SetFilter(Type, '<>0');
        OnCalculateInvoiceDiscountOnBeforeSalesLine2FindFirst(SalesLine2);
        if SalesLine2.FindFirst() then;

        // Update progress - Calculating VAT Amounts
        UpdateProgressDialog(ProgressDialog, CalculatingVATAmountsMsg);

        SalesLine2.CalcVATAmountLines(0, SalesHeader, SalesLine2, TempVATAmountLine);
        InvDiscBase :=
          TempVATAmountLine.GetTotalInvDiscBaseAmount(
            SalesHeader."Prices Including VAT", SalesHeader."Currency Code");
        ChargeBase :=
          TempVATAmountLine.GetTotalLineAmount(
            SalesHeader."Prices Including VAT", SalesHeader."Currency Code");

        if UpdateHeader then
            SalesHeader.Modify();

        if SalesHeader."Posting Date" = 0D then
            CurrencyDate := WorkDate()
        else
            CurrencyDate := SalesHeader."Posting Date";

        CustInvDiscFound := CustInvDisc.GetRecord(SalesHeader."Invoice Disc. Code", SalesHeader."Currency Code", CurrencyDate, ChargeBase);

        // Update progress - Processing Discounts
        UpdateProgressDialog(ProgressDialog, ProcessingDiscountsMsg);

        OnCalculateInvoiceDiscountOnBeforeCheckCustInvDiscServiceCharge(CustInvDisc, SalesHeader, CurrencyDate, ChargeBase);
        if CustInvDiscFound and (CustInvDisc."Service Charge" <> 0) then begin
            OnCalculateInvoiceDiscountOnBeforeCurrencyInitialize(CustPostingGr);
            Currency.Initialize(SalesHeader."Currency Code");
            if not UpdateHeader then
                SalesLine2.SetSalesHeader(SalesHeader);
            if not TempServiceChargeLine.IsEmpty() then begin
                TempServiceChargeLine.FindLast();
                SalesLine2.Get(SalesLine."Document Type", SalesLine."Document No.", TempServiceChargeLine."Line No.");
                SetSalesLineServiceCharge(SalesHeader, SalesLine2);
                SalesLine2.Modify();
            end else begin
                IsHandled := false;
                OnCalculateInvoiceDiscountOnBeforeUpdateSalesLine2(SalesHeader, SalesLine2, UpdateHeader, CustInvDisc, IsHandled);
                if not IsHandled then begin
                    SalesLine2.Reset();
                    SalesLine2.SetRange("Document Type", SalesLine."Document Type");
                    SalesLine2.SetRange("Document No.", SalesLine."Document No.");
                    SalesLine2.FindLast();
                    SalesLine2.Init();
                    if not UpdateHeader then
                        SalesLine2.SetSalesHeader(SalesHeader);
                    SalesLine2."Line No." := SalesLine2."Line No." + 10000;
                    SalesLine2."System-Created Entry" := true;
                    SalesLine2.Type := SalesLine2.Type::"G/L Account";
                    SalesLine2.Validate("No.", CustPostingGr.GetServiceChargeAccount());
                    SalesLine2.Description := Text000;
                    SalesLine2.Validate(Quantity, 1);

                    OnAfterValidateSalesLine2Quantity(SalesHeader, SalesLine2, CustInvDisc);

                    if SalesLine2."Document Type" in
                        [SalesLine2."Document Type"::"Return Order", SalesLine2."Document Type"::"Credit Memo"]
                    then
                        SalesLine2.Validate("Return Qty. to Receive", SalesLine2.Quantity)
                    else
                        SalesLine2.Validate("Qty. to Ship", SalesLine2.Quantity);
                    SetSalesLineServiceCharge(SalesHeader, SalesLine2);
                    OnCalculateInvoiceDiscountOnBeforeSalesLineInsert(SalesLine2, SalesHeader);
                    SalesLine2.Insert();
                end;
            end;
            SalesLine2.CalcVATAmountLines(0, SalesHeader, SalesLine2, TempVATAmountLine);
        end else
            if TempServiceChargeLine.FindSet(false) then
                repeat
                    if (TempServiceChargeLine."Shipment No." = '') and (TempServiceChargeLine."Qty. Shipped Not Invoiced" = 0) then begin
                        SalesLine2.Get(SalesLine."Document Type", SalesLine."Document No.", TempServiceChargeLine."Line No.");
                        IsHandled := false;
                        OnCalculateInvoiceDiscountOnBeforeSalesLine2DeleteTrue(UpdateHeader, SalesLine2, IsHandled);
                        if not IsHandled then
                            SalesLine2.Delete(true);
                    end;
                until TempServiceChargeLine.Next() = 0;

        IsHandled := false;
        OnCalculateInvoiceDiscountOnBeforeCustInvDiscRecExists(SalesHeader, SalesLine2, UpdateHeader, InvDiscBase, ChargeBase, TempVATAmountLine, IsHandled);
        if IsHandled then
            exit;

        if CustInvDiscRecExists(SalesHeader."Invoice Disc. Code") then begin
            ShouldGetCustInvDisc := InvDiscBase <> ChargeBase;
            OnAfterCustInvDiscRecExists(SalesHeader, CustInvDisc, InvDiscBase, ChargeBase, ShouldGetCustInvDisc);
            if ShouldGetCustInvDisc then
                CustInvDisc.GetRecord(
                  SalesHeader."Invoice Disc. Code", SalesHeader."Currency Code", CurrencyDate, InvDiscBase);

            DiscountNotificationMgt.NotifyAboutMissingSetup(
              SalesSetup.RecordId, SalesHeader."Gen. Bus. Posting Group", SalesLine2."Gen. Prod. Posting Group",
              SalesSetup."Discount Posting", SalesSetup."Discount Posting"::"Line Discounts");

            // Update progress - Updating Header
            UpdateProgressDialog(ProgressDialog, UpdatingHeaderMsg);

            UpdateSalesHeaderInvoiceDiscount(SalesHeader, TempVATAmountLine, SalesSetup."Calc. Inv. Disc. per VAT ID");

            SalesLine2.SetSalesHeader(SalesHeader);
            SalesLine2.UpdateVATOnLines(0, SalesHeader, SalesLine2, TempVATAmountLine);
            UpdatePrepmtLineAmount(SalesHeader);
        end;

        // Update progress - Finalizing
        UpdateProgressDialog(ProgressDialog, FinalizingMsg);

        SalesCalcDiscountByType.ResetRecalculateInvoiceDisc(SalesHeader);

        if GuiAllowed() then
            ProgressDialog.Close();

        OnAfterCalcSalesDiscount(SalesHeader, TempVATAmountLine, SalesLine2);
    end;

    local procedure UpdateSalesHeaderInvoiceDiscount(var SalesHeader: Record "Sales Header"; var TempVATAmountLine: Record "VAT Amount Line" temporary; CalcInvDiscPerVATID: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSalesHeaderInvoiceDiscount(CustInvDisc, SalesHeader, TempVATAmountLine, UpdateHeader, IsHandled);
        if IsHandled then
            exit;

        SalesHeader."Invoice Discount Calculation" := SalesHeader."Invoice Discount Calculation"::"%";
        SalesHeader."Invoice Discount Value" := CustInvDisc."Discount %";
        if UpdateHeader then
            SalesHeader.Modify();

        TempVATAmountLine.SetInvoiceDiscountPercent(
          CustInvDisc."Discount %", SalesHeader."Currency Code",
          SalesHeader."Prices Including VAT", CalcInvDiscPerVATID,
          SalesHeader."VAT Base Discount %");
    end;

    local procedure SetSalesLineServiceCharge(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetSalesLineServiceCharge(SalesHeader, SalesLine, CustInvDisc, IsHandled);
        if IsHandled then
            exit;

        if SalesHeader."Prices Including VAT" then
            SalesLine.Validate(
                "Unit Price",
                Round((1 + SalesLine."VAT %" / 100) * CustInvDisc."Service Charge", Currency."Unit-Amount Rounding Precision"))
        else
            SalesLine.Validate("Unit Price", CustInvDisc."Service Charge");
    end;

    procedure CustInvDiscRecExists(InvDiscCode: Code[20]) Result: Boolean
    var
        CustInvDisc: Record "Cust. Invoice Disc.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCustInvDiscRecExists(InvDiscCode, Result, IsHandled);
        if IsHandled then
            exit(Result);

        CustInvDisc.SetRange(Code, InvDiscCode);
        exit(CustInvDisc.FindFirst());
    end;

    procedure CalculateWithSalesHeader(var TempSalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line")
    var
        FilterSalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateWithSalesHeader(SalesLine, TempSalesHeader, TempSalesLine, UpdateHeader, IsHandled); // <-- NEW EVENT
        if IsHandled then
            exit;

        FilterSalesLine.Copy(TempSalesLine);
        SalesLine := TempSalesLine;

        UpdateHeader := false;
        CalculateInvoiceDiscount(TempSalesHeader, TempSalesLine);

        TempSalesLine.Copy(FilterSalesLine);
    end;

    procedure CalculateInvoiceDiscountOnLine(var SalesLineToUpdate: Record "Sales Line")
    begin
        SalesLine.Copy(SalesLineToUpdate);

        TempSalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        UpdateHeader := false;
        CalculateInvoiceDiscount(TempSalesHeader, SalesLine);

        if SalesLineToUpdate.Get(SalesLineToUpdate."Document Type", SalesLineToUpdate."Document No.", SalesLineToUpdate."Line No.") then;
    end;

    procedure CalculateIncDiscForHeader(var TempSalesHeader: Record "Sales Header")
    var
        SalesSetup: Record "Sales & Receivables Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateIncDiscForHeader(TempSalesHeader, IsHandled, SalesLine, TempSalesLine, UpdateHeader);
        if IsHandled then
            exit;

        SalesSetup.Get();
        if not SalesSetup."Calc. Inv. Discount" then
            exit;

        SalesLine."Document Type" := TempSalesHeader."Document Type";
        SalesLine."Document No." := TempSalesHeader."No.";
        UpdateHeader := true;
        CalculateInvoiceDiscount(TempSalesHeader, TempSalesLine);
    end;

    procedure UpdatePrepmtLineAmount(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        if (SalesHeader."Invoice Discount Calculation" = SalesHeader."Invoice Discount Calculation"::"%") and
           (SalesHeader."Prepayment %" > 0) and (SalesHeader."Invoice Discount Value" > 0) and
           (SalesHeader."Invoice Discount Value" + SalesHeader."Prepayment %" >= 100)
        then begin
            SalesLine.SetRange("Document Type", SalesHeader."Document Type");
            SalesLine.SetRange("Document No.", SalesHeader."No.");
            SalesLine.SetLoadFields(Type, Quantity, "Unit Price", "Qty. to Invoice", "Prepayment %", "Prepmt. Line Amount", Amount);
            if SalesLine.FindSet(true) then
                repeat
                    if not SalesLine.ZeroAmountLine(0) and (SalesLine."Prepayment %" = SalesHeader."Prepayment %") then begin
                        SalesLine."Prepmt. Line Amount" := SalesLine.Amount;
                        SalesLine.Modify();
                    end;
                until SalesLine.Next() = 0;
        end;
    end;

    local procedure UpdateProgressDialog(var ProgressDialog: Dialog; StepDescription: Text)
    begin
        if not GuiAllowed() then
            exit;

        ProgressDialog.Update(2, StepDescription);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcSalesDiscount(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; var SalesLine: Record "Sales Line"; var UpdateHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcSalesDiscount(var SalesHeader: Record "Sales Header"; var TempVATAmountLine: Record "VAT Amount Line" temporary; var SalesLine2: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCustInvDiscRecExists(var SalesHeader: Record "Sales Header"; var CustInvDisc: Record "Cust. Invoice Disc."; InvDiscBase: Decimal; ChargeBase: Decimal; var ShouldGetCustInvDisc: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateSalesLine2Quantity(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustInvoiceDisc: Record "Cust. Invoice Disc.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateIncDiscForHeader(var TempSalesHeader: Record "Sales Header" temporary; var IsHandled: Boolean; var SalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary; var UpdateHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSalesLineServiceCharge(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustInvoiceDisc: Record "Cust. Invoice Disc."; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSalesHeaderInvoiceDiscount(var CustInvoiceDisc: Record "Cust. Invoice Disc."; var SalesHeader: Record "Sales Header"; var TempVATAmountLine: Record "VAT Amount Line" temporary; var UpdateHeader: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateInvoiceDiscountOnBeforeCurrencyInitialize(var CustomerPostingGroup: Record "Customer Posting Group")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateInvoiceDiscountOnBeforeCheckCustInvDiscServiceCharge(var CustInvoiceDisc: Record "Cust. Invoice Disc."; var SalesHeader: Record "Sales Header"; CurrencyDate: Date; ChargeBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateInvoiceDiscountOnBeforeCustInvDiscRecExists(var SalesHeader: Record "Sales Header"; var SalesLine2: Record "Sales Line"; var UpdateHeader: Boolean; var InvDiscBase: Decimal; var ChargeBase: Decimal; var TempVATAmountLine: Record "VAT Amount Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateInvoiceDiscountOnBeforeSalesLine2FindFirst(var SalesLine2: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateInvoiceDiscountOnBeforeSalesLineInsert(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateWithSalesHeader(var SalesLine: Record "Sales Line"; var TempSalesHeader: Record "Sales Header" temporary; var TempSalesLine: Record "Sales Line"; var UpdateHeader: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateInvoiceDiscountOnBeforeSalesLine2DeleteTrue(UpdateHeader: Boolean; var SalesLine2: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeCalculateInvoiceDiscount(var SalesLine: Record "Sales Line"; var TempSalesHeader: Record "Sales Header" temporary; var TempSalesLine: Record "Sales Line" temporary; var UpdateHeader: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateInvoiceDiscountOnBeforeUpdateSalesLine2(var SalesHeader: Record "Sales Header"; var SalesLine2: Record "Sales Line"; UpdateHeader: Boolean; CustInvDisc: Record "Cust. Invoice Disc."; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCustInvDiscRecExists(InvDiscCode: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateInvoiceDiscount(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var UpdateHeader: Boolean)
    begin
    end;
}

