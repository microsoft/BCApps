// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using System.IO;
using System.Utilities;

report 10085 "Aged Accounts Payable NA"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/AgedAccountsPayableNA.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Aged Accounts Payable';
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem(Header; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(Aged_Accounts_Payable_; 'Aged Accounts Payable')
            {
            }
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
            column(SubTitle; SubTitle)
            {
            }
            column(DateTitle; DateTitle)
            {
            }
            column(Document_Number_is______Vendor_Ledger_Entry__FIELDCAPTION__External_Document_No___; 'Document Number is ' + TempVendorLedgerEntry.FieldCaption("External Document No."))
            {
            }
            column(Vendor_TABLECAPTION__________FilterString; Vendor.TableCaption() + ': ' + FilterString)
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
            column(PrintToExcel; PrintToExcel)
            {
            }
            column(PrintDetail; PrintDetail)
            {
            }
            column(PrintAmountsInLocal; PrintAmountsInLocal)
            {
            }
            column(ShowAllForOverdue; ShowAllForOverdue)
            {
            }
            column(UseExternalDocNo; UseExternalDocNo)
            {
            }
            column(FilterString; FilterString)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Aged_byCaption; Aged_byCaptionLbl)
            {
            }
            column(Control11Caption; CaptionClassTranslate('101,1,' + VendorCurrencyLbl))
            {
            }
            column(Vendor__No__Caption; Vendor.FieldCaption("No."))
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(AmountDueToPrint_Control74Caption; AmountDueToPrint_Control74CaptionLbl)
            {
            }
            column(Vendor__No__Caption_Control22; Vendor.FieldCaption("No."))
            {
            }
            column(Vendor_NameCaption; Vendor.FieldCaption(Name))
            {
            }
            column(DocNoCaption; DocNoCaptionLbl)
            {
            }
            column(DescriptionCaption; DescriptionCaptionLbl)
            {
            }
            column(TypeCaption; TypeCaptionLbl)
            {
            }
            column(AmountDueToPrint_Control63Caption; AmountDueToPrint_Control63CaptionLbl)
            {
            }
            column(DocumentCaption; DocumentCaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry___Currency_Code_Caption; Vendor_Ledger_Entry___Currency_Code_CaptionLbl)
            {
            }
            column(Phone_Caption; Phone_CaptionLbl)
            {
            }
            column(Contact_Caption; Contact_CaptionLbl)
            {
            }
            column(Control1020000Caption; CaptionClassTranslate(GetCurrencyCaptionCode(Vendor."Currency Code")))
            {
            }
            column(Control47Caption; CaptionClassTranslate('101,0,' + ReportTotalAmountLbl))
            {
            }
            column(Control48Caption; CaptionClassTranslate('101,0,' + ReportTotalAmountLbl))
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
            column(ColumnHeadHead_Control21; ColumnHeadHead)
            {
            }
            column(ShortDateTitle; ShortDateTitle)
            {
            }
            column(ColumnHead_1__Control26; ColumnHead[1])
            {
            }
            column(ColumnHead_2__Control27; ColumnHead[2])
            {
            }
            column(ColumnHead_3__Control28; ColumnHead[3])
            {
            }
            column(ColumnHead_4__Control29; ColumnHead[4])
            {
            }
            column(GrandTotalBalanceDue_; -GrandTotalBalanceDue)
            {
            }
            column(GrandBalanceDue_1_; -GrandBalanceDue[1])
            {
            }
            column(GrandBalanceDue_2_; -GrandBalanceDue[2])
            {
            }
            column(GrandBalanceDue_3_; -GrandBalanceDue[3])
            {
            }
            column(GrandBalanceDue_4_; -GrandBalanceDue[4])
            {
            }
            dataitem(Vendor; Vendor)
            {
                PrintOnlyIfDetail = true;
                RequestFilterFields = "No.", "Vendor Posting Group", "Payment Terms Code", "Purchaser Code";
                column(Vendor__No__; "No.")
                {
                }
                column(Vendor_Name; Name)
                {
                }
                column(Vendor__Phone_No__; "Phone No.")
                {
                }
                column(Vendor_Contact; Contact)
                {
                }
                column(BlockedDescription; BlockedDescription)
                {
                }
                column(TotalBalanceDue__; -"TotalBalanceDue$")
                {
                }
                column(BalanceDue___1_; -"BalanceDue$"[1])
                {
                }
                column(BalanceDue___2_; -"BalanceDue$"[2])
                {
                }
                column(BalanceDue___3_; -"BalanceDue$"[3])
                {
                }
                column(BalanceDue___4_; -"BalanceDue$"[4])
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
                column(TotalBalanceDue___Control91; -"TotalBalanceDue$")
                {
                }
                column(BalanceDue___1__Control92; -"BalanceDue$"[1])
                {
                }
                column(BalanceDue___2__Control93; -"BalanceDue$"[2])
                {
                }
                column(BalanceDue___3__Control94; -"BalanceDue$"[3])
                {
                }
                column(PercentString_1__Control95; PercentString[1])
                {
                }
                column(PercentString_2__Control96; PercentString[2])
                {
                }
                column(PercentString_3__Control97; PercentString[3])
                {
                }
                column(BalanceDue___4__Control98; -"BalanceDue$"[4])
                {
                }
                column(PercentString_4__Control99; PercentString[4])
                {
                }
                column(Vendor_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
                {
                }
                column(Vendor_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
                {
                }
                dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
                {
                    DataItemLink = "Vendor No." = field("No."), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter");
                    DataItemTableView = sorting("Vendor No.", Open, Positive, "Due Date");

                    trigger OnAfterGetRecord()
                    begin
                        CalcFields("Remaining Amount");
                        if "Remaining Amount" <> 0 then
                            InsertTemp("Vendor Ledger Entry");

                        CurrReport.Skip();    // this fools the system into thinking that no details "printed"...yet
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetLoadFields("Vendor No.", Open, Positive, "Currency Code", "Global Dimension 1 Code", "Global Dimension 2 Code", "Remaining Amount", "Posting Date", "Date Filter", "Due Date", "Document Date");

                        // Find ledger entries which are posted before the date of the aging.
                        SetRange("Posting Date", 0D, PeriodEndingDate[1]);
                        SetRange("Date Filter", 0D, PeriodEndingDate[1]);

                        if (Format(ShowOnlyOverDueBy) <> '') and (not ShowAllForOverdue) then
                            SetRange("Due Date", 0D, CalculatedDate);
                    end;
                }
                dataitem(Totals; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(AmountDueToPrint; -AmountDueToPrint)
                    {
                        AutoFormatExpression = TempVendorLedgerEntry."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(AmountDue_1_; -AmountDue[1])
                    {
                        AutoFormatExpression = TempVendorLedgerEntry."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(AmountDue_2_; -AmountDue[2])
                    {
                        AutoFormatExpression = TempVendorLedgerEntry."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(AmountDue_3_; -AmountDue[3])
                    {
                        AutoFormatExpression = TempVendorLedgerEntry."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(AmountDue_4_; -AmountDue[4])
                    {
                        AutoFormatExpression = TempVendorLedgerEntry."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(AgingDate; AgingDate)
                    {
                    }
                    column(Vendor_Ledger_Entry__Description; TempVendorLedgerEntry.Description)
                    {
                    }
                    column(Vendor_Ledger_Entry___Document_Type_; TempVendorLedgerEntry."Document Type")
                    {
                    }
                    column(DocNo; DocNo)
                    {
                    }
                    column(AmountDueToPrint_Control63; -AmountDueToPrint)
                    {
                        AutoFormatExpression = TempVendorLedgerEntry."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(AmountDue_1__Control64; -AmountDue[1])
                    {
                        AutoFormatExpression = TempVendorLedgerEntry."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(AmountDue_2__Control65; -AmountDue[2])
                    {
                        AutoFormatExpression = TempVendorLedgerEntry."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(AmountDue_3__Control66; -AmountDue[3])
                    {
                        AutoFormatExpression = TempVendorLedgerEntry."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(AmountDue_4__Control67; -AmountDue[4])
                    {
                        AutoFormatExpression = TempVendorLedgerEntry."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Vendor_Ledger_Entry___Currency_Code_; TempVendorLedgerEntry."Currency Code")
                    {
                    }
                    column(AmountDueToPrint_Control68; -AmountDueToPrint)
                    {
                        AutoFormatExpression = TempVendorLedgerEntry."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(AmountDue_1__Control69; -AmountDue[1])
                    {
                        AutoFormatExpression = TempVendorLedgerEntry."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(AmountDue_2__Control70; -AmountDue[2])
                    {
                        AutoFormatExpression = TempVendorLedgerEntry."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(AmountDue_3__Control71; -AmountDue[3])
                    {
                        AutoFormatExpression = TempVendorLedgerEntry."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(AmountDue_4__Control72; -AmountDue[4])
                    {
                        AutoFormatExpression = TempVendorLedgerEntry."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(AmountDueToPrint_Control74; -AmountDueToPrint)
                    {
                        AutoFormatExpression = TempVendorLedgerEntry."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(AmountDue_1__Control75; -AmountDue[1])
                    {
                        AutoFormatExpression = TempVendorLedgerEntry."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(AmountDue_2__Control76; -AmountDue[2])
                    {
                        AutoFormatExpression = TempVendorLedgerEntry."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(AmountDue_3__Control77; -AmountDue[3])
                    {
                        AutoFormatExpression = TempVendorLedgerEntry."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(AmountDue_4__Control78; -AmountDue[4])
                    {
                        AutoFormatExpression = TempVendorLedgerEntry."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(PercentString_1__Control5; PercentString[1])
                    {
                    }
                    column(PercentString_2__Control6; PercentString[2])
                    {
                    }
                    column(PercentString_3__Control7; PercentString[3])
                    {
                    }
                    column(PercentString_4__Control8; PercentString[4])
                    {
                    }
                    column(Vendor__No___Control80; Vendor."No.")
                    {
                    }
                    column(AmountDueToPrint_Control81; -AmountDueToPrint)
                    {
                        AutoFormatExpression = TempVendorLedgerEntry."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(AmountDue_1__Control82; -AmountDue[1])
                    {
                        AutoFormatExpression = TempVendorLedgerEntry."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(AmountDue_2__Control83; -AmountDue[2])
                    {
                        AutoFormatExpression = TempVendorLedgerEntry."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(AmountDue_3__Control84; -AmountDue[3])
                    {
                        AutoFormatExpression = TempVendorLedgerEntry."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(AmountDue_4__Control85; -AmountDue[4])
                    {
                        AutoFormatExpression = TempVendorLedgerEntry."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(PercentString_1__Control87; PercentString[1])
                    {
                    }
                    column(PercentString_2__Control88; PercentString[2])
                    {
                    }
                    column(PercentString_3__Control89; PercentString[3])
                    {
                    }
                    column(PercentString_4__Control90; PercentString[4])
                    {
                    }
                    column(Totals_Number; Number)
                    {
                    }
                    column(Control1020001Caption; CaptionClassTranslate(GetCurrencyCaptionCode(Vendor."Currency Code")))
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        CalcPercents(AmountDueToPrint, AmountDue);
                        Clear(AmountDue);
                        AmountDueToPrint := 0;
                        if Number = 1 then
                            TempVendorLedgerEntry.Find('-')
                        else
                            TempVendorLedgerEntry.Next();

                        TempVendorLedgerEntry.SetRange("Date Filter", 0D, PeriodEndingDate[1]);
                        TempVendorLedgerEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");

                        if TempVendorLedgerEntry."Remaining Amount" = 0 then
                            CurrReport.Skip();

                        if TempVendorLedgerEntry."Currency Code" <> '' then
                            TempVendorLedgerEntry."Remaining Amt. (LCY)" := Round(CurrencyExchangeRate.ExchangeAmtFCYToFCY(PeriodEndingDate[1], TempVendorLedgerEntry."Currency Code", '', TempVendorLedgerEntry."Remaining Amount"));

                        if PrintAmountsInLocal then begin
                            TempVendorLedgerEntry."Remaining Amount" := Round(CurrencyExchangeRate.ExchangeAmtFCYToFCY(PeriodEndingDate[1], TempVendorLedgerEntry."Currency Code", Vendor."Currency Code", TempVendorLedgerEntry."Remaining Amount"), Currency."Amount Rounding Precision");
                            AmountDueToPrint := TempVendorLedgerEntry."Remaining Amount";
                        end else
                            AmountDueToPrint := TempVendorLedgerEntry."Remaining Amt. (LCY)";

                        case AgingMethod of
                            AgingMethod::"Due Date":
                                AgingDate := TempVendorLedgerEntry."Due Date";
                            AgingMethod::"Trans Date":
                                AgingDate := TempVendorLedgerEntry."Posting Date";
                            AgingMethod::"Document Date":
                                AgingDate := TempVendorLedgerEntry."Document Date";
                        end;
                        j := 0;
                        while AgingDate < PeriodEndingDate[j + 1] do
                            j := j + 1;
                        if j = 0 then
                            j := 1;

                        AmountDue[j] := AmountDueToPrint;
                        "BalanceDue$"[j] := "BalanceDue$"[j] + TempVendorLedgerEntry."Remaining Amt. (LCY)";

                        "TotalBalanceDue$" := 0;
                        VendTotAmountDue[j] := VendTotAmountDue[j] + AmountDueToPrint;
                        VendTotAmountDueToPrint := VendTotAmountDueToPrint + AmountDueToPrint;

                        for j := 1 to 4 do
                            "TotalBalanceDue$" := "TotalBalanceDue$" + "BalanceDue$"[j];
                        CalcPercents("TotalBalanceDue$", "BalanceDue$");

                        if UseExternalDocNo then
                            DocNo := TempVendorLedgerEntry."External Document No."
                        else
                            DocNo := TempVendorLedgerEntry."Document No.";

                        TotalNumberOfEntries -= 1;
                        if TotalNumberOfEntries = 0 then begin
                            for j := 1 to 4 do
                                GrandBalanceDue[j] += "BalanceDue$"[j];
                            GrandTotalBalanceDue += "TotalBalanceDue$";
                        end;

                        // Do NOT use the following fields in the sections:
                        // "Applied-To Doc. Type"
                        // "Applied-To Doc. No."
                        // Open
                        // "Paym. Disc. Taken"
                        // "Closed by Entry No."
                        // "Closed at Date"
                        // "Closed by Amount"

                        if PrintDetail and PrintToExcel then
                            MakeExcelDataBody();
                    end;

                    trigger OnPostDataItem()
                    begin
                        if TempVendorLedgerEntry.Count() > 0 then begin
                            for j := 1 to 4 do
                                AmountDue[j] := VendTotAmountDue[j];
                            AmountDueToPrint := VendTotAmountDueToPrint;
                            if not PrintDetail and PrintToExcel then
                                MakeExcelDataBody();
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        Clear(AmountDueToPrint);
                        Clear(AmountDue);
                        SetRange(Number, 1, TempVendorLedgerEntry.Count());
                        TempVendorLedgerEntry.SetCurrentKey("Vendor No.", "Posting Date");
                        Clear(VendTotAmountDue);
                        VendTotAmountDueToPrint := 0;
                        TotalNumberOfEntries := TempVendorLedgerEntry.Count();
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    VendLedgEntry: Record "Vendor Ledger Entry";
                begin
                    Clear("BalanceDue$");
                    if PrintAmountsInLocal then begin
                        GetCurrencyRecord(Currency, "Currency Code");
                        CurrencyFactor := CurrencyExchangeRate.ExchangeRate(PeriodEndingDate[1], "Currency Code");
                    end;

                    if "Privacy Blocked" then
                        BlockedDescription := PrivacyBlockedTxt
                    else
                        BlockedDescription := '';
                    if Blocked <> Blocked::" " then
                        BlockedDescription := StrSubstNo(VendorBlockedLbl, Blocked)
                    else
                        BlockedDescription := '';

                    TempVendorLedgerEntry.DeleteAll();

                    if Format(ShowOnlyOverDueBy) <> '' then
                        CalculatedDate := CalcDate(ShowOnlyOverDueBy, PeriodEndingDate[1]);

                    VendLedgEntry.SetLoadFields("Vendor No.", Open, "Due Date");

                    if ShowAllForOverdue and (Format(ShowOnlyOverDueBy) <> '') then begin
                        VendLedgEntry.SetRange("Vendor No.", "No.");
                        VendLedgEntry.SetRange(Open, true);
                        VendLedgEntry.SetRange("Due Date", 0D, CalculatedDate);
                        if VendLedgEntry.IsEmpty() then
                            CurrReport.Skip();
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    Vendor.SetLoadFields(Name, "Currency Code");

                    Clear("BalanceDue$");
                    if PeriodEndingDate[1] = 0D then
                        PeriodEndingDate[1] := WorkDate();

                    if PrintDetail then
                        SubTitle := DetailLbl
                    else
                        SubTitle := SummaryLbl;

                    SubTitle := copystr(SubTitle + AgedAsOfLbl + ' ' + Format(PeriodEndingDate[1], 0, 4) + ')', 1, MaxStrLen(SubTitle));

                    case AgingMethod of
                        AgingMethod::"Due Date":
                            begin
                                DateTitle := DueDateFullLbl;
                                ShortDateTitle := DueDateShortLbl;
                                ColumnHead[2] := UpToLbl + ' ' + Format(PeriodEndingDate[1] - PeriodEndingDate[3]) + ' ' + DaysLbl;
                                ColumnHeadHead := ' ' + AgedOverdueAmountsLbl + ' ';
                            end;
                        AgingMethod::"Trans Date":
                            begin
                                DateTitle := TransactionDateLbl;
                                ShortDateTitle := TrxDateLbl;
                                ColumnHead[2] := Format(PeriodEndingDate[1] - PeriodEndingDate[2] + 1) + ' - ' + Format(PeriodEndingDate[1] - PeriodEndingDate[3]) + ' ' + DaysLbl;
                                ColumnHeadHead := ' ' + AgedVendorBalancesLbl + ' ';
                            end;
                        AgingMethod::"Document Date":
                            begin
                                DateTitle := DocumentDateFullLbl;
                                ShortDateTitle := DocumentDateShortLbl;
                                ColumnHead[2] := Format(PeriodEndingDate[1] - PeriodEndingDate[2] + 1) + ' - ' + Format(PeriodEndingDate[1] - PeriodEndingDate[3]) + ' ' + DaysLbl;
                                ColumnHeadHead := ' ' + AgedVendorBalancesLbl + ' ';
                            end;
                    end;

                    ColumnHead[1] := CurrentLbl;
                    ColumnHead[3] := Format(PeriodEndingDate[1] - PeriodEndingDate[3] + 1) + ' - ' + Format(PeriodEndingDate[1] - PeriodEndingDate[4]) + ' ' + DaysLbl;
                    ColumnHead[4] := 'Over ' + Format(PeriodEndingDate[1] - PeriodEndingDate[4]) + ' ' + DaysLbl;

                    if PrintToExcel then
                        MakeExcelInfo();
                end;
            }
        }
    }

    requestpage
    {
        SaveValues = true;
        AboutTitle = 'About Aged Accounts Payable';
        AboutText = 'Analyze vendor balances at the end of each period by calculating outstanding invoice, credit memo, and payment totals in three periods of equal length. Monitor unpaid invoices, and prioritize payments for overdue accounts. ';

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
                    field(AgingMethodControl; AgingMethod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Aging Method';
                        OptionCaption = 'Due Date,Trans Date,Document Date';
                        ToolTip = 'Specifies how aging is calculated. Due Date: Aging is calculated by the number of days that the transaction is overdue. Trans Date: Aging is calculated by the number of days since the transaction posting date. Document Date: Aging is calculated by the number of days since the document date.';
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
                        Caption = 'Show All for Overdue By Vendor';
                        ToolTip = 'Specifies if you want to include the open vendor ledger entries that are overdue. These entries will be calculated based on the period in the Show if Overdue By field. If the Show All for Overdue by Vendor field is selected, then you must enter a date in the Aged by field and a date in the Show if Overdue By field to show overdue vendor ledger entries.';

                        trigger OnValidate()
                        begin
                            if AgingMethod <> AgingMethod::"Due Date" then
                                Error(OnlyForDueDateLbl);
                            if ShowAllForOverdue and (Format(ShowOnlyOverDueBy) = '') then
                                Error(ShowOnlyOverdueLbl);
                        end;
                    }
                    field(PrintAmountsInVendorsCurrency; PrintAmountsInLocal)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Print Amounts in Vendor''s Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies if amounts are printed in the vendor''s currency. Clear the check box to print all amounts in US dollars.';

                        trigger OnValidate()
                        begin
                            if ShowAllForOverdue and (Format(ShowOnlyOverDueBy) = '') then
                                Error(ShowOnlyOverdueLbl);
                        end;
                    }
                    field(PrintDetailControl; PrintDetail)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Detail';
                        ToolTip = 'Specifies if individual transactions are included in the report. Clear the check box to include only totals.';
                    }
                    field(UseExternalDocNoControl; UseExternalDocNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use External Doc. No.';
                        ToolTip = 'Specifies if you want to print the vendor''s document numbers, such as the invoice number, on all transactions. Clear this check box to print only internal document numbers.';
                    }
                    field(PrintToExcelControl; PrintToExcel)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print to Excel';
                        ToolTip = 'Specifies if you want to export the data to an Excel spreadsheet for additional analysis or formatting before printing.';
                    }
                    field(PrintVendorWithZeroBalanceControl; PrintVendorWithZeroBalance)
                    {
                        ApplicationArea = Basic, Suite;
                        Visible = false;
                        Caption = 'Print Vendors with Zero Balance';
                        ToolTip = 'Specifies if you want to print the list of vendors that have a balance of zero.';
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
    end;

    trigger OnPreReport()
    begin
        TempVendorLedgerEntry.SetloadFields("Posting Date", "Document Date", "Due Date", "Document No.", "External Document No.", "Document Type", "Date Filter", "Currency Code", Description, "Remaining Amount", "Remaining Amt. (LCY)", "Vendor No.");

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
        FilterString := Vendor.GetFilters();
    end;

    var
        CompanyInformation: Record "Company Information";
        TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GLSetup: Record "General Ledger Setup";
        TempExcelBuffer: Record "Excel Buffer" temporary;
        PeriodCalculation: DateFormula;
        ShowOnlyOverDueBy: DateFormula;
        AgingMethod: Option "Due Date","Trans Date","Document Date";
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
        BlockedDescription: Text[80];
        j: Integer;
        CurrencyFactor: Decimal;
        FilterString: Text;
        SubTitle: Text[88];
        DateTitle: Text[20];
        ShortDateTitle: Text[20];
        PeriodEndingDate: array[5] of Date;
        AgingDate: Date;
        UseExternalDocNo: Boolean;
        DocNo: Code[35];
        PrintVendorWithZeroBalance: Boolean;
        AmountsAreInLbl: Label 'Amounts are in %1', Comment = '%1=currency code';
        VendorBlockedLbl: Label '*** This vendor is blocked for %1 processing ***', Comment = '%1=blocking type';
        PrivacyBlockedTxt: Label '*** This vendor is blocked for privacy ***.';
        DetailLbl: Label '(Detail';
        SummaryLbl: Label '(Summary';
        AgedAsOfLbl: Label ', aged as of';
        DueDateFullLbl: Label 'due date.';
        DueDateShortLbl: Label 'Due Date';
        UpToLbl: Label 'Up To';
        DaysLbl: Label 'Days';
        AgedOverdueAmountsLbl: Label 'Aged Overdue Amounts';
        TransactionDateLbl: Label 'transaction date.';
        TrxDateLbl: Label 'Trx Date';
        AgedVendorBalancesLbl: Label 'Aged Vendor Balances';
        DocumentDateFullLbl: Label 'document date.';
        DocumentDateShortLbl: Label 'Doc Date';
        CurrentLbl: Label 'Current';
        VendorCurrencyLbl: Label 'Amounts are in the vendor''s local currency (report totals are in %1).', Comment = '%1=currency code';
        ReportTotalAmountLbl: Label 'Report Total Amount Due (%1)', Comment = '%1=currency code';
        DataLbl: Label 'Data';
        AgedAccountsPayableLbl: Label 'Aged Accounts Payable';
        CompanyNameLbl: Label 'Company Name';
        ReportNoLbl: Label 'Report No.';
        ReportNameLbl: Label 'Report Name';
        UserIDLbl: Label 'User ID';
        DateTimeLbl: Label 'Date / Time';
        VendorFiltersLbl: Label 'Vendor Filters';
        AmountsAreLbl: Label 'Amounts are';
        InOurFunctionalCurrencyLbl: Label 'In our Functional Currency';
        AsindicatedinDataLbl: Label 'As indicated in Data';
        AgedAsOf2Lbl: Label 'Aged as of';
        AgingDateLbl: Label 'Aging Date (%1)', Comment = '%1=date';
        BalanceDueLbl: Label 'Balance Due';
        DocumentCurrencyLbl: Label 'Document Currency';
        VendorCurrency2Lbl: Label 'Vendor Currency';
        ShowAllForOverdue: Boolean;
        ShowOnlyOverdueLbl: Label 'Show Only Overdue By Needs a Valid Date Formula';
        CalculatedDate: Date;
        OnlyForDueDateLbl: Label 'This option is only allowed for method Due Date';
        VendTotAmountDue: array[4] of Decimal;
        VendTotAmountDueToPrint: Decimal;
        PeriodCalculationRequiredLbl: Label 'You must enter a period calculation in the Length of Aging Periods field.';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Aged_byCaptionLbl: Label 'Aged by';
        NameCaptionLbl: Label 'Name';
        AmountDueToPrint_Control74CaptionLbl: Label 'Balance Due';
        DocNoCaptionLbl: Label 'Number';
        DescriptionCaptionLbl: Label 'Description';
        TypeCaptionLbl: Label 'Type';
        AmountDueToPrint_Control63CaptionLbl: Label 'Balance Due';
        DocumentCaptionLbl: Label 'Document';
        Vendor_Ledger_Entry___Currency_Code_CaptionLbl: Label 'Doc. Curr.';
        Phone_CaptionLbl: Label 'Phone:';
        Contact_CaptionLbl: Label 'Contact:';
        Balance_ForwardCaptionLbl: Label 'Balance Forward';
        Balance_to_Carry_ForwardCaptionLbl: Label 'Balance to Carry Forward';
        Total_Amount_DueCaptionLbl: Label 'Total Amount Due';
        Total_Amount_DueCaption_Control86Lbl: Label 'Total Amount Due';
        GrandBalanceDue: array[4] of Decimal;
        GrandTotalBalanceDue: Decimal;
        TotalNumberOfEntries: Integer;

    local procedure InsertTemp(var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        if TempVendorLedgerEntry.Get(VendLedgEntry."Entry No.") then
            exit;

        TempVendorLedgerEntry := VendLedgEntry;
        case AgingMethod of
            AgingMethod::"Due Date":
                TempVendorLedgerEntry."Posting Date" := TempVendorLedgerEntry."Due Date";
            AgingMethod::"Document Date":
                TempVendorLedgerEntry."Posting Date" := TempVendorLedgerEntry."Document Date";
        end;
        TempVendorLedgerEntry.Insert();
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

    local procedure GetCurrencyRecord(var LocalCurrencyVariable: Record Currency; CurrencyCode: Code[10])
    begin
        if CurrencyCode = '' then begin
            Clear(LocalCurrencyVariable);
            LocalCurrencyVariable.Description := GLSetup."LCY Code";
            LocalCurrencyVariable."Amount Rounding Precision" := GLSetup."Amount Rounding Precision";
        end else
            if LocalCurrencyVariable.Code <> CurrencyCode then
                LocalCurrencyVariable.Get(CurrencyCode);
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
        TempExcelBuffer.SetUseInfoSheet();
        TempExcelBuffer.AddInfoColumn(Format(CompanyNameLbl), false, true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddInfoColumn(CompanyInformation.Name, false, false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.NewRow();
        TempExcelBuffer.AddInfoColumn(Format(ReportNameLbl), false, true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddInfoColumn(Format(AgedAccountsPayableLbl), false, false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.NewRow();
        TempExcelBuffer.AddInfoColumn(Format(ReportNoLbl), false, true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddInfoColumn(REPORT::"Aged Accounts Payable NA", false, false, false, false, '', TempExcelBuffer."Cell Type"::Number);
        TempExcelBuffer.NewRow();
        TempExcelBuffer.AddInfoColumn(Format(UserIDLbl), false, true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddInfoColumn(UserId(), false, false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.NewRow();
        TempExcelBuffer.AddInfoColumn(Format(DateTimeLbl), false, true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddInfoColumn(Today(), false, false, false, false, '', TempExcelBuffer."Cell Type"::Date);
        TempExcelBuffer.AddInfoColumn(Time(), false, false, false, false, '', TempExcelBuffer."Cell Type"::Time);
        TempExcelBuffer.NewRow();
        TempExcelBuffer.AddInfoColumn(Format(VendorFiltersLbl), false, true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddInfoColumn(FilterString, false, false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.NewRow();
        TempExcelBuffer.AddInfoColumn(Format(Aged_byCaptionLbl), false, true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddInfoColumn(DateTitle, false, false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.NewRow();
        TempExcelBuffer.AddInfoColumn(Format(AgedAsOf2Lbl), false, true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddInfoColumn(PeriodEndingDate[1], false, false, false, false, '', TempExcelBuffer."Cell Type"::Date);
        TempExcelBuffer.NewRow();
        TempExcelBuffer.AddInfoColumn(Format(AmountsAreLbl), false, true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        if PrintAmountsInLocal then
            TempExcelBuffer.AddInfoColumn(Format(AsindicatedinDataLbl), false, false, false, false, '', TempExcelBuffer."Cell Type"::Text)
        else
            TempExcelBuffer.AddInfoColumn(Format(InOurFunctionalCurrencyLbl), false, false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.ClearNewRow();
        MakeExcelDataHeader();
    end;

    local procedure MakeExcelDataHeader()
    begin
        TempExcelBuffer.NewRow();
        TempExcelBuffer.AddColumn(TempVendorLedgerEntry.FieldCaption("Vendor No."), false, '', true, false, true, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(Vendor.FieldCaption(Name), false, '', true, false, true, '', TempExcelBuffer."Cell Type"::Text);
        if PrintDetail then begin
            TempExcelBuffer.AddColumn(StrSubstNo(AgingDateLbl, ShortDateTitle), false, '', true, false, true, '', TempExcelBuffer."Cell Type"::Text);
            TempExcelBuffer.AddColumn(TempVendorLedgerEntry.FieldCaption(Description), false, '', true, false, true, '', TempExcelBuffer."Cell Type"::Text);
            TempExcelBuffer.AddColumn(TempVendorLedgerEntry.FieldCaption("Document Type"), false, '', true, false, true, '', TempExcelBuffer."Cell Type"::Text);
            TempExcelBuffer.AddColumn(TempVendorLedgerEntry.FieldCaption("Document No."), false, '', true, false, true, '', TempExcelBuffer."Cell Type"::Text);
        end;
        TempExcelBuffer.AddColumn(Format(BalanceDueLbl), false, '', true, false, true, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(ColumnHead[1], false, '', true, false, true, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(ColumnHead[2], false, '', true, false, true, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(ColumnHead[3], false, '', true, false, true, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(ColumnHead[4], false, '', true, false, true, '', TempExcelBuffer."Cell Type"::Text);
        if PrintAmountsInLocal then
            if PrintDetail then
                TempExcelBuffer.AddColumn(Format(DocumentCurrencyLbl), false, '', true, false, true, '', TempExcelBuffer."Cell Type"::Text)
            else
                TempExcelBuffer.AddColumn(Format(VendorCurrency2Lbl), false, '', true, false, true, '', TempExcelBuffer."Cell Type"::Text);
    end;

    local procedure MakeExcelDataBody()
    var
        CurrencyCodeToPrint: Code[20];
    begin
        TempExcelBuffer.NewRow();
        TempExcelBuffer.AddColumn(Vendor."No.", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(Vendor.Name, false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        if PrintDetail then begin
            TempExcelBuffer.AddColumn(AgingDate, false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Date);
            TempExcelBuffer.AddColumn(TempVendorLedgerEntry.Description, false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
            TempExcelBuffer.AddColumn(Format(TempVendorLedgerEntry."Document Type"), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
            TempExcelBuffer.AddColumn(DocNo, false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        end;
        TempExcelBuffer.AddColumn(-AmountDueToPrint, false, '', false, false, false, '#,##0.00', TempExcelBuffer."Cell Type"::Number);
        TempExcelBuffer.AddColumn(-AmountDue[1], false, '', false, false, false, '#,##0.00', TempExcelBuffer."Cell Type"::Number);
        TempExcelBuffer.AddColumn(-AmountDue[2], false, '', false, false, false, '#,##0.00', TempExcelBuffer."Cell Type"::Number);
        TempExcelBuffer.AddColumn(-AmountDue[3], false, '', false, false, false, '#,##0.00', TempExcelBuffer."Cell Type"::Number);
        TempExcelBuffer.AddColumn(-AmountDue[4], false, '', false, false, false, '#,##0.00', TempExcelBuffer."Cell Type"::Number);
        if PrintAmountsInLocal then begin
            if PrintDetail then
                CurrencyCodeToPrint := TempVendorLedgerEntry."Currency Code"
            else
                CurrencyCodeToPrint := Vendor."Currency Code";

            if CurrencyCodeToPrint = '' then
                CurrencyCodeToPrint := GLSetup."LCY Code";
            TempExcelBuffer.AddColumn(CurrencyCodeToPrint, false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text)
        end;
    end;

    local procedure CreateExcelbook()
    begin
        TempExcelBuffer.CreateBookAndOpenExcel('', DataLbl, AgedAccountsPayableLbl, CompanyName(), UserId());
    end;
}

