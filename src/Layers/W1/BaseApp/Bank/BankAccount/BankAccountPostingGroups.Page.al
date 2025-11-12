// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

/// <summary>
/// Administrative interface for managing bank account posting group configurations.
/// Defines G/L account assignments for bank transaction posting across different bank account types.
/// </summary>
/// <remarks>
/// Source Table: Bank Account Posting Group (277). Setup page for posting group administration.
/// Used to configure where bank transactions are posted in the general ledger.
/// </remarks>
page 373 "Bank Account Posting Groups"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Bank Account Posting Groups';
    PageType = List;
    SourceTable = "Bank Account Posting Group";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the G/L account that bank transactions, such as bank payment reconciliations, are posted to when the bank account card contains this code.';
                }
                field("G/L Account No."; Rec."G/L Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account to which bank account entries in this posting group are posted.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}

