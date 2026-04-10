// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

/// <summary>
/// Displays a list of finance charge terms configurations with interest rates, grace periods, and fee settings.
/// </summary>
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
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Interest Calculation"; Rec."Interest Calculation")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Interest Calculation Method"; Rec."Interest Calculation Method")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Interest Rate"; Rec."Interest Rate")
                {
                    ApplicationArea = Basic, Suite;
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
                }
                field("Due Date Calculation"; Rec."Due Date Calculation")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Line Description"; Rec."Line Description")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Detailed Lines Description"; Rec."Detailed Lines Description")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Post Interest"; Rec."Post Interest")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Post Additional Fee"; Rec."Post Additional Fee")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Add. Line Fee in Interest"; Rec."Add. Line Fee in Interest")
                {
                    ApplicationArea = Basic, Suite;
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

