#if not CLEAN28
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.Purchases.History;
using Microsoft.Sales.History;
using Microsoft.Service.History;

codeunit 10148 "Sales Tax Amount Line Calc"
{
    ObsoleteReason = 'Use procedute CalcTaxAmountLine in codeunit SalesTaxCalculate instead.';
    ObsoleteState = Pending;
    ObsoleteTag = '28.0';

    trigger OnRun()
    begin
    end;

    var
        RecRef: RecordRef;
        TaxGroupCodeFieldRef: FieldRef;
        LineType: Option;
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        VATBaseAmount: Decimal;
        LineAmount: Decimal;
        LineQuantity: Decimal;
        TaxLiable: Boolean;
        UseTax: Boolean;

    local procedure Clean()
    begin
        LineType := 0;
        TaxAreaCode := '';
        TaxGroupCode := '';
        VATBaseAmount := 0;
        LineAmount := 0;
        LineQuantity := 0;
        TaxLiable := false;
        UseTax := false;
        Clear(RecRef);
    end;

    procedure InitFromServCrMemoLine(ServiceCrMemoLine: Record "Service Cr.Memo Line")
    begin
        Clean();
        RecRef.GetTable(ServiceCrMemoLine);
        TaxGroupCodeFieldRef := RecRef.Field(ServiceCrMemoLine.FieldNo("Tax Group Code"));
        LineType := ServiceCrMemoLine.Type.AsInteger();
        TaxAreaCode := ServiceCrMemoLine."Tax Area Code";
        TaxGroupCode := ServiceCrMemoLine."Tax Group Code";
        VATBaseAmount := ServiceCrMemoLine."VAT Base Amount";
        LineAmount := ServiceCrMemoLine."Line Amount";
        LineQuantity := ServiceCrMemoLine.Quantity;
        TaxLiable := ServiceCrMemoLine."Tax Liable";
    end;

    procedure InitFromServInvLine(ServiceInvoiceLine: Record "Service Invoice Line")
    begin
        Clean();
        RecRef.GetTable(ServiceInvoiceLine);
        TaxGroupCodeFieldRef := RecRef.Field(ServiceInvoiceLine.FieldNo("Tax Group Code"));
        LineType := ServiceInvoiceLine.Type.AsInteger();
        TaxAreaCode := ServiceInvoiceLine."Tax Area Code";
        TaxGroupCode := ServiceInvoiceLine."Tax Group Code";
        VATBaseAmount := ServiceInvoiceLine."VAT Base Amount";
        LineAmount := ServiceInvoiceLine."Line Amount";
        LineQuantity := ServiceInvoiceLine.Quantity;
        TaxLiable := ServiceInvoiceLine."Tax Liable";
    end;

    procedure InitFromPurchCrMemoLine(PurchCrMemoLine: Record "Purch. Cr. Memo Line")
    begin
        Clean();
        RecRef.GetTable(PurchCrMemoLine);
        TaxGroupCodeFieldRef := RecRef.Field(PurchCrMemoLine.FieldNo("Tax Group Code"));
        LineType := PurchCrMemoLine.Type.AsInteger();
        TaxAreaCode := PurchCrMemoLine."Tax Area Code";
        TaxGroupCode := PurchCrMemoLine."Tax Group Code";
        VATBaseAmount := PurchCrMemoLine."VAT Base Amount";
        LineAmount := PurchCrMemoLine."Line Amount";
        LineQuantity := PurchCrMemoLine."Quantity (Base)";
        TaxLiable := PurchCrMemoLine."Tax Liable";
        UseTax := PurchCrMemoLine."Use Tax";
    end;

    procedure InitFromPurchInvLine(PurchInvLine: Record "Purch. Inv. Line")
    begin
        Clean();
        RecRef.GetTable(PurchInvLine);
        TaxGroupCodeFieldRef := RecRef.Field(PurchInvLine.FieldNo("Tax Group Code"));
        LineType := PurchInvLine.Type.AsInteger();
        TaxAreaCode := PurchInvLine."Tax Area Code";
        TaxGroupCode := PurchInvLine."Tax Group Code";
        VATBaseAmount := PurchInvLine."VAT Base Amount";
        LineAmount := PurchInvLine."Line Amount";
        LineQuantity := PurchInvLine."Quantity (Base)";
        TaxLiable := PurchInvLine."Tax Liable";
        UseTax := PurchInvLine."Use Tax";
    end;

    procedure InitFromSalesCrMemoLine(SalesCrMemoLine: Record "Sales Cr.Memo Line")
    begin
        Clean();
        RecRef.GetTable(SalesCrMemoLine);
        TaxGroupCodeFieldRef := RecRef.Field(SalesCrMemoLine.FieldNo("Tax Group Code"));
        LineType := SalesCrMemoLine.Type.AsInteger();
        TaxAreaCode := SalesCrMemoLine."Tax Area Code";
        TaxGroupCode := SalesCrMemoLine."Tax Group Code";
        VATBaseAmount := SalesCrMemoLine."VAT Base Amount";
        LineAmount := SalesCrMemoLine."Line Amount";
        LineQuantity := SalesCrMemoLine."Quantity (Base)";
        TaxLiable := SalesCrMemoLine."Tax Liable";
    end;

    procedure InitFromSalesInvLine(SalesInvoiceLine: Record "Sales Invoice Line")
    begin
        Clean();
        RecRef.GetTable(SalesInvoiceLine);
        TaxGroupCodeFieldRef := RecRef.Field(SalesInvoiceLine.FieldNo("Tax Group Code"));
        LineType := SalesInvoiceLine.Type.AsInteger();
        TaxAreaCode := SalesInvoiceLine."Tax Area Code";
        TaxGroupCode := SalesInvoiceLine."Tax Group Code";
        VATBaseAmount := SalesInvoiceLine."VAT Base Amount";
        LineAmount := SalesInvoiceLine."Line Amount";
        LineQuantity := SalesInvoiceLine."Quantity (Base)";
        TaxLiable := SalesInvoiceLine."Tax Liable";
    end;

    procedure CalcSalesOrServLineSalesTaxAmountLine(var SalesTaxAmountLine: Record "Sales Tax Amount Line"; var TaxAreaLine: Record "Tax Area Line"; TaxCountry: Option US,CA; var TaxArea: Record "Tax Area"; var TaxJurisdiction: Record "Tax Jurisdiction"; ExchangeFactor: Decimal)
    begin
        SalesTaxAmountLine.Reset();
        if (LineType <> 0) and (TaxAreaCode <> '') then begin
            TaxAreaLine.SetCurrentKey("Tax Area", "Calculation Order");
            TaxAreaLine.SetRange("Tax Area", TaxAreaCode);
            TaxAreaLine.FindSet();
            repeat
                case TaxCountry of
                    TaxCountry::US:
                        // Area Code
                        SalesTaxAmountLine.SetRange("Tax Area Code for Key", TaxAreaCode);
                    TaxCountry::CA:
                        // Jurisdictions
                        SalesTaxAmountLine.SetRange("Tax Area Code for Key", '');
                end;
                TaxGroupCodeFieldRef.TestField();
                SalesTaxAmountLine.SetRange("Tax Group Code", TaxGroupCode);
                SalesTaxAmountLine.SetRange("Tax Jurisdiction Code", TaxAreaLine."Tax Jurisdiction Code");
                if not SalesTaxAmountLine.FindFirst() then begin
                    SalesTaxAmountLine.Init();
                    case TaxCountry of
                        TaxCountry::US:
                            // Area Code
                            SalesTaxAmountLine."Tax Area Code for Key" := TaxAreaCode;
                        TaxCountry::CA:
                            // Jurisdictions
                            SalesTaxAmountLine."Tax Area Code for Key" := '';
                    end;
                    SalesTaxAmountLine."Tax Group Code" := TaxGroupCode;
                    SalesTaxAmountLine."Tax Area Code" := TaxAreaCode;
                    SalesTaxAmountLine."Tax Jurisdiction Code" := TaxAreaLine."Tax Jurisdiction Code";
                    if TaxCountry = TaxCountry::US then begin
                        if SalesTaxAmountLine."Tax Area Code" <> TaxArea.Code then
                            TaxArea.Get(SalesTaxAmountLine."Tax Area Code");
                        SalesTaxAmountLine."Round Tax" := TaxArea."Round Tax";
                        TaxJurisdiction.Get(SalesTaxAmountLine."Tax Jurisdiction Code");
                        SalesTaxAmountLine."Is Report-to Jurisdiction" :=
                          (SalesTaxAmountLine."Tax Jurisdiction Code" = TaxJurisdiction."Report-to Jurisdiction");
                    end;
                    SalesTaxAmountLine."Line Amount" := LineAmount / ExchangeFactor;
                    SetTaxBaseAmount(SalesTaxAmountLine, VATBaseAmount, ExchangeFactor, false);
                    SalesTaxAmountLine.Quantity := LineQuantity;
                    SalesTaxAmountLine."Tax Liable" := TaxLiable;
                    SalesTaxAmountLine.Positive := LineAmount > 0;

                    SalesTaxAmountLine."Calculation Order" := TaxAreaLine."Calculation Order";
                    SalesTaxAmountLine.Insert();
                end else begin
                    SalesTaxAmountLine."Line Amount" := SalesTaxAmountLine."Line Amount" + (LineAmount / ExchangeFactor);
                    SetTaxBaseAmount(SalesTaxAmountLine, VATBaseAmount, ExchangeFactor, true);
                    SalesTaxAmountLine.Quantity := SalesTaxAmountLine.Quantity + LineQuantity;
                    if TaxLiable then
                        SalesTaxAmountLine."Tax Liable" := TaxLiable;
                    SalesTaxAmountLine.Modify();
                end;
            until TaxAreaLine.Next() = 0;
        end;
    end;

    procedure CalcPurchLineSalesTaxAmountLine(var SalesTaxAmountLine: Record "Sales Tax Amount Line"; var TaxAreaLine: Record "Tax Area Line"; TaxCountry: Option US,CA; var TaxArea: Record "Tax Area"; var TaxJurisdiction: Record "Tax Jurisdiction"; ExchangeFactor: Decimal; TaxDetail: Record "Tax Detail"; PostingDate: Date)
    begin
        SalesTaxAmountLine.Reset();
        if (LineType <> 0) and (TaxAreaCode <> '') then begin
            TaxAreaLine.SetCurrentKey("Tax Area", "Calculation Order");
            TaxAreaLine.SetRange("Tax Area", TaxAreaCode);
            TaxAreaLine.FindSet();
            repeat
                case TaxCountry of
                    TaxCountry::US:
                        // Area Code
                        SalesTaxAmountLine.SetRange("Tax Area Code for Key", TaxAreaCode);
                    TaxCountry::CA:
                        // Jurisdictions
                        SalesTaxAmountLine.SetRange("Tax Area Code for Key", '');
                end;
                TaxGroupCodeFieldRef.TestField();
                SalesTaxAmountLine.SetRange("Tax Group Code", TaxGroupCode);
                SalesTaxAmountLine.SetRange("Use Tax", UseTax);
                SalesTaxAmountLine.SetRange("Tax Jurisdiction Code", TaxAreaLine."Tax Jurisdiction Code");
                if not SalesTaxAmountLine.FindFirst() then begin
                    SalesTaxAmountLine.Init();
                    case TaxCountry of
                        TaxCountry::US:
                            // Area Code
                            SalesTaxAmountLine."Tax Area Code for Key" := TaxAreaCode;
                        TaxCountry::CA:
                            // Jurisdictions
                            SalesTaxAmountLine."Tax Area Code for Key" := '';
                    end;
                    SalesTaxAmountLine."Tax Group Code" := TaxGroupCode;
                    SalesTaxAmountLine."Tax Area Code" := TaxAreaCode;
                    SalesTaxAmountLine."Tax Jurisdiction Code" := TaxAreaLine."Tax Jurisdiction Code";
                    if TaxCountry = TaxCountry::US then begin
                        if SalesTaxAmountLine."Tax Area Code" <> TaxArea.Code then
                            TaxArea.Get(SalesTaxAmountLine."Tax Area Code");
                        SalesTaxAmountLine."Round Tax" := TaxArea."Round Tax";
                        TaxJurisdiction.Get(SalesTaxAmountLine."Tax Jurisdiction Code");
                        SalesTaxAmountLine."Is Report-to Jurisdiction" :=
                          (SalesTaxAmountLine."Tax Jurisdiction Code" = TaxJurisdiction."Report-to Jurisdiction");
                    end;
                    SalesTaxAmountLine."Line Amount" := LineAmount / ExchangeFactor;
                    SetTaxBaseAmount(SalesTaxAmountLine, VATBaseAmount, ExchangeFactor, false);
                    SalesTaxAmountLine.Quantity := LineQuantity;
                    SalesTaxAmountLine."Tax Liable" := TaxLiable;
                    SalesTaxAmountLine."Use Tax" := UseTax;

                    TaxDetail.Reset();
                    TaxDetail.SetRange("Tax Jurisdiction Code", SalesTaxAmountLine."Tax Jurisdiction Code");
                    if SalesTaxAmountLine."Tax Group Code" = '' then
                        TaxDetail.SetFilter("Tax Group Code", '%1', SalesTaxAmountLine."Tax Group Code")
                    else
                        TaxDetail.SetFilter("Tax Group Code", '%1|%2', '', SalesTaxAmountLine."Tax Group Code");
                    if PostingDate = 0D then
                        TaxDetail.SetFilter("Effective Date", '<=%1', WorkDate())
                    else
                        TaxDetail.SetFilter("Effective Date", '<=%1', PostingDate);
                    TaxDetail.SetFilter("Tax Type", '%1|%2', TaxDetail."Tax Type"::"Sales and Use Tax",
                      TaxDetail."Tax Type"::"Sales Tax Only");
                    if TaxDetail.FindLast() then
                        SalesTaxAmountLine."Expense/Capitalize" := TaxDetail."Expense/Capitalize";

                    SalesTaxAmountLine."Calculation Order" := TaxAreaLine."Calculation Order";
                    SalesTaxAmountLine.Insert();
                end else begin
                    SalesTaxAmountLine."Line Amount" := SalesTaxAmountLine."Line Amount" + (LineAmount / ExchangeFactor);
                    SetTaxBaseAmount(SalesTaxAmountLine, VATBaseAmount, ExchangeFactor, true);
                    SalesTaxAmountLine.Quantity := SalesTaxAmountLine.Quantity + LineQuantity;
                    if TaxLiable then
                        SalesTaxAmountLine."Tax Liable" := TaxLiable;
                    SalesTaxAmountLine.Modify();
                end;
            until TaxAreaLine.Next() = 0;
        end;
    end;

    procedure SetTaxBaseAmount(var SalesTaxAmountLine: Record "Sales Tax Amount Line"; Value: Decimal; ExchangeFactor: Decimal; Increment: Boolean)
    begin
        if Increment then
            SalesTaxAmountLine."Tax Base Amount FCY" += Value
        else
            SalesTaxAmountLine."Tax Base Amount FCY" := Value;
        SalesTaxAmountLine."Tax Base Amount" := SalesTaxAmountLine."Tax Base Amount FCY" / ExchangeFactor;
    end;
}
#endif
