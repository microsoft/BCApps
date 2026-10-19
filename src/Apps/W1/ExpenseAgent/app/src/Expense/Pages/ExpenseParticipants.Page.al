// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6992 "Expense Participants"
{
    Caption = 'Expense Participants';
    PageType = List;
    SourceTable = "Expense Participant";
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Participant Type"; Rec."Participant Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the participant is an employee or external.';
                }
                field("Participant Employee No."; Rec."Participant Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee number when Participant Type is Employee. Available when Participant Type is Employee.';
                    Editable = Rec."Participant Type" = Rec."Participant Type"::Employee;
                }
                field("Participant Name"; Rec."Participant Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the participant''s full name.';
                }
                field("Participant Country/Region"; Rec."Participant Country/Region")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the participant''s country/region.';
                }
                field("Participant Organization"; Rec."Participant Organization")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the participant''s organization.';
                }
                field("Participant Title"; Rec."Participant Title")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the participant''s job title.';
                }
                field("Participant Email"; Rec."Participant Email")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the participant''s email address.';
                }
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Expense: Record Expense;
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
    begin
        if CloseAction in [Action::OK, Action::LookupOK] then begin
            Expense.Get(Rec."Expense No.");

            ExpenseRuleValidation.ValidateExpenseAgainstRule(Expense);
        end;
    end;
}
