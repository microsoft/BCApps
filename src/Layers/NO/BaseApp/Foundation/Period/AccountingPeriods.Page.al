// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Period;

using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Inventory.Setup;

page 100 "Accounting Periods"
{
    AdditionalSearchTerms = 'fiscal year,fiscal period';
    ApplicationArea = Basic, Suite;
    Caption = 'Accounting Periods';
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Accounting Period";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the accounting period will begin.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the accounting period.';
                }
                field("New Fiscal Year"; Rec."New Fiscal Year")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to use the accounting period to start a fiscal year.';
                }
                field(Closed; Rec.Closed)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the accounting period belongs to a closed fiscal year.';
                }
                field("Date Locked"; Rec."Date Locked")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you can change the starting date for the accounting period.';
                }
#pragma warning disable AA0100
                field("InvtPeriod.IsInvtPeriodClosed(""Starting Date"")"; InvtPeriod.IsInvtPeriodClosed(Rec."Starting Date"))
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Inventory Period Closed';
                    Editable = false;
                    ToolTip = 'Specifies that the inventory period has been closed.';
                }
                field("Average Cost Period"; Rec."Average Cost Period")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the period type that was used in the accounting period to calculate the average cost.';
                    Visible = false;
                }
                field("Average Cost Calc. Type"; Rec."Average Cost Calc. Type")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how the average cost for items in the accounting period was calculated.';
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

    actions
    {
        area(processing)
        {
            action("&VAT Period")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&VAT Period';
                Image = ShowInventoryPeriods;
                RunObject = Page "VAT Periods";
                ToolTip = 'View your custom VAT periods. To align with legal requirements, VAT Periods are to be closed after settling. Normally a year is divided in 6 periods, 2 months each. When the VAT is settled, the period is closed for further posting.';
            }
            action("&Inventory Period")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Inventory Period';
                Image = ShowInventoryPeriods;
                RunObject = Page "Inventory Periods";
                ToolTip = 'Create an inventory period. An inventory period defines a period of time in which you can post changes to the inventory value.';
            }
            action("&Create Year")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Create Year';
                Ellipsis = true;
                Image = CreateYear;
                RunObject = Report "Create Fiscal Year";
                ToolTip = 'Open a new fiscal year and define its accounting periods so you can start posting documents.';
            }
            action("C&lose Year")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'C&lose Year';
                Image = CloseYear;
                RunObject = Codeunit "Fiscal Year-Close";
                ToolTip = 'Close the current fiscal year. A confirmation message will display that tells you which year will be closed. You cannot reopen the year after it has been closed.';
            }
        }
        area(reporting)
        {
            action("Trial Balance by Period")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Trial Balance by Period';
                Image = "Report";
                RunObject = Report "Trial Balance by Period";
                ToolTip = 'Show the opening balance by general ledger account, the movements in the selected period of month, quarter, or year, and the resulting closing balance.';
            }
#if not CLEAN28
            action("Trial Balance")
            {
                ApplicationArea = Suite;
                Caption = 'Trial Balance (Obsolete)';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Trial Balance";
                ToolTip = 'Show the chart of accounts with balances and net changes. You can use the report at the close of an accounting period or fiscal year.';
                ObsoleteState = Pending;
                ObsoleteReason = 'This report has been replaced by the report Trial Balance (Excel). This report will be removed in a future release.';
                ObsoleteTag = '28.0';
            }
#endif
            action("Fiscal Year Balance")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Fiscal Year Balance';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Fiscal Year Balance";
                ToolTip = 'View balance sheet movements for a selected period. The report is useful at the close of an accounting period or fiscal year.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&VAT Period_Promoted"; "&VAT Period")
                {
                }
                actionref("&Inventory Period_Promoted"; "&Inventory Period")
                {
                }
                actionref("&Create Year_Promoted"; "&Create Year")
                {
                }
                actionref("C&lose Year_Promoted"; "C&lose Year")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("Trial Balance by Period_Promoted"; "Trial Balance by Period")
                {
                }
            }
        }
    }

    var
        InvtPeriod: Record "Inventory Period";
}

