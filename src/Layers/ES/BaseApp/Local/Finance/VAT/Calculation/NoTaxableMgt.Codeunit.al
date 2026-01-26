// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Calculation;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Reversal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Receivables;

codeunit 10740 "No Taxable Mgt."
{
    Permissions = TableData "No Taxable Entry" = rm;

    trigger OnRun()
    begin
    end;

    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SIIManagement: Codeunit "SII Management";
        GLSetupRead: Boolean;
        NonEURSetupErr: label 'You must set either local currency code or additional reporting currency in General Ledger Setup to EUR.';

    local procedure CreateNoTaxableEntriesPurchInvoice(GenJournalLine: Record "Gen. Journal Line"; TransactionNo: Integer): Boolean
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        TempPurchInvLine: Record "Purch. Inv. Line" temporary;
        NoTaxableEntry: Record "No Taxable Entry";
        PostedLineRecordRef: RecordRef;
    begin
        if GenJournalLine."Document Type" <> GenJournalLine."Document Type"::Invoice then
            exit(false);
        if PurchInvHeader.Get(GenJournalLine."Document No.") then begin
            if not FindNoTaxableLinesPurchaseInvoice(
                 PurchInvLine, GenJournalLine."Account No.", GenJournalLine."Document No.", GenJournalLine."Posting Date")
            then
                exit(true);
            CopyPurchInvoiceLineToTempPurchInvoiceLine(TempPurchInvLine, PurchInvLine);
        end else begin
            if not CopyVATGenJnlLineToTempPurchInvoiceLine(TempPurchInvLine, GenJournalLine) then
                exit(false);
            GenJournalLine."Account No." := FindVendNoFromLedgEntryInSameTransNo(GenJournalLine, TransactionNo);
            if GenJournalLine."Account No." = '' then
                exit(false);
        end;

        NoTaxableEntry.InitFromGenJnlLine(GenJournalLine);
        NoTaxableEntry."Transaction No." := TransactionNo;
        PostedLineRecordRef.GetTable(TempPurchInvLine);
        InsertNoTaxableEntriesFromPurchLines(PostedLineRecordRef, NoTaxableEntry, 1);
        exit(true);
    end;

    local procedure CreateNoTaxableEntriesPurchCreditMemo(GenJournalLine: Record "Gen. Journal Line"; TransactionNo: Integer): Boolean
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        TempPurchCrMemoLine: Record "Purch. Cr. Memo Line" temporary;
        NoTaxableEntry: Record "No Taxable Entry";
        PostedLineRecordRef: RecordRef;
    begin
        if GenJournalLine."Document Type" <> GenJournalLine."Document Type"::"Credit Memo" then
            exit(false);
        if PurchCrMemoHdr.Get(GenJournalLine."Document No.") then begin
            if not FindNoTaxableLinesPurchaseCrMemo(
                 PurchCrMemoLine, GenJournalLine."Account No.", GenJournalLine."Document No.", GenJournalLine."Posting Date")
            then
                exit(true);
            CopyPurchCrMemoLineToTempPurchCrMemoLine(TempPurchCrMemoLine, PurchCrMemoLine);
        end else begin
            if not CopyVATGenJnlLineToTempPurchCrMemoLine(TempPurchCrMemoLine, GenJournalLine) then
                exit(false);
            GenJournalLine."Account No." := FindVendNoFromLedgEntryInSameTransNo(GenJournalLine, TransactionNo);
            if GenJournalLine."Account No." = '' then
                exit(false);
        end;

        NoTaxableEntry.InitFromGenJnlLine(GenJournalLine);
        NoTaxableEntry."Transaction No." := TransactionNo;
        PostedLineRecordRef.GetTable(TempPurchCrMemoLine);
        InsertNoTaxableEntriesFromPurchLines(PostedLineRecordRef, NoTaxableEntry, -1);
        exit(true);
    end;

    local procedure CreateNoTaxableEntriesSalesInvoice(GenJournalLine: Record "Gen. Journal Line"; TransactionNo: Integer): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        TempSalesInvoiceLine: Record "Sales Invoice Line" temporary;
        NoTaxableEntry: Record "No Taxable Entry";
        PostedLineRecordRef: RecordRef;
    begin
        if GenJournalLine."Document Type" <> GenJournalLine."Document Type"::Invoice then
            exit(false);
        if SalesInvoiceHeader.Get(GenJournalLine."Document No.") then begin
            if not FindNoTaxableLinesSalesInvoice(SalesInvoiceLine,
                 GenJournalLine."Account No.", GenJournalLine."Document No.", GenJournalLine."Posting Date")
            then
                exit(true);
            CopySalesInvoiceLineToTempSalesInvoiceLine(TempSalesInvoiceLine, SalesInvoiceLine);
        end else begin
            if not CopyVATGenJnlLineToTempSalesInvoiceLine(TempSalesInvoiceLine, GenJournalLine) then
                exit(false);
            GenJournalLine."Account No." := FindCustNoFromLedgEntryInSameTransNo(GenJournalLine, TransactionNo);
            if GenJournalLine."Account No." = '' then
                exit(false);
        end;

        NoTaxableEntry.InitFromGenJnlLine(GenJournalLine);
        NoTaxableEntry."Transaction No." := TransactionNo;
        PostedLineRecordRef.GetTable(TempSalesInvoiceLine);
        InsertNoTaxableEntriesFromSalesLines(PostedLineRecordRef, NoTaxableEntry, -1);
        exit(true);
    end;

    local procedure CreateNoTaxableEntriesSalesCreditMemo(GenJournalLine: Record "Gen. Journal Line"; TransactionNo: Integer): Boolean
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        TempSalesCrMemoLine: Record "Sales Cr.Memo Line" temporary;
        NoTaxableEntry: Record "No Taxable Entry";
        PostedLineRecordRef: RecordRef;
    begin
        if GenJournalLine."Document Type" <> GenJournalLine."Document Type"::"Credit Memo" then
            exit(false);
        if SalesCrMemoHeader.Get(GenJournalLine."Document No.") then begin
            if not FindNoTaxableLinesSalesCrMemo(
                 SalesCrMemoLine, GenJournalLine."Account No.", GenJournalLine."Document No.", GenJournalLine."Posting Date")
            then
                exit(true);
            CopySalesCrMemoLineToTempSalesCrMemoLine(TempSalesCrMemoLine, SalesCrMemoLine);
        end else begin
            if not CopyVATGenJnlLineToTempSalesCrMemoLine(TempSalesCrMemoLine, GenJournalLine) then
                exit(false);
            GenJournalLine."Account No." := FindCustNoFromLedgEntryInSameTransNo(GenJournalLine, TransactionNo);
            if GenJournalLine."Account No." = '' then
                exit(false);
        end;

        NoTaxableEntry.InitFromGenJnlLine(GenJournalLine);
        NoTaxableEntry."Transaction No." := TransactionNo;
        PostedLineRecordRef.GetTable(TempSalesCrMemoLine);
        InsertNoTaxableEntriesFromSalesLines(PostedLineRecordRef, NoTaxableEntry, 1);
        exit(true);
    end;

    local procedure CreateNoTaxableEntriesPurchInvoiceFromVendEntry(VendorLedgerEntry: Record "Vendor Ledger Entry"): Boolean
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        NoTaxableEntry: Record "No Taxable Entry";
        PostedLineRecordRef: RecordRef;
    begin
        if VendorLedgerEntry."Document Type" <> VendorLedgerEntry."Document Type"::Invoice then
            exit(false);
        if not PurchInvHeader.Get(VendorLedgerEntry."Document No.") then
            exit(false);
        if not FindNoTaxableLinesPurchaseInvoice(
             PurchInvLine, VendorLedgerEntry."Vendor No.", VendorLedgerEntry."Document No.", VendorLedgerEntry."Posting Date")
        then
            exit(true);

        NoTaxableEntry.InitFromVendorEntry(
          VendorLedgerEntry, PurchInvHeader."Pay-to Country/Region Code", false, PurchInvHeader."VAT Registration No.");
        PostedLineRecordRef.GetTable(PurchInvLine);
        InsertNoTaxableEntriesFromPurchLines(PostedLineRecordRef, NoTaxableEntry, 1);
        exit(true);
    end;

    local procedure CreateNoTaxableEntriesPurchCreditMemoFromVendEntry(VendorLedgerEntry: Record "Vendor Ledger Entry"): Boolean
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        NoTaxableEntry: Record "No Taxable Entry";
        PostedLineRecordRef: RecordRef;
    begin
        if VendorLedgerEntry."Document Type" <> VendorLedgerEntry."Document Type"::"Credit Memo" then
            exit(false);
        if not PurchCrMemoHdr.Get(VendorLedgerEntry."Document No.") then
            exit(false);
        if not FindNoTaxableLinesPurchaseCrMemo(
             PurchCrMemoLine, VendorLedgerEntry."Vendor No.", VendorLedgerEntry."Document No.", VendorLedgerEntry."Posting Date")
        then
            exit(true);

        NoTaxableEntry.InitFromVendorEntry(
          VendorLedgerEntry, PurchCrMemoHdr."Pay-to Country/Region Code", false, PurchCrMemoHdr."VAT Registration No.");
        PostedLineRecordRef.GetTable(PurchCrMemoLine);
        InsertNoTaxableEntriesFromPurchLines(PostedLineRecordRef, NoTaxableEntry, -1);
        exit(true);
    end;

    local procedure CreateNoTaxableEntriesSalesInvoiceFromCustEntry(CustLedgerEntry: Record "Cust. Ledger Entry"): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        NoTaxableEntry: Record "No Taxable Entry";
        PostedLineRecordRef: RecordRef;
    begin
        if CustLedgerEntry."Document Type" <> CustLedgerEntry."Document Type"::Invoice then
            exit(false);
        if not SalesInvoiceHeader.Get(CustLedgerEntry."Document No.") then
            exit(false);
        if not FindNoTaxableLinesSalesInvoice(SalesInvoiceLine,
             CustLedgerEntry."Customer No.", CustLedgerEntry."Document No.", CustLedgerEntry."Posting Date")
        then
            exit(true);

        NoTaxableEntry.InitFromCustomerEntry(
          CustLedgerEntry, SalesInvoiceHeader."Bill-to Country/Region Code",
          SalesInvoiceHeader."EU 3-Party Trade", SalesInvoiceHeader."VAT Registration No.");
        PostedLineRecordRef.GetTable(SalesInvoiceLine);
        InsertNoTaxableEntriesFromSalesLines(PostedLineRecordRef, NoTaxableEntry, -1);
        exit(true);
    end;

    local procedure CreateNoTaxableEntriesSalesCreditMemoFromCustEntry(CustLedgerEntry: Record "Cust. Ledger Entry"): Boolean
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        NoTaxableEntry: Record "No Taxable Entry";
        PostedLineRecordRef: RecordRef;
    begin
        if CustLedgerEntry."Document Type" <> CustLedgerEntry."Document Type"::"Credit Memo" then
            exit(false);
        if not SalesCrMemoHeader.Get(CustLedgerEntry."Document No.") then
            exit(false);
        if not FindNoTaxableLinesSalesCrMemo(
             SalesCrMemoLine, CustLedgerEntry."Customer No.", CustLedgerEntry."Document No.", CustLedgerEntry."Posting Date")
        then
            exit(true);

        NoTaxableEntry.InitFromCustomerEntry(
          CustLedgerEntry, SalesCrMemoHeader."Bill-to Country/Region Code",
          SalesCrMemoHeader."EU 3-Party Trade", SalesCrMemoHeader."VAT Registration No.");
        PostedLineRecordRef.GetTable(SalesCrMemoLine);
        InsertNoTaxableEntriesFromSalesLines(PostedLineRecordRef, NoTaxableEntry, 1);
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure FindNoTaxableLinesPurchaseInvoice(var PurchInvLine: Record "Purch. Inv. Line"; VendorNo: Code[20]; DocumentNo: Code[20]; PostingDate: Date): Boolean
    begin
        PurchInvLine.SetRange("Pay-to Vendor No.", VendorNo);
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.SetRange("Posting Date", PostingDate);
        PurchInvLine.SetRange("VAT Calculation Type", PurchInvLine."VAT Calculation Type"::"No Taxable VAT");
        PurchInvLine.SetRange("VAT %", 0);
        exit(PurchInvLine.FindSet());
    end;

    [Scope('OnPrem')]
    procedure FindNoTaxableLinesPurchaseCrMemo(var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; VendorNo: Code[20]; DocumentNo: Code[20]; PostingDate: Date): Boolean
    begin
        PurchCrMemoLine.SetRange("Pay-to Vendor No.", VendorNo);
        PurchCrMemoLine.SetRange("Document No.", DocumentNo);
        PurchCrMemoLine.SetRange("Posting Date", PostingDate);
        PurchCrMemoLine.SetRange("VAT Calculation Type", PurchCrMemoLine."VAT Calculation Type"::"No Taxable VAT");
        PurchCrMemoLine.SetRange("VAT %", 0);
        exit(PurchCrMemoLine.FindSet());
    end;

    [Scope('OnPrem')]
    procedure FindNoTaxableLinesSalesInvoice(var SalesInvoiceLine: Record "Sales Invoice Line"; CustomerNo: Code[20]; DocumentNo: Code[20]; PostingDate: Date): Boolean
    begin
        SalesInvoiceLine.SetRange("Bill-to Customer No.", CustomerNo);
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.SetRange("Posting Date", PostingDate);
        SalesInvoiceLine.SetRange("VAT Calculation Type", SalesInvoiceLine."VAT Calculation Type"::"No Taxable VAT");
        SalesInvoiceLine.SetRange("VAT %", 0);
        exit(SalesInvoiceLine.FindSet());
    end;

    [Scope('OnPrem')]
    procedure FindNoTaxableLinesSalesCrMemo(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; CustomerNo: Code[20]; DocumentNo: Code[20]; PostingDate: Date): Boolean
    begin
        SalesCrMemoLine.SetRange("Bill-to Customer No.", CustomerNo);
        SalesCrMemoLine.SetRange("Document No.", DocumentNo);
        SalesCrMemoLine.SetRange("Posting Date", PostingDate);
        SalesCrMemoLine.SetRange("VAT Calculation Type", SalesCrMemoLine."VAT Calculation Type"::"No Taxable VAT");
        SalesCrMemoLine.SetRange("VAT %", 0);
        exit(SalesCrMemoLine.FindSet());
    end;

#if not CLEAN27
    [Obsolete('Moved to codeunit Serv. No Taxable Mgt.', '27.0')]
    [Scope('OnPrem')]
    procedure FindNoTaxableLinesServiceInvoice(var ServiceInvoiceLine: Record Microsoft.Service.History."Service Invoice Line"; CustomerNo: Code[20]; DocumentNo: Code[20]; PostingDate: Date): Boolean
    var
        ServNoTaxableMgt: Codeunit "Serv. No Taxable Mgt.";
    begin
        exit(ServNoTaxableMgt.FindNoTaxableLinesServiceInvoice(ServiceInvoiceLine, CustomerNo, DocumentNo, PostingDate));
    end;
#endif

#if not CLEAN27
    [Obsolete('Moved to codeunit Serv. No Taxable Mgt.', '27.0')]
    [Scope('OnPrem')]
    procedure FindNoTaxableLinesServiceCrMemo(var ServiceCrMemoLine: Record Microsoft.Service.History."Service Cr.Memo Line"; CustomerNo: Code[20]; DocumentNo: Code[20]; PostingDate: Date): Boolean
    var
        ServNoTaxableMgt: Codeunit "Serv. No Taxable Mgt.";
    begin
        exit(ServNoTaxableMgt.FindNoTaxableLinesServiceCrMemo(ServiceCrMemoLine, CustomerNo, DocumentNo, PostingDate));
    end;
#endif

    local procedure FindCustNoFromLedgEntryInSameTransNo(GenJournalLine: Record "Gen. Journal Line"; TransNo: Integer): Code[20]
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document Type", GenJournalLine."Document Type");
        CustLedgerEntry.SetRange("Document No.", GenJournalLine."Document No.");
        CustLedgerEntry.SetRange("Transaction No.", TransNo);
        if CustLedgerEntry.FindFirst() then
            exit(CustLedgerEntry."Customer No.");
    end;

    local procedure FindVendNoFromLedgEntryInSameTransNo(GenJournalLine: Record "Gen. Journal Line"; TransNo: Integer): Code[20]
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Document Type", GenJournalLine."Document Type");
        VendorLedgerEntry.SetRange("Document No.", GenJournalLine."Document No.");
        VendorLedgerEntry.SetRange("Transaction No.", TransNo);
        if VendorLedgerEntry.FindFirst() then
            exit(VendorLedgerEntry."Vendor No.");
    end;

    local procedure InsertNoTaxableEntriesFromPurchLines(var PostedLineRecRef: RecordRef; NoTaxableEntry: Record "No Taxable Entry"; Sign: Integer)
    var
        DummyPurchInvLine: Record "Purch. Inv. Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        TypeFieldRef: FieldRef;
        NoFieldRef: FieldRef;
        AmountFieldRef: FieldRef;
        VATBusPostGrFieldRef: FieldRef;
        VATProdPostGrFieldRef: FieldRef;
        GenBusPostGrFieldRef: FieldRef;
        GenProdPostGrFieldRef: FieldRef;
        LineType: Option;
        LineNo: Code[20];
        LineAmount: Decimal;
        VATBusPostGroup: Code[20];
        VATProdPostGroup: Code[20];
        GenBusPostGroup: Code[20];
        GenProdPostGroup: Code[20];
        NotIn347: Boolean;
    begin
        if not PostedLineRecRef.FindSet() then
            exit;

        repeat
            TypeFieldRef := PostedLineRecRef.Field(DummyPurchInvLine.FieldNo(Type));
            NoFieldRef := PostedLineRecRef.Field(DummyPurchInvLine.FieldNo("No."));
            AmountFieldRef := PostedLineRecRef.Field(DummyPurchInvLine.FieldNo(Amount));
            VATBusPostGrFieldRef := PostedLineRecRef.Field(DummyPurchInvLine.FieldNo("VAT Bus. Posting Group"));
            VATProdPostGrFieldRef := PostedLineRecRef.Field(DummyPurchInvLine.FieldNo("VAT Prod. Posting Group"));
            GenBusPostGrFieldRef := PostedLineRecRef.Field(DummyPurchInvLine.FieldNo("Gen. Bus. Posting Group"));
            GenProdPostGrFieldRef := PostedLineRecRef.Field(DummyPurchInvLine.FieldNo("Gen. Prod. Posting Group"));
            LineType := TypeFieldRef.Value();
            LineNo := NoFieldRef.Value();
            LineAmount := AmountFieldRef.Value();
            VATBusPostGroup := VATBusPostGrFieldRef.Value();
            VATProdPostGroup := VATProdPostGrFieldRef.Value();
            GenBusPostGroup := GenBusPostGrFieldRef.Value();
            GenProdPostGroup := GenProdPostGrFieldRef.Value();

            if VATPostingSetup.Get(VATBusPostGroup, VATProdPostGroup) then
                if VATPostingSetup.IsNoTaxable() then begin
                    if Format(LineType) = Format(DummyPurchInvLine.Type::"G/L Account") then
                        NotIn347 := GLAccount.Get(LineNo) and GLAccount."Ignore in 347 Report";
                    InsertNoTaxableEntry(
                      NoTaxableEntry, NoTaxableEntry.Type::Purchase, Sign * LineAmount, VATPostingSetup."EU Service", NotIn347, 0, 0,
                      VATPostingSetup."VAT Calculation Type", VATBusPostGroup, VATProdPostGroup,
                      GenBusPostGroup, GenProdPostGroup, VATPostingSetup."Ignore In SII");
                    UpdateAmountsInCurrency(NoTaxableEntry);
                end;
        until PostedLineRecRef.Next() = 0;
    end;

    procedure InsertNoTaxableEntriesFromSalesLines(var PostedLineRecRef: RecordRef; NoTaxableEntry: Record "No Taxable Entry"; Sign: Integer)
    var
        DummySalesInvoiceLine: Record "Sales Invoice Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        GLAccount: Record "G/L Account";
        TypeFieldRef: FieldRef;
        NoFieldRef: FieldRef;
        AmountFieldRef: FieldRef;
        VATBusPostGrFieldRef: FieldRef;
        VATProdPostGrFieldRef: FieldRef;
        GenBusPostGrFieldRef: FieldRef;
        GenProdPostGrFieldRef: FieldRef;
        LineType: Option;
        LineNo: Code[20];
        LineAmount: Decimal;
        VATBusPostGroup: Code[20];
        VATProdPostGroup: Code[20];
        GenBusPostGroup: Code[20];
        GenProdPostGroup: Code[20];
        NotIn347: Boolean;
    begin
        if not PostedLineRecRef.FindSet() then
            exit;

        repeat
            TypeFieldRef := PostedLineRecRef.Field(DummySalesInvoiceLine.FieldNo(Type));
            NoFieldRef := PostedLineRecRef.Field(DummySalesInvoiceLine.FieldNo("No."));
            AmountFieldRef := PostedLineRecRef.Field(DummySalesInvoiceLine.FieldNo(Amount));
            VATBusPostGrFieldRef := PostedLineRecRef.Field(DummySalesInvoiceLine.FieldNo("VAT Bus. Posting Group"));
            VATProdPostGrFieldRef := PostedLineRecRef.Field(DummySalesInvoiceLine.FieldNo("VAT Prod. Posting Group"));
            GenBusPostGrFieldRef := PostedLineRecRef.Field(DummySalesInvoiceLine.FieldNo("Gen. Bus. Posting Group"));
            GenProdPostGrFieldRef := PostedLineRecRef.Field(DummySalesInvoiceLine.FieldNo("Gen. Prod. Posting Group"));
            LineType := TypeFieldRef.Value();
            LineNo := NoFieldRef.Value();
            LineAmount := AmountFieldRef.Value();
            VATBusPostGroup := VATBusPostGrFieldRef.Value();
            VATProdPostGroup := VATProdPostGrFieldRef.Value();
            GenBusPostGroup := GenBusPostGrFieldRef.Value();
            GenProdPostGroup := GenProdPostGrFieldRef.Value();

            if VATPostingSetup.Get(VATBusPostGroup, VATProdPostGroup) then
                if VATPostingSetup.IsNoTaxable() then begin
                    if Format(LineType) = Format(DummySalesInvoiceLine.Type::"G/L Account") then
                        NotIn347 := GLAccount.Get(LineNo) and GLAccount."Ignore in 347 Report";
                    if VATProductPostingGroup.Get(VATPostingSetup."VAT Prod. Posting Group") then;
                    InsertNoTaxableEntry(
                      NoTaxableEntry, NoTaxableEntry.Type::Sale, Sign * LineAmount, VATPostingSetup."EU Service", NotIn347,
                      VATPostingSetup."No Taxable Type", VATProductPostingGroup."Delivery Operation Code",
                      VATPostingSetup."VAT Calculation Type", VATBusPostGroup, VATProdPostGroup,
                      GenBusPostGroup, GenProdPostGroup, VATPostingSetup."Ignore In SII");
                    UpdateAmountsInCurrency(NoTaxableEntry);
                end;
        until PostedLineRecRef.Next() = 0;
    end;

    local procedure InsertNoTaxableEntriesFromGenLedgEntry(NoTaxableEntry: Record "No Taxable Entry"; EntryAmount: Decimal; Sign: Integer)
    var
        GLEntry: Record "G/L Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if NoTaxableEntry.Type = NoTaxableEntry.Type::Sale then begin
            GLEntry.SetRange("Source Type", GLEntry."Source Type"::Customer);
            GLEntry.SetRange("Bal. Account Type", GLEntry."Bal. Account Type"::Customer);
        end else begin
            GLEntry.SetRange("Source Type", GLEntry."Source Type"::Vendor);
            GLEntry.SetRange("Bal. Account Type", GLEntry."Bal. Account Type"::Vendor);
        end;
        GLEntry.SetRange("Source No.", NoTaxableEntry."Source No.");
        GLEntry.SetRange("Document Type", NoTaxableEntry."Document Type");
        GLEntry.SetRange("Document No.", NoTaxableEntry."Document No.");
        GLEntry.SetRange("Posting Date", NoTaxableEntry."Posting Date");
        GLEntry.SetRange(Reversed, false);

        if GLEntry.IsEmpty() then
            exit;
        GLEntry.FindFirst();
        if not VATPostingSetup.Get(GLEntry."VAT Bus. Posting Group", GLEntry."VAT Prod. Posting Group") then
            exit;
        if not VATPostingSetup.IsNoTaxable() then
            exit;

        if GeneralPostingSetup.Get(GLEntry."Gen. Bus. Posting Group", GLEntry."Gen. Prod. Posting Group") then;
        if NoTaxableEntry.Type = NoTaxableEntry.Type::Sale then
            if VATProductPostingGroup.Get(VATPostingSetup."VAT Prod. Posting Group") then;
        if NoTaxableEntry."Document Type" = NoTaxableEntry."Document Type"::"Credit Memo" then
            Sign := -Sign;
        InsertNoTaxableEntry(
          NoTaxableEntry, NoTaxableEntry.Type, Sign * Abs(EntryAmount), VATPostingSetup."EU Service", false,
          VATPostingSetup."No Taxable Type", VATProductPostingGroup."Delivery Operation Code",
          VATPostingSetup."VAT Calculation Type", VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group",
          GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."Ignore In SII");
        UpdateAmountsInCurrency(NoTaxableEntry);
    end;

    local procedure InsertNoTaxableEntry(var NoTaxableEntry: Record "No Taxable Entry"; EntryType: Enum "General Posting Type"; EntryAmount: Decimal; EUService: Boolean; NotIn347: Boolean; NoTaxableType: Option; DeliveryOperationCode: Option; VATCalculationType: Enum "Tax Calculation Type"; VATBusPostingGroupCode: Code[20]; VATProdPostingGroupCode: Code[20]; GenBusPostingGroupCode: Code[20]; GenProdPostingGroupCode: Code[20]; IgnoreInSII: Boolean)
    begin
        NoTaxableEntry.Type := EntryType;
        NoTaxableEntry.Base := EntryAmount;
        NoTaxableEntry.Amount := EntryAmount;
        NoTaxableEntry."EU Service" := EUService;
        NoTaxableEntry."Not In 347" := NotIn347;
        NoTaxableEntry."No Taxable Type" := NoTaxableType;
        NoTaxableEntry."Delivery Operation Code" := DeliveryOperationCode;
        NoTaxableEntry."VAT Calculation Type" := VATCalculationType;
        NoTaxableEntry."VAT Bus. Posting Group" := VATBusPostingGroupCode;
        NoTaxableEntry."VAT Prod. Posting Group" := VATProdPostingGroupCode;
        NoTaxableEntry."Gen. Bus. Posting Group" := GenBusPostingGroupCode;
        NoTaxableEntry."Gen. Prod. Posting Group" := GenProdPostingGroupCode;
        NoTaxableEntry.Intracommunity := SIIManagement.IsIntracommunity(NoTaxableEntry."Country/Region Code");
        NoTaxableEntry."Ignore In SII" := IgnoreInSII;
        NoTaxableEntry.Update(NoTaxableEntry);
    end;

    local procedure MapDeliveryOperationCode(DeliveryOperationCode: Option " ","E - General","M - Imported Tax Exempt","H - Imported Tax Exempt (Representative)"): Integer
    begin
        if DeliveryOperationCode = DeliveryOperationCode::" " then
            exit(DeliveryOperationCode::"E - General");
        exit(DeliveryOperationCode);
    end;

    [Scope('OnPrem')]
    procedure CalcNoTaxableAmountCustomerSimple(var NormalAmount: Decimal; var EUServiceAmount: Decimal; var EU3PartyAmount: Decimal; CustomerNo: Code[20]; FromDate: Date; ToDate: Date; FilterString: Text)
    var
        NoTaxableNormalAmountSales: array[3] of Decimal;
    begin
        CalcNoTaxableAmountCustomer(
          NoTaxableNormalAmountSales, NormalAmount, EUServiceAmount, EU3PartyAmount, CustomerNo,
          FromDate, ToDate, FilterString, false);
    end;

    [Scope('OnPrem')]
    procedure CalcNoTaxableAmountCustomerWithDeliveryCode(var NoTaxableNormalAmount: array[3] of Decimal; var EUServiceAmount: Decimal; var EU3PartyAmount: Decimal; CustomerNo: Code[20]; FromDate: Date; ToDate: Date; FilterString: Text)
    var
        NormalAmount: Decimal;
    begin
        CalcNoTaxableAmountCustomer(
          NoTaxableNormalAmount, NormalAmount, EUServiceAmount, EU3PartyAmount, CustomerNo,
          FromDate, ToDate, FilterString, true);
    end;

    local procedure CalcNoTaxableAmountCustomer(var NoTaxableNormalAmountSales: array[3] of Decimal; var NormalAmount: Decimal; var EUServiceAmount: Decimal; var EU3PartyAmount: Decimal; CustomerNo: Code[20]; FromDate: Date; ToDate: Date; FilterString: Text; SplitByDelivery: Boolean)
    var
        NoTaxableEntry: Record "No Taxable Entry";
        AmountInACY: Boolean;
    begin
        NoTaxableEntry.FilterNoTaxableEntriesForSourceWithVATReportingDate(
          "General Posting Type"::Sale.AsInteger(), CustomerNo, "Gen. Journal Document Type"::Invoice.AsInteger(),
          FromDate, ToDate, FilterString);
        if NoTaxableEntry.IsEmpty() then
            exit;

        AmountInACY := ReportAmountInACY();

        NoTaxableEntry.SetRange("EU Service", true);
        if AmountInACY then begin
            NoTaxableEntry.CalcSums("Amount (ACY)");
            EUServiceAmount += NoTaxableEntry."Amount (ACY)"
        end else begin
            NoTaxableEntry.CalcSums("Amount (LCY)");
            EUServiceAmount += NoTaxableEntry."Amount (LCY)"
        end;

        NoTaxableEntry.SetRange("EU Service", false);
        NoTaxableEntry.SetRange("EU 3-Party Trade", true);
        if AmountInACY then begin
            NoTaxableEntry.CalcSums("Amount (ACY)");
            EU3PartyAmount += NoTaxableEntry."Amount (ACY)"
        end else begin
            NoTaxableEntry.CalcSums("Amount (LCY)");
            EU3PartyAmount += NoTaxableEntry."Amount (LCY)"
        end;

        NoTaxableEntry.SetRange("EU 3-Party Trade", false);
        if not SplitByDelivery then
            if AmountInACY then begin
                NoTaxableEntry.CalcSums("Amount (ACY)");
                NormalAmount += NoTaxableEntry."Amount (ACY)"
            end else begin
                NoTaxableEntry.CalcSums("Amount (LCY)");
                NormalAmount += NoTaxableEntry."Amount (LCY)"
            end
        else
            if NoTaxableEntry.FindSet() then
                repeat
                    if AmountInACY then
                        NoTaxableNormalAmountSales[MapDeliveryOperationCode(NoTaxableEntry."Delivery Operation Code")] += NoTaxableEntry."Amount (ACY)"
                    else
                        NoTaxableNormalAmountSales[MapDeliveryOperationCode(NoTaxableEntry."Delivery Operation Code")] += NoTaxableEntry."Amount (LCY)"
                until NoTaxableEntry.Next() = 0;
    end;

    procedure CalcNoTaxableAmountVendor(var NormalAmount: Decimal; var EUServiceAmount: Decimal; VendorNo: Code[20]; FromDate: Date; ToDate: Date; FilterString: Text[1024])
    var
        NoTaxableEntry: Record "No Taxable Entry";
        AmountInACY: Boolean;
    begin
        NoTaxableEntry.FilterNoTaxableEntriesForSourceWithVATReportingDate(
          "General Posting Type"::Purchase.AsInteger(), VendorNo, "Gen. Journal Document Type"::Invoice.AsInteger(),
          FromDate, ToDate, FilterString);
        if NoTaxableEntry.IsEmpty() then
            exit;

        AmountInACY := ReportAmountInACY();

        NoTaxableEntry.SetRange("EU Service", false);
        if AmountInACY then begin
            NoTaxableEntry.CalcSums("Amount (ACY)");
            NormalAmount += NoTaxableEntry."Amount (ACY)";
        end else begin
            NoTaxableEntry.CalcSums("Amount (LCY)");
            NormalAmount += NoTaxableEntry."Amount (LCY)";
        end;

        NoTaxableEntry.SetRange("EU Service", true);
        if AmountInACY then begin
            NoTaxableEntry.CalcSums("Amount (ACY)");
            EUServiceAmount += NoTaxableEntry."Amount (ACY)";
        end else begin
            NoTaxableEntry.CalcSums("Amount (LCY)");
            EUServiceAmount += NoTaxableEntry."Amount (LCY)";
        end;
    end;

    local procedure ReportAmountInACY(): Boolean
    begin
        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."LCY Code" <> 'EUR' then
            if GeneralLedgerSetup."Additional Reporting Currency" <> 'EUR' then
                Error(NonEURSetupErr)
            else
                exit(true);

        exit(false);
    end;

    local procedure ConvertAmountFCYtoLCY(Amount: Decimal; PostingDate: Date; CurrencyCode: Code[10]; CurrencyFactor: Decimal): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        if CurrencyCode = '' then
            exit(Amount);
        exit(
          Round(CurrencyExchangeRate.ExchangeAmtFCYToLCY(PostingDate, CurrencyCode, Amount, CurrencyFactor)));
    end;

    local procedure ConvertAmountLCYtoACY(Amount: Decimal; PostingDate: Date; CurrencyCode: Code[10]): Decimal
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CurrencyFactor: Decimal;
    begin
        Currency.Get(CurrencyCode);
        Currency.InitRoundingPrecision();
        CurrencyFactor := CurrencyExchangeRate.ExchangeRate(PostingDate, CurrencyCode);
        exit(
          Round(
            CurrencyExchangeRate.ExchangeAmtLCYToFCY(
              PostingDate, CurrencyCode, Amount, CurrencyFactor), Currency."Amount Rounding Precision"));
    end;

    local procedure CopySalesInvoiceLineToTempSalesInvoiceLine(var TempSalesInvoiceLine: Record "Sales Invoice Line" temporary; var SalesInvoiceLine: Record "Sales Invoice Line")
    begin
        TempSalesInvoiceLine.Reset();
        TempSalesInvoiceLine.DeleteAll();
        repeat
            TempSalesInvoiceLine := SalesInvoiceLine;
            TempSalesInvoiceLine.Insert();
        until SalesInvoiceLine.Next() = 0;
    end;

    local procedure CopyVATGenJnlLineToTempSalesInvoiceLine(var TempSalesInvoiceLine: Record "Sales Invoice Line" temporary; GenJournalLine: Record "Gen. Journal Line"): Boolean
    begin
        Clear(TempSalesInvoiceLine);
        if (GenJournalLine."VAT Bus. Posting Group" <> '') or (GenJournalLine."VAT Prod. Posting Group" <> '') then begin
            if GenJournalLine."Account Type" = GenJournalLine."Account Type"::"G/L Account" then begin
                TempSalesInvoiceLine.Type := TempSalesInvoiceLine.Type::"G/L Account";
                TempSalesInvoiceLine."No." := GenJournalLine."Account No.";
            end;
            TempSalesInvoiceLine.Amount := GenJournalLine.Amount;
            TempSalesInvoiceLine."Gen. Bus. Posting Group" := GenJournalLine."Gen. Bus. Posting Group";
            TempSalesInvoiceLine."Gen. Prod. Posting Group" := GenJournalLine."Gen. Prod. Posting Group";
            TempSalesInvoiceLine."VAT Bus. Posting Group" := GenJournalLine."VAT Bus. Posting Group";
            TempSalesInvoiceLine."VAT Prod. Posting Group" := GenJournalLine."VAT Prod. Posting Group";
            TempSalesInvoiceLine.Insert();
            exit(true);
        end;
        if (GenJournalLine."Bal. VAT Bus. Posting Group" <> '') and (GenJournalLine."Bal. VAT Prod. Posting Group" <> '') then begin
            if GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::"G/L Account" then begin
                TempSalesInvoiceLine.Type := TempSalesInvoiceLine.Type::"G/L Account";
                TempSalesInvoiceLine."No." := GenJournalLine."Bal. Account No.";
            end;
            TempSalesInvoiceLine.Amount := GenJournalLine.Amount;
            TempSalesInvoiceLine."Gen. Bus. Posting Group" := GenJournalLine."Bal. Gen. Bus. Posting Group";
            TempSalesInvoiceLine."Gen. Prod. Posting Group" := GenJournalLine."Bal. Gen. Prod. Posting Group";
            TempSalesInvoiceLine."VAT Bus. Posting Group" := GenJournalLine."Bal. VAT Bus. Posting Group";
            TempSalesInvoiceLine."VAT Prod. Posting Group" := GenJournalLine."Bal. VAT Prod. Posting Group";
            TempSalesInvoiceLine.Insert();
            exit(true);
        end;
        exit(false);
    end;

    local procedure CopySalesCrMemoLineToTempSalesCrMemoLine(var TempSalesCrMemoLine: Record "Sales Cr.Memo Line" temporary; var SalesCrMemoLine: Record "Sales Cr.Memo Line")
    begin
        TempSalesCrMemoLine.Reset();
        TempSalesCrMemoLine.DeleteAll();
        repeat
            TempSalesCrMemoLine := SalesCrMemoLine;
            TempSalesCrMemoLine.Insert();
        until SalesCrMemoLine.Next() = 0;
    end;

    local procedure CopyVATGenJnlLineToTempSalesCrMemoLine(var TempSalesCrMemoLine: Record "Sales Cr.Memo Line" temporary; GenJournalLine: Record "Gen. Journal Line"): Boolean
    begin
        Clear(TempSalesCrMemoLine);
        if (GenJournalLine."VAT Bus. Posting Group" <> '') or (GenJournalLine."VAT Prod. Posting Group" <> '') then begin
            if GenJournalLine."Account Type" = GenJournalLine."Account Type"::"G/L Account" then begin
                TempSalesCrMemoLine.Type := TempSalesCrMemoLine.Type::"G/L Account";
                TempSalesCrMemoLine."No." := GenJournalLine."Account No.";
            end;
            TempSalesCrMemoLine.Amount := GenJournalLine.Amount;
            TempSalesCrMemoLine."Gen. Bus. Posting Group" := GenJournalLine."Gen. Bus. Posting Group";
            TempSalesCrMemoLine."Gen. Prod. Posting Group" := GenJournalLine."Gen. Prod. Posting Group";
            TempSalesCrMemoLine."VAT Bus. Posting Group" := GenJournalLine."VAT Bus. Posting Group";
            TempSalesCrMemoLine."VAT Prod. Posting Group" := GenJournalLine."VAT Prod. Posting Group";
            TempSalesCrMemoLine.Insert();
            exit(true);
        end;
        if (GenJournalLine."Bal. VAT Bus. Posting Group" <> '') and (GenJournalLine."Bal. VAT Prod. Posting Group" <> '') then begin
            if GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::"G/L Account" then begin
                TempSalesCrMemoLine.Type := TempSalesCrMemoLine.Type::"G/L Account";
                TempSalesCrMemoLine."No." := GenJournalLine."Bal. Account No.";
            end;
            TempSalesCrMemoLine.Amount := -GenJournalLine.Amount;
            TempSalesCrMemoLine."Gen. Bus. Posting Group" := GenJournalLine."Bal. Gen. Bus. Posting Group";
            TempSalesCrMemoLine."Gen. Prod. Posting Group" := GenJournalLine."Bal. Gen. Prod. Posting Group";
            TempSalesCrMemoLine."VAT Bus. Posting Group" := GenJournalLine."Bal. VAT Bus. Posting Group";
            TempSalesCrMemoLine."VAT Prod. Posting Group" := GenJournalLine."Bal. VAT Prod. Posting Group";
            TempSalesCrMemoLine.Insert();
            exit(true);
        end;
        exit(false);
    end;

    local procedure CopyPurchInvoiceLineToTempPurchInvoiceLine(var TempPurchInvLine: Record "Purch. Inv. Line" temporary; var PurchInvLine: Record "Purch. Inv. Line")
    begin
        TempPurchInvLine.Reset();
        TempPurchInvLine.DeleteAll();
        repeat
            TempPurchInvLine := PurchInvLine;
            TempPurchInvLine.Insert();
        until PurchInvLine.Next() = 0;
    end;

    local procedure CopyVATGenJnlLineToTempPurchInvoiceLine(var TempPurchInvLine: Record "Purch. Inv. Line" temporary; GenJournalLine: Record "Gen. Journal Line"): Boolean
    begin
        Clear(TempPurchInvLine);
        if (GenJournalLine."VAT Bus. Posting Group" <> '') or (GenJournalLine."VAT Prod. Posting Group" <> '') then begin
            if GenJournalLine."Account Type" = GenJournalLine."Account Type"::"G/L Account" then begin
                TempPurchInvLine.Type := TempPurchInvLine.Type::"G/L Account";
                TempPurchInvLine."No." := GenJournalLine."Account No.";
            end;
            TempPurchInvLine.Amount := GenJournalLine.Amount;
            TempPurchInvLine."Gen. Bus. Posting Group" := GenJournalLine."Gen. Bus. Posting Group";
            TempPurchInvLine."Gen. Prod. Posting Group" := GenJournalLine."Gen. Prod. Posting Group";
            TempPurchInvLine."VAT Bus. Posting Group" := GenJournalLine."VAT Bus. Posting Group";
            TempPurchInvLine."VAT Prod. Posting Group" := GenJournalLine."VAT Prod. Posting Group";
            TempPurchInvLine.Insert();
            exit(true);
        end;
        if (GenJournalLine."Bal. VAT Bus. Posting Group" <> '') and (GenJournalLine."Bal. VAT Prod. Posting Group" <> '') then begin
            if GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::"G/L Account" then begin
                TempPurchInvLine.Type := TempPurchInvLine.Type::"G/L Account";
                TempPurchInvLine."No." := GenJournalLine."Bal. Account No.";
            end;
            TempPurchInvLine.Amount := -GenJournalLine.Amount;
            TempPurchInvLine."Gen. Bus. Posting Group" := GenJournalLine."Bal. Gen. Bus. Posting Group";
            TempPurchInvLine."Gen. Prod. Posting Group" := GenJournalLine."Bal. Gen. Prod. Posting Group";
            TempPurchInvLine."VAT Bus. Posting Group" := GenJournalLine."Bal. VAT Bus. Posting Group";
            TempPurchInvLine."VAT Prod. Posting Group" := GenJournalLine."Bal. VAT Prod. Posting Group";
            TempPurchInvLine.Insert();
            exit(true);
        end;
        exit(false);
    end;

    local procedure CopyPurchCrMemoLineToTempPurchCrMemoLine(var TempPurchCrMemoLine: Record "Purch. Cr. Memo Line" temporary; var PurchCrMemoLine: Record "Purch. Cr. Memo Line")
    begin
        TempPurchCrMemoLine.Reset();
        TempPurchCrMemoLine.DeleteAll();
        repeat
            TempPurchCrMemoLine := PurchCrMemoLine;
            TempPurchCrMemoLine.Insert();
        until PurchCrMemoLine.Next() = 0;
    end;

    local procedure CopyVATGenJnlLineToTempPurchCrMemoLine(var TempPurchCrMemoLine: Record "Purch. Cr. Memo Line" temporary; GenJournalLine: Record "Gen. Journal Line"): Boolean
    begin
        Clear(TempPurchCrMemoLine);
        if (GenJournalLine."VAT Bus. Posting Group" <> '') or (GenJournalLine."VAT Prod. Posting Group" <> '') then begin
            if GenJournalLine."Account Type" = GenJournalLine."Account Type"::"G/L Account" then begin
                TempPurchCrMemoLine.Type := TempPurchCrMemoLine.Type::"G/L Account";
                TempPurchCrMemoLine."No." := GenJournalLine."Account No.";
            end;
            TempPurchCrMemoLine.Amount := GenJournalLine.Amount;
            TempPurchCrMemoLine."Gen. Bus. Posting Group" := GenJournalLine."Gen. Bus. Posting Group";
            TempPurchCrMemoLine."Gen. Prod. Posting Group" := GenJournalLine."Gen. Prod. Posting Group";
            TempPurchCrMemoLine."VAT Bus. Posting Group" := GenJournalLine."VAT Bus. Posting Group";
            TempPurchCrMemoLine."VAT Prod. Posting Group" := GenJournalLine."VAT Prod. Posting Group";
            TempPurchCrMemoLine.Insert();
            exit(true);
        end;
        if (GenJournalLine."Bal. VAT Bus. Posting Group" <> '') and (GenJournalLine."Bal. VAT Prod. Posting Group" <> '') then begin
            if GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::"G/L Account" then begin
                TempPurchCrMemoLine.Type := TempPurchCrMemoLine.Type::"G/L Account";
                TempPurchCrMemoLine."No." := GenJournalLine."Bal. Account No.";
            end;
            TempPurchCrMemoLine.Amount := GenJournalLine.Amount;
            TempPurchCrMemoLine."Gen. Bus. Posting Group" := GenJournalLine."Bal. Gen. Bus. Posting Group";
            TempPurchCrMemoLine."Gen. Prod. Posting Group" := GenJournalLine."Bal. Gen. Prod. Posting Group";
            TempPurchCrMemoLine."VAT Bus. Posting Group" := GenJournalLine."Bal. VAT Bus. Posting Group";
            TempPurchCrMemoLine."VAT Prod. Posting Group" := GenJournalLine."Bal. VAT Prod. Posting Group";
            TempPurchCrMemoLine.Insert();
            exit(true);
        end;
        exit(false);
    end;

    local procedure UpdateAmountsInCurrency(var NoTaxableEntry: Record "No Taxable Entry")
    begin
        NoTaxableEntry."Base (LCY)" := ConvertAmountFCYtoLCY(NoTaxableEntry.Base, NoTaxableEntry."Posting Date", NoTaxableEntry."Currency Code", NoTaxableEntry."Currency Factor");
        NoTaxableEntry."Amount (LCY)" := ConvertAmountFCYtoLCY(NoTaxableEntry.Amount, NoTaxableEntry."Posting Date", NoTaxableEntry."Currency Code", NoTaxableEntry."Currency Factor");
        GetGLSetup();
        if GeneralLedgerSetup."Additional Reporting Currency" <> '' then begin
            NoTaxableEntry."Base (ACY)" :=
              ConvertAmountLCYtoACY(NoTaxableEntry."Base (LCY)", NoTaxableEntry."Posting Date", GeneralLedgerSetup."Additional Reporting Currency");
            NoTaxableEntry."Amount (ACY)" :=
              ConvertAmountLCYtoACY(NoTaxableEntry."Amount (LCY)", NoTaxableEntry."Posting Date", GeneralLedgerSetup."Additional Reporting Currency");
        end;
        NoTaxableEntry.Modify();
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GeneralLedgerSetup.Get();
        GLSetupRead := true;
    end;

    [Scope('OnPrem')]
    procedure UpdateNoTaxableEntryFromVendorLedgerEntry(VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        Vendor: Record Vendor;
        NoTaxableEntry: Record "No Taxable Entry";
    begin
        if not Vendor.Get(VendorLedgerEntry."Vendor No.") then
            exit;
        if CreateNoTaxableEntriesPurchInvoiceFromVendEntry(VendorLedgerEntry) then
            exit;
        if CreateNoTaxableEntriesPurchCreditMemoFromVendEntry(VendorLedgerEntry) then
            exit;

        VendorLedgerEntry.CalcFields(Amount);
        NoTaxableEntry.InitFromVendorEntry(VendorLedgerEntry, Vendor."Country/Region Code", false, Vendor."VAT Registration No.");
        NoTaxableEntry.Type := NoTaxableEntry.Type::Purchase;
        InsertNoTaxableEntriesFromGenLedgEntry(NoTaxableEntry, VendorLedgerEntry.Amount, 1);
    end;

    [Scope('OnPrem')]
    procedure UpdateNoTaxableEntryFromCustomerLedgerEntry(CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        NoTaxableEntry: Record "No Taxable Entry";
        Customer: Record Customer;
        ShouldExit: Boolean;
    begin
        if not Customer.Get(CustLedgerEntry."Customer No.") then
            exit;
        if CreateNoTaxableEntriesSalesInvoiceFromCustEntry(CustLedgerEntry) then
            exit;
        if CreateNoTaxableEntriesSalesCreditMemoFromCustEntry(CustLedgerEntry) then
            exit;

        ShouldExit := false;
        OnUpdateNoTaxableEntryFromCustomerLedgerEntryOnBeforeCalcAmount(CustLedgerEntry, ShouldExit);
        if ShouldExit then
            exit;

        CustLedgerEntry.CalcFields(Amount);
        NoTaxableEntry.InitFromCustomerEntry(CustLedgerEntry, Customer."Country/Region Code", false, Customer."VAT Registration No.");
        NoTaxableEntry.Type := NoTaxableEntry.Type::Sale;
        InsertNoTaxableEntriesFromGenLedgEntry(NoTaxableEntry, CustLedgerEntry.Amount, -1);
    end;

    [EventSubscriber(ObjectType::Codeunit, 12, 'OnAfterPostGLAcc', '', false, false)]
    local procedure InsertNoTaxableEntryOnPostGLAcc(var GenJnlLine: Record "Gen. Journal Line"; var TempGLEntryBuf: Record "G/L Entry" temporary; var NextEntryNo: Integer; var NextTransactionNo: Integer; Balancing: Boolean)
    begin
        if (GenJnlLine."Gen. Posting Type" = GenJnlLine."Gen. Posting Type"::Sale) or
           (GenJnlLine."Bal. Gen. Posting Type" = GenJnlLine."Bal. Gen. Posting Type"::Sale)
        then
            InsertNoTaxableEntryOnPostCust(GenJnlLine, Balancing, TempGLEntryBuf, NextEntryNo, NextTransactionNo)
        else
            if (GenJnlLine."Gen. Posting Type" = GenJnlLine."Gen. Posting Type"::Purchase) or
               (GenJnlLine."Bal. Gen. Posting Type" = GenJnlLine."Bal. Gen. Posting Type"::Purchase)
            then
                InsertNoTaxableEntryOnPostVend(GenJnlLine, Balancing, TempGLEntryBuf, NextEntryNo, NextTransactionNo);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterPostVend', '', false, false)]
    local procedure InsertNoTaxableEntryOnPostVend(var GenJournalLine: Record "Gen. Journal Line"; Balancing: Boolean; var TempGLEntryBuf: Record "G/L Entry" temporary; var NextEntryNo: Integer; var NextTransactionNo: Integer)
    begin
        if not (GenJournalLine."Document Type" in
                [GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::"Credit Memo"])
        then
            exit;

        if CreateNoTaxableEntriesPurchInvoice(GenJournalLine, TempGLEntryBuf."Transaction No.") then
            exit;
        if CreateNoTaxableEntriesPurchCreditMemo(GenJournalLine, TempGLEntryBuf."Transaction No.") then
            exit;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterPostCust', '', false, false)]
    local procedure InsertNoTaxableEntryOnPostCust(var GenJournalLine: Record "Gen. Journal Line"; Balancing: Boolean; var TempGLEntryBuf: Record "G/L Entry" temporary; var NextEntryNo: Integer; var NextTransactionNo: Integer)
    begin
        if not (GenJournalLine."Document Type" in
                [GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::"Credit Memo"])
        then
            exit;

        if CreateNoTaxableEntriesSalesInvoice(GenJournalLine, TempGLEntryBuf."Transaction No.") then
            exit;
        if CreateNoTaxableEntriesSalesCreditMemo(GenJournalLine, TempGLEntryBuf."Transaction No.") then
            exit;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Reverse", 'OnReverseVendLedgEntryOnBeforeInsertVendLedgEntry', '', false, false)]
    local procedure ReverseNoTaxableEntryVend(var NewVendLedgEntry: Record "Vendor Ledger Entry"; VendLedgEntry: Record "Vendor Ledger Entry")
    var
        DummyNoTaxableEntry: Record "No Taxable Entry";
    begin
        DummyNoTaxableEntry.Reverse(
          "General Posting Type"::Purchase.AsInteger(), VendLedgEntry."Vendor No.",
          VendLedgEntry."Document Type".AsInteger(), VendLedgEntry."Document No.", VendLedgEntry."Posting Date");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Reverse", 'OnReverseCustLedgEntryOnBeforeInsertCustLedgEntry', '', false, false)]
    local procedure ReverseNoTaxableEntryCust(var NewCustLedgerEntry: Record "Cust. Ledger Entry"; CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        DummyNoTaxableEntry: Record "No Taxable Entry";
    begin
        DummyNoTaxableEntry.Reverse(
          "General Posting Type"::Sale.AsInteger(), CustLedgerEntry."Customer No.",
          CustLedgerEntry."Document Type".AsInteger(), CustLedgerEntry."Document No.", CustLedgerEntry."Posting Date");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterTestPurchLine', '', false, false)]
    local procedure TestPurchLineOnPurchPost(PurchLine: Record "Purchase Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if VATPostingSetup.Get(PurchLine."VAT Bus. Posting Group", PurchLine."VAT Prod. Posting Group") and
            (VATPostingSetup."No Taxable Type" <> VATPostingSetup."No Taxable Type"::" ") then
            VATPostingSetup.TestField("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"No Taxable VAT");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterTestSalesLine', '', false, false)]
    local procedure TestSalesLineOnSalesPost(SalesLine: Record "Sales Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group") and
            (VATPostingSetup."No Taxable Type" <> VATPostingSetup."No Taxable Type"::" ") then
            VATPostingSetup.TestField("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"No Taxable VAT");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Check Line", 'OnAfterCheckGenJnlLine', '', false, false)]
    local procedure TestGenJnlLineOnGenJnlPost(var GenJournalLine: Record "Gen. Journal Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if VATPostingSetup.Get(GenJournalLine."VAT Bus. Posting Group", GenJournalLine."VAT Prod. Posting Group") and
            (VATPostingSetup."No Taxable Type" <> VATPostingSetup."No Taxable Type"::" ") then
            VATPostingSetup.TestField("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"No Taxable VAT");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateNoTaxableEntryFromCustomerLedgerEntryOnBeforeCalcAmount(CustLedgerEntry: Record "Cust. Ledger Entry"; var ShouldExit: Boolean)
    begin
    end;
}

