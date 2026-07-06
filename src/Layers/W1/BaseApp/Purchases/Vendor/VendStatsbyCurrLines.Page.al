// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Finance.Currency;

page 487 "Vend. Stats. by Curr. Lines"
{
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = Currency;
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a currency code that you can select. The code must comply with ISO 4217.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a text to describe the currency code.';
                }
                field("Vendor Balance"; Rec."Vendor Balance")
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = Rec.Code;
                    AutoFormatType = 1;
                    Caption = 'Balance';
                    ToolTip = 'Specifies the payment amount that you owe the vendor for completed purchases.';
                }
                field("Vendor Outstanding Orders"; Rec."Vendor Outstanding Orders")
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = Rec.Code;
                    AutoFormatType = 1;
                    Caption = 'Outstanding Orders';
                    ToolTip = 'Specifies the number of orders for which payment has not been made.';
                }
                field("Vendor Amt. Rcd. Not Invoiced"; Rec."Vendor Amt. Rcd. Not Invoiced")
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = Rec.Code;
                    AutoFormatType = 1;
                    Caption = 'Shipped Not Invoiced';
                    ToolTip = 'Specifies the number of orders that are shipped but not invoiced.';
                }
                field(TotalAmount; TotalAmount)
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = Rec.Code;
                    AutoFormatType = 1;
                    Caption = 'Total';
                    ToolTip = 'Specifies the total amount less any invoice discount amount and excluding VAT for the purchase document.';
                }
                field("Vendor Balance Due"; Rec."Vendor Balance Due")
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = Rec.Code;
                    AutoFormatType = 1;
                    Caption = 'Balance Due';
                    ToolTip = 'Specifies the payment amount that you owe the vendor for completed purchases where the payment date is exceeded.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields(
          "Vendor Balance", "Vendor Balance Due",
          "Vendor Outstanding Orders", "Vendor Amt. Rcd. Not Invoiced");
        TotalAmount := Rec."Vendor Balance" + Rec."Vendor Outstanding Orders" + Rec."Vendor Amt. Rcd. Not Invoiced";
    end;

    trigger OnOpenPage()
    begin
        Rec.Code := '';
        Rec.Insert();
        if Currency.FindSet() then
            repeat
                Rec := Currency;
                Rec.Insert();
            until Currency.Next() = 0;

        Rec.SetRange("Vendor Ledg. Entries in Filter", true);
    end;

    var
        Currency: Record Currency;
        TotalAmount: Decimal;
}

