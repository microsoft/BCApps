// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Finance.GeneralLedger.Reports;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Utilities;

report 11529 "SR Account Interest"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/Finance/GeneralLedger/Reports/SRAccountInterest.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Account Interest';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Header; "Integer")
        {
            DataItemTableView = sorting(Number);
            MaxIteration = 1;
            column(InterestDaysTxt; InterestDaysTxt)
            {
            }
            column(AccNameTxt; AccNameTxt)
            {
            }
            column(StartDateEndDate; Format(StartDate) + ' - ' + Format(EndDate))
            {
            }
            column(InterestRate; Format(InterestRate) + '%')
            {
            }
            column(InterestDate; Format(InterestDate))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(InterestDays2; InterestDays2)
            {
            }
            column(WithStartBalance; WithStartBalance)
            {
            }
            column(ShowInterestPerDay; ShowInterestPerDay)
            {
            }
            column(AccType; Format(AccType))
            {
            }
            column(RightTxt; RightTxt)
            {
            }
            column(Balance; Balance)
            {
            }
            column(InterestAmt; InterestAmt)
            {
            }
            column(InterestDays; InterestDays)
            {
            }
            column(StartDate; Format(StartDate))
            {
            }
            column(StartBalance; StartBalance)
            {
            }
            column(TotalInterestAmt; TotalInterestAmt)
            {
            }
            column(EndDate; Text004 + Format(EndDate))
            {
            }
            column(BalanceLCYCaption; BalanceLCYCaptionLbl)
            {
            }
            column(GLEntryAmountCaption; "G/L Entry".FieldCaption(Amount))
            {
            }
            column(TypeCaption; TypeCaptionLbl)
            {
            }
            column(GLEntryDescriptionCaption; "G/L Entry".FieldCaption(Description))
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(GLEntryDocNoCaption; "G/L Entry".FieldCaption("Document No."))
            {
            }
            column(AccInterestCaption; AccInterestCaptionLbl)
            {
            }
            column(InterestRateCaption; InterestRateCaptionLbl)
            {
            }
            column(InterestDateCaption; InterestDateCaptionLbl)
            {
            }
            column(EntriesfromtoCaption; EntriesfromtoCaptionLbl)
            {
            }
            column(PostDateCaption; PostDateCaptionLbl)
            {
            }
            column(InterestAmtLCYCaption; InterestAmtLCYCaptionLbl)
            {
            }
            column(AmtFCYCaption; AmtFCYCaptionLbl)
            {
            }
            column(StartBalanceCaption; StartBalanceCaptionLbl)
            {
            }
            dataitem("G/L Entry"; "G/L Entry")
            {
                DataItemTableView = sorting("G/L Account No.", "Posting Date");
                column(PostingDate_GLEntry; Format("Posting Date"))
                {
                }
                column(DocType_GLEntry; CopyStr(Format("Document Type"), 1, 3))
                {
                }
                column(DocNo_GLEntry; "Document No.")
                {
                }
                column(Desc_GLEntry; Description)
                {
                }
                column(Amount_GLEntry; Amount)
                {
                }
                column(InterestAmt_GLEntry; InterestAmt)
                {
                }
                column(InterestDays_GLEntry; InterestDays)
                {
                }
                column(Balance_GLEntry; Balance)
                {
                }
                column(FcyAmt; FcyAmt)
                {
                }
                column(EntryNo_GLEntry; "Entry No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    CalcInterest("Posting Date", Amount, "Source Currency Amount");
                end;

                trigger OnPreDataItem()
                begin
                    if AccType <> AccType::"G/L" then
                        CurrReport.Break();

                    SetRange("G/L Account No.", AccNumber);
                    SetRange("Posting Date", StartDate, EndDate);
                end;
            }
            dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
            {
                DataItemTableView = sorting("Customer No.", "Posting Date", "Currency Code");
                column(Balance_CustLedgEntry; Balance)
                {
                }
                column(AmtLCY_CustLedgEntry; "Amount (LCY)")
                {
                }
                column(InterestAmt_CustLedgEntry; InterestAmt)
                {
                }
                column(InterestDays_CustLedgEntry; InterestDays)
                {
                }
                column(DocType_CustLedgEntry; CopyStr(Format("Document Type"), 1, 3))
                {
                }
                column(Desc_CustLedgEntry; Description)
                {
                }
                column(DocNo_CustLedgEntry; "Document No.")
                {
                }
                column(PostingDate_CustLedgEntry; Format("Posting Date"))
                {
                }
                column(CurrCode_CustLedgEntry; "Currency Code")
                {
                }
                column(FcyAmt_CustLedgEntry; FcyAmt)
                {
                }
                column(EntryNo_CustLedgEntry; "Entry No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    CalcFields("Amount (LCY)", Amount);

                    CalcInterest("Posting Date", "Amount (LCY)", Amount);
                end;

                trigger OnPreDataItem()
                begin
                    if AccType <> AccType::Customer then
                        CurrReport.Break();

                    SetRange("Customer No.", AccNumber);
                    SetRange("Posting Date", StartDate, EndDate);
                end;
            }
            dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
            {
                DataItemTableView = sorting("Vendor No.", "Posting Date", "Currency Code");
                column(Balance_VendLedgEntry; Balance)
                {
                }
                column(AmtLCY_VendLedgEntry; "Amount (LCY)")
                {
                }
                column(InterestAmt_VendLedgEntry; InterestAmt)
                {
                }
                column(InterestDays_VendLedgEntry; InterestDays)
                {
                }
                column(DocType_VendLedgEntry; CopyStr(Format("Document Type"), 1, 3))
                {
                }
                column(Desc_VendLedgEntry; Description)
                {
                }
                column(DocNo_VendLedgEntry; "Document No.")
                {
                }
                column(PostingDate_VendLedgEntry; Format("Posting Date"))
                {
                }
                column(CurrCode_VendLedgEntry; "Currency Code")
                {
                }
                column(FcyAmt_VendLedgEntry; FcyAmt)
                {
                }
                column(EntryNo_VendLedgEntry; "Entry No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    CalcFields("Amount (LCY)", Amount);

                    CalcInterest("Posting Date", "Amount (LCY)", Amount);
                end;

                trigger OnPreDataItem()
                begin
                    if AccType <> AccType::Vendor then
                        CurrReport.Break();

                    SetRange("Vendor No.", AccNumber);
                    SetRange("Posting Date", StartDate, EndDate);
                end;
            }
            dataitem("Bank Account Ledger Entry"; "Bank Account Ledger Entry")
            {
                DataItemTableView = sorting("Bank Account No.", "Posting Date");
                column(Balance_BankAccLedgEntry; Balance)
                {
                }
                column(AmtLCY_BankAccLedgEntry; "Amount (LCY)")
                {
                }
                column(InterestAmt_BankAccLedgEntry; InterestAmt)
                {
                }
                column(InterestDays_BankAccLedgEntry; InterestDays)
                {
                }
                column(DocType_BankAccLedgEntry; CopyStr(Format("Document Type"), 1, 3))
                {
                }
                column(Desc_BankAccLedgEntry; Description)
                {
                }
                column(DocNo_BankAccLedgEntry; "Document No.")
                {
                }
                column(PostingDate_BankAccLedgEntry; Format("Posting Date"))
                {
                }
                column(FcyAmt_BankAccLedgEntry; FcyAmt)
                {
                }
                column(EntryNo_BankAccLedgEntry; "Entry No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    CalcInterest("Posting Date", "Amount (LCY)", Amount);
                end;

                trigger OnPreDataItem()
                begin
                    if AccType <> AccType::Bank then
                        CurrReport.Break();

                    SetRange("Bank Account No.", AccNumber);
                    SetRange("Posting Date", StartDate, EndDate);
                end;
            }
        }
    }

    requestpage
    {
        Caption = 'SR Account Interest';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field("Account Type"; AccType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Account Type';
                        OptionCaption = 'G/L,Customer,Vendor,Bank';
                        ToolTip = 'Specifies the account type.';

                        trigger OnValidate()
                        begin
                            AccTypeOnAfterValidate();
                        end;
                    }
                    field("Account No."; AccNumber)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Account No.';
                        ToolTip = 'Specifies the account number.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            case AccType of
                                AccType::"G/L":
                                    if PAGE.RunModal(0, GlAcc) = ACTION::LookupOK then
                                        AccNumber := GlAcc."No.";
                                AccType::Customer:
                                    if PAGE.RunModal(0, Customer) = ACTION::LookupOK then
                                        AccNumber := Customer."No.";
                                AccType::Vendor:
                                    if PAGE.RunModal(0, Vendor) = ACTION::LookupOK then
                                        AccNumber := Vendor."No.";
                                AccType::Bank:
                                    if PAGE.RunModal(0, BankAcc) = ACTION::LookupOK then
                                        AccNumber := BankAcc."No.";
                            end;
                        end;
                    }
                    group(Entries)
                    {
                        Caption = 'Entries';
                        field("From Date"; StartDate)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'From Date';
                            ToolTip = 'Specifies the first date to be included in the report.';
                        }
                        field(EndDate; EndDate)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'To Date';
                            ToolTip = 'Specifies the end date to include in the report.';

                            trigger OnValidate()
                            begin
                                InterestDate := EndDate;
                            end;
                        }
                    }
                    field("Interest Date"; InterestDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Interest Date';
                        ToolTip = 'Specifies the end date for the interest calculation. This is typically the end date of the entries. If the interest date is earlier than the posting date, the interest is negative.';
                    }
                    field("Interest Rate %"; InterestRate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Interest Rate %';
                        ToolTip = 'Specifies the rate for calculating interest. If an interest rate is changed during the year, the calculation of interest can be run a second time with a different date range and interest date.';
                    }
                    field("No of Days per Year"; LengthOfYear)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No of Days per Year';
                        OptionCaption = '360 Days,Actual Days (365/366)';
                        ToolTip = 'Specifies the number of days of interest, which will calculate the amount of interest. Options include 360 Days and Actual Days (365/366).';
                    }
                    field("With Start Balance"; WithStartBalance)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'With Start Balance';
                        ToolTip = 'Specifies if the account''s beginning balance will be used to compute the interest.';
                    }
                    field("Show Interest per Line"; ShowInterestPerDay)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Interest per Line';
                        ToolTip = 'Specifies if the amount of interest and number of days until the interest date are shown for each entry.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if StartDate = 0D then begin
                StartDate := CalcDate('<-CY>', WorkDate());
                EndDate := CalcDate('<CY>', WorkDate());
                InterestDate := EndDate;
                WithStartBalance := true;
                ShowInterestPerDay := true;
                InterestRate := 5;
            end;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if (AccNumber = '') or
           (InterestRate = 0) or
           (StartDate = 0D) or
           (EndDate = 0D) or
           (InterestDate = 0D)
        then
            Error(Text000);

        case AccType of
            AccType::"G/L":
                begin
                    GlAcc.Get(AccNumber);
                    GlAcc.SetRange("Date Filter", 0D, ClosingDate(StartDate - 1));
                    GlAcc.CalcFields("Balance at Date");
                    StartBalance := GlAcc."Balance at Date";
                    AccNameTxt := GlAcc.Name;
                end;
            AccType::Customer:
                begin
                    Customer.Get(AccNumber);
                    Customer.SetRange("Date Filter", 0D, ClosingDate(StartDate - 1));
                    Customer.CalcFields("Net Change (LCY)");
                    StartBalance := Customer."Net Change (LCY)";
                    AccNameTxt := Customer.Name;
                end;
            AccType::Vendor:
                begin
                    Vendor.Get(AccNumber);
                    Vendor.SetRange("Date Filter", 0D, ClosingDate(StartDate - 1));
                    Vendor.CalcFields("Net Change (LCY)");
                    StartBalance := Vendor."Net Change (LCY)";
                    AccNameTxt := Vendor.Name;
                end;
            AccType::Bank:
                begin
                    BankAcc.Get(AccNumber);
                    BankAcc.SetRange("Date Filter", 0D, ClosingDate(StartDate - 1));
                    BankAcc.CalcFields("Net Change (LCY)");
                    StartBalance := BankAcc."Net Change (LCY)";
                    AccNameTxt := BankAcc.Name;
                end;
        end;

        RightTxt := ' ' + AccNumber + ' ' + AccNameTxt;

        AccNameTxt := Format(AccType) + ' ' + AccNumber + ' ' + AccNameTxt;

        if ShowInterestPerDay then
            InterestDaysTxt := Text001;

        if LengthOfYear = LengthOfYear::"360 Days" then
            DaysPerYear := 360
        else
            DaysPerYear := CalcDate('<CY>', InterestDate) - CalcDate('<-CY>', InterestDate) + 1;

        if WithStartBalance then
            CalcInterest(StartDate, StartBalance, 0)
        else
            Balance := 0;
        InterestDays2 := InterestDays;
    end;

    var
        Text000: Label 'Account no, interest rate, start date, end date and interest date must be specified.';
        Text001: Label 'Days';
        Text004: Label 'Total per ';
        GlAcc: Record "G/L Account";
        Customer: Record Customer;
        Vendor: Record Vendor;
        BankAcc: Record "Bank Account";
        AccNumber: Code[20];
        AccNameTxt: Text[100];
        InterestDaysTxt: Text[30];
        InterestRate: Decimal;
        StartDate: Date;
        EndDate: Date;
        InterestDate: Date;
        LengthOfYear: Option "360 Days","Actual Days (365/366)";
        DaysPerYear: Integer;
        ShowInterestPerDay: Boolean;
        WithStartBalance: Boolean;
        InterestDays: Integer;
        FcyAmt: Decimal;
        InterestAmt: Decimal;
        InterestNumbers: Decimal;
        TotalInterestAmt: Decimal;
        Balance: Decimal;
        StartBalance: Decimal;
        AccType: Option "G/L",Customer,Vendor,Bank;
        InterestDays2: Integer;
        RightTxt: Text;
        BalanceLCYCaptionLbl: Label 'Balance (LCY)';
        TypeCaptionLbl: Label 'Type';
        PageNoCaptionLbl: Label 'Page';
        AccInterestCaptionLbl: Label 'Account Interest';
        InterestRateCaptionLbl: Label 'Interest Rate';
        InterestDateCaptionLbl: Label 'InterestDate';
        EntriesfromtoCaptionLbl: Label 'Entries from/to';
        PostDateCaptionLbl: Label 'Post Date';
        InterestAmtLCYCaptionLbl: Label 'Interest Amount LCY';
        AmtFCYCaptionLbl: Label 'Amt. FCY';
        StartBalanceCaptionLbl: Label 'Start Balance';

    [Scope('OnPrem')]
    procedure CalcInterest(_PostDate: Date; _Amt: Decimal; _FcyAmt: Decimal)
    var
        CorrDays: Integer;
    begin
        if LengthOfYear = LengthOfYear::"360 Days" then begin
            CorrDays := CorrectMonthLength(_PostDate);
            CorrDays := CorrDays - CorrectMonthLength(InterestDate);
            InterestDays :=
              (Date2DMY(InterestDate, 3) - Date2DMY(_PostDate, 3)) * 360 +
              (Date2DMY(InterestDate, 2) - Date2DMY(_PostDate, 2)) * 30 +
              (Date2DMY(InterestDate, 1) - Date2DMY(_PostDate, 1)) +
              1 + CorrDays;
        end else
            InterestDays := InterestDate - NormalDate(_PostDate) + 1;

        InterestNumbers := _Amt * InterestDays / 100;
        InterestAmt := Round(InterestNumbers / DaysPerYear * InterestRate);
        TotalInterestAmt := TotalInterestAmt + InterestAmt;
        Balance := Balance + _Amt;

        if not ShowInterestPerDay then begin
            InterestDays := 0;
            InterestAmt := 0;
        end;

        if (_FcyAmt <> 0) and (FcyAmt <> _Amt) then
            FcyAmt := _FcyAmt
        else
            FcyAmt := 0;
    end;

    [Scope('OnPrem')]
    procedure CorrectMonthLength(_Date: Date) NoOfCorrDays: Integer
    begin
        NoOfCorrDays := 0;

        if Date2DMY(_Date, 1) = 31 then
            NoOfCorrDays := 1;

        if (Date2DMY(_Date, 2) = 2) and
           (Date2DMY(_Date, 1) = 28)
        then
            NoOfCorrDays := -2;

        if (Date2DMY(_Date, 2) = 2) and
           (Date2DMY(_Date, 1) = 29)
        then
            NoOfCorrDays := -1;

        exit(NoOfCorrDays);
    end;

    local procedure AccTypeOnAfterValidate()
    begin
        AccNumber := '';
    end;
}
