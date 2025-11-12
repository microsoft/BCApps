// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.IO;

using Microsoft.Bank.Reconciliation;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using System.Utilities;

codeunit 1217 "Pre-map Incoming Purch. Doc"
{
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        BuyFromVendorNo: Code[20];
        PayToVendorNo: Code[20];
        ParentRecNo: Integer;
        CurrRecNo: Integer;
    begin
        ParentRecNo := 0;
        FindDistinctRecordNos(TempIntegerHeaderRecords, Rec."Entry No.", DATABASE::"Purchase Header", ParentRecNo);
        if not TempIntegerHeaderRecords.FindSet() then
            exit;

        repeat
            CurrRecNo := TempIntegerHeaderRecords.Number;

            ValidateCompanyInfo(Rec."Entry No.", CurrRecNo);
            ValidateCurrency(Rec."Entry No.", CurrRecNo);
            SetDocumentType(Rec."Entry No.", ParentRecNo, CurrRecNo);

            CorrectHeaderData(Rec."Entry No.", CurrRecNo);
            BuyFromVendorNo := FindBuyFromVendor(Rec."Entry No.", CurrRecNo);
            PayToVendorNo := FindPayToVendor(Rec."Entry No.", CurrRecNo);
            FindInvoiceToApplyTo(Rec."Entry No.", CurrRecNo);

            PersistHeaderData(Rec."Entry No.", CurrRecNo, BuyFromVendorNo, PayToVendorNo);

            ProcessLines(Rec."Entry No.", CurrRecNo, BuyFromVendorNo);
        until TempIntegerHeaderRecords.Next() = 0;
    end;

    var
        InvalidCompanyInfoGLNErr: Label 'The customer''s GLN %1 on the incoming document does not match the GLN in the Company Information window.', Comment = '%1 = GLN (13 digit number)';
        InvalidCompanyInfoVATRegNoErr: Label 'The customer''s VAT registration number %1 on the incoming document does not match the VAT Registration No. in the Company Information window.', Comment = '%1 VAT Registration Number (format could be AB###### or ###### or AB##-##-###)';
        CurrencyCodeMissingErr: Label 'The currency code is missing on the incoming document.';
        CurrencyCodeDifferentErr: Label 'The currency code %1 must not be different from the currency code %2 on the incoming document.', Comment = '%1 currency code (e.g. GBP), %2 the document currency code (e.g. DKK)';
        ItemCurrencyCodeDifferentErr: Label 'The currency code %1 on invoice line no. %2 must not be different from the currency code %3 on the incoming document.', Comment = '%1 Invoice line currency code (e.g. GBP), %2 invoice line no. (e.g. 2), %3 document currency code (e.g. DKK)';
        BuyFromVendorNotFoundErr: Label 'Cannot find buy-from vendor ''%1'' based on the vendor''s GLN %2 or VAT registration number %3 on the incoming document. Make sure that a card for the vendor exists with the corresponding GLN or VAT Registration No.', Comment = '%1 Vendor name (e.g. London Postmaster), %2 Vendor''s GLN (13 digit number), %3 Vendor''s VAT Registration Number';
        PayToVendorNotFoundErr: Label 'Cannot find pay-to vendor ''%1'' based on the vendor''s GLN %2 or VAT registration number %3 on the incoming document. Make sure that a card for the vendor exists with the corresponding GLN or VAT Registration No.', Comment = '%1 Vendor name (e.g. London Postmaster), %2 Vendor''s GLN (13 digit number), %3 Vendor''s VAT Registration Number';
        ItemNotFoundErr: Label 'Cannot find item ''%1'' based on the vendor %2 item number %3 or GTIN %4 on the incoming document. Make sure that a card for the item exists with the corresponding item reference or GTIN.', Comment = '%1 Vendor item name (e.g. Bicycle - may be another language),%2 Vendor''''s number,%3 Vendor''''s item number, %4 item bar code (GTIN)';
        ItemNotFoundByGTINErr: Label 'Cannot find item ''%1'' based on GTIN %2 on the incoming document. Make sure that a card for the item exists with the corresponding GTIN.', Comment = '%1 Vendor item name (e.g. Bicycle - may be another language),%2 item bar code (GTIN)';
        ItemNotFoundByVendorItemNoErr: Label 'Cannot find item ''%1'' based on the vendor %2 item number %3 on the incoming document. Make sure that a card for the item exists with the corresponding item reference.', Comment = '%1 Vendor item name (e.g. Bicycle - may be another language),%2 Vendor''''s number,%3 Vendor''''s item number';
        UOMNotFoundErr: Label 'Cannot find unit of measure %1. Make sure that the unit of measure exists.', Comment = '%1 International Standard Code or Code or Description for Unit of Measure';
        UOMMissingErr: Label 'Cannot find a unit of measure code on the incoming document line %1.', Comment = '%1 document line number (e.g. 2)';
        UOMConflictWithItemRefErr: Label 'Unit of measure %1 on incoming document line %2 does not match unit of measure %3 in the item reference.  Make sure that a card for the item with the specified unit of measure exists with the corresponding item reference.', Comment = '%1 imported unit code, %2 document line number (e.g. 2), %3 Item Reference unit code';
        UOMConflictWithItemErr: Label 'Unit of measure %1 on incoming document line %2 does not match purchase unit of measure %3 on the item card.  Make sure that a card for the item with the specified unit of measure exists with the corresponding item reference.', Comment = '%1 imported unit code, %2 document line number (e.g. 2), %3 Item unit code';
        UOMConflictItemRefWithItemErr: Label 'Unit of measure %1 in the item reference is not in the list of units of measure for the corresponding item. Make sure that a unit of measure of item reference is in the list of units of measure for the corresponding item.', Comment = '%1 item reference unit code';
        NotSpecifiedUnitOfMeasureTxt: Label '<NONE>';
        MissingCompanyInfoSetupErr: Label 'You must fill either GLN or VAT Registration No. in the Company Information window.';
#pragma warning disable AA0470
        VendorNotFoundByNameAndAddressErr: Label 'Cannot find vendor based on the vendor''s name ''%1'' and street name ''%2'' on the incoming document. Make sure that a card for the vendor exists with the corresponding name.';
#pragma warning restore AA0470
        InvalidCompanyInfoNameErr: Label 'The customer name ''%1'' on the incoming document does not match the name in the Company Information window.', Comment = '%1 = customer name';
        InvalidCompanyInfoAddressErr: Label 'The customer''s address ''%1'' on the incoming document does not match the Address in the Company Information window.', Comment = '%1 = customer address, street name';
        TempIntegerHeaderRecords: Record "Integer" temporary;
        TempIntegerLineRecords: Record "Integer" temporary;
        FieldMustHaveAValueErr: Label 'You must specify a value for field ''%1''.', Comment = '%1 - field caption';
        DocumentTypeUnknownErr: Label 'You must make a new entry in the %1 of the %2 window, and enter ''%3'' or ''%4'' in the %5 field. Then, you must map it to the %6 field in the %7 table.', Comment = '%1 - Column Definitions (page caption),%2 - Data Exchange Definition (page caption),%3 - invoice (option caption),%4 - credit memo (option caption),%5 - Constant (field name),%6 - Document Type (field caption),%7 - Purchase Header (table caption)';
        YouMustFirstPostTheRelatedInvoiceErr: Label 'The incoming document references invoice %1 from the vendor. You must post related purchase invoice %2 before you create a new purchase document from this incoming document.', Comment = '%1 - vendor invoice no.,%2 posted purchase invoice no.';
        UnableToFindRelatedInvoiceErr: Label 'The incoming document references invoice %1 from the vendor, but no purchase invoice exists for %1.', Comment = '%1 - vendor invoice no.';
        UnableToFindTotalAmountErr: Label 'The incoming document has no total amount excluding VAT.';
        UnableToFindAppropriateAccountErr: Label 'Cannot find an appropriate G/L account for the line with description ''%1''. Choose the Map Text to Account button, and then map the core part of ''%1'' to the relevant G/L account.', Comment = '%1 - arbitrary text';

    local procedure ValidateCompanyInfo(EntryNo: Integer; RecordNo: Integer)
    var
        IntermediateDataImport: Record "Intermediate Data Import";
        CompanyInformation: Record "Company Information";
        DataExch: Record "Data Exch.";
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        GLN: Text;
        VatRegNo: Text;
        VatRegNoFound: Boolean;
    begin
        // for OCRed invoices, we don't check the buyer's information
        DataExch.Get(EntryNo);
        IncomingDocument.Get(DataExch."Incoming Entry No.");
        if IncomingDocument.GetGeneratedFromOCRAttachment(IncomingDocumentAttachment) then
            exit;

        CompanyInformation.Get();
        if IntermediateDataImport.FindEntry(EntryNo, DATABASE::"Company Information", CompanyInformation.FieldNo("VAT Registration No."), 0, RecordNo) then
            VatRegNo := IntermediateDataImport.Value;

        IntermediateDataImport.SetRange("Field ID", CompanyInformation.FieldNo(GLN));
        if IntermediateDataImport.FindFirst() then
            GLN := IntermediateDataImport.Value;

        if (GLN = '') and (VatRegNo = '') then begin
            ValidateCompanyInfoByNameAndAddress(EntryNo, RecordNo);
            exit;
        end;

        if (CompanyInformation.GLN = '') and (CompanyInformation."VAT Registration No." = '') then
            LogErrorMessage(EntryNo, CompanyInformation, CompanyInformation.FieldNo(GLN), MissingCompanyInfoSetupErr);

        if CompanyInformation.GLN <> '' then begin
            IntermediateDataImport.SetFilter(Value, StrSubstNo('<>%1&<>%2', CompanyInformation.GLN, ''''''));
            if IntermediateDataImport.FindLast() then
                LogErrorMessage(EntryNo, CompanyInformation, CompanyInformation.FieldNo(GLN),
                  StrSubstNo(InvalidCompanyInfoGLNErr, GLN));
        end;

        if CompanyInformation."VAT Registration No." <> '' then begin
            IntermediateDataImport.SetRange("Field ID", CompanyInformation.FieldNo("VAT Registration No."));
            IntermediateDataImport.SetFilter(Value, StrSubstNo('<>%1', ''''''));

            if IntermediateDataImport.FindSet() then begin
                repeat
                    VatRegNoFound := ExtractVatRegNo(IntermediateDataImport.Value, '') = ExtractVatRegNo(CompanyInformation."VAT Registration No.", '');
                until (IntermediateDataImport.Next() = 0) or VatRegNoFound;
                if not VatRegNoFound then
                    LogErrorMessage(EntryNo, CompanyInformation, CompanyInformation.FieldNo("VAT Registration No."),
                      StrSubstNo(InvalidCompanyInfoVATRegNoErr, VatRegNo));
            end;
        end;
    end;

    local procedure ValidateCompanyInfoByNameAndAddress(EntryNo: Integer; RecordNo: Integer)
    var
        IntermediateDataImport: Record "Intermediate Data Import";
        CompanyInfo: Record "Company Information";
        RecordMatchMgt: Codeunit "Record Match Mgt.";
        ImportedAddress: Text;
        ImportedName: Text;
        CompanyName: Text;
        CompanyAddr: Text;
        NameNearness: Integer;
        AddressNearness: Integer;
    begin
        CompanyInfo.Get();
        CompanyName := CompanyInfo.Name;
        CompanyAddr := CompanyInfo.Address;
        if IntermediateDataImport.FindEntry(EntryNo, DATABASE::"Company Information", CompanyInfo.FieldNo(Name), 0, RecordNo) then
            ImportedName := IntermediateDataImport.Value;

        NameNearness := RecordMatchMgt.CalculateStringNearness(CompanyName, ImportedName, MatchThreshold(), NormalizingFactor());

        IntermediateDataImport.SetRange("Field ID", CompanyInfo.FieldNo(Address));
        if IntermediateDataImport.FindFirst() then
            ImportedAddress := IntermediateDataImport.Value;

        AddressNearness := RecordMatchMgt.CalculateStringNearness(CompanyAddr, ImportedAddress, MatchThreshold(), NormalizingFactor());

        if (ImportedName <> '') and (NameNearness < RequiredNearness()) then
            LogErrorMessage(EntryNo, CompanyInfo, CompanyInfo.FieldNo(Name), StrSubstNo(InvalidCompanyInfoNameErr, ImportedName));

        if (ImportedAddress <> '') and (AddressNearness < RequiredNearness()) then
            LogErrorMessage(EntryNo, CompanyInfo, CompanyInfo.FieldNo(Address), StrSubstNo(InvalidCompanyInfoAddressErr, ImportedAddress));
    end;

    local procedure ValidateCurrency(EntryNo: Integer; RecordNo: Integer)
    var
        IntermediateDataImport: Record "Intermediate Data Import";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLSetup: Record "General Ledger Setup";
        DocumentCurrency: Text;
        IsLCY: Boolean;
    begin
        GLSetup.Get();
        if GLSetup."LCY Code" = '' then
            LogErrorMessage(EntryNo, GLSetup, GLSetup.FieldNo("LCY Code"),
              StrSubstNo(FieldMustHaveAValueErr, GLSetup.FieldCaption("LCY Code")));

        DocumentCurrency := IntermediateDataImport.GetEntryValue(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Currency Code"), 0, RecordNo);
        if DocumentCurrency = '' then begin
            LogSimpleErrorMessage(EntryNo, CurrencyCodeMissingErr);
            exit;
        end;

        IsLCY := DocumentCurrency = GLSetup."LCY Code";
        // If LCY Currency wont be in Currency table
        if IsLCY then begin
            // Update Document Currency
            IntermediateDataImport.Value := '';
            IntermediateDataImport.Modify();
        end;
        // Ensure the currencies all match the same document currency
        IntermediateDataImport.SetRange("Field ID", PurchaseHeader.FieldNo("Tax Area Code"));
        IntermediateDataImport.SetFilter(Value, '<>%1', DocumentCurrency);
        if IntermediateDataImport.FindFirst() then
            LogSimpleErrorMessage(EntryNo, StrSubstNo(CurrencyCodeDifferentErr, IntermediateDataImport.Value, DocumentCurrency));
        // Clear the additional currency values on header
        IntermediateDataImport.SetRange(Value);
        IntermediateDataImport.DeleteAll();
        // check currency on the lines
        IntermediateDataImport.SetRange("Table ID", DATABASE::"Purchase Line");
        IntermediateDataImport.SetRange("Field ID", PurchaseLine.FieldNo("Currency Code"));
        IntermediateDataImport.SetRange("Record No.");
        IntermediateDataImport.SetRange("Parent Record No.", RecordNo);
        IntermediateDataImport.SetFilter(Value, '<>%1', DocumentCurrency);
        if IntermediateDataImport.FindFirst() then
            LogSimpleErrorMessage(EntryNo, StrSubstNo(ItemCurrencyCodeDifferentErr, IntermediateDataImport.Value, IntermediateDataImport."Record No.", DocumentCurrency));
        // Clear the additional currency values on lines
        IntermediateDataImport.SetRange(Value);
        IntermediateDataImport.DeleteAll();
    end;

    local procedure ProcessLines(EntryNo: Integer; HeaderRecordNo: Integer; VendorNo: Code[20])
    var
        DataExch: Record "Data Exch.";
        IncomingDocument: Record "Incoming Document";
    begin
        DataExch.Get(EntryNo);
        IncomingDocument.Get(DataExch."Incoming Entry No.");
        if IncomingDocument."Document Type" = IncomingDocument."Document Type"::Journal then
            exit;

        FindDistinctRecordNos(TempIntegerLineRecords, EntryNo, DATABASE::"Purchase Line", HeaderRecordNo);
        if not TempIntegerLineRecords.FindSet() then begin
            InsertLineForTotalDocumentAmount(EntryNo, HeaderRecordNo, 1, VendorNo);
            exit;
        end;

        repeat
            ProcessLine(EntryNo, HeaderRecordNo, TempIntegerLineRecords.Number, VendorNo);
        until TempIntegerLineRecords.Next() = 0;
    end;

    local procedure CorrectHeaderData(EntryNo: Integer; RecordNo: Integer)
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        IncomingDocument: Record "Incoming Document";
        DataExch: Record "Data Exch.";
        PurchaseHeader: Record "Purchase Header";
        GLEntry: Record "G/L Entry";
    begin
        DataExch.Get(EntryNo);
        IncomingDocument.Get(DataExch."Incoming Entry No.");
        if IncomingDocument."OCR Data Corrected" then begin
            CorrectHeaderField(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor Name"), RecordNo,
              IncomingDocument."Vendor Name");
            CorrectHeaderField(EntryNo, DATABASE::Vendor, Vendor.FieldNo("VAT Registration No."), RecordNo,
              IncomingDocument."Vendor VAT Registration No.");
            CorrectHeaderField(EntryNo, DATABASE::"Vendor Bank Account", VendorBankAccount.FieldNo(IBAN), RecordNo,
              IncomingDocument."Vendor IBAN");
            CorrectHeaderField(EntryNo, DATABASE::"Vendor Bank Account", VendorBankAccount.FieldNo("Bank Account No."), RecordNo,
              IncomingDocument."Vendor Bank Account No.");
            CorrectHeaderField(EntryNo, DATABASE::"Vendor Bank Account", VendorBankAccount.FieldNo("Bank Branch No."), RecordNo,
              IncomingDocument."Vendor Bank Branch No.");
            CorrectHeaderField(EntryNo, DATABASE::Vendor, Vendor.FieldNo("Phone No."), RecordNo,
              IncomingDocument."Vendor Phone No.");
            CorrectHeaderField(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Vendor Invoice No."), RecordNo,
              IncomingDocument."Vendor Invoice No.");
            CorrectHeaderField(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Document Date"), RecordNo,
              IncomingDocument."Document Date");
            CorrectHeaderField(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Due Date"), RecordNo,
              IncomingDocument."Due Date");
            CorrectCurrencyCode(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Currency Code"), RecordNo,
              IncomingDocument."Currency Code");
            CorrectHeaderField(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo(Amount), RecordNo,
              IncomingDocument."Amount Excl. VAT");
            CorrectHeaderField(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Amount Including VAT"), RecordNo,
              IncomingDocument."Amount Incl. VAT");
            CorrectHeaderField(EntryNo, DATABASE::"G/L Entry", GLEntry.FieldNo("VAT Amount"), RecordNo,
              IncomingDocument."VAT Amount");
            CorrectHeaderField(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Vendor Order No."), RecordNo,
              IncomingDocument."Order No.");
        end;
        OnAfterCorrectHeaderData(EntryNo, RecordNo, DataExch, IncomingDocument);
    end;

    procedure CorrectHeaderField(EntryNo: Integer; TableID: Integer; FieldID: Integer; RecordNo: Integer; IncomingDocumentValue: Variant)
    var
        IntermediateDataImport: Record "Intermediate Data Import";
        ExistingValue: Text;
        CorrectedValue: Text[250];
    begin
        if CheckDataExchMappingNotExist(EntryNo, TableID, FieldID) then
            exit;

        ExistingValue := IntermediateDataImport.GetEntryValue(EntryNo, TableID, FieldID, 0, RecordNo);
        CorrectedValue := CopyStr(Format(IncomingDocumentValue, 0, 9), 1, MaxStrLen(CorrectedValue));
        if CorrectedValue <> ExistingValue then
            IntermediateDataImport.InsertOrUpdateEntry(EntryNo, TableID, FieldID, 0, RecordNo, CorrectedValue);
    end;

    local procedure CheckDataExchMappingNotExist(EntryNo: Integer; TableID: Integer; FieldID: Integer): Boolean
    var
        DataExch: Record "Data Exch.";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        DataExch.Get(EntryNo);
        DataExchMapping.SetRange("Data Exch. Def Code", DataExch."Data Exch. Def Code");
        DataExchMapping.SetRange("Data Exch. Line Def Code", DataExch."Data Exch. Line Def Code");
        if DataExchMapping.FindSet() then
            repeat
                DataExchFieldMapping.SetRange("Data Exch. Def Code", DataExch."Data Exch. Def Code");
                DataExchFieldMapping.SetRange("Data Exch. Line Def Code", DataExch."Data Exch. Line Def Code");
                DataExchFieldMapping.SetRange("Target Table ID", TableID);
                DataExchFieldMapping.SetRange("Target Field ID", FieldID);
                if DataExchFieldMapping.IsEmpty() then
                    exit(true);
            until DataExchMapping.Next() = 0;
    end;

    local procedure CorrectCurrencyCode(EntryNo: Integer; TableID: Integer; FieldID: Integer; RecordNo: Integer; IncomingDocumentValue: Variant)
    var
        IntermediateDataImport: Record "Intermediate Data Import";
        GeneralLedgerSetup: Record "General Ledger Setup";
        ExistingValue: Text;
        CorrectedValue: Text[250];
    begin
        ExistingValue := IntermediateDataImport.GetEntryValue(EntryNo, TableID, FieldID, 0, RecordNo);
        CorrectedValue := CopyStr(Format(IncomingDocumentValue, 0, 9), 1, MaxStrLen(CorrectedValue));
        GeneralLedgerSetup.Get();
        if (CorrectedValue <> ExistingValue) and ((CorrectedValue <> GeneralLedgerSetup."LCY Code") or (ExistingValue <> '')) then
            IntermediateDataImport.InsertOrUpdateEntry(EntryNo, TableID, FieldID, 0, RecordNo, CorrectedValue);
    end;

    local procedure PersistHeaderData(EntryNo: Integer; RecordNo: Integer; BuyFromVendorNo: Code[20]; PayToVendorNo: Code[20])
    var
        IntermediateDataImport: Record "Intermediate Data Import";
        DataExch: Record "Data Exch.";
        IncomingDocument: Record "Incoming Document";
        PurchaseHeader: Record "Purchase Header";
        VendorBankAccount: Record "Vendor Bank Account";
        Vendor: Record Vendor;
        GLEntry: Record "G/L Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        AmountInclVAT: Decimal;
        AmountExclVAT: Decimal;
        VATAmount: Decimal;
        TextValue: Text[250];
        Date: Date;
    begin
        DataExch.Get(EntryNo);
        IncomingDocument.Get(DataExch."Incoming Entry No.");

        if PayToVendorNo <> '' then
            IncomingDocument.Validate("Vendor No.", PayToVendorNo)
        else
            IncomingDocument.Validate("Vendor No.", BuyFromVendorNo);

        Evaluate(
          TextValue, IntermediateDataImport.GetEntryValue(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor Name"), 0, RecordNo));
        IncomingDocument.Validate("Vendor Name", CopyStr(TextValue, 1, MaxStrLen(IncomingDocument."Vendor Name")));

        TextValue := IntermediateDataImport.GetEntryValue(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Amount Including VAT"), 0, RecordNo);
        if TextValue <> '' then
            Evaluate(AmountInclVAT, TextValue, 9);
        IncomingDocument.Validate("Amount Incl. VAT", AmountInclVAT);

        TextValue := IntermediateDataImport.GetEntryValue(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo(Amount), 0, RecordNo);
        if TextValue <> '' then
            Evaluate(AmountExclVAT, TextValue, 9);
        IncomingDocument.Validate("Amount Excl. VAT", AmountExclVAT);

        TextValue := IntermediateDataImport.GetEntryValue(EntryNo, DATABASE::"G/L Entry", GLEntry.FieldNo("VAT Amount"), 0, RecordNo);
        if TextValue <> '' then
            Evaluate(VATAmount, TextValue, 9);
        IncomingDocument.Validate("VAT Amount", VATAmount);

        if IntermediateDataImport.GetEntryValue(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Document Type"), 0, RecordNo) =
           Format(PurchaseHeader."Document Type"::Invoice, 0, 9)
        then
            Evaluate(TextValue, IntermediateDataImport.GetEntryValue(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Vendor Invoice No."), 0, RecordNo))
        else
            Evaluate(
              TextValue, IntermediateDataImport.GetEntryValue(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Vendor Cr. Memo No."), 0, RecordNo));

        IncomingDocument.Validate("Vendor Invoice No.", CopyStr(TextValue, 1, MaxStrLen(IncomingDocument."Vendor Invoice No.")));

        Evaluate(TextValue, IntermediateDataImport.GetEntryValue(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Vendor Order No."), 0, RecordNo));
        IncomingDocument.Validate("Order No.", CopyStr(TextValue, 1, MaxStrLen(IncomingDocument."Order No.")));

        Evaluate(Date, IntermediateDataImport.GetEntryValue(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Document Date"), 0, RecordNo), 9);
        IncomingDocument.Validate("Document Date", Date);

        Evaluate(Date, IntermediateDataImport.GetEntryValue(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Due Date"), 0, RecordNo), 9);
        IncomingDocument.Validate("Due Date", Date);

        Evaluate(TextValue, IntermediateDataImport.GetEntryValue(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Currency Code"), 0, RecordNo));
        GeneralLedgerSetup.Get();
        if (TextValue <> '') or (IncomingDocument."Currency Code" <> GeneralLedgerSetup."LCY Code") then
            IncomingDocument."Currency Code" := CopyStr(TextValue, 1, MaxStrLen(IncomingDocument."Currency Code"));

        Evaluate(TextValue, IntermediateDataImport.GetEntryValue(EntryNo, DATABASE::Vendor, Vendor.FieldNo("VAT Registration No."), 0, RecordNo));
        IncomingDocument.Validate("Vendor VAT Registration No.",
          CopyStr(TextValue, 1, MaxStrLen(IncomingDocument."Vendor VAT Registration No.")));

        Evaluate(TextValue, IntermediateDataImport.GetEntryValue(EntryNo, DATABASE::"Vendor Bank Account", VendorBankAccount.FieldNo(IBAN), 0, RecordNo));
        IncomingDocument.Validate("Vendor IBAN", CopyStr(TextValue, 1, MaxStrLen(IncomingDocument."Vendor IBAN")));

        Evaluate(
          TextValue, IntermediateDataImport.GetEntryValue(EntryNo, DATABASE::"Vendor Bank Account", VendorBankAccount.FieldNo("Bank Branch No."), 0, RecordNo));
        IncomingDocument.Validate("Vendor Bank Branch No.", CopyStr(TextValue, 1, MaxStrLen(IncomingDocument."Vendor Bank Branch No.")));

        Evaluate(
          TextValue, IntermediateDataImport.GetEntryValue(EntryNo, DATABASE::Vendor, Vendor.FieldNo("Phone No."), 0, RecordNo));
        IncomingDocument.Validate("Vendor Phone No.", CopyStr(TextValue, 1, MaxStrLen(IncomingDocument."Vendor Phone No.")));

        Evaluate(
          TextValue, IntermediateDataImport.GetEntryValue(EntryNo, DATABASE::"Vendor Bank Account", VendorBankAccount.FieldNo("Bank Account No."), 0, RecordNo));
        IncomingDocument.Validate("Vendor Bank Account No.",
          CopyStr(TextValue, 1, MaxStrLen(IncomingDocument."Vendor Bank Account No.")));

        IncomingDocument.Modify();
    end;

    local procedure FindBuyFromVendor(EntryNo: Integer; RecordNo: Integer): Code[20]
    var
        IntermediateDataImport: Record "Intermediate Data Import";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        EmptyVendor: Record Vendor;
        IncomingDocument: Record "Incoming Document";
        DataExch: Record "Data Exch.";
        GLN: Text;
        BuyFromName: Text;
        BuyFromAddress: Text;
        BuyFromPhoneNo: Text;
        VatRegNo: Text;
        VendorIdText: Text;
        VendorNoText: Text;
        VendorNo: Code[20];
    begin
        VendorIdText := IntermediateDataImport.GetEntryValue(EntryNo, DATABASE::Vendor, Vendor.FieldNo(SystemId), 0, RecordNo);
        VendorNo := FindVendorById(EntryNo, RecordNo, PurchaseHeader.FieldNo("Buy-from Vendor No."), VendorIdText);
        if VendorNo <> '' then
            exit(VendorNo);

        VendorNoText := IntermediateDataImport.GetEntryValue(EntryNo, DATABASE::Vendor, Vendor.FieldNo("No."), 0, RecordNo);
        VendorNo := FindVendorByNo(EntryNo, RecordNo, PurchaseHeader.FieldNo("Buy-from Vendor No."), VendorNoText);
        if VendorNo <> '' then
            exit(VendorNo);

        BuyFromPhoneNo := IntermediateDataImport.GetEntryValue(EntryNo, DATABASE::Vendor, Vendor.FieldNo("Phone No."), 0, RecordNo);

        if IntermediateDataImport.FindEntry(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor Name"), 0, RecordNo) then
            BuyFromName := IntermediateDataImport.Value;

        IntermediateDataImport.SetRange("Field ID", PurchaseHeader.FieldNo("Buy-from Address"));
        if IntermediateDataImport.FindFirst() then
            BuyFromAddress := IntermediateDataImport.Value;
        // Lookup GLN
        IntermediateDataImport.SetRange("Field ID", PurchaseHeader.FieldNo("Buy-from Vendor No."));
        if IntermediateDataImport.FindFirst() then
            if IntermediateDataImport.Value <> '' then begin
                GLN := IntermediateDataImport.Value;
                Vendor.SetCurrentKey(Blocked);
                Vendor.SetRange(GLN, IntermediateDataImport.Value);
                if Vendor.FindFirst() then begin
                    IntermediateDataImport.InsertOrUpdateEntry(EntryNo, DATABASE::"Purchase Header",
                      PurchaseHeader.FieldNo("Buy-from Vendor No."), 0, RecordNo, Vendor."No.");
                    exit(Vendor."No.");
                end;
            end;

        Vendor.Reset();
        Vendor.SetCurrentKey(Blocked);
        VatRegNo := '';
        // Lookup VAT Reg No
        IntermediateDataImport.SetRange("Table ID", DATABASE::Vendor);
        IntermediateDataImport.SetRange("Field ID", Vendor.FieldNo("VAT Registration No."));

        if IntermediateDataImport.FindFirst() then begin
            if (IntermediateDataImport.Value = '') and (GLN = '') then begin
                VendorNo := FindVendorByBankAccount(EntryNo, RecordNo, PurchaseHeader.FieldNo("Buy-from Vendor No."));
                if VendorNo <> '' then
                    exit(VendorNo);
                VendorNo := FindVendorByPhoneNo(EntryNo, RecordNo, PurchaseHeader.FieldNo("Buy-from Vendor No."), BuyFromPhoneNo);
                if VendorNo <> '' then
                    exit(VendorNo);
                exit(FindVendorByNameAndAddress(EntryNo, RecordNo, BuyFromName, BuyFromAddress,
                    PurchaseHeader.FieldNo("Buy-from Vendor No.")));
            end;
            VatRegNo := IntermediateDataImport.Value;
            if IntermediateDataImport.Value <> '' then begin
                Vendor.SetFilter("VAT Registration No.",
                  StrSubstNo('*%1', CopyStr(IntermediateDataImport.Value, StrLen(IntermediateDataImport.Value))));
                if Vendor.FindSet() then
                    repeat
                        if ExtractVatRegNo(Vendor."VAT Registration No.", Vendor."Country/Region Code") =
                           ExtractVatRegNo(IntermediateDataImport.Value, Vendor."Country/Region Code")
                        then begin
                            IntermediateDataImport.InsertOrUpdateEntry(EntryNo, DATABASE::"Purchase Header",
                              PurchaseHeader.FieldNo("Buy-from Vendor No."), 0, RecordNo, Vendor."No.");

                            exit(Vendor."No.");
                        end;
                    until Vendor.Next() = 0;
            end;
        end;

        if (VatRegNo = '') and (GLN = '') then begin
            VendorNo := FindVendorByBankAccount(EntryNo, RecordNo, PurchaseHeader.FieldNo("Buy-from Vendor No."));
            if VendorNo <> '' then
                exit(VendorNo);
            VendorNo := FindVendorByPhoneNo(EntryNo, RecordNo, PurchaseHeader.FieldNo("Buy-from Vendor No."), BuyFromPhoneNo);
            if VendorNo <> '' then
                exit(VendorNo);
            exit(FindVendorByNameAndAddress(EntryNo, RecordNo, BuyFromName, BuyFromAddress,
                PurchaseHeader.FieldNo("Buy-from Vendor No.")));
        end;

        DataExch.Get(EntryNo);
        IncomingDocument.Get(DataExch."Incoming Entry No.");
        if IncomingDocument."Document Type" <> IncomingDocument."Document Type"::Journal then
            LogErrorMessage(EntryNo, EmptyVendor, EmptyVendor.FieldNo(Name),
              StrSubstNo(BuyFromVendorNotFoundErr, BuyFromName, GLN, VatRegNo));
        exit('');
    end;

    local procedure FindPayToVendor(EntryNo: Integer; RecordNo: Integer): Code[20]
    var
        IntermediateDataImport: Record "Intermediate Data Import";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        EmptyVendor: Record Vendor;
        IncomingDocument: Record "Incoming Document";
        DataExch: Record "Data Exch.";
        GLN: Text;
        VatRegNo: Text;
        PayToName: Text;
        PayToAddress: Text;
    begin
        if IntermediateDataImport.FindEntry(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Pay-to Name"), 0, RecordNo) then
            PayToName := IntermediateDataImport.Value;

        IntermediateDataImport.SetRange("Field ID", PurchaseHeader.FieldNo("Pay-to Address"));
        if IntermediateDataImport.FindFirst() then
            PayToAddress := IntermediateDataImport.Value;

        IntermediateDataImport.SetRange("Field ID", PurchaseHeader.FieldNo("VAT Registration No."));
        if IntermediateDataImport.FindFirst() then
            VatRegNo := IntermediateDataImport.Value;

        IntermediateDataImport.SetRange("Field ID", PurchaseHeader.FieldNo("Pay-to Vendor No."));
        if IntermediateDataImport.FindFirst() then
            GLN := IntermediateDataImport.Value;

        if (VatRegNo = '') and (GLN = '') then begin
            if PayToName <> '' then
                exit(FindVendorByNameAndAddress(EntryNo, RecordNo, PayToName, PayToAddress, PurchaseHeader.FieldNo("Pay-to Vendor No.")));
            exit;
        end;
        // Lookup GLN
        if GLN <> '' then begin
            Vendor.SetCurrentKey(Blocked);
            Vendor.SetRange(GLN, GLN);
            if Vendor.FindFirst() then begin
                IntermediateDataImport.InsertOrUpdateEntry(EntryNo, DATABASE::"Purchase Header",
                  PurchaseHeader.FieldNo("Pay-to Vendor No."), 0, RecordNo, Vendor."No.");

                exit(Vendor."No.");
            end;
        end;

        Vendor.Reset();
        Vendor.SetCurrentKey(Blocked);
        // Lookup VAT Reg No
        Vendor.SetLoadFields("VAT Registration No.", "Country/Region Code");
        Vendor.SetFilter("VAT Registration No.", StrSubstNo('*%1', CopyStr(VatRegNo, StrLen(VatRegNo))));
        if Vendor.FindSet() then
            repeat
                if ExtractVatRegNo(Vendor."VAT Registration No.", Vendor."Country/Region Code") =
                   ExtractVatRegNo(VatRegNo, Vendor."Country/Region Code")
                then begin
                    IntermediateDataImport.InsertOrUpdateEntry(EntryNo, DATABASE::"Purchase Header",
                      PurchaseHeader.FieldNo("Pay-to Vendor No."), 0, RecordNo, Vendor."No.");

                    exit(Vendor."No.");
                end;
            until Vendor.Next() = 0;

        DataExch.Get(EntryNo);
        IncomingDocument.Get(DataExch."Incoming Entry No.");
        if IncomingDocument."Document Type" <> IncomingDocument."Document Type"::Journal then
            LogErrorMessage(EntryNo, EmptyVendor, EmptyVendor.FieldNo(Name),
              StrSubstNo(PayToVendorNotFoundErr, PayToName, GLN, VatRegNo));
        exit('');
    end;

    local procedure FindVendorByNameAndAddress(EntryNo: Integer; RecordNo: Integer; VendorName: Text; VendorAddress: Text; FieldID: Integer): Code[20]
    var
        IntermediateDataImport: Record "Intermediate Data Import";
        Vendor: Record Vendor;
        EmptyVendor: Record Vendor;
        IncomingDocument: Record "Incoming Document";
        DataExch: Record "Data Exch.";
        RecordMatchMgt: Codeunit "Record Match Mgt.";
        NameNearness: Integer;
        AddressNearness: Integer;
    begin
        Vendor.SetCurrentKey(Blocked);
        Vendor.SetLoadFields(Name, Address);
        if Vendor.FindSet() then
            repeat
                NameNearness := RecordMatchMgt.CalculateStringNearness(VendorName, Vendor.Name, MatchThreshold(), NormalizingFactor());
                if VendorAddress = '' then
                    AddressNearness := RequiredNearness()
                else
                    AddressNearness := RecordMatchMgt.CalculateStringNearness(VendorAddress, Vendor.Address, MatchThreshold(), NormalizingFactor());
                if (NameNearness >= RequiredNearness()) and (AddressNearness >= RequiredNearness()) then begin
                    IntermediateDataImport.InsertOrUpdateEntry(EntryNo, DATABASE::"Purchase Header", FieldID, 0, RecordNo, Vendor."No.");
                    exit(Vendor."No.");
                end;
            until Vendor.Next() = 0;

        DataExch.Get(EntryNo);
        IncomingDocument.Get(DataExch."Incoming Entry No.");
        if IncomingDocument."Document Type" <> IncomingDocument."Document Type"::Journal then
            LogErrorMessage(EntryNo, EmptyVendor, EmptyVendor.FieldNo(Name),
              StrSubstNo(VendorNotFoundByNameAndAddressErr, VendorName, VendorAddress));
        exit('');
    end;

    local procedure FindVendorByBankAccount(EntryNo: Integer; RecordNo: Integer; FieldID: Integer): Code[20]
    var
        IntermediateDataImport: Record "Intermediate Data Import";
        VendorBankAccount: Record "Vendor Bank Account";
        VendorNo: Code[20];
        VendorIBAN: Code[50];
        VendorBankBranchNo: Text[20];
        VendorBankAccountNo: Text[30];
    begin
        if IntermediateDataImport.FindEntry(EntryNo, DATABASE::"Vendor Bank Account", VendorBankAccount.FieldNo(IBAN), 0, RecordNo) then
            VendorIBAN := CopyStr(IntermediateDataImport.Value, 1, MaxStrLen(VendorIBAN));

        IntermediateDataImport.SetRange("Field ID", VendorBankAccount.FieldNo("Bank Branch No."));
        if IntermediateDataImport.FindFirst() then
            VendorBankBranchNo := CopyStr(IntermediateDataImport.Value, 1, MaxStrLen(VendorBankBranchNo));

        IntermediateDataImport.SetRange("Field ID", VendorBankAccount.FieldNo("Bank Account No."));
        if IntermediateDataImport.FindFirst() then
            VendorBankAccountNo := CopyStr(IntermediateDataImport.Value, 1, MaxStrLen(VendorBankAccountNo));

        if VendorIBAN <> '' then begin
            VendorBankAccount.SetRange(IBAN, VendorIBAN);
            VendorNo := TryFindLeastBlockedVendorNoByVendorBankAcc(VendorBankAccount);
        end;

        if (VendorNo = '') and (VendorBankBranchNo <> '') and (VendorBankAccountNo <> '') then begin
            VendorBankAccount.Reset();
            VendorBankAccount.SetRange("Bank Branch No.", VendorBankBranchNo);
            VendorBankAccount.SetRange("Bank Account No.", VendorBankAccountNo);
            VendorNo := TryFindLeastBlockedVendorNoByVendorBankAcc(VendorBankAccount);
        end;

        if VendorNo <> '' then begin
            IntermediateDataImport.InsertOrUpdateEntry(EntryNo, DATABASE::"Purchase Header", FieldID, 0, RecordNo, VendorNo);
            exit(VendorNo);
        end;

        exit('');
    end;

    local procedure FindVendorByPhoneNo(EntryNo: Integer; RecordNo: Integer; FieldID: Integer; PhoneNo: Text): Code[20]
    var
        IntermediateDataImport: Record "Intermediate Data Import";
        Vendor: Record Vendor;
        RecordMatchMgt: Codeunit "Record Match Mgt.";
        PhoneNoNearness: Integer;
    begin
        if PhoneNo = '' then
            exit('');

        PhoneNo := DelChr(PhoneNo, '=', DelChr(PhoneNo, '=', '0123456789'));
        Vendor.SetCurrentKey(Blocked);
        Vendor.SetLoadFields("Phone No.");
        if Vendor.FindSet() then
            repeat
                PhoneNoNearness := RecordMatchMgt.CalculateStringNearness(PhoneNo, Vendor."Phone No.", MatchThreshold(), NormalizingFactor());
                if PhoneNoNearness >= RequiredNearness() then begin
                    IntermediateDataImport.InsertOrUpdateEntry(EntryNo, DATABASE::"Purchase Header", FieldID, 0, RecordNo, Vendor."No.");
                    exit(Vendor."No.");
                end;
            until Vendor.Next() = 0;

        exit('');
    end;

    local procedure FindVendorById(EntryNo: Integer; RecordNo: Integer; FieldID: Integer; VendorIdText: Text): Code[20]
    var
        IntermediateDataImport: Record "Intermediate Data Import";
        Vendor: Record Vendor;
        VendorId: Guid;
    begin
        if VendorIdText = '' then
            exit('');

        if not Evaluate(VendorId, VendorIdText, 9) then
            exit('');

        if not Vendor.GetBySystemId(VendorId) then
            exit('');

        IntermediateDataImport.InsertOrUpdateEntry(EntryNo, DATABASE::"Purchase Header", FieldID, 0, RecordNo, Vendor."No.");
        exit(Vendor."No.");
    end;

    local procedure FindVendorByNo(EntryNo: Integer; RecordNo: Integer; FieldID: Integer; VendorNoText: Text): Code[20]
    var
        IntermediateDataImport: Record "Intermediate Data Import";
        Vendor: Record Vendor;
    begin
        if VendorNoText = '' then
            exit('');

        if not Vendor.Get(VendorNoText) then
            exit('');

        IntermediateDataImport.InsertOrUpdateEntry(EntryNo, DATABASE::"Purchase Header", FieldID, 0, RecordNo, Vendor."No.");
        exit(Vendor."No.");
    end;

    local procedure FindInvoiceToApplyTo(EntryNo: Integer; RecordNo: Integer)
    var
        IntermediateDataImport: Record "Intermediate Data Import";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorInvoiceNo: Text;
        AppliesToDocTypeAsInteger: Integer;
    begin
        VendorInvoiceNo := IntermediateDataImport.GetEntryValue(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Applies-to Doc. No."), 0, RecordNo);
        if VendorInvoiceNo = '' then
            exit;
        // Find a posted purchase invoice that has the specified Vendor Invoice No.
        PurchInvHeader.SetRange("Vendor Invoice No.", VendorInvoiceNo);
        if PurchInvHeader.FindFirst() then begin
            AppliesToDocTypeAsInteger := PurchaseHeader."Applies-to Doc. Type"::Invoice.AsInteger();
            IntermediateDataImport.InsertOrUpdateEntry(EntryNo, DATABASE::"Purchase Header",
              PurchaseHeader.FieldNo("Applies-to Doc. Type"), 0, RecordNo, Format(AppliesToDocTypeAsInteger));
            IntermediateDataImport.InsertOrUpdateEntry(EntryNo, DATABASE::"Purchase Header",
              PurchaseHeader.FieldNo("Applies-to Doc. No."), 0, RecordNo, PurchInvHeader."No.");
            exit;
        end;
        // No posted purchase invoice has the specified Vendor Invoice No.
        // This is an error - the user first needs to post the related invoice before importing this document.
        // If we can find an unposted invoice with this Vendor Invoice No. we will link to it in the error message.
        PurchaseHeader.SetRange("Vendor Invoice No.", VendorInvoiceNo);
        if PurchaseHeader.FindFirst() then begin
            LogErrorMessage(EntryNo, PurchaseHeader, PurchaseHeader.FieldNo("No."),
              StrSubstNo(YouMustFirstPostTheRelatedInvoiceErr, VendorInvoiceNo, PurchaseHeader."No."));
            exit;
        end;
        // No purchase invoice (posted or not) has the specified Vendor Invoice No.
        // This is an error - the user needs to create and post the related invoice before importing this document.
        LogErrorMessage(
          EntryNo, PurchInvHeader, PurchInvHeader.FieldNo("No."), StrSubstNo(UnableToFindRelatedInvoiceErr, VendorInvoiceNo));
    end;

    local procedure ProcessLine(EntryNo: Integer; HeaderRecordNo: Integer; RecordNo: Integer; VendorNo: Code[20])
    var
        ImportedUnitCode: Code[10];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeProcessLine(EntryNo, HeaderRecordNo, RecordNo, VendorNo, IsHandled);
        if IsHandled then
            exit;

        // Lines with 0 quantity are "empty/description only" lines
        if IsDescriptionOnlyLine(EntryNo, HeaderRecordNo, RecordNo) then begin
            CleanDescriptionOnlyLine(EntryNo, HeaderRecordNo, RecordNo);
            exit;
        end;

        // Lookup Item Ref, then GTIN/Bar Code, else G/L Account
        if ResolveUnitOfMeasureFromDataImport(ImportedUnitCode, EntryNo, HeaderRecordNo, RecordNo) then
            if not FindItemReferenceForLine(ImportedUnitCode, EntryNo, HeaderRecordNo, RecordNo, VendorNo) then
                if not FindItemForLine(ImportedUnitCode, EntryNo, HeaderRecordNo, RecordNo) then
                    if not FindGLAccountForLine(EntryNo, HeaderRecordNo, RecordNo, VendorNo) then
                        LogErrorIfItemNotFound(EntryNo, HeaderRecordNo, RecordNo, VendorNo);

        ValidateLineDiscount(EntryNo, HeaderRecordNo, RecordNo);
    end;

    local procedure InsertLineForTotalDocumentAmount(EntryNo: Integer; HeaderRecordNo: Integer; RecordNo: Integer; VendorNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        IntermediateDataImport: Record "Intermediate Data Import";
        LineDescription: Text[250];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertLineForTotalDocumentAmount(EntryNo, IsHandled);
        if IsHandled then
            exit;

        if not Vendor.Get(VendorNo) then
            exit;

        LineDescription := IntermediateDataImport.GetEntryValue(
            EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor Name"), 0, HeaderRecordNo);
        if LineDescription = '' then
            LineDescription := Vendor.Name;
        IntermediateDataImport.InsertOrUpdateEntry(EntryNo, DATABASE::"Purchase Line",
          PurchaseLine.FieldNo(Description), HeaderRecordNo, RecordNo, LineDescription);
        IntermediateDataImport.InsertOrUpdateEntry(EntryNo, DATABASE::"Purchase Line",
          PurchaseLine.FieldNo(Quantity), HeaderRecordNo, RecordNo, '1');
        IntermediateDataImport.InsertOrUpdateEntry(EntryNo, DATABASE::"Purchase Line",
          PurchaseLine.FieldNo("Direct Unit Cost"), HeaderRecordNo, RecordNo, GetTotalAmountExclVAT(EntryNo, HeaderRecordNo));
        FindGLAccountForLine(EntryNo, HeaderRecordNo, RecordNo, VendorNo);
    end;

    local procedure GetTotalAmountExclVAT(EntryNo: Integer; HeaderRecordNo: Integer): Text[250]
    var
        PurchaseHeader: Record "Purchase Header";
        IntermediateDataImport: Record "Intermediate Data Import";
    begin
        if not IntermediateDataImport.FindEntry(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo(Amount), 0, HeaderRecordNo) then begin
            LogSimpleErrorMessage(EntryNo, UnableToFindTotalAmountErr);
            exit('');
        end;
        exit(IntermediateDataImport.Value);
    end;

    local procedure FindItemForLine(ImportedUnitCode: Code[10]; EntryNo: Integer; HeaderNo: Integer; RecordNo: Integer): Boolean
    var
        IntermediateDataImport: Record "Intermediate Data Import";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        GTIN: Text;
    begin
        if not IntermediateDataImport.FindEntry(EntryNo, DATABASE::"Purchase Line", PurchaseLine.FieldNo("No."), HeaderNo, RecordNo) then
            exit(false);

        GTIN := IntermediateDataImport.Value;
        if GTIN = '' then
            exit(false);

        Item.SetRange(GTIN, GTIN);
        if not Item.FindFirst() then
            exit(false);

        IntermediateDataImport.Value := Item."No.";
        IntermediateDataImport.Modify();

        IntermediateDataImport.InsertOrUpdateEntry(
          EntryNo, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Type), HeaderNo, RecordNo, Format(PurchaseLine.Type::Item, 0, 9));

        ResolveUnitOfMeasureFromItem(Item, ImportedUnitCode, EntryNo, HeaderNo, RecordNo);

        exit(true);
    end;

    local procedure FindItemReferenceForLine(ImportedUnitCode: Code[10]; EntryNo: Integer; HeaderNo: Integer; RecordNo: Integer; VendorNo: Code[20]): Boolean
    var
        IntermediateDataImport: Record "Intermediate Data Import";
        PurchaseLine: Record "Purchase Line";
        ItemReference: Record "Item Reference";
        Vendor: Record Vendor;
    begin
        if not Vendor.Get(VendorNo) then
            exit(false);

        if not IntermediateDataImport.FindEntry(
             EntryNo, DATABASE::"Purchase Line", PurchaseLine.FieldNo("Item Reference No."), HeaderNo, RecordNo)
        then
            exit(false);

        ItemReference.SetRange("Reference Type", "Item Reference Type"::Vendor);
        ItemReference.SetRange("Reference Type No.", VendorNo);
        ItemReference.SetRange(
          "Reference No.", CopyStr(IntermediateDataImport.Value, 1, MaxStrLen(ItemReference."Reference No.")));

        if not FindMatchingItemReference(ItemReference, ImportedUnitCode) then
            exit(false);

        IntermediateDataImport.InsertOrUpdateEntry(
          EntryNo, DATABASE::"Purchase Line", PurchaseLine.FieldNo("No."), HeaderNo, RecordNo, Format(ItemReference."Item No.", 0, 9));
        IntermediateDataImport.InsertOrUpdateEntry(
          EntryNo, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Type), HeaderNo, RecordNo, Format(PurchaseLine.Type::Item, 0, 9));

        ResolveUnitOfMeasureFromItemReference(ItemReference, ImportedUnitCode, EntryNo, HeaderNo, RecordNo);

        exit(true);
    end;

    local procedure FindMatchingItemReference(var ItemReference: Record "Item Reference"; ImportedUnitCode: Code[10]): Boolean
    begin
        if not ItemReference.FindFirst() then
            exit(false);

        ItemReference.SetRange("Unit of Measure", ImportedUnitCode);
        if ItemReference.FindSet() then
            repeat
                if ItemReference.HasValidUnitOfMeasure() then
                    exit(true);
            until ItemReference.Next() = 0;

        ItemReference.SetRange("Unit of Measure", '');
        if ItemReference.FindSet() then
            repeat
                if ItemReference.HasValidUnitOfMeasure() then
                    exit(true);
            until ItemReference.Next() = 0;

        ItemReference.SetRange("Unit of Measure");
        exit(ItemReference.FindFirst());
    end;

    local procedure IsDescriptionOnlyLine(EntryNo: Integer; HeaderRecordNo: Integer; RecordNo: Integer): Boolean
    var
        IntermediateDataImport: Record "Intermediate Data Import";
        PurchaseLine: Record "Purchase Line";
        Qty: Decimal;
    begin
        if not IntermediateDataImport.FindEntry(EntryNo, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Quantity), HeaderRecordNo, RecordNo) then
            exit(true);

        Evaluate(Qty, IntermediateDataImport.Value, 9);
        if Qty = 0 then
            exit(true);

        exit(false);
    end;

    local procedure CleanDescriptionOnlyLine(EntryNo: Integer; HeaderRecordNo: Integer; RecordNo: Integer)
    var
        IntermediateDataImport: Record "Intermediate Data Import";
        PurchaseLine: Record "Purchase Line";
    begin
        IntermediateDataImport.InsertOrUpdateEntry(EntryNo, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Type),
          HeaderRecordNo, RecordNo, Format(PurchaseLine.Type::" ", 0, 9));

        IntermediateDataImport.SetRange("Data Exch. No.", EntryNo);
        IntermediateDataImport.SetRange("Table ID", DATABASE::"Purchase Line");
        IntermediateDataImport.SetRange("Parent Record No.", HeaderRecordNo);
        IntermediateDataImport.SetRange("Record No.", RecordNo);
        IntermediateDataImport.SetFilter("Field ID", '<>%1&<>%2&<>%3',
          PurchaseLine.FieldNo(Type), PurchaseLine.FieldNo(Description), PurchaseLine.FieldNo("Description 2"));
        IntermediateDataImport.DeleteAll();
    end;

    local procedure LogErrorIfItemNotFound(EntryNo: Integer; HeaderRecordNo: Integer; RecordNo: Integer; VendorNo: Code[20]): Boolean
    var
        IntermediateDataImport: Record "Intermediate Data Import";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        GTIN: Text[250];
        ItemName: Text[250];
        VendorItemNo: Text[250];
    begin
        GTIN := IntermediateDataImport.GetEntryValue(EntryNo, DATABASE::"Purchase Line", PurchaseLine.FieldNo("No."), HeaderRecordNo, RecordNo);

        VendorItemNo :=
            IntermediateDataImport.GetEntryValue(
                EntryNo, DATABASE::"Purchase Line", PurchaseLine.FieldNo("Item Reference No."), HeaderRecordNo, RecordNo);

        ItemName := IntermediateDataImport.GetEntryValue(EntryNo, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Description),
            HeaderRecordNo, RecordNo);

        if (GTIN <> '') and (VendorItemNo <> '') then begin
            LogErrorMessage(EntryNo, Item, Item.FieldNo("No."),
              StrSubstNo(ItemNotFoundErr, ItemName, VendorNo, VendorItemNo, GTIN));
            exit(false);
        end;

        if GTIN <> '' then begin
            LogErrorMessage(EntryNo, Item, Item.FieldNo("No."),
              StrSubstNo(ItemNotFoundByGTINErr, ItemName, GTIN));
            exit(false);
        end;

        if VendorItemNo <> '' then begin
            LogErrorMessage(EntryNo, Item, Item.FieldNo("No."),
              StrSubstNo(ItemNotFoundByVendorItemNoErr, ItemName, VendorNo, VendorItemNo));
            exit(false);
        end;

        exit(true);
    end;

    local procedure FindGLAccountForLine(EntryNo: Integer; HeaderRecordNo: Integer; RecordNo: Integer; VendorNo: Code[20]): Boolean
    var
        IntermediateDataImport: Record "Intermediate Data Import";
        PurchaseLine: Record "Purchase Line";
        GLAccountNo: Code[20];
        LineDescription: Text[250];
        LineDirectUnitCostTxt: Text;
        LineDirectUnitCost: Decimal;
        IsHandled: Boolean;
    begin
        LineDescription := IntermediateDataImport.GetEntryValue(EntryNo, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Description), HeaderRecordNo, RecordNo);
        LineDirectUnitCostTxt :=
          IntermediateDataImport.GetEntryValue(EntryNo, DATABASE::"Purchase Line", PurchaseLine.FieldNo("Direct Unit Cost"), HeaderRecordNo, RecordNo);
        if LineDirectUnitCostTxt <> '' then
            Evaluate(LineDirectUnitCost, LineDirectUnitCostTxt, 9);

        IsHandled := false;
        OnFindGLAccountForLineOnBeforeFindAppropriateGLAccount(IntermediateDataImport, GLAccountNo, EntryNo, HeaderRecordNo, RecordNo, VendorNo, IsHandled);
        if not IsHandled then
            GLAccountNo := FindAppropriateGLAccount(EntryNo, HeaderRecordNo, LineDescription, LineDirectUnitCost, VendorNo);

        if GLAccountNo <> '' then begin
            IntermediateDataImport.InsertOrUpdateEntry(EntryNo, DATABASE::"Purchase Line", PurchaseLine.FieldNo("No."),
              HeaderRecordNo, RecordNo, GLAccountNo);
            IntermediateDataImport.InsertOrUpdateEntry(EntryNo, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Type),
              HeaderRecordNo, RecordNo, Format(PurchaseLine.Type::"G/L Account", 0, 9));
        end;
        exit(GLAccountNo <> '');
    end;

    local procedure InsertOrUpdateUnitOfMeasureCode(EntryNo: Integer; HeaderNo: Integer; RecordNo: Integer; UnitCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
        IntermediateDataImport: Record "Intermediate Data Import";
    begin
        IntermediateDataImport.InsertOrUpdateEntry(
          EntryNo, DATABASE::"Purchase Line", PurchaseLine.FieldNo("Unit of Measure Code"), HeaderNo, RecordNo, UnitCode);
    end;

    local procedure ResolveUnitOfMeasureFromItemReference(var ItemReference: Record "Item Reference"; ImportedUnitCode: Code[10]; EntryNo: Integer; HeaderNo: Integer; RecordNo: Integer): Boolean
    var
        Item: Record Item;
        ResolvedUnitCode: Code[10];
    begin
        ResolvedUnitCode := ItemReference."Unit of Measure";
        if ResolvedUnitCode = '' then begin
            Item.Get(ItemReference."Item No.");
            exit(ResolveUnitOfMeasureFromItem(Item, ImportedUnitCode, EntryNo, HeaderNo, RecordNo));
        end;

        if (ImportedUnitCode <> '') and (ImportedUnitCode <> ResolvedUnitCode) then begin
            LogErrorMessage(EntryNo, ItemReference, ItemReference.FieldNo("Unit of Measure"),
              StrSubstNo(UOMConflictWithItemRefErr, ImportedUnitCode, RecordNo, UnitCodeToString(ResolvedUnitCode)));
            exit(false);
        end;

        if not ItemReference.HasValidUnitOfMeasure() then begin
            LogErrorMessage(EntryNo, ItemReference, ItemReference.FieldNo("Unit of Measure"),
              StrSubstNo(UOMConflictItemRefWithItemErr, UnitCodeToString(ResolvedUnitCode)));
            exit(false);
        end;

        InsertOrUpdateUnitOfMeasureCode(EntryNo, HeaderNo, RecordNo, ResolvedUnitCode);
        exit(true);
    end;

    local procedure ResolveUnitOfMeasureFromItem(var Item: Record Item; ImportedUnitCode: Code[10]; EntryNo: Integer; HeaderNo: Integer; RecordNo: Integer): Boolean
    var
        ResolvedUnitCode: Code[10];
    begin
        ResolvedUnitCode := Item."Purch. Unit of Measure";
        if ResolvedUnitCode = '' then
            ResolvedUnitCode := Item."Base Unit of Measure";

        if (ImportedUnitCode <> '') and (ImportedUnitCode <> ResolvedUnitCode) then begin
            LogErrorMessage(EntryNo, Item, Item.FieldNo("Base Unit of Measure"),
              StrSubstNo(UOMConflictWithItemErr, ImportedUnitCode, RecordNo, UnitCodeToString(ResolvedUnitCode)));
            exit(false);
        end;

        InsertOrUpdateUnitOfMeasureCode(EntryNo, HeaderNo, RecordNo, ResolvedUnitCode);
        exit(true);
    end;

    local procedure ResolveUnitOfMeasureFromDataImport(var ImportedUnitCode: Code[10]; EntryNo: Integer; HeaderNo: Integer; RecordNo: Integer): Boolean
    var
        PurchaseLine: Record "Purchase Line";
        UnitOfMeasure: Record "Unit of Measure";
        IntermediateDataImport: Record "Intermediate Data Import";
        ImportedUnitString: Text;
    begin
        if not IntermediateDataImport.FindEntry(
             EntryNo, DATABASE::"Purchase Line", PurchaseLine.FieldNo("Unit of Measure Code"), HeaderNo, RecordNo)
        then begin
            LogSimpleErrorMessage(EntryNo, StrSubstNo(UOMMissingErr, RecordNo));
            exit(false);
        end;

        ImportedUnitString := IntermediateDataImport.Value;
        if ImportedUnitString = '' then begin
            ImportedUnitCode := '';
            InsertOrUpdateUnitOfMeasureCode(EntryNo, HeaderNo, RecordNo, ImportedUnitCode);
            exit(true);
        end;

        UnitOfMeasure.SetRange(Code, CopyStr(ImportedUnitString, 1, MaxStrLen(UnitOfMeasure.Code)));
        if UnitOfMeasure.FindFirst() then begin
            ImportedUnitCode := UnitOfMeasure.Code;
            InsertOrUpdateUnitOfMeasureCode(EntryNo, HeaderNo, RecordNo, ImportedUnitCode);
            exit(true);
        end;

        UnitOfMeasure.SetRange(Code);
        UnitOfMeasure.SetRange(
          "International Standard Code", CopyStr(ImportedUnitString, 1, MaxStrLen(UnitOfMeasure."International Standard Code")));
        if UnitOfMeasure.FindFirst() then begin
            ImportedUnitCode := UnitOfMeasure.Code;
            InsertOrUpdateUnitOfMeasureCode(EntryNo, HeaderNo, RecordNo, ImportedUnitCode);
            exit(true);
        end;

        UnitOfMeasure.SetRange("International Standard Code");
        UnitOfMeasure.SetRange(Description, ImportedUnitString);
        if UnitOfMeasure.FindFirst() then begin
            ImportedUnitCode := UnitOfMeasure.Code;
            InsertOrUpdateUnitOfMeasureCode(EntryNo, HeaderNo, RecordNo, ImportedUnitCode);
            exit(true);
        end;

        LogErrorMessage(EntryNo, UnitOfMeasure, UnitOfMeasure.FieldNo(Code), StrSubstNo(UOMNotFoundErr, ImportedUnitString));
        exit(false);
    end;

    local procedure UnitCodeToString(UnitCode: Code[10]): Text
    begin
        if UnitCode <> '' then
            exit(UnitCode);
        exit(NotSpecifiedUnitOfMeasureTxt);
    end;

    local procedure ValidateLineDiscount(EntryNo: Integer; HeaderRecordNo: Integer; RecordNo: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        IntermediateDataImport: Record "Intermediate Data Import";
        LineDirectUnitCostTxt: Text;
        LineQuantityTxt: Text;
        LineAmountTxt: Text;
        LineDirectUnitCost: Decimal;
        LineAmount: Decimal;
        LineQuantity: Decimal;
        LineDiscountAmount: Decimal;
    begin
        if IntermediateDataImport.GetEntryValue(EntryNo, DATABASE::"Purchase Line", PurchaseLine.FieldNo("Line Discount Amount"), HeaderRecordNo, RecordNo) <> '' then
            exit;
        // if no discount amount has been specified, calculate it based on quantity, direct unit cost and line extension amount
        LineDirectUnitCostTxt :=
          IntermediateDataImport.GetEntryValue(EntryNo, DATABASE::"Purchase Line", PurchaseLine.FieldNo("Direct Unit Cost"), HeaderRecordNo, RecordNo);
        if LineDirectUnitCostTxt <> '' then
            Evaluate(LineDirectUnitCost, LineDirectUnitCostTxt, 9);
        LineQuantityTxt :=
          IntermediateDataImport.GetEntryValue(EntryNo, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Quantity), HeaderRecordNo, RecordNo);
        if LineQuantityTxt <> '' then
            Evaluate(LineQuantity, LineQuantityTxt, 9);
        LineAmountTxt :=
          IntermediateDataImport.GetEntryValue(EntryNo, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Amount), HeaderRecordNo, RecordNo);
        if LineAmountTxt <> '' then
            Evaluate(LineAmount, LineAmountTxt, 9);
        LineDiscountAmount := (LineQuantity * LineDirectUnitCost) - LineAmount;

        IntermediateDataImport.InsertOrUpdateEntry(EntryNo, DATABASE::"Purchase Line", PurchaseLine.FieldNo("Line Discount Amount"),
          HeaderRecordNo, RecordNo, Format(LineDiscountAmount, 0, 9));

        IntermediateDataImport.Modify();
    end;

    local procedure ExtractVatRegNo(VatRegNo: Text; CountryRegionCode: Text): Text
    var
        CompanyInformation: Record "Company Information";
    begin
        if CountryRegionCode = '' then begin
            CompanyInformation.Get();
            CountryRegionCode := CompanyInformation."Country/Region Code";
        end;
        VatRegNo := UpperCase(VatRegNo);
        VatRegNo := DelChr(VatRegNo, '=', DelChr(VatRegNo, '=', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'));
        if StrPos(VatRegNo, UpperCase(CountryRegionCode)) = 1 then
            VatRegNo := DelStr(VatRegNo, 1, StrLen(CountryRegionCode));
        exit(VatRegNo);
    end;

    local procedure FindDistinctRecordNos(var TempInteger: Record "Integer" temporary; DataExchEntryNo: Integer; TableID: Integer; ParentRecNo: Integer)
    var
        IntermediateDataImport: Record "Intermediate Data Import";
        CurrRecNo: Integer;
    begin
        CurrRecNo := -1;
        Clear(TempInteger);
        TempInteger.DeleteAll();

        IntermediateDataImport.SetRange("Data Exch. No.", DataExchEntryNo);
        IntermediateDataImport.SetRange("Table ID", TableID);
        IntermediateDataImport.SetRange("Parent Record No.", ParentRecNo);
        IntermediateDataImport.SetCurrentKey("Record No.");
        if not IntermediateDataImport.FindSet() then
            exit;

        repeat
            if CurrRecNo <> IntermediateDataImport."Record No." then begin
                CurrRecNo := IntermediateDataImport."Record No.";
                Clear(TempInteger);
                TempInteger.Number := CurrRecNo;
                TempInteger.Insert();
            end;
        until IntermediateDataImport.Next() = 0;
    end;

    local procedure LogErrorMessage(EntryNo: Integer; RelatedRec: Variant; FieldNo: Integer; Message: Text)
    var
        ErrorMessage: Record "Error Message";
        DataExch: Record "Data Exch.";
        IncomingDocument: Record "Incoming Document";
    begin
        DataExch.Get(EntryNo);
        IncomingDocument.Get(DataExch."Incoming Entry No.");

        ErrorMessage.SetContext(IncomingDocument);
        ErrorMessage.LogMessage(RelatedRec, FieldNo, ErrorMessage."Message Type"::Error, Message);
    end;

    local procedure LogSimpleErrorMessage(EntryNo: Integer; Message: Text)
    var
        ErrorMessage: Record "Error Message";
        DataExch: Record "Data Exch.";
        IncomingDocument: Record "Incoming Document";
    begin
        DataExch.Get(EntryNo);
        IncomingDocument.Get(DataExch."Incoming Entry No.");

        ErrorMessage.SetContext(IncomingDocument);
        ErrorMessage.LogSimpleMessage(ErrorMessage."Message Type"::Error, Message);
    end;

    local procedure SetDocumentType(EntryNo: Integer; ParentRecNo: Integer; CurrRecNo: Integer)
    var
        IntermediateDataImport: Record "Intermediate Data Import";
        PurchaseHeader: Record "Purchase Header";
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DocumentType: Text[250];
    begin
        DataExch.Get(EntryNo);
        DataExchDef.Get(DataExch."Data Exch. Def Code");
        if not IntermediateDataImport.FindEntry(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Document Type"), ParentRecNo, CurrRecNo) then
            LogErrorMessage(EntryNo, DataExchDef, DataExchDef.FieldNo(Code),
              ConstructDocumenttypeUnknownErr());

        case UpperCase(IntermediateDataImport.Value) of
            GetDocumentTypeOptionString(PurchaseHeader."Document Type"::Invoice.AsInteger()),
            GetDocumentTypeOptionCaption(PurchaseHeader."Document Type"::Invoice.AsInteger()):
                DocumentType := Format(PurchaseHeader."Document Type"::Invoice, 0, 9);
            GetDocumentTypeOptionString(PurchaseHeader."Document Type"::"Credit Memo".AsInteger()),
            GetDocumentTypeOptionCaption(PurchaseHeader."Document Type"::"Credit Memo".AsInteger()),
          'CREDIT NOTE':
                DocumentType := Format(PurchaseHeader."Document Type"::"Credit Memo", 0, 9);
            else
                LogErrorMessage(EntryNo, DataExchDef, DataExchDef.FieldNo(Code),
                  ConstructDocumenttypeUnknownErr());
        end;

        IntermediateDataImport.InsertOrUpdateEntry(EntryNo, DATABASE::"Purchase Header",
          PurchaseHeader.FieldNo("Document Type"), ParentRecNo, CurrRecNo,
          DocumentType);
    end;

    procedure GetDocumentTypeOptionString(OptionIndex: Integer): Text[250]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderRecRef: RecordRef;
        DocumentTypeFieldRef: FieldRef;
    begin
        PurchaseHeaderRecRef.Open(DATABASE::"Purchase Header");
        DocumentTypeFieldRef := PurchaseHeaderRecRef.Field(PurchaseHeader.FieldNo("Document Type"));
        exit(UpperCase(SelectStr(OptionIndex + 1, DocumentTypeFieldRef.OptionMembers)));
    end;

    procedure GetDocumentTypeOptionCaption(OptionIndex: Integer): Text[250]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderRecRef: RecordRef;
        DocumentTypeFieldRef: FieldRef;
    begin
        PurchaseHeaderRecRef.Open(DATABASE::"Purchase Header");
        DocumentTypeFieldRef := PurchaseHeaderRecRef.Field(PurchaseHeader.FieldNo("Document Type"));
        exit(UpperCase(SelectStr(OptionIndex + 1, DocumentTypeFieldRef.OptionCaption)));
    end;

    procedure ConstructDocumenttypeUnknownErr(): Text
    var
        PurchaseHeader: Record "Purchase Header";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchColDefPart: Page "Data Exch Col Def Part";
        DataExchDefCard: Page "Data Exch Def Card";
    begin
        exit(StrSubstNo(DocumentTypeUnknownErr,
            DataExchColDefPart.Caption,
            DataExchDefCard.Caption,
            GetDocumentTypeOptionCaption(PurchaseHeader."Document Type"::Invoice.AsInteger()),
            GetDocumentTypeOptionCaption(PurchaseHeader."Document Type"::"Credit Memo".AsInteger()),
            DataExchColumnDef.FieldCaption(Constant),
            PurchaseHeader.FieldCaption("Document Type"),
            PurchaseHeader.TableCaption()));
    end;

    procedure FindAppropriateGLAccount(EntryNo: Integer; HeaderRecordNo: Integer; LineDescription: Text[250]; LineDirectUnitCost: Decimal; VendorNo: Code[20]): Code[20]
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        TextToAccountMapping: Record "Text-to-Account Mapping";
        PurchaseHeader: Record "Purchase Header";
        IntermediateDataImport: Record "Intermediate Data Import";
        DocumentTypeTxt: Text;
        DocumentType: Enum "Gen. Journal Document Type";
        DefaultGLAccount: Code[20];
        CountOfResult: Integer;
    begin
        DocumentTypeTxt := IntermediateDataImport.GetEntryValue(
            EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Document Type"), 0, HeaderRecordNo);
        if not Evaluate(DocumentType, DocumentTypeTxt) then
            exit('');

        CountOfResult := TextToAccountMapping.SearchEnteriesInText(TextToAccountMapping, LineDescription, VendorNo);
        if CountOfResult = 1 then
            exit(FindCorrectAccountFromMapping(TextToAccountMapping, LineDirectUnitCost, DocumentType));
        if CountOfResult > 1 then begin
            LogErrorMessage(EntryNo, TextToAccountMapping, TextToAccountMapping.FieldNo("Mapping Text"),
              StrSubstNo(UnableToFindAppropriateAccountErr, LineDescription));
            exit('');
        end;

        if VendorNo <> '' then begin
            CountOfResult := TextToAccountMapping.SearchEnteriesInText(TextToAccountMapping, LineDescription, '');
            if CountOfResult = 1 then
                exit(FindCorrectAccountFromMapping(TextToAccountMapping, LineDirectUnitCost, DocumentType));
            if CountOfResult > 1 then begin
                LogErrorMessage(EntryNo, TextToAccountMapping, TextToAccountMapping.FieldNo("Mapping Text"),
                  StrSubstNo(UnableToFindAppropriateAccountErr, LineDescription));
                exit('');
            end;
        end;

        // if you don't find any suggestion in Text-to-Account Mapping, then look in the Purchases & Payables table
        PurchasesPayablesSetup.Get();
        case DocumentType of
            "Gen. Journal Document Type"::Invoice:
                if LineDirectUnitCost >= 0 then
                    DefaultGLAccount := PurchasesPayablesSetup."Debit Acc. for Non-Item Lines"
                else
                    DefaultGLAccount := PurchasesPayablesSetup."Credit Acc. for Non-Item Lines";
            "Gen. Journal Document Type"::"Credit Memo":
                if LineDirectUnitCost >= 0 then
                    DefaultGLAccount := PurchasesPayablesSetup."Credit Acc. for Non-Item Lines"
                else
                    DefaultGLAccount := PurchasesPayablesSetup."Debit Acc. for Non-Item Lines";
        end;
        if DefaultGLAccount = '' then
            LogErrorMessage(EntryNo, TextToAccountMapping, TextToAccountMapping.FieldNo("Mapping Text"),
              StrSubstNo(UnableToFindAppropriateAccountErr, LineDescription));
        exit(DefaultGLAccount)
    end;

    local procedure NormalizingFactor(): Integer
    begin
        exit(100)
    end;

    local procedure MatchThreshold(): Integer
    begin
        exit(4)
    end;

    local procedure RequiredNearness(): Integer
    begin
        exit(95)
    end;

    local procedure FindCorrectAccountFromMapping(TextToAccountMapping: Record "Text-to-Account Mapping"; LineDirectUnitCost: Decimal; DocumentType: Enum "Gen. Journal Document Type"): Code[20]
    begin
        case DocumentType of
            "Gen. Journal Document Type"::Invoice:
                begin
                    if (LineDirectUnitCost >= 0) and (TextToAccountMapping."Debit Acc. No." <> '') then
                        exit(TextToAccountMapping."Debit Acc. No.");
                    if (LineDirectUnitCost < 0) and (TextToAccountMapping."Credit Acc. No." <> '') then
                        exit(TextToAccountMapping."Credit Acc. No.");
                end;
            "Gen. Journal Document Type"::"Credit Memo":
                begin
                    if (LineDirectUnitCost >= 0) and (TextToAccountMapping."Credit Acc. No." <> '') then
                        exit(TextToAccountMapping."Credit Acc. No.");
                    if (LineDirectUnitCost < 0) and (TextToAccountMapping."Debit Acc. No." <> '') then
                        exit(TextToAccountMapping."Debit Acc. No.");
                end;
        end
    end;

    local procedure TryFindLeastBlockedVendorNoByVendorBankAcc(var VendorBankAccount: record "Vendor Bank Account"): Code[20]
    var
        Vendor: Record Vendor;
        NonBlockedVendorNo: Code[20];
        BlockedPaymentVendorNo: Code[20];
        BlockedAllVendorNo: Code[20];
    begin
        BlockedAllVendorNo := '';
        BlockedPaymentVendorNo := '';
        if VendorBankAccount.FindSet() then
            repeat
                if Vendor.Get(VendorBankAccount."Vendor No.") then begin
                    if Vendor.Blocked = "Vendor Blocked"::" " then
                        NonBlockedVendorNo := Vendor."No.";

                    if (Vendor.Blocked = "Vendor Blocked"::Payment) and (BlockedPaymentVendorNo = '') then
                        BlockedPaymentVendorNo := Vendor."No.";

                    if (Vendor.Blocked = "Vendor Blocked"::All) and (BlockedAllVendorNo = '') then
                        BlockedAllVendorNo := Vendor."No.";
                end;
            until (VendorBankAccount.Next() = 0) or (NonBlockedVendorNo <> '');

        if NonBlockedVendorNo <> '' then
            exit(NonBlockedVendorNo);
        if BlockedPaymentVendorNo <> '' then
            exit(BlockedPaymentVendorNo);
        if BlockedAllVendorNo <> '' then
            exit(BlockedAllVendorNo);

        exit('');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCorrectHeaderData(EntryNo: Integer; RecordNo: Integer; DataExch: Record "Data Exch."; var IncomingDocument: Record "Incoming Document")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertLineForTotalDocumentAmount(EntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessLine(EntryNo: Integer; HeaderRecordNo: Integer; RecordNo: Integer; VendorNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindGLAccountForLineOnBeforeFindAppropriateGLAccount(IntermediateDataImport: Record "Intermediate Data Import"; var GLAccountNo: Code[20]; EntryNo: Integer; HeaderRecordNo: Integer; RecordNo: Integer; VendorNo: Code[20]; var IsHandled: Boolean)
    begin
    end;
}

