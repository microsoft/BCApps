// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using System.Reflection;
using System.Text;
using System.Utilities;

page 408 "G/L Balance by Dimension"
{
    Caption = 'G/L Balance by Dimension';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTableTemporary = true;
    SourceTable = "Analysis by Dim. Parameters";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
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
                        ColumnDimCodeOnAfterValidate();
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        if (UpperCase(LineDimCode) = UpperCase(ColumnDimCode)) and (LineDimCode <> '') then begin
                            LineDimCode := '';
                            ValidateLineDimCode();
                        end;
                        ValidateColumnDimCode();
                        ColumnDimCodeOnAfterValidate();
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
                        GLAccount: Record "G/L Account";
                        FilterTokens: Codeunit "Filter Tokens";
                        DateFilter: Text;
                    begin
                        DateFilter := Rec."Date Filter";
                        FilterTokens.MakeDateFilter(DateFilter);
                        GLAccount.SetFilter("Date Filter", DateFilter);
                        DateFilter := GLAccount.GetFilter("Date Filter");
                        Rec."Date Filter" := CopyStr(DateFilter, 1, MaxStrLen(Rec."Date Filter"));
                        InternalDateFilter := DateFilter;
                        DateFilterOnAfterValidate();
                    end;
                }
                field(GLAccFilter; Rec."Account Filter")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'G/L Account Filter';
                    ToolTip = 'Specifies the G/L accounts for which you will see information in the window.';

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
                field(BudgetFilter; Rec."Budget Filter")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Budget Filter';
                    LookupPageID = "G/L Budget Names";
                    TableRelation = "G/L Budget Name".Name;
                    ToolTip = 'Specifies the budget that information in the matrix is shown for.';
                }
                field(BusUnitFilter; Rec."Bus. Unit Filter")
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '3,' + BusUnitFilterCaption;

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

                    trigger OnValidate()
                    begin
                        BusUnitFilterOnAfterValidate();
                    end;
                }
                field(Dim1Filter; Rec."Dimension 1 Filter")
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,3,1';
                    Enabled = Dim1FilterEnable;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        DimensionValue: Record "Dimension Value";
                    begin
                        exit(DimensionValue.LookUpDimFilter(GLSetup."Global Dimension 1 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        GlobalDim1FilterOnAfterValidat();
                    end;
                }
                field(Dim2Filter; Rec."Dimension 2 Filter")
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,3,2';
                    Enabled = Dim2FilterEnable;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        DimensionValue: Record "Dimension Value";
                    begin
                        exit(DimensionValue.LookUpDimFilter(GLSetup."Global Dimension 2 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        GlobalDim2FilterOnAfterValidat();
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
                }
                field(AmountField; Rec."Show Amount Field")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the type of entries that will be included in the matrix window. The Amount options means that amounts that are the sum of debit and credit amounts are shown.';
                }
                field(ClosingEntryFilter; Rec."Closing Entries")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Closing Entries';
                    OptionCaption = 'Include,Exclude';
                    ToolTip = 'Specifies whether the balance shown will include closing entries. If you want to see the amounts on income statement accounts in closed years, you must exclude closing entries.';

                    trigger OnValidate()
                    begin
                        FindPeriod('=');
                    end;
                }
                field(RoundingFactor; Rec."Rounding Factor")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Rounding Factor';
                    ToolTip = 'Specifies the factor that is used to round the amounts.';
                }
                field(ShowInAddCurr; Rec."Show In Add. Currency")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Show Amounts in Add. Reporting Currency';
                    MultiLine = true;
                    ToolTip = 'Specifies whether to show the reported amounts in the additional reporting currency.';
                }
                field(ShowColumnName; Rec."Show Column Name")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Show Column Name';
                    ToolTip = 'Specifies that the names of columns are shown in the matrix window.';

                    trigger OnValidate()
                    begin
                        ShowColumnNameOnAfterValidate();
                    end;
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
                        PeriodTypeOnAfterValidate();
                    end;
                }
                field(AmountType; Rec."Amount Type")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'View as';
                    ToolTip = 'Specifies how amounts are displayed. Net Change: The net change in the balance for the selected period. Balance at Date: The balance as of the last day in the selected period.';

                    trigger OnValidate()
                    begin
                        FindPeriod('');
                        AmountTypeOnAfterValidate();
                    end;
                }
                field(MATRIX_ColumnSet; Rec."Column Set")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the range of values that are displayed in the matrix window, for example, the total period. To change the contents of the field, choose Next Set or Previous Set.';
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
                        GenerateColumnCaptions("Matrix Page Step Type"::Initial);
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
                    MatrixForm: Page "G/L Balance by Dim. Matrix";
                begin
                    Clear(MatrixForm);

                    MatrixForm.Load(Rec, LineDimCode, ColumnDimCode, MATRIX_ColumnCaptions, MATRIX_PrimaryKeyFirstColInSet, MATRIX_CurrSetLength);
                    OnShowMatrixActionOnBeforeRunModal(MatrixForm);
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
                    GenerateColumnCaptions("Matrix Page Step Type"::Previous);
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
                    GenerateColumnCaptions("Matrix Page Step Type"::Next);
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

    trigger OnInit()
    var
        "Field": Record "Field";
    begin
        Dim2FilterEnable := true;
        Dim1FilterEnable := true;
        Field.Get(DATABASE::"G/L Account", 42);
        BusUnitFilterCaption := Field."Field Caption";

        OnAfterOnInit();
    end;

    trigger OnOpenPage()
    var
        AnalysisByDimUserParam: Record "Analysis by Dim. User Param.";
        GLAccGlobalDim1Filter: Text;
        GlAccGlobalDim2Filter: Text;
    begin
        AnalysisByDimUserParam.Load(Rec, Page::"G/L Balance by Dimension");
        OnBeforeGLAccFilter(GLAcc, Rec."Account Filter", LineDimOption, ColumnDimOption);
        GLAccGlobalDim1Filter := GLAcc.GetFilter("Global Dimension 1 Filter");
        if (GLAccGlobalDim1Filter <> '') then
            Rec."Dimension 1 Filter" := GLAccGlobalDim1Filter;
        GLAccGlobalDim2Filter := GLAcc.GetFilter("Global Dimension 2 Filter");
        if (GLAccGlobalDim2Filter <> '') then
            Rec."Dimension 2 Filter" := GLAccGlobalDim2Filter;

        GLSetup.Get();
        Dim1FilterEnable :=
          (GLSetup."Global Dimension 1 Code" <> '') and
          (GLAcc.GetFilter("Global Dimension 1 Filter") = '');
        Dim2FilterEnable :=
          (GLSetup."Global Dimension 2 Code" <> '') and
          (GLAcc.GetFilter("Global Dimension 2 Filter") = '');

        if GLSetup."Additional Reporting Currency" = '' then
            Rec."Show In Add. Currency" := false;

        if (LineDimCode = '') and (ColumnDimCode = '') then begin
            LineDimCode := GLAcc.TableCaption();
            ColumnDimCode := Text001;
        end;
        LineDimOption := DimCodeToOption(LineDimCode);
        ColumnDimOption := DimCodeToOption(ColumnDimCode);

        OnOnOpenPageOnBeforeFindPeriod(GLSetup, GLAcc);

        FindPeriod('');

        MATRIX_NoOfColumns := 32;
        SetDateFilter(Rec."Date Filter");

        GenerateColumnCaptions("Matrix Page Step Type"::Initial);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        AnalysisByDimUserParam: Record "Analysis by Dim. User Param.";
    begin
        AnalysisByDimUserParam.Save(Rec, Page::"G/L Balance by Dimension");
    end;

    var
#pragma warning disable AA0074
        Text001: Label 'Period';
#pragma warning disable AA0470
        Text002: Label '%1 is not a valid line definition.';
        Text003: Label '%1 is not a valid column definition.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        GLAcc: Record "G/L Account";
        BusUnit: Record "Business Unit";
        LineDimCode: Text[30];
        ColumnDimCode: Text[30];
        InternalDateFilter: Text;
        BusUnitFilterCaption: Text[80];
        PeriodInitialized: Boolean;
        MATRIX_ColumnCaptions: array[32] of Text[1024];
        MATRIX_NoOfColumns: Integer;
        MATRIX_PrimaryKeyFirstColInSet: Text[1024];
        MATRIX_CurrSetLength: Integer;
        Dim1FilterEnable: Boolean;
        Dim2FilterEnable: Boolean;

    protected var
        GLSetup: Record "General Ledger Setup";
        LineDimOption: Option "G/L Account",Period,"Business Unit","Dimension 1","Dimension 2","Dimension 3","Dimension 4";
        ColumnDimOption: Option "G/L Account",Period,"Business Unit","Dimension 1","Dimension 2","Dimension 3","Dimension 4";

    local procedure DimCodeToOption(DimCode: Text[30]) Result: Integer
    var
        BusUnit: Record "Business Unit";
    begin
        case DimCode of
            '':
                Result := -1;
            GLAcc.TableCaption:
                Result := 0;
            Text001:
                Result := 1;
            BusUnit.TableCaption:
                Result := 2;
            GLSetup."Global Dimension 1 Code":
                Result := 3;
            GLSetup."Global Dimension 2 Code":
                Result := 4;
            else
                Result := -1;
        end;

        OnAfterDimCodeToOption(DimCode, GLSetup, Result);
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
        Period: Record Date;
        PeriodPageMgt: Codeunit PeriodPageManagement;
    begin
        if Rec."Date Filter" <> '' then begin
            Period.SetFilter("Period Start", Rec."Date Filter");
            if not PeriodPageMgt.FindDate('+', Period, Rec."Period Type") then
                PeriodPageMgt.FindDate('+', Period, Rec."Period Type"::Day);
            Period.SetRange("Period Start");
        end;
        if PeriodPageMgt.FindDate(SearchText, Period, Rec."Period Type") then
            if Rec."Closing Entries" = Rec."Closing Entries"::Include then
                Period."Period End" := ClosingDate(Period."Period End");
        if Rec."Amount Type" = Rec."Amount Type"::"Net Change" then begin
            GLAcc.SetRange("Date Filter", Period."Period Start", Period."Period End");
            if GLAcc.GetRangeMin("Date Filter") = GLAcc.GetRangeMax("Date Filter") then
                GLAcc.SetRange("Date Filter", GLAcc.GetRangeMin("Date Filter"));
        end else
            GLAcc.SetRange("Date Filter", 0D, Period."Period End");

        InternalDateFilter := GLAcc.GetFilter("Date Filter");
        if (LineDimOption <> LineDimOption::Period) and (ColumnDimOption <> ColumnDimOption::Period) then
            Rec."Date Filter" := InternalDateFilter;
    end;

    local procedure GetDimSelection(OldDimSelCode: Text[30]): Text[30]
    var
        DimSelection: Page "Dimension Selection";
    begin
        DimSelection.InsertDimSelBuf(false, GLAcc.TableCaption(), GLAcc.TableCaption());
        DimSelection.InsertDimSelBuf(false, BusUnit.TableCaption(), BusUnit.TableCaption());
        DimSelection.InsertDimSelBuf(false, Text001, Text001);
        if GLSetup."Global Dimension 1 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, GLSetup."Global Dimension 1 Code", '');
        if GLSetup."Global Dimension 2 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, GLSetup."Global Dimension 2 Code", '');

        OnGetDimSelectionOnBeforeDimSelectionLookup(GLSetup, DimSelection);

        DimSelection.LookupMode := true;
        if DimSelection.RunModal() = ACTION::LookupOK then
            exit(DimSelection.GetDimSelCode());

        exit(OldDimSelCode);
    end;

    local procedure ValidateLineDimCode()
    begin
        if IsNotValidDefinition(LineDimCode) then begin
            Message(Text002, LineDimCode);
            LineDimCode := '';
        end;
        LineDimOption := DimCodeToOption(LineDimCode);
        InternalDateFilter := GLAcc.GetFilter("Date Filter");
        if (LineDimOption <> LineDimOption::Period) and (ColumnDimOption <> ColumnDimOption::Period) then begin
            Rec."Date Filter" := InternalDateFilter;
            if StrPos(Rec."Date Filter", '&') > 1 then
                Rec."Date Filter" := CopyStr(Rec."Date Filter", 1, StrPos(Rec."Date Filter", '&') - 1);
        end else
            PeriodInitialized := false;
    end;

    local procedure ValidateColumnDimCode()
    begin
        if IsNotValidDefinition(ColumnDimCode) then begin
            Message(Text003, ColumnDimCode);
            ColumnDimCode := '';
        end;
        ColumnDimOption := DimCodeToOption(ColumnDimCode);
        InternalDateFilter := GLAcc.GetFilter("Date Filter");
        if (LineDimOption <> LineDimOption::Period) and (ColumnDimOption <> ColumnDimOption::Period) then begin
            Rec."Date Filter" := InternalDateFilter;
            if StrPos(Rec."Date Filter", '&') > 1 then
                Rec."Date Filter" := CopyStr(Rec."Date Filter", 1, StrPos(Rec."Date Filter", '&') - 1);
        end else
            PeriodInitialized := false;
    end;

    local procedure IsNotValidDefinition(DimCode: Text[30]) Result: Boolean
    begin
        Result := (UpperCase(DimCode) <> UpperCase(GLAcc.TableCaption())) and
           (UpperCase(DimCode) <> UpperCase(BusUnit.TableCaption())) and
           (UpperCase(DimCode) <> UpperCase(Text001)) and
           (UpperCase(DimCode) <> GLSetup."Global Dimension 1 Code") and
           (UpperCase(DimCode) <> GLSetup."Global Dimension 2 Code") and
           (DimCode <> '');

        OnAfterIsNotValidDefinition(GLSetup, DimCode, Result);
    end;

    local procedure FindRec(DimOption: Option "G/L Account",Period,"Business Unit","Dimension 1","Dimension 2"; var DimCodeBuf: Record "Dimension Code Buffer"; Which: Text[250]): Boolean
    var
        GLAcc: Record "G/L Account";
        BusUnit: Record "Business Unit";
        Period: Record Date;
        DimVal: Record "Dimension Value";
        PeriodPageMgt: Codeunit PeriodPageManagement;
        Found: Boolean;
    begin
        OnBeforeFindRec(DimOption, DimVal, GLAcc);
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
            DimOption::Period:
                begin
                    if not PeriodInitialized then
                        Rec."Date Filter" := '';
                    PeriodInitialized := true;
                    Evaluate(Period."Period Start", DimCodeBuf.Code);
                    if Rec."Date Filter" <> '' then
                        Period.SetFilter("Period Start", Rec."Date Filter")
                    else
                        if not PeriodInitialized and (InternalDateFilter <> '') then
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
            DimOption::"Dimension 1":
                begin
                    if Rec."Dimension 1 Filter" <> '' then
                        DimVal.SetFilter(Code, Rec."Dimension 1 Filter");
                    DimVal."Dimension Code" := GLSetup."Global Dimension 1 Code";
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
                    DimVal."Dimension Code" := GLSetup."Global Dimension 2 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            else
                OnFindRecCaseElse(Rec, DimOption, GLSetup, Found, DimCodeBuf, Which);
        end;
        exit(Found);
    end;

    local procedure NextRec(DimOption: Option "G/L Account",Period,"Business Unit","Dimension 1","Dimension 2"; var DimCodeBuf: Record "Dimension Code Buffer"; Steps: Integer): Integer
    var
        GLAcc: Record "G/L Account";
        BusUnit: Record "Business Unit";
        Period: Record Date;
        DimVal: Record "Dimension Value";
        PeriodPageMgt: Codeunit PeriodPageManagement;
        ResultSteps: Integer;
    begin
        OnBeforeNextRec(DimOption, DimVal, GLAcc);
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
            DimOption::Period:
                begin
                    if Rec."Date Filter" <> '' then
                        Period.SetFilter("Period Start", Rec."Date Filter");
                    Evaluate(Period."Period Start", DimCodeBuf.Code);
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
            DimOption::"Dimension 1":
                begin
                    if Rec."Dimension 1 Filter" <> '' then
                        DimVal.SetFilter(Code, Rec."Dimension 1 Filter");
                    DimVal."Dimension Code" := GLSetup."Global Dimension 1 Code";
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
                    DimVal."Dimension Code" := GLSetup."Global Dimension 2 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            else
                OnNextRecCaseElse(Rec, DimOption, GLSetup, ResultSteps, DimCodeBuf, Steps);
        end;
        exit(ResultSteps);
    end;

    protected procedure GenerateColumnCaptions(StepType: Enum "Matrix Page Step Type")
    var
        CurrentColumn: Record "Dimension Code Buffer";
        Found: Boolean;
        Which: Text[30];
    begin
        MATRIX_CurrSetLength := 0;
        Clear(MATRIX_ColumnCaptions);
        Rec."Column Set" := '';

        case StepType of
            "Matrix Page Step Type"::Initial:
                begin
                    if (ColumnDimOption = ColumnDimOption::Period) and (Rec."Period Type" <> Rec."Period Type"::"Accounting Period")
                       and (Rec."Date Filter" = '')
                    then begin
                        Evaluate(CurrentColumn.Code, Format(WorkDate()));
                        Which := '=><';
                    end else
                        Which := '-';
                    Found := FindRec(ColumnDimOption, CurrentColumn, Which);
                end;
            "Matrix Page Step Type"::Previous:
                begin
                    CurrentColumn.SetPosition(MATRIX_PrimaryKeyFirstColInSet);
                    Found := FindRec(ColumnDimOption, CurrentColumn, '=');
                    NextRec(ColumnDimOption, CurrentColumn, -MATRIX_NoOfColumns)
                end;
            "Matrix Page Step Type"::Same:
                begin
                    CurrentColumn.SetPosition(MATRIX_PrimaryKeyFirstColInSet);
                    Found := FindRec(ColumnDimOption, CurrentColumn, '=');
                end;
            "Matrix Page Step Type"::Next:
                begin
                    CurrentColumn.SetPosition(MATRIX_PrimaryKeyFirstColInSet);
                    Found := FindRec(ColumnDimOption, CurrentColumn, '=');
                    if not (NextRec(ColumnDimOption, CurrentColumn, MATRIX_NoOfColumns) = MATRIX_NoOfColumns) then begin
                        CurrentColumn.SetPosition(MATRIX_PrimaryKeyFirstColInSet);
                        Found := FindRec(ColumnDimOption, CurrentColumn, '=');
                    end
                end;
        end;

        MATRIX_PrimaryKeyFirstColInSet := CurrentColumn.GetPosition();

        if Found then begin
            repeat
                MATRIX_CurrSetLength := MATRIX_CurrSetLength + 1;
                if Rec."Show Column Name" then
                    MATRIX_ColumnCaptions[MATRIX_CurrSetLength] := CurrentColumn.Name
                else
                    MATRIX_ColumnCaptions[MATRIX_CurrSetLength] := CurrentColumn.Code;
            until (MATRIX_CurrSetLength = MATRIX_NoOfColumns) or (NextRec(ColumnDimOption, CurrentColumn, 1) <> 1);

            if MATRIX_CurrSetLength = 1 then
                Rec."Column Set" := MATRIX_ColumnCaptions[1]
            else
                Rec."Column Set" := MATRIX_ColumnCaptions[1] + '..' + MATRIX_ColumnCaptions[MATRIX_CurrSetLength];
        end;
    end;

    local procedure ColumnDimCodeOnAfterValidate()
    begin
        GenerateColumnCaptions("Matrix Page Step Type"::Initial);
    end;

    local procedure DateFilterOnAfterValidate()
    begin
        if ColumnDimOption = ColumnDimOption::Period then begin
            PeriodInitialized := true;
            GenerateColumnCaptions("Matrix Page Step Type"::Initial);
        end;
    end;

    local procedure GLAccFilterOnAfterValidate()
    begin
        if ColumnDimOption = ColumnDimOption::"G/L Account" then
            GenerateColumnCaptions("Matrix Page Step Type"::Initial);
    end;

    local procedure GlobalDim2FilterOnAfterValidat()
    begin
        if ColumnDimOption = ColumnDimOption::"Dimension 2" then
            GenerateColumnCaptions("Matrix Page Step Type"::Initial);
    end;

    local procedure GlobalDim1FilterOnAfterValidat()
    begin
        if ColumnDimOption = ColumnDimOption::"Dimension 1" then
            GenerateColumnCaptions("Matrix Page Step Type"::Initial);
    end;

    local procedure BusUnitFilterOnAfterValidate()
    begin
        if ColumnDimOption = ColumnDimOption::"Business Unit" then
            GenerateColumnCaptions("Matrix Page Step Type"::Initial);
    end;

    local procedure ShowColumnNameOnAfterValidate()
    begin
        GenerateColumnCaptions("Matrix Page Step Type"::Same);
    end;

    local procedure PeriodTypeOnAfterValidate()
    begin
        if ColumnDimOption = ColumnDimOption::Period then
            GenerateColumnCaptions("Matrix Page Step Type"::Initial);
    end;

    local procedure AmountTypeOnAfterValidate()
    begin
        if ColumnDimOption = ColumnDimOption::Period then
            GenerateColumnCaptions("Matrix Page Step Type"::Initial);
    end;

    local procedure SetDateFilter(DateFilter: Text[250])
    var
        FilterTokens: Codeunit "Filter Tokens";
        Date1: Date;
    begin
        FilterTokens.MakeDateFilter(DateFilter);
        if DateFilter <> '' then
            if Evaluate(Date1, DateFilter) then
                if Date1 <> NormalDate(Date1) then
                    DateFilter := StrSubstNo('%1..%2', NormalDate(Date1), Date1);
        GLAcc.SetFilter("Date Filter", DateFilter);
        DateFilter := GLAcc.GetFilter("Date Filter");
        InternalDateFilter := DateFilter;
        DateFilterOnAfterValidate();
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterOnInit()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDimCodeToOption(DimCode: Text[30]; GeneralLedgerSetup: Record "General Ledger Setup"; var Result: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsNotValidDefinition(GeneralLedgerSetup: Record "General Ledger Setup"; var DimCode: Text[30]; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGLAccFilter(var GLAccount: Record "G/L Account"; var GLAccFilter: Text; LineDimOption: Option "G/L Account",Period,"Business Unit","Dimension 1","Dimension 2","Dimension 3","Dimension 4"; ColumnDimOption: Option "G/L Account",Period,"Business Unit","Dimension 1","Dimension 2","Dimension 3","Dimension 4")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindRec(DimOption: Option; var DimensionValue: Record "Dimension Value"; var GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNextRec(DimOption: Option; var DimensionValue: Record "Dimension Value"; var GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnFindRecCaseElse(AnalysisByDimParameters: Record "Analysis by Dim. Parameters"; DimOption: Integer; GeneralLedgerSetup: Record "General Ledger Setup"; var Found: Boolean; var DimensionCodeBuffer: Record "Dimension Code Buffer"; Which: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDimSelectionOnBeforeDimSelectionLookup(GeneralLedgerSetup: Record "General Ledger Setup"; var DimensionSelection: Page "Dimension Selection")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnNextRecCaseElse(AnalysisByDimParameters: Record "Analysis by Dim. Parameters"; DimOption: Integer; GeneralLedgerSetup: Record "General Ledger Setup"; var ResultSteps: Integer; var DimensionCodeBuffer: Record "Dimension Code Buffer"; Steps: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnShowMatrixActionOnBeforeRunModal(var GLBalancebyDimMatrix: Page "G/L Balance by Dim. Matrix")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnOnOpenPageOnBeforeFindPeriod(GeneralLedgerSetup: Record "General Ledger Setup"; var GLAccount: Record "G/L Account")
    begin
    end;
}

