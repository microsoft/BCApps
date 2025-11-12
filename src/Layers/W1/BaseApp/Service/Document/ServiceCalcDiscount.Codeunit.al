// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Finance.Currency;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;

codeunit 5950 "Service-Calc. Discount"
{
    TableNo = "Service Line";

    trigger OnRun()
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.Copy(Rec);

        TempServHeader.Get(Rec."Document Type", Rec."Document No.");
        TemporaryHeader := false;
        CalculateInvoiceDiscount(TempServHeader, ServiceLine, TempServiceLine);

        Rec := ServiceLine;
    end;

    var
        TempServHeader: Record "Service Header";
        TempServiceLine: Record "Service Line";
        CustInvDisc: Record "Cust. Invoice Disc.";
        CustPostingGr: Record "Customer Posting Group";
        Currency: Record Currency;
        InvDiscBase: Decimal;
        ChargeBase: Decimal;
        CurrencyDate: Date;
        TemporaryHeader: Boolean;
        CustInvDiscFound: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Service Charge';
#pragma warning restore AA0074

    local procedure CalculateInvoiceDiscount(var ServHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var ServiceLine2: Record "Service Line")
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        SalesSetup: Record "Sales & Receivables Setup";
        DiscountNotificationMgt: Codeunit "Discount Notification Mgt.";
        ServiceChargeLineNo: Integer;
        ApplyServiceCharge, IsHandled : Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcServDiscount(ServHeader, ServiceLine, ServiceLine2, TemporaryHeader, IsHandled);
        if not IsHandled then begin
            SalesSetup.Get();
            ServiceLine.LockTable();
            ServHeader.TestField("Customer Posting Group");
            CustPostingGr.Get(ServHeader."Customer Posting Group");

            IsHandled := false;
            OnCalculateInvoiceDiscountOnBeforeIsServiceChargeUpdated(ServiceLine, CustPostingGr, IsHandled);
            if not IsHandled then
                if not IsServiceChargeUpdated(ServiceLine) then begin
                    ServiceLine2.Reset();
                    ServiceLine2.SetRange("Document Type", ServiceLine."Document Type");
                    ServiceLine2.SetRange("Document No.", ServiceLine."Document No.");
                    ServiceLine2.SetRange("System-Created Entry", true);
                    ServiceLine2.SetRange(Type, ServiceLine2.Type::"G/L Account");
                    ServiceLine2.SetRange("No.", CustPostingGr.GetServiceChargeAccount());
                    if ServiceLine2.Find('+') then begin
                        ServiceChargeLineNo := ServiceLine2."Line No.";
                        ServiceLine2.Validate("Unit Price", 0);
                        ServiceLine2.Modify();
                    end;
                    ApplyServiceCharge := true;
                end;

            ServiceLine2.Reset();
            ServiceLine2.SetRange("Document Type", ServiceLine."Document Type");
            ServiceLine2.SetRange("Document No.", ServiceLine."Document No.");
            ServiceLine2.SetFilter(Type, '<>0');
            OnCalculateInvoiceDiscountOnAfterSetServiceLineFilters(ServiceLine2);
            if ServiceLine2.Find('-') then;
            ServiceLine2.CalcVATAmountLines(0, ServHeader, ServiceLine2, TempVATAmountLine, false);
            InvDiscBase :=
              TempVATAmountLine.GetTotalInvDiscBaseAmount(
                ServHeader."Prices Including VAT", ServHeader."Currency Code");
            ChargeBase :=
              TempVATAmountLine.GetTotalLineAmount(
                ServHeader."Prices Including VAT", ServHeader."Currency Code");

            if not TemporaryHeader then
                ServHeader.Modify();

            if (ServiceLine."Document Type" in [ServiceLine."Document Type"::Quote]) and
               (ServHeader."Posting Date" = 0D)
            then
                CurrencyDate := WorkDate()
            else
                CurrencyDate := ServHeader."Posting Date";

            CustInvDiscFound := CustInvDisc.GetRecord(ServHeader."Invoice Disc. Code", ServHeader."Currency Code", CurrencyDate, ChargeBase);

            OnCalculateInvoiceDiscountOnBeforeApplyServiceCharge(CustInvDisc, ServHeader, CurrencyDate, ChargeBase, ApplyServiceCharge);

            if ApplyServiceCharge then
                if CustInvDiscFound and (CustInvDisc."Service Charge" <> 0) then begin
                    Currency.Initialize(ServHeader."Currency Code");
                    if TemporaryHeader then
                        ServiceLine2.SetServHeader(ServHeader);
                    if ServiceChargeLineNo <> 0 then begin
                        ServiceLine2.Get(ServiceLine."Document Type", ServiceLine."Document No.", ServiceChargeLineNo);
                        if ServHeader."Prices Including VAT" then
                            ServiceLine2.Validate(
                              "Unit Price",
                              Round(
                                (1 + ServiceLine2."VAT %" / 100) * CustInvDisc."Service Charge",
                                Currency."Unit-Amount Rounding Precision"))
                        else
                            ServiceLine2.Validate("Unit Price", CustInvDisc."Service Charge");
                        ServiceLine2.Modify();
                    end else begin
                        ServiceLine2.Reset();
                        ServiceLine2.SetRange("Document Type", ServiceLine."Document Type");
                        ServiceLine2.SetRange("Document No.", ServiceLine."Document No.");
                        ServiceLine2.Find('+');
                        ServiceLine2.Init();
                        if TemporaryHeader then
                            ServiceLine2.SetServHeader(ServHeader);
                        ServiceLine2."Line No." := ServiceLine2."Line No." + GetNewServiceLineNoBias(ServiceLine2);
                        ServiceLine2.Type := ServiceLine2.Type::"G/L Account";
                        ServiceLine2.Validate("No.", CustPostingGr.GetServiceChargeAccount());
                        ServiceLine2.Description := Text000;
                        ServiceLine2.Validate(Quantity, 1);
                        OnCalculateInvoiceDiscountOnAfterServiceLine2ValidateQuantity(ServHeader, ServiceLine2, CustInvDisc);
                        if ServHeader."Prices Including VAT" then
                            ServiceLine2.Validate(
                              "Unit Price",
                              Round(
                                (1 + ServiceLine2."VAT %" / 100) * CustInvDisc."Service Charge",
                                Currency."Unit-Amount Rounding Precision"))
                        else
                            ServiceLine2.Validate("Unit Price", CustInvDisc."Service Charge");
                        ServiceLine2."System-Created Entry" := true;
                        OnCalculateInvoiceDiscountOnBeforeServiceLineInsert(ServiceLine2, ServHeader);
                        ServiceLine2.Insert();
                    end;
                    ServiceLine2.CalcVATAmountLines(0, ServHeader, ServiceLine2, TempVATAmountLine, false);
                end else
                    if ServiceChargeLineNo <> 0 then begin
                        ServiceLine2.Get(ServiceLine."Document Type", ServiceLine."Document No.", ServiceChargeLineNo);
                        IsHandled := false;
                        OnCalculateInvoiceDiscountOnBeforeServiceLine2Delete(ServiceLine2, TemporaryHeader, IsHandled);
                        if not IsHandled then
                            ServiceLine2.Delete(true);
                    end;

            OnCalculateInvoiceDiscountOnAfterApplyServiceCharge(CustInvDisc, ServHeader, ServiceLine2, CurrencyDate, TemporaryHeader);

            if CustInvDiscRecExists(ServHeader."Invoice Disc. Code") then begin
                if InvDiscBase <> ChargeBase then
                    CustInvDisc.GetRecord(ServHeader."Invoice Disc. Code", ServHeader."Currency Code", CurrencyDate, InvDiscBase);

                DiscountNotificationMgt.NotifyAboutMissingSetup(
                  SalesSetup.RecordId, ServHeader."Gen. Bus. Posting Group", ServiceLine2."Gen. Prod. Posting Group",
                  SalesSetup."Discount Posting", SalesSetup."Discount Posting"::"Line Discounts");

                ServHeader."Invoice Discount Calculation" := ServHeader."Invoice Discount Calculation"::"%";
                ServHeader."Invoice Discount Value" := CustInvDisc."Discount %";
                if not TemporaryHeader then
                    ServHeader.Modify();

                TempVATAmountLine.SetInvoiceDiscountPercent(
                  CustInvDisc."Discount %", ServHeader."Currency Code",
                  ServHeader."Prices Including VAT", SalesSetup."Calc. Inv. Disc. per VAT ID",
                  ServHeader."VAT Base Discount %");

                ServiceLine2.SetServHeader(ServHeader);
                ServiceLine2.UpdateVATOnLines(0, ServHeader, ServiceLine2, TempVATAmountLine);
            end else begin
                ServHeader."Invoice Discount Calculation" := ServHeader."Invoice Discount Calculation"::"%";
                ServHeader."Invoice Discount Value" := CustInvDisc."Discount %";
                if not TemporaryHeader then
                    ServHeader.Modify();

                TempVATAmountLine.SetInvoiceDiscountPercent(
                  CustInvDisc."Discount %", ServHeader."Currency Code",
                  ServHeader."Prices Including VAT", SalesSetup."Calc. Inv. Disc. per VAT ID",
                  ServHeader."VAT Base Discount %");

                ServiceLine2.SetServHeader(ServHeader);
                ServiceLine2.UpdateVATOnLines(0, ServHeader, ServiceLine2, TempVATAmountLine);
            end;
        end;
        OnAfterCalcServDiscount(ServHeader, TempVATAmountLine, ServiceLine2);
    end;

    local procedure CustInvDiscRecExists(InvDiscCode: Code[20]): Boolean
    var
        CustInvDisc2: Record "Cust. Invoice Disc.";
    begin
        CustInvDisc2.SetRange(Code, InvDiscCode);
        exit(not CustInvDisc2.IsEmpty());
    end;

    procedure CalculateWithServHeader(var TempServHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var TempServiceLine: Record "Service Line")
    begin
        TemporaryHeader := true;
        if ServiceLine.Get(TempServiceLine."Document Type", TempServiceLine."Document No.", TempServiceLine."Line No.") then
            CalculateInvoiceDiscount(TempServHeader, ServiceLine, TempServiceLine);
    end;

    procedure CalculateIncDiscForHeader(var TempServiceHeader: Record "Service Header")
    var
        SalesSetup: Record "Sales & Receivables Setup";
        ServiceLine: Record "Service Line";
        ServiceLine2: Record "Service Line";
    begin
        SalesSetup.Get();
        if not SalesSetup."Calc. Inv. Discount" then
            exit;
        ServiceLine2."Document Type" := TempServiceHeader."Document Type";
        ServiceLine2."Document No." := TempServiceHeader."No.";
        ServiceLine.Copy(ServiceLine2);
        CalculateInvoiceDiscount(TempServiceHeader, ServiceLine2, ServiceLine);
    end;

    local procedure GetNewServiceLineNoBias(ServiceLineParam: Record "Service Line"): Integer
    var
        ServLin: Record "Service Line";
        LineAdd: Integer;
    begin
        LineAdd := 10000;
        while ServLin.Get(ServiceLineParam."Document Type", ServiceLineParam."Document No.", ServiceLineParam."Line No." + LineAdd) and
              (LineAdd > 1)
        do
            LineAdd := Round(LineAdd / 2, 1, '<');
        exit(LineAdd);
    end;

    local procedure IsServiceChargeUpdated(ServiceLine: Record "Service Line"): Boolean
    var
        ServiceLine2: Record "Service Line";
    begin
        ServiceLine2.Reset();
        ServiceLine2.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine2.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine2.SetRange("System-Created Entry", true);
        ServiceLine2.SetRange(Type, ServiceLine2.Type::"G/L Account");
        ServiceLine2.SetRange("No.", CustPostingGr."Service Charge Acc.");
        exit(not ServiceLine2.IsEmpty());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcServDiscount(var ServiceHeader: Record "Service Header"; var TempVATAmountLine: Record "VAT Amount Line" temporary; var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcServDiscount(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var ServiceLine2: Record "Service Line"; TemporaryHeader: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateInvoiceDiscountOnBeforeServiceLine2Delete(var ServiceLine: Record "Service Line"; TemporaryHeader: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateInvoiceDiscountOnAfterServiceLine2ValidateQuantity(var ServiceHeader: Record "Service Header"; var ServiceLine2: Record "Service Line"; var CustInvDisc: Record "Cust. Invoice Disc.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateInvoiceDiscountOnBeforeServiceLineInsert(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateInvoiceDiscountOnBeforeApplyServiceCharge(var CustInvoiceDisc: Record "Cust. Invoice Disc."; var ServiceHeader: Record "Service Header"; CurrencyDate: Date; ChargeBase: Decimal; var ApplyServiceCharge: Boolean)
    begin
    end;

    [InternalEvent(false)]
    local procedure OnCalculateInvoiceDiscountOnAfterApplyServiceCharge(var CustInvoiceDisc: Record "Cust. Invoice Disc."; var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; CurrencyDate: Date; TemporaryHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateInvoiceDiscountOnBeforeIsServiceChargeUpdated(var ServiceLine: Record "Service Line"; CustomerPostingGroup: Record "Customer Posting Group"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateInvoiceDiscountOnAfterSetServiceLineFilters(var ServiceLine: Record "Service Line")
    begin
    end;
}

