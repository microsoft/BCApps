// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

/// <summary>
/// Displays a card view for editing individual finance charge terms with all configuration options.
/// </summary>
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
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                }
                field("Line Description"; Rec."Line Description")
                {
                    ApplicationArea = Suite;
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
                }
                field("Interest Calculation"; Rec."Interest Calculation")
                {
                    ApplicationArea = Suite;
                }
                field("Interest Calculation Method"; Rec."Interest Calculation Method")
                {
                    ApplicationArea = Suite;
                }
                field("Interest Period (Days)"; Rec."Interest Period (Days)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the period that the interest rate applies to. Enter the number of days in the period.';
                }
                field("Due Date Calculation"; Rec."Due Date Calculation")
                {
                    ApplicationArea = Suite;
                }
                field("Grace Period"; Rec."Grace Period")
                {
                    ApplicationArea = Suite;
                }
                field("Post Interest"; Rec."Post Interest")
                {
                    ApplicationArea = Suite;
                }
                field("Post Additional Fee"; Rec."Post Additional Fee")
                {
                    ApplicationArea = Suite;
                }
                field("Add. Line Fee in Interest"; Rec."Add. Line Fee in Interest")
                {
                    ApplicationArea = Suite;
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

