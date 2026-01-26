// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEAN27
namespace Microsoft.Finance.VAT.Reporting;

page 12123 "Periodic VAT Settlement Card"
{
    Caption = 'Periodic VAT Settlement Card';
    DelayedInsert = true;
    ObsoleteReason = 'Replaced by page 12110 "Periodic VAT Settl. Card".';
    ObsoleteState = Pending;
    ObsoleteTag = '27.0';
    PageType = Card;
    SourceTable = "Periodic Settlement VAT Entry";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("VAT Period"; Rec."VAT Period")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the period of time that defines the VAT period.';
                }
                field("Paid Date"; Rec."Paid Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date that the VAT settlement transaction is posted and sent to the tax authority.';
                }
                field("Bank Code"; Rec."Bank Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the bank code that is assigned to the bank account that is used for the VAT settlement transaction.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for the periodic settlement VAT entry.';
                }
                field("VAT Period Closed"; Rec."VAT Period Closed")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies if the VAT period has been closed.';
                }
            }
            group(Settlement)
            {
                Caption = 'Settlement';
                field("VAT Settlement"; Rec."VAT Settlement")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the net VAT amount that is transferred to the VAT settlement account.';
                }
                field("Advanced Amount"; Rec."Advanced Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of VAT tax that is paid in advance to offset future VAT liabilities.';
                }
                field("Prior Year Input VAT"; Rec."Prior Year Input VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of input VAT from purchases during the previous year.';
                }
                field("Prior Year Output VAT"; Rec."Prior Year Output VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of output VAT from sales during the prior year.';
                }
                field("Payable VAT Variation"; Rec."Payable VAT Variation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the difference in VAT payable that arises when you make adjustments to VAT amounts on a sales document.';
                }
                field("Paid Amount"; Rec."Paid Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the amount of VAT that is paid to the tax authority.';
                }
                field("Prior Period Input VAT"; Rec."Prior Period Input VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of input VAT from purchases during the previous period.';
                }
                field("Prior Period Output VAT"; Rec."Prior Period Output VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of output VAT from sales during the prior period.';
                }
                field("Deductible VAT Variation"; Rec."Deductible VAT Variation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the difference in VAT deductions that occurs when you make adjustments to VAT amounts on purchase documents.';
                }
                field("Tax Debit Variation"; Rec."Tax Debit Variation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the difference in the VAT debit amount that is due to adjustments from investigation.';
                }
                field("Tax Credit Variation"; Rec."Tax Credit Variation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the difference in the VAT credit amount that is due to adjustments from investigation.';
                }
                field("Unpaid VAT Previous Periods"; Rec."Unpaid VAT Previous Periods")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of VAT due that is currently unpaid from previous periods.';
                }
                field("Tax Debit Variation Interest"; Rec."Tax Debit Variation Interest")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the difference in the VAT debit interest amount that is due to adjustments from investigation.';
                }
                field("Omit VAT Payable Interest"; Rec."Omit VAT Payable Interest")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of payable VAT interest that is omitted from a periodic VAT settlement due to provisions in the law.';
                }
                field("Credit VAT Compensation"; Rec."Credit VAT Compensation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies VAT credit compensation for a periodic VAT settlement.';
                }
                field("Special Credit"; Rec."Special Credit")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the special credit amount for a periodic VAT settlement.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&VAT Settl.")
            {
                Caption = '&VAT Settl.';
                action("&List")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&List';
                    Image = OpportunitiesList;
                    RunObject = Page "Periodic VAT Settlement List";
                    ShortCutKey = 'Shift+Ctrl+L';
                    ToolTip = 'View a list of VAT settlements.';
                }
            }
        }
    }
}
#endif
