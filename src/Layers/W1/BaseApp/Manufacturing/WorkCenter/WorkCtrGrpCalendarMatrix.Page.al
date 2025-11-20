// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.WorkCenter;

using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Setup;
using System.Utilities;

page 9295 "Work Ctr. Grp. Calendar Matrix"
{
    Caption = 'Work Ctr. Grp. Calendar Matrix';
    DataCaptionExpression = '';
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Work Center Group";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the code for the work center group.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a name for the work center group.';
                }
                field(Field1; MATRIX_CellData[1])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[1];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(1);
                    end;
                }
                field(Field2; MATRIX_CellData[2])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[2];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(2);
                    end;
                }
                field(Field3; MATRIX_CellData[3])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[3];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(3);
                    end;
                }
                field(Field4; MATRIX_CellData[4])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[4];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(4);
                    end;
                }
                field(Field5; MATRIX_CellData[5])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[5];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(5);
                    end;
                }
                field(Field6; MATRIX_CellData[6])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[6];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(6);
                    end;
                }
                field(Field7; MATRIX_CellData[7])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[7];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(7);
                    end;
                }
                field(Field8; MATRIX_CellData[8])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[8];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(8);
                    end;
                }
                field(Field9; MATRIX_CellData[9])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[9];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(9);
                    end;
                }
                field(Field10; MATRIX_CellData[10])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[10];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(10);
                    end;
                }
                field(Field11; MATRIX_CellData[11])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[11];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(11);
                    end;
                }
                field(Field12; MATRIX_CellData[12])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[12];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(12);
                    end;
                }
                field(Field13; MATRIX_CellData[13])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[13];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(13);
                    end;
                }
                field(Field14; MATRIX_CellData[14])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[14];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(14);
                    end;
                }
                field(Field15; MATRIX_CellData[15])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[15];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(15);
                    end;
                }
                field(Field16; MATRIX_CellData[16])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[16];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(16);
                    end;
                }
                field(Field17; MATRIX_CellData[17])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[17];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(17);
                    end;
                }
                field(Field18; MATRIX_CellData[18])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[18];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(18);
                    end;
                }
                field(Field19; MATRIX_CellData[19])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[19];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(19);
                    end;
                }
                field(Field20; MATRIX_CellData[20])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[20];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(20);
                    end;
                }
                field(Field21; MATRIX_CellData[21])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[21];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(21);
                    end;
                }
                field(Field22; MATRIX_CellData[22])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[22];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(22);
                    end;
                }
                field(Field23; MATRIX_CellData[23])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[23];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(23);
                    end;
                }
                field(Field24; MATRIX_CellData[24])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[24];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(24);
                    end;
                }
                field(Field25; MATRIX_CellData[25])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[25];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(25);
                    end;
                }
                field(Field26; MATRIX_CellData[26])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[26];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(26);
                    end;
                }
                field(Field27; MATRIX_CellData[27])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[27];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(27);
                    end;
                }
                field(Field28; MATRIX_CellData[28])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[28];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(28);
                    end;
                }
                field(Field29; MATRIX_CellData[29])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[29];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(29);
                    end;
                }
                field(Field30; MATRIX_CellData[30])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[30];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(30);
                    end;
                }
                field(Field31; MATRIX_CellData[31])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[31];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(31);
                    end;
                }
                field(Field32; MATRIX_CellData[32])
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[32];

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

    trigger OnOpenPage()
    begin
        MATRIX_CurrentNoOfMatrixColumn := ArrayLen(MATRIX_CaptionSet);
        MfgSetup.Get();
        MfgSetup.TestField("Show Capacity In");
    end;

    var
        MfgSetup: Record "Manufacturing Setup";
        MatrixRecords: array[32] of Record Date;
        MATRIX_CurrentNoOfMatrixColumn: Integer;
        MATRIX_CellData: array[32] of Decimal;
        MATRIX_CaptionSet: array[32] of Text[80];
        CapacityUoM: Code[10];

    local procedure SetDateFilter(MATRIX_ColumnOrdinal: Integer)
    begin
        if MatrixRecords[MATRIX_ColumnOrdinal]."Period Start" = MatrixRecords[MATRIX_ColumnOrdinal]."Period End" then
            Rec.SetRange("Date Filter", MatrixRecords[MATRIX_ColumnOrdinal]."Period Start")
        else
            Rec.SetRange("Date Filter", MatrixRecords[MATRIX_ColumnOrdinal]."Period Start", MatrixRecords[MATRIX_ColumnOrdinal]."Period End")
    end;

    procedure Load(MatrixColumns1: array[32] of Text[1024]; var MatrixRecords1: array[32] of Record Date; CurrentNoOfMatrixColumns: Integer; SetCapacityUoM: Code[10])
    begin
        CopyArray(MATRIX_CaptionSet, MatrixColumns1, 1);
        CopyArray(MatrixRecords, MatrixRecords1, 1);
        MATRIX_CurrentNoOfMatrixColumn := CurrentNoOfMatrixColumns;
        CapacityUoM := SetCapacityUoM;
    end;

    local procedure MATRIX_OnDrillDown(MATRIX_ColumnOrdinal: Integer)
    var
        CalendarEntry: Record "Calendar Entry";
    begin
        CalendarEntry.SetRange("Capacity Type", CalendarEntry."Capacity Type"::"Work Center");
        CalendarEntry.SetRange("Work Center Group Code", Rec.Code);

        if MatrixRecords[MATRIX_ColumnOrdinal]."Period Start" = MatrixRecords[MATRIX_ColumnOrdinal]."Period End" then
            CalendarEntry.SetRange(Date, MatrixRecords[MATRIX_ColumnOrdinal]."Period Start")
        else
            CalendarEntry.SetRange(Date,
              MatrixRecords[MATRIX_ColumnOrdinal]."Period Start", MatrixRecords[MATRIX_ColumnOrdinal]."Period End");

        PAGE.RunModal(PAGE::"Calendar Entries", CalendarEntry);
    end;

    local procedure MATRIX_OnAfterGetRecord(MATRIX_ColumnOrdinal: Integer)
    begin
        SetDateFilter(MATRIX_ColumnOrdinal);
        Rec."Capacity (Effective)" := CalculateCapacity();
        MATRIX_CellData[MATRIX_ColumnOrdinal] := Rec."Capacity (Effective)";
    end;

    local procedure CalculateCapacity(): Decimal
    var
        WorkCenter: Record "Work Center";
        CalendarMgt: Codeunit "Shop Calendar Management";
        Capacity: Decimal;
    begin
        if CapacityUoM = '' then
            CapacityUoM := MfgSetup."Show Capacity In";
        WorkCenter.SetCurrentKey("Work Center Group Code");
        WorkCenter.SetRange("Work Center Group Code", Rec.Code);
        if WorkCenter.FindSet() then
            repeat
                if Rec.GetFilter("Work Shift Filter") <> '' then
                    Rec.CopyFilter("Work Shift Filter", WorkCenter."Work Shift Filter");
                Rec.CopyFilter("Date Filter", WorkCenter."Date Filter");
                WorkCenter.CalcFields("Capacity (Effective)");
                Capacity :=
                  Capacity +
                  WorkCenter."Capacity (Effective)" *
                  CalendarMgt.TimeFactor(WorkCenter."Unit of Measure Code") /
                  CalendarMgt.TimeFactor(CapacityUoM);
            until WorkCenter.Next() = 0;

        exit(Capacity);
    end;
}

