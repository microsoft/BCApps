// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

page 10129 "Posted Bank Rec. List"
{
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;
    Caption = 'Posted Bank Reconciliations List';
    CardPageID = "Posted Bank Rec. Worksheet";
    Editable = false;
    PageType = List;
    SourceTable = "Posted Bank Rec. Header";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the bank account the reconciliation applies to.';
                }
                field("Statement No."; Rec."Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the statement number to be reconciled.';
                }
                field("Statement Date"; Rec."Statement Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the as-of date of the statement. All G/L balances will be calculated based upon this date.';
                }
                field("Statement Balance"; Rec."Statement Balance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount entered by the operator from the balance found on the bank statement.';
                }
                field("Date Created"; Rec."Date Created")
                {
                    ToolTip = 'Specifies a date automatically populated when the record is created.';
                    Visible = false;
                }
                field("Time Created"; Rec."Time Created")
                {
                    ToolTip = 'Specifies the  time created, which is automatically populated when the record is created.';
                    Visible = false;
                }
            }
        }
    }

    var
        NewPostedInBankStatementsNotificationMsg: Label 'Posted bank reconciliations are now kept in the Bank Account Statement List page.';

    trigger OnOpenPage()
    var
        Notification: Notification;
    begin
        Notification.Message := NewPostedInBankStatementsNotificationMsg;
        Notification.AddAction('Go to Bank Account Statement List', Codeunit::"Bank Reconciliation Mgt.", 'OpenBankStatementsPage');
        Notification.Scope := NotificationScope::LocalScope;
        Notification.Send();
    end;
}

