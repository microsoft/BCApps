// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

using Microsoft.Integration.Graph;

page 5499 "Aged AR Entity"
{
    Caption = 'agedAccountsReceivable', Locked = true;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    SourceTable = "Aged Report Entity";
    PageType = List;
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(customerId; Rec.AccountId)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Account Id.';
                    Caption = 'CustomerId', Locked = true;
                }
                field(customerNumber; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Customer No..';
                    Caption = 'CustomerNumber', Locked = true;
                }
                field(name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Customer Name.';
                    Caption = 'Name', Locked = true;
                }
                field(currencyCode; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Currency Code.';
                    Caption = 'CurrencyCode', Locked = true;
                }
                field(balanceDue; Rec.Balance)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Balance Due.';
                    Caption = 'Balance', Locked = true;
                }
                field(currentAmount; Rec.Before)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the period Before.';
                    Caption = 'Before', Locked = true;
                }
                field(period1Amount; Rec."Period 1")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies Period 1.';
                    Caption = 'Period1', Locked = true;
                }
                field(period2Amount; Rec."Period 2")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies Period 2.';
                    Caption = 'Period2', Locked = true;
                }
                field(period3Amount; Rec."Period 3")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies Period 3.';
                    Caption = 'Period3', Locked = true;
                }
                field(agedAsOfDate; Rec."Period Start Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Period Start Date.';
                    Caption = 'PeriodStartDate', Locked = true;
                }
                field(periodLengthFilter; Rec."Period Length")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Period Length.';
                    Caption = 'PeriodLength', Locked = true;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        GraphMgtReports: Codeunit "Graph Mgt - Reports";
        RecVariant: Variant;
        ReportAPIType: Option "Balance Sheet","Income Statement","Trial Balance","CashFlow Statement","Aged Accounts Payable","Aged Accounts Receivable","Retained Earnings";
    begin
        RecVariant := Rec;
        GraphMgtReports.SetUpAgedReportAPIData(RecVariant, ReportAPIType::"Aged Accounts Receivable");
    end;
}