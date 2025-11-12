// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

page 6 "Finance Charge Terms"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Finance Charge Terms';
    CardPageID = "Finance Charge Terms Card";
    PageType = List;
    SourceTable = "Finance Charge Terms";
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
                    ToolTip = 'Specifies a code for the finance charge terms.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the finance charge terms.';
                }
                field("Interest Calculation"; Rec."Interest Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which entries should be used in interest calculation on finance charge memos.';
                }
                field("Interest Calculation Method"; Rec."Interest Calculation Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the interest calculation method for this set of finance charge terms.';
                }
                field("Interest Rate"; Rec."Interest Rate")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the percentage to use to calculate interest for this finance charge code.';
                }
                field("Interest Period (Days)"; Rec."Interest Period (Days)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the period that the interest rate applies to. Enter the number of days in the period.';
                }
                field("Minimum Amount (LCY)"; Rec."Minimum Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a minimum interest charge in LCY.';
                }
                field("Additional Fee (LCY)"; Rec."Additional Fee (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a fee amount in LCY.';
                }
                field("Grace Period"; Rec."Grace Period")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the grace period length for this set of finance charge terms.';
                }
                field("Due Date Calculation"; Rec."Due Date Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a formula that determines how to calculate the due date of the finance charge memo.';
                }
                field("Line Description"; Rec."Line Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description to be used in the Description field on the finance charge memo lines.';
                }
                field("Detailed Lines Description"; Rec."Detailed Lines Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description to be used in the Description field on the finance charge memo lines if multiple interest rates are set up for different payment delay periods and the description must show the sum of these.';
                }
                field("Post Interest"; Rec."Post Interest")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether or not interest listed on the finance charge memo should be posted to the general ledger and customer accounts when the finance charge memo is issued.';
                }
                field("Post Additional Fee"; Rec."Post Additional Fee")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether or not any additional fee listed on the finance charge memo should be posted to the general ledger and customer accounts when the memo is issued.';
                }
                field("Add. Line Fee in Interest"; Rec."Add. Line Fee in Interest")
                {
                    ApplicationArea = Basic, Suite;
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
        area(navigation)
        {
            group("Ter&ms")
            {
                Caption = 'Ter&ms';
                Image = BeginningText;
                action("Interest Rates")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Interest Rates';
                    Image = Percentage;
                    RunObject = Page "Finance Charge Interest Rates";
                    RunPageLink = "Fin. Charge Terms Code" = field(Code);
                    ToolTip = 'Set up interest rates.';
                }
                action(BeginningText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Beginning Text';
                    Image = BeginningText;
                    RunObject = Page "Finance Charge Text";
                    RunPageLink = "Fin. Charge Terms Code" = field(Code),
                                  Position = const(Beginning);
                    ToolTip = 'Define a beginning text for each finance charge term. The text will then be printed on the finance charge memo.';
                }
                action(EndingText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ending Text';
                    Image = EndingText;
                    RunObject = Page "Finance Charge Text";
                    RunPageLink = "Fin. Charge Terms Code" = field(Code),
                                  Position = const(Ending);
                    ToolTip = 'Define an ending text for each finance charge term. The text will then be printed on the finance charge memo.';
                }
                separator(Action35)
                {
                }
                action("C&urrencies")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&urrencies';
                    Image = Currency;
                    RunObject = Page "Currencies for Fin. Chrg Terms";
                    RunPageLink = "Fin. Charge Terms Code" = field(Code);
                    ToolTip = 'Set up finance charge terms in foreign currencies. For example, you can use this table to set up finance charge terms with an additional fee of FRF 100.';
                }
            }
        }
    }
}

