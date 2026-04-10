// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Budget;

using Microsoft.CostAccounting.Account;
using Microsoft.CostAccounting.Ledger;
using Microsoft.Finance.Analysis;
using Microsoft.Foundation.Enums;
using System.Utilities;

page 1131 "Cost Budget per Period Matrix"
{
    Caption = 'Cost Budget per Period Matrix';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPart;
    RefreshOnActivate = true;
    ShowFilter = false;
    SourceTable = "Cost Type";

    layout
    {
        area(content)
        {
            repeater(Control12)
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
                    ToolTip = 'Specifies the name of the cost type.';
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

                    trigger OnValidate()
                    begin
                        UpdateAmount(1);
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

                    trigger OnValidate()
                    begin
                        UpdateAmount(2);
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

                    trigger OnValidate()
                    begin
                        UpdateAmount(3);
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

                    trigger OnValidate()
                    begin
                        UpdateAmount(4);
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

                    trigger OnValidate()
                    begin
                        UpdateAmount(5);
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

                    trigger OnValidate()
                    begin
                        UpdateAmount(6);
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

                    trigger OnValidate()
                    begin
                        UpdateAmount(7);
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

                    trigger OnValidate()
                    begin
                        UpdateAmount(8);
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

                    trigger OnValidate()
                    begin
                        UpdateAmount(9);
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

                    trigger OnValidate()
                    begin
                        UpdateAmount(10);
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

                    trigger OnValidate()
                    begin
                        UpdateAmount(11);
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

                    trigger OnValidate()
                    begin
                        UpdateAmount(12);
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
                                  "Cost Object Filter" = field("Cost Object Filter"),
                                  "Budget Filter" = field("Budget Filter");
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
                    ToolTip = 'View the entries for the cost budget per period.';
                }
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("&Copy Cost Budget to Cost Budget")
                {
                    ApplicationArea = CostAccounting;
                    Caption = '&Copy Cost Budget to Cost Budget';
                    Ellipsis = true;
                    Image = CopyCostBudget;
                    ToolTip = 'Copy cost budget amounts within a budget or from budget to budget. You can copy a budget several times and enter a factor to increase or reduce the budget amounts.';

                    trigger OnAction()
                    begin
                        Rec.CopyFilter("Budget Filter", CostBudgetEntry."Budget Name");
                        Rec.CopyFilter("Cost Center Filter", CostBudgetEntry."Cost Center Code");
                        Rec.CopyFilter("Cost Object Filter", CostBudgetEntry."Cost Object Code");
                        REPORT.RunModal(REPORT::"Copy Cost Budget", true, false, CostBudgetEntry);
                    end;
                }
                action("Copy &G/L Budget to Cost Budget")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Copy &G/L Budget to Cost Budget';
                    Ellipsis = true;
                    Image = CopyGLtoCostBudget;
                    RunObject = Report "Copy G/L Budget to Cost Acctg.";
                    ToolTip = 'Copy general ledger budget figures to the cost accounting budget. You can also enter budgets for the cost centers and cost objects in the general ledger.';
                }
                action("Copy Cost &Budget to G/L Budget")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Copy Cost &Budget to G/L Budget';
                    Image = CopyCosttoGLBudget;
                    RunPageOnRec = true;
                    ToolTip = 'Copy selected cost budget entries into the general ledger. Multiplication factors and multiple copies with date offsets are also possible.';

                    trigger OnAction()
                    begin
                        Rec.CopyFilter("Budget Filter", CostBudgetEntry."Budget Name");
                        Rec.CopyFilter("Cost Center Filter", CostBudgetEntry."Cost Center Code");
                        Rec.CopyFilter("Cost Object Filter", CostBudgetEntry."Cost Object Code");
                        REPORT.RunModal(REPORT::"Copy Cost Acctg. Budget to G/L", true, false, CostBudgetEntry);
                    end;
                }
                separator(Action9)
                {
                }
                action("Compress Budget &Entries")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Compress Budget &Entries';
                    ToolTip = 'Compresses cost budget entries so that they take up less space in the database.';

                    trigger OnAction()
                    begin
                        CostBudgetEntry.CompressBudgetEntries(Rec.GetFilter("Budget Filter"));
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        MATRIX_CurrentColumnOrdinal: Integer;
    begin
        for MATRIX_CurrentColumnOrdinal := 1 to CurrentNoOfMatrixColumn do
            MATRIX_OnAfterGetRecord(MATRIX_CurrentColumnOrdinal);
        NameIndent := Rec.Indentation;
        Emphasize := Rec.Type <> Rec.Type::"Cost Type";
    end;

    var
        MatrixRecords: array[32] of Record Date;
        CostBudgetEntry: Record "Cost Budget Entry";
        MatrixMgt: Codeunit "Matrix Management";
        CostCenterFilter: Code[20];
        CostObjectFilter: Code[20];
        BudgetFilter: Code[10];
        MATRIX_ColumnCaption: array[12] of Text[80];
        RoundingFactorFormatString: Text;
        AmtType: Enum "Analysis Amount Type";
        RoundingFactor: Enum "Analysis Rounding Factor";
        CurrentNoOfMatrixColumn: Integer;
        MATRIX_CellData: array[32] of Decimal;
        Emphasize: Boolean;
        NameIndent: Integer;
#pragma warning disable AA0074
        Text000: Label 'Set View As to Net Change before you edit entries.';
#pragma warning disable AA0470
        Text001: Label '%1 or %2 must not be blank.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        CurrRegNo: Integer;

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

    procedure LoadMatrix(NewMatrixColumns: array[32] of Text[80]; var NewMatrixRecords: array[32] of Record Date; NewCurrentNoOfMatrixColumns: Integer; NewCostCenterFilter: Code[20]; NewCostObjectFilter: Code[20]; NewBudgetFilter: Code[10]; NewRoundingFactor: Enum "Analysis Rounding Factor"; NewAmountType: Enum "Analysis Amount Type")
    var
        i: Integer;
    begin
        for i := 1 to 12 do begin
            if NewMatrixColumns[i] = '' then
                MATRIX_ColumnCaption[i] := ' '
            else
                MATRIX_ColumnCaption[i] := NewMatrixColumns[i];
            MatrixRecords[i] := NewMatrixRecords[i];
        end;
        if MATRIX_ColumnCaption[1] = '' then; // To make this form pass preCAL test

        if NewCurrentNoOfMatrixColumns > ArrayLen(MATRIX_CellData) then
            CurrentNoOfMatrixColumn := ArrayLen(MATRIX_CellData)
        else
            CurrentNoOfMatrixColumn := NewCurrentNoOfMatrixColumns;
        CostCenterFilter := NewCostCenterFilter;
        CostObjectFilter := NewCostObjectFilter;
        BudgetFilter := NewBudgetFilter;
        RoundingFactor := NewRoundingFactor;
        AmtType := NewAmountType;
        RoundingFactorFormatString := MatrixMgt.FormatRoundingFactor(NewRoundingFactor, false);

        CurrPage.Update(false);
    end;

    local procedure MATRIX_OnDrillDown(ColumnID: Integer)
    var
        CostBudgetEntries: Page "Cost Budget Entries";
    begin
        OnBeforeMATRIX_OnDrillDown(CostBudgetEntry);

        SetDateFilter(ColumnID);
        CostBudgetEntry.SetCurrentKey("Budget Name", "Cost Type No.", "Cost Center Code", "Cost Object Code", Date);
        if Rec.Type in [Rec.Type::Total, Rec.Type::"End-Total"] then
            CostBudgetEntry.SetFilter("Cost Type No.", Rec.Totaling)
        else
            CostBudgetEntry.SetRange("Cost Type No.", Rec."No.");
        CostBudgetEntry.SetFilter("Cost Center Code", CostCenterFilter);
        CostBudgetEntry.SetFilter("Cost Object Code", CostObjectFilter);
        CostBudgetEntry.SetFilter("Budget Name", BudgetFilter);
        CostBudgetEntry.SetFilter(Date, Rec.GetFilter("Date Filter"));
        CostBudgetEntry.FilterGroup(26);
        CostBudgetEntry.SetFilter(Date, '..%1|%1..', MatrixRecords[ColumnID]."Period Start");
        CostBudgetEntry.FilterGroup(0);

        CostBudgetEntries.SetCurrRegNo(CurrRegNo);
        CostBudgetEntries.SetTableView(CostBudgetEntry);
        CostBudgetEntries.RunModal();
        CurrRegNo := CostBudgetEntries.GetCurrRegNo();
        CurrPage.Update(false);
    end;

    local procedure MATRIX_OnAfterGetRecord(ColumnID: Integer)
    begin
        SetRecordFilters(ColumnID);
        Rec.CalcFields("Budget Amount");
        MATRIX_CellData[ColumnID] := MatrixMgt.RoundAmount(Rec."Budget Amount", RoundingFactor);

        OnAfterMATRIX_OnAfterGetRecord(Rec, MATRIX_CellData, ColumnID, RoundingFactor);
    end;

    local procedure UpdateAmount(ColumnID: Integer)
    begin
        if AmtType <> AmtType::"Net Change" then
            Error(Text000);

        if (CostCenterFilter = '') and (CostObjectFilter = '') then
            Error(Text001, Rec.FieldCaption("Cost Center Filter"), Rec.FieldCaption("Cost Object Filter"));

        SetRecordFilters(ColumnID);
        Rec.CalcFields("Budget Amount");
        InsertMatrixCostBudgetEntry(CurrRegNo, ColumnID);
        OnUpdateAmountOnBeforeUpdatePage(Rec);
        CurrPage.Update(false);
    end;

    local procedure SetRecordFilters(ColumnID: Integer)
    begin
        SetDateFilter(ColumnID);
        Rec.SetFilter("Cost Center Filter", CostCenterFilter);
        Rec.SetFilter("Cost Object Filter", CostObjectFilter);
        Rec.SetFilter("Budget Filter", BudgetFilter);

        OnAfterSetRecordFilters(Rec);
    end;

    local procedure InsertMatrixCostBudgetEntry(var RegNo: Integer; ColumnID: Integer)
    var
        MatrixCostBudgetEntry: Record "Cost Budget Entry";
    begin
        MatrixCostBudgetEntry.SetCostBudgetRegNo(RegNo);
        MatrixCostBudgetEntry.Init();
        MatrixCostBudgetEntry."Budget Name" := BudgetFilter;
        MatrixCostBudgetEntry."Cost Type No." := Rec."No.";
        MatrixCostBudgetEntry.Date := MatrixRecords[ColumnID]."Period Start";
        MatrixCostBudgetEntry."Cost Center Code" := CostCenterFilter;
        MatrixCostBudgetEntry."Cost Object Code" := CostObjectFilter;
        MatrixCostBudgetEntry.Amount := MATRIX_CellData[ColumnID] - Rec."Budget Amount";
        OnBeforeMatrixCostBudgetEntryInsert(MatrixCostBudgetEntry, Rec);
        MatrixCostBudgetEntry.Insert(true);
        RegNo := MatrixCostBudgetEntry.GetCostBudgetRegNo();
    end;

    local procedure FormatStr(): Text
    begin
        exit(RoundingFactorFormatString);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetRecordFilters(var CostType: Record "Cost Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMatrixCostBudgetEntryInsert(var MatrixCostBudgetEntry: Record "Cost Budget Entry"; var CostType: Record "Cost Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMATRIX_OnDrillDown(var CostBudgetEntry: Record "Cost Budget Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAmountOnBeforeUpdatePage(var CostType: Record "Cost Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMATRIX_OnAfterGetRecord(var CostType: Record "Cost Type"; var MATRIX_CellData: array[12] of Decimal; ColumnID: Integer; RoundingFactor: Enum "Analysis Rounding Factor")
    begin
    end;
}

