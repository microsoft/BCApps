#pragma warning disable AA0247
page 14940 "G/L Corr. Analysis by Dim."
{
    ApplicationArea = Basic, Suite;
    Caption = 'G/L Correspondence Analysis by Dimensions';
    DataCaptionExpression = GLCorrAnalysisViewCode;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Document;
    SaveValues = true;
    SourceTable = "Dimension Code Buffer";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(GLCorrAnalysisViewCode; GLCorrAnalysisViewCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Corr. Analysis View Code';
                    TableRelation = "G/L Corr. Analysis View";

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        GLCorrAnalysisViewList: Page "G/L Corr. Analysis View List";
                    begin
                        GLCorrAnalysisViewList.LookupMode := true;
                        GLCorrAnalysisViewList.SetRecord(GLCorrAnalysisView);
                        if GLCorrAnalysisViewList.RunModal() = ACTION::LookupOK then begin
                            GLCorrAnalysisViewList.GetRecord(GLCorrAnalysisView);
                            GLCorrAnalysisViewCode := GLCorrAnalysisView.Code;
                            Text := GLCorrAnalysisView.Code;
                            ValidateGLCorrAnalysisViewCode();
                            ValidateLineDimCode();
                            CurrPage.Update();
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        ValidateGLCorrAnalysisViewCode();
                        ValidateLineDimCode();
                        CurrPage.Update();
                    end;
                }
                field(DimGroupType; DimGroupType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimension Group Type';
                    OptionCaption = 'Debit,Credit';

                    trigger OnValidate()
                    begin
                        DimGroupTypeOnAfterValidate();
                    end;
                }
                field(LineDimCode; LineDimCode)
                {
                    ApplicationArea = Basic, Suite;
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
                        CurrPage.Update();
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        ValidateLineDimCode();
                        CurrPage.Update();
                    end;
                }
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies the dates that will be used to filter the amounts in the window.';

                    trigger OnValidate()
                    var
                        GLAcc: Record "G/L Account";
                        FilterTokens: Codeunit "Filter Tokens";
                    begin
                        FilterTokens.MakeDateFilter(DateFilter);
                        GLAcc.SetFilter("Date Filter", DateFilter);
                        DateFilter := GLAcc.GetFilter("Date Filter");
                        StartDate := GLCorrAnalysisViewEntry.GetRangeMin("Posting Date");
                        EndDate := GLCorrAnalysisViewEntry.GetRangeMax("Posting Date");
                        CurrPage.Update();
                    end;
                }
                field(DebitAccFilter; DebitAccFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Debit Account Filter';
                    TableRelation = "G/L Account";

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field(CreditAccFilter; CreditAccFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Credit Account Filter';
                    TableRelation = "G/L Account";

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field(BusUnitFilter; BusUnitFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Business Unit Filter';
                    TableRelation = "Business Unit";
                    ToolTip = 'Specifies which group company unit the data is shown for.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View by';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        FindPeriod('');
                        CurrPage.Update();
                    end;
                }
                field(AmountType; AmountType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View as';
                    ToolTip = 'Specifies how amounts are displayed. Net Change: The net change in the balance for the selected period. Balance at Date: The balance as of the last day in the selected period.';

                    trigger OnValidate()
                    begin
                        FindPeriod('');
                        CurrPage.Update();
                    end;
                }
            }
            repeater(Control1210000)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = CodeEmphasize;

                    trigger OnAssistEdit()
                    begin
                        LookUpCode(LineDimCode, Rec.Code);
                    end;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = NameEmphasize;
                    ToolTip = 'Specifies the name of the related record.';
                }
                field(DebitAmount; DebitAmount)
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    ApplicationArea = Basic, Suite;
                    Caption = 'Debit Amount';
                    Editable = false;
                    ToolTip = 'Specifies the debit amount for the period on the line.';

                    trigger OnDrillDown()
                    begin
                        DrillDown(0);
                    end;
                }
                field(CreditAmount; CreditAmount)
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    ApplicationArea = Basic, Suite;
                    Caption = 'Credit Amount';
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        DrillDown(1);
                    end;
                }
            }
            group("Dimension Filters")
            {
                Caption = 'Dimension Filters';
                field(DebitDim1Filter; DebitDim1Filter)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = GetCaptionClass(1);
                    Caption = 'Debit Dimension 1 Filter';
                    Enabled = DebitDim1FilterEnable;
                    ToolTip = 'Specifies a filter for dimensions by which data is included.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookUpDimFilter(GLCorrAnalysisView."Debit Dimension 1 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field(DebitDim2Filter; DebitDim2Filter)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = GetCaptionClass(2);
                    Caption = 'Debit Dimension 2 Filter';
                    Enabled = DebitDim2FilterEnable;
                    ToolTip = 'Specifies a filter for dimensions by which data is included.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookUpDimFilter(GLCorrAnalysisView."Debit Dimension 2 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field(DebitDim3Filter; DebitDim3Filter)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = GetCaptionClass(3);
                    Caption = 'Debit Dimension 3 Filter';
                    Enabled = DebitDim3FilterEnable;
                    ToolTip = 'Specifies a filter for dimensions by which data is included.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookUpDimFilter(GLCorrAnalysisView."Debit Dimension 3 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field(CreditDim1Filter; CreditDim1Filter)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = GetCaptionClass(4);
                    Caption = 'Credit Dimension 1 Filter';
                    Enabled = CreditDim1FilterEnable;
                    ToolTip = 'Specifies a filter for dimensions by which data is included.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookUpDimFilter(GLCorrAnalysisView."Credit Dimension 1 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field(CreditDim2Filter; CreditDim2Filter)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = GetCaptionClass(5);
                    Caption = 'Credit Dimension 2 Filter';
                    Enabled = CreditDim2FilterEnable;
                    ToolTip = 'Specifies a filter for dimensions by which data is included.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookUpDimFilter(GLCorrAnalysisView."Credit Dimension 2 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field(CreditDim3Filter; CreditDim3Filter)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = GetCaptionClass(6);
                    Caption = 'Credit Dimension 3 Filter';
                    Enabled = CreditDim3FilterEnable;
                    ToolTip = 'Specifies a filter for dimensions by which data is included.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookUpDimFilter(GLCorrAnalysisView."Credit Dimension 3 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
            }
            group(Parameters)
            {
                Caption = 'Parameters';
                field(ClosingEntryFilter; ClosingEntryFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Closing Entries';
                    OptionCaption = 'Include,Exclude';
                    ToolTip = 'Specifies whether the balance shown will include closing entries. If you want to see the amounts on income statement accounts in closed years, you must exclude closing entries.';

                    trigger OnValidate()
                    begin
                        CalculateClosingDateFilter();
                        FindPeriod('=');
                        Rec.Amount := CalcDebitAmount();
                    end;
                }
                field(RoundingFactor; RoundingFactor)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Rounding Factor';
                    ToolTip = 'Specifies the factor that is used to round the amounts.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Previous Period")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Previous Period';
                Image = PreviousRecord;
                ToolTip = 'Previous Period';

                trigger OnAction()
                begin
                    FindPeriod('<=');
                end;
            }
            action("Next Period")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next Period';
                Image = NextRecord;
                ToolTip = 'Next Period';

                trigger OnAction()
                begin
                    FindPeriod('>=');
                end;
            }
            action("&Print")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    Print();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Previous Period_Promoted"; "Previous Period")
                {
                }
                actionref("Next Period_Promoted"; "Next Period")
                {
                }
                actionref("&Print_Promoted"; "&Print")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        NameIndent := 0;
        DebitAmount := CalcDebitAmount();
        CreditAmount := CalcCreditAmount();
        CodeOnFormat();
        NameOnFormat();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(FindRec(LineDimOption, Rec, Which));
    end;

    trigger OnInit()
    begin
        CreditDim3FilterEnable := true;
        CreditDim2FilterEnable := true;
        CreditDim1FilterEnable := true;
        DebitDim3FilterEnable := true;
        DebitDim2FilterEnable := true;
        DebitDim1FilterEnable := true;
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(NextRec(LineDimOption, Rec, Steps));
    end;

    trigger OnOpenPage()
    begin
        ValidateGLCorrAnalysisViewCode();

        GLSetup.Get();

        if LineDimCode = '' then
            LineDimCode := FindFirstDimension();
        LineDimOption := DimCodeToOption(LineDimCode, DimGroupType);

        CalculateClosingDateFilter();
        FindPeriod('');
    end;

    var
#pragma warning disable AA0074
        Text002: Label 'You have not yet defined an analysis view.';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label '%1 is not a valid line definition.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text005: Label '1,6,,Debit Dimension 1 Filter';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text006: Label '1,6,,Debit Dimension 2 Filter';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text007: Label '1,6,,Debit Dimension 3 Filter';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text008: Label '1,6,,Credit Dimension 1 Filter';
#pragma warning restore AA0074
        GLSetup: Record "General Ledger Setup";
        GLCorrAnalysisView: Record "G/L Corr. Analysis View";
        GLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry";
        GLCorrAnalysisViewCode: Code[10];
        LineDimOption: Option "Debit Dimension 1","Debit Dimension 2","Debit Dimension 3","Credit Dimension 1","Credit Dimension 2","Credit Dimension 3";
        LineDimCode: Text[30];
        PeriodType: Enum "Analysis Period Type";
        AmountType: Enum "Analysis Amount Type";
        RoundingFactor: Enum "Analysis Rounding Factor";
        ClosingEntryFilter: Option Include,Exclude;
        DimGroupType: Option Debit,Credit;
        DateFilter: Text;
        ExcludeClosingDateFilter: Text;
        DebitAccFilter: Text;
        CreditAccFilter: Text;
        DebitDim1Filter: Text;
        DebitDim2Filter: Text;
        DebitDim3Filter: Text;
        CreditDim1Filter: Text;
        CreditDim2Filter: Text;
        CreditDim3Filter: Text;
        BusUnitFilter: Text;
#pragma warning disable AA0074
        Text009: Label '1,6,,Credit Dimension 2 Filter';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text010: Label '1,6,,Credit Dimension 3 Filter';
#pragma warning restore AA0074
        DebitAmount: Decimal;
        CreditAmount: Decimal;
        StartDate: Date;
        EndDate: Date;
        CodeEmphasize: Boolean;
        NameEmphasize: Boolean;
        NameIndent: Integer;
        DebitDim1FilterEnable: Boolean;
        DebitDim2FilterEnable: Boolean;
        DebitDim3FilterEnable: Boolean;
        CreditDim1FilterEnable: Boolean;
        CreditDim2FilterEnable: Boolean;
        CreditDim3FilterEnable: Boolean;

    local procedure DimCodeToOption(DimCode: Code[30]; GroupType: Option Debit,Credit): Integer
    begin
        case GroupType of
            GroupType::Debit:
                case DimCode of
                    '':
                        exit(-1);
                    GLCorrAnalysisView."Debit Dimension 1 Code":
                        exit(0);
                    GLCorrAnalysisView."Debit Dimension 2 Code":
                        exit(1);
                    GLCorrAnalysisView."Debit Dimension 3 Code":
                        exit(2);
                    else
                        exit(-1);
                end;
            GroupType::Credit:
                case DimCode of
                    '':
                        exit(-1);
                    GLCorrAnalysisView."Credit Dimension 1 Code":
                        exit(3);
                    GLCorrAnalysisView."Credit Dimension 2 Code":
                        exit(4);
                    GLCorrAnalysisView."Credit Dimension 3 Code":
                        exit(5);
                    else
                        exit(-1);
                end;
        end;
    end;

    local procedure FindRec(DimOption: Option "Debit Dimension 1","Debit Dimension 2","Debit Dimension 3","Credit Dimension 1","Credit Dimension 2","Credit Dimension 3"; var DimCodeBuf: Record "Dimension Code Buffer"; Which: Text[250]): Boolean
    var
        DimVal: Record "Dimension Value";
        Found: Boolean;
    begin
        case DimOption of
            DimOption::"Debit Dimension 1":
                begin
                    if DebitDim1Filter <> '' then
                        DimVal.SetFilter(Code, DebitDim1Filter);
                    DimVal."Dimension Code" := GLCorrAnalysisView."Debit Dimension 1 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Debit Dimension 2":
                begin
                    if DebitDim2Filter <> '' then
                        DimVal.SetFilter(Code, DebitDim2Filter);
                    DimVal."Dimension Code" := GLCorrAnalysisView."Debit Dimension 2 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Debit Dimension 3":
                begin
                    if DebitDim3Filter <> '' then
                        DimVal.SetFilter(Code, DebitDim3Filter);
                    DimVal."Dimension Code" := GLCorrAnalysisView."Debit Dimension 3 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Credit Dimension 1":
                begin
                    if CreditDim1Filter <> '' then
                        DimVal.SetFilter(Code, CreditDim1Filter);
                    DimVal."Dimension Code" := GLCorrAnalysisView."Credit Dimension 1 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Credit Dimension 2":
                begin
                    if CreditDim2Filter <> '' then
                        DimVal.SetFilter(Code, CreditDim2Filter);
                    DimVal."Dimension Code" := GLCorrAnalysisView."Credit Dimension 2 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Credit Dimension 3":
                begin
                    if CreditDim3Filter <> '' then
                        DimVal.SetFilter(Code, CreditDim3Filter);
                    DimVal."Dimension Code" := GLCorrAnalysisView."Credit Dimension 3 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
        end;
        exit(Found);
    end;

    local procedure NextRec(DimOption: Option "Debit Dimension 1","Debit Dimension 2","Debit Dimension 3","Credit Dimension 1","Credit Dimension 2","Credit Dimension 3"; var DimCodeBuf: Record "Dimension Code Buffer"; Steps: Integer): Integer
    var
        DimVal: Record "Dimension Value";
        ResultSteps: Integer;
    begin
        case DimOption of
            DimOption::"Debit Dimension 1":
                begin
                    if DebitDim1Filter <> '' then
                        DimVal.SetFilter(Code, DebitDim1Filter);
                    DimVal."Dimension Code" := GLCorrAnalysisView."Debit Dimension 1 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Debit Dimension 2":
                begin
                    if DebitDim2Filter <> '' then
                        DimVal.SetFilter(Code, DebitDim2Filter);
                    DimVal."Dimension Code" := GLCorrAnalysisView."Debit Dimension 2 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Debit Dimension 3":
                begin
                    if DebitDim3Filter <> '' then
                        DimVal.SetFilter(Code, DebitDim3Filter);
                    DimVal."Dimension Code" := GLCorrAnalysisView."Debit Dimension 3 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Credit Dimension 1":
                begin
                    if CreditDim1Filter <> '' then
                        DimVal.SetFilter(Code, CreditDim1Filter);
                    DimVal."Dimension Code" := GLCorrAnalysisView."Credit Dimension 1 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Credit Dimension 2":
                begin
                    if CreditDim2Filter <> '' then
                        DimVal.SetFilter(Code, CreditDim2Filter);
                    DimVal."Dimension Code" := GLCorrAnalysisView."Credit Dimension 2 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Credit Dimension 3":
                begin
                    if CreditDim3Filter <> '' then
                        DimVal.SetFilter(Code, CreditDim3Filter);
                    DimVal."Dimension Code" := GLCorrAnalysisView."Credit Dimension 3 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
        end;
        exit(ResultSteps);
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
        PeriodPageManagement: Codeunit PeriodPageManagement;
    begin
        if DateFilter <> '' then begin
            Calendar.SetFilter("Period Start", DateFilter);
            if not PeriodPageManagement.FindDate('+', Calendar, PeriodType) then
                PeriodPageManagement.FindDate('+', Calendar, PeriodType::Day);
            Calendar.SetRange("Period Start");
        end;
        if PeriodPageManagement.FindDate(SearchText, Calendar, PeriodType) then
            if ClosingEntryFilter = ClosingEntryFilter::Include then
                Calendar."Period End" := ClosingDate(Calendar."Period End");
        if AmountType = AmountType::"Net Change" then begin
            GLCorrAnalysisViewEntry.SetRange("Posting Date", Calendar."Period Start", Calendar."Period End");
            if GLCorrAnalysisViewEntry.GetRangeMin("Posting Date") = GLCorrAnalysisViewEntry.GetRangeMax("Posting Date") then
                GLCorrAnalysisViewEntry.SetRange("Posting Date", GLCorrAnalysisViewEntry.GetRangeMin("Posting Date"));
        end else
            GLCorrAnalysisViewEntry.SetRange("Posting Date", 0D, Calendar."Period End");

        DateFilter := GLCorrAnalysisViewEntry.GetFilter("Posting Date");
        StartDate := GLCorrAnalysisViewEntry.GetRangeMin("Posting Date");
        EndDate := GLCorrAnalysisViewEntry.GetRangeMax("Posting Date");
    end;

    local procedure CalculateClosingDateFilter()
    var
        AccountingPeriod: Record "Accounting Period";
        FirstRec: Boolean;
    begin
        if ClosingEntryFilter = ClosingEntryFilter::Include then
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
                          ExcludeClosingDateFilter + StrSubstNo('&<>%1', ClosingDate(AccountingPeriod."Starting Date" - 1));
                    FirstRec := false;
                until AccountingPeriod.Next() = 0;
        end;
    end;

    local procedure GetDimSelection(OldDimSelCode: Text[30]): Text[30]
    var
        DimSelection: Page "Dimension Selection";
    begin
        case DimGroupType of
            DimGroupType::Debit:
                begin
                    if GLCorrAnalysisView."Debit Dimension 1 Code" <> '' then
                        DimSelection.InsertDimSelBuf(false, GLCorrAnalysisView."Debit Dimension 1 Code", '');
                    if GLCorrAnalysisView."Debit Dimension 2 Code" <> '' then
                        DimSelection.InsertDimSelBuf(false, GLCorrAnalysisView."Debit Dimension 2 Code", '');
                    if GLCorrAnalysisView."Debit Dimension 3 Code" <> '' then
                        DimSelection.InsertDimSelBuf(false, GLCorrAnalysisView."Debit Dimension 3 Code", '');
                end;
            DimGroupType::Credit:
                begin
                    if GLCorrAnalysisView."Credit Dimension 1 Code" <> '' then
                        DimSelection.InsertDimSelBuf(false, GLCorrAnalysisView."Credit Dimension 1 Code", '');
                    if GLCorrAnalysisView."Credit Dimension 2 Code" <> '' then
                        DimSelection.InsertDimSelBuf(false, GLCorrAnalysisView."Credit Dimension 2 Code", '');
                    if GLCorrAnalysisView."Credit Dimension 3 Code" <> '' then
                        DimSelection.InsertDimSelBuf(false, GLCorrAnalysisView."Credit Dimension 3 Code", '');
                end;
        end;
        DimSelection.LookupMode := true;
        if DimSelection.RunModal() = ACTION::LookupOK then
            exit(DimSelection.GetDimSelCode());

        exit(OldDimSelCode);
    end;

    local procedure LookUpCode(DimCode: Text[30]; "Code": Text[30])
    var
        DimVal: Record "Dimension Value";
        DimValList: Page "Dimension Value List";
    begin
        DimVal.SetRange("Dimension Code", DimCode);
        DimVal.Get(DimCode, Code);
        DimValList.SetTableView(DimVal);
        DimValList.SetRecord(DimVal);
        DimValList.RunModal();
    end;

    local procedure LookUpDimFilter(Dim: Code[20]; var Text: Text[250]): Boolean
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

    local procedure SetCommonFilters(var TheGLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry")
    var
        DateFilter2: Text;
    begin
        if DateFilter = '' then
            DateFilter2 := ExcludeClosingDateFilter
        else begin
            if AmountType = AmountType::"Net Change" then
                DateFilter2 := DateFilter
            else begin
                TheGLCorrAnalysisViewEntry.SetFilter("Posting Date", DateFilter);
                DateFilter2 := StrSubstNo('..%1', TheGLCorrAnalysisViewEntry.GetRangeMax("Posting Date"));
            end;
            if ExcludeClosingDateFilter <> '' then
                DateFilter2 := DateFilter2 + '&' + ExcludeClosingDateFilter;
        end;
        TheGLCorrAnalysisViewEntry.Reset();
        TheGLCorrAnalysisViewEntry.SetRange("G/L Corr. Analysis View Code", GLCorrAnalysisView.Code);
        if BusUnitFilter <> '' then
            TheGLCorrAnalysisViewEntry.SetFilter("Business Unit Code", BusUnitFilter);
        if DebitAccFilter <> '' then
            TheGLCorrAnalysisViewEntry.SetFilter("Debit Account No.", DebitAccFilter);
        if CreditAccFilter <> '' then
            TheGLCorrAnalysisViewEntry.SetFilter("Credit Account No.", CreditAccFilter);
        TheGLCorrAnalysisViewEntry.SetFilter("Posting Date", DateFilter2);
        if DebitDim1Filter <> '' then
            TheGLCorrAnalysisViewEntry.SetFilter("Debit Dimension 1 Value Code", DebitDim1Filter);
        if DebitDim2Filter <> '' then
            TheGLCorrAnalysisViewEntry.SetFilter("Debit Dimension 2 Value Code", DebitDim2Filter);
        if DebitDim3Filter <> '' then
            TheGLCorrAnalysisViewEntry.SetFilter("Debit Dimension 3 Value Code", DebitDim3Filter);
        if CreditDim1Filter <> '' then
            TheGLCorrAnalysisViewEntry.SetFilter("Credit Dimension 1 Value Code", CreditDim1Filter);
        if CreditDim2Filter <> '' then
            TheGLCorrAnalysisViewEntry.SetFilter("Credit Dimension 2 Value Code", CreditDim2Filter);
        if CreditDim3Filter <> '' then
            TheGLCorrAnalysisViewEntry.SetFilter("Credit Dimension 3 Value Code", CreditDim3Filter);
    end;

    local procedure SetDimFilters(var TheGLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry"; DimOption: Option "Debit Dimension 1","Debit Dimension 2","Debit Dimension 3","Credit Dimension 1","Credit Dimension 2","Credit Dimension 3")
    var
        DimCodeBuf: Record "Dimension Code Buffer";
    begin
        DimCodeBuf := Rec;

        case DimOption of
            DimOption::"Debit Dimension 1":
                if DimCodeBuf.Totaling = '' then
                    TheGLCorrAnalysisViewEntry.SetRange("Debit Dimension 1 Value Code", DimCodeBuf.Code)
                else
                    TheGLCorrAnalysisViewEntry.SetFilter("Debit Dimension 1 Value Code", DimCodeBuf.Totaling);
            DimOption::"Debit Dimension 2":
                if DimCodeBuf.Totaling = '' then
                    TheGLCorrAnalysisViewEntry.SetRange("Debit Dimension 2 Value Code", DimCodeBuf.Code)
                else
                    TheGLCorrAnalysisViewEntry.SetFilter("Debit Dimension 2 Value Code", DimCodeBuf.Totaling);
            DimOption::"Debit Dimension 3":
                if DimCodeBuf.Totaling = '' then
                    TheGLCorrAnalysisViewEntry.SetRange("Debit Dimension 3 Value Code", DimCodeBuf.Code)
                else
                    TheGLCorrAnalysisViewEntry.SetFilter("Debit Dimension 3 Value Code", DimCodeBuf.Totaling);
            DimOption::"Credit Dimension 1":
                if DimCodeBuf.Totaling = '' then
                    TheGLCorrAnalysisViewEntry.SetRange("Credit Dimension 1 Value Code", DimCodeBuf.Code)
                else
                    TheGLCorrAnalysisViewEntry.SetFilter("Credit Dimension 1 Value Code", DimCodeBuf.Totaling);
            DimOption::"Credit Dimension 2":
                if DimCodeBuf.Totaling = '' then
                    TheGLCorrAnalysisViewEntry.SetRange("Credit Dimension 2 Value Code", DimCodeBuf.Code)
                else
                    TheGLCorrAnalysisViewEntry.SetFilter("Credit Dimension 2 Value Code", DimCodeBuf.Totaling);
            DimOption::"Credit Dimension 3":
                if DimCodeBuf.Totaling = '' then
                    TheGLCorrAnalysisViewEntry.SetRange("Credit Dimension 3 Value Code", DimCodeBuf.Code)
                else
                    TheGLCorrAnalysisViewEntry.SetFilter("Credit Dimension 3 Value Code", DimCodeBuf.Totaling);
            else // filter for non-existing entries
                TheGLCorrAnalysisViewEntry.SetRange("Entry No.", -1);
        end;
    end;

    local procedure DrillDown(GroupType: Option Debit,Credit)
    var
        GLCorrByDim: Page "G/L Corr. by Dimension";
    begin
        GLCorrAnalysisViewEntry.Reset();
        SetCommonFilters(GLCorrAnalysisViewEntry);
        SetDimFilters(GLCorrAnalysisViewEntry, DimCodeToOption(LineDimCode, GroupType));
        GLCorrByDim.InitParameters(GLCorrAnalysisViewEntry);
        GLCorrByDim.RunModal();
    end;

    local procedure ValidateGLCorrAnalysisViewCode()
    var
        GLCorrAnalysisViewFilter: Record "Analysis View Filter";
    begin
        GLCorrAnalysisView.Code := GLCorrAnalysisViewCode;
        if not GLCorrAnalysisView.Find('=<>') then
            Error(Text002);
        GLCorrAnalysisViewCode := GLCorrAnalysisView.Code;
        DebitDim1Filter := '';
        DebitDim2Filter := '';
        DebitDim3Filter := '';
        CreditDim1Filter := '';
        CreditDim2Filter := '';
        CreditDim3Filter := '';
        DebitDim1Filter := Rec.GetFilter("Dimension 1 Value Filter");
        DebitDim2Filter := Rec.GetFilter("Dimension 2 Value Filter");
        DebitDim3Filter := Rec.GetFilter("Dimension 3 Value Filter");
        CreditDim1Filter := Rec.GetFilter("Credit Dim. 1 Value Filter");
        CreditDim2Filter := Rec.GetFilter("Credit Dim. 2 Value Filter");
        CreditDim3Filter := Rec.GetFilter("Credit Dim. 3 Value Filter");

        DebitDim1FilterEnable :=
          (GLCorrAnalysisView."Debit Dimension 1 Code" <> '') and
          (Rec.GetFilter("Dimension 1 Value Filter") = '');
        DebitDim2FilterEnable :=
          (GLCorrAnalysisView."Debit Dimension 2 Code" <> '') and
          (Rec.GetFilter("Dimension 2 Value Filter") = '');
        DebitDim3FilterEnable :=
          (GLCorrAnalysisView."Debit Dimension 3 Code" <> '') and
          (Rec.GetFilter("Dimension 3 Value Filter") = '');
        CreditDim1FilterEnable :=
          (GLCorrAnalysisView."Credit Dimension 1 Code" <> '') and
          (Rec.GetFilter("Credit Dim. 1 Value Filter") = '');
        CreditDim2FilterEnable :=
          (GLCorrAnalysisView."Credit Dimension 2 Code" <> '') and
          (Rec.GetFilter("Credit Dim. 2 Value Filter") = '');
        CreditDim3FilterEnable :=
          (GLCorrAnalysisView."Credit Dimension 3 Code" <> '') and
          (Rec.GetFilter("Credit Dim. 3 Value Filter") = '');

        if DebitDim1FilterEnable then
            if GLCorrAnalysisViewFilter.Get(GLCorrAnalysisView.Code, GLCorrAnalysisView."Debit Dimension 1 Code") then
                DebitDim1Filter := GLCorrAnalysisViewFilter."Dimension Value Filter";

        if DebitDim2FilterEnable then
            if GLCorrAnalysisViewFilter.Get(GLCorrAnalysisView.Code, GLCorrAnalysisView."Debit Dimension 2 Code") then
                DebitDim2Filter := GLCorrAnalysisViewFilter."Dimension Value Filter";

        if DebitDim3FilterEnable then
            if GLCorrAnalysisViewFilter.Get(GLCorrAnalysisView.Code, GLCorrAnalysisView."Debit Dimension 3 Code") then
                DebitDim3Filter := GLCorrAnalysisViewFilter."Dimension Value Filter";

        if CreditDim1FilterEnable then
            if GLCorrAnalysisViewFilter.Get(GLCorrAnalysisView.Code, GLCorrAnalysisView."Credit Dimension 1 Code") then
                CreditDim1Filter := GLCorrAnalysisViewFilter."Dimension Value Filter";

        if CreditDim2FilterEnable then
            if GLCorrAnalysisViewFilter.Get(GLCorrAnalysisView.Code, GLCorrAnalysisView."Credit Dimension 2 Code") then
                CreditDim2Filter := GLCorrAnalysisViewFilter."Dimension Value Filter";

        if CreditDim3FilterEnable then
            if GLCorrAnalysisViewFilter.Get(GLCorrAnalysisView.Code, GLCorrAnalysisView."Credit Dimension 3 Code") then
                CreditDim3Filter := GLCorrAnalysisViewFilter."Dimension Value Filter";
    end;

    local procedure ValidateLineDimCode()
    begin
        if (UpperCase(LineDimCode) <> GLCorrAnalysisView."Debit Dimension 1 Code") and
           (UpperCase(LineDimCode) <> GLCorrAnalysisView."Debit Dimension 2 Code") and
           (UpperCase(LineDimCode) <> GLCorrAnalysisView."Debit Dimension 3 Code") and
           (UpperCase(LineDimCode) <> GLCorrAnalysisView."Credit Dimension 1 Code") and
           (UpperCase(LineDimCode) <> GLCorrAnalysisView."Credit Dimension 2 Code") and
           (UpperCase(LineDimCode) <> GLCorrAnalysisView."Credit Dimension 3 Code") and
           (LineDimCode <> '')
        then begin
            Message(Text003, LineDimCode);
            LineDimCode := '';
        end;
        LineDimOption := DimCodeToOption(LineDimCode, DimGroupType);
        DateFilter := GLCorrAnalysisViewEntry.GetFilter("Posting Date");
    end;

    local procedure CalcDebitAmount(): Decimal
    var
        Amount: Decimal;
    begin
        GLCorrAnalysisViewEntry.Reset();
        SetCommonFilters(GLCorrAnalysisViewEntry);
        SetDimFilters(GLCorrAnalysisViewEntry, DimCodeToOption(LineDimCode, DimGroupType::Debit));

        GLCorrAnalysisViewEntry.CalcSums(Amount);
        Amount := GLCorrAnalysisViewEntry.Amount;

        exit(RoundAmount(Amount));
    end;

    local procedure CalcCreditAmount(): Decimal
    var
        Amount: Decimal;
    begin
        GLCorrAnalysisViewEntry.Reset();
        SetCommonFilters(GLCorrAnalysisViewEntry);
        SetDimFilters(GLCorrAnalysisViewEntry, DimCodeToOption(LineDimCode, DimGroupType::Credit));

        GLCorrAnalysisViewEntry.CalcSums(Amount);
        Amount := GLCorrAnalysisViewEntry.Amount;

        exit(RoundAmount(Amount));
    end;

    local procedure GetCaptionClass(GLCorrAnalysisViewDimType: Integer): Text[250]
    begin
        if GLCorrAnalysisView.Code <> GLCorrAnalysisViewCode then
            GLCorrAnalysisView.Get(GLCorrAnalysisViewCode);
        case GLCorrAnalysisViewDimType of
            1:
                begin
                    if GLCorrAnalysisView."Debit Dimension 1 Code" <> '' then
                        exit('1,6,' + GLCorrAnalysisView."Debit Dimension 1 Code");

                    exit(Text005);
                end;
            2:
                begin
                    if GLCorrAnalysisView."Debit Dimension 2 Code" <> '' then
                        exit('1,6,' + GLCorrAnalysisView."Debit Dimension 2 Code");

                    exit(Text006);
                end;
            3:
                begin
                    if GLCorrAnalysisView."Debit Dimension 3 Code" <> '' then
                        exit('1,6,' + GLCorrAnalysisView."Debit Dimension 3 Code");

                    exit(Text007);
                end;
            4:
                begin
                    if GLCorrAnalysisView."Credit Dimension 1 Code" <> '' then
                        exit('1,6,' + GLCorrAnalysisView."Credit Dimension 1 Code");

                    exit(Text008);
                end;
            5:
                begin
                    if GLCorrAnalysisView."Credit Dimension 2 Code" <> '' then
                        exit('1,6,' + GLCorrAnalysisView."Credit Dimension 2 Code");

                    exit(Text009);
                end;
            6:
                begin
                    if GLCorrAnalysisView."Credit Dimension 3 Code" <> '' then
                        exit('1,6,' + GLCorrAnalysisView."Credit Dimension 3 Code");

                    exit(Text010);
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure FindFirstDimension(): Code[20]
    begin
        case DimGroupType of
            DimGroupType::Debit:
                begin
                    if GLCorrAnalysisView."Debit Dimension 1 Code" <> '' then
                        exit(GLCorrAnalysisView."Debit Dimension 1 Code");
                    if GLCorrAnalysisView."Debit Dimension 2 Code" <> '' then
                        exit(GLCorrAnalysisView."Debit Dimension 2 Code");
                    if GLCorrAnalysisView."Debit Dimension 3 Code" <> '' then
                        exit(GLCorrAnalysisView."Debit Dimension 3 Code");
                end;
            DimGroupType::Credit:
                begin
                    if GLCorrAnalysisView."Credit Dimension 1 Code" <> '' then
                        exit(GLCorrAnalysisView."Credit Dimension 1 Code");
                    if GLCorrAnalysisView."Credit Dimension 2 Code" <> '' then
                        exit(GLCorrAnalysisView."Credit Dimension 2 Code");
                    if GLCorrAnalysisView."Credit Dimension 3 Code" <> '' then
                        exit(GLCorrAnalysisView."Credit Dimension 3 Code");
                end;
        end;

        exit('');
    end;

    [Scope('OnPrem')]
    procedure Print()
    var
        AnalyticAccountCardByDim: Report "Analytic Account Card by Dim.";
        ReportPeriodType: Option Month,Quarter,Year;
    begin
        case PeriodType of
            PeriodType::Month:
                ReportPeriodType := ReportPeriodType::Month;
            PeriodType::Quarter:
                ReportPeriodType := ReportPeriodType::Quarter;
            PeriodType::Year:
                ReportPeriodType := ReportPeriodType::Year;
            else
                ReportPeriodType := ReportPeriodType::Month;
        end;

        AnalyticAccountCardByDim.SetParameters(
          GLCorrAnalysisViewCode,
          DimGroupType,
          LineDimCode,
          BusUnitFilter,
          DebitAccFilter,
          StartDate,
          EndDate,
          DebitDim1Filter,
          DebitDim2Filter,
          DebitDim3Filter,
          CreditDim1Filter,
          CreditDim2Filter,
          CreditDim3Filter);

        AnalyticAccountCardByDim.RunModal();
    end;

    [Scope('OnPrem')]
    procedure SetAnalysisViewCode(NextAnalysisViewCode: Code[10])
    begin
        GLCorrAnalysisViewCode := NextAnalysisViewCode;
    end;

    local procedure DimGroupTypeOnAfterValidate()
    begin
        LineDimCode := FindFirstDimension();
        LineDimOption := DimCodeToOption(LineDimCode, DimGroupType);
        CurrPage.Update();
    end;

    local procedure CodeOnFormat()
    begin
        CodeEmphasize := Rec."Show in Bold";
    end;

    local procedure NameOnFormat()
    begin
        NameEmphasize := Rec."Show in Bold";
        NameIndent := Rec.Indentation;
    end;

    local procedure RoundAmount(Amount: Decimal): Decimal
    begin
        case RoundingFactor of
            RoundingFactor::"1":
                Amount := Round(Amount, 1);
            RoundingFactor::"1000":
                Amount := Round(Amount / 1000, 0.1);
            RoundingFactor::"1000000":
                Amount := Round(Amount / 1000000, 0.1);
        end;
        exit(Amount);
    end;
}

