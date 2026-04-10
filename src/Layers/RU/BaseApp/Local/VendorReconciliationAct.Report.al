#pragma warning disable AA0247
report 14911 "Vendor - Reconciliation Act"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor Reconciliations';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Agreement Filter";
            dataitem(OldVendInvoices; "Vendor Ledger Entry")
            {
                DataItemLink = "Vendor No." = field("No."), "Agreement No." = field("Agreement Filter");
                DataItemTableView = sorting("Document Type", "Vendor No.", "Posting Date", "Currency Code");
                dataitem(OldAppldVendPays2; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then begin
                            if not AppldVendLedgEntryTmp.FindSet() then
                                CurrReport.Break();
                        end else
                            if AppldVendLedgEntryTmp.Next(1) = 0 then
                                CurrReport.Break();

                        if not (AppldVendLedgEntryTmp."Posting Date" in [MinDate .. MaxDate]) then
                            CurrReport.Skip();

                        OldAppldVendPays."Entry Type" := OldAppldVendPays."Entry Type"::Application;
                        VendPayProcessing(OldAppldVendPays, OldVendInvoices, false);
                        PayCounter += 1;
                        if (CurrencyCode = '') or (VendLedgEntry."Currency Code" = CurrencyCode) then
                            SetOppositeData(1, Format(DocumentAmount, 0, '<Precision,2:2><Standard Format,0>'), CreditAppliedAmt, DebitAppliedAmt)
                        else
                            SetOppositeData(1, VendLedgEntry."Currency Code", CreditAppliedAmt, DebitAppliedAmt);

                        if (ShowDetails = 0) and ((CurrencyCode = '') or (VendLedgEntry."Currency Code" = CurrencyCode)) then
                            ReconActReportHelper.FillBody(
                              Format(InvCounter) + '.' + Format(PayCounter), Format(PostingDate), EntryDescription,
                              FormatAmount(DocumentAmount), FormatAmount(DebitAppliedAmt), FormatAmount(CreditAppliedAmt),
                              OppositeText, FormatAmount(OppositeData[1, 1]), FormatAmount(OppositeData[1, 2]));
                    end;
                }
                dataitem(OldAppldVendPays; "Detailed Vendor Ledg. Entry")
                {
                    DataItemLink = "Vendor Ledger Entry No." = field("Entry No.");
                    DataItemTableView = sorting("Vendor Ledger Entry No.", "Entry Type", "Posting Date") where("Entry Type" = filter("Realized Gain" | "Unrealized Gain" | "Realized Loss" | "Unrealized Loss"));

                    trigger OnAfterGetRecord()
                    begin
                        VendPayProcessing(OldAppldVendPays, OldVendInvoices, false);
                        PayCounter += 1;
                        if (CurrencyCode = '') or (VendLedgEntry."Currency Code" = CurrencyCode) then
                            SetOppositeData(1, Format(DocumentAmount, 0, '<Precision,2:2><Standard Format,0>'), CreditAppliedAmt, DebitAppliedAmt)
                        else
                            SetOppositeData(1, VendLedgEntry."Currency Code", CreditAppliedAmt, DebitAppliedAmt);

                        if ShowDetails = 0 then begin
                            if (CurrencyCode = '') or (VendLedgEntry."Currency Code" = CurrencyCode) then
                                ReconActReportHelper.FillBody(
                                  Format(InvCounter) + '.' + Format(PayCounter), Format(PostingDate), EntryDescription,
                                  FormatAmount(DocumentAmount), FormatAmount(DebitAppliedAmt), FormatAmount(CreditAppliedAmt),
                                  OppositeText, FormatAmount(OppositeData[1, 1]), FormatAmount(OppositeData[1, 2]));
                            if not ((CurrencyCode = '') or (VendLedgEntry."Currency Code" = CurrencyCode)) then
                                ReconActReportHelper.FillBody(
                                  Format(InvCounter) + '.' + Format(PayCounter), Format(PostingDate), EntryDescription,
                                  VendLedgEntry."Currency Code", FormatAmount(DebitAppliedAmt), FormatAmount(CreditAppliedAmt),
                                  OppositeText, FormatAmount(OppositeData[1, 1]), FormatAmount(OppositeData[1, 2]));
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
                        SetOppositeData(1, '', TotalInvAmount, 0);

                        if ShowDetails < 2 then
                            ReconActReportHelper.FillFooter(
                              Format(OldVendInvoices."Document Type") + ' ' + OldVendInvoices."Document No.",
                              FormatAmount(0), FormatAmount(TotalInvAmount), FormatAmount(OppositeData[1, 1]), FormatAmount(0));
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if not IsVendorInvoice(OldVendInvoices) then
                        CurrReport.Skip();

                    SetFilter("Date Filter", '..%1', FirstDate);
                    GetVendAmounts(OldVendInvoices, TempAmount, RemainingAmount);
                    RemainingAmount := -RemainingAmount;
                    if RemainingAmount = 0 then
                        CurrReport.Skip();

                    IsInvProcessedInPrevPeriod("Entry No.", false);

                    SetFilter("Date Filter", '..%1', "Posting Date");
                    GetVendAmounts(OldVendInvoices, DocumentAmount, TempAmount);
                    DocumentAmount := -DocumentAmount;
                    TotalInvAmount := RemainingAmount;
                    InvCounter += 1;
                    EntryDescription := Format("Document Type") + ' ' + "Document No." + ' ' + Description;
                    SetOppositeData(1, Format(DocumentAmount, 0, '<Precision,2:2><Standard Format,0>'), RemainingAmount, 0);

                    FindAppldVendLedgEntry("Entry No.");

                    if ShowDetails < 2 then
                        ReconActReportHelper.FillBody(
                          Format(InvCounter), Format("Posting Date"), EntryDescription,
                          FormatAmount(DocumentAmount), FormatAmount(0), FormatAmount(RemainingAmount),
                          OppositeText, FormatAmount(OppositeData[1, 1]), FormatAmount(0));
                end;

                trigger OnPreDataItem()
                begin
                    if CurrencyCode <> '' then
                        SetFilter("Currency Code", CurrencyCode);
                    SetFilter("Posting Date", '..%1', FirstDate);

                    if (not OldVendInvoices.IsEmpty) and (ShowDetails < 2) then
                        ReconActReportHelper.FillPrevHeader();
                end;
            }
            dataitem(VendInvoices; "Vendor Ledger Entry")
            {
                DataItemLink = "Vendor No." = field("No."), "Agreement No." = field("Agreement Filter");
                DataItemTableView = sorting("Document Type", "Vendor No.", "Posting Date", "Currency Code");
                dataitem(AppldVendPays2; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then begin
                            if not AppldVendLedgEntryTmp.FindSet() then
                                CurrReport.Break();
                        end else
                            if AppldVendLedgEntryTmp.Next(1) = 0 then
                                CurrReport.Break();

                        if AppldVendLedgEntryTmp."Posting Date" < MinDate then
                            CurrReport.Skip();

                        AppldVendPays."Entry Type" := AppldVendPays."Entry Type"::Application;
                        VendPayProcessing(AppldVendPays, VendInvoices, true);
                        PayCounter += 1;
                        if (CurrencyCode = '') or (VendLedgEntry."Currency Code" = CurrencyCode) then
                            SetOppositeData(1, Format(DocumentAmount, 0, '<Precision,2:2><Standard Format,0>'), CreditAppliedAmt, DebitAppliedAmt)
                        else
                            SetOppositeData(1, VendLedgEntry."Currency Code", CreditAppliedAmt, DebitAppliedAmt);

                        if (ShowDetails = 0) and ((CurrencyCode = '') or (VendLedgEntry."Currency Code" = CurrencyCode)) then
                            ReconActReportHelper.FillBody(
                              Format(InvCounter) + '.' + Format(PayCounter), Format(PostingDate), EntryDescription,
                              FormatAmount(DocumentAmount), FormatAmount(DebitAppliedAmt), FormatAmount(CreditAppliedAmt),
                              OppositeText, FormatAmount(OppositeData[1, 1]), FormatAmount(OppositeData[1, 2]));
                    end;
                }
                dataitem(AppldVendPays; "Detailed Vendor Ledg. Entry")
                {
                    DataItemLink = "Vendor Ledger Entry No." = field("Entry No.");
                    DataItemTableView = sorting("Vendor Ledger Entry No.", "Entry Type", "Posting Date") where("Entry Type" = filter("Realized Gain" | "Unrealized Gain" | "Realized Loss" | "Unrealized Loss"));

                    trigger OnAfterGetRecord()
                    begin
                        VendPayProcessing(AppldVendPays, VendInvoices, true);
                        PayCounter += 1;
                        if (CurrencyCode = '') or (VendLedgEntry."Currency Code" = CurrencyCode) then
                            SetOppositeData(1, Format(DocumentAmount, 0, '<Precision,2:2><Standard Format,0>'), CreditAppliedAmt, DebitAppliedAmt)
                        else
                            SetOppositeData(1, VendLedgEntry."Currency Code", CreditAppliedAmt, DebitAppliedAmt);

                        if ShowDetails = 0 then begin
                            if (CurrencyCode = '') or (VendLedgEntry."Currency Code" = CurrencyCode) then
                                ReconActReportHelper.FillBody(
                                  Format(InvCounter) + '.' + Format(PayCounter), Format(PostingDate), EntryDescription,
                                  FormatAmount(DocumentAmount), FormatAmount(DebitAppliedAmt), FormatAmount(CreditAppliedAmt),
                                  OppositeText, FormatAmount(OppositeData[1, 1]), FormatAmount(OppositeData[1, 2]));
                            if not ((CurrencyCode = '') or (VendLedgEntry."Currency Code" = CurrencyCode)) then
                                ReconActReportHelper.FillBody(
                                  Format(InvCounter) + '.' + Format(PayCounter), Format(PostingDate), EntryDescription,
                                  VendLedgEntry."Currency Code", FormatAmount(DebitAppliedAmt), FormatAmount(CreditAppliedAmt),
                                  OppositeText, FormatAmount(OppositeData[1, 1]), FormatAmount(OppositeData[1, 2]));
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
                        SetOppositeData(1, '', TotalInvAmount, 0);

                        if ShowDetails < 2 then
                            ReconActReportHelper.FillFooter(
                              Format(VendInvoices."Document Type") + ' ' + VendInvoices."Document No.",
                              FormatAmount(0), FormatAmount(TotalInvAmount), FormatAmount(OppositeData[1, 1]), FormatAmount(0));
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if not IsVendorInvoice(VendInvoices) then
                        if IsReturnPrepayment(VendInvoices) then begin
                            if IsReturnPpmtForCurrentPeriod(VendInvoices) then
                                CurrReport.Skip();
                        end else
                            CurrReport.Skip();

                    if "Posting Date" <= FirstDate then
                        if (not CurrentPeriodApplicationExists("Entry No.")) or IsInvProcessedInPrevPeriod("Entry No.", true) then
                            CurrReport.Skip();

                    SetFilter("Date Filter", '..%1', "Posting Date");
                    GetVendAmounts(VendInvoices, DocumentAmount, TempAmount);
                    DocumentAmount := -DocumentAmount;
                    if "Posting Date" in [MinDate .. MaxDate] then
                        CreditTurnover2 += DocumentAmount;

                    SetFilter("Date Filter", DateFilter);
                    GetVendAmounts(VendInvoices, TempAmount, RemainingAmount);
                    RemainingAmount := -RemainingAmount;

                    TotalInvAmount := DocumentAmount;
                    RemainingAmount := -GetInvRemAmtAtDate("Entry No.");
                    if "Posting Date" <= FirstDate then
                        TotalInvAmount := RemainingAmount;
                    InvCounter += 1;
                    EntryDescription := Format("Document Type") + ' ' + "Document No." + ' ' + Description;
                    SetOppositeData(1, Format(DocumentAmount, 0, '<Precision,2:2><Standard Format,0>'), RemainingAmount, 0);

                    FindAppldVendLedgEntry("Entry No.");

                    if ShowDetails < 2 then
                        ReconActReportHelper.FillBody(
                          Format(InvCounter), Format("Posting Date"), EntryDescription,
                          FormatAmount(DocumentAmount), FormatAmount(0), FormatAmount(RemainingAmount),
                          OppositeText, FormatAmount(OppositeData[1, 1]), FormatAmount(0));
                end;

                trigger OnPreDataItem()
                begin
                    if CurrencyCode <> '' then
                        SetFilter("Currency Code", CurrencyCode);
                    SetRange("Posting Date", 0D, MaxDate);
                    InvCounter := 0;

                    if (not VendInvoices.IsEmpty) and (ShowDetails < 2) then
                        ReconActReportHelper.FillHeader(MinDate, MaxDate);
                end;
            }
            dataitem(VendPayments; "Vendor Ledger Entry")
            {
                DataItemLink = "Vendor No." = field("No."), "Agreement No." = field("Agreement Filter");
                DataItemTableView = sorting("Document Type", "Vendor No.", "Posting Date", "Currency Code");
                dataitem(VendOtherCurrAppln; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));

                    trigger OnAfterGetRecord()
                    begin
                        if OtherCurrApplAmount = 0 then
                            CurrReport.Skip();
                        InvCounter += 1;
                        SetOppositeData(1, '', OtherCurrApplAmount, RemainingAmount);

                        if ShowDetails = 2 then
                            ReconActReportHelper.FillAdvOtherCurrBody(
                              Format(PayCounter) + '.1', Format(VendPayments."Document Type") + ' ' + VendPayments."Document No.",
                              FormatAmount(0), FormatAmount(OtherCurrApplAmount), FormatAmount(OppositeData[1, 1]), FormatAmount(0),
                              FormatAmount(RemainingAmount), FormatAmount(0), FormatAmount(0), FormatAmount(OppositeData[1, 2]));
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if not IsVendorPayment(VendPayments) then
                        CurrReport.Skip();

                    SetFilter("Date Filter", DateFilter);
                    GetVendPay(VendPayments, DocumentAmount, RemainingAmount, OtherCurrApplAmount);

                    if (RemainingAmount + OtherCurrApplAmount = 0) and ("Document Type" <> "Document Type"::Refund) then
                        CurrReport.Skip();
                    DebitTurnover2 += (RemainingAmount + OtherCurrApplAmount);
                    TotalPayAmount += RemainingAmount;
                    PayCounter += 1;
                    InvCounter := 0;
                    SetOppositeData(1, Format(DocumentAmount, 0, '<Precision,2:2><Standard Format,0>'), 0, RemainingAmount);
                    SetOppositeData(2, '', 0, TotalPayAmount);
                    if "Document Type" = "Document Type"::Refund then
                        Description := CopyStr(Description + ' (' + "Applies-to Doc. No." + ')', 1, MaxStrLen(Description));

                    if ShowDetails < 2 then
                        ReconActReportHelper.FillBody(
                          Format(PayCounter), Format("Posting Date"), Format("Document Type") + ' ' + "Document No." + ' ' + Description,
                          FormatAmount(DocumentAmount), FormatAmount(RemainingAmount), FormatAmount(0),
                          OppositeText, FormatAmount(0), FormatAmount(OppositeData[1, 2]));
                end;

                trigger OnPostDataItem()
                begin
                    DebitBalance2 += TotalPayAmount;

                    if (ShowDetails < 2) and (not VendPayments.IsEmpty) then
                        ReconActReportHelper.FillAdvFooter(
                          MaxDate, FormatAmount(TotalPayAmount), FormatAmount(0), FormatAmount(0), FormatAmount(OppositeData[2, 2]));
                end;

                trigger OnPreDataItem()
                begin
                    if CurrencyCode <> '' then
                        SetFilter("Currency Code", CurrencyCode);
                    SetFilter("Posting Date", DateFilter);
                    PayCounter := 0;

                    if (ShowDetails < 2) and (not VendPayments.IsEmpty) then
                        ReconActReportHelper.FillAdvHeader(MinDate, MaxDate);
                end;
            }
            dataitem(OldVendPayments; "Vendor Ledger Entry")
            {
                DataItemLink = "Vendor No." = field("No."), "Agreement No." = field("Agreement Filter");
                DataItemTableView = sorting("Document Type", "Vendor No.", "Posting Date", "Currency Code");
                dataitem(OldVendOtherCurrAppln; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));

                    trigger OnAfterGetRecord()
                    begin
                        if OtherCurrApplAmount = 0 then
                            CurrReport.Skip();
                        InvCounter += 1;
                        SetOppositeData(1, '', OtherCurrApplAmount, RemainingAmount);

                        if ShowDetails = 2 then
                            ReconActReportHelper.FillAdvOtherCurrBody(
                              Format(PayCounter) + '.1', Format(OldVendPayments."Document Type") + ' ' + OldVendPayments."Document No.",
                              FormatAmount(0), FormatAmount(OtherCurrApplAmount), FormatAmount(OppositeData[1, 1]), FormatAmount(0),
                              FormatAmount(RemainingAmount), FormatAmount(0), FormatAmount(0), FormatAmount(OppositeData[1, 2]));
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if not IsVendorPayment(OldVendPayments) then
                        CurrReport.Skip();

                    SetFilter("Date Filter", '..%1', MaxDate);
                    GetVendPay(OldVendPayments, DocumentAmount, RemainingAmount, OtherCurrApplAmount);

                    if RemainingAmount + OtherCurrApplAmount = 0 then
                        CurrReport.Skip();
                    TotalPayAmount += RemainingAmount;
                    PayCounter += 1;
                    InvCounter := 0;
                    SetOppositeData(1, Format(DocumentAmount, 0, '<Precision,2:2><Standard Format,0>'), 0, RemainingAmount);
                    SetOppositeData(2, '', 0, TotalPayAmount);
                    if "Document Type" = "Document Type"::Refund then
                        Description := CopyStr(Description + ' (' + "Applies-to Doc. No." + ')', 1, MaxStrLen(Description));

                    if ShowDetails < 2 then
                        ReconActReportHelper.FillBody(
                          Format(PayCounter), Format("Posting Date"), Format("Document Type") + ' ' + "Document No." + ' ' + Description,
                          FormatAmount(DocumentAmount), FormatAmount(RemainingAmount), FormatAmount(0),
                          OppositeText, FormatAmount(0), FormatAmount(OppositeData[1, 2]));
                end;

                trigger OnPostDataItem()
                begin
                    DebitBalance2 += TotalPayAmount;

                    if (ShowDetails < 2) and (not OldVendPayments.IsEmpty) then
                        ReconActReportHelper.FillPrevAdvFooter(
                          MaxDate, FormatAmount(TotalPayAmount), FormatAmount(0), FormatAmount(0), FormatAmount(OppositeData[2, 2]));
                end;

                trigger OnPreDataItem()
                begin
                    if CurrencyCode <> '' then
                        SetFilter("Currency Code", CurrencyCode);
                    SetFilter("Posting Date", '..%1', FirstDate);
                    PayCounter := 0;
                    TotalPayAmount := 0;

                    if (ShowDetails < 2) and (not OldVendPayments.IsEmpty) then
                        ReconActReportHelper.FillPrevAdvHeader(MinDate);
                end;
            }
            dataitem(VendTotal; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));

                trigger OnAfterGetRecord()
                begin
                    AdjustTotalsBalance(DebitBalance2, CreditBalance2);
                    SetOppositeData(1, '', CreditTurnover2, DebitTurnover2);
                    SetOppositeData(2, '', CreditBalance2, DebitBalance2);

                    ReconActReportHelper.FillVendFooter(
                      MinDate, MaxDate,
                      FormatAmount(DebitTurnover2), FormatAmount(CreditTurnover2),
                      FormatAmount(OppositeData[1, 1]), FormatAmount(OppositeData[1, 2]),
                      FormatAmount(DebitBalance2), FormatAmount(CreditBalance2),
                      FormatAmount(OppositeData[2, 1]), FormatAmount(OppositeData[2, 2]));
                end;
            }
            dataitem(Customer; Customer)
            {
                DataItemLink = "Vendor No." = field("No.");
                DataItemTableView = sorting("No.");
                PrintOnlyIfDetail = true;
                RequestFilterFields = "Agreement Filter";
                dataitem(OldCustInvoices; "Cust. Ledger Entry")
                {
                    DataItemLink = "Customer No." = field("No."), "Agreement No." = field("Agreement Filter");
                    DataItemTableView = sorting("Document Type", "Customer No.", "Posting Date", "Currency Code") where("Document Type" = filter(" " | Invoice | "Credit Memo"));
                    dataitem(OldAppldCustPays; "Detailed Cust. Ledg. Entry")
                    {
                        DataItemLink = "Cust. Ledger Entry No." = field("Entry No.");
                        DataItemTableView = sorting("Cust. Ledger Entry No.", "Posting Date") where("Entry Type" = filter(Application | "Realized Gain" | "Unrealized Gain" | "Realized Loss" | "Unrealized Loss"));

                        trigger OnAfterGetRecord()
                        begin
                            CustPayProcessing(OldAppldCustPays, OldCustInvoices);
                            PayCounter += 1;
                            if (CurrencyCode = '') or (CustLedgEntry."Currency Code" = CurrencyCode) then
                                SetOppositeData(1, Format(DocumentAmount, 0, '<Precision,2:2><Standard Format,0>'), CreditAppliedAmt, DebitAppliedAmt)
                            else
                                SetOppositeData(1, CustLedgEntry."Currency Code", CreditAppliedAmt, DebitAppliedAmt);

                            if ShowDetails = 0 then begin
                                if (CurrencyCode = '') or (CustLedgEntry."Currency Code" = CurrencyCode) then
                                    ReconActReportHelper.FillBody(
                                      Format(InvCounter) + '.' + Format(PayCounter), Format(PostingDate), EntryDescription,
                                      FormatAmount(DocumentAmount), FormatAmount(DebitAppliedAmt), FormatAmount(CreditAppliedAmt),
                                      OppositeText, FormatAmount(OppositeData[1, 1]), FormatAmount(OppositeData[1, 2]));
                                if not ((CurrencyCode = '') or (CustLedgEntry."Currency Code" = CurrencyCode)) then
                                    ReconActReportHelper.FillBody(
                                      Format(InvCounter) + '.' + Format(PayCounter), Format(PostingDate), EntryDescription,
                                      CustLedgEntry."Currency Code", FormatAmount(DebitAppliedAmt), FormatAmount(CreditAppliedAmt),
                                      OppositeText, FormatAmount(OppositeData[1, 1]), FormatAmount(OppositeData[1, 2]));
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
                            DebitBalance += TotalInvAmount;
                            SetOppositeData(1, '', 0, TotalInvAmount);

                            if ShowDetails < 2 then
                                ReconActReportHelper.FillFooter(
                                  Format(OldVendInvoices."Document Type") + ' ' + OldCustInvoices."Document No.",
                                  FormatAmount(TotalInvAmount), FormatAmount(0), FormatAmount(0), FormatAmount(OppositeData[1, 2]));
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        SetFilter("Date Filter", '..%1', FirstDate);
                        GetCustAmounts(OldCustInvoices, TempAmount, RemainingAmount);
                        if RemainingAmount = 0 then
                            CurrReport.Skip();

                        SetFilter("Date Filter", '..%1', "Posting Date");
                        GetCustAmounts(OldCustInvoices, DocumentAmount, TempAmount);
                        TotalInvAmount := RemainingAmount;
                        InvCounter += 1;
                        EntryDescription := Format("Document Type") + ' ' + "Document No." + ' ' + Description;
                        SetOppositeData(1, Format(DocumentAmount, 0, '<Precision,2:2><Standard Format,0>'), 0, RemainingAmount);

                        if ShowDetails < 2 then
                            ReconActReportHelper.FillBody(
                              Format(InvCounter), Format("Posting Date"), EntryDescription,
                              FormatAmount(DocumentAmount), FormatAmount(RemainingAmount), FormatAmount(0),
                              OppositeText, FormatAmount(0), FormatAmount(OppositeData[1, 2]));
                    end;

                    trigger OnPreDataItem()
                    begin
                        if CurrencyCode <> '' then
                            SetFilter("Currency Code", CurrencyCode);
                        SetFilter("Posting Date", '..%1', FirstDate);

                        if (not OldCustInvoices.IsEmpty) and (ShowDetails < 2) then
                            ReconActReportHelper.FillPrevHeader();
                    end;
                }
                dataitem(CustInvoices; "Cust. Ledger Entry")
                {
                    DataItemLink = "Customer No." = field("No."), "Agreement No." = field("Agreement Filter");
                    DataItemTableView = sorting("Document Type", "Customer No.", "Posting Date", "Currency Code") where("Document Type" = filter(" " | Invoice | "Credit Memo"));
                    dataitem(AppldCustPays; "Detailed Cust. Ledg. Entry")
                    {
                        DataItemLink = "Cust. Ledger Entry No." = field("Entry No.");
                        DataItemTableView = sorting("Cust. Ledger Entry No.", "Posting Date") where("Entry Type" = filter(Application | "Realized Gain" | "Unrealized Gain" | "Realized Loss" | "Unrealized Loss"));

                        trigger OnAfterGetRecord()
                        begin
                            CustPayProcessing(AppldCustPays, CustInvoices);
                            PayCounter += 1;
                            if (CurrencyCode = '') or (CustLedgEntry."Currency Code" = CurrencyCode) then
                                SetOppositeData(1, Format(DocumentAmount, 0, '<Precision,2:2><Standard Format,0>'), CreditAppliedAmt, DebitAppliedAmt)
                            else
                                SetOppositeData(1, CustLedgEntry."Currency Code", CreditAppliedAmt, DebitAppliedAmt);

                            if ShowDetails = 0 then begin
                                if (CurrencyCode = '') or (CustLedgEntry."Currency Code" = CurrencyCode) then
                                    ReconActReportHelper.FillBody(
                                      Format(InvCounter) + '.' + Format(PayCounter), Format(PostingDate), EntryDescription,
                                      FormatAmount(DocumentAmount), FormatAmount(DebitAppliedAmt), FormatAmount(CreditAppliedAmt),
                                      OppositeText, FormatAmount(OppositeData[1, 1]), FormatAmount(OppositeData[1, 2]));
                                if not ((CurrencyCode = '') or (CustLedgEntry."Currency Code" = CurrencyCode)) then
                                    ReconActReportHelper.FillBody(
                                      Format(InvCounter) + '.' + Format(PayCounter), Format(PostingDate), EntryDescription,
                                      CustLedgEntry."Currency Code", FormatAmount(DebitAppliedAmt), FormatAmount(CreditAppliedAmt),
                                      OppositeText, FormatAmount(OppositeData[1, 1]), FormatAmount(OppositeData[1, 2]));
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
                            DebitBalance += TotalInvAmount;
                            SetOppositeData(1, '', 0, TotalInvAmount);

                            if ShowDetails < 2 then
                                ReconActReportHelper.FillFooter(
                                  Format(CustInvoices."Document Type") + ' ' + CustInvoices."Document No.",
                                  FormatAmount(TotalInvAmount), FormatAmount(0), FormatAmount(0), FormatAmount(OppositeData[1, 2]));
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        SetFilter("Date Filter", '..%1', "Posting Date");
                        GetCustAmounts(CustInvoices, DocumentAmount, TempAmount);
                        DebitTurnover += DocumentAmount;

                        SetFilter("Date Filter", DateFilter);
                        GetCustAmounts(CustInvoices, TempAmount, RemainingAmount);

                        TotalInvAmount := DocumentAmount;
                        RemainingAmount := DocumentAmount;
                        InvCounter += 1;
                        EntryDescription := Format("Document Type") + ' ' + "Document No." + ' ' + Description;
                        SetOppositeData(1, Format(DocumentAmount, 0, '<Precision,2:2><Standard Format,0>'), 0, RemainingAmount);

                        if ShowDetails < 2 then
                            ReconActReportHelper.FillBody(
                              Format(InvCounter), Format("Posting Date"), EntryDescription,
                              FormatAmount(DocumentAmount), FormatAmount(RemainingAmount), FormatAmount(0),
                              OppositeText, FormatAmount(0), FormatAmount(OppositeData[1, 2]));
                    end;

                    trigger OnPreDataItem()
                    begin
                        if CurrencyCode <> '' then
                            SetFilter("Currency Code", CurrencyCode);
                        SetFilter("Posting Date", DateFilter);
                        InvCounter := 0;

                        if (not CustInvoices.IsEmpty) and (ShowDetails < 2) then
                            ReconActReportHelper.FillHeader(MinDate, MaxDate);
                    end;
                }
                dataitem(CustPayments; "Cust. Ledger Entry")
                {
                    DataItemLink = "Customer No." = field("No."), "Agreement No." = field("Agreement Filter");
                    DataItemTableView = sorting("Document Type", "Customer No.", "Posting Date", "Currency Code") where("Document Type" = filter(Payment | Refund));
                    dataitem(CustOtherCurrAppln; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));

                        trigger OnAfterGetRecord()
                        begin
                            if OtherCurrApplAmount = 0 then
                                CurrReport.Skip();
                            InvCounter += 1;
                            SetOppositeData(1, '', RemainingAmount, OtherCurrApplAmount);

                            if ShowDetails = 2 then
                                ReconActReportHelper.FillAdvOtherCurrBody(
                                  Format(PayCounter) + '.' + Format(InvCounter), Format(CustPayments."Document Type") + ' ' + CustPayments."Document No.",
                                  FormatAmount(OtherCurrApplAmount), FormatAmount(0), FormatAmount(0), FormatAmount(OppositeData[1, 2]),
                                  FormatAmount(0), FormatAmount(RemainingAmount), FormatAmount(OppositeData[1, 1]), FormatAmount(0));
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        SetFilter("Date Filter", DateFilter);
                        GetCustPay(CustPayments, DocumentAmount, RemainingAmount, OtherCurrApplAmount);
                        CreditTurnover += DocumentAmount;

                        if ShowDetails = ShowDetails::Full then
                            if (RemainingAmount + OtherCurrApplAmount = 0) and ("Document Type" <> "Document Type"::Refund) then
                                CurrReport.Skip();
                        TotalPayAmount += RemainingAmount;
                        PayCounter += 1;
                        InvCounter := 0;
                        SetOppositeData(1, Format(DocumentAmount, 0, '<Precision,2:2><Standard Format,0>'), RemainingAmount, 0);
                        SetOppositeData(2, '', TotalPayAmount, 0);
                        if "Document Type" = "Document Type"::Refund then
                            Description := CopyStr(Description + ' (' + "Applies-to Doc. No." + ')', 1, MaxStrLen(Description));

                        if ShowDetails < 2 then
                            ReconActReportHelper.FillBody(
                              Format(PayCounter), Format("Posting Date"), Format("Document Type") + ' ' + "Document No." + ' ' + Description,
                              FormatAmount(DocumentAmount), FormatAmount(0), FormatAmount(RemainingAmount + OtherCurrApplAmount),
                              OppositeText, FormatAmount(OppositeData[1, 1]), FormatAmount(0));
                    end;

                    trigger OnPostDataItem()
                    begin
                        CreditBalance += TotalPayAmount;

                        if (ShowDetails < 2) and (not CustPayments.IsEmpty) then
                            ReconActReportHelper.FillAdvFooter(
                              MaxDate, FormatAmount(0), FormatAmount(TotalPayAmount), FormatAmount(OppositeData[2, 1]), FormatAmount(0));
                    end;

                    trigger OnPreDataItem()
                    begin
                        if CurrencyCode <> '' then
                            SetFilter("Currency Code", CurrencyCode);
                        SetFilter("Posting Date", DateFilter);
                        PayCounter := 0;

                        if (ShowDetails < 2) and (not CustPayments.IsEmpty) then
                            ReconActReportHelper.FillAdvHeader(MinDate, MaxDate);
                    end;
                }
                dataitem(OldCustPayments; "Cust. Ledger Entry")
                {
                    DataItemLink = "Customer No." = field("No."), "Agreement No." = field("Agreement Filter");
                    DataItemTableView = sorting("Document Type", "Customer No.", "Posting Date", "Currency Code") where("Document Type" = filter(Payment | Refund));
                    dataitem(OldCustOtherCurrAppln; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));

                        trigger OnAfterGetRecord()
                        begin
                            if OtherCurrApplAmount = 0 then
                                CurrReport.Skip();
                            InvCounter += 1;
                            SetOppositeData(1, '', RemainingAmount, OtherCurrApplAmount);

                            if ShowDetails = 2 then
                                ReconActReportHelper.FillAdvOtherCurrBody(
                                  Format(PayCounter) + '.' + Format(InvCounter), Format(OldCustPayments."Document Type") + ' ' + OldCustPayments."Document No.",
                                  FormatAmount(OtherCurrApplAmount), FormatAmount(0), FormatAmount(0), FormatAmount(OppositeData[1, 2]),
                                  FormatAmount(0), FormatAmount(RemainingAmount), FormatAmount(OppositeData[1, 1]), FormatAmount(0));
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        SetFilter("Date Filter", '..%1', MaxDate);
                        GetCustPay(OldCustPayments, DocumentAmount, RemainingAmount, OtherCurrApplAmount);

                        if RemainingAmount + OtherCurrApplAmount = 0 then
                            CurrReport.Skip();
                        TotalPayAmount += RemainingAmount;
                        PayCounter += 1;
                        InvCounter := 0;
                        SetOppositeData(1, Format(DocumentAmount, 0, '<Precision,2:2><Standard Format,0>'), RemainingAmount, 0);
                        SetOppositeData(2, '', TotalPayAmount, 0);
                        if "Document Type" = "Document Type"::Refund then
                            Description := CopyStr(Description + ' (' + "Applies-to Doc. No." + ')', 1, MaxStrLen(Description));

                        if ShowDetails < 2 then
                            ReconActReportHelper.FillBody(
                              Format(PayCounter), Format("Posting Date"), Format("Document Type") + ' ' + "Document No." + ' ' + Description,
                              FormatAmount(DocumentAmount), FormatAmount(0), FormatAmount(RemainingAmount),
                              OppositeText, FormatAmount(OppositeData[1, 1]), FormatAmount(0));
                    end;

                    trigger OnPostDataItem()
                    begin
                        CreditBalance += TotalPayAmount;

                        if (ShowDetails < 2) and (not OldCustPayments.IsEmpty) then
                            ReconActReportHelper.FillPrevAdvFooter(
                              MaxDate, FormatAmount(0), FormatAmount(TotalPayAmount), FormatAmount(OppositeData[2, 1]), FormatAmount(0));
                    end;

                    trigger OnPreDataItem()
                    begin
                        if CurrencyCode <> '' then
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
                        AdjustTotals(DebitBalance, CreditBalance);
                        SetOppositeData(1, '', CreditTurnover, DebitTurnover);
                        SetOppositeData(2, '', CreditBalance, DebitBalance);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    DtldCustLedgEntry.Reset();
                    DtldCustLedgEntry.SetCurrentKey(
                      "Customer No.", "Initial Document Type", "Document Type", "Entry Type", "Posting Date", "Currency Code"); // PS36580
                    DtldCustLedgEntry.SetRange("Customer No.", "No.");
                    DtldCustLedgEntry.SetFilter("Posting Date", '..%1', FirstDate);
                    DtldCustLedgEntry.SetFilter("Initial Document Type", '%1|%2|%3', DtldCustLedgEntry."Initial Document Type"::" ",
                      DtldCustLedgEntry."Initial Document Type"::Invoice,
                      DtldCustLedgEntry."Initial Document Type"::"Credit Memo");
                    if CurrencyCode <> '' then begin
                        CurrencyClaim := StrSubstNo(Text003, CurrencyCode);
                        DtldCustLedgEntry.SetRange("Currency Code", CurrencyCode);
                        DtldCustLedgEntry.CalcSums(Amount);
                        InitialDebitBalance := DtldCustLedgEntry.Amount;
                    end else begin
                        CurrencyClaim := '';
                        DtldCustLedgEntry.CalcSums("Amount (LCY)");
                        InitialDebitBalance := DtldCustLedgEntry."Amount (LCY)";
                    end;

                    DtldCustLedgEntry.SetFilter("Initial Document Type", '%1|%2', DtldCustLedgEntry."Initial Document Type"::Payment,
                      DtldCustLedgEntry."Initial Document Type"::Refund);
                    if CurrencyCode <> '' then begin
                        DtldCustLedgEntry.CalcSums(Amount);
                        InitialCreditBalance := -DtldCustLedgEntry.Amount;
                    end else begin
                        DtldCustLedgEntry.CalcSums("Amount (LCY)");
                        InitialCreditBalance := -DtldCustLedgEntry."Amount (LCY)";
                    end;

                    if (InitialCreditBalance = 0) and (InitialDebitBalance = 0) and (not HasAnyOps("No.")) then
                        CurrReport.Break();

                    AdjustTotals(InitialDebitBalance, InitialCreditBalance);
                    SetOppositeData(1, '', InitialCreditBalance, InitialDebitBalance);

                    ReconActReportHelper.FillCustHeader(
                      Format(MinDate), FormatAmount(InitialDebitBalance), FormatAmount(InitialCreditBalance),
                      FormatAmount(OppositeData[1, 1]), FormatAmount(OppositeData[1, 2]));
                end;

                trigger OnPreDataItem()
                begin
                    CreditBalance := 0;
                    DebitBalance := 0;
                    CreditTurnover := 0;
                    DebitTurnover := 0;
                    InvCounter := 0;
                    TotalInvAmount := 0;
                    PayCounter := 0;
                    TotalPayAmount := 0;
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
                    CreditBalance := CreditBalance + CreditBalance2;
                    DebitBalance := DebitBalance + DebitBalance2;
                    AdjustTotals(DebitBalance, CreditBalance);
                    CreditTurnover := CreditTurnover + CreditTurnover2;
                    DebitTurnover := DebitTurnover + DebitTurnover2;
                    InitialDebitBalance := InitialDebitBalance + InitialDebitBalance2;
                    InitialCreditBalance := InitialCreditBalance + InitialCreditBalance2;
                    AdjustTotals(InitialDebitBalance, InitialCreditBalance);
                    CreditTotalBalance := InitialCreditBalance + CreditTurnover;
                    DebitTotalBalance := InitialDebitBalance + DebitTurnover;
                    AdjustTotalsBalance(DebitTotalBalance, CreditTotalBalance);
                    SetOppositeData(1, '', InitialCreditBalance, InitialDebitBalance);
                    SetOppositeData(2, '', CreditTurnover, DebitTurnover);
                    SetOppositeData(3, '', CreditBalance, DebitBalance);

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

                    ReconActReportHelper.FillPageFooter(
                      MinDate, MaxDate,
                      FormatAmount(InitialDebitBalance), FormatAmount(InitialCreditBalance),
                      FormatAmount(OppositeData[1, 1]), FormatAmount(OppositeData[1, 2]),
                      FormatAmount(DebitTurnover), FormatAmount(CreditTurnover),
                      FormatAmount(OppositeData[2, 1]), FormatAmount(OppositeData[2, 2]),
                      FormatAmount(DebitTotalBalance), FormatAmount(CreditTotalBalance),
                      FormatAmount(OppositeData[3, 1]), FormatAmount(OppositeData[3, 2]));

                    ReconActReportHelper.FillReportFooter(
                      ResultText, CompanyInfo.Name, Customer.Name,
                      CompanyInfo."Director Name", CompanyInfo."Accountant Name");
                end;
            }

            trigger OnAfterGetRecord()
            begin
                ClearAmounts();
                if CurrencyCode <> '' then
                    CurrencyClaim := StrSubstNo(Text003, CurrencyCode)
                else
                    CurrencyClaim := '';

                GetInitialDebitCreditBalance(InitialDebitBalance2, InitialCreditBalance2);
                AdjustTotalsBalance(InitialDebitBalance2, InitialCreditBalance2);
                SetOppositeData(1, '', InitialCreditBalance2, InitialDebitBalance2);

                if not FirstVendor then
                    ReconActReportHelper.AddPageBreak();
                ReconActReportHelper.FillReportHeader(
                  MinDate, MaxDate, CompanyInfo.Name, CompanyInfo."VAT Registration No.", Name, "VAT Registration No.");
                ReconActReportHelper.FillPageHeader(CurrencyClaim, CompanyInfo.Name, Name);
                ReconActReportHelper.FillVendHeader(
                  Format(MinDate), FormatAmount(InitialDebitBalance2), FormatAmount(InitialCreditBalance2),
                  FormatAmount(OppositeData[1, 1]), FormatAmount(OppositeData[1, 2]));

                FirstVendor := false;
            end;

            trigger OnPreDataItem()
            begin
                FirstDate := CalcDate('<-1D>', MinDate);
                FirstVendor := true;
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
                        OptionCaption = 'All,Partially,None';
                        ToolTip = 'Specifies if the report displays all lines in detail.';
                    }
                    field(PrintCustomerData; PrintCustomerData)
                    {
                        Caption = 'Print Customer Data';
                        ToolTip = 'Specifies if you want to fill in the right side of the report with the customer''s data.';
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
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        AppldVendLedgEntryTmp: Record "Detailed Vendor Ledg. Entry" temporary;
        CurrencyCode: Code[10];
        CurrencyClaim: Text[100];
        DateFilter: Text[250];
        PrintCustomerData: Boolean;
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
        TempAmount: Decimal;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label 'Report currency code: %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text004: Label 'rub';
#pragma warning restore AA0074
        EntryDescription: Text[1024];
        PostingDate: Date;
        OtherCurrApplAmount: Decimal;
        ShowDetails: Option Full,Partly,Nothing;
        OppositeData: array[3, 2] of Decimal;
        OppositeText: Text[30];
        CreditTotalBalance: Decimal;
        DebitTotalBalance: Decimal;
        ProcessedPayEntries: Record "Detailed Vendor Ledg. Entry" temporary;
        ProcessedVendInvoices: Record "Vendor Ledger Entry" temporary;
#pragma warning disable AA0074
        Text007: Label '(AR)';
#pragma warning restore AA0074
        FileName: Text;
        ReconActReportHelper: Codeunit "Recon. Act Report Helper";
        FirstVendor: Boolean;

    local procedure ExchAmount(Amount: Decimal; FromCurrencyCode: Code[10]; ToCurrencyCode: Code[10]; UsePostingDate: Date): Decimal
    var
        ToCurrency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        if (FromCurrencyCode = ToCurrencyCode) or (Amount = 0) then
            exit(Amount);

        if (FromCurrencyCode = '') or (FromCurrencyCode = GLSetup."LCY Code") then
            Amount :=
              CurrExchRate.ExchangeAmtLCYToFCY(
                UsePostingDate, ToCurrencyCode, Amount, VendInvoices."Original Currency Factor")
        else
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
        DtldCustLedgEntry.SetFilter("Entry No.", '%1|%2', SourceEntry."Entry No." - 1, SourceEntry."Entry No." + 1);
        if DtldCustLedgEntry.Find('-') then
            repeat
                if (DtldCustLedgEntry."Entry Type" = DtldCustLedgEntry."Entry Type"::Application) and
                   (DtldCustLedgEntry."Transaction No." = SourceEntry."Transaction No.")
                then begin
                    if GetLedgEntry then
                        CustLedgEntry.Get(DtldCustLedgEntry."Cust. Ledger Entry No.");
                    if SourceEntry."Currency Code" <> DtldCustLedgEntry."Currency Code" then
                        OtherCurrApplAmount += SourceEntry.Amount;
                    exit;
                end;
            until DtldCustLedgEntry.Next() = 0;
    end;

    local procedure GetVendApplicationEntry(SourceEntry: Record "Detailed Vendor Ledg. Entry"; var DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; GetLedgEntry: Boolean; var VendLedgEntry: Record "Vendor Ledger Entry"; var OtherCurrApplAmount: Decimal)
    begin
        DetailedVendLedgEntry.Reset();
        DetailedVendLedgEntry.SetFilter("Entry No.", '%1|%2', SourceEntry."Entry No." - 1, SourceEntry."Entry No." + 1);
        if DetailedVendLedgEntry.Find('-') then
            repeat
                if (DetailedVendLedgEntry."Entry Type" = DetailedVendLedgEntry."Entry Type"::Application) and
                   (DetailedVendLedgEntry."Transaction No." = SourceEntry."Transaction No.")
                then begin
                    if GetLedgEntry then
                        // Positive is just temporary flag
                        VendLedgEntry.Get(DetailedVendLedgEntry."Vendor Ledger Entry No.");
                    if SourceEntry."Currency Code" <> DetailedVendLedgEntry."Currency Code" then
                        OtherCurrApplAmount += SourceEntry.Amount;
                    exit;
                end;
            until DetailedVendLedgEntry.Next() = 0;
    end;

    local procedure AdjustTotals(var DebitAmount: Decimal; var CreditAmount: Decimal)
    begin
        if ShowDetails > 0 then
            AdjustTotalsBalance(DebitAmount, CreditAmount);
    end;

    local procedure GetCustPay(var Rec: Record "Cust. Ledger Entry"; var DocumentAmount: Decimal; var RemainingAmount: Decimal; var OtherCurrApplAmount: Decimal)
    var
        ApplDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        OtherCurrApplAmount := 0;
        GetCustAmounts(Rec, DocumentAmount, RemainingAmount);
        DocumentAmount := -DocumentAmount;
        RemainingAmount := -RemainingAmount;
        if CurrencyCode = '' then
            exit;
        DtldCustLedgEntry.Reset();
        DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type", "Posting Date");
        DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", Rec."Entry No.");
        DtldCustLedgEntry.SetRange("Entry Type", DtldCustLedgEntry."Entry Type"::Application);
        DtldCustLedgEntry.SetFilter("Posting Date", DateFilter);
        if DtldCustLedgEntry.Find('-') then
            repeat
                CustLedgEntry.Positive := false;
                GetCustApplicationEntry(DtldCustLedgEntry, ApplDtldCustLedgEntry, false, CustLedgEntry, OtherCurrApplAmount);
            until DtldCustLedgEntry.Next() = 0;
    end;

    local procedure GetVendPay(var Rec: Record "Vendor Ledger Entry"; var DocumentAmount: Decimal; var RemainingAmount: Decimal; var OtherCurrApplAmount: Decimal)
    var
        ApplDetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        OtherCurrApplAmount := 0;
        GetVendAmounts(Rec, DocumentAmount, RemainingAmount);
        if CurrencyCode = '' then
            exit;
        DetailedVendLedgEntry.Reset();
        DetailedVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type", "Posting Date");
        DetailedVendLedgEntry.SetRange("Vendor Ledger Entry No.", Rec."Entry No.");
        DetailedVendLedgEntry.SetRange("Entry Type", DetailedVendLedgEntry."Entry Type"::Application);
        DetailedVendLedgEntry.SetFilter("Posting Date", DateFilter);
        if DetailedVendLedgEntry.FindSet() then
            repeat
                GetVendApplicationEntry(DetailedVendLedgEntry, ApplDetailedVendLedgEntry, false, VendLedgEntry, OtherCurrApplAmount);
            until DetailedVendLedgEntry.Next() = 0;
    end;

    local procedure GetCustAmounts(var CustLedgEntry: Record "Cust. Ledger Entry"; var Amount1: Decimal; var RemainingAmount1: Decimal)
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

    local procedure GetVendAmounts(var VendLedgEntry: Record "Vendor Ledger Entry"; var Amount1: Decimal; var RemainingAmount1: Decimal)
    var
        IsInvoice: Boolean;
    begin
        IsInvoice := IsVendorInvoice(VendLedgEntry);
        if CurrencyCode = '' then begin
            VendLedgEntry.CalcFields("Amount (LCY)", "Remaining Amt. (LCY)", "Original Amt. (LCY)");
            if IsInvoice then
                Amount1 := VendLedgEntry."Original Amt. (LCY)"
            else
                Amount1 := VendLedgEntry."Amount (LCY)";
            RemainingAmount1 := VendLedgEntry."Remaining Amt. (LCY)";
        end else begin
            VendLedgEntry.CalcFields(Amount, "Remaining Amount", "Original Amount");
            if IsInvoice then
                Amount1 := VendLedgEntry."Original Amount"
            else
                Amount1 := VendLedgEntry.Amount;
            RemainingAmount1 := VendLedgEntry."Remaining Amount";
        end;
    end;

    local procedure CustPayProcessing(var PayEntry: Record "Detailed Cust. Ledg. Entry"; var InvEntry: Record "Cust. Ledger Entry")
    begin
        if PayEntry."Entry Type" <> PayEntry."Entry Type"::Application then begin
            if CurrencyCode <> '' then
                CurrReport.Skip();
            PostingDate := PayEntry."Posting Date";
            EntryDescription := Format(InvEntry."Document Type") + ' ' + InvEntry."Document No." + ' ' + InvEntry.Description;
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
            GetCustApplicationEntry(PayEntry, DtldCustLedgEntry, true, CustLedgEntry, OtherCurrApplAmount);
            CustLedgEntry.SetFilter("Date Filter", '..%1', CustLedgEntry."Posting Date");
            PostingDate := CustLedgEntry."Posting Date";
            if CustLedgEntry."Currency Code" = '' then
                CustLedgEntry."Currency Code" := GLSetup."LCY Code";
            EntryDescription :=
              Format(CustLedgEntry."Document Type") + ' ' +
              CustLedgEntry."Document No." + ' ' + CustLedgEntry.Description;
            if CurrencyCode = '' then begin
                CustLedgEntry.CalcFields("Amount (LCY)");
                DocumentAmount := -CustLedgEntry."Amount (LCY)";
                TempAmount := PayEntry."Amount (LCY)";
            end else begin
                CustLedgEntry.CalcFields(Amount);
                DocumentAmount := -CustLedgEntry.Amount;
                TempAmount := ExchAmount(PayEntry.Amount, PayEntry."Currency Code", CurrencyCode, PayEntry."Posting Date");
            end;
            if CustLedgEntry."Document Type" in [CustLedgEntry."Document Type"::Invoice,
                                                 CustLedgEntry."Document Type"::"Credit Memo"]
            then begin
                DocumentAmount := -DocumentAmount;
                CreditAppliedAmt := 0;
                DebitAppliedAmt := TempAmount;
            end else begin
                CreditAppliedAmt := -TempAmount;
                DebitAppliedAmt := 0;
            end;
        end;
        TotalInvAmount += TempAmount;
    end;

    local procedure VendPayProcessing(var PayEntry: Record "Detailed Vendor Ledg. Entry"; var InvEntry: Record "Vendor Ledger Entry"; CurrentPeriod: Boolean)
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
            VendLedgEntry.Get(AppldVendLedgEntryTmp."Vendor Ledger Entry No.");
            VendLedgEntry.SetFilter("Date Filter", '..%1', VendLedgEntry."Posting Date");
            PostingDate := VendLedgEntry."Posting Date";
            if VendLedgEntry."Currency Code" = '' then
                VendLedgEntry."Currency Code" := GLSetup."LCY Code";
            if AppldVendLedgEntryTmp."Prepmt. Diff." then
                EntryDescription :=
                  StrSubstNo(
                    '%1 %2 %3 %4', Text007, Format(InvEntry."Document Type"),
                    InvEntry."Document No.", InvEntry.Description)
            else
                EntryDescription :=
                  StrSubstNo(
                    '%1 %2 %3', Format(VendLedgEntry."Document Type"), VendLedgEntry."Document No.",
                    VendLedgEntry.Description);
            if CurrencyCode = '' then begin
                VendLedgEntry.CalcFields("Amount (LCY)", "Remaining Amt. (LCY)");
                DocumentAmount := VendLedgEntry."Amount (LCY)";
                TempAmount := -AppldVendLedgEntryTmp."Amount (LCY)";
            end else begin
                VendLedgEntry.CalcFields(Amount, "Remaining Amount");
                DocumentAmount := VendLedgEntry.Amount;
                TempAmount := ExchAmount(
                    -AppldVendLedgEntryTmp.Amount,
                    AppldVendLedgEntryTmp."Currency Code",
                    CurrencyCode,
                    VendLedgEntry."Posting Date");
            end;
            if AppldVendLedgEntryTmp."Prepmt. Diff." then begin
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

    local procedure SetOppositeData(Index: Integer; Data1: Text[30]; Data2: Decimal; Data3: Decimal)
    begin
        if PrintCustomerData then begin
            if Index = 1 then
                OppositeText := Format(Data1, 0, '<Precision,2:2><Standard Format,0>');
            OppositeData[Index, 1] := Data2;
            OppositeData[Index, 2] := Data3;
        end;
    end;

    local procedure HasAnyOps(CustNo: Code[20]): Boolean
    begin
        DtldCustLedgEntry.Reset();
        DtldCustLedgEntry.SetCurrentKey("Customer No.", "Posting Date");
        DtldCustLedgEntry.SetRange("Customer No.", CustNo);
        DtldCustLedgEntry.SetRange("Posting Date", MinDate, MaxDate);
        exit(DtldCustLedgEntry.Count <> 0);
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

    local procedure IsVendorPayment(PmtVendLedgEntry: Record "Vendor Ledger Entry"): Boolean
    begin
        PmtVendLedgEntry.CalcFields("Original Amount");
        exit(
          ((PmtVendLedgEntry."Document Type" = PmtVendLedgEntry."Document Type"::Payment) or
           (PmtVendLedgEntry."Document Type" = PmtVendLedgEntry."Document Type"::Refund)) or
          ((PmtVendLedgEntry."Document Type" = PmtVendLedgEntry."Document Type"::" ") and (PmtVendLedgEntry."Original Amount" > 0)));
    end;

    local procedure IsReturnPrepayment(VendorLedgerEntry: Record "Vendor Ledger Entry"): Boolean
    begin
        exit((VendorLedgerEntry."Document Type" = VendorLedgerEntry."Document Type"::" ") and VendorLedgerEntry.Prepayment);
    end;

    local procedure IsReturnPpmtForCurrentPeriod(VendorLedgerEntry: Record "Vendor Ledger Entry"): Boolean
    var
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        if (VendorLedgerEntry."Document Type" = VendorLedgerEntry."Document Type"::" ") and VendorLedgerEntry.Prepayment then begin
            VendorLedgerEntry2.SetRange("Document Type", VendorLedgerEntry."Document Type"::Payment);
            VendorLedgerEntry2.SetRange(Prepayment, true);
            VendorLedgerEntry2.SetRange("Document No.", VendorLedgerEntry."Document No.");
            VendorLedgerEntry2.SetRange("Posting Date", MinDate, MaxDate);
            if VendorLedgerEntry2.Count > 0 then
                exit(true);
        end;
        exit(false);
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
        ApplDetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        ApplDetailedVendLedgEntry.SetRange("Vendor Ledger Entry No.", EntryNo);
        ApplDetailedVendLedgEntry.SetRange("Entry Type", ApplDetailedVendLedgEntry."Entry Type"::Application);
        ApplDetailedVendLedgEntry.SetRange("Posting Date", MinDate, MaxDate);
        ApplDetailedVendLedgEntry.SetRange(Unapplied, false);
        exit(not ApplDetailedVendLedgEntry.IsEmpty);
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
        SrcDetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        AppliedDetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        AppliedVendLedgEntry: Record "Vendor Ledger Entry";
    begin
        AppldVendLedgEntryTmp.Reset();
        AppldVendLedgEntryTmp.DeleteAll();

        SrcDetailedVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.");
        SrcDetailedVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntryNo);
        SrcDetailedVendLedgEntry.SetRange(Unapplied, false);
        SrcDetailedVendLedgEntry.SetFilter("Posting Date", '..%1', MaxDate);
        SrcDetailedVendLedgEntry.SetRange("Entry Type", SrcDetailedVendLedgEntry."Entry Type"::Application);
        if SrcDetailedVendLedgEntry.FindSet() then
            repeat
                if SrcDetailedVendLedgEntry."Vendor Ledger Entry No." =
                   SrcDetailedVendLedgEntry."Applied Vend. Ledger Entry No."
                then begin
                    AppliedDetailedVendLedgEntry.Init();
                    AppliedDetailedVendLedgEntry.SetCurrentKey("Applied Vend. Ledger Entry No.", "Entry Type");
                    AppliedDetailedVendLedgEntry.SetRange(
                      "Applied Vend. Ledger Entry No.", SrcDetailedVendLedgEntry."Applied Vend. Ledger Entry No.");
                    AppliedDetailedVendLedgEntry.SetRange("Entry Type", AppliedDetailedVendLedgEntry."Entry Type"::Application);
                    AppliedDetailedVendLedgEntry.SetRange(Unapplied, false);
                    if AppliedDetailedVendLedgEntry.FindSet() then
                        repeat
                            if AppliedDetailedVendLedgEntry."Vendor Ledger Entry No." <>
                               AppliedDetailedVendLedgEntry."Applied Vend. Ledger Entry No."
                            then
                                if AppliedVendLedgEntry.Get(AppliedDetailedVendLedgEntry."Vendor Ledger Entry No.") then begin
                                    AppldVendLedgEntryTmp := AppliedDetailedVendLedgEntry;
                                    AppldVendLedgEntryTmp.Amount := -AppldVendLedgEntryTmp.Amount;
                                    AppldVendLedgEntryTmp."Amount (LCY)" := -AppldVendLedgEntryTmp."Amount (LCY)";
                                    if not AppliedDetailedVendLedgEntry."Prepmt. Diff." then
                                        if AppldVendLedgEntryTmp.Insert() then;
                                end;
                        until AppliedDetailedVendLedgEntry.Next() = 0;
                end else
                    if AppliedVendLedgEntry.Get(SrcDetailedVendLedgEntry."Applied Vend. Ledger Entry No.") then begin
                        AppldVendLedgEntryTmp := SrcDetailedVendLedgEntry;
                        AppldVendLedgEntryTmp."Vendor Ledger Entry No." := AppldVendLedgEntryTmp."Applied Vend. Ledger Entry No.";
                        if AppldVendLedgEntryTmp.Insert() then;
                    end;
            until SrcDetailedVendLedgEntry.Next() = 0;
    end;

    local procedure GetInitialDebitCreditBalance(var InitialDebitAmount: Decimal; var InitialCreditAmount: Decimal)
    begin
        DetailedVendLedgEntry.Reset();
        DetailedVendLedgEntry.SetCurrentKey(
          "Vendor No.", "Initial Document Type", "Document Type",
          "Entry Type", "Posting Date", "Currency Code");
        DetailedVendLedgEntry.SetRange("Vendor No.", Vendor."No.");
        DetailedVendLedgEntry.SetFilter("Agreement No.", Vendor.GetFilter("Agreement Filter"));
        DetailedVendLedgEntry.SetFilter("Posting Date", '..%1', FirstDate);
        DetailedVendLedgEntry.SetRange("Prepmt. Diff. in TA", false);
        if CurrencyCode <> '' then
            DetailedVendLedgEntry.SetRange("Currency Code", CurrencyCode);

        GetInitialCreditBalance(DetailedVendLedgEntry, InitialCreditAmount);
        GetInitialDebitBalance(DetailedVendLedgEntry, InitialDebitAmount);
        UpdInitialDebitCreditBalance(DetailedVendLedgEntry, InitialDebitAmount, InitialCreditAmount);
    end;

    local procedure GetInitialCreditBalance(var DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; var InitialCreditAmount: Decimal): Decimal
    begin
        DetailedVendLedgEntry.SetFilter(
            "Initial Document Type", '%1|%2',
            DetailedVendLedgEntry."Initial Document Type"::Invoice,
            DetailedVendLedgEntry."Initial Document Type"::"Credit Memo");
        if CurrencyCode <> '' then begin
            DetailedVendLedgEntry.CalcSums(Amount);
            InitialCreditAmount := -DetailedVendLedgEntry.Amount;
        end else begin
            DetailedVendLedgEntry.CalcSums("Amount (LCY)");
            InitialCreditAmount := -DetailedVendLedgEntry."Amount (LCY)";
        end;
    end;

    local procedure GetInitialDebitBalance(var DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; var InitialDebitAmount: Decimal)
    begin
        DetailedVendLedgEntry.SetFilter(
            "Initial Document Type", '%1|%2',
            DetailedVendLedgEntry."Initial Document Type"::Payment,
            DetailedVendLedgEntry."Initial Document Type"::Refund);
        if CurrencyCode <> '' then begin
            DetailedVendLedgEntry.CalcSums(Amount);
            InitialDebitAmount := DetailedVendLedgEntry.Amount;
        end else begin
            DetailedVendLedgEntry.CalcSums("Amount (LCY)");
            InitialDebitAmount := DetailedVendLedgEntry."Amount (LCY)";
        end;
    end;

    local procedure UpdInitialDebitCreditBalance(var DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; var InitialDebitAmount: Decimal; var InitialCreditAmount: Decimal)
    begin
        DetailedVendLedgEntry.SetRange("Initial Document Type", DetailedVendLedgEntry."Initial Document Type"::" ");
        if DetailedVendLedgEntry.FindSet() then
            repeat
                if CurrencyCode <> '' then
                    HandleInitialDebitCreditBal(DetailedVendLedgEntry.Amount, InitialDebitAmount, InitialCreditAmount)
                else
                    HandleInitialDebitCreditBal(DetailedVendLedgEntry."Amount (LCY)", InitialDebitAmount, InitialCreditAmount);
            until DetailedVendLedgEntry.Next() = 0;
    end;

    local procedure HandleInitialDebitCreditBal(Amount: Decimal; var InitialDebitAmount: Decimal; var InitialCreditAmount: Decimal)
    var
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        if Amount < 0 then begin
            if DetailedVendLedgEntry."Entry Type" <> DetailedVendLedgEntry."Entry Type"::Application then
                InitialCreditAmount += -Amount
            else
                InitialDebitAmount += Amount;
        end else
            if DetailedVendLedgEntry."Entry Type" <> DetailedVendLedgEntry."Entry Type"::Application then
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
        DebitTotalBalance := 0;
        CreditTotalBalance := 0;
        InitialDebitBalance := 0;
        InitialCreditBalance := 0;
        InitialDebitBalance2 := 0;
        InitialCreditBalance2 := 0;
        DebitTurnover := 0;
        CreditTurnover := 0;
        ProcessedPayEntries.Reset();
        ProcessedPayEntries.DeleteAll();
        ProcessedVendInvoices.Reset();
        ProcessedVendInvoices.DeleteAll();
    end;

    local procedure WasProcessedInPrevPeriod(var PayEntry: Record "Detailed Vendor Ledg. Entry"; CurrentPeriod: Boolean): Boolean
    begin
        if PayEntry."Entry No." = 0 then
            exit(false);
        if CurrentPeriod then begin
            ProcessedPayEntries.SetRange("Entry No.", PayEntry."Entry No.");
            exit(not ProcessedPayEntries.IsEmpty);
        end;
        ProcessedPayEntries."Entry No." := PayEntry."Entry No.";
        if ProcessedPayEntries.Insert() then;
        exit(false);
    end;

    local procedure IsInvProcessedInPrevPeriod(EntryNo: Integer; CurrentPeriod: Boolean): Boolean
    begin
        if CurrentPeriod then begin
            ProcessedVendInvoices.SetRange("Entry No.", EntryNo);
            exit(not ProcessedVendInvoices.IsEmpty);
        end;
        ProcessedVendInvoices."Entry No." := EntryNo;
        if ProcessedVendInvoices.Insert() then;
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewStartDate: Date; NewEndDate: Date; NewFileName: Text; NewPrintCustomerData: Boolean)
    begin
        FileName := NewFileName;
        MinDate := NewStartDate;
        MaxDate := NewEndDate;
        PrintCustomerData := NewPrintCustomerData;
    end;

    local procedure FormatAmount(Amount: Decimal): Text
    begin
        if Amount <> 0 then
            exit(Format(Amount, 0, '<Precision,2:2><Standard Format,0>'));
        exit('');
    end;
}

