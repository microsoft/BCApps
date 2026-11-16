// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6940 "Posted Exp. Rep. Line Particip"
{
    Caption = 'Posted Expense Report Line Participants';
    PageType = List;
    SourceTable = "Posted Exp. Rep. Line Particip";
    AutoSplitKey = true;
    Editable = false;

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
}