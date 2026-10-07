#pragma warning disable AA0247
report 12440 "Customer Post. Gr. Turnover"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/CustomerPostGrTurnover.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer Posting Group Turnover';
    EnableHyperlinks = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Customer Posting Group"; "Customer Posting Group")
        {
            DataItemTableView = sorting(Code);
            RequestFilterFields = "Code";
            column(CurrentDate; CurrentDate)
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(USERID; UserId)
            {
            }
            column(Text005__FORMAT_StartDate___Text006__FORMAT_EndDate_; Text005 + Format(StartDate) + Text006 + Format(EndDate))
            {
            }
            column(RequestFilter; RequestFilter)
            {
            }
            column(AmountUnit; AmountUnit)
            {
            }
            column(ShowChart; ShowChart)
            {
            }
            column(LineText_1__Control1470006; LineText[1])
            {
            }
            column(TotalText_1_; TotalText[1])
            {
            }
            column(LineText_2__Control1470009; LineText[2])
            {
            }
            column(TotalText_2_; TotalText[2])
            {
            }
            column(TotalText_3_; TotalText[3])
            {
            }
            column(LineText_3__Control1470013; LineText[3])
            {
            }
            column(TotalText_4_; TotalText[4])
            {
            }
            column(LineText_4__Control1470016; LineText[4])
            {
            }
            column(LineText_5__Control1470018; LineText[5])
            {
            }
            column(TotalText_5_; TotalText[5])
            {
            }
            column(LineText_6__Control1470021; LineText[6])
            {
            }
            column(TotalText_6_; TotalText[6])
            {
            }
            column(ReportParameters_1_; ReportParameters[1])
            {
            }
            column(ReportParameters_2_; ReportParameters[2])
            {
            }
            column(ReportParameters_3_; ReportParameters[3])
            {
            }
            column(ReportParameters_4_; ReportParameters[4])
            {
            }
            column(Customer_Posting_GroupCaption; Customer_Posting_GroupCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(Turnover_SheetCaption; Turnover_SheetCaptionLbl)
            {
            }
            column(CodeCaption; CodeCaptionLbl)
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(Beginning_period_balanceCaption; Beginning_period_balanceCaptionLbl)
            {
            }
            column(DebitCaption; DebitCaptionLbl)
            {
            }
            column(CreditCaption; CreditCaptionLbl)
            {
            }
            column(Net_Change_for_PeriodCaption; Net_Change_for_PeriodCaptionLbl)
            {
            }
            column(DebitCaption_Control25; DebitCaption_Control25Lbl)
            {
            }
            column(CreditCaption_Control27; CreditCaption_Control27Lbl)
            {
            }
            column(Ending_period_balanceCaption; Ending_period_balanceCaptionLbl)
            {
            }
            column(DebitCaption_Control30; DebitCaption_Control30Lbl)
            {
            }
            column(CreditCaption_Control31; CreditCaption_Control31Lbl)
            {
            }
            column(Total_Caption; Total_CaptionLbl)
            {
            }
            dataitem(Customer; Customer)
            {
                DataItemLink = "Customer Posting Group" = field(Code);
                DataItemTableView = sorting("No.");
                RequestFilterFields = "Global Dimension 1 Filter", "Global Dimension 2 Filter", "Date Filter";

                trigger OnAfterGetRecord()
                begin
                    if StartDate > 0D then begin
                        SetRange("Date Filter", 0D, CalcDate('<-1D>', StartDate));
                        CalcFields("Net Change (LCY)");
                        RoundedValue := Round(Abs("Net Change (LCY)"), Decimals, '=');
                        if "Net Change (LCY)" > 0 then
                            LineAmount[1] := LineAmount[1] + RoundedValue
                        else
                            LineAmount[2] := LineAmount[2] + RoundedValue;
                    end;

                    SetRange("Date Filter", 0D, EndDate);
                    CalcFields("Net Change (LCY)");
                    RoundedValue := Round(Abs("Net Change (LCY)"), Decimals, '=');
                    if "Net Change (LCY)" > 0 then
                        LineAmount[5] := LineAmount[5] + RoundedValue
                    else
                        LineAmount[6] := LineAmount[6] + RoundedValue;

                    SetRange("Date Filter", StartDate, EndDate);
                    CalcFields("Debit Amount (LCY)", "Credit Amount (LCY)");
                    LineAmount[3] := LineAmount[3] + Round(Abs("Debit Amount (LCY)"), Decimals, '=');
                    LineAmount[4] := LineAmount[4] + Round(Abs("Credit Amount (LCY)"), Decimals, '=');
                end;

                trigger OnPreDataItem()
                begin
                    Clear(LineAmount);
                    Clear(LineText);
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(SkipZeroValues; SkipZeroValues)
                {
                }
                column(LineAmount_6_; LineAmount[6])
                {
                }
                column(LineAmount_5_; LineAmount[5])
                {
                }
                column(LineAmount_4_; LineAmount[4])
                {
                }
                column(LineAmount_3_; LineAmount[3])
                {
                }
                column(LineAmount_2_; LineAmount[2])
                {
                }
                column(LineAmount_1_; LineAmount[1])
                {
                }
                column(CustomerPostingGroupURL; Format(CustomerPostingGroupURL.RecordId, 0, 10))
                {
                }
                column(LineText_6_; LineText[6])
                {
                }
                column(LineText_5_; LineText[5])
                {
                }
                column(LineText_4_; LineText[4])
                {
                }
                column(LineText_3_; LineText[3])
                {
                }
                column(LineText_2_; LineText[2])
                {
                }
                column(LineText_1_; LineText[1])
                {
                }
                column(EmptyString; '')
                {
                }
                column(Customer_Posting_Group_Code; "Customer Posting Group".Code)
                {
                }
                column(Integer_Number; Number)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if SkipZeroBalances and (LineAmount[5] = 0) and (LineAmount[6] = 0) then
                        CurrReport.Skip();

                    if SkipZeroNetChanges and (LineAmount[3] = 0) and (LineAmount[4] = 0) then
                        CurrReport.Skip();

                    if SkipZeroLines and
                      (LineAmount[1] = 0) and (LineAmount[2] = 0) and
                      (LineAmount[3] = 0) and (LineAmount[4] = 0) and
                      (LineAmount[5] = 0) and (LineAmount[6] = 0) then
                        CurrReport.Skip();

                    for I := 1 to 6 do
                        TotalAmount[I] += LineAmount[I];

                    TextLineValues(SkipZeroValues);
                end;
            }

            trigger OnAfterGetRecord()
            var
            begin
                CustomerPostingGroupURL.SetPosition(GetPosition());
            end;

            trigger OnPreDataItem()
            begin
                CustomerPostingGroupURL.Open(DATABASE::"Customer Posting Group");
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
                    group(Printout)
                    {
                        Caption = 'Printout';
                        field("Rounding Precision"; RoundingPrecision)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Rounding Precision';
                            ToolTip = 'Specifies the size of the interval to be used when rounding amounts in the specified currency. You can specify invoice rounding for each currency in the Currency table.';
                        }
                        field("Replace zero values by blanks"; SkipZeroValues)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Replace zero values by blanks';
                            ToolTip = 'Specifies if you want all zero values on the report to be displayed as blank entries.';
                        }
                        field("Skip accounts without net changes"; SkipZeroNetChanges)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Skip accounts without net changes';
                            ToolTip = 'Specifies that you want the report to exclude accounts with zero turnovers for the given period.';
                        }
                        field("Skip accounts with zero ending balance"; SkipZeroBalances)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Skip accounts with zero ending balance';
                            ToolTip = 'Specifies that you want the report to exclude accounts with zero ending balance at the end of the period.';
                        }
                        field("Skip zero lines"; SkipZeroLines)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Skip zero lines';
                            ToolTip = 'Specifies if lines with zero amount are not be included.';
                        }
                        field(ShowChartControl; ShowChart)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Show Chart';
                            Visible = true;
                        }
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CurrentDate := LocMgt.Date2Text(Today()) + Format(Time(), 0, '(<Hours24>:<Minutes>)');
        RequestFilter := "Customer Posting Group".GetFilters();
        if Customer.GetRangeMin("Date Filter") > 0D then
            StartDate := Customer.GetRangeMin("Date Filter");
        EndDate := Customer.GetRangeMax("Date Filter");
        FillReportParameters();
    end;

    var
#pragma warning disable AA0074
        Text005: Label 'for period from ';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text006: Label ' to ';
#pragma warning restore AA0074
        LocMgt: Codeunit "Localisation Management";
        LineAmount: array[10] of Decimal;
        TotalAmount: array[10] of Decimal;
        LineText: array[10] of Text[30];
        TotalText: array[10] of Text[30];
        RoundedValue: Decimal;
        StartDate: Date;
        EndDate: Date;
        RoundingPrecision: Option "0.01","1.00","1000";
        Decimals: Decimal;
        SkipZeroNetChanges: Boolean;
        SkipZeroValues: Boolean;
        SkipZeroLines: Boolean;
        SkipZeroBalances: Boolean;
        PrintParameters: Boolean;
        CurrentDate: Text[30];
        RequestFilter: Text;
        AmountUnit: Text[30];
        ValueFormat: Text[50];
        ReportParameters: array[4] of Text[80];
        PeriodText: Text[100];
        Counter: Integer;
        I: Integer;
        CustomerPostingGroupURL: RecordRef;
        ShowChart: Boolean;
        Customer_Posting_GroupCaptionLbl: Label 'Customer Posting Group';
        PageCaptionLbl: Label 'Page';
        Turnover_SheetCaptionLbl: Label 'Turnover Sheet';
        CodeCaptionLbl: Label 'Code';
        NameCaptionLbl: Label 'Name';
        Beginning_period_balanceCaptionLbl: Label 'Beginning period balance';
        DebitCaptionLbl: Label 'Debit';
        CreditCaptionLbl: Label 'Credit';
        Net_Change_for_PeriodCaptionLbl: Label 'Net Change for Period';
        DebitCaption_Control25Lbl: Label 'Debit';
        CreditCaption_Control27Lbl: Label 'Credit';
        Ending_period_balanceCaptionLbl: Label 'Ending period balance';
        DebitCaption_Control30Lbl: Label 'Debit';
        CreditCaption_Control31Lbl: Label 'Credit';
        Total_CaptionLbl: Label 'Total:';

    local procedure TextLineValues(ZeroBySpaces: Boolean)
    begin
        Clear(LineText);
        for I := 1 to 6 do
            LineText[I] := Value2Text(LineAmount[I], ZeroBySpaces);
    end;

    local procedure Value2Text(Value: Decimal; ZeroBySpaces: Boolean): Text[30]
    begin
        if ZeroBySpaces and (Value = 0) then
            exit('');
        Value := Round(Value, Decimals);
        if Decimals > 1 then
            Value := Value / Decimals;
        exit(Format(Value, 0, ValueFormat));
    end;

    [Scope('OnPrem')]
    procedure FillReportParameters()
    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'for period from %1 to %2';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text003: Label 'Replace zero values by blanks';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text004: Label 'Skip accounts without net change  ';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text005: Label 'Skip accounts without ending balance';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text006: Label 'Skip lines with zero values';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text007: Label '(in currency units)';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text008: Label '(in thousands)';
#pragma warning restore AA0074
    begin
        case RoundingPrecision of
            RoundingPrecision::"0.01":
                begin
                    ValueFormat := '<Sign><Integer Thousand><Decimals,3>';
                    Decimals := 0.01;
                    AmountUnit := '';
                end;
            RoundingPrecision::"1.00":
                begin
                    ValueFormat := '<Sign><Integer Thousand>';
                    Decimals := 1;
                    AmountUnit := Text007;
                end;
            RoundingPrecision::"1000":
                begin
                    ValueFormat := '<Sign><Integer Thousand>';
                    Decimals := 1000;
                    AmountUnit := Text008;
                end;
        end;
        Counter := 0;
        if SkipZeroValues then begin
            Counter := Counter + 1;
            ReportParameters[Counter] := Text003;
        end;
        if SkipZeroNetChanges then begin
            Counter := Counter + 1;
            ReportParameters[Counter] := Text004;
        end;
        if SkipZeroBalances then begin
            Counter := Counter + 1;
            ReportParameters[Counter] := Text005;
        end;
        if SkipZeroLines then begin
            Counter := Counter + 1;
            ReportParameters[Counter] := Text006;
        end;

        PeriodText := StrSubstNo(Text001, StartDate, EndDate);
        PrintParameters := Counter > 0;
    end;
}

