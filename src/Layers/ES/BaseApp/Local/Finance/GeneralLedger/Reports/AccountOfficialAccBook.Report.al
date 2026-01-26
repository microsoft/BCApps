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

report 10706 "Account - Official Acc. Book"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/GeneralLedger/Reports/AccountOfficialAccBook.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Account - Official Acc. Book';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(USERID; UserId)
            {
            }
            column(Text1100003___GLDateFilter; Text1100003 + GLDateFilter)
            {
            }
            column(FirstPageNum; FirstPageNum)
            {
            }
            column(G_L_Register__TABLECAPTION___________GLFilter; "G/L Entry".TableCaption + ': ' + GLFilter)
            {
            }
            column(GLFilter; GLFilter)
            {
            }
            column(HeaderText; HeaderText)
            {
            }
            column(LineID; LineID)
            {
            }
            column(IntNumber; Number)
            {
            }
            column(TFTotalDebitAmt; TFTotalDebitAmt)
            {
            }
            column(TFTotalCreditAmt; TFTotalCreditAmt)
            {
            }
            column(TFTotalDebitAmt_Control61; TFTotalDebitAmt)
            {
            }
            column(TFTotalCreditAmt_Control72; TFTotalCreditAmt)
            {
            }
            column(TotalDebitAmt; TotalDebitAmt)
            {
            }
            column(TotalCreditAmt; TotalCreditAmt)
            {
            }
            column(Official_Accounting_BookCaption; Official_Accounting_BookCaptionLbl)
            {
            }
            column(CurrReport_PAGENO___FirstPageCaption; CurrReport_PAGENO___FirstPageCaptionLbl)
            {
            }
            column(G_L_Entry__Document_Type_Caption; "G/L Entry".FieldCaption("Document Type"))
            {
            }
            column(G_L_Entry__G_L_Account_No__Caption; "G/L Entry".FieldCaption("G/L Account No."))
            {
            }
            column(GLAccount_NameCaption; GLAccount_NameCaptionLbl)
            {
            }
            column(G_L_Entry__Debit_Amount_Caption; "G/L Entry".FieldCaption("Debit Amount"))
            {
            }
            column(G_L_Entry__Credit_Amount_Caption; "G/L Entry".FieldCaption("Credit Amount"))
            {
            }
            column(G_L_Entry__Document_No__Caption; "G/L Entry".FieldCaption("Document No."))
            {
            }
            column(G_L_Entry_Description_Control48Caption; "G/L Entry".FieldCaption(Description))
            {
            }
            column(ContinuedCaption; ContinuedCaptionLbl)
            {
            }
            column(ContinuedCaption_Control60; ContinuedCaption_Control60Lbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            dataitem("G/L Account"; "G/L Account")
            {
                DataItemTableView = sorting("No.") where("Account Type" = const(Posting));
                column(V1; 1)
                {
                }
                column(NORMALDATE_OpenCloseDate_; Format(NormalDate(OpenCloseDate)))
                {
                }
                column(ShowGLHeader1; (NormalDate(OpenCloseDate) <> FirstPeriodDate) and (AccPeriod."Starting Date" = FromDate) and (OpenCloseDate <= ToDate))
                {
                }
                column(OpenClosePerTransNo; OpenClosePerTransNo)
                {
                }
                column(NORMALDATE_OpenCloseDate__Control29; Format(NormalDate(OpenCloseDate)))
                {
                }
                column(ShowGLHeader2; (NormalDate(OpenCloseDate) < NormalDate(ToDate)) and (TotalDebitAmt <> 0) and (TotalCreditAmt <> 0))
                {
                }
                column(CreditAmt; CreditAmt)
                {
                }
                column(DebitAmt; DebitAmt)
                {
                }
                column(G_L_Account_Name; Name)
                {
                }
                column(G_L_Account__No__; "No.")
                {
                }
                column(OpenTransactDesc; OpenTransactDesc)
                {
                }
                column(ShowGLBody1; ((DebitAmt <> 0) or (CreditAmt <> 0)) and not (TempDate <> AccPeriod."Starting Date") and not (TempDate > ToDate) and not (FirstReg) and not (FromPerTransNo > 1))
                {
                }
                column(V1Caption; V1CaptionLbl)
                {
                }
                column(NORMALDATE_OpenCloseDate_Caption; NORMALDATE_OpenCloseDate_CaptionLbl)
                {
                }
                column(OpenClosePerTransNoCaption; OpenClosePerTransNoCaptionLbl)
                {
                }
                column(NORMALDATE_OpenCloseDate__Control29Caption; NORMALDATE_OpenCloseDate__Control29CaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    SetRange("Date Filter", 0D, ClosingDate(AccPeriod."Starting Date" - 1));
                    CalcFields("Balance at Date", "Add.-Currency Balance at Date");
                    if not PrintAmountsInAddCurrency then
                        if "Balance at Date" > 0 then begin
                            DebitAmt := "Balance at Date";
                            CreditAmt := 0;
                            TotalDebitAmt := TotalDebitAmt + DebitAmt;
                        end else begin
                            CreditAmt := -"Balance at Date";
                            DebitAmt := 0;
                            TotalCreditAmt := TotalCreditAmt + CreditAmt;
                        end
                    else
                        if "Add.-Currency Balance at Date" > 0 then begin
                            DebitAmt := "Add.-Currency Balance at Date";
                            CreditAmt := 0;
                            TotalDebitAmt := TotalDebitAmt + DebitAmt;
                        end else begin
                            CreditAmt := -"Add.-Currency Balance at Date";
                            DebitAmt := 0;
                            TotalCreditAmt := TotalCreditAmt + CreditAmt;
                        end;

                    FirstPeriodDate := 19990101D;

                    TFTotalCreditAmt := TotalCreditAmt;
                    TFTotalDebitAmt := TotalDebitAmt;

                    LineID := 1;
                end;

                trigger OnPostDataItem()
                begin
                    NextAccPeriod.CopyFilters(AccPeriod);
                    NextAccPeriod := AccPeriod;
                    if NextAccPeriod.Next() = 0 then
                        LoopEnd := true;
                end;

                trigger OnPreDataItem()
                begin
                    OpenCloseDate := AccPeriod."Starting Date";
                    OpenClosePerTransNo := 1;
                    CurrTransNo := 1;
                end;
            }
            dataitem("G/L Entry Group"; "G/L Entry")
            {
                DataItemTableView = sorting("Posting Date", "Period Trans. No.");
                PrintOnlyIfDetail = true;
                RequestFilterFields = "Posting Date", "Period Trans. No.";
                column(TFTotalDebitAmt_Control47; TFTotalDebitAmt)
                {
                }
                column(TFTotalCreditAmt_Control55; TFTotalCreditAmt)
                {
                }
                column(TFTotalDebitAmt1; TFTotalDebitAmt1)
                {
                }
                column(TFTotalCreditAmt1; TFTotalCreditAmt1)
                {
                }
                column(G_L_Register__Period_Trans__No__; "Period Trans. No.")
                {
                }
                column(G_L_Register__Posting_Date_; "Posting Date")
                {
                }
                column(G_L_Register__Period_Trans__No___Control37; "Period Trans. No.")
                {
                }
                column(G_L_Register__Posting_Date__Control39; Format("Posting Date"))
                {
                }
                column(ContinuedCaption_Control43; ContinuedCaption_Control43Lbl)
                {
                }
                column(G_L_Register__Period_Trans__No__Caption; FieldCaption("Period Trans. No."))
                {
                }
                column(G_L_Register__Posting_Date_Caption; G_L_Register__Posting_Date_CaptionLbl)
                {
                }
                column(ContinuedCaption_Control42; ContinuedCaption_Control42Lbl)
                {
                }
                column(G_L_Register__Period_Trans__No___Control37Caption; FieldCaption("Period Trans. No."))
                {
                }
                column(G_L_Register__Posting_Date__Control39Caption; G_L_Register__Posting_Date__Control39CaptionLbl)
                {
                }
                dataitem("G/L Entry"; "G/L Entry")
                {
                    DataItemTableView = sorting("Entry No.");
                    column(G_L_Entry__G_L_Account_No__; "G/L Account No.")
                    {
                    }
                    column(GLAccount_Name; GLAccount.Name)
                    {
                    }
                    column(G_L_Entry__Document_Type_; "Document Type")
                    {
                    }
                    column(G_L_Entry__Debit_Amount_; "Debit Amount")
                    {
                    }
                    column(G_L_Entry__Credit_Amount_; "Credit Amount")
                    {
                    }
                    column(G_L_Entry__Document_No__; "Document No.")
                    {
                    }
                    column(G_L_Entry_Description; Description)
                    {
                    }
                    column(ShowGLEntryBody1; not PrintAmountsInAddCurrency)
                    {
                    }
                    column(G_L_Entry__Add__Currency_Credit_Amount_; "Add.-Currency Credit Amount")
                    {
                    }
                    column(G_L_Entry__Add__Currency_Debit_Amount_; "Add.-Currency Debit Amount")
                    {
                    }
                    column(GLAccount_Name_Control34; GLAccount.Name)
                    {
                    }
                    column(G_L_Entry__G_L_Account_No___Control40; "G/L Account No.")
                    {
                    }
                    column(G_L_Entry__Document_Type__Control41; "Document Type")
                    {
                    }
                    column(G_L_Entry__Document_No___Control74; "Document No.")
                    {
                    }
                    column(G_L_Entry_Description_Control48; Description)
                    {
                    }
                    column(ShowGLEntryBody2; PrintAmountsInAddCurrency)
                    {
                    }
                    column(G_L_Entry_Entry_No_; "Entry No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if not GLAccount.Get("G/L Account No.") then
                            GLAccount.Init();

                        if not PrintAmountsInAddCurrency then begin
                            TotalDebitAmt := TotalDebitAmt + "Debit Amount";
                            TotalCreditAmt := TotalCreditAmt + "Credit Amount";
                        end else begin
                            TotalDebitAmt := TotalDebitAmt + "Add.-Currency Debit Amount";
                            TotalCreditAmt := TotalCreditAmt + "Add.-Currency Credit Amount";
                        end;

                        TFTotalCreditAmt := TotalCreditAmt + CreditAmt;
                        TFTotalDebitAmt := TotalDebitAmt + DebitAmt;

                        LineID := 2;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetCurrentKey("Posting Date", "Transaction No.");
                        SetRange("Posting Date", "G/L Entry Group"."Posting Date");
                        SetRange("Transaction No.", "G/L Entry Group"."Transaction No.");
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if (GroupPostingDate = "Posting Date") and (GroupPeriodTransNo = "Period Trans. No.") then
                        CurrReport.Skip();

                    GroupPostingDate := "Posting Date";
                    GroupPeriodTransNo := "Period Trans. No.";

                    TestField("Period Trans. No.");
                    FirstRec := false;
                    TempDate := "Posting Date";
                    if TempDate > ClosingDate(NextAccPeriod."Starting Date" - 1) then begin
                        OldDate := "Posting Date";
                        CurrReport.Break();
                    end;

                    CurrTransNo := "Period Trans. No.";
                    if FromPerTransNo <> 0 then
                        if (CurrTransNo < FromPerTransNo) or
                           (CurrTransNo > ToPerTransNo)
                        then
                            CurrReport.Break();

                    TFTotalCreditAmt := TotalCreditAmt + CreditAmt;
                    TFTotalDebitAmt := TotalDebitAmt + DebitAmt;
                    TFTotalCreditAmt1 := TFTotalCreditAmt;
                    TFTotalDebitAmt1 := TFTotalDebitAmt;
                    LineID := 4;
                end;

                trigger OnPreDataItem()
                begin
                    if TableEnd or LoopEnd then
                        CurrReport.Break();

                    if not FirstRec then
                        SetFilter("Posting Date", '>= %1 & <= %2', OldDate, ToDate);
                    if GetFilter("Period Trans. No.") <> '' then
                        SetRange("Period Trans. No.", FromPerTransNo, ToPerTransNo);

                    GroupPostingDate := 0D;
                    GroupPeriodTransNo := 0;
                end;
            }
            dataitem(GLAccount2; "G/L Account")
            {
                DataItemTableView = sorting("No.") where("Account Type" = const(Posting));
                column(FORMAT_CLOSINGDATE_OpenCloseDate__; Format(ClosingDate(OpenCloseDate)))
                {
                }
                column(OpenClosePerTransNo_Control58; OpenClosePerTransNo)
                {
                }
                column(CloseTransactDesc; CloseTransactDesc)
                {
                }
                column(GLAccount2__No__; "No.")
                {
                }
                column(DebitAmt_Control24; DebitAmt)
                {
                }
                column(CreditAmt_Control25; CreditAmt)
                {
                }
                column(GLAccount2_Name; Name)
                {
                }
                column(ShowGLAcc2Body1; (DebitAmt <> 0) or (CreditAmt <> 0))
                {
                }
                column(OpenClosePerTransNo_Control58Caption; OpenClosePerTransNo_Control58CaptionLbl)
                {
                }
                column(FORMAT_CLOSINGDATE_OpenCloseDate__Caption; FORMAT_CLOSINGDATE_OpenCloseDate__CaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    SetRange("Date Filter", 0D, ClosingDate(NextAccPeriod."Starting Date" - 1));
                    CalcFields("Balance at Date", "Add.-Currency Balance at Date");
                    if not PrintAmountsInAddCurrency then
                        if "Balance at Date" < 0 then begin
                            DebitAmt := -"Balance at Date";
                            CreditAmt := 0;
                        end else begin
                            CreditAmt := "Balance at Date";
                            DebitAmt := 0;
                        end
                    else
                        if "Add.-Currency Balance at Date" < 0 then begin
                            DebitAmt := -"Add.-Currency Balance at Date";
                            CreditAmt := 0;
                        end else begin
                            CreditAmt := "Add.-Currency Balance at Date";
                            DebitAmt := 0;
                        end;

                    TFTotalCreditAmt := TFTotalCreditAmt + CreditAmt;
                    TFTotalDebitAmt := TFTotalDebitAmt + DebitAmt;

                    LineID := 3;
                end;

                trigger OnPreDataItem()
                begin
                    if LoopEnd then
                        CurrReport.Break();

                    if TempDate <= ClosingDate(NextAccPeriod."Starting Date" - 1) then
                        TableEnd := true;
                    if TableEnd and
                       (ToDate < ClosingDate(NextAccPeriod."Starting Date" - 1))
                    then begin
                        LoopEnd := true;
                        CurrReport.Break();
                    end;

                    OpenCloseDate := NextAccPeriod."Starting Date" - 1;
                    OpenClosePerTransNo := CurrTransNo + 1;
                    FirstReg := false;

                    if AccPeriod.Next() = 0 then begin
                        if TableEnd then
                            LoopEnd := true
                        else
                            Error(Text1100005, "G/L Entry Group"."Transaction No.");
                    end else
                        TempDate := AccPeriod."Starting Date";

                    if FromPerTransNo <> 0 then
                        if (OpenClosePerTransNo < FromPerTransNo) or
                           (OpenClosePerTransNo > ToPerTransNo)
                        then
                            CurrReport.Break();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if LoopEnd then
                    CurrReport.Break();

                if PrintAmountsInAddCurrency then
                    HeaderText := Text1100004 + ' ' + GLSetup."Additional Reporting Currency"
                else begin
                    GLSetup.TestField("LCY Code");
                    HeaderText := Text1100004 + ' ' + GLSetup."LCY Code";
                end;

                LineID := 0;
            end;

            trigger OnPreDataItem()
            begin
                GLSetup.Get();
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
                    field(CloseTransactDesc; CloseTransactDesc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Closing Transaction Description';
                        ToolTip = 'Specifies the closing transaction description that you want to include in the report.';
                    }
                    field(OpenTransactDesc; OpenTransactDesc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Opening Transaction Description';
                        ToolTip = 'Specifies a description for the initial transaction that you want to include in the report.';
                    }
                    field(FirstPage; FirstPage)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'First Page';
                        ToolTip = 'Specifies the beginning page number to include in the report or view.';
                    }
                    field(PrintAmountsInAddCurrency; PrintAmountsInAddCurrency)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in Add. Currency';
                        ToolTip = 'Specifies if amounts in the additional currency are included.';
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

    trigger OnInitReport()
    begin
        FirstRec := true;
        if OpenTransactDesc = '' then
            OpenTransactDesc := Text1100000;
        if CloseTransactDesc = '' then
            CloseTransactDesc := Text1100001;
    end;

    trigger OnPreReport()
    var
        GLEntry: Record "G/L Entry";
    begin
        FirstPageNum := FirstPage;
        GLDateFilter := "G/L Entry Group".GetFilter("Posting Date");
        GLFilter := "G/L Entry Group".GetFilters();
        FromDate := "G/L Entry Group".GetRangeMin("Posting Date");
        ToDate := "G/L Entry Group".GetRangeMax("Posting Date");
        InitPeriodDate := CalcPeriod(FromDate);
        AccPeriod.Reset();
        if InitPeriodDate <> FromDate then begin
            GLEntry.SetRange("Posting Date", InitPeriodDate, CalcDate('<-1D>', FromDate));
            if GLEntry.Find('-') then
                repeat
                    if not PrintAmountsInAddCurrency then begin
                        TotalDebitAmt := TotalDebitAmt + GLEntry."Debit Amount";
                        TotalCreditAmt := TotalCreditAmt + GLEntry."Credit Amount";
                    end else begin
                        TotalDebitAmt := TotalDebitAmt + GLEntry."Add.-Currency Debit Amount";
                        TotalCreditAmt := TotalCreditAmt + GLEntry."Add.-Currency Credit Amount";
                    end;
                until GLEntry.Next() = 0;
        end;
        GLEntry.SetRange("Posting Date");
        if "G/L Entry Group".GetFilter("Period Trans. No.") <> '' then begin
            FromPerTransNo := "G/L Entry Group".GetRangeMin("Period Trans. No.");
            ToPerTransNo := "G/L Entry Group".GetRangeMax("Period Trans. No.");
        end;

        TempDate := FromDate;

        GLEntry.SetCurrentKey("Posting Date", "Period Trans. No.");
        GLEntry.FindLast();
        if GLEntry."Posting Date" < ToDate then begin
            AccPeriod.SetRange("New Fiscal Year", true);
            AccPeriod.SetFilter("Starting Date", '>%1', GLEntry."Posting Date");
            if not AccPeriod.Find('-') then
                ToDate := GLEntry."Posting Date"
            else
                ToDate := ClosingDate(AccPeriod."Starting Date" - 1);
        end;

        AccPeriod.SetRange("New Fiscal Year", true);
        AccPeriod.SetFilter("Starting Date", '>= %1', FromDate);
        if not AccPeriod.Find('-') then
            AccPeriod."Starting Date" := 99991231D
        else
            if FromDate < AccPeriod."Starting Date" then begin
                AccPeriod.SetRange("Starting Date");
                AccPeriod.Next(-1);
            end;

        if FirstPage <> 0 then
            FirstPage := FirstPage - 1;

        GLEntry.SetFilter("Posting Date", '<%1', FromDate);
        if GLEntry.IsEmpty() then
            FirstReg := true
        else
            FirstReg := false;
    end;

    var
        Text1100000: Label 'Period Opening Transaction';
        Text1100001: Label 'Period Closing Transaction';
        Text1100003: Label 'Period: ';
        Text1100004: Label 'All amounts are in ';
        Text1100005: Label 'There are no more AccPeriods in your registers. Transaction: %1', Comment = '%1=GL register number';
        Text1100006: Label 'There is not any period in this range of date';
        GLAccount: Record "G/L Account";
        AccPeriod: Record "Accounting Period";
        NextAccPeriod: Record "Accounting Period";
        GLSetup: Record "General Ledger Setup";
        GLFilter: Text;
        LoopEnd: Boolean;
        FirstRec: Boolean;
        TempDate: Date;
        OldDate: Date;
        FromDate: Date;
        ToDate: Date;
        FromPerTransNo: Integer;
        ToPerTransNo: Integer;
        OpenTransactDesc: Text[30];
        CloseTransactDesc: Text[30];
        DebitAmt: Decimal;
        CreditAmt: Decimal;
        TFTotalCreditAmt: Decimal;
        TFTotalDebitAmt: Decimal;
        TotalDebitAmt: Decimal;
        TotalCreditAmt: Decimal;
        OpenClosePerTransNo: Integer;
        OpenCloseDate: Date;
        TableEnd: Boolean;
        FirstPage: Integer;
        GLDateFilter: Text;
        FirstReg: Boolean;
        CurrTransNo: Integer;
        PrintAmountsInAddCurrency: Boolean;
        HeaderText: Text[50];
        InitPeriodDate: Date;
        FirstPeriodDate: Date;
        LineID: Integer;
        FirstPageNum: Integer;
        TFTotalCreditAmt1: Decimal;
        TFTotalDebitAmt1: Decimal;
        Official_Accounting_BookCaptionLbl: Label 'Official Accounting Book';
        CurrReport_PAGENO___FirstPageCaptionLbl: Label 'Page';
        GLAccount_NameCaptionLbl: Label 'Name';
        ContinuedCaptionLbl: Label 'Continued';
        ContinuedCaption_Control60Lbl: Label 'Continued';
        TotalCaptionLbl: Label 'Total';
        V1CaptionLbl: Label 'Period Trans. No.';
        NORMALDATE_OpenCloseDate_CaptionLbl: Label 'Posting Date';
        OpenClosePerTransNoCaptionLbl: Label 'Period Trans. No.';
        NORMALDATE_OpenCloseDate__Control29CaptionLbl: Label 'Posting Date';
        ContinuedCaption_Control43Lbl: Label 'Continued';
        G_L_Register__Posting_Date_CaptionLbl: Label 'Posting Date';
        ContinuedCaption_Control42Lbl: Label 'Continued';
        G_L_Register__Posting_Date__Control39CaptionLbl: Label 'Posting Date';
        OpenClosePerTransNo_Control58CaptionLbl: Label 'Period Trans. No.';
        FORMAT_CLOSINGDATE_OpenCloseDate__CaptionLbl: Label 'Posting Date';
        GroupPostingDate: Date;
        GroupPeriodTransNo: Integer;

    [Scope('OnPrem')]
    procedure CalcPeriod(InitialDate: Date): Date
    begin
        AccPeriod.SetRange("New Fiscal Year", true);
        AccPeriod.SetFilter("Starting Date", '<=%1', InitialDate);
        if AccPeriod.Find('+') then
            exit(AccPeriod."Starting Date");

        Error(Text1100006);
    end;
}

