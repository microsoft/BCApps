#pragma warning disable AA0247
report 12442 "Customer Entries Analysis"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/CustomerEntriesAnalysis.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer Entries Analysis';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Customer Posting Group", "Global Dimension 1 Filter", "Global Dimension 2 Filter", "Agreement Filter";
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
            column(Customer_Entries_AnalysisCaption; Customer_Entries_AnalysisCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(ReportCurrencyCaption; ReportCurrencyCaptionLbl)
            {
            }
            column(Customer_No_; "No.")
            {
            }
            column(Customer_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
            {
            }
            column(Customer_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
            {
            }
            column(Customer_Agreement_Filter; "Agreement Filter")
            {
            }
            column(Customer_Date_Filter; "Date Filter")
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
                column(Customer_Name; Customer.Name)
                {
                }
                column(Customer__No__; Customer."No.")
                {
                }
                column(Balance_LCY_Begining_Number; Number)
                {
                }
            }
            dataitem("Customer Currence Begining"; Currency)
            {
                DataItemLink = "Customer Filter" = field("No."), "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"), "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"), "Agreement Filter" = field("Agreement Filter");
                DataItemTableView = sorting(Code) where("Cust. Ledg. Entries in Filter" = const(true));
                column(BalanceBegining_Control2400; BalanceBegining)
                {
                }
                column(SignBalanceBegining_Control2300; SignBalanceBegining)
                {
                }
                column(Customer_Currence_Begining_Code; Code)
                {
                }
                column(Customer_Currence_Begining_Customer_Filter; "Customer Filter")
                {
                }
                column(Customer_Currence_Begining_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
                {
                }
                column(Customer_Currence_Begining_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
                {
                }
                column(Customer_Currence_Begining_Agreement_Filter; "Agreement Filter")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    CalcFields(
                      "Customer Balance", "Customer Balance Due",
                      "Customer Outstanding Orders", "Customer Shipped Not Invoiced");
                    Value := "Customer Balance" +
                      "Customer Outstanding Orders" + "Customer Shipped Not Invoiced";
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
            dataitem("Customer Entry"; "Cust. Ledger Entry")
            {
                DataItemLink = "Customer No." = field("No."), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter"), "Agreement No." = field("Agreement Filter"), "Posting Date" = field("Date Filter");
                DataItemTableView = sorting("Document Type", "Customer No.", "Posting Date", "Currency Code");
                RequestFilterFields = "Document No.";
                column(Customer_Name_Control37; Customer.Name)
                {
                }
                column(Customer__No___Control43; Customer."No.")
                {
                }
                column(PaymentDate; PaymentDate)
                {
                }
                column(ResidualAmount; ResidualAmount)
                {
                }
                column(DocAmount; CustEntryDocAmount)
                {
                }
                column(Customer_Entry__Customer_Entry___Document_Type_; "Customer Entry"."Document Type")
                {
                }
                column(Customer_Entry__Customer_Entry__Description; "Customer Entry".Description)
                {
                }
                column(Customer_Entry__Customer_Entry___Document_No__; "Customer Entry"."Document No.")
                {
                }
                column(Customer_Entry__Customer_Entry___Posting_Date_; "Customer Entry"."Posting Date")
                {
                }
                column(Customer_Entry__Customer_Entry___Currency_Code_; "Customer Entry"."Currency Code")
                {
                }
                column(NameCaption; NameCaptionLbl)
                {
                }
                column(Closed_AmountCaption; Closed_AmountCaptionLbl)
                {
                }
                column(Posting_DateCaption; Posting_DateCaptionLbl)
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
                column(Customer_Entry_Entry_No_; "Entry No.")
                {
                }
                column(Customer_Entry_Customer_No_; "Customer No.")
                {
                }
                column(Customer_Entry_Global_Dimension_1_Code; "Global Dimension 1 Code")
                {
                }
                column(Customer_Entry_Global_Dimension_2_Code; "Global Dimension 2 Code")
                {
                }
                column(Customer_Entry_Agreement_No_; "Agreement No.")
                {
                }
                dataitem(ApplicationEntry; "Detailed Cust. Ledg. Entry")
                {
                    DataItemLink = "Cust. Ledger Entry No." = field("Entry No.");
                    DataItemTableView = sorting("Cust. Ledger Entry No.", "Posting Date") where("Entry Type" = const(Application), Unapplied = const(false));
                    column(ApplicationEntry_Entry_No_; "Entry No.")
                    {
                    }
                    column(ApplicationEntry_Cust__Ledger_Entry_No_; "Cust. Ledger Entry No.")
                    {
                    }
                    column(ApplicationEntry_Transaction_No_; "Transaction No.")
                    {
                    }
                    column(ApplicationEntry_Customer_No_; "Customer No.")
                    {
                    }
                    dataitem(AppliedEntry; "Detailed Cust. Ledg. Entry")
                    {
                        DataItemLink = "Transaction No." = field("Transaction No."), "Customer No." = field("Customer No.");
                        DataItemTableView = sorting("Transaction No.", "Customer No.", "Entry Type") where("Entry Type" = const(Application), Unapplied = const(false));
                        column(AppliedEntry__Posting_Date_; "Posting Date")
                        {
                        }
                        column(AppliedEntry__Document_Type_; "Document Type")
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
                        column(ApplCustLedgerEntry_Description; ApplCustLedgerEntry.Description)
                        {
                        }
                        column(ApplCustLedgerEntry__Currency_Code_; ApplCustLedgerEntry."Currency Code")
                        {
                        }
                        column(AppliedEntry_Entry_No_; "Entry No.")
                        {
                        }
                        column(AppliedEntry_Transaction_No_; "Transaction No.")
                        {
                        }
                        column(AppliedEntry_Customer_No_; "Customer No.")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if "Cust. Ledger Entry No." = "Customer Entry"."Entry No." then
                                CurrReport.Skip();

                            ApplCustLedgerEntry.Get("Cust. Ledger Entry No.");
                            ApplCustLedgerEntry.CalcFields("Amount (LCY)", Amount);

                            if ReportCurrency = ReportCurrency::LCY then begin
                                DocAmount2 := ApplCustLedgerEntry."Amount (LCY)";
                                AmountClosed := GetClosedAmount(ApplicationEntry."Amount (LCY)", "Amount (LCY)");
                            end else begin
                                DocAmount2 := ApplCustLedgerEntry.Amount;
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

                    CustEntryDocAmount := DocAmount1;
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
            dataitem("Customer Currence Ending"; Currency)
            {
                DataItemLink = "Customer Filter" = field("No."), "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"), "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"), "Agreement Filter" = field("Agreement Filter");
                DataItemTableView = sorting(Code) where("Cust. Ledg. Entries in Filter" = const(true));
                column(Customer_Currence_Ending_Code; Code)
                {
                }
                column(BalanceEnding_Control18; BalanceEnding)
                {
                }
                column(SignBalanceEnding_Control34; SignBalanceEnding)
                {
                }
                column(Customer_Currence_Ending_Customer_Filter; "Customer Filter")
                {
                }
                column(Customer_Currence_Ending_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
                {
                }
                column(Customer_Currence_Ending_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
                {
                }
                column(Customer_Currence_Ending_Agreement_Filter; "Agreement Filter")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    CalcFields(
                      "Customer Balance", "Customer Balance Due",
                      "Customer Outstanding Orders", "Customer Shipped Not Invoiced");
                    Value := "Customer Balance" +
                      "Customer Outstanding Orders" + "Customer Shipped Not Invoiced";
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
                        Caption = 'New Page For Customer';
                        ToolTip = 'Specifies if you want to print the data for each customer on a separate page.';
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
        ApplCustLedgerEntry: Record "Cust. Ledger Entry";
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
        CustEntryDocAmount: Decimal;
        PageCounter: Integer;
        Customer_Entries_AnalysisCaptionLbl: Label 'Customer Entries Analysis';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        ReportCurrencyCaptionLbl: Label 'Report Currency';
        NameCaptionLbl: Label 'Name';
        Closed_AmountCaptionLbl: Label 'Closed\Amount';
        Posting_DateCaptionLbl: Label 'Posting\Date';
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

