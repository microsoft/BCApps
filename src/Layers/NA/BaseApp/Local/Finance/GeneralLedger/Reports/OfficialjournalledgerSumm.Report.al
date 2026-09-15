// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Period;
using System.Utilities;

report 14030 "Official journal ledger Summ."
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/GeneralLedger/Reports/OfficialjournalledgerSumm.rdlc';
    Caption = 'Official journal ledger summary';

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number);
            PrintOnlyIfDetail = true;
            column(USERID; UserId)
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Periodo_____FORMAT_FromDate___________FORMAT_ToDate_; 'Periodo:' + Format(FromDate) + '..' + Format(ToDate))
            {
            }
            column(HeaderText; HeaderText)
            {
            }
            column(USERID_Control23; UserId)
            {
            }
            column(FORMAT_TODAY_0_4__Control26; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME_Control27; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Periodo_____FORMAT_FromDate___________FORMAT_ToDate__Control28; 'Periodo:' + Format(FromDate) + '..' + Format(ToDate))
            {
            }
            column(HeaderText_Control30; HeaderText)
            {
            }
            column(TotalCreditAmt; TotalCreditAmt)
            {
            }
            column(TotalDebitAmt; TotalDebitAmt)
            {
            }
            column(TotalCreditAmt_Control57; TotalCreditAmt)
            {
            }
            column(TotalDebitAmt_Control58; TotalDebitAmt)
            {
            }
            column(TotalDebitAmtEnd; TotalDebitAmtEnd)
            {
            }
            column(TotalCreditAmtEnd; TotalCreditAmtEnd)
            {
            }
            column(Integer_Number; Number)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(Official_Acc_Summarized_BookCaption; Official_Acc_Summarized_BookCaptionLbl)
            {
            }
            column(PageCaption_Control24; PageCaption_Control24Lbl)
            {
            }
            column(Official_Acc_Summarized_BookCaption_Control29; Official_Acc_Summarized_BookCaption_Control29Lbl)
            {
            }
            column(ContinuedCaption; ContinuedCaptionLbl)
            {
            }
            column(ContinuedCaption_Control59; ContinuedCaption_Control59Lbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            dataitem(Cuenta2; "G/L Account")
            {
                CalcFields = "Debit Amount", "Credit Amount", "Add.-Currency Debit Amount", "Add.-Currency Credit Amount";
                DataItemTableView = sorting("No.");
                column(j; j)
                {
                }
                column(PeriodDate; Format(PeriodDate))
                {
                }
                column(CreditAmt; CreditAmt)
                {
                }
                column(DebitAmt; DebitAmt)
                {
                }
                column(Cuenta2_Name; Name)
                {
                }
                column(Number; Number)
                {
                }
                column(TotalDebitAmt_Control52; TotalDebitAmt)
                {
                }
                column(TotalCreditAmt_Control53; TotalCreditAmt)
                {
                }
                column(Cuenta2_No_; "No.")
                {
                }
                column(Credit_AmountCaption; Credit_AmountCaptionLbl)
                {
                }
                column(Debit_AmountCaption; Debit_AmountCaptionLbl)
                {
                }
                column(PeriodCaption; PeriodCaptionLbl)
                {
                }
                column(NameCaption; NameCaptionLbl)
                {
                }
                column(No_Caption; No_CaptionLbl)
                {
                }
                column(Total_PeriodCaption; Total_PeriodCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if GLFilterAccType = GLFilterAccType::Mayor then
                        if StrLen("No.") <> 3 then
                            CurrReport.Skip();
                    CreditAmt := 0;
                    DebitAmt := 0;
                    Name := 'Mov. regularización';
                    Number := "No.";
                    if PrintAmountsInAddCurrency then begin
                        CreditAmt := CreditAmt + "Add.-Currency Credit Amount";
                        DebitAmt := DebitAmt + "Add.-Currency Debit Amount";
                    end else begin
                        CreditAmt := CreditAmt + "Credit Amount";
                        DebitAmt := DebitAmt + "Debit Amount";
                    end;

                    TotalCreditAmt := TotalCreditAmt + CreditAmt;
                    TotalDebitAmt := TotalDebitAmt + DebitAmt;
                    TotalCreditAmtEnd := TotalCreditAmtEnd + CreditAmt;
                    TotalDebitAmtEnd := TotalDebitAmtEnd + DebitAmt;
                end;

                trigger OnPreDataItem()
                begin
                    if not PrintClose then
                        CurrReport.Break();
                    SetRange("Date Filter", ClosingDate(ToDate));
                    if GLFilterAccType = GLFilterAccType::Mayor then
                        SetRange("Account Type", "Account Type"::Heading)
                    else
                        SetRange("Account Type", "Account Type"::Posting);
                    DebitAmt := 0;
                    CreditAmt := 0;
                    TotalCreditAmt := 0;
                    TotalDebitAmt := 0;
                    PeriodDate := ClosingDate(ToDate);
                end;
            }
            dataitem("G/L Account"; "G/L Account")
            {
                CalcFields = "Debit Amount", "Credit Amount", "Add.-Currency Debit Amount", "Add.-Currency Credit Amount", "Net Change", "Additional-Currency Net Change";
                DataItemTableView = sorting("No.");
                column(j___AddPeriod; j + AddPeriod)
                {
                }
                column(PeriodDate_Control44; Format(PeriodDate))
                {
                }
                column(CreditAmt_Control16; CreditAmt)
                {
                }
                column(G_L_Account_Name; Name)
                {
                }
                column(DebitAmt_Control18; DebitAmt)
                {
                }
                column(Number_Control19; Number)
                {
                }
                column(TotalDebitAmt_Control20; TotalDebitAmt)
                {
                }
                column(TotalCreditAmt_Control21; TotalCreditAmt)
                {
                }
                column(G_L_Account_No_; "No.")
                {
                }
                column(Credit_AmountCaption_Control40; Credit_AmountCaption_Control40Lbl)
                {
                }
                column(Debit_AmountCaption_Control41; Debit_AmountCaption_Control41Lbl)
                {
                }
                column(PeriodCaption_Control43; PeriodCaption_Control43Lbl)
                {
                }
                column(NameCaption_Control45; NameCaption_Control45Lbl)
                {
                }
                column(No_Caption_Control46; No_Caption_Control46Lbl)
                {
                }
                column(Total_PeriodCaption_Control22; Total_PeriodCaption_Control22Lbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if GLFilterAccType = GLFilterAccType::Mayor then
                        if StrLen("No.") <> 3 then
                            CurrReport.Skip();

                    CreditAmt := 0;
                    DebitAmt := 0;
                    Number := "No.";
                    if PrintClose then begin
                        Name := 'Mov. cierre';
                        CalcCloseEntriesHeading();
                    end;
                    if not PrintClose and not Open then begin
                        Name := Name;
                        if not PrintAmountsInAddCurrency then begin
                            DebitAmt := "G/L Account"."Debit Amount";
                            CreditAmt := "G/L Account"."Credit Amount";
                        end else begin
                            DebitAmt := "G/L Account"."Add.-Currency Debit Amount";
                            CreditAmt := "G/L Account"."Add.-Currency Credit Amount";
                        end;
                    end;
                    if Open then begin
                        Name := 'Mov. apertura';
                        CalcOpenEntriesHeading();
                    end;
                    TotalCreditAmt := TotalCreditAmt + CreditAmt;
                    TotalDebitAmt := TotalDebitAmt + DebitAmt;
                    TotalCreditAmtEnd := TotalCreditAmtEnd + CreditAmt;
                    TotalDebitAmtEnd := TotalDebitAmtEnd + DebitAmt;
                end;

                trigger OnPostDataItem()
                begin
                    Open := false;
                end;

                trigger OnPreDataItem()
                begin
                    if GLFilterAccType = GLFilterAccType::Mayor then
                        SetRange("Account Type", "Account Type"::Heading)
                    else
                        SetRange("Account Type", "Account Type"::Posting);
                    if Open then begin
                        SetRange("Date Filter", 0D, ClosingDate(FromDate - 1));
                        PeriodDate := FromDate;
                    end;
                    if PrintClose then begin
                        j := j + 1;
                        SetRange("Date Filter", 0D, ClosingDate(ToDate));
                        PeriodDate := ClosingDate(ToDate);
                    end;
                    if not Open and not PrintClose then begin
                        SetRange("Date Filter", FromFec, ClosingDate(ToFec - 1));
                        PeriodDate := FromFec;
                    end;
                    if AccountingPeriod."Starting Date" > ToDate then begin
                        SetRange("Date Filter", FromFec, ToFec - 1);
                        PeriodDate := FromFec;
                    end;

                    TotalCreditAmt := 0;
                    TotalDebitAmt := 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                j := j + 1;
                if (j = Num) and Closed then
                    PrintClose := true;
                if not Open then begin
                    FromFec := AccountingPeriod."Starting Date";
                    AccountingPeriod.Next();
                    ToFec := AccountingPeriod."Starting Date";
                end;
                TotalCreditAmt := 0;
                TotalDebitAmt := 0;
            end;

            trigger OnPreDataItem()
            begin
                if Verify(1) = 1 then begin
                    Open := true;
                    if ToDate = 0D then
                        ToDate := FromDate;
                    i := i + 1;
                end;
                if (Verify(2) = 1) and Closed then begin
                    if FromDate = 0D then
                        FromDate := ToDate;
                    i := i + 1;
                end else
                    Closed := false;
                Verify(4);
                if Closed and (FromDate = ToDate) then
                    Verify(0)
                else
                    Verify(5);
                if Open and (FromDate = ToDate) then
                    Verify(0)
                else
                    Verify(6);

                Num := Verify(3) + i;
                if not Open then
                    AddPeriod := Verify(7);
                SetRange(Number, 1, Num);
                AccountingPeriod.SetRange("Starting Date", FromDate, ToDate + 1);
                if AccountingPeriod.Find('-') then
                    GLSetup.Get();
                if PrintAmountsInAddCurrency then
                    HeaderText := StrSubstNo('Importes en %1', GLSetup."Additional Reporting Currency")
                else begin
                    GLSetup.TestField("LCY Code");
                    HeaderText := StrSubstNo('Importes en %1', GLSetup."LCY Code");
                end;
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
                    field(FromDate; FromDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'From Date';
                        ToolTip = 'Specifies the start date of the report.';
                    }
                    field(ToDate; ToDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'To Date';
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';
                    }
                    field(Closed; Closed)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Closing Entries';
                        ToolTip = 'Specifies if closing entries are included in the report.';
                    }
                    field(PrintAmountsInAddCurrency; PrintAmountsInAddCurrency)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Show Amounts In Add Currency';
                        ToolTip = 'Specifies if the reported amounts are shown in the additional reporting currency.';
                    }
                    field(Pagina; Pagina)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'First page';
                        ToolTip = 'Specifies the page number that the report will begin with.';
                    }
                    field(GLFilterAccType; GLFilterAccType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Account Type';
                        ToolTip = 'Specifies the type of the account.';
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

    var
        FromDate: Date;
        ToDate: Date;
        FromFec: Date;
        ToFec: Date;
        Open: Boolean;
        Closed: Boolean;
        j: Integer;
        AddPeriod: Integer;
        i: Integer;
        AccountingPeriod: Record "Accounting Period";
        PrintClose: Boolean;
        PrintAmountsInAddCurrency: Boolean;
        Number: Code[20];
        CreditAmt: Decimal;
        DebitAmt: Decimal;
        TotalCreditAmt: Decimal;
        TotalDebitAmt: Decimal;
        HeaderText: Text[30];
        GLSetup: Record "General Ledger Setup";
        PeriodDate: Date;
        Num: Integer;
        Pagina: Integer;
        TotalCreditAmtEnd: Decimal;
        TotalDebitAmtEnd: Decimal;
        GLFilterAccType: Option Mayor,Auxiliar;
        Text000: Label 'This report can run just for one fiscal year.';
        Text001: Label '%1 is not a period starting date.';
        Text002: Label 'Check fiscal year ending date.';
        PageCaptionLbl: Label 'Page';
        Official_Acc_Summarized_BookCaptionLbl: Label 'Official Acc. Summarized Book';
        PageCaption_Control24Lbl: Label 'Page';
        Official_Acc_Summarized_BookCaption_Control29Lbl: Label 'Official Acc. Summarized Book';
        ContinuedCaptionLbl: Label 'Continued';
        ContinuedCaption_Control59Lbl: Label 'Continued';
        TotalCaptionLbl: Label 'Total';
        Credit_AmountCaptionLbl: Label 'Credit Amount';
        Debit_AmountCaptionLbl: Label 'Debit Amount';
        PeriodCaptionLbl: Label 'Period';
        NameCaptionLbl: Label 'Name';
        No_CaptionLbl: Label 'No.';
        Total_PeriodCaptionLbl: Label 'Total Period';
        Credit_AmountCaption_Control40Lbl: Label 'Credit Amount';
        Debit_AmountCaption_Control41Lbl: Label 'Debit Amount';
        PeriodCaption_Control43Lbl: Label 'Period';
        NameCaption_Control45Lbl: Label 'Name';
        No_Caption_Control46Lbl: Label 'No.';
        Total_PeriodCaption_Control22Lbl: Label 'Total Period';

    procedure CalcCloseEntriesHeading()
    var
        GLAcc: Record "G/L Account";
    begin
        GLAcc.SetRange("Date Filter", 0D, ClosingDate(ToDate));
        if GLFilterAccType = GLFilterAccType::Mayor then begin
            GLAcc.SetFilter("No.", "G/L Account".Totaling);
            GLAcc.SetRange("Account Type", 0);
        end else
            GLAcc.SetFilter("No.", "G/L Account"."No.");
        if GLAcc.Find('-') then
            repeat
                GLAcc.CalcFields("Additional-Currency Net Change", "Net Change");
                if PrintAmountsInAddCurrency then begin
                    if GLAcc."Additional-Currency Net Change" > 0 then
                        CreditAmt := CreditAmt + GLAcc."Additional-Currency Net Change"
                    else
                        DebitAmt := DebitAmt + Abs(GLAcc."Additional-Currency Net Change");
                end else
                    if GLAcc."Net Change" > 0 then
                        CreditAmt := CreditAmt + GLAcc."Net Change"
                    else
                        DebitAmt := DebitAmt + Abs(GLAcc."Net Change");
            until GLAcc.Next() = 0;
    end;

    procedure CalcOpenEntriesHeading()
    var
        GLAcc: Record "G/L Account";
    begin
        GLAcc.SetRange("Date Filter", 0D, ClosingDate(FromDate - 1));
        if GLFilterAccType = GLFilterAccType::Mayor then begin
            GLAcc.SetFilter("No.", "G/L Account".Totaling);
            GLAcc.SetRange("Account Type", 0);
        end else
            GLAcc.SetFilter("No.", "G/L Account"."No.");
        if GLAcc.Find('-') then
            repeat
                GLAcc.CalcFields("Additional-Currency Net Change", "Net Change");
                if PrintAmountsInAddCurrency then begin
                    if GLAcc."Additional-Currency Net Change" < 0 then
                        CreditAmt := CreditAmt + Abs(GLAcc."Additional-Currency Net Change")
                    else
                        DebitAmt := DebitAmt + GLAcc."Additional-Currency Net Change";
                end else
                    if GLAcc."Net Change" < 0 then
                        CreditAmt := CreditAmt + Abs(GLAcc."Net Change")
                    else
                        DebitAmt := DebitAmt + GLAcc."Net Change";

            until GLAcc.Next() = 0;
    end;

    procedure Verify(Process: Integer): Integer
    var
        AccPeriod: Record "Accounting Period";
        AccPeriod2: Record "Accounting Period";
    begin
        case Process of
            1:
                begin
                    AccPeriod.SetRange("New Fiscal Year", true);
                    AccPeriod.SetRange("Starting Date", FromDate);
                    if AccPeriod.FindFirst() then
                        exit(1);

                    exit(0);
                end;
            2:
                begin
                    AccPeriod.SetRange("New Fiscal Year", true);
                    AccPeriod.SetRange("Starting Date", ToDate + 1);
                    if AccPeriod.FindFirst() then
                        exit(1);

                    exit(0);
                end;
            3:
                begin
                    if Open and (FromDate = ToDate) then
                        exit(0);
                    AccPeriod.SetRange("Starting Date", FromDate, ToDate);
                    if AccPeriod.FindFirst() then
                        exit(AccPeriod.Count);

                    exit(0);
                end;
            4:
                if FromDate <> ToDate then begin
                    AccPeriod.SetRange("Starting Date", FromDate + 1, ToDate);
                    AccPeriod.SetRange("New Fiscal Year", true);
                    if AccPeriod.FindFirst() then begin
                        Error(Text000);
                        CurrReport.Break();
                    end;
                end;
            5:
                begin
                    AccPeriod.SetRange("Starting Date", FromDate);
                    if not AccPeriod.FindFirst() then
                        Error(Text001, FromDate);
                end;
            6:
                begin
                    AccPeriod.SetRange("Starting Date", ToDate + 1);
                    if not AccPeriod.FindFirst() then
                        Error(Text002);
                end;
            7:
                begin
                    AccPeriod2.SetFilter("Starting Date", '<%1', FromDate);
                    AccPeriod2.SetRange("New Fiscal Year", true);
                    if AccPeriod2.FindLast() then;
                    AccPeriod.SetRange("Starting Date", AccPeriod2."Starting Date", FromDate);
                    if AccPeriod.FindFirst() then
                        exit(AccPeriod.Count);

                    exit(0);
                end;
        end;
    end;
}

