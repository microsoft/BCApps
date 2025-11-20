// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Period;
using System.Utilities;

page 9233 "G/L Balance by Dim. Matrix"
{
    Caption = 'G/L Balance by Dim. Matrix';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Dimension Code Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                IndentationColumn = Rec.Indentation;
                IndentationControls = Name;
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Suite;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the code of the record.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        LookUpCode(AnalysisByDimParameters."Line Dim Option", LineDimCode, Rec.Code);
                    end;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Suite;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the name of the record.';
                }
                field(TotalAmount; Rec.Amount)
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    Caption = 'Total Amount';
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the total value for the amount type that you select in the Show field.';

                    trigger OnDrillDown()
                    begin
                        DrillDown(false);
                    end;
                }
                field(Field1; MATRIX_CellData[1])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[1];
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = Field1Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_UpdateMatrixRecord(1);
                        DrillDown(true);
                    end;
                }
                field(Field2; MATRIX_CellData[2])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[2];
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = Field2Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_UpdateMatrixRecord(2);
                        DrillDown(true);
                    end;
                }
                field(Field3; MATRIX_CellData[3])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[3];
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = Field3Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_UpdateMatrixRecord(3);
                        DrillDown(true);
                    end;
                }
                field(Field4; MATRIX_CellData[4])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[4];
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = Field4Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_UpdateMatrixRecord(4);
                        DrillDown(true);
                    end;
                }
                field(Field5; MATRIX_CellData[5])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[5];
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = Field5Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_UpdateMatrixRecord(5);
                        DrillDown(true);
                    end;
                }
                field(Field6; MATRIX_CellData[6])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[6];
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = Field6Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_UpdateMatrixRecord(6);
                        DrillDown(true);
                    end;
                }
                field(Field7; MATRIX_CellData[7])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[7];
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = Field7Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_UpdateMatrixRecord(7);
                        DrillDown(true);
                    end;
                }
                field(Field8; MATRIX_CellData[8])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[8];
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = Field8Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_UpdateMatrixRecord(8);
                        DrillDown(true);
                    end;
                }
                field(Field9; MATRIX_CellData[9])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[9];
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = Field9Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_UpdateMatrixRecord(9);
                        DrillDown(true);
                    end;
                }
                field(Field10; MATRIX_CellData[10])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[10];
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = Field10Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_UpdateMatrixRecord(10);
                        DrillDown(true);
                    end;
                }
                field(Field11; MATRIX_CellData[11])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[11];
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = Field11Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_UpdateMatrixRecord(11);
                        DrillDown(true);
                    end;
                }
                field(Field12; MATRIX_CellData[12])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[12];
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = Field12Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_UpdateMatrixRecord(12);
                        DrillDown(true);
                    end;
                }
                field(Field13; MATRIX_CellData[13])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[13];
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = Field13Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_UpdateMatrixRecord(13);
                        DrillDown(true);
                    end;
                }
                field(Field14; MATRIX_CellData[14])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[14];
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = Field14Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_UpdateMatrixRecord(14);
                        DrillDown(true);
                    end;
                }
                field(Field15; MATRIX_CellData[15])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[15];
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = Field15Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_UpdateMatrixRecord(15);
                        DrillDown(true);
                    end;
                }
                field(Field16; MATRIX_CellData[16])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[16];
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = Field16Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_UpdateMatrixRecord(16);
                        DrillDown(true);
                    end;
                }
                field(Field17; MATRIX_CellData[17])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[17];
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = Field17Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_UpdateMatrixRecord(17);
                        DrillDown(true);
                    end;
                }
                field(Field18; MATRIX_CellData[18])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[18];
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = Field18Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_UpdateMatrixRecord(18);
                        DrillDown(true);
                    end;
                }
                field(Field19; MATRIX_CellData[19])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[19];
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = Field19Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_UpdateMatrixRecord(19);
                        DrillDown(true);
                    end;
                }
                field(Field20; MATRIX_CellData[20])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[20];
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = Field20Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_UpdateMatrixRecord(20);
                        DrillDown(true);
                    end;
                }
                field(Field21; MATRIX_CellData[21])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[21];
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = Field21Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_UpdateMatrixRecord(21);
                        DrillDown(true);
                    end;
                }
                field(Field22; MATRIX_CellData[22])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[22];
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = Field22Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_UpdateMatrixRecord(22);
                        DrillDown(true);
                    end;
                }
                field(Field23; MATRIX_CellData[23])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[23];
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = Field23Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_UpdateMatrixRecord(23);
                        DrillDown(true);
                    end;
                }
                field(Field24; MATRIX_CellData[24])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[24];
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = Field24Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_UpdateMatrixRecord(24);
                        DrillDown(true);
                    end;
                }
                field(Field25; MATRIX_CellData[25])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[25];
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = Field25Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_UpdateMatrixRecord(25);
                        DrillDown(true);
                    end;
                }
                field(Field26; MATRIX_CellData[26])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[26];
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = Field26Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_UpdateMatrixRecord(26);
                        DrillDown(true);
                    end;
                }
                field(Field27; MATRIX_CellData[27])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[27];
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = Field27Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_UpdateMatrixRecord(27);
                        DrillDown(true);
                    end;
                }
                field(Field28; MATRIX_CellData[28])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[28];
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = Field28Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_UpdateMatrixRecord(28);
                        DrillDown(true);
                    end;
                }
                field(Field29; MATRIX_CellData[29])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[29];
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = Field29Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_UpdateMatrixRecord(29);
                        DrillDown(true);
                    end;
                }
                field(Field30; MATRIX_CellData[30])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[30];
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = Field30Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_UpdateMatrixRecord(30);
                        DrillDown(true);
                    end;
                }
                field(Field31; MATRIX_CellData[31])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[31];
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = Field31Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_UpdateMatrixRecord(31);
                        DrillDown(true);
                    end;
                }
                field(Field32; MATRIX_CellData[32])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaptions[32];
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Visible = Field32Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_UpdateMatrixRecord(32);
                        DrillDown(true);
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
        // IF CurrForm.TotalAmount.VISIBLE THEN
        Rec.Amount := MatrixMgt.RoundAmount(CalcAmount(false), AnalysisByDimParameters."Rounding Factor");

        MATRIX_CurrentColumnOrdinal := 0;
        MatrixRecord.SetPosition(MATRIX_PrimKeyFirstCol);

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
        end;
        SetColumnVisibility();
        FormatLine();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        FindNext := false;
        if AnalysisByDimParameters."Line Dim Option" = AnalysisByDimParameters."Line Dim Option"::"G/L Account" then begin
            FindNext := true;
            exit(Rec.Find(Which));
        end;
        exit(FindRec(AnalysisByDimParameters."Line Dim Option", Rec, Which));
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
        exit(NextRec(AnalysisByDimParameters."Line Dim Option", Rec, Steps));
    end;

    trigger OnOpenPage()
    begin
        Rec.Code := '';

        GLSetup.Get();

        if (LineDimCode = '') and (ColumnDimCode = '') then begin
            LineDimCode := GLAcc.TableCaption();
            ColumnDimCode := Text001;
        end;
        AnalysisByDimParameters."Line Dim Option" := DimCodeToOption(LineDimCode);
        AnalysisByDimParameters."Column Dim Option" := DimCodeToOption(ColumnDimCode);
        InitRecord(Rec, AnalysisByDimParameters."Line Dim Option");
        CalculateClosingDateFilter();

        MATRIX_NoOfMatrixColumns := ArrayLen(MATRIX_CellData);

        if not PeriodInitialized then
            LoadDefault();

        FindRec(AnalysisByDimParameters."Column Dim Option", MatrixRecord, '=');
        SetColumnVisibility();
        if MATRIX_PrimKeyFirstCol = '' then
            MATRIX_PrimKeyFirstCol := MatrixRecord.GetPosition();
    end;

    var
        GLSetup: Record "General Ledger Setup";
        GLAcc: Record "G/L Account";
        TempDimensionCodeAmountBuffer: Record "Dimension Code Amount Buffer" temporary;
        CurrExchRate: Record "Currency Exchange Rate";
        MatrixRecord: Record "Dimension Code Buffer";
        MatrixMgt: Codeunit "Matrix Management";
        LineDimCode: Text[30];
        ColumnDimCode: Text[30];
        ExcludeClosingDateFilter: Text;
        InternalDateFilter: Text;
        MatrixAmount: Decimal;
        PeriodInitialized: Boolean;
        CurrExchDate: Date;
        MATRIX_ColumnOrdinal: Integer;
        MATRIX_NoOfMatrixColumns: Integer;
        MATRIX_CellData: array[32] of Decimal;
        MATRIX_ColumnCaptions: array[32] of Text[1024];
        MATRIX_PrimKeyFirstCol: Text[1024];
        RoundingFactorFormatString: Text;
        MATRIX_CurrSetLength: Integer;
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
        FindNext: Boolean;

#pragma warning disable AA0074
        Text001: Label 'Period';
#pragma warning restore AA0074

    protected var
        AnalysisByDimParameters: Record "Analysis by Dim. Parameters";

    local procedure DimCodeToOption(DimCode: Text[30]) Result: Enum "Analysis Dimension Option"
    var
        BusUnit: Record "Business Unit";
        ResultInt: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDimCodeToOption(DimCode, ResultInt, IsHandled);
        Result := "Analysis Dimension Option".FromInteger(ResultInt);
        if IsHandled then
            exit(Result);

        case DimCode of
            '':
                exit("Analysis Dimension Option"::Undefined);
            GLAcc.TableCaption:
                exit("Analysis Dimension Option"::"G/L Account");
            Text001:
                exit("Analysis Dimension Option"::Period);
            BusUnit.TableCaption:
                exit("Analysis Dimension Option"::"Business Unit");
            GLSetup."Global Dimension 1 Code":
                exit("Analysis Dimension Option"::"Dimension 1");
            GLSetup."Global Dimension 2 Code":
                exit("Analysis Dimension Option"::"Dimension 2");
            else
                exit("Analysis Dimension Option"::Undefined);
        end;
    end;

    local procedure FindRec(DimOption: Enum "Analysis Dimension Option"; var DimCodeBuf: Record "Dimension Code Buffer"; Which: Text[1024]) Found: Boolean
    var
        GLAcc: Record "G/L Account";
        BusUnit: Record "Business Unit";
        Period: Record Date;
        DimVal: Record "Dimension Value";
        PeriodPageMgt: Codeunit PeriodPageManagement;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindRec(DimOption, DimVal, GLAcc, DimCodeBuf, Which, Found, IsHandled);
        if not IsHandled then
            case DimOption of
                DimOption::"G/L Account":
                    begin
                        GLAcc."No." := DimCodeBuf.Code;
                        if AnalysisByDimParameters."Account Filter" <> '' then
                            GLAcc.SetFilter("No.", AnalysisByDimParameters."Account Filter");
                        Found := GLAcc.Find(Which);
                        if Found then
                            CopyGLAccToBuf(GLAcc, DimCodeBuf);
                    end;
                DimOption::Period:
                    begin
                        if not PeriodInitialized then
                            AnalysisByDimParameters."Date Filter" := '';
                        PeriodInitialized := true;
                        Evaluate(Period."Period Start", DimCodeBuf.Code);
                        if AnalysisByDimParameters."Date Filter" <> '' then
                            Period.SetFilter("Period Start", AnalysisByDimParameters."Date Filter")
                        else
                            if not PeriodInitialized and (InternalDateFilter <> '') then
                                Period.SetFilter("Period Start", InternalDateFilter);
                        Found := PeriodPageMgt.FindDate(Which, Period, AnalysisByDimParameters."Period Type");
                        if Found then
                            CopyPeriodToBuf(Period, DimCodeBuf);
                    end;
                DimOption::"Business Unit":
                    begin
                        BusUnit.Code := DimCodeBuf.Code;
                        if AnalysisByDimParameters."Bus. Unit Filter" <> '' then
                            BusUnit.SetFilter(Code, AnalysisByDimParameters."Bus. Unit Filter");
                        Found := BusUnit.Find(Which);
                        if Found then
                            CopyBusUnitToBuf(BusUnit, DimCodeBuf);
                    end;
                DimOption::"Dimension 1":
                    begin
                        if AnalysisByDimParameters."Dimension 1 Filter" <> '' then
                            DimVal.SetFilter(Code, AnalysisByDimParameters."Dimension 1 Filter");
                        DimVal."Dimension Code" := GLSetup."Global Dimension 1 Code";
                        DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                        DimVal.Code := DimCodeBuf.Code;
                        Found := DimVal.Find(Which);
                        if Found then
                            CopyDimValueToBuf(DimVal, DimCodeBuf);
                    end;
                DimOption::"Dimension 2":
                    begin
                        if AnalysisByDimParameters."Dimension 2 Filter" <> '' then
                            DimVal.SetFilter(Code, AnalysisByDimParameters."Dimension 2 Filter");
                        DimVal."Dimension Code" := GLSetup."Global Dimension 2 Code";
                        DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                        DimVal.Code := DimCodeBuf.Code;
                        Found := DimVal.Find(Which);
                        if Found then
                            CopyDimValueToBuf(DimVal, DimCodeBuf);
                    end;
            end;

        OnAfterFindRec(DimOption.AsInteger(), DimCodeBuf, Which, Found, AnalysisByDimParameters);
    end;

    local procedure NextRec(DimOption: Enum "Analysis Dimension Option"; var DimCodeBuf: Record "Dimension Code Buffer"; Steps: Integer) ResultSteps: Integer
    var
        GLAcc: Record "G/L Account";
        BusUnit: Record "Business Unit";
        Period: Record Date;
        DimVal: Record "Dimension Value";
        PeriodPageMgt: Codeunit PeriodPageManagement;
    begin
        OnBeforeNextRec(DimOption, DimVal, GLAcc);
        case DimOption of
            DimOption::"G/L Account":
                begin
                    if FindNext then
                        exit(DimCodeBuf.Next(Steps));
                    GLAcc."No." := DimCodeBuf.Code;
                    if AnalysisByDimParameters."Account Filter" <> '' then
                        GLAcc.SetFilter("No.", AnalysisByDimParameters."Account Filter");
                    ResultSteps := GLAcc.Next(Steps);
                    if ResultSteps <> 0 then begin
                        CopyGLAccToBuf(GLAcc, DimCodeBuf);
                        if not DimCodeBuf.Get(GLAcc."No.") then
                            DimCodeBuf.Insert();
                    end;
                end;
            DimOption::Period:
                begin
                    if AnalysisByDimParameters."Date Filter" <> '' then
                        Period.SetFilter("Period Start", AnalysisByDimParameters."Date Filter");
                    Period."Period Start" := DimCodeBuf."Period Start";
                    ResultSteps := PeriodPageMgt.NextDate(Steps, Period, AnalysisByDimParameters."Period Type");
                    if ResultSteps <> 0 then
                        CopyPeriodToBuf(Period, DimCodeBuf);
                end;
            DimOption::"Business Unit":
                begin
                    BusUnit.Code := DimCodeBuf.Code;
                    if AnalysisByDimParameters."Bus. Unit Filter" <> '' then
                        BusUnit.SetFilter(Code, AnalysisByDimParameters."Bus. Unit Filter");
                    ResultSteps := BusUnit.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyBusUnitToBuf(BusUnit, DimCodeBuf);
                end;
            DimOption::"Dimension 1":
                begin
                    if AnalysisByDimParameters."Dimension 1 Filter" <> '' then
                        DimVal.SetFilter(Code, AnalysisByDimParameters."Dimension 1 Filter");
                    DimVal."Dimension Code" := GLSetup."Global Dimension 1 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Dimension 2":
                begin
                    if AnalysisByDimParameters."Dimension 2 Filter" <> '' then
                        DimVal.SetFilter(Code, AnalysisByDimParameters."Dimension 2 Filter");
                    DimVal."Dimension Code" := GLSetup."Global Dimension 2 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
        end;
        OnAfterNextRec(DimOption.AsInteger(), DimCodeBuf, Steps, ResultSteps, AnalysisByDimParameters);
    end;

    local procedure CopyGLAccToBuf(var TheGLAcc: Record "G/L Account"; var TheDimCodeBuf: Record "Dimension Code Buffer")
    begin
        TheDimCodeBuf.Init();
        TheDimCodeBuf.Code := TheGLAcc."No.";
        TheDimCodeBuf.Name := TheGLAcc.Name;
        TheDimCodeBuf.Totaling := TheGLAcc.Totaling;
        TheDimCodeBuf.Indentation := TheGLAcc.Indentation;
        TheDimCodeBuf."Show in Bold" := TheGLAcc."Account Type" <> TheGLAcc."Account Type"::Posting;
        OnAfterCopyGLAccToBuf(TheGLAcc, TheDimCodeBuf);
    end;

    local procedure CopyPeriodToBuf(var ThePeriod: Record Date; var TheDimCodeBuf: Record "Dimension Code Buffer")
    var
        Period2: Record Date;
    begin
        TheDimCodeBuf.Init();
        TheDimCodeBuf.Code := Format(ThePeriod."Period Start");
        TheDimCodeBuf."Period Start" := ThePeriod."Period Start";
        if AnalysisByDimParameters."Closing Entries" = AnalysisByDimParameters."Closing Entries"::Include then
            TheDimCodeBuf."Period End" := ClosingDate(ThePeriod."Period End")
        else
            TheDimCodeBuf."Period End" := ThePeriod."Period End";
        if AnalysisByDimParameters."Date Filter" <> '' then begin
            Period2.SetFilter("Period End", AnalysisByDimParameters."Date Filter");
            if Period2.GetRangeMax("Period End") < TheDimCodeBuf."Period End" then
                TheDimCodeBuf."Period End" := Period2.GetRangeMax("Period End");
        end;
        TheDimCodeBuf.Name := ThePeriod."Period Name";
    end;

    local procedure CopyBusUnitToBuf(var TheBusUnit: Record "Business Unit"; var TheDimCodeBuf: Record "Dimension Code Buffer")
    begin
        TheDimCodeBuf.Init();
        TheDimCodeBuf.Code := TheBusUnit.Code;
        TheDimCodeBuf.Name := TheBusUnit.Name;
    end;

    local procedure CopyDimValueToBuf(var TheDimVal: Record "Dimension Value"; var TheDimCodeBuf: Record "Dimension Code Buffer")
    begin
        TheDimCodeBuf.Init();
        TheDimCodeBuf.Code := TheDimVal.Code;
        TheDimCodeBuf.Name := TheDimVal.Name;
        TheDimCodeBuf.Totaling := TheDimVal.Totaling;
        TheDimCodeBuf.Indentation := TheDimVal.Indentation;
        TheDimCodeBuf."Show in Bold" :=
          TheDimVal."Dimension Value Type" <> TheDimVal."Dimension Value Type"::Standard;
        OnAfterCopyDimValueToBuf(TheDimVal, TheDimCodeBuf);
    end;

    local procedure FindPeriod(SearchText: Code[10])
    var
        Period: Record Date;
        PeriodPageMgt: Codeunit PeriodPageManagement;
    begin
        if AnalysisByDimParameters."Date Filter" <> '' then begin
            Period.SetFilter("Period Start", AnalysisByDimParameters."Date Filter");
            if not PeriodPageMgt.FindDate('+', Period, AnalysisByDimParameters."Period Type") then
                PeriodPageMgt.FindDate('+', Period, AnalysisByDimParameters."Period Type"::Day);
            Period.SetRange("Period Start");
        end;
        if PeriodPageMgt.FindDate(SearchText, Period, AnalysisByDimParameters."Period Type") then
            if AnalysisByDimParameters."Closing Entries" = AnalysisByDimParameters."Closing Entries"::Include then
                Period."Period End" := ClosingDate(Period."Period End");
        if AnalysisByDimParameters."Amount Type" = AnalysisByDimParameters."Amount Type"::"Net Change" then begin
            GLAcc.SetRange("Date Filter", Period."Period Start", Period."Period End");
            if GLAcc.GetRangeMin("Date Filter") = GLAcc.GetRangeMax("Date Filter") then
                GLAcc.SetRange("Date Filter", GLAcc.GetRangeMin("Date Filter"));
        end else
            GLAcc.SetRange("Date Filter", 0D, Period."Period End");
        InternalDateFilter := GLAcc.GetFilter("Date Filter");
        if (AnalysisByDimParameters."Line Dim Option" <> AnalysisByDimParameters."Line Dim Option"::Period) and (AnalysisByDimParameters."Column Dim Option" <> AnalysisByDimParameters."Column Dim Option"::Period) then
            AnalysisByDimParameters."Date Filter" := InternalDateFilter;
        TempDimensionCodeAmountBuffer.DeleteAll();
    end;

    local procedure CalculateClosingDateFilter()
    var
        AccountingPeriod: Record "Accounting Period";
        FirstRec: Boolean;
    begin
        if AnalysisByDimParameters."Closing Entries" = AnalysisByDimParameters."Closing Entries"::Include then
            ExcludeClosingDateFilter := ''
        else begin
            AccountingPeriod.SetCurrentKey("New Fiscal Year");
            AccountingPeriod.SetRange("New Fiscal Year", true);
            FirstRec := true;
            if AccountingPeriod.Find('-') then
                repeat
                    if FirstRec then
                        ExcludeClosingDateFilter :=
                          StrSubstNo('<>%1', ClosingDate(AccountingPeriod."Starting Date" - 1))
                    else
                        ExcludeClosingDateFilter :=
                          StrSubstNo('%1&<>%2', ExcludeClosingDateFilter, ClosingDate(AccountingPeriod."Starting Date" - 1));
                    FirstRec := false;
                until AccountingPeriod.Next() = 0;
        end;
    end;

    local procedure LookUpCode(DimOption: Enum "Analysis Dimension Option"; DimCode: Text[30]; "Code": Text[30])
    var
        GLAcc: Record "G/L Account";
        BusUnit: Record "Business Unit";
        DimVal: Record "Dimension Value";
        DimOption2: Option;
    begin
        case DimOption of
            DimOption::"G/L Account":
                begin
                    GLAcc.Get(Code);
                    PAGE.RunModal(PAGE::"G/L Account List", GLAcc);
                end;
            DimOption::Period:
                ;
            DimOption::"Business Unit":
                begin
                    BusUnit.Get(Code);
                    PAGE.RunModal(PAGE::"Business Unit List", BusUnit);
                end;
            DimOption::"Dimension 1", DimOption::"Dimension 2":
                begin
                    DimVal.SetRange("Dimension Code", DimCode);
                    DimVal.Get(DimCode, Code);

                    PAGE.RunModal(PAGE::"Dimension Value List", DimVal);
                end;
            else begin
                DimOption2 := DimOption.AsInteger();
                OnLookupCodeOnCaseElse(DimOption2, DimCode, Code);
                DimOption := "Analysis Dimension Option".FromInteger(DimOption2);
            end;
        end;
    end;

    local procedure SetCommonFilters(var TheGLAcc: Record "G/L Account")
    var
        DateFilter2: Text;
    begin
        Clear(TheGLAcc);
        if AnalysisByDimParameters."Date Filter" = '' then
            DateFilter2 := ExcludeClosingDateFilter
        else begin
            if AnalysisByDimParameters."Amount Type" = AnalysisByDimParameters."Amount Type"::"Net Change" then
                DateFilter2 := AnalysisByDimParameters."Date Filter"
            else begin
                TheGLAcc.SetFilter("Date Filter", AnalysisByDimParameters."Date Filter");
                DateFilter2 := StrSubstNo('..%1', TheGLAcc.GetRangeMax(TheGLAcc."Date Filter"));
            end;
            if ExcludeClosingDateFilter <> '' then
                DateFilter2 := StrSubstNo('%1 & %2', DateFilter2, ExcludeClosingDateFilter);
        end;
        TheGLAcc.Reset();
        if AnalysisByDimParameters."Account Filter" <> '' then
            TheGLAcc.SetFilter("No.", AnalysisByDimParameters."Account Filter")
        else
            TheGLAcc.SetRange(TheGLAcc."No.");
        if AnalysisByDimParameters."Account Filter" <> '' then
            TheGLAcc.Totaling := CopyStr(AnalysisByDimParameters."Account Filter", 1, MaxStrLen(TheGLAcc.Totaling))
        else
            if TheGLAcc."No." = '' then
                TheGLAcc.Totaling := StrSubstNo('>%1', '''''');
        TheGLAcc.SetFilter("Date Filter", DateFilter2);
        if AnalysisByDimParameters."Bus. Unit Filter" <> '' then
            TheGLAcc.SetFilter("Business Unit Filter", AnalysisByDimParameters."Bus. Unit Filter");
        if AnalysisByDimParameters."Dimension 1 Filter" <> '' then
            TheGLAcc.SetFilter("Global Dimension 1 Filter", GetDimValueTotaling(AnalysisByDimParameters."Dimension 1 Filter", GLSetup."Global Dimension 1 Code"));
        if AnalysisByDimParameters."Dimension 2 Filter" <> '' then
            TheGLAcc.SetFilter("Global Dimension 2 Filter", GetDimValueTotaling(AnalysisByDimParameters."Dimension 2 Filter", GLSetup."Global Dimension 2 Code"));
        if AnalysisByDimParameters."Budget Filter" = '' then
            TheGLAcc.SetRange(TheGLAcc."Budget Filter")
        else
            TheGLAcc.SetFilter("Budget Filter", AnalysisByDimParameters."Budget Filter");

        OnAfterSetCommonFilters(TheGLAcc, AnalysisByDimParameters);
    end;

    local procedure SetDimFilters(var TheGLAcc: Record "G/L Account"; LineOrColumn: Option Line,Column)
    var
        DimCodeBuf: Record "Dimension Code Buffer";
        DimOption: Enum "Analysis Dimension Option";
    begin
        if LineOrColumn = LineOrColumn::Line then begin
            DimCodeBuf := Rec;
            DimOption := AnalysisByDimParameters."Line Dim Option";
        end else begin
            DimCodeBuf := MatrixRecord;
            DimOption := AnalysisByDimParameters."Column Dim Option";
        end;
        case DimOption of
            DimOption::"G/L Account":
                begin
                    TheGLAcc."No." := DimCodeBuf.Code;
                    TheGLAcc.Totaling := DimCodeBuf.Totaling;
                end;
            DimOption::Period:
                begin
                    if AnalysisByDimParameters."Amount Type" = AnalysisByDimParameters."Amount Type"::"Net Change" then
                        TheGLAcc.SetRange(
                          "Date Filter", DimCodeBuf."Period Start", DimCodeBuf."Period End")
                    else
                        TheGLAcc.SetRange("Date Filter", 0D, DimCodeBuf."Period End");
                    if (AnalysisByDimParameters."Closing Entries" = AnalysisByDimParameters."Closing Entries"::Exclude) and (ExcludeClosingDateFilter <> '') then
                        TheGLAcc.SetFilter(
                          "Date Filter", TheGLAcc.GetFilter("Date Filter") +
                          '&' + ExcludeClosingDateFilter);
                end;
            DimOption::"Business Unit":
                TheGLAcc.SetRange("Business Unit Filter", DimCodeBuf.Code);
            DimOption::"Dimension 1":
                if DimCodeBuf.Totaling = '' then
                    TheGLAcc.SetRange("Global Dimension 1 Filter", DimCodeBuf.Code)
                else
                    TheGLAcc.SetFilter("Global Dimension 1 Filter", DimCodeBuf.Totaling);
            DimOption::"Dimension 2":
                if DimCodeBuf.Totaling = '' then
                    TheGLAcc.SetRange("Global Dimension 2 Filter", DimCodeBuf.Code)
                else
                    TheGLAcc.SetFilter("Global Dimension 2 Filter", DimCodeBuf.Totaling);
            else
                OnSetDimFiltersOnCaseElse(DimOption.AsInteger(), TheGLAcc, DimCodeBuf);
        end;
    end;

    local procedure DrillDown(SetColFilter: Boolean)
    var
        GLEntry: Record "G/L Entry";
        GLBudgetEntry: Record "G/L Budget Entry";
        IsHandled: Boolean;
    begin
        SetCommonFilters(GLAcc);
        SetDimFilters(GLAcc, 0);
        if SetColFilter then
            SetDimFilters(GLAcc, 1);

        IsHandled := false;
        OnBeforeDrillDown(SetColFilter, GLAcc, AnalysisByDimParameters, IsHandled, GLEntry, GLBudgetEntry);
        if IsHandled then
            exit;

        if AnalysisByDimParameters."Show Actual/Budgets" = AnalysisByDimParameters."Show Actual/Budgets"::"Actual Amounts" then begin
            if GLAcc."No." <> '' then
                GLEntry.SetRange("G/L Account No.", GLAcc."No.");
            if GLAcc.Totaling <> '' then
                GLEntry.SetFilter(GLEntry."G/L Account No.", GLAcc.Totaling);
            GLAcc.CopyFilter("Date Filter", GLEntry."Posting Date");
            GLAcc.CopyFilter("Global Dimension 1 Filter", GLEntry."Global Dimension 1 Code");
            GLAcc.CopyFilter("Global Dimension 2 Filter", GLEntry."Global Dimension 2 Code");
            GLAcc.CopyFilter("Business Unit Filter", GLEntry."Business Unit Code");
            if (GLEntry.GetFilter("Global Dimension 1 Code") <> '') or (GLEntry.GetFilter("Global Dimension 2 Code") <> '') or
               (GLEntry.GetFilter("Business Unit Code") <> '')
            then
                GLEntry.SetCurrentKey("G/L Account No.", "Business Unit Code", "Global Dimension 1 Code")
            else
                GLEntry.SetCurrentKey("G/L Account No.", "Posting Date");
            OnDrillDownOnBeforeRunGeneralLedgerEntriesPage(GLAcc, GLEntry);
            PAGE.Run(PAGE::"General Ledger Entries", GLEntry);
        end;
        if AnalysisByDimParameters."Show Actual/Budgets" = AnalysisByDimParameters."Show Actual/Budgets"::"Budgeted Amounts" then begin
            GLAcc.CopyFilter("Budget Filter", GLBudgetEntry."Budget Name");
            if GLAcc."No." <> '' then
                GLBudgetEntry.SetRange("G/L Account No.", GLAcc."No.");
            if GLAcc.Totaling <> '' then
                GLBudgetEntry.SetFilter(GLBudgetEntry."G/L Account No.", GLAcc.Totaling);
            GLAcc.CopyFilter("Date Filter", GLBudgetEntry.Date);
            GLAcc.CopyFilter("Global Dimension 1 Filter", GLBudgetEntry."Global Dimension 1 Code");
            GLAcc.CopyFilter("Global Dimension 2 Filter", GLBudgetEntry."Global Dimension 2 Code");
            GLAcc.CopyFilter("Business Unit Filter", GLBudgetEntry."Business Unit Code");
            if (GLBudgetEntry.GetFilter("Global Dimension 1 Code") <> '') or (GLBudgetEntry.GetFilter("Global Dimension 2 Code") <> '') or
               (GLBudgetEntry.GetFilter("Business Unit Code") <> '')
            then
                GLBudgetEntry.SetCurrentKey("Budget Name", "G/L Account No.", "Business Unit Code", "Global Dimension 1 Code")
            else
                GLBudgetEntry.SetCurrentKey("Budget Name", "G/L Account No.", Date);
            OnDrillDownOnBeforeRunGLBudgetEntriesPage(GLAcc, GLBudgetEntry);
            PAGE.Run(PAGE::"G/L Budget Entries", GLBudgetEntry);
        end;
    end;

    local procedure CalcAmount(SetColFilter: Boolean): Decimal
    var
        Amount: Decimal;
        ColumnCode: Code[20];
    begin
        if SetColFilter then
            ColumnCode := MatrixRecord.Code
        else
            ColumnCode := '';
        if TempDimensionCodeAmountBuffer.Get(Rec.Code, ColumnCode) then
            exit(TempDimensionCodeAmountBuffer.Amount);
        GLAcc.Reset();
        SetCommonFilters(GLAcc);
        SetDimFilters(GLAcc, 0);
        if SetColFilter then
            SetDimFilters(GLAcc, 1);
        OnCalcAmountOnAfterGLAccSetFilters(GLAcc, SetColFilter);
        case AnalysisByDimParameters."Show Actual/Budgets" of
            AnalysisByDimParameters."Show Actual/Budgets"::"Actual Amounts":
                Amount := CalcActualAmount();
            AnalysisByDimParameters."Show Actual/Budgets"::"Budgeted Amounts":
                Amount := CalcBudgAmount();
            AnalysisByDimParameters."Show Actual/Budgets"::Variance:
                Amount := CalcActualAmount() - CalcBudgAmount();
            AnalysisByDimParameters."Show Actual/Budgets"::"Variance%":
                begin
                    Amount := CalcBudgAmount();
                    if Amount <> 0 then
                        Amount := Round(100 * (CalcActualAmount() - Amount) / Amount);
                end;
            AnalysisByDimParameters."Show Actual/Budgets"::"Index%":
                begin
                    Amount := CalcBudgAmount();
                    if Amount <> 0 then
                        Amount := Round(100 * CalcActualAmount() / Amount);
                end;
        end;
        OnCalcAmountOnAfterAssignAmount(AnalysisByDimParameters, GLAcc, Amount);
        TempDimensionCodeAmountBuffer."Line Code" := Rec.Code;
        TempDimensionCodeAmountBuffer."Column Code" := ColumnCode;
        TempDimensionCodeAmountBuffer.Amount := Amount;
        TempDimensionCodeAmountBuffer.Insert();
        exit(Amount);
    end;

    local procedure CalcActualAmount(): Decimal
    var
        Amount: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcActualAmounts(GLAcc, AnalysisByDimParameters, Amount, IsHandled);
        if IsHandled then
            exit(Amount);

        if AnalysisByDimParameters."Show In Add. Currency" then
            case AnalysisByDimParameters."Show Amount Field" of
                AnalysisByDimParameters."Show Amount Field"::Amount:
                    begin
                        GLAcc.CalcFields("Additional-Currency Net Change");
                        Amount := GLAcc."Additional-Currency Net Change";
                    end;
                AnalysisByDimParameters."Show Amount Field"::"Debit Amount":
                    begin
                        GLAcc.CalcFields("Add.-Currency Debit Amount");
                        Amount := GLAcc."Add.-Currency Debit Amount";
                    end;
                AnalysisByDimParameters."Show Amount Field"::"Credit Amount":
                    begin
                        GLAcc.CalcFields("Add.-Currency Credit Amount");
                        Amount := GLAcc."Add.-Currency Credit Amount";
                    end;
            end
        else
            case AnalysisByDimParameters."Show Amount Field" of
                AnalysisByDimParameters."Show Amount Field"::Amount:
                    begin
                        GLAcc.CalcFields("Net Change");
                        Amount := GLAcc."Net Change";
                    end;
                AnalysisByDimParameters."Show Amount Field"::"Debit Amount":
                    begin
                        GLAcc.CalcFields("Debit Amount");
                        Amount := GLAcc."Debit Amount";
                    end;
                AnalysisByDimParameters."Show Amount Field"::"Credit Amount":
                    begin
                        GLAcc.CalcFields("Credit Amount");
                        Amount := GLAcc."Credit Amount";
                    end;
            end;

        OnAfterCalcActualAmount(GLAcc, AnalysisByDimParameters, Amount);

        exit(Amount);
    end;

    local procedure CalcBudgAmount(): Decimal
    var
        Amount: Decimal;
    begin
        if AnalysisByDimParameters."Budget Filter" = '' then
            GLAcc.SetRange("Budget Filter")
        else
            GLAcc.SetFilter("Budget Filter", AnalysisByDimParameters."Budget Filter");
        GLAcc.CalcFields("Budgeted Amount");
        Amount := GLAcc."Budgeted Amount";
        case AnalysisByDimParameters."Show Amount Field" of
            AnalysisByDimParameters."Show Amount Field"::"Debit Amount":
                if Amount < 0 then
                    Amount := 0;
            AnalysisByDimParameters."Show Amount Field"::"Credit Amount":
                if Amount > 0 then
                    Amount := 0
                else
                    Amount := -Amount;
        end;
        if (Amount <> 0) and AnalysisByDimParameters."Show In Add. Currency" then begin
            if GLAcc.GetFilter("Date Filter") = '' then
                CurrExchDate := WorkDate()
            else
                CurrExchDate := GLAcc.GetRangeMin("Date Filter");
            Amount :=
              CurrExchRate.ExchangeAmtLCYToFCY(
                CurrExchDate, GLSetup."Additional Reporting Currency", Amount,
                CurrExchRate.ExchangeRate(CurrExchDate, GLSetup."Additional Reporting Currency"));
        end;

        OnAfterCalcBudgetAmount(GLAcc, AnalysisByDimParameters, Amount);

        exit(Amount);
    end;

    local procedure MATRIX_UpdateMatrixRecord(MATRIX_NewColumnOrdinal: Integer)
    begin
        MATRIX_ColumnOrdinal := MATRIX_NewColumnOrdinal;
        MatrixRecord.SetPosition(MATRIX_PrimKeyFirstCol);
        MATRIX_OnFindRecord('=');
        if MATRIX_ColumnOrdinal <> 1 then
            MATRIX_OnNextRecord(MATRIX_ColumnOrdinal - 1);
    end;

    local procedure MATRIX_OnFindRecord(Which: Text[1024]): Boolean
    begin
        exit(FindRec(AnalysisByDimParameters."Column Dim Option", MatrixRecord, Which));
    end;

    local procedure MATRIX_OnNextRecord(Steps: Integer): Integer
    begin
        exit(NextRec(AnalysisByDimParameters."Column Dim Option", MatrixRecord, Steps));
    end;

    local procedure MATRIX_OnAfterGetRecord()
    begin
        MatrixAmount := MatrixMgt.RoundAmount(CalcAmount(true), AnalysisByDimParameters."Rounding Factor");

        MATRIX_CellData[MATRIX_ColumnOrdinal] := MatrixAmount;
    end;

    procedure Load(NewAnalysisByDimParameters: Record "Analysis by Dim. Parameters"; NewLineDimCode: Text[30]; NewColumnDimCode: Text[30]; NewMATRIX_ColumnCaptions: array[32] of Text[1024]; NewPrimKeyFirstCol: Text[1024]; CurrSetLength: Integer)
    begin
        FindPeriod('');
        AnalysisByDimParameters := NewAnalysisByDimParameters;
        LineDimCode := NewLineDimCode;
        ColumnDimCode := NewColumnDimCode;
        MATRIX_CurrSetLength := CurrSetLength;
        MATRIX_PrimKeyFirstCol := NewPrimKeyFirstCol;
        PeriodInitialized := true;
        CopyArray(MATRIX_ColumnCaptions, NewMATRIX_ColumnCaptions, 1);
        RoundingFactorFormatString := MatrixMgt.FormatRoundingFactor(AnalysisByDimParameters."Rounding Factor", false);
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

    local procedure FormatLine()
    begin
        Emphasize := Rec."Show in Bold";
    end;

    local procedure LoadDefault()
    begin
        FindPeriod('');
        PeriodInitialized := true;
        MATRIX_CurrSetLength := ArrayLen(MATRIX_ColumnCaptions);
        GenerateColumnCaptions();
        RoundingFactorFormatString := MatrixMgt.FormatRoundingFactor(AnalysisByDimParameters."Rounding Factor"::None, false);
    end;

    local procedure GenerateColumnCaptions()
    var
        DimCodeBuffer: Record "Dimension Code Buffer";
        Found: Boolean;
        Which: Text[30];
    begin
        MATRIX_CurrSetLength := 0;
        Clear(MATRIX_ColumnCaptions);

        if (AnalysisByDimParameters."Column Dim Option" = AnalysisByDimParameters."Column Dim Option"::Period) and
           (AnalysisByDimParameters."Period Type" <> AnalysisByDimParameters."Period Type"::"Accounting Period") and
           (AnalysisByDimParameters."Date Filter" = '')
        then begin
            Evaluate(DimCodeBuffer.Code, Format(WorkDate()));
            Which := '=><';
        end else
            Which := '-';
        Found := FindRec(AnalysisByDimParameters."Column Dim Option", DimCodeBuffer, Which);

        MATRIX_PrimKeyFirstCol := DimCodeBuffer.GetPosition();

        if Found then
            repeat
                MATRIX_CurrSetLength := MATRIX_CurrSetLength + 1;
                MATRIX_ColumnCaptions[MATRIX_CurrSetLength] := DimCodeBuffer.Code;
            until (MATRIX_CurrSetLength = MATRIX_NoOfMatrixColumns) or (NextRec(AnalysisByDimParameters."Column Dim Option", DimCodeBuffer, 1) <> 1);
    end;

    local procedure FormatStr(): Text
    begin
        exit(RoundingFactorFormatString);
    end;

    local procedure GetDimValueTotaling(DimValueFilter: Text; DimensionCode: Code[20]): Text
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        DimensionManagement.ResolveDimValueFilter(DimValueFilter, DimensionCode);
        exit(DimValueFilter);
    end;

    local procedure InitRecord(var DimCodeBuf: Record "Dimension Code Buffer"; DimOption: Enum "Analysis Dimension Option")
    var
        GLAccount: Record "G/L Account";
    begin
        case DimOption of
            DimOption::"G/L Account":
                begin
                    if AnalysisByDimParameters."Account Filter" <> '' then
                        GLAccount.SetFilter("No.", AnalysisByDimParameters."Account Filter");
                    if GLAccount.FindSet() then
                        repeat
                            CopyGLAccToBuf(GLAccount, DimCodeBuf);
                            DimCodeBuf.Insert();
                        until GLAccount.Next() = 0;
                end;
        end;
        if Rec.FindFirst() then;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterFindRec(DimOption: Option "G/L Account",Period,"Business Unit","Dimension 1","Dimension 2",Fund,"Dimension 3","Dimension 4","Dimension 5","Dimension 6","Dimension 7","Dimension 8"; var DimCodeBuf: Record "Dimension Code Buffer"; Which: Text; var Found: Boolean; AnalysisbyDimParameters: Record "Analysis by Dim. Parameters")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterNextRec(DimOption: Option "G/L Account",Period,"Business Unit","Dimension 1","Dimension 2",Fund,"Dimension 3","Dimension 4","Dimension 5","Dimension 6","Dimension 7","Dimension 8"; var DimCodeBuf: Record "Dimension Code Buffer"; Steps: Integer; var ResultSteps: Integer; AnalysisbyDimParameters: Record "Analysis by Dim. Parameters")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterSetCommonFilters(var GLAccount: Record "G/L Account"; AnalysisByDimParameters: Record "Analysis by Dim. Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcActualAmount(var GLAccount: Record "G/L Account"; AnalysisByDimParameters: Record "Analysis by Dim. Parameters"; var Amount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcBudgetAmount(var GLAccount: Record "G/L Account"; AnalysisByDimParameters: Record "Analysis by Dim. Parameters"; var Amount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcActualAmounts(var GLAcc: Record "G/L Account"; AnalysisByDimParameters: Record "Analysis by Dim. Parameters"; var Amount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDrillDown(SetColFilter: Boolean; var GLAcc: Record "G/L Account"; AnalysisByDimParameters: Record "Analysis by Dim. Parameters"; var IsHandled: Boolean; var GLEntry: Record "G/L Entry"; var GLBudgetEntry: Record "G/L Budget Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDimCodeToOption(DimCode: Text[30]; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeFindRec(DimOption: Enum "Analysis Dimension Option"; var DimensionValue: Record "Dimension Value"; var GLAccount: Record "G/L Account"; var DimensionCodeBuffer: Record "Dimension Code Buffer"; Which: Text[1024]; var Found: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeNextRec(DimOption: Enum "Analysis Dimension Option"; var DimensionValue: Record "Dimension Value"; var GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCalcAmountOnAfterGLAccSetFilters(var GLAcc: Record "G/L Account"; SetColFilter: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnDrillDownOnBeforeRunGeneralLedgerEntriesPage(var GLAcc: Record "G/L Account"; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnDrillDownOnBeforeRunGLBudgetEntriesPage(var GLAcc: Record "G/L Account"; var GLBudgetEntry: Record "G/L Budget Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupCodeOnCaseElse(var DimOption: Option "G/L Account",Period,"Business Unit","Dimension 1","Dimension 2",Fund,"Dimension 3","Dimension 4","Dimension 5","Dimension 6","Dimension 7","Dimension 8"; DimCode: Text[30]; Code: Text[30])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnSetDimFiltersOnCaseElse(DimOption: Option "G/L Account",Period,"Business Unit","Dimension 1","Dimension 2",Fund,"Dimension 3","Dimension 4","Dimension 5","Dimension 6","Dimension 7","Dimension 8"; var TheGLAcc: Record "G/L Account"; var DimCodeBuf: Record "Dimension Code Buffer")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCalcAmountOnAfterAssignAmount(var AnalysisByDimParameters: Record "Analysis by Dim. Parameters"; var GLAccount: record "G/L Account"; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyDimValueToBuf(var DimVal: Record "Dimension Value"; var DimCodeBuf: Record "Dimension Code Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGLAccToBuf(GLAcc: Record "G/L Account"; var DimCodeBuf: Record "Dimension Code Buffer")
    begin
    end;

}
