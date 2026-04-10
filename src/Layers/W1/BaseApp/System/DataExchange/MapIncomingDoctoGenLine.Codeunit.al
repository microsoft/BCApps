namespace System.IO;

using Microsoft.Bank.Reconciliation;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Setup;
using System.Utilities;

codeunit 1224 "Map Incoming Doc to Gen. Line"
{
    TableNo = "Incoming Document";

    trigger OnRun()
    begin
        IncomingDocument := Rec;
        ErrorMessage.SetContext(IncomingDocument);
        CreateGeneralJournalLineFromIncomingDocument();
    end;

    var
        NoBalanceAccountMappingErr: Label 'Could not fill the Bal. Account No. field for vendor ''''%1''''. Choose the Map Text to Account button to map ''''%1'''' to the relevant G/L account.', Comment = '%1 - vendor name';
        NoDebitAccountMappingErr: Label 'Could not fill the %1 field for vendor ''''%2''''. Choose the Map Text to Account button to map ''''%2'''' to the relevant G/L account.', Comment = '%1 - Debit Acc. No. or Credit Acc. No. field caption, %2 - vendor name';
        VatAmountMismatchErr: Label 'VAT amount %1 on the general journal line does not match VAT amount %2 in the incoming document.', Comment = '%1 - General Journal Line VAT amount, %2 - Incoming Document VAT  amount';
        TemplateBatchNameMissingErr: Label 'You must fill the General Journal Template Name and General Journal Batch Name fields in the Incoming Document Setup window. ';
        IncomingDocument: Record "Incoming Document";
        ErrorMessage: Record "Error Message";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        CurrencyDoesNotExistErr: Label 'The currency %1 does not exist. You must add the currency in the Currencies window.', Comment = '%1 referee to a concrete currency';
        CurrencyExchangeDoesNotExistErr: Label 'No exchange rate exists for %1 on %2. You must add the exchange rate in the Currencies window.', Comment = '%1 reference to a concrete currency,%2 to the date for the transaction';

    local procedure CreateGeneralJournalLineFromIncomingDocument()
    var
        GenJournalLine: Record "Gen. Journal Line";
        IncomingDocumentsSetup: Record "Incoming Documents Setup";
        LastGenJournalLine: Record "Gen. Journal Line";
        TextToAccountMapping: Record "Text-to-Account Mapping";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GeneralLedgerSetup: Record "General Ledger Setup";
        TextToAccountMappingFound: Boolean;
        TempGenJournalLineInserted: Boolean;
    begin
        IncomingDocumentsSetup.Get();
        if (IncomingDocumentsSetup."General Journal Template Name" = '') or
           (IncomingDocumentsSetup."General Journal Batch Name" = '')
        then
            ErrorMessage.LogMessage(
              IncomingDocumentsSetup, IncomingDocumentsSetup.FieldNo("General Journal Template Name"),
              ErrorMessage."Message Type"::Error, TemplateBatchNameMissingErr)
        else begin
            GenJournalTemplate.Get(IncomingDocumentsSetup."General Journal Template Name");
            GenJournalBatch.Get(
              IncomingDocumentsSetup."General Journal Template Name", IncomingDocumentsSetup."General Journal Batch Name");
            LastGenJournalLine.SetRange("Journal Template Name", IncomingDocumentsSetup."General Journal Template Name");
            LastGenJournalLine.SetRange("Journal Batch Name", IncomingDocumentsSetup."General Journal Batch Name");
            if not LastGenJournalLine.FindLast() then begin
                LastGenJournalLine.Validate("Journal Template Name", IncomingDocumentsSetup."General Journal Template Name");
                LastGenJournalLine.Validate("Journal Batch Name", IncomingDocumentsSetup."General Journal Batch Name");
                LastGenJournalLine."Line No." := LastGenJournalLine."Line No." + 10000;
                LastGenJournalLine.Validate("Document No.", NoSeriesBatch.GetNextNo(GenJournalBatch."No. Series", IncomingDocument."Document Date"));
                TempGenJournalLineInserted := LastGenJournalLine.Insert();
            end;

            // Create the gen jnl line out of the inc doc and text-to-account mapping
            GenJournalLine.Init();
            GenJournalLine.Validate("Journal Template Name", IncomingDocumentsSetup."General Journal Template Name");
            GenJournalLine.Validate("Journal Batch Name", IncomingDocumentsSetup."General Journal Batch Name");
            GenJournalLine."Line No." := LastGenJournalLine."Line No." + 10000;
            LastGenJournalLine.CalcSums("Balance (LCY)");
            GenJournalLine.SetUpNewLine(LastGenJournalLine, LastGenJournalLine."Balance (LCY)", true);

            if TempGenJournalLineInserted then
                LastGenJournalLine.Delete();

            GenJournalLine."Document Type" := GetAttachedDocumentType();

            TextToAccountMapping.SetFilter("Mapping Text", StrSubstNo('@%1', IncomingDocument."Vendor Name"));
            TextToAccountMappingFound := TextToAccountMapping.FindFirst();

            case GenJournalLine."Document Type" of
                GenJournalLine."Document Type"::Invoice:
                    if TextToAccountMappingFound then begin
                        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"G/L Account");
                        if IncomingDocument."Amount Incl. VAT" >= 0 then
                            GenJournalLine.Validate("Account No.", TextToAccountMapping."Debit Acc. No.")
                        else
                            GenJournalLine.Validate("Account No.", TextToAccountMapping."Credit Acc. No.");
                    end else
                        UseDefaultGLAccount(GenJournalLine, GenJournalLine.FieldCaption("Account No."), IncomingDocument."Vendor Name");
                GenJournalLine."Document Type"::"Credit Memo":
                    if TextToAccountMappingFound then begin
                        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"G/L Account");
                        if IncomingDocument."Amount Incl. VAT" >= 0 then
                            GenJournalLine.Validate("Account No.", TextToAccountMapping."Credit Acc. No.")
                        else
                            GenJournalLine.Validate("Account No.", TextToAccountMapping."Debit Acc. No.");
                    end else
                        UseDefaultGLAccount(GenJournalLine, GenJournalLine.FieldCaption("Account No."), IncomingDocument."Vendor Name");
            end;

            if IncomingDocument."Vendor No." <> '' then begin
                GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::Vendor);
                GenJournalLine.Validate("Bal. Account No.", IncomingDocument."Vendor No.");
            end else
                if TextToAccountMapping."Bal. Source No." <> '' then begin
                    GenJournalLine.Validate("Bal. Account Type", TextToAccountMapping."Bal. Source Type");
                    GenJournalLine.Validate("Bal. Account No.", TextToAccountMapping."Bal. Source No.");
                end else
                    if GenJournalBatch."Bal. Account No." <> '' then begin
                        GenJournalLine.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type");
                        GenJournalLine.Validate("Bal. Account No.", GenJournalBatch."Bal. Account No.");
                    end else
                        ErrorMessage.LogMessage(
                          TextToAccountMapping, TextToAccountMapping.FieldNo("Mapping Text"),
                          ErrorMessage."Message Type"::Error, StrSubstNo(NoBalanceAccountMappingErr, IncomingDocument."Vendor Name"));

            GenJournalLine.Validate("Due Date", IncomingDocument."Due Date");
            GenJournalLine.Validate("Posting Date", IncomingDocument."Document Date");
            GenJournalLine.Validate("Document Date", IncomingDocument."Document Date");
            GenJournalLine.Validate("External Document No.", IncomingDocument."Vendor Invoice No.");
            GeneralLedgerSetup.Get();
            if IncomingDocument."Currency Code" <> GeneralLedgerSetup."LCY Code" then
                if VerifyCurrency(IncomingDocument."Currency Code", IncomingDocument."Document Date") then
                    GenJournalLine.Validate("Currency Code", IncomingDocument."Currency Code");
            GenJournalLine.Validate(Amount, IncomingDocument."Amount Incl. VAT");
            GenJournalLine.Validate("Incoming Document Entry No.", IncomingDocument."Entry No.");
            GenJournalLine.Validate(Description, IncomingDocument."Vendor Name");

            OnBeforeGenJnlLineInsertFromIncomingDocument(GenJournalLine, IncomingDocument);

            if not ErrorMessage.HasErrors(false) then
                GenJournalLine.Insert(true);

            if IncomingDocument."Amount Incl. VAT" - IncomingDocument."Amount Excl. VAT" <> GenJournalLine."VAT Amount" then
                ErrorMessage.LogMessage(GenJournalLine, GenJournalLine.FieldNo("Account No."),
                  ErrorMessage."Message Type"::Warning,
                  StrSubstNo(VatAmountMismatchErr, GenJournalLine."VAT Amount",
                    IncomingDocument."Amount Incl. VAT" - IncomingDocument."Amount Excl. VAT"));
        end;
    end;

    local procedure GetAttachedDocumentType(): Enum "Gen. Journal Document Type"
    var
        DataExch: Record "Data Exch.";
        IntermediateDataImport: Record "Intermediate Data Import";
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        PreMapIncomingPurchDoc: Codeunit "Pre-map Incoming Purch. Doc";
        Value: Text;
        DocumentType: Enum "Purchase Document Type";
    begin
        DataExch.SetRange("Incoming Entry No.", IncomingDocument."Entry No.");
        if not DataExch.FindLast() then
            ErrorMessage.LogMessage(GenJournalLine, GenJournalLine.FieldNo("Document Type"),
              ErrorMessage."Message Type"::Error, PreMapIncomingPurchDoc.ConstructDocumenttypeUnknownErr());
        Value :=
          IntermediateDataImport.GetEntryValue(
            DataExch."Entry No.", DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Document Type"), 0, 1);
        Evaluate(DocumentType, Value);
        case DocumentType of
            PurchaseHeader."Document Type"::Invoice:
                exit(GenJournalLine."Document Type"::Invoice);
            PurchaseHeader."Document Type"::"Credit Memo":
                exit(GenJournalLine."Document Type"::"Credit Memo");
            else
                ErrorMessage.LogMessage(GenJournalLine, GenJournalLine.FieldNo("Document Type"),
                  ErrorMessage."Message Type"::Error, PreMapIncomingPurchDoc.ConstructDocumenttypeUnknownErr());
        end;
        exit(Enum::"Gen. Journal Document Type"::" ");
    end;

    local procedure UseDefaultGLAccount(var GenJournalLine: Record "Gen. Journal Line"; FieldName: Text; VendorName: Text)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        TextToAccountMapping: Record "Text-to-Account Mapping";
        DefaultGLAccount: Code[20];
    begin
        PurchasesPayablesSetup.Get();

        if GenJournalLine."Document Type" = GenJournalLine."Document Type"::Invoice then
            DefaultGLAccount := PurchasesPayablesSetup."Debit Acc. for Non-Item Lines";
        if GenJournalLine."Document Type" = GenJournalLine."Document Type"::"Credit Memo" then
            DefaultGLAccount := PurchasesPayablesSetup."Credit Acc. for Non-Item Lines";

        if DefaultGLAccount = '' then
            ErrorMessage.LogMessage(TextToAccountMapping, TextToAccountMapping.FieldNo("Mapping Text"),
              ErrorMessage."Message Type"::Error,
              StrSubstNo(NoDebitAccountMappingErr, FieldName, VendorName))
        else begin
            GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"G/L Account");
            GenJournalLine.Validate("Account No.", DefaultGLAccount);
        end;
    end;

    local procedure VerifyCurrency(CurrencyCode: Code[10]; PostingDate: Date): Boolean
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        if not Currency.Get(CurrencyCode) then begin
            ErrorMessage.LogMessage(
              Currency, Currency.FieldNo(Code),
              ErrorMessage."Message Type"::Error, StrSubstNo(CurrencyDoesNotExistErr, IncomingDocument."Currency Code"));
            exit(false)
        end;
        if not CurrencyExchangeRate.CurrencyExchangeRateExist(IncomingDocument."Currency Code", IncomingDocument."Document Date") then begin
            ErrorMessage.LogMessage(
              Currency, CurrencyExchangeRate.FieldNo("Exchange Rate Amount"),
              ErrorMessage."Message Type"::Error, StrSubstNo(CurrencyExchangeDoesNotExistErr, CurrencyCode, PostingDate));
            exit(false);
        end;
        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJnlLineInsertFromIncomingDocument(var GenJournalLine: Record "Gen. Journal Line"; IncomingDocument: Record "Incoming Document")
    begin
    end;
}

