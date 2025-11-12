// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Analysis;

using Microsoft.Finance.Currency;

page 486 "Cust. Stats. by Curr. Lines"
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
                field("Customer Balance"; Rec."Customer Balance")
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = Rec.Code;
                    AutoFormatType = 1;
                    Caption = 'Balance';
                    ToolTip = 'Specifies the payment amount that the customer owes for completed sales.';
                }
                field("Customer Outstanding Orders"; Rec."Customer Outstanding Orders")
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = Rec.Code;
                    AutoFormatType = 1;
                    Caption = 'Outstanding Orders';
                    ToolTip = 'Specifies the number of orders for which payment has not been made.';
                }
                field("Customer Shipped Not Invoiced"; Rec."Customer Shipped Not Invoiced")
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
                    ToolTip = 'Specifies the total amount less any invoice discount amount and excluding VAT for the sales document.';
                }
                field("Customer Balance Due"; Rec."Customer Balance Due")
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = Rec.Code;
                    AutoFormatType = 1;
                    Caption = 'Balance Due';
                    ToolTip = 'Specifies the payment amount that the customer owes you for completed sales where the payment date is exceeded.';
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
          "Customer Balance", "Customer Balance Due",
          "Customer Outstanding Orders", "Customer Shipped Not Invoiced");
        TotalAmount := Rec."Customer Balance" + Rec."Customer Outstanding Orders" + Rec."Customer Shipped Not Invoiced";
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

        Rec.SetRange("Cust. Ledg. Entries in Filter", true);
    end;

    var
        Currency: Record Currency;
        TotalAmount: Decimal;
}

