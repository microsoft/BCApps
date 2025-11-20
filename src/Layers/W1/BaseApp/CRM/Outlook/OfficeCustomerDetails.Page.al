// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

using Microsoft.Sales.Customer;

page 1611 "Office Customer Details"
{
    Caption = 'Details';
    PageType = CardPart;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            field("Balance (LCY)"; Rec."Balance (LCY)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the payment amount that the customer owes for completed sales. This value is also known as the customer''s balance.';

                trigger OnDrillDown()
                begin
                    Rec.OpenCustomerLedgerEntries(false);
                end;
            }
            field("Past Due"; PastDue)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Past Due';
                Style = Unfavorable;
                StyleExpr = PastDue > 0;
                ToolTip = 'Specifies the amount of the customer''s balance that is overdue for payment.';
            }
            field("LTD Sales"; GetTotalSales())
            {
                ApplicationArea = Basic, Suite;
                Caption = 'LTD Sales';
                ToolTip = 'Specifies the total life-to-date sales for the customer.';
            }
            field("YTD Sales"; GetYTDSales())
            {
                ApplicationArea = Basic, Suite;
                Caption = 'YTD Sales';
                Editable = false;
                ToolTip = 'Specifies the total year-to-date sales for the customer.';
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        PastDue := Rec.CalcOverdueBalance();
    end;

    var
        CustomerMgt: Codeunit "Customer Mgt.";
        PastDue: Decimal;

    local procedure GetTotalSales(): Decimal
    begin
        exit(CustomerMgt.GetTotalSales(Rec."No."));
    end;

    local procedure GetYTDSales(): Decimal
    begin
        exit(CustomerMgt.GetYTDSales(Rec."No."));
    end;
}

