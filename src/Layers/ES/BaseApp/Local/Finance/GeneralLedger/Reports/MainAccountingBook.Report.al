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

report 10723 "Main Accounting Book"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/GeneralLedger/Reports/MainAccountingBook.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Main Accounting Book';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "Date Filter", "No.", "Global Dimension 1 Filter", "Global Dimension 2 Filter", "Account Type";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(STRSUBSTNO_Text1100002_GLFilter_; StrSubstNo(Text1100002, GLFilter))
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(USERID; UserId)
            {
            }
            column(G_L_Account__TABLECAPTION__________GLFilterAcc; TableCaption + ': ' + GLFilterAcc)
            {
            }
            column(HeaderText; HeaderText)
            {
            }
            column(EmptyString; '')
            {
            }
            column(NumAcc; NumAcc)
            {
            }
            column(TransDebit___TransCredit; TransDebit - TransCredit)
            {
            }
            column(TransDebit; TransDebit)
            {
            }
            column(TransCredit; TransCredit)
            {
            }
            column(NameAcc; NameAcc)
            {
            }
            column(NumAcc_Control24; NumAcc)
            {
            }
            column(TransDebit___TransCredit_Control94; TransDebit - TransCredit)
            {
            }
            column(NumAcc_Control8; NumAcc)
            {
            }
            column(TransDebit_Control54; TransDebit)
            {
            }
            column(TransCredit_Control93; TransCredit)
            {
            }
            column(TD; TD)
            {
            }
            column(TB; TB)
            {
            }
            column(TC; TC)
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
            column(Main_Accounting_BookCaption; Main_Accounting_BookCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Posting_DateCaption; Posting_DateCaptionLbl)
            {
            }
            column(DescriptionCaption; DescriptionCaptionLbl)
            {
            }
            column(DebitCaption; DebitCaptionLbl)
            {
            }
            column(CreditCaption; CreditCaptionLbl)
            {
            }
            column(Acum__Balance_at_dateCaption; Acum__Balance_at_dateCaptionLbl)
            {
            }
            column(Net_ChangeCaption; Net_ChangeCaptionLbl)
            {
            }
            column(Continued____________________________Caption; Continued____________________________CaptionLbl)
            {
            }
            column(Num_Account_Caption; Num_Account_CaptionLbl)
            {
            }
            column(Continued____________________________Caption_Control51; Continued____________________________Caption_Control51Lbl)
            {
            }
            column(Num_Account_Caption_Control6; Num_Account_Caption_Control6Lbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
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
                column(FromDate; Format(FromDate))
                {
                }
                column(TotalCredit; TotalCredit)
                {
                }
                column(Open; Open)
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
                    if GLFilterAccType = Text1100000Lbl then begin
                        GLAccount.SetFilter("No.", "G/L Account".Totaling);
                        GLAccount.SetRange("Account Type", 0);
                    end else
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
                column(TotalDebit_Control27; TotalDebit)
                {
                }
                column(TotalCredit_Control28; TotalCredit)
                {
                }
                column(NotFound; NotFound)
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
                end;

                trigger OnPreDataItem()
                begin
                    PostDate := FromDate;
                    GLEntry3.SetCurrentKey("G/L Account No.", "Posting Date");
                    if GLFilterDim1 <> '' then
                        GLEntry3.SetFilter("Global Dimension 1 Code", GLFilterDim1);
                    if GLFilterDim2 <> '' then
                        GLEntry3.SetFilter("Global Dimension 2 Code", GLFilterDim2);
                    GLEntry3.SetRange("Posting Date", FromDate, ToDate);
                    if GLFilterAccType = Text1100000Lbl then
                        GLEntry3.SetFilter("G/L Account No.", "G/L Account".Totaling)
                    else
                        GLEntry3.SetFilter("G/L Account No.", "G/L Account"."No.");
                    if GLEntry3.Find('-') then begin
                        GLEntry3.Next(-1);
                        PostDate := GLEntry3."Posting Date";
                    end else
                        NotFound := true;

                    SetRange("New Fiscal Year", true);
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
                column(G_L_Entry__Posting_Date_; Format("Posting Date"))
                {
                }
                column(G_L_Entry_Description; Description)
                {
                }
                column(G_L_Entry__Add__Currency_Debit_Amount_; "Add.-Currency Debit Amount")
                {
                }
                column(G_L_Entry__Add__Currency_Credit_Amount_; "Add.-Currency Credit Amount")
                {
                }
                column(GLBalance_Control76; GLBalance)
                {
                }
                column(PrintAmountsInAddCurrency; PrintAmountsInAddCurrency)
                {
                }
                column(GLFilterAccType; GLFilterAccType)
                {
                }
                column(Text1100000; Text1100000Lbl)
                {
                }
                column(G_L_Entry__Posting_Date__Control3; Format("Posting Date"))
                {
                }
                column(G_L_Entry_Description_Control1100111; Description)
                {
                }
                column(GLBalance_Control14; GLBalance)
                {
                }
                column(G_L_Entry__Debit_Amount_; "Debit Amount")
                {
                }
                column(G_L_Entry__Credit_Amount_; "Credit Amount")
                {
                }
                column(GLBalance_Control48; GLBalance)
                {
                }
                column(TotalCreditHead; TotalCreditHead)
                {
                }
                column(TotalDebitHead; TotalDebitHead)
                {
                }
                column(Num; Num)
                {
                }
                column(TempTotalCreditHead; TempTotalCreditHead)
                {
                }
                column(TempTotalDebitHead; TempTotalDebitHead)
                {
                }
                column(TotalDebitHead_Control26; TotalDebitHead)
                {
                }
                column(TotalCreditHead_Control47; TotalCreditHead)
                {
                }
                column(GLBalance_Control49; GLBalance)
                {
                }
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
                column(Total_Period_EntriesCaption; Total_Period_EntriesCaptionLbl)
                {
                }
                column(Total_Period_EntriesCaption_Control50; Total_Period_EntriesCaption_Control50Lbl)
                {
                }
                dataitem("<Accounting Period3>"; "Accounting Period")
                {
                    DataItemTableView = sorting("Starting Date");
                    column(AccPeriodNum; AccPeriodNum)
                    {
                    }
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
                    column(TotalCredit_Control29; TotalCredit)
                    {
                    }
                    column(TotalDebit_Control30; TotalDebit)
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
                        AccPeriodNum += 1;
                        TempTotalCreditHead := TotalCreditHead;
                        TempTotalDebitHead := TotalDebitHead;
                        TotalDebitHead := 0;
                        TotalCreditHead := 0;
                        TotalDebit := 0;
                        TotalCredit := 0;
                        GLAccount.SetRange("Date Filter");
                        if GLFilterDim1 <> '' then
                            GLAccount.SetFilter("Global Dimension 1 Filter", GLFilterDim1);
                        if GLFilterDim2 <> '' then
                            GLAccount.SetFilter("Global Dimension 2 Filter", GLFilterDim2);
                        GLAccount.SetRange("Date Filter", 0D, ClosingDate(CalcDate('<-1D>', "Starting Date")));
                        if GLFilterAccType = Text1100000Lbl then begin
                            GLAccount.SetFilter("No.", "G/L Account".Totaling);
                            GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
                        end else
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
                    end;

                    trigger OnPreDataItem()
                    begin
                        if Num > 0 then begin
                            SetFilter("Starting Date", '>%1 & <= %2', LastDate, NormPostDate);
                            SetRange("New Fiscal Year", true);
                            AccPeriodNum := 0;
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
                    TotalDebitHead := TotalDebitHead + TotalDebit;
                    TotalCreditHead := TotalCreditHead + TotalCredit;

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

                trigger OnPreDataItem()
                begin
                    SetCurrentKey("Posting Date", "G/L Account No.");
                    if GLFilterDim1 <> '' then
                        SetFilter("Global Dimension 1 Code", GLFilterDim1);
                    if GLFilterDim2 <> '' then
                        SetFilter("Global Dimension 2 Code", GLFilterDim2);
                    SetRange("Posting Date", FromDate, ToDate);
                    if GLFilterAccType = Text1100000Lbl then
                        SetFilter("G/L Account No.", "G/L Account".Totaling)
                    else
                        SetFilter("G/L Account No.", "G/L Account"."No.");
                    LastDate := 0D;
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
                column(CLOSINGDATE_DateClose_; Format(ClosingDate(DateClose)))
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
                column(TotalCredit_Control43; TotalCredit)
                {
                }
                column(TotalDebit_Control44; TotalDebit)
                {
                }
                column(Accounting_Period_Starting_Date; "Starting Date")
                {
                }
                column(Total_Opening_EntriesCaption_Control68; Total_Opening_EntriesCaption_Control68Lbl)
                {
                }
                column(Total_Closing_EntriesCaption_Control70; Total_Closing_EntriesCaption_Control70Lbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    DateOpen := "Starting Date";
                    DateClose := ClosingDate(CalcDate('<-1D>', "Starting Date"));
                    TotalDebitHead := 0;
                    TotalCreditHead := 0;
                    TotalDebit := 0;
                    TotalCredit := 0;
                    GLAccount.SetRange("Date Filter");
                    if GLFilterDim1 <> '' then
                        GLAccount.SetFilter("Global Dimension 1 Filter", GLFilterDim1);
                    if GLFilterDim2 <> '' then
                        GLAccount.SetFilter("Global Dimension 2 Filter", GLFilterDim2);
                    GLAccount.SetRange("Date Filter", 0D, DateClose);
                    if GLFilterAccType = Text1100000Lbl then begin
                        GLAccount.SetFilter("No.", "G/L Account".Totaling);
                        GLAccount.SetRange("Account Type", 0);
                    end else
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
                end;

                trigger OnPreDataItem()
                begin
                    if Print then begin
                        "Accounting Period".SetRange("New Fiscal Year", true);
                        "Accounting Period".SetFilter("Starting Date", '> %1 & <= %2', LastDate, ToDate);
                    end else begin
                        "Accounting Period".SetRange("New Fiscal Year", true);
                        "Accounting Period".SetFilter("Starting Date", '> %1 & <= %2', FromDate, ToDate);
                    end;
                end;
            }
            dataitem("<Integer2>"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(CLOSINGDATE_DateClose__Control90; Format(ClosingDate(DateClose)))
                {
                }
                column(TotalCredit_Control45; TotalCredit)
                {
                }
                column(TotalDebit_Control46; TotalDebit)
                {
                }
                column(Found; Found)
                {
                }
                column(TFTotalDebitAmt; TFTotalDebitAmt)
                {
                }
                column(TFTotalCreditAmt; TFTotalCreditAmt)
                {
                }
                column(NumAcc_Control1100105; NumAcc)
                {
                }
                column(Integer2__Number; Number)
                {
                }
                column(Total_Closing_EntriesCaption_Control91; Total_Closing_EntriesCaption_Control91Lbl)
                {
                }
                column(Num_Account_Caption_Control62; Num_Account_Caption_Control62Lbl)
                {
                }
                column(TotalCaption_Control64; TotalCaption_Control64Lbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    // CHANGE
                    DateClose := ToDate;
                    if Found then begin
                        PrintClosing := true;
                        TotalDebit := 0;
                        TotalCredit := 0;
                        GLAccount.SetRange("Date Filter");
                        if GLFilterDim1 <> '' then
                            GLAccount.SetFilter("Global Dimension 1 Filter", GLFilterDim1);
                        if GLFilterDim2 <> '' then
                            GLAccount.SetFilter("Global Dimension 2 Filter", GLFilterDim2);
                        GLAccount.SetRange("Date Filter", 0D, ToDate);
                        if GLFilterAccType = Text1100000Lbl then begin
                            GLAccount.SetFilter("No.", "G/L Account".Totaling);
                            GLAccount.SetRange("Account Type", 0);
                        end else
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
                            if "Accounting Period"."New Fiscal Year" then
                                Found := true
                            else
                                Found := false;
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
                TotalDebitHead := 0;
                TotalCreditHead := 0;
                NotFound := false;
                Print := false;
                if GLFilterAccType = Text1100000Lbl then
                    if StrLen("No.") <> 3 then
                        CurrReport.Skip();

                FromDate := GetRangeMin("Date Filter");
                ToDate := GetRangeMax("Date Filter");
                NameAcc := Name;
                NumAcc := "No.";

                SetRange("Date Filter", FromDate, ToDate);
                CalcFields("Debit Amount", "Credit Amount", Balance, "Balance at Date", "Additional-Currency Balance", "Net Change");
                if "Balance at Date" = 0 then
                    HaveEntries := CalcEntries(FromDate)
                else
                    HaveEntries := CalcEntries(0D);
                if (not HaveEntries) and (not ZeroBalance) then
                    CurrReport.Skip();

                InitPeriodDate := CalcPeriod(FromDate);
                EndPeriodDate := CalcPeriodEnd(ToDate);
                if ((InitPeriodDate <> FromDate) and
                    (ClosingDate(CalcDate('<-1D>', EndPeriodDate)) <> ToDate) and
                    ("Net Change" = 0) and (not ZeroBalance))
                then
                    CurrReport.Skip();

                GLSetup.Get();
                if PrintAmountsInAddCurrency then
                    HeaderText := StrSubstNo(Text1100003, GLSetup."Additional Reporting Currency")
                else begin
                    GLSetup.TestField("LCY Code");
                    HeaderText := StrSubstNo(Text1100003, GLSetup."LCY Code");
                end;
            end;

            trigger OnPreDataItem()
            begin
                GLFilterDim1 := GetFilter("Global Dimension 1 Filter");
                GLFilterDim2 := GetFilter("Global Dimension 2 Filter");
                GLFilter := GetFilter("Date Filter");
                GLFilterAcc := GetFilter("No.");
                GLFilterAccType := GetFilter("Account Type");
                if GLFilterAccType = Text1100000Lbl then
                    SetRange("Account Type", "Account Type"::Heading)
                else
                    SetRange("Account Type", "Account Type"::Posting);
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
                    field(ShowAmountsInAddCurrency; PrintAmountsInAddCurrency)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts In Add Currency';
                        ToolTip = 'Specifies if amounts in the additional currency are included.';
                    }
                    field(ZeroBalance; ZeroBalance)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Acc. with Zero Balance';
                        ToolTip = 'Specifies if you also want accounts with a zero balance to be included.';
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
        Text1100002: Label 'Period: %1';
        Text1100003: Label 'All Amounts are in %1';
        Text1100005: Label 'There is no period within this date range.';
        GLSetup: Record "General Ledger Setup";
        GLAccount: Record "G/L Account";
        GLEntry3: Record "G/L Entry";
        NumAcc: Code[20];
        GLFilterAccType: Text[30];
        GLFilterAcc: Text;
        HeaderText: Text[40];
        GLFilter: Text[30];
        NameAcc: Text[100];
        Num: Integer;
        AccPeriodNum: Integer;
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
        TotalDebitHead: Decimal;
        TotalCreditHead: Decimal;
        TransDebit: Decimal;
        TransCredit: Decimal;
        ZeroBalance: Boolean;
        GLFilterDim1: Code[20];
        GLFilterDim2: Code[20];
        TempTotalCreditHead: Decimal;
        TempTotalDebitHead: Decimal;
        Main_Accounting_BookCaptionLbl: Label 'Main Accounting Book';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Posting_DateCaptionLbl: Label 'Posting Date';
        DescriptionCaptionLbl: Label 'Description';
        DebitCaptionLbl: Label 'Debit';
        CreditCaptionLbl: Label 'Credit';
        Acum__Balance_at_dateCaptionLbl: Label 'Accum. Bal. at Date';
        Net_ChangeCaptionLbl: Label 'Net Change';
        Continued____________________________CaptionLbl: Label 'Continued............................';
        Num_Account_CaptionLbl: Label 'Num.Account:';
        Continued____________________________Caption_Control51Lbl: Label 'Continued............................';
        Num_Account_Caption_Control6Lbl: Label 'Num.Account:';
        TotalCaptionLbl: Label 'Total';
        Total_Opening_EntriesCaptionLbl: Label 'Total Opening Entries';
        Total_Opening_EntriesCaption_Control31Lbl: Label 'Total Opening Entries';
        Total_Closing_EntriesCaptionLbl: Label 'Total Closing Entries';
        Text1100000Lbl: Label 'Heading';
        Total_Period_EntriesCaptionLbl: Label 'Total Period Entries';
        Total_Period_EntriesCaption_Control50Lbl: Label 'Total Period Entries';
        Total_Opening_EntriesCaption_Control108Lbl: Label 'Total Opening Entries';
        Total_Closing_EntriesCaption_Control109Lbl: Label 'Total Closing Entries';
        Total_Opening_EntriesCaption_Control68Lbl: Label 'Total Opening Entries';
        Total_Closing_EntriesCaption_Control70Lbl: Label 'Total Closing Entries';
        Total_Closing_EntriesCaption_Control91Lbl: Label 'Total Closing Entries';
        Num_Account_Caption_Control62Lbl: Label 'Num.Account:';
        TotalCaption_Control64Lbl: Label 'Total';

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
        if GLFilterDim1 <> '' then
            GLEntry.SetFilter("Global Dimension 1 Code", GLFilterDim1);
        if GLFilterDim2 <> '' then
            GLEntry.SetFilter("Global Dimension 2 Code", GLFilterDim2);
        GLEntry.SetRange("Posting Date", EndDate, ToDate);
        if GLFilterAccType = Text1100000Lbl then
            GLEntry.SetFilter("G/L Account No.", "G/L Account".Totaling)
        else
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

