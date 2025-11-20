// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Foundation.Period;

page 3 "Sales Stats. Per Period"
{
    Caption = 'Sales Stats. Per Period';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Accounting Period Buffer";

    layout
    {
        area(Content)
        {
            repeater(Repeater)
            {
                field(CustomerNoCtrl; CustomerNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer No.';
                    ToolTip = 'Specifies the customer number for which sales are displayed.';
                    Editable = false;
                    Visible = false;
                }
                field(PeriodName; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Period Name';
                    ToolTip = 'Specifies the name of the accounting period.';
                    Editable = false;
                }
                field(StartingDate; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Starting Date';
                    ToolTip = 'Specifies the starting date of the accounting period.';
                    Editable = false;
                    Visible = false;
                }
                field(EndingDate; Rec."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ending Date';
                    ToolTip = 'Specifies the ending date of the accounting period.';
                    Editable = false;
                    Visible = false;
                }
                field(PeriodSalesLCY; SalesLCY)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales (LCY)';
                    ToolTip = 'Specifies the total sales in local currency for the accounting period.';
                    Editable = false;
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                }
                field(PeriodProfitLCY; ProfitLCY)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Profit (LCY)';
                    ToolTip = 'Specifies the total profit in local currency for the accounting period.';
                    Editable = false;
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                }
            }
        }
    }

    var
        CustomerSalesPerPeriod: Query "Customer Sales per Period";
        CustomerNo: Code[20];
        SalesLCY: Decimal;
        ProfitLCY: Decimal;

    trigger OnOpenPage()
    begin
        CustomerNo := CopyStr(Rec.GetFilter("Customer No. Filter"), 1, MaxStrLen(CustomerNo));
        Rec.FillBuffer();
    end;

    trigger OnAfterGetRecord()
    begin
        SalesLCY := 0;
        ProfitLCY := 0;
        CustomerSalesPerPeriod.SetRange(CustomerNo, CustomerNo);
        CustomerSalesPerPeriod.SetRange(PostingDate, Rec."Starting Date", Rec."Ending Date");
        CustomerSalesPerPeriod.Open();
        if CustomerSalesPerPeriod.Read() then begin
            SalesLCY := CustomerSalesPerPeriod.SalesLCY;
            ProfitLCY := CustomerSalesPerPeriod.ProfitLCY;
        end;
    end;
}