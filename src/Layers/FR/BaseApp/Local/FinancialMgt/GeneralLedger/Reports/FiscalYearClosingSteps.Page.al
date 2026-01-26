// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Period;

page 10818 "Fiscal Year Closing Steps"
{
    Caption = 'Fiscal Year Closing Steps';
    DataCaptionExpression = '';
    PageType = Card;
    SaveValues = true;
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                label(Control13)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = Text19039023;
                    ShowCaption = false;
                }
                label(Control5)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = Text19036566;
                    MultiLine = true;
                    ShowCaption = false;
                }
                label(Control8)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = Text19033763;
                    MultiLine = true;
                    ShowCaption = false;
                }
                label(Control14)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = Text19025164;
                    MultiLine = true;
                    ShowCaption = false;
                }
                label(Control9)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = Text19025389;
                    ShowCaption = false;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Ste&ps")
            {
                Caption = 'Ste&ps';
                Image = MoveToNextPeriod;
                action("Accounting Periods")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Accounting Periods';
                    Image = AccountingPeriods;
                    RunObject = Page "Accounting Periods";
                    ToolTip = 'Specify the accounting periods to include in each step in the process of closing a fiscal year.';
                }
                action("Close Income Statement")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Close Income Statement';
                    Ellipsis = true;
                    Image = Close;
                    RunObject = Report "Close Income Statement";
                    ToolTip = 'Run the Close Income Statement batch job to transfer the year''s results to an account in the balance sheet and close the income statement accounts. The batch job processes all general accounts of the income statement type and creates entries that cancel out their respective balances.';
                }
                action("General Journals")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'General Journals';
                    Image = Journal;
                    RunObject = Page "General Journal";
                    ToolTip = 'View the list of general journal templates that are associated with closing the fiscal year. The templates specify the settings required to close a fiscal year. ';
                }
            }
        }
    }

    var
        Text19039023: Label 'To fiscally close the fiscal year, please follow the steps below:';
        Text19036566: Label '1. Close the fiscal year in Accounting Periods to permanently set the end date of the fiscal year and be able to run the Close Income Statement batch job';
        Text19033763: Label '2. Run the batch job Close Income Statement to create or update the closing entries and post the closing entries in the General Journal';
        Text19025164: Label '3. Fiscally close the fiscal year in Accounting Periods to permanently forbid any new postings on this fiscal year';
        Text19025389: Label 'Please refer to the online Help for more information about this topic.';
}

