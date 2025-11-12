// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Setup;

using Microsoft.Foundation.Period;
using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Costing;

page 5828 "Inventory Periods"
{
    AdditionalSearchTerms = 'accounting period';
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory Periods';
    PageType = List;
    SourceTable = "Inventory Period";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ending date of an inventory period is the last day of the inventory period.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a descriptive name that helps users identify the inventory period.';
                }
                field(Closed; Rec.Closed)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that an inventory period can be open or closed.';
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
            group("&Invt. Period")
            {
                Caption = '&Invt. Period';
                Image = Period;
                action("Invt. Period E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Invt. Period E&ntries';
                    Image = PeriodEntries;
                    RunObject = Page "Inventory Period Entries";
                    RunPageLink = "Ending Date" = field("Ending Date");
                    RunPageView = sorting("Ending Date", "Entry No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'Define how to track the closings and re-openings of an inventory period.';
                }
                action("&Accounting Periods")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Accounting Periods';
                    Image = AccountingPeriods;
                    RunObject = Page "Accounting Periods";
                    ToolTip = 'Set up accounting periods, one line per period. You must set up at least one accounting period for each fiscal year.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Test Report")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        ReportPrint.PrintInvtPeriod(Rec);
                    end;
                }
                action("&Close Period")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Close Period';
                    Ellipsis = true;
                    Image = ClosePeriod;
                    ToolTip = 'Close the selected period. Once it is closed, you cannot post in the period, until you re-open it.';

                    trigger OnAction()
                    begin
                        CloseInventoryPeriod.SetReOpen(false);
                        CloseInventoryPeriod.Run(Rec);
                    end;
                }
                action("&Reopen Period")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Reopen Period';
                    Ellipsis = true;
                    Image = ReopenPeriod;
                    ToolTip = 'Reopen a closed period in order to be able to post in it.';

                    trigger OnAction()
                    begin
                        CloseInventoryPeriod.SetReOpen(true);
                        CloseInventoryPeriod.Run(Rec);
                    end;
                }
                separator(Action15)
                {
                }
                action("&Adjust Cost - Item Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Adjust Cost - Item Entries';
                    Ellipsis = true;
                    Image = AdjustEntries;
                    RunObject = Report "Adjust Cost - Item Entries";
                    ToolTip = 'Adjust inventory values in value entries so that you use the correct adjusted cost for updating the general ledger and so that sales and profit statistics are up to date.';
                }
                action("&Post Inventory to G/L")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Post Inventory to G/L';
                    Ellipsis = true;
                    Image = PostInventoryToGL;
                    RunObject = Report "Post Inventory Cost to G/L";
                    ToolTip = 'Record the quantity and value changes to the inventory in the item ledger entries and the value entries when you post inventory transactions, such as sales shipments or purchase receipts.';
                }
                action("Post &Inventory to G/L - Test")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post &Inventory to G/L - Test';
                    Ellipsis = true;
                    Image = PostInventoryToGLTest;
                    RunObject = Report "Post Invt. Cost to G/L - Test";
                    ToolTip = 'Run a test of the Post Inventory to G/L.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Test Report_Promoted"; "Test Report")
                {
                }
                actionref("Post &Inventory to G/L - Test_Promoted"; "Post &Inventory to G/L - Test")
                {
                }
                actionref("&Accounting Periods_Promoted"; "&Accounting Periods")
                {
                }
                actionref("&Close Period_Promoted"; "&Close Period")
                {
                }
                actionref("&Reopen Period_Promoted"; "&Reopen Period")
                {
                }
                actionref("&Post Inventory to G/L_Promoted"; "&Post Inventory to G/L")
                {
                }
            }
        }
    }

    var
        CloseInventoryPeriod: Codeunit "Close Inventory Period";
        ReportPrint: Codeunit "Test Report-Print";
}

