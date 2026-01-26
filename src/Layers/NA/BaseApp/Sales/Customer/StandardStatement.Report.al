// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.CRM.Interaction;
using Microsoft.CRM.Segment;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using System.Email;
using System.Globalization;
using System.Utilities;

report 1316 "Standard Statement"
{
    Caption = 'Customer Statement';
    DefaultRenderingLayout = "StandardStatement.docx";

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Name", "Print Statements", "Currency Filter";
            column(No_Cust; "No.")
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                PrintOnlyIfDetail = true;
                column(CompanyPicture; CompanyInfo.Picture)
                {
                }
                column(CompanyInfo1Picture; CompanyInfo1.Picture)
                {
                }
                column(CompanyInfo2Picture; CompanyInfo2.Picture)
                {
                }
                column(CompanyInfo3Picture; CompanyInfo3.Picture)
                {
                }
                column(CustAddr1; CustomerAddress[1])
                {
                }
                column(CompanyAddr1; CompanyAddress[1])
                {
                }
                column(CustAddr2; CustomerAddress[2])
                {
                }
                column(CompanyAddr2; CompanyAddress[2])
                {
                }
                column(CustAddr3; CustomerAddress[3])
                {
                }
                column(CompanyAddr3; CompanyAddress[3])
                {
                }
                column(CustAddr4; CustomerAddress[4])
                {
                }
                column(CompanyAddr4; CompanyAddress[4])
                {
                }
                column(CustAddr5; CustomerAddress[5])
                {
                }
                column(CompanyAddr5; CompanyAddress[5])
                {
                }
                column(PhoneNo_CompanyInfo; CompanyInfo."Phone No.")
                {
                }
                column(CustAddr6; CustomerAddress[6])
                {
                }
                column(CompanyAddr6; CompanyAddress[6])
                {
                }
                column(CompanyInfoEmail; CompanyInfo."E-Mail")
                {
                }
                column(CompanyInfoHomePage; CompanyInfo."Home Page")
                {
                }
                column(VATRegNo_CompanyInfo; CompanyInfo."VAT Registration No.")
                {
                }
                column(GiroNo_CompanyInfo; CompanyInfo."Giro No.")
                {
                }
                column(BankName_CompanyInfo; CompanyInfo."Bank Name")
                {
                }
                column(BankAccNo_CompanyInfo; CompanyInfo."Bank Account No.")
                {
                }
                column(No1_Cust; Customer."No.")
                {
                }
                column(TodayFormatted; Format(Today))
                {
                }
                column(StartDate; Format(StartDate))
                {
                }
                column(EndDate; Format(EndDate))
                {
                }
                column(LastStatmntNo_Cust; Format(Customer."Last Statement No." + 1))
                {
                }
                column(CustAddr7; CustomerAddress[7])
                {
                }
                column(CustAddr8; CustomerAddress[8])
                {
                }
                column(CompanyAddr7; CompanyAddress[7])
                {
                }
                column(CompanyAddr8; CompanyAddress[8])
                {
                }
                column(StatementCaption; StatementCaptionLbl)
                {
                }
                column(PhoneNo_CompanyInfoCaption; PhoneNo_CompanyInfoCaptionLbl)
                {
                }
                column(VATRegNo_CompanyInfoCaption; VATRegNo_CompanyInfoCaptionLbl)
                {
                }
                column(GiroNo_CompanyInfoCaption; GiroNo_CompanyInfoCaptionLbl)
                {
                }
                column(BankName_CompanyInfoCaption; BankName_CompanyInfoCaptionLbl)
                {
                }
                column(BankAccNo_CompanyInfoCaption; BankAccNo_CompanyInfoCaptionLbl)
                {
                }
                column(No1_CustCaption; No1_CustCaptionLbl)
                {
                }
                column(StartDateCaption; StartDateCaptionLbl)
                {
                }
                column(EndDateCaption; EndDateCaptionLbl)
                {
                }
                column(LastStatmntNo_CustCaption; LastStatmntNo_CustCaptionLbl)
                {
                }
                column(PostDate_DtldCustLedgEntriesCaption; PostDate_DtldCustLedgEntriesCaptionLbl)
                {
                }
                column(DocNo_DtldCustLedgEntriesCaption; DtldCustLedgEntries.FieldCaption("Document No."))
                {
                }
                column(Desc_CustLedgEntry2Caption; CustLedgEntry2.FieldCaption(Description))
                {
                }
                column(DueDate_CustLedgEntry2Caption; DueDate_CustLedgEntry2CaptionLbl)
                {
                }
                column(RemainAmtCustLedgEntry2Caption; CustLedgEntry2.FieldCaption("Remaining Amount"))
                {
                }
                column(CustBalanceCaption; CustBalanceCaptionLbl)
                {
                }
                column(OriginalAmt_CustLedgEntry2Caption; CustLedgEntry2.FieldCaption("Original Amount"))
                {
                }
                column(CompanyInfoHomepageCaption; CompanyInfoHomepageCaptionLbl)
                {
                }
                column(CompanyInfoEmailCaption; CompanyInfoEmailCaptionLbl)
                {
                }
                column(DocDateCaption; DocDateCaptionLbl)
                {
                }
                column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
                {
                }
                column(CompanyLegalOffice; LegalOfficeTxt)
                {
                }
                column(CompanyLegalOffice_Lbl; LegalOfficeLbl)
                {
                }
                dataitem(CurrencyLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                    PrintOnlyIfDetail = true;
                    column(Total_Caption2; Total_CaptionLbl)
                    {
                    }
                    dataitem(CustLedgEntryHdr; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(Currency2Code_CustLedgEntryHdr; StrSubstNo(EntriesLbl, CurrencyCode3))
                        {
                        }
                        column(StartBalance; StartBalance)
                        {
                            AutoFormatExpression = TempCurrency2.Code;
                            AutoFormatType = 1;
                        }
                        column(CurrencyCode3; CurrencyCode3)
                        {
                        }
                        column(CustBalance_CustLedgEntryHdr; CustBalance)
                        {
                        }
                        column(PrintLine; PrintLine)
                        {
                        }
                        column(DtldCustLedgEntryType; Format(DtldCustLedgEntries."Entry Type", 0, 2))
                        {
                        }
                        column(EntriesExists; EntriesExists)
                        {
                        }
                        column(IsNewCustCurrencyGroup; IsNewCustCurrencyGroup)
                        {
                        }
                        dataitem(DtldCustLedgEntries; "Detailed Cust. Ledg. Entry")
                        {
                            DataItemTableView = sorting("Customer No.", "Posting Date", "Entry Type", "Currency Code");
                            column(PostDate_DtldCustLedgEntries; Format("Posting Date"))
                            {
                            }
                            column(DocNo_DtldCustLedgEntries; "Document No.")
                            {
                            }
                            column(Description; Description)
                            {
                            }
                            column(YourReference_DtldCustLedgEntries; YourReference)
                            {
                            }
                            column(DueDate_DtldCustLedgEntries; Format(DueDate))
                            {
                            }
                            column(CurrCode_DtldCustLedgEntries; "Currency Code")
                            {
                            }
                            column(Amt_DtldCustLedgEntries; Amount)
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(RemainAmt_DtldCustLedgEntries; RemainingAmount)
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(CustBalance; CustBalance)
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(Currency2Code; TempCurrency2.Code)
                            {
                            }

                            trigger OnAfterGetRecord()
                            var
                                Skip: Boolean;
                            begin
                                if SkipReversedUnapplied(DtldCustLedgEntries) or (Amount = 0) then
                                    CurrReport.Skip();
                                RemainingAmount := 0;
                                PrintLine := true;
                                YourReference := '';
                                case "Entry Type" of
                                    "Entry Type"::"Initial Entry":
                                        begin
                                            CustLedgerEntry.Get("Cust. Ledger Entry No.");
                                            Skip := false;
                                            OnDtldCustLedgEntriesOnAfterGetRecordnAfterGetCustLedgerEntry(DtldCustLedgEntries, CustLedgerEntry, Skip);
                                            if Skip then
                                                CurrReport.Skip();
                                            YourReference := CustLedgerEntry."Your Reference";
                                            Description := CustLedgerEntry.Description;
                                            DueDate := CustLedgerEntry."Due Date";
                                            CustLedgerEntry.SetRange("Date Filter", 0D, EndDate);
                                            CustLedgerEntry.CalcFields("Remaining Amount");
                                            RemainingAmount := CustLedgerEntry."Remaining Amount";
                                            CustLedgerEntry.SetRange("Date Filter");
                                        end;
                                    "Entry Type"::Application:
                                        begin
                                            DetailedCustLedgEntry2.SetCurrentKey("Customer No.", "Posting Date", "Entry Type");
                                            DetailedCustLedgEntry2.SetRange("Customer No.", "Customer No.");
                                            DetailedCustLedgEntry2.SetRange("Posting Date", "Posting Date");
                                            DetailedCustLedgEntry2.SetRange("Entry Type", "Entry Type"::Application);
                                            DetailedCustLedgEntry2.SetRange("Transaction No.", "Transaction No.");
                                            DetailedCustLedgEntry2.SetFilter("Currency Code", '<>%1', "Currency Code");
                                            if not DetailedCustLedgEntry2.IsEmpty() then begin
                                                Description := MulticurrencyAppLbl;
                                                DueDate := 0D;
                                            end else
                                                CurrReport.Skip();
                                        end;
                                    "Entry Type"::"Payment Discount",
                                    "Entry Type"::"Payment Discount (VAT Excl.)",
                                    "Entry Type"::"Payment Discount (VAT Adjustment)",
                                    "Entry Type"::"Payment Discount Tolerance",
                                    "Entry Type"::"Payment Discount Tolerance (VAT Excl.)",
                                    "Entry Type"::"Payment Discount Tolerance (VAT Adjustment)":
                                        begin
                                            Description := PaymentDiscountLbl;
                                            DueDate := 0D;
                                        end;
                                    "Entry Type"::"Payment Tolerance",
                                    "Entry Type"::"Payment Tolerance (VAT Excl.)",
                                    "Entry Type"::"Payment Tolerance (VAT Adjustment)":
                                        begin
                                            Description := WriteoffsLbl;
                                            DueDate := 0D;
                                        end;
                                    "Entry Type"::"Appln. Rounding",
                                    "Entry Type"::"Correction of Remaining Amount":
                                        begin
                                            Description := RoundingLbl;
                                            DueDate := 0D;
                                        end;
                                end;

                                if PrintLine then begin
                                    if StatementStyle = StatementStyle::"Open Item" then
                                        if RemainingAmount = 0 then
                                            CurrReport.Skip();

                                    NumberOfCustLedgerEntryLines += 1;
                                    if StatementStyle = StatementStyle::"Open Item" then
                                        CustBalance += RemainingAmount
                                    else
                                        CustBalance := CustBalance + Amount;
                                    IsNewCustCurrencyGroup := IsFirstPrintLine;
                                    IsFirstPrintLine := false;
                                    ClearCompanyPicture();
                                end;
                            end;

                            trigger OnPreDataItem()
                            begin
                                SetRange("Customer No.", Customer."No.");
                                SetRange("Posting Date", StartDate, EndDate);
                                SetRange("Currency Code", TempCurrency2.Code);
                                if StatementStyle = StatementStyle::"Open Item" then
                                    SetRange("Entry Type", "Entry Type"::"Initial Entry");
                                OnDtldCustLedgEntriesOnPreDataItemOnAfterSetFilters(DtldCustLedgEntries);
                                if TempCurrency2.Code = '' then begin
                                    GLSetup.TestField("LCY Code");
                                    CurrencyCode3 := GLSetup."LCY Code"
                                end else
                                    CurrencyCode3 := TempCurrency2.Code;

                                IsFirstPrintLine := true;
                            end;
                        }
                    }
                    dataitem(CustLedgEntryFooter; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(CurrencyCode3_CustLedgEntryFooter; CurrencyCode3)
                        {
                        }
                        column(Total_Caption; Total_CaptionLbl)
                        {
                        }
                        column(CustBalance_CustLedgEntryHdrFooter; CustBalance)
                        {
                            AutoFormatExpression = TempCurrency2.Code;
                            AutoFormatType = 1;
                        }
                        column(EntriesExistsl_CustLedgEntryFooterCaption; EntriesExists)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            ClearCompanyPicture();
                        end;
                    }
                    dataitem(OverdueVisible; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(Total_Caption3; Total_CaptionLbl)
                        {
                        }
                        column(PostDate_DtldCustLedgEntriesCaption2; PostDate_DtldCustLedgEntriesCaptionLbl)
                        {
                        }
                        column(DocNo_DtldCustLedgEntriesCaption2; DtldCustLedgEntries.FieldCaption("Document No."))
                        {
                        }
                        column(Desc_CustLedgEntry2Caption2; CustLedgEntry2.FieldCaption(Description))
                        {
                        }
                        column(DueDate_CustLedgEntry2Caption2; DueDate_CustLedgEntry2CaptionLbl)
                        {
                        }
                        column(RemainAmtCustLedgEntry2Caption2; CustLedgEntry2.FieldCaption("Remaining Amount"))
                        {
                        }
                        column(OriginalAmt_CustLedgEntry2Caption2; CustLedgEntry2.FieldCaption("Original Amount"))
                        {
                        }
                        column(OverDueEntries; StrSubstNo(OverdueEntriesLbl, CurrencyCode3))
                        {
                        }
                        column(CurrencyCode3_CustLedgEntry2; CurrencyCode3)
                        {
                        }
                        dataitem(CustLedgEntry2; "Cust. Ledger Entry")
                        {
                            DataItemLink = "Customer No." = field("No.");
                            DataItemLinkReference = Customer;
                            DataItemTableView = sorting("Customer No.", Open, Positive, "Due Date");
                            column(RemainAmt_CustLedgEntry2; "Remaining Amount")
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(PostDate_CustLedgEntry2; Format("Posting Date"))
                            {
                            }
                            column(DocNo_CustLedgEntry2; "Document No.")
                            {
                            }
                            column(Desc_CustLedgEntry2; Description)
                            {
                            }
                            column(YourReference_CustLedgEntry2; "Your Reference") { }
                            column(DueDate_CustLedgEntry2; Format("Due Date"))
                            {
                            }
                            column(OriginalAmt_CustLedgEntry2; "Original Amount")
                            {
                                AutoFormatExpression = "Currency Code";
                            }
                            column(CurrCode_CustLedgEntry2; "Currency Code")
                            {
                            }
                            column(PrintEntriesDue; PrintEntriesDue)
                            {
                            }
                            column(Currency2Code_CustLedgEntry2; TempCurrency2.Code)
                            {
                            }
                            column(CustNo_CustLedgEntry2; "Customer No.")
                            {
                            }

                            trigger OnAfterGetRecord()
                            var
                                CustLedgEntry: Record "Cust. Ledger Entry";
                            begin
                                if IncludeAgingBand then
                                    if ("Posting Date" > EndDate) and ("Due Date" >= EndDate) then
                                        CurrReport.Skip();
                                CustLedgEntry := CustLedgEntry2;
                                CustLedgEntry.SetRange("Date Filter", 0D, EndDate);
                                CustLedgEntry.CalcFields("Remaining Amount");
                                "Remaining Amount" := CustLedgEntry."Remaining Amount";
                                if CustLedgEntry."Remaining Amount" = 0 then
                                    CurrReport.Skip();

                                if "Due Date" >= EndDate then
                                    CurrReport.Skip();

                                CustBalance2 := CustBalance2 + CustLedgEntry."Remaining Amount";
                                ClearCompanyPicture();
                            end;

                            trigger OnPreDataItem()
                            begin
                                if not IncludeAgingBand then
                                    SetRange("Due Date", 0D, EndDate - 1);
                                SetRange("Currency Code", TempCurrency2.Code);
                                OnCustLedgEntry2OnPreDataItemOnAfterSetFilters(CustLedgEntry2);
                                if (not PrintEntriesDue) and (not IncludeAgingBand) then
                                    CurrReport.Break();
                            end;
                        }
                        dataitem(OverdueEntryFooder; "Integer")
                        {
                            DataItemTableView = sorting(Number) where(Number = const(1));
                            column(OverdueBalance; CustBalance2)
                            {
                            }
                        }

                        trigger OnPreDataItem()
                        begin
                            if not PrintEntriesDue then
                                CurrReport.Break();
                        end;
                    }

                    trigger OnAfterGetRecord()
                    var
                        CustLedgerEntryBalance: Record "Cust. Ledger Entry";
                    begin
                        if Number = 1 then
                            TempCurrency2.Find('-');

                        repeat
                            if not IsFirstLoop then
                                IsFirstLoop := true
                            else
                                if TempCurrency2.Next() = 0 then
                                    CurrReport.Break();
                            CustLedgerEntry.SetCurrentKey("Customer No.", "Posting Date", "Currency Code");
                            CustLedgerEntry.SetRange("Customer No.", Customer."No.");
                            CustLedgerEntry.SetRange("Posting Date", 0D, EndDate);
                            CustLedgerEntry.SetRange("Currency Code", TempCurrency2.Code);
                            EntriesExists := not CustLedgerEntry.IsEmpty();
                        until EntriesExists;

                        if StatementStyle = StatementStyle::"Open Item" then begin
                            CustBalance := 0;
                            StartBalance := 0;
                            CustLedgerEntryBalance.SetCurrentKey("Customer No.", "Posting Date", "Currency Code");
                            CustLedgerEntryBalance.SetRange("Customer No.", Customer."No.");
                            CustLedgerEntryBalance.SetRange("Posting Date", 0D, StartDate - 1);
                            CustLedgerEntryBalance.SetRange("Currency Code", TempCurrency2.Code);
                            CustLedgerEntryBalance.SetRange("Date Filter", 0D, EndDate);
                            CustLedgerEntryBalance.SetFilter("Remaining Amount", '<>0');
                            CustLedgerEntryBalance.SetAutoCalcFields("Remaining Amount");
                            if CustLedgerEntryBalance.FindSet() then
                                repeat
                                    StartBalance += CustLedgerEntryBalance."Remaining Amount";
                                until CustLedgerEntryBalance.Next() = 0;
                            OnCurrencyLoopOnAfterGetRecordOnAfterCalculateStartBalanceStatementTypeOpenItems(Customer, CustLedgerEntryBalance, StartDate, EndDate, TempCurrency2.Code, StartBalance);
                        end else begin
                            Cust2 := Customer;
                            Cust2.SetRange("Date Filter", 0D, StartDate - 1);
                            Cust2.SetRange("Currency Filter", TempCurrency2.Code);
                            Cust2.CalcFields("Net Change");
                            StartBalance := Cust2."Net Change";
                            OnCurrencyLoopOnAfterGetRecordOnAfterCalculateStartBalanceStatementTypeBalance(Customer, StartDate, EndDate, TempCurrency2.Code, StartBalance);
                        end;
                        CustBalance := StartBalance;
                        CustBalance2 := 0;
                    end;

                    trigger OnPreDataItem()
                    begin
                        Customer.CopyFilter("Currency Filter", TempCurrency2.Code);
                    end;
                }
                dataitem(AgingBandVisible; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    dataitem(AgingCustLedgEntry; "Cust. Ledger Entry")
                    {
                        DataItemLink = "Customer No." = field("No.");
                        DataItemLinkReference = Customer;
                        DataItemTableView = sorting("Customer No.", Open, Positive, "Due Date");

                        trigger OnAfterGetRecord()
                        var
                            CustLedgEntry: Record "Cust. Ledger Entry";
                        begin
                            if ("Posting Date" > EndDate) and ("Due Date" >= EndDate) then
                                CurrReport.Skip();
                            if DateChoice = DateChoice::"Due Date" then
                                if "Due Date" > EndDate then
                                    CurrReport.Skip();
                            CustLedgEntry := AgingCustLedgEntry;
                            CustLedgEntry.SetRange("Date Filter", 0D, EndDate);
                            CustLedgEntry.CalcFields("Remaining Amount");
                            "Remaining Amount" := CustLedgEntry."Remaining Amount";
                            if CustLedgEntry."Remaining Amount" = 0 then
                                CurrReport.Skip();

                            if "Posting Date" <= EndDate then
                                UpdateBuffer("Currency Code", GetDate("Posting Date", "Due Date"), "Remaining Amount");
                        end;

                        trigger OnPreDataItem()
                        begin
                            Customer.CopyFilter("Currency Filter", "Currency Code");
                            SetCurrentKey("Customer No.", "Posting Date", "Currency Code");
                            SetRange("Customer No.", Customer."No.");
                            SetRange("Posting Date", 0D, EndDate);
                        end;
                    }
                    dataitem(AgingBandLoop; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                        column(AgingDate1; Format(AgingDate[1] + 1))
                        {
                        }
                        column(AgingDate2; Format(AgingDate[2]))
                        {
                        }
                        column(AgingDate21; Format(AgingDate[2] + 1))
                        {
                        }
                        column(AgingDate3; Format(AgingDate[3]))
                        {
                        }
                        column(AgingDate31; Format(AgingDate[3] + 1))
                        {
                        }
                        column(AgingDate4; Format(AgingDate[4]))
                        {
                        }
                        column(AgingBandEndingDate; StrSubstNo(AgedSummaryLbl, AgingBandEndingDate, PeriodLength, SelectStr(DateChoice + 1, DuePostingDateLbl)))
                        {
                        }
                        column(AgingDate41; Format(AgingDate[4] + 1))
                        {
                        }
                        column(AgingDate5; Format(AgingDate[5]))
                        {
                        }
                        column(AgingBandBufCol1Amt; TempAgingBandBuf."Column 1 Amt.")
                        {
                            AutoFormatExpression = TempAgingBandBuf."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(AgingBandBufCol2Amt; TempAgingBandBuf."Column 2 Amt.")
                        {
                            AutoFormatExpression = TempAgingBandBuf."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(AgingBandBufCol3Amt; TempAgingBandBuf."Column 3 Amt.")
                        {
                            AutoFormatExpression = TempAgingBandBuf."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(AgingBandBufCol4Amt; TempAgingBandBuf."Column 4 Amt.")
                        {
                            AutoFormatExpression = TempAgingBandBuf."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(AgingBandBufCol5Amt; TempAgingBandBuf."Column 5 Amt.")
                        {
                            AutoFormatExpression = TempAgingBandBuf."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(AgingBandCurrencyCode; AgingBandCurrencyCode)
                        {
                        }
                        column(beforeCaption; beforeCaptionLbl)
                        {
                        }
                        column(AgingDateHeader1; AgingDateHeader1)
                        {
                        }
                        column(AgingDateHeader2; AgingDateHeader2)
                        {
                        }
                        column(AgingDateHeader3; AgingDateHeader3)
                        {
                        }
                        column(AgingDateHeader4; AgingDateHeader4)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then begin
                                ClearCompanyPicture();
                                if not TempAgingBandBuf.Find('-') then
                                    CurrReport.Break();
                            end else
                                if TempAgingBandBuf.Next() = 0 then
                                    CurrReport.Break();
                            AgingBandCurrencyCode := TempAgingBandBuf."Currency Code";
                            if AgingBandCurrencyCode = '' then
                                AgingBandCurrencyCode := GLSetup."LCY Code";
                        end;
                    }

                    trigger OnPreDataItem()
                    begin
                        if not IncludeAgingBand then
                            CurrReport.Break();
                    end;
                }
            }
            dataitem(LetterText; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(GreetingText; GreetingLbl)
                {
                }
                column(BodyText; BodyLbl)
                {
                }
                column(ClosingText; ClosingLbl)
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                TempAgingBandBuf.DeleteAll();
                CurrReport.Language := LanguageMgt.GetLanguageIdOrDefault("Language Code");
                CurrReport.FormatRegion := LanguageMgt.GetFormatRegionOrDefault("Format Region");
                FormatAddress.SetLanguageCode("Language Code");
                PrintLine := false;
                if PrintAllHavingBal and (not PrintAllHavingEntry) then
                    PrintLine := true;

                if (not PrintLine) and PrintAllHavingEntry then begin
                    CustLedgerEntry.Reset();
                    CustLedgerEntry.SetCurrentKey("Customer No.", "Posting Date");
                    CustLedgerEntry.SetRange("Customer No.", "No.");
                    CustLedgerEntry.SetRange("Posting Date", StartDate, EndDate);
                    CopyFilter("Currency Filter", CustLedgerEntry."Currency Code");
                    if StatementStyle = StatementStyle::"Open Item" then begin
                        CustLedgerEntry.SetRange("Date Filter", 0D, EndDate);
                        CustLedgerEntry.SetFilter("Remaining Amount", '<>0');
                    end;

                    PrintLine := not CustLedgerEntry.IsEmpty();
                    OnCurrencyLoopOnAfterGetRecordOnAfterCustLedgerEntryCheckIsEmpty(Customer, CustLedgerEntry, PrintLine);
                end;
                if (not PrintLine) and PrintAllHavingBal then begin
                    Cust2 := Customer;
                    Cust2.SetRange("Date Filter", 0D, EndDate);
                    Cust2.CalcFields("Net Change (LCY)");
                    PrintLine := Cust2."Net Change (LCY)" <> 0;
                end;
                if not PrintLine then
                    CurrReport.Skip();

                FormatAddress.Customer(CustomerAddress, Customer);
                PrintedCustomersList.Add("No.");
                UpdatePictures();
                FirstRecordPrinted := false;
                IsFirstLoop := false;
            end;

            trigger OnPreDataItem()
            begin
                VerifyDates();
                AgingBandEndingDate := EndDate;
                CalcAgingBandDates();

                CompanyInfo.Get();
                FormatAddress.Company(CompanyAddress, CompanyInfo);
                CompanyInfo.CalcFields(Picture);

                PopulateTempCurrencies();

                if PrintAllHavingBal and not PrintAllHavingEntry then begin
                    SetRange("Date Filter", 0D, EndDate);
                    SetAutoCalcFields("Net Change (LCY)");
                    SetFilter("Net Change (LCY)", '<>0');
                end;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Customer Statement';
        AboutText = 'Send customers an overview of outstanding amounts, and also use as a payment reminder about overdue amounts.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field("Start Date"; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Start Date';
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                        ShowMandatory = true;
                    }
                    field("End Date"; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'End Date';
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';
                        ShowMandatory = true;
                    }
                    field("Statement Style"; StatementStyle)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Statement Style';
                        OptionCaption = 'Balance,Open Item';
                        ToolTip = 'Specifies if you want regular statement report or report with open entries only which are posted in the selected period and still open in the moment of Ending Date.';

                        trigger OnValidate()
                        begin
                            UpdateReqPageParameters();
                        end;
                    }

                    field(ShowOverdueEntries; PrintEntriesDue)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Overdue Entries';
                        ToolTip = 'Specifies if you want overdue entries to be shown separately for each currency.';
                    }

                    group(Include)
                    {
                        Caption = 'Include';
                        field(IncludeAllCustomerswithLE; PrintAllHavingEntry)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Include All Customers with Ledger Entries';
                            MultiLine = true;
                            ToolTip = 'Specifies if you want entries displayed for customers that have ledger entries at the end of the selected period.';
                            Editable = PrintAllHavingEntryEditable;

                            trigger OnValidate()
                            begin
                                if not PrintAllHavingEntry then
                                    PrintAllHavingBal := true;
                            end;
                        }
                        field(IncludeAllCustomerswithBalance; PrintAllHavingBal)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Include All Customers with a Balance';
                            MultiLine = true;
                            ToolTip = 'Specifies if you want entries displayed for customers that have a balance at the end of the selected period.';
                            Editable = PrintAllHavingBalEditable;

                            trigger OnValidate()
                            begin
                                if not PrintAllHavingBal then
                                    PrintAllHavingEntry := true;
                            end;
                        }
                        field(IncludeReversedEntries; PrintReversedEntries)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Include Reversed Entries';
                            ToolTip = 'Specifies if you want to include reversed entries in the report.';
                            Editable = PrintReversedEntriesEditable;
                        }
                        field(IncludeUnappliedEntries; PrintUnappliedEntries)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Include Unapplied Entries';
                            ToolTip = 'Specifies if you want to include unapplied entries in the report.';
                            Editable = PrintUnappliedEntriesEditable;
                        }
                    }
                    group("Aging Band")
                    {
                        Caption = 'Aging Band';
                        field(IncludeAgingBand; IncludeAgingBand)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Include Aging Band';
                            ToolTip = 'Specifies if you want an aging band to be included in the document. If you select the check box, then you must also fill the Aging Band Period Length and Aging Band by fields.';
                        }
                        field(AgingBandPeriodLengt; PeriodLength)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Aging Band Period Length';
                            ToolTip = 'Specifies the length of each of the four periods in the aging band, for example, enter "1M" for one month. The most recent period will end on the last day of the period in the Date Filter field.';
                        }
                        field(AgingBandby; DateChoice)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Aging Band by';
                            OptionCaption = 'Due Date,Posting Date';
                            ToolTip = 'Specifies if the aging band will be calculated from the due date or from the posting date.';
                        }
                    }
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Log Interaction';
                        Enabled = LogInteractionEnable;
                        ToolTip = 'Specifies if you want the program to log this interaction.';
                    }
                }
                group("Output Options")
                {
                    Caption = 'Output Options';
                    field(ReportOutput; SupportedOutputMethod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Report Output';
                        OptionCaption = 'Print,Preview,Word,PDF,Email,XML - RDLC layouts only', Comment = 'Each item is a verb/action - to print, to preview, to export to Word, export to PDF, send email, export to XML for RDLC layouts only';
                        ToolTip = 'Specifies the output of the scheduled report, such as PDF or Word.';

                        trigger OnValidate()
                        var
                            CustomLayoutReporting: Codeunit "Custom Layout Reporting";
                        begin
                            ShowPrintIfEmailIsMissing := (SupportedOutputMethod = SupportedOutputMethod::Email);

                            case SupportedOutputMethod of
                                SupportedOutputMethod::Print:
                                    ChosenOutputMethod := CustomLayoutReporting.GetPrintOption();
                                SupportedOutputMethod::Preview:
                                    ChosenOutputMethod := CustomLayoutReporting.GetPreviewOption();
                                SupportedOutputMethod::Word:
                                    ChosenOutputMethod := CustomLayoutReporting.GetWordOption();
                                SupportedOutputMethod::PDF:
                                    ChosenOutputMethod := CustomLayoutReporting.GetPDFOption();
                                SupportedOutputMethod::Email:
                                    ChosenOutputMethod := CustomLayoutReporting.GetEmailOption();
                                SupportedOutputMethod::XML:
                                    ChosenOutputMethod := CustomLayoutReporting.GetXMLOption();
                            end;
                        end;
                    }
                    field(ChosenOutput; ChosenOutputMethod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Chosen Output';
                        ToolTip = 'Specifies how to output the report, such as Print or Excel.';
                        Visible = false;
                    }
                    group(EmailOptions)
                    {
                        Caption = 'Email Options';
                        Visible = ShowPrintIfEmailIsMissing;
                        field(PrintMissingAddresses; PrintIfEmailIsMissing)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Print Although Email is Missing or Invalid';
                            ToolTip = 'Specifies if you want to print also the statements for customers that have not been set up with a send-to email address or defined send-to email address is invalid.';
                        }
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            InitInteractionLog();
            LogInteractionEnable := LogInteraction;
            InitRequestPageDataInternal();
        end;
    }

    rendering
    {
        layout("StandardStatement.rdlc")
        {
            Type = RDLC;
            LayoutFile = './Sales/Customer/StandardStatement.rdlc';
            Caption = 'Standard Customer Statement (RDLC)';
            Summary = 'The Standard Customer Statement (RDLC) provides a detailed layout.';
        }
        layout("StandardStatement.docx")
        {
            Type = Word;
            LayoutFile = './Sales/Customer/StandardStatement.docx';
            Caption = 'Standard Customer Statement (Word)';
            Summary = 'The Standard Customer Statement (Word) provides a basic layout.';
        }
        layout("StandardCustomerStatementEmail.docx")
        {
            Type = Word;
            LayoutFile = './Sales/Customer/StandardCustomerStatementEmail.docx';
            Caption = 'Standard Customer Statement Email (Word)';
            Summary = 'The Standard Customer Statement Email (Word) provides an email body layout.';
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    var
        IsHandled: Boolean;
    begin
        GLSetup.Get();
        SalesSetup.Get();
        SavedCompanyInfo.SetAutoCalcFields(Picture);
        SavedCompanyInfo1.SetAutoCalcFields(Picture);
        SavedCompanyInfo2.SetAutoCalcFields(Picture);
        SavedCompanyInfo3.SetAutoCalcFields(Picture);
        SavedCompanyInfo.Get();
        case SalesSetup."Logo Position on Documents" of
            SalesSetup."Logo Position on Documents"::Left:
                SavedCompanyInfo1.Get();
            SalesSetup."Logo Position on Documents"::Center:
                SavedCompanyInfo2.Get();
            SalesSetup."Logo Position on Documents"::Right:
                SavedCompanyInfo3.Get();
        end;

        UpdatePictures();

        LogInteractionEnable := true;
        PrintAllHavingEntryEditable := true;

        IsHandled := false;
        OnInitReportForGlobalVariable(IsHandled, LegalOfficeTxt, LegalOfficeLbl);
    end;

    trigger OnPostReport()
    var
        CusNo: Code[20];
    begin
        if not IsReportInPreviewMode() then
            foreach CusNo in PrintedCustomersList do
                if Customer.Get(CusNo) then begin
                    Customer."Last Statement No." := Customer."Last Statement No." + 1;
                    Customer.Modify();
                    if LogInteraction then
                        SegManagement.LogDocument(
                          7, Format(Customer."Last Statement No."), 0, 0, DATABASE::Customer, Customer."No.", Customer."Salesperson Code", '',
                          StatementLbl + Format(Customer."Last Statement No."), '');
                end;
        FinishDateTime := CurrentDateTime();
        LogReportTelemetry(StartDateTime, FinishDateTime, NumberOfCustLedgerEntryLines);
    end;

    trigger OnPreReport()
    begin
        StartDateTime := CurrentDateTime();
        InitRequestPageDataInternal();
    end;

    var
        GLSetup: Record "General Ledger Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        SavedCompanyInfo: Record "Company Information";
        SavedCompanyInfo1: Record "Company Information";
        SavedCompanyInfo2: Record "Company Information";
        SavedCompanyInfo3: Record "Company Information";
        Cust2: Record Customer;
        TempCurrency2: Record Currency temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
        TempAgingBandBuf: Record "Aging Band Buffer" temporary;
        LanguageMgt: Codeunit Language;
        FormatAddress: Codeunit "Format Address";
        SegManagement: Codeunit SegManagement;
        PeriodLength2: DateFormula;
        PrintedCustomersList: List of [Code[20]];
        PrintLine: Boolean;
        LogInteraction: Boolean;
        EntriesExists: Boolean;
        DueDate: Date;
        StartBalance: Decimal;
        CurrencyCode3: Code[10];
        AgingDate: array[5] of Date;
        AgingBandEndingDate: Date;
        AgingBandCurrencyCode: Code[20];
        LogInteractionEnable: Boolean;
        PrintAllHavingEntryEditable: Boolean;
        PrintAllHavingBalEditable: Boolean;
        PrintUnappliedEntriesEditable: Boolean;
        PrintReversedEntriesEditable: Boolean;
        isInitialized: Boolean;
        IsFirstLoop: Boolean;
        IsFirstPrintLine: Boolean;
        IsNewCustCurrencyGroup: Boolean;
        AgingDateHeader1: Text;
        AgingDateHeader2: Text;
        AgingDateHeader3: Text;
        AgingDateHeader4: Text;
        SupportedOutputMethod: Option Print,Preview,Word,PDF,Email,XML;
        ChosenOutputMethod: Integer;
        PrintIfEmailIsMissing: Boolean;
        ShowPrintIfEmailIsMissing: Boolean;
        CustBalance2: Decimal;
        FirstRecordPrinted: Boolean;
        YourReference: Text;
        EntriesLbl: Label 'Entries %1', Comment = '%1 = Currency code';
        OverdueEntriesLbl: Label 'Overdue Entries %1', Comment = '%1=Currency code';
        StatementLbl: Label 'Statement ';
        MulticurrencyAppLbl: Label 'Multicurrency Application';
        PaymentDiscountLbl: Label 'Payment Discount';
        RoundingLbl: Label 'Rounding';
        AgingBandPeriodErr: Label 'You must specify the Aging Band Period Length.';
        AgingBandEndErr: Label 'You must specify Aging Band Ending Date.';
        AgedSummaryLbl: Label 'Aged Summary by %1 (%2 by %3)', Comment = '%1=Report aging band end date, %2=Aging band period, %3=Type of deadline (''due date'', ''posting date'') as given in DuePostingDateLbl';
        PeriodLengthErr: Label 'Period Length is out of range.';
        DuePostingDateLbl: Label 'Due Date,Posting Date';
        WriteoffsLbl: Label 'Application Writeoffs';
        PeriodSeparatorLbl: Label '-%1', Comment = 'Negating the period length: %1 is the period length';
        StatementCaptionLbl: Label 'Statement';
        PhoneNo_CompanyInfoCaptionLbl: Label 'Phone No.';
        VATRegNo_CompanyInfoCaptionLbl: Label 'VAT Registration No.';
        GiroNo_CompanyInfoCaptionLbl: Label 'Giro No.';
        BankName_CompanyInfoCaptionLbl: Label 'Bank';
        BankAccNo_CompanyInfoCaptionLbl: Label 'Account No.';
        No1_CustCaptionLbl: Label 'Customer No.';
        StartDateCaptionLbl: Label 'Starting Date';
        EndDateCaptionLbl: Label 'Ending Date';
        LastStatmntNo_CustCaptionLbl: Label 'Statement No.';
        PostDate_DtldCustLedgEntriesCaptionLbl: Label 'Posting Date';
        DueDate_CustLedgEntry2CaptionLbl: Label 'Due Date';
        CustBalanceCaptionLbl: Label 'Running Total';
        beforeCaptionLbl: Label '..before';
        CompanyInfoHomepageCaptionLbl: Label 'Home Page';
        CompanyInfoEmailCaptionLbl: Label 'Email';
        DocDateCaptionLbl: Label 'Document Date';
        Total_CaptionLbl: Label 'Total';
        BlankStartDateErr: Label 'Start Date must have a value.';
        BlankEndDateErr: Label 'End Date must have a value.';
        StartDateLaterTheEndDateErr: Label 'Start date must be earlier than End date.';
        CurrReportPageNoCaptionLbl: Label 'Page';
        GreetingLbl: Label 'Hello';
        ClosingLbl: Label 'Sincerely';
        BodyLbl: Label 'Thank you for your business. Your statement is attached to this message.';
        TelemetryCategoryTxt: Label 'Report', Locked = true;
        CustomerStatementReportGeneratedTxt: Label 'Customer Statement report generated.', Locked = true;
        LegalOfficeTxt, LegalOfficeLbl : Text;

    protected var
        CompanyInfo: Record "Company Information";
        CompanyInfo1: Record "Company Information";
        CompanyInfo2: Record "Company Information";
        CompanyInfo3: Record "Company Information";
        PeriodLength: DateFormula;
        Description: Text[100];
        CustomerAddress: array[8] of Text[100];
        CompanyAddress: array[8] of Text[100];
        CustBalance: Decimal;
        RemainingAmount: Decimal;
        IncludeAgingBand: Boolean;
        NumberOfCustLedgerEntryLines: Integer;
        StartDateTime: DateTime;
        FinishDateTime: DateTime;
        StartDate: Date;
        EndDate: Date;
        PrintAllHavingEntry: Boolean;
        PrintAllHavingBal: Boolean;
        PrintEntriesDue: Boolean;
        PrintUnappliedEntries: Boolean;
        PrintReversedEntries: Boolean;
        DateChoice: Option "Due Date","Posting Date";
        StatementStyle: Option "Balance","Open Item";

    local procedure GetDate(PostingDate: Date; DueDate: Date): Date
    begin
        if DateChoice = DateChoice::"Posting Date" then
            exit(PostingDate);

        exit(DueDate);
    end;

    local procedure UpdatePictures()
    begin
        CompanyInfo.Picture := SavedCompanyInfo.Picture;
        CompanyInfo1.Picture := SavedCompanyInfo1.Picture;
        CompanyInfo2.Picture := SavedCompanyInfo2.Picture;
        CompanyInfo3.Picture := SavedCompanyInfo3.Picture;
    end;

    local procedure CalcAgingBandDates()
    begin
        if not IncludeAgingBand then
            exit;
        if AgingBandEndingDate = 0D then
            Error(AgingBandEndErr);
        if Format(PeriodLength) = '' then
            Error(AgingBandPeriodErr);
        Evaluate(PeriodLength2, StrSubstNo(PeriodSeparatorLbl, PeriodLength));
        AgingDate[5] := AgingBandEndingDate;
        AgingDate[4] := CalcDate(PeriodLength2, AgingDate[5]);
        AgingDate[3] := CalcDate(PeriodLength2, AgingDate[4]);
        AgingDate[2] := CalcDate(PeriodLength2, AgingDate[3]);
        AgingDate[1] := CalcDate(PeriodLength2, AgingDate[2]);
        if AgingDate[2] <= AgingDate[1] then
            Error(PeriodLengthErr);

        AgingDateHeader1 := Format(AgingDate[1]) + ' - ' + Format(AgingDate[2]);
        AgingDateHeader2 := Format(AgingDate[2] + 1) + ' - ' + Format(AgingDate[3]);
        AgingDateHeader3 := Format(AgingDate[3] + 1) + ' - ' + Format(AgingDate[4]);
        AgingDateHeader4 := Format(AgingDate[4] + 1);
    end;

    local procedure UpdateBuffer(CurrencyCode: Code[10]; Date: Date; Amount: Decimal)
    var
        I: Integer;
        GoOn: Boolean;
    begin
        TempAgingBandBuf.Init();
        TempAgingBandBuf."Currency Code" := CurrencyCode;
        if not TempAgingBandBuf.Find() then
            TempAgingBandBuf.Insert();
        I := 1;
        GoOn := true;
        while (I <= 5) and GoOn do begin
            if Date <= AgingDate[I] then
                if I = 1 then begin
                    TempAgingBandBuf."Column 1 Amt." := TempAgingBandBuf."Column 1 Amt." + Amount;
                    GoOn := false;
                end;
            if Date <= AgingDate[I] then
                if I = 2 then begin
                    TempAgingBandBuf."Column 2 Amt." := TempAgingBandBuf."Column 2 Amt." + Amount;
                    GoOn := false;
                end;
            if Date <= AgingDate[I] then
                if I = 3 then begin
                    TempAgingBandBuf."Column 3 Amt." := TempAgingBandBuf."Column 3 Amt." + Amount;
                    GoOn := false;
                end;
            if Date <= AgingDate[I] then
                if I = 4 then begin
                    TempAgingBandBuf."Column 4 Amt." := TempAgingBandBuf."Column 4 Amt." + Amount;
                    GoOn := false;
                end;
            if Date <= AgingDate[I] then
                if I = 5 then begin
                    TempAgingBandBuf."Column 5 Amt." := TempAgingBandBuf."Column 5 Amt." + Amount;
                    GoOn := false;
                end;
            I := I + 1;
        end;
        TempAgingBandBuf.Modify();
    end;

    procedure SkipReversedUnapplied(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"): Boolean
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        if PrintReversedEntries and PrintUnappliedEntries then
            exit(false);
        if not PrintUnappliedEntries then
            if DetailedCustLedgEntry.Unapplied then
                exit(true);
        if not PrintReversedEntries then begin
            CustLedgEntry.Get(DetailedCustLedgEntry."Cust. Ledger Entry No.");
            if CustLedgEntry.Reversed then
                exit(true);
        end;
        exit(false);
    end;

    procedure InitializeRequest(NewPrintEntriesDue: Boolean; NewPrintAllHavingEntry: Boolean; NewPrintAllHavingBal: Boolean; NewPrintReversedEntries: Boolean; NewPrintUnappliedEntries: Boolean; NewIncludeAgingBand: Boolean; NewPeriodLength: Text[30]; NewDateChoice: Option "Due Date","Posting Date"; NewLogInteraction: Boolean; NewStartDate: Date; NewEndDate: Date)
    begin
        InitRequestPageDataInternal();

        PrintEntriesDue := NewPrintEntriesDue;
        PrintAllHavingEntry := NewPrintAllHavingEntry;
        PrintAllHavingBal := NewPrintAllHavingBal;
        PrintReversedEntries := NewPrintReversedEntries;
        PrintUnappliedEntries := NewPrintUnappliedEntries;
        IncludeAgingBand := NewIncludeAgingBand;
        Evaluate(PeriodLength, NewPeriodLength);
        DateChoice := NewDateChoice;
        LogInteraction := NewLogInteraction;
        StartDate := NewStartDate;
        EndDate := NewEndDate;
    end;

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody());
    end;

    procedure InitRequestPageDataInternal()
    begin
        if isInitialized then
            exit;

        isInitialized := true;

        if (not PrintAllHavingEntry) and (not PrintAllHavingBal) then
            PrintAllHavingBal := true;

        if Format(PeriodLength) = '' then
            Evaluate(PeriodLength, '<1M+CM>');

        UpdateReqPageParameters();

        ShowPrintIfEmailIsMissing := SupportedOutputMethod = SupportedOutputMethod::Email;
    end;

    local procedure InitInteractionLog()
    begin
        LogInteraction := SegManagement.FindInteractionTemplateCode(Enum::"Interaction Log Entry Document Type"::"Sales Stmnt.") <> '';
    end;

    local procedure VerifyDates()
    begin
        if StartDate = 0D then
            Error(BlankStartDateErr);
        if EndDate = 0D then
            Error(BlankEndDateErr);
        if StartDate > EndDate then
            Error(StartDateLaterTheEndDateErr);
    end;

    local procedure PopulateTempCurrencies()
    begin
        CustLedgerEntry.Reset();
        CustLedgerEntry.SetCurrentKey("Currency Code");
        TempCurrency2.Init();
        while CustLedgerEntry.FindFirst() do begin
            TempCurrency2.Code := CustLedgerEntry."Currency Code";
            TempCurrency2.Insert();
            CustLedgerEntry.SetFilter("Currency Code", '>%1', CustLedgerEntry."Currency Code");
        end;
    end;

    local procedure UpdateReqPageParameters()
    begin
        PrintAllHavingEntryEditable := StatementStyle <> StatementStyle::"Open Item";
        PrintAllHavingBalEditable := StatementStyle <> StatementStyle::"Open Item";
        PrintUnappliedEntriesEditable := StatementStyle <> StatementStyle::"Open Item";
        PrintReversedEntriesEditable := StatementStyle <> StatementStyle::"Open Item";

        if not PrintAllHavingEntryEditable then
            PrintAllHavingEntry := false;

        if not PrintAllHavingBalEditable then
            PrintAllHavingBal := true;

        if not PrintUnappliedEntriesEditable then
            PrintUnappliedEntries := true;

        if not PrintReversedEntriesEditable then
            PrintReversedEntries := false;
    end;

    local procedure LogReportTelemetry(StartDateTime: DateTime; FinishDateTime: DateTime; NumberOfLines: Integer)
    var
        Dimensions: Dictionary of [Text, Text];
        ReportDuration: BigInteger;
    begin
        ReportDuration := FinishDateTime - StartDateTime;
        Dimensions.Add('Category', TelemetryCategoryTxt);
        Dimensions.Add('ReportStartTime', Format(StartDateTime, 0, 9));
        Dimensions.Add('ReportFinishTime', Format(FinishDateTime, 0, 9));
        Dimensions.Add('ReportDuration', Format(ReportDuration));
        Dimensions.Add('NumberOfLines', Format(NumberOfLines));
        Session.LogMessage('0000FJK', CustomerStatementReportGeneratedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dimensions);
    end;

    local procedure ClearCompanyPicture()
    begin
        if FirstRecordPrinted then begin
            Clear(CompanyInfo.Picture);
            Clear(CompanyInfo1.Picture);
            Clear(CompanyInfo2.Picture);
            Clear(CompanyInfo3.Picture);
        end;
        FirstRecordPrinted := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDtldCustLedgEntriesOnPreDataItemOnAfterSetFilters(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDtldCustLedgEntriesOnAfterGetRecordnAfterGetCustLedgerEntry(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; CustLedgerEntry: Record "Cust. Ledger Entry"; var Skip: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCurrencyLoopOnAfterGetRecordOnAfterCustLedgerEntryCheckIsEmpty(Customer: Record Customer; var CustLedgerEntry: Record "Cust. Ledger Entry"; var PrintLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCustLedgEntry2OnPreDataItemOnAfterSetFilters(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitReportForGlobalVariable(var IsHandled: Boolean; var LegalOfficeTxt: Text; var LegalOfficeLbl: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCurrencyLoopOnAfterGetRecordOnAfterCalculateStartBalanceStatementTypeOpenItems(Customer: Record Customer; var CustLedgerEntryBalance: Record "Cust. Ledger Entry"; StartDate: Date; EndDate: Date; CurrencyCode: Code[10]; var StartBalance: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCurrencyLoopOnAfterGetRecordOnAfterCalculateStartBalanceStatementTypeBalance(Customer: Record Customer; StartDate: Date; EndDate: Date; CurrencyCode: Code[10]; var StartBalance: Decimal)
    begin
    end;
}

