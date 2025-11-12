// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Depreciation;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.FixedAssets.Posting;

page 5619 "FA Depreciation Books"
{
    Caption = 'FA Depreciation Books';
    DataCaptionFields = "FA No.", "Depreciation Book Code";
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "FA Depreciation Book";
    AnalysisModeEnabled = false;
    AboutTitle = 'About FA Depreciation Books';
    AboutText = 'The **FA Depreciation Books** help us to maintain multiple depreciation books for a fixed asset with different Depreciation percentages.';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("FA No."; Rec."FA No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number of the related fixed asset. ';
                }
                field("Depreciation Book Code"; Rec."Depreciation Book Code")
                {
                    ApplicationArea = FixedAssets;
                    AboutTitle = 'FA Depreciation Books configuration';
                    AboutText = 'Specify the details to update the different depreciation books with different depreciation methods, and percentages for a fixed asset.';
                    ToolTip = 'Specifies the code for the depreciation book to which the line will be posted if you have selected Fixed Asset in the Type field for this line.';
                }
                field(AddCurrCode; GetACYCode())
                {
                    ApplicationArea = Suite;
                    Caption = 'FA Add.-Currency Code';
                    ToolTip = 'Specifies the exchange rate to be used if you post in an additional currency.';
                    Visible = false;

                    trigger OnAssistEdit()
                    begin
                        ChangeExchangeRate.SetParameterFA(Rec."FA Add.-Currency Factor", GetACYCode(), WorkDate());
                        if ChangeExchangeRate.RunModal() = ACTION::OK then
                            Rec."FA Add.-Currency Factor" := ChangeExchangeRate.GetParameter();

                        Clear(ChangeExchangeRate);
                    end;
                }
                field("FA Posting Group"; Rec."FA Posting Group")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies which posting group is used for the depreciation book when posting fixed asset transactions.';
                }
                field("Depreciation Method"; Rec."Depreciation Method")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies how depreciation is calculated for the depreciation book.';
                }
                field("No. of Depreciation Years"; Rec."No. of Depreciation Years")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the length of the depreciation period, expressed in years.';
                }
                field("Depreciation Starting Date"; Rec."Depreciation Starting Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the date on which depreciation of the fixed asset starts.';
                }
                field("No. of Depreciation Months"; Rec."No. of Depreciation Months")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the length of the depreciation period, expressed in months.';
                    Visible = false;
                }
                field("Depreciation Ending Date"; Rec."Depreciation Ending Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the date on which depreciation of the fixed asset ends.';
                }
                field("Straight-Line %"; Rec."Straight-Line %")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the percentage to depreciate the fixed asset by the straight-line principle, but with a fixed yearly percentage.';
                    Visible = false;
                }
                field("Fixed Depr. Amount"; Rec."Fixed Depr. Amount")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies an amount to depreciate the fixed asset, by a fixed yearly amount.';
                    Visible = false;
                }
                field("Declining-Balance %"; Rec."Declining-Balance %")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the percentage to depreciate the fixed asset by the declining-balance principle, but with a fixed yearly percentage.';
                    Visible = false;
                }
                field("First User-Defined Depr. Date"; Rec."First User-Defined Depr. Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the starting date for the user-defined depreciation table if you have entered a code in the Depreciation Table Code field.';
                    Visible = false;
                }
                field("Depreciation Table Code"; Rec."Depreciation Table Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the code of the depreciation table to use if you have selected the User-Defined option in the Depreciation Method field.';
                    Visible = false;
                }
                field("Final Rounding Amount"; Rec."Final Rounding Amount")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the final rounding amount to use.';
                    Visible = false;
                }
                field("Ending Book Value"; Rec."Ending Book Value")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the amount to use as the ending book value.';
                    Visible = false;
                }
                field("Ignore Def. Ending Book Value"; Rec."Ignore Def. Ending Book Value")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies that the default ending book value is ignored, and the value in the Ending Book Value is used.';
                    Visible = false;
                }
                field("FA Exchange Rate"; Rec."FA Exchange Rate")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a decimal number, which will be used as an exchange rate when duplicating journal lines to this depreciation book.';
                    Visible = false;
                }
                field("Use FA Ledger Check"; Rec."Use FA Ledger Check")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies which checks to perform before posting a journal line.';
                    Visible = false;
                }
                field("Depr. below Zero %"; Rec."Depr. below Zero %")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a percentage if you have selected the Allow Depr. below Zero field in the depreciation book.';
                    Visible = false;
                }
                field("Fixed Depr. Amount below Zero"; Rec."Fixed Depr. Amount below Zero")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a positive amount if you have selected the Allow Depr. below Zero field in the depreciation book.';
                    Visible = false;
                }
                field("Projected Disposal Date"; Rec."Projected Disposal Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the date on which you want to dispose of the fixed asset.';
                    Visible = false;
                }
                field("Projected Proceeds on Disposal"; Rec."Projected Proceeds on Disposal")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the expected proceeds from disposal of the fixed asset.';
                    Visible = false;
                }
                field("Depr. Starting Date (Custom 1)"; Rec."Depr. Starting Date (Custom 1)")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the starting date for depreciation of custom 1 entries.';
                    Visible = false;
                }
                field("Depr. Ending Date (Custom 1)"; Rec."Depr. Ending Date (Custom 1)")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the ending date for depreciation of custom 1 entries.';
                    Visible = false;
                }
                field("Accum. Depr. % (Custom 1)"; Rec."Accum. Depr. % (Custom 1)")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the total percentage for depreciation of custom 1 entries.';
                    Visible = false;
                }
                field("Depr. This Year % (Custom 1)"; Rec."Depr. This Year % (Custom 1)")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the percentage for depreciation of custom 1 entries for the current year.';
                    Visible = false;
                }
                field("Property Class (Custom 1)"; Rec."Property Class (Custom 1)")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the property class of the asset.';
                    Visible = false;
                }
                field("Use Half-Year Convention"; Rec."Use Half-Year Convention")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies that the Half-Year Convention is to be applied to the selected depreciation method.';
                    Visible = false;
                }
                field("Use DB% First Fiscal Year"; Rec."Use DB% First Fiscal Year")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies that the depreciation methods DB1/SL and DB2/SL use the declining balance depreciation amount in the first fiscal year.';
                    Visible = false;
                }
                field("Temp. Ending Date"; Rec."Temp. Ending Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the ending date of the period during which a temporary fixed depreciation amount will be used.';
                    Visible = false;
                }
                field("Temp. Fixed Depr. Amount"; Rec."Temp. Fixed Depr. Amount")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a temporary fixed depreciation amount.';
                    Visible = false;
                }
                field("Default FA Depreciation Book"; Rec."Default FA Depreciation Book")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the depreciation book that is used by default on documents and journals when a fixed asset has more than one depreciation book. A fixed asset can have only one default depreciation book. If a depreciation book is not specified for a fixed asset, the default depreciation book from the fixed asset setup is used.';
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
                action("Ledger E&ntries")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Ledger E&ntries';
                    Image = FixedAssetLedger;
                    RunObject = Page "FA Ledger Entries";
                    RunPageLink = "FA No." = field("FA No."),
                                  "Depreciation Book Code" = field("Depreciation Book Code");
                    RunPageView = sorting("FA No.", "Depreciation Book Code");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
                action("Error Ledger Entries")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Error Ledger Entries';
                    Image = ErrorFALedgerEntries;
                    RunObject = Page "FA Error Ledger Entries";
                    RunPageLink = "Canceled from FA No." = field("FA No."),
                                  "Depreciation Book Code" = field("Depreciation Book Code");
                    RunPageView = sorting("Canceled from FA No.", "Depreciation Book Code");
                    ToolTip = 'View the entries that have been posted as a result of you using the Cancel function to cancel an entry.';
                }
                action("Maintenance Ledger Entries")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Maintenance Ledger Entries';
                    Image = MaintenanceLedgerEntries;
                    RunObject = Page "Maintenance Ledger Entries";
                    RunPageLink = "FA No." = field("FA No."),
                                  "Depreciation Book Code" = field("Depreciation Book Code");
                    RunPageView = sorting("FA No.", "Depreciation Book Code");
                    ToolTip = 'View the maintenance ledger entries for the selected fixed asset.';
                }
                separator(Action65)
                {
                }
                action(Statistics)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Fixed Asset Statistics";
                    RunPageLink = "FA No." = field("FA No."),
                                  "Depreciation Book Code" = field("Depreciation Book Code");
                    ShortCutKey = 'F7';
                    ToolTip = 'View detailed historical information about the fixed asset.';
                }
                action("Main &Asset Statistics")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Main &Asset Statistics';
                    Image = StatisticsDocument;
                    RunObject = Page "Main Asset Statistics";
                    RunPageLink = "FA No." = field("FA No."),
                                  "Depreciation Book Code" = field("Depreciation Book Code");
                    ToolTip = 'View statistics for all the components that make up the main asset for the selected book. The left side of the General FastTab displays the main asset''s book value, depreciable basis and any maintenance expenses posted to the components that comprise the main asset. The right side shows the number of components for the main asset, the first date on which an acquisition and/or disposal entry was posted to one of the assets that comprise the main asset.';
                }
                action("FA Posting Types Overview")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'FA Posting Types Overview';
                    Image = ShowMatrix;
                    RunObject = Page "FA Posting Types Overview";
                    ToolTip = 'View accumulated amounts for each field, such as book value, acquisition cost, and depreciation, and for each fixed asset. For every fixed asset, a separate line is shown for each depreciation book linked to the fixed asset.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Statistics_Promoted; Statistics)
                {
                }
            }
        }
    }

    var
        GLSetup: Record "General Ledger Setup";
        ChangeExchangeRate: Page "Change Exchange Rate";
        AddCurrCodeIsFound: Boolean;

    local procedure GetACYCode(): Code[10]
    begin
        if not AddCurrCodeIsFound then
            GLSetup.Get();
        exit(GLSetup."Additional Reporting Currency");
    end;
}

