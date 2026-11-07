#pragma warning disable AA0247
report 12464 "Fixed Asset G/L Turnover"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FixedAssetGLTurnover.rdlc';
    Caption = 'Fixed Asset G/L Turnover';

    dataset
    {
        dataitem("Fixed Asset"; "Fixed Asset")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "FA Type", "Global Dimension 1 Filter", "Global Dimension 2 Filter", "FA Location Code Filter", "Depreciation Book Code Filter", "Depreciation Group", "Date Filter";
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
            column(Fixed_Asset__No__; "No.")
            {
            }
            column(Fixed_Asset_Description; Description)
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
            column(LineText_1__Control61; LineText[1])
            {
            }
            column(TotalText_1_; TotalText[1])
            {
            }
            column(LineText_2__Control63; LineText[2])
            {
            }
            column(TotalText_2_; TotalText[2])
            {
            }
            column(TotalText_3_; TotalText[3])
            {
            }
            column(LineText_3__Control68; LineText[3])
            {
            }
            column(TotalText_4_; TotalText[4])
            {
            }
            column(LineText_4__Control76; LineText[4])
            {
            }
            column(LineText_5__Control78; LineText[5])
            {
            }
            column(TotalText_5_; TotalText[5])
            {
            }
            column(LineText_6__Control81; LineText[6])
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
            column(Fixed_AssetsCaption; Fixed_AssetsCaptionLbl)
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

            trigger OnAfterGetRecord()
            begin
                Clear(LineAmount);

                if StartDate > 0D then begin
                    SetRange("Date Filter", 0D, CalcDate('<-1D>', StartDate));
                    CalcFields("G/L Net Change");
                    RoundedValue := Round(Abs("G/L Net Change"), Decimals, '=');
                    if "G/L Net Change" > 0 then
                        LineAmount[1] := RoundedValue
                    else
                        LineAmount[2] := RoundedValue;
                end;
                SetRange("Date Filter", 0D, EndDate);
                CalcFields("G/L Net Change");
                RoundedValue := Round(Abs("G/L Net Change"), Decimals, '=');
                if "G/L Net Change" > 0 then
                    LineAmount[5] := RoundedValue
                else
                    LineAmount[6] := RoundedValue;
                SetRange("Date Filter", StartDate, EndDate);
                CalcFields("G/L Debit Amount", "G/L Credit Amount");
                LineAmount[3] := Round(("G/L Debit Amount"), Decimals, '=');
                LineAmount[4] := Round(("G/L Credit Amount"), Decimals, '=');


                if SkipZeroLines and
                  (LineAmount[1] = 0) and (LineAmount[2] = 0) and
                  (LineAmount[3] = 0) and (LineAmount[4] = 0) and
                  (LineAmount[5] = 0) and (LineAmount[6] = 0) then
                    CurrReport.Skip();

                TextLineValues(SkipZeroValues);
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
                            ApplicationArea = FixedAssets;
                            Caption = 'Rounding Precision';
                            ToolTip = 'Specifies the size of the interval to be used when rounding amounts in the specified currency. You can specify invoice rounding for each currency in the Currency table.';
                        }
                        field("Replace zero values"; SkipZeroValues)
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Replace zero values by blanks';
                            ToolTip = 'Specifies if you want all zero values on the report to be displayed as blank entries.';
                        }
                        field("Skip zero lines"; SkipZeroLines)
                        {
                            ApplicationArea = FixedAssets;
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
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CurrentDate := LocMgt.Date2Text(Today()) + Format(Time(), 0, '(<Hours24>:<Minutes>)');
        RequestFilter := "Fixed Asset".GetFilters();
        if "Fixed Asset".GetRangeMin("Date Filter") > 0D then
            StartDate := "Fixed Asset".GetRangeMin("Date Filter");
        EndDate := "Fixed Asset".GetRangeMax("Date Filter");
        FillReportParameters();
    end;

    var
        LocMgt: Codeunit "Localisation Management";
        LineAmount: array[10] of Decimal;
        LineText: array[10] of Text[30];
        TotalText: array[10] of Text[30];
        RoundedValue: Decimal;
        StartDate: Date;
        EndDate: Date;
        RoundingPrecision: Option "0.01","1.00","1000";
        Decimals: Decimal;
        SkipZeroValues: Boolean;
        SkipZeroLines: Boolean;
        PrintParameters: Boolean;
        CurrentDate: Text[30];
        RequestFilter: Text;
        AmountUnit: Text[30];
        ValueFormat: Text[50];
        ReportParameters: array[4] of Text[80];
        PeriodText: Text[100];
        Counter: Integer;
        I: Integer;
        Fixed_AssetsCaptionLbl: Label 'Fixed Assets';
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
        if SkipZeroLines then begin
            Counter := Counter + 1;
            ReportParameters[Counter] := Text006;
        end;

        PeriodText := StrSubstNo(Text001, StartDate, EndDate);
        PrintParameters := Counter > 0;
    end;
}

