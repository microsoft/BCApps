// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Depreciation;

using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Posting;

page 5610 "Depreciation Book Card"
{
    Caption = 'Depreciation Book Card';
    PageType = Card;
    RefreshOnActivate = true;
    SourceTable = "Depreciation Book";
    AboutTitle = 'About Depreciation Book Card';
    AboutText = 'With the **Depreciation Book Card** you manage information about the Depreciation Book. Specify the Integration between the G/L accounts with applicable transactions. Option to duplicate the entries made in another depreciation book to this depreciation book, option to enable the details for reporting with additional currency exchange rates.';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                AboutTitle = 'Manage the Depreciation Book''s general details';
                AboutText = 'Here you can specify the default values used in creating fixed asset transactions for a given depreciation book. The card will have the applicable options to allow certain features/changes or corrections.';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = FixedAssets;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = FixedAssets;
                }
                field("Default Final Rounding Amount"; Rec."Default Final Rounding Amount")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the final rounding amount to use if the Final Rounding Amount field is zero.';
                }
                field("Default Ending Book Value"; Rec."Default Ending Book Value")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the ending book value to use if the Ending Book Value field is zero.';
                }
                field("Disposal Calculation Method"; Rec."Disposal Calculation Method")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the disposal method for the current depreciation book.';
                }
                field("Subtract Disc. in Purch. Inv."; Rec."Subtract Disc. in Purch. Inv.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies that the line and invoice discount are subtracted from the acquisition cost posted for the fixed asset.';
                }
                field("Allow Correction of Disposal"; Rec."Allow Correction of Disposal")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies whether to correct fixed ledger entries of the Disposal type.';
                }
                field("Allow Changes in Depr. Fields"; Rec."Allow Changes in Depr. Fields")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies whether to allow the depreciation fields to be modified.';
                }
                field("VAT on Net Disposal Entries"; Rec."VAT on Net Disposal Entries")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies whether you sell a fixed asset with the net disposal method.';
                }
                field("Allow Identical Document No."; Rec."Allow Identical Document No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the check box for this field to allow identical document numbers in the depreciation book.';
                }
                field("Allow Indexation"; Rec."Allow Indexation")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies whether to allow indexation of FA ledger entries and maintenance ledger entries posted to this book.';
                }
                field("Allow Depr. below Zero"; Rec."Allow Depr. below Zero")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies whether to allow the Calculate Depreciation batch job to continue calculating depreciation even if the book value is zero or below.';
                }
                field("Allow more than 360/365 Days"; Rec."Allow more than 360/365 Days")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies if the fiscal year has more than 360 depreciation days.';
                }
                field("Use FA Ledger Check"; Rec."Use FA Ledger Check")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies which checks to perform before posting a journal line.';
                }
                field("Use Rounding in Periodic Depr."; Rec."Use Rounding in Periodic Depr.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies whether the calculated periodic depreciation amounts should be rounded to whole numbers.';
                }
                field("Use Same FA+G/L Posting Dates"; Rec."Use Same FA+G/L Posting Dates")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies whether to indicate that the Posting Date and the FA Posting Date must be the same on a journal line before posting.';
                }
                field("Fiscal Year 365 Days"; Rec."Fiscal Year 365 Days")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies that when the Calculate Depreciation batch job calculates depreciations, a standardized year of 360 days, where each month has 30 days, is used.';
                }
                field("Use Accounting Period"; Rec."Use Accounting Period")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies if you want the periods between start date and ending date to correspond to the accounting periods that you have set up.';
                }
            }
            group(Integration)
            {
                Caption = 'Integration';
                AboutTitle = 'Manage the Depreciation Book''s integration details.';
                AboutText = 'On enabling the applicable options against which the G/L Integration is to be used, the amounts get posted to the G/L Account when you post the transactions with the Fixed Assets.';
                group("G/L Integration")
                {
                    Caption = 'G/L Integration';
                    field("G/L Integration - Acq. Cost"; Rec."G/L Integration - Acq. Cost")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'G/L Integration - Acq. Cost';
                        ToolTip = 'Specifies whether acquisition cost entries posted to this depreciation book are posted both to the general ledger and the FA ledger.';
                    }
                    field("G/L Integration - Depreciation"; Rec."G/L Integration - Depreciation")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'G/L Integration - Depreciation';
                        ToolTip = 'Specifies whether depreciation entries posted to this depreciation book are posted both to the general ledger and the FA ledger.';
                    }
                    field("G/L Integration - Write-Down"; Rec."G/L Integration - Write-Down")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'G/L Integration - Write-Down';
                        ToolTip = 'Specifies whether write-down entries posted to this depreciation book should be posted to the general ledger and the FA ledger.';
                    }
                    field("G/L Integration - Appreciation"; Rec."G/L Integration - Appreciation")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'G/L Integration - Appreciation';
                        ToolTip = 'Specifies whether appreciation entries posted to this depreciation book are posted to the general ledger and the FA ledger.';
                    }
                    field("G/L Integration - Custom 1"; Rec."G/L Integration - Custom 1")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'G/L Integration - Custom 1';
                        ToolTip = 'Specifies whether custom 1 entries posted to this depreciation book are posted to the general ledger and the FA ledger.';
                    }
                    field("G/L Integration - Custom 2"; Rec."G/L Integration - Custom 2")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'G/L Integration - Custom 2';
                        ToolTip = 'Specifies whether custom 2 entries posted to this depreciation book are posted to the general ledger and the FA ledger.';
                    }
                    field("G/L Integration - Disposal"; Rec."G/L Integration - Disposal")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'G/L Integration - Disposal';
                        ToolTip = 'Specifies whether disposal entries posted to this depreciation book are posted to the general ledger and the FA ledger.';
                    }
                    field("G/L Integration - Maintenance"; Rec."G/L Integration - Maintenance")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'G/L Integration - Maintenance';
                        ToolTip = 'Specifies whether maintenance entries that are posted to this depreciation book are posted both to the general ledger and the FA ledger.';
                    }
                }
            }
            group(Duplication)
            {
                Caption = 'Duplication';
                AboutTitle = 'Manage the Depreciation Book''s duplication details';
                AboutText = 'Enable the applicable options to indicate that entries made in another depreciation book should be duplicated to this depreciation book as well.';
                field("Part of Duplication List"; Rec."Part of Duplication List")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies whether to indicate that entries made in another depreciation book should be duplicated to this depreciation book.';
                }
                field("Use FA Exch. Rate in Duplic."; Rec."Use FA Exch. Rate in Duplic.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies whether to use the FA Exchange Rate field when you duplicate entries from one depreciation book to another.';
                }
                field("Default Exchange Rate"; Rec."Default Exchange Rate")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the exchange rate to use if the rate in the FA Exchange Rate field is zero.';
                }
            }
            group(Reporting)
            {
                Caption = 'Reporting';
                group("Use Add.-Curr Exch. Rate")
                {
                    Caption = 'Use Add.-Curr Exch. Rate';
                    field("Add-Curr Exch Rate - Acq. Cost"; Rec."Add-Curr Exch Rate - Acq. Cost")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Add-Curr Exch Rate - Acq. Cost';
                        ToolTip = 'Specifies that acquisition transactions in the general ledger can be in both LCY and any additional reporting currency.';
                    }
                    field("Add.-Curr. Exch. Rate - Depr."; Rec."Add.-Curr. Exch. Rate - Depr.")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Depreciation';
                        ToolTip = 'Specifies depreciation transactions in the general ledger in both LCY and any additional reporting currency.';
                    }
                    field("Add-Curr Exch Rate -Write-Down"; Rec."Add-Curr Exch Rate -Write-Down")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Write-Down';
                        ToolTip = 'Specifies write-down transactions in the general ledger in both LCY and any additional reporting currency.';
                    }
                    field("Add-Curr. Exch. Rate - Apprec."; Rec."Add-Curr. Exch. Rate - Apprec.")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Add-Curr. Exch. Rate - Apprec.';
                        ToolTip = 'Specifies appreciation transactions in the general ledger in both LCY and any additional reporting currency.';
                    }
                    field("Add-Curr. Exch Rate - Custom 1"; Rec."Add-Curr. Exch Rate - Custom 1")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Custom 1';
                        ToolTip = 'Specifies that custom 1 transactions in the general ledger can be in both LCY and any additional reporting currency.';
                    }
                    field("Add-Curr. Exch Rate - Custom 2"; Rec."Add-Curr. Exch Rate - Custom 2")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Custom 2';
                        ToolTip = 'Specifies custom 2 transactions in the general ledger in both LCY and any additional reporting currency.';
                    }
                    field("Add.-Curr. Exch. Rate - Disp."; Rec."Add.-Curr. Exch. Rate - Disp.")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Disposal';
                        ToolTip = 'Specifies disposal transactions in the general ledger in both LCY and any additional reporting currency.';
                    }
                    field("Add.-Curr. Exch. Rate - Maint."; Rec."Add.-Curr. Exch. Rate - Maint.")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Maintenance';
                        ToolTip = 'Specifies maintenance transactions in the general ledger in both LCY and any additional reporting currency.';
                    }
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
            group("&Depr. Book")
            {
                Caption = '&Depr. Book';
                action("FA Posting Type Setup")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'FA Posting Type Setup';
                    Ellipsis = false;
                    Image = Setup;
                    RunObject = Page "FA Posting Type Setup";
                    RunPageLink = "Depreciation Book Code" = field(Code);
                    ToolTip = 'Set up how to handle the write-down, appreciation, custom 1, and custom 2 posting types that you use when posting to fixed assets.';
                }
                action("FA &Journal Setup")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'FA &Journal Setup';
                    Image = JournalSetup;
                    RunObject = Page "FA Journal Setup";
                    RunPageLink = "Depreciation Book Code" = field(Code);
                    ToolTip = 'Set up the FA general ledger journal, the FA journal, and the insurance journal templates and batches to use when duplicating depreciation entries and acquisition-cost entries and when calculating depreciation or indexing fixed assets.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Create FA Depreciation Books")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Create FA Depreciation Books';
                    Ellipsis = true;
                    Image = NewDepreciationBook;
                    RunObject = Report "Create FA Depreciation Books";
                    ToolTip = 'Create depreciation books for the fixed asset. You can create empty fixed asset depreciation books, for example for all fixed assets, when you have set up a new depreciation book. You can also use an existing fixed asset depreciation book as the basis for new book.';
                }
                action("C&opy Depreciation Book")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'C&opy Depreciation Book';
                    Ellipsis = true;
                    Image = CopyDepreciationBook;
                    RunObject = Report "Copy Depreciation Book";
                    ToolTip = 'Copy specified entries from one depreciation book to another. The entries are not posted to the new depreciation book - they are either inserted as lines in a general ledger fixed asset journal or in a fixed asset journal, depending on whether the new depreciation book has activated general ledger integration.';
                }
                action("C&ancel FA Ledger Entries")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'C&ancel FA Ledger Entries';
                    Ellipsis = true;
                    Image = CancelFALedgerEntries;
                    RunObject = Report "Cancel FA Ledger Entries";
                    ToolTip = 'Remove one or more fixed asset ledger entries from the FA Ledger Entries window. If you posted erroneous transactions to one or more fixed assets, you can use this function to cancel the fixed asset ledger entries. In the FA Ledger Entries window, select the entry or entries that you want to cancel.';
                }
                action("Co&py FA Entries to G/L Budget")
                {
                    ApplicationArea = Suite;
                    Caption = 'Co&py FA Entries to G/L Budget';
                    Ellipsis = true;
                    Image = CopyLedgerToBudget;
                    RunObject = Report "Copy FA Entries to G/L Budget";
                    ToolTip = 'Copy the fixed asset ledger entries to budget entries.';
                }
            }
        }
    }
}

