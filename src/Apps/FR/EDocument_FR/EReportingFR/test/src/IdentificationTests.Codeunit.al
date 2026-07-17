// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Formats;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Company;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

codeunit 148146 "Identification Tests"
{
    Subtype = Test;
    Permissions = tabledata "Company Information" = rimd,
                  tabledata "E-Document" = rimd,
                  tabledata "E-Document Service" = rimd,
                  tabledata "Sales Invoice Header" = rimd,
                  tabledata "Cust. Ledger Entry" = rimd,
                  tabledata "Detailed Cust. Ledg. Entry" = rimd,
                  tabledata "FR E-Invoice Lifecycle" = rimd;

    trigger OnRun()
    begin
        // [FEATURE] [FR Identification]
    end;

    var
        Assert: Codeunit Assert;
        EDocHelpers: Codeunit "EDoc. Helpers";

    [Test]
    procedure CheckSIRENNotEmptyRaisesErrorWhenEmpty()
    var
        CompanyInformation: Record "Company Information";
        OriginalRegistrationNo: Text[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] CheckSIRENNotEmpty raises error when Registration No. is blank

        // [GIVEN] Company Information with blank Registration No.
        CompanyInformation.Get();
        OriginalRegistrationNo := CompanyInformation."Registration No.";
        CompanyInformation."Registration No." := '';
        CompanyInformation.Modify();

        // [WHEN] CheckSIRENNotEmpty is called
        // [THEN] Error is raised
        asserterror EDocHelpers.CheckSIRENNotEmpty();
        Assert.ExpectedError('Registration No. must be specified in Company Information for French e-invoicing.');

        // Cleanup
        CompanyInformation.Get();
        CompanyInformation."Registration No." := CopyStr(OriginalRegistrationNo, 1, MaxStrLen(CompanyInformation."Registration No."));
        CompanyInformation.Modify();
    end;

    [Test]
    procedure CheckSIRETNotEmptyRaisesErrorWhenEmpty()
    var
        CompanyInformation: Record "Company Information";
        OriginalSIRETNo: Code[14];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] CheckSIRETNotEmpty raises error when SIRET is blank

        // [GIVEN] Company Information with blank SIRET No.
        CompanyInformation.Get();
        OriginalSIRETNo := CompanyInformation."SIRET No.";
        CompanyInformation."SIRET No." := '';
        CompanyInformation.Modify();

        // [WHEN] CheckSIRETNotEmpty is called
        // [THEN] Error is raised
        asserterror EDocHelpers.CheckSIRETNotEmpty();
        Assert.ExpectedError('SIRET No. must be specified in Company Information for French e-invoicing.');

        // Cleanup
        CompanyInformation.Get();
        CompanyInformation."SIRET No." := OriginalSIRETNo;
        CompanyInformation.Modify();
    end;

    [Test]
    procedure CheckSIRENNotEmptyDoesNotErrorWhenRegistrationNoPresent()
    var
        CompanyInformation: Record "Company Information";
        OriginalRegistrationNo: Text[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] CheckSIRENNotEmpty succeeds when Registration No. is set

        // [GIVEN] Company Information with Registration No. set
        CompanyInformation.Get();
        OriginalRegistrationNo := CompanyInformation."Registration No.";
        CompanyInformation."Registration No." := '123456789';
        CompanyInformation.Modify();

        // [WHEN] CheckSIRENNotEmpty is called
        // [THEN] No error is raised
        EDocHelpers.CheckSIRENNotEmpty();

        // Cleanup
        CompanyInformation.Get();
        CompanyInformation."Registration No." := CopyStr(OriginalRegistrationNo, 1, MaxStrLen(CompanyInformation."Registration No."));
        CompanyInformation.Modify();
    end;

    [Test]
    procedure CheckSIRETNotEmptyDoesNotErrorWhenSIRETPresent()
    var
        CompanyInformation: Record "Company Information";
        OriginalSIRETNo: Code[14];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] CheckSIRETNotEmpty succeeds when SIRET No. is set

        // [GIVEN] Company Information with SIRET No. set
        CompanyInformation.Get();
        OriginalSIRETNo := CompanyInformation."SIRET No.";
        CompanyInformation."SIRET No." := '12345678901234';
        CompanyInformation.Modify();

        // [WHEN] CheckSIRETNotEmpty is called
        // [THEN] No error is raised
        EDocHelpers.CheckSIRETNotEmpty();

        // Cleanup
        CompanyInformation.Get();
        CompanyInformation."SIRET No." := OriginalSIRETNo;
        CompanyInformation.Modify();
    end;

    [Test]
    procedure CaptureCollectedOccurrenceCreatesCapturedLifecycle()
    var
        EDocument: Record "E-Document";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
        SourceOccurrenceID: Guid;
    begin
        // [SCENARIO] A payment application is captured as an immutable Collected lifecycle occurrence
        CreateEDocument(EDocument);
        SourceOccurrenceID := CreateGuid();

        FREInvoiceLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, SourceOccurrenceID,
            1250, 'EUR', WorkDate(), 0, 0, 0, 0);

        Assert.AreEqual(EDocument."Entry No", FREInvoiceLifecycle."E-Document Entry No.", 'The e-document entry must be retained.');
        Assert.AreEqual(1250, FREInvoiceLifecycle."Reported Amount", 'The reported amount must be retained.');
        Assert.AreEqual('EUR', FREInvoiceLifecycle."Currency Code", 'The currency code must be retained.');
        Assert.AreEqual(FREInvoiceLifecycle."Processing Status"::Captured, FREInvoiceLifecycle."Processing Status", 'A new occurrence must be captured.');
        Assert.IsTrue(FREInvoiceLifecycle."Created At" <> 0DT, 'The creation timestamp must be populated.');
    end;

    [Test]
    procedure CaptureCollectedOccurrenceReplayReturnsExistingLifecycle()
    var
        EDocument: Record "E-Document";
        FirstLifecycle: Record "FR E-Invoice Lifecycle";
        ReplayedLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
        SourceOccurrenceID: Guid;
    begin
        // [SCENARIO] Replaying the same payment event does not create a duplicate occurrence
        CreateEDocument(EDocument);
        SourceOccurrenceID := CreateGuid();
        FirstLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, SourceOccurrenceID,
            1250, 'EUR', WorkDate(), 0, 0, 0, 0);

        ReplayedLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, SourceOccurrenceID,
            1250, 'EUR', WorkDate(), 0, 0, 0, 0);

        Assert.AreEqual(FirstLifecycle."Entry No.", ReplayedLifecycle."Entry No.", 'An identical replay must return the existing occurrence.');
    end;

    [Test]
    procedure CaptureCollectedOccurrenceRejectsConflictingReplay()
    var
        EDocument: Record "E-Document";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
        SourceOccurrenceID: Guid;
    begin
        // [SCENARIO] A replay with the same identity but different regulatory values is rejected
        CreateEDocument(EDocument);
        SourceOccurrenceID := CreateGuid();
        FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, SourceOccurrenceID,
            1250, 'EUR', WorkDate(), 0, 0, 0, 0);

        asserterror FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, SourceOccurrenceID,
            1200, 'EUR', WorkDate(), 0, 0, 0, 0);

        Assert.ExpectedError('The payment lifecycle occurrence was already captured with different values.');
    end;

    [Test]
    procedure CaptureNegativeCollectedLinksExactReversal()
    var
        EDocument: Record "E-Document";
        CollectedLifecycle: Record "FR E-Invoice Lifecycle";
        NegativeCollectedLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
    begin
        // [SCENARIO] Unapplication creates a separate Negative Collected occurrence linked to Collected
        CreateEDocument(EDocument);
        CollectedLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, CreateGuid(),
            1250, 'EUR', WorkDate(), 0, 0, 0, 0);

        NegativeCollectedLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::"Negative Collected", CreateGuid(),
            -1250, 'EUR', WorkDate(), 0, 0, 0, CollectedLifecycle."Entry No.");

        Assert.AreEqual(CollectedLifecycle."Entry No.", NegativeCollectedLifecycle."Original Occurrence Entry No.", 'The reversal must reference the Collected occurrence.');
        Assert.AreEqual(-CollectedLifecycle."Reported Amount", NegativeCollectedLifecycle."Reported Amount", 'The reversal must negate the original amount.');
    end;

    [Test]
    procedure CaptureNegativeCollectedRejectsDifferentAmount()
    var
        EDocument: Record "E-Document";
        CollectedLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
    begin
        // [SCENARIO] Negative Collected cannot reverse a different amount than its original occurrence
        CreateEDocument(EDocument);
        CollectedLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, CreateGuid(),
            1250, 'EUR', WorkDate(), 0, 0, 0, 0);

        asserterror FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::"Negative Collected", CreateGuid(),
            -1200, 'EUR', WorkDate(), 0, 0, 0, CollectedLifecycle."Entry No.");

        Assert.ExpectedError('A Negative Collected occurrence must exactly reverse the reported amount of the original Collected occurrence.');
    end;

    [Test]
    procedure CapturedOccurrenceRejectsRegulatoryValueChanges()
    var
        EDocument: Record "E-Document";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
    begin
        // [SCENARIO] Captured regulatory values cannot be changed in place
        CreateEDocument(EDocument);
        FREInvoiceLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, CreateGuid(),
            1250, 'EUR', WorkDate(), 0, 0, 0, 0);

        FREInvoiceLifecycle."Reported Amount" := 1200;
        asserterror FREInvoiceLifecycle.Modify();

        Assert.ExpectedError('The regulatory identity and values of a French electronic invoice lifecycle occurrence cannot be changed.');
    end;

    [Test]
    procedure DetailedApplicationCapturesCollectedForFREInvoice()
    var
        EDocument: Record "E-Document";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
    begin
        // [SCENARIO] Applying a payment to a French electronic invoice captures a Collected occurrence
        CreatePostedInvoiceApplication(EDocument, DetailedCustLedgEntry, "E-Document Format"::"Factur-X FR");

        FREInvoiceLifecycleMgt.ProcessDetailedLedgerApplication(DetailedCustLedgEntry);

        FREInvoiceLifecycle.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceLifecycle.FindFirst();
        Assert.AreEqual(FREInvoiceLifecycle."Lifecycle Status"::Collected, FREInvoiceLifecycle."Lifecycle Status", 'A payment application must create a Collected occurrence.');
        Assert.AreEqual(1250, FREInvoiceLifecycle."Reported Amount", 'The collected amount must be positive.');
        Assert.AreEqual(DetailedCustLedgEntry."Entry No.", FREInvoiceLifecycle."Detailed Ledger Entry No.", 'The source detail entry must be retained.');
        Assert.AreEqual(DetailedCustLedgEntry.SystemId, FREInvoiceLifecycle."Source Occurrence ID", 'The detail entry system ID must identify the occurrence.');
    end;

    [Test]
    procedure DetailedApplicationIgnoresNonFREInvoice()
    var
        EDocument: Record "E-Document";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
    begin
        // [SCENARIO] Applying a payment to an electronic invoice in a non-French format creates no French lifecycle occurrence
        CreatePostedInvoiceApplication(EDocument, DetailedCustLedgEntry, "E-Document Format"::"PEPPOL BIS 3.0");

        FREInvoiceLifecycleMgt.ProcessDetailedLedgerApplication(DetailedCustLedgEntry);

        FREInvoiceLifecycle.SetRange("E-Document Entry No.", EDocument."Entry No");
        Assert.RecordIsEmpty(FREInvoiceLifecycle);
    end;

    [Test]
    procedure DetailedUnapplicationCapturesLinkedNegativeCollected()
    var
        EDocument: Record "E-Document";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        NewDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CollectedLifecycle: Record "FR E-Invoice Lifecycle";
        NegativeCollectedLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
    begin
        // [SCENARIO] Unapplying a captured payment creates an exact linked Negative Collected occurrence
        CreatePostedInvoiceApplication(EDocument, DetailedCustLedgEntry, "E-Document Format"::"Peppol BIS 3.0 FR");
        FREInvoiceLifecycleMgt.ProcessDetailedLedgerApplication(DetailedCustLedgEntry);
        CollectedLifecycle.SetRange("E-Document Entry No.", EDocument."Entry No");
        CollectedLifecycle.FindFirst();
        CreateUnapplicationDetail(NewDetailedCustLedgEntry, DetailedCustLedgEntry);

        FREInvoiceLifecycleMgt.ProcessDetailedLedgerUnapplication(DetailedCustLedgEntry, NewDetailedCustLedgEntry);

        NegativeCollectedLifecycle.SetRange("E-Document Entry No.", EDocument."Entry No");
        NegativeCollectedLifecycle.SetRange("Lifecycle Status", NegativeCollectedLifecycle."Lifecycle Status"::"Negative Collected");
        NegativeCollectedLifecycle.FindFirst();
        Assert.AreEqual(-CollectedLifecycle."Reported Amount", NegativeCollectedLifecycle."Reported Amount", 'The unapplication must exactly negate the collected amount.');
        Assert.AreEqual(CollectedLifecycle."Entry No.", NegativeCollectedLifecycle."Original Occurrence Entry No.", 'The unapplication must reference the Collected occurrence.');
        Assert.AreEqual(NewDetailedCustLedgEntry."Entry No.", NegativeCollectedLifecycle."Detailed Ledger Entry No.", 'The unapplication detail entry must be retained.');
    end;

    local procedure CreateEDocument(var EDocument: Record "E-Document")
    begin
        EDocument.Init();
        EDocument."Document No." := CopyStr(CreateGuid(), 1, MaxStrLen(EDocument."Document No."));
        EDocument."Document Type" := EDocument."Document Type"::"Sales Invoice";
        EDocument.Direction := EDocument.Direction::Outgoing;
        EDocument.Insert();
    end;

    local procedure CreatePostedInvoiceApplication(var EDocument: Record "E-Document"; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; EDocumentFormat: Enum "E-Document Format")
    var
        EDocumentService: Record "E-Document Service";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        InvoiceCustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentCustLedgerEntry: Record "Cust. Ledger Entry";
        DocumentNo: Code[20];
    begin
        DocumentNo := CopyStr(CreateGuid(), 1, MaxStrLen(DocumentNo));
        SalesInvoiceHeader."No." := DocumentNo;
        SalesInvoiceHeader.Insert();

        EDocumentService.Code := CopyStr(CreateGuid(), 1, MaxStrLen(EDocumentService.Code));
        EDocumentService."Document Format" := EDocumentFormat;
        EDocumentService.Insert();

        EDocument."Document Record ID" := SalesInvoiceHeader.RecordId;
        EDocument."Document No." := DocumentNo;
        EDocument."Document Type" := EDocument."Document Type"::"Sales Invoice";
        EDocument.Direction := EDocument.Direction::Outgoing;
        EDocument.Service := EDocumentService.Code;
        EDocument.Insert();

        InvoiceCustLedgerEntry."Entry No." := GetNextCustLedgerEntryNo();
        InvoiceCustLedgerEntry."Document Type" := InvoiceCustLedgerEntry."Document Type"::Invoice;
        InvoiceCustLedgerEntry."Document No." := DocumentNo;
        InvoiceCustLedgerEntry.Insert();

        PaymentCustLedgerEntry."Entry No." := InvoiceCustLedgerEntry."Entry No." + 1;
        PaymentCustLedgerEntry."Document Type" := PaymentCustLedgerEntry."Document Type"::Payment;
        PaymentCustLedgerEntry."Document No." := CopyStr(CreateGuid(), 1, MaxStrLen(PaymentCustLedgerEntry."Document No."));
        PaymentCustLedgerEntry.Insert();

        DetailedCustLedgEntry."Entry No." := GetNextDetailedCustLedgerEntryNo();
        DetailedCustLedgEntry."Cust. Ledger Entry No." := InvoiceCustLedgerEntry."Entry No.";
        DetailedCustLedgEntry."Applied Cust. Ledger Entry No." := PaymentCustLedgerEntry."Entry No.";
        DetailedCustLedgEntry."Entry Type" := DetailedCustLedgEntry."Entry Type"::Application;
        DetailedCustLedgEntry."Initial Document Type" := DetailedCustLedgEntry."Initial Document Type"::Invoice;
        DetailedCustLedgEntry.Amount := -1250;
        DetailedCustLedgEntry."Currency Code" := 'EUR';
        DetailedCustLedgEntry."Posting Date" := WorkDate();
        DetailedCustLedgEntry.Insert(true);
    end;

    local procedure CreateUnapplicationDetail(var NewDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
        NewDetailedCustLedgEntry := DetailedCustLedgEntry;
        NewDetailedCustLedgEntry."Entry No." := GetNextDetailedCustLedgerEntryNo();
        NewDetailedCustLedgEntry.Amount := -DetailedCustLedgEntry.Amount;
        NewDetailedCustLedgEntry."Posting Date" := WorkDate() + 1;
        NewDetailedCustLedgEntry.Unapplied := true;
        NewDetailedCustLedgEntry."Unapplied by Entry No." := DetailedCustLedgEntry."Entry No.";
        NewDetailedCustLedgEntry.Insert(true);
    end;

    local procedure GetNextCustLedgerEntryNo(): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if CustLedgerEntry.FindLast() then
            exit(CustLedgerEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure GetNextDetailedCustLedgerEntryNo(): Integer
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        if DetailedCustLedgEntry.FindLast() then
            exit(DetailedCustLedgEntry."Entry No." + 1);
        exit(1);
    end;
}
