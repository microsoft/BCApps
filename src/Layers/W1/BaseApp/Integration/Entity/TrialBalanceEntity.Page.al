// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

using Microsoft.Finance.FinancialReports;
using Microsoft.Integration.Graph;

page 5502 "Trial Balance Entity"
{
    Caption = 'trialBalance', Locked = true;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    SourceTable = "Trial Balance Entity Buffer";
    PageType = List;
    SourceTableTemporary = true;


    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(number; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the No..';
                    Caption = 'Number', Locked = true;
                }
                field(accountId; Rec."Account Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Account Id.';
                    Caption = 'AccountId', Locked = true;
                }
                field(accountType; Rec."Account Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Account Type.';
                    Caption = 'AccountType', Locked = true;
                }
                field(display; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Name.';
                    Caption = 'Name', Locked = true;
                }
                field(totalDebit; Rec."Total Debit")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Total Debit Amount.';
                    Caption = 'TotalDebit', Locked = true;
                }
                field(totalCredit; Rec."Total Credit")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Total Credit Amount.';
                    Caption = 'TotalCredit', Locked = true;
                }
                field(balanceAtDateDebit; Rec."Balance at Date Debit")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Balance at Date Debit Amount.';
                    Caption = 'BalanceAtDateDebit', Locked = true;
                }
                field(balanceAtDateCredit; Rec."Balance at Date Credit")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Balance at Date Credit Amount.';
                    Caption = 'BalanceAtDateCredit', Locked = true;
                }
                field(dateFilter; Rec."Date Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Date Filter.';
                    Caption = 'DateFilter', Locked = true;
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
    begin
        RecVariant := Rec;
        GraphMgtReports.SetUpTrialBalanceAPIData(RecVariant);
    end;
}
