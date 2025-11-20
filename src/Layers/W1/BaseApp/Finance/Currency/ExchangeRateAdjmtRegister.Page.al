// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

page 106 "Exchange Rate Adjmt. Register"
{
    ApplicationArea = Suite;
    Caption = 'Exchange Rate Adjustment Registers';
    Editable = false;
    PageType = List;
    SourceTable = "Exch. Rate Adjmt. Reg.";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Creation Date"; Rec."Creation Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the posting date for the exchange rate adjustment register.';
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the account type that was adjusted for exchange rate fluctuations when you ran the Adjust Exchange Rates batch job.';
                }
                field("Posting Group"; Rec."Posting Group")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the posting group of the exchange rate adjustment register on this line.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    AssistEdit = true;
                    ToolTip = 'Specifies the code for the currency whose exchange rate was adjusted.';
                }
                field("Adjusted Customers"; Rec."Adjusted Customers")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of customer ledger entries with remaining amount that was adjusted.';
                    Visible = false;
                }
                field("Adjusted Vendors"; Rec."Adjusted Vendors")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of vendor ledger entries with remaining amount that was adjusted.';
                    Visible = false;
                }
                field("Adjusted Employees"; Rec."Adjusted Employees")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of emplooyee ledger entries with remaining amount that was adjusted.';
                    Visible = false;
                }
                field("Adjusted Base"; Rec."Adjusted Base")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the amount that was adjusted by the batch job for customer, vendor and/or bank ledger entries.';
                }
                field("Adjusted Base (LCY)"; Rec."Adjusted Base (LCY)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the amount in LCY that was adjusted by the batch job for G/L, customer, vendor and/or bank ledger entries.';
                }
                field("Adjusted Amt. (LCY)"; Rec."Adjusted Amt. (LCY)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the amount by which the batch job has adjusted G/L, customer, vendor and/or bank ledger entries for exchange rate fluctuations.';
                }
                field("Adjustment Amount"; Rec."Adjustment Amount")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the total adjustment amount of exchange rate adjustment ledger entries.';
                    Visible = false;
                }
                field("Adjusted Base (Add.-Curr.)"; Rec."Adjusted Base (Add.-Curr.)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the additional-reporting-currency amount the batch job has adjusted G/L, customer, and other entries for exchange rate fluctuations.';
                    Visible = false;
                }
                field("Adjusted Amt. (Add.-Curr.)"; Rec."Adjusted Amt. (Add.-Curr.)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the additional-reporting-currency amount the batch job has adjusted G/L, customer, and other entries for exchange rate fluctuations.';
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
        area(navigation)
        {
            group("Ledger Entries")
            {
                Caption = 'Exch. Rate Adjmt. Ledger Entries';
                Image = Entry;
                action("Show Ledger Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Ledger Entries';
                    Image = LedgerEntries;
                    RunObject = Page "Exch.Rate Adjmt. Ledg.Entries";
                    RunPageLink = "Register No." = field("No.");
                    Scope = Repeater;
                    ToolTip = 'View adjusted customer or vendor ledger entries for this register.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Show Ledger Entries_Promoted"; "Show Ledger Entries")
                {
                }
            }
        }
    }
}

