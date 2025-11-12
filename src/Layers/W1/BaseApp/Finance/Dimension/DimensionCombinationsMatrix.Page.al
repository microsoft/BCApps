// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

page 9251 "Dimension Combinations Matrix"
{
    Caption = 'Dimension Combinations Matrix';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = Dimension;

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
                    ToolTip = 'Specifies the code for the dimension.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension code you enter in the Code field.';
                }
                field(Field1; MATRIX_CellData[1])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[1];
                    Visible = Field1Visible;

                    trigger OnAssistEdit()
                    begin
                        SetLimitations(1);
                    end;
                }
                field(Field2; MATRIX_CellData[2])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[2];
                    Visible = Field2Visible;

                    trigger OnAssistEdit()
                    begin
                        SetLimitations(2);
                    end;
                }
                field(Field3; MATRIX_CellData[3])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[3];
                    Visible = Field3Visible;

                    trigger OnAssistEdit()
                    begin
                        SetLimitations(3);
                    end;
                }
                field(Field4; MATRIX_CellData[4])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[4];
                    Visible = Field4Visible;

                    trigger OnAssistEdit()
                    begin
                        SetLimitations(4);
                    end;
                }
                field(Field5; MATRIX_CellData[5])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[5];
                    Visible = Field5Visible;

                    trigger OnAssistEdit()
                    begin
                        SetLimitations(5);
                    end;
                }
                field(Field6; MATRIX_CellData[6])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[6];
                    Visible = Field6Visible;

                    trigger OnAssistEdit()
                    begin
                        SetLimitations(6);
                    end;
                }
                field(Field7; MATRIX_CellData[7])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[7];
                    Visible = Field7Visible;

                    trigger OnAssistEdit()
                    begin
                        SetLimitations(7);
                    end;
                }
                field(Field8; MATRIX_CellData[8])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[8];
                    Visible = Field8Visible;

                    trigger OnAssistEdit()
                    begin
                        SetLimitations(8);
                    end;
                }
                field(Field9; MATRIX_CellData[9])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[9];
                    Visible = Field9Visible;

                    trigger OnAssistEdit()
                    begin
                        SetLimitations(9);
                    end;
                }
                field(Field10; MATRIX_CellData[10])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[10];
                    Visible = Field10Visible;

                    trigger OnAssistEdit()
                    begin
                        SetLimitations(10);
                    end;
                }
                field(Field11; MATRIX_CellData[11])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[11];
                    Visible = Field11Visible;

                    trigger OnAssistEdit()
                    begin
                        SetLimitations(11);
                    end;
                }
                field(Field12; MATRIX_CellData[12])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[12];
                    Visible = Field12Visible;

                    trigger OnAssistEdit()
                    begin
                        SetLimitations(12);
                    end;
                }
                field(Field13; MATRIX_CellData[13])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[13];
                    Visible = Field13Visible;

                    trigger OnAssistEdit()
                    begin
                        SetLimitations(13);
                    end;
                }
                field(Field14; MATRIX_CellData[14])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[14];
                    Visible = Field14Visible;

                    trigger OnAssistEdit()
                    begin
                        SetLimitations(14);
                    end;
                }
                field(Field15; MATRIX_CellData[15])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[15];
                    Visible = Field15Visible;

                    trigger OnAssistEdit()
                    begin
                        SetLimitations(15);
                    end;
                }
                field(Field16; MATRIX_CellData[16])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[16];
                    Visible = Field16Visible;

                    trigger OnAssistEdit()
                    begin
                        SetLimitations(16);
                    end;
                }
                field(Field17; MATRIX_CellData[17])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[17];
                    Visible = Field17Visible;

                    trigger OnAssistEdit()
                    begin
                        SetLimitations(17);
                    end;
                }
                field(Field18; MATRIX_CellData[18])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[18];
                    Visible = Field18Visible;

                    trigger OnAssistEdit()
                    begin
                        SetLimitations(18);
                    end;
                }
                field(Field19; MATRIX_CellData[19])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[19];
                    Visible = Field19Visible;

                    trigger OnAssistEdit()
                    begin
                        SetLimitations(19);
                    end;
                }
                field(Field20; MATRIX_CellData[20])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[20];
                    Visible = Field20Visible;

                    trigger OnAssistEdit()
                    begin
                        SetLimitations(20);
                    end;
                }
                field(Field21; MATRIX_CellData[21])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[21];
                    Visible = Field21Visible;

                    trigger OnAssistEdit()
                    begin
                        SetLimitations(21);
                    end;
                }
                field(Field22; MATRIX_CellData[22])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[22];
                    Visible = Field22Visible;

                    trigger OnAssistEdit()
                    begin
                        SetLimitations(22);
                    end;
                }
                field(Field23; MATRIX_CellData[23])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[23];
                    Visible = Field23Visible;

                    trigger OnAssistEdit()
                    begin
                        SetLimitations(23);
                    end;
                }
                field(Field24; MATRIX_CellData[24])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[24];
                    Visible = Field24Visible;

                    trigger OnAssistEdit()
                    begin
                        SetLimitations(24);
                    end;
                }
                field(Field25; MATRIX_CellData[25])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[25];
                    Visible = Field25Visible;

                    trigger OnAssistEdit()
                    begin
                        SetLimitations(25);
                    end;
                }
                field(Field26; MATRIX_CellData[26])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[26];
                    Visible = Field26Visible;

                    trigger OnAssistEdit()
                    begin
                        SetLimitations(26);
                    end;
                }
                field(Field27; MATRIX_CellData[27])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[27];
                    Visible = Field27Visible;

                    trigger OnAssistEdit()
                    begin
                        SetLimitations(27);
                    end;
                }
                field(Field28; MATRIX_CellData[28])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[28];
                    Visible = Field28Visible;

                    trigger OnAssistEdit()
                    begin
                        SetLimitations(28);
                    end;
                }
                field(Field29; MATRIX_CellData[29])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[29];
                    Visible = Field29Visible;

                    trigger OnAssistEdit()
                    begin
                        SetLimitations(29);
                    end;
                }
                field(Field30; MATRIX_CellData[30])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[30];
                    Visible = Field30Visible;

                    trigger OnAssistEdit()
                    begin
                        SetLimitations(30);
                    end;
                }
                field(Field31; MATRIX_CellData[31])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[31];
                    Visible = Field31Visible;

                    trigger OnAssistEdit()
                    begin
                        SetLimitations(31);
                    end;
                }
                field(Field32; MATRIX_CellData[32])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[32];
                    Visible = Field32Visible;

                    trigger OnAssistEdit()
                    begin
                        SetLimitations(32);
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
        MATRIX_Steps: Integer;
    begin
        Rec.Name := Rec.GetMLName(GlobalLanguage);
        MATRIX_CurrentColumnOrdinal := 0;
        if MATRIX_OnFindRecord('=><') then begin
            MATRIX_CurrentColumnOrdinal := 1;
            repeat
                MATRIX_ColumnOrdinal := MATRIX_CurrentColumnOrdinal;
                MATRIX_OnAfterGetRecord();
                MATRIX_Steps := MATRIX_OnNextRecord(1);
                MATRIX_CurrentColumnOrdinal := MATRIX_CurrentColumnOrdinal + MATRIX_Steps;
            until (MATRIX_CurrentColumnOrdinal - MATRIX_Steps = MATRIX_NoOfMatrixColumns) or (MATRIX_Steps = 0);
            if MATRIX_CurrentColumnOrdinal <> 1 then
                MATRIX_OnNextRecord(1 - MATRIX_CurrentColumnOrdinal);
        end
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
        MATRIX_NoOfMatrixColumns := ArrayLen(MATRIX_CellData);
        if SelectedDimCode <> '' then
            Rec.SetRange(Code, SelectedDimCode);
    end;

    var
        DimComb: Record "Dimension Combination";
        MatrixRecord: Record Dimension;
        MatrixRecords: array[32] of Record Dimension;
        DimensionValueCombinations: Page "MyDim Value Combinations";
        CombRestriction: Option " ",Limited,Blocked;
        ShowColumnName: Boolean;
        MATRIX_ColumnOrdinal: Integer;
        MATRIX_NoOfMatrixColumns: Integer;
        MATRIX_CellData: array[32] of Text[1024];
        MATRIX_ColumnCaption: array[32] of Text[1024];
        SeeCombinationsQst: Label 'Do you want to see the list of values?';
#pragma warning disable AA0074
        Text001: Label 'No limitations,Limited,Blocked';
#pragma warning restore AA0074
        SelectedDimCode: Code[20];
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

    procedure Load(MatrixColumns1: array[32] of Text[1024]; var MatrixRecords1: array[32] of Record Dimension; _ShowColumnName: Boolean)
    begin
        CopyArray(MATRIX_ColumnCaption, MatrixColumns1, 1);
        CopyArray(MatrixRecords, MatrixRecords1, 1);
        ShowColumnName := _ShowColumnName;
    end;

    procedure SetSelectedDimCode(DimCode: Code[20])
    begin
        SelectedDimCode := DimCode;
    end;

    local procedure SetLimitations(ColumnID: Integer)
    begin
        if MatrixRecords[ColumnID].Code <> Rec.Code then begin
            if CombinationIsLimited(ColumnID) then
                if Confirm(SeeCombinationsQst) then begin
                    DimensionValueCombinations.Load(Rec.Code, MatrixRecords[ColumnID].Code, ShowColumnName);
                    DimensionValueCombinations.RunModal();
                    Clear(DimensionValueCombinations);
                    exit;
                end;

            DisplayListOfDimensionValues(ColumnID);
        end;
    end;

    local procedure CombinationExists(ColumnID: Integer): Boolean
    begin
        Clear(DimComb); // The global record variable holds what GET returns or nothing.
        exit(DimComb.Get(Rec.Code, MatrixRecords[ColumnID].Code) or DimComb.Get(MatrixRecords[ColumnID].Code, Rec.Code));
    end;

    local procedure CombinationIsLimited(ColumnID: Integer): Boolean
    begin
        exit(CombinationExists(ColumnID) and (DimComb."Combination Restriction" = DimComb."Combination Restriction"::Limited));
    end;

    local procedure DisplayListOfDimensionValues(ColumnID: Integer)
    var
        DimLimVal: Integer;
        NewDimLimVal: Integer;
        OptionValueOutOfRange: Integer;
    begin
        OptionValueOutOfRange := -1;
        if MatrixRecords[ColumnID].Code <> Rec.Code then begin
            if not DimComb.Get(Rec.Code, MatrixRecords[ColumnID].Code) then
                if not DimComb.Get(MatrixRecords[ColumnID].Code, Rec.Code) then
                    DimComb."Combination Restriction" := OptionValueOutOfRange;

            DimLimVal := DimComb."Combination Restriction" + 2;
            NewDimLimVal := StrMenu(Text001, DimLimVal);
            if (DimLimVal <> NewDimLimVal) and (NewDimLimVal <> 0) then begin
                CombRestriction := NewDimLimVal - 1;
                ChangeCombRestriction(ColumnID);
                CurrPage.Update(false);
            end;
        end;
    end;

    local procedure MATRIX_OnAfterGetRecord()
    begin
        ShowCombRestriction();
        if CombRestriction = CombRestriction::" " then
            MATRIX_CellData[MATRIX_ColumnOrdinal] := ''
        else
            MATRIX_CellData[MATRIX_ColumnOrdinal] := SelectStr(CombRestriction + 1, Text001);
        SetVisible();
    end;

    local procedure MATRIX_OnFindRecord(Which: Text[1024]): Boolean
    begin
        exit(MatrixRecord.Find(Which));
    end;

    local procedure MATRIX_OnNextRecord(Steps: Integer): Integer
    begin
        exit(MatrixRecord.Next(Steps));
    end;

    local procedure ShowCombRestriction()
    var
        Dim1Code: Code[20];
        Dim2Code: Code[20];
    begin
        if Rec.Code > MatrixRecords[MATRIX_ColumnOrdinal].Code then begin
            Dim1Code := MatrixRecords[MATRIX_ColumnOrdinal].Code;
            Dim2Code := Rec.Code;
        end else begin
            Dim1Code := Rec.Code;
            Dim2Code := MatrixRecords[MATRIX_ColumnOrdinal].Code;
        end;

        if not DimComb.Get(Dim1Code, Dim2Code) then
            if not DimComb.Get(Dim2Code, Dim1Code) then begin
                DimComb.Init();
                DimComb."Dimension 1 Code" := Dim1Code;
                DimComb."Dimension 2 Code" := Dim2Code;
                CombRestriction := CombRestriction::" ";
                exit
            end;
        CombRestriction := DimComb."Combination Restriction" + 1;
    end;

    local procedure ChangeCombRestriction(ColumnID: Integer)
    var
        Dim1Code: Code[20];
        Dim2Code: Code[20];
    begin
        if MatrixRecords[ColumnID].Code <> Rec.Code then begin
            if Rec.Code > MatrixRecords[ColumnID].Code then begin
                Dim1Code := MatrixRecords[ColumnID].Code;
                Dim2Code := Rec.Code;
            end else begin
                Dim1Code := Rec.Code;
                Dim2Code := MatrixRecords[ColumnID].Code;
            end;

            if not DimComb.Get(Dim1Code, Dim2Code) then
                if not DimComb.Get(Dim2Code, Dim1Code) then
                    if CombRestriction <> CombRestriction::" " then begin
                        DimComb.Validate("Dimension 1 Code", Dim1Code);
                        DimComb.Validate("Dimension 2 Code", Dim2Code);
                        DimComb.Validate("Combination Restriction", CombRestriction - 1);
                        DimComb.Insert(true);
                        exit;
                    end;

            if CombRestriction = CombRestriction::" " then
                DimComb.Delete(true)
            else begin
                DimComb.Validate("Combination Restriction", CombRestriction - 1);
                DimComb.Modify(true);
            end;
        end;
    end;

    procedure SetVisible()
    begin
        Field1Visible := MATRIX_ColumnCaption[1] <> '';
        Field2Visible := MATRIX_ColumnCaption[2] <> '';
        Field3Visible := MATRIX_ColumnCaption[3] <> '';
        Field4Visible := MATRIX_ColumnCaption[4] <> '';
        Field5Visible := MATRIX_ColumnCaption[5] <> '';
        Field6Visible := MATRIX_ColumnCaption[6] <> '';
        Field7Visible := MATRIX_ColumnCaption[7] <> '';
        Field8Visible := MATRIX_ColumnCaption[8] <> '';
        Field9Visible := MATRIX_ColumnCaption[9] <> '';
        Field10Visible := MATRIX_ColumnCaption[10] <> '';
        Field11Visible := MATRIX_ColumnCaption[11] <> '';
        Field12Visible := MATRIX_ColumnCaption[12] <> '';
        Field13Visible := MATRIX_ColumnCaption[13] <> '';
        Field14Visible := MATRIX_ColumnCaption[14] <> '';
        Field15Visible := MATRIX_ColumnCaption[15] <> '';
        Field16Visible := MATRIX_ColumnCaption[16] <> '';
        Field17Visible := MATRIX_ColumnCaption[17] <> '';
        Field18Visible := MATRIX_ColumnCaption[18] <> '';
        Field19Visible := MATRIX_ColumnCaption[19] <> '';
        Field20Visible := MATRIX_ColumnCaption[20] <> '';
        Field21Visible := MATRIX_ColumnCaption[21] <> '';
        Field22Visible := MATRIX_ColumnCaption[22] <> '';
        Field23Visible := MATRIX_ColumnCaption[23] <> '';
        Field24Visible := MATRIX_ColumnCaption[24] <> '';
        Field25Visible := MATRIX_ColumnCaption[25] <> '';
        Field26Visible := MATRIX_ColumnCaption[26] <> '';
        Field27Visible := MATRIX_ColumnCaption[27] <> '';
        Field28Visible := MATRIX_ColumnCaption[28] <> '';
        Field29Visible := MATRIX_ColumnCaption[29] <> '';
        Field30Visible := MATRIX_ColumnCaption[30] <> '';
        Field31Visible := MATRIX_ColumnCaption[31] <> '';
        Field32Visible := MATRIX_ColumnCaption[32] <> '';
    end;
}

