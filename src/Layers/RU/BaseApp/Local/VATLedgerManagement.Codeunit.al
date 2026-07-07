#pragma warning disable AA0247
codeunit 12423 "VAT Ledger Management"
{
    Permissions = tabledata "VAT Ledger Line Tariff No." = imd,
                  tabledata "VAT Ledger Line CD No." = imd,
                  tabledata "VAT Ledger Line" = imd;

    var
        MultipleCDNoTxt: Label 'DIFFERENT', Comment = 'Means that there are several different "CD No." values';

    [Scope('OnPrem')]
    procedure SetVATGroupsFilter(var VATEntry: Record "VAT Entry"; VATProdGroupFilter: Code[250]; VATBusGroupFilter: Code[250])
    begin
        if VATProdGroupFilter <> '' then
            VATEntry.SetFilter("VAT Prod. Posting Group", VATProdGroupFilter);
        if VATBusGroupFilter <> '' then
            VATEntry.SetFilter("VAT Bus. Posting Group", VATBusGroupFilter);
    end;

    [Scope('OnPrem')]
    procedure SetCustVendFilter(var VATEntry: Record "VAT Entry"; CustVendFilter: Code[250])
    begin
        if CustVendFilter <> '' then
            VATEntry.SetFilter("Bill-to/Pay-to No.", CustVendFilter);
    end;

    [Scope('OnPrem')]
    procedure SetVATPeriodFilter(var VATEntry: Record "VAT Entry"; StartDate: Date; EndDate: Date)
    begin
        VATEntry.SetRange("Posting Date", StartDate, EndDate);
    end;

    [Scope('OnPrem')]
    procedure GetVendFilterByCustFilter(var VendFilter: Code[250]; CustFilter: Code[250])
    var
        Customer: Record Customer;
        Delimiter: Code[1];
    begin
        if CustFilter <> '' then begin
            Delimiter := '';
            Customer.Reset();
            Customer.SetFilter("No.", CustFilter);
            if Customer.FindSet() then
                repeat
                    if Customer."Vendor No." <> '' then begin
                        VendFilter := VendFilter + Delimiter + Customer."Vendor No.";
                        Delimiter := '|';
                    end;
                until Customer.Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetCustFilterByVendFilter(var CustFilter: Code[250]; VendFilter: Code[250])
    var
        Vendor: Record Vendor;
        Delimiter: Code[1];
    begin
        if VendFilter <> '' then begin
            Delimiter := '';
            Vendor.Reset();
            Vendor.SetFilter("No.", VendFilter);
            if Vendor.Find('-') then
                repeat
                    if Vendor."Customer No." <> '' then begin
                        CustFilter := CustFilter + Delimiter + Vendor."Customer No.";
                        Delimiter := '|';
                    end;
                until Vendor.Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure SkipVATEntry(VATEntry: Record "VAT Entry"; StartDate: Date; EndDate: Date; CheckReversed: Boolean; CheckUnapplied: Boolean; CheckBaseAndAmount: Boolean; CheckPrepmt: Boolean; CheckAmtDiffVAT: Boolean; CheckUnrealizedVAT: Boolean; CheckPrepmtDiff: Boolean; ShowPrepmt: Boolean; ShowAmtDiff: Boolean; ShowUnrealVAT: Boolean; ShowRealVAT: Boolean): Boolean
    var
        ReversedByVATEntry: Record "VAT Entry";
        ReversedByCorrection: Boolean;
        UnappliedEntryDate: Date;
    begin
        if CheckReversed then
            if VATEntry.Reversed then begin
                ReversedByCorrection := false;
                if VATEntry."Additional VAT Ledger Sheet" then
                    ReversedByCorrection := true;

                if ReversedByVATEntry.Get(VATEntry."Reversed by Entry No.") then
                    if ReversedByVATEntry."Corrected Document Date" <> 0D then
                        ReversedByCorrection := true;
                if not ReversedByCorrection then
                    exit(true);
            end;

        if CheckUnapplied then
            if VATEntry.IsUnapplied(UnappliedEntryDate) then
                if UnappliedEntryDate in [StartDate .. EndDate] then
                    exit(true);

        if CheckBaseAndAmount then
            if (VATEntry.Base = 0) and (VATEntry.Amount = 0) and
               not VATEntry.Prepayment
            then
                exit(true);

        if CheckPrepmt then
            if VATEntry.Prepayment and
               (not ShowPrepmt or
                ((VATEntry."Unrealized VAT Entry No." <> 0) and not VATEntry.Reversed) or
                ((VATEntry.Amount = 0) and (VATEntry."Unrealized Amount" = 0)))
            then
                exit(true);

        if CheckUnrealizedVAT then begin
            if VATEntry.Prepayment then
                if (VATEntry."Unrealized VAT Entry No." <> 0) and
                   not VATEntry.Reversed
                then
                    exit(true);
            if not VATEntry.Prepayment then
                if VATEntry."Unrealized VAT Entry No." <> 0 then begin
                    if not ShowUnrealVAT then
                        exit(true)
                end else
                    if not ShowRealVAT then
                        exit(true);
        end;

        if CheckPrepmtDiff then
            if VATEntry."Prepmt. Diff." then
                exit(true);

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure GetCorrDocProperties(CorrVATEntry: Record "VAT Entry"; var DocumentNo: Code[30]; var DocumentDate: Date; var CorrectionNo: Code[30]; var CorrectionDate: Date; var RevisionNo: Code[20]; var RevisionDate: Date; var RevisionOfCorrNo: Code[20]; var RevisionOfCorrDate: Date; var PrintRevision: Boolean)
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        CorrSalesInvHeader: Record "Sales Invoice Header";
        CorrSalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CorrPurchInvHeader: Record "Purch. Inv. Header";
        CorrPurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        CorrDocMgt: Codeunit "Corrective Document Mgt.";
        IsInvoice: Boolean;
    begin
        CorrectionNo := '';
        CorrectionDate := 0D;
        RevisionNo := '';
        RevisionDate := 0D;
        RevisionOfCorrNo := '';
        RevisionOfCorrDate := 0D;
        PrintRevision := false;

        case CorrVATEntry.Type of
            CorrVATEntry.Type::Sale:
                case CorrVATEntry."Document Type" of
                    CorrVATEntry."Document Type"::Invoice:
                        begin
                            SalesInvHeader.Get(CorrVATEntry."Document No.");
                            IsInvoice := SalesInvHeader."Original Doc. Type" = SalesInvHeader."Original Doc. Type"::Invoice;
                            CorrDocMgt.GetSalesDocData(
                              DocumentNo, DocumentDate, IsInvoice, SalesInvHeader."Original Doc. No.");
                            if SalesInvHeader."Corrective Doc. Type" =
                               SalesInvHeader."Corrective Doc. Type"::Correction
                            then begin
                                CorrectionNo := SalesInvHeader."No.";
                                CorrectionDate := SalesInvHeader."Posting Date";
                            end else
                                case SalesInvHeader."Corrected Doc. Type" of
                                    SalesInvHeader."Corrected Doc. Type"::Invoice:
                                        begin
                                            PrintRevision := true;
                                            CorrSalesInvHeader.Get(SalesInvHeader."Corrected Doc. No.");
                                            if CorrSalesInvHeader."Corrective Doc. Type" <>
                                               CorrSalesInvHeader."Corrective Doc. Type"::Correction
                                            then begin
                                                RevisionNo := SalesInvHeader."Revision No.";
                                                RevisionDate := SalesInvHeader."Posting Date";
                                            end else begin
                                                RevisionOfCorrNo := SalesInvHeader."Revision No.";
                                                RevisionOfCorrDate := SalesInvHeader."Posting Date";
                                                CorrectionNo := CorrSalesInvHeader."No.";
                                                CorrectionDate := CorrSalesInvHeader."Posting Date";
                                            end;
                                        end;
                                    SalesInvHeader."Corrected Doc. Type"::"Credit Memo":
                                        begin
                                            PrintRevision := false;
                                            CorrSalesCrMemoHeader.Get(SalesInvHeader."Corrected Doc. No.");
                                            if CorrSalesCrMemoHeader."Corrective Doc. Type" <>
                                               CorrSalesCrMemoHeader."Corrective Doc. Type"::Correction
                                            then begin
                                                RevisionNo := SalesInvHeader."Revision No.";
                                                RevisionDate := SalesInvHeader."Posting Date";
                                            end else begin
                                                RevisionOfCorrNo := SalesInvHeader."Revision No.";
                                                RevisionOfCorrDate := SalesInvHeader."Posting Date";
                                                CorrectionNo := CorrSalesCrMemoHeader."No.";
                                                CorrectionDate := CorrSalesCrMemoHeader."Posting Date";
                                            end;
                                        end;
                                end;
                        end;
                    CorrVATEntry."Document Type"::"Credit Memo":
                        begin
                            SalesCrMemoHeader.Get(CorrVATEntry."Document No.");
                            IsInvoice := SalesCrMemoHeader."Original Doc. Type" = SalesCrMemoHeader."Original Doc. Type"::Invoice;
                            CorrDocMgt.GetSalesDocData(
                              DocumentNo, DocumentDate, IsInvoice, SalesCrMemoHeader."Original Doc. No.");
                            if SalesCrMemoHeader."Corrective Doc. Type" =
                               SalesCrMemoHeader."Corrective Doc. Type"::Correction
                            then begin
                                CorrectionNo := SalesCrMemoHeader."No.";
                                CorrectionDate := SalesCrMemoHeader."Posting Date";
                            end else
                                case SalesCrMemoHeader."Corrected Doc. Type" of
                                    SalesCrMemoHeader."Corrected Doc. Type"::Invoice:
                                        begin
                                            PrintRevision := false;
                                            CorrSalesInvHeader.Get(SalesCrMemoHeader."Corrected Doc. No.");
                                            if CorrSalesInvHeader."Corrective Doc. Type" <>
                                               CorrSalesInvHeader."Corrective Doc. Type"::Correction
                                            then begin
                                                RevisionNo := SalesCrMemoHeader."Revision No.";
                                                RevisionDate := SalesCrMemoHeader."Posting Date";
                                            end else begin
                                                RevisionOfCorrNo := SalesCrMemoHeader."Revision No.";
                                                RevisionOfCorrDate := SalesCrMemoHeader."Posting Date";
                                                CorrectionNo := CorrSalesInvHeader."No.";
                                                CorrectionDate := CorrSalesInvHeader."Posting Date";
                                            end;
                                        end;
                                    SalesCrMemoHeader."Corrected Doc. Type"::"Credit Memo":
                                        begin
                                            PrintRevision := true;
                                            CorrSalesCrMemoHeader.Get(SalesCrMemoHeader."Corrected Doc. No.");
                                            if CorrSalesCrMemoHeader."Corrective Doc. Type" <>
                                               CorrSalesCrMemoHeader."Corrective Doc. Type"::Correction
                                            then begin
                                                RevisionNo := SalesCrMemoHeader."Revision No.";
                                                RevisionDate := SalesCrMemoHeader."Posting Date";
                                            end else begin
                                                RevisionOfCorrNo := SalesCrMemoHeader."Revision No.";
                                                RevisionOfCorrDate := SalesCrMemoHeader."Posting Date";
                                                CorrectionNo := CorrSalesCrMemoHeader."No.";
                                                CorrectionDate := CorrSalesCrMemoHeader."Posting Date";
                                            end;
                                        end;
                                end;
                        end;
                end;
            CorrVATEntry.Type::Purchase:
                case CorrVATEntry."Document Type" of
                    CorrVATEntry."Document Type"::Invoice:
                        begin
                            PurchInvHeader.Get(CorrVATEntry."Document No.");
                            IsInvoice := PurchInvHeader."Original Doc. Type" = PurchInvHeader."Original Doc. Type"::Invoice;
                            CorrDocMgt.GetPurchDocData(
                              DocumentNo, DocumentDate, IsInvoice, PurchInvHeader."Original Doc. No.");
                            if PurchInvHeader."Corrective Doc. Type" =
                               PurchInvHeader."Corrective Doc. Type"::Correction
                            then
                                CorrDocMgt.GetPurchDocData(CorrectionNo, CorrectionDate, true, CorrVATEntry."Document No.")
                            else
                                case PurchInvHeader."Corrected Doc. Type" of
                                    PurchInvHeader."Corrected Doc. Type"::Invoice:
                                        begin
                                            PrintRevision := true;
                                            CorrPurchInvHeader.Get(PurchInvHeader."Corrected Doc. No.");
                                            if CorrPurchInvHeader."Corrective Doc. Type" <>
                                               CorrPurchInvHeader."Corrective Doc. Type"::Correction
                                            then begin
                                                RevisionNo := PurchInvHeader."Revision No.";
                                                RevisionDate := PurchInvHeader."Posting Date";
                                            end else begin
                                                RevisionOfCorrNo := PurchInvHeader."Revision No.";
                                                RevisionOfCorrDate := PurchInvHeader."Posting Date";
                                                CorrDocMgt.GetPurchDocData(
                                                  CorrectionNo, CorrectionDate, true, PurchInvHeader."Corrected Doc. No.");
                                            end;
                                        end;
                                    PurchInvHeader."Corrected Doc. Type"::"Credit Memo":
                                        begin
                                            PrintRevision := false;
                                            CorrPurchCrMemoHeader.Get(PurchInvHeader."Corrected Doc. No.");
                                            if CorrPurchCrMemoHeader."Corrective Doc. Type" <>
                                               CorrPurchCrMemoHeader."Corrective Doc. Type"::Correction
                                            then begin
                                                RevisionNo := PurchInvHeader."Revision No.";
                                                RevisionDate := PurchInvHeader."Posting Date";
                                            end else begin
                                                RevisionOfCorrNo := PurchInvHeader."Revision No.";
                                                RevisionOfCorrDate := PurchInvHeader."Posting Date";
                                                CorrDocMgt.GetPurchDocData(
                                                  CorrectionNo, CorrectionDate, false, PurchInvHeader."Corrected Doc. No.");
                                            end;
                                        end;
                                end;
                        end;
                    CorrVATEntry."Document Type"::"Credit Memo":
                        begin
                            PurchCrMemoHeader.Get(CorrVATEntry."Document No.");
                            IsInvoice := PurchCrMemoHeader."Original Doc. Type" = PurchCrMemoHeader."Original Doc. Type"::Invoice;
                            CorrDocMgt.GetPurchDocData(
                              DocumentNo, DocumentDate, IsInvoice, PurchCrMemoHeader."Original Doc. No.");
                            if PurchCrMemoHeader."Corrective Doc. Type" =
                               PurchCrMemoHeader."Corrective Doc. Type"::Correction
                            then
                                CorrDocMgt.GetPurchDocData(CorrectionNo, CorrectionDate, false, CorrVATEntry."Document No.")
                            else
                                case PurchCrMemoHeader."Corrected Doc. Type" of
                                    PurchCrMemoHeader."Corrected Doc. Type"::Invoice:
                                        begin
                                            PrintRevision := false;
                                            CorrPurchInvHeader.Get(PurchCrMemoHeader."Corrected Doc. No.");
                                            if CorrPurchInvHeader."Corrective Doc. Type" <>
                                               CorrPurchInvHeader."Corrective Doc. Type"::Correction
                                            then begin
                                                RevisionNo := PurchCrMemoHeader."Revision No.";
                                                RevisionDate := PurchCrMemoHeader."Posting Date";
                                            end else begin
                                                RevisionOfCorrNo := PurchCrMemoHeader."Revision No.";
                                                RevisionOfCorrDate := PurchCrMemoHeader."Posting Date";
                                                CorrDocMgt.GetPurchDocData(
                                                  CorrectionNo, CorrectionDate, true, PurchCrMemoHeader."Corrected Doc. No.");
                                            end;
                                        end;
                                    PurchCrMemoHeader."Corrected Doc. Type"::"Credit Memo":
                                        begin
                                            PrintRevision := true;
                                            CorrPurchCrMemoHeader.Get(PurchCrMemoHeader."Corrected Doc. No.");
                                            if CorrPurchCrMemoHeader."Corrective Doc. Type" <>
                                               CorrPurchCrMemoHeader."Corrective Doc. Type"::Correction
                                            then begin
                                                RevisionNo := PurchCrMemoHeader."Revision No.";
                                                RevisionDate := PurchCrMemoHeader."Posting Date";
                                            end else begin
                                                RevisionOfCorrNo := PurchCrMemoHeader."Revision No.";
                                                RevisionOfCorrDate := PurchCrMemoHeader."Posting Date";
                                                CorrDocMgt.GetPurchDocData(
                                                  CorrectionNo, CorrectionDate, false, PurchCrMemoHeader."Corrected Doc. No.");
                                            end;
                                        end;
                                end;
                        end;
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure InsertVATLedgerLineCDNoList(VATLedgerLineBuf: Record "VAT Ledger Line")
    var
        VATLedgerLine: Record "VAT Ledger Line";
        ValueEntry: Record "Value Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        CDNo: Code[50];
    begin
        CDNo := '';
        if VATLedgerLineBuf."C/V Type" = VATLedgerLineBuf."C/V Type"::Customer then
            ValueEntry.SetRange("Source Type", ValueEntry."Source Type"::Customer)
        else
            ValueEntry.SetRange("Source Type", ValueEntry."Source Type"::Vendor);
        ValueEntry.SetRange("Source No.", VATLedgerLineBuf."C/V No.");
        ValueEntry.SetRange("Document No.", VATLedgerLineBuf."Origin. Document No.");

        if ValueEntry.FindSet() then
            repeat
                ItemLedgerEntry.Get(ValueEntry."Item Ledger Entry No.");
                if ItemLedgerEntry."Package No." <> '' then begin
                    InsertVATLedgerLineCDNo(VATLedgerLineBuf, ItemLedgerEntry."Package No.");
                    if CDNo = '' then
                        CDNo := ItemLedgerEntry."Package No."
                    else
                        if CDNo <> ItemLedgerEntry."Package No." then
                            CDNo := MultipleCDNoTxt;
                end;
            until (ValueEntry.Next() = 0);

        if CDNo <> '' then begin
            VATLedgerLine.Get(VATLedgerLineBuf.Type, VATLedgerLineBuf.Code, VATLedgerLineBuf."Line No.");
            VATLedgerLine."CD No." := CDNo;
            VATLedgerLine.Modify();
        end;
    end;

    local procedure InsertVATLedgerLineCDNo(VATLedgerLine: Record "VAT Ledger Line"; CDNo: Code[50])
    var
        VATLedgerLineCDNo: Record "VAT Ledger Line CD No.";
    begin
        VATLedgerLineCDNo.Init();
        VATLedgerLineCDNo.Type := VATLedgerLine.Type;
        VATLedgerLineCDNo.Code := VATLedgerLine.Code;
        VATLedgerLineCDNo."Line No." := VATLedgerLine."Line No.";
        VATLedgerLineCDNo."CD No." := CDNo;
        if VATLedgerLineCDNo.Insert() then;
    end;

    [Scope('OnPrem')]
    procedure InsertVATLedgerLineTariffNoList(VATLedgerLineBuf: Record "VAT Ledger Line")
    var
        VATLedgerLine: Record "VAT Ledger Line";
        DummyValueEntry: Record "Value Entry";
        LocalReportMgt: Codeunit "Local Report Management";
        ValueEntryItemTariffNo: Query "Value Entry Item Tariff No.";
        TariffNo: Code[20];
        PrevTariffNo: Code[20];
    begin
        TariffNo := '';
        PrevTariffNo := '';
        if VATLedgerLineBuf."C/V Type" = VATLedgerLineBuf."C/V Type"::Customer then
            ValueEntryItemTariffNo.SetRange(Source_Type, DummyValueEntry."Source Type"::Customer)
        else
            ValueEntryItemTariffNo.SetRange(Source_Type, DummyValueEntry."Source Type"::Vendor);
        ValueEntryItemTariffNo.SetRange(Source_No, VATLedgerLineBuf."C/V No.");
        ValueEntryItemTariffNo.SetRange(Document_No, VATLedgerLineBuf."Origin. Document No.");
        ValueEntryItemTariffNo.Open();

        while ValueEntryItemTariffNo.Read() do
            if PrevTariffNo <> ValueEntryItemTariffNo.Tariff_No then begin
                PrevTariffNo := ValueEntryItemTariffNo.Tariff_No;
                if LocalReportMgt.IsEAEUItem_ValueEntry(
                     ValueEntryItemTariffNo.Document_Type, ValueEntryItemTariffNo.Document_No, ValueEntryItemTariffNo.Document_Line_No)
                then begin
                    InsertVATLedgerLineTariffNo(VATLedgerLineBuf, ValueEntryItemTariffNo.Tariff_No);
                    if TariffNo = '' then
                        TariffNo := ValueEntryItemTariffNo.Tariff_No
                    else
                        if TariffNo <> ValueEntryItemTariffNo.Tariff_No then
                            TariffNo := MultipleCDNoTxt;
                end;
            end;

        if TariffNo <> '' then begin
            VATLedgerLine.Get(VATLedgerLineBuf.Type, VATLedgerLineBuf.Code, VATLedgerLineBuf."Line No.");
            VATLedgerLine."Tariff No." := TariffNo;
            VATLedgerLine.Modify();
        end;
    end;

    local procedure InsertVATLedgerLineTariffNo(VATLedgerLine: Record "VAT Ledger Line"; TariffNo: Code[20])
    var
        VATLedgerLineTariffNo: Record "VAT Ledger Line Tariff No.";
    begin
        VATLedgerLineTariffNo.Init();
        VATLedgerLineTariffNo.Type := VATLedgerLine.Type;
        VATLedgerLineTariffNo.Code := VATLedgerLine.Code;
        VATLedgerLineTariffNo."Line No." := VATLedgerLine."Line No.";
        VATLedgerLineTariffNo."Tariff No." := TariffNo;
        if VATLedgerLineTariffNo.Insert() then;
    end;

    [Scope('OnPrem')]
    procedure DeleteVATLedgerLines(VATLedger: Record "VAT Ledger")
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        VATLedgerLine.SetRange(Type, VATLedger.Type);
        VATLedgerLine.SetRange(Code, VATLedger.Code);
        VATLedgerLine.DeleteAll(true);
    end;

    [Scope('OnPrem')]
    procedure DeleteVATLedgerAddSheetLines(VATLedger: Record "VAT Ledger")
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        VATLedgerLine.SetRange(Type, VATLedger.Type);
        VATLedgerLine.SetRange(Code, VATLedger.Code);
        VATLedgerLine.SetRange("Additional Sheet", true);
        VATLedgerLine.DeleteAll(true);
    end;

    [Scope('OnPrem')]
    procedure GetVATPctRate2018(): Decimal
    begin
        exit(18);
    end;

    [Scope('OnPrem')]
    procedure GetVATPctRate2019(): Decimal
    begin
        exit(20);
    end;
}

