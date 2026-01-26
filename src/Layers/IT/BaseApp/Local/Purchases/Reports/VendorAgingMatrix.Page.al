// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Comment;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using System.Utilities;

page 35463 "Vendor Aging Matrix"
{
    Caption = 'Vendor Aging Matrix';
    DataCaptionExpression = '';
    Editable = false;
    PageType = List;
    SourceTable = Vendor;

    layout
    {
        area(content)
        {
            repeater(Control1130000)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor number.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name.';
                }
                field("Balance (LCY)"; Rec."Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the balance in the local currency.';
                }
                field(Field1; MATRIX_CellData[1])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[1];
                    ToolTip = 'Specifies the related data.';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(1);
                    end;
                }
                field(Field2; MATRIX_CellData[2])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[2];
                    ToolTip = 'Specifies the related data.';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(2);
                    end;
                }
                field(Field3; MATRIX_CellData[3])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[3];
                    ToolTip = 'Specifies the related data.';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(3);
                    end;
                }
                field(Field4; MATRIX_CellData[4])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[4];
                    ToolTip = 'Specifies the related data.';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(4);
                    end;
                }
                field(Field5; MATRIX_CellData[5])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[5];
                    ToolTip = 'Specifies the related data.';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(5);
                    end;
                }
                field(Field6; MATRIX_CellData[6])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[6];
                    ToolTip = 'Specifies the related data.';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(6);
                    end;
                }
                field(Field7; MATRIX_CellData[7])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[7];
                    ToolTip = 'Specifies the related data.';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(7);
                    end;
                }
                field(Field8; MATRIX_CellData[8])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[8];
                    ToolTip = 'Specifies the related data.';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(8);
                    end;
                }
                field(Field9; MATRIX_CellData[9])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[9];
                    ToolTip = 'Specifies the related data.';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(9);
                    end;
                }
                field(Field10; MATRIX_CellData[10])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[10];
                    ToolTip = 'Specifies the related data.';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(10);
                    end;
                }
                field(Field11; MATRIX_CellData[11])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[11];
                    ToolTip = 'Specifies the related data.';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(11);
                    end;
                }
                field(Field12; MATRIX_CellData[12])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[12];
                    ToolTip = 'Specifies the related data.';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(12);
                    end;
                }
                field(Field13; MATRIX_CellData[13])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[13];
                    ToolTip = 'Specifies the related data.';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(13);
                    end;
                }
                field(Field14; MATRIX_CellData[14])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[14];
                    ToolTip = 'Specifies the related data.';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(14);
                    end;
                }
                field(Field15; MATRIX_CellData[15])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[15];
                    ToolTip = 'Specifies the related data.';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(15);
                    end;
                }
                field(Field16; MATRIX_CellData[16])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[16];
                    ToolTip = 'Specifies the related data.';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(16);
                    end;
                }
                field(Field17; MATRIX_CellData[17])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[17];
                    ToolTip = 'Specifies the related data.';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(17);
                    end;
                }
                field(Field18; MATRIX_CellData[18])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[18];
                    ToolTip = 'Specifies the related data.';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(18);
                    end;
                }
                field(Field19; MATRIX_CellData[19])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[19];
                    ToolTip = 'Specifies the related data.';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(19);
                    end;
                }
                field(Field20; MATRIX_CellData[20])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[20];
                    ToolTip = 'Specifies the related data.';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(20);
                    end;
                }
                field(Field21; MATRIX_CellData[21])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[21];
                    ToolTip = 'Specifies the related data.';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(21);
                    end;
                }
                field(Field22; MATRIX_CellData[22])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[22];
                    ToolTip = 'Specifies the related data.';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(22);
                    end;
                }
                field(Field23; MATRIX_CellData[23])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[23];
                    ToolTip = 'Specifies the related data.';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(23);
                    end;
                }
                field(Field24; MATRIX_CellData[24])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[24];
                    ToolTip = 'Specifies the related data.';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(24);
                    end;
                }
                field(Field25; MATRIX_CellData[25])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[25];
                    ToolTip = 'Specifies the related data.';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(25);
                    end;
                }
                field(Field26; MATRIX_CellData[26])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[26];
                    ToolTip = 'Specifies the related data.';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(26);
                    end;
                }
                field(Field27; MATRIX_CellData[27])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[27];
                    ToolTip = 'Specifies the related data.';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(27);
                    end;
                }
                field(Field28; MATRIX_CellData[28])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[28];
                    ToolTip = 'Specifies the related data.';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(28);
                    end;
                }
                field(Field29; MATRIX_CellData[29])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[29];
                    ToolTip = 'Specifies the related data.';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(29);
                    end;
                }
                field(Field30; MATRIX_CellData[30])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[30];
                    ToolTip = 'Specifies the related data.';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(30);
                    end;
                }
                field(Field31; MATRIX_CellData[31])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[31];
                    ToolTip = 'Specifies the related data.';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(31);
                    end;
                }
                field(Field32; MATRIX_CellData[32])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[32];
                    ToolTip = 'Specifies the related data.';

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
            group("Ven&dor")
            {
                Caption = 'Ven&dor';
                Image = Vendor;
                action("Ledger E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger E&ntries';
                    RunObject = Page "Vendor Ledger Entries";
                    RunPageLink = "Vendor No." = field("No.");
                    RunPageView = sorting("Vendor No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the related ledger entries.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = const(Vendor),
                                  "No." = field("No.");
                    ToolTip = 'View or edit comments about the document.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = const(23),
                                  "No." = field("No.");
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View the related dimensions.';
                }
                action("Bank Accounts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Accounts';
                    Image = BankAccount;
                    RunObject = Page "Vendor Bank Account List";
                    RunPageLink = "Vendor No." = field("No.");
                    ToolTip = 'View the related bank accounts.';
                }
                action("Order &Addresses")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Order &Addresses';
                    Image = Addresses;
                    RunObject = Page "Order Address List";
                    RunPageLink = "Vendor No." = field("No.");
                    ToolTip = 'View the order addresses.';
                }
                action("C&ontact")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&ontact';
                    Image = ContactPerson;
                    ToolTip = 'View the related contact person.';

                    trigger OnAction()
                    begin
                        Rec.ShowContact();
                    end;
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
        MATRIXCellData1OnFormat(Format(MATRIX_CellData[1]));
        MATRIXCellData2OnFormat(Format(MATRIX_CellData[2]));
        MATRIXCellData3OnFormat(Format(MATRIX_CellData[3]));
        MATRIXCellData4OnFormat(Format(MATRIX_CellData[4]));
        MATRIXCellData5OnFormat(Format(MATRIX_CellData[5]));
        MATRIXCellData6OnFormat(Format(MATRIX_CellData[6]));
        MATRIXCellData7OnFormat(Format(MATRIX_CellData[7]));
        MATRIXCellData8OnFormat(Format(MATRIX_CellData[8]));
        MATRIXCellData9OnFormat(Format(MATRIX_CellData[9]));
        MATRIXCellData10OnFormat(Format(MATRIX_CellData[10]));
        MATRIXCellData11OnFormat(Format(MATRIX_CellData[11]));
        MATRIXCellData12OnFormat(Format(MATRIX_CellData[12]));
        MATRIXCellData13OnFormat(Format(MATRIX_CellData[13]));
        MATRIXCellData14OnFormat(Format(MATRIX_CellData[14]));
        MATRIXCellData15OnFormat(Format(MATRIX_CellData[15]));
        MATRIXCellData16OnFormat(Format(MATRIX_CellData[16]));
        MATRIXCellData17OnFormat(Format(MATRIX_CellData[17]));
        MATRIXCellData18OnFormat(Format(MATRIX_CellData[18]));
        MATRIXCellData19OnFormat(Format(MATRIX_CellData[19]));
        MATRIXCellData20OnFormat(Format(MATRIX_CellData[20]));
        MATRIXCellData21OnFormat(Format(MATRIX_CellData[21]));
        MATRIXCellData22OnFormat(Format(MATRIX_CellData[22]));
        MATRIXCellData23OnFormat(Format(MATRIX_CellData[23]));
        MATRIXCellData24OnFormat(Format(MATRIX_CellData[24]));
        MATRIXCellData25OnFormat(Format(MATRIX_CellData[25]));
        MATRIXCellData26OnFormat(Format(MATRIX_CellData[26]));
        MATRIXCellData27OnFormat(Format(MATRIX_CellData[27]));
        MATRIXCellData28OnFormat(Format(MATRIX_CellData[28]));
        MATRIXCellData29OnFormat(Format(MATRIX_CellData[29]));
        MATRIXCellData30OnFormat(Format(MATRIX_CellData[30]));
        MATRIXCellData31OnFormat(Format(MATRIX_CellData[31]));
        MATRIXCellData32OnFormat(Format(MATRIX_CellData[32]));
    end;

    trigger OnOpenPage()
    begin
        MATRIX_CurrentNoOfMatrixColumn := ArrayLen(MATRIX_CellData);
    end;

    var
        AmountType: Option "Period Balance","Balance at Date";
        RoundingFactor: Option "None","1","1000","1000000";
        MatrixRecords: array[32] of Record Date;
        MATRIX_CurrentNoOfMatrixColumn: Integer;
        MATRIX_CellData: array[32] of Decimal;
        MATRIX_CaptionSet: array[32] of Text[1024];
        GlobalDim1Filter: Text[1024];
        GlobalDim2Filter: Text[1024];

    local procedure SetDateFilter(MATRIX_ColumnOrdinal: Integer)
    begin
        if AmountType = AmountType::"Period Balance" then
            if MatrixRecords[MATRIX_ColumnOrdinal]."Period Start" = MatrixRecords[MATRIX_ColumnOrdinal]."Period End" then
                Rec.SetRange("Date Filter", MatrixRecords[MATRIX_ColumnOrdinal]."Period Start")
            else
                Rec.SetRange("Date Filter", MatrixRecords[MATRIX_ColumnOrdinal]."Period Start", MatrixRecords[MATRIX_ColumnOrdinal]."Period End")
        else
            Rec.SetRange("Date Filter", 0D, MatrixRecords[MATRIX_ColumnOrdinal]."Period End");
    end;

    local procedure FormatAmount(var Amount: Text[250])
    var
        Amount2: Decimal;
    begin
        if (Amount = '') or (RoundingFactor = RoundingFactor::None) then
            exit;
        Evaluate(Amount2, Amount);
        case RoundingFactor of
            RoundingFactor::"1":
                Amount2 := Round(Amount2, 1);
            RoundingFactor::"1000":
                Amount2 := Round(Amount2 / 1000, 0.1);
            RoundingFactor::"1000000":
                Amount2 := Round(Amount2 / 1000000, 0.1);
        end;
        if Amount2 = 0 then
            Amount := ''
        else
            case RoundingFactor of
                RoundingFactor::"1":
                    Amount := Format(Amount2);
                RoundingFactor::"1000", RoundingFactor::"1000000":
                    Amount := Format(Amount2, 0, '<Sign><Integer Thousand><Decimals,2>');
            end;
    end;

    [Scope('OnPrem')]
    procedure Load(MatrixColumns1: array[32] of Text[1024]; var MatrixRecords1: array[32] of Record Date; CurrentNoOfMatrixColumns: Integer; RoundingFactor2: Option "None","1","1000","1000000"; AmountType2: Option "Period Balance","Balance at Date"; GlobalDim1Filter2: Text[1024]; GlobalDim2Filter2: Text[1024])
    begin
        CopyArray(MATRIX_CaptionSet, MatrixColumns1, 1);
        CopyArray(MatrixRecords, MatrixRecords1, 1);
        MATRIX_CurrentNoOfMatrixColumn := CurrentNoOfMatrixColumns;
        RoundingFactor := RoundingFactor2;
        AmountType := AmountType2;
        GlobalDim1Filter := GlobalDim1Filter2;
        GlobalDim2Filter := GlobalDim2Filter2;
    end;

    local procedure MATRIX_OnDrillDown(MATRIX_ColumnOrdinal: Integer)
    var
        DetVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        SetDateFilter(MATRIX_ColumnOrdinal);
        DetVendLedgEntry.SetFilter("Vendor No.", '%1', Rec."No.");
        DetVendLedgEntry.SetFilter("Initial Entry Due Date", Rec.GetFilter("Date Filter"));
        DetVendLedgEntry.SetFilter("Initial Entry Global Dim. 1", GlobalDim1Filter);
        DetVendLedgEntry.SetFilter("Initial Entry Global Dim. 2", GlobalDim2Filter);
        PAGE.RunModal(0, DetVendLedgEntry, DetVendLedgEntry."Amount (LCY)");
    end;

    local procedure MATRIX_OnAfterGetRecord(MATRIX_ColumnOrdinal: Integer)
    var
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        SetDateFilter(MATRIX_ColumnOrdinal);
        DetailedVendLedgEntry.SetFilter("Vendor No.", '%1', Rec."No.");
        DetailedVendLedgEntry.SetFilter("Initial Entry Due Date", Rec.GetFilter("Date Filter"));
        DetailedVendLedgEntry.SetFilter("Initial Entry Global Dim. 1", GlobalDim1Filter);
        DetailedVendLedgEntry.SetFilter("Initial Entry Global Dim. 2", GlobalDim2Filter);
        DetailedVendLedgEntry.CalcSums("Amount (LCY)");
        MATRIX_CellData[MATRIX_ColumnOrdinal] := -DetailedVendLedgEntry."Amount (LCY)";
    end;

    local procedure MATRIXCellData1OnFormat(Text: Text[1024])
    begin
        FormatAmount(Text);
    end;

    local procedure MATRIXCellData2OnFormat(Text: Text[1024])
    begin
        FormatAmount(Text);
    end;

    local procedure MATRIXCellData3OnFormat(Text: Text[1024])
    begin
        FormatAmount(Text);
    end;

    local procedure MATRIXCellData4OnFormat(Text: Text[1024])
    begin
        FormatAmount(Text);
    end;

    local procedure MATRIXCellData5OnFormat(Text: Text[1024])
    begin
        FormatAmount(Text);
    end;

    local procedure MATRIXCellData6OnFormat(Text: Text[1024])
    begin
        FormatAmount(Text);
    end;

    local procedure MATRIXCellData7OnFormat(Text: Text[1024])
    begin
        FormatAmount(Text);
    end;

    local procedure MATRIXCellData8OnFormat(Text: Text[1024])
    begin
        FormatAmount(Text);
    end;

    local procedure MATRIXCellData9OnFormat(Text: Text[1024])
    begin
        FormatAmount(Text);
    end;

    local procedure MATRIXCellData10OnFormat(Text: Text[1024])
    begin
        FormatAmount(Text);
    end;

    local procedure MATRIXCellData11OnFormat(Text: Text[1024])
    begin
        FormatAmount(Text);
    end;

    local procedure MATRIXCellData12OnFormat(Text: Text[1024])
    begin
        FormatAmount(Text);
    end;

    local procedure MATRIXCellData13OnFormat(Text: Text[1024])
    begin
        FormatAmount(Text);
    end;

    local procedure MATRIXCellData14OnFormat(Text: Text[1024])
    begin
        FormatAmount(Text);
    end;

    local procedure MATRIXCellData15OnFormat(Text: Text[1024])
    begin
        FormatAmount(Text);
    end;

    local procedure MATRIXCellData16OnFormat(Text: Text[1024])
    begin
        FormatAmount(Text);
    end;

    local procedure MATRIXCellData17OnFormat(Text: Text[1024])
    begin
        FormatAmount(Text);
    end;

    local procedure MATRIXCellData18OnFormat(Text: Text[1024])
    begin
        FormatAmount(Text);
    end;

    local procedure MATRIXCellData19OnFormat(Text: Text[1024])
    begin
        FormatAmount(Text);
    end;

    local procedure MATRIXCellData20OnFormat(Text: Text[1024])
    begin
        FormatAmount(Text);
    end;

    local procedure MATRIXCellData21OnFormat(Text: Text[1024])
    begin
        FormatAmount(Text);
    end;

    local procedure MATRIXCellData22OnFormat(Text: Text[1024])
    begin
        FormatAmount(Text);
    end;

    local procedure MATRIXCellData23OnFormat(Text: Text[1024])
    begin
        FormatAmount(Text);
    end;

    local procedure MATRIXCellData24OnFormat(Text: Text[1024])
    begin
        FormatAmount(Text);
    end;

    local procedure MATRIXCellData25OnFormat(Text: Text[1024])
    begin
        FormatAmount(Text);
    end;

    local procedure MATRIXCellData26OnFormat(Text: Text[1024])
    begin
        FormatAmount(Text);
    end;

    local procedure MATRIXCellData27OnFormat(Text: Text[1024])
    begin
        FormatAmount(Text);
    end;

    local procedure MATRIXCellData28OnFormat(Text: Text[1024])
    begin
        FormatAmount(Text);
    end;

    local procedure MATRIXCellData29OnFormat(Text: Text[1024])
    begin
        FormatAmount(Text);
    end;

    local procedure MATRIXCellData30OnFormat(Text: Text[1024])
    begin
        FormatAmount(Text);
    end;

    local procedure MATRIXCellData31OnFormat(Text: Text[1024])
    begin
        FormatAmount(Text);
    end;

    local procedure MATRIXCellData32OnFormat(Text: Text[1024])
    begin
        FormatAmount(Text);
    end;
}

