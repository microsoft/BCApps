#pragma warning disable AA0247
report 12455 "Create VAT Purchase Ledger"
{
    Caption = 'Create VAT Purchase Ledger';
    ProcessingOnly = true;
    Permissions = tabledata "VAT Ledger Line" = i,
                  tabledata "VAT Ledger Connection" = i;

    dataset
    {
        dataitem(VATLedgerName; "VAT Ledger")
        {
            dataitem(PurchVATEntry; "VAT Entry")
            {
                DataItemTableView = sorting("Posting Date", Type, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Tax Invoice Amount Type", Prepayment, Positive) where(Type = const(Purchase), "Tax Invoice Amount Type" = const(VAT), "Additional VAT Ledger Sheet" = const(false), "Include In Other VAT Ledger" = const(false), "VAT Allocation Type" = const(VAT), "VAT Reinstatement" = const(false), "VAT Agent" = const(false));

                trigger OnAfterGetRecord()
                var
                    VATEntryNo: Integer;
                    VATEntry1: Record "VAT Entry";
                    Vend: Record Vendor;
                    VendLedgEntry: Record "Vendor Ledger Entry";
                    DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
                    FA: Record "Fixed Asset";
                    TransactionNo: Integer;
                begin
                    if VATLedgMgt.SkipVATEntry(
                         PurchVATEntry, VATLedgerName."Start Date", VATLedgerName."End Date",
                         CheckReversed, CheckUnapplied, CheckBaseAndAmount, CheckPrepmt, CheckAmtDiffVAT,
                         CheckUnrealizedVAT, CheckPrepmtDiff, true, ShowAmtDiff, ShowUnrealVAT, ShowRealVAT)
                    then
                        CurrReport.Skip();

                    if Prepayment then
                        CurrReport.Skip();

                    if (Vend.Get("Bill-to/Pay-to No.")) and
                       (Vend."Vendor Type" = Vend."Vendor Type"::"Resp. Employee") and
                       (Amount = 0)
                    then
                        CurrReport.Skip();

                    if (Vend.Get("Bill-to/Pay-to No.")) and (Vend."VAT Agent") then
                        CurrReport.Skip();

                    DocumentDate := 0D;
                    DocPostingDate := 0D;
                    RealVATEntryDate := 0D;
                    Partial := false;
                    InvoiceRecDate := 0D;
                    PaymentDate := 0D;

                    FutureExp := "VAT Settlement Type" = "VAT Settlement Type"::"Future Expenses";

                    VATEntryNo := "Entry No.";
                    if "Unrealized VAT Entry No." <> 0 then
                        VATEntryNo := "Unrealized VAT Entry No.";
                    GetLineProperties(PurchVATEntry, VATEntryNo);

                    VendLedgEntry.Reset();
                    VendLedgEntry.SetCurrentKey("Transaction No.");
                    VendLedgEntry.SetRange("Transaction No.", TransNo);

                    if UseExternal and VendLedgEntry.FindFirst() then
                        if VendLedgEntry."Vendor VAT Invoice No." = '' then
                            CurrReport.Skip();

                    if VendLedgEntry.FindFirst() then begin
                        if UseExternal and not CorrDocMgt.IsCorrVATEntry(PurchVATEntry) then begin
                            if VendLedgEntry."Vendor VAT Invoice No." <> '' then
                                DocumentNo := VendLedgEntry."Vendor VAT Invoice No.";
                            if VendLedgEntry."Vendor VAT Invoice Date" <> 0D then
                                DocumentDate := VendLedgEntry."Vendor VAT Invoice Date";
                        end;
                        if DocumentDate = 0D then
                            if VendLedgEntry."Document Date" <> 0D then
                                DocumentDate := VendLedgEntry."Document Date"
                            else
                                DocumentDate := VendLedgEntry."Posting Date";
                        InvoiceRecDate := VendLedgEntry."Vendor VAT Invoice Rcvd Date";

                        DocPostingDate := VendLedgEntry."Posting Date";
                    end;

                    if "Object Type" = "Object Type"::"Fixed Asset" then
                        if FA.Get("Object No.") then
                            if FA."Initial Release Date" <> 0D then
                                DocPostingDate := FA."Initial Release Date";

                    GetRealVATDate(PurchVATEntry, "Transaction No.", RealVATEntryDate);

                    if RealVATEntryDate = 0D then
                        if VATEntry1.Get("Unrealized VAT Entry No.") then begin
                            VendLedgEntry.Reset();
                            VendLedgEntry.SetCurrentKey("Transaction No.");
                            VendLedgEntry.SetRange("Transaction No.", VATEntry1."Transaction No.");
                            if VendLedgEntry.Find('-') then begin
                                DtldVendLedgEntry.Reset();
                                DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type");
                                DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntry."Entry No.");
                                DtldVendLedgEntry.SetFilter("Entry Type", '%1', DtldVendLedgEntry."Entry Type"::Application);
                                if DtldVendLedgEntry.Find('-') then
                                    repeat
                                        GetRealVATDate(PurchVATEntry, DtldVendLedgEntry."Transaction No.", RealVATEntryDate);
                                    until DtldVendLedgEntry.Next() = 0;
                            end;
                        end;

                    if RealVATEntryDate = 0D then
                        RealVATEntryDate := PurchVATEntry."Posting Date";

                    GetPurchPaymentDateDocNo("Transaction No.", PaymentDate, PaymentDocNo);

                    if PaymentDate = 0D then begin
                        if VATEntry1.Get("Unrealized VAT Entry No.") then
                            TransactionNo := VATEntry1."Transaction No."
                        else
                            TransactionNo := "Transaction No.";
                        VendLedgEntry.Reset();
                        VendLedgEntry.SetCurrentKey("Transaction No.");
                        VendLedgEntry.SetRange("Transaction No.", TransactionNo);
                        if VendLedgEntry.Find('-') then begin
                            DtldVendLedgEntry.Reset();
                            DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type");
                            DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntry."Entry No.");
                            DtldVendLedgEntry.SetFilter("Entry Type", '%1', DtldVendLedgEntry."Entry Type"::Application);
                            if DtldVendLedgEntry.Find('-') then
                                repeat
                                    if not DtldVendLedgEntry.Unapplied then
                                        GetPurchPaymentDateDocNo(DtldVendLedgEntry."Transaction No.", PaymentDate, PaymentDocNo);
                                until DtldVendLedgEntry.Next() = 0;
                        end;
                    end;

                    MakePurchLedger(PurchVATEntry, VATLedgerLineBuffer);
                end;

                trigger OnPreDataItem()
                begin
                    VATLedgMgt.SetVATPeriodFilter(PurchVATEntry, VATLedgerName."Start Date", VATLedgerName."End Date");
                    VATLedgMgt.SetCustVendFilter(PurchVATEntry, VendFilter);
                    VATLedgMgt.SetVATGroupsFilter(PurchVATEntry, VATProdGroupFilter, VATBusGroupFilter);

                    VATLedgerLineBuffer.Reset();
                    VATLedgerLineBuffer.SetCurrentKey("Document No.");
                    LineNo := 0;

                    CheckReversed := true;
                    CheckUnapplied := true;
                    CheckBaseAndAmount := true;
                    CheckPrepmt := true;
                    CheckAmtDiffVAT := true;
                    CheckUnrealizedVAT := true;
                    CheckPrepmtDiff := true;
                end;
            }
            dataitem(PurchPrepmtVATEntry; "VAT Entry")
            {
                DataItemTableView = sorting("Posting Date", Type, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Tax Invoice Amount Type", Prepayment, Positive) where(Type = const(Purchase), "Tax Invoice Amount Type" = const(VAT), "Additional VAT Ledger Sheet" = const(false), "Include In Other VAT Ledger" = const(false), Prepayment = const(true), "VAT Allocation Type" = const(VAT), "VAT Reinstatement" = const(false), "VAT Agent" = const(false));

                trigger OnAfterGetRecord()
                var
                    VendLedgEntry: Record "Vendor Ledger Entry";
                begin
                    if VATLedgMgt.SkipVATEntry(
                         PurchPrepmtVATEntry, VATLedgerName."Start Date", VATLedgerName."End Date",
                         CheckReversed, CheckUnapplied, CheckBaseAndAmount, CheckPrepmt, CheckAmtDiffVAT,
                         CheckUnrealizedVAT, CheckPrepmtDiff, true, ShowAmtDiff, ShowUnrealVAT, ShowRealVAT)
                    then
                        CurrReport.Skip();

                    if "Unrealized VAT Entry No." <> 0 then
                        CurrReport.Skip();

                    DocumentDate := 0D;
                    Partial := false;
                    InvoiceRecDate := 0D;
                    GetLineProperties(PurchPrepmtVATEntry, "Entry No.");

                    if VendLedgEntry.Get("CV Ledg. Entry No.") then begin
                        if not CorrDocMgt.IsCorrVATEntry(PurchPrepmtVATEntry) then begin
                            if VendLedgEntry."Vendor VAT Invoice No." <> '' then
                                DocumentNo := VendLedgEntry."Vendor VAT Invoice No.";
                            if VendLedgEntry."Vendor VAT Invoice Date" <> 0D then
                                DocumentDate := VendLedgEntry."Vendor VAT Invoice Date";
                        end;
                        InvoiceRecDate := VendLedgEntry."Vendor VAT Invoice Rcvd Date";
                    end;
                    DocPostingDate := 0D;
                    PaymentDate := VendLedgEntry."Posting Date";

                    MakePurchLedger(PurchPrepmtVATEntry, VATLedgerLineBuffer);
                end;

                trigger OnPreDataItem()
                begin
                    VATLedgMgt.SetVATPeriodFilter(PurchPrepmtVATEntry, VATLedgerName."Start Date", VATLedgerName."End Date");
                    VATLedgMgt.SetCustVendFilter(PurchPrepmtVATEntry, VendFilter);
                    VATLedgMgt.SetVATGroupsFilter(PurchPrepmtVATEntry, VATProdGroupFilter, VATBusGroupFilter);

                    CheckReversed := true;
                    CheckUnapplied := true;
                    CheckBaseAndAmount := false;
                    CheckPrepmt := false;
                    CheckAmtDiffVAT := false;
                    CheckUnrealizedVAT := false;
                    CheckPrepmtDiff := false;
                end;
            }
            dataitem(CustPrepmtVATEntry; "VAT Entry")
            {
                DataItemTableView = sorting("Posting Date", Type, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Tax Invoice Amount Type", Prepayment, Positive) where(Type = const(Sale), "Tax Invoice Amount Type" = const(VAT), Prepayment = const(true), "Additional VAT Ledger Sheet" = const(false), "Include In Other VAT Ledger" = const(false), "VAT Allocation Type" = const(VAT));

                trigger OnAfterGetRecord()
                var
                    VATEntryNo: Integer;
                begin
                    if VATLedgMgt.SkipVATEntry(
                         CustPrepmtVATEntry, VATLedgerName."Start Date", VATLedgerName."End Date",
                         CheckReversed, CheckUnapplied, CheckBaseAndAmount, CheckPrepmt, CheckAmtDiffVAT,
                         CheckUnrealizedVAT, CheckPrepmtDiff, true, ShowAmtDiff, ShowUnrealVAT, ShowRealVAT)
                    then
                        CurrReport.Skip();

                    if (Base = 0) and (Amount = 0) then
                        CurrReport.Skip();

                    DocumentDate := 0D;
                    DocPostingDate := 0D;
                    RealVATEntryDate := 0D;
                    Partial := false;
                    InvoiceRecDate := 0D;
                    VATEntryNo := CustPrepmtVATEntry."Unrealized VAT Entry No.";
                    GetLineProperties(CustPrepmtVATEntry, VATEntryNo);
                    RealVATEntryDate := "Posting Date";
                    DocPostingDate := 0D;
                    Base := -Base;
                    Amount := -Amount;
                    MakePurchLedger(CustPrepmtVATEntry, VATLedgerLineBuffer);
                end;

                trigger OnPreDataItem()
                var
                begin
                    if not ShowCustPrepmt then
                        CurrReport.Break();

                    VATLedgMgt.SetVATPeriodFilter(CustPrepmtVATEntry, VATLedgerName."Start Date", VATLedgerName."End Date");
                    VATLedgMgt.SetCustVendFilter(CustPrepmtVATEntry, CustFilter);
                    VATLedgMgt.SetVATGroupsFilter(CustPrepmtVATEntry, VATProdGroupFilter, VATBusGroupFilter);

                    CheckReversed := true;
                    CheckUnapplied := true;
                    CheckBaseAndAmount := true;
                    CheckPrepmt := false;
                    CheckAmtDiffVAT := true;
                    CheckUnrealizedVAT := false;
                    CheckPrepmtDiff := false;
                end;
            }
            dataitem(SalesReturnVATEntry; "VAT Entry")
            {
                DataItemTableView = sorting("Posting Date", Type, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Tax Invoice Amount Type", Prepayment, Positive) where(Type = const(Sale), "Tax Invoice Amount Type" = const(VAT), "Document Type" = const("Credit Memo"), "Include In Other VAT Ledger" = const(true), "VAT Allocation Type" = const(VAT));

                trigger OnAfterGetRecord()
                var
                begin
                    if VATLedgMgt.SkipVATEntry(
                         SalesReturnVATEntry, VATLedgerName."Start Date", VATLedgerName."End Date",
                         CheckReversed, CheckUnapplied, CheckBaseAndAmount, CheckPrepmt, CheckAmtDiffVAT,
                         CheckUnrealizedVAT, CheckPrepmtDiff, true, ShowAmtDiff, ShowUnrealVAT, ShowRealVAT)
                    then
                        CurrReport.Skip();

                    DocumentDate := 0D;
                    DocPostingDate := 0D;
                    RealVATEntryDate := 0D;
                    Partial := false;
                    InvoiceRecDate := 0D;
                    GetLineProperties(SalesReturnVATEntry, "Entry No.");
                    RealVATEntryDate := "Posting Date";

                    MakePurchLedger(SalesReturnVATEntry, VATLedgerLineBuffer);
                end;

                trigger OnPostDataItem()
                begin
                    //SavePurchLedger();
                end;

                trigger OnPreDataItem()
                begin
                    VATLedgMgt.SetVATPeriodFilter(SalesReturnVATEntry, VATLedgerName."Start Date", VATLedgerName."End Date");
                    VATLedgMgt.SetCustVendFilter(SalesReturnVATEntry, CustFilter);
                    VATLedgMgt.SetVATGroupsFilter(SalesReturnVATEntry, VATProdGroupFilter, VATBusGroupFilter);

                    CheckReversed := true;
                    CheckUnapplied := true;
                    CheckBaseAndAmount := true;
                    CheckPrepmt := false;
                    CheckAmtDiffVAT := true;
                    CheckUnrealizedVAT := false;
                    CheckPrepmtDiff := false;
                end;
            }
            dataitem(VATAgentEntry; "VAT Entry")
            {
                DataItemTableView = sorting("Posting Date", Type, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Tax Invoice Amount Type", Prepayment, Positive) where(Type = const(Purchase), "Tax Invoice Amount Type" = const(VAT), "Additional VAT Ledger Sheet" = const(false), "Include In Other VAT Ledger" = const(false), "VAT Allocation Type" = const(VAT), "VAT Reinstatement" = const(false), "VAT Agent" = const(true));

                trigger OnAfterGetRecord()
                var
                    VendLedgEntry: Record "Vendor Ledger Entry";
                    UnrealizedVATEntry: Record "VAT Entry";
                begin
                    if VATLedgMgt.SkipVATEntry(
                         VATAgentEntry, VATLedgerName."Start Date", VATLedgerName."End Date",
                         CheckReversed, CheckUnapplied, CheckBaseAndAmount, CheckPrepmt, CheckAmtDiffVAT,
                         CheckUnrealizedVAT, CheckPrepmtDiff, true, ShowAmtDiff, ShowUnrealVAT, ShowRealVAT)
                    then
                        CurrReport.Skip();

                    if (Base = 0) and (Amount = 0) then
                        CurrReport.Skip();

                    DocumentDate := 0D;
                    Partial := false;
                    InvoiceRecDate := 0D;
                    GetLineProperties(VATAgentEntry, "Entry No.");

                    if VendLedgEntry.Get("CV Ledg. Entry No.") then begin
                        if not CorrDocMgt.IsCorrVATEntry(VATAgentEntry) then begin
                            if VendLedgEntry."Vendor VAT Invoice No." <> '' then
                                DocumentNo := VendLedgEntry."Vendor VAT Invoice No.";
                            if VendLedgEntry."Vendor VAT Invoice Date" <> 0D then
                                DocumentDate := VendLedgEntry."Vendor VAT Invoice Date";
                        end;
                        InvoiceRecDate := VendLedgEntry."Vendor VAT Invoice Rcvd Date";
                    end;

                    if "Unrealized VAT Entry No." <> 0 then begin
                        UnrealizedVATEntry.Get("Unrealized VAT Entry No.");
                        "External Document No." := UnrealizedVATEntry."External Document No.";
                        DocumentNo := UnrealizedVATEntry."Document No.";
                    end;

                    DocPostingDate := 0D;
                    PaymentDate := VendLedgEntry."Posting Date";

                    MakePurchLedger(VATAgentEntry, VATLedgerLineBuffer);

                    if Prepayment then
                        AdjustVATAgentPrepayment(VATAgentEntry, VATLedgerLineBuffer);
                end;

                trigger OnPostDataItem()
                begin
                    SavePurchLedger();
                end;

                trigger OnPreDataItem()
                begin
                    VATLedgMgt.SetVATPeriodFilter(VATAgentEntry, VATLedgerName."Start Date", VATLedgerName."End Date");
                    VATLedgMgt.SetCustVendFilter(VATAgentEntry, VendFilter);
                    VATLedgMgt.SetVATGroupsFilter(VATAgentEntry, VATProdGroupFilter, VATBusGroupFilter);

                    CheckReversed := true;
                    CheckUnapplied := true;
                    CheckBaseAndAmount := false;
                    CheckPrepmt := false;
                    CheckAmtDiffVAT := false;
                    CheckUnrealizedVAT := false;
                    CheckPrepmtDiff := false;
                end;
            }
            dataitem(LedgerPart; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(0 .. 1));
                dataitem(PurchLedger; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then begin
                            if not VATLedgerLineBuffer.Find('-') then
                                CurrReport.Break();
                        end else
                            if VATLedgerLineBuffer.Next(1) = 0 then
                                CurrReport.Break();

                        VATLedgerLineBuffer."Sales Tax Amount" := VATLedgerLineBuffer."Sales Tax Amount" + VATLedgerLineBuffer."Full Sales Tax Amount";
                        VATLedgerLineBuffer."Full VAT Amount" := 0;
                        VATLedgerLineBuffer."Full Sales Tax Amount" := 0;
                        VATLedgerLineBuffer.Base20 := Round(VATLedgerLineBuffer.Base20, 0.01);
                        VATLedgerLineBuffer.Amount20 := Round(VATLedgerLineBuffer.Amount20, 0.01);
                        VATLedgerLineBuffer.Base18 := Round(VATLedgerLineBuffer.Base18, 0.01);
                        VATLedgerLineBuffer.Amount18 := Round(VATLedgerLineBuffer.Amount18, 0.01);
                        VATLedgerLineBuffer.Base10 := Round(VATLedgerLineBuffer.Base10, 0.01);
                        VATLedgerLineBuffer.Amount10 := Round(VATLedgerLineBuffer.Amount10, 0.01);
                        VATLedgerLineBuffer."Full VAT Amount" := Round(VATLedgerLineBuffer."Full VAT Amount", 0.01);
                        VATLedgerLineBuffer."Sales Tax Amount" := Round(VATLedgerLineBuffer."Sales Tax Amount", 0.01);
                        VATLedgerLineBuffer."Full Sales Tax Amount" := Round(VATLedgerLineBuffer."Full Sales Tax Amount", 0.01);
                        VATLedgerLineBuffer.Base0 := Round(VATLedgerLineBuffer.Base0, 0.01);
                        VATLedgerLineBuffer."Base VAT Exempt" := Round(VATLedgerLineBuffer."Base VAT Exempt", 0.01);

                        if VATLedgerLineBuffer."Amount Including VAT" = 0 then
                            VATLedgerLineBuffer."Amount Including VAT" :=
                                    VATLedgerLineBuffer.Base20 + VATLedgerLineBuffer.Amount20 +
                                    VATLedgerLineBuffer.Base18 + VATLedgerLineBuffer.Amount18 +
                                    VATLedgerLineBuffer.Base10 + VATLedgerLineBuffer.Amount10 +
                                    VATLedgerLineBuffer."Sales Tax Amount" + VATLedgerLineBuffer."Full Sales Tax Amount" + VATLedgerLineBuffer.Base0 +
                                    VATLedgerLineBuffer."Base VAT Exempt";

                        if VATLedgerLineBuffer."Amount Including VAT" = 0 then
                            CurrReport.Skip();

                        VATLedgMgt.InsertVATLedgerLineCDNoList(VATLedgerLineBuffer);

                        LineLabel := 0;
                        if VATLedgerLineBuffer.Prepayment then
                            LineLabel := LineLabel::"@ PrePay";
                        if VATLedgerLineBuffer."Amt. Diff. VAT" then
                            LineLabel := LineLabel::"$ Amt.Diff";
                        PartialText := '';
                        if VATLedgerLineBuffer.Partial then
                            PartialText := LowerCase(VATLedgerLineBuffer.FieldCaption(Partial));
                    end;

                    trigger OnPreDataItem()
                    begin
                        if LedgerPart.Number <> 0 then
                            CurrReport.Break();

                        LineNo := 0;
                        VATLedgerLineBuffer.Reset();

                        case Sorting of
                            Sorting::"Document Date":
                                VATLedgerLineBuffer.SetCurrentKey("Document Date");
                            Sorting::"Document No.":
                                VATLedgerLineBuffer.SetCurrentKey("Document No.");
                            Sorting::"Last Date":
                                VATLedgerLineBuffer.SetCurrentKey("Last Date");
                            else
                                VATLedgerLineBuffer.SetCurrentKey("Real. VAT Entry Date");
                        end;

                        if OtherPercents <> OtherPercents::"Not Select" then
                            VATLedgerLineBuffer.SetRange("VAT Percent", 0);
                    end;
                }
                dataitem(OtherLedger; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(0 ..));

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 0 then begin
                            VATLedgerLineBuffer := TotalBuffer;
                            exit;
                        end;
                        if Number = 1 then begin
                            if not VATLedgerLineBuffer.Find('-') then
                                CurrReport.Break();
                        end else
                            if VATLedgerLineBuffer.Next(1) = 0 then
                                CurrReport.Break();

                        VATLedgerLineBuffer."Sales Tax Amount" := VATLedgerLineBuffer."Sales Tax Amount" + VATLedgerLineBuffer."Full Sales Tax Amount";
                        VATLedgerLineBuffer."Full VAT Amount" := 0;
                        VATLedgerLineBuffer."Full Sales Tax Amount" := 0;
                        VATLedgerLineBuffer.Base20 := Round(VATLedgerLineBuffer.Base20, 0.01);
                        VATLedgerLineBuffer.Amount20 := Round(VATLedgerLineBuffer.Amount20, 0.01);
                        VATLedgerLineBuffer.Base18 := Round(VATLedgerLineBuffer.Base18, 0.01);
                        VATLedgerLineBuffer.Amount18 := Round(VATLedgerLineBuffer.Amount18, 0.01);
                        VATLedgerLineBuffer.Base10 := Round(VATLedgerLineBuffer.Base10, 0.01);
                        VATLedgerLineBuffer.Amount10 := Round(VATLedgerLineBuffer.Amount10, 0.01);
                        VATLedgerLineBuffer."Full VAT Amount" := Round(VATLedgerLineBuffer."Full VAT Amount", 0.01);
                        VATLedgerLineBuffer."Sales Tax Amount" := Round(VATLedgerLineBuffer."Sales Tax Amount", 0.01);
                        VATLedgerLineBuffer."Full Sales Tax Amount" := Round(VATLedgerLineBuffer."Full Sales Tax Amount", 0.01);
                        VATLedgerLineBuffer.Base0 := Round(VATLedgerLineBuffer.Base0, 0.01);
                        VATLedgerLineBuffer."Base VAT Exempt" := Round(VATLedgerLineBuffer."Base VAT Exempt", 0.01);

                        if VATLedgerLineBuffer."Amount Including VAT" = 0 then
                            VATLedgerLineBuffer."Amount Including VAT" :=
                              VATLedgerLineBuffer.Base20 + VATLedgerLineBuffer.Amount20 +
                              VATLedgerLineBuffer.Base18 + VATLedgerLineBuffer.Amount18 +
                              VATLedgerLineBuffer.Base10 + VATLedgerLineBuffer.Amount10 +
                              VATLedgerLineBuffer."Sales Tax Amount" + VATLedgerLineBuffer."Full Sales Tax Amount" + VATLedgerLineBuffer.Base0 +
                              VATLedgerLineBuffer."Base VAT Exempt";
                    end;

                    trigger OnPreDataItem()
                    begin
                        if LedgerPart.Number <> 1 then
                            CurrReport.Break();

                        if OtherPercents = OtherPercents::"Not Select" then
                            CurrReport.Break();

                        VATLedgerLineBuffer.Reset();

                        case Sorting of
                            Sorting::"Document Date":
                                VATLedgerLineBuffer.SetCurrentKey("Document Date");
                            Sorting::"Document No.":
                                VATLedgerLineBuffer.SetCurrentKey("Document No.");
                            Sorting::"Last Date":
                                VATLedgerLineBuffer.SetCurrentKey("Last Date");
                            else
                                VATLedgerLineBuffer.SetCurrentKey("Real. VAT Entry Date");
                        end;

                        VATLedgerLineBuffer.SetFilter("VAT Percent", '<>%1', 0);
                    end;
                }
            }

            trigger OnAfterGetRecord()
            begin
                if ClearOperation then
                    VATLedgMgt.DeleteVATLedgerLines(VATLedgerName);

                "C/V Filter" := VendFilter;
                "VAT Product Group Filter" := VATProdGroupFilter;
                "VAT Business Group Filter" := VATBusGroupFilter;
                "Purchase Sorting" := Sorting;
                "Use External Doc. No." := UseExternal;
                "Clear Lines" := ClearOperation;
                "Start Numbering" := StartPageNo;
                "Other Rates" := OtherPercents;
                "Show Realized VAT" := ShowRealVAT;
                "Show Unrealized VAT" := ShowUnrealVAT;
                "Show Amount Differences" := ShowAmtDiff;
                "Show Customer Prepayments" := ShowCustPrepmt;
                Modify();
            end;

            trigger OnPreDataItem()
            begin
                LineNo := 0;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(VendFilter; VendFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor Filter';
                        TableRelation = Vendor;
                    }
                    field(VATProdGroupFilter; VATProdGroupFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Product Group Filter';
                        TableRelation = "VAT Product Posting Group";
                        ToolTip = 'Specifies a filter for data to be included. VAT product posting groups define the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    }
                    field(VATBusGroupFilter; VATBusGroupFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Business Group Filter';
                        TableRelation = "VAT Business Posting Group";
                        ToolTip = 'Specifies a filter for data to be included. VAT business posting groups define the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    }
                    field(Sorting; Sorting)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sorting';
                        OptionCaption = ' ,Document Date,Document No.,Last Date';
                        ToolTip = 'Specifies how items are sorted on the resulting report.';
                    }
                    field(UseExternal; UseExternal)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use External Doc. No.';
                    }
                    field(ClearOperation; ClearOperation)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Clear Lines by Code';
                        ToolTip = 'Specifies if you want to delete the stored lines that are created before the data in the VAT ledger is refreshed.';
                    }
                    field(StartPageNo; StartPageNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Start Numbering';
                    }
                    field(OtherPercents; OtherPercents)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Other Rates';
                        OptionCaption = 'Do Not Show,Summarized,Detailed';
                        ToolTip = 'Specifies the other rates that are associated with the VAT ledger. Other rates include Do Not Show, Summarized, and Detailed. VAT ledgers are used to store details about VAT in transactions that involve goods and services in Russia or goods imported into Russia.';
                    }
                    field(ShowRealVAT; ShowRealVAT)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Realized VAT';
                        ToolTip = 'Specifies if you want to include realized VAT entries.';
                    }
                    field(ShowUnrealVAT; ShowUnrealVAT)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Unrealized VAT';
                        ToolTip = 'Specifies if you want to include unrealized VAT entries.';
                    }
                    field(ShowAmtDiff; ShowAmtDiff)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amount Differences';
                        ToolTip = 'Specifies if you want to include exchange rate differences.';
                    }
                    field(ShowCustPrepmt; ShowCustPrepmt)
                    {
                        ApplicationArea = Prepayments;
                        Caption = 'Show Customer Prepayments';
                        ToolTip = 'Specifies if you want to include customer prepayment information.';

                        trigger OnValidate()
                        begin
                            ShowCustPrepmtOnPush();
                        end;
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
        UseExternal := true;
    end;

    trigger OnPreReport()
    begin
        if StartPageNo > 0 then
            StartPageNo := StartPageNo - 1
        else
            StartPageNo := 0;

        CompanyInfo.Get();
        VATLedgMgt.GetCustFilterByVendFilter(CustFilter, VendFilter);
    end;

    var
        CompanyInfo: Record "Company Information";
        VATLedgerConnection: Record "VAT Ledger Connection";
        VATLedgerLineBuffer: Record "VAT Ledger Line" temporary;
        VATLedgerConnBuffer: Record "VAT Ledger Connection" temporary;
        AmountBuffer: Record "VAT Ledger Line" temporary;
        TotalBuffer: Record "VAT Ledger Line" temporary;
        ChangeNoBuf: Record "VAT Entry" temporary;
        VATLedgMgt: Codeunit "VAT Ledger Management";
        CorrDocMgt: Codeunit "Corrective Document Mgt.";
        Sorting: Option " ","Document Date","Document No.","Last Date";
        LineNo: Integer;
        VendFilter: Code[250];
        CustFilter: Code[250];
        VATProdGroupFilter: Code[250];
        VATBusGroupFilter: Code[250];
        DocumentNo: Code[30];
        DocumentDate: Date;
        DocPostingDate: Date;
        OtherPercents: Option "Not Select",Total,Detail;
        UseExternal: Boolean;
        OrigDocNo: Code[20];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text12400: Label 'cannot be %1 if Tax Invoice Amount Type is %2';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text12401: Label 'Creation is not possible!';
#pragma warning restore AA0074
        ClearOperation: Boolean;
        RealVATEntryDate: Date;
        Partial: Boolean;
        PartialText: Text[30];
        InvoiceRecDate: Date;
        IsPrepayment: Boolean;
        TransNo: Integer;
        FutureExp: Boolean;
        LineLabel: Option " ","@ PrePay","$ Amt.Diff";
        ShowCustPrepmt: Boolean;
        ShowAmtDiff: Boolean;
        ShowUnrealVAT: Boolean;
        ShowRealVAT: Boolean;
        StartPageNo: Integer;
        VendNo: Code[20];
        PaymentDate: Date;
        PaymentDocNo: Code[20];
        CheckReversed: Boolean;
        CheckUnapplied: Boolean;
        CheckBaseAndAmount: Boolean;
        CheckPrepmt: Boolean;
        CheckAmtDiffVAT: Boolean;
        CheckUnrealizedVAT: Boolean;
        CheckPrepmtDiff: Boolean;
        CorrectionNo: Code[20];
        CorrectionDate: Date;
        RevisionNo: Code[20];
        RevisionDate: Date;
        RevisionOfCorrectionNo: Code[20];
        RevisionOfCorrectionDate: Date;
        PrintRevision: Boolean;

    [Scope('OnPrem')]
    procedure Check(VATEntry: Record "VAT Entry"): Boolean
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxDetail: Record "Tax Detail";
    begin
        Clear(AmountBuffer);

        VATEntry."Tax Invoice Amount Type" := VATEntry."Tax Invoice Amount Type"::VAT;

        case VATEntry."VAT Calculation Type" of
            VATEntry."VAT Calculation Type"::"Full VAT",
            VATEntry."VAT Calculation Type"::"Normal VAT":
                begin
                    VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");
                    if VATPostingSetup."Not Include into VAT Ledger" in
                       [VATPostingSetup."Not Include into VAT Ledger"::Purchases,
                        VATPostingSetup."Not Include into VAT Ledger"::"Purchases & Sales"]
                    then
                        exit(false);
                    VATEntry."Tax Invoice Amount Type" := VATPostingSetup."Tax Invoice Amount Type";
                end;
            VATEntry."VAT Calculation Type"::"Sales Tax":
                begin
                    TaxJurisdiction.Get(VATEntry."Tax Jurisdiction Code");
                    if TaxJurisdiction."Not Include into Ledger" in
                       [TaxJurisdiction."Not Include into Ledger"::Purchase,
                        TaxJurisdiction."Not Include into Ledger"::"Purchase & Sales"]
                    then
                        exit(false);
                    VATEntry."Tax Invoice Amount Type" := TaxJurisdiction."Sales Tax Amount Type";
                    TaxDetail.SetRange("Tax Jurisdiction Code", VATEntry."Tax Jurisdiction Code");
                    TaxDetail.SetRange("Tax Group Code", VATEntry."Tax Group Used");
                    TaxDetail.SetRange("Tax Type", VATEntry."Tax Type");
                    TaxDetail.SetRange("Effective Date", 0D, VATEntry."Posting Date");
                    TaxDetail.Find('+');
                end;
        end;

        case VATEntry."Tax Invoice Amount Type" of

            VATEntry."Tax Invoice Amount Type"::Excise:
                case VATEntry."VAT Calculation Type" of
                    VATEntry."VAT Calculation Type"::"Full VAT",
                  VATEntry."VAT Calculation Type"::"Sales Tax":
                        AmountBuffer."Excise Amount" := VATEntry.Amount;
                    else
                        VATEntry.FieldError("VAT Calculation Type",
                          StrSubstNo(Text12400,
                            VATEntry."VAT Calculation Type", VATEntry."Tax Invoice Amount Type"));
                end;

            VATEntry."Tax Invoice Amount Type"::VAT:
                case VATEntry."VAT Calculation Type" of
                    VATEntry."VAT Calculation Type"::"Full VAT":
                        begin
                            if VATEntry."VAT Correction" then
                                AmountBuffer."VAT Correction" := true
                            else
                                AmountBuffer."Full VAT Amount" := VATEntry.Amount;
                            CheckVAT(VATEntry, VATPostingSetup."VAT %", VATPostingSetup."VAT Exempt");
                        end;

                    VATEntry."VAT Calculation Type"::"Normal VAT":
                        CheckVAT(VATEntry, VATPostingSetup."VAT %", VATPostingSetup."VAT Exempt");
                    VATEntry."VAT Calculation Type"::"Sales Tax":
                        CheckVAT(VATEntry, TaxDetail."Tax Below Maximum", VATPostingSetup."VAT Exempt");
                    else
                        VATEntry.FieldError("VAT Calculation Type",
                          StrSubstNo(Text12400,
                            VATEntry."VAT Calculation Type", VATEntry."Tax Invoice Amount Type"));
                end;

            VATEntry."Tax Invoice Amount Type"::"Sales Tax":
                case VATEntry."VAT Calculation Type" of
                    VATEntry."VAT Calculation Type"::"Full VAT":
                        if VATEntry."VAT Correction" = true then begin
                            AmountBuffer."VAT Correction" := true;
                            AmountBuffer."Sales Tax Amount" := VATEntry.Amount;
                            AmountBuffer."Sales Tax Base" := VATEntry.Base;
                        end else
                            AmountBuffer."Full Sales Tax Amount" := VATEntry.Amount;
                    VATEntry."VAT Calculation Type"::"Sales Tax":
                        begin
                            AmountBuffer."Sales Tax Amount" := VATEntry.Amount;
                            AmountBuffer."Sales Tax Base" := VATEntry.Base;
                        end;
                    else
                        VATEntry.FieldError("VAT Calculation Type",
                          StrSubstNo(Text12400,
                            VATEntry."VAT Calculation Type", VATEntry."Tax Invoice Amount Type"));
                end;
            else
                Error(Text12401);
        end;
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure CheckVAT(VATEntry: Record "VAT Entry"; VATPercent: Decimal; VATExempt: Boolean)
    begin
        if VATPercent = 0 then
            if not VATExempt then
                AmountBuffer.Base0 := VATEntry.Base + VATEntry."Unrealized Base"
            else
                AmountBuffer."Base VAT Exempt" := VATEntry.Base + VATEntry."Unrealized Base"
        else
            case VATPercent of
                9.09, 10:
                    begin
                        AmountBuffer.Base10 := VATEntry.Base + VATEntry."Unrealized Base";
                        AmountBuffer.Amount10 := VATEntry.Amount + VATEntry."Unrealized Amount";
                    end;
                VATLedgMgt.GetVATPctRate2018():
                    begin
                        AmountBuffer.Base18 := VATEntry.Base + VATEntry."Unrealized Base";
                        AmountBuffer.Amount18 := VATEntry.Amount + VATEntry."Unrealized Amount";
                    end;
                16.67, VATLedgMgt.GetVATPctRate2019():
                    begin
                        AmountBuffer.Base20 := VATEntry.Base + VATEntry."Unrealized Base";
                        AmountBuffer.Amount20 := VATEntry.Amount + VATEntry."Unrealized Amount";
                    end;
                else begin
                    AmountBuffer.Base20 := VATEntry.Base + VATEntry."Unrealized Base";
                    AmountBuffer.Amount20 := VATEntry.Amount + VATEntry."Unrealized Amount";
                    AmountBuffer."VAT Percent" := VATPercent;
                end;
            end;
    end;

    [Scope('OnPrem')]
    procedure MakePurchLedger(VATEntry: Record "VAT Entry"; var TempVATLedgerLineBuffer: Record "VAT Ledger Line" temporary)
    var
        PrepmtDiffVATEntry: Record "VAT Entry";
    begin
        if not Check(VATEntry) then
            exit;

        MakePurchLedgerSetFilters(VATEntry, TempVATLedgerLineBuffer);
        if not TempVATLedgerLineBuffer.FindFirst() then begin
            MakePurchLedgerMapValues(VATEntry, TempVATLedgerLineBuffer);
            MakePurchLedgMapTypeSpecificValues(VATEntry, TempVATLedgerLineBuffer);
            MakePurchLedgMapCorrectionValues(VATEntry, TempVATLedgerLineBuffer);
            TempVATLedgerLineBuffer.Insert();
            InsertLedgerConnBuffer(TempVATLedgerLineBuffer, VATEntry."Entry No.");
        end;

        TempVATLedgerLineBuffer.Base10 := TempVATLedgerLineBuffer.Base10 + AmountBuffer.Base10;
        TempVATLedgerLineBuffer.Amount10 := TempVATLedgerLineBuffer.Amount10 + AmountBuffer.Amount10;
        TempVATLedgerLineBuffer.Base18 := TempVATLedgerLineBuffer.Base18 + AmountBuffer.Base18;
        TempVATLedgerLineBuffer.Amount18 := TempVATLedgerLineBuffer.Amount18 + AmountBuffer.Amount18;
        TempVATLedgerLineBuffer.Base20 := TempVATLedgerLineBuffer.Base20 + AmountBuffer.Base20;
        TempVATLedgerLineBuffer.Amount20 := TempVATLedgerLineBuffer.Amount20 + AmountBuffer.Amount20;
        TempVATLedgerLineBuffer."Full VAT Amount" := TempVATLedgerLineBuffer."Full VAT Amount" + AmountBuffer."Full VAT Amount";
        TempVATLedgerLineBuffer."Sales Tax Amount" := TempVATLedgerLineBuffer."Sales Tax Amount" + AmountBuffer."Sales Tax Amount";
        TempVATLedgerLineBuffer."Sales Tax Base" := TempVATLedgerLineBuffer."Sales Tax Base" + AmountBuffer."Sales Tax Base";
        TempVATLedgerLineBuffer."Full Sales Tax Amount" := TempVATLedgerLineBuffer."Full Sales Tax Amount" + AmountBuffer."Full Sales Tax Amount";
        TempVATLedgerLineBuffer.Base0 := TempVATLedgerLineBuffer.Base0 + AmountBuffer.Base0;
        TempVATLedgerLineBuffer."Base VAT Exempt" := TempVATLedgerLineBuffer."Base VAT Exempt" + AmountBuffer."Base VAT Exempt";
        TempVATLedgerLineBuffer."Excise Amount" := TempVATLedgerLineBuffer."Excise Amount" + AmountBuffer."Excise Amount";
        if DocumentDate <> 0D then
            TempVATLedgerLineBuffer."Document Date" := DocumentDate;
        if DocPostingDate <> 0D then
            TempVATLedgerLineBuffer."Unreal. VAT Entry Date" := DocPostingDate;
        TempVATLedgerLineBuffer.Modify();

        PrepmtDiffVATEntry.Reset();
        PrepmtDiffVATEntry.SetRange("Initial VAT Transaction No.", VATEntry."Transaction No.");
        PrepmtDiffVATEntry.SetRange("Document Line No.", VATEntry."Document Line No.");
        PrepmtDiffVATEntry.SetRange("Prepmt. Diff.", true);
        PrepmtDiffVATEntry.SetRange("Additional VAT Ledger Sheet", false);
        if PrepmtDiffVATEntry.FindSet() then
            repeat
                if (PrepmtDiffVATEntry.Base <> 0) or (PrepmtDiffVATEntry.Amount <> 0) then
                    if Check(PrepmtDiffVATEntry) then begin
                        TempVATLedgerLineBuffer.Base10 := TempVATLedgerLineBuffer.Base10 + AmountBuffer.Base10;
                        TempVATLedgerLineBuffer.Amount10 := TempVATLedgerLineBuffer.Amount10 + AmountBuffer.Amount10;
                        TempVATLedgerLineBuffer.Base18 := TempVATLedgerLineBuffer.Base18 + AmountBuffer.Base18;
                        TempVATLedgerLineBuffer.Amount18 := TempVATLedgerLineBuffer.Amount18 + AmountBuffer.Amount18;
                        TempVATLedgerLineBuffer.Base20 := TempVATLedgerLineBuffer.Base20 + AmountBuffer.Base20;
                        TempVATLedgerLineBuffer.Amount20 := TempVATLedgerLineBuffer.Amount20 + AmountBuffer.Amount20;
                        TempVATLedgerLineBuffer."Full VAT Amount" := TempVATLedgerLineBuffer."Full VAT Amount" + AmountBuffer."Full VAT Amount";
                        TempVATLedgerLineBuffer."Sales Tax Amount" := TempVATLedgerLineBuffer."Sales Tax Amount" + AmountBuffer."Sales Tax Amount";
                        TempVATLedgerLineBuffer."Sales Tax Base" := TempVATLedgerLineBuffer."Sales Tax Base" + AmountBuffer."Sales Tax Base";
                        TempVATLedgerLineBuffer."Full Sales Tax Amount" := TempVATLedgerLineBuffer."Full Sales Tax Amount" + AmountBuffer."Full Sales Tax Amount";
                        TempVATLedgerLineBuffer.Base0 := TempVATLedgerLineBuffer.Base0 + AmountBuffer.Base0;
                        TempVATLedgerLineBuffer."Base VAT Exempt" := TempVATLedgerLineBuffer."Base VAT Exempt" + AmountBuffer."Base VAT Exempt";
                        TempVATLedgerLineBuffer."Excise Amount" := TempVATLedgerLineBuffer."Excise Amount" + AmountBuffer."Excise Amount";
                        TempVATLedgerLineBuffer.Modify();
                    end;
            until PrepmtDiffVATEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure MakePurchLedgerSetFilters(VATEntry: Record "VAT Entry"; var TempVATLedgerLineBuffer: Record "VAT Ledger Line" temporary)
    begin
        if (OtherPercents = OtherPercents::Total) and (AmountBuffer."VAT Percent" <> 0) then begin
            TempVATLedgerLineBuffer.SetRange("Document No.");
            TempVATLedgerLineBuffer.SetRange("Real. VAT Entry Date");
            TempVATLedgerLineBuffer.SetRange("Transaction/Entry No.");
            TempVATLedgerLineBuffer.SetRange("VAT Product Posting Group");
            TempVATLedgerLineBuffer.SetRange("Document Type");
            TempVATLedgerLineBuffer.SetRange("C/V No.");
        end else begin
            TempVATLedgerLineBuffer.SetRange("Document No.", DocumentNo);
            TempVATLedgerLineBuffer.SetRange("VAT Product Posting Group");
            TempVATLedgerLineBuffer.SetRange("Document Type", VATEntry."Document Type");
            TempVATLedgerLineBuffer.SetRange("C/V No.", VendNo);
        end;
        TempVATLedgerLineBuffer.SetRange("VAT Percent", AmountBuffer."VAT Percent");

        if CorrDocMgt.IsCorrVATEntry(VATEntry) then
            case VATEntry."Corrective Doc. Type" of
                VATEntry."Corrective Doc. Type"::Correction:
                    begin
                        TempVATLedgerLineBuffer.SetRange("Correction No.", CorrectionNo);
                        TempVATLedgerLineBuffer.SetRange("Revision No.");
                        TempVATLedgerLineBuffer.SetRange("Revision of Corr. No.");
                    end;
                VATEntry."Corrective Doc. Type"::Revision:
                    begin
                        if RevisionNo <> '' then begin
                            TempVATLedgerLineBuffer.SetRange("Revision No.", RevisionNo);
                            TempVATLedgerLineBuffer.SetRange("Correction No.");
                            TempVATLedgerLineBuffer.SetRange("Revision of Corr. No.");
                        end;
                        if RevisionOfCorrectionNo <> '' then begin
                            TempVATLedgerLineBuffer.SetRange("Revision of Corr. No.", RevisionOfCorrectionNo);
                            TempVATLedgerLineBuffer.SetRange("Correction No.");
                            TempVATLedgerLineBuffer.SetRange("Revision No.");
                        end;
                    end;
            end
        else begin
            TempVATLedgerLineBuffer.SetRange("Correction No.", '');
            TempVATLedgerLineBuffer.SetRange("Revision No.", '');
            TempVATLedgerLineBuffer.SetRange("Revision of Corr. No.", '');
        end;
    end;

    [Scope('OnPrem')]
    procedure MakePurchLedgerMapValues(VATEntry: Record "VAT Entry"; var TempVATLedgerLineBuffer: Record "VAT Ledger Line" temporary)
    var
        CurrencyCode: Code[10];
        VATEntryType: Code[15];
        CVLedgEntryAmount: Decimal;
        ExternalDocNo: Code[35];
    begin
        if not TempVATLedgerLineBuffer.FindFirst() then begin
            TempVATLedgerLineBuffer.Init();
            LineNo := LineNo + 1;
            TempVATLedgerLineBuffer.Type := VATLedgerName.Type;
            TempVATLedgerLineBuffer.Code := VATLedgerName.Code;
            TempVATLedgerLineBuffer."Line No." := LineNo;
            if (OtherPercents = OtherPercents::Total) and
               (AmountBuffer."VAT Percent" <> 0)
            then begin
                TempVATLedgerLineBuffer."Document No." := '';
                TempVATLedgerLineBuffer."Real. VAT Entry Date" := VATLedgerName."End Date";
                TempVATLedgerLineBuffer."Transaction/Entry No." := 0;
                TempVATLedgerLineBuffer."VAT Product Posting Group" := '';
                TempVATLedgerLineBuffer."VAT Business Posting Group" := '';
                TempVATLedgerLineBuffer."Document Type" := "Gen. Journal Document Type"::" ";
            end else begin
                TempVATLedgerLineBuffer."Document Type" := VATEntry."Document Type";
                TempVATLedgerLineBuffer."Document Date" := DocumentDate;
                TempVATLedgerLineBuffer."Document No." := DocumentNo;
                TempVATLedgerLineBuffer."Origin. Document No." := OrigDocNo;
                TempVATLedgerLineBuffer."Real. VAT Entry Date" := RealVATEntryDate;
                TempVATLedgerLineBuffer."Transaction/Entry No." := VATEntry."Transaction No.";
                TempVATLedgerLineBuffer."VAT Product Posting Group" := VATEntry."VAT Prod. Posting Group";
                TempVATLedgerLineBuffer."VAT Business Posting Group" := VATEntry."VAT Bus. Posting Group";
                TempVATLedgerLineBuffer."Unreal. VAT Entry Date" := DocPostingDate;
                TempVATLedgerLineBuffer.Prepayment := VATEntry.Prepayment;
            end;
            TempVATLedgerLineBuffer."C/V No." := VATEntry."Bill-to/Pay-to No.";
            TempVATLedgerLineBuffer."VAT Percent" := AmountBuffer."VAT Percent";

            if VATEntry.Type = VATEntry.Type::Sale then begin
                GetSalesVATEntryValues(VATEntry, CVLedgEntryAmount, CurrencyCode, VATEntryType, ExternalDocNo);
                TempVATLedgerLineBuffer."External Document No." := ExternalDocNo;
            end else begin
                GetPurchaseVATEntryValues(VATEntry, CVLedgEntryAmount, CurrencyCode, VATEntryType);
                TempVATLedgerLineBuffer."External Document No." := VATEntry."External Document No.";
            end;

            TempVATLedgerLineBuffer.Amount := CVLedgEntryAmount;
            TempVATLedgerLineBuffer."Currency Code" := CurrencyCode;
            TempVATLedgerLineBuffer."VAT Entry Type" := VATEntryType;
            TempVATLedgerLineBuffer."VAT Correction" := VATEntry."VAT Correction";
            TempVATLedgerLineBuffer.Partial := Partial;
            TempVATLedgerLineBuffer."Last Date" := 0D;
            if (DocumentDate <> 0D) and (DocumentDate > TempVATLedgerLineBuffer."Last Date") then
                TempVATLedgerLineBuffer."Last Date" := DocumentDate;
            if (RealVATEntryDate <> 0D) and (RealVATEntryDate > TempVATLedgerLineBuffer."Last Date") then
                TempVATLedgerLineBuffer."Last Date" := RealVATEntryDate;
            if (DocPostingDate <> 0D) and (DocPostingDate > TempVATLedgerLineBuffer."Last Date") then
                TempVATLedgerLineBuffer."Last Date" := DocPostingDate;
            if (InvoiceRecDate <> 0D) and (InvoiceRecDate > TempVATLedgerLineBuffer."Last Date") then
                TempVATLedgerLineBuffer."Last Date" := InvoiceRecDate;

            TempVATLedgerLineBuffer."Additional Sheet" := VATEntry."Additional VAT Ledger Sheet";
            if VATEntry."Additional VAT Ledger Sheet" then
                TempVATLedgerLineBuffer."Corr. VAT Entry Posting Date" := VATEntry."Posting Date";
            TempVATLedgerLineBuffer."Payment Date" := PaymentDate;
            TempVATLedgerLineBuffer."Payment Doc. No." := PaymentDocNo;
        end;
    end;

    [Scope('OnPrem')]
    procedure MakePurchLedgMapTypeSpecificValues(VATEntry: Record "VAT Entry"; var TempVATLedgerLineBuffer: Record "VAT Ledger Line" temporary)
    var
        Vend: Record Vendor;
        Cust: Record Customer;
        LocalReportManagement: Codeunit "Local Report Management";
    begin
        case VATEntry.Type of
            VATEntry.Type::Purchase:
                begin
                    TempVATLedgerLineBuffer."C/V Type" := TempVATLedgerLineBuffer."C/V Type"::Vendor;
                    if Vend.Get(VATLedgerLineBuffer."C/V No.") then begin
                        TempVATLedgerLineBuffer."C/V Name" :=
                          CopyStr(LocalReportManagement.GetVendorName(Vend."No."), 1, MaxStrLen(TempVATLedgerLineBuffer."C/V Name"));
                        if Vend."VAT Agent" and (Vend."VAT Agent Type" = Vend."VAT Agent Type"::"Non-resident") then begin
                            TempVATLedgerLineBuffer."C/V VAT Reg. No." := '-';
                            TempVATLedgerLineBuffer."Reg. Reason Code" := '-';
                        end else begin
                            TempVATLedgerLineBuffer."C/V VAT Reg. No." := Vend."VAT Registration No.";
                            TempVATLedgerLineBuffer."Reg. Reason Code" := Vend."KPP Code";
                        end;
                    end else
                        Vend.Init();
                end;
            VATEntry.Type::Sale:
                begin
                    TempVATLedgerLineBuffer."C/V Type" := TempVATLedgerLineBuffer."C/V Type"::Customer;
                    if VATEntry.Prepayment then begin
                        TempVATLedgerLineBuffer."C/V Name" :=
                          CopyStr(LocalReportManagement.GetCompanyName(), 1, MaxStrLen(TempVATLedgerLineBuffer."C/V Name"));
                        TempVATLedgerLineBuffer."C/V VAT Reg. No." := CompanyInfo."VAT Registration No.";
                        TempVATLedgerLineBuffer."Reg. Reason Code" := CompanyInfo."KPP Code";
                    end else
                        if Cust.Get(VATLedgerLineBuffer."C/V No.") then begin
                            TempVATLedgerLineBuffer."C/V Name" :=
                              CopyStr(LocalReportManagement.GetCustName(Cust."No."), 1, MaxStrLen(TempVATLedgerLineBuffer."C/V Name"));
                            TempVATLedgerLineBuffer."C/V VAT Reg. No." := Cust."VAT Registration No.";
                            TempVATLedgerLineBuffer."Reg. Reason Code" := Cust."KPP Code";
                        end;
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure MakePurchLedgMapCorrectionValues(VATEntry: Record "VAT Entry"; var TempVATLedgerLineBuffer: Record "VAT Ledger Line" temporary)
    begin
        if CorrDocMgt.IsCorrVATEntry(VATEntry) then begin
            TempVATLedgerLineBuffer."Document Date" := DocumentDate;
            TempVATLedgerLineBuffer."Correction No." := CorrectionNo;
            TempVATLedgerLineBuffer."Correction Date" := CorrectionDate;
            TempVATLedgerLineBuffer."Revision No." := RevisionNo;
            TempVATLedgerLineBuffer."Revision Date" := RevisionDate;
            TempVATLedgerLineBuffer."Revision of Corr. No." := RevisionOfCorrectionNo;
            TempVATLedgerLineBuffer."Revision of Corr. Date" := RevisionOfCorrectionDate;
            TempVATLedgerLineBuffer."Print Revision" := PrintRevision;
        end;
    end;

    [Scope('OnPrem')]
    procedure SavePurchLedger()
    var
        StartNo: Integer;
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        VATLedgerLineBuffer.Reset();
        if VATLedgerLineBuffer.Find('-') then
            StartNo := VATLedgerLineBuffer."Line No.";
        case Sorting of
            Sorting::"Document Date":
                VATLedgerLineBuffer.SetCurrentKey("Document Date");
            Sorting::"Document No.":
                VATLedgerLineBuffer.SetCurrentKey("Document No.");
            Sorting::"Last Date":
                VATLedgerLineBuffer.SetCurrentKey("Last Date");
            else
                VATLedgerLineBuffer.SetCurrentKey("Real. VAT Entry Date");
        end;

        if VATLedgerLineBuffer.Find('-') then
            repeat
                if VATLedgerLineBuffer."Amount Including VAT" = 0 then
                    VATLedgerLineBuffer."Amount Including VAT" :=
                      Round(VATLedgerLineBuffer.Base20 + VATLedgerLineBuffer.Amount20 +
                            VATLedgerLineBuffer.Base18 + VATLedgerLineBuffer.Amount18 +
                            VATLedgerLineBuffer.Base10 + VATLedgerLineBuffer.Amount10 +
                            VATLedgerLineBuffer."Sales Tax Amount" + VATLedgerLineBuffer."Full Sales Tax Amount" + VATLedgerLineBuffer.Base0 +
                            VATLedgerLineBuffer."Base VAT Exempt",
                            0.01);

                if VATLedgerLineBuffer."Amount Including VAT" <> 0 then begin
                    VATLedgerLine := VATLedgerLineBuffer;
                    ChangeNoBuf.Init();
                    ChangeNoBuf."Entry No." := VATLedgerLineBuffer."Line No.";
                    ChangeNoBuf."Closed by Entry No." := StartNo;
                    ChangeNoBuf.Insert();
                    VATLedgerLine."Line No." := StartNo;
                    VATLedgerLine."Last Date" := 0D;
                    StartNo += 1;
                    VATLedgerLine.Correction := VATLedgerLine.IsCorrection();
                    VATLedgerLine.Insert();
                end else begin
                    VATLedgerConnBuffer.SetRange("Purch. Ledger Code", VATLedgerLineBuffer.Code);
                    VATLedgerConnBuffer.SetRange("Purch. Ledger Line No.", VATLedgerLineBuffer."Line No.");
                    VATLedgerConnBuffer.DeleteAll();
                end;
            until VATLedgerLineBuffer.Next() = 0;

        VATLedgerConnBuffer.Reset();
        if VATLedgerConnBuffer.Find('-') then
            repeat
                VATLedgerConnection := VATLedgerConnBuffer;
                ChangeNoBuf.Get(VATLedgerConnBuffer."Purch. Ledger Line No.");
                VATLedgerConnection."Purch. Ledger Line No." := ChangeNoBuf."Closed by Entry No.";
                VATLedgerConnection.Insert();
            until VATLedgerConnBuffer.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GetRealVATDate(VATEntry: Record "VAT Entry"; TransactionNo: Integer; var RealVATDate: Date)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        TempDate: Date;
    begin
        if VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group") then
            if VATPostingSetup."Manual VAT Settlement" then
                RealVATDate := VATEntry."Posting Date";

        DtldVendLedgEntry.Reset();
        DtldVendLedgEntry.SetCurrentKey("Transaction No.", "Vendor No.", "Entry Type");
        DtldVendLedgEntry.SetRange("Transaction No.", TransactionNo);
        DtldVendLedgEntry.SetRange("Vendor No.", VATEntry."Bill-to/Pay-to No.");
        DtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::Application);
        if DtldVendLedgEntry.Find('-') then
            repeat
                if not (DtldVendLedgEntry."Initial Document Type" in
                    [DtldVendLedgEntry."Initial Document Type"::Invoice,
                     DtldVendLedgEntry."Initial Document Type"::"Credit Memo"]) then begin
                    VendLedgEntry.Get(DtldVendLedgEntry."Vendor Ledger Entry No.");
                    if VendLedgEntry."Document Date" = 0D then
                        TempDate := VendLedgEntry."Posting Date"
                    else
                        TempDate := VendLedgEntry."Document Date";
                    if RealVATDate < TempDate then
                        RealVATDate := TempDate;
                end;
            until DtldVendLedgEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GetLineProperties(VATEntry: Record "VAT Entry"; VATEntryNo: Integer)
    var
        VATEntry1: Record "VAT Entry";
        Date1: Date;
    begin
        if VATEntry1.Get(VATEntryNo) then begin
            OrigDocNo := VATEntry1."Document No.";
            DocumentNo := VATEntry1."Document No.";
            if VATEntry1."Document Date" = 0D then
                DocumentDate := VATEntry1."Posting Date"
            else
                DocumentDate := VATEntry1."Document Date";
            VendNo := VATEntry1."Bill-to/Pay-to No.";
            DocPostingDate := VATEntry1."Posting Date";
            IsPrepayment := VATEntry1.Prepayment;
            TransNo := VATEntry1."Transaction No.";
            if VATEntry."Unrealized VAT Entry No." <> 0 then begin
                if VATEntry.IsUnapplied(Date1) then
                    VATEntry.Reversed := true;
                Partial :=
                  not (VATEntry.Reversed and (Abs(VATEntry.Base) = Abs(VATEntry1."Unrealized Base"))) and
                  not VATEntry1.FullyRealizedOnDate(VATEntry."Posting Date");
            end;
            if IsPrepayment then
                PaymentDate := VATEntry1."Posting Date";

            if CorrDocMgt.IsCorrVATEntry(VATEntry) then
                VATLedgMgt.GetCorrDocProperties(
                  VATEntry, DocumentNo, DocumentDate, CorrectionNo, CorrectionDate,
                  RevisionNo, RevisionDate, RevisionOfCorrectionNo, RevisionOfCorrectionDate, PrintRevision);
        end;
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewUseExternal: Boolean; NewVendFilter: Text[250]; NewShowCustomerPrepayments: Boolean)
    begin
        UseExternal := NewUseExternal;
        VendFilter := NewVendFilter;
        ShowCustPrepmt := NewShowCustomerPrepayments;
        ShowAmtDiff := true;
        ShowUnrealVAT := true;
        ShowRealVAT := true;
        ClearOperation := true;
    end;

    [Scope('OnPrem')]
    procedure ReversedByCorrection(ReversedVATEntry: Record "VAT Entry"): Boolean
    var
        ReversedByVATEntry: Record "VAT Entry";
    begin
        if ReversedVATEntry.Reversed then begin
            if ReversedVATEntry."Additional VAT Ledger Sheet" then
                exit(true);

            if ReversedByVATEntry.Get(ReversedVATEntry."Reversed by Entry No.") then
                exit(ReversedByVATEntry."Corrected Document Date" <> 0D);
        end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure ShowDate(Date: Date): Text[30]
    begin
        if Date = 0D then
            exit('-');
        exit(Format(Date));
    end;

    procedure SetParameters(NewVendFilter: Code[250]; NewVATProdGroupFilter: Code[250]; NewVATBusGroupFilter: Code[250]; NewSorting: Option " ","Document Date","Document No.","Last Date"; NewUseExternal: Boolean; NewClearOperation: Boolean; NewStartPageNo: Integer; NewOtherPercents: Option "Do Not Show",Summarized,Detailed; NewShowRealVAT: Boolean; NewShowUnrealVAT: Boolean; NewShowAmtDiff: Boolean; NewShowCustPrepmt: Boolean)
    begin
        VendFilter := NewVendFilter;
        VATProdGroupFilter := NewVATProdGroupFilter;
        VATBusGroupFilter := NewVATBusGroupFilter;
        Sorting := NewSorting;
        UseExternal := NewUseExternal;
        ClearOperation := NewClearOperation;
        StartPageNo := NewStartPageNo;
        OtherPercents := NewOtherPercents;
        ShowRealVAT := NewShowRealVAT;
        ShowUnrealVAT := NewShowUnrealVAT;
        ShowAmtDiff := NewShowAmtDiff;
        ShowCustPrepmt := NewShowCustPrepmt;
    end;

    local procedure ShowCustPrepmtOnPush()
    begin
        if not ShowCustPrepmt then
            CustFilter := '';
    end;

    local procedure GetSalesVATEntryValues(VATEntry: Record "VAT Entry"; var CVLedgEntryAmount: Decimal; var CurrencyCode: Code[10]; var VATEntryType: Code[15]; var ExternalDocNo: Code[35])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if CustLedgerEntry.Get(VATEntry."CV Ledg. Entry No.") then begin
            CustLedgerEntry.CalcFields(Amount);
            CVLedgEntryAmount := Abs(CustLedgerEntry.Amount);
            CurrencyCode := CustLedgerEntry."Currency Code";
            VATEntryType := CustLedgerEntry."VAT Entry Type";
            if VATEntry.Prepayment and (CustLedgerEntry."Document Type" = CustLedgerEntry."Document Type"::Payment) then
                if CustLedgerEntry."External Document No." <> '' then begin
                    ExternalDocNo := CustLedgerEntry."External Document No.";
                    exit;
                end;
            ExternalDocNo := VATEntry."External Document No.";
        end;
    end;

    local procedure GetPurchaseVATEntryValues(VATEntry: Record "VAT Entry"; var CVLedgEntryAmount: Decimal; var CurrencyCode: Code[10]; var VATEntryType: Code[15])
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if VendLedgerEntry.Get(VATEntry."CV Ledg. Entry No.") then begin
            VendLedgerEntry.CalcFields(Amount);
            CVLedgEntryAmount := Abs(VendLedgerEntry.Amount);
            CurrencyCode := VendLedgerEntry."Currency Code";
            VATEntryType := VendLedgerEntry."VAT Entry Type";
        end;
    end;

    local procedure InsertLedgerConnBuffer(VATLedgerLine: Record "VAT Ledger Line"; VATEntryNo: Integer)
    begin
        VATLedgerConnBuffer.Init();
        VATLedgerConnBuffer."Connection Type" := VATLedgerConnection."Connection Type"::Purchase;
        VATLedgerConnBuffer."Sales Ledger Code" := '';
        VATLedgerConnBuffer."Sales Ledger Line No." := 0;
        VATLedgerConnBuffer."Purch. Ledger Code" := VATLedgerLine.Code;
        VATLedgerConnBuffer."Purch. Ledger Line No." := VATLedgerLine."Line No.";
        VATLedgerConnBuffer."VAT Entry No." := VATEntryNo;
        VATLedgerConnBuffer.Insert();
    end;

    local procedure AdjustVATAgentPrepayment(VATEntry: Record "VAT Entry"; var TempVATLedgerLineBuffer: Record "VAT Ledger Line" temporary)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");
        case VATPostingSetup."VAT %" of
            VATLedgMgt.GetVATPctRate2019():
                begin
                    TempVATLedgerLineBuffer.Base20 += TempVATLedgerLineBuffer.Amount20;
                    TempVATLedgerLineBuffer.Amount += TempVATLedgerLineBuffer.GetVATAgentVATAmountFCY();
                end;
            VATLedgMgt.GetVATPctRate2018():
                begin
                    TempVATLedgerLineBuffer.Base18 += TempVATLedgerLineBuffer.Amount18;
                    TempVATLedgerLineBuffer.Amount += TempVATLedgerLineBuffer.GetVATAgentVATAmountFCY();
                end;
            10:
                begin
                    TempVATLedgerLineBuffer.Base10 += TempVATLedgerLineBuffer.Amount10;
                    TempVATLedgerLineBuffer.Amount += TempVATLedgerLineBuffer.GetVATAgentVATAmountFCY();
                end;
        end;
        TempVATLedgerLineBuffer.Modify();
    end;
}

