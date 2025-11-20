// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Analysis;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using Microsoft.Service.Contract;
using System.Utilities;

page 9267 "Contr. G/Loss (Contr.) Matrix"
{
    // ContractGainLossEntry.Reset();
    // ContractGainLossEntry.SETCURRENTKEY("Contract Reason Code","Change Date");
    // ContractGainLossEntry.SETRANGE("Contract Reason Code",CurrForm.Matrix.MatrixRec.Code);
    // IF AmountType = AmountType::"Net Change" THEN
    //   ContractGainLossEntry.SETRANGE("Change Date","Period Start","Period End")
    // else
    //   ContractGainLossEntry.SETRANGE("Change Date",0D,"Period End");
    // 
    // PAGE.RUN(0,ContractGainLossEntry);

    Caption = 'Contract Gain/Loss (Contract) Matrix';
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = Date;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Period Start"; Rec."Period Start")
                {
                    ApplicationArea = Service;
                    Caption = 'Period Start';
                    ToolTip = 'Specifies the starting date of the period that you want to view.';
                }
                field("Period Name"; Rec."Period Name")
                {
                    ApplicationArea = Service;
                    Caption = 'Period Name';
                    ToolTip = 'Specifies the name of the period shown in the line.';
                }
                field(TotalGainLoss; TotalGainLoss)
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    Caption = 'Total Movement';
                    ToolTip = 'Specifies the total change in annual amount on the service contract.';

                    trigger OnDrillDown()
                    begin
                        Clear(ContractGainLossEntry);
                        ContractGainLossEntry.SetCurrentKey("Reason Code", "Change Date");
                        if ContractFilter <> '' then
                            ContractGainLossEntry.SetRange("Contract No.", ContractFilter);
                        if AmountType = AmountType::"Net Change" then
                            ContractGainLossEntry.SetRange("Change Date", Rec."Period Start", Rec."Period End")
                        else
                            ContractGainLossEntry.SetRange("Change Date", 0D, Rec."Period End");
                        PAGE.Run(0, ContractGainLossEntry);
                    end;
                }
                field(Field1; MATRIX_CellData[1])
                {
                    ApplicationArea = Service;
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
                    ApplicationArea = Service;
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
                    ApplicationArea = Service;
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
                    ApplicationArea = Service;
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
                    ApplicationArea = Service;
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
                    ApplicationArea = Service;
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
                    ApplicationArea = Service;
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
                    ApplicationArea = Service;
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
                    ApplicationArea = Service;
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
                    ApplicationArea = Service;
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
                    ApplicationArea = Service;
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
                    ApplicationArea = Service;
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
                    ApplicationArea = Service;
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
                    ApplicationArea = Service;
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
                    ApplicationArea = Service;
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
                    ApplicationArea = Service;
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
                    ApplicationArea = Service;
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
                    ApplicationArea = Service;
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
                    ApplicationArea = Service;
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
                    ApplicationArea = Service;
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
                    ApplicationArea = Service;
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
                    ApplicationArea = Service;
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
                    ApplicationArea = Service;
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
                    ApplicationArea = Service;
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
                    ApplicationArea = Service;
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
                    ApplicationArea = Service;
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
                    ApplicationArea = Service;
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
                    ApplicationArea = Service;
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
                    ApplicationArea = Service;
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
                    ApplicationArea = Service;
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
                    ApplicationArea = Service;
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
                    ApplicationArea = Service;
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
    }

    trigger OnAfterGetCurrRecord()
    begin
        SetDateFilter();
        CalculateTotals();
    end;

    trigger OnAfterGetRecord()
    var
        MATRIX_CurrentColumnOrdinal: Integer;
    begin
        SetDateFilter();
        CalculateTotals();
        MATRIX_CurrentColumnOrdinal := 0;
        while MATRIX_CurrentColumnOrdinal < CurrentNoOfMatrixColumn do begin
            MATRIX_CurrentColumnOrdinal := MATRIX_CurrentColumnOrdinal + 1;
            MATRIX_OnAfterGetRecord(MATRIX_CurrentColumnOrdinal);
        end;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(PeriodPageMgt.FindDate(Which, Rec, PeriodType));
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

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(PeriodPageMgt.NextDate(Steps, Rec, PeriodType));
    end;

    trigger OnOpenPage()
    begin
        StartFilter := Format(PeriodStart) + '..';
        Rec.SetFilter("Period Start", StartFilter);
        CurrentNoOfMatrixColumn := 32;
    end;

    var
        MatrixRecords: array[32] of Record "Service Contract Header";
        ServiceContract: Record "Service Contract Header";
        ContractGainLossEntry: Record "Contract Gain/Loss Entry";
        PeriodPageMgt: Codeunit PeriodPageManagement;
        AmountType: Enum "Analysis Amount Type";
        PeriodType: Enum "Analysis Period Type";
        ContractFilter: Text[250];
        TotalGainLoss: Decimal;
        PeriodStart: Date;
        MATRIX_CellData: array[32] of Text[80];
        MATRIX_CaptionSet: array[32] of Text[80];
        StartFilter: Text[1024];
        CurrentNoOfMatrixColumn: Integer;
#pragma warning disable AA0074
        Text000: Label '<Sign><Integer Thousand><Decimals,3>', Locked = true;
#pragma warning restore AA0074
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

    local procedure SetDateFilter()
    begin
        if AmountType = AmountType::"Net Change" then
            ServiceContract.SetRange("Date Filter", Rec."Period Start", Rec."Period End")
        else
            ServiceContract.SetRange("Date Filter", PeriodStart, Rec."Period End");
    end;

    local procedure CalculateMovement("Code": Code[10]): Decimal
    begin
        if ServiceContract.Get(ServiceContract."Contract Type"::Contract, Code) then begin
            SetDateFilter();
            ServiceContract.CalcFields("Contract Gain/Loss Amount");
            exit(ServiceContract."Contract Gain/Loss Amount");
        end;
        exit(0);
    end;

    local procedure CalculateTotals()
    begin
        ContractGainLossEntry.Reset();
        ContractGainLossEntry.SetCurrentKey("Contract No.", "Change Date");
        ContractGainLossEntry.SetFilter("Contract No.", ContractFilter);
        if AmountType = AmountType::"Net Change" then
            ContractGainLossEntry.SetRange("Change Date", Rec."Period Start", Rec."Period End")
        else
            ContractGainLossEntry.SetRange("Change Date", PeriodStart, Rec."Period End");
        ContractGainLossEntry.CalcSums(Amount);
        TotalGainLoss := ContractGainLossEntry.Amount;
    end;

    procedure LoadMatrix(NewMatrixColumns: array[32] of Text[1024]; var NewMatrixRecords: array[32] of Record "Service Contract Header"; NewCurrentNoOfMatrixColumns: Integer; NewAmountType: Enum "Analysis Amount Type"; NewPeriodType: Enum "Analysis Period Type"; NewContractFilter: Text[250]; NewPeriodStart: Date)
    begin
        CopyArray(MATRIX_CaptionSet, NewMatrixColumns, 1);
        CopyArray(MatrixRecords, NewMatrixRecords, 1);
        CurrentNoOfMatrixColumn := NewCurrentNoOfMatrixColumns;
        PeriodType := NewPeriodType;
        AmountType := NewAmountType;
        ContractFilter := NewContractFilter;
        PeriodStart := NewPeriodStart;
    end;

    local procedure MATRIX_OnDrillDown(MATRIX_ColumnOrdinal: Integer)
    begin
        ContractGainLossEntry.Reset();
        ContractGainLossEntry.SetCurrentKey("Contract No.", "Change Date");
        ContractGainLossEntry.SetRange("Contract No.", MatrixRecords[MATRIX_ColumnOrdinal]."Contract No.");
        if AmountType = AmountType::"Net Change" then
            ContractGainLossEntry.SetRange("Change Date", Rec."Period Start", Rec."Period End")
        else
            ContractGainLossEntry.SetRange("Change Date", 0D, Rec."Period End");

        PAGE.Run(0, ContractGainLossEntry);
    end;

    local procedure MATRIX_OnAfterGetRecord(Ordinal: Integer)
    var
        Amount: Decimal;
    begin
        Amount := CalculateMovement(MatrixRecords[Ordinal]."Contract No.");

        if Amount = 0 then
            MATRIX_CellData[Ordinal] := ''
        else
            MATRIX_CellData[Ordinal] := Format(Amount, 0, Text000);

        SetVisible();
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
}

