// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6924 "Expense Posting Groups API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Expense Posting Group';
    EntitySetCaption = 'Expense Posting Groups';
    DelayedInsert = true;
    EntityName = 'expensePostingGroup';
    EntitySetName = 'expensePostingGroups';
    PageType = API;
    ODataKeyFields = SystemId;
    SourceTable = "Expense Posting Group";
    AboutText = 'Provides access to data from the Expense Posting Group table';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(code; Rec."Code")
                {
                    Caption = 'Code';
                }
                field(nonRefundableDebitAccount; Rec."Non-Refundable Debit Account")
                {
                    Caption = 'Non-Refundable Debit Account';
                }
                field(refundableDebitAccount; Rec."Refundable Debit Account")
                {
                    Caption = 'Refundable Debit Account';
                }
                field(prepaymentCreditAccount; Rec."Prepayment Credit Account")
                {
                    Caption = 'Prepayment Credit Account';
                }
            }
        }
    }

    trigger OnInit()
    var
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
    end;
}