#pragma warning disable AA0247
report 14910 "Customer - Reconciliation Act"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Customer Reconciliations';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Agreement Filter";
            dataitem(OldCustInvoices; "Cust. Ledger Entry")
            {
                DataItemLink = "Customer No." = field("No."), "Agreement No." = field("Agreement Filter");
                DataItemTableView = sorting("Document Type", "Customer No.", "Posting Date", "Currency Code") where("Document Type" = filter(" " | Invoice | "Credit Memo"));
                dataitem(OldAppldCustPays2; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then begin
                            if not TempAppDtldCustLedgEntry.FindSet() then
                                CurrReport.Break();
                        end else
                            if TempAppDtldCustLedgEntry.Next() = 0 then
                                CurrReport.Break();

                        OldAppldCustPays."Entry Type" := OldAppldCustPays."Entry Type"::Application;
                        CustPayProcessing(OldAppldCustPays, OldCustInvoices, CurrencyCode);
                        PayCounter += 1;
                        if (CurrencyCode = '') or (CustLedgEntry."Currency Code" = CurrencyCode) then
                            CurrCodeToShow := ''
                        else
                            CurrCodeToShow := CustLedgEntry."Currency Code";

                        if (ShowDetails = 0) and ((CurrencyCode = '') or (CustLedgEntry."Currency Code" = CurrencyCode)) then
                            FillBody(
                              Format(InvCounter) + '.' + Format(PayCounter), Format(PostingDate), EntryDescription,
                              FormatAmount(DocumentAmount), DebitAppliedAmt, CreditAppliedAmt, false);
                    end;
                }
                dataitem(OldAppldCustPays; "Detailed Cust. Ledg. Entry")
                {
                    DataItemLink = "Cust. Ledger Entry No." = field("Entry No.");
                    DataItemTableView = sorting("Cust. Ledger Entry No.", "Entry Type", "Posting Date") where("Entry Type" = filter("Realized Gain" | "Unrealized Gain" | "Realized Loss" | "Unrealized Loss"));

                    trigger OnAfterGetRecord()
                    begin
                        CustPayProcessing(OldAppldCustPays, OldCustInvoices, CurrencyCode);
                        PayCounter += 1;
                        if (CurrencyCode = '') or (CustLedgEntry."Currency Code" = CurrencyCode) then
                            CurrCodeToShow := ''
                        else
                            CurrCodeToShow := CustLedgEntry."Currency Code";

                        if ShowDetails = 0 then begin
                            if (CurrencyCode = '') or (CustLedgEntry."Currency Code" = CurrencyCode) then
                                FillBody(
                                  Format(InvCounter) + '.' + Format(PayCounter), Format(PostingDate), EntryDescription,
                                  FormatAmount(DocumentAmount), DebitAppliedAmt, CreditAppliedAmt, false);
                            if not ((CurrencyCode = '') or (CustLedgEntry."Currency Code" = CurrencyCode)) then
                                FillBody(
                                  Format(InvCounter) + '.' + Format(PayCounter), Format(PostingDate), EntryDescription,
                                  CustLedgEntry."Currency Code", DebitAppliedAmt, CreditAppliedAmt, false);
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetFilter("Posting Date", DateFilter);
                        PayCounter := 0;
                    end;
                }
                dataitem(OldCustInvTotal; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));

                    trigger OnAfterGetRecord()
                    begin
                        DebitBalance2 += TotalPayAmount;
                        AdjustTotalsBalance(TotalPayAmount, TotalInvAmount);

                        CustDocTotals(OldCustInvoices, CurrencyCode, TotalInvAmount, TotalPayAmount);

                        if ShowDetails < 2 then
                            FillFooter(GetCustEntryDescription(OldCustInvoices), TotalInvAmount, TotalPayAmount, CustCorrection);
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    IsAgreementTransfer: Boolean;
                    DocumentAmountTmp: Decimal;
                begin
                    IsAgreementTransfer := CheckCustTransfBetweenAgreements(OldCustInvoices);

                    SetFilter("Date Filter", '..%1', FirstDate);
                    GetCustAmounts(OldCustInvoices, CurrencyCode, TempAmount, RemainingAmount);

                    if RemainingAmount <> 0 then
                        FindAppldCustLedgEntry("Entry No.", 0D, MaxDate)
                    else
                        if FindAppldCustLedgEntry("Entry No.", MinDate, MaxDate) then
                            FindAppldCustLedgEntry("Entry No.", 0D, MaxDate)
                        else
                            CurrReport.Skip();

                    SetFilter("Date Filter", '..%1', "Posting Date");
                    GetCustAmounts(OldCustInvoices, CurrencyCode, DocumentAmount, TempAmount);

                    if IsAgreementTransfer then begin
                        DocumentAmountTmp := DocumentAmount;
                        DocumentAmount := RemainingAmount;
                    end;

                    if DocumentAmount < 0 then begin
                        CreditTurnover2 += -DocumentAmount;
                        TotalPayAmount := -DocumentAmount;
                        TotalInvAmount := 0;
                        DocumentAmount := -DocumentAmount;
                        RemainingCreditAmount := DocumentAmount;
                        RemainingAmount := 0;
                        DocumentAmountTmp := -DocumentAmountTmp;
                    end else begin
                        DebitTurnover2 += DocumentAmount;
                        TotalInvAmount := DocumentAmount;
                        TotalPayAmount := 0;
                        RemainingAmount := DocumentAmount;
                        RemainingCreditAmount := 0;
                    end;
                    InvCounter += 1;

                    ShowCustRemAmount(OldCustInvoices, CurrencyCode, RemainingAmount, RemainingCreditAmount);

                    EntryDescription := GetCustEntryDescription(OldCustInvoices);

                    if IsAgreementTransfer then
                        DocumentAmount := DocumentAmountTmp;

                    CustCorrection := IsCustCorrection(OldCustInvoices);

                    if ShowDetails < 2 then
                        FillBody(
                          Format(InvCounter), Format("Posting Date"), EntryDescription,
                          FormatAmount(DocumentAmount), RemainingAmount, RemainingCreditAmount, CustCorrection);
                end;

                trigger OnPreDataItem()
                begin
                    SetFilter("Currency Code", CurrencyCode);
                    SetFilter("Posting Date", '..%1', FirstDate);

                    if (not OldCustInvoices.IsEmpty) and (ShowDetails < 2) then
                        ReconActReportHelper.FillPrevHeader();
                end;
            }
            dataitem(CustInvoices; "Cust. Ledger Entry")
            {
                DataItemLink = "Customer No." = field("No."), "Agreement No." = field("Agreement Filter");
                DataItemTableView = sorting("Document Type", "Customer No.", "Posting Date", "Currency Code") where("Document Type" = filter(" " | Invoice | "Credit Memo"), Reversed = const(false));
                dataitem(AppldCustPays2; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then begin
                            if not TempAppDtldCustLedgEntry.FindSet() then
                                CurrReport.Break();
                        end else
                            if TempAppDtldCustLedgEntry.Next() = 0 then
                                CurrReport.Break();

                        AppldCustPays."Entry Type" := AppldCustPays."Entry Type"::Application;
                        CustPayProcessing(AppldCustPays, CustInvoices, CurrencyCode);
                        PayCounter += 1;
                        if (CurrencyCode = '') or (CustLedgEntry."Currency Code" = CurrencyCode) then
                            CurrCodeToShow := ''
                        else
                            CurrCodeToShow := CustLedgEntry."Currency Code";

                        if (ShowDetails <= 1) and ((CurrencyCode = '') or (CustLedgEntry."Currency Code" = CurrencyCode)) then
                            FillBody(
                              Format(InvCounter) + '.' + Format(PayCounter), Format(PostingDate), EntryDescription,
                              FormatAmount(DocumentAmount), DebitAppliedAmt, CreditAppliedAmt, false);
                    end;
                }
                dataitem(AppldCustPays; "Detailed Cust. Ledg. Entry")
                {
                    DataItemLink = "Cust. Ledger Entry No." = field("Entry No.");
                    DataItemTableView = sorting("Cust. Ledger Entry No.", "Entry Type", "Posting Date") where("Entry Type" = filter("Realized Gain" | "Unrealized Gain" | "Realized Loss" | "Unrealized Loss"));

                    trigger OnAfterGetRecord()
                    begin
                        CustPayProcessing(AppldCustPays, CustInvoices, CurrencyCode);
                        PayCounter += 1;
                        if (CurrencyCode = '') or (CustLedgEntry."Currency Code" = CurrencyCode) then
                            CurrCodeToShow := ''
                        else
                            CurrCodeToShow := CustLedgEntry."Currency Code";

                        if ShowDetails <= 1 then begin
                            if (CurrencyCode = '') or (CustLedgEntry."Currency Code" = CurrencyCode) then
                                FillBody(
                                  Format(InvCounter) + '.' + Format(PayCounter), Format(PostingDate), EntryDescription,
                                  FormatAmount(DocumentAmount), DebitAppliedAmt, CreditAppliedAmt, false);
                            if not ((CurrencyCode = '') or (CustLedgEntry."Currency Code" = CurrencyCode)) then
                                FillBody(
                                  Format(InvCounter) + '.' + Format(PayCounter), Format(PostingDate), EntryDescription,
                                  CustLedgEntry."Currency Code", DebitAppliedAmt, CreditAppliedAmt, false);
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetFilter("Posting Date", DateFilter);
                        PayCounter := 0;
                    end;
                }
                dataitem(CustInvTotal; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));

                    trigger OnAfterGetRecord()
                    begin
                        DebitBalance2 += TotalInvAmount;
                        CreditBalance2 += TotalPayAmount;
                        if not AppliedToPayment then begin
                            CreditTurnover2 += CreditAppliedAmt;
                            DebitTurnover2 += DebitAppliedAmt;
                            CreditAppliedAmt := 0;
                            DebitAppliedAmt := 0;
                        end;
                        AppliedToPayment := false;

                        AdjustTotalsBalance(TotalInvAmount, TotalPayAmount);

                        CustDocTotals(CustInvoices, CurrencyCode, TotalInvAmount, TotalPayAmount);

                        if ShowDetails < 2 then
                            FillFooter(GetCustEntryDescription(CustInvoices), TotalInvAmount, TotalPayAmount, CustCorrection);
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    IsAgreementTransfer: Boolean;
                    DocumentAmountTmp: Decimal;
                    PrepmtDiffAmount: Decimal;
                begin
                    IsAgreementTransfer := CheckCustTransfBetweenAgreements(CustInvoices);

                    if ExcludeCustDoc(CustInvoices, CurrencyCode) then
                        CurrReport.Skip();

                    SetFilter("Date Filter", '..%1', "Posting Date");
                    GetCustAmounts(CustInvoices, CurrencyCode, DocumentAmount, TempAmount);
                    GetCustPrepmtDiffAmount(CustInvoices, CurrencyCode, PrepmtDiffAmount);

                    SetFilter("Date Filter", DateFilter);
                    GetCustAmounts(CustInvoices, CurrencyCode, TempAmount, RemainingAmount);

                    if IsAgreementTransfer then begin
                        DocumentAmountTmp := DocumentAmount;
                        DocumentAmount := RemainingAmount;
                    end;

                    if DocumentAmount < 0 then begin
                        CreditTurnover2 += -DocumentAmount;
                        CreditTurnover2 += -PrepmtDiffAmount;
                        TotalPayAmount := -DocumentAmount;
                        TotalInvAmount := 0;
                        DocumentAmount := -DocumentAmount;
                        RemainingCreditAmount := DocumentAmount;
                        RemainingAmount := 0;
                        DocumentAmountTmp := -DocumentAmountTmp;
                    end else begin
                        DebitTurnover2 += DocumentAmount;
                        DebitTurnover2 += PrepmtDiffAmount;
                        TotalInvAmount := DocumentAmount;
                        TotalPayAmount := 0;
                        RemainingAmount := DocumentAmount;
                        RemainingCreditAmount := 0;
                    end;
                    InvCounter += 1;

                    ShowCustRemAmount(CustInvoices, CurrencyCode, RemainingAmount, RemainingCreditAmount);

                    EntryDescription := GetCustEntryDescription(CustInvoices);

                    FindAppldCustLedgEntry("Entry No.", 0D, MaxDate);
                    if IsAgreementTransfer then
                        DocumentAmount := DocumentAmountTmp;

                    CustCorrection := IsCustCorrection(CustInvoices);

                    if ShowDetails < 2 then
                        FillBody(
                          Format(InvCounter), Format("Posting Date"), EntryDescription,
                          FormatAmount(DocumentAmount), RemainingAmount, RemainingCreditAmount, CustCorrection);
                end;

                trigger OnPreDataItem()
                begin
                    SetFilter("Currency Code", CurrencyCode);
                    SetFilter("Posting Date", DateFilter);
                    InvCounter := 0;
                    PayCounter := 0;
                    TotalInvAmount := 0;
                    TotalPayAmount := 0;
                    RemainingAmount := 0;
                    RemainingCreditAmount := 0;
                    CreditTurnover2 := 0;
                    DebitTurnover2 := 0;

                    if (not CustInvoices.IsEmpty) and (ShowDetails < 2) then
                        ReconActReportHelper.FillHeader(MinDate, MaxDate);
                end;
            }
            dataitem(CustPayments; "Cust. Ledger Entry")
            {
                DataItemLink = "Customer No." = field("No."), "Agreement No." = field("Agreement Filter");
                DataItemTableView = sorting("Document Type", "Customer No.", "Posting Date", "Currency Code") where("Document Type" = filter(Payment | Refund), Reversed = const(false));
                dataitem(CustOtherCurrAppln; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));

                    trigger OnAfterGetRecord()
                    begin
                        if OtherCurrApplAmount = 0 then
                            CurrReport.Skip();
                        InvCounter += 1;

                        if ShowDetails = 2 then
                            FillAdvOtherCurrBody(
                              Format(PayCounter) + '.' + Format(InvCounter), GetCustEntryDescription(CustPayments),
                              FormatAmount(OtherCurrApplAmount), FormatAmount(0),
                              FormatAmount(0), FormatAmount(RemainingAmount));
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if ExcludeCustDoc(CustPayments, CurrencyCode) then
                        CurrReport.Skip();

                    SetFilter("Date Filter", DateFilter);
                    GetCustPay(CustPayments, CurrencyCode, DocumentAmount, RemainingAmount, OtherCurrApplAmount);

                    CreditTurnover2 += DocumentAmount;

                    if ShowDetails = ShowDetails::Full then
                        if (RemainingAmount + OtherCurrApplAmount = 0) and ("Document Type" <> "Document Type"::Refund) then
                            CurrReport.Skip();
                    TotalPayAmount += RemainingAmount;
                    PayCounter += 1;

                    ShowCustRemAmount(CustPayments, CurrencyCode, RemainingDebitAmount, RemainingAmount);

                    if "Document Type" = "Document Type"::Refund then
                        Description := CopyStr(Description + ' (' + "Applies-to Doc. No." + ')', 1, MaxStrLen(Description));

                    if ShowDetails < 2 then
                        FillBody(
                          Format(PayCounter), Format("Posting Date"), GetCustEntryDescription(CustPayments),
                          FormatAmount(DocumentAmount), RemainingDebitAmount, RemainingAmount, false);
                end;

                trigger OnPostDataItem()
                begin
                    CreditBalance2 += TotalPayAmount;

                    if (ShowDetails < 2) and (not CustPayments.IsEmpty) then
                        FillAdvFooter(
                          MaxDate, FormatAmount(0), FormatAmount(TotalPayAmount));
                end;

                trigger OnPreDataItem()
                begin
                    SetFilter("Currency Code", CurrencyCode);
                    SetFilter("Posting Date", DateFilter);
                    PayCounter := 0;
                    InvCounter := 0;
                    TotalInvAmount := 0;
                    TotalPayAmount := 0;

                    if (ShowDetails < 2) and (not CustPayments.IsEmpty) then
                        ReconActReportHelper.FillAdvHeader(MinDate, MaxDate);
                end;
            }
            dataitem(OldCustPayments; "Cust. Ledger Entry")
            {
                DataItemLink = "Customer No." = field("No."), "Agreement No." = field("Agreement Filter");
                DataItemTableView = sorting("Document Type", "Customer No.", "Posting Date", "Currency Code") where("Document Type" = filter(Payment | Refund), Open = const(true));
                dataitem(OldCustOtherCurrAppln; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));

                    trigger OnAfterGetRecord()
                    begin
                        if OtherCurrApplAmount = 0 then
                            CurrReport.Skip();
                        InvCounter += 1;

                        if ShowDetails = 2 then
                            FillAdvOtherCurrBody(
                              Format(PayCounter) + '.' + Format(InvCounter), GetCustEntryDescription(OldCustPayments),
                              FormatAmount(OtherCurrApplAmount), FormatAmount(0),
                              FormatAmount(0), FormatAmount(RemainingAmount));
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if CustEntryIsClosed(OldCustPayments, CurrencyCode, MaxDate) then
                        CurrReport.Skip();

                    SetFilter("Date Filter", '..%1', MaxDate);
                    GetCustPay(OldCustPayments, CurrencyCode, DocumentAmount, RemainingAmount, OtherCurrApplAmount);

                    if RemainingAmount + OtherCurrApplAmount = 0 then
                        CurrReport.Skip();
                    TotalPayAmount += RemainingAmount;
                    PayCounter += 1;
                    InvCounter := 0;

                    ShowCustRemAmount(OldCustPayments, CurrencyCode, RemainingDebitAmount, RemainingAmount);

                    if "Document Type" = "Document Type"::Refund then
                        Description := CopyStr(Description + ' (' + "Applies-to Doc. No." + ')', 1, MaxStrLen(Description));

                    if ShowDetails < 2 then
                        FillBody(
                          Format(PayCounter), Format("Posting Date"), GetCustEntryDescription(OldCustPayments),
                          FormatAmount(DocumentAmount), RemainingDebitAmount, RemainingAmount, false);
                end;

                trigger OnPostDataItem()
                begin
                    CreditBalance += TotalPayAmount;

                    if (ShowDetails < 2) and (not OldCustPayments.IsEmpty) then
                        FillPrevAdvFooter(
                          MaxDate, FormatAmount(0), FormatAmount(TotalPayAmount));
                end;

                trigger OnPreDataItem()
                begin
                    SetFilter("Currency Code", CurrencyCode);
                    SetFilter("Posting Date", '..%1', FirstDate);
                    PayCounter := 0;
                    TotalPayAmount := 0;

                    if (ShowDetails < 2) and (not OldCustPayments.IsEmpty) then
                        ReconActReportHelper.FillPrevAdvHeader(MinDate);
                end;
            }
            dataitem(CustTotal; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));

                trigger OnAfterGetRecord()
                begin
                    DtldCustLedgEntry.Reset();
                    DtldCustLedgEntry.SetRange("Customer No.", Customer."No.");
                    DtldCustLedgEntry.SetRange("Posting Date", MinDate, MaxDate);
                    DtldCustLedgEntry.SetFilter("Entry Type", '<>%1', DtldCustLedgEntry."Entry Type"::Application);
                    DtldCustLedgEntry.SetFilter("Agreement No.", Customer.GetFilter("Agreement Filter"));
                    DtldCustLedgEntry.SetFilter("Currency Code", CurrencyCode);
                    DtldCustLedgEntry.CalcSums("Debit Amount", "Debit Amount (LCY)", "Credit Amount", "Credit Amount (LCY)");
                    if CurrencyCode = '' then begin
                        DebitTurnover2 := DtldCustLedgEntry."Debit Amount (LCY)" - ExclAmountDebit;
                        CreditTurnover2 := DtldCustLedgEntry."Credit Amount (LCY)" - ExclAmountCredit;
                    end else begin
                        DebitTurnover2 := DtldCustLedgEntry."Debit Amount" - ExclAmountDebit;
                        CreditTurnover2 := DtldCustLedgEntry."Credit Amount" - ExclAmountCredit;
                    end;
                    DebitBalance2 := InitialDebitBalance2 + DebitTurnover2;
                    CreditBalance2 := InitialCreditBalance2 + CreditTurnover2;
                    AdjustTotalsBalance(DebitBalance2, CreditBalance2);

                    InitialDebitBalance := InitialDebitBalance2;
                    InitialCreditBalance := InitialCreditBalance2;
                    DebitTurnover := DebitTurnover2;
                    CreditTurnover := CreditTurnover2;
                    DebitBalance := DebitBalance2;
                    CreditBalance := CreditBalance2;

                    FillCustFooter(
                      MinDate, MaxDate,
                      FormatAmount(DebitTurnover2), FormatAmount(CreditTurnover2),
                      FormatAmount(DebitBalance2), FormatAmount(CreditBalance2));
                end;
            }
            dataitem(Vendor; Vendor)
            {
                DataItemLink = "Customer No." = field("No.");
                DataItemTableView = sorting("No.");
                PrintOnlyIfDetail = true;
                dataitem(OldVendInvoices; "Vendor Ledger Entry")
                {
                    DataItemLink = "Vendor No." = field("No."), "Agreement No." = field("Agreement Filter");
                    DataItemTableView = sorting("Document Type", "Vendor No.", "Posting Date", "Currency Code") where("Document Type" = filter(" " | Invoice | "Credit Memo"));
                    dataitem(OldAppldVendPays2; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = filter(1 ..));

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then begin
                                if not TempAppDtldVendLedgEntry.FindSet() then
                                    CurrReport.Break();
                            end else
                                if TempAppDtldVendLedgEntry.Next() = 0 then
                                    CurrReport.Break();

                            if not (TempAppDtldVendLedgEntry."Posting Date" in [MinDate .. MaxDate]) then
                                CurrReport.Skip();

                            OldAppldVendPays."Entry Type" := OldAppldVendPays."Entry Type"::Application;
                            VendPayProcessing(OldAppldVendPays, OldVendInvoices, false, CurrencyCode);
                            PayCounter += 1;
                            if (CurrencyCode = '') or (CustLedgEntry."Currency Code" = CurrencyCode) then
                                CurrCodeToShow := ''
                            else
                                CurrCodeToShow := VendLedgEntry."Currency Code";

                            if (ShowDetails = 0) and ((CurrencyCode = '') or (VendLedgEntry."Currency Code" = CurrencyCode)) then
                                FillBody(
                                  Format(InvCounter) + '.' + Format(PayCounter), Format(PostingDate), EntryDescription,
                                  FormatAmount(DocumentAmount), DebitAppliedAmt, CreditAppliedAmt, false);
                        end;
                    }
                    dataitem(OldAppldVendPays; "Detailed Vendor Ledg. Entry")
                    {
                        DataItemLink = "Vendor Ledger Entry No." = field("Entry No.");
                        DataItemTableView = sorting("Document Type", "Vendor No.", "Posting Date", "Currency Code") where("Entry Type" = filter("Realized Gain" | "Unrealized Gain" | "Realized Loss" | "Unrealized Loss"));

                        trigger OnAfterGetRecord()
                        begin
                            VendPayProcessing(OldAppldVendPays, OldVendInvoices, false, CurrencyCode);
                            PayCounter += 1;
                            if (CurrencyCode = '') or (CustLedgEntry."Currency Code" = CurrencyCode) then
                                CurrCodeToShow := ''
                            else
                                CurrCodeToShow := VendLedgEntry."Currency Code";

                            if ShowDetails = 0 then begin
                                if (CurrencyCode = '') or (VendLedgEntry."Currency Code" = CurrencyCode) then
                                    FillBody(
                                      Format(InvCounter) + '.' + Format(PayCounter), Format(PostingDate), EntryDescription,
                                      FormatAmount(DocumentAmount), DebitAppliedAmt, CreditAppliedAmt, false);
                                if not ((CurrencyCode = '') or (VendLedgEntry."Currency Code" = CurrencyCode)) then
                                    FillBody(
                                      Format(InvCounter) + '.' + Format(PayCounter), Format(PostingDate), EntryDescription,
                                      VendLedgEntry."Currency Code", DebitAppliedAmt, CreditAppliedAmt, false);
                            end;
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetFilter("Posting Date", DateFilter);
                            PayCounter := 0;
                        end;
                    }
                    dataitem(OldVendInvTotal; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));

                        trigger OnAfterGetRecord()
                        begin
                            CreditBalance2 += TotalInvAmount;

                            if ShowDetails < 2 then
                                FillFooter(GetVendEntryDescription(OldVendInvoices), 0, TotalInvAmount, false);
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        SetFilter("Date Filter", '..%1', FirstDate);
                        GetVendAmounts(OldVendInvoices, CurrencyCode, TempAmount, RemainingAmount);
                        RemainingAmount := -RemainingAmount;
                        if RemainingAmount = 0 then
                            CurrReport.Skip();

                        IsInvProcessedInPrevPeriod("Entry No.", false);

                        SetFilter("Date Filter", '..%1', "Posting Date");
                        GetVendAmounts(OldVendInvoices, CurrencyCode, DocumentAmount, TempAmount);
                        DocumentAmount := -DocumentAmount;
                        TotalInvAmount := RemainingAmount;
                        InvCounter += 1;
                        EntryDescription := GetVendEntryDescription(OldVendInvoices);

                        FindAppldVendLedgEntry("Entry No.");

                        if ShowDetails < 2 then
                            FillBody(
                              Format(InvCounter), Format("Posting Date"), EntryDescription,
                              FormatAmount(DocumentAmount), 0, RemainingAmount, false);
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetFilter("Currency Code", CurrencyCode);
                        SetFilter("Posting Date", '..%1', FirstDate);

                        if (not IsEmpty) and (ShowDetails < 2) then
                            ReconActReportHelper.FillPrevHeader();
                    end;
                }
                dataitem(VendInvoices; "Vendor Ledger Entry")
                {
                    DataItemLink = "Vendor No." = field("No."), "Agreement No." = field("Agreement Filter");
                    DataItemTableView = sorting("Vendor No.", "Posting Date", "Currency Code", "Agreement No.") where("Document Type" = filter(" " | Invoice | "Credit Memo"), Reversed = const(false));
                    dataitem(AppldVendPays2; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = filter(1 ..));

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then begin
                                if not TempAppDtldVendLedgEntry.FindSet() then
                                    CurrReport.Break();
                            end else
                                if TempAppDtldVendLedgEntry.Next() = 0 then
                                    CurrReport.Break();

                            if TempAppDtldVendLedgEntry."Posting Date" < MinDate then
                                CurrReport.Skip();

                            AppldVendPays."Entry Type" := AppldVendPays."Entry Type"::Application;
                            VendPayProcessing(AppldVendPays, VendInvoices, true, CurrencyCode);
                            PayCounter += 1;
                            if (CurrencyCode = '') or (CustLedgEntry."Currency Code" = CurrencyCode) then
                                CurrCodeToShow := ''
                            else
                                CurrCodeToShow := VendLedgEntry."Currency Code";

                            if (ShowDetails = 0) and ((CurrencyCode = '') or (VendLedgEntry."Currency Code" = CurrencyCode)) then
                                FillBody(
                                  Format(InvCounter) + '.' + Format(PayCounter), Format(PostingDate), EntryDescription,
                                  FormatAmount(DocumentAmount), DebitAppliedAmt, CreditAppliedAmt, false);
                        end;
                    }
                    dataitem(AppldVendPays; "Detailed Vendor Ledg. Entry")
                    {
                        DataItemLink = "Vendor Ledger Entry No." = field("Entry No.");
                        DataItemTableView = sorting("Vendor Ledger Entry No.", "Entry Type", "Posting Date") where("Entry Type" = filter("Realized Gain" | "Unrealized Gain" | "Realized Loss" | "Unrealized Loss"));

                        trigger OnAfterGetRecord()
                        begin
                            VendPayProcessing(AppldVendPays, VendInvoices, true, CurrencyCode);
                            PayCounter += 1;
                            if (CurrencyCode = '') or (CustLedgEntry."Currency Code" = CurrencyCode) then
                                CurrCodeToShow := ''
                            else
                                CurrCodeToShow := VendLedgEntry."Currency Code";

                            if ShowDetails = 0 then begin
                                if (CurrencyCode = '') or (VendLedgEntry."Currency Code" = CurrencyCode) then
                                    FillBody(
                                      Format(InvCounter) + '.' + Format(PayCounter), Format(PostingDate), EntryDescription,
                                      FormatAmount(DocumentAmount), DebitAppliedAmt, CreditAppliedAmt, false);
                                if not ((CurrencyCode = '') or (VendLedgEntry."Currency Code" = CurrencyCode)) then
                                    FillBody(
                                      Format(InvCounter) + '.' + Format(PayCounter), Format(PostingDate), EntryDescription,
                                      VendLedgEntry."Currency Code", DebitAppliedAmt, CreditAppliedAmt, false);
                            end;
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetFilter("Posting Date", DateFilter);
                            PayCounter := 0;
                        end;
                    }
                    dataitem(VendInvTotal; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));

                        trigger OnAfterGetRecord()
                        begin
                            if VendInvoices."Posting Date" in [MinDate .. MaxDate] then
                                CreditBalance2 += TotalInvAmount;

                            if ShowDetails < 2 then
                                FillFooter(GetVendEntryDescription(VendInvoices), 0, TotalInvAmount, false);
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if ExcludeVendDoc(VendInvoices, CurrencyCode) then
                            CurrReport.Skip();

                        if "Posting Date" <= FirstDate then
                            if (not CurrentPeriodApplicationExists("Entry No.")) or IsInvProcessedInPrevPeriod("Entry No.", true) then
                                CurrReport.Skip();

                        SetFilter("Date Filter", '..%1', "Posting Date");
                        GetVendAmounts(VendInvoices, CurrencyCode, DocumentAmount, TempAmount);
                        DocumentAmount := -DocumentAmount;
                        if "Posting Date" in [MinDate .. MaxDate] then
                            CreditTurnover2 += DocumentAmount;

                        SetFilter("Date Filter", DateFilter);
                        GetVendAmounts(VendInvoices, CurrencyCode, TempAmount, RemainingAmount);
                        RemainingAmount := -RemainingAmount;

                        TotalInvAmount := DocumentAmount;
                        RemainingAmount := -GetInvRemAmtAtDate("Entry No.");
                        if "Posting Date" <= FirstDate then
                            TotalInvAmount := RemainingAmount;
                        InvCounter += 1;
                        EntryDescription := GetVendEntryDescription(VendInvoices);

                        FindAppldVendLedgEntry("Entry No.");

                        if ShowDetails < 2 then
                            FillBody(
                              Format(InvCounter), Format("Posting Date"), EntryDescription,
                              FormatAmount(DocumentAmount), 0, RemainingAmount, false);
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetFilter("Currency Code", CurrencyCode);
                        SetRange("Posting Date", 0D, MaxDate);
                        InvCounter := 0;

                        if (not IsEmpty) and (ShowDetails < 2) then
                            ReconActReportHelper.FillHeader(MinDate, MaxDate);
                    end;
                }
                dataitem(VendPayments; "Vendor Ledger Entry")
                {
                    DataItemLink = "Vendor No." = field("No."), "Agreement No." = field("Agreement Filter");
                    DataItemTableView = sorting("Document Type", "Vendor No.", "Posting Date", "Currency Code") where("Document Type" = filter(Payment | Refund), Reversed = const(false));
                    dataitem(VendOtherCurrAppln; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));

                        trigger OnAfterGetRecord()
                        begin
                            if OtherCurrApplAmount = 0 then
                                CurrReport.Skip();
                            InvCounter += 1;

                            if ShowDetails = 2 then
                                FillAdvOtherCurrBody(
                                  Format(PayCounter) + '.' + Format(InvCounter), GetVendEntryDescription(VendPayments),
                                  FormatAmount(0), FormatAmount(OtherCurrApplAmount),
                                  FormatAmount(RemainingAmount), FormatAmount(0));
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if ExcludeVendDoc(VendPayments, CurrencyCode) then
                            CurrReport.Skip();

                        SetFilter("Date Filter", DateFilter);
                        GetVendPay(VendPayments, CurrencyCode, DocumentAmount, RemainingAmount, OtherCurrApplAmount);

                        if (RemainingAmount + OtherCurrApplAmount = 0) and ("Document Type" <> "Document Type"::Refund) then
                            CurrReport.Skip();
                        DebitTurnover2 += RemainingAmount + OtherCurrApplAmount;
                        TotalPayAmount += RemainingAmount;
                        PayCounter += 1;
                        InvCounter := 0;
                        if "Document Type" = "Document Type"::Refund then
                            Description := CopyStr(Description + ' (' + "Applies-to Doc. No." + ')', 1, MaxStrLen(Description));

                        if ShowDetails < 2 then
                            FillBody(
                              Format(PayCounter), Format("Posting Date"), GetVendEntryDescription(VendPayments),
                              FormatAmount(DocumentAmount), RemainingAmount, 0, false);
                    end;

                    trigger OnPostDataItem()
                    begin
                        DebitBalance2 += TotalPayAmount;

                        if (ShowDetails < 2) and (not IsEmpty) then
                            FillAdvFooter(
                              MaxDate, FormatAmount(TotalPayAmount), FormatAmount(0));
                    end;

                    trigger OnPreDataItem()
                    begin
                        if CurrencyCode <> '' then
                            SetFilter("Currency Code", CurrencyCode);
                        SetFilter("Posting Date", DateFilter);
                        PayCounter := 0;

                        if (ShowDetails < 2) and (not IsEmpty) then
                            ReconActReportHelper.FillAdvHeader(MinDate, MaxDate);
                    end;
                }
                dataitem(OldVendPayments; "Vendor Ledger Entry")
                {
                    DataItemLink = "Vendor No." = field("No."), "Agreement No." = field("Agreement Filter");
                    DataItemTableView = sorting("Document Type", "Vendor No.", "Posting Date", "Currency Code") where("Document Type" = filter(Payment | Refund), Open = const(true));
                    dataitem(OldVendOtherCurrAppln; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));

                        trigger OnAfterGetRecord()
                        begin
                            if OtherCurrApplAmount = 0 then
                                CurrReport.Skip();
                            InvCounter += 1;

                            if ShowDetails = 2 then
                                FillAdvOtherCurrBody(
                                  Format(PayCounter) + '.' + Format(InvCounter), GetVendEntryDescription(OldVendPayments),
                                  FormatAmount(0), FormatAmount(OtherCurrApplAmount),
                                  FormatAmount(RemainingAmount), FormatAmount(0));
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        SetFilter("Date Filter", '..%1', MaxDate);
                        GetVendPay(OldVendPayments, CurrencyCode, DocumentAmount, RemainingAmount, OtherCurrApplAmount);

                        if RemainingAmount + OtherCurrApplAmount = 0 then
                            CurrReport.Skip();
                        TotalPayAmount += RemainingAmount;
                        PayCounter += 1;
                        InvCounter := 0;
                        if "Document Type" = "Document Type"::Refund then
                            Description := CopyStr(Description + ' (' + "Applies-to Doc. No." + ')', 1, MaxStrLen(Description));

                        if ShowDetails < 2 then
                            FillBody(
                              Format(PayCounter), Format("Posting Date"), GetVendEntryDescription(OldVendPayments),
                              FormatAmount(DocumentAmount), RemainingAmount, 0, false);
                    end;

                    trigger OnPostDataItem()
                    begin
                        DebitBalance2 += TotalPayAmount;

                        if (ShowDetails < 2) and (not IsEmpty) then
                            FillPrevAdvFooter(
                              MaxDate, FormatAmount(TotalPayAmount), FormatAmount(0));
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetFilter("Currency Code", CurrencyCode);
                        SetFilter("Posting Date", '..%1', FirstDate);
                        PayCounter := 0;
                        TotalPayAmount := 0;

                        if (ShowDetails < 2) and (not IsEmpty) then
                            ReconActReportHelper.FillPrevAdvHeader(MinDate);
                    end;
                }
                dataitem(VendTotal; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));

                    trigger OnAfterGetRecord()
                    begin
                        AdjustTotalsBalance(DebitBalance2, CreditBalance2);

                        FillVendFooter(
                          MinDate, MaxDate,
                          FormatAmount(DebitTurnover2), FormatAmount(CreditTurnover2),
                          FormatAmount(DebitBalance2), FormatAmount(CreditBalance2));
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    GetInitialDebitCreditBalance(InitialDebitBalance2, InitialCreditBalance2);
                    AdjustTotalsBalance(InitialDebitBalance2, InitialCreditBalance2);

                    FillVendHeader(
                      Format(MinDate), FormatAmount(InitialDebitBalance2), FormatAmount(InitialCreditBalance2));
                end;

                trigger OnPreDataItem()
                begin
                    ClearAmounts();
                end;
            }
            dataitem(Totals; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));

                trigger OnAfterGetRecord()
                var
                    LocMgt: Codeunit "Localisation Management";
                    Result: Decimal;
                    CurrencyText: Text[30];
                begin
                    CreditBalance += CreditBalance2;
                    DebitBalance += DebitBalance2;
                    AdjustTotalsBalance(DebitBalance, CreditBalance);
                    CreditTurnover += CreditTurnover2;
                    DebitTurnover += DebitTurnover2;
                    InitialDebitBalance += InitialDebitBalance2;
                    InitialCreditBalance += InitialCreditBalance2;
                    AdjustTotalsBalance(InitialDebitBalance, InitialCreditBalance);
                    CreditTotalBalance := InitialCreditBalance + CreditTurnover;
                    DebitTotalBalance := InitialDebitBalance + DebitTurnover;
                    AdjustTotalsBalance(DebitTotalBalance, CreditTotalBalance);

                    Result := CreditTotalBalance - DebitTotalBalance;
                    if CurrencyCode = '' then
                        CurrencyText := Text004
                    else
                        CurrencyText := CurrencyCode;
                    if Result = 0 then
                        ResultText := StrSubstNo(Text000, MaxDate, CompanyInfo.Name, Vendor.Name)
                    else
                        if Result > 0 then
                            ResultText :=
                              StrSubstNo(Text001, MaxDate, CompanyInfo.Name, Vendor.Name, Result,
                                LocMgt.Amount2Text(CurrencyCode, Result), CurrencyText)
                        else
                            ResultText :=
                              StrSubstNo(Text001, MaxDate, Vendor.Name, CompanyInfo.Name, -Result,
                                LocMgt.Amount2Text(CurrencyCode, -Result), CurrencyText);

                    FillPageFooter(
                      MinDate, MaxDate,
                      FormatAmount(InitialDebitBalance), FormatAmount(InitialCreditBalance),
                      FormatAmount(DebitTurnover), FormatAmount(CreditTurnover),
                      FormatAmount(DebitTotalBalance), FormatAmount(CreditTotalBalance));

                    ReconActReportHelper.FillReportFooter(
                      ResultText, CompanyInfo.Name, Vendor.Name,
                      CompanyInfo."Director Name", CompanyInfo."Accountant Name");
                end;
            }

            trigger OnAfterGetRecord()
            begin
                ExclAmountCredit := 0;
                ExclAmountDebit := 0;
                DtldCustLedgEntry.Reset();
                DtldCustLedgEntry.SetCurrentKey(
                  "Customer No.", "Initial Document Type", "Document Type", "Entry Type", "Posting Date", "Currency Code");
                DtldCustLedgEntry.SetRange("Customer No.", "No.");
                DtldCustLedgEntry.SetFilter("Agreement No.", GetFilter("Agreement Filter"));
                DtldCustLedgEntry.SetFilter("Posting Date", '..%1', FirstDate);
                DtldCustLedgEntry.SetFilter("Initial Document Type", '%1|%2|%3', DtldCustLedgEntry."Initial Document Type"::" ",
                  DtldCustLedgEntry."Initial Document Type"::Invoice,
                  DtldCustLedgEntry."Initial Document Type"::"Credit Memo");
                if CurrencyCode <> '' then begin
                    CurrencyClaim := StrSubstNo(Text003, CurrencyCode);
                    DtldCustLedgEntry.SetRange("Currency Code", CurrencyCode);
                    DtldCustLedgEntry.CalcSums(Amount);
                    InitialDebitBalance2 := DtldCustLedgEntry.Amount;
                end else begin
                    CurrencyClaim := '';
                    DtldCustLedgEntry.CalcSums("Amount (LCY)");
                    InitialDebitBalance2 := DtldCustLedgEntry."Amount (LCY)";
                end;
                DtldCustLedgEntry.SetFilter("Initial Document Type", '%1|%2', DtldCustLedgEntry."Initial Document Type"::Payment,
                  DtldCustLedgEntry."Initial Document Type"::Refund);
                if CurrencyCode <> '' then begin
                    DtldCustLedgEntry.CalcSums(Amount);
                    InitialCreditBalance2 := -DtldCustLedgEntry.Amount;
                end else begin
                    DtldCustLedgEntry.CalcSums("Amount (LCY)");
                    InitialCreditBalance2 := -DtldCustLedgEntry."Amount (LCY)";
                end;
                AdjustTotalsBalance(InitialDebitBalance2, InitialCreditBalance2);

                if not FirstCustomer then
                    ReconActReportHelper.AddPageBreak();

                CustName := Name;
                if GetFilter("Agreement Filter") <> '' then
                    CustName := CustName + ' (' + GetFilter("Agreement Filter") + ')';
                CustAgreement.SetRange("Customer No.", "No.");
                CustAgreement.SetFilter("No.", GetFilter("Agreement Filter"));
                OneAgreement := CustAgreement.Count = 1;

                ReconActReportHelper.FillReportHeader(
                  MinDate, MaxDate, CompanyInfo.Name, CompanyInfo."VAT Registration No.", CustName, "VAT Registration No.");
                ReconActReportHelper.FillPageHeader(CurrencyClaim, CompanyInfo.Name, Name);
                FillCustHeader(
                  Format(MinDate), FormatAmount(InitialDebitBalance2), FormatAmount(InitialCreditBalance2));

                FirstCustomer := false;
            end;

            trigger OnPreDataItem()
            begin
                CreditBalance2 := 0;
                DebitBalance2 := 0;
                CreditTurnover2 := 0;
                DebitTurnover2 := 0;
                InvCounter := 0;
                TotalInvAmount := 0;
                PayCounter := 0;
                TotalPayAmount := 0;
                FirstDate := CalcDate('<-1D>', MinDate);
                FirstCustomer := true;
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
                    field(MinDate; MinDate)
                    {
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the beginning of the period for which entries are adjusted. This field is usually left blank, but you can enter a date.';

                        trigger OnValidate()
                        begin
                            if MinDate <> 0D then
                                MaxDate := CalcDate('<CM>', MinDate);
                        end;
                    }
                    field(MaxDate; MaxDate)
                    {
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';
                    }
                    field(CurrencyCode; CurrencyCode)
                    {
                        Caption = 'Currency Code';
                        TableRelation = Currency;
                        ToolTip = 'Specifies the code for the currency that amounts are shown in.';
                    }
                    field(ShowDetails; ShowDetails)
                    {
                        Caption = 'Show Details';
                        OptionCaption = 'All,Partial,None';
                        ToolTip = 'Specifies if the report displays all lines in detail.';
                    }
                    field(PrintVendorData; PrintVendorData)
                    {
                        Caption = 'Print Vendor Data';
                        ToolTip = 'Specifies if you want to fill in the right side of the report with the vendor''s data.';
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
        ReconActReportHelper.InitReportTemplate();
    end;

    trigger OnPostReport()
    begin
        if FileName = '' then
            ReconActReportHelper.ExportData()
        else
            ReconActReportHelper.ExportDataFile(FileName);
    end;

    trigger OnPreReport()
    begin
        if (MinDate = 0D) or (MaxDate = 0D) then
            Error(Text002);
        DateFilter := Format(MinDate) + '..' + Format(MaxDate);
        CompanyInfo.Get();
        GLSetup.Get();
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'There is no debt between %2 and %3 at %1', Comment = 'Must be translated: ìá %1 ¼ÑªñÒ %2 ¿ %3 ºáñ«½ªÑ¡¡«ßÔý «ÔßÒÔßÔóÒÑÔ';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text001: Label '%2 debt amount to %3 is %4 (%5) %6 at %1.', Comment = 'Must be translated: ìá %1 ºáñ«½ªÑ¡¡«ßÔý %2 »ÑÓÑñ %3 ß«ßÔáó½´ÑÔ %4 (%5) %6.';
#pragma warning restore AA0074
        GLSetup: Record "General Ledger Setup";
        CompanyInfo: Record "Company Information";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        TempAppDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary;
        TempAppDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry" temporary;
        CustAgreement: Record "Customer Agreement";
        TempProcPayDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry" temporary;
        TempProcInvVendLedgEntry: Record "Vendor Ledger Entry" temporary;
        CurrencyCode: Code[10];
        CurrencyClaim: Text[100];
        DateFilter: Text[250];
        PrintVendorData: Boolean;
        MinDate: Date;
        MaxDate: Date;
#pragma warning disable AA0074
        Text002: Label 'Starting Date and Ending Date should be filled.';
#pragma warning restore AA0074
        FirstDate: Date;
        TotalInvAmount: Decimal;
        TotalPayAmount: Decimal;
        InvCounter: Integer;
        PayCounter: Integer;
        InitialDebitBalance: Decimal;
        InitialCreditBalance: Decimal;
        DebitAppliedAmt: Decimal;
        CreditAppliedAmt: Decimal;
        DebitTurnover: Decimal;
        CreditTurnover: Decimal;
        DebitBalance: Decimal;
        CreditBalance: Decimal;
        DebitTurnover2: Decimal;
        CreditTurnover2: Decimal;
        DebitBalance2: Decimal;
        CreditBalance2: Decimal;
        InitialDebitBalance2: Decimal;
        InitialCreditBalance2: Decimal;
        ResultText: Text[1024];
        DocumentAmount: Decimal;
        RemainingAmount: Decimal;
        RemainingDebitAmount: Decimal;
        RemainingCreditAmount: Decimal;
        TempAmount: Decimal;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label 'Report currency code: %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text004: Label 'rub';
#pragma warning restore AA0074
        EntryDescription: Text;
        PostingDate: Date;
        OtherCurrApplAmount: Decimal;
        ShowDetails: Option Full,Partly,Nothing;
        CreditTotalBalance: Decimal;
        DebitTotalBalance: Decimal;
        AppliedToPayment: Boolean;
        FileName: Text;
        ReconActReportHelper: Codeunit "Recon. Act Report Helper";
        FirstCustomer: Boolean;
        ExclAmountDebit: Decimal;
        ExclAmountCredit: Decimal;
        CustName: Text;
        OneAgreement: Boolean;
        CurrCodeToShow: Code[10];
        CustCorrection: Boolean;

    local procedure ExchAmount(Amount: Decimal; FromCurrencyCode: Code[10]; ToCurrencyCode: Code[10]; UsePostingDate: Date): Decimal
    var
        ToCurrency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        if (FromCurrencyCode = ToCurrencyCode) or (Amount = 0) then
            exit(Amount);

        Amount :=
          CurrExchRate.ExchangeAmtFCYToFCY(
            UsePostingDate, FromCurrencyCode, ToCurrencyCode, Amount);

        if ToCurrencyCode <> '' then begin
            ToCurrency.Get(ToCurrencyCode);
            Amount := Round(Amount, ToCurrency."Amount Rounding Precision");
        end else
            Amount := Round(Amount);

        exit(Amount);
    end;

    local procedure GetCustApplicationEntry(SourceEntry: Record "Detailed Cust. Ledg. Entry"; var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; GetLedgEntry: Boolean; var CustLedgEntry: Record "Cust. Ledger Entry"; var OtherCurrApplAmount: Decimal)
    begin
        DtldCustLedgEntry.Reset();
        FilterApplDtldCustLedgEntry(DtldCustLedgEntry, SourceEntry."Applied Cust. Ledger Entry No.");
        DtldCustLedgEntry.SetRange("Transaction No.", SourceEntry."Transaction No.");
        if DtldCustLedgEntry.FindSet() then
            repeat
                if GetLedgEntry then
                    CustLedgEntry.Get(DtldCustLedgEntry."Cust. Ledger Entry No.");
                if SourceEntry."Currency Code" <> DtldCustLedgEntry."Currency Code" then
                    OtherCurrApplAmount += SourceEntry.Amount;
                exit;
            until DtldCustLedgEntry.Next() = 0;
    end;

    local procedure GetCustPay(var Rec: Record "Cust. Ledger Entry"; CurrencyCode: Code[10]; var DocumentAmount: Decimal; var RemainingAmount: Decimal; var OtherCurrApplAmount: Decimal)
    var
        ApplDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        OtherCurrApplAmount := 0;
        GetCustAmounts(Rec, CurrencyCode, DocumentAmount, RemainingAmount);
        DocumentAmount := -DocumentAmount;
        RemainingAmount := -RemainingAmount;
        if CurrencyCode = '' then
            exit;
        DtldCustLedgEntry.Reset();
        DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type", "Posting Date");
        DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", Rec."Entry No.");
        DtldCustLedgEntry.SetRange("Entry Type", DtldCustLedgEntry."Entry Type"::Application);
        DtldCustLedgEntry.SetFilter("Posting Date", DateFilter);
        if DtldCustLedgEntry.FindSet() then
            repeat
                CustLedgEntry.Positive := false;
                GetCustApplicationEntry(DtldCustLedgEntry, ApplDtldCustLedgEntry, false, CustLedgEntry, OtherCurrApplAmount);
            until DtldCustLedgEntry.Next() = 0;
    end;

    local procedure GetCustAmounts(var CustLedgEntry: Record "Cust. Ledger Entry"; CurrencyCode: Code[10]; var Amount1: Decimal; var RemainingAmount1: Decimal)
    var
        IsInvoice: Boolean;
    begin
        IsInvoice := CustLedgEntry."Document Type" in [CustLedgEntry."Document Type"::" ",
                                                       CustLedgEntry."Document Type"::Invoice,
                                                       CustLedgEntry."Document Type"::"Credit Memo"];
        if CurrencyCode = '' then begin
            CustLedgEntry.CalcFields("Amount (LCY)", "Remaining Amt. (LCY)", "Original Amt. (LCY)");
            if IsInvoice then
                Amount1 := CustLedgEntry."Original Amt. (LCY)"
            else
                Amount1 := CustLedgEntry."Amount (LCY)";
            RemainingAmount1 := CustLedgEntry."Remaining Amt. (LCY)";
        end else begin
            CustLedgEntry.CalcFields(Amount, "Remaining Amount", "Original Amount");
            if IsInvoice then
                Amount1 := CustLedgEntry."Original Amount"
            else
                Amount1 := CustLedgEntry.Amount;
            RemainingAmount1 := CustLedgEntry."Remaining Amount";
        end;
    end;

    local procedure CustPayProcessing(var PayEntry: Record "Detailed Cust. Ledg. Entry"; var InvEntry: Record "Cust. Ledger Entry"; CurrencyCode: Code[10])
    begin
        if PayEntry."Entry Type" <> PayEntry."Entry Type"::Application then begin
            if CurrencyCode <> '' then
                CurrReport.Skip();
            PostingDate := PayEntry."Posting Date";
            EntryDescription := GetCustEntryDescription(InvEntry);
            TempAmount := PayEntry."Amount (LCY)";
            if PayEntry."Amount (LCY)" < 0 then begin
                DocumentAmount := -PayEntry."Amount (LCY)";
                CreditAppliedAmt := -PayEntry."Amount (LCY)";
                DebitAppliedAmt := 0;
                CreditTurnover += -PayEntry."Amount (LCY)";
            end else begin
                DocumentAmount := PayEntry."Amount (LCY)";
                CreditAppliedAmt := 0;
                DebitAppliedAmt := PayEntry."Amount (LCY)";
                DebitTurnover += PayEntry."Amount (LCY)";
            end;
        end else begin
            CustLedgEntry.Get(TempAppDtldCustLedgEntry."Cust. Ledger Entry No.");
            CustLedgEntry.SetFilter("Date Filter", '..%1', CustLedgEntry."Posting Date");
            PostingDate := CustLedgEntry."Posting Date";
            if CustLedgEntry."Currency Code" = '' then
                CustLedgEntry."Currency Code" := GLSetup."LCY Code";
            EntryDescription := GetCustEntryDescription(CustLedgEntry);
            if CurrencyCode = '' then begin
                CustLedgEntry.CalcFields("Amount (LCY)", "Remaining Amt. (LCY)");
                DocumentAmount := CustLedgEntry."Amount (LCY)";
                TempAmount := -TempAppDtldCustLedgEntry."Amount (LCY)";
            end else begin
                CustLedgEntry.CalcFields(Amount, "Remaining Amount");
                DocumentAmount := CustLedgEntry.Amount;
                TempAmount := ExchAmount(
                    -TempAppDtldCustLedgEntry.Amount, CustLedgEntry."Currency Code", CurrencyCode, CustLedgEntry."Posting Date");
            end;
            if (CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::Payment) or
               (CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::Refund)
            then
                AppliedToPayment := true;
            if DocumentAmount > 0 then begin
                CreditAppliedAmt := 0;
                DebitAppliedAmt := -TempAmount;
            end else begin
                DocumentAmount := -DocumentAmount;
                CreditAppliedAmt := TempAmount;
                DebitAppliedAmt := 0;
            end;
        end;
        TotalInvAmount += -TempAmount;
    end;

    local procedure AdjustTotalsBalance(var DebitAmount: Decimal; var CreditAmount: Decimal)
    begin
        if DebitAmount > CreditAmount then begin
            DebitAmount -= CreditAmount;
            CreditAmount := 0;
        end else begin
            CreditAmount -= DebitAmount;
            DebitAmount := 0;
        end;
    end;

    local procedure FindAppldCustLedgEntry(CustLedgEntryNo: Integer; FromDate: Date; MaxDate: Date): Boolean
    var
        DtldCustLedgEntry1: Record "Detailed Cust. Ledg. Entry";
        DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
    begin
        TempAppDtldCustLedgEntry.Reset();
        TempAppDtldCustLedgEntry.DeleteAll();

        DtldCustLedgEntry1.SetCurrentKey("Cust. Ledger Entry No.");
        DtldCustLedgEntry1.SetRange("Cust. Ledger Entry No.", CustLedgEntryNo);
        DtldCustLedgEntry1.SetRange("Entry Type", DtldCustLedgEntry1."Entry Type"::Application);
        DtldCustLedgEntry1.SetRange(Unapplied, false);
        DtldCustLedgEntry1.SetRange("Posting Date", FromDate, MaxDate);
        if DtldCustLedgEntry1.FindSet() then
            repeat
                if DtldCustLedgEntry1."Cust. Ledger Entry No." =
                   DtldCustLedgEntry1."Applied Cust. Ledger Entry No."
                then begin
                    DtldCustLedgEntry2.Init();
                    DtldCustLedgEntry2.SetCurrentKey("Applied Cust. Ledger Entry No.", "Entry Type");
                    DtldCustLedgEntry2.SetRange(
                      "Applied Cust. Ledger Entry No.", DtldCustLedgEntry1."Applied Cust. Ledger Entry No.");
                    DtldCustLedgEntry2.SetFilter("Cust. Ledger Entry No.", '<>%1', DtldCustLedgEntry1."Applied Cust. Ledger Entry No.");
                    DtldCustLedgEntry2.SetRange("Entry Type", DtldCustLedgEntry2."Entry Type"::Application);
                    DtldCustLedgEntry2.SetRange(Unapplied, false);
                    DtldCustLedgEntry2.SetRange("Prepmt. Diff.", false);
                    if DtldCustLedgEntry2.FindSet() then
                        repeat
                            CustLedgEntry2.Get(DtldCustLedgEntry2."Cust. Ledger Entry No.");
                            TempAppDtldCustLedgEntry := DtldCustLedgEntry2;
                            TempAppDtldCustLedgEntry.Amount := -TempAppDtldCustLedgEntry.Amount;
                            TempAppDtldCustLedgEntry."Amount (LCY)" := -TempAppDtldCustLedgEntry."Amount (LCY)";
                            if TempAppDtldCustLedgEntry.Insert() then;
                        until DtldCustLedgEntry2.Next() = 0;
                end else
                    if not DtldCustLedgEntry1."Prepmt. Diff." and
                       CustLedgEntry2.Get(DtldCustLedgEntry1."Applied Cust. Ledger Entry No.")
                    then begin
                        TempAppDtldCustLedgEntry := DtldCustLedgEntry1;
                        TempAppDtldCustLedgEntry."Cust. Ledger Entry No." := TempAppDtldCustLedgEntry."Applied Cust. Ledger Entry No.";
                        if TempAppDtldCustLedgEntry.Insert() then;
                    end;
            until DtldCustLedgEntry1.Next() = 0;

        exit(TempAppDtldCustLedgEntry.FindFirst())
    end;

    local procedure FilterApplDtldCustLedgEntry(var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; CustLedgEntryNo: Integer)
    begin
        if not DtldCustLedgEntry.RecordLevelLocking then
            DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type", "Posting Date", "Prepmt. Diff. in TA");
        DtldCustLedgEntry.SetRange("Entry Type", DtldCustLedgEntry."Entry Type"::Application);
        DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntryNo);
        DtldCustLedgEntry.SetRange(Unapplied, false);
    end;

    local procedure CheckCustTransfBetweenAgreements(var CustLedgerEntry: Record "Cust. Ledger Entry"): Boolean
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.CalcFields(Amount, "Remaining Amount");
        if (CustLedgerEntry."Document Type" <> CustLedgerEntry."Document Type"::" ") or (CustLedgerEntry."Remaining Amount" = 0) then
            exit(false);
        CustLedgerEntry2.SetRange("Document Type", CustLedgerEntry."Document Type");
        CustLedgerEntry2.SetRange("Customer No.", CustLedgerEntry."Customer No.");
        CustLedgerEntry2.SetRange("Posting Date", CustLedgerEntry."Posting Date");
        CustLedgerEntry2.SetFilter("Agreement No.", '<>%1&<>%2', '', CustLedgerEntry."Agreement No.");
        if CustLedgerEntry2.FindSet() then
            repeat
                CustLedgerEntry2.CalcFields(Amount);
                if CustLedgerEntry2.Amount = -CustLedgerEntry.Amount then
                    exit(true);
            until CustLedgerEntry2.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewStartDate: Date; NewEndDate: Date; NewFileName: Text; NewPrintVendorData: Boolean)
    begin
        FileName := NewFileName;
        MinDate := NewStartDate;
        MaxDate := NewEndDate;
        PrintVendorData := NewPrintVendorData;
    end;

    local procedure FormatAmount(Amount: Decimal): Text
    begin
        if Amount <> 0 then
            exit(Format(Round(Amount), 0, '<Precision,2:2><Standard Format,0>'));
        exit('');
    end;

    local procedure GetCustPrepmtDiffAmount(var CustLedgEntry: Record "Cust. Ledger Entry"; CurrencyCode: Code[10]; var PrepmtDiffAmount: Decimal)
    var
        DtldCustLedgEntryPrepmtDiff: Record "Detailed Cust. Ledg. Entry";
    begin
        if CurrencyCode <> '' then
            exit;
        DtldCustLedgEntryPrepmtDiff.SetRange("Cust. Ledger Entry No.", CustLedgEntry."Entry No.");
        DtldCustLedgEntryPrepmtDiff.SetRange("Entry Type", DtldCustLedgEntryPrepmtDiff."Entry Type"::Application);
        DtldCustLedgEntryPrepmtDiff.SetRange("Prepmt. Diff.", true);
        DtldCustLedgEntryPrepmtDiff.SetFilter("Posting Date", CustLedgEntry.GetFilter("Date Filter"));
        DtldCustLedgEntryPrepmtDiff.CalcSums("Amount (LCY)");
        PrepmtDiffAmount += DtldCustLedgEntryPrepmtDiff."Amount (LCY)";
    end;

    local procedure GetVendApplicationEntry(SourceEntry: Record "Detailed Vendor Ledg. Entry"; var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; GetLedgEntry: Boolean; var VendLedgEntry: Record "Vendor Ledger Entry"; var OtherCurrApplAmount: Decimal)
    begin
        DtldVendLedgEntry.Reset();
        DtldVendLedgEntry.SetFilter("Entry No.", '%1|%2', SourceEntry."Entry No." - 1, SourceEntry."Entry No." + 1);
        DtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::Application);
        DtldVendLedgEntry.SetRange("Transaction No.", SourceEntry."Transaction No.");
        if DtldVendLedgEntry.FindSet() then
            repeat
                if GetLedgEntry then
                    // Positive is just temporary flag
                    VendLedgEntry.Get(DtldVendLedgEntry."Vendor Ledger Entry No.");
                if SourceEntry."Currency Code" <> DtldVendLedgEntry."Currency Code" then
                    OtherCurrApplAmount += SourceEntry.Amount;
                exit;
            until DtldVendLedgEntry.Next() = 0;
    end;

    local procedure GetVendPay(var Rec: Record "Vendor Ledger Entry"; CurrencyCode: Code[10]; var DocumentAmount: Decimal; var RemainingAmount: Decimal; var OtherCurrApplAmount: Decimal)
    var
        ApplDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        OtherCurrApplAmount := 0;
        GetVendAmounts(Rec, CurrencyCode, DocumentAmount, RemainingAmount);
        if CurrencyCode = '' then
            exit;
        DtldVendLedgEntry.Reset();
        DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type", "Posting Date");
        DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", Rec."Entry No.");
        DtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::Application);
        DtldVendLedgEntry.SetFilter("Posting Date", DateFilter);
        if DtldVendLedgEntry.FindSet() then
            repeat
                GetVendApplicationEntry(DtldVendLedgEntry, ApplDtldVendLedgEntry, false, VendLedgEntry, OtherCurrApplAmount);
            until DtldVendLedgEntry.Next() = 0;
    end;

    local procedure GetVendAmounts(var VendLedgEntry: Record "Vendor Ledger Entry"; CurrencyCode: Code[10]; var NewAmount: Decimal; var NewRemainingAmount: Decimal)
    var
        IsInvoice: Boolean;
    begin
        IsInvoice := IsVendorInvoice(VendLedgEntry);
        if CurrencyCode = '' then begin
            VendLedgEntry.CalcFields("Amount (LCY)", "Remaining Amt. (LCY)", "Original Amt. (LCY)");
            if IsInvoice then
                NewAmount := VendLedgEntry."Original Amt. (LCY)"
            else
                NewAmount := VendLedgEntry."Amount (LCY)";
            NewRemainingAmount := VendLedgEntry."Remaining Amt. (LCY)";
        end else begin
            VendLedgEntry.CalcFields(Amount, "Remaining Amount", "Original Amount");
            if IsInvoice then
                NewAmount := VendLedgEntry."Original Amount"
            else
                NewAmount := VendLedgEntry.Amount;
            NewRemainingAmount := VendLedgEntry."Remaining Amount";
        end;
    end;

    local procedure VendPayProcessing(var PayEntry: Record "Detailed Vendor Ledg. Entry"; var InvEntry: Record "Vendor Ledger Entry"; CurrentPeriod: Boolean; CurrencyCode: Code[10])
    begin
        if PayEntry."Entry Type" <> PayEntry."Entry Type"::Application then begin
            VendLedgEntry.Get(PayEntry."Vendor Ledger Entry No.");
            if CurrencyCode <> '' then
                CurrReport.Skip();
            PostingDate := PayEntry."Posting Date";
            EntryDescription := Format(InvEntry."Document Type") + ' ' + InvEntry."Document No." + ' ' + InvEntry.Description;
            TempAmount := -PayEntry."Amount (LCY)";
            if PayEntry."Amount (LCY)" < 0 then begin
                DocumentAmount := -PayEntry."Amount (LCY)";
                CreditAppliedAmt := -PayEntry."Amount (LCY)";
                DebitAppliedAmt := 0;
            end else begin
                DocumentAmount := PayEntry."Amount (LCY)";
                CreditAppliedAmt := 0;
                DebitAppliedAmt := PayEntry."Amount (LCY)";
            end;
        end else begin
            VendLedgEntry.Get(TempAppDtldVendLedgEntry."Vendor Ledger Entry No.");
            VendLedgEntry.SetFilter("Date Filter", '..%1', VendLedgEntry."Posting Date");
            PostingDate := VendLedgEntry."Posting Date";
            if VendLedgEntry."Currency Code" = '' then
                VendLedgEntry."Currency Code" := GLSetup."LCY Code";
            if TempAppDtldVendLedgEntry."Prepmt. Diff." then
                EntryDescription :=
                  StrSubstNo(
                    '%1 %2 %3', Format(InvEntry."Document Type"),
                    InvEntry."Document No.", InvEntry.Description)
            else
                EntryDescription :=
                  StrSubstNo(
                    '%1 %2 %3', Format(VendLedgEntry."Document Type"), VendLedgEntry."Document No.",
                    VendLedgEntry.Description);
            if CurrencyCode = '' then begin
                VendLedgEntry.CalcFields("Amount (LCY)", "Remaining Amt. (LCY)");
                DocumentAmount := VendLedgEntry."Amount (LCY)";
                TempAmount := -TempAppDtldVendLedgEntry."Amount (LCY)";
            end else begin
                VendLedgEntry.CalcFields(Amount, "Remaining Amount");
                DocumentAmount := VendLedgEntry.Amount;
                TempAmount := ExchAmount(
                    -TempAppDtldVendLedgEntry.Amount,
                    TempAppDtldVendLedgEntry."Currency Code",
                    CurrencyCode,
                    VendLedgEntry."Posting Date");
            end;
            if TempAppDtldVendLedgEntry."Prepmt. Diff." then begin
                if TempAmount = 0 then
                    CurrReport.Skip();
                DebitAppliedAmt := 0;
                CreditAppliedAmt := TempAmount;
            end else
                if (VendLedgEntry."Document Type" in [VendLedgEntry."Document Type"::Invoice,
                                                      VendLedgEntry."Document Type"::"Credit Memo"])
                then begin
                    DocumentAmount := -DocumentAmount;
                    DebitAppliedAmt := 0;
                    CreditAppliedAmt := TempAmount;
                end else begin
                    CreditAppliedAmt := 0;
                    DebitAppliedAmt := -TempAmount;
                end;
        end;
        if (not WasProcessedInPrevPeriod(PayEntry, CurrentPeriod)) and (PostingDate in [MinDate .. MaxDate]) then begin
            DebitTurnover2 += DebitAppliedAmt;
            CreditTurnover2 += CreditAppliedAmt;
        end;
        TotalInvAmount += TempAmount;
    end;

    local procedure IsCheckVoiding(VendLedgEntry: Record "Vendor Ledger Entry"): Boolean
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        if not FindBankAccountLedgerEntry(VendLedgEntry, BankAccountLedgerEntry) then
            exit(false);

        CheckLedgerEntry.SetRange("Bank Account Ledger Entry No.", BankAccountLedgerEntry."Entry No.");
        CheckLedgerEntry.SetRange("Document No.", BankAccountLedgerEntry."Document No.");
        CheckLedgerEntry.SetRange("Entry Status", CheckLedgerEntry."Entry Status"::"Financially Voided");
        exit(not CheckLedgerEntry.IsEmpty);
    end;

    local procedure FindBankAccountLedgerEntry(VendLedgEntry: Record "Vendor Ledger Entry"; var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"): Boolean
    begin
        BankAccountLedgerEntry.SetRange("Transaction No.", VendLedgEntry."Transaction No.");
        if BankAccountLedgerEntry.FindFirst() then begin
            BankAccountLedgerEntry.SetRange("Document Type", BankAccountLedgerEntry."Document Type"::Payment);
            BankAccountLedgerEntry.SetRange("Document No.", BankAccountLedgerEntry."Document No.");
            BankAccountLedgerEntry.SetFilter("Transaction No.", '<>%1', VendLedgEntry."Transaction No.");
            exit(BankAccountLedgerEntry.FindFirst());
        end;

        exit(false);
    end;

    local procedure CurrentPeriodApplicationExists(EntryNo: Integer): Boolean
    var
        ApplDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        ApplDtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", EntryNo);
        ApplDtldVendLedgEntry.SetRange("Entry Type", ApplDtldVendLedgEntry."Entry Type"::Application);
        ApplDtldVendLedgEntry.SetRange("Posting Date", MinDate, MaxDate);
        ApplDtldVendLedgEntry.SetRange(Unapplied, false);
        exit(not ApplDtldVendLedgEntry.IsEmpty);
    end;

    local procedure GetInvRemAmtAtDate(EntryNo: Integer): Decimal
    var
        InvVendLedgEntry: Record "Vendor Ledger Entry";
        InvoiceRemainingAmount: Decimal;
    begin
        InvVendLedgEntry.Get(EntryNo);
        if InvVendLedgEntry."Posting Date" in [MinDate .. MaxDate] then begin
            InvVendLedgEntry.SetFilter("Date Filter", '..%1', InvVendLedgEntry."Posting Date");
            InvVendLedgEntry.CalcFields("Original Amount", "Original Amt. (LCY)");
            if CurrencyCode <> '' then
                InvoiceRemainingAmount := InvVendLedgEntry."Original Amount"
            else
                InvoiceRemainingAmount := InvVendLedgEntry."Original Amt. (LCY)";
        end else begin
            InvVendLedgEntry.SetFilter("Date Filter", '..%1', FirstDate);
            InvVendLedgEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
            if CurrencyCode <> '' then
                InvoiceRemainingAmount := InvVendLedgEntry."Remaining Amount"
            else
                InvoiceRemainingAmount := InvVendLedgEntry."Remaining Amt. (LCY)";
        end;
        exit(InvoiceRemainingAmount);
    end;

    local procedure FindAppldVendLedgEntry(VendLedgEntryNo: Integer)
    var
        SourceDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        AppliedDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        AppliedVendLedgEntry: Record "Vendor Ledger Entry";
    begin
        TempAppDtldVendLedgEntry.Reset();
        TempAppDtldVendLedgEntry.DeleteAll();

        SourceDtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.");
        SourceDtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntryNo);
        SourceDtldVendLedgEntry.SetRange(Unapplied, false);
        SourceDtldVendLedgEntry.SetFilter("Posting Date", '..%1', MaxDate);
        SourceDtldVendLedgEntry.SetRange("Entry Type", SourceDtldVendLedgEntry."Entry Type"::Application);
        if SourceDtldVendLedgEntry.FindSet() then
            repeat
                if SourceDtldVendLedgEntry."Vendor Ledger Entry No." =
                   SourceDtldVendLedgEntry."Applied Vend. Ledger Entry No."
                then begin
                    AppliedDtldVendLedgEntry.Init();
                    AppliedDtldVendLedgEntry.SetCurrentKey("Applied Vend. Ledger Entry No.", "Entry Type");
                    AppliedDtldVendLedgEntry.SetRange(
                      "Applied Vend. Ledger Entry No.", SourceDtldVendLedgEntry."Applied Vend. Ledger Entry No.");
                    AppliedDtldVendLedgEntry.SetRange("Entry Type", AppliedDtldVendLedgEntry."Entry Type"::Application);
                    AppliedDtldVendLedgEntry.SetRange(Unapplied, false);
                    if AppliedDtldVendLedgEntry.FindSet() then
                        repeat
                            if AppliedDtldVendLedgEntry."Vendor Ledger Entry No." <>
                               AppliedDtldVendLedgEntry."Applied Vend. Ledger Entry No."
                            then
                                if AppliedVendLedgEntry.Get(AppliedDtldVendLedgEntry."Vendor Ledger Entry No.") then begin
                                    TempAppDtldVendLedgEntry := AppliedDtldVendLedgEntry;
                                    TempAppDtldVendLedgEntry.Amount := -TempAppDtldVendLedgEntry.Amount;
                                    TempAppDtldVendLedgEntry."Amount (LCY)" := -TempAppDtldVendLedgEntry."Amount (LCY)";
                                    if not AppliedDtldVendLedgEntry."Prepmt. Diff." then
                                        if TempAppDtldVendLedgEntry.Insert() then;
                                end;
                        until AppliedDtldVendLedgEntry.Next() = 0;
                end else
                    if AppliedVendLedgEntry.Get(SourceDtldVendLedgEntry."Applied Vend. Ledger Entry No.") then begin
                        TempAppDtldVendLedgEntry := SourceDtldVendLedgEntry;
                        TempAppDtldVendLedgEntry."Vendor Ledger Entry No." := TempAppDtldVendLedgEntry."Applied Vend. Ledger Entry No.";
                        if TempAppDtldVendLedgEntry.Insert() then;
                    end;
            until SourceDtldVendLedgEntry.Next() = 0;
    end;

    local procedure GetInitialDebitCreditBalance(var InitialDebitAmount: Decimal; var InitialCreditAmount: Decimal)
    begin
        DtldVendLedgEntry.Reset();
        DtldVendLedgEntry.SetCurrentKey(
          "Vendor No.", "Initial Document Type", "Document Type",
          "Entry Type", "Posting Date", "Currency Code");
        DtldVendLedgEntry.SetRange("Vendor No.", Vendor."No.");
        DtldVendLedgEntry.SetFilter("Agreement No.", Vendor.GetFilter("Agreement Filter"));
        DtldVendLedgEntry.SetFilter("Posting Date", '..%1', FirstDate);
        DtldVendLedgEntry.SetRange("Prepmt. Diff. in TA", false);
        if CurrencyCode <> '' then
            DtldVendLedgEntry.SetRange("Currency Code", CurrencyCode);

        GetInitialCreditBalance(DtldVendLedgEntry, CurrencyCode, InitialCreditAmount);
        GetInitialDebitBalance(DtldVendLedgEntry, CurrencyCode, InitialDebitAmount);
        UpdInitialDebitCreditBalance(DtldVendLedgEntry, CurrencyCode, InitialDebitAmount, InitialCreditAmount);
    end;

    local procedure GetInitialCreditBalance(var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; CurrencyCode: Code[10]; var InitialCreditAmount: Decimal)
    begin
        DtldVendLedgEntry.SetFilter(
            "Initial Document Type", '%1|%2',
            DtldVendLedgEntry."Initial Document Type"::Invoice,
            DtldVendLedgEntry."Initial Document Type"::"Credit Memo");
        if CurrencyCode <> '' then begin
            DtldVendLedgEntry.SetRange("Currency Code", CurrencyCode);
            DtldVendLedgEntry.CalcSums(Amount);
            InitialCreditAmount := -DtldVendLedgEntry.Amount;
        end else begin
            DtldVendLedgEntry.CalcSums("Amount (LCY)");
            InitialCreditAmount := -DtldVendLedgEntry."Amount (LCY)";
        end;
    end;

    local procedure GetInitialDebitBalance(var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; CurrencyCode: Code[10]; var InitialDebitAmount: Decimal)
    begin
        DtldVendLedgEntry.SetFilter(
            "Initial Document Type", '%1|%2',
            DtldVendLedgEntry."Initial Document Type"::Payment,
            DtldVendLedgEntry."Initial Document Type"::Refund);
        if CurrencyCode <> '' then begin
            DtldVendLedgEntry.SetRange("Currency Code", CurrencyCode);
            DtldVendLedgEntry.CalcSums(Amount);
            InitialDebitAmount := DtldVendLedgEntry.Amount;
        end else begin
            DtldVendLedgEntry.CalcSums("Amount (LCY)");
            InitialDebitAmount := DtldVendLedgEntry."Amount (LCY)";
        end;
    end;

    local procedure UpdInitialDebitCreditBalance(var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; CurrencyCode: Code[10]; var InitialDebitAmount: Decimal; var InitialCreditAmount: Decimal)
    begin
        DtldVendLedgEntry.SetRange("Initial Document Type", DtldVendLedgEntry."Initial Document Type"::" ");
        if DtldVendLedgEntry.FindSet() then
            repeat
                if CurrencyCode <> '' then
                    HandleInitialDebitCreditBal(DtldVendLedgEntry.Amount, InitialDebitAmount, InitialCreditAmount)
                else
                    HandleInitialDebitCreditBal(DtldVendLedgEntry."Amount (LCY)", InitialDebitAmount, InitialCreditAmount);
            until DtldVendLedgEntry.Next() = 0;
    end;

    local procedure HandleInitialDebitCreditBal(Amount: Decimal; var InitialDebitAmount: Decimal; var InitialCreditAmount: Decimal)
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        if Amount < 0 then begin
            if DtldVendLedgEntry."Entry Type" <> DtldVendLedgEntry."Entry Type"::Application then
                InitialCreditAmount += -Amount
            else
                InitialDebitAmount += Amount;
        end else
            if DtldVendLedgEntry."Entry Type" <> DtldVendLedgEntry."Entry Type"::Application then
                InitialDebitAmount += Amount
            else
                InitialCreditAmount += -Amount;
    end;

    local procedure ClearAmounts()
    begin
        CreditBalance2 := 0;
        DebitBalance2 := 0;
        CreditTurnover2 := 0;
        DebitTurnover2 := 0;
        InvCounter := 0;
        TotalInvAmount := 0;
        PayCounter := 0;
        TotalPayAmount := 0;
        InitialDebitBalance2 := 0;
        InitialCreditBalance2 := 0;
        TempProcPayDtldVendLedgEntry.Reset();
        TempProcPayDtldVendLedgEntry.DeleteAll();
        TempProcInvVendLedgEntry.Reset();
        TempProcInvVendLedgEntry.DeleteAll();
    end;

    local procedure WasProcessedInPrevPeriod(var PayDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; CurrentPeriod: Boolean): Boolean
    begin
        if PayDtldVendLedgEntry."Entry No." = 0 then
            exit(false);
        if CurrentPeriod then begin
            TempProcPayDtldVendLedgEntry.SetRange("Entry No.", PayDtldVendLedgEntry."Entry No.");
            exit(not TempProcPayDtldVendLedgEntry.IsEmpty);
        end;
        TempProcPayDtldVendLedgEntry."Entry No." := PayDtldVendLedgEntry."Entry No.";
        if TempProcPayDtldVendLedgEntry.Insert() then;
        exit(false);
    end;

    local procedure IsInvProcessedInPrevPeriod(EntryNo: Integer; CurrentPeriod: Boolean): Boolean
    begin
        if CurrentPeriod then begin
            TempProcInvVendLedgEntry.SetRange("Entry No.", EntryNo);
            exit(not TempProcInvVendLedgEntry.IsEmpty);
        end;
        TempProcInvVendLedgEntry."Entry No." := EntryNo;
        if TempProcInvVendLedgEntry.Insert() then;
        exit(false);
    end;

    local procedure IsVendorInvoice(InvVendLedgEntry: Record "Vendor Ledger Entry"): Boolean
    begin
        InvVendLedgEntry.CalcFields("Original Amount");
        if IsReturnPrepayment(InvVendLedgEntry) or IsCheckVoiding(InvVendLedgEntry) then
            exit(false);
        exit(
          ((InvVendLedgEntry."Document Type" = InvVendLedgEntry."Document Type"::Invoice) or
           (InvVendLedgEntry."Document Type" = InvVendLedgEntry."Document Type"::"Credit Memo")) or
          ((InvVendLedgEntry."Document Type" = InvVendLedgEntry."Document Type"::" ") and (InvVendLedgEntry."Original Amount" < 0)));
    end;

    local procedure IsReturnPrepayment(VendorLedgerEntry: Record "Vendor Ledger Entry"): Boolean
    begin
        exit((VendorLedgerEntry."Document Type" = VendorLedgerEntry."Document Type"::" ") and VendorLedgerEntry.Prepayment);
    end;

    local procedure IsCustCorrection(CustLedgerEntry: Record "Cust. Ledger Entry"): Boolean
    begin
        CustLedgerEntry.CalcFields("Debit Amount", "Credit Amount");
        exit((CustLedgerEntry."Debit Amount" < 0) or (CustLedgerEntry."Credit Amount" < 0));
    end;

    local procedure ExcludeCustDoc(var CustLedgEntry1: Record "Cust. Ledger Entry"; CurrencyCode: Code[10]): Boolean
    var
        CustLedgEntry2: Record "Cust. Ledger Entry";
    begin
        if CustLedgEntry1.Open then
            exit(false);
        if (GetAppliedCustEntry(CustLedgEntry1."Entry No.", CustLedgEntry2) > 1) or CustLedgEntry2.Open then
            exit(false);

        exit(IsReturnedCustPrepayment(CustLedgEntry1, CustLedgEntry2, CurrencyCode) or
          IsReversedCustDoc(CustLedgEntry1, CustLedgEntry2, CurrencyCode));
    end;

    local procedure ExcludeVendDoc(var VendLedgEntry1: Record "Vendor Ledger Entry"; CurrencyCode: Code[10]): Boolean
    var
        VendLedgEntry2: Record "Vendor Ledger Entry";
    begin
        if VendLedgEntry1.Open then
            exit(false);
        if (GetAppliedVendEntry(VendLedgEntry1."Entry No.", VendLedgEntry2) > 1) or VendLedgEntry2.Open then
            exit(false);

        exit(IsReturnedVendPrepayment(VendLedgEntry1, VendLedgEntry2, CurrencyCode) or
          IsReversedVendDoc(VendLedgEntry1, VendLedgEntry2, CurrencyCode));
    end;

    local procedure GetAppliedCustEntry(EntryNo: Integer; var CustLedgEntry2: Record "Cust. Ledger Entry"): Integer
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.");
        DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", EntryNo);
        DtldCustLedgEntry.SetRange("Entry Type", DtldCustLedgEntry."Entry Type"::Application);
        DtldCustLedgEntry.SetRange(Unapplied, false);
        if not DtldCustLedgEntry.FindFirst() then
            exit(0);
        if DtldCustLedgEntry."Cust. Ledger Entry No." = DtldCustLedgEntry."Applied Cust. Ledger Entry No." then begin
            DtldCustLedgEntry.SetFilter("Cust. Ledger Entry No.", '<>%1', EntryNo);
            DtldCustLedgEntry.SetRange("Applied Cust. Ledger Entry No.", EntryNo);
            DtldCustLedgEntry.FindFirst();
            CustLedgEntry2.Get(DtldCustLedgEntry."Cust. Ledger Entry No.");
        end else
            CustLedgEntry2.Get(DtldCustLedgEntry."Applied Cust. Ledger Entry No.");
        exit(DtldCustLedgEntry.Count);
    end;

    local procedure GetAppliedVendEntry(EntryNo: Integer; var VendLedgEntry2: Record "Vendor Ledger Entry"): Integer
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.");
        DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", EntryNo);
        DtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::Application);
        DtldVendLedgEntry.SetRange(Unapplied, false);
        if not DtldVendLedgEntry.FindFirst() then
            exit(0);
        if DtldVendLedgEntry."Vendor Ledger Entry No." = DtldVendLedgEntry."Applied Vend. Ledger Entry No." then begin
            DtldVendLedgEntry.SetFilter("Vendor Ledger Entry No.", '<>%1', EntryNo);
            DtldVendLedgEntry.SetRange("Applied Vend. Ledger Entry No.", EntryNo);
            DtldVendLedgEntry.FindFirst();
            VendLedgEntry2.Get(DtldVendLedgEntry."Vendor Ledger Entry No.");
        end else
            VendLedgEntry2.Get(DtldVendLedgEntry."Applied Vend. Ledger Entry No.");
        exit(DtldVendLedgEntry.Count);
    end;

    local procedure IsReturnedCustPrepayment(var CustLedgEntry1: Record "Cust. Ledger Entry"; var CustLedgEntry2: Record "Cust. Ledger Entry"; CurrencyCode: Code[10]): Boolean
    begin
        if not (CustLedgEntry1.Prepayment and CustLedgEntry2.Prepayment and
                (CustLedgEntry1."Posting Date" in [MinDate .. MaxDate]) and
                (CustLedgEntry2."Posting Date" in [MinDate .. MaxDate]))
        then
            exit(false);
        ExcludeCustAmounts(CustLedgEntry1, CustLedgEntry2, CurrencyCode);
        exit(true);
    end;

    local procedure IsReturnedVendPrepayment(var VendLedgEntry1: Record "Vendor Ledger Entry"; var VendLedgEntry2: Record "Vendor Ledger Entry"; CurrencyCode: Code[10]): Boolean
    begin
        if not (VendLedgEntry1.Prepayment and VendLedgEntry2.Prepayment and
                (VendLedgEntry1."Posting Date" in [MinDate .. MaxDate]) and
                (VendLedgEntry2."Posting Date" in [MinDate .. MaxDate]))
        then
            exit(false);
        ExcludeVendAmounts(VendLedgEntry1, VendLedgEntry2, CurrencyCode);
        exit(true);
    end;

    local procedure IsReversedCustDoc(var CustLedgEntry1: Record "Cust. Ledger Entry"; var CustLedgEntry2: Record "Cust. Ledger Entry"; CurrencyCode: Code[10]): Boolean
    begin
        if not ((CustLedgEntry1."Document Type" in
                 [CustLedgEntry1."Document Type"::Invoice, CustLedgEntry1."Document Type"::"Credit Memo"]) and
                (CustLedgEntry2."Document Type" in
                 [CustLedgEntry2."Document Type"::Invoice, CustLedgEntry2."Document Type"::"Credit Memo"]) and
                (CustLedgEntry1."Posting Date" = CustLedgEntry2."Posting Date"))
        then
            exit(false);
        ExcludeCustAmounts(CustLedgEntry1, CustLedgEntry2, CurrencyCode);
        exit(true);
    end;

    local procedure IsReversedVendDoc(var VendLedgEntry1: Record "Vendor Ledger Entry"; var VendLedgEntry2: Record "Vendor Ledger Entry"; CurrencyCode: Code[10]): Boolean
    begin
        if not ((VendLedgEntry1."Document Type" in
                 [VendLedgEntry1."Document Type"::Invoice, VendLedgEntry1."Document Type"::"Credit Memo"]) and
                (VendLedgEntry2."Document Type" in
                 [VendLedgEntry2."Document Type"::Invoice, VendLedgEntry2."Document Type"::"Credit Memo"]) and
                (VendLedgEntry1."Posting Date" = VendLedgEntry2."Posting Date"))
        then
            exit(false);
        ExcludeVendAmounts(VendLedgEntry1, VendLedgEntry2, CurrencyCode);
        exit(true);
    end;

    local procedure ExcludeCustAmounts(var CustLedgEntry1: Record "Cust. Ledger Entry"; var CustLedgEntry2: Record "Cust. Ledger Entry"; CurrencyCode: Code[10])
    begin
        CustLedgEntry1.CalcFields("Debit Amount", "Debit Amount (LCY)", "Credit Amount", "Credit Amount (LCY)");
        CustLedgEntry2.CalcFields("Debit Amount", "Debit Amount (LCY)", "Credit Amount", "Credit Amount (LCY)");
        if (CustLedgEntry1."Debit Amount (LCY)" + CustLedgEntry2."Debit Amount (LCY)" <> 0) or
           (CustLedgEntry1."Credit Amount (LCY)" + CustLedgEntry2."Credit Amount (LCY)" <> 0)
        then
            if CurrencyCode = '' then begin
                ExclAmountDebit += CustLedgEntry1."Debit Amount (LCY)";
                ExclAmountCredit += CustLedgEntry1."Credit Amount (LCY)";
            end else begin
                ExclAmountDebit += CustLedgEntry1."Debit Amount";
                ExclAmountCredit += CustLedgEntry1."Credit Amount";
            end;
    end;

    local procedure ExcludeVendAmounts(var VendLedgEntry1: Record "Vendor Ledger Entry"; var VendLedgEntry2: Record "Vendor Ledger Entry"; CurrencyCode: Code[10])
    begin
        VendLedgEntry1.CalcFields("Debit Amount", "Debit Amount (LCY)", "Credit Amount", "Credit Amount (LCY)");
        VendLedgEntry2.CalcFields("Debit Amount", "Debit Amount (LCY)", "Credit Amount", "Credit Amount (LCY)");
        if (VendLedgEntry1."Debit Amount (LCY)" + VendLedgEntry2."Debit Amount (LCY)" <> 0) or
           (VendLedgEntry1."Credit Amount (LCY)" + VendLedgEntry2."Credit Amount (LCY)" <> 0)
        then
            if CurrencyCode = '' then begin
                ExclAmountDebit += VendLedgEntry1."Debit Amount (LCY)";
                ExclAmountCredit += VendLedgEntry1."Credit Amount (LCY)";
            end else begin
                ExclAmountDebit += VendLedgEntry1."Debit Amount";
                ExclAmountCredit += VendLedgEntry1."Credit Amount";
            end;
    end;

    local procedure GetCustEntryDescription(var CustLedgEntry: Record "Cust. Ledger Entry") EntryDescr: Text
    begin
        EntryDescr := CustLedgEntry."Document No." + ' ' + CustLedgEntry.Description;
        if not CustLedgEntry.Prepayment and (CustLedgEntry."Document Type" <> CustLedgEntry."Document Type"::" ") then
            EntryDescr := Format(CustLedgEntry."Document Type") + ' ' + EntryDescr;
        if CustLedgEntry.Prepayment and (CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::" ") then
            EntryDescr := CustLedgEntry.FieldCaption(Prepayment) + ' ' + Format(CustLedgEntry."Document Type"::Refund) + ' ' + EntryDescr;
        if CustLedgEntry.Prepayment and (CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::Payment) then
            EntryDescr := CustLedgEntry.FieldCaption(Prepayment) + ' ' + EntryDescr;
        if (not OneAgreement) and (CustLedgEntry."Agreement No." <> '') then
            EntryDescr := EntryDescr + ' (' + CustLedgEntry."Agreement No." + ')';
    end;

    local procedure GetVendEntryDescription(var VendLedgEntry: Record "Vendor Ledger Entry") EntryDescr: Text[1024]
    begin
        EntryDescr := VendLedgEntry."Document No." + ' ' + VendLedgEntry.Description;
        if not VendLedgEntry.Prepayment and (VendLedgEntry."Document Type" <> VendLedgEntry."Document Type"::" ") then
            EntryDescr := Format(VendLedgEntry."Document Type") + ' ' + EntryDescr;
        if VendLedgEntry.Prepayment and (VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::" ") then
            EntryDescr := VendLedgEntry.FieldCaption(Prepayment) + ' ' + Format(VendLedgEntry."Document Type"::Refund) + ' ' + EntryDescr;
        if VendLedgEntry.Prepayment and (VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::Payment) then
            EntryDescr := VendLedgEntry.FieldCaption(Prepayment) + ' ' + EntryDescr;
        if (not OneAgreement) and (VendLedgEntry."Agreement No." <> '') then
            EntryDescr := EntryDescr + ' (' + VendLedgEntry."Agreement No." + ')';
    end;

    local procedure ShowCustRemAmount(CustLedgEntry: Record "Cust. Ledger Entry"; CurrencyCode: Code[10]; var RemainingDebitAmount: Decimal; var RemainingCreditAmount: Decimal)
    begin
        if ShowDetails > 0 then
            CustDocTotals(CustLedgEntry, CurrencyCode, RemainingDebitAmount, RemainingCreditAmount);
    end;

    local procedure CustDocTotals(CustLedgEntry: Record "Cust. Ledger Entry"; CurrencyCode: Code[10]; var DebitValue: Decimal; var CreditValue: Decimal)
    begin
        CustLedgEntry.SetRange("Date Filter");
        CustLedgEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
        if CustLedgEntry."Remaining Amt. (LCY)" > 0 then begin
            if CurrencyCode = '' then
                DebitValue := CustLedgEntry."Remaining Amt. (LCY)"
            else
                DebitValue := CustLedgEntry."Remaining Amount";
            CreditValue := 0;
        end else begin
            DebitValue := 0;
            if CurrencyCode = '' then
                CreditValue := -CustLedgEntry."Remaining Amt. (LCY)"
            else
                CreditValue := -CustLedgEntry."Remaining Amount";
        end;
    end;

    local procedure CustEntryIsClosed(CustLedgEntry: Record "Cust. Ledger Entry"; CurrencyCode: Code[10]; MaxDate: Date): Boolean
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntry."Entry No.");
        DtldCustLedgEntry.SetRange("Entry Type", DtldCustLedgEntry."Entry Type"::Application);
        DtldCustLedgEntry.SetRange("Posting Date", 0D, MaxDate);
        DtldCustLedgEntry.SetFilter("Currency Code", CurrencyCode);
        DtldCustLedgEntry.CalcSums(Amount, "Amount (LCY)");
        if CurrencyCode = '' then begin
            CustLedgEntry.CalcFields("Amount (LCY)");
            exit(CustLedgEntry."Amount (LCY)" + DtldCustLedgEntry."Amount (LCY)" = 0);
        end;
        CustLedgEntry.CalcFields(Amount);
        exit(CustLedgEntry.Amount + DtldCustLedgEntry.Amount = 0);
    end;

    local procedure FillBody(LineNo: Text; DocDate: Text; DocDescription: Text; DocAmount: Text; DebitAmount: Decimal; CreditAmount: Decimal; Correction: Boolean)
    var
        OppDocAmount: Text;
        OppDebitAmount: Text;
        OppCreditAmount: Text;
        DebitAmountTxt: Text;
        CreditAmountTxt: Text;
    begin
        PreparePrintAmounts(CreditAmountTxt, DebitAmountTxt, CreditAmount, DebitAmount, Correction);
        if PrintVendorData then begin
            OppDocAmount := DocAmount;
            if CurrCodeToShow <> '' then
                OppDocAmount := CurrCodeToShow;
            OppDebitAmount := CreditAmountTxt;
            OppCreditAmount := DebitAmountTxt;
        end;
        ReconActReportHelper.FillBody(LineNo, DocDate, DocDescription, DocAmount, DebitAmountTxt, CreditAmountTxt,
          OppDocAmount, OppDebitAmount, OppCreditAmount);
    end;

    local procedure FillFooter(DocDescription: Text; DebitAmount: Decimal; CreditAmount: Decimal; Correction: Boolean)
    var
        OppDebitAmount: Text;
        OppCreditAmount: Text;
        DebitAmountTxt: Text;
        CreditAmountTxt: Text;
    begin
        PreparePrintAmounts(CreditAmountTxt, DebitAmountTxt, CreditAmount, DebitAmount, Correction);
        if PrintVendorData then begin
            OppDebitAmount := CreditAmountTxt;
            OppCreditAmount := DebitAmountTxt;
        end;
        ReconActReportHelper.FillFooter(DocDescription, DebitAmountTxt, CreditAmountTxt, OppDebitAmount, OppCreditAmount);
    end;

    local procedure FillCustFooter(StartingDate: Date; EndingDate: Date; TurnoverDebitAmount: Text; TurnoverCreditAmount: Text; CustBalanceDebitAmount: Text; CustBalanceCreditAmount: Text)
    var
        OppTurnoverDebitAmount: Text;
        OppTurnoverCreditAmount: Text;
        CustOppBalanceDebitAmount: Text;
        CustOppBalanceCreditAmount: Text;
    begin
        if PrintVendorData then begin
            OppTurnoverDebitAmount := TurnoverCreditAmount;
            OppTurnoverCreditAmount := TurnoverDebitAmount;
            CustOppBalanceDebitAmount := CustBalanceCreditAmount;
            CustOppBalanceCreditAmount := CustBalanceDebitAmount;
        end;
        ReconActReportHelper.FillCustFooter(StartingDate, EndingDate, TurnoverDebitAmount, TurnoverCreditAmount,
          OppTurnoverDebitAmount, OppTurnoverCreditAmount,
          CustBalanceDebitAmount, CustBalanceCreditAmount, CustOppBalanceDebitAmount, CustOppBalanceCreditAmount)
    end;

    local procedure FillVendFooter(StartingDate: Date; EndingDate: Date; TurnoverDebitAmount: Text; TurnoverCreditAmount: Text; VendBalanceDebitAmount: Text; VendBalanceCreditAmount: Text)
    var
        OppTurnoverDebitAmount: Text;
        OppTurnoverCreditAmount: Text;
        VendOppBalanceDebitAmount: Text;
        VendOppBalanceCreditAmount: Text;
    begin
        if PrintVendorData then begin
            OppTurnoverDebitAmount := TurnoverCreditAmount;
            OppTurnoverCreditAmount := TurnoverDebitAmount;
            VendOppBalanceDebitAmount := VendBalanceCreditAmount;
            VendOppBalanceCreditAmount := VendBalanceDebitAmount;
        end;
        ReconActReportHelper.FillVendFooter(StartingDate, EndingDate, TurnoverDebitAmount, TurnoverCreditAmount,
          OppTurnoverDebitAmount, OppTurnoverCreditAmount,
          VendBalanceDebitAmount, VendBalanceCreditAmount, VendOppBalanceDebitAmount, VendOppBalanceCreditAmount)
    end;

    local procedure FillCustHeader(InitialBalanceDate: Text; InitialDebitAmount: Text; InitialCreditAmount: Text)
    var
        OppInitialDebitAmount: Text;
        OppInitialCreditAmount: Text;
    begin
        if PrintVendorData then begin
            OppInitialDebitAmount := InitialCreditAmount;
            OppInitialCreditAmount := InitialDebitAmount;
        end;
        ReconActReportHelper.FillCustHeader(InitialBalanceDate, InitialDebitAmount, InitialCreditAmount,
          OppInitialDebitAmount, OppInitialCreditAmount)
    end;

    local procedure FillVendHeader(InitialBalanceDate: Text; InitialDebitAmount: Text; InitialCreditAmount: Text)
    var
        OppInitialDebitAmount: Text;
        OppInitialCreditAmount: Text;
    begin
        if PrintVendorData then begin
            OppInitialDebitAmount := InitialCreditAmount;
            OppInitialCreditAmount := InitialDebitAmount;
        end;
        ReconActReportHelper.FillVendHeader(InitialBalanceDate, InitialDebitAmount, InitialCreditAmount,
          OppInitialDebitAmount, OppInitialCreditAmount)
    end;

    local procedure FillAdvOtherCurrBody(LineNo: Text; DocDescription: Text; AdvOtherCurrDebitAmount: Text; AdvOtherCurrCreditAmount: Text; AdvOtherCurrBalanceDebitAmount: Text; AdvOtherCurrBalanceCreditAmount: Text)
    var
        OppAdvOtherCurrDebitAmount: Text;
        OppAdvOtherCurrCreditAmount: Text;
        OppAdvOtherCurrBalanceDebitAmount: Text;
        OppAdvOtherCurrBalanceCreditAmount: Text;
    begin
        if PrintVendorData then begin
            OppAdvOtherCurrDebitAmount := AdvOtherCurrCreditAmount;
            OppAdvOtherCurrCreditAmount := AdvOtherCurrDebitAmount;
            OppAdvOtherCurrBalanceDebitAmount := AdvOtherCurrBalanceCreditAmount;
            OppAdvOtherCurrBalanceCreditAmount := AdvOtherCurrBalanceDebitAmount;
        end;
        ReconActReportHelper.FillAdvOtherCurrBody(LineNo, DocDescription, AdvOtherCurrDebitAmount, AdvOtherCurrCreditAmount,
          OppAdvOtherCurrDebitAmount, OppAdvOtherCurrCreditAmount, AdvOtherCurrBalanceDebitAmount,
          AdvOtherCurrBalanceCreditAmount, OppAdvOtherCurrBalanceDebitAmount, OppAdvOtherCurrBalanceCreditAmount);
    end;

    local procedure FillAdvFooter(EndingDate: Date; AdvBalanceDebitAmount: Text; AdvBalanceCreditAmount: Text)
    var
        OppAdvBalanceDebitAmount: Text;
        OppAdvBalanceCreditAmount: Text;
    begin
        if PrintVendorData then begin
            OppAdvBalanceDebitAmount := AdvBalanceCreditAmount;
            OppAdvBalanceCreditAmount := AdvBalanceDebitAmount;
        end;
        ReconActReportHelper.FillAdvFooter(EndingDate, AdvBalanceDebitAmount, AdvBalanceCreditAmount,
          OppAdvBalanceDebitAmount, OppAdvBalanceCreditAmount)
    end;

    local procedure FillPrevAdvFooter(EndingDate: Date; PrevAdvBalanceDebitAmount: Text; PrevAdvBalanceCreditAmount: Text)
    var
        OppPrevAdvBalanceDebitAmount: Text;
        OppPrevAdvBalanceCreditAmount: Text;
    begin
        if PrintVendorData then begin
            OppPrevAdvBalanceDebitAmount := PrevAdvBalanceCreditAmount;
            OppPrevAdvBalanceCreditAmount := PrevAdvBalanceDebitAmount;
        end;
        ReconActReportHelper.FillPrevAdvFooter(EndingDate, PrevAdvBalanceDebitAmount, PrevAdvBalanceCreditAmount,
          OppPrevAdvBalanceDebitAmount, OppPrevAdvBalanceCreditAmount)
    end;

    local procedure FillPageFooter(StartingDate: Date; EndingDate: Date; InitialDebitAmount: Text; InitialCreditAmount: Text; TurnoverDebitAmount: Text; TurnoverCreditAmount: Text; TotalDebitAmount: Text; TotalCreditAmount: Text)
    var
        OppInitialDebitAmount: Text;
        OppInitialCreditAmount: Text;
        OppTurnoverDebitAmount: Text;
        OppTurnoverCreditAmount: Text;
        OppTotalDebitAmount: Text;
        OppTotalCreditAmount: Text;
    begin
        if PrintVendorData then begin
            OppInitialDebitAmount := InitialCreditAmount;
            OppInitialCreditAmount := InitialDebitAmount;
            OppTurnoverDebitAmount := TurnoverCreditAmount;
            OppTurnoverCreditAmount := TurnoverDebitAmount;
            OppTotalDebitAmount := TotalCreditAmount;
            OppTotalCreditAmount := TotalDebitAmount;
        end;
        ReconActReportHelper.FillPageFooter(StartingDate, EndingDate, InitialDebitAmount, InitialCreditAmount,
          OppInitialDebitAmount, OppInitialCreditAmount, TurnoverDebitAmount,
          TurnoverCreditAmount, OppTurnoverDebitAmount, OppTurnoverCreditAmount, TotalDebitAmount, TotalCreditAmount,
          OppTotalDebitAmount, OppTotalCreditAmount)
    end;

    local procedure PreparePrintAmounts(var CreditAmountTxt: Text; var DebitAmountTxt: Text; CreditAmount: Decimal; DebitAmount: Decimal; Correction: Boolean)
    begin
        if ((DebitAmount < 0) or (CreditAmount < 0)) xor Correction then begin
            CreditAmountTxt := FormatAmount(-DebitAmount);
            DebitAmountTxt := FormatAmount(-CreditAmount);
        end else begin
            CreditAmountTxt := FormatAmount(CreditAmount);
            DebitAmountTxt := FormatAmount(DebitAmount);
        end;
    end;
}

