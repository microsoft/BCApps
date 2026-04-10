#pragma warning disable AA0247
report 14962 "Create VAT Purch. Led. Ad. Sh."
{
    Caption = 'Create VAT Purch. Led. Ad. Sh.';
    ProcessingOnly = true;
    Permissions = tabledata "VAT Ledger Line" = imd,
                  tabledata "VAT Ledger Connection" = imd;

    dataset
    {
        dataitem(VATLedgerName; "VAT Ledger")
        {
            dataitem(PurchVATEntryAdd; "VAT Entry")
            {
                DataItemTableView = sorting("Posting Date", Type, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Tax Invoice Amount Type", Prepayment, Positive) where(Type = const(Purchase), "Tax Invoice Amount Type" = const(VAT), "Additional VAT Ledger Sheet" = const(true), "VAT Allocation Type" = const(VAT));

                trigger OnAfterGetRecord()
                var
                    VATEntry1: Record "VAT Entry";
                    Vend: Record Vendor;
                    VendLedgEntry: Record "Vendor Ledger Entry";
                    DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
                    FA: Record "Fixed Asset";
                    VATEntryNo: Integer;
                begin
                    if Reversed then
                        if not ReversedByCorrection(PurchVATEntryAdd) then
                            CurrReport.Skip();

                    if Prepayment then begin
                        if ("Unrealized VAT Entry No." <> 0) and not Reversed then
                            CurrReport.Skip();
                    end else
                        if "Unrealized VAT Entry No." = 0 then
                            if (Base = 0) and (Amount = 0) then
                                CurrReport.Skip();
                    if not Prepayment then
                        if "Unrealized VAT Entry No." <> 0 then begin
                            if not ShowUnrealVAT then
                                CurrReport.Skip()
                        end else
                            if not ShowRealVAT then
                                CurrReport.Skip();

                    if not Reversed then
                        if "Posting Date" in [VATLedgerName."Start Date" .. VATLedgerName."End Date"] then
                            CurrReport.Skip();

                    if Vend.Get("Bill-to/Pay-to No.") and
                       (Vend."Vendor Type" = Vend."Vendor Type"::"Resp. Employee") and
                       (Amount = 0)
                    then
                        CurrReport.Skip();

                    DocumentDate := 0D;
                    DocPostingDate := 0D;
                    RealVATEntryDate := 0D;
                    Partial := false;
                    InvoiceRecDate := 0D;

                    VATEntryNo := "Entry No.";
                    if "Unrealized VAT Entry No." <> 0 then
                        VATEntryNo := "Unrealized VAT Entry No.";
                    GetLineProperties(PurchVATEntryAdd, VATEntryNo);

                    VendLedgEntry.Reset();
                    if not VendLedgEntry.Get("CV Ledg. Entry No.") then begin
                        VendLedgEntry.SetCurrentKey("Transaction No.");
                        VendLedgEntry.SetRange("Transaction No.", TransNo);
                    end else
                        VendLedgEntry.SetRange("Entry No.", "CV Ledg. Entry No.");

                    if UseExternal and VendLedgEntry.FindFirst() then
                        if VendLedgEntry."Vendor VAT Invoice No." = '' then
                            CurrReport.Skip();

                    if VendLedgEntry.FindFirst() then begin
                        if UseExternal and not CorrDocMgt.IsCorrVATEntry(PurchVATEntryAdd) then begin
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

                    if Prepayment then begin
                        DocPostingDate := 0D;
                        PaymentDate := VendLedgEntry."Posting Date";
                    end;

                    if "VAT Settlement Type" <> 0 then begin
                        if VATEntry1.Get("Unrealized VAT Entry No.") then begin
                            VendLedgEntry.Reset();
                            VendLedgEntry.SetCurrentKey("Transaction No.");
                            VendLedgEntry.SetRange("Transaction No.", VATEntry1."Transaction No.");
                            if VendLedgEntry.FindFirst() then begin
                                DtldVendLedgEntry.Reset();
                                DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type");
                                DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntry."Entry No.");
                                DtldVendLedgEntry.SetFilter("Entry Type", '%1', DtldVendLedgEntry."Entry Type"::Application);
                                if DtldVendLedgEntry.FindSet() then
                                    repeat
                                        GetRealVATDate(PurchVATEntryAdd, DtldVendLedgEntry."Transaction No.", RealVATEntryDate);
                                    until DtldVendLedgEntry.Next() = 0;
                            end;
                        end;
                    end else
                        GetRealVATDate(PurchVATEntryAdd, "Transaction No.", RealVATEntryDate);
                    if RealVATEntryDate = 0D then
                        RealVATEntryDate := "Posting Date";

                    GetPurchPaymentDateDocNo("Transaction No.", PaymentDate, PaymentDocNo);

                    if PaymentDate = 0D then begin
                        if VATEntry1.Get("Unrealized VAT Entry No.") then
                            VendLedgEntry.Reset();
                        VendLedgEntry.SetCurrentKey("Transaction No.");
                        VendLedgEntry.SetRange("Transaction No.", VATEntry1."Transaction No.");
                        if VendLedgEntry.FindFirst() then begin
                            DtldVendLedgEntry.Reset();
                            DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type");
                            DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntry."Entry No.");
                            DtldVendLedgEntry.SetFilter("Entry Type", '%1', DtldVendLedgEntry."Entry Type"::Application);
                            if DtldVendLedgEntry.FindSet() then
                                repeat
                                    GetPurchPaymentDateDocNo(DtldVendLedgEntry."Transaction No.", PaymentDate, PaymentDocNo);
                                until DtldVendLedgEntry.Next() = 0;
                        end;
                    end;

                    if Prepayment and Reversed then begin
                        Base := -Base;
                        Amount := -Amount;
                    end;
                    MakePurchLedger(PurchVATEntryAdd, VATLedgerLineBuffer);
                end;

                trigger OnPreDataItem()
                var
                    VATLedgerLine: Record "VAT Ledger Line";
                begin
                    SetRange("Corrected Document Date", VATLedgerName."Start Date", VATLedgerName."End Date");
                    VATLedgMgt.SetCustVendFilter(PurchVATEntryAdd, VendFilter);
                    VATLedgMgt.SetVATGroupsFilter(PurchVATEntryAdd, VATProdGroupFilter, VATBusGroupFilter);

                    VATLedgerLineBuffer.Reset();
                    VATLedgerLineBuffer.SetCurrentKey("Document No.");
                    VATLedgerLine.SetRange(Code, VATLedgerName.Code);
                    VATLedgerLine.SetRange(Type, VATLedgerName.Type);
                    if VATLedgerLine.FindLast() then;
                    LineNo := VATLedgerLine."Line No.";
                end;
            }
            dataitem(PrepayVATEntryAdd; "VAT Entry")
            {
                DataItemTableView = sorting("Posting Date", Type, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Tax Invoice Amount Type", Prepayment, Positive) where(Type = const(Sale), "Tax Invoice Amount Type" = const(VAT), Prepayment = const(true), "Additional VAT Ledger Sheet" = const(true), "VAT Allocation Type" = const(VAT));

                trigger OnAfterGetRecord()
                var
                    ReversedVATEntry: Record "VAT Entry";
                    VATEntryNo: Integer;
                begin
                    if (Base = 0) and (Amount = 0) then
                        CurrReport.Skip();

                    if not Reversed then
                        if "Posting Date" in [VATLedgerName."Start Date" .. VATLedgerName."End Date"] then
                            CurrReport.Skip();

                    if Reversed then begin
                        if not ReversedByCorrection(PrepayVATEntryAdd) then
                            CurrReport.Skip();
                        // Returned Prepayment
                        if ReversedVATEntry.Get("Reversed Entry No.") then
                            if ReversedVATEntry."Unrealized VAT Entry No." = 0 then
                                CurrReport.Skip();
                    end;

                    DocumentDate := 0D;
                    DocPostingDate := 0D;
                    RealVATEntryDate := 0D;
                    Partial := false;
                    InvoiceRecDate := 0D;
                    VATEntryNo := "Unrealized VAT Entry No.";
                    GetLineProperties(PrepayVATEntryAdd, VATEntryNo);
                    RealVATEntryDate := "Posting Date";
                    if Prepayment then
                        DocPostingDate := 0D;

                    Base := -Base;
                    Amount := -Amount;
                    MakePurchLedger(PrepayVATEntryAdd, VATLedgerLineBuffer);
                end;

                trigger OnPreDataItem()
                var
                begin
                    if not ShowCustPrepay then
                        CurrReport.Break();

                    SetRange("Corrected Document Date", VATLedgerName."Start Date", VATLedgerName."End Date");
                    VATLedgMgt.GetCustFilterByVendFilter(CustFilter, VendFilter);
                    VATLedgMgt.SetCustVendFilter(PrepayVATEntryAdd, CustFilter);
                    VATLedgMgt.SetVATGroupsFilter(PrepayVATEntryAdd, VATProdGroupFilter, VATBusGroupFilter);
                end;
            }
            dataitem(PurchVATEntry; "VAT Entry")
            {
                DataItemTableView = sorting("Posting Date", Type, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Tax Invoice Amount Type", Prepayment, Positive) where(Type = const(Purchase), "Tax Invoice Amount Type" = const(VAT), "Additional VAT Ledger Sheet" = const(false), "Include In Other VAT Ledger" = const(false), "VAT Allocation Type" = const(VAT));

                trigger OnAfterGetRecord()
                var
                    VATEntry1: Record "VAT Entry";
                    Vend: Record Vendor;
                    VendLedgEntry: Record "Vendor Ledger Entry";
                    DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
                    FA: Record "Fixed Asset";
                    VATEntry: Record "VAT Entry";
                    TransactionNo: Integer;
                    VATEntryNo: Integer;
                begin
                    exit;
                    if Reversed then
                        if not ReversedByCorrection(PurchVATEntry) then
                            CurrReport.Skip();

                    if Prepayment then begin
                        if ("Unrealized VAT Entry No." <> 0) and not Reversed then
                            CurrReport.Skip();
                    end else
                        if "Unrealized VAT Entry No." = 0 then
                            if (Base = 0) and (Amount = 0) then
                                CurrReport.Skip();
                    if not Prepayment then
                        if "Unrealized VAT Entry No." <> 0 then begin
                            if not ShowUnrealVAT then
                                CurrReport.Skip()
                        end else
                            if not ShowRealVAT then
                                CurrReport.Skip();

                    if not Reversed then
                        if not ("Posting Date" in [VATLedgerName."Start Date" .. VATLedgerName."End Date"]) then
                            CurrReport.Skip();

                    if Vend.Get("Bill-to/Pay-to No.") and
                       (Vend."Vendor Type" = Vend."Vendor Type"::"Resp. Employee") and
                       (Amount = 0)
                    then
                        CurrReport.Skip();

                    DocumentDate := 0D;
                    DocPostingDate := 0D;
                    RealVATEntryDate := 0D;
                    Partial := false;
                    InvoiceRecDate := 0D;

                    VATEntryNo := "Entry No.";
                    if "Unrealized VAT Entry No." <> 0 then
                        VATEntryNo := "Unrealized VAT Entry No.";
                    GetLineProperties(PurchVATEntry, VATEntryNo);

                    VendLedgEntry.Reset();
                    if not VendLedgEntry.Get("CV Ledg. Entry No.") then begin
                        VendLedgEntry.SetCurrentKey("Transaction No.");
                        VendLedgEntry.SetRange("Transaction No.", TransNo);
                    end else
                        VendLedgEntry.SetRange("Entry No.", "CV Ledg. Entry No.");

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

                    if Prepayment then begin
                        DocPostingDate := 0D;
                        PaymentDate := VendLedgEntry."Posting Date";
                    end;

                    if "VAT Settlement Type" <> 0 then begin
                        if VATEntry1.Get("Unrealized VAT Entry No.") then begin
                            VendLedgEntry.Reset();
                            VendLedgEntry.SetCurrentKey("Transaction No.");
                            VendLedgEntry.SetRange("Transaction No.", VATEntry1."Transaction No.");
                            if VendLedgEntry.FindFirst() then begin
                                DtldVendLedgEntry.Reset();
                                DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type");
                                DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntry."Entry No.");
                                DtldVendLedgEntry.SetFilter("Entry Type", '%1', DtldVendLedgEntry."Entry Type"::Application);
                                if DtldVendLedgEntry.FindSet() then
                                    repeat
                                        GetRealVATDate(PurchVATEntry, DtldVendLedgEntry."Transaction No.", RealVATEntryDate);
                                    until DtldVendLedgEntry.Next() = 0;
                            end;
                        end;
                    end else
                        GetRealVATDate(PurchVATEntry, "Transaction No.", RealVATEntryDate);
                    if RealVATEntryDate = 0D then
                        RealVATEntryDate := "Posting Date";

                    "Additional VAT Ledger Sheet" := true;
                    VATEntry.SetCurrentKey(Reversed, "Posting Date");
                    VATEntry.SetRange(Reversed, false);
                    VATEntry.SetFilter("Posting Date", '>%1', VATLedgerName."End Date");
                    if VATEntry.FindSet() then
                        repeat
                            VendLedgEntry.Reset();
                            VendLedgEntry.SetCurrentKey("Transaction No.");
                            if VATEntry1.Get(VATEntry."Unrealized VAT Entry No.") then
                                TransactionNo := VATEntry1."Transaction No."
                            else
                                TransactionNo := VATEntry."Transaction No.";
                            VendLedgEntry.SetRange("Transaction No.", TransactionNo);
                            if VendLedgEntry.FindFirst() then begin
                                DtldVendLedgEntry.Reset();
                                DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type");
                                DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntry."Entry No.");
                                DtldVendLedgEntry.SetFilter("Entry Type", '%1', DtldVendLedgEntry."Entry Type"::Application);
                                if DtldVendLedgEntry.FindSet() then
                                    repeat
                                        if not DtldVendLedgEntry.Unapplied then
                                            GetPurchPaymentDateDocNo(DtldVendLedgEntry."Transaction No.", PaymentDate, PaymentDocNo);
                                    until DtldVendLedgEntry.Next() = 0;
                            end;

                            ADinTA := false;
                            Base := -Base;
                            Amount := -Amount;
                            MakePurchLedger(PurchVATEntry, VATLedgerLineBuffer);

                            ADinTA := true;
                            Base := -Base;
                            Amount := -Amount;
                            Base := Base + VATEntry.Base;
                            Amount := Amount + VATEntry.Amount;
                            MakePurchLedger(PurchVATEntry, VATLedgerLineBuffer);
                        until VATEntry.Next() = 0;
                end;

                trigger OnPostDataItem()
                begin
                    SavePurchLedger();
                end;

                trigger OnPreDataItem()
                begin
                    VATLedgMgt.SetCustVendFilter(PurchVATEntry, VendFilter);
                    VATLedgMgt.SetVATGroupsFilter(PurchVATEntry, VATProdGroupFilter, VATBusGroupFilter);
                end;
            }
            dataitem(LedgerPart; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(0 .. 1));
                dataitem(PurchLedger; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                    dataitem(CustDeclLine; "Integer")
                    {
                        DataItemTableView = sorting(Number);

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then
                                PackageNoInfo.Find('-')
                            else
                                PackageNoInfo.Next();
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange(Number, 1, -2);
                        end;
                    }

                    trigger OnAfterGetRecord()
                    var
                        VATLedgerLine: Record "VAT Ledger Line";
                        ValueEntry: Record "Value Entry";
                        ItemLedgerEntry: Record "Item Ledger Entry";
                    begin
                        if Number = 1 then begin
                            if not VATLedgerLineBuffer.FindFirst() then
                                CurrReport.Break();
                        end else
                            if VATLedgerLineBuffer.Next() = 0 then
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

                        CDNo := '';
                        CountryCode := '';

                        ValueEntry.Reset();
                        ValueEntry.SetCurrentKey("Document No.");
                        ValueEntry.SetRange("Document No.", VATLedgerLineBuffer."Origin. Document No.");
                        if ValueEntry.FindSet() then
                            repeat
                                ItemLedgerEntry.Get(ValueEntry."Item Ledger Entry No.");
                                if CDNo = '' then
                                    CDNo := ItemLedgerEntry."Package No."
                                else
                                    if ItemLedgerEntry."Package No." <> CDNo then
                                        CDNo := Text12403;
                            until ValueEntry.Next() = 0;

                        ChangeNoBuf.Get(VATLedgerLineBuffer."Line No.");
                        VATLedgerLine.Get(VATLedgerLineBuffer.Type, VATLedgerLineBuffer.Code, ChangeNoBuf."Closed by Entry No.");
                        VATLedgerLine."CD No." := CDNo;
                        VATLedgerLine."Country/Region of Origin Code" := CountryCode;
                        VATLedgerLine.Modify();

                        LineLabel := 0;
                        if VATLedgerLineBuffer.Prepayment then
                            LineLabel := LineLabel::"@ PrePay";
                        if VATLedgerLineBuffer."Amt. Diff. VAT" then
                            LineLabel := LineLabel::"$ Amt.Diff";
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

                        VATLedgMgt.InsertVATLedgerLineCDNoList(VATLedgerLineBuffer);
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
                    VATLedgMgt.DeleteVATLedgerAddSheetLines(VATLedgerName);
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
                        Editable = false;
                        TableRelation = Vendor;
                    }
                    field(VATProdGroupFilter; VATProdGroupFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Product Group Filter';
                        Editable = false;
                        TableRelation = "VAT Product Posting Group";
                        ToolTip = 'Specifies a filter for data to be included. VAT product posting groups define the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    }
                    field(VATBusGroupFilter; VATBusGroupFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Business Group Filter';
                        Editable = false;
                        TableRelation = "VAT Business Posting Group";
                        ToolTip = 'Specifies a filter for data to be included. VAT business posting groups define the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    }
                    field(Sorting; Sorting)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sorting';
                        Editable = false;
                        OptionCaption = ' ,Document Date,Document No.,Last Date';
                        ToolTip = 'Specifies how items are sorted on the resulting report.';
                    }
                    field(UseExternal; UseExternal)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use External Doc. No.';
                        Editable = false;
                    }
                    field(ClearOperation; ClearOperation)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Clear Lines by Code';
                        Editable = false;
                        ToolTip = 'Specifies if you want to delete the stored lines that are created before the data in the VAT ledger is refreshed.';
                    }
                    field(StartPageNo; StartPageNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Start Numbering';
                        Editable = false;
                    }
                    field(OtherPercents; OtherPercents)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Other Rates';
                        Editable = false;
                        OptionCaption = 'Do Not Show,Summarized,Detailed';
                        ToolTip = 'Specifies the other rates that are associated with the VAT ledger. Other rates include Do Not Show, Summarized, and Detailed. VAT ledgers are used to store details about VAT in transactions that involve goods and services in Russia or goods imported into Russia.';
                    }
                    field(ShowRealVAT; ShowRealVAT)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Realized VAT';
                        Editable = false;
                        ToolTip = 'Specifies if you want to include realized VAT entries.';
                    }
                    field(ShowUnrealVAT; ShowUnrealVAT)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Unrealized VAT';
                        Editable = false;
                        ToolTip = 'Specifies if you want to include unrealized VAT entries.';
                    }
                    field(ShowAmtDiff; ShowAmtDiff)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amount Differences';
                        Editable = false;
                        ToolTip = 'Specifies if you want to include exchange rate differences.';
                    }
                    field(ShowCustPrepay; ShowCustPrepay)
                    {
                        ApplicationArea = Prepayments;
                        Caption = 'Show Customer Prepayments';
                        Editable = false;
                        ToolTip = 'Specifies if you want to include customer prepayment information.';

                        trigger OnValidate()
                        begin
                            ShowCustPrepayOnPush();
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
    end;

    var
        CompanyInfo: Record "Company Information";
        VATLedgerConnection: Record "VAT Ledger Connection";
        VATLedgerLineBuffer: Record "VAT Ledger Line" temporary;
        VATLedgerConnBuffer: Record "VAT Ledger Connection" temporary;
        AmountBuffer: Record "VAT Ledger Line" temporary;
        TotalBuffer: Record "VAT Ledger Line" temporary;
        PackageNoInfo: Record "Package No. Information" temporary;
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
        CDNo: Code[50];
        CountryCode: Code[10];
        OrigDocNo: Code[20];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text12400: Label 'cannot be %1 if Tax Invoice Amount Type is %2';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text12401: Label 'Creation is not possible!';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text12403: Label 'DIFFERENT';
#pragma warning restore AA0074
        ClearOperation: Boolean;
        RealVATEntryDate: Date;
        PaymentDate: Date;
        PaymentDocNo: Code[20];
        Partial: Boolean;
        InvoiceRecDate: Date;
        IsPrepayment: Boolean;
        TransNo: Integer;
        LineLabel: Option " ","@ PrePay","$ Amt.Diff";
        ShowCustPrepay: Boolean;
        ShowAmtDiff: Boolean;
        ShowUnrealVAT: Boolean;
        ShowRealVAT: Boolean;
        StartPageNo: Integer;
        VendNo: Code[20];
        ADinTA: Boolean;
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
                16.67, 20:
                    begin
                        AmountBuffer.Base20 := VATEntry.Base + VATEntry."Unrealized Base";
                        AmountBuffer.Amount20 := VATEntry.Amount + VATEntry."Unrealized Amount";
                    end;
                else begin
                    AmountBuffer.Base18 := VATEntry.Base + VATEntry."Unrealized Base";
                    AmountBuffer.Amount18 := VATEntry.Amount + VATEntry."Unrealized Amount";
                    AmountBuffer."VAT Percent" := VATPercent;
                end;
            end;
    end;

    [Scope('OnPrem')]
    procedure MakePurchLedger(VATEntry: Record "VAT Entry"; var LedgerBuffer: Record "VAT Ledger Line" temporary)
    var
        Vend: Record Vendor;
        Cust: Record Customer;
        CurrencyCode: Code[10];
        VATEntryType: Code[15];
        CVLedgEntryAmount: Decimal;
    begin
        if not Check(VATEntry) then
            exit;

        if (OtherPercents = OtherPercents::Total) and (AmountBuffer."VAT Percent" <> 0) then begin
            LedgerBuffer.SetRange("Document No.");
            LedgerBuffer.SetRange("Real. VAT Entry Date");
            LedgerBuffer.SetRange("Transaction/Entry No.");
            LedgerBuffer.SetRange("VAT Product Posting Group");
            LedgerBuffer.SetRange("Document Type");
            LedgerBuffer.SetRange("C/V No.");
        end else begin
            LedgerBuffer.SetRange("Document No.", DocumentNo);
            LedgerBuffer.SetRange("Payment Date", PaymentDate);
            LedgerBuffer.SetRange(Correction, ADinTA);
            LedgerBuffer.SetRange("VAT Product Posting Group");
            LedgerBuffer.SetRange("Document Type", VATEntry."Document Type");
            LedgerBuffer.SetRange("C/V No.", VendNo);
        end;
        LedgerBuffer.SetRange("VAT Percent", AmountBuffer."VAT Percent");

        if CorrDocMgt.IsCorrVATEntry(VATEntry) then
            case VATEntry."Corrective Doc. Type" of
                VATEntry."Corrective Doc. Type"::Correction:
                    begin
                        LedgerBuffer.SetRange("Correction No.", CorrectionNo);
                        LedgerBuffer.SetRange("Revision No.");
                        LedgerBuffer.SetRange("Revision of Corr. No.");
                    end;
                VATEntry."Corrective Doc. Type"::Revision:
                    begin
                        if RevisionNo <> '' then begin
                            LedgerBuffer.SetRange("Revision No.", RevisionNo);
                            LedgerBuffer.SetRange("Correction No.");
                            LedgerBuffer.SetRange("Revision of Corr. No.");
                        end;
                        if RevisionOfCorrectionNo <> '' then begin
                            LedgerBuffer.SetRange("Revision of Corr. No.", RevisionOfCorrectionNo);
                            LedgerBuffer.SetRange("Correction No.");
                            LedgerBuffer.SetRange("Revision No.");
                        end;
                    end;
            end
        else begin
            LedgerBuffer.SetRange("Correction No.", '');
            LedgerBuffer.SetRange("Revision No.", '');
            LedgerBuffer.SetRange("Revision of Corr. No.", '');
        end;

        if LedgerBuffer.IsEmpty() then begin
            LedgerBuffer.Init();
            LineNo := LineNo + 1;
            LedgerBuffer.Type := VATLedgerName.Type;
            LedgerBuffer.Code := VATLedgerName.Code;
            LedgerBuffer."Line No." := LineNo;
            if (OtherPercents = OtherPercents::Total) and
               (AmountBuffer."VAT Percent" <> 0)
            then begin
                LedgerBuffer."Document No." := '';
                LedgerBuffer."Real. VAT Entry Date" := VATLedgerName."End Date";
                LedgerBuffer."Transaction/Entry No." := 0;
                LedgerBuffer."VAT Product Posting Group" := '';
                LedgerBuffer."VAT Business Posting Group" := '';
                LedgerBuffer."Document Type" := "Gen. Journal Document Type"::" ";
            end else begin
                LedgerBuffer."Document Type" := VATEntry."Document Type";
                LedgerBuffer."Document Date" := DocumentDate;
                LedgerBuffer."Document No." := DocumentNo;
                LedgerBuffer.Correction := ADinTA;
                LedgerBuffer."Origin. Document No." := OrigDocNo;
                LedgerBuffer."Real. VAT Entry Date" := RealVATEntryDate;
                LedgerBuffer."Transaction/Entry No." := VATEntry."Transaction No.";
                LedgerBuffer."VAT Product Posting Group" := VATEntry."VAT Prod. Posting Group";
                LedgerBuffer."VAT Business Posting Group" := VATEntry."VAT Bus. Posting Group";
                LedgerBuffer."Unreal. VAT Entry Date" := DocPostingDate;
                LedgerBuffer.Prepayment := VATEntry.Prepayment;
            end;
            LedgerBuffer."C/V No." := VATEntry."Bill-to/Pay-to No.";
            LedgerBuffer."VAT Percent" := AmountBuffer."VAT Percent";

            LedgerBuffer."External Document No." := VATEntry."External Document No.";
            GetVATEntryValues(VATEntry, CVLedgEntryAmount, CurrencyCode, VATEntryType);
            LedgerBuffer.Amount := CVLedgEntryAmount;
            LedgerBuffer."Currency Code" := CurrencyCode;
            LedgerBuffer."VAT Entry Type" := VATEntryType;
            LedgerBuffer."VAT Correction" := VATEntry."VAT Correction";
            LedgerBuffer.Partial := Partial;
            LedgerBuffer."Last Date" := 0D;
            if (DocumentDate <> 0D) and (DocumentDate > LedgerBuffer."Last Date") then
                LedgerBuffer."Last Date" := DocumentDate;
            if (RealVATEntryDate <> 0D) and (RealVATEntryDate > LedgerBuffer."Last Date") then
                LedgerBuffer."Last Date" := RealVATEntryDate;
            if (DocPostingDate <> 0D) and (DocPostingDate > LedgerBuffer."Last Date") then
                LedgerBuffer."Last Date" := DocPostingDate;
            if (InvoiceRecDate <> 0D) and (InvoiceRecDate > LedgerBuffer."Last Date") then
                LedgerBuffer."Last Date" := InvoiceRecDate;

            case VATEntry.Type of
                VATEntry.Type::Purchase:
                    if Vend.Get(LedgerBuffer."C/V No.") then begin
                        LedgerBuffer."C/V Name" := Vend.Name + Vend."Name 2";
                        LedgerBuffer."C/V VAT Reg. No." := Vend."VAT Registration No.";
                        LedgerBuffer."Reg. Reason Code" := Vend."KPP Code";
                    end else
                        Vend.Init();
                VATEntry.Type::Sale:
                    if Cust.Get(LedgerBuffer."C/V No.") then begin
                        LedgerBuffer."C/V Name" := Cust.Name + Cust."Name 2";
                        LedgerBuffer."C/V VAT Reg. No." := Cust."VAT Registration No.";
                        LedgerBuffer."Reg. Reason Code" := Cust."KPP Code";
                    end;
            end;

            LedgerBuffer."Additional Sheet" := VATEntry."Additional VAT Ledger Sheet";
            if VATEntry."Additional VAT Ledger Sheet" then
                LedgerBuffer."Corr. VAT Entry Posting Date" := VATEntry."Posting Date";

            LedgerBuffer."Payment Date" := PaymentDate;
            LedgerBuffer."Payment Doc. No." := PaymentDocNo;

            if CorrDocMgt.IsCorrVATEntry(VATEntry) then begin
                LedgerBuffer."Document Date" := DocumentDate;
                LedgerBuffer."Correction No." := CorrectionNo;
                LedgerBuffer."Correction Date" := CorrectionDate;
                LedgerBuffer."Revision No." := RevisionNo;
                LedgerBuffer."Revision Date" := RevisionDate;
                LedgerBuffer."Revision of Corr. No." := RevisionOfCorrectionNo;
                LedgerBuffer."Revision of Corr. Date" := RevisionOfCorrectionDate;
                LedgerBuffer."Print Revision" := PrintRevision;
            end;

            LedgerBuffer.Insert();
            InsertLedgerConnBuffer(LedgerBuffer, VATEntry."Entry No.");
        end;

        LedgerBuffer.Base10 := LedgerBuffer.Base10 + AmountBuffer.Base10;
        LedgerBuffer.Amount10 := LedgerBuffer.Amount10 + AmountBuffer.Amount10;
        LedgerBuffer.Base18 := LedgerBuffer.Base18 + AmountBuffer.Base18;
        LedgerBuffer.Amount18 := LedgerBuffer.Amount18 + AmountBuffer.Amount18;
        LedgerBuffer.Base20 := LedgerBuffer.Base20 + AmountBuffer.Base20;
        LedgerBuffer.Amount20 := LedgerBuffer.Amount20 + AmountBuffer.Amount20;
        LedgerBuffer."Full VAT Amount" := LedgerBuffer."Full VAT Amount" + AmountBuffer."Full VAT Amount";
        LedgerBuffer."Sales Tax Amount" := LedgerBuffer."Sales Tax Amount" + AmountBuffer."Sales Tax Amount";
        LedgerBuffer."Sales Tax Base" := LedgerBuffer."Sales Tax Base" + AmountBuffer."Sales Tax Base";
        LedgerBuffer."Full Sales Tax Amount" := LedgerBuffer."Full Sales Tax Amount" + AmountBuffer."Full Sales Tax Amount";
        LedgerBuffer.Base0 := LedgerBuffer.Base0 + AmountBuffer.Base0;
        LedgerBuffer."Base VAT Exempt" := LedgerBuffer."Base VAT Exempt" + AmountBuffer."Base VAT Exempt";
        LedgerBuffer."Excise Amount" := LedgerBuffer."Excise Amount" + AmountBuffer."Excise Amount";
        if DocumentDate <> 0D then
            LedgerBuffer."Document Date" := DocumentDate;
        if DocPostingDate <> 0D then
            LedgerBuffer."Unreal. VAT Entry Date" := DocPostingDate;
        LedgerBuffer.Modify();
    end;

    [Scope('OnPrem')]
    procedure SavePurchLedger()
    var
        VATLedgerLine: Record "VAT Ledger Line";
        StartNo: Integer;
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

        if VATLedgerLineBuffer.FindSet() then
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
        if VATLedgerConnBuffer.FindSet() then
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
        if DtldVendLedgEntry.FindSet() then
            repeat
                if not (DtldVendLedgEntry."Initial Document Type" in
                        [DtldVendLedgEntry."Initial Document Type"::Invoice,
                        DtldVendLedgEntry."Initial Document Type"::"Credit Memo"])
                then begin
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
            DocumentDate := VATEntry1."Posting Date";
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
    procedure InitializeRequest(NewUseExternal: Boolean; NewVendFilter: Code[250])
    begin
        UseExternal := NewUseExternal;
        VendFilter := NewVendFilter;
        ShowCustPrepay := true;
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
        ShowCustPrepay := NewShowCustPrepmt;
    end;

    local procedure ShowCustPrepayOnPush()
    begin
        if not ShowCustPrepay then
            CustFilter := '';
    end;

    local procedure GetVATEntryValues(VATEntry: Record "VAT Entry"; var CVLedgEntryAmount: Decimal; var CurrencyCode: Code[10]; var VATEntryType: Code[15])
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if VATEntry.Type = VATEntry.Type::Sale then
            if CustLedgerEntry.Get(VATEntry."CV Ledg. Entry No.") then begin
                CustLedgerEntry.CalcFields(Amount);
                CVLedgEntryAmount := Abs(CustLedgerEntry.Amount);
                CurrencyCode := CustLedgerEntry."Currency Code";
                VATEntryType := CustLedgerEntry."VAT Entry Type";
            end;
        if VATEntry.Type = VATEntry.Type::Purchase then
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
}

