// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Utilities;
using System.Utilities;

report 10042 "Customer Account Detail"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/CustomerAccountDetail.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer Account Detail';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
        {
            RequestFilterFields = "No.", "Search Name", "Customer Posting Group", "Date Filter";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(TIME; Time)
            {
            }
            column(CompanyInformation_Name; CompanyInformation.Name)
            {
            }
            column(USERID; UserId)
            {
            }
            column(Customer_TABLENAME__________FilterString; Customer.TableName + ': ' + FilterString)
            {
            }
            column(Cust__Ledger_Entry__TABLENAME__________FilterString2; "Cust. Ledger Entry".TableName + ': ' + FilterString2)
            {
            }
            column(Customer__No__; "No.")
            {
            }
            column(Customer_Name; Name)
            {
            }
            column(Customer__Phone_No__; "Phone No.")
            {
            }
            column(Customer_Contact; Contact)
            {
            }
            column(PrintAmountsInLocal; PrintAmountsInLocal)
            {
            }
            column(OnlyOnePerPage; OnlyOnePerPage)
            {
            }
            column(AllHavingBalance; AllHavingBalance)
            {
            }
            column(AdditionalInformation; AdditionalInformation)
            {
            }
            column(FilterString2; FilterString2)
            {
            }
            column(FilterString; FilterString)
            {
            }
            column(TempAppliedCustLedgEntryCount; TempAppliedCustLedgEntryCount)
            {
            }
            column(CustLedgerEntry2_Temp; CustLedgerEntry2_Temp)
            {
            }
            column(BalanceToPrintTemp; BalanceToPrintTemp)
            {
            }
            column(NewPagePerGroupNo; NewPagePerGroupNo)
            {
            }
            column(CurrencyCaptionForCurrencyCode; GetCurrencyCaptionCode("Currency Code"))
            {
            }
            column(ToDate; ToDate)
            {
            }
            column(EndingBalanceToPrint; EndingBalanceToPrint)
            {
            }
            column(FromDateToPrint; FromDateToPrint)
            {
            }
            column(BalanceToPrint; BalanceToPrint)
            {
            }
            column(TotalCustomers; TotalCustomers)
            {
            }
            column(TotalEntries; TotalEntries)
            {
            }
            column(DebitTotal; DebitTotal)
            {
            }
            column(CreditTotal; CreditTotal)
            {
            }
            column(BalanceTotal; BalanceTotal)
            {
            }
            column(Customer_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
            {
            }
            column(Customer_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
            {
            }
            column(Customer_Account_DetailCaption; Customer_Account_DetailCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Control8Caption; CaptionClassTranslate('101,1,' + Text003))
            {
            }
            column(Customers_without_balances_are_not_included_Caption; Customers_without_balances_are_not_included_CaptionLbl)
            {
            }
            column(Customer__No__Caption; Customer__No__CaptionLbl)
            {
            }
            column(DocumentCaption; DocumentCaptionLbl)
            {
            }
            column(Net_ChangeCaption; Net_ChangeCaptionLbl)
            {
            }
            column(Running_BalanceCaption; Running_BalanceCaptionLbl)
            {
            }
            column(DateCaption; DateCaptionLbl)
            {
            }
            column(Cust__Ledger_Entry__Document_Type_Caption; Cust__Ledger_Entry__Document_Type_CaptionLbl)
            {
            }
            column(Cust__Ledger_Entry_DescriptionCaption; "Cust. Ledger Entry".FieldCaption(Description))
            {
            }
            column(DebitsCaption; DebitsCaptionLbl)
            {
            }
            column(CreditsCaption; CreditsCaptionLbl)
            {
            }
            column(Cust__Ledger_Entry__Document_No__Caption; Cust__Ledger_Entry__Document_No__CaptionLbl)
            {
            }
            column(Cust__Ledger_Entry__Currency_Code_Caption; Cust__Ledger_Entry__Currency_Code_CaptionLbl)
            {
            }
            column(Cust__Ledger_Entry_AmountCaption; Cust__Ledger_Entry_AmountCaptionLbl)
            {
            }
            column(Cust__Ledger_Entry_OpenCaption; Cust__Ledger_Entry_OpenCaptionLbl)
            {
            }
            column(Phone_Caption; Phone_CaptionLbl)
            {
            }
            column(Contact_Caption; Contact_CaptionLbl)
            {
            }
            column(Ending_Balance__no_activity_Caption; Ending_Balance__no_activity_CaptionLbl)
            {
            }
            column(Beginning_BalanceCaption; Beginning_BalanceCaptionLbl)
            {
            }
            column(CustomersCaption; CustomersCaptionLbl)
            {
            }
            column(EntriesCaption; EntriesCaptionLbl)
            {
            }
            column(Control46Caption; CaptionClassTranslate('101,0,' + Text005))
            {
            }
            dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
            {
                DataItemLink = "Customer No." = field("No."), "Global Dimension 2 Code" = field("Global Dimension 2 Filter"), "Global Dimension 1 Code" = field("Global Dimension 1 Filter");
                DataItemTableView = sorting("Customer No.", "Posting Date");
                RequestFilterFields = "Document Type", Open;
                column(Cust__Ledger_Entry__Posting_Date_; "Posting Date")
                {
                }
                column(Cust__Ledger_Entry__Document_Type_; "Document Type")
                {
                }
                column(Cust__Ledger_Entry__Document_No__; "Document No.")
                {
                }
                column(Cust__Ledger_Entry_Description; Description)
                {
                }
                column(AmountToPrint; AmountToPrint)
                {
                }
                column(AmountToPrint_Control63; -AmountToPrint)
                {
                }
                column(BalanceToPrint_Control64; BalanceToPrint)
                {
                }
                column(Cust__Ledger_Entry__Currency_Code_; "Currency Code")
                {
                }
                column(Cust__Ledger_Entry_Amount; Amount)
                {
                }
                column(Cust__Ledger_Entry_Open; Format(Open))
                {
                }
                column(ToDate_Control69; ToDate)
                {
                }
                column(Ending_Balance_for_____Customer__No__; 'Ending Balance for ' + Customer."No.")
                {
                }
                column(TotalDebits; TotalDebits)
                {
                }
                column(TotalCredits; TotalCredits)
                {
                }
                column(BalanceToPrint_Control73; BalanceToPrint)
                {
                }
                column(Customer_TABLENAME_____Total_for_____Customer__No__; Customer.TableName + ' Total for ' + Customer."No.")
                {
                }
                column(TotalDebits_Control77; TotalDebits)
                {
                }
                column(TotalCredits_Control78; TotalCredits)
                {
                }
                column(BalanceToPrint_Control79; BalanceToPrint)
                {
                }
                column(Cust__Ledger_Entry_Entry_No_; "Entry No.")
                {
                }
                column(Cust__Ledger_Entry_Customer_No_; "Customer No.")
                {
                }
                column(Cust__Ledger_Entry_Global_Dimension_2_Code; "Global Dimension 2 Code")
                {
                }
                column(Cust__Ledger_Entry_Global_Dimension_1_Code; "Global Dimension 1 Code")
                {
                }
                dataitem(OtherInfo; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(Cust__Ledger_Entry___Entry_No__; "Cust. Ledger Entry"."Entry No.")
                    {
                    }
                    column(DueDateToPrint; DueDateToPrint)
                    {
                    }
                    column(Cust__Ledger_Entry___Pmt__Discount_Date_; "Cust. Ledger Entry"."Pmt. Discount Date")
                    {
                    }
                    column(Cust__Ledger_Entry___Original_Pmt__Disc__Possible_; "Cust. Ledger Entry"."Original Pmt. Disc. Possible")
                    {
                    }
                    column(Cust__Ledger_Entry___Remaining_Amount_; "Cust. Ledger Entry"."Remaining Amount")
                    {
                    }
                    column(FORMAT_TempAppliedCustLedgEntry__Document_Type__; Format(TempAppliedCustLedgEntry."Document Type"))
                    {
                    }
                    column(TempAppliedCustLedgEntry__Document_No__; TempAppliedCustLedgEntry."Document No.")
                    {
                    }
                    column(TempAppliedCustLedgEntry__Entry_No__; TempAppliedCustLedgEntry."Entry No.")
                    {
                    }
                    column(OtherInfo_Number; Number)
                    {
                    }
                    column(FORMAT_TempAppliedCustLedgEntry__Document_Type___Control82Caption; FORMAT_TempAppliedCustLedgEntry__Document_Type___Control82CaptionLbl)
                    {
                    }
                    column(Apply_ToCaption; Apply_ToCaptionLbl)
                    {
                    }
                    column(TempAppliedCustLedgEntry__Document_No___Control83Caption; TempAppliedCustLedgEntry__Document_No___Control83CaptionLbl)
                    {
                    }
                    column(Due_DateCaption; Due_DateCaptionLbl)
                    {
                    }
                    column(Cust__Ledger_Entry___Remaining_Amount_Caption; Cust__Ledger_Entry___Remaining_Amount_CaptionLbl)
                    {
                    }
                    column(Cust__Ledger_Entry___Pmt__Discount_Date_Caption; Cust__Ledger_Entry___Pmt__Discount_Date_CaptionLbl)
                    {
                    }
                    column(Cust__Ledger_Entry___Original_Pmt__Disc__Possible_Caption; Cust__Ledger_Entry___Original_Pmt__Disc__Possible_CaptionLbl)
                    {
                    }
                    column(TempAppliedCustLedgEntry__Entry_No___Control65Caption; TempAppliedCustLedgEntry__Entry_No___Control65CaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if not TempAppliedCustLedgEntry.Find('-') then
                            Clear(TempAppliedCustLedgEntry);

                        if "Cust. Ledger Entry"."Document Type" <> "Cust. Ledger Entry"."Document Type"::Payment then
                            DueDateToPrint := "Cust. Ledger Entry"."Due Date"
                        else
                            DueDateToPrint := 0D;

                        if "Cust. Ledger Entry"."Pmt. Discount Date" < ToDate then
                            "Cust. Ledger Entry"."Original Pmt. Disc. Possible" := 0;

                        if "Cust. Ledger Entry"."Original Pmt. Disc. Possible" = 0 then
                            "Cust. Ledger Entry"."Pmt. Discount Date" := 0D;

                        TempAppliedCustLedgEntryCount := TempAppliedCustLedgEntry.Count();
                    end;

                    trigger OnPreDataItem()
                    begin
                        if not AdditionalInformation then
                            CurrReport.Break();
                    end;
                }
                dataitem(AppliedEntries; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(TempAppliedCustLedgEntry__Document_No___Control83; TempAppliedCustLedgEntry."Document No.")
                    {
                    }
                    column(FORMAT_TempAppliedCustLedgEntry__Document_Type___Control82; Format(TempAppliedCustLedgEntry."Document Type"))
                    {
                    }
                    column(TempAppliedCustLedgEntry__Entry_No___Control65; TempAppliedCustLedgEntry."Entry No.")
                    {
                    }
                    column(AppliedEntries_Number; Number)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        TempAppliedCustLedgEntry.Next();
                    end;

                    trigger OnPreDataItem()
                    begin
                        if not AdditionalInformation then
                            CurrReport.Break();
                        SetRange(Number, 2, TempAppliedCustLedgEntry.Count);
                    end;
                }
                dataitem(Blank; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));

                    trigger OnPreDataItem()
                    begin
                        if not AdditionalInformation then
                            CurrReport.Break();
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    CalcFields(Amount, "Amount (LCY)", "Remaining Amount");
                    if not PrintAmountsInLocal then
                        AmountToPrint := "Amount (LCY)"
                    else
                        if "Currency Code" = Currency.Code then
                            AmountToPrint := Amount
                        else
                            AmountToPrint :=
                              Round(
                                CurrExchRate.ExchangeAmtFCYToFCY(
                                  ToDate,
                                  "Currency Code",
                                  Currency.Code,
                                  Amount),
                                Currency."Amount Rounding Precision");

                    if Amount > 0 then begin
                        TotalDebits := TotalDebits + AmountToPrint;
                        DebitTotal := DebitTotal + "Amount (LCY)";
                    end
                    else begin
                        TotalCredits := TotalCredits - AmountToPrint;
                        CreditTotal := CreditTotal - "Amount (LCY)";
                    end;

                    BalanceToPrintTemp := BalanceToPrint;

                    BalanceToPrint := BalanceToPrint + AmountToPrint;

                    TotalEntries := TotalEntries + 1;
                    BalanceTotal := BalanceTotal + "Amount (LCY)";

                    EntryAppMgt.GetAppliedCustEntries(TempAppliedCustLedgEntry, "Cust. Ledger Entry", false);
                end;

                trigger OnPreDataItem()
                begin
                    TotalDebits := 0;
                    TotalCredits := 0;
                    SetRange("Posting Date", FromDate, ToDate);
                    SetRange("Date Filter", FromDate, ToDate);
                end;
            }

            trigger OnAfterGetRecord()
            var
                Cust: Record Customer;
            begin
                if FromDate <> 0D then
                    FromDateToPrint := FromDate - 1
                else
                    FromDateToPrint := 0D;

                if Currency.ReadPermission then begin
                    TempCurrency.DeleteAll();
                    CustLedgerEntry2.Reset();
                    if not CustLedgerEntry2.SetCurrentKey("Customer No.", "Currency Code", "Posting Date") then
                        CustLedgerEntry2.SetCurrentKey("Customer No.", "Posting Date", "Currency Code");
                    CustLedgerEntry2.SetRange("Customer No.", Customer."No.");
                    CustLedgerEntry2.SetFilter("Currency Code", '=%1', '');
                    if CustLedgerEntry2.FindFirst() then begin
                        TempCurrency.Init();
                        TempCurrency.Code := '';
                        TempCurrency.Description := GLSetup."LCY Code";
                        TempCurrency.Insert();
                    end;
                    if Currency.Find('-') then
                        repeat
                            CustLedgerEntry2.SetRange("Currency Code", Currency.Code);
                            if CustLedgerEntry2.FindFirst() then begin
                                TempCurrency.Init();
                                TempCurrency.Code := Currency.Code;
                                TempCurrency.Description := Currency.Description;
                                TempCurrency.Insert();
                            end;
                        until Currency.Next() = 0;
                    GetCurrencyRecord(Currency, "Currency Code");
                end;

                /* If Customer Ledger Filters are being used, we no longer attempt to keep a
                  running balance, and instead just keep a total of selected entries.
                  Otherwise, we need to get beginning balances to keep running balances.  */
                if FilterString2 <> '' then begin
                    BalanceToPrint := 0;
                    EndingBalanceToPrint := 0;
                end else begin
                    SetRange("Date Filter", 0D, ToDate);
                    if PrintAmountsInLocal then begin
                        EndingBalanceToPrint := 0;
                        if TempCurrency.Find('-') then
                            repeat
                                SetRange("Currency Filter", TempCurrency.Code);
                                CalcFields("Net Change");
                                "Net Change" := CurrExchRate.ExchangeAmtFCYToFCY(
                                    ToDate,
                                    TempCurrency.Code,
                                    Currency.Code,
                                    "Net Change");
                                EndingBalanceToPrint := EndingBalanceToPrint + "Net Change";
                            until TempCurrency.Next() = 0;
                        SetRange("Currency Filter");
                        EndingBalanceToPrint := Round(EndingBalanceToPrint, Currency."Amount Rounding Precision");
                    end else begin
                        CalcFields("Net Change (LCY)");
                        EndingBalanceToPrint := "Net Change (LCY)";
                    end;

                    SetRange("Date Filter", 0D, FromDateToPrint);
                    CalcFields("Net Change (LCY)");
                    if PrintAmountsInLocal then begin
                        BalanceToPrint := 0;
                        if TempCurrency.Find('-') then
                            repeat
                                SetRange("Currency Filter", TempCurrency.Code);
                                CalcFields("Net Change");
                                "Net Change" := CurrExchRate.ExchangeAmtFCYToFCY(
                                    ToDate,
                                    TempCurrency.Code,
                                    Currency.Code,
                                    "Net Change");
                                BalanceToPrint := BalanceToPrint + "Net Change";
                            until TempCurrency.Next() = 0;
                        SetRange("Currency Filter");
                        BalanceToPrint := Round(BalanceToPrint, Currency."Amount Rounding Precision");
                    end else
                        BalanceToPrint := "Net Change (LCY)";
                end;

                if FilterString2 = '' then
                    if AllHavingBalance and
                       (BalanceToPrint = 0) and
                       (EndingBalanceToPrint = 0)
                    then
                        CurrReport.Skip();

                if FilterString2 = '' then begin
                    TotalCustomers := TotalCustomers + 1;  // count if there are no ledger filters
                    CustLedgerEntry2.Reset();
                    CustLedgerEntry2.SetCurrentKey("Customer No.");
                    CustLedgerEntry2.SetRange("Posting Date", FromDate, ToDate);
                    CustLedgerEntry2.SetRange("Customer No.", "No.");
                    Cust.Get("No.");
                    Cust.CopyFilters(Customer);
                    Cust.SetFilter("Date Filter", '<%1', FromDate);
                    Cust.CalcFields("Net Change (LCY)");
                    BalanceTotal := BalanceTotal + Cust."Net Change (LCY)";
                end;

                CustLedgerEntry2_Temp := CustLedgerEntry2.FindFirst();

                if OnlyOnePerPage then
                    NewPagePerGroupNo := NewPagePerGroupNo + 1;

            end;

            trigger OnPreDataItem()
            begin
                DateFilter := GetFilter("Date Filter");
                if DateFilter <> '' then begin
                    FromDate := GetRangeMin("Date Filter");
                    ToDate := GetRangeMax("Date Filter");
                end else begin
                    FromDate := 0D;
                    ToDate := WorkDate();
                    SetRange("Date Filter", FromDate, ToDate);
                end;

                if FilterString2 <> '' then
                    TotalCustomers := TotalCustomers + 1;
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
                    field(PrintAmountsInLocal; PrintAmountsInLocal)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Print Amounts in Customer''s Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies if amounts are printed in the customer''s currency. Clear the check box to print all amounts in US dollars.';
                    }
                    field(OnlyOnePerPage; OnlyOnePerPage)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Page per Account';
                        ToolTip = 'Specifies if you want to print each account on a separate page. Each account will begin at the top of the following page. Otherwise, each account will follow the previous account on the current page.';
                    }
                    field(AllHavingBalance; AllHavingBalance)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Acc. with Balances Only';
                        ToolTip = 'Specifies that you want to include all accounts that have a balance other than zero, even if there has been no activity in the period. This option cannot be used if you are also entering Customer Ledger Entry Filters such as the Open filter.';
                    }
                    group("Print Additional Details")
                    {
                        Caption = 'Print Additional Details';
                        field(AdditionalInformation; AdditionalInformation)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = '  (Terms, Applications, etc.)';
                            ToolTip = 'Specifies that you want to include transaction information regarding payment terms, what entries this entry was applied to, and the remaining (open) amount. If you do not select this field, the report will not contain this additional information.';
                        }
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
        CompanyInformation.Get();
        GLSetup.Get();
        FilterString := Customer.GetFilters();
        FilterString2 := "Cust. Ledger Entry".GetFilters();
        if (FilterString2 <> '') and AllHavingBalance then
            Error(Text000
              + Text001);
    end;

    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        TempAppliedCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        CompanyInformation: Record "Company Information";
        Currency: Record Currency;
        TempCurrency: Record Currency temporary;
        CurrExchRate: Record "Currency Exchange Rate";
        GLSetup: Record "General Ledger Setup";
        EntryAppMgt: Codeunit "Entry Application Management";
        FilterString: Text;
        FilterString2: Text;
        DateFilter: Text;
        PrintAmountsInLocal: Boolean;
        AllHavingBalance: Boolean;
        OnlyOnePerPage: Boolean;
        AdditionalInformation: Boolean;
        AmountToPrint: Decimal;
        TotalDebits: Decimal;
        TotalCredits: Decimal;
        BalanceToPrint: Decimal;
        EndingBalanceToPrint: Decimal;
        DebitTotal: Decimal;
        CreditTotal: Decimal;
        BalanceTotal: Decimal;
        FromDate: Date;
        ToDate: Date;
        FromDateToPrint: Date;
        DueDateToPrint: Date;
        TotalCustomers: Integer;
        TotalEntries: Integer;
        Text000: Label 'Do not select Accounts with Balances if you';
        Text001: Label 'are also setting Customer Ledger Entry Filters.';
        Text003: Label 'Amounts are in the customer''s local currency (report totals are in %1).';
        Text004: Label 'Amounts are in %1';
        Text005: Label 'Report Totals (%1)';
        TempAppliedCustLedgEntryCount: Integer;
        CustLedgerEntry2_Temp: Boolean;
        BalanceToPrintTemp: Decimal;
        NewPagePerGroupNo: Integer;
        Customer_Account_DetailCaptionLbl: Label 'Customer Account Detail';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Customers_without_balances_are_not_included_CaptionLbl: Label 'Customers without balances are not included.';
        Customer__No__CaptionLbl: Label 'Customer';
        DocumentCaptionLbl: Label 'Document';
        Net_ChangeCaptionLbl: Label 'Net Change';
        Running_BalanceCaptionLbl: Label 'Running Balance';
        DateCaptionLbl: Label 'Date';
        Cust__Ledger_Entry__Document_Type_CaptionLbl: Label 'Type';
        DebitsCaptionLbl: Label 'Debits';
        CreditsCaptionLbl: Label 'Credits';
        Cust__Ledger_Entry__Document_No__CaptionLbl: Label 'Number';
        Cust__Ledger_Entry__Currency_Code_CaptionLbl: Label 'Transaction Currency';
        Cust__Ledger_Entry_AmountCaptionLbl: Label 'Transaction Amount';
        Cust__Ledger_Entry_OpenCaptionLbl: Label 'Open';
        Phone_CaptionLbl: Label 'Phone:';
        Contact_CaptionLbl: Label 'Contact:';
        Ending_Balance__no_activity_CaptionLbl: Label 'Ending Balance (no activity)';
        Beginning_BalanceCaptionLbl: Label 'Beginning Balance';
        CustomersCaptionLbl: Label 'Customers';
        EntriesCaptionLbl: Label 'Entries';
        FORMAT_TempAppliedCustLedgEntry__Document_Type___Control82CaptionLbl: Label 'Type';
        Apply_ToCaptionLbl: Label 'Apply To';
        TempAppliedCustLedgEntry__Document_No___Control83CaptionLbl: Label 'Number';
        Due_DateCaptionLbl: Label 'Due Date';
        Cust__Ledger_Entry___Remaining_Amount_CaptionLbl: Label 'Remaining Amount';
        Cust__Ledger_Entry___Pmt__Discount_Date_CaptionLbl: Label 'Discount Date';
        Cust__Ledger_Entry___Original_Pmt__Disc__Possible_CaptionLbl: Label 'Pmt. Disc. Possible';
        TempAppliedCustLedgEntry__Entry_No___Control65CaptionLbl: Label 'Entry No.';

    local procedure GetCurrencyRecord(var Currency: Record Currency; CurrencyCode: Code[10])
    begin
        if CurrencyCode = '' then begin
            Clear(Currency);
            Currency.Description := GLSetup."LCY Code";
            Currency."Amount Rounding Precision" := GLSetup."Amount Rounding Precision";
        end else
            if Currency.Code <> CurrencyCode then
                Currency.Get(CurrencyCode);
    end;

    local procedure GetCurrencyCaptionCode(CurrencyCode: Code[10]): Text[80]
    begin
        if PrintAmountsInLocal then begin
            if CurrencyCode = '' then
                exit('101,1,' + Text004);

            GetCurrencyRecord(Currency, CurrencyCode);
            exit(StrSubstNo(Text004, Currency.Description));
        end;
        exit('');
    end;
}

