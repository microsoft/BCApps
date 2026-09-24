// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// List interface for managing expense payment methods and their configurations.
/// </summary>
page 6930 "Expense Payment Methods"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Expense Payment Methods';
    PageType = List;
    AboutTitle = 'About Expense Payment Methods';
    AboutText = 'Define and manage expense payment methods such as bank, cash or card employees, specifying reimbursement types for expenses.';
    SourceTable = "Expense Payment Method";
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
                    ToolTip = 'Specifies a code to identify this payment method.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a text that describes the payment method.';
                }
                field("Reimbursement Type"; Rec."Reimbursement Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account that a balancing entry is posted to, such as BANK for a cash account.';
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
}

