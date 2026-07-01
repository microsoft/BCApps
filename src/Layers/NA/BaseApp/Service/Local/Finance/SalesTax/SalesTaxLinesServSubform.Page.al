// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.Finance.Currency;

page 10060 "Sales Tax Lines Serv. Subform"
{
    Caption = 'Sales Tax Lines Serv. Subform';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Sales Tax Amount Line";

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
                }
                field("Tax Group Code"; Rec."Tax Group Code")
                {
                    ToolTip = 'Specifies the Tax Group Code from the sales or purchase lines.';
                }
                field("Tax Jurisdiction Code"; Rec."Tax Jurisdiction Code")
                {
                    ToolTip = 'Specifies the Tax Jurisdiction Code from the Tax Area Lines table, for the Tax Area Code field on the purchase or sales lines';
                }
                field("Tax Type"; Rec."Tax Type")
                {
                    ToolTip = 'Specifies the type of tax that applies to the entry, such as sales tax, excise tax, or use tax.';
                    Visible = false;
                }
                field("Tax %"; Rec."Tax %")
                {
                    ToolTip = 'Specifies the Tax Percentage that was used on the sales tax amount lines with this combination of Tax Area Code and Tax Group Code.';
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the net amount (excluding tax) for sales or purchase lines matching the combination of Tax Area Code and Tax Group Code.';
                }
                field("Tax Base Amount"; Rec."Tax Base Amount")
                {
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
                    DecimalPlaces = 2 : 5;
                    Editable = "Tax AmountEditable";
                    ToolTip = 'Specifies the sales tax calculated for this Sales Tax Amount Line.';

                    trigger OnValidate()
                    begin
                        if AllowVATDifference and not AllowVATDifferenceOnThisTab then
                            Error(Text000, Rec.FieldCaption("Tax Amount"));
                        Rec."Amount Including Tax" := Rec."Tax Amount" + Rec."Tax Base Amount";

                        FormCheckVATDifference();
                        ModifyRec();
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
                    ToolTip = 'Specifies if the Tax Amount will be debited to an Expense or Capital account, rather than to a Payable or Receivable account.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        TempSalesTaxLine.Copy(Rec);
        if TempSalesTaxLine.Find(Which) then begin
            Rec := TempSalesTaxLine;
            exit(true);
        end;
        exit(false);
    end;

    trigger OnInit()
    begin
        "Tax AmountEditable" := true;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        ModifyRec();
        exit(false);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        ResultSteps: Integer;
    begin
        TempSalesTaxLine.Copy(Rec);
        ResultSteps := TempSalesTaxLine.Next(Steps);
        if ResultSteps <> 0 then
            Rec := TempSalesTaxLine;
        exit(ResultSteps);
    end;

    var
        Text000: Label '%1 can only be modified on the Invoicing tab.';
        Text001: Label 'The total %1 for a document must not exceed %2 = %3.';
        TempSalesTaxLine: Record "Sales Tax Amount Line" temporary;
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
        TempSalesTaxLine.DeleteAll();
        if NewSalesTaxLine.Find('-') then
            repeat
                TempSalesTaxLine.Copy(NewSalesTaxLine);
                TempSalesTaxLine.Insert();
            until NewSalesTaxLine.Next() = 0;
        CurrPage.Update();
    end;

    procedure GetTempTaxAmountLine(var NewSalesTaxLine: Record "Sales Tax Amount Line" temporary)
    begin
        NewSalesTaxLine.DeleteAll();
        if TempSalesTaxLine.Find('-') then
            repeat
                NewSalesTaxLine.Copy(TempSalesTaxLine);
                NewSalesTaxLine.Insert();
            until TempSalesTaxLine.Next() = 0;
    end;

    procedure InitGlobals(NewCurrencyCode: Code[10]; NewAllowVATDifference: Boolean; NewAllowVATDifferenceOnThisTab: Boolean; NewPricesIncludingVAT: Boolean; NewAllowInvDisc: Boolean; NewVATBaseDiscPct: Decimal)
    begin
        CurrencyCode := NewCurrencyCode;
        AllowVATDifference := NewAllowVATDifference;
        AllowVATDifferenceOnThisTab := NewAllowVATDifferenceOnThisTab;
        PricesIncludingVAT := NewPricesIncludingVAT;
        AllowInvDisc := NewAllowInvDisc;
        VATBaseDiscPct := NewVATBaseDiscPct;
        "Tax AmountEditable" := AllowVATDifference;
        if CurrencyCode = '' then
            Currency.InitRoundingPrecision()
        else
            Currency.Get(CurrencyCode);
        CurrPage.Update();
    end;

    procedure FormCheckVATDifference()
    var
        TaxAmountLine2: Record "Sales Tax Amount Line";
        TotalVATDifference: Decimal;
    begin
        Rec.CheckTaxDifference(CurrencyCode, AllowVATDifference, PricesIncludingVAT);
        TaxAmountLine2 := TempSalesTaxLine;
        TotalVATDifference := Abs(Rec."Tax Difference") - Abs(xRec."Tax Difference");
        if TempSalesTaxLine.Find('-') then
            repeat
                TotalVATDifference := TotalVATDifference + Abs(TempSalesTaxLine."Tax Difference");
            until TempSalesTaxLine.Next() = 0;
        TempSalesTaxLine := TaxAmountLine2;
        if TotalVATDifference > Currency."Max. VAT Difference Allowed" then
            Error(
              Text001, Rec.FieldCaption("Tax Difference"),
              Currency.FieldCaption("Max. VAT Difference Allowed"), Currency."Max. VAT Difference Allowed");
    end;

    local procedure ModifyRec()
    begin
        TempSalesTaxLine := Rec;
        TempSalesTaxLine.Modified := true;
        TempSalesTaxLine.Modify();
    end;
}

