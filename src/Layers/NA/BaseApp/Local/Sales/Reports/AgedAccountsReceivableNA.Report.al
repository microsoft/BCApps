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
using System.IO;
using System.Utilities;

report 10040 "Aged Accounts Receivable NA"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/AgedAccountsReceivableNA.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Aged Accounts Receivable';
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem(Header; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(FORMAT_TODAY_0_4_; Format(Today(), 0, 4))
            {
            }
            column(TIME; Time())
            {
            }
            column(CompanyInformation_Name; CompanyInformation.Name)
            {
            }
            column(USERID; UserId())
            {
            }
            column(PrintDetail; PrintDetail)
            {
            }
            column(PrintToExcel; PrintToExcel)
            {
            }
            column(PrintAmountsInLocal; PrintAmountsInLocal)
            {
            }
            column(ShowAllForOverdue; ShowAllForOverdue)
            {
            }
            column(FilterString; FilterString)
            {
            }
            column(Aged_Accounts_ReceivableCaption; Aged_Accounts_ReceivableCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Aged_byCaption; Aged_byCaptionLbl)
            {
            }
            column(Control11Caption; CaptionClassTranslate('101,1,' + AmountsAreIn2Lbl))
            {
            }
            column(AmountDueToPrint_Control74Caption; AmountDueToPrint_Control74CaptionLbl)
            {
            }
            column(Credit_LimitCaption; Credit_LimitCaptionLbl)
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(Cust__Ledger_Entry___Document_No__Caption; Cust__Ledger_Entry___Document_No__CaptionLbl)
            {
            }
            column(Cust__Ledger_Entry__DescriptionCaption; Cust__Ledger_Entry__DescriptionCaptionLbl)
            {
            }
            column(Cust__Ledger_Entry___Document_Type_Caption; Cust__Ledger_Entry___Document_Type_CaptionLbl)
            {
            }
            column(Cust__Ledger_Entry___Currency_Code_Caption; Cust__Ledger_Entry___Currency_Code_CaptionLbl)
            {
            }
            column(DocumentCaption; DocumentCaptionLbl)
            {
            }
            column(Control47Caption; CaptionClassTranslate('101,0,' + ReportTotalAmountDueLbl))
            {
            }
            column(Control8Caption; CaptionClassTranslate('101,0,' + ReportTotalAmountDueLbl))
            {
            }
            column(Balance_ForwardCaption; Balance_ForwardCaptionLbl)
            {
            }
            column(Balance_to_Carry_ForwardCaption; Balance_to_Carry_ForwardCaptionLbl)
            {
            }
            column(Total_Amount_DueCaption; Total_Amount_DueCaptionLbl)
            {
            }
            column(Total_Amount_DueCaption_Control86; Total_Amount_DueCaption_Control86Lbl)
            {
            }
            column(Credit_Limit_Caption; Credit_Limit_CaptionLbl)
            {
            }
            column(Customer__No__Caption; Customer.FieldCaption("No."))
            {
            }
            column(Customer_NameCaption; Customer.FieldCaption(Name))
            {
            }
            column(Customer__Phone_No__Caption; Customer.FieldCaption("Phone No."))
            {
            }
            column(Customer_ContactCaption; Customer.FieldCaption(Contact))
            {
            }
            column(Control1020000Caption; CaptionClassTranslate(GetCurrencyCaptionCode(Customer."Currency Code")))
            {
            }
            column(SubTitle; SubTitle)
            {
            }
            column(DateTitle; DateTitle)
            {
            }
            column(ShortDateTitle; ShortDateTitle)
            {
            }
            column(Customer_TABLECAPTION__________FilterString; Customer.TableCaption() + ': ' + FilterString)
            {
            }
            column(ColumnHeadHead; ColumnHeadHead)
            {
            }
            column(ColumnHead_1_; ColumnHead[1])
            {
            }
            column(ColumnHead_2_; ColumnHead[2])
            {
            }
            column(ColumnHead_3_; ColumnHead[3])
            {
            }
            column(ColumnHead_4_; ColumnHead[4])
            {
            }
            column(GrandTotalBalanceDue_; GrandTotalBalanceDue)
            {
            }
            column(GrandBalanceDue_1_; GrandBalanceDue[1])
            {
            }
            column(GrandBalanceDue_2_; GrandBalanceDue[2])
            {
            }
            column(GrandBalanceDue_3_; GrandBalanceDue[3])
            {
            }
            column(GrandBalanceDue_4_; GrandBalanceDue[4])
            {
            }
            dataitem(Customer; Customer)
            {
                PrintOnlyIfDetail = true;
                RequestFilterFields = "No.", "Customer Posting Group", "Payment Terms Code", "Salesperson Code";
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
                column(BlockedDescription; BlockedDescription)
                {
                }
                column(OverLimitDescription; OverLimitDescription)
                {
                }
                column(TotalBalanceDue__; "TotalBalanceDue$")
                {
                }
                column(BalanceDue___1_; "BalanceDue$"[1])
                {
                }
                column(BalanceDue___2_; "BalanceDue$"[2])
                {
                }
                column(BalanceDue___3_; "BalanceDue$"[3])
                {
                }
                column(BalanceDue___4_; "BalanceDue$"[4])
                {
                }
                column(PercentString_1_; PercentString[1])
                {
                }
                column(PercentString_2_; PercentString[2])
                {
                }
                column(PercentString_3_; PercentString[3])
                {
                }
                column(PercentString_4_; PercentString[4])
                {
                }
                column(Customer_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
                {
                }
                column(Customer_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
                {
                }
                dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
                {
                    DataItemLink = "Customer No." = field("No."), "Global Dimension 2 Code" = field("Global Dimension 2 Filter"), "Global Dimension 1 Code" = field("Global Dimension 1 Filter");
                    DataItemTableView = sorting("Customer No.", Open, Positive, "Due Date", "Currency Code");

                    trigger OnAfterGetRecord()
                    begin
                        InsertTemp("Cust. Ledger Entry");
                        CurrReport.Skip();    // this fools the system into thinking that no details "printed"...yet
                    end;

                    trigger OnPreDataItem()
                    begin
                        // Find ledger entries which are posted before the date of the aging
                        SetRange("Posting Date", 0D, PeriodEndingDate[1]);

                        if (Format(ShowOnlyOverDueBy) <> '') and not ShowAllForOverdue then
                            SetRange("Due Date", 0D, CalculatedDate);

                        SetRange("Date Filter", 0D, PeriodEndingDate[1]);
                        SetAutoCalcFields("Remaining Amount");
                        SetFilter("Remaining Amount", '<>0');
                    end;
                }
                dataitem(Totals; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(AmountDueToPrint; AmountDueToPrint)
                    {
                    }
                    column(AmountDue_1_; AmountDue[1])
                    {
                    }
                    column(AmountDue_2_; AmountDue[2])
                    {
                    }
                    column(AmountDue_3_; AmountDue[3])
                    {
                    }
                    column(AmountDue_4_; AmountDue[4])
                    {
                    }
                    column(AgingDate; AgingDate)
                    {
                    }
                    column(Cust__Ledger_Entry__Description; "Cust. Ledger Entry".Description)
                    {
                    }
                    column(Cust__Ledger_Entry___Document_Type_; "Cust. Ledger Entry"."Document Type")
                    {
                    }
                    column(Cust__Ledger_Entry___Document_No__; "Cust. Ledger Entry"."Document No.")
                    {
                    }
                    column(AmountDueToPrint_Control63; AmountDueToPrint)
                    {
                    }
                    column(Cust__Ledger_Entry___Currency_Code_; "Cust. Ledger Entry"."Currency Code")
                    {
                    }
                    column(CreditLimitToPrint; CreditLimitToPrint)
                    {
                    }
                    column(Customer__No___Control80; Customer."No.")
                    {
                    }
                    column(AmountDueToPrint_Control81; AmountDueToPrint)
                    {
                    }
                    column(Totals_Number; Number)
                    {
                    }
                    column(Control1020001Caption; CaptionClassTranslate(GetCurrencyCaptionCode(Customer."Currency Code")))
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        CalcPercents(AmountDueToPrint, AmountDue);
                        Clear(AmountDue);
                        AmountDueToPrint := 0;
                        if Number = 1 then
                            TempCustLedgEntry.Find('-')
                        else
                            TempCustLedgEntry.Next();
                        TempCustLedgEntry.SetRange("Date Filter", 0D, PeriodEndingDate[1]);
                        TempCustLedgEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
                        if TempCustLedgEntry."Remaining Amount" = 0 then
                            CurrReport.Skip();
                        if TempCustLedgEntry."Currency Code" <> '' then
                            TempCustLedgEntry."Remaining Amt. (LCY)" :=
                              Round(
                                CurrExchRate.ExchangeAmtFCYToFCY(
                                  PeriodEndingDate[1],
                                  TempCustLedgEntry."Currency Code",
                                  '',
                                  TempCustLedgEntry."Remaining Amount"));
                        if PrintAmountsInLocal then begin
                            TempCustLedgEntry."Remaining Amount" :=
                              Round(
                                CurrExchRate.ExchangeAmtFCYToFCY(
                                  PeriodEndingDate[1],
                                  TempCustLedgEntry."Currency Code",
                                  Customer."Currency Code",
                                  TempCustLedgEntry."Remaining Amount"),
                                Currency."Amount Rounding Precision");
                            AmountDueToPrint := TempCustLedgEntry."Remaining Amount";
                        end else
                            AmountDueToPrint := TempCustLedgEntry."Remaining Amt. (LCY)";

                        case AgingMethod of
                            AgingMethod::"Due Date":
                                AgingDate := TempCustLedgEntry."Due Date";
                            AgingMethod::"Trans Date":
                                AgingDate := TempCustLedgEntry."Posting Date";
                            AgingMethod::"Document Date":
                                AgingDate := TempCustLedgEntry."Document Date";
                        end;
                        j := 0;
                        while AgingDate < PeriodEndingDate[j + 1] do
                            j := j + 1;
                        if j = 0 then
                            j := 1;

                        AmountDue[j] := AmountDueToPrint;
                        "BalanceDue$"[j] := "BalanceDue$"[j] + TempCustLedgEntry."Remaining Amt. (LCY)";

                        CustTotAmountDue[j] := CustTotAmountDue[j] + AmountDueToPrint;
                        CustTotAmountDueToPrint := CustTotAmountDueToPrint + AmountDueToPrint;

                        "TotalBalanceDue$" := 0;
                        for j := 1 to 4 do
                            "TotalBalanceDue$" := "TotalBalanceDue$" + "BalanceDue$"[j];
                        CalcPercents("TotalBalanceDue$", "BalanceDue$");

                        "Cust. Ledger Entry" := TempCustLedgEntry;

                        // Do NOT use the following fields in the sections:
                        // "Applied-To Doc. Type"
                        // "Applied-To Doc. No."
                        // Open
                        // "Paym. Disc. Taken"
                        // "Closed by Entry No."
                        // "Closed at Date"
                        // "Closed by Amount"

                        TotalNumberOfEntries -= 1;
                        if TotalNumberOfEntries = 0 then begin
                            for j := 1 to 4 do
                                GrandBalanceDue[j] += "BalanceDue$"[j];
                            GrandTotalBalanceDue += "TotalBalanceDue$";
                        end;

                        if PrintDetail and PrintToExcel then
                            MakeExcelDataBody();

                        NumberOfLines += 1;
                    end;

                    trigger OnPostDataItem()
                    begin
                        if TempCustLedgEntry.Count() > 0 then begin
                            for j := 1 to 4 do
                                AmountDue[j] := CustTotAmountDue[j];
                            AmountDueToPrint := CustTotAmountDueToPrint;
                            if not PrintDetail and PrintToExcel then
                                MakeExcelDataBody();
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        Clear(AmountDueToPrint);
                        Clear(AmountDue);
                        SetRange(Number, 1, TempCustLedgEntry.Count());
                        TempCustLedgEntry.SetCurrentKey("Customer No.", "Posting Date");
                        Clear(CustTotAmountDue);
                        CustTotAmountDueToPrint := 0;
                        TotalNumberOfEntries := TempCustLedgEntry.Count();
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    CustLedgEntry: Record "Cust. Ledger Entry";
                begin
                    if not TempCustomer.get("No.") then
                        CurrReport.Skip();

                    Clear("BalanceDue$");
                    if PrintAmountsInLocal then begin
                        GetCurrencyRecord(Currency, "Currency Code");
                        CurrencyFactor := CurrExchRate.ExchangeRate(PeriodEndingDate[1], "Currency Code");
                    end;

                    if "Privacy Blocked" then
                        BlockedDescription := PrivacyBlockedTxt
                    else
                        BlockedDescription := '';
                    if Blocked <> Blocked::" " then
                        BlockedDescription := StrSubstNo(CustomerBlockedLbl, Blocked)
                    else
                        BlockedDescription := '';

                    if "Credit Limit (LCY)" = 0 then begin
                        CreditLimitToPrint := NoLimitLbl;
                        OverLimitDescription := '';
                    end else begin
                        SetRange("Date Filter", 0D, PeriodEndingDate[1]);
                        CalcFields("Net Change (LCY)");
                        if "Net Change (LCY)" > "Credit Limit (LCY)" then
                            OverLimitDescription := OverLimitLbl
                        else
                            OverLimitDescription := '';
                        if PrintAmountsInLocal and ("Currency Code" <> '') then
                            "Credit Limit (LCY)" :=
                              CurrExchRate.ExchangeAmtLCYToFCY(PeriodEndingDate[1], "Currency Code", "Credit Limit (LCY)", CurrencyFactor);
                        CreditLimitToPrint := Format(Round("Credit Limit (LCY)", 1));
                    end;

                    if not TempCustLedgEntry.IsEmpty() then
                        TempCustLedgEntry.DeleteAll();

                    if Format(ShowOnlyOverDueBy) <> '' then
                        CalculatedDate := CalcDate(ShowOnlyOverDueBy, PeriodEndingDate[1]);

                    if ShowAllForOverdue and (Format(ShowOnlyOverDueBy) <> '') then begin
                        CustLedgEntry.SetRange("Customer No.", "No.");
                        CustLedgEntry.SetRange(Open, true);
                        CustLedgEntry.SetRange("Due Date", 0D, CalculatedDate);
                        if CustLedgEntry.IsEmpty() then
                            CurrReport.Skip();
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    NumCustLedgEntriesperCust.SetFilter(Customer_No, GetFilter("No."));
                    if NumCustLedgEntriesperCust.Open() then
                        while NumCustLedgEntriesperCust.Read() do
                            if not TempCustomer.get(NumCustLedgEntriesperCust.Customer_No) then begin
                                TempCustomer."No." := NumCustLedgEntriesperCust.Customer_No;
                                TempCustomer.Insert();
                            end;
                end;
            }
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
                    field(AgedAsOf; PeriodEndingDate[1])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Aged as of';
                        ToolTip = 'Specifies, in the MMDDYY format, the date that aging is based on. Transactions posted after this date will not be included in the report. The default is today''s date.';

                        trigger OnValidate()
                        begin
                            if PeriodEndingDate[1] = 0D then
                                PeriodEndingDate[1] := WorkDate();
                        end;
                    }
                    field(AgedBy; AgingMethod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Aged by';
                        OptionCaption = 'Trans Date,Due Date,Document Date';
                        ToolTip = 'Specifies how aging is calculated. Due Date: Aging is calculated by the number of days that the transaction is overdue. Trans Date: Aging is calculated by the number of days since the transaction posting date. Document Date: Aging is calculated by the number of days since the document date.';

                        trigger OnValidate()
                        begin
                            if AgingMethod in [AgingMethod::"Document Date", AgingMethod::"Trans Date"] then begin
                                Evaluate(ShowOnlyOverDueBy, '');
                                ShowAllForOverdue := false;
                            end;
                        end;
                    }
                    field(LengthOfAgingPeriods; PeriodCalculation)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Length of Aging Periods';
                        ToolTip = 'Specifies the length of each of the aging periods. For example, enter 30D to base aging on 30-day intervals.';

                        trigger OnValidate()
                        begin
                            if Format(PeriodCalculation) = '' then
                                Error(PeriodCalculationRequiredLbl);
                        end;
                    }
                    field(ShowOnlyOverDueByControl; ShowOnlyOverDueBy)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show If Overdue By';
                        ToolTip = 'Specifies the length of the period that you would like to use for the overdue balance.';

                        trigger OnValidate()
                        begin
                            if AgingMethod <> AgingMethod::"Due Date" then
                                Error(OnlyForDueDateLbl);
                            if Format(ShowOnlyOverDueBy) = '' then
                                ShowAllForOverdue := false;
                        end;
                    }
                    field(ShowAllForOverdueControl; ShowAllForOverdue)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show All for Overdue Customer';
                        ToolTip = 'Specifies if you want to include the open customer ledger entries that are overdue. These entries will be calculated based on the period in the Show if Overdue By field. If the Show All for Overdue by Customer field is selected, then you must enter a date in the Aged by field and a date in the Show if Overdue By field to show overdue customer ledger entries.';

                        trigger OnValidate()
                        begin
                            if AgingMethod <> AgingMethod::"Due Date" then
                                Error(OnlyForDueDateLbl);
                            if ShowAllForOverdue and (Format(ShowOnlyOverDueBy) = '') then
                                Error(ShowOnlyOverdueByLbl);
                        end;
                    }
                    field(PrintAmountsInVendorsCurrency; PrintAmountsInLocal)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Print Amounts in Customer''s Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies if amounts are printed in the customer''s currency. Clear the check box to print all amounts in US dollars.';
                    }
                    field(PrintDetailControl; PrintDetail)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Detail';
                        ToolTip = 'Specifies if individual transactions are included in the report. Clear the check box to include only totals.';
                    }
                    field(PrintToExcelControl; PrintToExcel)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print to Excel';
                        ToolTip = 'Specifies if you want to export the data to an Excel spreadsheet for additional analysis or formatting before printing.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if PeriodEndingDate[1] = 0D then begin
                PeriodEndingDate[1] := WorkDate();
                Evaluate(PeriodCalculation, '<30D>');
            end;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if PrintToExcel then
            CreateExcelbook();

        FinishDateTime := CurrentDateTime();
        LogReportTelemetry(StartDateTime, FinishDateTime, NumberOfLines);
    end;

    trigger OnPreReport()
    begin
        StartDateTime := CurrentDateTime();
        NumberOfLines := 0;

        if Format(PeriodCalculation) <> '' then
            Evaluate(PeriodCalculation, '-' + Format(PeriodCalculation));
        if Format(ShowOnlyOverDueBy) <> '' then
            Evaluate(ShowOnlyOverDueBy, '-' + Format(ShowOnlyOverDueBy));
        if AgingMethod = AgingMethod::"Due Date" then begin
            PeriodEndingDate[2] := PeriodEndingDate[1];
            for j := 3 to 4 do
                PeriodEndingDate[j] := CalcDate(PeriodCalculation, PeriodEndingDate[j - 1]);
        end else
            for j := 2 to 4 do
                PeriodEndingDate[j] := CalcDate(PeriodCalculation, PeriodEndingDate[j - 1]);

        PeriodEndingDate[5] := 0D;
        CompanyInformation.Get();
        GLSetup.Get();
        FilterString := Customer.GetFilters();

        if PrintDetail then
            SubTitle := DetailLbl
        else
            SubTitle := SummaryLbl;

        SubTitle := CopyStr(SubTitle + AgedAsOfLbl + ' ' + Format(PeriodEndingDate[1], 0, 4) + ')', 1, MaxStrLen(SubTitle));

        case AgingMethod of
            AgingMethod::"Due Date":
                begin
                    DateTitle := DueDateFullLbl;
                    ShortDateTitle := DueDateShortLbl;
                    ColumnHead[2] := UpToLbl + ' ' + Format(PeriodEndingDate[1] - PeriodEndingDate[3]) + DaysLbl;
                    ColumnHeadHead := AgedOverdueAmountsLbl + ' ';
                end;
            AgingMethod::"Trans Date":
                begin
                    DateTitle := TransactionDateFullLbl;
                    ShortDateTitle := TransactionDateShortLbl;
                    ColumnHead[2] :=
                      Format(PeriodEndingDate[1] - PeriodEndingDate[2] + 1) +
                      ' - ' + Format(PeriodEndingDate[1] - PeriodEndingDate[3]) + DaysLbl;
                    ColumnHeadHead := AgedCustomerBalancesLbl + ' ';
                end;
            AgingMethod::"Document Date":
                begin
                    DateTitle := DocumentDateFullLbl;
                    ShortDateTitle := DocumentDateShortLbl;
                    ColumnHead[2] :=
                      Format(PeriodEndingDate[1] - PeriodEndingDate[2] + 1) +
                      ' - ' + Format(PeriodEndingDate[1] - PeriodEndingDate[3]) + DaysLbl;
                    ColumnHeadHead := AgedCustomerBalancesLbl + ' ';
                end;
        end;

        ColumnHead[1] := CurrentLbl;
        ColumnHead[3] :=
          Format(PeriodEndingDate[1] - PeriodEndingDate[3] + 1) + ' - ' + Format(PeriodEndingDate[1] - PeriodEndingDate[4]) + DaysLbl;
        ColumnHead[4] := OverLbl + ' ' + Format(PeriodEndingDate[1] - PeriodEndingDate[4]) + DaysLbl;

        if PrintToExcel then
            MakeExcelInfo();
    end;

    var
        CompanyInformation: Record "Company Information";
        TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        GLSetup: Record "General Ledger Setup";
        ExcelBuf: Record "Excel Buffer" temporary;
        TempCustomer: Record Customer temporary;
        NumCustLedgEntriesperCust: Query "Num CustLedgEntries per Cust";
        PeriodCalculation: DateFormula;
        ShowOnlyOverDueBy: DateFormula;
        AgingMethod: Option "Trans Date","Due Date","Document Date";
        PrintAmountsInLocal: Boolean;
        PrintDetail: Boolean;
        PrintToExcel: Boolean;
        AmountDue: array[4] of Decimal;
        "BalanceDue$": array[4] of Decimal;
        ColumnHead: array[4] of Text[20];
        ColumnHeadHead: Text[59];
        PercentString: array[4] of Text[10];
        Percent: Decimal;
        "TotalBalanceDue$": Decimal;
        AmountDueToPrint: Decimal;
        CreditLimitToPrint: Text[25];
        BlockedDescription: Text[60];
        OverLimitDescription: Text[25];
        j: Integer;
        CurrencyFactor: Decimal;
        FilterString: Text;
        SubTitle: Text[88];
        DateTitle: Text[20];
        ShortDateTitle: Text[20];
        PeriodEndingDate: array[5] of Date;
        AgingDate: Date;
        AmountsAreInLbl: Label 'Amounts are in %1', Comment = '%1=currency code';
        CustomerBlockedLbl: Label '*** This customer is blocked  for %1 processing ***  ', Comment = '%1=blocking type';
        PrivacyBlockedTxt: Label '*** This customer is blocked for privacy ***.';
        NoLimitLbl: Label 'No Limit';
        OverLimitLbl: Label '*** Over Limit ***';
        DetailLbl: Label '(Detail';
        SummaryLbl: Label '(Summary';
        AgedAsOfLbl: Label ', aged as of';
        DueDateFullLbl: Label 'due date.';
        DueDateShortLbl: Label 'Due Date';
        UpToLbl: Label 'Up To';
        DaysLbl: Label ' Days';
        AgedOverdueAmountsLbl: Label ' Aged Overdue Amounts';
        TransactionDateFullLbl: Label 'transaction date.';
        TransactionDateShortLbl: Label 'Trx Date';
        AgedCustomerBalancesLbl: Label ' Aged Customer Balances';
        DocumentDateFullLbl: Label 'document date.';
        DocumentDateShortLbl: Label 'Doc Date';
        CurrentLbl: Label 'Current';
        OverLbl: Label 'Over';
        AmountsAreIn2Lbl: Label 'Amounts are in the customer''s local currency (report totals are in %1).';
        ReportTotalAmountDueLbl: Label 'Report Total Amount Due (%1)', Comment = '%1=currency code';
        DataLbl: Label 'Data';
        AgedAccountsReceivableLbl: Label 'Aged Accounts Receivable';
        CompanyNameLbl: Label 'Company Name';
        ReportNoLbl: Label 'Report No.';
        ReportNameLbl: Label 'Report Name';
        UserIDLbl: Label 'User ID';
        DateTimeLbl: Label 'Date / Time';
        CustomerFiltersLbl: Label 'Customer Filters';
        AmountsAreLbl: Label 'Amounts are';
        InOurFunctionalCurrencyLbl: Label 'In our Functional Currency';
        AsindicatedinDataLbl: Label 'As indicated in Data';
        AgedAsOf2Lbl: Label 'Aged as of';
        AgingDateLbl: Label 'Aging Date (%1)', Comment = '%1=date';
        DocumentCurrencyLbl: Label 'Document Currency';
        CustomerCurrencyLbl: Label 'Customer Currency';
        CreditLimitLbl: Label 'Credit Limit';
        ShowOnlyOverdueByLbl: Label 'Show Only Overdue By Needs a Valid Date Formula';
        ShowAllForOverdue: Boolean;
        CalculatedDate: Date;
        OnlyForDueDateLbl: Label 'This option is only allowed for method Due Date';
        CustTotAmountDue: array[4] of Decimal;
        CustTotAmountDueToPrint: Decimal;
        PeriodCalculationRequiredLbl: Label 'You must enter a period calculation in the Length of Aging Periods field.';
        Aged_Accounts_ReceivableCaptionLbl: Label 'Aged Accounts Receivable';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Aged_byCaptionLbl: Label 'Aged by';
        AmountDueToPrint_Control74CaptionLbl: Label 'Balance Due';
        Credit_LimitCaptionLbl: Label 'Credit Limit';
        NameCaptionLbl: Label 'Name';
        Cust__Ledger_Entry___Document_No__CaptionLbl: Label 'Number';
        Cust__Ledger_Entry__DescriptionCaptionLbl: Label 'Description';
        Cust__Ledger_Entry___Document_Type_CaptionLbl: Label 'Type';
        Cust__Ledger_Entry___Currency_Code_CaptionLbl: Label 'Doc. Curr.';
        DocumentCaptionLbl: Label 'Document';
        Balance_ForwardCaptionLbl: Label 'Balance Forward';
        Balance_to_Carry_ForwardCaptionLbl: Label 'Balance to Carry Forward';
        Total_Amount_DueCaptionLbl: Label 'Total Amount Due';
        Total_Amount_DueCaption_Control86Lbl: Label 'Total Amount Due';
        Credit_Limit_CaptionLbl: Label 'Credit Limit:';
        TotalNumberOfEntries: Integer;
        GrandTotalBalanceDue: Decimal;
        GrandBalanceDue: array[4] of Decimal;
        TelemetryCategoryTxt: Label 'Report', Locked = true;
        AgedARReportGeneratedTxt: Label 'Aged AR Report generated.', Locked = true;

    protected var
        NumberOfLines: Integer;
        StartDateTime: DateTime;
        FinishDateTime: DateTime;

    local procedure InsertTemp(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        if TempCustLedgEntry.Get(CustLedgEntry."Entry No.") then
            exit;
        TempCustLedgEntry := CustLedgEntry;
        case AgingMethod of
            AgingMethod::"Due Date":
                TempCustLedgEntry."Posting Date" := TempCustLedgEntry."Due Date";
            AgingMethod::"Document Date":
                TempCustLedgEntry."Posting Date" := TempCustLedgEntry."Document Date";
        end;
        TempCustLedgEntry.Insert();
    end;

    procedure CalcPercents(Total: Decimal; Amounts: array[4] of Decimal)
    var
        i: Integer;
        k: Integer;
    begin
        Clear(PercentString);
        if Total <> 0 then
            for i := 1 to 4 do begin
                Percent := Amounts[i] / Total * 100.0;
                if StrLen(Format(Round(Percent))) + 4 > MaxStrLen(PercentString[1]) then
                    PercentString[i] := PadStr(PercentString[i], MaxStrLen(PercentString[i]), '*')
                else begin
                    PercentString[i] := Format(Round(Percent));
                    k := StrPos(PercentString[i], '.');
                    if k = 0 then
                        PercentString[i] := PercentString[i] + '.00'
                    else
                        if k = StrLen(PercentString[i]) - 1 then
                            PercentString[i] := PercentString[i] + '0';
                    PercentString[i] := PercentString[i] + '%';
                end;
            end;
    end;

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
                exit('101,1,' + AmountsAreInLbl);

            GetCurrencyRecord(Currency, CurrencyCode);
            exit(StrSubstNo(AmountsAreInLbl, Currency.Description));
        end;
        exit('');
    end;

    local procedure MakeExcelInfo()
    begin
        ExcelBuf.SetUseInfoSheet();
        ExcelBuf.AddInfoColumn(Format(CompanyNameLbl), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(CompanyInformation.Name, false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(ReportNameLbl), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(Format(AgedAccountsReceivableLbl), false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(ReportNoLbl), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(REPORT::"Aged Accounts Receivable NA", false, false, false, false, '', ExcelBuf."Cell Type"::Number);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(UserIDLbl), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(UserId(), false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(DateTimeLbl), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(Today(), false, false, false, false, '', ExcelBuf."Cell Type"::Date);
        ExcelBuf.AddInfoColumn(Time(), false, false, false, false, '', ExcelBuf."Cell Type"::Time);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(CustomerFiltersLbl), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(FilterString, false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Aged_byCaptionLbl), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(DateTitle, false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(AgedAsOf2Lbl), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(PeriodEndingDate[1], false, false, false, false, '', ExcelBuf."Cell Type"::Date);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(AmountsAreLbl), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        if PrintAmountsInLocal then
            ExcelBuf.AddInfoColumn(Format(AsindicatedinDataLbl), false, false, false, false, '', ExcelBuf."Cell Type"::Text)
        else
            ExcelBuf.AddInfoColumn(Format(InOurFunctionalCurrencyLbl), false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.ClearNewRow();
        MakeExcelDataHeader();
    end;

    local procedure MakeExcelDataHeader()
    begin
        ExcelBuf.NewRow();
        ExcelBuf.AddColumn("Cust. Ledger Entry".FieldCaption("Customer No."), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Customer.FieldCaption(Name), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        if PrintDetail then begin
            ExcelBuf.AddColumn(StrSubstNo(AgingDateLbl, ShortDateTitle), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
            ExcelBuf.AddColumn("Cust. Ledger Entry".FieldCaption(Description), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
            ExcelBuf.AddColumn("Cust. Ledger Entry".FieldCaption("Document Type"), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
            ExcelBuf.AddColumn("Cust. Ledger Entry".FieldCaption("Document No."), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        end else
            ExcelBuf.AddColumn(Format(CreditLimitLbl), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Format(AmountDueToPrint_Control74CaptionLbl), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(ColumnHead[1], false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(ColumnHead[2], false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(ColumnHead[3], false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(ColumnHead[4], false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        if PrintAmountsInLocal then
            if PrintDetail then
                ExcelBuf.AddColumn(Format(DocumentCurrencyLbl), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text)
            else
                ExcelBuf.AddColumn(Format(CustomerCurrencyLbl), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
    end;

    local procedure MakeExcelDataBody()
    var
        CurrencyCodeToPrint: Code[20];
    begin
        ExcelBuf.NewRow();
        ExcelBuf.AddColumn(Customer."No.", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Customer.Name, false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        if PrintDetail then begin
            ExcelBuf.AddColumn(AgingDate, false, '', false, false, false, '', ExcelBuf."Cell Type"::Date);
            ExcelBuf.AddColumn("Cust. Ledger Entry".Description, false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
            ExcelBuf.AddColumn(Format("Cust. Ledger Entry"."Document Type"), false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
            ExcelBuf.AddColumn("Cust. Ledger Entry"."Document No.", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        end else
            if OverLimitDescription = '' then
                ExcelBuf.AddColumn(CreditLimitToPrint, false, '', false, false, false, '#,##0', ExcelBuf."Cell Type"::Number)
            else
                ExcelBuf.AddColumn(CreditLimitToPrint, false, OverLimitDescription, true, false, false, '#,##0', ExcelBuf."Cell Type"::Number);
        ExcelBuf.AddColumn(AmountDueToPrint, false, '', false, false, false, '#,##0.00', ExcelBuf."Cell Type"::Number);
        ExcelBuf.AddColumn(AmountDue[1], false, '', false, false, false, '#,##0.00', ExcelBuf."Cell Type"::Number);
        ExcelBuf.AddColumn(AmountDue[2], false, '', false, false, false, '#,##0.00', ExcelBuf."Cell Type"::Number);
        ExcelBuf.AddColumn(AmountDue[3], false, '', false, false, false, '#,##0.00', ExcelBuf."Cell Type"::Number);
        ExcelBuf.AddColumn(AmountDue[4], false, '', false, false, false, '#,##0.00', ExcelBuf."Cell Type"::Number);
        if PrintAmountsInLocal then begin
            if PrintDetail then
                CurrencyCodeToPrint := "Cust. Ledger Entry"."Currency Code"
            else
                CurrencyCodeToPrint := Customer."Currency Code";
            if CurrencyCodeToPrint = '' then
                CurrencyCodeToPrint := GLSetup."LCY Code";
            ExcelBuf.AddColumn(CurrencyCodeToPrint, false, '', false, false, false, '', ExcelBuf."Cell Type"::Text)
        end;
    end;

    local procedure CreateExcelbook()
    begin
        ExcelBuf.CreateBookAndOpenExcel('', DataLbl, AgedAccountsReceivableLbl, CompanyName(), UserId());
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
        Session.LogMessage('0000FJM', AgedARReportGeneratedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dimensions);
    end;
}

