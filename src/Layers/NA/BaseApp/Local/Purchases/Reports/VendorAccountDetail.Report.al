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
using Microsoft.Utilities;
using System.Utilities;

report 10103 "Vendor Account Detail"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/VendorAccountDetail.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor Account Detail';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Header; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(Vendor_Account_DetailCaption; Vendor_Account_DetailCaptionLbl)
            {
            }
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
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Vendors_without_balances_are_not_included_Caption; Vendors_without_balances_are_not_included_CaptionLbl)
            {
            }
            column(Vendor__No__Caption; Vendor__No__CaptionLbl)
            {
            }
            column(DocumentCaption; DocumentCaptionLbl)
            {
            }
            column(Net_ChangeCaption; Net_ChangeCaptionLbl)
            {
            }
            column(BalanceToPrint_Control64Caption; BalanceToPrint_Control64CaptionLbl)
            {
            }
            column(DebitsCaption; DebitsCaptionLbl)
            {
            }
            column(CreditsCaption; CreditsCaptionLbl)
            {
            }
            column(DocNoCaption; DocNoCaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry_AmountCaption; Vendor_Ledger_Entry_AmountCaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Currency_Code_Caption; Vendor_Ledger_Entry__Currency_Code_CaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry_OpenCaption; Vendor_Ledger_Entry_OpenCaptionLbl)
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
            column(VendorsCaption; VendorsCaptionLbl)
            {
            }
            column(EntriesCaption; EntriesCaptionLbl)
            {
            }
            column(Control8Caption; CaptionClassTranslate('101,1,' + Text003))
            {
            }
            column(Vendor_Ledger_Entry__Posting_Date_Caption; "Vendor Ledger Entry".FieldCaption("Posting Date"))
            {
            }
            column(Vendor_Ledger_Entry__Document_Type_Caption; Vendor_Ledger_Entry__Document_Type_CaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry_DescriptionCaption; "Vendor Ledger Entry".FieldCaption(Description))
            {
            }
            column(Document_Number_is______Vendor_Ledger_Entry__FIELDCAPTION__External_Document_No___; 'Document Number is ' + "Vendor Ledger Entry".FieldCaption("External Document No."))
            {
            }
            column(GetCurrencyCaptionCode__Currency_Code__; CaptionClassTranslate(GetCurrencyCaptionCode(Vendor."Currency Code")))
            {
            }
            column(Control104Caption; CaptionClassTranslate('101,0,' + Text005))
            {
            }
            column(Vendor_Ledger_Entry___Remaining_Amount_Caption; Vendor_Ledger_Entry___Remaining_Amount_CaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry___Original_Pmt__Disc__Possible_Caption; Vendor_Ledger_Entry___Original_Pmt__Disc__Possible_CaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry___Pmt__Discount_Date_Caption; Vendor_Ledger_Entry___Pmt__Discount_Date_CaptionLbl)
            {
            }
            column(Due_DateCaption; Due_DateCaptionLbl)
            {
            }
            column(TempAppliedVendLedgEntry__Entry_No___Control75Caption; TempAppliedVendLedgEntry__Entry_No___Control75CaptionLbl)
            {
            }
            column(FORMAT_TempAppliedVendLedgEntry__Document_Type__Caption; FORMAT_TempAppliedVendLedgEntry__Document_Type__CaptionLbl)
            {
            }
            column(DocNo_Control55Caption; DocNo_Control55CaptionLbl)
            {
            }
            column(PrintAmountsInLocal; PrintAmountsInLocal)
            {
            }
            column(AllHavingBalance; AllHavingBalance)
            {
            }
            column(UseExternalDocNo; UseExternalDocNo)
            {
            }
            column(AdditionalInformation; AdditionalInformation)
            {
            }
            column(OnlyOnePerPage; OnlyOnePerPage)
            {
            }
            column(Vendor_TABLECAPTION__________FilterString; Vendor.TableCaption + ': ' + FilterString)
            {
            }
            column(FilterString; FilterString)
            {
            }
            column(Vendor_Ledger_Entry__TABLECAPTION__________FilterString2; "Vendor Ledger Entry".TableCaption + ': ' + FilterString2)
            {
            }
            column(FilterString2; FilterString2)
            {
            }
            dataitem(Vendor; Vendor)
            {
                RequestFilterFields = "No.", "Search Name", "Vendor Posting Group", "Date Filter";
                column(NewPagePerGroupNo; NewPagePerGroupNo)
                {
                }
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
                column(ToDate; ToDate)
                {
                }
                column(EndingBalanceToPrint; EndingBalanceToPrint)
                {
                }
                column(VendLedgerEntry2_FiND_; VendLedgerEntry2.FindFirst())
                {
                }
                column(FromDateToPrint; FromDateToPrint)
                {
                }
                column(BalanceToPrint; BalanceToPrint)
                {
                }
                column(TotalVendors; TotalVendors)
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
                column(Vendor_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
                {
                }
                column(Vendor_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
                {
                }
                dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
                {
                    DataItemLink = "Vendor No." = field("No."), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter");
                    DataItemTableView = sorting("Vendor No.", "Currency Code", "Posting Date");
                    RequestFilterFields = "Document Type", Open;
                    column(Vendor_Ledger_Entry__Posting_Date_; "Posting Date")
                    {
                    }
                    column(Vendor_Ledger_Entry__Document_Type_; "Document Type")
                    {
                    }
                    column(DocNo; DocNo)
                    {
                    }
                    column(Vendor_Ledger_Entry_Description; Description)
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
                    column(Vendor_Ledger_Entry_Open; Format(Open))
                    {
                    }
                    column(Vendor_Ledger_Entry__Currency_Code_; "Currency Code")
                    {
                    }
                    column(Vendor_Ledger_Entry_Amount; Amount)
                    {
                    }
                    column(ToDate_Control91; ToDate)
                    {
                    }
                    column(Ending_Balance_for_____Vendor__No__; 'Ending Balance for ' + Vendor."No.")
                    {
                    }
                    column(TotalDebits; TotalDebits)
                    {
                    }
                    column(TotalCredits; TotalCredits)
                    {
                    }
                    column(BalanceToPrint_Control95; BalanceToPrint)
                    {
                    }
                    column(Vendor_TABLECAPTION_____Total_for_____Vendor__No__; Vendor.TableCaption + ' Total for ' + Vendor."No.")
                    {
                    }
                    column(TotalDebits_Control97; TotalDebits)
                    {
                    }
                    column(TotalCredits_Control98; TotalCredits)
                    {
                    }
                    column(BalanceToPrint_Control99; BalanceToPrint)
                    {
                    }
                    column(Vendor_Ledger_Entry_Entry_No_; "Entry No.")
                    {
                    }
                    column(Vendor_Ledger_Entry_Vendor_No_; "Vendor No.")
                    {
                    }
                    column(Vendor_Ledger_Entry_Global_Dimension_1_Code; "Global Dimension 1 Code")
                    {
                    }
                    column(Vendor_Ledger_Entry_Global_Dimension_2_Code; "Global Dimension 2 Code")
                    {
                    }
                    dataitem(OtherInfo; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(Vendor_Ledger_Entry___Entry_No__; "Vendor Ledger Entry"."Entry No.")
                        {
                        }
                        column(Vendor_Ledger_Entry___Remaining_Amount_; "Vendor Ledger Entry"."Remaining Amount")
                        {
                        }
                        column(Vendor_Ledger_Entry___Original_Pmt__Disc__Possible_; "Vendor Ledger Entry"."Original Pmt. Disc. Possible")
                        {
                        }
                        column(Vendor_Ledger_Entry___Pmt__Discount_Date_; "Vendor Ledger Entry"."Pmt. Discount Date")
                        {
                        }
                        column(DueDateToPrint; DueDateToPrint)
                        {
                        }
                        column(DocNo_Control55; DocNo)
                        {
                        }
                        column(FORMAT_TempAppliedVendLedgEntry__Document_Type__; Format(TempAppliedVendLedgEntry."Document Type"))
                        {
                        }
                        column(TempAppliedVendLedgEntry__Entry_No__; TempAppliedVendLedgEntry."Entry No.")
                        {
                        }
                        column(Vendor_Ledger_Entry__Open; "Vendor Ledger Entry".Open)
                        {
                        }
                        column(Closed_by_Entry_No; "Vendor Ledger Entry"."Closed by Entry No.")
                        {
                        }
                        column(VendorClosedbyEntryNo; VendorClosedbyEntryNo)
                        {
                        }
                        column(BalanceToPrintTemp; BalanceToPrintTemp)
                        {
                        }
                        column(DocNoTemp; DocNoTemp)
                        {
                        }
                        column(OtherInfo_Number; Number)
                        {
                        }
                        column(Apply_ToCaption; Apply_ToCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if TempAppliedVendLedgEntry.Find('-') then begin
                                if UseExternalDocNo then
                                    DocNo := TempAppliedVendLedgEntry."External Document No."
                                else
                                    DocNo := TempAppliedVendLedgEntry."Document No.";
                            end else begin
                                DocNo := '';
                                Clear(TempAppliedVendLedgEntry);
                            end;

                            if "Vendor Ledger Entry"."Document Type" <> "Vendor Ledger Entry"."Document Type"::Payment then
                                DueDateToPrint := "Vendor Ledger Entry"."Due Date"
                            else
                                DueDateToPrint := 0D;

                            if "Vendor Ledger Entry"."Pmt. Discount Date" < ToDate then
                                "Vendor Ledger Entry"."Original Pmt. Disc. Possible" := 0;

                            if "Vendor Ledger Entry"."Original Pmt. Disc. Possible" = 0 then
                                "Vendor Ledger Entry"."Pmt. Discount Date" := 0D;

                            VendorClosedbyEntryNo := "Vendor Ledger Entry"."Closed by Entry No."
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
                        column(DocNo_Control81; DocNo)
                        {
                        }
                        column(FORMAT_TempAppliedVendLedgEntry__Document_Type___Control84; Format(TempAppliedVendLedgEntry."Document Type"))
                        {
                        }
                        column(TempAppliedVendLedgEntry__Entry_No___Control75; TempAppliedVendLedgEntry."Entry No.")
                        {
                        }
                        column(AppliedEntries_Number; Number)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            TempAppliedVendLedgEntry.Next();
                            if UseExternalDocNo then
                                DocNo := TempAppliedVendLedgEntry."External Document No."
                            else
                                DocNo := TempAppliedVendLedgEntry."Document No.";
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not AdditionalInformation then
                                CurrReport.Break();
                            SetRange(Number, 2, TempAppliedVendLedgEntry.Count);
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
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

                        BalanceToPrint := BalanceToPrint - AmountToPrint;

                        TotalEntries := TotalEntries + 1;
                        BalanceTotal := BalanceTotal - "Amount (LCY)";

                        if UseExternalDocNo then
                            DocNo := "External Document No."
                        else
                            DocNo := "Document No.";

                        DocNoTemp := DocNo;

                        if AdditionalInformation then
                            EntryAppMgt.GetAppliedVendEntries(TempAppliedVendLedgEntry, "Vendor Ledger Entry", false);

                        if VendorNoTemp <> "Vendor No." then begin
                            VendorNoTemp := "Vendor No.";
                            if FilterString2 <> '' then
                                TotalVendors := TotalVendors + 1;
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        TotalDebits := 0;
                        TotalCredits := 0;
                        SetRange("Posting Date", FromDate, ToDate);
                        SetRange("Date Filter", FromDate, ToDate);

                        if AdditionalInformation then
                            SetAutoCalcFields(Amount, "Amount (LCY)", "Remaining Amount")
                        else
                            SetAutoCalcFields(Amount, "Amount (LCY)");
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if FromDate <> 0D then
                        FromDateToPrint := FromDate - 1
                    else
                        FromDateToPrint := 0D;

                    if PrintAmountsInLocal then
                        if Currency.ReadPermission then begin
                            TempCurrency.DeleteAll();

                            VendLedgerEntry2.Reset();
                            VendLedgerEntry2.SetCurrentKey("Vendor No.", "Currency Code");
                            VendLedgerEntry2.SetRange("Vendor No.", Vendor."No.");
                            VendLedgerEntry2.SetFilter("Posting Date", '%1..%2', FromDate, ToDate);
                            while VendLedgerEntry2.FindFirst() do begin
                                TempCurrency.Init();
                                TempCurrency.Code := VendLedgerEntry2."Currency Code";
                                TempCurrency.Insert();
                                VendLedgerEntry2.SetFilter("Currency Code", '>%1', VendLedgerEntry2."Currency Code");
                            end;
                            GetCurrencyRecord(Currency, "Currency Code");
                        end;

                    /* If Vendor Ledger Filters are being used, we no longer attempt to keep a
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
                        TotalVendors := TotalVendors + 1;  // count if there are no ledger filters
                        VendLedgerEntry2.Reset();
                        VendLedgerEntry2.SetCurrentKey("Vendor No.", "Posting Date");
                        VendLedgerEntry2.SetRange("Vendor No.", "No.");
                        VendLedgerEntry2.SetRange("Posting Date", FromDate, ToDate);
                        BalanceTotal := BalanceTotal + "Net Change (LCY)"; // report total will be in $
                    end;

                    if OnlyOnePerPage then
                        NewPagePerGroupNo += 1;

                end;

                trigger OnPreDataItem()
                begin
                    if DateFilter <> '' then begin
                        FromDate := GetRangeMin("Date Filter");
                        ToDate := GetRangeMax("Date Filter");
                    end else begin
                        FromDate := 0D;
                        ToDate := WorkDate();
                        SetRange("Date Filter", FromDate, ToDate);
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
                    field(PrintAmountsInVendorCurrency; PrintAmountsInLocal)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Print Amounts in Vendor''s Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies if amounts are printed in the vendor''s currency. Clear the check box to print all amounts in US dollars.';
                    }
                    field(OnlyOnePerPage; OnlyOnePerPage)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Page per Account';
                        ToolTip = 'Specifies if you want to print each account on a separate page. Each account will begin at the top of the following page. Otherwise, each account will follow the previous account on the current page.';
                    }
                    field(AccWithBalancesOnly; AllHavingBalance)
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
                            Caption = '   (Terms, Applications, etc.)';
                            ToolTip = 'Specifies that you want to include transaction information regarding payment terms, what entries this entry was applied to, and the remaining (open) amount. If you do not select this field, the report will not contain this additional information.';
                        }
                    }
                    field(UseExternalDocNo; UseExternalDocNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use External Doc. No.';
                        ToolTip = 'Specifies if you want to print the vendor''s document numbers, such as the invoice number, on all transactions. Clear this check box to print only internal document numbers.';
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
        FilterString := Vendor.GetFilters();
        FilterString2 := "Vendor Ledger Entry".GetFilters();
        DateFilter := Vendor.GetFilter("Date Filter");
        if (FilterString2 <> '') and AllHavingBalance then
            Error(Text000 + ' ' + Text001);
    end;

    var
        VendLedgerEntry2: Record "Vendor Ledger Entry";
        TempAppliedVendLedgEntry: Record "Vendor Ledger Entry" temporary;
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
        TotalVendors: Integer;
        TotalEntries: Integer;
        UseExternalDocNo: Boolean;
        DocNo: Code[50];
        Text000: Label 'Do not select Accounts with Balances Only if you';
        Text001: Label 'are also setting Vendor Ledger Entry Filters.';
        Text003: Label 'Amounts are in the vendor''s local currency (report totals are in %1).';
        Text004: Label 'Amounts are in %1';
        Text005: Label 'Report Totals (%1)';
        NewPagePerGroupNo: Integer;
        VendorClosedbyEntryNo: Integer;
        BalanceToPrintTemp: Decimal;
        DocNoTemp: Code[50];
        VendorNoTemp: Code[20];
        Vendor_Account_DetailCaptionLbl: Label 'Vendor Account Detail';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Vendors_without_balances_are_not_included_CaptionLbl: Label 'Vendors without balances are not included.';
        Vendor__No__CaptionLbl: Label 'Vendor';
        DocumentCaptionLbl: Label 'Document';
        Net_ChangeCaptionLbl: Label 'Net Change';
        BalanceToPrint_Control64CaptionLbl: Label 'Running Balance';
        Vendor_Ledger_Entry__Document_Type_CaptionLbl: Label 'Type';
        DebitsCaptionLbl: Label 'Debits';
        CreditsCaptionLbl: Label 'Credits';
        DocNoCaptionLbl: Label 'Number';
        Vendor_Ledger_Entry_AmountCaptionLbl: Label 'Transaction Amount';
        Vendor_Ledger_Entry__Currency_Code_CaptionLbl: Label 'Transaction Currency';
        Vendor_Ledger_Entry_OpenCaptionLbl: Label 'Open';
        Phone_CaptionLbl: Label 'Phone:';
        Contact_CaptionLbl: Label 'Contact:';
        Ending_Balance__no_activity_CaptionLbl: Label 'Ending Balance (no activity)';
        Beginning_BalanceCaptionLbl: Label 'Beginning Balance';
        VendorsCaptionLbl: Label 'Vendors';
        EntriesCaptionLbl: Label 'Entries';
        Vendor_Ledger_Entry___Remaining_Amount_CaptionLbl: Label 'Remaining Amount';
        Vendor_Ledger_Entry___Original_Pmt__Disc__Possible_CaptionLbl: Label 'Pmt. Disc. Possible';
        Vendor_Ledger_Entry___Pmt__Discount_Date_CaptionLbl: Label 'Discount Date';
        Due_DateCaptionLbl: Label 'Due Date';
        Apply_ToCaptionLbl: Label 'Apply To';
        TempAppliedVendLedgEntry__Entry_No___Control75CaptionLbl: Label 'Entry No.';
        FORMAT_TempAppliedVendLedgEntry__Document_Type__CaptionLbl: Label 'Type';
        DocNo_Control55CaptionLbl: Label 'Number';

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

