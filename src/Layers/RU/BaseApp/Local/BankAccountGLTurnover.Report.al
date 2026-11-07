#pragma warning disable AA0247
report 12447 "Bank Account G/L Turnover"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/BankAccountGLTurnover.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Bank Account G/L Turnover';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Bank Account"; "Bank Account")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(RequestFilter; RequestFilter)
            {
            }
            column(Text005__FORMAT_BeginingDate___Text006__FORMAT_EndingDate_; Text005 + Format(BeginingDate) + Text006 + Format(EndingDate))
            {
            }
            column(CurrentDate; CurrentDate)
            {
            }
            column(AmountUnit; AmountUnit)
            {
            }
            column(USERID; UserId)
            {
            }
            column(Bank_Account__No__; "No.")
            {
            }
            column(Bank_Account_Name; Name)
            {
            }
            column(BalanceDebitBeginingText; BalanceDebitBeginingText)
            {
            }
            column(BalanceCreditBeginingText; BalanceCreditBeginingText)
            {
            }
            column(NetChangeDebitText; NetChangeDebitText)
            {
            }
            column(NetChangeCreditText; NetChangeCreditText)
            {
            }
            column(BalanceDebitEndingText; BalanceDebitEndingText)
            {
            }
            column(BalanceCreditEndingText; BalanceCreditEndingText)
            {
            }
            column(BalanceDebitBegining; BalanceDebitBegining)
            {
            }
            column(BalanceCreditBegining; BalanceCreditBegining)
            {
            }
            column(BalanceDebitEnding; BalanceDebitEnding)
            {
            }
            column(BalanceCreditEnding; BalanceCreditEnding)
            {
            }
            column(NetChangeCredit; NetChangeCredit)
            {
            }
            column(NetChangeDebit; NetChangeDebit)
            {
            }
            column(BalanceDebitBeginingText_Control123; BalanceDebitBeginingText)
            {
            }
            column(BalanceDebitBeginingTotalText; BalanceDebitBeginingTotalText)
            {
            }
            column(BalanceCreditBeginingText_Control126; BalanceCreditBeginingText)
            {
            }
            column(BalanceCreditBeginingTotalText; BalanceCreditBeginingTotalText)
            {
            }
            column(NetChangeDebitTotalText; NetChangeDebitTotalText)
            {
            }
            column(NetChangeDebitText_Control130; NetChangeDebitText)
            {
            }
            column(NetChangeCreditTotalText; NetChangeCreditTotalText)
            {
            }
            column(NetChangeCreditText_Control133; NetChangeCreditText)
            {
            }
            column(BalanceDebitEndingText_Control135; BalanceDebitEndingText)
            {
            }
            column(BalanceDebitEndingTotalText; BalanceDebitEndingTotalText)
            {
            }
            column(BalanceCreditEndingText_Control138; BalanceCreditEndingText)
            {
            }
            column(BalanceCreditEndingTotalText; BalanceCreditEndingTotalText)
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
            column(Bank_AccountCaption; Bank_AccountCaptionLbl)
            {
            }
            column(G_L_Turnover_SheetCaption; G_L_Turnover_SheetCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(Ending_period_balanceCaption; Ending_period_balanceCaptionLbl)
            {
            }
            column(CreditCaption; CreditCaptionLbl)
            {
            }
            column(DebitCaption; DebitCaptionLbl)
            {
            }
            column(Net_Change_for_PeriodCaption; Net_Change_for_PeriodCaptionLbl)
            {
            }
            column(CreditCaption_Control87; CreditCaption_Control87Lbl)
            {
            }
            column(DebitCaption_Control88; DebitCaption_Control88Lbl)
            {
            }
            column(Beginning_period_balanceCaption; Beginning_period_balanceCaptionLbl)
            {
            }
            column(CreditCaption_Control92; CreditCaption_Control92Lbl)
            {
            }
            column(DebitCaption_Control93; DebitCaption_Control93Lbl)
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(No_Caption; No_CaptionLbl)
            {
            }
            column(Total_Caption; Total_CaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            var
                "Rounded Value": Decimal;
            begin
                BalanceDebitBegining := 0;
                BalanceCreditBegining := 0;
                BalanceDebitEnding := 0;
                BalanceCreditEnding := 0;
                if BeginingDate > 0D then begin
                    SetRange("Date Filter", 0D, CalcDate('<-1D>', BeginingDate));
                    CalcFields("Net Change (LCY)");
                    Value := "Net Change (LCY)";
                    "Rounded Value" := Round(Abs(Value), DecPlacesOfValues, '=');
                    if Value > 0 then
                        BalanceDebitBegining := "Rounded Value"
                    else
                        BalanceCreditBegining := "Rounded Value";
                end;
                SetRange("Date Filter", 0D, EndingDate);
                CalcFields("Net Change (LCY)");
                Value := "Net Change (LCY)";
                "Rounded Value" := Round(Abs(Value), DecPlacesOfValues, '=');
                if Value > 0 then
                    BalanceDebitEnding := "Rounded Value"
                else
                    BalanceCreditEnding := "Rounded Value";
                SetRange("Date Filter", BeginingDate, EndingDate);
                CalcFields("Debit Amount (LCY)", "Credit Amount (LCY)");
                Value := "Debit Amount (LCY)";
                NetChangeDebit := Round(Abs(Value), DecPlacesOfValues, '=');
                Value := "Credit Amount (LCY)";
                NetChangeCredit := Round(Abs(Value), DecPlacesOfValues, '=');

                if ExcludingZeroLine and
                  (BalanceDebitBegining = 0) and (BalanceCreditBegining = 0) and
                  (NetChangeDebit = 0) and (NetChangeCredit = 0) and
                  (BalanceDebitEnding = 0) and (BalanceCreditEnding = 0) then
                    CurrReport.Skip();

                TextLineValues(SubstituteSpacesZeroVal);
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
                    field("Starting Date"; BeginingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the beginning of the period for which entries are adjusted. This field is usually left blank, but you can enter a date.';
                    }
                    field("Ending Date"; EndingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';
                    }
                    field("Rounding Precision"; RoundingPrecision)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Rounding Precision';
                        ToolTip = 'Specifies the size of the interval to be used when rounding amounts in the specified currency. You can specify invoice rounding for each currency in the Currency table.';
                    }
                    field("Replace zero values"; SubstituteSpacesZeroVal)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Replace zero values by spaces';
                        ToolTip = 'Specifies if you want all zero values on the report to be displayed as blank entries.';
                    }
                    field("Exclude zero lines"; ExcludingZeroLine)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Exclude lines with zero values';
                        ToolTip = 'Specifies that lines with zero content are excluded from the view.';
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
        case RoundingPrecision of
            RoundingPrecision::"0.01":
                begin
                    ValueFormat := '<Integer Thousand><Decimals,3>';
                    DecPlacesOfValues := 0.01;
                    AmountUnit := '';
                end;
            RoundingPrecision::"1.00":
                begin
                    ValueFormat := '<Integer Thousand>';
                    DecPlacesOfValues := 1;
                    AmountUnit := '(ó µÑ½ÙÕ Ññ¿¡¿µáÕ)';
                end;
            RoundingPrecision::"1000":
                begin
                    ValueFormat := '<Integer Thousand>';
                    DecPlacesOfValues := 1000;
                    AmountUnit := '(ó ÔÙß´þáÕ)';
                end;
        end;
        CycleIndex := 0;
        if SubstituteSpacesZeroVal then begin
            CycleIndex := CycleIndex + 1;
            ReportParameters[CycleIndex] :=
              Text003;
        end;
        if ExcludingZeroLine then begin
            CycleIndex := CycleIndex + 1;
            ReportParameters[CycleIndex] := 'êß¬½¯þÑ¡Ù ßÔÓ«¬¿ ¿º ¡Ò½ÑóÙÕ º¡áþÑ¡¿®';
        end;
        PrintingParamsIsNecessary := CycleIndex > 0;
        RequestFilter := "Bank Account".GetFilters();
        WasPrintTotal := false;
    end;

    var
#pragma warning disable AA0074
        Text003: Label 'Zero values are replaced by spacebar';
#pragma warning restore AA0074
        LocMgt: Codeunit "Localisation Management";
        BalanceDebitBegining: Decimal;
        BalanceCreditBegining: Decimal;
        NetChangeDebit: Decimal;
        NetChangeCredit: Decimal;
        BalanceDebitEnding: Decimal;
        BalanceCreditEnding: Decimal;
        BeginingDate: Date;
        EndingDate: Date;
        RoundingPrecision: Option "0.01","1.00","1000";
        Value: Decimal;
        DecPlacesOfValues: Decimal;
        SubstituteSpacesZeroVal: Boolean;
        ExcludingZeroLine: Boolean;
        WasPrintTotal: Boolean;
        PrintingParamsIsNecessary: Boolean;
        CurrentDate: Text[30];
        BalanceDebitBeginingText: Text[30];
        BalanceCreditBeginingText: Text[30];
        NetChangeDebitText: Text[30];
        NetChangeCreditText: Text[30];
        BalanceDebitEndingText: Text[30];
        BalanceCreditEndingText: Text[30];
        BalanceCreditBeginingTotalText: Text[30];
        BalanceDebitBeginingTotalText: Text[30];
        NetChangeCreditTotalText: Text[30];
        NetChangeDebitTotalText: Text[30];
        BalanceCreditEndingTotalText: Text[30];
        BalanceDebitEndingTotalText: Text[30];
        RequestFilter: Text;
        ValueFormat: Text[50];
        AmountUnit: Text[30];
        ReportParameters: array[4] of Text[80];
        CycleIndex: Integer;
#pragma warning disable AA0074
        Text005: Label 'for period from ';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text006: Label ' to ';
#pragma warning restore AA0074
        Bank_AccountCaptionLbl: Label 'Bank Account';
        G_L_Turnover_SheetCaptionLbl: Label 'G/L Turnover Sheet';
        PageCaptionLbl: Label 'Page';
        Ending_period_balanceCaptionLbl: Label 'Ending period balance';
        CreditCaptionLbl: Label 'Credit';
        DebitCaptionLbl: Label 'Debit';
        Net_Change_for_PeriodCaptionLbl: Label 'Net Change for Period';
        CreditCaption_Control87Lbl: Label 'Credit';
        DebitCaption_Control88Lbl: Label 'Debit';
        Beginning_period_balanceCaptionLbl: Label 'Beginning period balance';
        CreditCaption_Control92Lbl: Label 'Credit';
        DebitCaption_Control93Lbl: Label 'Debit';
        NameCaptionLbl: Label 'Name';
        No_CaptionLbl: Label 'No.';
        Total_CaptionLbl: Label 'Total:';

    [Scope('OnPrem')]
    procedure TextLineValues(ZeroBySpaces: Boolean)
    begin
        if BeginingDate > 0D then begin
            BalanceDebitBeginingText := "Value Text"(BalanceDebitBegining, ZeroBySpaces);
            BalanceCreditBeginingText := "Value Text"(BalanceCreditBegining, ZeroBySpaces);
        end else begin
            BalanceDebitBeginingText := '';
            BalanceCreditBeginingText := '';
        end;
        BalanceDebitEndingText := "Value Text"(BalanceDebitEnding, ZeroBySpaces);
        BalanceCreditEndingText := "Value Text"(BalanceCreditEnding, ZeroBySpaces);
        NetChangeDebitText := "Value Text"(NetChangeDebit, ZeroBySpaces);
        NetChangeCreditText := "Value Text"(NetChangeCredit, ZeroBySpaces);
    end;

    local procedure "Value Text"(Value: Decimal; ZeroBySpaces: Boolean): Text[30]
    begin
        if ZeroBySpaces and (Value = 0) then
            exit('');
        Value := Round(Value, DecPlacesOfValues);
        if DecPlacesOfValues > 1 then
            Value := Value / DecPlacesOfValues;
        exit(Format(Value, 0, ValueFormat));
    end;
}

