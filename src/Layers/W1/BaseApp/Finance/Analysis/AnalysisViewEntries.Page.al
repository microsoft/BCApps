// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

/// <summary>
/// Displays analysis view entries with drill-down capability to underlying transactions.
/// Provides detailed view of aggregated financial data with dimension breakdown and filtering options.
/// </summary>
page 558 "Analysis View Entries"
{
    ApplicationArea = Dimensions;
    Caption = 'Analysis View Entries';
    Editable = false;
    PageType = List;
    AboutTitle = 'About Analysis View Entries';
    AboutText = 'Review financial analysis data by dimensions, accounts, and business units to gain insights into posted amounts, debits, and credits across various analysis views.';
    SourceTable = "Analysis View Entry";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Analysis View Code"; Rec."Analysis View Code")
                {
                    ApplicationArea = Suite;
                }
                field("Business Unit Code"; Rec."Business Unit Code")
                {
                    ApplicationArea = Suite;
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Suite;
                }
                field("Account Source"; Rec."Account Source")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies an account that you can use as a filter to define what is displayed in the Analysis by Dimensions window. ';
                }
                field("Cash Flow Forecast No."; Rec."Cash Flow Forecast No.")
                {
                    ApplicationArea = Suite;
                }
                field("Dimension 1 Value Code"; Rec."Dimension 1 Value Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Dimension 2 Value Code"; Rec."Dimension 2 Value Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Dimension 3 Value Code"; Rec."Dimension 3 Value Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Dimension 4 Value Code"; Rec."Dimension 4 Value Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Suite;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Suite;

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDown();
                    end;
                }
                field("Debit Amount"; Rec."Debit Amount")
                {
                    ApplicationArea = Suite;
                }
                field("Credit Amount"; Rec."Credit Amount")
                {
                    ApplicationArea = Suite;
                }
                field("Add.-Curr. Amount"; Rec."Add.-Curr. Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Add.-Curr. Debit Amount"; Rec."Add.-Curr. Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Add.-Curr. Credit Amount"; Rec."Add.-Curr. Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
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
