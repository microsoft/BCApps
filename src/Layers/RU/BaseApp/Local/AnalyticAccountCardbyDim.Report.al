#pragma warning disable AA0247
report 14940 "Analytic Account Card by Dim."
{
    ApplicationArea = Basic, Suite;
    Caption = 'Analytic Account Card by Dim.';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(GLAccountBuffer; "Integer")
        {
            DataItemTableView = sorting(Number);
            dataitem("Dimension Value"; "Dimension Value")
            {
                DataItemTableView = sorting("Dimension Code", Code);
                dataitem("Integer"; "Integer")
                {
                    DataItemTableView = sorting(Number);

                    trigger OnAfterGetRecord()
                    var
                        GLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry";
                    begin
                        if Number = 1 then
                            GLCorrBuffer.FindFirst()
                        else
                            GLCorrBuffer.Next();

                        ExcelMgt.CopyRow(LineCounter);

                        GLCorrAnalysisViewEntry.SetRange("G/L Corr. Analysis View Code", GLCorrAnalysisViewCode);
                        GLCorrAnalysisViewEntry.SetFilter("Business Unit Code", BusUnitFilter);
                        SetDimensionFilters(GLCorrAnalysisViewEntry, "Dimension Value".Code);
                        GLCorrAnalysisViewEntry.SetRange("Posting Date", StartDate, EndDate);
                        GLCorrAnalysisViewEntry.SetRange("Debit Account No.", GLCorrBuffer."Debit Account No.");
                        GLCorrAnalysisViewEntry.SetRange("Credit Account No.", GLCorrBuffer."Credit Account No.");
                        GLCorrAnalysisViewEntry.CalcSums(Amount);

                        ExcelMgt.FillCell('A' + Format(LineCounter), '  ' + "Dimension Value".Code);

                        if SheetBuffer."No." = GLCorrBuffer."Debit Account No." then begin
                            GLAccount.Get(GLCorrBuffer."Credit Account No.");
                            ExcelMgt.FillCell('B' + Format(LineCounter), FormatAmount(GLCorrAnalysisViewEntry.Amount));
                            ExcelMgt.FillCell('E' + Format(LineCounter), GLCorrBuffer."Credit Account No.");
                            ExcelMgt.FillCell('F' + Format(LineCounter), GLAccount.Name);
                            ExcelMgt.FillCell('G' + Format(LineCounter), FormatAmount(GLCorrAnalysisViewEntry.Amount));
                            TotalDimDebitAmount += GLCorrAnalysisViewEntry.Amount;
                        end else begin
                            GLAccount.Get(GLCorrBuffer."Debit Account No.");
                            ExcelMgt.FillCell('C' + Format(LineCounter), FormatAmount(GLCorrAnalysisViewEntry.Amount));
                            ExcelMgt.FillCell('D' + Format(LineCounter), GLCorrBuffer."Debit Account No.");
                            ExcelMgt.FillCell('F' + Format(LineCounter), GLAccount.Name);
                            ExcelMgt.FillCell('G' + Format(LineCounter), FormatAmount(-GLCorrAnalysisViewEntry.Amount));
                            TotalDimCreditAmount += GLCorrAnalysisViewEntry.Amount;
                        end;

                        LineCounter += 1;
                    end;

                    trigger OnPostDataItem()
                    begin
                        if Count >= 1 then begin
                            ExcelMgt.CopyRow(LineCounter);
                            ExcelMgt.FillCell(
                              'A' + Format(LineCounter),
                              StrSubstNo(Text004, "Dimension Value"."Dimension Code", "Dimension Value".Code));
                            ExcelMgt.FillCell('B' + Format(LineCounter), FormatAmount(TotalDimDebitAmount));
                            ExcelMgt.FillCell('C' + Format(LineCounter), FormatAmount(TotalDimCreditAmount));
                            LineCounter += 1;
                        end;

                        TotalDebitAmount += TotalDimDebitAmount;
                        TotalCreditAmount += TotalDimCreditAmount;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, GLCorrBuffer.Count);

                        if Count >= 1 then begin
                            ExcelMgt.CopyRow(LineCounter);
                            ExcelMgt.FillCell('A' + Format(LineCounter), "Dimension Value"."Dimension Code" + ' ' + "Dimension Value".Code);
                            LineCounter += 1;
                        end;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    FillGLCorrBuffer(SheetBuffer."No.", Code);
                    TotalDimDebitAmount := 0;
                    TotalDimCreditAmount := 0;
                end;

                trigger OnPostDataItem()
                var
                    EndingBalanceAmount: Decimal;
                begin
                    ExcelMgt.DeleteRows(LineCounter, LineCounter);
                    ExcelMgt.FillCell(
                      'A' + Format(LineCounter),
                      StrSubstNo(Text004, SheetBuffer."No.", SheetBuffer.Name));
                    ExcelMgt.FillCell('B' + Format(LineCounter), FormatAmount(TotalDebitAmount));
                    ExcelMgt.FillCell('C' + Format(LineCounter), FormatAmount(TotalCreditAmount));
                    LineCounter += 2;

                    EndingBalanceAmount := BeginningBalanceAmount + TotalDebitAmount - TotalCreditAmount;

                    if EndingBalanceAmount > 0 then
                        ExcelMgt.FillCell('B' + Format(LineCounter), FormatAmount(EndingBalanceAmount))
                    else
                        ExcelMgt.FillCell('C' + Format(LineCounter), FormatAmount(-EndingBalanceAmount));
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Dimension Code", DimensionCode);
                    case DimOption of
                        0:
                            SetFilter(Code, DebitDim1Filter);
                        1:
                            SetFilter(Code, DebitDim2Filter);
                        2:
                            SetFilter(Code, DebitDim3Filter);
                        3:
                            SetFilter(Code, CreditDim1Filter);
                        4:
                            SetFilter(Code, CreditDim2Filter);
                        5:
                            SetFilter(Code, CreditDim3Filter);
                    end;

                    LineCounter := 13;
                end;
            }

            trigger OnAfterGetRecord()
            var
                GLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry";
            begin
                if Number = 1 then
                    SheetBuffer.FindFirst()
                else
                    SheetBuffer.Next();

                GLAccount.Get(SheetBuffer."No.");
                ExcelMgt.OpenSheet(SheetBuffer."Search Name");
                FillSheetHeader();

                GLCorrAnalysisViewEntry.Reset();
                GLCorrAnalysisViewEntry.SetRange("G/L Corr. Analysis View Code", GLCorrAnalysisViewCode);
                GLCorrAnalysisViewEntry.SetFilter("Business Unit Code", BusUnitFilter);
                GLCorrAnalysisViewEntry.SetRange("Debit Account No.", GLAccount."No.");
                SetDimensionFilters(GLCorrAnalysisViewEntry, '');
                GLCorrAnalysisViewEntry.SetFilter("Posting Date", '..%1', StartDate - 1);
                GLCorrAnalysisViewEntry.CalcSums(Amount);
                BeginningBalanceAmount := GLCorrAnalysisViewEntry.Amount;
                GLCorrAnalysisViewEntry.SetRange("Debit Account No.");
                GLCorrAnalysisViewEntry.SetRange("Credit Account No.", GLAccount."No.");
                GLCorrAnalysisViewEntry.CalcSums(Amount);
                BeginningBalanceAmount -= GLCorrAnalysisViewEntry.Amount;
                if BeginningBalanceAmount > 0 then
                    ExcelMgt.FillCell('B8', FormatAmount(BeginningBalanceAmount))
                else
                    ExcelMgt.FillCell('C8', FormatAmount(-BeginningBalanceAmount));

                ExcelMgt.CopyRow(12);
                ExcelMgt.FillCell('A12', GLAccount."No." + ' ' + GLAccount.Name);

                TotalDimDebitAmount := 0;
                TotalDimCreditAmount := 0;
                TotalDebitAmount := 0;
                TotalCreditAmount := 0;

                Counter += 1;
                Window.Update(2, Round(Counter / TotalQty * 10000, 1));
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Number, 1, SheetBuffer.Count);

                if TotalQty = 0 then begin
                    Message(Text007);
                    ExcelMgt.CloseBook();
                    CurrReport.Quit();
                end;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    group(General)
                    {
                        Caption = 'General';
                        field(StartDate; StartDate)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Starting Date';
                            ToolTip = 'Specifies the beginning of the period for which entries are adjusted. This field is usually left blank, but you can enter a date.';
                        }
                        field(EndDate; EndDate)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Ending Date';
                            ToolTip = 'Specifies the date to which the report or batch job processes information.';
                        }
                        field(GLCorrAnalysisViewCode; GLCorrAnalysisViewCode)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'G/L Corr. Analysis View Code';
                            TableRelation = "G/L Corr. Analysis View";
                        }
                        field(BusUnitFilter; BusUnitFilter)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Business Unit Filter';
                            TableRelation = "Business Unit";
                            ToolTip = 'Specifies which group company unit the data is shown for.';
                        }
                        field(GLAccountFilter; GLAccountFilter)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'G/L Account Filter';
                            TableRelation = "G/L Account";
                            ToolTip = 'Specifies the G/L accounts by which data is shown.';
                        }
                        field(DimGroupType; DimGroupType)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Dimension Group Type';
                            OptionCaption = 'Debit,Credit';
                        }
                        field(DimensionCode; DimensionCode)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Dimension Code';

                            trigger OnLookup(var Text: Text): Boolean
                            var
                                NewCode: Text[30];
                            begin
                                NewCode := GetDimSelection(DimensionCode);
                                if NewCode = DimensionCode then
                                    exit(false);

                                Text := NewCode;
                                DimensionCode := NewCode;
                                ValidateLineDimCode();
                                RequestOptionsPage.Update();
                                exit(true);
                            end;

                            trigger OnValidate()
                            begin
                                ValidateLineDimCode();
                            end;
                        }
                        field(SkipZeroNetChangeAccounts; SkipZeroNetChangeAccounts)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Skip Zero Net Change Accounts';
                        }
                    }
                    group("Debit Dimension Filters")
                    {
                        Caption = 'Debit Dimension Filters';
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
                        }
                    }
                    group("Credit Dimension Filters")
                    {
                        Caption = 'Credit Dimension Filters';
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
                        }
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            CreditDim3FilterEnable := true;
            CreditDim2FilterEnable := true;
            CreditDim1FilterEnable := true;
            DebitDim3FilterEnable := true;
            DebitDim2FilterEnable := true;
            DebitDim1FilterEnable := true;
        end;

        trigger OnOpenPage()
        begin
            if UseHiddenParameters then begin
                GLCorrAnalysisViewCode := HidGLCorrAnalysisViewCode;
                DimGroupType := HidDimGroupType;
                DimensionCode := HidDimensionCode;
                BusUnitFilter := HidBusUnitFilter;
                GLAccountFilter := HidGLAccountFilter;
                StartDate := HidStartDate;
                EndDate := HidEndDate;
                DebitDim1Filter := HidDebitDim1Filter;
                DebitDim2Filter := HidDebitDim2Filter;
                DebitDim3Filter := HidDebitDim3Filter;
                CreditDim1Filter := HidCreditDim1Filter;
                CreditDim2Filter := HidCreditDim2Filter;
                CreditDim3Filter := HidCreditDim3Filter;
            end;

            ValidateLineDimCode();
            PageUpdateFiltersControls();
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(GLSetup."Analytic Acc. Card Code"));
    end;

    trigger OnPreReport()
    begin
        if GLCorrAnalysisViewCode = '' then
            Error(Text002, Text008);

        if DimensionCode = '' then
            Error(Text002, Text005);

        if StartDate = 0D then
            Error(Text002, Text009);

        if EndDate = 0D then
            Error(Text002, Text010);

        GLSetup.Get();
        GLSetup.TestField("Analytic Acc. Card Code");

        FileName := ExcelTemplate.OpenTemplate(GLSetup."Analytic Acc. Card Code");

        GLCorrAnalysisView.Get(GLCorrAnalysisViewCode);
        ExcelMgt.OpenBookForUpdate(FileName);
        CreateSheets();
    end;

    var
        GLAccount: Record "G/L Account";
        SheetBuffer: Record "G/L Account" temporary;
        GLSetup: Record "General Ledger Setup";
        GLCorrAnalysisView: Record "G/L Corr. Analysis View";
        GLCorrBuffer: Record "G/L Correspondence" temporary;
        ExcelTemplate: Record "Excel Template";
        ExcelMgt: Codeunit "Excel Management";
        Window: Dialog;
        StartDate: Date;
        EndDate: Date;
        HidStartDate: Date;
        HidEndDate: Date;
        DimGroupType: Option Debit,Credit;
        HidDimGroupType: Option Debit,Credit;
        DimOption: Option "Debit Dimension 1","Debit Dimension 2","Debit Dimension 3","Credit Dimension 1","Credit Dimension 2","Credit Dimension 3";
        GLCorrAnalysisViewCode: Code[10];
        DimensionCode: Code[20];
        HidGLCorrAnalysisViewCode: Code[10];
        HidDimensionCode: Code[20];
        BusUnitFilter: Code[250];
        DebitDim1Filter: Code[250];
        DebitDim2Filter: Code[250];
        DebitDim3Filter: Code[250];
        CreditDim1Filter: Code[250];
        CreditDim2Filter: Code[250];
        CreditDim3Filter: Code[250];
        HidDebitDim1Filter: Code[250];
        HidDebitDim2Filter: Code[250];
        HidDebitDim3Filter: Code[250];
        HidCreditDim1Filter: Code[250];
        HidCreditDim2Filter: Code[250];
        HidCreditDim3Filter: Code[250];
        HidBusUnitFilter: Code[250];
        GLAccountFilter: Text[250];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label '%1 must be filled in.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        HidGLAccountFilter: Text[250];
        FileName: Text;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label '%1 is not a valid dimension.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        LineCounter: Integer;
        Counter: Integer;
        TotalQty: Integer;
        BeginningBalanceAmount: Decimal;
        TotalDimDebitAmount: Decimal;
        TotalDimCreditAmount: Decimal;
        TotalDebitAmount: Decimal;
        TotalCreditAmount: Decimal;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text004: Label 'Total, %1 %2';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text005: Label 'Dimension Code';
#pragma warning restore AA0074
        SkipZeroNetChangeAccounts: Boolean;
#pragma warning disable AA0074
        Text006: Label 'Sheets creating   @1@@@@@@@@@@@@@@\Sheets processing @2@@@@@@@@@@@@@@';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text007: Label 'No entries are found according to specified filters on the request form. There is nothing to export!';
#pragma warning restore AA0074
        UseHiddenParameters: Boolean;
#pragma warning disable AA0074
        Text008: Label 'G/L Corr. Analysis View Code';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text009: Label 'Starting Date';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text010: Label 'Ending Date';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text011: Label '1,6,,Debit Dimension 1 Filter';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text012: Label '1,6,,Debit Dimension 2 Filter';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text013: Label '1,6,,Debit Dimension 3 Filter';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text014: Label '1,6,,Credit Dimension 1 Filter';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text015: Label '1,6,,Credit Dimension 2 Filter';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text016: Label '1,6,,Credit Dimension 3 Filter';
#pragma warning restore AA0074
        DebitDim1FilterEnable: Boolean;
        DebitDim2FilterEnable: Boolean;
        DebitDim3FilterEnable: Boolean;
        CreditDim1FilterEnable: Boolean;
        CreditDim2FilterEnable: Boolean;
        CreditDim3FilterEnable: Boolean;

    [Scope('OnPrem')]
    procedure SetParameters(NewGLCorrAnViewCode: Code[20]; NewDimGroupType: Option Debit,Credit; NewDimCode: Code[20]; NewBusUnitFilter: Code[250]; NewGLAccNoFilter: Code[250]; NewStartDate: Date; NewEndDate: Date; NewDebitDim1Filter: Code[250]; NewDebitDim2Filter: Code[250]; NewDebitDim3Filter: Code[250]; NewCreditDim1Filter: Code[250]; NewCreditDim2Filter: Code[250]; NewCreditDim3Filter: Code[250])
    begin
        HidGLCorrAnalysisViewCode := NewGLCorrAnViewCode;
        HidDimGroupType := NewDimGroupType;
        HidDimensionCode := NewDimCode;
        HidBusUnitFilter := NewBusUnitFilter;
        HidGLAccountFilter := NewGLAccNoFilter;
        HidStartDate := NewStartDate;
        HidEndDate := NewEndDate;
        HidDebitDim1Filter := NewDebitDim1Filter;
        HidDebitDim2Filter := NewDebitDim2Filter;
        HidDebitDim3Filter := NewDebitDim3Filter;
        HidCreditDim1Filter := NewCreditDim1Filter;
        HidCreditDim2Filter := NewCreditDim2Filter;
        HidCreditDim3Filter := NewCreditDim3Filter;

        UseHiddenParameters := true;
    end;

    [Scope('OnPrem')]
    procedure CreateSheets()
    var
        SheetNo: Integer;
        LastSheetName: Text[30];
    begin
        FillSheetBuffer();

        Window.Open(Text006);

        SheetBuffer.Reset();
        TotalQty := SheetBuffer.Count();

        if SheetBuffer.FindLast() then
            repeat
                SheetNo := SheetNo + 1;
                if SheetNo = 1 then begin
                    ExcelMgt.OpenSheet('АК_сводная');
                    ExcelMgt.SetSheetName(SheetBuffer."Search Name");
                end else
                    ExcelMgt.CopySheet(LastSheetName, LastSheetName, SheetBuffer."Search Name");
                LastSheetName := SheetBuffer."Search Name";
                Window.Update(1, Round(SheetNo / TotalQty * 10000, 1));
            until SheetBuffer.Next(-1) = 0;
    end;

    [Scope('OnPrem')]
    procedure FillSheetBuffer()
    begin
        if GLAccountFilter <> '' then
            GLAccount.SetFilter("No.", GLAccountFilter);

        if GLAccount.FindSet() then
            repeat
                if CheckAccountNetChange(GLAccount."No.") then begin
                    SheetBuffer."No." := GLAccount."No.";
                    SheetBuffer.Name := GLAccount.Name;
                    SheetBuffer."Search Name" := GetSheetName(GLAccount."No.");
                    SheetBuffer.Insert();
                end;
            until GLAccount.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CheckAccountNetChange(AccountNo: Code[20]): Boolean
    var
        GLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry";
    begin
        if not SkipZeroNetChangeAccounts then
            exit(true);

        GLCorrAnalysisViewEntry.SetRange("G/L Corr. Analysis View Code", GLCorrAnalysisViewCode);
        GLCorrAnalysisViewEntry.SetRange("Debit Account No.", AccountNo);
        SetDimensionFilters(GLCorrAnalysisViewEntry, '');
        GLCorrAnalysisViewEntry.SetRange("Posting Date", StartDate, EndDate);
        GLCorrAnalysisViewEntry.CalcSums(Amount);
        if (not GLCorrAnalysisViewEntry.IsEmpty) and
           (GLCorrAnalysisViewEntry.Amount <> 0)
        then
            exit(true);

        GLCorrAnalysisViewEntry.SetRange("Debit Account No.");
        GLCorrAnalysisViewEntry.SetRange("Credit Account No.", AccountNo);
        GLCorrAnalysisViewEntry.CalcSums(Amount);
        if (not GLCorrAnalysisViewEntry.IsEmpty) and
           (GLCorrAnalysisViewEntry.Amount <> 0)
        then
            exit(true);

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure FormatAccountNo(AccountNo: Code[20]): Code[20]
    begin
        exit(ConvertStr(AccountNo, ':\/?*[]', '_______'));
    end;

    [Scope('OnPrem')]
    procedure GetSheetName(AccountNo: Code[20]) SheetName: Code[50]
    begin
        SheetName := FormatAccountNo(AccountNo);
        SheetBuffer.SetCurrentKey("Search Name");
        SheetBuffer.SetRange("Search Name", SheetName);
        if not SheetBuffer.IsEmpty() then
            exit(GetSheetName(SheetName + '_'));
    end;

    [Scope('OnPrem')]
    procedure FillSheetHeader()
    var
        DebitDimFilters: Text[1024];
        CreditDimFilters: Text[1024];
    begin
        ExcelMgt.FillCell('B2', StrSubstNo('%1..%2', StartDate, EndDate));
        ExcelMgt.FillCell('B3', GLAccountFilter);
        ExcelMgt.FillCell('B4', DimensionCode);

        if DebitDim1Filter <> '' then
            AddStrValue(DebitDimFilters, GLCorrAnalysisView."Debit Dimension 1 Code" + ': ' + DebitDim1Filter);
        if DebitDim2Filter <> '' then
            AddStrValue(DebitDimFilters, GLCorrAnalysisView."Debit Dimension 2 Code" + ': ' + DebitDim2Filter);
        if DebitDim3Filter <> '' then
            AddStrValue(DebitDimFilters, GLCorrAnalysisView."Debit Dimension 3 Code" + ': ' + DebitDim3Filter);
        if CreditDim1Filter <> '' then
            AddStrValue(CreditDimFilters, GLCorrAnalysisView."Credit Dimension 1 Code" + ': ' + CreditDim1Filter);
        if CreditDim2Filter <> '' then
            AddStrValue(CreditDimFilters, GLCorrAnalysisView."Credit Dimension 2 Code" + ': ' + CreditDim2Filter);
        if CreditDim3Filter <> '' then
            AddStrValue(CreditDimFilters, GLCorrAnalysisView."Credit Dimension 3 Code" + ': ' + CreditDim3Filter);

        ExcelMgt.FillCell('B5', DebitDimFilters);
        ExcelMgt.FillCell('B6', CreditDimFilters);
    end;

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

    local procedure ValidateLineDimCode()
    begin
        if GLCorrAnalysisView.Code <> GLCorrAnalysisViewCode then
            GLCorrAnalysisView.Get(GLCorrAnalysisViewCode);
        if (UpperCase(DimensionCode) <> GLCorrAnalysisView."Debit Dimension 1 Code") and
           (UpperCase(DimensionCode) <> GLCorrAnalysisView."Debit Dimension 2 Code") and
           (UpperCase(DimensionCode) <> GLCorrAnalysisView."Debit Dimension 3 Code") and
           (UpperCase(DimensionCode) <> GLCorrAnalysisView."Credit Dimension 1 Code") and
           (UpperCase(DimensionCode) <> GLCorrAnalysisView."Credit Dimension 2 Code") and
           (UpperCase(DimensionCode) <> GLCorrAnalysisView."Credit Dimension 3 Code") and
           (DimensionCode <> '')
        then begin
            Message(Text003, DimensionCode);
            DimensionCode := '';
        end;
        DimOption := DimCodeToOption(DimensionCode, DimGroupType);
    end;

    [Scope('OnPrem')]
    procedure SetDimensionFilters(var GLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry"; SelectedDimFilter: Text[250])
    begin
        GLCorrAnalysisViewEntry.FilterGroup(2);
        if DebitDim1Filter <> '' then
            GLCorrAnalysisViewEntry.SetFilter("Debit Dimension 1 Value Code", DebitDim1Filter);
        if DebitDim2Filter <> '' then
            GLCorrAnalysisViewEntry.SetFilter("Debit Dimension 2 Value Code", DebitDim2Filter);
        if DebitDim3Filter <> '' then
            GLCorrAnalysisViewEntry.SetFilter("Debit Dimension 3 Value Code", DebitDim3Filter);
        if CreditDim1Filter <> '' then
            GLCorrAnalysisViewEntry.SetFilter("Credit Dimension 1 Value Code", CreditDim1Filter);
        if CreditDim2Filter <> '' then
            GLCorrAnalysisViewEntry.SetFilter("Credit Dimension 2 Value Code", CreditDim2Filter);
        if CreditDim3Filter <> '' then
            GLCorrAnalysisViewEntry.SetFilter("Credit Dimension 3 Value Code", CreditDim3Filter);
        GLCorrAnalysisViewEntry.FilterGroup(0);

        if SelectedDimFilter <> '' then
            case DimOption of
                0:
                    GLCorrAnalysisViewEntry.SetFilter("Debit Dimension 1 Value Code", SelectedDimFilter);
                1:
                    GLCorrAnalysisViewEntry.SetFilter("Debit Dimension 2 Value Code", SelectedDimFilter);
                2:
                    GLCorrAnalysisViewEntry.SetFilter("Debit Dimension 3 Value Code", SelectedDimFilter);
                3:
                    GLCorrAnalysisViewEntry.SetFilter("Credit Dimension 1 Value Code", SelectedDimFilter);
                4:
                    GLCorrAnalysisViewEntry.SetFilter("Credit Dimension 2 Value Code", SelectedDimFilter);
                5:
                    GLCorrAnalysisViewEntry.SetFilter("Credit Dimension 3 Value Code", SelectedDimFilter);
            end
        else
            case DimOption of
                0:
                    GLCorrAnalysisViewEntry.SetRange("Debit Dimension 1 Value Code");
                1:
                    GLCorrAnalysisViewEntry.SetRange("Debit Dimension 2 Value Code");
                2:
                    GLCorrAnalysisViewEntry.SetRange("Debit Dimension 3 Value Code");
                3:
                    GLCorrAnalysisViewEntry.SetRange("Credit Dimension 1 Value Code");
                4:
                    GLCorrAnalysisViewEntry.SetRange("Credit Dimension 2 Value Code");
                5:
                    GLCorrAnalysisViewEntry.SetRange("Credit Dimension 3 Value Code");
            end;
    end;

    [Scope('OnPrem')]
    procedure FormatAmount(Amount: Decimal): Text[30]
    begin
        if Amount <> 0 then
            exit(Format(Amount, 0, '<Sign><Integer><Decimals>'));

        exit('');
    end;

    [Scope('OnPrem')]
    procedure FillGLCorrBuffer(AccountNo: Code[20]; DimValue: Code[20])
    var
        GLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry";
    begin
        GLCorrBuffer.Reset();
        GLCorrBuffer.DeleteAll();

        GLCorrAnalysisViewEntry.SetRange("G/L Corr. Analysis View Code", GLCorrAnalysisViewCode);
        GLCorrAnalysisViewEntry.SetRange("Debit Account No.", AccountNo);
        SetDimensionFilters(GLCorrAnalysisViewEntry, DimValue);
        GLCorrAnalysisViewEntry.SetRange("Posting Date", StartDate, EndDate);
        if GLCorrAnalysisViewEntry.FindSet() then
            repeat
                if not GLCorrBuffer.Get(
                     GLCorrAnalysisViewEntry."Debit Account No.",
                     GLCorrAnalysisViewEntry."Credit Account No.")
                then begin
                    GLCorrBuffer."Debit Account No." := GLCorrAnalysisViewEntry."Debit Account No.";
                    GLCorrBuffer."Credit Account No." := GLCorrAnalysisViewEntry."Credit Account No.";
                    GLCorrBuffer.Insert();
                    GLCorrAnalysisViewEntry.SetFilter("Credit Account No.", '>%1', GLCorrAnalysisViewEntry."Credit Account No.");
                end;
            until GLCorrAnalysisViewEntry.Next() = 0;

        GLCorrAnalysisViewEntry.SetRange("Debit Account No.");
        GLCorrAnalysisViewEntry.SetRange("Credit Account No.", AccountNo);
        if GLCorrAnalysisViewEntry.FindSet() then
            repeat
                if not GLCorrBuffer.Get(
                     GLCorrAnalysisViewEntry."Debit Account No.",
                     GLCorrAnalysisViewEntry."Credit Account No.")
                then begin
                    GLCorrBuffer."Debit Account No." := GLCorrAnalysisViewEntry."Debit Account No.";
                    GLCorrBuffer."Credit Account No." := GLCorrAnalysisViewEntry."Credit Account No.";
                    GLCorrBuffer.Insert();
                    GLCorrAnalysisViewEntry.SetFilter("Debit Account No.", '>%1', GLCorrAnalysisViewEntry."Debit Account No.");
                end;
            until GLCorrAnalysisViewEntry.Next() = 0;
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
        end else
            exit(false)
    end;

    local procedure GetCaptionClass(GLCorrAnalysisViewDimType: Integer): Text[250]
    begin
        if GLCorrAnalysisView.Code <> GLCorrAnalysisViewCode then
            if not GLCorrAnalysisView.Get(GLCorrAnalysisViewCode) then
                exit('');
        case GLCorrAnalysisViewDimType of
            1:
                begin
                    if GLCorrAnalysisView."Debit Dimension 1 Code" <> '' then
                        exit('1,6,' + GLCorrAnalysisView."Debit Dimension 1 Code");

                    exit(Text011);
                end;
            2:
                begin
                    if GLCorrAnalysisView."Debit Dimension 2 Code" <> '' then
                        exit('1,6,' + GLCorrAnalysisView."Debit Dimension 2 Code");

                    exit(Text012);
                end;
            3:
                begin
                    if GLCorrAnalysisView."Debit Dimension 3 Code" <> '' then
                        exit('1,6,' + GLCorrAnalysisView."Debit Dimension 3 Code");

                    exit(Text013);
                end;
            4:
                begin
                    if GLCorrAnalysisView."Credit Dimension 1 Code" <> '' then
                        exit('1,6,' + GLCorrAnalysisView."Credit Dimension 1 Code");

                    exit(Text014);
                end;
            5:
                begin
                    if GLCorrAnalysisView."Credit Dimension 2 Code" <> '' then
                        exit('1,6,' + GLCorrAnalysisView."Credit Dimension 2 Code");

                    exit(Text015);
                end;
            6:
                begin
                    if GLCorrAnalysisView."Credit Dimension 3 Code" <> '' then
                        exit('1,6,' + GLCorrAnalysisView."Credit Dimension 3 Code");

                    exit(Text016);
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure AddStrValue(var Str: Text[1024]; AddStr: Text[250])
    begin
        if AddStr <> '' then
            if Str <> '' then
                Str := Str + ', ' + AddStr
            else
                Str := AddStr;
    end;

    local procedure PageUpdateFiltersControls()
    begin
        DebitDim1FilterEnable := GLCorrAnalysisView."Debit Dimension 1 Code" <> '';
        DebitDim2FilterEnable := GLCorrAnalysisView."Debit Dimension 2 Code" <> '';
        DebitDim3FilterEnable := GLCorrAnalysisView."Debit Dimension 3 Code" <> '';
        CreditDim1FilterEnable := GLCorrAnalysisView."Credit Dimension 1 Code" <> '';
        CreditDim2FilterEnable := GLCorrAnalysisView."Credit Dimension 2 Code" <> '';
        CreditDim3FilterEnable := GLCorrAnalysisView."Credit Dimension 3 Code" <> '';
    end;
}

