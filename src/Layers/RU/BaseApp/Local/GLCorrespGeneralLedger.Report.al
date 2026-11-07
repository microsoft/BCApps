#pragma warning disable AA0247
report 12431 "G/L Corresp. General Ledger"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/GLCorrespGeneralLedger.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'G/L Corresp. General Ledger';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(GLAcc; "G/L Account")
        {
            DataItemTableView = sorting("No.") order(ascending);
            RequestFilterFields = "No.";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Text006__FORMAT_DateStartedOfPeriod___Text007_FORMAT_EndingPeriodDate_; Text006 + Format(DateStartedOfPeriod) + Text007 + Format(EndingPeriodDate))
            {
            }
            column(CurrentDate; CurrentDate)
            {
            }
            column(USERID; UserId)
            {
            }
            column(RowNo; RowNo)
            {
            }
            column(General_LedgerCaption; General_LedgerCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Month_Begining_BalanceCaption; Month_Begining_BalanceCaptionLbl)
            {
            }
            column(Account_turnover_from_debit_to_creditCaption; Account_turnover_from_debit_to_creditCaptionLbl)
            {
            }
            column(Totals_Debit_Net_ChangesCaption; Totals_Debit_Net_ChangesCaptionLbl)
            {
            }
            column(Totals_Credit_Net_ChangesCaption; Totals_Credit_Net_ChangesCaptionLbl)
            {
            }
            column(Month_Ending_BalanceCaption; Month_Ending_BalanceCaptionLbl)
            {
            }
            column(GLAcc_No_; "No.")
            {
            }
            column(GLAcc_Business_Unit_Filter; "Business Unit Filter")
            {
            }
            column(GLAcc_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
            {
            }
            column(GLAcc_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
            {
            }
            dataitem("Missing Lines"; "Integer")
            {
                DataItemTableView = sorting(Number) order(ascending);

                trigger OnPreDataItem()
                begin
                    if InvProcessing = InvProcessing::Pass
                    then
                        CurrReport.Break();
                    SetRange(Number, 1, PassLinesBeforeAccount);
                end;
            }
            dataitem("Invoice Heading"; "Integer")
            {
                DataItemTableView = sorting(Number) order(ascending);
                MaxIteration = 1;
                column(PADSTR_____Enclosure_Level____2______GLAcc__No__; PadStr('', "Enclosure Level" * 2, ' ') + GLAcc."No.")
                {
                }
                column(PADSTR_____Enclosure_Level____2______GLAcc_Name; PadStr('', "Enclosure Level" * 2, ' ') + GLAcc.Name)
                {
                }
                column(PADSTR_____Enclosure_Level____2______GLAcc__No___Control25; PadStr('', "Enclosure Level" * 2, ' ') + GLAcc."No.")
                {
                }
                column(PADSTR_____Enclosure_Level____2______GLAcc_Name_Control26; PadStr('', "Enclosure Level" * 2, ' ') + GLAcc.Name)
                {
                }
                column(Invoice_Heading_Number; Number)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    RowNo := 0;
                end;

                trigger OnPreDataItem()
                begin
                    if InvProcessing = InvProcessing::Pass
                    then
                        CurrReport.Break();
                end;
            }
            dataitem("Period Month"; "Integer")
            {
                DataItemTableView = sorting(Number) order(ascending);
                column(MonthFromPeriod; MonthFromPeriod)
                {
                }
                column(BalanceDebitCreditBegining; BalanceDebitCreditBegining)
                {
                }
                column(BalanceDebitCreditEnding; BalanceDebitCreditEnding)
                {
                }
                column(BeginingMonthBalance; BeginingMonthBalance)
                {
                }
                column(NetChangeDebit; NetChangeDebit)
                {
                }
                column(NetChangeCredit; NetChangeCredit)
                {
                }
                column(BalanceEnding; BalanceEnding)
                {
                }
                column(Period_Month_Number; Number)
                {
                }
                dataitem("Double Entry"; "G/L Correspondence")
                {
                    DataItemLink = "Business Unit Filter" = field("Business Unit Filter"), "Debit Global Dim. 1 Filter" = field("Global Dimension 1 Filter"), "Debit Global Dim. 2 Filter" = field("Global Dimension 2 Filter");
                    DataItemLinkReference = GLAcc;
                    DataItemTableView = sorting("Debit Account No.", "Credit Account No.");
                    column(Double_Entry__Credit_Account_No__; "Credit Account No.")
                    {
                    }
                    column(Double_Entry_Amount; Amount)
                    {
                    }
                    column(Double_Entry_Amount_Control8; Amount)
                    {
                    }
                    column(Double_Entry_Debit_Account_No_; "Debit Account No.")
                    {
                    }
                    column(Double_Entry_Business_Unit_Filter; "Business Unit Filter")
                    {
                    }
                    column(Double_Entry_Debit_Global_Dim__1_Filter; "Debit Global Dim. 1 Filter")
                    {
                    }
                    column(Double_Entry_Debit_Global_Dim__2_Filter; "Debit Global Dim. 2 Filter")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        SetRange("Date Filter", DateFilterBeg, DateFilterEnd);

                        if GLAcc.Totaling <> '' then begin
                            if TimeGLAcc.Get("Double Entry"."Credit Account No.") then
                                CurrReport.Skip();
                            TimeGLAcc."No." := "Double Entry"."Credit Account No.";
                            TimeGLAcc.Insert();
                            "Double Entry"."Debit Totaling" := GLAcc.Totaling;
                        end;

                        CalcFields(Amount);
                        if Amount = 0 then
                            CurrReport.Skip()
                    end;

                    trigger OnPreDataItem()
                    begin
                        if WithoutAccountCorresp
                        then
                            CurrReport.Break();
                        DoubleEntriesSeparator := true;

                        if GLAcc.Totaling = '' then
                            SetFilter("Debit Account No.", GLAcc."No.")
                        else
                            SetFilter("Debit Account No.", GLAcc.Totaling);

                        TimeGLAcc.DeleteAll();
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if not ManualInputBeginingDate then
                        DateFilterBeg := CalcDate(StrSubstNo('<+%1M>', Number), DateStartedOfPeriod)
                    else
                        DateFilterBeg := DateStartedOfPeriod;
                    GLAcc.SetRange("Date Filter", ClosingDate(CalcDate('<-1D>', DateFilterBeg)));
                    GLAcc.CalcFields("Balance at Date");
                    BeginingMonthBalance := GLAcc."Balance at Date";

                    if not ManualInputEndingDate then
                        DateFilterEnd := CalcDate('<CM>', DateFilterBeg)
                    else
                        DateFilterEnd := EndingPeriodDate;
                    GLAcc.SetRange("Date Filter", ClosingDate(DateFilterEnd));
                    GLAcc.CalcFields("Balance at Date");
                    BalanceEnding := GLAcc."Balance at Date";

                    GLAcc.SetRange("Date Filter", DateFilterBeg, ClosingDate(DateFilterEnd));
                    GLAcc.CalcFields("Debit Amount", "Credit Amount");
                    NetChangeDebit := GLAcc."Debit Amount";
                    NetChangeCredit := GLAcc."Credit Amount";

                    if BeginingMonthBalance < 0 then begin
                        BalanceDebitCreditBegining := Text002;
                        BeginingMonthBalance := Abs(BeginingMonthBalance);
                    end else
                        if BeginingMonthBalance > 0 then
                            BalanceDebitCreditBegining := Text003
                        else
                            BalanceDebitCreditBegining := '';

                    if BalanceEnding < 0 then begin
                        BalanceDebitCreditEnding := Text002;
                        BalanceEnding := Abs(BalanceEnding);
                    end else
                        if BalanceEnding > 0 then
                            BalanceDebitCreditEnding := Text003
                        else
                            BalanceDebitCreditEnding := '';
                    if Number = 0 then begin
                        BeginingPeriodBalance := BeginingMonthBalance;
                        BalanceBegPeriodDebitCredit := BalanceDebitCreditBegining;
                    end;
                    MonthFromPeriod := Format(DateFilterBeg, 0, '<Month Text>');

                    RowNo += 1;
                end;

                trigger OnPreDataItem()
                begin
                    if (InvProcessing in [InvProcessing::Pass, InvProcessing::"Bold Header"])
                    then
                        CurrReport.Break();
                    if (not ManualInputBeginingDate) and (not ManualInputEndingDate) then
                        SetRange(Number, 0,
                           Date2DMY(EndingPeriodDate, 2) - Date2DMY(DateStartedOfPeriod, 2) +
                          (Date2DMY(EndingPeriodDate, 3) - Date2DMY(DateStartedOfPeriod, 3)) * 12)
                    else
                        SetRange(Number, 1);
                end;
            }
            dataitem(Total; "Integer")
            {
                DataItemTableView = sorting(Number);
                MaxIteration = 1;
                column(BalanceBegPeriodDebitCredit; BalanceBegPeriodDebitCredit)
                {
                }
                column(BalanceDebitCreditEnding_Control48; BalanceDebitCreditEnding)
                {
                }
                column(BeginingPeriodBalance; BeginingPeriodBalance)
                {
                }
                column(NetChangeDebit_Control50; NetChangeDebit)
                {
                }
                column(NetChangeCredit_Control51; NetChangeCredit)
                {
                }
                column(BalanceEnding_Control52; BalanceEnding)
                {
                }
                column(FOR_PERIODCaption; FOR_PERIODCaptionLbl)
                {
                }
                column(Total_Number; Number)
                {
                }
                dataitem(TotalAmount; "G/L Correspondence")
                {
                    DataItemLink = "Business Unit Filter" = field("Business Unit Filter"), "Debit Global Dim. 1 Filter" = field("Global Dimension 1 Filter"), "Debit Global Dim. 2 Filter" = field("Global Dimension 2 Filter");
                    DataItemLinkReference = GLAcc;
                    DataItemTableView = sorting("Debit Account No.", "Credit Account No.");
                    column(TotalAmount__Credit_Account_No__; "Credit Account No.")
                    {
                    }
                    column(TotalAmount_Amount; Amount)
                    {
                    }
                    column(TotalAmount_Amount_Control9; Amount)
                    {
                    }
                    column(TotalAmount_Debit_Account_No_; "Debit Account No.")
                    {
                    }
                    column(TotalAmount_Business_Unit_Filter; "Business Unit Filter")
                    {
                    }
                    column(TotalAmount_Debit_Global_Dim__1_Filter; "Debit Global Dim. 1 Filter")
                    {
                    }
                    column(TotalAmount_Debit_Global_Dim__2_Filter; "Debit Global Dim. 2 Filter")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        SetRange("Date Filter", DateStartedOfPeriod, EndingPeriodDate);

                        if GLAcc.Totaling <> '' then begin
                            if TimeGLAcc.Get("Double Entry"."Credit Account No.") then
                                CurrReport.Skip();
                            TimeGLAcc."No." := "Double Entry"."Credit Account No.";
                            TimeGLAcc.Insert();
                            "Double Entry"."Debit Totaling" := GLAcc.Totaling;
                        end;

                        CalcFields(Amount);
                        if Amount = 0 then
                            CurrReport.Skip()
                    end;

                    trigger OnPreDataItem()
                    begin
                        if WithoutAccountCorresp
                        then
                            CurrReport.Break();

                        if GLAcc.Totaling = '' then
                            SetFilter("Debit Account No.", GLAcc."No.")
                        else
                            SetFilter("Debit Account No.", GLAcc.Totaling);

                        TimeGLAcc.DeleteAll();
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    GLAcc.SetRange("Date Filter", DateStartedOfPeriod, EndingPeriodDate);
                    GLAcc.CalcFields("Debit Amount", "Credit Amount");
                    NetChangeDebit := GLAcc."Debit Amount";
                    NetChangeCredit := GLAcc."Credit Amount";
                end;

                trigger OnPreDataItem()
                begin
                    if (InvProcessing in [InvProcessing::Pass, InvProcessing::"Bold Header"])
                       or (Date2DMY(DateStartedOfPeriod, 2) = Date2DMY(EndingPeriodDate, 2))
                    then
                        CurrReport.Break();
                    DoubleEntriesSeparator := true;
                end;
            }
            dataitem(EndingLine; "Integer")
            {
                DataItemTableView = sorting(Number) order(ascending);
                column(EndingLine_Number; Number)
                {
                }

                trigger OnPreDataItem()
                begin
                    if (InvProcessing in [InvProcessing::Pass, InvProcessing::"Bold Header"])
                    then
                        CurrReport.Break();
                    SetRange(Number, 1);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if GLAcc."Account Type" = GLAcc."Account Type"::Posting
                then
                    InvProcessing := InvProcessing::"Simple Header + Data"
                else
                    if (GLAcc."Account Type" in
                       [GLAcc."Account Type"::Total, GLAcc."Account Type"::"End-Total"])
               then
                        InvProcessing := InvProcessing::"Bold Header + Data"
                    else
                        if WithoutAccountHeaderType
                   then
                            InvProcessing := InvProcessing::Pass
                        else
                            InvProcessing := InvProcessing::"Bold Header";
                if WithoutEnclosuredLevels
                  or (InvProcessing = InvProcessing::Pass)
                then
                    PassLinesBeforeAccount := 0
                else
                    PassLinesBeforeAccount := "No. of Blank Lines";
                if not WithoutEnclosuredLevels
                then
                    "Enclosure Level" := Indentation;
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
                    field(PeriodBegining; MonthBeginigOfPeriod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Beginning';
                        Editable = true;
                        Lookup = true;
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            PeriodReportManagement.SelectPeriod(Text, CalendarPeriodBegining, false);
                            DateStartedOfPeriod := CalendarPeriodBegining."Period Start";
                            exit(true);
                        end;
                    }
                    field(PeriodEnding; MonthEndOfPeriod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending of Period';
                        Lookup = true;
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            PeriodReportManagement.SelectPeriod(Text, CalendarPeriodEnding, false);
                            EndingPeriodDate := NormalDate(CalendarPeriodEnding."Period End");
                            exit(true);
                        end;
                    }
                    field(WithoutAccountCorresp; WithoutAccountCorresp)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Without Double Entries';
                        ToolTip = 'Specifies if you want to print the report without including double entries.';
                    }
                    field(WithoutAccountHeaderType; WithoutAccountHeaderType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Without Accounts Title Type';
                        ToolTip = 'Specifies if you want to print the report without including account titles.';
                    }
                    field(WithoutEnclosuredLevels; WithoutEnclosuredLevels)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Without Levels of Enclosure';
                        ToolTip = 'Specifies if you want to print the report without including levels of enclosure.';
                    }
                    field(InterimTotal; InterimTotal)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Interim Total';
                        ToolTip = 'Specifies if you want to print the report using interim totals.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            PeriodReportManagement.InitPeriod(CalendarPeriodBegining, 0);
            PeriodReportManagement.SetCaptionPeriodYear(MonthBeginigOfPeriod, CalendarPeriodBegining, false);
            DateStartedOfPeriod := CalendarPeriodBegining."Period Start";
            PeriodReportManagement.InitPeriod(CalendarPeriodEnding, 0);
            PeriodReportManagement.SetCaptionPeriodYear(MonthEndOfPeriod, CalendarPeriodEnding, false);
            EndingPeriodDate := NormalDate(CalendarPeriodEnding."Period End");
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if not ManualInputBeginingDate then begin
            PeriodReportManagement.ParseCaptionPeriodName(MonthBeginigOfPeriod, CalendarPeriodBegining, false);
            DateStartedOfPeriod := CalendarPeriodBegining."Period Start";
        end;
        if not ManualInputEndingDate then begin
            PeriodReportManagement.ParseCaptionPeriodName(MonthEndOfPeriod, CalendarPeriodEnding, false);
            EndingPeriodDate := NormalDate(CalendarPeriodEnding."Period End");
        end;
        if DateStartedOfPeriod > EndingPeriodDate then
            Error(Text005);
        CurrentDate := LocMgt.Date2Text(Today()) + Format(Time(), 0, ' (<Hours24>:<Minutes>)');
    end;

    var
#pragma warning disable AA0074
        Text002: Label 'Credit';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text003: Label 'Debit';
#pragma warning restore AA0074
        CalendarPeriodBegining: Record Date;
        CalendarPeriodEnding: Record Date;
        LocMgt: Codeunit "Localisation Management";
        PeriodReportManagement: Codeunit PeriodReportManagement;
        DateFilterBeg: Date;
        DateFilterEnd: Date;
        DateStartedOfPeriod: Date;
        EndingPeriodDate: Date;
        WithoutAccountHeaderType: Boolean;
        WithoutAccountCorresp: Boolean;
        WithoutEnclosuredLevels: Boolean;
        DoubleEntriesSeparator: Boolean;
        MonthBeginigOfPeriod: Text[30];
        MonthEndOfPeriod: Text[30];
        CurrentDate: Text[30];
        BalanceBegPeriodDebitCredit: Text[30];
        BalanceDebitCreditBegining: Text[30];
        BalanceDebitCreditEnding: Text[30];
        MonthFromPeriod: Text[30];
        "Enclosure Level": Integer;
        PassLinesBeforeAccount: Integer;
        InvProcessing: Option Pass,"Bold Header","Bold Header + Data","Simple Header + Data";
        BeginingPeriodBalance: Decimal;
        BeginingMonthBalance: Decimal;
        NetChangeDebit: Decimal;
        NetChangeCredit: Decimal;
        BalanceEnding: Decimal;
        TimeGLAcc: Record "G/L Account" temporary;
        InterimTotal: Boolean;
        ManualInputBeginingDate: Boolean;
        ManualInputEndingDate: Boolean;
#pragma warning disable AA0074
        Text005: Label 'Period Start Date cannot be later than Period End Date.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text006: Label 'for period from ';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text007: Label ' to ';
#pragma warning restore AA0074
        RowNo: Integer;
        General_LedgerCaptionLbl: Label 'General Ledger';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Month_Begining_BalanceCaptionLbl: Label 'Month Begining Balance';
        Account_turnover_from_debit_to_creditCaptionLbl: Label 'Account turnover from debit to credit';
        Totals_Debit_Net_ChangesCaptionLbl: Label 'Totals Debit Net Changes';
        Totals_Credit_Net_ChangesCaptionLbl: Label 'Totals Credit Net Changes';
        Month_Ending_BalanceCaptionLbl: Label 'Month Ending Balance';
        FOR_PERIODCaptionLbl: Label 'FOR PERIOD';
}

