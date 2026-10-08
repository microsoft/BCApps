#pragma warning disable AA0247
report 12444 "Vendor Turnover"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/VendorTurnover.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor Turnover';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Global Dimension 1 Filter", "Global Dimension 2 Filter", "Vendor Posting Group", "Date Filter";
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
            column(Vendor__No__; "No.")
            {
            }
            column(Vendor_Name; Name)
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
            column(LineText_6__Control54; LineText[6])
            {
            }
            column(LineText_5__Control56; LineText[5])
            {
            }
            column(TotalText_4_; TotalText[4])
            {
            }
            column(TotalText_3_; TotalText[3])
            {
            }
            column(LineText_2__Control62; LineText[2])
            {
            }
            column(LineText_1__Control64; LineText[1])
            {
            }
            column(LineText_4__Control68; LineText[4])
            {
            }
            column(LineText_3__Control69; LineText[3])
            {
            }
            column(TotalText_1_; TotalText[1])
            {
            }
            column(TotalText_2_; TotalText[2])
            {
            }
            column(TotalText_5_; TotalText[5])
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
            column(VendorsCaption; VendorsCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(Turnover_SheetCaption; Turnover_SheetCaptionLbl)
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
            dataitem("Vendor Agreement"; "Vendor Agreement")
            {
                DataItemLink = "Vendor No." = field("No.");
                RequestFilterFields = "No.", "Agreement Date";
                column(Vendor_Agreement__No__; "No.")
                {
                }
                column(Vendor_Agreement_Description; Description)
                {
                }
                column(LineAgrText1; LineAgrText[1])
                {
                }
                column(LineAgrText2; LineAgrText[2])
                {
                }
                column(LineAgrText3; LineAgrText[3])
                {
                }
                column(LineAgrText4; LineAgrText[4])
                {
                }
                column(LineAgrText5; LineAgrText[5])
                {
                }
                column(LineAgrText6; LineAgrText[6])
                {
                }
                column(Vendor_Agreement_Vendor_No_; "Vendor No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    Clear(LineAmountAgr);

                    if StartDate > 0D then begin
                        SetRange("Date Filter", 0D, CalcDate('<-1D>', StartDate));
                        CalcFields("Net Change (LCY)");
                        "Rounded Value" := Round(Abs("Net Change (LCY)"), Decimals, '=');
                        if "Net Change (LCY)" < 0 then
                            LineAmountAgr[1] := "Rounded Value"
                        else
                            LineAmountAgr[2] := "Rounded Value";
                    end;
                    SetRange("Date Filter", 0D, EndDate);
                    CalcFields("Net Change (LCY)");
                    "Rounded Value" := Round(Abs("Net Change (LCY)"), Decimals, '=');
                    if "Net Change (LCY)" < 0 then
                        LineAmountAgr[5] := "Rounded Value"
                    else
                        LineAmountAgr[6] := "Rounded Value";
                    SetRange("Date Filter", StartDate, EndDate);
                    CalcFields("Debit Amount (LCY)", "Credit Amount (LCY)");
                    LineAmountAgr[3] := Round(Abs("Debit Amount (LCY)"), Decimals, '=');
                    LineAmountAgr[4] := Round(Abs("Credit Amount (LCY)"), Decimals, '=');

                    if SkipZeroBalances and (LineAmountAgr[5] = 0) and (LineAmountAgr[6] = 0) then
                        CurrReport.Skip();
                    if SkipZeroNetChanges and (LineAmountAgr[3] = 0) and (LineAmountAgr[4] = 0) then
                        CurrReport.Skip();
                    if SkipZeroLines and
                      (LineAmountAgr[1] = 0) and (LineAmountAgr[2] = 0) and
                      (LineAmountAgr[3] = 0) and (LineAmountAgr[4] = 0) and
                      (LineAmountAgr[5] = 0) and (LineAmountAgr[6] = 0)
                    then
                        CurrReport.Skip();

                    TextLineValues(SkipZeroValues, LineAmountAgr, LineAgrText);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Clear(LineAmount);

                if StartDate > 0D then begin
                    SetRange("Date Filter", 0D, CalcDate('<-1D>', StartDate));
                    CalcFields("Net Change (LCY)");
                    "Rounded Value" := Round(Abs("Net Change (LCY)"), Decimals, '=');
                    if "Net Change (LCY)" < 0 then
                        LineAmount[1] := "Rounded Value"
                    else
                        LineAmount[2] := "Rounded Value";
                end;
                SetRange("Date Filter", 0D, EndDate);
                CalcFields("Net Change (LCY)");
                "Rounded Value" := Round(Abs("Net Change (LCY)"), Decimals, '=');
                if "Net Change (LCY)" < 0 then
                    LineAmount[5] := "Rounded Value"
                else
                    LineAmount[6] := "Rounded Value";
                SetRange("Date Filter", StartDate, EndDate);
                CalcFields("Debit Amount (LCY)", "Credit Amount (LCY)");
                LineAmount[3] := Round(Abs("Debit Amount (LCY)"), Decimals, '=');
                LineAmount[4] := Round(Abs("Credit Amount (LCY)"), Decimals, '=');

                if SkipZeroBalances and (LineAmount[5] = 0) and (LineAmount[6] = 0) then
                    CurrReport.Skip();
                if SkipZeroNetChanges and (LineAmount[3] = 0) and (LineAmount[4] = 0) then
                    CurrReport.Skip();
                if SkipZeroLines and
                  (LineAmount[1] = 0) and (LineAmount[2] = 0) and
                  (LineAmount[3] = 0) and (LineAmount[4] = 0) and
                  (LineAmount[5] = 0) and (LineAmount[6] = 0) then
                    CurrReport.Skip();

                TextLineValues(SkipZeroValues, LineAmount, LineText);
            end;

            trigger OnPreDataItem()
            begin
                Clear(LineAmount);
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
        RequestFilter := Vendor.GetFilters();
        TotalPrinted := false;
        if Vendor.GetRangeMin("Date Filter") > 0D then
            StartDate := Vendor.GetRangeMin("Date Filter");
        EndDate := Vendor.GetRangeMax("Date Filter");
        FillReportParameters();
    end;

    var
        LocMgt: Codeunit "Localisation Management";
        LineAmount: array[10] of Decimal;
        LineText: array[10] of Text[30];
        LineAgrText: array[10] of Text[30];
        TotalText: array[10] of Text[30];
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
        CurrentDate: Text[30];
        RequestFilter: Text;
        AmountUnit: Text[30];
        ValueFormat: Text[50];
        ReportParameters: array[4] of Text[80];
        PeriodText: Text[100];
        Counter: Integer;
        I: Integer;
        LineAmountAgr: array[10] of Decimal;
        "Rounded Value": Decimal;
        VendorsCaptionLbl: Label 'Vendors';
        PageCaptionLbl: Label 'Page';
        Turnover_SheetCaptionLbl: Label 'Turnover Sheet';
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

    local procedure TextLineValues(ZeroBySpaces: Boolean; Amounts: array[10] of Decimal; var TextValues: array[10] of Text)
    begin
        Clear(TextValues);
        for I := 1 to 6 do
            TextValues[I] := Value2Text(Amounts[I], ZeroBySpaces);
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

