// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.Finance.Currency;
using Microsoft.Service.Document;
using Microsoft.Service.History;

codeunit 5968 "Serv. Sales Tax Calculate"
{
    Permissions = TableData "Service Header" = rim,
                  TableData "Service Line" = rim;

    var
        Currency: Record Currency;
        ServiceHeader: Record "Service Header";
        SalesTaxAmountDifference: Record "Sales Tax Amount Difference";
        TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary;
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        ExchangeFactor: Decimal;
        TotalTaxAmountRounding: Decimal;
        ServHeaderRead: Boolean;

    procedure StartSalesTaxCalculation()
    begin
        TempSalesTaxAmountLine.Reset();
        TempSalesTaxAmountLine.DeleteAll();
        ClearAll();

        SalesTaxCalculate.StartSalesTaxCalculation();
    end;

    procedure CallExternalTaxEngineForServ(var ServiceHeader2: Record "Service Header"; UpdateRecIfChanged: Boolean) STETransactionIDChanged: Boolean
    var
        OldTransactionID: Text[20];
    begin
        OldTransactionID := ServiceHeader2."STE Transaction ID";
        ServiceHeader2."STE Transaction ID" := CallExternalTaxEngineForDoc(DATABASE::"Service Header", ServiceHeader2."Document Type".AsInteger(), ServiceHeader2."No.");
        STETransactionIDChanged := (ServiceHeader2."STE Transaction ID" <> OldTransactionID);
        if STETransactionIDChanged and UpdateRecIfChanged then
            ServiceHeader2.Modify();
    end;

    procedure CallExternalTaxEngineForDoc(DocTable: Integer; DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"; DocNo: Code[20]) STETransactionID: Text[20]
    begin
        exit(SalesTaxCalculate.CallExternalTaxEngineForDoc(DocTable, DocType, DocNo));
    end;

    procedure EndSalesTaxCalculation(PostingDate: Date)
    begin
        SalesTaxCalculate.SetExchangeFactor(ExchangeFactor);
        SalesTaxCalculate.EndSalesTaxCalculation(PostingDate);
        SalesTaxCalculate.GetSalesTaxAmountLineTable(TempSalesTaxAmountLine);
    end;

    procedure GetSummarizedSalesTaxTable(var TempSummarizedSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary);
    begin
        SalesTaxCalculate.GetSummarizedSalesTaxTable(TempSummarizedSalesTaxAmountLine);
    end;

    procedure AddServiceLine(ServiceLine: Record "Service Line")
    var
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        OnBeforeAddServiceLine(ServiceLine);
        if not ServHeaderRead then begin
            ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
            ServHeaderRead := true;
            ServiceHeader.TestField("Prices Including VAT", false);
            if not SalesTaxCalculate.GetSalesTaxCountry(ServiceHeader."Tax Area Code") then
                exit;
            SetUpCurrency(ServiceHeader."Currency Code");
            if ServiceHeader."Currency Code" <> '' then
                ServiceHeader.TestField("Currency Factor");
            if ServiceHeader."Currency Factor" = 0 then
                ExchangeFactor := 1
            else
                ExchangeFactor := ServiceHeader."Currency Factor";

            SalesTaxCalculate.CopyTaxDifferencesToTemp(
                Enum::"Sales Tax Document Area"::Service, ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.");
        end;
        if not SalesTaxCalculate.GetSalesTaxCountry(ServiceLine."Tax Area Code") then
            exit;

        ServiceLine.TestField("Tax Group Code");

        TempSalesTaxAmountLine.Reset();
        case SalesTaxCalculate.GetTaxCountry() of
            "Sales Tax Country"::US:
                // Area Code
                begin
                    TempSalesTaxAmountLine.SetRange("Tax Area Code for Key", ServiceLine."Tax Area Code");
                    TempSalesTaxAmountLine."Tax Area Code for Key" := ServiceLine."Tax Area Code";
                end;
            "Sales Tax Country"::CA:
                // Jurisdictions
                begin
                    TempSalesTaxAmountLine.SetRange("Tax Area Code for Key", '');
                    TempSalesTaxAmountLine."Tax Area Code for Key" := '';
                end;
        end;
        TempSalesTaxAmountLine.SetRange("Tax Group Code", ServiceLine."Tax Group Code");
        TaxAreaLine.SetCurrentKey("Tax Area", "Calculation Order");
        TaxAreaLine.SetRange("Tax Area", ServiceLine."Tax Area Code");
        OnAddServiceLineOnAfterTempSalesTaxAmountLineSetFilters(TempSalesTaxAmountLine);
        if TaxAreaLine.FindSet() then
            repeat
                TempSalesTaxAmountLine.SetRange("Tax Jurisdiction Code", TaxAreaLine."Tax Jurisdiction Code");
                TempSalesTaxAmountLine."Tax Jurisdiction Code" := TaxAreaLine."Tax Jurisdiction Code";
                OnAddServiceLineOnAfterSetSalesTaxAmountLineFilter(TempSalesTaxAmountLine, ServiceLine, TaxAreaLine);
                if not TempSalesTaxAmountLine.FindFirst() then begin
                    TempSalesTaxAmountLine.Init();
                    TempSalesTaxAmountLine."Tax Group Code" := ServiceLine."Tax Group Code";
                    TempSalesTaxAmountLine."Tax Area Code" := ServiceLine."Tax Area Code";
                    TempSalesTaxAmountLine."Tax Jurisdiction Code" := TaxAreaLine."Tax Jurisdiction Code";
                    if SalesTaxCalculate.GetTaxCountry() = "Sales Tax Country"::US then begin
                        TaxArea.Get(ServiceLine."Tax Area Code");
                        TempSalesTaxAmountLine."Round Tax" := TaxArea."Round Tax";
                        TaxJurisdiction.Get(TempSalesTaxAmountLine."Tax Jurisdiction Code");
                        TempSalesTaxAmountLine."Is Report-to Jurisdiction" := (TempSalesTaxAmountLine."Tax Jurisdiction Code" = TaxJurisdiction."Report-to Jurisdiction");
                    end;
                    SetTaxBaseAmount(
                        TempSalesTaxAmountLine, ServiceLine."Line Amount" - ServiceLine."Inv. Discount Amount", ExchangeFactor, false);
                    TempSalesTaxAmountLine."Line Amount" := ServiceLine."Line Amount" / ExchangeFactor;
                    TempSalesTaxAmountLine."Tax Liable" := ServiceLine."Tax Liable";
                    TempSalesTaxAmountLine.Quantity := ServiceLine."Quantity (Base)";
                    TempSalesTaxAmountLine."Invoice Discount Amount" := ServiceLine."Inv. Discount Amount";
                    TempSalesTaxAmountLine."Calculation Order" := TaxAreaLine."Calculation Order";
                    TempSalesTaxAmountLine.Insert();
                end else begin
                    TempSalesTaxAmountLine."Line Amount" := TempSalesTaxAmountLine."Line Amount" + (ServiceLine."Line Amount" / ExchangeFactor);
                    TempSalesTaxAmountLine."Tax Liable" := ServiceLine."Tax Liable";
                    SetTaxBaseAmount(
                        TempSalesTaxAmountLine, ServiceLine."Line Amount" - ServiceLine."Inv. Discount Amount", ExchangeFactor, true);
                    TempSalesTaxAmountLine."Tax Amount" := 0;
                    TempSalesTaxAmountLine.Quantity := TempSalesTaxAmountLine.Quantity + ServiceLine."Quantity (Base)";
                    TempSalesTaxAmountLine."Invoice Discount Amount" := TempSalesTaxAmountLine."Invoice Discount Amount" + ServiceLine."Inv. Discount Amount";
                    TempSalesTaxAmountLine.Modify();
                end;
            until TaxAreaLine.Next() = 0;

        SalesTaxCalculate.SetSalesTaxAmountLineTable(TempSalesTaxAmountLine);
        OnAfterAddServiceLine(TempSalesTaxAmountLine, ServiceLine)
    end;

    procedure AddServInvoiceLines(DocNo: Code[20])
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        ServiceInvoiceHeader.Get(DocNo);
        ServiceInvoiceHeader.TestField("Prices Including VAT", false);
        if not SalesTaxCalculate.GetSalesTaxCountry(ServiceInvoiceHeader."Tax Area Code") then
            exit;
        SetUpCurrency(ServiceInvoiceHeader."Currency Code");
        if ServiceInvoiceHeader."Currency Factor" = 0 then
            ExchangeFactor := 1
        else
            ExchangeFactor := ServiceInvoiceHeader."Currency Factor";

        ServiceInvoiceLine.SetRange("Document No.", DocNo);
        ServiceInvoiceLine.SetFilter("Tax Group Code", '<>%1', '');
        if ServiceInvoiceLine.FindSet() then
            repeat
                ServiceInvoiceLine.TestField("Tax Group Code");
                SalesTaxCalculate.CalcSalesTaxAmountLine(
                    TempSalesTaxAmountLine, SalesTaxCalculate.GetTaxCountry(), ExchangeFactor,
                    ServiceInvoiceLine."Tax Area Code", ServiceInvoiceLine."Tax Group Code", ServiceInvoiceLine.Type.AsInteger(),
                    ServiceInvoiceLine."Line Amount", ServiceInvoiceLine."VAT Base Amount", ServiceInvoiceLine."Quantity (Base)",
                    ServiceInvoiceLine."Posting Date", ServiceInvoiceLine."Tax Liable", false, "Sales Tax Document Area"::"Posted Service");
            until ServiceInvoiceLine.Next() = 0;

        SalesTaxCalculate.CopyTaxDifferencesToTemp(
          Enum::"Sales Tax Document Area"::"Posted Service", SalesTaxAmountDifference."Document Type"::Invoice, ServiceInvoiceHeader."No.");
    end;

    procedure AddServCrMemoLines(DocNo: Code[20])
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        ServiceCrMemoHeader.Get(DocNo);
        ServiceCrMemoHeader.TestField("Prices Including VAT", false);
        if not SalesTaxCalculate.GetSalesTaxCountry(ServiceCrMemoHeader."Tax Area Code") then
            exit;
        SetUpCurrency(ServiceCrMemoHeader."Currency Code");
        if ServiceCrMemoHeader."Currency Factor" = 0 then
            ExchangeFactor := 1
        else
            ExchangeFactor := ServiceCrMemoHeader."Currency Factor";

        ServiceCrMemoLine.SetRange("Document No.", DocNo);
        ServiceCrMemoLine.SetFilter("Tax Group Code", '<>%1', '');
        if ServiceCrMemoLine.FindSet() then
            repeat
                ServiceCrMemoLine.TestField("Tax Group Code");
                SalesTaxCalculate.CalcSalesTaxAmountLine(
                    TempSalesTaxAmountLine, SalesTaxCalculate.GetTaxCountry(), ExchangeFactor,
                    ServiceCrMemoLine."Tax Area Code", ServiceCrMemoLine."Tax Group Code", ServiceCrMemoLine.Type.AsInteger(),
                    ServiceCrMemoLine."Line Amount", ServiceCrMemoLine."VAT Base Amount", ServiceCrMemoLine."Quantity (Base)",
                    ServiceCrMemoLine."Posting Date", ServiceCrMemoLine."Tax Liable", false, "Sales Tax Document Area"::"Posted Service");
            until ServiceCrMemoLine.Next() = 0;

        SalesTaxCalculate.CopyTaxDifferencesToTemp(
          Enum::"Sales Tax Document Area"::"Posted Service", SalesTaxAmountDifference."Document Type"::"Credit Memo", ServiceCrMemoHeader."No.");
    end;

    procedure DistTaxOverServLines(var ServLine: Record "Service Line")
    var
        TaxAreaLine: Record "Tax Area Line";
        TempSalesTaxLine2: Record "Sales Tax Amount Line" temporary;
        TempServiceLine2: Record "Service Line" temporary;
        TaxCountry: Enum "Sales Tax Country";
        TaxAmount: Decimal;
        Amount: Decimal;
        ReturnTaxAmount: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDistTaxOverServLines(ServLine, IsHandled);
#if not CLEAN27
        SalesTaxCalculate.RunOnBeforeDistTaxOverServLines(ServLine, IsHandled);
#endif
        if IsHandled then
            exit;

        TotalTaxAmountRounding := 0;
        if not ServHeaderRead then begin
            if not ServiceHeader.Get(ServLine."Document Type", ServLine."Document No.") then
                exit;
            ServHeaderRead := true;
            SetUpCurrency(ServiceHeader."Currency Code");
            if ServiceHeader."Currency Factor" = 0 then
                ExchangeFactor := 1
            else
                ExchangeFactor := ServiceHeader."Currency Factor";
            if not SalesTaxCalculate.GetSalesTaxCountry(ServiceHeader."Tax Area Code") then
                exit;
            TaxCountry := SalesTaxCalculate.GetTaxCountry();
        end;

        TempSalesTaxAmountLine.Reset();
        if TempSalesTaxAmountLine.FindSet() then
            repeat
                if (TempSalesTaxAmountLine."Tax Jurisdiction Code" <> TempSalesTaxLine2."Tax Jurisdiction Code") and SalesTaxCalculate.GetRoundByJurisdiction() then begin
                    TempSalesTaxLine2."Tax Jurisdiction Code" := TempSalesTaxAmountLine."Tax Jurisdiction Code";
                    TotalTaxAmountRounding := 0;
                end;
                if TaxCountry = "Sales Tax Country"::US then
                    ServLine.SetRange("Tax Area Code", TempSalesTaxAmountLine."Tax Area Code");
                ServLine.SetRange("Tax Group Code", TempSalesTaxAmountLine."Tax Group Code");
                ServLine.SetCurrentKey(Amount);
                ServLine.FindSet(true);
                repeat
                    if (TaxCountry = "Sales Tax Country"::US) or
                        ((TaxCountry = "Sales Tax Country"::CA) and TaxAreaLine.Get(ServLine."Tax Area Code", TempSalesTaxAmountLine."Tax Jurisdiction Code"))
                    then begin
                        if TempSalesTaxAmountLine."Tax Type" = TempSalesTaxAmountLine."Tax Type"::"Sales and Use Tax" then begin
                            Amount := (ServLine."Line Amount" - ServLine."Inv. Discount Amount");
                            TaxAmount := Amount * TempSalesTaxAmountLine."Tax %" / 100;
                        end else
                            if (ServLine."Quantity (Base)" = 0) or (TempSalesTaxAmountLine.Quantity = 0) then
                                TaxAmount := 0
                            else
                                TaxAmount := TempSalesTaxAmountLine."Tax Amount" * ExchangeFactor * ServLine."Quantity (Base)" / TempSalesTaxAmountLine.Quantity;
                        if TaxAmount = 0 then
                            ReturnTaxAmount := 0
                        else begin
                            ReturnTaxAmount := Round(TaxAmount + TotalTaxAmountRounding, Currency."Amount Rounding Precision");
                            TotalTaxAmountRounding := TaxAmount + TotalTaxAmountRounding - ReturnTaxAmount;
                        end;
                        ServLine.Amount :=
                        ServLine."Line Amount" - ServLine."Inv. Discount Amount";
                        ServLine."VAT Base Amount" := ServLine.Amount;
                        if TempServiceLine2.Get(ServLine."Document Type", ServLine."Document No.", ServLine."Line No.") then begin
                            TempServiceLine2."Amount Including VAT" := TempServiceLine2."Amount Including VAT" + ReturnTaxAmount;
                            TempServiceLine2.Modify();
                        end else begin
                            TempServiceLine2.Copy(ServLine);
                            TempServiceLine2."Amount Including VAT" := ServLine.Amount + ReturnTaxAmount;
                            TempServiceLine2.Insert();
                        end;
                        if ServLine."Tax Liable" then
                            ServLine."Amount Including VAT" := TempServiceLine2."Amount Including VAT"
                        else
                            ServLine."Amount Including VAT" := ServLine.Amount;
                        if ServLine.Amount <> 0 then
                            ServLine."VAT %" :=
                            Round(100 * (ServLine."Amount Including VAT" - ServLine.Amount) / ServLine.Amount, 0.00001)
                        else
                            ServLine."VAT %" := 0;
                        ServLine.Modify();
                    end;
                until ServLine.Next() = 0;
            until TempSalesTaxAmountLine.Next() = 0;

        ServLine.SetRange("Tax Area Code");
        ServLine.SetRange("Tax Group Code");
        ServLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServLine.SetRange("Document No.", ServiceHeader."No.");
        if ServLine.FindSet(true) then
            repeat
                ServLine."Amount Including VAT" := Round(ServLine."Amount Including VAT", Currency."Amount Rounding Precision");
                ServLine.Amount :=
                  Round(ServLine."Line Amount" - ServLine."Inv. Discount Amount", Currency."Amount Rounding Precision");
                ServLine."VAT Base Amount" := ServLine.Amount;
                ServLine.Modify();
            until ServLine.Next() = 0;
    end;

    procedure GetSalesTaxAmountLineTable(var TempSalesTaxAmountLineTo: Record "Sales Tax Amount Line" temporary)
    begin
        TempSalesTaxAmountLineTo.DeleteAll();
        TempSalesTaxAmountLine.Reset();
        if TempSalesTaxAmountLine.FindSet() then
            repeat
                TempSalesTaxAmountLineTo.Copy(TempSalesTaxAmountLine);
                TempSalesTaxAmountLineTo.Insert();
            until TempSalesTaxAmountLine.Next() = 0;
    end;

    procedure PutSalesTaxAmountLineTable(var TempSalesTaxAmountLine2: Record "Sales Tax Amount Line" temporary; ProductArea: Integer; DocumentType: Integer; DocumentNo: Code[20])
    begin
        TempSalesTaxAmountLine.Reset();
        TempSalesTaxAmountLine.DeleteAll();
        if TempSalesTaxAmountLine2.FindSet() then
            repeat
                TempSalesTaxAmountLine.Copy(TempSalesTaxAmountLine2);
                TempSalesTaxAmountLine.Insert();
            until TempSalesTaxAmountLine2.Next() = 0;

        SalesTaxCalculate.PutSalesTaxAmountLineTable(TempSalesTaxAmountLine2, ProductArea, DocumentType, DocumentNo);
    end;

    procedure SaveTaxDifferences()
    begin
        SalesTaxCalculate.SaveTaxDifferences();
    end;

    local procedure SetTaxBaseAmount(var SalesTaxAmountLine: Record "Sales Tax Amount Line"; Value: Decimal; ExchangeFactor2: Decimal; Increment: Boolean)
    begin
        if Increment then
            SalesTaxAmountLine."Tax Base Amount FCY" += Value
        else
            SalesTaxAmountLine."Tax Base Amount FCY" := Value;
        SalesTaxAmountLine."Tax Base Amount" := SalesTaxAmountLine."Tax Base Amount FCY" / ExchangeFactor2;
    end;

    local procedure SetUpCurrency(CurrencyCode: Code[10])
    begin
        if CurrencyCode = '' then
            Currency.InitRoundingPrecision()
        else begin
            Currency.Get(CurrencyCode);
            Currency.TestField("Amount Rounding Precision");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDistTaxOverServLines(var ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddServiceLine(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddServiceLineOnAfterTempSalesTaxAmountLineSetFilters(var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddServiceLineOnAfterSetSalesTaxAmountLineFilter(var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary; ServiceLine: Record "Service Line"; TaxAreaLine: Record "Tax Area Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddServiceLine(var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary; ServiceLine: Record "Service Line")
    begin
    end;
}
