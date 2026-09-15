#pragma warning disable AA0247
report 12446 "Vendor Entries Analysis"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/VendorEntriesAnalysis.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor Entries Analysis';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Vendor Posting Group", "Global Dimension 1 Filter", "Global Dimension 2 Filter", "Agreement Filter";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(CurrentDate; CurrentDate)
            {
            }
            column(USERID; UserId)
            {
            }
            column(ReportCurrency; ReportCurrency)
            {
                OptionCaption = 'LCY,Entry Currency';
                OptionMembers = LCY,"Entry Currency";
            }
            column(PageCounter; PageCounter)
            {
            }
            column(Vendor_Entries_AnalysisCaption; Vendor_Entries_AnalysisCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(ReportCurrencyCaption; ReportCurrencyCaptionLbl)
            {
            }
            column(Vendor_No_; "No.")
            {
            }
            column(Vendor_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
            {
            }
            column(Vendor_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
            {
            }
            column(Vendor_Agreement_Filter; "Agreement Filter")
            {
            }
            column(Vendor_Date_Filter; "Date Filter")
            {
            }
            dataitem("Balance LCY Begining"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(BalanceBegining; BalanceBegining)
                {
                }
                column(Text004; Text004)
                {
                }
                column(SignBalanceBegining; SignBalanceBegining)
                {
                }
                column(Text005_ApplicationLocalization_Date2Text_DateStartedOfPeriod_; Text005 + ApplicationLocalization.Date2Text(DateStartedOfPeriod))
                {
                }
                column(Vendor_Name; Vendor.Name)
                {
                }
                column(Vendor__No__; Vendor."No.")
                {
                }
                column(Balance_LCY_Begining_Number; Number)
                {
                }
            }
            dataitem("Vendor Currency Starting"; Currency)
            {
                DataItemLink = "Vendor Filter" = field("No."), "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"), "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"), "Agreement Filter" = field("Agreement Filter");
                DataItemTableView = sorting(Code) where("Vendor Ledg. Entries in Filter" = const(true));
                column(BalanceBegining_Control2400; BalanceBegining)
                {
                }
                column(SignBalanceBegining_Control2300; SignBalanceBegining)
                {
                }
                column(Vendor_Currency_Starting_Code; Code)
                {
                }
                column(Vendor_Currency_Starting_Vendor_Filter; "Vendor Filter")
                {
                }
                column(Vendor_Currency_Starting_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
                {
                }
                column(Vendor_Currency_Starting_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
                {
                }
                column(Vendor_Currency_Starting_Agreement_Filter; "Agreement Filter")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    CalcFields(
                      "Vendor Balance", "Vendor Balance Due",
                      "Vendor Outstanding Orders", "Vendor Amt. Rcd. Not Invoiced");
                    Value := "Vendor Balance" +
                      "Vendor Outstanding Orders" + "Vendor Amt. Rcd. Not Invoiced";
                    if Value < 0 then
                        SignBalanceBegining := Text002
                    else
                        if Value > 0 then
                            SignBalanceBegining := Text003
                        else
                            CurrReport.Skip();
                    BalanceBegining := Abs(Value);
                end;

                trigger OnPreDataItem()
                begin
                    if ReportCurrency = ReportCurrency::LCY then
                        CurrReport.Break();

                    SetRange("Date Filter", 0D, CalcDate('<-1D>', DateStartedOfPeriod));
                end;
            }
            dataitem("Vendor Entry"; "Vendor Ledger Entry")
            {
                DataItemLink = "Vendor No." = field("No."), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter"), "Agreement No." = field("Agreement Filter"), "Posting Date" = field("Date Filter");
                DataItemTableView = sorting("Document Type", "Vendor No.", "Posting Date", "Currency Code");
                column(Vendor_Name_Control37; Vendor.Name)
                {
                }
                column(Vendor__No___Control43; Vendor."No.")
                {
                }
                column(PaymentDate; PaymentDate)
                {
                }
                column(ResidualAmount; ResidualAmount)
                {
                }
                column(DocAmount; DocAmount1)
                {
                }
                column(Vendor_Entry__Vendor_Entry___Document_Type_; "Vendor Entry"."Document Type")
                {
                }
                column(Vendor_Entry__Vendor_Entry__Description; "Vendor Entry".Description)
                {
                }
                column(Vendor_Entry__Vendor_Entry___Document_No__; "Vendor Entry"."Document No.")
                {
                }
                column(Vendor_Entry__Vendor_Entry___Posting_Date_; "Vendor Entry"."Posting Date")
                {
                }
                column(Vendor_Entry__Vendor_Entry___Currency_Code_; "Vendor Entry"."Currency Code")
                {
                }
                column(NameCaption; NameCaptionLbl)
                {
                }
                column(Closed_AmountCaption; Closed_AmountCaptionLbl)
                {
                }
                column(Posting_dateCaption; Posting_dateCaptionLbl)
                {
                }
                column(DocumentCaption; DocumentCaptionLbl)
                {
                }
                column(No_Caption; No_CaptionLbl)
                {
                }
                column(TypeCaption; TypeCaptionLbl)
                {
                }
                column(ResidualCaption; ResidualCaptionLbl)
                {
                }
                column(AmountCaption; AmountCaptionLbl)
                {
                }
                column(AmountCaption_Control50; AmountCaption_Control50Lbl)
                {
                }
                column(Payment_DateCaption; Payment_DateCaptionLbl)
                {
                }
                column(Vendor_Entry_Entry_No_; "Entry No.")
                {
                }
                column(Vendor_Entry_Vendor_No_; "Vendor No.")
                {
                }
                column(Vendor_Entry_Global_Dimension_1_Code; "Global Dimension 1 Code")
                {
                }
                column(Vendor_Entry_Global_Dimension_2_Code; "Global Dimension 2 Code")
                {
                }
                column(Vendor_Entry_Agreement_No_; "Agreement No.")
                {
                }
                dataitem(ApplicationEntry; "Detailed Vendor Ledg. Entry")
                {
                    DataItemLink = "Vendor Ledger Entry No." = field("Entry No.");
                    DataItemTableView = sorting("Vendor Ledger Entry No.", "Posting Date") where("Entry Type" = const(Application), Unapplied = const(false));
                    column(ApplicationEntry_Entry_No_; "Entry No.")
                    {
                    }
                    column(ApplicationEntry_Vendor_Ledger_Entry_No_; "Vendor Ledger Entry No.")
                    {
                    }
                    column(ApplicationEntry_Transaction_No_; "Transaction No.")
                    {
                    }
                    column(ApplicationEntry_Vendor_No_; "Vendor No.")
                    {
                    }
                    dataitem(AppliedEntry; "Detailed Vendor Ledg. Entry")
                    {
                        DataItemLink = "Transaction No." = field("Transaction No."), "Vendor No." = field("Vendor No.");
                        DataItemTableView = sorting("Transaction No.", "Vendor No.", "Entry Type") where("Entry Type" = const(Application), Unapplied = const(false));
                        column(AppliedEntry__Posting_Date_; "Posting Date")
                        {
                        }
                        column(AppliedEntry__Document_Type_; "Document Type")
                        {
                        }
                        column(ApplVendLedgerEntry_Description; ApplVendLedgerEntry.Description)
                        {
                        }
                        column(AppliedEntry__Document_No__; "Document No.")
                        {
                        }
                        column(DocAmount_Control1210011; DocAmount2)
                        {
                        }
                        column(AmountClosed; AmountClosed)
                        {
                        }
                        column(ApplVendLedgerEntry__Currency_Code_; ApplVendLedgerEntry."Currency Code")
                        {
                        }
                        column(AppliedEntry_Entry_No_; "Entry No.")
                        {
                        }
                        column(AppliedEntry_Transaction_No_; "Transaction No.")
                        {
                        }
                        column(AppliedEntry_Vendor_No_; "Vendor No.")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if "Vendor Ledger Entry No." = "Vendor Entry"."Entry No." then
                                CurrReport.Skip();

                            ApplVendLedgerEntry.Get("Vendor Ledger Entry No.");
                            ApplVendLedgerEntry.CalcFields("Amount (LCY)", Amount);

                            if ReportCurrency = ReportCurrency::LCY then begin
                                DocAmount2 := ApplVendLedgerEntry."Amount (LCY)";
                                AmountClosed := GetClosedAmount(ApplicationEntry."Amount (LCY)", "Amount (LCY)");
                            end else begin
                                DocAmount2 := ApplVendLedgerEntry.Amount;
                                AmountClosed := GetClosedAmount(ApplicationEntry.Amount, Amount);
                            end;
                        end;

                        trigger OnPreDataItem()
                        begin
                            if ApplicationEntry.Amount > 0 then
                                SetFilter(Amount, '<0')
                            else
                                SetFilter(Amount, '>0');
                        end;
                    }
                }
                dataitem(Total; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    MaxIteration = 1;
                    column(Total_Number; Number)
                    {
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    CalcFields("Amount (LCY)", "Remaining Amt. (LCY)", Amount, "Remaining Amount");
                    if ReportCurrency = ReportCurrency::LCY then begin
                        DocAmount1 := "Amount (LCY)";
                        AmountClosed := "Closed by Amount (LCY)";
                        ResidualAmount := "Remaining Amt. (LCY)";
                    end else begin
                        DocAmount1 := Amount;
                        AmountClosed := "Closed by Amount";
                        ResidualAmount := "Remaining Amount";
                    end;
                    if "Document Type" in
                      ["Document Type"::Payment, "Document Type"::"Credit Memo"]
                    then
                        PaymentDate := 0D
                    else
                        PaymentDate := "Due Date";
                end;
            }
            dataitem("Balance LCY Ending"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(BalanceEnding; BalanceEnding)
                {
                }
                column(Text004_Control30; Text004)
                {
                }
                column(SignBalanceEnding; SignBalanceEnding)
                {
                }
                column(Text005_ApplicationLocalization_Date2Text_EndingPeriodDate_; Text005 + ApplicationLocalization.Date2Text(EndingPeriodDate))
                {
                }
                column(Balance_LCY_Ending_Number; Number)
                {
                }
            }
            dataitem("Vendor Currency Ending"; Currency)
            {
                DataItemLink = "Vendor Filter" = field("No."), "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"), "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"), "Agreement Filter" = field("Agreement Filter");
                DataItemTableView = sorting(Code) where("Vendor Ledg. Entries in Filter" = const(true));
                column(Vendor_Currency_Ending_Code; Code)
                {
                }
                column(BalanceEnding_Control18; BalanceEnding)
                {
                }
                column(SignBalanceEnding_Control34; SignBalanceEnding)
                {
                }
                column(Vendor_Currency_Ending_Vendor_Filter; "Vendor Filter")
                {
                }
                column(Vendor_Currency_Ending_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
                {
                }
                column(Vendor_Currency_Ending_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
                {
                }
                column(Vendor_Currency_Ending_Agreement_Filter; "Agreement Filter")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    CalcFields(
                      "Vendor Balance", "Vendor Balance Due",
                      "Vendor Outstanding Orders", "Vendor Amt. Rcd. Not Invoiced");
                    Value := "Vendor Balance" +
                      "Vendor Outstanding Orders" + "Vendor Amt. Rcd. Not Invoiced";
                    if Value < 0 then
                        SignBalanceEnding := Text002
                    else
                        if Value > 0 then
                            SignBalanceEnding := Text003
                        else
                            CurrReport.Skip();
                    BalanceEnding := Abs(Value);
                end;

                trigger OnPreDataItem()
                begin
                    if ReportCurrency = ReportCurrency::LCY then
                        CurrReport.Break();

                    SetRange("Date Filter", 0D, EndingPeriodDate);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                SetRange("Date Filter", 0D, CalcDate('<-1D>', DateStartedOfPeriod));
                CalcFields("Net Change (LCY)");
                Value := "Net Change (LCY)";
                if Value < 0 then
                    SignBalanceBegining := Text002
                else
                    if Value > 0 then
                        SignBalanceBegining := Text003
                    else
                        SignBalanceBegining := '';
                BalanceBegining := Abs(Value);
                SetRange("Date Filter", 0D, EndingPeriodDate);
                CalcFields("Net Change (LCY)");
                Value := "Net Change (LCY)";
                if Value < 0 then
                    SignBalanceEnding := Text002
                else
                    if Value > 0 then
                        SignBalanceEnding := Text003
                    else
                        SignBalanceEnding := '';
                BalanceEnding := Abs(Value);
                SetRange("Date Filter", DateStartedOfPeriod, EndingPeriodDate);
                CalcFields("Debit Amount", "Credit Amount", "Debit Amount (LCY)", "Credit Amount (LCY)");
                if ("Debit Amount" = 0) and
                   ("Credit Amount" = 0) and
                   ("Debit Amount (LCY)" = 0) and
                   ("Credit Amount (LCY)" = 0)
                then
                    CurrReport.Skip();
                if not FirstPage then
                    if NewPageForCustomer then
                        PageCounter += 1;
                FirstPage := false;
            end;

            trigger OnPreDataItem()
            begin
                FirstPage := true;
                PageCounter := 0;
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
                    field(DateStartedOfPeriod; DateStartedOfPeriod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the beginning of the period for which entries are adjusted. This field is usually left blank, but you can enter a date.';
                    }
                    field(EndingPeriodDate; EndingPeriodDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending of Period';
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';
                    }
                    field(ReportCurrency; ReportCurrency)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Report Currency';
                        OptionCaption = 'LCY,Entry Currency';
                        ToolTip = 'Specifies the reporting currency for the report. Report currencies include LCY and Entry Currency.';
                    }
                    field(NewPageForCustomer; NewPageForCustomer)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Page For Vendor';
                        ToolTip = 'Specifies if you want to print the data for each vendor on a separate page.';
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
        if (DateStartedOfPeriod = 0D) and (EndingPeriodDate = 0D) then
            DateStartedOfPeriod := WorkDate();
        if DateStartedOfPeriod = 0D then
            DateStartedOfPeriod := EndingPeriodDate
        else
            if EndingPeriodDate = 0D then
                EndingPeriodDate := DateStartedOfPeriod;
        CurrentDate := ApplicationLocalization.Date2Text(Today()) + Format(Time(), 0, '(<Hours24>:<Minutes>)');
    end;

    var
#pragma warning disable AA0074
        Text002: Label 'Debit';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text003: Label 'Credit';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text004: Label 'LCY';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text005: Label 'Balance at';
#pragma warning restore AA0074
        ApplVendLedgerEntry: Record "Vendor Ledger Entry";
        ApplicationLocalization: Codeunit "Localisation Management";
        CurrentDate: Text[30];
        SignBalanceBegining: Text[10];
        SignBalanceEnding: Text[10];
        BalanceBegining: Decimal;
        BalanceEnding: Decimal;
        DocAmount1: Decimal;
        DocAmount2: Decimal;
        AmountClosed: Decimal;
        ResidualAmount: Decimal;
        Value: Decimal;
        DateStartedOfPeriod: Date;
        EndingPeriodDate: Date;
        PaymentDate: Date;
        NewPageForCustomer: Boolean;
        FirstPage: Boolean;
        ReportCurrency: Option LCY,"Entry Currency";
        PageCounter: Integer;
        Vendor_Entries_AnalysisCaptionLbl: Label 'Vendor Entries Analysis';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        ReportCurrencyCaptionLbl: Label 'Report Currency';
        NameCaptionLbl: Label 'Name';
        Closed_AmountCaptionLbl: Label 'Closed\Amount';
        Posting_dateCaptionLbl: Label 'Posting\date';
        DocumentCaptionLbl: Label 'Document';
        No_CaptionLbl: Label 'No.';
        TypeCaptionLbl: Label 'Type';
        ResidualCaptionLbl: Label 'Residual';
        AmountCaptionLbl: Label 'Amount';
        AmountCaption_Control50Lbl: Label 'Amount';
        Payment_DateCaptionLbl: Label 'Payment\Date';

    [Scope('OnPrem')]
    procedure GetClosedAmount(ApplicationAmount: Decimal; AppliedAmount: Decimal): Decimal
    var
        Amount: Decimal;
    begin
        if Abs(ApplicationAmount) > Abs(AppliedAmount) then
            Amount := Abs(AppliedAmount)
        else
            Amount := Abs(ApplicationAmount);

        if ApplicationAmount > 0 then
            exit(Amount)
        else
            exit(-Amount);
    end;
}

