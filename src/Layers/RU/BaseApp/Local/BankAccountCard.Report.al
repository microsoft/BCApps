#pragma warning disable AA0247
report 12448 "Bank Account Card"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/BankAccountCard.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Bank Account Card';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Bank Account"; "Bank Account")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(CurrentDate; CurrentDate)
            {
            }
            column(ApplicationLocalization_Date2Text_DateStartedOfPeriod___________ApplicationLocalization_Date2Text_EndingPeriodDate_; ApplicationLocalization.Date2Text(DateStartedOfPeriod) + '  ..  ' + ApplicationLocalization.Date2Text(EndingPeriodDate))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(USERID; UserId)
            {
            }
            column(CurrentFilter; CurrentFilter)
            {
            }
            column(PageCount; PageCount)
            {
            }
            column(Bank_GL_Acc_CardCaption; Bank_GL_Acc_CardCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Bank_Account_No_; "No.")
            {
            }
            column(Bank_Account_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
            {
            }
            column(Bank_Account_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
            {
            }
            column(Bank_Account_Date_Filter; "Date Filter")
            {
            }
            dataitem("Balance Beg/Ending"; "Integer")
            {
                DataItemTableView = sorting(Number);
                MaxIteration = 1;
                column(Bank_Account__Name; "Bank Account".Name)
                {
                }
                column(Bank_Account___No__; "Bank Account"."No.")
                {
                }
                column(Text005_____ApplicationLocalization_Date2Text_DateStartedOfPeriod_; Text005 + ' ' + ApplicationLocalization.Date2Text(DateStartedOfPeriod))
                {
                }
                column(SignBalanceBegining; SignBalanceBegining)
                {
                }
                column(BalanceBegining; BalanceBegining)
                {
                }
                column(Bank_Account___Credit_Amount__LCY__; "Bank Account"."Credit Amount (LCY)")
                {
                }
                column(Bank_Account___Debit_Amount__LCY__; "Bank Account"."Debit Amount (LCY)")
                {
                }
                column(Bank_Account__Name_Control80; "Bank Account".Name)
                {
                }
                column(BalanceEnding; BalanceEnding)
                {
                }
                column(SignBalanceEnding; SignBalanceEnding)
                {
                }
                column(Text006_____ApplicationLocalization_Date2Text_EndingPeriodDate_; Text006 + ' ' + ApplicationLocalization.Date2Text(EndingPeriodDate))
                {
                }
                column(Balance_Beg_Ending_Number; Number)
                {
                }
                dataitem("Bank Account Ledger Entry"; "Bank Account Ledger Entry")
                {
                    DataItemLink = "Bank Account No." = field("No."), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter"), "Posting Date" = field("Date Filter");
                    DataItemLinkReference = "Bank Account";
                    DataItemTableView = sorting("Bank Account No.", "Posting Date");
                    column(Bank_Account_Ledger_Entry__Posting_Date_; "Posting Date")
                    {
                    }
                    column(Bank_Account_Ledger_Entry__Document_No__; "Document No.")
                    {
                    }
                    column(Bank_Account_Ledger_Entry_Description; Description)
                    {
                    }
                    column(Bank_Account_Ledger_Entry__Debit_Amount__LCY__; "Debit Amount (LCY)")
                    {
                    }
                    column(Bank_Account_Ledger_Entry__Credit_Amount__LCY__; "Credit Amount (LCY)")
                    {
                    }
                    column(Bank_Account_Ledger_Entry__Entry_No__; "Entry No.")
                    {
                    }
                    column(Bank_Account_Ledger_Entry__Bal__Account_Type_; "Bal. Account Type")
                    {
                    }
                    column(Bank_Account_Ledger_Entry__Bal__Account_No__; "Bal. Account No.")
                    {
                    }
                    column(Entry_No_Caption; Entry_No_CaptionLbl)
                    {
                    }
                    column(Net_ChangeCaption; Net_ChangeCaptionLbl)
                    {
                    }
                    column(CreditCaption; CreditCaptionLbl)
                    {
                    }
                    column(DebitCaption; DebitCaptionLbl)
                    {
                    }
                    column(DescriptionCaption; DescriptionCaptionLbl)
                    {
                    }
                    column(Document_No_Caption; Document_No_CaptionLbl)
                    {
                    }
                    column(Posting_DateCaption; Posting_DateCaptionLbl)
                    {
                    }
                    column(Bank_Account_Ledger_Entry_Bank_Account_No_; "Bank Account No.")
                    {
                    }
                    column(Bank_Account_Ledger_Entry_Global_Dimension_1_Code; "Global Dimension 1 Code")
                    {
                    }
                    column(Bank_Account_Ledger_Entry_Global_Dimension_2_Code; "Global Dimension 2 Code")
                    {
                    }
                }
            }
            dataitem("Gen. Journal Line"; "Gen. Journal Line")
            {
                DataItemLink = "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"), "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter");
                DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.");
                RequestFilterFields = "Journal Template Name", "Journal Batch Name";
                RequestFilterHeading = 'Non-posted entries';
                column(Bank_Account__Name_Control70; "Bank Account".Name)
                {
                }
                column(Text004_____ApplicationLocalization_Date2Text_74; Text004 + ' ' + ApplicationLocalization.Date2Text(BeginingDateNonPosted) + '  ..  ' + ApplicationLocalization.Date2Text(EndingDateNonPosted))
                {
                }
                column(Bank_Account___No___Control1470005; "Bank Account"."No.")
                {
                }
                column(Gen__Journal_Line__Check_Printed_; "Check Printed")
                {
                }
                column(Gen__Journal_Line__Credit_Amount__LCY__; "Credit Amount (LCY)")
                {
                }
                column(Gen__Journal_Line__Debit_Amount__LCY__; "Debit Amount (LCY)")
                {
                }
                column(Gen__Journal_Line_Description; Description)
                {
                }
                column(Gen__Journal_Line__Document_No__; "Document No.")
                {
                }
                column(Gen__Journal_Line__Posting_Date_; "Posting Date")
                {
                }
                column(Gen__Journal_Line__Bal__Account_No__; "Bal. Account No.")
                {
                }
                column(Gen__Journal_Line__Bal__Account_Type_; "Bal. Account Type")
                {
                }
                column(Gen__Journal_Line__Debit_Amount__LCY___Control43; "Debit Amount (LCY)")
                {
                }
                column(Gen__Journal_Line__Credit_Amount__LCY___Control44; "Credit Amount (LCY)")
                {
                }
                column(Bank_Account__Name_Control42; "Bank Account".Name)
                {
                }
                column(Text007; Text007)
                {
                }
                column(UnpostedBalance; UnpostedBalance)
                {
                }
                column(SignBalanceNotPosted; SignBalanceNotPosted)
                {
                }
                column(Payment_checkCaption; Payment_checkCaptionLbl)
                {
                }
                column(Net_ChangeCaption_Control13; Net_ChangeCaption_Control13Lbl)
                {
                }
                column(DescriptionCaption_Control15; DescriptionCaption_Control15Lbl)
                {
                }
                column(CreditCaption_Control39; CreditCaption_Control39Lbl)
                {
                }
                column(DebitCaption_Control45; DebitCaption_Control45Lbl)
                {
                }
                column(Document_No_Caption_Control46; Document_No_Caption_Control46Lbl)
                {
                }
                column(Posting_DateCaption_Control50; Posting_DateCaption_Control50Lbl)
                {
                }
                column(Gen__Journal_Line_Journal_Template_Name; "Journal Template Name")
                {
                }
                column(Gen__Journal_Line_Journal_Batch_Name; "Journal Batch Name")
                {
                }
                column(Gen__Journal_Line_Line_No_; "Line No.")
                {
                }
                column(Gen__Journal_Line_Shortcut_Dimension_1_Code; "Shortcut Dimension 1 Code")
                {
                }
                column(Gen__Journal_Line_Shortcut_Dimension_2_Code; "Shortcut Dimension 2 Code")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if not (("Account Type" = "Account Type"::"Bank Account") and ("Account No." = "Bank Account"."No.")) then
                        if ("Bal. Account Type" = "Bal. Account Type"::"Bank Account") and ("Bal. Account No." = "Bank Account"."No.") then begin
                            "Bal. Account Type" := "Account Type";
                            "Bal. Account No." := "Account No.";
                            Value := "Debit Amount (LCY)";
                            "Debit Amount (LCY)" := "Credit Amount (LCY)";
                            "Credit Amount (LCY)" := Value;
                        end else
                            CurrReport.Skip();
                end;

                trigger OnPreDataItem()
                begin
                    if ExclNonpostedEntries then
                        CurrReport.Break();
                    SetRange("Posting Date", BeginingDateNonPosted, EndingDateNonPosted);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                SetRange("Date Filter", 0D, CalcDate('<-1D>', DateStartedOfPeriod));
                CalcFields("Balance at Date (LCY)");
                if "Balance at Date (LCY)" > 0 then
                    SignBalanceBegining := Text002
                else
                    if "Balance at Date" < 0 then
                        SignBalanceBegining := Text003
                    else
                        SignBalanceBegining := '';
                BalanceBegining := Abs("Balance at Date (LCY)");
                SetRange("Date Filter", 0D, EndingPeriodDate);
                CalcFields("Net Change (LCY)");
                if "Net Change (LCY)" > 0 then
                    SignBalanceEnding := Text002
                else
                    if "Net Change (LCY)" < 0 then
                        SignBalanceEnding := Text003
                    else
                        SignBalanceEnding := '';
                BalanceEnding := Abs("Net Change (LCY)");
                SetRange("Date Filter", DateStartedOfPeriod, EndingPeriodDate);
                CalcFields("Debit Amount (LCY)", "Credit Amount (LCY)");


                if NewPageForBankAcc then
                    PageCount += 1;
            end;

            trigger OnPreDataItem()
            begin
                PageCount := 0;
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
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';
                    }
                    field(NewPageForBankAcc; NewPageForBankAcc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Page For Bank Acc';
                        ToolTip = 'Specifies if you want to print a new page for each bank account.';
                    }
                    field(ExclNonpostedEntries; ExclNonpostedEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Except Non-posted Entries';
                        ToolTip = 'Specifies if you want to exclude the non-posted entries section from the report.';
                    }
                    field(BeginingDateNonPosted; BeginingDateNonPosted)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date of Non-posted Entries';
                    }
                    field(EndingDateNonPosted; EndingDateNonPosted)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date of Non-posted Entries';
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
        CurrentFilter := "Bank Account".GetFilters();
        if (DateStartedOfPeriod = 0D) and (EndingPeriodDate = 0D) then
            DateStartedOfPeriod := WorkDate();
        if DateStartedOfPeriod = 0D then
            DateStartedOfPeriod := EndingPeriodDate
        else
            if EndingPeriodDate = 0D then
                EndingPeriodDate := DateStartedOfPeriod;
        CurrentDate := ApplicationLocalization.Date2Text(Today()) + Format(Time(), 0, '(<Hours24>:<Minutes>)');
        if (BeginingDateNonPosted = 0D) and (EndingDateNonPosted = 0D) then begin
            BeginingDateNonPosted := DateStartedOfPeriod;
            EndingDateNonPosted := EndingPeriodDate;
        end else
            if BeginingDateNonPosted = 0D then
                BeginingDateNonPosted := DateStartedOfPeriod
            else
                if EndingDateNonPosted = 0D then
                    EndingDateNonPosted := EndingPeriodDate;
    end;

    var
#pragma warning disable AA0074
        Text002: Label 'Debit';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text003: Label 'Credit';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text004: Label 'Non-posted entries for the period from';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text005: Label 'Begining period balance';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text006: Label 'Ending period balance';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text007: Label 'Non-posted entries in current period total';
#pragma warning restore AA0074
        ApplicationLocalization: Codeunit "Localisation Management";
        CurrentDate: Text[30];
        CurrentFilter: Text;
        SignBalanceBegining: Text[10];
        SignBalanceEnding: Text[10];
        SignBalanceNotPosted: Text[30];
        BalanceBegining: Decimal;
        BalanceEnding: Decimal;
        UnpostedBalance: Decimal;
        Value: Decimal;
        DateStartedOfPeriod: Date;
        BeginingDateNonPosted: Date;
        EndingPeriodDate: Date;
        EndingDateNonPosted: Date;
        NewPageForBankAcc: Boolean;
        ExclNonpostedEntries: Boolean;
        PageCount: Integer;
        Bank_GL_Acc_CardCaptionLbl: Label 'Bank GL Acc Card';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Entry_No_CaptionLbl: Label 'Entry\No.';
        Net_ChangeCaptionLbl: Label 'Net Change';
        CreditCaptionLbl: Label 'Credit';
        DebitCaptionLbl: Label 'Debit';
        DescriptionCaptionLbl: Label 'Description';
        Document_No_CaptionLbl: Label 'Document No.';
        Posting_DateCaptionLbl: Label 'Posting Date';
        Payment_checkCaptionLbl: Label 'Payment check';
        Net_ChangeCaption_Control13Lbl: Label 'Net Change';
        DescriptionCaption_Control15Lbl: Label 'Description';
        CreditCaption_Control39Lbl: Label 'Credit';
        DebitCaption_Control45Lbl: Label 'Debit';
        Document_No_Caption_Control46Lbl: Label 'Document No.';
        Posting_DateCaption_Control50Lbl: Label 'Posting Date';
}

