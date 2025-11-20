// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

page 9253 "Dim. Value Combinations Matrix"
{
    Caption = 'Dimension Value Combinations Matrix';
    DataCaptionExpression = '';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Dimension Value";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the dimension value.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies a descriptive name for the dimension value.';
                }
                field(Field1; MATRIX_CellData[1])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[1];
                    Visible = Field1Visible;

                    trigger OnAssistEdit()
                    begin
                        MatrixOnAssistEdit(1);
                    end;
                }
                field(Field2; MATRIX_CellData[2])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[2];
                    Visible = Field2Visible;

                    trigger OnAssistEdit()
                    begin
                        MatrixOnAssistEdit(2);
                    end;
                }
                field(Field3; MATRIX_CellData[3])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[3];
                    Visible = Field3Visible;

                    trigger OnAssistEdit()
                    begin
                        MatrixOnAssistEdit(3);
                    end;
                }
                field(Field4; MATRIX_CellData[4])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[4];
                    Visible = Field4Visible;

                    trigger OnAssistEdit()
                    begin
                        MatrixOnAssistEdit(4);
                    end;
                }
                field(Field5; MATRIX_CellData[5])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[5];
                    Visible = Field5Visible;

                    trigger OnAssistEdit()
                    begin
                        MatrixOnAssistEdit(5);
                    end;
                }
                field(Field6; MATRIX_CellData[6])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[6];
                    Visible = Field6Visible;

                    trigger OnAssistEdit()
                    begin
                        MatrixOnAssistEdit(6);
                    end;
                }
                field(Field7; MATRIX_CellData[7])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[7];
                    Visible = Field7Visible;

                    trigger OnAssistEdit()
                    begin
                        MatrixOnAssistEdit(7);
                    end;
                }
                field(Field8; MATRIX_CellData[8])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[8];
                    Visible = Field8Visible;

                    trigger OnAssistEdit()
                    begin
                        MatrixOnAssistEdit(8);
                    end;
                }
                field(Field9; MATRIX_CellData[9])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[9];
                    Visible = Field9Visible;

                    trigger OnAssistEdit()
                    begin
                        MatrixOnAssistEdit(9);
                    end;
                }
                field(Field10; MATRIX_CellData[10])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[10];
                    Visible = Field10Visible;

                    trigger OnAssistEdit()
                    begin
                        MatrixOnAssistEdit(10);
                    end;
                }
                field(Field11; MATRIX_CellData[11])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[11];
                    Visible = Field11Visible;

                    trigger OnAssistEdit()
                    begin
                        MatrixOnAssistEdit(11);
                    end;
                }
                field(Field12; MATRIX_CellData[12])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[12];
                    Visible = Field12Visible;

                    trigger OnAssistEdit()
                    begin
                        MatrixOnAssistEdit(12);
                    end;
                }
                field(Field13; MATRIX_CellData[13])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[13];
                    Visible = Field13Visible;

                    trigger OnAssistEdit()
                    begin
                        MatrixOnAssistEdit(13);
                    end;
                }
                field(Field14; MATRIX_CellData[14])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[14];
                    Visible = Field14Visible;

                    trigger OnAssistEdit()
                    begin
                        MatrixOnAssistEdit(14);
                    end;
                }
                field(Field15; MATRIX_CellData[15])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[15];
                    Visible = Field15Visible;

                    trigger OnAssistEdit()
                    begin
                        MatrixOnAssistEdit(15);
                    end;
                }
                field(Field16; MATRIX_CellData[16])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[16];
                    Visible = Field16Visible;

                    trigger OnAssistEdit()
                    begin
                        MatrixOnAssistEdit(16);
                    end;
                }
                field(Field17; MATRIX_CellData[17])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[17];
                    Visible = Field17Visible;

                    trigger OnAssistEdit()
                    begin
                        MatrixOnAssistEdit(17);
                    end;
                }
                field(Field18; MATRIX_CellData[18])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[18];
                    Visible = Field18Visible;

                    trigger OnAssistEdit()
                    begin
                        MatrixOnAssistEdit(18);
                    end;
                }
                field(Field19; MATRIX_CellData[19])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[19];
                    Visible = Field19Visible;

                    trigger OnAssistEdit()
                    begin
                        MatrixOnAssistEdit(19);
                    end;
                }
                field(Field20; MATRIX_CellData[20])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[20];
                    Visible = Field20Visible;

                    trigger OnAssistEdit()
                    begin
                        MatrixOnAssistEdit(20);
                    end;
                }
                field(Field21; MATRIX_CellData[21])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[21];
                    Visible = Field21Visible;

                    trigger OnAssistEdit()
                    begin
                        MatrixOnAssistEdit(21);
                    end;
                }
                field(Field22; MATRIX_CellData[22])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[22];
                    Visible = Field22Visible;

                    trigger OnAssistEdit()
                    begin
                        MatrixOnAssistEdit(22);
                    end;
                }
                field(Field23; MATRIX_CellData[23])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[23];
                    Visible = Field23Visible;

                    trigger OnAssistEdit()
                    begin
                        MatrixOnAssistEdit(23);
                    end;
                }
                field(Field24; MATRIX_CellData[24])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[24];
                    Visible = Field24Visible;

                    trigger OnAssistEdit()
                    begin
                        MatrixOnAssistEdit(24);
                    end;
                }
                field(Field25; MATRIX_CellData[25])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[25];
                    Visible = Field25Visible;

                    trigger OnAssistEdit()
                    begin
                        MatrixOnAssistEdit(25);
                    end;
                }
                field(Field26; MATRIX_CellData[26])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[26];
                    Visible = Field26Visible;

                    trigger OnAssistEdit()
                    begin
                        MatrixOnAssistEdit(26);
                    end;
                }
                field(Field27; MATRIX_CellData[27])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[27];
                    Visible = Field27Visible;

                    trigger OnAssistEdit()
                    begin
                        MatrixOnAssistEdit(27);
                    end;
                }
                field(Field28; MATRIX_CellData[28])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[28];
                    Visible = Field28Visible;

                    trigger OnAssistEdit()
                    begin
                        MatrixOnAssistEdit(28);
                    end;
                }
                field(Field29; MATRIX_CellData[29])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[29];
                    Visible = Field29Visible;

                    trigger OnAssistEdit()
                    begin
                        MatrixOnAssistEdit(29);
                    end;
                }
                field(Field30; MATRIX_CellData[30])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[30];
                    Visible = Field30Visible;

                    trigger OnAssistEdit()
                    begin
                        MatrixOnAssistEdit(30);
                    end;
                }
                field(Field31; MATRIX_CellData[31])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[31];
                    Visible = Field31Visible;

                    trigger OnAssistEdit()
                    begin
                        MatrixOnAssistEdit(31);
                    end;
                }
                field(Field32; MATRIX_CellData[32])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[32];
                    Visible = Field32Visible;

                    trigger OnAssistEdit()
                    begin
                        MatrixOnAssistEdit(32);
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
        SetColumnVisibility();
        Rec.FilterGroup(2);
        Rec.SetRange("Dimension Code", Row);
        Rec.FilterGroup(0);
        if SelectedDimValueCode <> '' then
            Rec.SetRange(Code, SelectedDimValueCode);
    end;

    var
        DimValueComb: Record "Dimension Value Combination";
        MatrixRecords: array[32] of Record "Dimension Value";
        CombRestriction: Option " ",Blocked;
        MATRIX_CurrentNoOfMatrixColumn: Integer;
        MATRIX_CellData: array[32] of Text[1024];
        MATRIX_ColumnCaption: array[32] of Text[1024];
#pragma warning disable AA0074
        Text000: Label 'Open,Blocked';
#pragma warning restore AA0074
        Row: Code[20];
        SelectedDimValueCode: Code[20];
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

    procedure SetSelectedDimValue(DimValueCode: Code[20])
    begin
        SelectedDimValueCode := DimValueCode;
    end;

    procedure Load(MatrixColumns1: array[32] of Text[1024]; var MatrixRecords1: array[32] of Record "Dimension Value"; _Row: Code[20]; CurrentNoOfMatrixColumn: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLoad(MatrixColumns1, MatrixRecords1, _Row, CurrentNoOfMatrixColumn, IsHandled);
        if IsHandled then
            exit;

        CopyArray(MATRIX_ColumnCaption, MatrixColumns1, 1);
        CopyArray(MatrixRecords, MatrixRecords1, 1);
        MATRIX_CurrentNoOfMatrixColumn := CurrentNoOfMatrixColumn;
        Row := _Row;

        SetColumnVisibility();
    end;

    local procedure MatrixOnAssistEdit(ColumnID: Integer)
    var
        DimLimVal: Integer;
        NewDimLimVal: Integer;
        Dim1Code: Code[20];
        Dim1ValueCode: Code[20];
        Dim2Code: Code[20];
        Dim2ValueCode: Code[20];
    begin
        if Rec."Dimension Code" > MatrixRecords[ColumnID]."Dimension Code" then begin
            Dim1Code := MatrixRecords[ColumnID]."Dimension Code";
            Dim1ValueCode := MatrixRecords[ColumnID].Code;
            Dim2Code := Rec."Dimension Code";
            Dim2ValueCode := Rec.Code;
        end else begin
            Dim1Code := Rec."Dimension Code";
            Dim1ValueCode := Rec.Code;
            Dim2Code := MatrixRecords[ColumnID]."Dimension Code";
            Dim2ValueCode := MatrixRecords[ColumnID].Code;
        end;
        CombRestriction := CombRestriction::Blocked;

        if not DimValueComb.Get(Dim1Code, Dim1ValueCode, Dim2Code, Dim2ValueCode) then
            if not DimValueComb.Get(Dim2Code, Dim2ValueCode, Dim1Code, Dim1ValueCode) then
                CombRestriction := CombRestriction::" ";

        DimLimVal := CombRestriction + 1;
        NewDimLimVal := StrMenu(Text000, DimLimVal);
        if DimLimVal <> NewDimLimVal then begin
            CombRestriction := NewDimLimVal - 1;
            ChangeCombRestriction(Dim1Code, Dim1ValueCode, Dim2Code, Dim2ValueCode);
        end;
    end;

    local procedure MATRIX_OnAfterGetRecord(ColumnID: Integer)
    begin
        ShowCombRestriction(ColumnID);
        if CombRestriction = CombRestriction::" " then
            MATRIX_CellData[ColumnID] := ''
        else
            MATRIX_CellData[ColumnID] := SelectStr(CombRestriction + 1, Text000);
    end;

    local procedure ShowCombRestriction(ColumnID: Integer)
    var
        Dim1Code: Code[20];
        Dim1ValueCode: Code[20];
        Dim2Code: Code[20];
        Dim2ValueCode: Code[20];
    begin
        if Rec."Dimension Code" > MatrixRecords[ColumnID]."Dimension Code" then begin
            Dim1Code := MatrixRecords[ColumnID]."Dimension Code";
            Dim1ValueCode := MatrixRecords[ColumnID].Code;
            Dim2Code := Rec."Dimension Code";
            Dim2ValueCode := Rec.Code;
        end else begin
            Dim1Code := Rec."Dimension Code";
            Dim1ValueCode := Rec.Code;
            Dim2Code := MatrixRecords[ColumnID]."Dimension Code";
            Dim2ValueCode := MatrixRecords[ColumnID].Code;
        end;

        if not DimValueComb.Get(Dim1Code, Dim1ValueCode, Dim2Code, Dim2ValueCode) then
            if not DimValueComb.Get(Dim2Code, Dim2ValueCode, Dim1Code, Dim1ValueCode) then begin
                DimValueComb.Init();
                DimValueComb."Dimension 1 Code" := Dim1Code;
                DimValueComb."Dimension 1 Value Code" := Dim1ValueCode;
                DimValueComb."Dimension 2 Code" := Dim2Code;
                DimValueComb."Dimension 2 Value Code" := Dim2ValueCode;
                CombRestriction := CombRestriction::" ";
                exit;
            end;

        CombRestriction := CombRestriction::Blocked;
    end;

    local procedure ChangeCombRestriction(Dim1Code: Code[20]; Dim1ValueCode: Code[20]; Dim2Code: Code[20]; Dim2ValueCode: Code[20])
    begin
        if not DimValueComb.Get(Dim1Code, Dim1ValueCode, Dim2Code, Dim2ValueCode) then
            if not DimValueComb.Get(Dim2Code, Dim2ValueCode, Dim1Code, Dim1ValueCode) then
                if CombRestriction = CombRestriction::Blocked then begin
                    DimValueComb."Dimension 1 Code" := Dim1Code;
                    DimValueComb."Dimension 2 Code" := Dim2Code;
                    DimValueComb."Dimension 1 Value Code" := Dim1ValueCode;
                    DimValueComb."Dimension 2 Value Code" := Dim2ValueCode;
                    DimValueComb.Insert(true);
                    exit;
                end;

        if CombRestriction = CombRestriction::" " then
            DimValueComb.Delete(true);
    end;

    procedure SetColumnVisibility()
    begin
        Field1Visible := MATRIX_CurrentNoOfMatrixColumn >= 1;
        Field2Visible := MATRIX_CurrentNoOfMatrixColumn >= 2;
        Field3Visible := MATRIX_CurrentNoOfMatrixColumn >= 3;
        Field4Visible := MATRIX_CurrentNoOfMatrixColumn >= 4;
        Field5Visible := MATRIX_CurrentNoOfMatrixColumn >= 5;
        Field6Visible := MATRIX_CurrentNoOfMatrixColumn >= 6;
        Field7Visible := MATRIX_CurrentNoOfMatrixColumn >= 7;
        Field8Visible := MATRIX_CurrentNoOfMatrixColumn >= 8;
        Field9Visible := MATRIX_CurrentNoOfMatrixColumn >= 9;
        Field10Visible := MATRIX_CurrentNoOfMatrixColumn >= 10;
        Field11Visible := MATRIX_CurrentNoOfMatrixColumn >= 11;
        Field12Visible := MATRIX_CurrentNoOfMatrixColumn >= 12;
        Field13Visible := MATRIX_CurrentNoOfMatrixColumn >= 13;
        Field14Visible := MATRIX_CurrentNoOfMatrixColumn >= 14;
        Field15Visible := MATRIX_CurrentNoOfMatrixColumn >= 15;
        Field16Visible := MATRIX_CurrentNoOfMatrixColumn >= 16;
        Field17Visible := MATRIX_CurrentNoOfMatrixColumn >= 17;
        Field18Visible := MATRIX_CurrentNoOfMatrixColumn >= 18;
        Field19Visible := MATRIX_CurrentNoOfMatrixColumn >= 19;
        Field20Visible := MATRIX_CurrentNoOfMatrixColumn >= 20;
        Field21Visible := MATRIX_CurrentNoOfMatrixColumn >= 21;
        Field22Visible := MATRIX_CurrentNoOfMatrixColumn >= 22;
        Field23Visible := MATRIX_CurrentNoOfMatrixColumn >= 23;
        Field24Visible := MATRIX_CurrentNoOfMatrixColumn >= 24;
        Field25Visible := MATRIX_CurrentNoOfMatrixColumn >= 25;
        Field26Visible := MATRIX_CurrentNoOfMatrixColumn >= 26;
        Field27Visible := MATRIX_CurrentNoOfMatrixColumn >= 27;
        Field28Visible := MATRIX_CurrentNoOfMatrixColumn >= 28;
        Field29Visible := MATRIX_CurrentNoOfMatrixColumn >= 29;
        Field30Visible := MATRIX_CurrentNoOfMatrixColumn >= 30;
        Field31Visible := MATRIX_CurrentNoOfMatrixColumn >= 31;
        Field32Visible := MATRIX_CurrentNoOfMatrixColumn >= 32;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLoad(MatrixColumns1: array[32] of Text[1024]; var MatrixRecords1: array[32] of Record "Dimension Value"; _Row: Code[20]; CurrentNoOfMatrixColumn: Integer; var IsHandled: Boolean)
    begin
    end;
}

