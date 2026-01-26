// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Reminder;
using System.Utilities;

report 17109 "Transaction Detail Report"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/GeneralLedger/Reports/TransactionDetailReport.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Transaction Detail Report';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Name", "Income/Balance", "Debit/Credit", "Date Filter";
            column(USERID; UserId)
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(STRSUBSTNO_Text000_GLDateFilter_; StrSubstNo(Text000, GLDateFilter))
            {
            }
            column(HeaderText; HeaderText)
            {
            }
            column(myPrintAllHavingBal; PrintAllHavingBal)
            {
            }
            column(myPrintClosingEntries; PrintClosingEntries)
            {
            }
            column(G_L_Account__TABLECAPTION__________GLFilter; "G/L Account".TableCaption + ': ' + GLFilter)
            {
            }
            column(myGLFilter; GLFilter)
            {
            }
            column(myPrintOnlyOnePerPage; PrintOnlyOnePerPage)
            {
            }
            column(myUseAmtsInAddCurr; UseAmtsInAddCurr)
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
            column(Transaction_DetailCaption; Transaction_DetailCaptionLbl)
            {
            }
            column(This_also_includes_G_L_accounts_that_only_have_a_balance_Caption; This_also_includes_G_L_accounts_that_only_have_a_balance_CaptionLbl)
            {
            }
            column(This_report_also_includes_closing_entries_within_the_period_Caption; This_report_also_includes_closing_entries_within_the_period_CaptionLbl)
            {
            }
            column(AmountCaption; AmountCaptionLbl)
            {
            }
            column(Global_Dimension_1_CodeCaption; CaptionClassTranslate('1,1,1'))
            {
            }
            column(Global_Dimension_2_CodeCaption; CaptionClassTranslate('1,1,2'))
            {
            }
            column(Source_Name_DescriptionCaption; Source_Name_DescriptionCaptionLbl)
            {
            }
            column(Source_NameCaption; Source_NameCaptionLbl)
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
            column(BalanceCaption; BalanceCaptionLbl)
            {
            }
            column(Document_TypeCaption; Document_TypeCaptionLbl)
            {
            }
            column(G_L_Entry_Amount_Control26Caption; "G/L Entry".FieldCaption(Amount))
            {
            }
            column(G_L_Entry__VAT_Amount__Control23Caption; "G/L Entry".FieldCaption("VAT Amount"))
            {
            }
            column(G_L_Entry__Global_Dimension_1_Code__Control1450014Caption; CaptionClassTranslate('1,1,1'))
            {
            }
            column(G_L_Entry__Global_Dimension_2_Code__Control1450016Caption; CaptionClassTranslate('1,1,2'))
            {
            }
            column(SourceDocDesc_Control1450002Caption; SourceDocDesc_Control1450002CaptionLbl)
            {
            }
            column(SourceName_Control1450000Caption; SourceName_Control1450000CaptionLbl)
            {
            }
            column(G_L_Entry_Description_Control20Caption; "G/L Entry".FieldCaption(Description))
            {
            }
            column(G_L_Entry__Document_No___Control14Caption; "G/L Entry".FieldCaption("Document No."))
            {
            }
            column(Posting_DateCaption_Control12; Posting_DateCaption_Control12Lbl)
            {
            }
            column(BalanceCaption_Control1450051; BalanceCaption_Control1450051Lbl)
            {
            }
            column(G_L_Entry__Document_Type__Control1450057Caption; "G/L Entry".FieldCaption("Document Type"))
            {
            }
            dataitem(PageCounter; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(G_L_Account___No__; "G/L Account"."No.")
                {
                }
                column(G_L_Account__Name; "G/L Account".Name)
                {
                }
                column(StartBalance; StartBalance)
                {
                    AutoFormatType = 1;
                }
                column(PageCounter_Number; Number)
                {
                }
                column(G_L_Account___No__Caption; G_L_Account___No__CaptionLbl)
                {
                }
                dataitem("G/L Entry"; "G/L Entry")
                {
                    DataItemLink = "G/L Account No." = field("No."), "Posting Date" = field("Date Filter"), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter"), "Business Unit Code" = field("Business Unit Filter");
                    DataItemLinkReference = "G/L Account";
                    DataItemTableView = sorting("G/L Account No.", "Posting Date");
                    RequestFilterFields = "Global Dimension 1 Code", "Global Dimension 2 Code";
                    column(StartBalance____Additional_Currency_Amount_; StartBalance + "Additional-Currency Amount")
                    {
                        AutoFormatType = 1;
                    }
                    column(G_L_Entry__Additional_Currency_Amount_; "Additional-Currency Amount")
                    {
                    }
                    column(StartBalance___Amount; StartBalance + Amount)
                    {
                        AutoFormatType = 1;
                    }
                    column(G_L_Entry_Amount; Amount)
                    {
                    }
                    column(G_L_Entry__VAT_Amount_; "VAT Amount")
                    {
                    }
                    column(G_L_Entry__Additional_Currency_Amount__Control1450019; "Additional-Currency Amount")
                    {
                    }
                    column(G_L_Entry__Global_Dimension_2_Code_; "Global Dimension 2 Code")
                    {
                    }
                    column(G_L_Entry__Global_Dimension_1_Code_; "Global Dimension 1 Code")
                    {
                    }
                    column(SourceDocDesc; SourceDocDesc)
                    {
                    }
                    column(SourceName; SourceName)
                    {
                    }
                    column(G_L_Entry_Description; Description)
                    {
                    }
                    column(G_L_Entry__Document_No__; "Document No.")
                    {
                    }
                    column(G_L_Entry__Posting_Date_; Format("Posting Date"))
                    {
                    }
                    column(GLBalance; GLBalance)
                    {
                        AutoFormatType = 1;
                    }
                    column(G_L_Entry__Document_Type_; "Document Type")
                    {
                    }
                    column(ShowDetail; ShowDetail)
                    {
                    }
                    column(G_L_Entry__Posting_Date__Control11; Format("Posting Date"))
                    {
                    }
                    column(G_L_Entry__Document_No___Control14; "Document No.")
                    {
                    }
                    column(G_L_Entry_Description_Control20; Description)
                    {
                    }
                    column(G_L_Entry__VAT_Amount__Control23; "VAT Amount")
                    {
                    }
                    column(G_L_Entry_Amount_Control26; Amount)
                    {
                    }
                    column(SourceName_Control1450000; SourceName)
                    {
                    }
                    column(SourceDocDesc_Control1450002; SourceDocDesc)
                    {
                    }
                    column(G_L_Entry__Global_Dimension_1_Code__Control1450014; "Global Dimension 1 Code")
                    {
                    }
                    column(G_L_Entry__Global_Dimension_2_Code__Control1450016; "Global Dimension 2 Code")
                    {
                    }
                    column(GLBalance_0; GLBalance + 0)
                    {
                        AutoFormatType = 1;
                    }
                    column(G_L_Entry__Document_Type__Control1450057; "Document Type")
                    {
                    }
                    column(myAmountGLBalance; "G/L Entry".Amount + GLBalance)
                    {
                    }
                    column(StartBalance____Additional_Currency_Amount__Control1450037; StartBalance + "Additional-Currency Amount")
                    {
                        AutoFormatType = 1;
                    }
                    column(G_L_Entry__Additional_Currency_Amount__Control1450038; "Additional-Currency Amount")
                    {
                    }
                    column(G_L_Entry_Amount_Control1450045; Amount)
                    {
                    }
                    column(StartBalance___Amount_Control1450046; StartBalance + Amount)
                    {
                        AutoFormatType = 1;
                    }
                    column(G_L_Entry__VAT_Amount__Control1450048; "VAT Amount")
                    {
                    }
                    column(G_L_Entry_Entry_No_; "Entry No.")
                    {
                    }
                    column(G_L_Entry_G_L_Account_No_; "G/L Account No.")
                    {
                    }
                    column(G_L_Entry_Posting_Date; "Posting Date")
                    {
                    }
                    column(G_L_Entry_Business_Unit_Code; "Business Unit Code")
                    {
                    }
                    column(ContinuedCaption; ContinuedCaptionLbl)
                    {
                    }
                    column(ContinuedCaption_Control1450043; ContinuedCaption_Control1450043Lbl)
                    {
                    }
                    column(ContinuedCaption_Control1450044; ContinuedCaption_Control1450044Lbl)
                    {
                    }
                    column(ContinuedCaption_Control1450047; ContinuedCaption_Control1450047Lbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        SourceName := '';
                        SourceDocDesc := '';
                        case "Source Type" of
                            "Source Type"::Vendor:
                                begin
                                    if Vendor.Get("G/L Entry"."Source No.") then
                                        SourceName := Vendor.Name;
                                    case "Document Type" of
                                        "Document Type"::Invoice:
                                            if PurchInvHeader.Get("Document No.") then
                                                SourceDocDesc := PurchInvHeader."Posting Description";
                                        "Document Type"::"Credit Memo":
                                            if PurchCrMemoHdr.Get("Document No.") then
                                                SourceDocDesc := PurchCrMemoHdr."Posting Description";
                                    end;
                                end;
                            "Source Type"::Customer:
                                begin
                                    if Customer.Get("G/L Entry"."Source No.") then
                                        SourceName := Customer.Name;
                                    case "Document Type" of
                                        "Document Type"::Invoice:
                                            if SalesInvoiceHeader.Get("Document No.") then
                                                SourceDocDesc := SalesInvoiceHeader."Posting Description";
                                        "Document Type"::"Credit Memo":
                                            if SalesCrMemoHeader.Get("Document No.") then
                                                SourceDocDesc := SalesCrMemoHeader."Posting Description";
                                        "Document Type"::"Finance Charge Memo":
                                            if FinanceChargeMemoHeader.Get("Document No.") then
                                                SourceDocDesc := FinanceChargeMemoHeader."Posting Description";
                                        "Document Type"::Reminder:
                                            if ReminderHeader.Get("Document No.") then
                                                SourceDocDesc := ReminderHeader."Posting Description";
                                    end;
                                end;
                            "Source Type"::"Bank Account":
                                if BankAccount.Get("G/L Entry"."Source No.") then
                                    SourceName := BankAccount.Name;
                            "Source Type"::"Fixed Asset":
                                begin
                                    if FixedAsset.Get("G/L Entry"."Source No.") then
                                        SourceName := FixedAsset.Description;
                                    case "Document Type" of
                                        "Document Type"::Invoice:
                                            if PurchInvHeader.Get("Document No.") then
                                                SourceDocDesc := PurchInvHeader."Posting Description";
                                        "Document Type"::"Credit Memo":
                                            if PurchCrMemoHdr.Get("Document No.") then
                                                SourceDocDesc := PurchCrMemoHdr."Posting Description";
                                    end;
                                end;
                        end;

                        ShowDetail := true;
                        if not UseAmtsInAddCurr then begin
                            GLBalance := GLBalance + Amount;
                            if ("Posting Date" = ClosingDate("Posting Date")) and
                               not PrintClosingEntries
                            then begin
                                ShowDetail := false;
                                Amount := 0;
                                "VAT Amount" := 0;
                            end;
                        end;

                        if UseAmtsInAddCurr then begin
                            GLBalance := GLBalance + "Additional-Currency Amount";
                            if ("Posting Date" = ClosingDate("Posting Date")) and
                               not PrintClosingEntries
                            then begin
                                ShowDetail := false;
                                "Additional-Currency Amount" := 0;
                            end;
                        end;
                        if ShowDetail then
                            RecNumber += 1;
                    end;

                    trigger OnPreDataItem()
                    begin
                        GLBalance := StartBalance;
                        RecNumber := 0;
                    end;
                }
                dataitem("Integer"; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(G_L_Entry___Additional_Currency_Amount_; "G/L Entry"."Additional-Currency Amount")
                    {
                    }
                    column(G_L_Account__Name_Control1450036; "G/L Account".Name)
                    {
                    }
                    column(StartBalance____G_L_Entry___Additional_Currency_Amount_; StartBalance + "G/L Entry"."Additional-Currency Amount")
                    {
                        AutoFormatType = 1;
                    }
                    column(RecNumber; RecNumber)
                    {
                    }
                    column(G_L_Entry__Amount; "G/L Entry".Amount)
                    {
                    }
                    column(G_L_Entry___VAT_Amount_; "G/L Entry"."VAT Amount")
                    {
                    }
                    column(G_L_Account__Name_Control1450006; "G/L Account".Name)
                    {
                    }
                    column(StartBalance____G_L_Entry__Amount; StartBalance + "G/L Entry".Amount)
                    {
                        AutoFormatType = 1;
                    }
                    column(Integer_Number; Number)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if UseAmtsInAddCurr then begin
                            if ("G/L Entry"."Additional-Currency Amount" = 0) and
                               ((StartBalance = 0) or
                                not PrintAllHavingBal)
                            then
                                CurrReport.Skip();
                        end else
                            if ("G/L Entry".Amount = 0) and
                               ((StartBalance = 0) or
                                not PrintAllHavingBal)
                            then
                                CurrReport.Skip();
                    end;

                    trigger OnPostDataItem()
                    begin
                        "G/L Entry"."Additional-Currency Amount" := 0;
                        "G/L Entry".Amount := 0;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    CurrReport.PrintOnlyIfDetail := not (PrintAllHavingBal and (StartBalance <> 0));
                end;
            }

            trigger OnAfterGetRecord()
            begin
                StartBalance := 0;
                if GLDateFilter <> '' then
                    if GetRangeMin("Date Filter") <> 0D then begin
                        SetRange("Date Filter", 0D, ClosingDate(GetRangeMin("Date Filter") - 1));
                        if UseAmtsInAddCurr then begin
                            CalcFields("Additional-Currency Net Change");
                            StartBalance := "Additional-Currency Net Change";
                        end else begin
                            CalcFields("Net Change");
                            StartBalance := "Net Change";
                        end;
                        SetFilter("Date Filter", GLDateFilter);
                    end;
            end;

            trigger OnPreDataItem()
            begin
                GLSetup.Get();

                if UseAmtsInAddCurr then
                    HeaderText := StrSubstNo(Text001, GLSetup."Additional Reporting Currency")
                else begin
                    GLSetup.TestField("LCY Code");
                    HeaderText := StrSubstNo(Text001, GLSetup."LCY Code");
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
                    field(PrintOnlyOnePerPage; PrintOnlyOnePerPage)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Page per G/L Acc.';
                        ToolTip = 'Specifies if each G/L account information is printed on a new page if you have chosen two or more G/L accounts to be included in the report.';
                    }
                    field(PrintAllHavingBal; PrintAllHavingBal)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include G/L Accs. That Have a Balance Only';
                        MultiLine = true;
                        ToolTip = 'Specifies that you want to include at general ledger accounts with a balance.';
                    }
                    field(PrintClosingEntries; PrintClosingEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Closing Entries Within the Period';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want the report to include closing entries. This is useful if the report covers an entire fiscal year. Closing entries are listed on a fictitious date between the last day of one fiscal year and the first day of the next one. They have a C before the date, such as C123194. If you do not select this field, no closing entries are shown.';
                    }
                    field(ShowAmountsInAddReportingCurrency; UseAmtsInAddCurr)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in Add. Reporting Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want report amounts to be shown in the additional reporting currency.';
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
        GLFilter := "G/L Account".GetFilters();
        GLDateFilter := "G/L Account".GetFilter("Date Filter");
    end;

    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        FixedAsset: Record "Fixed Asset";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        ReminderHeader: Record "Reminder Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        GLSetup: Record "General Ledger Setup";
        GLDateFilter: Text[30];
        GLFilter: Text[250];
        GLBalance: Decimal;
        SourceName: Text[250];
        SourceDocDesc: Text[250];
        PrintOnlyOnePerPage: Boolean;
        PrintAllHavingBal: Boolean;
        PrintClosingEntries: Boolean;
        UseAmtsInAddCurr: Boolean;
        StartBalance: Decimal;
        Text000: Label 'Period: %1';
        Text001: Label 'All amounts are in %1';
        HeaderText: Text[50];
        ShowDetail: Boolean;
        RecNumber: Integer;
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Transaction_DetailCaptionLbl: Label 'Transaction Detail';
        This_also_includes_G_L_accounts_that_only_have_a_balance_CaptionLbl: Label 'This also includes G/L accounts that only have a balance.';
        This_report_also_includes_closing_entries_within_the_period_CaptionLbl: Label 'This report also includes closing entries within the period.';
        AmountCaptionLbl: Label 'Amount';
        Source_Name_DescriptionCaptionLbl: Label 'Source Name Description';
        Source_NameCaptionLbl: Label 'Source Name';
        DescriptionCaptionLbl: Label 'Description';
        Document_No_CaptionLbl: Label 'Document No.';
        Posting_DateCaptionLbl: Label 'Posting Date';
        BalanceCaptionLbl: Label 'Balance';
        Document_TypeCaptionLbl: Label 'Document Type';
        SourceDocDesc_Control1450002CaptionLbl: Label 'Source Document Description';
        SourceName_Control1450000CaptionLbl: Label 'Source Name';
        Posting_DateCaption_Control12Lbl: Label 'Posting Date';
        BalanceCaption_Control1450051Lbl: Label 'Balance';
        G_L_Account___No__CaptionLbl: Label 'G/L Account No.';
        ContinuedCaptionLbl: Label 'Continued';
        ContinuedCaption_Control1450043Lbl: Label 'Continued';
        ContinuedCaption_Control1450044Lbl: Label 'Continued';
        ContinuedCaption_Control1450047Lbl: Label 'Continued';
}

