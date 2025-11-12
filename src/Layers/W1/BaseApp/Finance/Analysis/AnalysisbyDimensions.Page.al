// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.CashFlow.Account;
using Microsoft.CashFlow.Forecast;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using System.Reflection;
using System.Text;
using System.Utilities;

page 554 "Analysis by Dimensions"
{
    Caption = 'Analysis by Dimensions';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = "Analysis by Dim. Parameters";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(AnalysisViewCode; Rec."Analysis View Code")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Analysis View Code';
                    TableRelation = "Analysis View";
                    ToolTip = 'Specifies the code for the analysis view that the filter belongs to.';
                    Editable = false;
                }
                field(LineDimCode; LineDimCode)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Show as Lines';
                    ToolTip = 'Specifies which values you want to show as lines in the window. This allows you to see the same matrix window from various perspectives, especially when you use both the Show as Lines field and the Show as Columns field.';

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
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        if (UpperCase(LineDimCode) = UpperCase(ColumnDimCode)) and (LineDimCode <> '') then begin
                            ColumnDimCode := '';
                            ValidateColumnDimCode();
                        end;
                        ValidateLineDimCode();
                        if Rec."Line Dim Option" = Rec."Line Dim Option"::Period then
                            TempDimensionCodeBuffer.SetCurrentKey("Period Start")
                        else
                            TempDimensionCodeBuffer.SetCurrentKey(Code);
                    end;
                }
                field(ColumnDimCode; ColumnDimCode)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Show as Columns';
                    ToolTip = 'Specifies which values you want to show as columns in the window. This allows you to see the same matrix window from various perspectives, especially when you use both the Show as Lines field and the Show as Columns field.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        NewCode: Text[30];
                    begin
                        NewCode := GetDimSelection(ColumnDimCode);
                        if NewCode = ColumnDimCode then
                            exit(false);

                        Text := NewCode;
                        ColumnDimCode := NewCode;
                        ValidateColumnDimCode();
                        CreateCaptionSet(TempDimensionCodeBuffer, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, Rec."Column Set");
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        if (UpperCase(LineDimCode) = UpperCase(ColumnDimCode)) and (LineDimCode <> '') then begin
                            LineDimCode := '';
                            ValidateLineDimCode();
                        end;
                        ValidateColumnDimCode();

                        CreateCaptionSet(TempDimensionCodeBuffer, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, Rec."Column Set");
                    end;
                }
            }
            group(Filters)
            {
                Caption = 'Filters';
                field(DateFilter; Rec."Date Filter")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies the dates that will be used to filter the amounts in the window.';

                    trigger OnValidate()
                    var
                        GLAcc: Record "G/L Account";
                        FilterTokens: Codeunit "Filter Tokens";
                    begin
                        FilterTokens.MakeDateFilter(Rec."Date Filter");
                        GLAcc.SetFilter("Date Filter", Rec."Date Filter");
                        Rec."Date Filter" := GLAcc.GetFilter("Date Filter");
                        InternalDateFilter := Rec."Date Filter";
                        if Rec."Column Dim Option" = Rec."Column Dim Option"::Period then
                            CreateCaptionSet(TempDimensionCodeBuffer, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, Rec."Column Set");
                    end;
                }
                field(AccFilter; Rec."Account Filter")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Account Filter';
                    ToolTip = 'Specifies a filter for the general ledger accounts for which entries will be shown in the matrix window.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        GLAccList: Page "G/L Account List";
                        CFAccList: Page "Cash Flow Account List";
                    begin
                        case AnalysisView."Account Source" of
                            AnalysisView."Account Source"::"G/L Account":
                                begin
                                    GLAccList.LookupMode(true);
                                    if not (GLAccList.RunModal() = ACTION::LookupOK) then
                                        exit(false);
                                    Text := GLAccList.GetSelectionFilter();
                                end;
                            AnalysisView."Account Source"::"Cash Flow Account":
                                begin
                                    CFAccList.LookupMode(true);
                                    if not (CFAccList.RunModal() = ACTION::LookupOK) then
                                        exit(false);
                                    Text := CFAccList.GetSelectionFilter();
                                end;
                            else
                                OnLookupAccountFilterOnAccountSourceElseCase(Rec, AnalysisView);
                        end;
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        if (Rec."Column Dim Option" = Rec."Column Dim Option"::"G/L Account") or (Rec."Column Dim Option" = Rec."Column Dim Option"::"Cash Flow Account") then
                            CreateCaptionSet(TempDimensionCodeBuffer, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, Rec."Column Set");
                    end;
                }
                field(BusUnitFilter; Rec."Bus. Unit Filter")
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '3,' + BusUnitFilterCaption;
                    Visible = GLAccountSource;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        BusUnitList: Page "Business Unit List";
                    begin
                        BusUnitList.LookupMode(true);
                        if not (BusUnitList.RunModal() = ACTION::LookupOK) then
                            exit(false);
                        Text := BusUnitList.GetSelectionFilter();
                        exit(true);
                    end;
                }
                field(CashFlowFilter; Rec."Cash Flow Forecast Filter")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Cash Flow Forecast Filter';
                    LookupPageID = "Cash Flow Forecast List";
                    TableRelation = "Cash Flow Forecast";
                    ToolTip = 'Specifies the cash flow forecast that information in the matrix is shown for.';
                    Visible = (GLAccountSource = false);

                    trigger OnValidate()
                    begin
                        if Rec."Column Dim Option" = Rec."Column Dim Option"::"Cash Flow Forecast" then
                            CreateCaptionSet(TempDimensionCodeBuffer, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, Rec."Column Set");
                    end;
                }
                field(BudgetFilter; Rec."Budget Filter")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Budget Filter';
                    LookupPageID = "G/L Budget Names";
                    TableRelation = "G/L Budget Name".Name;
                    ToolTip = 'Specifies the budget that information in the matrix is shown for.';
                    Visible = GLAccountSource;
                }
                field(Dim1Filter; Rec."Dimension 1 Filter")
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = GetCaptionClass(1);
                    Caption = 'Dimension 1 Filter';
                    Enabled = Dim1FilterEnable;
                    ToolTip = 'Specifies a filter for the Dimension 1 for which entries will be shown in the matrix window.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookUpDimFilter(AnalysisView."Dimension 1 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        if Rec."Column Dim Option" = Rec."Column Dim Option"::"Dimension 1" then
                            CreateCaptionSet(TempDimensionCodeBuffer, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, Rec."Column Set");
                    end;
                }
                field(Dim2Filter; Rec."Dimension 2 Filter")
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = GetCaptionClass(2);
                    Caption = 'Dimension 2 Filter';
                    Enabled = Dim2FilterEnable;
                    ToolTip = 'Specifies a filter for the Dimension 2 for which entries will be shown in the matrix window.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookUpDimFilter(AnalysisView."Dimension 2 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        if Rec."Column Dim Option" = Rec."Column Dim Option"::"Dimension 2" then
                            CreateCaptionSet(TempDimensionCodeBuffer, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, Rec."Column Set");
                    end;
                }
                field(Dim3Filter; Rec."Dimension 3 Filter")
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = GetCaptionClass(3);
                    Caption = 'Dimension 3 Filter';
                    Enabled = Dim3FilterEnable;
                    ToolTip = 'Specifies a filter for the Dimension 3 for which entries will be shown in the matrix window.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookUpDimFilter(AnalysisView."Dimension 3 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        if Rec."Column Dim Option" = Rec."Column Dim Option"::"Dimension 3" then
                            CreateCaptionSet(TempDimensionCodeBuffer, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, Rec."Column Set");
                    end;
                }
                field(Dim4Filter; Rec."Dimension 4 Filter")
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = GetCaptionClass(4);
                    Caption = 'Dimension 4 Filter';
                    Enabled = Dim4FilterEnable;
                    ToolTip = 'Specifies a filter for the Dimension 4 for which entries will be shown in the matrix window.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookUpDimFilter(AnalysisView."Dimension 4 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        if Rec."Column Dim Option" = Rec."Column Dim Option"::"Dimension 4" then
                            CreateCaptionSet(TempDimensionCodeBuffer, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, Rec."Column Set");
                    end;
                }
            }
            group(Options)
            {
                Caption = 'Options';
                field(ShowActualBudg; Rec."Show Actual/Budgets")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies if the selected value is shown in the window.';
                    Visible = GLAccountSource;
                }
                field(AmountField; Rec."Show Amount Field")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Show Amount Field';
                    ToolTip = 'Specifies the type of entries that will be included in the matrix window. The Amount options means that amounts that are the sum of debit and credit amounts are shown.';
                }
                field(ClosingEntryFilter; Rec."Closing Entries")
                {
                    ApplicationArea = Dimensions;
                    OptionCaption = 'Include,Exclude';
                    ToolTip = 'Specifies whether the amounts shown in the matrix window will include closing entries.';
                    Visible = GLAccountSource;

                    trigger OnValidate()
                    begin
                        FindPeriod('=');
                    end;
                }
                field(RoundingFactor; Rec."Rounding Factor")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the factor that is used to round the amounts.';
                }
                field(ShowInAddCurr; Rec."Show In Add. Currency")
                {
                    ApplicationArea = Dimensions;
                    MultiLine = true;
                    ToolTip = 'Specifies if the reported amounts are shown in the additional reporting currency.';
                    Visible = GLAccountSource;
                }
                field(ShowColumnName; Rec."Show Column Name")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies that the names of columns are shown in the matrix window.';

                    trigger OnValidate()
                    begin
                        CreateCaptionSet(TempDimensionCodeBuffer, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, Rec."Column Set");
                    end;
                }
                field(ShowOppositeSign; Rec."Show Opposite Sign")
                {
                    ApplicationArea = Dimensions;
                    MultiLine = true;
                    ToolTip = 'Specifies whether to show debits as negative amounts (with minus signs) and credits as positive amounts in the matrix window.';
                }
            }
            group("Matrix Options")
            {
                Caption = 'Matrix Options';
                field(PeriodType; Rec."Period Type")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        FindPeriod('');
                        if Rec."Column Dim Option" = Rec."Column Dim Option"::Period then
                            CreateCaptionSet(TempDimensionCodeBuffer, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, Rec."Column Set");
                    end;
                }
                field(ColumnsSet; Rec."Column Set")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the range of values that are displayed in the matrix window, for example, the total period. To change the contents of the field, choose Next Set or Previous Set.';
                }
                field(QtyType; Rec."Amount Type")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies how amounts are displayed. Net Change: The net change in the balance for the selected period. Balance at Date: The balance as of the last day in the selected period.';
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
                action("Reverse Lines and Columns")
                {
                    ApplicationArea = Dimensions;
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
                        CreateCaptionSet(TempDimensionCodeBuffer, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, Rec."Column Set");
                    end;
                }
            }
        }
        area(processing)
        {
            action(ShowMatrix)
            {
                ApplicationArea = Dimensions;
                Caption = '&Show Matrix';
                Image = ShowMatrix;
                ToolTip = 'View the data overview according to the selected filters and options.';

                trigger OnAction()
                var
                    MatrixForm: Page "Analysis by Dimensions Matrix";
                begin
                    Clear(MatrixForm);

                    if GLAccountSource then
                        Rec."Cash Flow Forecast Filter" := '';

                    MatrixForm.Load(Rec, LineDimCode, ColumnDimCode, ColumnCaptions, PrimaryKeyFirstColInSet);
                    MatrixForm.RunModal();
                end;
            }
            action("Previous Set")
            {
                ApplicationArea = Dimensions;
                Caption = 'Previous Set';
                Image = PreviousSet;
                ToolTip = 'Go to the previous set of data.';

                trigger OnAction()
                begin
                    CreateCaptionSet(TempDimensionCodeBuffer, Step::Previous, 32, PrimaryKeyFirstColInSet, ColumnCaptions, Rec."Column Set");
                end;
            }
            action("Next Set")
            {
                ApplicationArea = Dimensions;
                Caption = 'Next Set';
                Image = NextSet;
                ToolTip = 'Go to the next set of data.';

                trigger OnAction()
                begin
                    CreateCaptionSet(TempDimensionCodeBuffer, Step::Next, 32, PrimaryKeyFirstColInSet, ColumnCaptions, Rec."Column Set");
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Previous Set_Promoted"; "Previous Set")
                {
                }
                actionref(ShowMatrix_Promoted; ShowMatrix)
                {
                }
                actionref("Next Set_Promoted"; "Next Set")
                {
                }
                actionref("Reverse Lines and Columns_Promoted"; "Reverse Lines and Columns")
                {
                }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(FindRecord(Rec."Line Dim Option", TempDimensionCodeBuffer, Which));
    end;

    trigger OnInit()
    begin
        Dim4FilterEnable := true;
        Dim3FilterEnable := true;
        Dim2FilterEnable := true;
        Dim1FilterEnable := true;
    end;

    trigger OnOpenPage()
    var
        GLAcc: Record "G/L Account";
        "Field": Record "Field";
        CashFlowAccount: Record "Cash Flow Account";
        AnalysisByDimUserParam: Record "Analysis by Dim. User Param.";
        AccountCaption: Text[30];
        UnitCaption: Text[30];
    begin
        OnBeforeOpenPage(Rec);
        if (NewAnalysisViewCode <> '') and (NewAnalysisViewCode <> Rec."Analysis View Code") then
            Rec."Analysis View Code" := NewAnalysisViewCode;
        AnalysisByDimUserParam.Load(Rec, Page::"Analysis by Dimensions");
        ValidateAnalysisViewCode();

        GLSetup.Get();
        if GLSetup."Additional Reporting Currency" = '' then
            Rec."Show In Add. Currency" := false
        else
            Currency.Get(GLSetup."Additional Reporting Currency");

        case Rec."Analysis Account Source" of
            Rec."Analysis Account Source"::"G/L Account":
                LineDimCode := GLAcc.TableCaption;
            Rec."Analysis Account Source"::"Cash Flow Account":
                LineDimCode := CashFlowAccount.TableCaption();
            else
                OnGetCaptions(AnalysisView, LineDimCode, AccountCaption, UnitCaption, true);
        end;
        ColumnDimCode := Text000;

        Rec."Line Dim Option" := DimCodeToDimOption(LineDimCode);
        Rec."Column Dim Option" := DimCodeToDimOption(ColumnDimCode);
        case Rec."Analysis Account Source" of
            Rec."Analysis Account Source"::"G/L Account":
                begin
                    Field.Get(DATABASE::"G/L Account", 42);
                    BusUnitFilterCaption := Field."Field Caption";
                end;
            else
                OnOpenPageOnGetBusUnitFilterCaptionElseCase(Rec, AnalysisView, BusUnitFilterCaption);
        end;

        FindPeriod('');

        CreateCaptionSet(TempDimensionCodeBuffer, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, Rec."Column Set");
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        AnalysisByDimUserParam: Record "Analysis by Dim. User Param.";
    begin
        AnalysisByDimUserParam.Save(Rec, Page::"Analysis by Dimensions");
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'Period';
        Text002: Label 'You have not yet defined an analysis view.';
#pragma warning disable AA0470
        Text003: Label '%1 is not a valid line definition.';
        Text004: Label '%1 is not a valid column definition.';
#pragma warning restore AA0470
        Text005: Label '1,6,,Dimension 1 Filter';
        Text006: Label '1,6,,Dimension 2 Filter';
        Text007: Label '1,6,,Dimension 3 Filter';
        Text008: Label '1,6,,Dimension 4 Filter';
#pragma warning restore AA0074
        GLSetup: Record "General Ledger Setup";
        AnalysisView: Record "Analysis View";
        AnalysisViewEntry: Record "Analysis View Entry";
        Currency: Record Currency;
        AmountType: Enum "Analysis Amount Type";
        GLAccountSource: Boolean;
        LineDimCode: Text[30];
        ColumnDimCode: Text[30];
        InternalDateFilter: Text;
        NewAnalysisViewCode: Code[10];
        PeriodInitialized: Boolean;
        BusUnitFilterCaption: Text[80];
        Dim1FilterEnable: Boolean;
        Dim2FilterEnable: Boolean;
        Dim3FilterEnable: Boolean;
        Dim4FilterEnable: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text009: Label 'Unsupported Account Source %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
        TempDimensionCodeBuffer: Record "Dimension Code Buffer" temporary;
        ColumnCaptions: array[32] of Text[80];
        PrimaryKeyFirstColInSet: Text[1024];
        Step: Option First,Previous,Same,Next;

    procedure DimCodeToDimOption(DimCode: Text[30]) Result: Enum "Analysis Dimension Option"
    var
        AccountCaption: Text[30];
        UnitCaption: Text[30];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDimCodeToDimOption(DimCode, AnalysisView, Result, IsHandled);
        if IsHandled then
            exit(Result);

        GetAccountCaption(AccountCaption, UnitCaption);
        case DimCode of
            AccountCaption:
                case Rec."Analysis Account Source" of
                    Rec."Analysis Account Source"::"G/L Account":
                        exit(Enum::"Analysis Dimension Option"::"G/L Account");
                    Rec."Analysis Account Source"::"Cash Flow Account":
                        exit(Enum::"Analysis Dimension Option"::"Cash Flow Account");
                    else begin
                        OnGetAnalysisViewDimensionOption(AnalysisView, Result, DimCode);
                        exit(Result);
                    end;
                end;
            Text000:
                exit(Enum::"Analysis Dimension Option"::Period);
            UnitCaption:
                case Rec."Analysis Account Source" of
                    Rec."Analysis Account Source"::"G/L Account":
                        exit(Enum::"Analysis Dimension Option"::"Business Unit");
                    Rec."Analysis Account Source"::"Cash Flow Account":
                        exit(Enum::"Analysis Dimension Option"::"Cash Flow Forecast");
                    else begin
                        OnGetAnalysisViewDimensionOption(AnalysisView, Result, DimCode);
                        exit(Result);
                    end;
                end;
            AnalysisView."Dimension 1 Code":
                exit(Enum::"Analysis Dimension Option"::"Dimension 1");
            AnalysisView."Dimension 2 Code":
                exit(Enum::"Analysis Dimension Option"::"Dimension 2");
            AnalysisView."Dimension 3 Code":
                exit(Enum::"Analysis Dimension Option"::"Dimension 3");
            AnalysisView."Dimension 4 Code":
                exit(Enum::"Analysis Dimension Option"::"Dimension 4");
            else
                exit(Enum::"Analysis Dimension Option"::Undefined);
        end;
    end;

    procedure FindRecord(DimOption: Enum "Analysis Dimension Option"; var DimCodeBuf: Record "Dimension Code Buffer"; Which: Text[250]) Found: Boolean
    var
        GLAcc: Record "G/L Account";
        BusUnit: Record "Business Unit";
        CFAccount: Record "Cash Flow Account";
        CashFlowForecast: Record "Cash Flow Forecast";
        Period: Record Date;
        DimVal: Record "Dimension Value";
        PeriodPageMgt: Codeunit PeriodPageManagement;
    begin
        OnBeforeFindRecord(DimOption, DimVal);
        case DimOption of
            DimOption::"G/L Account":
                begin
                    GLAcc."No." := DimCodeBuf.Code;
                    if Rec."Account Filter" <> '' then
                        GLAcc.SetFilter("No.", Rec."Account Filter");
                    Found := GLAcc.Find(Which);
                    if Found then
                        CopyGLAccToBuf(GLAcc, DimCodeBuf);
                end;
            DimOption::"Cash Flow Account":
                begin
                    CFAccount."No." := DimCodeBuf.Code;
                    if Rec."Account Filter" <> '' then
                        CFAccount.SetFilter("No.", Rec."Account Filter");
                    Found := CFAccount.Find(Which);
                    if Found then
                        CopyCFAccToBuf(CFAccount, DimCodeBuf);
                end;
            DimOption::Period:
                begin
                    if not PeriodInitialized then
                        Rec."Date Filter" := '';
                    PeriodInitialized := true;
                    Period."Period Start" := DimCodeBuf."Period Start";
                    if Rec."Date Filter" <> '' then
                        Period.SetFilter("Period Start", Rec."Date Filter")
                    else
                        if Period."Period Start" <> 0D then
                            Period.SetFilter("Period Start", '%1..%2', Period."Period Start", ClosingDate(Period."Period Start"))
                        else
                            if InternalDateFilter <> '' then
                                Period.SetFilter("Period Start", InternalDateFilter);

                    Found := PeriodPageMgt.FindDate(Which, Period, Rec."Period Type");
                    if Found then
                        CopyPeriodToBuf(Period, DimCodeBuf);
                end;
            DimOption::"Business Unit":
                begin
                    BusUnit.Code := DimCodeBuf.Code;
                    if Rec."Bus. Unit Filter" <> '' then
                        BusUnit.SetFilter(Code, Rec."Bus. Unit Filter");
                    Found := BusUnit.Find(Which);
                    if Found then
                        CopyBusUnitToBuf(BusUnit, DimCodeBuf);
                end;
            DimOption::"Cash Flow Forecast":
                begin
                    CashFlowForecast."No." := DimCodeBuf.Code;
                    if Rec."Cash Flow Forecast Filter" <> '' then
                        CashFlowForecast.SetFilter("No.", Rec."Cash Flow Forecast Filter");
                    Found := CashFlowForecast.Find(Which);
                    if Found then
                        CopyCashFlowToBuf(CashFlowForecast, DimCodeBuf);
                end;
            DimOption::"Dimension 1":
                begin
                    if Rec."Dimension 1 Filter" <> '' then
                        DimVal.SetFilter(Code, Rec."Dimension 1 Filter");
                    DimVal."Dimension Code" := AnalysisView."Dimension 1 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Dimension 2":
                begin
                    if Rec."Dimension 2 Filter" <> '' then
                        DimVal.SetFilter(Code, Rec."Dimension 2 Filter");
                    DimVal."Dimension Code" := AnalysisView."Dimension 2 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Dimension 3":
                begin
                    if Rec."Dimension 3 Filter" <> '' then
                        DimVal.SetFilter(Code, Rec."Dimension 3 Filter");
                    DimVal."Dimension Code" := AnalysisView."Dimension 3 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Dimension 4":
                begin
                    if Rec."Dimension 4 Filter" <> '' then
                        DimVal.SetFilter(Code, Rec."Dimension 4 Filter");
                    DimVal."Dimension Code" := AnalysisView."Dimension 4 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
        end;

        OnAfterFindRecord(DimOption, DimCodeBuf, AnalysisView, Which, Found, Rec);
    end;

    procedure NextRecord(DimOption: Enum "Analysis Dimension Option"; var DimCodeBuf: Record "Dimension Code Buffer"; Steps: Integer) ResultSteps: Integer
    var
        GLAcc: Record "G/L Account";
        BusUnit: Record "Business Unit";
        CFAccount: Record "Cash Flow Account";
        CashFlowForecast: Record "Cash Flow Forecast";
        Period: Record Date;
        DimVal: Record "Dimension Value";
        PeriodPageMgt: Codeunit PeriodPageManagement;
    begin
        OnBeforeNextRecord(DimOption, DimVal);
        case DimOption of
            DimOption::"G/L Account":
                begin
                    GLAcc."No." := DimCodeBuf.Code;
                    if Rec."Account Filter" <> '' then
                        GLAcc.SetFilter("No.", Rec."Account Filter");
                    ResultSteps := GLAcc.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyGLAccToBuf(GLAcc, DimCodeBuf);
                end;
            DimOption::"Cash Flow Account":
                begin
                    CFAccount."No." := DimCodeBuf.Code;
                    if Rec."Account Filter" <> '' then
                        CFAccount.SetFilter("No.", Rec."Account Filter");
                    ResultSteps := CFAccount.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyCFAccToBuf(CFAccount, DimCodeBuf);
                end;
            DimOption::Period:
                begin
                    if Rec."Date Filter" <> '' then
                        Period.SetFilter("Period Start", Rec."Date Filter");
                    Period."Period Start" := DimCodeBuf."Period Start";
                    ResultSteps := PeriodPageMgt.NextDate(Steps, Period, Rec."Period Type");
                    if ResultSteps <> 0 then
                        CopyPeriodToBuf(Period, DimCodeBuf);
                end;
            DimOption::"Business Unit":
                begin
                    BusUnit.Code := DimCodeBuf.Code;
                    if Rec."Bus. Unit Filter" <> '' then
                        BusUnit.SetFilter(Code, Rec."Bus. Unit Filter");
                    ResultSteps := BusUnit.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyBusUnitToBuf(BusUnit, DimCodeBuf);
                end;
            DimOption::"Cash Flow Forecast":
                begin
                    CashFlowForecast."No." := DimCodeBuf.Code;
                    if Rec."Cash Flow Forecast Filter" <> '' then
                        CashFlowForecast.SetFilter("No.", Rec."Cash Flow Forecast Filter");
                    ResultSteps := CashFlowForecast.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyCashFlowToBuf(CashFlowForecast, DimCodeBuf);
                end;
            DimOption::"Dimension 1":
                begin
                    if Rec."Dimension 1 Filter" <> '' then
                        DimVal.SetFilter(Code, Rec."Dimension 1 Filter");
                    DimVal."Dimension Code" := AnalysisView."Dimension 1 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Dimension 2":
                begin
                    if Rec."Dimension 2 Filter" <> '' then
                        DimVal.SetFilter(Code, Rec."Dimension 2 Filter");
                    DimVal."Dimension Code" := AnalysisView."Dimension 2 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Dimension 3":
                begin
                    if Rec."Dimension 3 Filter" <> '' then
                        DimVal.SetFilter(Code, Rec."Dimension 3 Filter");
                    DimVal."Dimension Code" := AnalysisView."Dimension 3 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Dimension 4":
                begin
                    if Rec."Dimension 4 Filter" <> '' then
                        DimVal.SetFilter(Code, Rec."Dimension 4 Filter");
                    DimVal."Dimension Code" := AnalysisView."Dimension 4 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
        end;

        OnAfterNextRecord(DimOption, DimCodeBuf, AnalysisView, Steps, ResultSteps);
    end;

    local procedure CopyGLAccToBuf(var TheGLAcc: Record "G/L Account"; var TheDimCodeBuf: Record "Dimension Code Buffer")
    begin
        TheDimCodeBuf.Init();
        TheDimCodeBuf.Code := TheGLAcc."No.";
        TheDimCodeBuf.Name := TheGLAcc.Name;
        TheDimCodeBuf.Totaling := TheGLAcc.Totaling;
        TheDimCodeBuf.Indentation := TheGLAcc.Indentation;
        TheDimCodeBuf."Show in Bold" := TheGLAcc."Account Type" <> TheGLAcc."Account Type"::Posting;
    end;

    local procedure CopyCFAccToBuf(var TheCFAcc: Record "Cash Flow Account"; var TheDimCodeBuf: Record "Dimension Code Buffer")
    begin
        TheDimCodeBuf.Init();
        TheDimCodeBuf.Code := TheCFAcc."No.";
        TheDimCodeBuf.Name := TheCFAcc.Name;
        TheDimCodeBuf.Totaling := TheCFAcc.Totaling;
        TheDimCodeBuf.Indentation := TheCFAcc.Indentation;
        TheDimCodeBuf."Show in Bold" := TheCFAcc."Account Type" <> TheCFAcc."Account Type"::Entry;
    end;

    local procedure CopyPeriodToBuf(var ThePeriod: Record Date; var TheDimCodeBuf: Record "Dimension Code Buffer")
    var
        Period2: Record Date;
    begin
        TheDimCodeBuf.Init();
        TheDimCodeBuf.Code := Format(ThePeriod."Period Start");
        TheDimCodeBuf."Period Start" := ThePeriod."Period Start";
        if Rec."Closing Entries" = Rec."Closing Entries"::Include then
            TheDimCodeBuf."Period End" := ClosingDate(ThePeriod."Period End")
        else
            TheDimCodeBuf."Period End" := ThePeriod."Period End";
        if Rec."Date Filter" <> '' then begin
            Period2.SetFilter("Period End", Rec."Date Filter");
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

    local procedure CopyCashFlowToBuf(var TheCashFlowForecast: Record "Cash Flow Forecast"; var TheDimCodeBuf: Record "Dimension Code Buffer")
    begin
        TheDimCodeBuf.Init();
        TheDimCodeBuf.Code := TheCashFlowForecast."No.";
        TheDimCodeBuf.Name := TheCashFlowForecast.Description;
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
    end;

    local procedure FindPeriod(SearchText: Code[10])
    var
        Calendar: Record Date;
        PeriodPageMgt: Codeunit PeriodPageManagement;
        TempDate: Date;
    begin
        if not PeriodInitialized then
            Rec."Date Filter" := '';
        if (Rec."Date Filter" <> '') and Evaluate(TempDate, Rec."Date Filter") then begin
            Calendar.SetFilter("Period Start", Rec."Date Filter");
            if not PeriodPageMgt.FindDate('+', Calendar, Rec."Period Type") then
                PeriodPageMgt.FindDate('+', Calendar, Rec."Period Type"::Day);
            Calendar.SetRange("Period Start");
        end;
        if PeriodPageMgt.FindDate(SearchText, Calendar, Rec."Period Type") then
            if Rec."Closing Entries" = Rec."Closing Entries"::Include then
                Calendar."Period End" := ClosingDate(Calendar."Period End");
        if AmountType = AmountType::"Net Change" then begin
            AnalysisViewEntry.SetRange("Posting Date", Calendar."Period Start", Calendar."Period End");
            if AnalysisViewEntry.GetRangeMin("Posting Date") = AnalysisViewEntry.GetRangeMax("Posting Date") then
                AnalysisViewEntry.SetRange("Posting Date", AnalysisViewEntry.GetRangeMin("Posting Date"));
        end else
            AnalysisViewEntry.SetRange("Posting Date", 0D, Calendar."Period End");

        InternalDateFilter := AnalysisViewEntry.GetFilter("Posting Date");
        OnFindPeriodOnAfterSetInternalDateFilter(Rec."Period Type", InternalDateFilter);

        if (Rec."Line Dim Option" <> Rec."Line Dim Option"::Period) and (Rec."Column Dim Option" <> Rec."Column Dim Option"::Period) then
            Rec."Date Filter" := InternalDateFilter;
    end;

    local procedure GetDimSelection(OldDimSelCode: Text[30]): Text[30]
    var
        DimSelection: Page "Dimension Selection";
        AccountCaption: Text[30];
        UnitCaption: Text[30];
    begin
        GetAccountCaption(AccountCaption, UnitCaption);
        DimSelection.InsertDimSelBuf(false, AccountCaption, AccountCaption);
        DimSelection.InsertDimSelBuf(false, Text000, Text000);
        if UnitCaption <> '' then
            DimSelection.InsertDimSelBuf(false, UnitCaption, UnitCaption);

        if AnalysisView."Dimension 1 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, AnalysisView."Dimension 1 Code", '');
        if AnalysisView."Dimension 2 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, AnalysisView."Dimension 2 Code", '');
        if AnalysisView."Dimension 3 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, AnalysisView."Dimension 3 Code", '');
        if AnalysisView."Dimension 4 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, AnalysisView."Dimension 4 Code", '');

        OnGetDimSelectionOnBeforeDimSelectionLookup(AnalysisView, DimSelection);
        DimSelection.LookupMode := true;
        if DimSelection.RunModal() = ACTION::LookupOK then
            exit(DimSelection.GetDimSelCode());

        exit(OldDimSelCode);
    end;

    local procedure LookUpDimFilter(Dim: Code[20]; var Text: Text): Boolean
    var
        DimVal: Record "Dimension Value";
        DimValList: Page "Dimension Value List";
    begin
        if Dim = '' then
            exit(false);
        DimValList.LookupMode(true);
        DimVal.SetRange("Dimension Code", Dim);
        DimValList.SetTableView(DimVal);
        if DimValList.RunModal() = ACTION::LookupOK then begin
            DimValList.GetRecord(DimVal);
            Text := DimValList.GetSelectionFilter();
            exit(true);
        end;
        exit(false)
    end;

    local procedure ValidateAnalysisViewCode()
    var
        AnalysisViewFilter: Record "Analysis View Filter";
        IsSupported: Boolean;
    begin
        AnalysisView.Code := Rec."Analysis View Code";
        if not AnalysisView.Find('=<>') then
            Error(Text002);
        Rec."Analysis View Code" := AnalysisView.Code;

        if ((Rec."Analysis Account Source" = AnalysisView."Account Source") or (Rec."Account Filter" = '')) then
            Rec."Account Filter" := AnalysisView."Account Filter";

        Rec."Dimension 1 Filter" := '';
        Rec."Dimension 2 Filter" := '';
        Rec."Dimension 3 Filter" := '';
        Rec."Dimension 4 Filter" := '';

        Dim1FilterEnable :=
          (AnalysisView."Dimension 1 Code" <> '') and
          (Rec."Dimension 1 Filter" = '');
        Dim2FilterEnable :=
          (AnalysisView."Dimension 2 Code" <> '') and
          (Rec."Dimension 2 Filter" = '');
        Dim3FilterEnable :=
          (AnalysisView."Dimension 3 Code" <> '') and
          (Rec."Dimension 3 Filter" = '');
        Dim4FilterEnable :=
          (AnalysisView."Dimension 4 Code" <> '') and
          (Rec."Dimension 4 Filter" = '');

        if Dim1FilterEnable then
            if AnalysisViewFilter.Get(AnalysisView.Code, AnalysisView."Dimension 1 Code") then
                Rec."Dimension 1 Filter" := AnalysisViewFilter."Dimension Value Filter";

        if Dim2FilterEnable then
            if AnalysisViewFilter.Get(AnalysisView.Code, AnalysisView."Dimension 2 Code") then
                Rec."Dimension 2 Filter" := AnalysisViewFilter."Dimension Value Filter";

        if Dim3FilterEnable then
            if AnalysisViewFilter.Get(AnalysisView.Code, AnalysisView."Dimension 3 Code") then
                Rec."Dimension 3 Filter" := AnalysisViewFilter."Dimension Value Filter";

        if Dim4FilterEnable then
            if AnalysisViewFilter.Get(AnalysisView.Code, AnalysisView."Dimension 4 Code") then
                Rec."Dimension 4 Filter" := AnalysisViewFilter."Dimension Value Filter";

        OnValidateAnalysisViewCodeOnAfterRecSetFilters(Rec, AnalysisView);

        case Rec."Analysis Account Source" of
            Rec."Analysis Account Source"::"G/L Account":
                GLAccountSource := true;
            Rec."Analysis Account Source"::"Cash Flow Account":
                GLAccountSource := false;
            else begin
                AnalysisView.OnGetAnalysisViewSupported(AnalysisView, IsSupported);
                if not IsSupported then
                    Error(Text009, AnalysisView."Account Source");
            end;
        end;
    end;

    local procedure ValidateLineDimCode()
    var
        AccountCaption: Text[30];
        UnitCaption: Text[30];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateLineDimCode(GLAccountSource, LineDimCode, InternalDateFilter, IsHandled, Rec, AnalysisView, AnalysisViewEntry);
        if IsHandled then
            exit;

        GetAccountCaption(AccountCaption, UnitCaption);

        if (UpperCase(LineDimCode) <> UpperCase(AccountCaption)) and
           (UpperCase(LineDimCode) <> UpperCase(UnitCaption)) and
           (UpperCase(LineDimCode) <> UpperCase(Text000)) and
           (UpperCase(LineDimCode) <> AnalysisView."Dimension 1 Code") and
           (UpperCase(LineDimCode) <> AnalysisView."Dimension 2 Code") and
           (UpperCase(LineDimCode) <> AnalysisView."Dimension 3 Code") and
           (UpperCase(LineDimCode) <> AnalysisView."Dimension 4 Code") and
           (LineDimCode <> '')
        then begin
            Message(Text003, LineDimCode);
            LineDimCode := '';
        end;
        Rec."Line Dim Option" := DimCodeToDimOption(LineDimCode);
        InternalDateFilter := AnalysisViewEntry.GetFilter("Posting Date");
        if (Rec."Line Dim Option" <> Rec."Line Dim Option"::Period) and (Rec."Column Dim Option" <> Rec."Column Dim Option"::Period) then begin
            Rec."Date Filter" := InternalDateFilter;
            if StrPos(Rec."Date Filter", '&') > 1 then
                Rec."Date Filter" := CopyStr(Rec."Date Filter", 1, StrPos(Rec."Date Filter", '&') - 1);
        end;
    end;

    local procedure ValidateColumnDimCode()
    var
        AccountCaption: Text[30];
        UnitCaption: Text[30];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateColumnDimCode(GLAccountSource, ColumnDimCode, InternalDateFilter, IsHandled, Rec, AnalysisView, AnalysisViewEntry, PeriodInitialized);
        if IsHandled then
            exit;

        GetAccountCaption(AccountCaption, UnitCaption);

        if (UpperCase(ColumnDimCode) <> UpperCase(AccountCaption)) and
           (UpperCase(ColumnDimCode) <> UpperCase(UnitCaption)) and
           (UpperCase(ColumnDimCode) <> UpperCase(Text000)) and
           (UpperCase(ColumnDimCode) <> AnalysisView."Dimension 1 Code") and
           (UpperCase(ColumnDimCode) <> AnalysisView."Dimension 2 Code") and
           (UpperCase(ColumnDimCode) <> AnalysisView."Dimension 3 Code") and
           (UpperCase(ColumnDimCode) <> AnalysisView."Dimension 4 Code") and
           (ColumnDimCode <> '')
        then begin
            Message(Text004, ColumnDimCode);
            ColumnDimCode := '';
        end;
        Rec."Column Dim Option" := DimCodeToDimOption(ColumnDimCode);
        InternalDateFilter := AnalysisViewEntry.GetFilter("Posting Date");
        if (Rec."Line Dim Option" <> Rec."Line Dim Option"::Period) and (Rec."Column Dim Option" <> Rec."Column Dim Option"::Period) then begin
            Rec."Date Filter" := InternalDateFilter;
            if StrPos(Rec."Date Filter", '&') > 1 then
                Rec."Date Filter" := CopyStr(Rec."Date Filter", 1, StrPos(Rec."Date Filter", '&') - 1);
        end else
            PeriodInitialized := false;
    end;

    procedure GetCaptionClass(AnalysisViewDimType: Integer) Result: Text[250]
    var
        DummyAnalysisbyDimParameters: Record "Analysis by Dim. Parameters";
    begin
        if AnalysisView.Code <> Rec."Analysis View Code" then
            if AnalysisView.Get(Rec."Analysis View Code") then
                if Rec."Analysis Account Source" = DummyAnalysisbyDimParameters."Analysis Account Source" then
                    Rec."Analysis Account Source" := AnalysisView."Account Source";

        case AnalysisViewDimType of
            1:
                begin
                    if AnalysisView."Dimension 1 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 1 Code");

                    exit(Text005);
                end;
            2:
                begin
                    if AnalysisView."Dimension 2 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 2 Code");

                    exit(Text006);
                end;
            3:
                begin
                    if AnalysisView."Dimension 3 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 3 Code");

                    exit(Text007);
                end;
            4:
                begin
                    if AnalysisView."Dimension 4 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 4 Code");

                    exit(Text008);
                end;
        end;

        OnAfterGetCaptionClass(AnalysisViewDimType, AnalysisView, Result);
    end;

    protected procedure CreateCaptionSet(RecRef: Record "Dimension Code Buffer"; Step: Option First,Previous,Same,Next; MaximumNoOfCaptions: Integer; var PrimaryKeyFirstCaptionInCurrSe: Text[1024]; var CaptionSet: array[32] of Text[1024]; var CaptionRange: Text[1024])
    var
        CurrentCaptionOrdinal: Integer;
    begin
        Clear(CaptionSet);
        CaptionRange := '';

        CurrentCaptionOrdinal := 0;

        case Step of
            Step::First:
                if (Rec."Column Dim Option" = Rec."Column Dim Option"::Period) and (Rec."Date Filter" = '') then
                    FindRecord(Rec."Column Dim Option", RecRef, '=><')
                else
                    if not FindRecord(Rec."Column Dim Option", RecRef, '-') then
                        exit;
            Step::Previous:
                begin
                    RecRef.SetPosition(PrimaryKeyFirstCaptionInCurrSe);
                    if Rec."Column Dim Option" = Rec."Column Dim Option"::Period then
                        Evaluate(RecRef."Period Start", RecRef.Code);
                    if not FindRecord(Rec."Column Dim Option", RecRef, '=') then
                        exit;
                    NextRecord(Rec."Column Dim Option", RecRef, -MaximumNoOfCaptions);
                end;
            Step::Same:
                begin
                    RecRef.SetPosition(PrimaryKeyFirstCaptionInCurrSe);
                    if Rec."Column Dim Option" = Rec."Column Dim Option"::Period then
                        Evaluate(RecRef."Period Start", RecRef.Code);
                    if not FindRecord(Rec."Column Dim Option", RecRef, '=') then
                        exit;
                end;
            Step::Next:
                begin
                    RecRef.SetPosition(PrimaryKeyFirstCaptionInCurrSe);
                    if Rec."Column Dim Option" = Rec."Column Dim Option"::Period then
                        Evaluate(RecRef."Period Start", RecRef.Code);
                    if not FindRecord(Rec."Column Dim Option", RecRef, '=') then
                        exit;
                    if not (NextRecord(Rec."Column Dim Option", RecRef, MaximumNoOfCaptions) = MaximumNoOfCaptions) then begin
                        RecRef.SetPosition(PrimaryKeyFirstCaptionInCurrSe);
                        FindRecord(Rec."Column Dim Option", RecRef, '=');
                    end;
                end;
        end;

        PrimaryKeyFirstCaptionInCurrSe := RecRef.GetPosition();

        repeat
            CurrentCaptionOrdinal := CurrentCaptionOrdinal + 1;
            if Rec."Show Column Name" then
                CaptionSet[CurrentCaptionOrdinal] := RecRef.Name
            else
                CaptionSet[CurrentCaptionOrdinal] := RecRef.Code;
        until (CurrentCaptionOrdinal = MaximumNoOfCaptions) or (NextRecord(Rec."Column Dim Option", RecRef, 1) <> 1);

        if CurrentCaptionOrdinal = 1 then
            CaptionRange := CaptionSet[1]
        else
            CaptionRange := CopyStr(CaptionSet[1] + '..' + CaptionSet[CurrentCaptionOrdinal], 1, MaxStrLen(CaptionRange));
    end;

    procedure SetAnalysisViewCode(NextAnalysisViewCode: Code[10])
    begin
        NewAnalysisViewCode := NextAnalysisViewCode;
        Rec."Analysis View Code" := NextAnalysisViewCode;
        Rec.Insert();
    end;

    local procedure GetAccountCaption(var AccountCaption: Text[30]; var UnitCaption: Text[30])
    var
        GLAcc: Record "G/L Account";
        CFAccount: Record "Cash Flow Account";
        BusUnit: Record "Business Unit";
        CashFlowForecast: Record "Cash Flow Forecast";
    begin
        case Rec."Analysis Account Source" of
            Rec."Analysis Account Source"::"G/L Account":
                begin
                    AccountCaption := GLAcc.TableCaption();
                    UnitCaption := BusUnit.TableCaption();
                end;
            Rec."Analysis Account Source"::"Cash Flow Account":
                begin
                    AccountCaption := CFAccount.TableCaption();
                    UnitCaption := CashFlowForecast.TableCaption();
                end;
            else
                OnGetCaptions(AnalysisView, LineDimCode, AccountCaption, UnitCaption, false);
        end;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterFindRecord(var DimOption: Enum "Analysis Dimension Option"; var DimCodeBuf: Record "Dimension Code Buffer"; var AnalysisView: Record "Analysis View"; Which: Text[250]; var Found: Boolean; var AnalysisByDimParameters: Record "Analysis by Dim. Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCaptionClass(AnalysisViewDimType: Integer; var AnalysisView: Record "Analysis View"; var ReturnValue: Text[250])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterNextRecord(DimOption: Enum "Analysis Dimension Option"; var DimCodeBuf: Record "Dimension Code Buffer"; var AnalysisView: Record "Analysis View"; Steps: Integer; var ResultSteps: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenPage(var AnalysisByDimParameters: Record "Analysis by Dim. Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDimCodeToDimOption(DimCode: Text[30]; var AnalysisView: Record "Analysis View"; var Result: Enum "Analysis Dimension Option"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNextRecord(DimOption: Enum "Analysis Dimension Option"; var DimensionValue: Record "Dimension Value")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindRecord(DimOption: Enum "Analysis Dimension Option"; var DimensionValue: Record "Dimension Value")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeValidateColumnDimCode(var GLAccountSource: Boolean; var ColumnDimCode: Text[30]; var InternalDateFilter: Text; var IsHandled: Boolean; var AnalysisByDimParameters: Record "Analysis by Dim. Parameters"; var AnalysisView: Record "Analysis View"; var AnalysisViewEntry: Record "Analysis View Entry"; var PeriodInitialized: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeValidateLineDimCode(var GLAccountSource: Boolean; var LineDimCode: Text[30]; var InternalDateFilter: Text; var IsHandled: Boolean; var AnalysisByDimParameters: Record "Analysis by Dim. Parameters"; var AnalysisView: Record "Analysis View"; var AnalysisViewEntry: Record "Analysis View Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDimSelectionOnBeforeDimSelectionLookup(var AnalysisView: Record "Analysis View"; var DimSelection: Page "Dimension Selection")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateAnalysisViewCodeOnAfterRecSetFilters(var AnalysisByDimParameters: Record "Analysis by Dim. Parameters"; var AnalysisView: Record "Analysis View")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCaptions(var AnalysisView: Record "Analysis View"; var LineDimCode: Text[30]; var AccountCaption: Text[30]; var UnitCaption: Text[30]; OpenPage: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetAnalysisViewDimensionOption(var AnalysisView: Record "Analysis View"; var Result: enum "Analysis Dimension Option"; DimCode: Text[30])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupAccountFilterOnAccountSourceElseCase(var AnalysisByDimParameters: Record "Analysis by Dim. Parameters"; AnalysisView: Record "Analysis View")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenPageOnGetBusUnitFilterCaptionElseCase(var AnalysisByDimParameters: Record "Analysis by Dim. Parameters"; AnalysisView: Record "Analysis View"; var BusUnitFilterCaption: Text[80])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindPeriodOnAfterSetInternalDateFilter(PeriodType: Enum "Analysis Period Type"; var DateFilter: Text)
    begin
    end;
}

