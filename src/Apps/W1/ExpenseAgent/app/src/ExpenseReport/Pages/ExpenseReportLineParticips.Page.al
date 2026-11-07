// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6912 "Expense Report Line Particips"
{
    Caption = 'Expense Report Line Participants';
    PageType = List;
    SourceTable = "Expense Report Line Particip.";
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
                    ToolTip = 'Specifies the type of participant (Employee, Customer, Vendor, Other).';
                }
                field("Participant Employee No."; Rec."Participant Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee number if the participant is an employee.';
                    Editable = Rec."Participant Type" = Rec."Participant Type"::Employee;
                }
                field("Participant Name"; Rec."Participant Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the participant.';
                }
                field("Participant Organization"; Rec."Participant Organization")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the organization of the participant.';
                }
                field("Participant Title"; Rec."Participant Title")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the job title of the participant.';
                }
                field("Participant Country/Region"; Rec."Participant Country/Region")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region of the participant.';
                }
                field("Participant Email"; Rec."Participant Email")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the email address of the participant.';
                }
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
    begin
        if CloseAction in [Action::OK, Action::LookupOK] then
            if ExpenseReportLine.Get(Rec."Expense Report No.", Rec."Expense Report Line No.") then
                ExpenseRuleValidation.ValidateExpenseReportLineAgainstRule(ExpenseReportLine);
    end;
}
