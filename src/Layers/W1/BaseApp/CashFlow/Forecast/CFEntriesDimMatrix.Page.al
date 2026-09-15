// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Forecast;

using Microsoft.CashFlow.Account;
using Microsoft.Finance.Dimension;

page 863 "CF Entries Dim. Matrix"
{
    Caption = 'CF Forcst. Entries Dim. Overv. M.';
    DataCaptionExpression = GetCaption();
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Cash Flow Forecast Entry";

    layout
    {
        area(content)
        {
            group(Disclaimer)
            {
                Caption = ' ';
                ShowCaption = false;
                Editable = false;
                InstructionalText = 'AI generated suggestions may not always be accurate. Please validate results for correctness before using content provided.';
            }
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("Cash Flow Date"; Rec."Cash Flow Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the cash flow date that the entry is posted to.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the document that represents the forecast entry.';
                }
                field("Cash Flow Forecast No."; Rec."Cash Flow Forecast No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a number for the cash flow forecast.';
                }
                field("Cash Flow Account No."; Rec."Cash Flow Account No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the cash flow account that the forecast entry is posted to.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a description of the cash flow forecast.';
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the amount of the worksheet line in LCY. Revenues are entered without a plus or minus sign. Expenses are entered with a minus sign.';
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field(Field1; MATRIX_CellData[1])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[1];
                    Visible = Field1Visible;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MATRIX_UpdateMatrixRecord(1);
                        MATRIX_OnLookup(Text);
                    end;
                }
                field(Field2; MATRIX_CellData[2])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[2];
                    Visible = Field2Visible;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MATRIX_UpdateMatrixRecord(2);
                        MATRIX_OnLookup(Text);
                    end;
                }
                field(Field3; MATRIX_CellData[3])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[3];
                    Visible = Field3Visible;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MATRIX_UpdateMatrixRecord(3);
                        MATRIX_OnLookup(Text);
                    end;
                }
                field(Field4; MATRIX_CellData[4])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[4];
                    Visible = Field4Visible;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MATRIX_UpdateMatrixRecord(4);
                        MATRIX_OnLookup(Text);
                    end;
                }
                field(Field5; MATRIX_CellData[5])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[5];
                    Visible = Field5Visible;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MATRIX_UpdateMatrixRecord(5);
                        MATRIX_OnLookup(Text);
                    end;
                }
                field(Field6; MATRIX_CellData[6])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[6];
                    Visible = Field6Visible;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MATRIX_UpdateMatrixRecord(6);
                        MATRIX_OnLookup(Text);
                    end;
                }
                field(Field7; MATRIX_CellData[7])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[7];
                    Visible = Field7Visible;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MATRIX_UpdateMatrixRecord(7);
                        MATRIX_OnLookup(Text);
                    end;
                }
                field(Field8; MATRIX_CellData[8])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[8];
                    Visible = Field8Visible;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MATRIX_UpdateMatrixRecord(8);
                        MATRIX_OnLookup(Text);
                    end;
                }
                field(Field9; MATRIX_CellData[9])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[9];
                    Visible = Field9Visible;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MATRIX_UpdateMatrixRecord(9);
                        MATRIX_OnLookup(Text);
                    end;
                }
                field(Field10; MATRIX_CellData[10])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[10];
                    Visible = Field10Visible;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MATRIX_UpdateMatrixRecord(10);
                        MATRIX_OnLookup(Text);
                    end;
                }
                field(Field11; MATRIX_CellData[11])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[11];
                    Visible = Field11Visible;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MATRIX_UpdateMatrixRecord(11);
                        MATRIX_OnLookup(Text);
                    end;
                }
                field(Field12; MATRIX_CellData[12])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[12];
                    Visible = Field12Visible;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MATRIX_UpdateMatrixRecord(12);
                        MATRIX_OnLookup(Text);
                    end;
                }
                field(Field13; MATRIX_CellData[13])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[13];
                    Visible = Field13Visible;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MATRIX_UpdateMatrixRecord(13);
                        MATRIX_OnLookup(Text);
                    end;
                }
                field(Field14; MATRIX_CellData[14])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[14];
                    Visible = Field14Visible;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MATRIX_UpdateMatrixRecord(14);
                        MATRIX_OnLookup(Text);
                    end;
                }
                field(Field15; MATRIX_CellData[15])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[15];
                    Visible = Field15Visible;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MATRIX_UpdateMatrixRecord(15);
                        MATRIX_OnLookup(Text);
                    end;
                }
                field(Field16; MATRIX_CellData[16])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[16];
                    Visible = Field16Visible;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MATRIX_UpdateMatrixRecord(16);
                        MATRIX_OnLookup(Text);
                    end;
                }
                field(Field17; MATRIX_CellData[17])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[17];
                    Visible = Field17Visible;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MATRIX_UpdateMatrixRecord(17);
                        MATRIX_OnLookup(Text);
                    end;
                }
                field(Field18; MATRIX_CellData[18])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[18];
                    Visible = Field18Visible;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MATRIX_UpdateMatrixRecord(18);
                        MATRIX_OnLookup(Text);
                    end;
                }
                field(Field19; MATRIX_CellData[19])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[19];
                    Visible = Field19Visible;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MATRIX_UpdateMatrixRecord(19);
                        MATRIX_OnLookup(Text);
                    end;
                }
                field(Field20; MATRIX_CellData[20])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[20];
                    Visible = Field20Visible;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MATRIX_UpdateMatrixRecord(20);
                        MATRIX_OnLookup(Text);
                    end;
                }
                field(Field21; MATRIX_CellData[21])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[21];
                    Visible = Field21Visible;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MATRIX_UpdateMatrixRecord(21);
                        MATRIX_OnLookup(Text);
                    end;
                }
                field(Field22; MATRIX_CellData[22])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[22];
                    Visible = Field22Visible;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MATRIX_UpdateMatrixRecord(22);
                        MATRIX_OnLookup(Text);
                    end;
                }
                field(Field23; MATRIX_CellData[23])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[23];
                    Visible = Field23Visible;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MATRIX_UpdateMatrixRecord(23);
                        MATRIX_OnLookup(Text);
                    end;
                }
                field(Field24; MATRIX_CellData[24])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[24];
                    Visible = Field24Visible;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MATRIX_UpdateMatrixRecord(24);
                        MATRIX_OnLookup(Text);
                    end;
                }
                field(Field25; MATRIX_CellData[25])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[25];
                    Visible = Field25Visible;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MATRIX_UpdateMatrixRecord(25);
                        MATRIX_OnLookup(Text);
                    end;
                }
                field(Field26; MATRIX_CellData[26])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[26];
                    Visible = Field26Visible;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MATRIX_UpdateMatrixRecord(26);
                        MATRIX_OnLookup(Text);
                    end;
                }
                field(Field27; MATRIX_CellData[27])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[27];
                    Visible = Field27Visible;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MATRIX_UpdateMatrixRecord(27);
                        MATRIX_OnLookup(Text);
                    end;
                }
                field(Field28; MATRIX_CellData[28])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[28];
                    Visible = Field28Visible;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MATRIX_UpdateMatrixRecord(28);
                        MATRIX_OnLookup(Text);
                    end;
                }
                field(Field29; MATRIX_CellData[29])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[29];
                    Visible = Field29Visible;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MATRIX_UpdateMatrixRecord(29);
                        MATRIX_OnLookup(Text);
                    end;
                }
                field(Field30; MATRIX_CellData[30])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[30];
                    Visible = Field30Visible;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MATRIX_UpdateMatrixRecord(30);
                        MATRIX_OnLookup(Text);
                    end;
                }
                field(Field31; MATRIX_CellData[31])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[31];
                    Visible = Field31Visible;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MATRIX_UpdateMatrixRecord(31);
                        MATRIX_OnLookup(Text);
                    end;
                }
                field(Field32; MATRIX_CellData[32])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[32];
                    Visible = Field32Visible;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MATRIX_UpdateMatrixRecord(32);
                        MATRIX_OnLookup(Text);
                    end;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Actions")
            {
                Caption = '&Actions';
                Image = "Action";
                group(Entries)
                {
                    Caption = 'Entries';
                    Image = Entries;
                    action(Dimensions)
                    {
                        AccessByPermission = TableData Dimension = R;
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions';
                        Image = Dimensions;
                        ShortCutKey = 'Alt+D';
                        ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                        trigger OnAction()
                        begin
                            Rec.ShowDimensions();
                        end;
                    }
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        MATRIX_Steps: Integer;
    begin
        MATRIX_CurrentColumnOrdinal := 0;
        DimensionMatrix.SetPosition(MATRIX_PKFirstCaptionInSet);
        if MATRIX_OnFindRecord('=') then begin
            MATRIX_CurrentColumnOrdinal := 1;
            repeat
                MATRIX_OnAfterGetRecord();
                MATRIX_Steps := MATRIX_OnNextRecord(1);
                MATRIX_CurrentColumnOrdinal := MATRIX_CurrentColumnOrdinal + MATRIX_Steps;
            until (MATRIX_CurrentColumnOrdinal - MATRIX_Steps = MATRIX_NoOfMatrixColumns) or (MATRIX_Steps = 0);
            if MATRIX_CurrentColumnOrdinal <> 1 then begin
                MATRIX_OnNextRecord(1 - MATRIX_CurrentColumnOrdinal);
                MATRIX_CurrentColumnOrdinal := 1;
            end;
        end;

        MATRIX_CurrentColumnOrdinal := MATRIX_CurrentColumnOrdinal;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        Found: Boolean;
    begin
        if RunOnTempRec then begin
            TempCFForecastEntry := Rec;
            Found := TempCFForecastEntry.Find(Which);
            if Found then
                Rec := TempCFForecastEntry;
            exit(Found);
        end;
        exit(Rec.Find(Which));
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
    var
        ResultSteps: Integer;
    begin
        if RunOnTempRec then begin
            TempCFForecastEntry := Rec;
            ResultSteps := TempCFForecastEntry.Next(Steps);
            if ResultSteps <> 0 then
                Rec := TempCFForecastEntry;
            exit(ResultSteps);
        end;
        exit(Rec.Next(Steps));
    end;

    trigger OnOpenPage()
    begin
        MATRIX_NoOfMatrixColumns := ArrayLen(MATRIX_CellData);
        SetColumnVisibility();
    end;

    var
        CFAccount: Record "Cash Flow Account";
        TempCFForecastEntry: Record "Cash Flow Forecast Entry" temporary;
        DimSetEntry: Record "Dimension Set Entry";
        DimensionMatrix: Record Dimension;
        MATRIX_CellData: array[32] of Text[80];
        MATRIX_ColumnCaptions: array[32] of Text[80];
        MATRIX_PKFirstCaptionInSet: Text;
        MATRIX_NoOfMatrixColumns: Integer;
        MATRIX_CurrentColumnOrdinal: Integer;
        MATRIX_CurrSetLength: Integer;
        RunOnTempRec: Boolean;
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

    local procedure GetCaption(): Text[250]
    begin
        if CFAccount."No." <> Rec."Cash Flow Account No." then
            CFAccount.Get(Rec."Cash Flow Account No.");
        exit(StrSubstNo('%1 %2', CFAccount."No.", CFAccount.Name));
    end;

    local procedure MATRIX_UpdateMatrixRecord(MATRIX_NewColumnOrdinal: Integer)
    begin
        MATRIX_CurrentColumnOrdinal := MATRIX_NewColumnOrdinal;
        DimensionMatrix.SetPosition(MATRIX_PKFirstCaptionInSet);
        MATRIX_OnFindRecord('=');
        MATRIX_OnNextRecord(MATRIX_NewColumnOrdinal - 1);
    end;

    local procedure MATRIX_OnAfterGetRecord()
    begin
        if not DimSetEntry.Get(Rec."Dimension Set ID", DimensionMatrix.Code) then begin
            DimSetEntry.Init();
            DimSetEntry."Dimension Code" := DimensionMatrix.Code;
        end;
        MATRIX_CellData[MATRIX_CurrentColumnOrdinal] := Format(DimSetEntry."Dimension Value Code");
    end;

    local procedure MATRIX_OnFindRecord(Which: Text[1024]): Boolean
    begin
        exit(DimensionMatrix.Find(Which));
    end;

    local procedure MATRIX_OnNextRecord(Steps: Integer): Integer
    begin
        exit(DimensionMatrix.Next(Steps));
    end;

    procedure Load(NewMATRIX_Captions: array[32] of Text[80]; PKFirstCaptionInSet: Text; LengthOfCurrSet: Integer)
    begin
        CopyArray(MATRIX_ColumnCaptions, NewMATRIX_Captions, 1);
        MATRIX_PKFirstCaptionInSet := PKFirstCaptionInSet;
        MATRIX_CurrSetLength := LengthOfCurrSet;
    end;

    local procedure MATRIX_OnLookup(var Text: Text[1024])
    var
        DimVal: Record "Dimension Value";
    begin
        Text := DimensionMatrix.Code; // For PreCal
        DimVal.SetRange("Dimension Code", DimensionMatrix.Code);
        DimVal."Dimension Code" := DimSetEntry."Dimension Code";
        DimVal.Code := DimSetEntry."Dimension Value Code";
        PAGE.RunModal(PAGE::"Dimension Value List", DimVal);
    end;

    procedure SetTempCFForecastEntry(var NewCFForecastEntry: Record "Cash Flow Forecast Entry")
    begin
        RunOnTempRec := true;
        TempCFForecastEntry.DeleteAll();
        if NewCFForecastEntry.Find('-') then
            repeat
                TempCFForecastEntry := NewCFForecastEntry;
                TempCFForecastEntry.Insert();
            until NewCFForecastEntry.Next() = 0;
    end;

    procedure SetColumnVisibility()
    begin
        Field1Visible := MATRIX_CurrSetLength >= 1;
        Field2Visible := MATRIX_CurrSetLength >= 2;
        Field3Visible := MATRIX_CurrSetLength >= 3;
        Field4Visible := MATRIX_CurrSetLength >= 4;
        Field5Visible := MATRIX_CurrSetLength >= 5;
        Field6Visible := MATRIX_CurrSetLength >= 6;
        Field7Visible := MATRIX_CurrSetLength >= 7;
        Field8Visible := MATRIX_CurrSetLength >= 8;
        Field9Visible := MATRIX_CurrSetLength >= 9;
        Field10Visible := MATRIX_CurrSetLength >= 10;
        Field11Visible := MATRIX_CurrSetLength >= 11;
        Field12Visible := MATRIX_CurrSetLength >= 12;
        Field13Visible := MATRIX_CurrSetLength >= 13;
        Field14Visible := MATRIX_CurrSetLength >= 14;
        Field15Visible := MATRIX_CurrSetLength >= 15;
        Field16Visible := MATRIX_CurrSetLength >= 16;
        Field17Visible := MATRIX_CurrSetLength >= 17;
        Field18Visible := MATRIX_CurrSetLength >= 18;
        Field19Visible := MATRIX_CurrSetLength >= 19;
        Field20Visible := MATRIX_CurrSetLength >= 20;
        Field21Visible := MATRIX_CurrSetLength >= 21;
        Field22Visible := MATRIX_CurrSetLength >= 22;
        Field23Visible := MATRIX_CurrSetLength >= 23;
        Field24Visible := MATRIX_CurrSetLength >= 24;
        Field25Visible := MATRIX_CurrSetLength >= 25;
        Field26Visible := MATRIX_CurrSetLength >= 26;
        Field27Visible := MATRIX_CurrSetLength >= 27;
        Field28Visible := MATRIX_CurrSetLength >= 28;
        Field29Visible := MATRIX_CurrSetLength >= 29;
        Field30Visible := MATRIX_CurrSetLength >= 30;
        Field31Visible := MATRIX_CurrSetLength >= 31;
        Field32Visible := MATRIX_CurrSetLength >= 32;
    end;
}

