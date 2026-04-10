#pragma warning disable AA0247
report 12436 "G/L Account Turnover"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/GLAccountTurnover.rdlc';
    Caption = 'G/L Account Turnover';
    EnableHyperlinks = true;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Global Dimension 1 Filter", "Global Dimension 2 Filter", "Business Unit Filter", "Date Filter";
            column(CurrentDate; CurrentDate)
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(USERID; UserId)
            {
            }
            column(PeriodText; PeriodText)
            {
            }
            column(RequestFilter; RequestFilter)
            {
            }
            column(AmountUnit; AmountUnit)
            {
            }
            column(GLAccNo; GLAccNo)
            {
            }
            column(GLAccName; GLAccName)
            {
            }
            column(LineText_1_; LineText[1])
            {
            }
            column(LineText_2_; LineText[2])
            {
            }
            column(LineText_3_; LineText[3])
            {
            }
            column(LineText_4_; LineText[4])
            {
            }
            column(LineText_5_; LineText[5])
            {
            }
            column(LineText_6_; LineText[6])
            {
            }
            column(GLAccNo_Control34; GLAccNo)
            {
            }
            column(GLAccName_Control35; GLAccName)
            {
            }
            column(LineText_1__Control36; LineText[1])
            {
            }
            column(LineText_2__Control37; LineText[2])
            {
            }
            column(LineText_3__Control38; LineText[3])
            {
            }
            column(LineText_4__Control39; LineText[4])
            {
            }
            column(LineText_5__Control40; LineText[5])
            {
            }
            column(LineText_6__Control41; LineText[6])
            {
            }
            column(SkipZeroValues; SkipZeroValues)
            {
            }
            column(TotalAmount_6_; TotalAmount[6])
            {
            }
            column(TotalAmount_5_; TotalAmount[5])
            {
            }
            column(TotalAmount_4_; TotalAmount[4])
            {
            }
            column(TotalAmount_3_; TotalAmount[3])
            {
            }
            column(TotalAmount_2_; TotalAmount[2])
            {
            }
            column(TotalAmount_1_; TotalAmount[1])
            {
            }
            column(GLAccURL; Format(GLAccURL.RecordId, 0, 10))
            {
            }
            column(LineText_1__Control58; LineText[1])
            {
            }
            column(TotalText_1_; TotalText[1])
            {
            }
            column(LineText_2__Control60; LineText[2])
            {
            }
            column(TotalText_2_; TotalText[2])
            {
            }
            column(TotalText_3_; TotalText[3])
            {
            }
            column(LineText_3__Control65; LineText[3])
            {
            }
            column(TotalText_4_; TotalText[4])
            {
            }
            column(LineText_4__Control68; LineText[4])
            {
            }
            column(LineText_5__Control92; LineText[5])
            {
            }
            column(TotalText_5_; TotalText[5])
            {
            }
            column(LineText_6__Control95; LineText[6])
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
            column(G_L_AccountCaption; G_L_AccountCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(G_L_Turnover_SheetCaption; G_L_Turnover_SheetCaptionLbl)
            {
            }
            column(No_Caption; No_CaptionLbl)
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(Beginning_period_balanceCaption; Beginning_period_balanceCaptionLbl)
            {
            }
            column(Net_Change_for_PeriodCaption; Net_Change_for_PeriodCaptionLbl)
            {
            }
            column(Ending_period_balanceCaption; Ending_period_balanceCaptionLbl)
            {
            }
            column(DebitCaption; DebitCaptionLbl)
            {
            }
            column(CreditCaption; CreditCaptionLbl)
            {
            }
            column(DebitCaption_Control18; DebitCaption_Control18Lbl)
            {
            }
            column(CreditCaption_Control19; CreditCaption_Control19Lbl)
            {
            }
            column(DebitCaption_Control20; DebitCaption_Control20Lbl)
            {
            }
            column(CreditCaption_Control21; CreditCaption_Control21Lbl)
            {
            }
            column(Total_Caption; Total_CaptionLbl)
            {
            }
            column(G_L_Account_No_; "No.")
            {
            }

            trigger OnAfterGetRecord()
            begin
                GLAccURL.SetPosition(GetPosition());

                Clear(LineAmount);
                if StartDate > 0D then begin
                    SetRange("Date Filter", 0D, CalcDate('<-1D>', ClosingDate(StartDate)));
                    CalcFields("Balance at Date");
                    RoundedValue := Round("Balance at Date", Decimals, '=');
                    if "Balance at Date" > 0 then
                        LineAmount[1] := RoundedValue
                    else
                        LineAmount[2] := -RoundedValue;
                end;
                SetRange("Date Filter", 0D, EndDate);
                CalcFields("Net Change");
                RoundedValue := Round("Net Change", Decimals, '=');
                if "Net Change" > 0 then
                    LineAmount[5] := RoundedValue
                else
                    LineAmount[6] := -RoundedValue;

                SetRange("Date Filter", StartDate, EndDate);
                CalcFields("Debit Amount", "Credit Amount");
                LineAmount[3] := Round("Debit Amount", Decimals, '=');
                LineAmount[4] := Round("Credit Amount", Decimals, '=');

                CurrRecordSkip := false;

                if SkipZeroNetChanges and (LineAmount[3] + LineAmount[4] = 0) then
                    CurrRecordSkip := true;
                if SkipZeroBalances and (LineAmount[5] = 0) and (LineAmount[6] = 0) then
                    CurrRecordSkip := true;
                if SkipZeroLines and
                  (LineAmount[1] = 0) and (LineAmount[2] = 0) and
                  (LineAmount[3] = 0) and (LineAmount[4] = 0) and
                  (LineAmount[5] = 0) and (LineAmount[6] = 0) then
                    CurrRecordSkip := true;

                if CurrRecordSkip then CurrReport.Skip();

                if "Account Type" = "Account Type"::Posting then
                    for I := 1 to 6 do
                        TotalAmount[I] += LineAmount[I];

                if not CurrRecordSkip then begin
                    CurrRecordBold := not ("Account Type" = "Account Type"::Posting);
                    if ("Account Type" = "Account Type"::Heading) or
                       ("Account Type" = "Account Type"::"Begin-Total") then
                        Clear(LineText)
                    else
                        TextLineValues(SkipZeroValues);
                    if PrintExcludingIndention then begin
                        GLAccName := Name;
                        GLAccNo := "No.";
                    end else begin
                        GLAccName := PadStr('', Indentation * 2, ' ') + Name;
                        GLAccNo := PadStr('', Indentation * 2, ' ') + "No.";
                    end;
                end;
            end;

            trigger OnPreDataItem()
            begin
                GLAccURL.Open(DATABASE::"G/L Account");

                if (SkipZeroNetChanges or SkipZeroBalances) then
                    SetRange("Account Type", "Account Type"::Posting);
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
                        field("Replace zero values"; SkipZeroValues)
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
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            SkipZeroValues := true;
            SkipZeroLines := true;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        AccRepMgt.SetBeginEndDate(StartDate, EndDate);
        CurrentDate := LocMgt.Date2Text(Today()) + Format(Time(), 0, ' (<Hours24>:<Minutes>)');
        RequestFilter := "G/L Account".GetFilters();
        TotalPrinted := false;
        if "G/L Account".GetRangeMin("Date Filter") > 0D then
            StartDate := "G/L Account".GetRangeMin("Date Filter");
        EndDate := "G/L Account".GetRangeMax("Date Filter");
        FillReportParameters();
    end;

    var
        LocMgt: Codeunit "Localisation Management";
        AccRepMgt: Codeunit "Internal Report Management";
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
        TotalPrinted: Boolean;
        PrintParameters: Boolean;
        CurrRecordSkip: Boolean;
        CurrRecordBold: Boolean;
        PrintExcludingIndention: Boolean;
        CurrentDate: Text[30];
        RequestFilter: Text[250];
        AmountUnit: Text[30];
        ValueFormat: Text[50];
        ReportParameters: array[4] of Text[80];
        GLAccName: Text[250];
        GLAccNo: Text[250];
        PeriodText: Text[100];
        Counter: Integer;
        I: Integer;
        GLAccURL: RecordRef;
        G_L_AccountCaptionLbl: Label 'G/L Account';
        PageCaptionLbl: Label 'Page';
        G_L_Turnover_SheetCaptionLbl: Label 'G/L Turnover Sheet';
        No_CaptionLbl: Label 'No.';
        NameCaptionLbl: Label 'Name';
        Beginning_period_balanceCaptionLbl: Label 'Beginning period balance';
        Net_Change_for_PeriodCaptionLbl: Label 'Net Change for Period';
        Ending_period_balanceCaptionLbl: Label 'Ending period balance';
        DebitCaptionLbl: Label 'Debit';
        CreditCaptionLbl: Label 'Credit';
        DebitCaption_Control18Lbl: Label 'Debit';
        CreditCaption_Control19Lbl: Label 'Credit';
        DebitCaption_Control20Lbl: Label 'Debit';
        CreditCaption_Control21Lbl: Label 'Credit';
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

