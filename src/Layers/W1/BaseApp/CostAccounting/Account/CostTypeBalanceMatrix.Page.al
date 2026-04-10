// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Account;

using Microsoft.CostAccounting.Ledger;
using Microsoft.Finance.Analysis;
using Microsoft.Foundation.Enums;
using System.Utilities;

page 1130 "Cost Type Balance Matrix"
{
    Caption = 'Cost Type Balance Matrix';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPart;
    RefreshOnActivate = true;
    SourceTable = "Cost Type";

    layout
    {
        area(content)
        {
            repeater(Control6)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = CostAccounting;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = CostAccounting;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the name of the cost type balance matrix.';
                }
                field(Column1; MATRIX_CellData[1])
                {
                    ApplicationArea = CostAccounting;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[1];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(1);
                    end;
                }
                field(Column2; MATRIX_CellData[2])
                {
                    ApplicationArea = CostAccounting;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[2];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(2);
                    end;
                }
                field(Column3; MATRIX_CellData[3])
                {
                    ApplicationArea = CostAccounting;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[3];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(3);
                    end;
                }
                field(Column4; MATRIX_CellData[4])
                {
                    ApplicationArea = CostAccounting;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[4];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(4);
                    end;
                }
                field(Column5; MATRIX_CellData[5])
                {
                    ApplicationArea = CostAccounting;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[5];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(5);
                    end;
                }
                field(Column6; MATRIX_CellData[6])
                {
                    ApplicationArea = CostAccounting;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[6];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(6);
                    end;
                }
                field(Column7; MATRIX_CellData[7])
                {
                    ApplicationArea = CostAccounting;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[7];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(7);
                    end;
                }
                field(Column8; MATRIX_CellData[8])
                {
                    ApplicationArea = CostAccounting;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[8];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(8);
                    end;
                }
                field(Column9; MATRIX_CellData[9])
                {
                    ApplicationArea = CostAccounting;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[9];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(9);
                    end;
                }
                field(Column10; MATRIX_CellData[10])
                {
                    ApplicationArea = CostAccounting;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[10];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(10);
                    end;
                }
                field(Column11; MATRIX_CellData[11])
                {
                    ApplicationArea = CostAccounting;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[11];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(11);
                    end;
                }
                field(Column12; MATRIX_CellData[12])
                {
                    ApplicationArea = CostAccounting;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[12];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(12);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Cost Type")
            {
                Caption = '&Cost Type';
                Image = Costs;
                action("&Card")
                {
                    ApplicationArea = CostAccounting;
                    Caption = '&Card';
                    Image = EditLines;
                    RunObject = Page "Cost Type Card";
                    RunPageLink = "No." = field("No."),
                                  "Date Filter" = field("Date Filter"),
                                  "Cost Center Filter" = field("Cost Center Filter"),
                                  "Cost Object Filter" = field("Cost Object Filter");
                    RunPageOnRec = true;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit detailed information for the cost type.';
                }
                action("E&ntries")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'E&ntries';
                    Image = Entries;
                    RunObject = Page "Cost Entries";
                    RunPageLink = "Cost Type No." = field("No.");
                    RunPageView = sorting("Cost Type No.", "Posting Date");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the entries for the cost type balance matrix.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        MATRIX_CurrentColumnOrdinal: Integer;
    begin
        for MATRIX_CurrentColumnOrdinal := 1 to MATRIX_CurrentNoOfMatrixColumn do
            MATRIX_OnAfterGetRecord(MATRIX_CurrentColumnOrdinal);
        NameIndent := Rec.Indentation;
        Emphasize := Rec.Type <> Rec.Type::"Cost Type";
    end;

    var
        MatrixRecords: array[12] of Record Date;
        MatrixMgt: Codeunit "Matrix Management";
        CostCenterFilter: Code[20];
        CostObjectFilter: Code[20];
        MATRIX_ColumnCaption: array[12] of Text[80];
        RoundingFactorFormatString: Text;
        AmtType: Enum "Analysis Amount Type";
        RoundingFactor: Enum "Analysis Rounding Factor";
        MATRIX_CurrentNoOfMatrixColumn: Integer;
        MATRIX_CellData: array[12] of Decimal;
        Emphasize: Boolean;
        NameIndent: Integer;

    local procedure SetDateFilter(MATRIX_ColumnOrdinal: Integer)
    begin
        if AmtType = AmtType::"Net Change" then
            if MatrixRecords[MATRIX_ColumnOrdinal]."Period Start" = MatrixRecords[MATRIX_ColumnOrdinal]."Period End" then
                Rec.SetRange("Date Filter", MatrixRecords[MATRIX_ColumnOrdinal]."Period Start")
            else
                Rec.SetRange("Date Filter", MatrixRecords[MATRIX_ColumnOrdinal]."Period Start", MatrixRecords[MATRIX_ColumnOrdinal]."Period End")
        else
            Rec.SetRange("Date Filter", 0D, MatrixRecords[MATRIX_ColumnOrdinal]."Period End");
    end;

    procedure LoadMatrix(MatrixColumns1: array[12] of Text[80]; var MatrixRecords1: array[12] of Record Date; CurrentNoOfMatrixColumns: Integer; NewCostCenterFilter: Code[20]; NewCostObjectFilter: Code[20]; NewRoundingFactor: Enum "Analysis Rounding Factor"; NewAmountType: Enum "Analysis Amount Type")
    var
        i: Integer;
    begin
        for i := 1 to 12 do begin
            if MatrixColumns1[i] = '' then
                MATRIX_ColumnCaption[i] := ' '
            else
                MATRIX_ColumnCaption[i] := MatrixColumns1[i];
            MatrixRecords[i] := MatrixRecords1[i];
        end;
        if MATRIX_ColumnCaption[1] = '' then; // To make this form pass preCAL test

        if CurrentNoOfMatrixColumns > ArrayLen(MATRIX_CellData) then
            MATRIX_CurrentNoOfMatrixColumn := ArrayLen(MATRIX_CellData)
        else
            MATRIX_CurrentNoOfMatrixColumn := CurrentNoOfMatrixColumns;
        CostCenterFilter := NewCostCenterFilter;
        CostObjectFilter := NewCostObjectFilter;
        RoundingFactor := NewRoundingFactor;
        AmtType := NewAmountType;
        RoundingFactorFormatString := MatrixMgt.FormatRoundingFactor(RoundingFactor, false);

        CurrPage.Update(false);
    end;

    local procedure MATRIX_OnDrillDown(ColumnID: Integer)
    var
        CostEntry: Record "Cost Entry";
    begin
        SetDateFilter(ColumnID);
        if Rec.Type in [Rec.Type::Total, Rec.Type::"End-Total"] then
            CostEntry.SetFilter("Cost Type No.", Rec.Totaling)
        else
            CostEntry.SetRange("Cost Type No.", Rec."No.");
        CostEntry.SetFilter("Cost Center Code", CostCenterFilter);
        CostEntry.SetFilter("Cost Object Code", CostObjectFilter);
        CostEntry.SetFilter("Posting Date", Rec.GetFilter("Date Filter"));
        OnMATRIX_OnDrillDownOnBeforePageRun(CostEntry);
        PAGE.Run(0, CostEntry);
    end;

    local procedure MATRIX_OnAfterGetRecord(ColumnID: Integer)
    begin
        SetFilters(ColumnID);
        Rec.CalcFields("Net Change");
        MATRIX_CellData[ColumnID] := MatrixMgt.RoundAmount(Rec."Net Change", RoundingFactor);

        OnAfterMATRIX_OnAfterGetRecord(Rec, MATRIX_CellData, ColumnID, RoundingFactor);
    end;

    local procedure SetFilters(ColumnID: Integer)
    begin
        SetDateFilter(ColumnID);
        Rec.SetFilter("Cost Center Filter", CostCenterFilter);
        Rec.SetFilter("Cost Object Filter", CostObjectFilter);
        OnAfterSetFilters(Rec);
    end;

    local procedure FormatStr(): Text
    begin
        exit(RoundingFactorFormatString);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilters(var CostType: Record "Cost Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMATRIX_OnDrillDownOnBeforePageRun(var CostEntry: Record "Cost Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMATRIX_OnAfterGetRecord(var CostType: Record "Cost Type"; var MATRIX_CellData: array[12] of Decimal; ColumnID: Integer; RoundingFactor: Enum "Analysis Rounding Factor")
    begin
    end;
}

