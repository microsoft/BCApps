// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Ledger;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

table 10740 "No Taxable Entry"
{
    Caption = 'No Taxable Entry';
    DrillDownPageID = "No Taxable Entries";
    LookupPageID = "No Taxable Entries";
    Permissions = TableData "No Taxable Entry" = rim;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(3; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(6; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(7; Type; Enum "General Posting Type")
        {
            Caption = 'Type';
        }
        field(8; Base; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Base';
        }
        field(9; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(10; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
        }
        field(12; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = if (Type = const(Purchase)) Vendor
            else
            if (Type = const(Sale)) Customer;
        }
        field(13; "EU 3-Party Trade"; Boolean)
        {
            Caption = 'EU 3-Party Trade';
        }
        field(18; Closed; Boolean)
        {
            Caption = 'Closed';
            Editable = false;
        }
        field(19; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(21; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
        }
        field(26; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(28; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(39; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(40; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(54; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(55; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(56; Reversed; Boolean)
        {
            Caption = 'Reversed';
        }
        field(57; "Reversed by Entry No."; Integer)
        {
            Caption = 'Reversed by Entry No.';
            TableRelation = "No Taxable Entry";
        }
        field(58; "Reversed Entry No."; Integer)
        {
            Caption = 'Reversed Entry No.';
            TableRelation = "No Taxable Entry";
        }
        field(59; "EU Service"; Boolean)
        {
            Caption = 'EU Service';
        }
        field(61; "Not In 347"; Boolean)
        {
            Caption = 'Not In 347';
        }
        field(73; "Delivery Operation Code"; Option)
        {
            Caption = 'Delivery Operation Code';
            OptionCaption = ' ,E - General,M - Imported Tax Exempt,H - Imported Tax Exempt (Representative)';
            OptionMembers = " ","E - General","M - Imported Tax Exempt","H - Imported Tax Exempt (Representative)";
        }
        field(76; "No Taxable Type"; Option)
        {
            Caption = 'No Taxable Type';
            OptionCaption = ' ,Non Taxable Art 7-14 and others,Non Taxable Due To Localization Rules';
            OptionMembers = " ","Non Taxable Art 7-14 and others","Non Taxable Due To Localization Rules";
        }
        field(101; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(102; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
        }
        field(115; Intracommunity; Boolean)
        {
            Caption = 'Intracommunity';
        }
        field(121; "Base (LCY)"; Decimal)
        {
            Caption = 'Base (LCY)';
        }
        field(122; "Amount (LCY)"; Decimal)
        {
            Caption = 'Amount (LCY)';
        }
        field(131; "Base (ACY)"; Decimal)
        {
            Caption = 'Base (ACY)';
        }
        field(132; "Amount (ACY)"; Decimal)
        {
            Caption = 'Amount (ACY)';
        }
        field(10707; "VAT Reporting Date"; Date)
        {
            Caption = 'VAT Date';
        }
        field(10708; "Ignore In SII"; Boolean)
        {
            Caption = 'Ignore In SII';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Document No.", "Posting Date")
        {
        }
        key(Key3; Type, "Posting Date", "Document Type", "Document No.", "Source No.")
        {
        }
        key(Key4; "No. Series", "Posting Date", "Document No.")
        {
        }
        key(Key5; Type, "VAT Reporting Date", "Document Type", "Document No.", "Source No.")
        {
        }
        key(Key6; "No. Series", "VAT Reporting Date", "Document No.")
        {
        }
        key(Key10; Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Reporting Date")
        {
            SumIndexFields = Base;
        }
    }
    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure FilterNoTaxableEntry(EntryType: Option; SourceNo: Code[20]; DocumentType: Option; DocumentNo: Code[20]; PostingDate: Date; IsReversed: Boolean)
    begin
        SetRange(Type, EntryType);
        SetRange("Source No.", SourceNo);
        SetRange("Document Type", DocumentType);
        SetRange("Document No.", DocumentNo);
        SetRange("Posting Date", PostingDate);
        SetRange(Reversed, IsReversed);
    end;

    internal procedure FilterNoTaxableEntryWithVATReportingDate(EntryType: Option; SourceNo: Code[20]; DocumentType: Option; DocumentNo: Code[20]; VATReportingDate: Date; IsReversed: Boolean)
    begin
        SetRange(Type, EntryType);
        SetRange("Source No.", SourceNo);
        SetRange("Document Type", DocumentType);
        SetRange("Document No.", DocumentNo);
        SetRange("VAT Reporting Date", VATReportingDate);
        SetRange(Reversed, IsReversed);
    end;

    [Scope('OnPrem')]
    procedure FilterNoTaxableEntriesForSource(EntryType: Option; SourceNo: Code[20]; DocumentType: Option; FromDate: Date; ToDate: Date; GenProdPostGroupFilter: Text)
    begin
        SetRange(Type, EntryType);
        SetRange("Source No.", SourceNo);
        SetRange("Document Type", DocumentType);
        SetRange("Posting Date", FromDate, ToDate);
        if GenProdPostGroupFilter <> '' then
            SetFilter("Gen. Prod. Posting Group", GenProdPostGroupFilter);
        SetRange(Intracommunity, true);
        SetRange(Reversed, false);
    end;

    internal procedure FilterNoTaxableEntriesForSourceWithVATReportingDate(EntryType: Option; SourceNo: Code[20]; DocumentType: Option; FromDate: Date; ToDate: Date; GenProdPostGroupFilter: Text)
    begin
        SetRange(Type, EntryType);
        SetRange("Source No.", SourceNo);
        SetRange("Document Type", DocumentType);
        SetRange("VAT Reporting Date", FromDate, ToDate);
        if GenProdPostGroupFilter <> '' then
            SetFilter("Gen. Prod. Posting Group", GenProdPostGroupFilter);
        SetRange(Intracommunity, true);
        SetRange(Reversed, false);
    end;

    [Scope('OnPrem')]
    procedure InitFromGenJnlLine(GenJournalLine: Record "Gen. Journal Line")
    begin
        "Document No." := GenJournalLine."Document No.";
        "Document Type" := GenJournalLine."Document Type";
        "Document Date" := GenJournalLine."Document Date";
        "Posting Date" := GenJournalLine."Posting Date";
        "Currency Code" := GenJournalLine."Currency Code";
        "Country/Region Code" := GenJournalLine."Country/Region Code";
        "Source No." := GenJournalLine."Account No.";
        "External Document No." := GenJournalLine."External Document No.";
        "Currency Factor" := GenJournalLine."Currency Factor";
        "No. Series" := GenJournalLine."Posting No. Series";
        "EU 3-Party Trade" := GenJournalLine."EU 3-Party Trade";
        "VAT Registration No." := GenJournalLine."VAT Registration No.";
        "VAT Reporting Date" := GenJournalLine."VAT Reporting Date";

        OnAfterInitFromGenJnlLine(Rec, GenJournalLine);
    end;

#if not CLEAN27
    [Obsolete('Moved to codeunit Serv. No Taxable Management', '27.0')]
    [Scope('OnPrem')]
    procedure InitFromServiceDocument(ServiceHeader: Record Microsoft.Service.Document."Service Header"; PostedDocumentNo: Code[20])
    var
        ServNoTaxableManagement: Codeunit "Serv. No Taxable Mgt.";
    begin
        ServNoTaxableManagement.InitFromServiceDocument(Rec, ServiceHeader, PostedDocumentNo);
    end;
#endif

    [Scope('OnPrem')]
    procedure InitFromVendorEntry(VendorLedgerEntry: Record "Vendor Ledger Entry"; CountryRegionCode: Code[10]; EU3PartyTrade: Boolean; VATRegistrationNo: Text[20])
    begin
        "Document No." := VendorLedgerEntry."Document No.";
        "Document Type" := VendorLedgerEntry."Document Type";
        "Document Date" := VendorLedgerEntry."Document Date";
        "Posting Date" := VendorLedgerEntry."Posting Date";
        "Currency Code" := VendorLedgerEntry."Currency Code";
        "Country/Region Code" := CountryRegionCode;
        "Source No." := VendorLedgerEntry."Vendor No.";
        "External Document No." := VendorLedgerEntry."External Document No.";
        "Currency Factor" := VendorLedgerEntry."Original Currency Factor";
        "No. Series" := VendorLedgerEntry."No. Series";
        "EU 3-Party Trade" := EU3PartyTrade;
        "VAT Registration No." := VATRegistrationNo;
        "Transaction No." := VendorLedgerEntry."Transaction No.";
        "VAT Reporting Date" := VendorLedgerEntry."VAT Reporting Date";

        OnAfterInitFromVendorEntry(Rec, VendorLedgerEntry);
    end;

    [Scope('OnPrem')]
    procedure InitFromCustomerEntry(CustLedgerEntry: Record "Cust. Ledger Entry"; CountryRegionCode: Code[10]; EU3PartyTrade: Boolean; VATRegistrationNo: Text[20])
    begin
        "Document No." := CustLedgerEntry."Document No.";
        "Document Type" := CustLedgerEntry."Document Type";
        "Document Date" := CustLedgerEntry."Document Date";
        "Posting Date" := CustLedgerEntry."Posting Date";
        "Currency Code" := CustLedgerEntry."Currency Code";
        "Country/Region Code" := CountryRegionCode;
        "Source No." := CustLedgerEntry."Customer No.";
        "External Document No." := CustLedgerEntry."External Document No.";
        "Currency Factor" := CustLedgerEntry."Original Currency Factor";
        "No. Series" := CustLedgerEntry."No. Series";
        "EU 3-Party Trade" := EU3PartyTrade;
        "VAT Registration No." := VATRegistrationNo;
        "Transaction No." := CustLedgerEntry."Transaction No.";
        "VAT Reporting Date" := CustLedgerEntry."VAT Reporting Date";

        OnAfterInitFromCustomerEntry(Rec, CustLedgerEntry);
    end;

    [Scope('OnPrem')]
    procedure Reverse(EntryType: Option; SourceNo: Code[20]; DocumentType: Option; DocumentNo: Code[20]; PostingDate: Date)
    var
        NoTaxableEntry: Record "No Taxable Entry";
        NewNoTaxableEntry: Record "No Taxable Entry";
    begin
        NoTaxableEntry.FilterNoTaxableEntry(EntryType, SourceNo, DocumentType, DocumentNo, PostingDate, false);
        if NoTaxableEntry.IsEmpty() then
            exit;

        NoTaxableEntry.FindSet(true);
        repeat
            NewNoTaxableEntry := NoTaxableEntry;
            NewNoTaxableEntry."Entry No." := GetLastEntryNo() + 1;
            NewNoTaxableEntry.Base := -NewNoTaxableEntry.Base;
            NewNoTaxableEntry."Base (LCY)" := -NewNoTaxableEntry."Base (LCY)";
            NewNoTaxableEntry."Base (ACY)" := -NewNoTaxableEntry."Base (ACY)";
            NewNoTaxableEntry.Amount := -NewNoTaxableEntry.Amount;
            NewNoTaxableEntry."Amount (LCY)" := -NewNoTaxableEntry."Amount (LCY)";
            NewNoTaxableEntry."Amount (ACY)" := -NewNoTaxableEntry."Amount (ACY)";

            NewNoTaxableEntry.Reversed := true;
            NewNoTaxableEntry."Reversed Entry No." := NoTaxableEntry."Entry No.";
            NewNoTaxableEntry.Insert();

            NoTaxableEntry.Reversed := true;
            NoTaxableEntry."Reversed by Entry No." := NewNoTaxableEntry."Entry No.";
            NoTaxableEntry.Modify();
        until NoTaxableEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure Update(NoTaxableEntry: Record "No Taxable Entry")
    begin
        Rec := NoTaxableEntry;

        SetRange(Type, NoTaxableEntry.Type);
        SetRange("Document Type", NoTaxableEntry."Document Type");
        SetRange("Document No.", NoTaxableEntry."Document No.");
        SetRange("Posting Date", NoTaxableEntry."Posting Date");
        SetRange("Source No.", NoTaxableEntry."Source No.");
        SetRange("VAT Calculation Type", NoTaxableEntry."VAT Calculation Type");
        SetRange("EU Service", NoTaxableEntry."EU Service");
        SetRange("Not In 347", NoTaxableEntry."Not In 347");
        SetRange("Ignore In SII", NoTaxableEntry."Ignore In SII");
        SetRange("No Taxable Type", NoTaxableEntry."No Taxable Type");
        SetRange("Delivery Operation Code", NoTaxableEntry."Delivery Operation Code");
        SetRange("VAT Bus. Posting Group", NoTaxableEntry."VAT Bus. Posting Group");
        SetRange("VAT Prod. Posting Group", NoTaxableEntry."VAT Prod. Posting Group");
        if FindFirst() then begin
            Base += NoTaxableEntry.Base;
            "Base (LCY)" += NoTaxableEntry."Base (LCY)";
            "Base (ACY)" += NoTaxableEntry."Base (ACY)";
            Amount += NoTaxableEntry.Amount;
            "Amount (LCY)" += NoTaxableEntry."Amount (LCY)";
            "Amount (ACY)" += NoTaxableEntry."Amount (ACY)";
            Modify();
        end else begin
            "Entry No." := GetLastEntryNo() + 1;
            Insert();
        end;
    end;

    local procedure GetLastEntryNo(): Integer
    var
        NoTaxableEntry: Record "No Taxable Entry";
    begin
        if not NoTaxableEntry.FindLast() then
            exit(0);

        exit(NoTaxableEntry."Entry No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromGenJnlLine(var NoTaxableEntry: Record "No Taxable Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromCustomerEntry(var NoTaxableEntry: Record "No Taxable Entry"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

#if not CLEAN27
    internal procedure RunOnAfterInitFromServiceDocument(var NoTaxableEntry: Record "No Taxable Entry"; ServiceHeader: Record Microsoft.Service.Document."Service Header")
    begin
        OnAfterInitFromServiceDocument(NoTaxableEntry, ServiceHeader);
    end;

    [Obsolete('Moved to codeunit Serv. No Taxable Management', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromServiceDocument(var NoTaxableEntry: Record "No Taxable Entry"; ServiceHeader: Record Microsoft.Service.Document."Service Header")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromVendorEntry(var NoTaxableEntry: Record "No Taxable Entry"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;
}

