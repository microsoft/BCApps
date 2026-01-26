// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Period;
using Microsoft.Utilities;
using System.Utilities;

report 12109 "Account Book Sheet - Print"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/GeneralLedger/Reports/AccountBookSheetPrint.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Account Book Sheet - Print';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.") order(ascending) where("Account Type" = filter(Posting));
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Date Filter", "Business Unit Filter";
            column(CompAddr_4_; CompAddr[4])
            {
            }
            column(CompAddr_5_; CompAddr[5])
            {
            }
            column(CompAddr_3_; CompAddr[3])
            {
            }
            column(Text1033___GLDateFilter; Text1033 + GLDateFilter)
            {
            }
            column(CompAddr_2_; CompAddr[2])
            {
            }
            column(CompAddr_1_; CompAddr[1])
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(GLDateFilter; GLDateFilter)
            {
            }
            column(GLFilterNo; GLFilterNo)
            {
            }
            column(ProgressiveBalance; ProgressiveBalance)
            {
            }
            column(UseAmtsInAddCurr; UseAmtsInAddCurr)
            {
            }
            column(G_L_Account__TABLECAPTION___________G_L_Account___No____________G_L_Account__Name; "G/L Account".TableCaption + ': ' + "G/L Account"."No." + ' ' + "G/L Account".Name)
            {
            }
            column(G_L_Account_No_; "No.")
            {
            }
            column(G_L_Account_Date_Filter; "Date Filter")
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Account_Sheet___General_LedgerCaption; Account_Sheet___General_LedgerCaptionLbl)
            {
            }
            column(Account_No_Caption; Account_No_CaptionLbl)
            {
            }
            column(Period_Caption; Period_CaptionLbl)
            {
            }
            column(IcreasesAmnt_Control1130071Caption; IcreasesAmnt_Control1130071CaptionLbl)
            {
            }
            column(DecreasesAmnt_Control1130070Caption; DecreasesAmnt_Control1130070CaptionLbl)
            {
            }
            column(GL_Book_Entry_DescriptionCaption; "GL Book Entry".FieldCaption(Description))
            {
            }
            column(GL_Book_Entry__External_Document_No__Caption; "GL Book Entry".FieldCaption("External Document No."))
            {
            }
            column(GL_Book_Entry__Document_Date_Caption; GL_Book_Entry__Document_Date_CaptionLbl)
            {
            }
            column(GL_Book_Entry__Document_No__Caption; "GL Book Entry".FieldCaption("Document No."))
            {
            }
            column(GL_Book_Entry__Posting_Date_Caption; GL_Book_Entry__Posting_Date_CaptionLbl)
            {
            }
            column(GL_Book_Entry__Transaction_No__Caption; "GL Book Entry".FieldCaption("Transaction No."))
            {
            }
            column(GL_Book_Entry__Entry_No__Caption; "GL Book Entry".FieldCaption("Entry No."))
            {
            }
            column(Amounts_in_Additional_CurrencyCaption; Amounts_in_Additional_CurrencyCaptionLbl)
            {
            }
            column(IcreasesAmnt_Control1130071Caption_Control1130026; IcreasesAmnt_Control1130071Caption_Control1130026Lbl)
            {
            }
            column(DecreasesAmnt_Control1130070Caption_Control1130027; DecreasesAmnt_Control1130070Caption_Control1130027Lbl)
            {
            }
            column(GL_Book_Entry_DescriptionCaption_Control1130028; "GL Book Entry".FieldCaption(Description))
            {
            }
            column(GL_Book_Entry__External_Document_No__Caption_Control1130029; "GL Book Entry".FieldCaption("External Document No."))
            {
            }
            column(GL_Book_Entry__Document_Date_Caption_Control1130030; GL_Book_Entry__Document_Date_Caption_Control1130030Lbl)
            {
            }
            column(GL_Book_Entry__Document_No__Caption_Control1130031; "GL Book Entry".FieldCaption("Document No."))
            {
            }
            column(GL_Book_Entry__Posting_Date_Caption_Control1130032; GL_Book_Entry__Posting_Date_Caption_Control1130032Lbl)
            {
            }
            column(GL_Book_Entry__Transaction_No__Caption_Control1130033; "GL Book Entry".FieldCaption("Transaction No."))
            {
            }
            column(GL_Book_Entry__Entry_No__Caption_Control1130034; "GL Book Entry".FieldCaption("Entry No."))
            {
            }
            column(GL_Book_Entry__External_Document_No__Caption_Control1130036; "GL Book Entry".FieldCaption("External Document No."))
            {
            }
            column(GL_Book_Entry__Document_Date_Caption_Control1130037; GL_Book_Entry__Document_Date_Caption_Control1130037Lbl)
            {
            }
            column(GL_Book_Entry__Document_No__Caption_Control1130038; "GL Book Entry".FieldCaption("Document No."))
            {
            }
            column(GL_Book_Entry_DescriptionCaption_Control1130039; "GL Book Entry".FieldCaption(Description))
            {
            }
            column(IcreasesAmnt_Control1130071Caption_Control1130040; IcreasesAmnt_Control1130071Caption_Control1130040Lbl)
            {
            }
            column(DecreasesAmnt_Control1130070Caption_Control1130041; DecreasesAmnt_Control1130070Caption_Control1130041Lbl)
            {
            }
            column(AmntCaption; AmntCaptionLbl)
            {
            }
            column(GL_Book_Entry__Posting_Date_Caption_Control1130043; GL_Book_Entry__Posting_Date_Caption_Control1130043Lbl)
            {
            }
            column(GL_Book_Entry__Transaction_No__Caption_Control1130044; "GL Book Entry".FieldCaption("Transaction No."))
            {
            }
            column(GL_Book_Entry__Entry_No__Caption_Control1130045; "GL Book Entry".FieldCaption("Entry No."))
            {
            }
            column(IcreasesAmnt_Control1130071Caption_Control1130047; IcreasesAmnt_Control1130071Caption_Control1130047Lbl)
            {
            }
            column(DecreasesAmnt_Control1130070Caption_Control1130048; DecreasesAmnt_Control1130070Caption_Control1130048Lbl)
            {
            }
            column(AmntCaption_Control1130049; AmntCaption_Control1130049Lbl)
            {
            }
            column(GL_Book_Entry_DescriptionCaption_Control1130050; "GL Book Entry".FieldCaption(Description))
            {
            }
            column(GL_Book_Entry__External_Document_No__Caption_Control1130051; "GL Book Entry".FieldCaption("External Document No."))
            {
            }
            column(GL_Book_Entry__Document_Date_Caption_Control1130052; GL_Book_Entry__Document_Date_Caption_Control1130052Lbl)
            {
            }
            column(GL_Book_Entry__Document_No__Caption_Control1130053; "GL Book Entry".FieldCaption("Document No."))
            {
            }
            column(Amounts_in_Additional_CurrencyCaption_Control1130054; Amounts_in_Additional_CurrencyCaption_Control1130054Lbl)
            {
            }
            column(GL_Book_Entry__Posting_Date_Caption_Control1130055; GL_Book_Entry__Posting_Date_Caption_Control1130055Lbl)
            {
            }
            column(GL_Book_Entry__Transaction_No__Caption_Control1130056; "GL Book Entry".FieldCaption("Transaction No."))
            {
            }
            column(GL_Book_Entry__Entry_No__Caption_Control1130057; "GL Book Entry".FieldCaption("Entry No."))
            {
            }
            dataitem(PageCounter; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                PrintOnlyIfDetail = true;
                column(StartOnHand; StartOnHand)
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 5;
                }
                column(PageCounter_Number; Number)
                {
                }
                column(Progressive_TotalCaption; Progressive_TotalCaptionLbl)
                {
                }
                column(Printed_Entries_TotalCaption; Printed_Entries_TotalCaptionLbl)
                {
                }
                column(Printed_Entries_TotalCaption_Control1130099; Printed_Entries_TotalCaption_Control1130099Lbl)
                {
                }
                column(Printed_Entries_Total___Progressive_TotalCaption; Printed_Entries_Total___Progressive_TotalCaptionLbl)
                {
                }
                dataitem("GL Book Entry"; "GL Book Entry")
                {
                    DataItemLink = "G/L Account No." = field("No."), "Posting Date" = field("Date Filter");
                    DataItemLinkReference = "G/L Account";
                    DataItemTableView = sorting("Posting Date", "Transaction No.", "Entry No.") order(ascending) where(Amount = filter(<> 0));
                    column(DecreasesAmnt; DecreasesAmnt)
                    {
                        AutoFormatType = 1;
                    }
                    column(IcreasesAmnt; IcreasesAmnt)
                    {
                        AutoFormatType = 1;
                    }
                    column(Text1035____G_L_Account___No______________G_L_Account__Name; Text1035 + "G/L Account"."No." + ' - ' + "G/L Account".Name)
                    {
                    }
                    column(StartOnHand___Amount; StartOnHand + Amount)
                    {
                        AutoFormatType = 1;
                        DecimalPlaces = 0 : 5;
                    }
                    column(Text1035____G_L_Account___No______________G_L_Account__Name_Control1130068; Text1035 + "G/L Account"."No." + ' - ' + "G/L Account".Name)
                    {
                    }
                    column(Amnt; Amnt)
                    {
                        AutoFormatType = 1;
                    }
                    column(DecreasesAmnt_Control1130070; DecreasesAmnt)
                    {
                        AutoFormatType = 1;
                    }
                    column(IcreasesAmnt_Control1130071; IcreasesAmnt)
                    {
                        AutoFormatType = 1;
                    }
                    column(GL_Book_Entry_Description; Description)
                    {
                    }
                    column(GL_Book_Entry__External_Document_No__; "External Document No.")
                    {
                    }
                    column(GL_Book_Entry__Document_Date_; Format("Document Date"))
                    {
                    }
                    column(GL_Book_Entry__Document_No__; "Document No.")
                    {
                    }
                    column(GL_Book_Entry__Posting_Date_; Format("Posting Date"))
                    {
                    }
                    column(GL_Book_Entry__Transaction_No__; "Transaction No.")
                    {
                    }
                    column(GL_Book_Entry__Entry_No__; "Entry No.")
                    {
                    }
                    column(DecreasesAmnt_Control1130079; DecreasesAmnt)
                    {
                        AutoFormatType = 1;
                    }
                    column(IcreasesAmnt_Control1130080; IcreasesAmnt)
                    {
                        AutoFormatType = 1;
                    }
                    column(GL_Book_Entry_Description_Control1130081; Description)
                    {
                    }
                    column(GL_Book_Entry__External_Document_No___Control1130082; "External Document No.")
                    {
                    }
                    column(GL_Book_Entry__Document_Date__Control1130083; Format("Document Date"))
                    {
                    }
                    column(GL_Book_Entry__Document_No___Control1130084; "Document No.")
                    {
                    }
                    column(GL_Book_Entry__Posting_Date__Control1130085; Format("Posting Date"))
                    {
                    }
                    column(GL_Book_Entry__Transaction_No___Control1130086; "Transaction No.")
                    {
                    }
                    column(GL_Book_Entry__Entry_No___Control1130087; "Entry No.")
                    {
                    }
                    column(DecreasesAmnt_Control1130088; DecreasesAmnt)
                    {
                        AutoFormatType = 1;
                    }
                    column(IcreasesAmnt_Control1130089; IcreasesAmnt)
                    {
                        AutoFormatType = 1;
                    }
                    column(StartOnHand___Amount_Control1130094; StartOnHand + Amount)
                    {
                        AutoFormatType = 1;
                        DecimalPlaces = 0 : 5;
                    }
                    column(DecreasesAmnt_Control1130095; DecreasesAmnt)
                    {
                        AutoFormatType = 1;
                    }
                    column(IcreasesAmnt_Control1130096; IcreasesAmnt)
                    {
                        AutoFormatType = 1;
                    }
                    column(IcreasesAmnt_Control1130102; IcreasesAmnt)
                    {
                        AutoFormatType = 1;
                    }
                    column(DecreasesAmnt_Control1130103; DecreasesAmnt)
                    {
                        AutoFormatType = 1;
                    }
                    column(GL_Book_Entry_Amount; Amount)
                    {
                        AutoFormatType = 1;
                    }
                    column(StartOnHand___Amount_Control1130105; StartOnHand + Amount)
                    {
                        AutoFormatType = 1;
                    }
                    column(TotalAmount; Amount)
                    {
                        AutoFormatType = 1;
                    }
                    column(GL_Book_Entry_G_L_Account_No_; "G/L Account No.")
                    {
                    }
                    column(GL_Book_Entry_Posting_Date; "Posting Date")
                    {
                    }
                    column(ContinuedCaption; ContinuedCaptionLbl)
                    {
                    }
                    column(ContinuedCaption_Control1130092; ContinuedCaption_Control1130092Lbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        CalcFields(Amount, "Debit Amount", "Credit Amount", "Additional-Currency Amount");

                        if not UseAmtsInAddCurr then begin
                            Amnt := Amnt + Amount;
                            CalcAmounts(IcreasesAmnt, DecreasesAmnt, Amount);
                        end else begin
                            Amnt := Amnt + "Additional-Currency Amount";
                            CalcAmounts(IcreasesAmnt, DecreasesAmnt, "Additional-Currency Amount");
                        end;
                    end;
                }
            }

            trigger OnAfterGetRecord()
            begin
                if GetFilter("No.") <> '' then
                    GLFilterNo := GetFilter("No.")
                else
                    GLFilterNo := Text1034;

                StartOnHand := 0;
                if GLDateFilter <> '' then
                    if GetRangeMin("Date Filter") > 00000101D then begin
                        if "Income/Balance" = "Income/Balance"::"Balance Sheet" then
                            SetRange("Date Filter", 0D, ClosingDate(GetRangeMin("Date Filter") - 1))
                        else
                            if FiscalYearStartDate <> GetRangeMin("Date Filter") then
                                SetRange("Date Filter", FiscalYearStartDate, GetRangeMin("Date Filter") - 1);
                        CalcFields("Net Change", "Additional-Currency Net Change");
                        if not UseAmtsInAddCurr then
                            StartOnHand := "Net Change"
                        else
                            StartOnHand := "Additional-Currency Net Change";
                        SetFilter("Date Filter", GLDateFilter);
                        if (FiscalYearStartDate = GetRangeMin("Date Filter")) and
                           ("Income/Balance" = "Income/Balance"::"Income Statement")
                        then
                            StartOnHand := 0;
                    end;
                Amnt := StartOnHand;

                GLBookEntry.Reset();
                GLBookEntry.CalcFields(Amount);
                GLBookEntry.SetRange("G/L Account No.", "No.");
                GLBookEntry.SetFilter("Posting Date", Format("Date Filter"));
                GLBookEntry.SetFilter(Amount, '<>0');
                if (StartOnHand = 0) and GLBookEntry.IsEmpty() then
                    CurrReport.Skip();
                NextRec := true;
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();
                CompAddr[1] := CompanyInfo.Name;
                CompAddr[2] := CompanyInfo.Address;
                CompAddr[3] := CompanyInfo."Post Code";
                CompAddr[4] := CompanyInfo.City;
                CompAddr[5] := CompanyInfo."Fiscal Code";
                CompressArray(CompAddr);

                AccPeriod.Reset();
                AccPeriod.SetRange("New Fiscal Year", true);
                AccPeriod.SetFilter("Starting Date", '<=%1', GetRangeMin("Date Filter"));
                AccPeriod.FindLast();

                FiscalYearStartDate := AccPeriod."Starting Date";
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
                    field(ProgressiveBalance; ProgressiveBalance)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Progressive Balance';
                        ToolTip = 'Specifies the progressive balance.';
                    }
                    field(ShowAmountsInAddReportingCurrency; UseAmtsInAddCurr)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in Add. Reporting Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want to see the related show amounts in your company''s additional reporting currency.';
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
    var
        ITReportManagement: Codeunit "IT - Report Management";
    begin
        GLDateFilter := "G/L Account".GetFilter("Date Filter");

        if GLDateFilter <> '' then begin
            ITReportManagement.CheckSalesDocNoGaps("G/L Account".GetRangeMax("Date Filter"), false);
            ITReportManagement.CheckPurchDocNoGaps("G/L Account".GetRangeMax("Date Filter"), false);
        end else begin
            ITReportManagement.CheckSalesDocNoGaps(0D, false);
            ITReportManagement.CheckPurchDocNoGaps(0D, false);
        end;
    end;

    var
        Text1033: Label 'Period: ';
        Text1034: Label 'ALL';
        Text1035: Label 'Continued: ';
        AccPeriod: Record "Accounting Period";
        CompanyInfo: Record "Company Information";
        GLBookEntry: Record "GL Book Entry";
        CompAddr: array[5] of Text[100];
        GLDateFilter: Text;
        Amnt: Decimal;
        StartOnHand: Decimal;
        IcreasesAmnt: Decimal;
        DecreasesAmnt: Decimal;
        UseAmtsInAddCurr: Boolean;
        ProgressiveBalance: Boolean;
        GLFilterNo: Text[30];
        FiscalYearStartDate: Date;
        NextRec: Boolean;
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Account_Sheet___General_LedgerCaptionLbl: Label 'Account Sheet - General Ledger';
        Account_No_CaptionLbl: Label 'Account No.';
        Period_CaptionLbl: Label 'Period:';
        IcreasesAmnt_Control1130071CaptionLbl: Label 'Debit Amount';
        DecreasesAmnt_Control1130070CaptionLbl: Label 'Credit Amount';
        GL_Book_Entry__Document_Date_CaptionLbl: Label 'Document Date';
        GL_Book_Entry__Posting_Date_CaptionLbl: Label 'Posting Date';
        Amounts_in_Additional_CurrencyCaptionLbl: Label 'Amounts in Additional-Currency';
        IcreasesAmnt_Control1130071Caption_Control1130026Lbl: Label 'Debit Amount';
        DecreasesAmnt_Control1130070Caption_Control1130027Lbl: Label 'Credit Amount';
        GL_Book_Entry__Document_Date_Caption_Control1130030Lbl: Label 'Document Date';
        GL_Book_Entry__Posting_Date_Caption_Control1130032Lbl: Label 'Posting Date';
        GL_Book_Entry__Document_Date_Caption_Control1130037Lbl: Label 'Document Date';
        IcreasesAmnt_Control1130071Caption_Control1130040Lbl: Label 'Debit Amount';
        DecreasesAmnt_Control1130070Caption_Control1130041Lbl: Label 'Credit Amount';
        AmntCaptionLbl: Label 'Balance';
        GL_Book_Entry__Posting_Date_Caption_Control1130043Lbl: Label 'Posting Date';
        IcreasesAmnt_Control1130071Caption_Control1130047Lbl: Label 'Debit Amount';
        DecreasesAmnt_Control1130070Caption_Control1130048Lbl: Label 'Credit Amount';
        AmntCaption_Control1130049Lbl: Label 'Balance';
        GL_Book_Entry__Document_Date_Caption_Control1130052Lbl: Label 'Document Date';
        Amounts_in_Additional_CurrencyCaption_Control1130054Lbl: Label 'Amounts in Additional-Currency';
        GL_Book_Entry__Posting_Date_Caption_Control1130055Lbl: Label 'Posting Date';
        Progressive_TotalCaptionLbl: Label 'Progressive Total';
        ContinuedCaptionLbl: Label 'Continued';
        ContinuedCaption_Control1130092Lbl: Label 'Continued';
        Printed_Entries_TotalCaptionLbl: Label 'Printed Entries Total';
        Printed_Entries_TotalCaption_Control1130099Lbl: Label 'Printed Entries Total';
        Printed_Entries_Total___Progressive_TotalCaptionLbl: Label 'Printed Entries Total + Progressive Total';

    local procedure CalcAmounts(var IcreasesAmnt: Decimal; var DecreasesAmnt: Decimal; Amount: Decimal)
    begin
        IcreasesAmnt := 0;
        DecreasesAmnt := 0;

        if Amount > 0 then
            IcreasesAmnt := Amount
        else
            DecreasesAmnt := Abs(Amount);
    end;
}

