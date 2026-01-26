// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.Finance.Currency;

page 36740 "Sales Tax Lines Subform Dyn"
{
    Caption = 'Sales Tax Lines';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Sales Tax Amount Line";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Tax Area Code"; Rec."Tax Area Code")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the tax area code used on the sales or purchase lines with this Tax Group Code.';
                    Visible = false;
                }
                field("Tax Group Code"; Rec."Tax Group Code")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the tax group that is used to calculate and post sales tax.';
                }
                field("Tax Jurisdiction Code"; Rec."Tax Jurisdiction Code")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the tax jurisdiction that is used for the Tax Area Code field on the purchase or sales lines.';
                }
                field("Tax Type"; Rec."Tax Type")
                {
                    ToolTip = 'Specifies the type of tax that applies to the entry, such as sales tax, excise tax, or use tax.';
                    Visible = false;
                }
                field("Tax %"; Rec."Tax %")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the Tax Percentage that was used on the sales tax amount lines with this combination of Tax Area Code and Tax Group Code.';
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = SalesTax;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the net amount (excluding tax) for sales or purchase lines matching the combination of Tax Area Code and Tax Group Code.';
                }
                field("Tax Base Amount"; Rec."Tax Base Amount")
                {
                    ApplicationArea = SalesTax;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the net amount (excluding tax) for sales or purchase lines.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ToolTip = 'Specifies the sum of quantities from sales or purchase lines matching the combination of Tax Area Code and Tax Group Code found on this line.';
                    Visible = false;
                }
                field("Tax Amount"; Rec."Tax Amount")
                {
                    ApplicationArea = SalesTax;
                    DecimalPlaces = 2 : 5;
                    Editable = "Tax AmountEditable";
                    ToolTip = 'Specifies the sales tax calculated for this Sales Tax Amount Line.';

                    trigger OnValidate()
                    begin
                        if AllowVATDifference and not AllowVATDifferenceOnThisTab then
                            Error(Text000, Rec.FieldCaption("Tax Amount"));
                        Rec."Amount Including Tax" := Rec."Tax Amount" + Rec."Tax Base Amount";

                        FormCheckVATDifference();
                        Rec.Modified := true;
                        Rec.Modify();
                    end;
                }
                field("Tax Difference"; Rec."Tax Difference")
                {
                    DecimalPlaces = 2 : 5;
                    ToolTip = 'Specifies the difference for the sales tax amount that is used for tax calculations.';
                    Visible = false;
                }
                field("Amount Including Tax"; Rec."Amount Including Tax")
                {
                    ApplicationArea = SalesTax;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the sum of the Tax Base Amount field and the Tax Amount field.';

                    trigger OnValidate()
                    begin
                        FormCheckVATDifference();
                    end;
                }
                field("Expense/Capitalize"; Rec."Expense/Capitalize")
                {
                    ApplicationArea = SalesTax;
                    Editable = false;
                    ToolTip = 'Specifies if the Tax Amount will be debited to an Expense or Capital account, rather than to a Payable or Receivable account.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        "Tax AmountEditable" := true;
    end;

    trigger OnOpenPage()
    begin
        if Rec.FindFirst() then;
    end;

    var
        Text000: Label '%1 can only be modified on the Invoicing tab.';
        Text001: Label 'The total %1 for a document must not exceed %2 = %3.';
        Currency: Record Currency;
        CurrencyCode: Code[10];
        AllowVATDifference: Boolean;
        AllowVATDifferenceOnThisTab: Boolean;
        PricesIncludingVAT: Boolean;
        AllowInvDisc: Boolean;
        VATBaseDiscPct: Decimal;
        "Tax AmountEditable": Boolean;

    procedure SetTempTaxAmountLine(var NewSalesTaxLine: Record "Sales Tax Amount Line" temporary)
    begin
        if NewSalesTaxLine.FindFirst() then
            repeat
                Rec.Copy(NewSalesTaxLine);
                Rec.Insert();
            until NewSalesTaxLine.Next() = 0;
        CurrPage.Update();
    end;

    procedure GetTempTaxAmountLine(var NewSalesTaxLine: Record "Sales Tax Amount Line" temporary)
    begin
        NewSalesTaxLine.DeleteAll();
        if Rec.FindFirst() then
            repeat
                NewSalesTaxLine.Copy(Rec);
                NewSalesTaxLine.Insert();
            until Rec.Next() = 0;
    end;

    procedure InitGlobals(NewCurrencyCode: Code[10]; NewAllowVATDifference: Boolean; NewAllowVATDifferenceOnThisTab: Boolean; NewPricesIncludingVAT: Boolean; NewAllowInvDisc: Boolean; NewVATBaseDiscPct: Decimal)
    begin
        CurrencyCode := NewCurrencyCode;
        AllowVATDifference := NewAllowVATDifference;
        AllowVATDifferenceOnThisTab := NewAllowVATDifferenceOnThisTab;
        PricesIncludingVAT := NewPricesIncludingVAT;
        AllowInvDisc := NewAllowInvDisc;
        VATBaseDiscPct := NewVATBaseDiscPct;
        "Tax AmountEditable" := NewAllowVATDifference;
        Currency.Initialize(CurrencyCode);

        OnAfterInitGlobals("Tax AmountEditable");
        CurrPage.Update();
    end;

    procedure FormCheckVATDifference()
    var
        TaxAmountLine2: Record "Sales Tax Amount Line";
        TotalVATDifference: Decimal;
    begin
        Rec.CheckTaxDifference(CurrencyCode, AllowVATDifference, PricesIncludingVAT);
        TaxAmountLine2 := Rec;
        TotalVATDifference := Abs(Rec."Tax Difference") - Abs(xRec."Tax Difference");
        if Rec.Find('-') then
            repeat
                TotalVATDifference := TotalVATDifference + Abs(Rec."Tax Difference");
            until Rec.Next() = 0;
        Rec := TaxAmountLine2;
        if TotalVATDifference > Currency."Max. VAT Difference Allowed" then
            Error(
              Text001, Rec.FieldCaption("Tax Difference"),
              Currency.FieldCaption("Max. VAT Difference Allowed"), Currency."Max. VAT Difference Allowed");
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInitGlobals(var TaxAmountEditable: Boolean)
    begin
    end;
}

