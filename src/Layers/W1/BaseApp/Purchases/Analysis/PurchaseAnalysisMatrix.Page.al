// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Analysis;

using Microsoft.Finance.Analysis;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Analysis;

page 9205 "Purchase Analysis Matrix"
{
    Caption = 'Purchase Analysis Matrix';
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Analysis Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Row Ref. No."; Rec."Row Ref. No.")
                {
                    ApplicationArea = PurchaseAnalysis;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies a row reference number for the analysis line.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = PurchaseAnalysis;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies a description for the analysis line.';
                }
                field(Field1; MatrixData[1])
                {
                    ApplicationArea = PurchaseAnalysis;
                    AutoFormatExpression = FormatStr(1);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[1];
                    StyleExpr = Field1Style;
                    Visible = Field1Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(1);
                    end;
                }
                field(Field2; MatrixData[2])
                {
                    ApplicationArea = PurchaseAnalysis;
                    AutoFormatExpression = FormatStr(2);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[2];
                    StyleExpr = Field2Style;
                    Visible = Field2Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(2);
                    end;
                }
                field(Field3; MatrixData[3])
                {
                    ApplicationArea = PurchaseAnalysis;
                    AutoFormatExpression = FormatStr(3);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[3];
                    StyleExpr = Field3Style;
                    Visible = Field3Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(3);
                    end;
                }
                field(Field4; MatrixData[4])
                {
                    ApplicationArea = PurchaseAnalysis;
                    AutoFormatExpression = FormatStr(4);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[4];
                    StyleExpr = Field4Style;
                    Visible = Field4Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(4);
                    end;
                }
                field(Field5; MatrixData[5])
                {
                    ApplicationArea = PurchaseAnalysis;
                    AutoFormatExpression = FormatStr(5);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[5];
                    StyleExpr = Field5Style;
                    Visible = Field5Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(5);
                    end;
                }
                field(Field6; MatrixData[6])
                {
                    ApplicationArea = PurchaseAnalysis;
                    AutoFormatExpression = FormatStr(6);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[6];
                    StyleExpr = Field6Style;
                    Visible = Field6Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(6);
                    end;
                }
                field(Field7; MatrixData[7])
                {
                    ApplicationArea = PurchaseAnalysis;
                    AutoFormatExpression = FormatStr(7);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[7];
                    StyleExpr = Field7Style;
                    Visible = Field7Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(7);
                    end;
                }
                field(Field8; MatrixData[8])
                {
                    ApplicationArea = PurchaseAnalysis;
                    AutoFormatExpression = FormatStr(8);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[8];
                    StyleExpr = Field8Style;
                    Visible = Field8Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(8);
                    end;
                }
                field(Field9; MatrixData[9])
                {
                    ApplicationArea = PurchaseAnalysis;
                    AutoFormatExpression = FormatStr(9);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[9];
                    StyleExpr = Field9Style;
                    Visible = Field9Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(9);
                    end;
                }
                field(Field10; MatrixData[10])
                {
                    ApplicationArea = PurchaseAnalysis;
                    AutoFormatExpression = FormatStr(10);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[10];
                    StyleExpr = Field10Style;
                    Visible = Field10Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(10);
                    end;
                }
                field(Field11; MatrixData[11])
                {
                    ApplicationArea = PurchaseAnalysis;
                    AutoFormatExpression = FormatStr(11);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[11];
                    StyleExpr = Field11Style;
                    Visible = Field11Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(11);
                    end;
                }
                field(Field12; MatrixData[12])
                {
                    ApplicationArea = PurchaseAnalysis;
                    AutoFormatExpression = FormatStr(12);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[12];
                    StyleExpr = Field12Style;
                    Visible = Field12Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(12);
                    end;
                }
                field(Field13; MatrixData[13])
                {
                    ApplicationArea = PurchaseAnalysis;
                    AutoFormatExpression = FormatStr(13);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[13];
                    StyleExpr = Field13Style;
                    Visible = Field13Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(13);
                    end;
                }
                field(Field14; MatrixData[14])
                {
                    ApplicationArea = PurchaseAnalysis;
                    AutoFormatExpression = FormatStr(14);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[14];
                    StyleExpr = Field14Style;
                    Visible = Field14Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(14);
                    end;
                }
                field(Field15; MatrixData[15])
                {
                    ApplicationArea = PurchaseAnalysis;
                    AutoFormatExpression = FormatStr(15);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[15];
                    StyleExpr = Field15Style;
                    Visible = Field15Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(15);
                    end;
                }
                field(Field16; MatrixData[16])
                {
                    ApplicationArea = PurchaseAnalysis;
                    AutoFormatExpression = FormatStr(16);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[16];
                    StyleExpr = Field16Style;
                    Visible = Field16Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(16);
                    end;
                }
                field(Field17; MatrixData[17])
                {
                    ApplicationArea = PurchaseAnalysis;
                    AutoFormatExpression = FormatStr(17);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[17];
                    StyleExpr = Field17Style;
                    Visible = Field17Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(17);
                    end;
                }
                field(Field18; MatrixData[18])
                {
                    ApplicationArea = PurchaseAnalysis;
                    AutoFormatExpression = FormatStr(18);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[18];
                    StyleExpr = Field18Style;
                    Visible = Field18Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(18);
                    end;
                }
                field(Field19; MatrixData[19])
                {
                    ApplicationArea = PurchaseAnalysis;
                    AutoFormatExpression = FormatStr(19);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[19];
                    StyleExpr = Field19Style;
                    Visible = Field19Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(19);
                    end;
                }
                field(Field20; MatrixData[20])
                {
                    ApplicationArea = PurchaseAnalysis;
                    AutoFormatExpression = FormatStr(20);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[20];
                    StyleExpr = Field20Style;
                    Visible = Field20Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(20);
                    end;
                }
                field(Field21; MatrixData[21])
                {
                    ApplicationArea = PurchaseAnalysis;
                    AutoFormatExpression = FormatStr(21);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[21];
                    StyleExpr = Field21Style;
                    Visible = Field21Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(21);
                    end;
                }
                field(Field22; MatrixData[22])
                {
                    ApplicationArea = PurchaseAnalysis;
                    AutoFormatExpression = FormatStr(22);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[22];
                    StyleExpr = Field22Style;
                    Visible = Field22Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(22);
                    end;
                }
                field(Field23; MatrixData[23])
                {
                    ApplicationArea = PurchaseAnalysis;
                    AutoFormatExpression = FormatStr(23);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[23];
                    StyleExpr = Field23Style;
                    Visible = Field23Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(23);
                    end;
                }
                field(Field24; MatrixData[24])
                {
                    ApplicationArea = PurchaseAnalysis;
                    AutoFormatExpression = FormatStr(24);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[24];
                    StyleExpr = Field24Style;
                    Visible = Field24Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(24);
                    end;
                }
                field(Field25; MatrixData[25])
                {
                    ApplicationArea = PurchaseAnalysis;
                    AutoFormatExpression = FormatStr(25);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[25];
                    StyleExpr = Field25Style;
                    Visible = Field25Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(25);
                    end;
                }
                field(Field26; MatrixData[26])
                {
                    ApplicationArea = PurchaseAnalysis;
                    AutoFormatExpression = FormatStr(26);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[26];
                    StyleExpr = Field26Style;
                    Visible = Field26Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(26);
                    end;
                }
                field(Field27; MatrixData[27])
                {
                    ApplicationArea = PurchaseAnalysis;
                    AutoFormatExpression = FormatStr(27);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[27];
                    StyleExpr = Field27Style;
                    Visible = Field27Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(27);
                    end;
                }
                field(Field28; MatrixData[28])
                {
                    ApplicationArea = PurchaseAnalysis;
                    AutoFormatExpression = FormatStr(28);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[28];
                    StyleExpr = Field28Style;
                    Visible = Field28Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(28);
                    end;
                }
                field(Field29; MatrixData[29])
                {
                    ApplicationArea = PurchaseAnalysis;
                    AutoFormatExpression = FormatStr(29);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[29];
                    StyleExpr = Field29Style;
                    Visible = Field29Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(29);
                    end;
                }
                field(Field30; MatrixData[30])
                {
                    ApplicationArea = PurchaseAnalysis;
                    AutoFormatExpression = FormatStr(30);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[30];
                    StyleExpr = Field30Style;
                    Visible = Field30Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(30);
                    end;
                }
                field(Field31; MatrixData[31])
                {
                    ApplicationArea = PurchaseAnalysis;
                    AutoFormatExpression = FormatStr(31);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[31];
                    StyleExpr = Field31Style;
                    Visible = Field31Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(31);
                    end;
                }
                field(Field32; MatrixData[32])
                {
                    ApplicationArea = PurchaseAnalysis;
                    AutoFormatExpression = FormatStr(32);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[32];
                    StyleExpr = Field32Style;
                    Visible = Field32Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(32);
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
        CellValue: Decimal;
    begin
        i := 1;

        if AnalysisColumn.Find('-') then
            repeat
                if i <= ArrayLen(MatrixData) then begin
                    if Rec.Range = '' then
                        CellValue := 0
                    else
                        CellValue := AnalysisReportMgt.CalcCell(Rec, AnalysisColumn, false);
                    MatrixData[i] := MatrixMgt.RoundAmount(CellValue, AnalysisColumn."Rounding Factor");
                    MatrixRounding[i] := AnalysisColumn."Rounding Factor";
                    CachedContainsError[i] := FindError();
                end;
                SetStyle(i);
                i := i + 1;
            until AnalysisColumn.Next() = 0;
        Emphasize := Rec.Bold;
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
        Rec.SetFilter(Show, '<>%1', Rec.Show::No);
        AnalysisColumn.SetRange("Analysis Area", AnalysisColumn."Analysis Area"::Purchase);
        AnalysisColumn.SetRange("Analysis Column Template", AnalysisColumn."Analysis Column Template");
        AnalysisColumn.SetRange("Line No.", FirstLineNo, LastLineNo);
        AnalysisColumn.SetFilter(Show, '<>%1', AnalysisColumn.Show::Never);

        SetVisible();
    end;

    var
        AnalysisColumn2: Record "Analysis Column";
        MatrixMgt: Codeunit "Matrix Management";
        MatrixColumnCaptions: array[32] of Text[1024];
        i: Integer;
        MatrixData: array[32] of Decimal;
        MatrixRounding: array[32] of Enum "Analysis Rounding Factor";
        FirstLineNo: Integer;
        LastLineNo: Integer;
        CachedContainsError: array[32] of Boolean;
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
        Emphasize: Boolean;
        Field1Style: Text;
        Field2Style: Text;
        Field3Style: Text;
        Field4Style: Text;
        Field5Style: Text;
        Field6Style: Text;
        Field7Style: Text;
        Field8Style: Text;
        Field9Style: Text;
        Field10Style: Text;
        Field11Style: Text;
        Field12Style: Text;
        Field13Style: Text;
        Field14Style: Text;
        Field15Style: Text;
        Field16Style: Text;
        Field17Style: Text;
        Field18Style: Text;
        Field19Style: Text;
        Field20Style: Text;
        Field21Style: Text;
        Field22Style: Text;
        Field23Style: Text;
        Field24Style: Text;
        Field25Style: Text;
        Field26Style: Text;
        Field27Style: Text;
        Field28Style: Text;
        Field29Style: Text;
        Field30Style: Text;
        Field31Style: Text;
        Field32Style: Text;

    protected var
        AnalysisColumn: Record "Analysis Column";
        AnalysisReportMgt: Codeunit "Analysis Report Management";

    procedure Load(AnalysisColumn1: Record "Analysis Column"; MatrixColumnCaptions1: array[32] of Text[1024]; FirstLineNo1: Integer; LastLineNo1: Integer)
    begin
        AnalysisColumn.Copy(AnalysisColumn1);
        CopyArray(MatrixColumnCaptions, MatrixColumnCaptions1, 1);

        FirstLineNo := FirstLineNo1;
        LastLineNo := LastLineNo1;
    end;

    local procedure GetHorizontalRecord(HorizontalRecordOrdinal: Integer; var HorizontalRecord: Record "Analysis Column")
    var
        n: Integer;
    begin
        n := 1;
        if HorizontalRecord.Find('-') then
            while n <> HorizontalRecordOrdinal do begin
                n := n + 1;
                HorizontalRecord.Next();
            end;
    end;

    local procedure FindError(): Boolean
    begin
        if AnalysisReportMgt.GetDivisionError() or
           AnalysisReportMgt.GetPeriodError() or
           AnalysisReportMgt.GetFormulaError() or
           AnalysisReportMgt.GetCyclicError()
        then
            exit(true);

        exit(false);
    end;

    local procedure FieldDrillDown(ColumnID: Integer)
    begin
        AnalysisColumn2.Copy(AnalysisColumn);
        GetHorizontalRecord(ColumnID, AnalysisColumn2);
        AnalysisReportMgt.CalcCell(Rec, AnalysisColumn2, true);
    end;

    procedure SetVisible()
    begin
        Field1Visible := MatrixColumnCaptions[1] <> '';
        Field2Visible := MatrixColumnCaptions[2] <> '';
        Field3Visible := MatrixColumnCaptions[3] <> '';
        Field4Visible := MatrixColumnCaptions[4] <> '';
        Field5Visible := MatrixColumnCaptions[5] <> '';
        Field6Visible := MatrixColumnCaptions[6] <> '';
        Field7Visible := MatrixColumnCaptions[7] <> '';
        Field8Visible := MatrixColumnCaptions[8] <> '';
        Field9Visible := MatrixColumnCaptions[9] <> '';
        Field10Visible := MatrixColumnCaptions[10] <> '';
        Field11Visible := MatrixColumnCaptions[11] <> '';
        Field12Visible := MatrixColumnCaptions[12] <> '';
        Field13Visible := MatrixColumnCaptions[13] <> '';
        Field14Visible := MatrixColumnCaptions[14] <> '';
        Field15Visible := MatrixColumnCaptions[15] <> '';
        Field16Visible := MatrixColumnCaptions[16] <> '';
        Field17Visible := MatrixColumnCaptions[17] <> '';
        Field18Visible := MatrixColumnCaptions[18] <> '';
        Field19Visible := MatrixColumnCaptions[19] <> '';
        Field20Visible := MatrixColumnCaptions[20] <> '';
        Field21Visible := MatrixColumnCaptions[21] <> '';
        Field22Visible := MatrixColumnCaptions[22] <> '';
        Field23Visible := MatrixColumnCaptions[23] <> '';
        Field24Visible := MatrixColumnCaptions[24] <> '';
        Field25Visible := MatrixColumnCaptions[25] <> '';
        Field26Visible := MatrixColumnCaptions[26] <> '';
        Field27Visible := MatrixColumnCaptions[27] <> '';
        Field28Visible := MatrixColumnCaptions[28] <> '';
        Field29Visible := MatrixColumnCaptions[29] <> '';
        Field30Visible := MatrixColumnCaptions[30] <> '';
        Field31Visible := MatrixColumnCaptions[31] <> '';
        Field32Visible := MatrixColumnCaptions[32] <> '';
    end;

    procedure GetMatrixDimension(): Integer
    begin
        exit(ArrayLen(MatrixColumnCaptions));
    end;

    procedure FormatStr(ColumnNo: Integer): Text
    begin
        exit(MatrixMgt.FormatRoundingFactor(MatrixRounding[ColumnNo], false));
    end;

    local procedure SetStyle(ColumnID: Integer)
    begin
        SetFieldStyle(Field1Style, ColumnID);
        SetFieldStyle(Field2Style, ColumnID);
        SetFieldStyle(Field3Style, ColumnID);
        SetFieldStyle(Field4Style, ColumnID);
        SetFieldStyle(Field5Style, ColumnID);
        SetFieldStyle(Field6Style, ColumnID);
        SetFieldStyle(Field7Style, ColumnID);
        SetFieldStyle(Field8Style, ColumnID);
        SetFieldStyle(Field9Style, ColumnID);
        SetFieldStyle(Field10Style, ColumnID);
        SetFieldStyle(Field11Style, ColumnID);
        SetFieldStyle(Field12Style, ColumnID);
        SetFieldStyle(Field13Style, ColumnID);
        SetFieldStyle(Field14Style, ColumnID);
        SetFieldStyle(Field15Style, ColumnID);
        SetFieldStyle(Field16Style, ColumnID);
        SetFieldStyle(Field17Style, ColumnID);
        SetFieldStyle(Field18Style, ColumnID);
        SetFieldStyle(Field19Style, ColumnID);
        SetFieldStyle(Field20Style, ColumnID);
        SetFieldStyle(Field21Style, ColumnID);
        SetFieldStyle(Field22Style, ColumnID);
        SetFieldStyle(Field23Style, ColumnID);
        SetFieldStyle(Field24Style, ColumnID);
        SetFieldStyle(Field25Style, ColumnID);
        SetFieldStyle(Field26Style, ColumnID);
        SetFieldStyle(Field27Style, ColumnID);
        SetFieldStyle(Field28Style, ColumnID);
        SetFieldStyle(Field29Style, ColumnID);
        SetFieldStyle(Field30Style, ColumnID);
        SetFieldStyle(Field31Style, ColumnID);
        SetFieldStyle(Field32Style, ColumnID);
    end;

    local procedure SetFieldStyle(var FieldStyle: Text; ColumnID: Integer)
    begin
        if CachedContainsError[ColumnID] then
            FieldStyle := 'Unfavorable'
        else
            FieldStyle := 'Standard';
    end;
}

