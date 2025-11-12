// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using System.Text;
using System.Utilities;

page 113 Budget
{
    Caption = 'Budget';
    DataCaptionExpression = BudgetName;
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = ListPlus;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(BudgetName; BudgetName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Budget Name';
                    TableRelation = "G/L Budget Name";
                    ToolTip = 'Specifies the name of the budget.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        GLBudgetNames: Page "G/L Budget Names";
                    begin
                        GLBudgetNames.LookupMode := true;
                        GLBudgetNames.SetRecord(GLBudgetName);
                        if GLBudgetNames.RunModal() = ACTION::LookupOK then begin
                            GLBudgetNames.GetRecord(GLBudgetName);
                            BudgetName := GLBudgetName.Name;
                            Text := GLBudgetName.Name;
                            ValidateBudgetName();
                            ValidateLineDimCode();
                            ValidateColumnDimCode();
                            UpdateMatrixSubform();
                            exit(true);
                        end;
                        ValidateBudgetName();
                        ValidateLineDimCode();
                        ValidateColumnDimCode();
                        CurrPage.Update();
                        exit(false);
                    end;

                    trigger OnValidate()
                    begin
                        ValidateBudgetName();
                        ValidateLineDimCode();
                        ValidateColumnDimCode();

                        UpdateMatrixSubform();
                    end;
                }
                field(LineDimCode; LineDimCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'Show as Lines';
                    ToolTip = 'Specifies which values you want to show as lines in the window. This allows you to see the same matrix window from various perspectives, especially when you use both the Show as Lines field and the Show as Columns field.';
                    Importance = Promoted;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        NewCode: Text[30];
                    begin
                        NewCode := GetDimSelection(LineDimCode);
                        if NewCode = LineDimCode then
                            exit(false);

                        Text := NewCode;
                        LineDimCode := NewCode;
                        ValidateLineDimCode();
                        LineDimCodeOnAfterValidate();
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        if (UpperCase(LineDimCode) = UpperCase(ColumnDimCode)) and (LineDimCode <> '') then begin
                            ColumnDimCode := '';
                            ValidateColumnDimCode();
                        end;
                        ValidateLineDimCode();
                        GenerateColumnCaptions(Enum::"Matrix Page Step Type"::Initial);
                        LineDimCodeOnAfterValidate();
                    end;
                }
                field(ColumnDimCode; ColumnDimCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'Show as Columns';
                    ToolTip = 'Specifies which values you want to show as columns in the window. This allows you to see the same matrix window from various perspectives, especially when you use both the Show as Lines field and the Show as Columns field.';
                    Importance = Promoted;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        NewCode: Text[30];
                        "Matrix Page Step Type": Enum "Matrix Page Step Type";
                    begin
                        NewCode := GetDimSelection(ColumnDimCode);
                        if NewCode = ColumnDimCode then
                            exit(false);

                        Text := NewCode;
                        ColumnDimCode := NewCode;
                        ValidateColumnDimCode();
                        GenerateColumnCaptions("Matrix Page Step Type"::Initial);
                        ColumnDimCodeOnAfterValidate();
                        exit(true);
                    end;

                    trigger OnValidate()
                    var
                        "Matrix Page Step Type": Enum "Matrix Page Step Type";
                    begin
                        if (UpperCase(LineDimCode) = UpperCase(ColumnDimCode)) and (LineDimCode <> '') then begin
                            LineDimCode := '';
                            ValidateLineDimCode();
                        end;
                        ValidateColumnDimCode();
                        GenerateColumnCaptions("Matrix Page Step Type"::Initial);
                        ColumnDimCodeOnAfterValidate();
                    end;
                }
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Suite;
                    Caption = 'View by';
                    Enabled = PeriodTypeEnable;
                    ToolTip = 'Specifies by which period amounts are displayed.';
                    Importance = Promoted;

                    trigger OnValidate()
                    begin
                        FindPeriod('');
                        PeriodTypeOnAfterValidate();
                    end;
                }
                field(RoundingFactor; RoundingFactor)
                {
                    ApplicationArea = Suite;
                    Caption = 'Rounding Factor';
                    ToolTip = 'Specifies the factor that is used to round the amounts.';
                    Importance = Promoted;

                    trigger OnValidate()
                    begin
                        UpdateMatrixSubform();
                    end;
                }
                field(ShowColumnName; ShowColumnName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Show Column Name';
                    ToolTip = 'Specifies that the names of columns are shown in the matrix window.';

                    trigger OnValidate()
                    begin
                        ShowColumnNameOnPush();
                    end;
                }
            }
            part(MatrixForm; "Budget Matrix")
            {
                ApplicationArea = Suite;
            }
            group(Filters)
            {
                Caption = 'Filters';
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = Suite;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies the dates that will be used to filter the amounts in the window.';
                    Importance = Promoted;

                    trigger OnValidate()
                    begin
                        ValidateDateFilter(DateFilter);
                    end;
                }
                field(GLAccFilter; GLAccFilter)
                {
                    ApplicationArea = Suite;
                    Caption = 'G/L Account Filter';
                    ToolTip = 'Specifies the G/L accounts for which you will see information in the window.';
                    Importance = Promoted;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        GLAccList: Page "G/L Account List";
                    begin
                        GLAccList.LookupMode(true);
                        if not (GLAccList.RunModal() = ACTION::LookupOK) then
                            exit(false);

                        Text := GLAccList.GetSelectionFilter();
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        GLAccFilterOnAfterValidate();
                    end;
                }
                field(GLAccCategory; GLAccCategoryFilter)
                {
                    ApplicationArea = Suite;
                    Caption = 'G/L Account Category Filter';
                    ToolTip = 'Specifies the category of the G/L account for which you will see information in the window.';
                    Importance = Promoted;

                    trigger OnValidate()
                    begin
                        ValidateGLAccCategoryFilter();
                    end;
                }
                field(IncomeBalGLAccFilter; IncomeBalanceGLAccFilter)
                {
                    ApplicationArea = Suite;
                    Caption = 'Income/Balance G/L Account Filter';
                    ToolTip = 'Specifies the type of the G/L account for which you will see information in the window.';
                    Importance = Promoted;

                    trigger OnValidate()
                    begin
                        ValidateIncomeBalanceGLAccFilter();
                    end;
                }
                field(GlobalDim1Filter; GlobalDim1Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,3,1';
                    Caption = 'Global Dimension 1 Filter';
                    Enabled = GlobalDim1FilterEnable;
                    ToolTip = 'Specifies by which global dimension data is shown. Global dimensions are the dimensions that you analyze most frequently. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Importance = Promoted;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        DimensionValue: Record "Dimension Value";
                    begin
                        exit(DimensionValue.LookUpDimFilter(GLSetup."Global Dimension 1 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        GlobalDim1FilterOnAfterValidate();
                    end;
                }
                field(GlobalDim2Filter; GlobalDim2Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,3,2';
                    Caption = 'Global Dimension 2 Filter';
                    Enabled = GlobalDim2FilterEnable;
                    ToolTip = 'Specifies by which global dimension data is shown. Global dimensions are the dimensions that you analyze most frequently. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Importance = Promoted;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        DimensionValue: Record "Dimension Value";
                    begin
                        exit(DimensionValue.LookUpDimFilter(GLSetup."Global Dimension 2 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        GlobalDim2FilterOnAfterValidate();
                    end;
                }
                field(BudgetDim1Filter; BudgetDim1Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = GetCaptionClass(1);
                    Caption = 'Budget Dimension 1 Filter';
                    Enabled = BudgetDim1FilterEnable;
                    ToolTip = 'Specifies a filter by a budget dimension. You can specify four additional dimensions on each budget that you create.';
                    Importance = Promoted;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        DimensionValue: Record "Dimension Value";
                    begin
                        exit(DimensionValue.LookUpDimFilter(GLBudgetName."Budget Dimension 1 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        BudgetDim1FilterOnAfterValidate();
                    end;
                }
                field(BudgetDim2Filter; BudgetDim2Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = GetCaptionClass(2);
                    Caption = 'Budget Dimension 2 Filter';
                    Enabled = BudgetDim2FilterEnable;
                    ToolTip = 'Specifies a filter by a budget dimension. You can specify four additional dimensions on each budget that you create.';
                    Importance = Promoted;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        DimensionValue: Record "Dimension Value";
                    begin
                        exit(DimensionValue.LookUpDimFilter(GLBudgetName."Budget Dimension 2 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        BudgetDim2FilterOnAfterValidate();
                    end;
                }
                field(BudgetDim3Filter; BudgetDim3Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = GetCaptionClass(3);
                    Caption = 'Budget Dimension 3 Filter';
                    Enabled = BudgetDim3FilterEnable;
                    ToolTip = 'Specifies a filter by a budget dimension. You can specify four additional dimensions on each budget that you create.';
                    Importance = Promoted;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        DimensionValue: Record "Dimension Value";
                    begin
                        exit(DimensionValue.LookUpDimFilter(GLBudgetName."Budget Dimension 3 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        BudgetDim3FilterOnAfterValidate();
                    end;
                }
                field(BudgetDim4Filter; BudgetDim4Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = GetCaptionClass(4);
                    Caption = 'Budget Dimension 4 Filter';
                    Enabled = BudgetDim4FilterEnable;
                    ToolTip = 'Specifies a filter by a budget dimension. You can specify four additional dimensions on each budget that you create.';
                    Importance = Promoted;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        DimensionValue: Record "Dimension Value";
                    begin
                        exit(DimensionValue.LookUpDimFilter(GLBudgetName."Budget Dimension 4 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        BudgetDim4FilterOnAfterValidate();
                    end;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Balance")
            {
                Caption = '&Balance';
                Image = Balance;
                action(GLBalanceBudget)
                {
                    ApplicationArea = Suite;
                    Caption = 'G/L Account Balance B&udget by period';
                    Image = ChartOfAccounts;
                    ToolTip = 'Open a summary of the debit and credit balances for the current budget.';

                    trigger OnAction()
                    var
                        GLAccount: Record "G/L Account";
                    begin
                        GLAccount.SetFilter("Budget Filter", BudgetName);
                        if BusUnitFilter <> '' then
                            GLAccount.SetFilter("Business Unit Filter", BusUnitFilter);
                        if GLAccFilter <> '' then
                            GLAccount.SetFilter("No.", GLAccFilter);
                        if DateFilter <> '' then
                            GLAccount.SetFilter("Date Filter", DateFilter);
                        case IncomeBalanceGLAccFilter of
                            IncomeBalanceGLAccFilter::"Balance Sheet":
                                GLAccount.SetRange("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
                            IncomeBalanceGLAccFilter::"Income Statement":
                                GLAccount.SetRange("Income/Balance", GLAccount."Income/Balance"::"Income Statement");
                        end;
                        if GLAccCategoryFilter <> GLAccCategoryFilter::" " then
                            GLAccount.SetRange("Account Category", GLAccCategoryFilter);
                        if GlobalDim1Filter <> '' then
                            GLAccount.SetFilter("Global Dimension 1 Filter", GlobalDim1Filter);
                        if GlobalDim2Filter <> '' then
                            GLAccount.SetFilter("Global Dimension 2 Filter", GlobalDim2Filter);
                        PAGE.Run(PAGE::"G/L Balance/Budget", GLAccount);
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Copy Budget")
                {
                    ApplicationArea = Suite;
                    Caption = 'Copy Budget';
                    Ellipsis = true;
                    Image = CopyBudget;
                    ToolTip = 'Create a copy of the current budget based on a general ledger entry or a general ledger budget entry.';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Copy G/L Budget", true, false);
                        CurrPage.Update();
                    end;
                }
                action("Delete Budget")
                {
                    ApplicationArea = Suite;
                    Caption = 'Delete Budget';
                    Image = Delete;
                    ToolTip = 'Delete the current budget.';

                    trigger OnAction()
                    begin
                        DeleteBudget();
                    end;
                }
                separator(Action1102601004)
                {
                    Caption = '';
                }
                action("Export to Excel")
                {
                    ApplicationArea = Suite;
                    Caption = 'Export to Excel';
                    Ellipsis = true;
                    Image = ExportToExcel;
                    ToolTip = 'Export all or part of the budget to Excel for further analysis. If you make changes in Excel, you can import the budget afterwards.';

                    trigger OnAction()
                    var
                        GLBudgetEntry: Record "G/L Budget Entry";
                    begin
                        GLBudgetEntry.SetFilter("Budget Name", BudgetName);
                        GLBudgetEntry.SetFilter("Business Unit Code", BusUnitFilter);
                        GLBudgetEntry.SetFilter("G/L Account No.", GLAccFilter);
                        GLBudgetEntry.SetFilter("Global Dimension 1 Code", GlobalDim1Filter);
                        GLBudgetEntry.SetFilter("Global Dimension 2 Code", GlobalDim2Filter);
                        GLBudgetEntry.SetFilter("Budget Dimension 1 Code", BudgetDim1Filter);
                        GLBudgetEntry.SetFilter("Budget Dimension 2 Code", BudgetDim2Filter);
                        GLBudgetEntry.SetFilter("Budget Dimension 3 Code", BudgetDim3Filter);
                        GLBudgetEntry.SetFilter("Budget Dimension 4 Code", BudgetDim4Filter);
                        REPORT.Run(REPORT::"Export Budget to Excel", true, false, GLBudgetEntry);
                    end;
                }
                action("Import from Excel")
                {
                    ApplicationArea = Suite;
                    Caption = 'Import from Excel';
                    Ellipsis = true;
                    Image = ImportExcel;
                    ToolTip = 'Import a budget that you exported to Excel earlier.';

                    trigger OnAction()
                    var
                        ImportBudgetfromExcel: Report "Import Budget from Excel";
                    begin
                        ImportBudgetfromExcel.SetParameters(BudgetName, 0);
                        ImportBudgetfromExcel.RunModal();
                        UpdateMatrixSubform();
                    end;
                }
                separator(Action1102601007)
                {
                }
                action("Reverse Lines and Columns")
                {
                    ApplicationArea = Suite;
                    Caption = 'Reverse Lines and Columns';
                    Image = Undo;
                    ToolTip = 'Change the display of the matrix by inverting the values in the Show as Lines and Show as Columns fields.';

                    trigger OnAction()
                    var
                        TempDimCode: Text[30];
                    begin
                        TempDimCode := ColumnDimCode;
                        ColumnDimCode := LineDimCode;
                        LineDimCode := TempDimCode;
                        ValidateLineDimCode();
                        ValidateColumnDimCode();

                        GenerateColumnCaptions(Enum::"Matrix Page Step Type"::Initial);
                        UpdateMatrixSubform();
                    end;
                }
            }
            group(ReportGroup)
            {
                Caption = 'Report';
                Image = "Report";
                action(ReportTrialBalance)
                {
                    ApplicationArea = Suite;
                    Caption = 'Trial Balance/Budget';
                    Image = "Report";
                    ToolTip = 'View budget details for the specified period.';

                    trigger OnAction()
                    begin
                        REPORT.Run(REPORT::"Trial Balance/Budget");
                    end;
                }
                action(ReportBudget)
                {
                    ApplicationArea = Suite;
                    Caption = 'Budget';
                    Image = "Report";
                    ToolTip = 'View budget details for the specified period.';

                    trigger OnAction()
                    var
                        GLAccount: Record "G/L Account";
                        Budget: Report "Budget";
                    begin
                        GLAccount.SetRange("Budget Filter", BudgetName);
                        Budget.SetRoundingFactor(RoundingFactor);
                        Budget.SetTableView(GLAccount);
                        Budget.Run();
                    end;
                }
            }
            action("Next Period")
            {
                ApplicationArea = Suite;
                Caption = 'Next Period';
                Image = NextRecord;
                ToolTip = 'Show the information based on the next period. If you set the View by field to Day, the date filter changes to the day before.';

                trigger OnAction()
                begin
                    if (LineDimType = LineDimType::Period) or (ColumnDimType = ColumnDimType::Period) then
                        exit;
                    FindPeriod('>');
                    CurrPage.Update();
                    UpdateMatrixSubform();
                end;
            }
            action("Previous Period")
            {
                ApplicationArea = Suite;
                Caption = 'Previous Period';
                Image = PreviousRecord;
                ToolTip = 'Show the information based on the previous period. If you set the View by field to Day, the date filter changes to the day before.';

                trigger OnAction()
                begin
                    if (LineDimType = LineDimType::Period) or (ColumnDimType = ColumnDimType::Period) then
                        exit;
                    FindPeriod('<');
                    CurrPage.Update();
                    UpdateMatrixSubform();
                end;
            }
            action("Previous Set")
            {
                ApplicationArea = Suite;
                Caption = 'Previous Set';
                Image = PreviousSet;
                ToolTip = 'Go to the previous set of data.';

                trigger OnAction()
                begin
                    GenerateColumnCaptions(Enum::"Matrix Page Step Type"::Previous);
                    UpdateMatrixSubform();
                end;
            }
            action("Previous Column")
            {
                ApplicationArea = Suite;
                Caption = 'Previous Column';
                Image = PreviousRecord;
                ToolTip = 'Go to the previous column.';

                trigger OnAction()
                begin
                    GenerateColumnCaptions(Enum::"Matrix Page Step Type"::PreviousColumn);
                    UpdateMatrixSubform();
                end;
            }
            action("Next Column")
            {
                ApplicationArea = Suite;
                Caption = 'Next Column';
                Image = NextRecord;
                ToolTip = 'Go to the next column.';

                trigger OnAction()
                begin
                    GenerateColumnCaptions(Enum::"Matrix Page Step Type"::NextColumn);
                    UpdateMatrixSubform();
                end;
            }
            action("Next Set")
            {
                ApplicationArea = Suite;
                Caption = 'Next Set';
                Image = NextSet;
                ToolTip = 'Go to the next set of data.';

                trigger OnAction()
                begin
                    GenerateColumnCaptions(Enum::"Matrix Page Step Type"::Next);
                    UpdateMatrixSubform();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Import from Excel_Promoted"; "Import from Excel")
                {
                }
                actionref("Export to Excel_Promoted"; "Export to Excel")
                {
                }
                actionref("Copy Budget_Promoted"; "Copy Budget")
                {
                }
                actionref("Delete Budget_Promoted"; "Delete Budget")
                {
                }
                actionref("Reverse Lines and Columns_Promoted"; "Reverse Lines and Columns")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Period', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref("Previous Period_Promoted"; "Previous Period")
                {
                }
                actionref("Next Period_Promoted"; "Next Period")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Column', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref("Previous Column_Promoted"; "Previous Column")
                {
                }
                actionref("Next Column_Promoted"; "Next Column")
                {
                }
                actionref("Previous Set_Promoted"; "Previous Set")
                {
                }
                actionref("Next Set_Promoted"; "Next Set")
                {
                }
            }
            group(Category_Category6)
            {
                Caption = 'Budget', Comment = 'Generated from the PromotedActionCategories property index 5.';

            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';

                actionref(ReportBudget_Promoted; ReportBudget)
                {
                }
                actionref(ReportTrialBalance_Promoted; ReportTrialBalance)
                {
                }
                actionref(GLBalanceBudget_Promoted; GLBalanceBudget)
                {
                }
            }
        }
    }

    trigger OnInit()
    begin
        BudgetDim4FilterEnable := true;
        BudgetDim3FilterEnable := true;
        BudgetDim2FilterEnable := true;
        BudgetDim1FilterEnable := true;
        PeriodTypeEnable := true;
        GlobalDim2FilterEnable := true;
        GlobalDim1FilterEnable := true;
    end;

    trigger OnOpenPage()
    var
        GLAcc: Record "G/L Account";
        "Matrix Page Step Type": Enum "Matrix Page Step Type";
        IsHandled: Boolean;
    begin
        OnBeforeOnOpenPage();

        if GLAccBudgetBuf.GetFilter("Global Dimension 1 Filter") <> '' then
            GlobalDim1Filter := GLAccBudgetBuf.GetFilter("Global Dimension 1 Filter");
        if GLAccBudgetBuf.GetFilter("Global Dimension 2 Filter") <> '' then
            GlobalDim2Filter := GLAccBudgetBuf.GetFilter("Global Dimension 2 Filter");

        GLSetup.Get();

        GlobalDim1FilterEnable :=
          (GLSetup."Global Dimension 1 Code" <> '') and
          (GLAccBudgetBuf.GetFilter("Global Dimension 1 Filter") = '');
        GlobalDim2FilterEnable :=
          (GLSetup."Global Dimension 2 Code" <> '') and
          (GLAccBudgetBuf.GetFilter("Global Dimension 2 Filter") = '');

        if GLAccBudgetBuf.GetFilter("G/L Account Filter") <> '' then
            GLAccFilter := GLAccBudgetBuf.GetFilter("G/L Account Filter");

        ValidateBudgetName();

        if LineDimCode = '' then
            LineDimCode := GLAcc.TableCaption();
        if ColumnDimCode = '' then
            ColumnDimCode := Text001;

        LineDimType := DimCodeToType(LineDimCode);
        ColumnDimType := DimCodeToType(ColumnDimCode);

        if (NewBudgetName <> '') and (NewBudgetName <> BudgetName) then begin
            BudgetName := NewBudgetName;
            ValidateBudgetName();
            ValidateLineDimCode();
            ValidateColumnDimCode();
        end;

        IsHandled := false;
        OnOpenPageOnBeforeSetPeriodTypeMonth(PeriodType, IsHandled);
        if not IsHandled then
            PeriodType := PeriodType::Month;

        IsHandled := false;
        OnOpenPageOnBeforeIncomeBalanceGLAccFilter(IncomeBalanceGLAccFilter, IsHandled);
        if not IsHandled then begin
            IncomeBalanceGLAccFilter := IncomeBalanceGLAccFilter::"Income Statement";
            if DateFilter = '' then
                ValidateDateFilter(Format(CalcDate('<-CY>', Today)) + '..' + Format(CalcDate('<CY>', Today)));
        end;

        FindPeriod('');
        GenerateColumnCaptions("Matrix Page Step Type"::Initial);

        UpdateMatrixSubform();
    end;

    var
        GLSetup: Record "General Ledger Setup";
        GLBudgetName: Record "G/L Budget Name";
        PrevGLBudgetName: Record "G/L Budget Name";
        MATRIX_MatrixRecords: array[32] of Record "Dimension Code Buffer";
        MATRIX_CaptionSet: array[32] of Text[80];
        MATRIX_CaptionRange: Text;
        FirstColumn: Text;
        LastColumn: Text;
        MATRIX_PrimKeyFirstCaptionInCu: Text;
        MATRIX_CurrentNoOfColumns: Integer;
#pragma warning disable AA0074
        Text001: Label 'Period';
        Text003: Label 'Do you want to delete the budget entries shown?';
        Text004: Label 'DEFAULT';
        Text005: Label 'Default budget';
#pragma warning disable AA0470
        Text006: Label '%1 is not a valid line definition.';
        Text007: Label '%1 is not a valid column definition.';
#pragma warning restore AA0470
        Text008: Label '1,6,,Budget Dimension 1 Filter';
        Text009: Label '1,6,,Budget Dimension 2 Filter';
        Text010: Label '1,6,,Budget Dimension 3 Filter';
        Text011: Label '1,6,,Budget Dimension 4 Filter';
#pragma warning restore AA0074
        InternalDateFilter: Text[30];
        GlobalDim1FilterEnable: Boolean;
        GlobalDim2FilterEnable: Boolean;
        PeriodTypeEnable: Boolean;
        BudgetDim1FilterEnable: Boolean;
        BudgetDim2FilterEnable: Boolean;
        BudgetDim3FilterEnable: Boolean;
        BudgetDim4FilterEnable: Boolean;

    protected var
        GLAccBudgetBuf: Record "G/L Acc. Budget Buffer";
        BudgetName: Code[10];
        NewBudgetName: Code[10];
        LineDimType: Enum "G/L Budget Matrix Dimensions";
        ColumnDimType: Enum "G/L Budget Matrix Dimensions";
        LineDimCode: Text[30];
        ColumnDimCode: Text[30];
        PeriodType: Enum "Analysis Period Type";
        RoundingFactor: Enum "Analysis Rounding Factor";
        GLAccCategoryFilter: Enum "G/L Account Category";
        IncomeBalanceGLAccFilter: Enum "G/L Account Income/Balance";
        ShowColumnName: Boolean;
        BusUnitFilter: Text;
        DateFilter: Text[30];
        GLAccFilter: Text;
        GlobalDim1Filter: Text;
        GlobalDim2Filter: Text;
        BudgetDim1Filter: Text;
        BudgetDim2Filter: Text;
        BudgetDim3Filter: Text;
        BudgetDim4Filter: Text;

    protected procedure GenerateColumnCaptions(StepType: Enum "Matrix Page Step Type")
    var
        MATRIX_PeriodRecords: array[32] of Record Date;
        BusUnit: Record "Business Unit";
        GLAccount: Record "G/L Account";
        MatrixMgt: Codeunit "Matrix Management";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        IncomeBalFieldRef: FieldRef;
        GLAccCategoryFieldRef: FieldRef;
        i: Integer;
    begin
        Clear(MATRIX_CaptionSet);
        Clear(MATRIX_MatrixRecords);
        FirstColumn := '';
        LastColumn := '';
        MATRIX_CurrentNoOfColumns := 12;

        if ColumnDimCode = '' then
            exit;

        case ColumnDimCode of
            Text001:  // Period
                begin
                    MatrixMgt.GeneratePeriodMatrixData(
                      StepType.AsInteger(), MATRIX_CurrentNoOfColumns, ShowColumnName,
                      PeriodType, DateFilter, MATRIX_PrimKeyFirstCaptionInCu,
                      MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns, MATRIX_PeriodRecords);
                    for i := 1 to MATRIX_CurrentNoOfColumns do begin
                        MATRIX_MatrixRecords[i]."Period Start" := MATRIX_PeriodRecords[i]."Period Start";
                        MATRIX_MatrixRecords[i]."Period End" := MATRIX_PeriodRecords[i]."Period End";
                    end;
                    FirstColumn := Format(MATRIX_PeriodRecords[1]."Period Start");
                    LastColumn := Format(MATRIX_PeriodRecords[MATRIX_CurrentNoOfColumns]."Period End");
                    PeriodTypeEnable := true;
                end;
            GLAccount.TableCaption:
                begin
                    Clear(MATRIX_CaptionSet);
                    RecRef.GetTable(GLAccount);
                    RecRef.SetTable(GLAccount);
                    if GLAccFilter <> '' then begin
                        FieldRef := RecRef.Field(GLAccount.FieldNo("No."));
                        FieldRef.SetFilter(GLAccFilter);
                    end;
                    if IncomeBalanceGLAccFilter <> IncomeBalanceGLAccFilter::" " then begin
                        IncomeBalFieldRef := RecRef.FieldIndex(GLAccount.FieldNo("Income/Balance"));
                        case IncomeBalanceGLAccFilter of
                            IncomeBalanceGLAccFilter::"Balance Sheet":
                                IncomeBalFieldRef.SetRange(GLAccount."Income/Balance"::"Balance Sheet");
                            IncomeBalanceGLAccFilter::"Income Statement":
                                IncomeBalFieldRef.SetRange(GLAccount."Income/Balance"::"Income Statement");
                        end;
                    end;
                    if GLAccCategoryFilter <> GLAccCategoryFilter::" " then begin
                        GLAccCategoryFieldRef := RecRef.FieldIndex(GLAccount.FieldNo("Account Category"));
                        GLAccCategoryFieldRef.SetRange(GLAccCategoryFilter);
                    end;
                    MatrixMgt.GenerateMatrixData(
                      RecRef, StepType.AsInteger(), 12, 1,
                      MATRIX_PrimKeyFirstCaptionInCu, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                    for i := 1 to MATRIX_CurrentNoOfColumns do
                        MATRIX_MatrixRecords[i].Code := CopyStr(MATRIX_CaptionSet[i], 1, MaxStrLen(MATRIX_MatrixRecords[i].Code));
                    if ShowColumnName then
                        MatrixMgt.GenerateMatrixData(
                          RecRef, Enum::"Matrix Page Step Type"::Same.AsInteger(), 12, GLAccount.FieldNo(Name),
                          MATRIX_PrimKeyFirstCaptionInCu, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                end;
            BusUnit.TableCaption:
                begin
                    Clear(MATRIX_CaptionSet);
                    RecRef.GetTable(BusUnit);
                    RecRef.SetTable(BusUnit);
                    if BusUnitFilter <> '' then begin
                        FieldRef := RecRef.Field(BusUnit.FieldNo(Code));
                        FieldRef.SetFilter(BusUnitFilter);
                    end;
                    MatrixMgt.GenerateMatrixData(
                      RecRef, StepType.AsInteger(), 12, 1,
                      MATRIX_PrimKeyFirstCaptionInCu, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                    for i := 1 to MATRIX_CurrentNoOfColumns do
                        MATRIX_MatrixRecords[i].Code := CopyStr(MATRIX_CaptionSet[i], 1, MaxStrLen(MATRIX_MatrixRecords[i].Code));
                    if ShowColumnName then
                        MatrixMgt.GenerateMatrixData(
                          RecRef, Enum::"Matrix Page Step Type"::Same.AsInteger(), 12, BusUnit.FieldNo(Name),
                          MATRIX_PrimKeyFirstCaptionInCu, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                end;
            // Apply dimension filter
            GLSetup."Global Dimension 1 Code":
                MatrixMgt.GenerateDimColumnCaption(
                  GLSetup."Global Dimension 1 Code",
                  GlobalDim1Filter, StepType.AsInteger(), MATRIX_PrimKeyFirstCaptionInCu, FirstColumn, LastColumn,
                  MATRIX_CaptionSet, MATRIX_MatrixRecords, MATRIX_CurrentNoOfColumns, ShowColumnName, MATRIX_CaptionRange);
            GLSetup."Global Dimension 2 Code":
                MatrixMgt.GenerateDimColumnCaption(
                  GLSetup."Global Dimension 2 Code",
                  GlobalDim2Filter, StepType.AsInteger(), MATRIX_PrimKeyFirstCaptionInCu, FirstColumn, LastColumn,
                  MATRIX_CaptionSet, MATRIX_MatrixRecords, MATRIX_CurrentNoOfColumns, ShowColumnName, MATRIX_CaptionRange);
            GLBudgetName."Budget Dimension 1 Code":
                MatrixMgt.GenerateDimColumnCaption(
                  GLBudgetName."Budget Dimension 1 Code",
                  BudgetDim1Filter, StepType.AsInteger(), MATRIX_PrimKeyFirstCaptionInCu, FirstColumn, LastColumn,
                  MATRIX_CaptionSet, MATRIX_MatrixRecords, MATRIX_CurrentNoOfColumns, ShowColumnName, MATRIX_CaptionRange);
            GLBudgetName."Budget Dimension 2 Code":
                MatrixMgt.GenerateDimColumnCaption(
                  GLBudgetName."Budget Dimension 2 Code",
                  BudgetDim2Filter, StepType.AsInteger(), MATRIX_PrimKeyFirstCaptionInCu, FirstColumn, LastColumn,
                  MATRIX_CaptionSet, MATRIX_MatrixRecords, MATRIX_CurrentNoOfColumns, ShowColumnName, MATRIX_CaptionRange);
            GLBudgetName."Budget Dimension 3 Code":
                MatrixMgt.GenerateDimColumnCaption(
                  GLBudgetName."Budget Dimension 3 Code",
                  BudgetDim3Filter, StepType.AsInteger(), MATRIX_PrimKeyFirstCaptionInCu, FirstColumn, LastColumn,
                  MATRIX_CaptionSet, MATRIX_MatrixRecords, MATRIX_CurrentNoOfColumns, ShowColumnName, MATRIX_CaptionRange);
            GLBudgetName."Budget Dimension 4 Code":
                MatrixMgt.GenerateDimColumnCaption(
                  GLBudgetName."Budget Dimension 4 Code",
                  BudgetDim4Filter, StepType.AsInteger(), MATRIX_PrimKeyFirstCaptionInCu, FirstColumn, LastColumn,
                  MATRIX_CaptionSet, MATRIX_MatrixRecords, MATRIX_CurrentNoOfColumns, ShowColumnName, MATRIX_CaptionRange);
        end;
        OnAfterGenerateColumnCaptions(ColumnDimCode, StepType, MATRIX_PrimKeyFirstCaptionInCu, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns, MATRIX_MatrixRecords, ShowColumnName);
    end;

    local procedure DimCodeToType(DimCode: Text[30]) Result: Enum "G/L Budget Matrix Dimensions"
    var
        BusUnit: Record "Business Unit";
        GLAcc: Record "G/L Account";
    begin
        case DimCode of
            '':
                Result := Enum::"G/L Budget Matrix Dimensions"::Undefined;
            GLAcc.TableCaption():
                Result := Enum::"G/L Budget Matrix Dimensions"::"G/L Account";
            Text001:
                Result := Enum::"G/L Budget Matrix Dimensions"::Period;
            BusUnit.TableCaption():
                Result := Enum::"G/L Budget Matrix Dimensions"::"Business Unit";
            GLSetup."Global Dimension 1 Code":
                Result := Enum::"G/L Budget Matrix Dimensions"::"Global Dimension 1";
            GLSetup."Global Dimension 2 Code":
                Result := Enum::"G/L Budget Matrix Dimensions"::"Global Dimension 2";
            GLBudgetName."Budget Dimension 1 Code":
                Result := Enum::"G/L Budget Matrix Dimensions"::"Budget Dimension 1";
            GLBudgetName."Budget Dimension 2 Code":
                Result := Enum::"G/L Budget Matrix Dimensions"::"Budget Dimension 2";
            GLBudgetName."Budget Dimension 3 Code":
                Result := Enum::"G/L Budget Matrix Dimensions"::"Budget Dimension 3";
            GLBudgetName."Budget Dimension 4 Code":
                Result := Enum::"G/L Budget Matrix Dimensions"::"Budget Dimension 4";
            else
                Result := Enum::"G/L Budget Matrix Dimensions"::Undefined;
        end;
        OnAfterDimCodeToType(DimCode, Result);
    end;

    protected procedure FindPeriod(SearchText: Code[10])
    var
        GLAcc: Record "G/L Account";
        Calendar: Record Date;
        PeriodPageMgt: Codeunit PeriodPageManagement;
    begin
        if DateFilter <> '' then begin
            Calendar.SetFilter("Period Start", DateFilter);
            if not PeriodPageMgt.FindDate('+', Calendar, PeriodType) then
                PeriodPageMgt.FindDate('+', Calendar, PeriodType::Day);
            Calendar.SetRange("Period Start");
        end;
        PeriodPageMgt.FindDate(SearchText, Calendar, PeriodType);
        GLAcc.SetRange("Date Filter", Calendar."Period Start", Calendar."Period End");
        if GLAcc.GetRangeMin("Date Filter") = GLAcc.GetRangeMax("Date Filter") then
            GLAcc.SetRange("Date Filter", GLAcc.GetRangeMin("Date Filter"));
        InternalDateFilter := GLAcc.GetFilter("Date Filter");
        if (LineDimType <> LineDimType::Period) and (ColumnDimType <> ColumnDimType::Period) then
            DateFilter := InternalDateFilter;
    end;

    local procedure GetDimSelection(OldDimSelCode: Text[30]): Text[30]
    var
        GLAcc: Record "G/L Account";
        BusUnit: Record "Business Unit";
        DimSelection: Page "Dimension Selection";
    begin
        DimSelection.InsertDimSelBuf(false, GLAcc.TableCaption(), GLAcc.TableCaption());
        DimSelection.InsertDimSelBuf(false, BusUnit.TableCaption(), BusUnit.TableCaption());
        DimSelection.InsertDimSelBuf(false, Text001, Text001);
        if GLSetup."Global Dimension 1 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, GLSetup."Global Dimension 1 Code", '');
        if GLSetup."Global Dimension 2 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, GLSetup."Global Dimension 2 Code", '');
        if GLBudgetName."Budget Dimension 1 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, GLBudgetName."Budget Dimension 1 Code", '');
        if GLBudgetName."Budget Dimension 2 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, GLBudgetName."Budget Dimension 2 Code", '');
        if GLBudgetName."Budget Dimension 3 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, GLBudgetName."Budget Dimension 3 Code", '');
        if GLBudgetName."Budget Dimension 4 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, GLBudgetName."Budget Dimension 4 Code", '');

        OnGetDimSelectionOnBeforeDimSelectionLookup(DimSelection);

        DimSelection.LookupMode := true;
        if DimSelection.RunModal() = ACTION::LookupOK then
            exit(DimSelection.GetDimSelCode());

        exit(OldDimSelCode);
    end;

    local procedure DeleteBudget()
    var
        GLBudgetEntry: Record "G/L Budget Entry";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if ConfirmManagement.GetResponseOrDefault(Text003, true) then begin
            GLBudgetEntry.SetRange("Budget Name", BudgetName);
            if BusUnitFilter <> '' then
                GLBudgetEntry.SetFilter("Business Unit Code", BusUnitFilter);
            if GLAccFilter <> '' then
                GLBudgetEntry.SetFilter("G/L Account No.", GLAccFilter);
            if DateFilter <> '' then
                GLBudgetEntry.SetFilter(Date, DateFilter);
            if GlobalDim1Filter <> '' then
                GLBudgetEntry.SetFilter("Global Dimension 1 Code", GlobalDim1Filter);
            if GlobalDim2Filter <> '' then
                GLBudgetEntry.SetFilter("Global Dimension 2 Code", GlobalDim2Filter);
            if BudgetDim1Filter <> '' then
                GLBudgetEntry.SetFilter("Budget Dimension 1 Code", BudgetDim1Filter);
            if BudgetDim2Filter <> '' then
                GLBudgetEntry.SetFilter("Budget Dimension 2 Code", BudgetDim2Filter);
            if BudgetDim3Filter <> '' then
                GLBudgetEntry.SetFilter("Budget Dimension 3 Code", BudgetDim3Filter);
            if BudgetDim4Filter <> '' then
                GLBudgetEntry.SetFilter("Budget Dimension 4 Code", BudgetDim4Filter);
            OnDeleteBudgetOnAfterGLBudgetEntrySetFilters(GLBudgetEntry);
            GLBudgetEntry.SetCurrentKey(GLBudgetEntry."Entry No.");
            if GLBudgetEntry.FindFirst() then
                UpdateAnalysisView.SetLastBudgetEntryNo(GLBudgetEntry."Entry No." - 1);
            GLBudgetEntry.SetCurrentKey(GLBudgetEntry."Budget Name");
            GLBudgetEntry.DeleteAll(true);
        end;
    end;

    local procedure ValidateBudgetName()
    begin
        GLBudgetName.Name := BudgetName;
        if not GLBudgetName.Find('=<>') then begin
            GLBudgetName.Init();
            GLBudgetName.Name := Text004;
            GLBudgetName.Description := Text005;
            GLBudgetName.Insert();
        end;
        BudgetName := GLBudgetName.Name;
        GLAccBudgetBuf.SetRange("Budget Filter", BudgetName);
        if PrevGLBudgetName.Name <> '' then begin
            if GLBudgetName."Budget Dimension 1 Code" <> PrevGLBudgetName."Budget Dimension 1 Code" then
                BudgetDim1Filter := '';
            if GLBudgetName."Budget Dimension 2 Code" <> PrevGLBudgetName."Budget Dimension 2 Code" then
                BudgetDim2Filter := '';
            if GLBudgetName."Budget Dimension 3 Code" <> PrevGLBudgetName."Budget Dimension 3 Code" then
                BudgetDim3Filter := '';
            if GLBudgetName."Budget Dimension 4 Code" <> PrevGLBudgetName."Budget Dimension 4 Code" then
                BudgetDim4Filter := '';
        end;
        GLAccBudgetBuf.SetFilter("Budget Dimension 1 Filter", BudgetDim1Filter);
        GLAccBudgetBuf.SetFilter("Budget Dimension 2 Filter", BudgetDim2Filter);
        GLAccBudgetBuf.SetFilter("Budget Dimension 3 Filter", BudgetDim3Filter);
        GLAccBudgetBuf.SetFilter("Budget Dimension 4 Filter", BudgetDim4Filter);
        BudgetDim1FilterEnable := (GLBudgetName."Budget Dimension 1 Code" <> '');
        BudgetDim2FilterEnable := (GLBudgetName."Budget Dimension 2 Code" <> '');
        BudgetDim3FilterEnable := (GLBudgetName."Budget Dimension 3 Code" <> '');
        BudgetDim4FilterEnable := (GLBudgetName."Budget Dimension 4 Code" <> '');

        PrevGLBudgetName := GLBudgetName;

        OnAfterValidateBudgetName(GLAccBudgetBuf, GLBudgetName);
    end;

    local procedure ValidateLineDimCode()
    begin
        ClearDimCodeOnChange(LineDimCode, Text006);
        LineDimType := DimCodeToType(LineDimCode);
        DateFilter := InternalDateFilter;
        if (LineDimType <> LineDimType::Period) and (ColumnDimType <> ColumnDimType::Period) then begin
            DateFilter := InternalDateFilter;
            if StrPos(DateFilter, '&') > 1 then
                DateFilter := CopyStr(DateFilter, 1, StrPos(DateFilter, '&') - 1);
        end else
            DateFilter := '';
    end;

    local procedure ValidateColumnDimCode()
    begin
        ClearDimCodeOnChange(ColumnDimCode, Text007);
        ColumnDimType := DimCodeToType(ColumnDimCode);
        DateFilter := InternalDateFilter;
        if (LineDimType <> LineDimType::Period) and (ColumnDimType <> ColumnDimType::Period) then begin
            DateFilter := InternalDateFilter;
            if StrPos(DateFilter, '&') > 1 then
                DateFilter := CopyStr(DateFilter, 1, StrPos(DateFilter, '&') - 1);
        end else
            DateFilter := '';
    end;

    local procedure ClearDimCodeOnChange(var DimCode: Text[30]; MessageText: Text)
    var
        BusUnit: Record "Business Unit";
        GLAcc: Record "G/L Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeClearDimCodeOnChange(DimCode, IsHandled);
        if IsHandled then
            exit;

        if (UpperCase(DimCode) <> UpperCase(GLAcc.TableCaption())) and
            (UpperCase(DimCode) <> UpperCase(BusUnit.TableCaption())) and
            (UpperCase(DimCode) <> UpperCase(Text001)) and
            (UpperCase(DimCode) <> GLBudgetName."Budget Dimension 1 Code") and
            (UpperCase(DimCode) <> GLBudgetName."Budget Dimension 2 Code") and
            (UpperCase(DimCode) <> GLBudgetName."Budget Dimension 3 Code") and
            (UpperCase(DimCode) <> GLBudgetName."Budget Dimension 4 Code") and
            (UpperCase(DimCode) <> GLSetup."Global Dimension 1 Code") and
            (UpperCase(DimCode) <> GLSetup."Global Dimension 2 Code") and
            (DimCode <> '')
        then begin
            Message(MessageText, DimCode);
            DimCode := '';
        end;
    end;

    local procedure GetCaptionClass(BudgetDimType: Integer): Text[250]
    begin
        if GLBudgetName.Name <> BudgetName then
            GLBudgetName.Get(BudgetName);
        case BudgetDimType of
            1:
                begin
                    if GLBudgetName."Budget Dimension 1 Code" <> '' then
                        exit('1,6,' + GLBudgetName."Budget Dimension 1 Code");

                    exit(Text008);
                end;
            2:
                begin
                    if GLBudgetName."Budget Dimension 2 Code" <> '' then
                        exit('1,6,' + GLBudgetName."Budget Dimension 2 Code");

                    exit(Text009);
                end;
            3:
                begin
                    if GLBudgetName."Budget Dimension 3 Code" <> '' then
                        exit('1,6,' + GLBudgetName."Budget Dimension 3 Code");

                    exit(Text010);
                end;
            4:
                begin
                    if GLBudgetName."Budget Dimension 4 Code" <> '' then
                        exit('1,6,' + GLBudgetName."Budget Dimension 4 Code");

                    exit(Text011);
                end;
        end;
    end;

    procedure SetBudgetName(NextBudgetName: Code[10])
    begin
        NewBudgetName := NextBudgetName;
    end;

    procedure GetBudgetName(): Code[10]
    begin
        exit(BudgetName);
    end;

#if not CLEAN26
    [Obsolete('Replaced by SetGLAccountFilter(NewGLAccFilter: Text)', '26.0')]
    procedure SetGLAccountFilter(NewGLAccFilter: Code[250])
    begin
        GLAccFilter := NewGLAccFilter;
        GLAccFilterOnAfterValidate();
    end;
#endif

    procedure SetGLAccountFilter(NewGLAccFilter: Text)
    begin
        GLAccFilter := NewGLAccFilter;
        GLAccFilterOnAfterValidate();
    end;

    procedure SetGLAccountCategoryFilter(NewGLAccCategoryFilter: Enum "G/L Account Category")
    begin
        GLAccCategoryFilter := NewGLAccCategoryFilter;
    end;

    procedure SetIncomeBalanceGLAccFilter(NewIncomeBalanceGLAccFilter: Option)
    begin
        IncomeBalanceGLAccFilter := "G/L Account Income/Balance".FromInteger(NewIncomeBalanceGLAccFilter);
    end;

    procedure SetBudgetDimFilters(NewGlobalDim1Filter: Text; NewGlobalDim2Filter: Text; NewBudgetDim1Filter: Text; NewBudgetDim2Filter: Text; NewBudgetDim3Filter: Text; NewBudgetDim4Filter: Text);
    begin
        GlobalDim1Filter := NewGlobalDim1Filter;
        GlobalDim2Filter := NewGlobalDim2Filter;
        BudgetDim1Filter := NewBudgetDim1Filter;
        BudgetDim2Filter := NewBudgetDim2Filter;
        BudgetDim3Filter := NewBudgetDim3Filter;
        BudgetDim4Filter := NewBudgetDim4Filter;
    end;

    protected procedure UpdateMatrixSubform()
    begin
        CurrPage.MatrixForm.PAGE.LoadMatrix(
          MATRIX_CaptionSet, MATRIX_MatrixRecords, MATRIX_CurrentNoOfColumns, LineDimCode,
          LineDimType, ColumnDimType, GlobalDim1Filter, GlobalDim2Filter, BudgetDim1Filter,
          BudgetDim2Filter, BudgetDim3Filter, BudgetDim4Filter, GLBudgetName, DateFilter,
          GLAccFilter, IncomeBalanceGLAccFilter, GLAccCategoryFilter, RoundingFactor, PeriodType);

        CurrPage.Update();
    end;

    local procedure LineDimCodeOnAfterValidate()
    begin
        UpdateMatrixSubform();
    end;

    local procedure ColumnDimCodeOnAfterValidate()
    begin
        UpdateMatrixSubform();
    end;

    local procedure PeriodTypeOnAfterValidate()
    begin
        if ColumnDimType = ColumnDimType::Period then
            GenerateColumnCaptions(Enum::"Matrix Page Step Type"::Initial);
        UpdateMatrixSubform();
    end;

    local procedure GLAccFilterOnAfterValidate()
    begin
        GLAccBudgetBuf.SetFilter("G/L Account Filter", GLAccFilter);
        if ColumnDimType = ColumnDimType::"G/L Account" then
            GenerateColumnCaptions(Enum::"Matrix Page Step Type"::Initial);
        UpdateMatrixSubform();
    end;

    local procedure ValidateIncomeBalanceGLAccFilter()
    begin
        GLAccBudgetBuf.SetRange("Income/Balance", IncomeBalanceGLAccFilter);
        if ColumnDimType = ColumnDimType::"G/L Account" then
            GenerateColumnCaptions(Enum::"Matrix Page Step Type"::Initial);
        UpdateMatrixSubform();
    end;

    local procedure ValidateGLAccCategoryFilter()
    begin
        GLAccBudgetBuf.SetRange("Account Category", GLAccCategoryFilter);
        if ColumnDimType = ColumnDimType::"G/L Account" then
            GenerateColumnCaptions(Enum::"Matrix Page Step Type"::Initial);
        UpdateMatrixSubform();
    end;

    procedure GlobalDim2FilterOnAfterValidate()
    begin
        GLAccBudgetBuf.SetFilter("Global Dimension 2 Filter", GlobalDim2Filter);
        if ColumnDimType = ColumnDimType::"Global Dimension 2" then
            GenerateColumnCaptions(Enum::"Matrix Page Step Type"::Initial);
        UpdateMatrixSubform();
    end;

    procedure GlobalDim1FilterOnAfterValidate()
    begin
        GLAccBudgetBuf.SetFilter("Global Dimension 1 Filter", GlobalDim1Filter);
        if ColumnDimType = ColumnDimType::"Global Dimension 1" then
            GenerateColumnCaptions(Enum::"Matrix Page Step Type"::Initial);
        UpdateMatrixSubform();
    end;

    procedure BudgetDim2FilterOnAfterValidate()
    begin
        GLAccBudgetBuf.SetFilter("Budget Dimension 2 Filter", BudgetDim2Filter);
        if ColumnDimType = ColumnDimType::"Budget Dimension 2" then
            GenerateColumnCaptions(Enum::"Matrix Page Step Type"::Initial);
        UpdateMatrixSubform();
    end;

    procedure BudgetDim1FilterOnAfterValidate()
    begin
        GLAccBudgetBuf.SetFilter("Budget Dimension 1 Filter", BudgetDim1Filter);
        if ColumnDimType = ColumnDimType::"Budget Dimension 1" then
            GenerateColumnCaptions(Enum::"Matrix Page Step Type"::Initial);
        UpdateMatrixSubform();
    end;

    procedure BudgetDim4FilterOnAfterValidate()
    begin
        GLAccBudgetBuf.SetFilter("Budget Dimension 4 Filter", BudgetDim4Filter);
        if ColumnDimType = ColumnDimType::"Budget Dimension 4" then
            GenerateColumnCaptions(Enum::"Matrix Page Step Type"::Initial);
        UpdateMatrixSubform();
    end;

    procedure BudgetDim3FilterOnAfterValidate()
    begin
        GLAccBudgetBuf.SetFilter("Budget Dimension 3 Filter", BudgetDim3Filter);
        if ColumnDimType = ColumnDimType::"Budget Dimension 3" then
            GenerateColumnCaptions(Enum::"Matrix Page Step Type"::Initial);
        UpdateMatrixSubform();
    end;

    local procedure DateFilterOnAfterValidate()
    begin
        if ColumnDimType = ColumnDimType::Period then
            GenerateColumnCaptions(Enum::"Matrix Page Step Type"::Initial);
        UpdateMatrixSubform();
    end;

    local procedure ShowColumnNameOnPush()
    begin
        GenerateColumnCaptions(Enum::"Matrix Page Step Type"::Same);
        UpdateMatrixSubform();
    end;

    protected procedure ValidateDateFilter(NewDateFilter: Text[30])
    var
        FilterTokens: Codeunit "Filter Tokens";
    begin
        FilterTokens.MakeDateFilter(NewDateFilter);
        GLAccBudgetBuf.SetFilter("Date Filter", NewDateFilter);
        DateFilter := CopyStr(GLAccBudgetBuf.GetFilter("Date Filter"), 1, MaxStrLen(DateFilter));
        InternalDateFilter := NewDateFilter;
        DateFilterOnAfterValidate();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGenerateColumnCaptions(ColumnDimCode: Text[30]; StepType: Enum "Matrix Page Step Type"; var PrimKeyFirstCaptionInCu: Text; var CaptionSet: array[32] of Text[80]; var CaptionRange: Text; var CurrentNoOfColumns: Integer; var MatrixRecords: array[32] of Record "Dimension Code Buffer"; ShowColumnName: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDimCodeToType(DimCode: Text[30]; var Result: Enum "G/L Budget Matrix Dimensions")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateBudgetName(var GLAccBudgetBuf: Record "G/L Acc. Budget Buffer"; var GLBudgetName: Record "G/L Budget Name")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeClearDimCodeOnChange(DimensionCode: Text[30]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteBudgetOnAfterGLBudgetEntrySetFilters(var GLBudgetEntry: Record "G/L Budget Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDimSelectionOnBeforeDimSelectionLookup(var DimensionSelection: Page "Dimension Selection")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenPageOnBeforeSetPeriodTypeMonth(var PeriodType: Enum "Analysis Period Type"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenPageOnBeforeIncomeBalanceGLAccFilter(GLAccountIncomeBalanceFilter: Enum "G/L Account Income/Balance"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnOpenPage()
    begin
    end;
}

