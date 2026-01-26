// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Period;
using System.Utilities;

report 10725 "Detail Acc. Stat.- C&O Entries"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/GeneralLedger/Reports/DetailAccStatCOEntries.rdlc';
    Caption = 'Detail Acc. Stat.- C&O Entries';

    dataset
    {
        dataitem("<Integer3>"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            dataitem("G/L Account"; "G/L Account")
            {
                DataItemTableView = sorting("No.");
                RequestFilterFields = "Date Filter", "No.", "Global Dimension 2 Filter", "Global Dimension 1 Filter";
                column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
                {
                }
                column(USERID; UserId)
                {
                }
                column(STRSUBSTNO_Text1100002_GLFilter_; StrSubstNo(Text1100002, GLFilter))
                {
                }
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
                {
                }
                column(G_L_Account__TABLECAPTION__________GLFilterAcc; TableCaption + ': ' + GLFilterAcc)
                {
                }
                column(HeaderText; HeaderText)
                {
                }
                column(IncludeAccountBalance; IncludeAccountBalance)
                {
                }
                column(EmptyString; '')
                {
                }
                column(PageNoPerAcc; PageNoPerAcc)
                {
                }
                column(NameAcc; NameAcc)
                {
                }
                column(NumAcc; NumAcc)
                {
                }
                column(PageNo; PageNo)
                {
                }
                column(G_L_Account_No_; "No.")
                {
                }
                column(G_L_Account_Date_Filter; "Date Filter")
                {
                }
                column(G_L_Account_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
                {
                }
                column(G_L_Account_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
                {
                }
                column(G_L_Account_Business_Unit_Filter; "Business Unit Filter")
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(Detail_Account_Statement___Closing___Opening_EntriesCaption; Detail_Account_Statement___Closing___Opening_EntriesCaptionLbl)
                {
                }
                column(Only_Accs__With_Entries_at_DateCaption; Only_Accs__With_Entries_at_DateCaptionLbl)
                {
                }
                column(Balance_at_dateCaption; Balance_at_dateCaptionLbl)
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
                column(Posting_DateCaption; Posting_DateCaptionLbl)
                {
                }
                dataitem("Integer"; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(GLBalance; GLBalance)
                    {
                    }
                    column(TotalDebit; TotalDebit)
                    {
                    }
                    column(FromDate; FromDate)
                    {
                    }
                    column(TotalCredit; TotalCredit)
                    {
                    }
                    column(Open_AND___TotalDebit____0__OR__TotalCredit____0__; Open and ((TotalDebit <> 0) or (TotalCredit <> 0)))
                    {
                    }
                    column(Integer_Number; Number)
                    {
                    }
                    column(Total_Opening_EntriesCaption; Total_Opening_EntriesCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        Open := false;
                        GLBalance := 0;
                        if GLFilterDim1 <> '' then
                            GLAccount.SetFilter("Global Dimension 1 Filter", GLFilterDim1);
                        if GLFilterDim2 <> '' then
                            GLAccount.SetFilter("Global Dimension 2 Filter", GLFilterDim2);

                        if InitPeriodDate = FromDate then
                            Open := true;
                        GLAccount.SetRange("Date Filter", 0D, ClosingDate(CalcDate('<-1D>', FromDate)));
                        GLAccount.SetFilter("No.", "G/L Account"."No.");
                        if GLAccount.Find('-') then
                            repeat
                                GLAccount.CalcFields("Additional-Currency Net Change", "Net Change");
                                if PrintAmountsInAddCurrency then begin
                                    if GLAccount."Additional-Currency Net Change" > 0 then
                                        TotalDebit := TotalDebit + GLAccount."Additional-Currency Net Change"
                                    else
                                        TotalCredit := TotalCredit + Abs(GLAccount."Additional-Currency Net Change");
                                end else
                                    if GLAccount."Net Change" > 0 then
                                        TotalDebit := TotalDebit + GLAccount."Net Change"
                                    else
                                        TotalCredit := TotalCredit + Abs(GLAccount."Net Change");
                            until GLAccount.Next() = 0;

                        GLBalance := TotalDebit - TotalCredit;
                        if GLBalance = 0 then begin
                            TotalDebit := 0;
                            TotalCredit := 0;
                        end;
                        TransDebit := TFTotalDebitAmt;
                        TransCredit := TFTotalCreditAmt;
                        if Open and (GLBalance <> 0) then begin
                            TFTotalDebitAmt := TFTotalDebitAmt + TotalDebit;
                            TFTotalCreditAmt := TFTotalCreditAmt + TotalCredit;
                        end;
                        if Open and ((TotalDebit <> 0) or (TotalCredit <> 0)) then
                            LineNo := LineNo + 1;
                    end;
                }
                dataitem("<Accounting Period2>"; "Accounting Period")
                {
                    DataItemTableView = sorting("Starting Date");
                    column(CLOSINGDATE_CALCDATE_Text1100001__Starting_Date___; Format(ClosingDate(CalcDate('<-1D>', "Starting Date"))))
                    {
                    }
                    column(Accounting_Period2___Starting_Date_; Format("Starting Date"))
                    {
                    }
                    column(GLBalance_Control13; GLBalance)
                    {
                    }
                    column(TotalDebit_Control2; TotalDebit)
                    {
                    }
                    column(TotalCredit_Control9; TotalCredit)
                    {
                    }
                    column(TotalDebit_0; TotalDebit + 0)
                    {
                    }
                    column(TotalCredit_0; TotalCredit + 0)
                    {
                    }
                    column(NOT_NotFound__AND___TotalDebit____0__OR__TotalCredit____0__; (not NotFound) and ((TotalDebit <> 0) or (TotalCredit <> 0)))
                    {
                    }
                    column(Accounting_Period2__Starting_Date; "Starting Date")
                    {
                    }
                    column(Total_Opening_EntriesCaption_Control31; Total_Opening_EntriesCaption_Control31Lbl)
                    {
                    }
                    column(Total_Closing_EntriesCaption; Total_Closing_EntriesCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if GLBalance = 0 then begin
                            TotalDebit := 0;
                            TotalCredit := 0;
                        end;
                        if (not NotFound) and (GLBalance <> 0) then begin
                            TFTotalDebitAmt := TFTotalDebitAmt + TotalDebit + TotalCredit;
                            TFTotalCreditAmt := TFTotalCreditAmt + TotalDebit + TotalCredit;
                        end;
                        TransDebit := TFTotalDebitAmt;
                        TransCredit := TFTotalCreditAmt;
                        if (not NotFound) and ((TotalDebit <> 0) or (TotalCredit <> 0)) then
                            LineNo := LineNo + 2;
                    end;

                    trigger OnPreDataItem()
                    begin
                        PostDate := FromDate;
                        GLEntry3.SetCurrentKey("G/L Account No.", "Posting Date");
                        if GLEntry3.Find('-') then;
                        GLEntry3.SetRange("Posting Date", FromDate, ToDate);
                        if GLFilterDim1 <> '' then
                            GLEntry3.SetFilter("Global Dimension 1 Code", GLFilterDim1);
                        if GLFilterDim2 <> '' then
                            GLEntry3.SetFilter("Global Dimension 2 Code", GLFilterDim2);
                        GLEntry3.SetFilter("G/L Account No.", "G/L Account"."No.");
                        if GLEntry3.Find('-') then begin
                            GLEntry3.Next(-1);
                            PostDate := GLEntry3."Posting Date";
                        end else
                            NotFound := true;

                        SetRange("New Fiscal Year", true);
                        SetRange("Date Locked", true);
                        SetFilter("Starting Date", '> %1 & <= %2', FromDate, PostDate);

                        if NotFound then
                            CurrReport.Skip();
                    end;
                }
                dataitem("G/L Entry"; "G/L Entry")
                {
                    DataItemLink = "Posting Date" = field("Date Filter"), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter"), "Business Unit Code" = field("Business Unit Filter");
                    DataItemLinkReference = "G/L Account";
                    DataItemTableView = sorting("Posting Date", "G/L Account No.");
                    column(G_L_Entry_Entry_No_; "Entry No.")
                    {
                    }
                    column(G_L_Entry_Posting_Date; "Posting Date")
                    {
                    }
                    column(G_L_Entry_Global_Dimension_1_Code; "Global Dimension 1 Code")
                    {
                    }
                    column(G_L_Entry_Global_Dimension_2_Code; "Global Dimension 2 Code")
                    {
                    }
                    column(G_L_Entry_Business_Unit_Code; "Business Unit Code")
                    {
                    }
                    dataitem("<Accounting Period3>"; "Accounting Period")
                    {
                        DataItemTableView = sorting("Starting Date");
                        column(Accounting_Period3___Starting_Date_; Format("Starting Date"))
                        {
                        }
                        column(CLOSINGDATE_CALCDATE_Text1100001__Starting_Date____Control102; Format(ClosingDate(CalcDate('<-1D>', "Starting Date"))))
                        {
                        }
                        column(GLBalance_Control63; GLBalance)
                        {
                        }
                        column(TotalDebit_Control16; TotalDebit)
                        {
                        }
                        column(TotalCredit_Control19; TotalCredit)
                        {
                        }
                        column(TotalCredit_0_0; TotalCredit + 0 + 0)
                        {
                        }
                        column(TotalDebit_0_0; TotalDebit + 0 + 0)
                        {
                        }
                        column(TotalDebit____0__OR__TotalCredit____0_; (TotalDebit <> 0) or (TotalCredit <> 0))
                        {
                        }
                        column(Accounting_Period3__Starting_Date; "Starting Date")
                        {
                        }
                        column(Total_Opening_EntriesCaption_Control108; Total_Opening_EntriesCaption_Control108Lbl)
                        {
                        }
                        column(Total_Closing_EntriesCaption_Control109; Total_Closing_EntriesCaption_Control109Lbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Num = 0 then
                                CurrReport.Skip();
                            TotalDebit := 0;
                            TotalCredit := 0;
                            GLAccount.SetRange("Date Filter");
                            if GLFilterDim1 <> '' then
                                GLAccount.SetFilter("Global Dimension 1 Filter", GLFilterDim1);
                            if GLFilterDim2 <> '' then
                                GLAccount.SetFilter("Global Dimension 2 Filter", GLFilterDim2);
                            GLAccount.SetRange("Date Filter", 0D, ClosingDate(CalcDate('<-1D>', "Starting Date")));
                            GLAccount.SetFilter("No.", "G/L Account"."No.");
                            if GLAccount.Find('-') then
                                repeat
                                    GLAccount.CalcFields("Additional-Currency Net Change", "Net Change");
                                    if PrintAmountsInAddCurrency then begin
                                        if GLAccount."Additional-Currency Net Change" > 0 then
                                            TotalDebit := TotalDebit + GLAccount."Additional-Currency Net Change"
                                        else
                                            TotalCredit := TotalCredit + Abs(GLAccount."Additional-Currency Net Change");
                                    end else
                                        if GLAccount."Net Change" > 0 then
                                            TotalDebit := TotalDebit + GLAccount."Net Change"
                                        else
                                            TotalCredit := TotalCredit + Abs(GLAccount."Net Change");
                                until GLAccount.Next() = 0;

                            if GLBalance = 0 then begin
                                TotalDebit := 0;
                                TotalCredit := 0;
                            end else begin
                                TFTotalDebitAmt := TFTotalDebitAmt + TotalDebit + TotalCredit;
                                TFTotalCreditAmt := TFTotalCreditAmt + TotalDebit + TotalCredit;
                            end;
                            TransDebit := TFTotalDebitAmt;
                            TransCredit := TFTotalCreditAmt;
                            if (TotalDebit <> 0) or (TotalCredit <> 0) then
                                LineNo := LineNo + 2;
                        end;

                        trigger OnPreDataItem()
                        begin
                            if Num > 0 then begin
                                SetFilter("Starting Date", '>%1 & <= %2', LastDate, NormPostDate);
                                SetRange("Date Locked", true);
                                SetRange("New Fiscal Year", true);
                            end;
                            if Num = 0 then begin
                                SetRange("New Fiscal Year", true);
                                Find('-');
                                CurrReport.Skip();
                            end;
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        Num := 0;
                        TransDebit := TFTotalDebitAmt;
                        TransCredit := TFTotalCreditAmt;
                        TotalDebit := 0;
                        TotalCredit := 0;

                        if not PrintAmountsInAddCurrency then begin
                            TFTotalDebitAmt := TFTotalDebitAmt + "Debit Amount";
                            TFTotalCreditAmt := TFTotalCreditAmt + "Credit Amount";
                            TFGLBalance := TFGLBalance + "Debit Amount" - "Credit Amount";
                        end else begin
                            TFTotalDebitAmt := TFTotalDebitAmt + "Add.-Currency Debit Amount";
                            TFTotalCreditAmt := TFTotalCreditAmt + "Add.-Currency Credit Amount";
                            TFGLBalance := TFGLBalance + "Add.-Currency Debit Amount" - "Add.-Currency Credit Amount";
                        end;
                        if not PrintAmountsInAddCurrency then begin
                            TotalDebit := TotalDebit + "Debit Amount";
                            TotalCredit := TotalCredit + "Credit Amount";
                            GLBalance := GLBalance + "Debit Amount" - "Credit Amount";
                        end else begin
                            TotalDebit := TotalDebit + "Add.-Currency Debit Amount";
                            TotalCredit := TotalCredit + "Add.-Currency Credit Amount";
                            GLBalance := GLBalance + "Add.-Currency Debit Amount" - "Add.-Currency Credit Amount";
                        end;
                        PostDate := "Posting Date";
                        LastDate := "Posting Date";
                        i := i + 1;
                        Print := true;

                        if Next() <> 0 then begin
                            NormPostDate := NormalDate("Posting Date");
                            Num := CalcAccountingPeriod(NormPostDate, LastDate);
                            Next(-1);
                        end;
                    end;

                    trigger OnPostDataItem()
                    begin
                        Num := 1;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetCurrentKey("Posting Date", "G/L Account No.");
                        SetRange("Posting Date", FromDate, ToDate);
                        if GLFilterDim1 <> '' then
                            SetFilter("Global Dimension 1 Code", GLFilterDim1);
                        if GLFilterDim2 <> '' then
                            SetFilter("Global Dimension 2 Code", GLFilterDim2);
                        SetFilter("G/L Account No.", "G/L Account"."No.");
                        LastDate := 0D;
                        Num := 0;
                        Print := false;
                        Open := false;
                        i := 0;
                        TotalDebit := 0;
                        TotalCredit := 0;
                    end;
                }
                dataitem("Accounting Period"; "Accounting Period")
                {
                    DataItemTableView = sorting("Starting Date");
                    column(DateOpen; Format(DateOpen))
                    {
                    }
                    column(CLOSINGDATE_DateClose_; Format(DateClose))
                    {
                    }
                    column(GLBalance_Control84; GLBalance)
                    {
                    }
                    column(TotalDebit_Control21; TotalDebit)
                    {
                    }
                    column(TotalCredit_Control22; TotalCredit)
                    {
                    }
                    column(TotalCredit_0_0_0; TotalCredit + 0 + 0 + 0)
                    {
                    }
                    column(TotalDebit_0_0_0; TotalDebit + 0 + 0 + 0)
                    {
                    }
                    column(TotalDebit____0__OR__TotalCredit____0__Control1100005; (TotalDebit <> 0) or (TotalCredit <> 0))
                    {
                    }
                    column(Accounting_Period_Starting_Date; "Starting Date")
                    {
                    }
                    column(Total_Closing_EntriesCaption_Control70; Total_Closing_EntriesCaption_Control70Lbl)
                    {
                    }
                    column(Total_Opening_EntriesCaption_Control68; Total_Opening_EntriesCaption_Control68Lbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        DateOpen := "Starting Date";
                        DateClose := ClosingDate(CalcDate('<-1D>', "Starting Date"));
                        TotalDebit := 0;
                        TotalCredit := 0;
                        GLAccount.SetRange("Date Filter");
                        if GLFilterDim1 <> '' then
                            GLAccount.SetFilter("Global Dimension 1 Filter", GLFilterDim1);
                        if GLFilterDim2 <> '' then
                            GLAccount.SetFilter("Global Dimension 2 Filter", GLFilterDim2);
                        GLAccount.SetRange("Date Filter", 0D, DateClose);
                        GLAccount.SetFilter("No.", "G/L Account"."No.");
                        if GLAccount.Find('-') then
                            repeat
                                GLAccount.CalcFields("Additional-Currency Net Change", "Net Change");
                                if PrintAmountsInAddCurrency then begin
                                    if GLAccount."Additional-Currency Net Change" > 0 then
                                        TotalDebit := TotalDebit + GLAccount."Additional-Currency Net Change"
                                    else
                                        TotalCredit := TotalCredit + Abs(GLAccount."Additional-Currency Net Change");
                                end else
                                    if GLAccount."Net Change" > 0 then
                                        TotalDebit := TotalDebit + GLAccount."Net Change"
                                    else
                                        TotalCredit := TotalCredit + Abs(GLAccount."Net Change");
                            until GLAccount.Next() = 0;

                        if GLBalance = 0 then begin
                            TotalDebit := 0;
                            TotalCredit := 0;
                        end else begin
                            TFTotalDebitAmt := TFTotalDebitAmt + TotalDebit + TotalCredit;
                            TFTotalCreditAmt := TFTotalCreditAmt + TotalDebit + TotalCredit;
                        end;
                        TransDebit := TFTotalDebitAmt;
                        TransCredit := TFTotalCreditAmt;
                        if (TotalDebit <> 0) or (TotalCredit <> 0) then
                            LineNo := LineNo + 2;
                    end;

                    trigger OnPreDataItem()
                    begin
                        if Print then begin
                            SetRange("New Fiscal Year", true);
                            SetRange("Date Locked", true);
                            SetFilter("Starting Date", '> %1 & <= %2', LastDate, ToDate);
                        end else begin
                            SetRange("New Fiscal Year", true);
                            SetRange("Date Locked", true);
                            SetFilter("Starting Date", '> %1 & <= %2', FromDate, ToDate);
                        end;
                    end;
                }
                dataitem("<Integer2>"; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(TotalCredit_Control45; TotalCredit)
                    {
                    }
                    column(TotalDebit_Control46; TotalDebit)
                    {
                    }
                    column(Found_AND___TotalDebit____0__OR__TotalCredit____0__; Found and ((TotalDebit <> 0) or (TotalCredit <> 0)))
                    {
                    }
                    column(FORMAT_DateClose_; Format(DateClose))
                    {
                    }
                    column(Integer2__Number; Number)
                    {
                    }
                    column(Total_Closing_EntriesCaption_Control91; Total_Closing_EntriesCaption_Control91Lbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Found then begin
                            DateClose := ToDate;
                            PrintClosing := true;
                            TotalDebit := 0;
                            TotalCredit := 0;
                            GLAccount.SetRange("Date Filter");
                            GLAccount.SetRange("Date Filter", 0D, ToDate);
                            if GLFilterDim1 <> '' then
                                GLAccount.SetFilter("Global Dimension 1 Filter", GLFilterDim1);
                            if GLFilterDim2 <> '' then
                                GLAccount.SetFilter("Global Dimension 2 Filter", GLFilterDim2);
                            GLAccount.SetFilter("No.", "G/L Account"."No.");
                            if GLAccount.Find('-') then
                                repeat
                                    GLAccount.CalcFields("Additional-Currency Net Change", "Net Change");
                                    if PrintAmountsInAddCurrency then begin
                                        if GLAccount."Additional-Currency Net Change" > 0 then
                                            TotalDebit := TotalDebit + GLAccount."Additional-Currency Net Change"
                                        else
                                            TotalCredit := TotalCredit + Abs(GLAccount."Additional-Currency Net Change");
                                    end else
                                        if GLAccount."Net Change" > 0 then
                                            TotalDebit := TotalDebit + GLAccount."Net Change"
                                        else
                                            TotalCredit := TotalCredit + Abs(GLAccount."Net Change");
                                until GLAccount.Next() = 0;

                            TFTotalDebitAmt := TFTotalDebitAmt + TotalCredit;
                            TFTotalCreditAmt := TFTotalCreditAmt + TotalDebit;
                        end;
                        TotalBalance := TFTotalDebitAmt - TFTotalCreditAmt;
                        TD := TD + TFTotalDebitAmt;
                        TC := TC + TFTotalCreditAmt;
                        TB := TB + TFTotalDebitAmt - TFTotalCreditAmt;
                    end;

                    trigger OnPreDataItem()
                    begin
                        Found := false;
                        "Accounting Period".Reset();
                        "Accounting Period".SetRange("New Fiscal Year", true);
                        "Accounting Period".Find('+');
                        if ToDate <> NormalDate(ToDate) then
                            if "Accounting Period".Get(CalcDate('<1D>', NormalDate(ToDate))) then
                                if ("Accounting Period"."New Fiscal Year" = true) and ("Accounting Period"."Date Locked" = true) then
                                    Found := true
                                else
                                    Found := false;
                        if Found and ((TotalDebit <> 0) or (TotalCredit <> 0)) then
                            LineNo := LineNo + 1;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    TotalDebit := 0;
                    TotalCredit := 0;
                    GLBalance := 0;
                    TFTotalDebitAmt := 0;
                    TFTotalCreditAmt := 0;
                    TFGLBalance := 0;
                    TransDebit := 0;
                    TransCredit := 0;
                    NotFound := false;
                    Print := false;
                    FromDate := GetRangeMin("Date Filter");
                    ToDate := GetRangeMax("Date Filter");
                    if (ToDate <> NormalDate(ToDate)) and not IncludeAccountBalance then
                        Error(Text1100000);
                    NameAcc := Name;
                    NumAcc := "No.";
                    GLAcc2 := "G/L Account";
                    GLAcc2.SetRange("Date Filter", 0D, ToDate);
                    GLAcc2.CalcFields("Balance at Date");
                    SetRange("Date Filter", FromDate, ToDate);
                    CalcFields("Debit Amount", "Credit Amount", Balance, "Balance at Date", "Additional-Currency Balance", "Net Change");
                    if IncludeAccountBalance then begin
                        if "Balance at Date" = 0 then
                            HaveEntries := CalcEntries(FromDate)
                        else
                            HaveEntries := CalcEntries(0D);
                        if "Balance at Date" = 0 then begin
                            if not IncludeZeroBalance then
                                CurrReport.Skip();

                            GLAcc2.SetRange("No.", NumAcc);
                            GLAcc2.SetRange("Date Filter", FromDate, ToDate);
                            GLAcc2.CalcFields("Debit Amount", "Credit Amount");
                            if (GLAcc2."Debit Amount" = 0) and (GLAcc2."Credit Amount" = 0) then
                                CurrReport.Skip();

                        end;
                    end else begin
                        if (GLAcc2."Balance at Date" = 0) and (not IncludeZeroBalance) then
                            CurrReport.Skip();
                        if ("Debit Amount" <> 0) or ("Credit Amount" <> 0) then
                            HaveEntries := false
                        else
                            HaveEntries := true;
                    end;
                    InitPeriodDate := CalcPeriod(FromDate);
                    EndPeriodDate := CalcPeriodEnd(ToDate);
                    if ((InitPeriodDate <> FromDate) and
                        (ClosingDate(CalcDate('<-1D>', EndPeriodDate)) <> ToDate) and
                        ("Net Change" = 0)) and IncludeAccountBalance and (not IncludeZeroBalance)
                    then
                        CurrReport.Skip();

                    PreviusData := true;
                    if NewPagePerAcc and PreviusData then
                        PageNoPerAcc := PageNoPerAcc + 1;
                    NotFooterHeader := false;
                    LineNo := LineNo + 1;
                    if LineNo >= MaxLines then begin
                        NotFooterHeader := true;
                        LineNo := 0;
                        PageNo := PageNo + 1;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    GLFilterDim1 := GetFilter("Global Dimension 1 Filter");
                    GLFilterDim2 := GetFilter("Global Dimension 2 Filter");
                    GLFilter := GetFilter("Date Filter");
                    GLFilterAcc := GetFilter("No.");
                    GLFilterAccType := GetFilter("Account Type");
                    SetRange("Account Type", "Account Type"::Posting);
                    PageNoPerAcc := 0;
                    PageNo := 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                GLSetup.Get();
                if PrintAmountsInAddCurrency then
                    HeaderText := StrSubstNo(Text1100003, GLSetup."Additional Reporting Currency")
                else begin
                    GLSetup.TestField("LCY Code");
                    HeaderText := StrSubstNo(Text1100003, GLSetup."LCY Code");
                end;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PrintAmountsInAddCurrency; PrintAmountsInAddCurrency)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts In Add Currency';
                        ToolTip = 'Specifies if amounts in the additional currency are included.';
                    }
                    field(NewPagePerAcc; NewPagePerAcc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Page Per Account';
                        ToolTip = 'Specifies if each account''s information is printed on a new page if you have chosen two or more accounts to be included in the report.';
                    }
                    field(IncludeAccountBalance; IncludeAccountBalance)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Only Accs. With Entries at Date';
                        ToolTip = 'Specifies if you want to print accounts with a balance during the selected period, even if there are no entries for the selected period.';
                    }
                    field(IncludeZeroBalance; IncludeZeroBalance)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Entries zero balance';
                        ToolTip = 'Specifies if you also want entries with a zero balance to be included.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            IncludeAccountBalance := true;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        MaxLines := 47;
        IncludeAccountBalance := true;
    end;

    var
        Text1100000: Label 'You cannot deactivate the field "Only Accs. With Entries at Date" with a "C" date';
        Text1100002: Label 'Period: %1';
        Text1100003: Label 'All Amounts are in %1';
        Text1100005: Label 'There is not any period in this range of date';
        GLSetup: Record "General Ledger Setup";
        GLAccount: Record "G/L Account";
        GLEntry3: Record "G/L Entry";
        GLAcc2: Record "G/L Account";
        NumAcc: Code[20];
        GLFilterAccType: Text[30];
        GLFilterAcc: Text[30];
        HeaderText: Text[40];
        GLFilter: Text[30];
        NameAcc: Text[30];
        Num: Integer;
        i: Integer;
        FromDate: Date;
        ToDate: Date;
        PostDate: Date;
        InitPeriodDate: Date;
        DateClose: Date;
        EndPeriodDate: Date;
        DateOpen: Date;
        LastDate: Date;
        NormPostDate: Date;
        PrintAmountsInAddCurrency: Boolean;
        Print: Boolean;
        PrintClosing: Boolean;
        HaveEntries: Boolean;
        NotFound: Boolean;
        Found: Boolean;
        Open: Boolean;
        TFTotalDebitAmt: Decimal;
        TFTotalCreditAmt: Decimal;
        TFGLBalance: Decimal;
        TD: Decimal;
        TC: Decimal;
        TB: Decimal;
        TotalDebit: Decimal;
        TotalBalance: Decimal;
        TotalCredit: Decimal;
        GLBalance: Decimal;
        TransDebit: Decimal;
        TransCredit: Decimal;
        NewPagePerAcc: Boolean;
        PreviusData: Boolean;
        IncludeAccountBalance: Boolean;
        IncludeZeroBalance: Boolean;
        GLFilterDim1: Code[20];
        GLFilterDim2: Code[20];
        LineNo: Integer;
        MaxLines: Integer;
        PageNo: Integer;
        PageNoPerAcc: Integer;
        NotFooterHeader: Boolean;
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Detail_Account_Statement___Closing___Opening_EntriesCaptionLbl: Label 'Detail Account Statement - Closing & Opening Entries';
        Only_Accs__With_Entries_at_DateCaptionLbl: Label 'Only Accs. With Entries at Date';
        Balance_at_dateCaptionLbl: Label 'Balance at date';
        Net_ChangeCaptionLbl: Label 'Net Change';
        CreditCaptionLbl: Label 'Credit';
        DebitCaptionLbl: Label 'Debit';
        DescriptionCaptionLbl: Label 'Description';
        Posting_DateCaptionLbl: Label 'Posting Date';
        Total_Opening_EntriesCaptionLbl: Label 'Total Opening Entries';
        Total_Opening_EntriesCaption_Control31Lbl: Label 'Total Opening Entries';
        Total_Closing_EntriesCaptionLbl: Label 'Total Closing Entries';
        Total_Opening_EntriesCaption_Control108Lbl: Label 'Total Opening Entries';
        Total_Closing_EntriesCaption_Control109Lbl: Label 'Total Closing Entries';
        Total_Closing_EntriesCaption_Control70Lbl: Label 'Total Closing Entries';
        Total_Opening_EntriesCaption_Control68Lbl: Label 'Total Opening Entries';
        Total_Closing_EntriesCaption_Control91Lbl: Label 'Total Closing Entries';

    [Scope('OnPrem')]
    procedure CalcPeriod(InitialDate: Date): Date
    var
        AccPeriod: Record "Accounting Period";
    begin
        AccPeriod.SetRange("New Fiscal Year", true);
        AccPeriod.SetFilter("Starting Date", '<=%1', InitialDate);
        if AccPeriod.FindLast() then
            exit(AccPeriod."Starting Date");

        Error(Text1100005);
    end;

    [Scope('OnPrem')]
    procedure CalcAccountingPeriod(DateAux: Date; Lastdate: Date): Integer
    var
        AccPeriod: Record "Accounting Period";
    begin
        AccPeriod.SetRange("New Fiscal Year", true);
        AccPeriod.SetFilter("Starting Date", '>%1 & <=%2', Lastdate, DateAux);
        exit(AccPeriod.Count);
    end;

    [Scope('OnPrem')]
    procedure CalcEntries(EndDate: Date): Boolean
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetCurrentKey("Posting Date", "G/L Account No.");
        GLEntry.SetRange("Posting Date", EndDate, ToDate);
        if GLFilterDim1 <> '' then
            GLEntry.SetFilter("Global Dimension 1 Code", GLFilterDim1);
        if GLFilterDim2 <> '' then
            GLEntry.SetFilter("Global Dimension 2 Code", GLFilterDim2);
        GLEntry.SetFilter("G/L Account No.", "G/L Account"."No.");
        if GLEntry.FindFirst() then
            exit(true);

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure CalcPeriodEnd(EndPeriodDate: Date): Date
    var
        AccPeriod: Record "Accounting Period";
    begin
        AccPeriod.SetRange("New Fiscal Year", true);
        AccPeriod.SetFilter("Starting Date", '<=%1', CalcDate('<1D>', NormalDate(EndPeriodDate)));
        if AccPeriod.FindLast() then
            exit(AccPeriod."Starting Date");

        Error(Text1100005);
    end;
}

