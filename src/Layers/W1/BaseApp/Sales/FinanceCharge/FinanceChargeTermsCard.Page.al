// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

page 494 "Finance Charge Terms Card"
{
    Caption = 'Finance Charge Terms Card';
    PageType = Card;
    SourceTable = "Finance Charge Terms";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a code for the finance charge terms.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a description of the finance charge terms.';
                }
                field("Line Description"; Rec."Line Description")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a description to be used in the Description field on the finance charge memo lines.';
                }
                field("Detailed Lines Description"; Rec."Detailed Lines Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description to be used in the Description field on the finance charge memo lines.';
                }
                field("Minimum Amount (LCY)"; Rec."Minimum Amount (LCY)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a minimum interest charge in LCY.';
                }
                field("Additional Fee (LCY)"; Rec."Additional Fee (LCY)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a fee amount in LCY.';
                }
                field("Interest Rate"; Rec."Interest Rate")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the percentage to use to calculate interest for this finance charge code.';
                }
                field("Interest Calculation"; Rec."Interest Calculation")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies which entries should be used in interest calculation on finance charge memos.';
                }
                field("Interest Calculation Method"; Rec."Interest Calculation Method")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the interest calculation method for this set of finance charge terms.';
                }
                field("Interest Period (Days)"; Rec."Interest Period (Days)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the period that the interest rate applies to. Enter the number of days in the period.';
                }
                field("Due Date Calculation"; Rec."Due Date Calculation")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a formula that determines how to calculate the due date of the finance charge memo.';
                }
                field("Grace Period"; Rec."Grace Period")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the grace period length for this set of finance charge terms.';
                }
                field("Post Interest"; Rec."Post Interest")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether or not interest listed on the finance charge memo should be posted to the general ledger and customer accounts when the finance charge memo is issued.';
                }
                field("Post Additional Fee"; Rec."Post Additional Fee")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether or not any additional fee listed on the finance charge memo should be posted to the general ledger and customer accounts when the memo is issued.';
                }
                field("Add. Line Fee in Interest"; Rec."Add. Line Fee in Interest")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies that any additional fees are included in the interest calculation for the finance charge.';
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

