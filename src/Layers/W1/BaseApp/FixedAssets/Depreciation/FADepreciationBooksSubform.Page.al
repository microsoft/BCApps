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

page 5666 "FA Depreciation Books Subform"
{
    Caption = 'Lines';
    DataCaptionFields = "FA No.", "Depreciation Book Code";
    DelayedInsert = true;
    LinksAllowed = false;
    PageType = ListPart;
    RefreshOnActivate = true;
    SourceTable = "FA Depreciation Book";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Depreciation Book Code"; Rec."Depreciation Book Code")
                {
                    ApplicationArea = FixedAssets;
                    Editable = true;
                    ToolTip = 'Specifies the depreciation book that is assigned to the fixed asset.';
                }
                field(AddCurrCode; GetACYCode())
                {
                    ApplicationArea = Suite;
                    Caption = 'FA Add.-Currency Code';
                    ToolTip = 'Specifies an additional currency to be used when posting.';
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
                }
                field("Depreciation Method"; Rec."Depreciation Method")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Depreciation Starting Date"; Rec."Depreciation Starting Date")
                {
                    ApplicationArea = FixedAssets;
                }
                field("No. of Depreciation Years"; Rec."No. of Depreciation Years")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Depreciation Ending Date"; Rec."Depreciation Ending Date")
                {
                    ApplicationArea = FixedAssets;
                }
                field("No. of Depreciation Months"; Rec."No. of Depreciation Months")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Straight-Line %"; Rec."Straight-Line %")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Fixed Depr. Amount"; Rec."Fixed Depr. Amount")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Declining-Balance %"; Rec."Declining-Balance %")
                {
                    ApplicationArea = FixedAssets;
                }
                field("First User-Defined Depr. Date"; Rec."First User-Defined Depr. Date")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
#pragma warning disable AA0100
                field("""Disposal Date"" > 0D"; Rec."Disposal Date" > 0D)
#pragma warning restore AA0100
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Disposed Of';
                    Editable = false;
                    ToolTip = 'Specifies whether the fixed asset has been disposed of.';
                }
                field(BookValue; BookValue)
                {
                    ApplicationArea = FixedAssets;
                    AutoFormatType = 1;
                    AutoFormatExpression = Rec.GetCurrencyCode();
                    Caption = 'Book Value';
                    Editable = false;
                    ToolTip = 'Specifies the book value for the fixed asset as a FlowField.';

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownOnBookValue();
                    end;
                }
                field("Depreciation Table Code"; Rec."Depreciation Table Code")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Final Rounding Amount"; Rec."Final Rounding Amount")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Ending Book Value"; Rec."Ending Book Value")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Ignore Def. Ending Book Value"; Rec."Ignore Def. Ending Book Value")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("FA Exchange Rate"; Rec."FA Exchange Rate")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Use FA Ledger Check"; Rec."Use FA Ledger Check")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Depr. below Zero %"; Rec."Depr. below Zero %")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Fixed Depr. Amount below Zero"; Rec."Fixed Depr. Amount below Zero")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Projected Disposal Date"; Rec."Projected Disposal Date")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Projected Proceeds on Disposal"; Rec."Projected Proceeds on Disposal")
                {
                    ApplicationArea = FixedAssets;
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
                    Visible = false;
                }
                field("Use DB% First Fiscal Year"; Rec."Use DB% First Fiscal Year")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Temp. Ending Date"; Rec."Temp. Ending Date")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Temp. Fixed Depr. Amount"; Rec."Temp. Fixed Depr. Amount")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Default FA Depreciation Book"; Rec."Default FA Depreciation Book")
                {
                    ApplicationArea = FixedAssets;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Depr. Book")
            {
                Caption = '&Depr. Book';
                Image = DepreciationBooks;
                action("Ledger E&ntries")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Ledger E&ntries';
                    Image = CustomerLedger;
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';

                    trigger OnAction()
                    begin
                        ShowFALedgEntries();
                    end;
                }
                action("Error Ledger Entries")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Error Ledger Entries';
                    Image = ErrorFALedgerEntries;
                    ToolTip = 'View the entries that have been posted as a result of you using the Cancel function to cancel an entry.';

                    trigger OnAction()
                    begin
                        ShowFAErrorLedgEntries();
                    end;
                }
                action("Maintenance Ledger Entries")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Maintenance Ledger Entries';
                    Image = MaintenanceLedgerEntries;
                    ToolTip = 'View the maintenance ledger entries for the fixed asset.';

                    trigger OnAction()
                    begin
                        ShowMaintenanceLedgEntries();
                    end;
                }
                action(Statistics)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Statistics';
                    Image = Statistics;
                    ShortCutKey = 'F7';
                    ToolTip = 'View detailed historical information about the fixed asset.';
                    RunObject = Page "Fixed Asset Statistics";
                    RunPageLink = "FA No." = field("FA No."),
                                  "Depreciation Book Code" = field("Depreciation Book Code");
                    RunPageOnRec = true;
                }
                action("Main &Asset Statistics")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Main &Asset Statistics';
                    Image = StatisticsDocument;
                    ToolTip = 'View statistics for all the components that make up the main asset for the selected book. ';
                    RunObject = Page "Main Asset Statistics";
                    RunPageLink = "FA No." = field("FA No."),
                                  "Depreciation Book Code" = field("Depreciation Book Code");
                    RunPageOnRec = true;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        BookValue := GetBookValue();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        BookValue := GetBookValue();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        BookValue := 0;
    end;

    var
        GLSetup: Record "General Ledger Setup";
        FALedgEntry: Record "FA Ledger Entry";
        MaintenanceLedgEntry: Record "Maintenance Ledger Entry";
        DepreciationCalc: Codeunit "Depreciation Calculation";
        ChangeExchangeRate: Page "Change Exchange Rate";
        AddCurrCodeIsFound: Boolean;
        BookValue: Decimal;

    local procedure GetACYCode(): Code[10]
    begin
        if not AddCurrCodeIsFound then
            GLSetup.Get();
        exit(GLSetup."Additional Reporting Currency");
    end;

    local procedure ShowFALedgEntries()
    begin
        DepreciationCalc.SetFAFilter(FALedgEntry, Rec."FA No.", Rec."Depreciation Book Code", false);
        PAGE.Run(PAGE::"FA Ledger Entries", FALedgEntry);
    end;

    local procedure ShowFAErrorLedgEntries()
    begin
        FALedgEntry.Reset();
        FALedgEntry.SetCurrentKey("Canceled from FA No.");
        FALedgEntry.SetRange("Canceled from FA No.", Rec."FA No.");
        FALedgEntry.SetRange("Depreciation Book Code", Rec."Depreciation Book Code");
        PAGE.Run(PAGE::"FA Error Ledger Entries", FALedgEntry);
    end;

    local procedure ShowMaintenanceLedgEntries()
    begin
        MaintenanceLedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code");
        MaintenanceLedgEntry.SetRange("FA No.", Rec."FA No.");
        MaintenanceLedgEntry.SetRange("Depreciation Book Code", Rec."Depreciation Book Code");
        PAGE.Run(PAGE::"Maintenance Ledger Entries", MaintenanceLedgEntry);
    end;

    local procedure GetBookValue(): Decimal
    begin
        if Rec."Disposal Date" > 0D then
            exit(0);
        Rec.CalcFields("Book Value");
        exit(Rec."Book Value");
    end;
}
