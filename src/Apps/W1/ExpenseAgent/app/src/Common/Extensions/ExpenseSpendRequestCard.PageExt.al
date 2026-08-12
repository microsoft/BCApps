// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.SpendRequest;

pageextension 6902 "Expense Spend Request Card" extends "Spend Request Card"
{
    layout
    {
        modify("Requested By")
        {
            Visible = false;
        }
        modify("Currency Code")
        {
            Importance = Additional;
        }
        modify("Total Expected Amount (LCY)")
        {
            Importance = Additional;
        }
        modify(TotalSpentAmountLCY)
        {
            Importance = Additional;
        }
        addafter("Requested By")
        {
            field("Requested For"; Rec."Requested For")
            {
                ApplicationArea = Basic, Suite;
            }
        }
        addafter(Lines)
        {
            group("Travel Details")
            {
                Caption = 'Travel Details';
                field("Business Justification"; Rec."Business Justification")
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    Importance = Additional;
                }
                field("International Travel"; Rec."International Travel")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Origin Country"; Rec."Origin Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Destination Country"; Rec."Dest. Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Restrictions; Rec.Restrictions)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Travel Policy Acknowledgment"; Rec."Travel Policy Acknowledgment")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Per Diem Included"; Rec."Per Diem Included")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
            }
        }
        addafter("Expected End Date")
        {
            field("Actual Start Date and Time"; Rec."Actual Start Date and Time")
            {
                ApplicationArea = Basic, Suite;
                Importance = Additional;
            }
            field("Actual End Date and Time"; Rec."Actual End Date and Time")
            {
                ApplicationArea = Basic, Suite;
                Importance = Additional;
            }
        }
        modify("Approved by User Name")
        {
            Editable = false;
        }
    }
    actions
    {
        modify(Approve)
        {
            Visible = false;
        }
        modify(Reject)
        {
            Visible = false;
        }
        modify(Print)
        {
            Visible = false;
        }
        addlast(Navigation)
        {
            action("Travelers")
            {
                Image = Travel;
                Caption = 'Travelers';
                ToolTip = 'View the travelers associated with this spend request.';
                ApplicationArea = Basic, Suite;
                RunObject = page "Travelers";
                RunPageLink = "Spend Request No." = field("No.");
            }
        }
        addafter(Dimensions_Promoted)
        {
            actionref(Travelers_Promoted; Travelers)
            {
            }
        }
    }
}