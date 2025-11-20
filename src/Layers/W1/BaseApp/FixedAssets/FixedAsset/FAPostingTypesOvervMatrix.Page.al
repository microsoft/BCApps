// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Posting;

using Microsoft.Finance.Analysis;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.Foundation.Enums;

page 9277 "FA Posting Types Overv. Matrix"
{
    Caption = 'FA Posting Types Overv. Matrix';
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "FA Depreciation Book";
    AboutTitle = 'About FA Posting Types Overv. Matrix';
    AboutText = 'With the **FA Posting Types Overv. Matrix**, you can review accumulated amounts for each field, such as book value, acquisition cost, and depreciation, and for each fixed asset. For every fixed asset, a separate line is shown for each depreciation book linked to the asset.';

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
                    Caption = 'Depreciation Book Code';
                    ToolTip = 'Specifies a depreciation book to assign to the fixed asset you have entered in the FA No. field.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the value in the Description field on the fixed asset card.';
                }
                field(Field1; MATRIX_CellData[1])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[1];
                    DrillDown = true;
                    Visible = Field1Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(1);
                    end;
                }
                field(Field2; MATRIX_CellData[2])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[2];
                    DrillDown = true;
                    Visible = Field2Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(2);
                    end;
                }
                field(Field3; MATRIX_CellData[3])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[3];
                    DrillDown = true;
                    Visible = Field3Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(3);
                    end;
                }
                field(Field4; MATRIX_CellData[4])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[4];
                    DrillDown = true;
                    Visible = Field4Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(4);
                    end;
                }
                field(Field5; MATRIX_CellData[5])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[5];
                    DrillDown = true;
                    Visible = Field5Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(5);
                    end;
                }
                field(Field6; MATRIX_CellData[6])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[6];
                    DrillDown = true;
                    Visible = Field6Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(6);
                    end;
                }
                field(Field7; MATRIX_CellData[7])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[7];
                    DrillDown = true;
                    Visible = Field7Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(7);
                    end;
                }
                field(Field8; MATRIX_CellData[8])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[8];
                    DrillDown = true;
                    Visible = Field8Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(8);
                    end;
                }
                field(Field9; MATRIX_CellData[9])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[9];
                    DrillDown = true;
                    Visible = Field9Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(9);
                    end;
                }
                field(Field10; MATRIX_CellData[10])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[10];
                    DrillDown = true;
                    Visible = Field10Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(10);
                    end;
                }
                field(Field11; MATRIX_CellData[11])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[11];
                    DrillDown = true;
                    Visible = Field11Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(11);
                    end;
                }
                field(Field12; MATRIX_CellData[12])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[12];
                    DrillDown = true;
                    Visible = Field12Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(12);
                    end;
                }
                field(Field13; MATRIX_CellData[13])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[13];
                    DrillDown = true;
                    Visible = Field13Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(13);
                    end;
                }
                field(Field14; MATRIX_CellData[14])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[14];
                    DrillDown = true;
                    Visible = Field14Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(14);
                    end;
                }
                field(Field15; MATRIX_CellData[15])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[15];
                    DrillDown = true;
                    Visible = Field15Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(15);
                    end;
                }
                field(Field16; MATRIX_CellData[16])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[16];
                    DrillDown = true;
                    Visible = Field16Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(16);
                    end;
                }
                field(Field17; MATRIX_CellData[17])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[17];
                    DrillDown = true;
                    Visible = Field17Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(17);
                    end;
                }
                field(Field18; MATRIX_CellData[18])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[18];
                    DrillDown = true;
                    Visible = Field18Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(18);
                    end;
                }
                field(Field19; MATRIX_CellData[19])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[19];
                    DrillDown = true;
                    Visible = Field19Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(19);
                    end;
                }
                field(Field20; MATRIX_CellData[20])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[20];
                    DrillDown = true;
                    Visible = Field20Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(20);
                    end;
                }
                field(Field21; MATRIX_CellData[21])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[21];
                    DrillDown = true;
                    Visible = Field21Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(21);
                    end;
                }
                field(Field22; MATRIX_CellData[22])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[22];
                    DrillDown = true;
                    Visible = Field22Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(22);
                    end;
                }
                field(Field23; MATRIX_CellData[23])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[23];
                    DrillDown = true;
                    Visible = Field23Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(23);
                    end;
                }
                field(Field24; MATRIX_CellData[24])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[24];
                    DrillDown = true;
                    Visible = Field24Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(24);
                    end;
                }
                field(Field25; MATRIX_CellData[25])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[25];
                    DrillDown = true;
                    Visible = Field25Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(25);
                    end;
                }
                field(Field26; MATRIX_CellData[26])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[26];
                    DrillDown = true;
                    Visible = Field26Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(26);
                    end;
                }
                field(Field27; MATRIX_CellData[27])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[27];
                    DrillDown = true;
                    Visible = Field27Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(27);
                    end;
                }
                field(Field28; MATRIX_CellData[28])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[28];
                    DrillDown = true;
                    Visible = Field28Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(28);
                    end;
                }
                field(Field29; MATRIX_CellData[29])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[29];
                    DrillDown = true;
                    Visible = Field29Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(29);
                    end;
                }
                field(Field30; MATRIX_CellData[30])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[30];
                    DrillDown = true;
                    Visible = Field30Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(30);
                    end;
                }
                field(Field31; MATRIX_CellData[31])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[31];
                    DrillDown = true;
                    Visible = Field31Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(31);
                    end;
                }
                field(Field32; MATRIX_CellData[32])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[32];
                    DrillDown = true;
                    Visible = Field32Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(32);
                    end;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Related Information")
            {
                Caption = '&Related Information';
                Image = RelatedInformation;
                action("Ledger E&ntries")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Ledger E&ntries';
                    Image = FixedAssetLedger;
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';

                    trigger OnAction()
                    var
                        FALedgEntry: Record "FA Ledger Entry";
                    begin
                        FALedgEntry.SetRange("FA No.", Rec."FA No.");
                        FALedgEntry.SetRange("Depreciation Book Code", Rec."Depreciation Book Code");
                        FALedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code");

                        PAGE.Run(PAGE::"FA Ledger Entries", FALedgEntry);
                    end;
                }
                action("Error Ledger Entries")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Error Ledger Entries';
                    Image = ErrorFALedgerEntries;
                    ToolTip = 'View the entries that have been posted as a result of you using the cancel function to cancel an entry.';

                    trigger OnAction()
                    var
                        FALedgEntry: Record "FA Ledger Entry";
                    begin
                        FALedgEntry.SetRange("Canceled from FA No.", Rec."FA No.");
                        FALedgEntry.SetRange("Depreciation Book Code", Rec."Depreciation Book Code");
                        FALedgEntry.SetCurrentKey("Canceled from FA No.", "Depreciation Book Code");

                        PAGE.Run(PAGE::"FA Error Ledger Entries", FALedgEntry);
                    end;
                }
                action("Maintenance Ledger Entries")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Maintenance Ledger Entries';
                    Image = MaintenanceLedgerEntries;
                    ToolTip = 'View the maintenance ledger entries for the selected fixed asset.';

                    trigger OnAction()
                    var
                        MaintLedgEntry: Record "Maintenance Ledger Entry";
                    begin
                        MaintLedgEntry.SetRange("FA No.", Rec."FA No.");
                        MaintLedgEntry.SetRange("Depreciation Book Code", Rec."Depreciation Book Code");
                        MaintLedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code");

                        PAGE.Run(PAGE::"Maintenance Ledger Entries", MaintLedgEntry);
                    end;
                }
                separator(Action11)
                {
                }
                action(Statistics)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Statistics';
                    Image = Statistics;
                    ShortCutKey = 'F7';
                    AboutTitle = 'Review Fixed Asset Statistics';
                    AboutText = 'Review the asset-wise Statistics details for main and component assets.';
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
                    ToolTip = 'View statistics for all the components that make up the main asset for the selected book. The left side of the General FastTab displays the main asset''s book value, depreciable basis and any maintenance expenses posted to the components that comprise the main asset. The right side shows the number of components for the main asset, the first date on which an acquisition and/or disposal entry was posted to one of the assets that comprise the main asset.';
                    RunObject = Page "Main Asset Statistics";
                    RunPageLink = "FA No." = field("FA No."),
                                  "Depreciation Book Code" = field("Depreciation Book Code");
                    RunPageOnRec = true;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

            }
            group("Category_Fixed Asset")
            {
                Caption = 'Fixed Asset';

                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("Main &Asset Statistics_Promoted"; "Main &Asset Statistics")
                {
                }
            }
            group(Category_Entry)
            {
                Caption = 'Entry';

                actionref("Ledger E&ntries_Promoted"; "Ledger E&ntries")
                {
                }
                actionref("Maintenance Ledger Entries_Promoted"; "Maintenance Ledger Entries")
                {
                }
                actionref("Error Ledger Entries_Promoted"; "Error Ledger Entries")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        MATRIX_CurrentColumnOrdinal: Integer;
    begin
        MATRIX_CurrentColumnOrdinal := 0;
        while MATRIX_CurrentColumnOrdinal < MATRIX_CurrentNoOfMatrixColumn do begin
            MATRIX_CurrentColumnOrdinal := MATRIX_CurrentColumnOrdinal + 1;
            MATRIX_OnAfterGetRecord(MATRIX_CurrentColumnOrdinal);
        end;
    end;

    trigger OnInit()
    begin
        Field32Visible := true;
        Field31Visible := true;
        Field30Visible := true;
        Field29Visible := true;
        Field28Visible := true;
        Field27Visible := true;
        Field26Visible := true;
        Field25Visible := true;
        Field24Visible := true;
        Field23Visible := true;
        Field22Visible := true;
        Field21Visible := true;
        Field20Visible := true;
        Field19Visible := true;
        Field18Visible := true;
        Field17Visible := true;
        Field16Visible := true;
        Field15Visible := true;
        Field14Visible := true;
        Field13Visible := true;
        Field12Visible := true;
        Field11Visible := true;
        Field10Visible := true;
        Field9Visible := true;
        Field8Visible := true;
        Field7Visible := true;
        Field6Visible := true;
        Field5Visible := true;
        Field4Visible := true;
        Field3Visible := true;
        Field2Visible := true;
        Field1Visible := true;
    end;

    trigger OnOpenPage()
    begin
        MATRIX_CurrentNoOfMatrixColumn := 32;
    end;

    var
        MatrixRecords: array[32] of Record "FA Matrix Posting Type";
        FALedgerEntry: Record "FA Ledger Entry";
        DP_Book2: Record "FA Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        MatrixMgt: Codeunit "Matrix Management";
        RoundingFactor: Enum "Analysis Rounding Factor";
        MATRIX_CurrentNoOfMatrixColumn: Integer;
        MATRIX_CellData: array[32] of Decimal;
        MATRIX_CaptionSet: array[32] of Text[80];
        DateFilter: Text;
        RoundingFactorFormatString: Text;
        Field1Visible: Boolean;
        Field2Visible: Boolean;
        Field3Visible: Boolean;
        Field4Visible: Boolean;
        Field5Visible: Boolean;
        Field6Visible: Boolean;
        Field7Visible: Boolean;
        Field8Visible: Boolean;
        Field9Visible: Boolean;
        Field10Visible: Boolean;
        Field11Visible: Boolean;
        Field12Visible: Boolean;
        Field13Visible: Boolean;
        Field14Visible: Boolean;
        Field15Visible: Boolean;
        Field16Visible: Boolean;
        Field17Visible: Boolean;
        Field18Visible: Boolean;
        Field19Visible: Boolean;
        Field20Visible: Boolean;
        Field21Visible: Boolean;
        Field22Visible: Boolean;
        Field23Visible: Boolean;
        Field24Visible: Boolean;
        Field25Visible: Boolean;
        Field26Visible: Boolean;
        Field27Visible: Boolean;
        Field28Visible: Boolean;
        Field29Visible: Boolean;
        Field30Visible: Boolean;
        Field31Visible: Boolean;
        Field32Visible: Boolean;

    procedure LoadMatrix(NewMatrixColumns: array[32] of Text[80]; var NewMatrixRecords: array[32] of Record "FA Matrix Posting Type"; CurrentNoOfMatrixColumns: Integer; NewDateFilter: Text; NewRoundingFactor: Enum "Analysis Rounding Factor")
    var
        i: Integer;
    begin
        for i := 1 to CurrentNoOfMatrixColumns do begin
            MATRIX_CaptionSet[i] := NewMatrixColumns[i];
            MatrixRecords[i] := NewMatrixRecords[i];
        end;
        MATRIX_CurrentNoOfMatrixColumn := CurrentNoOfMatrixColumns;
        DateFilter := NewDateFilter;
        RoundingFactor := NewRoundingFactor;
        RoundingFactorFormatString := MatrixMgt.FormatRoundingFactor(RoundingFactor, false);
    end;

    local procedure MATRIX_OnDrillDown(MATRIX_ColumnOrdinal: Integer)
    begin
        DP_Book2.SetRange("FA No.", Rec."FA No.");
        DP_Book2.SetRange("Depreciation Book Code", Rec."Depreciation Book Code");

        if DP_Book2.FindFirst() then
            FALedgerEntry.SetRange("Depreciation Book Code", DP_Book2."Depreciation Book Code")
        else
            FALedgerEntry.SetRange("Depreciation Book Code");
        FALedgerEntry.SetFilter("FA Posting Date", DateFilter);
        FALedgerEntry.SetRange("FA No.", Rec."FA No.");
        OnBeforeMATRIX_OnDrillDown(FALedgerEntry);

        case MatrixRecords[MATRIX_ColumnOrdinal]."Entry No." of
            1:// 'Book Value'
                begin
                    FALedgerEntry.SetRange("Part of Book Value", true);
                    PAGE.Run(0, FALedgerEntry);
                end;
            2:// 'Acquisition Cost'
                begin
                    FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Acquisition Cost");
                    PAGE.Run(0, FALedgerEntry);
                end;
            3:// 'Depreciation'
                begin
                    FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Depreciation);
                    PAGE.Run(0, FALedgerEntry);
                end;
            4:// 'Write-Down'
                begin
                    FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Write-Down");
                    PAGE.Run(0, FALedgerEntry);
                end;
            5:// 'Appreciation'
                begin
                    FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Appreciation);
                    PAGE.Run(0, FALedgerEntry);
                end;
            6:// 'Custom 1'
                begin
                    FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Custom 1");
                    PAGE.Run(0, FALedgerEntry);
                end;
            7:// 'Custom 2'
                begin
                    FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Custom 2");
                    PAGE.Run(0, FALedgerEntry);
                end;
            8:// 'Proceeds on Disposal'
                begin
                    FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Proceeds on Disposal");
                    PAGE.Run(0, FALedgerEntry);
                end;
            9:// 'Gain/Loss'
                begin
                    FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Gain/Loss");
                    PAGE.Run(0, FALedgerEntry);
                end;
            10:// 'Depreciable Basis'
                begin
                    FALedgerEntry.SetRange("Part of Depreciable Basis", true);
                    PAGE.Run(0, FALedgerEntry);
                end;
            11:// 'Salvage Value'
                begin
                    FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Salvage Value");
                    PAGE.Run(0, FALedgerEntry);
                end;
            else
                OnMATRIX_OnDrillDownOnCaseElse(MATRIX_ColumnOrdinal, FALedgerEntry);
        end;
    end;

    local procedure MATRIX_OnAfterGetRecord(MATRIX_ColumnOrdinal: Integer)
    begin
        FADeprBook.SetFilter("FA Posting Date Filter", DateFilter);
        FADeprBook.SetRange("FA No.", Rec."FA No.");
        FADeprBook.SetRange("Depreciation Book Code", Rec."Depreciation Book Code");
        OnBeforeMATRIX_OnAfterGetRecord(FADeprBook);
        case MatrixRecords[MATRIX_ColumnOrdinal]."Entry No." of
            1:// 'Book Value'
                begin
                    if FADeprBook.FindFirst() then
                        FADeprBook.CalcBookValue();
                    MATRIX_CellData[MATRIX_ColumnOrdinal] := MatrixMgt.RoundAmount(FADeprBook."Book Value", RoundingFactor);
                end;
            10:// 'Depreciable Basis'
                begin
                    if FADeprBook.FindFirst() then
                        FADeprBook.CalcFields("Depreciable Basis");
                    MATRIX_CellData[MATRIX_ColumnOrdinal] := MatrixMgt.RoundAmount(FADeprBook."Depreciable Basis", RoundingFactor);
                end;
            2:// 'Acquisition Cost'
                begin
                    if FADeprBook.FindFirst() then
                        FADeprBook.CalcFields("Acquisition Cost");
                    MATRIX_CellData[MATRIX_ColumnOrdinal] := MatrixMgt.RoundAmount(FADeprBook."Acquisition Cost", RoundingFactor);
                end;
            3:// 'Depreciation'
                begin
                    if FADeprBook.FindFirst() then
                        FADeprBook.CalcFields(Depreciation);
                    MATRIX_CellData[MATRIX_ColumnOrdinal] := MatrixMgt.RoundAmount(FADeprBook.Depreciation, RoundingFactor);
                end;
            4:// 'Write-Down'
                begin
                    if FADeprBook.FindFirst() then
                        FADeprBook.CalcFields("Write-Down");
                    MATRIX_CellData[MATRIX_ColumnOrdinal] := MatrixMgt.RoundAmount(FADeprBook."Write-Down", RoundingFactor);
                end;
            5:// 'Appreciation'
                begin
                    if FADeprBook.FindFirst() then
                        FADeprBook.CalcFields(Appreciation);
                    MATRIX_CellData[MATRIX_ColumnOrdinal] := MatrixMgt.RoundAmount(FADeprBook.Appreciation, RoundingFactor);
                end;
            6:// 'Custom 1'
                begin
                    if FADeprBook.FindFirst() then
                        FADeprBook.CalcFields("Custom 1");
                    MATRIX_CellData[MATRIX_ColumnOrdinal] := MatrixMgt.RoundAmount(FADeprBook."Custom 1", RoundingFactor);
                end;
            7:// 'Custom 2'
                begin
                    if FADeprBook.FindFirst() then
                        FADeprBook.CalcFields("Custom 2");
                    MATRIX_CellData[MATRIX_ColumnOrdinal] := MatrixMgt.RoundAmount(FADeprBook."Custom 2", RoundingFactor);
                end;
            9:// 'Gain/Loss'
                begin
                    if FADeprBook.FindFirst() then
                        FADeprBook.CalcFields("Gain/Loss");
                    MATRIX_CellData[MATRIX_ColumnOrdinal] := MatrixMgt.RoundAmount(FADeprBook."Gain/Loss", RoundingFactor);
                end;
            8:// 'Proceeds on Disposal'
                begin
                    if FADeprBook.FindFirst() then
                        FADeprBook.CalcFields("Proceeds on Disposal");
                    MATRIX_CellData[MATRIX_ColumnOrdinal] := MatrixMgt.RoundAmount(FADeprBook."Proceeds on Disposal", RoundingFactor);
                end;
            11:// 'Salvage Value'
                begin
                    if FADeprBook.FindFirst() then
                        FADeprBook.CalcFields("Salvage Value");
                    MATRIX_CellData[MATRIX_ColumnOrdinal] := MatrixMgt.RoundAmount(FADeprBook."Salvage Value", RoundingFactor);
                end;
        end;

        SetVisible();

        OnAfterMATRIX_OnAfterGetRecord(MATRIX_CellData, MATRIX_ColumnOrdinal, RoundingFactor, MatrixRecords, FADeprBook);
    end;

    procedure SetVisible()
    begin
        Field1Visible := MATRIX_CaptionSet[1] <> '';
        Field2Visible := MATRIX_CaptionSet[2] <> '';
        Field3Visible := MATRIX_CaptionSet[3] <> '';
        Field4Visible := MATRIX_CaptionSet[4] <> '';
        Field5Visible := MATRIX_CaptionSet[5] <> '';
        Field6Visible := MATRIX_CaptionSet[6] <> '';
        Field7Visible := MATRIX_CaptionSet[7] <> '';
        Field8Visible := MATRIX_CaptionSet[8] <> '';
        Field9Visible := MATRIX_CaptionSet[9] <> '';
        Field10Visible := MATRIX_CaptionSet[10] <> '';
        Field11Visible := MATRIX_CaptionSet[11] <> '';
        Field12Visible := MATRIX_CaptionSet[12] <> '';
        Field13Visible := MATRIX_CaptionSet[13] <> '';
        Field14Visible := MATRIX_CaptionSet[14] <> '';
        Field15Visible := MATRIX_CaptionSet[15] <> '';
        Field16Visible := MATRIX_CaptionSet[16] <> '';
        Field17Visible := MATRIX_CaptionSet[17] <> '';
        Field18Visible := MATRIX_CaptionSet[18] <> '';
        Field19Visible := MATRIX_CaptionSet[19] <> '';
        Field20Visible := MATRIX_CaptionSet[20] <> '';
        Field21Visible := MATRIX_CaptionSet[21] <> '';
        Field22Visible := MATRIX_CaptionSet[22] <> '';
        Field23Visible := MATRIX_CaptionSet[23] <> '';
        Field24Visible := MATRIX_CaptionSet[24] <> '';
        Field25Visible := MATRIX_CaptionSet[25] <> '';
        Field26Visible := MATRIX_CaptionSet[26] <> '';
        Field27Visible := MATRIX_CaptionSet[27] <> '';
        Field28Visible := MATRIX_CaptionSet[28] <> '';
        Field29Visible := MATRIX_CaptionSet[29] <> '';
        Field30Visible := MATRIX_CaptionSet[30] <> '';
        Field31Visible := MATRIX_CaptionSet[31] <> '';
        Field32Visible := MATRIX_CaptionSet[32] <> '';
    end;

    local procedure FormatStr(): Text
    begin
        exit(RoundingFactorFormatString);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMATRIX_OnAfterGetRecord(var MATRIX_CellData: array[32] of Decimal; MATRIX_ColumnOrdinal: Integer; RoundingFactor: Enum "Analysis Rounding Factor"; MatrixRecords: array[32] of Record "FA Matrix Posting Type"; var FADepreciationBook: Record "FA Depreciation Book")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMATRIX_OnAfterGetRecord(var FADepreciationBook: Record "FA Depreciation Book")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMATRIX_OnDrillDown(var FALedgerEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMATRIX_OnDrillDownOnCaseElse(MATRIX_ColumnOrdinal: Integer; var FALedgerEntry: Record "FA Ledger Entry")
    begin
    end;
}
