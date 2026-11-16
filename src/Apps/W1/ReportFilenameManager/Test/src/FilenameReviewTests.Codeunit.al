// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.Assembly.History;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.Reporting.FileNaming;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;
using System.EMail;
using System.Environment;
using System.Reflection;
using System.TestLibraries.Security.AccessControl;
using System.Threading;
using System.Utilities;

codeunit 149534 "Filename Review Tests"
{
    // Regression tests. Expected names come from Base Application's own output where it has one;
    // the rebuilt default that OnlyBusinessCentralsDefaultIsRecognised uses is itself checked
    // against it by TheRebuiltDefaultIsTheNameBaseApplicationBuilds.

    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure TestDocumentsDoNotRequireDemoPostingSetup()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        TaxGroup: Record "Tax Group";
        GLAccount: Record "G/L Account";
        SalesSetup: Record "Sales & Receivables Setup";
        PurchaseSetup: Record "Purchases & Payables Setup";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        FilenameProofGuard: Codeunit "Filename Proof Guard";
    begin
        FilenameProofGuard.AssertSafeEnvironment();
        GeneralPostingSetup.DeleteAll();
        VATPostingSetup.DeleteAll();
        TaxGroup.DeleteAll();
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Inv. Rounding Precision (LCY)" := 0;
        GeneralLedgerSetup."VAT Reporting Date Usage" := GeneralLedgerSetup."VAT Reporting Date Usage"::Enabled;
        GeneralLedgerSetup.Modify();
        SalesSetup.Get();
        SalesSetup."Invoice Nos." := '';
        SalesSetup."Posted Invoice Nos." := '';
        SalesSetup.Modify();
        PurchaseSetup.Get();
        PurchaseSetup."Invoice Nos." := '';
        PurchaseSetup."Posted Invoice Nos." := '';
        PurchaseSetup.Modify();

        TestData.PostNewInvoice(SalesInvoiceHeader);
        TestData.PostNewPurchaseInvoice(PurchInvHeader);

        SalesInvoiceHeader.TestField("No.");
        PurchInvHeader.TestField("No.");
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Inv. Rounding Precision (LCY)", 0.01);
        GeneralLedgerSetup.TestField("VAT Reporting Date Usage", GeneralLedgerSetup."VAT Reporting Date Usage"::Disabled);
        if TaxGroup.IsEmpty() then
            Error(MissingTestSetupErr);
        if GeneralPostingSetup.IsEmpty() or VATPostingSetup.IsEmpty() or (GLAccount.Count() < 3) then
            Error(MissingTestSetupErr);
    end;

    [Test]
    procedure InvoiceReportSelectionDoesNotDependOnCountryDemoData()
    var
        ReportSelections: Record "Report Selections";
    begin
        Prepare();
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"S.Invoice");
        ReportSelections.DeleteAll();
        ReportSelections.Init();
        ReportSelections.Usage := ReportSelections.Usage::"S.Invoice";
        ReportSelections.Sequence := '1';
        ReportSelections."Report ID" := Report::"Filename Proof Report";
        ReportSelections.Insert();

        TestData.SetupInvoiceReport();

        ReportSelections.FindFirst();
        ReportSelections.TestField("Report ID", Report::"Standard Sales - Invoice");
        if ReportSelections.Count() <> 1 then
            Error(UnexpectedInvoiceSelectionsErr);
    end;

    [Test]
    procedure RepeatedSetupReturnsDistinctInvoicesWithTheirOwnAmounts()
    var
        FirstInvoice: Record "Sales Invoice Header";
        SecondInvoice: Record "Sales Invoice Header";
        SalesSetup: Record "Sales & Receivables Setup";
        PreviousSalesSetup: Record "Sales & Receivables Setup";
        CustomerNo: Code[20];
    begin
        Prepare();
        CustomerNo := TestData.CreateCustomer();
        PreviousSalesSetup.Get();
        TestData.PostNewInvoice(CustomerNo, '', '', 100, FirstInvoice);
        TestData.PostNewInvoice(CustomerNo, '', '', 250, SecondInvoice);

        SalesSetup.Get();
        SalesSetup.TestField("Customer Nos.", PreviousSalesSetup."Customer Nos.");
        SalesSetup.TestField("Invoice Nos.", PreviousSalesSetup."Invoice Nos.");
        SalesSetup.TestField("S. Invoice Template Name", PreviousSalesSetup."S. Invoice Template Name");
        SalesSetup.TestField("S. Cr. Memo Template Name", PreviousSalesSetup."S. Cr. Memo Template Name");
        if FirstInvoice."No." = SecondInvoice."No." then
            Error(SamePostedInvoiceErr);
        if FirstInvoice."Pre-Assigned No." = SecondInvoice."Pre-Assigned No." then
            Error(SameDraftInvoiceErr);
        FirstInvoice.CalcFields(Amount);
        SecondInvoice.CalcFields(Amount);
        FirstInvoice.TestField(Amount, 100);
        SecondInvoice.TestField(Amount, 250);
    end;

    [Test]
    procedure PurchaseInvoiceReportSelectionDoesNotDependOnCountryDemoData()
    var
        ReportSelections: Record "Report Selections";
        ReportMetadata: Record "Report Metadata";
    begin
        Prepare();
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"P.Invoice");
        ReportSelections.DeleteAll();
        ReportSelections.Init();
        ReportSelections.Usage := ReportSelections.Usage::"P.Invoice";
        ReportSelections.Sequence := '1';
        ReportSelections."Report ID" := Report::"Filename Proof Report";
        ReportSelections.Insert();

        TestData.SetupPurchaseInvoiceReport();

        ReportSelections.FindFirst();
        ReportSelections.TestField("Report ID", Report::"Purchase - Invoice");
        if ReportSelections.Count() <> 1 then
            Error(UnexpectedInvoiceSelectionsErr);
        ReportMetadata.Get(ReportSelections."Report ID");
        ReportMetadata.TestField(ProcessingOnly, false);
    end;

    [Test]
    procedure DocumentReportsAreRenderableAndSurviveDocumentCreation()
    var
        ReportSelections: Record "Report Selections";
        ReportMetadata: Record "Report Metadata";
        Invoice: Record "Sales Invoice Header";
        Usages: List of [Enum "Report Selection Usage"];
        Usage: Enum "Report Selection Usage";
    begin
        Prepare();
        Usages.Add(Usage::"S.Invoice");
        Usages.Add(Usage::"P.Invoice");
        Usages.Add(Usage::"S.Invoice Draft");
        Usages.Add(Usage::"S.Quote");
        foreach Usage in Usages do begin
            ReportSelections.Reset();
            ReportSelections.SetRange(Usage, Usage);
            ReportSelections.ModifyAll("Report ID", Report::"Filename Proof Report");
        end;

        TestData.SetupDocumentReports();
        foreach Usage in Usages do begin
            ReportSelections.Reset();
            ReportSelections.SetRange(Usage, Usage);
            ReportSelections.FindFirst();
            if ReportSelections.Count() <> 1 then
                Error(UnexpectedInvoiceSelectionsErr);
            ReportMetadata.Get(ReportSelections."Report ID");
            ReportMetadata.TestField(ProcessingOnly, false);
            if ReportSelections."Report ID" = Report::"Filename Proof Report" then
                Error(DocumentReportNotReplacedErr);
        end;

        ReportSelections.Reset();
        ReportSelections.Get(Usage::"S.Invoice", '1');
        ReportSelections.Sequence := '2';
        ReportSelections.Insert();
        TestData.PostNewInvoice(Invoice);
        ReportSelections.Get(Usage::"S.Invoice", '2');
        ReportSelections.TestField("Report ID", Report::"Standard Sales - Invoice");
    end;

    [Test]
    procedure CustomPaymentTermsSupportPosting()
    var
        Invoice: Record "Sales Invoice Header";
        PaymentTerms: Record "Payment Terms";
        CustomerNo: Code[20];
        PaymentTermsCode: Code[10];
    begin
        Prepare();
        CustomerNo := TestData.CreateCustomer();
        PaymentTermsCode := TestData.CreatePaymentTerms(PaymentTermsDescriptionTok);

        TestData.PostNewInvoice(CustomerNo, '', PaymentTermsCode, Invoice);

        Invoice.TestField("Payment Terms Code", PaymentTermsCode);
        PaymentTerms.Get(PaymentTermsCode);
        PaymentTerms.TestField(Description, PaymentTermsDescriptionTok);
        Invoice.CalcFields(Amount);
        Invoice.TestField(Amount, 100);
    end;

    [Test]
    procedure ObsoleteTablesAreNotOfferedAsReportSubjects()
    var
        TableMetadata: Record "Table Metadata";
        TempTableBuffer: Record "Report Filename Table Buffer" temporary;
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        PlaceholderMgt: Codeunit "Report Filename Plh. Mgt.";
    begin
        PlaceholderMgt.BuildTables(TempTableBuffer);
        TableMetadata.SetFilter(ObsoleteState, '<>%1', TableMetadata.ObsoleteState::No);
        if TableMetadata.FindSet() then
            repeat
                if ReportFilenameMgt.IsNamableTable(TableMetadata.ID) or TempTableBuffer.Get(TableMetadata.ID) then
                    Error(ObsoleteTableOfferedErr, TableMetadata.ID);
            until TableMetadata.Next() = 0;
    end;

    /// <summary>
    /// For a user who cannot read Report Selections, the email name is Business Central's own with the
    /// feature off or on, and no permission error is raised.
    /// </summary>
    [Test]
    procedure ARestrictedUserGetsTheStandardEmailNameWithTheFeatureOffOrOn()
    var
        Pattern: Record "Report Filename Pattern";
        ReportSelections: Record "Report Selections";
        DocumentMailing: Codeunit "Document-Mailing";
        PermissionsMock: Codeunit "Permissions Mock";
        Baseline: Text[250];
        Name: Text[250];
    begin
        Prepare();
        ReviewSupport.AddPattern(Pattern, ReviewSupport.InvoiceReportId(), EmailPatternTok, Enum::"Report Filename Output Route"::Email);
        ReviewSupport.SetFeature(false);
        DocumentMailing.GetAttachmentFileName(Baseline, UnknownDocumentNoTok, EmailDocumentNameTok, InvoiceUsage());

        PermissionsMock.Set(RestrictedSetTok);
        // Control: a user who can read Report Selections proves nothing.
        if ReportSelections.ReadPermission() then
            Error(UserCanReadReportSelectionsErr);
        DocumentMailing.GetAttachmentFileName(Name, UnknownDocumentNoTok, EmailDocumentNameTok, InvoiceUsage());
        PermissionsMock.ClearAssignments();
        if Name <> Baseline then
            Error(WrongNameErr, Baseline, Name);

        ReviewSupport.SetFeature(true);
        Clear(Name);
        PermissionsMock.Set(RestrictedSetTok);
        DocumentMailing.GetAttachmentFileName(Name, UnknownDocumentNoTok, EmailDocumentNameTok, InvoiceUsage());
        PermissionsMock.ClearAssignments();
        if Name <> Baseline then
            Error(WrongNameErr, Baseline, Name);
    end;

    /// <summary>
    /// The platform's print naming hook, for a user who cannot read the document: no error and no name,
    /// feature off or on. The pattern needs a field the filter does not carry, so naming must read the document.
    /// </summary>
    [Test]
    procedure ARestrictedUserPrintsWithTheStandardNameWithTheFeatureOffOrOn()
    var
        Pattern: Record "Report Filename Pattern";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ProofSupport: Codeunit "Filename Proof Support";
        Payload: JsonObject;
    begin
        Prepare();
        ReviewSupport.AddPattern(Pattern, Report::"Standard Sales - Invoice", PrintPatternTok, Enum::"Report Filename Output Route"::Print);
        TestData.PostNewInvoice(SalesInvoiceHeader);
        Payload.ReadFrom(StrSubstNo(PrintPayloadTok, ProofSupport.InvoiceFilterViews(SalesInvoiceHeader)));

        ReviewSupport.SetFeature(false);
        ExpectNoPrintName(Payload);
        ReviewSupport.SetFeature(true);
        ExpectNoPrintName(Payload);
    end;

    /// <summary>
    /// Send to Disk naming for a user who cannot read the document: no error and Business Central's own
    /// name, feature off or on. A real Send to Disk cannot run for this user (Base Application reads
    /// Report Selections first), so the vendor/zip-PDF and customer naming points are called directly.
    /// </summary>
    [Test]
    procedure ARestrictedUserGetsTheStandardSendToDiskNameWithTheFeatureOffOrOn()
    var
        Pattern: Record "Report Filename Pattern";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        Baseline: Text;
    begin
        Prepare();
        ReviewSupport.AddPattern(Pattern, ReviewSupport.InvoiceReportId(), DiskPatternTok, Enum::"Report Filename Output Route"::Any);
        TestData.PostNewInvoice(SalesInvoiceHeader);

        ReviewSupport.SetFeature(false);
        Baseline := ElectronicDocumentFormat.GetAttachmentFileName(SalesInvoiceHeader, SalesInvoiceHeader."No.", InvoiceDocumentNameTok, PdfCodeTok);

        ExpectStandardSendToDiskName(SalesInvoiceHeader, Baseline, false);
        ReviewSupport.SetFeature(true);
        ExpectStandardSendToDiskName(SalesInvoiceHeader, Baseline, true);
    end;

    /// <summary>
    /// The patterns list's "no pattern" notification is withdrawn as soon as the list shows a pattern.
    /// </summary>
    [Test]
    [HandlerFunctions('EmptyNoticeSentHandler,EmptyNoticeRecalledHandler')]
    procedure ThePatternsListWithdrawsItsEmptyNoticeOnceAPatternIsAdded()
    var
        Pattern: Record "Report Filename Pattern";
        PatternsPage: TestPage "Report Filename Patterns";
    begin
        Prepare();
        Clear(EmptyNoticeSentId);
        EmptyNoticeRecalled := false;

        PatternsPage.OpenView();
        ReviewSupport.AddPattern(Pattern, ReviewSupport.InvoiceReportId(), EmailPatternTok, Enum::"Report Filename Output Route"::Any);
        // Re-reads the rows, as the list does when the pattern's card closes.
        PatternsPage.Filter.SetFilter("Entry No.", Format(Pattern."Entry No."));
        if not PatternsPage.First() then
            Error(EmptyNoticeErr, 'test could not show the new pattern on the list');
        PatternsPage.Close();

        if IsNullGuid(EmptyNoticeSentId) then
            Error(EmptyNoticeErr, 'was not sent when the list opened empty');
        if not EmptyNoticeRecalled then
            Error(EmptyNoticeErr, 'was not withdrawn once the list showed a pattern');
    end;

    /// <summary>
    /// Enabled Patterns is recounted when the patterns list opened from the setup closes. A test page
    /// cannot reproduce the client's timing, so this proves the list opens modally and the count is
    /// right afterwards.
    /// </summary>
    [Test]
    [HandlerFunctions('AddPatternOnTheListHandler,EmptyNoticeSentHandler')]
    procedure TheSetupCountsEnabledPatternsAgainWhenThePatternsListCloses()
    var
        SetupPage: TestPage "Report Filename Setup";
    begin
        Prepare();
        SetupPage.OpenEdit();
        SetupPage."Enabled Patterns".AssertEquals(0);
        SetupPage.Patterns.Invoke();
        SetupPage."Enabled Patterns".AssertEquals(1);
        SetupPage.Close();
    end;

    [SendNotificationHandler]
    procedure EmptyNoticeSentHandler(var Notification: Notification): Boolean
    begin
        EmptyNoticeSentId := Notification.Id();
        exit(true);
    end;

    [RecallNotificationHandler]
    procedure EmptyNoticeRecalledHandler(var Notification: Notification): Boolean
    begin
        // The notice withdrawn must be the one sent.
        EmptyNoticeRecalled := Notification.Id() = EmptyNoticeSentId;
        exit(true);
    end;

    [ModalPageHandler]
    procedure AddPatternOnTheListHandler(var PatternsPage: TestPage "Report Filename Patterns")
    var
        Pattern: Record "Report Filename Pattern";
    begin
        ReviewSupport.AddPattern(Pattern, ReviewSupport.InvoiceReportId(), EmailPatternTok, Enum::"Report Filename Output Route"::Any);
    end;

    local procedure ExpectNoPrintName(Payload: JsonObject)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ReportingTriggers: Codeunit "Reporting Triggers";
        PermissionsMock: Codeunit "Permissions Mock";
        NoRecord: RecordRef;
        Filename: Text;
        Success: Boolean;
    begin
        PermissionsMock.Set(RestrictedSetTok);
        // Control: a user who can read the invoice proves nothing.
        if SalesInvoiceHeader.ReadPermission() then
            Error(UserCanReadInvoicesErr);
        ReportingTriggers.GetFilename(
            Report::"Standard Sales - Invoice", InvoiceCaptionTok, Payload, '.' + PdfTok, NoRecord, Filename, Success);
        PermissionsMock.ClearAssignments();
        if Success or (Filename <> '') then
            Error(RestrictedUserNamedErr, Filename);
    end;

    local procedure ExpectStandardSendToDiskName(var SalesInvoiceHeader: Record "Sales Invoice Header"; Baseline: Text; FeatureOn: Boolean)
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ReportFilenameContext: Codeunit "Report Filename Context";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        PermissionsMock: Codeunit "Permissions Mock";
        DocumentRecRef: RecordRef;
        Name: Text;
        Resolved: Text;
        ReportId: Integer;
        Active: Boolean;
        IsDefault: Boolean;
        Named: Boolean;
    begin
        // Read with the test's own permissions, as Base Application hands the selection to subscribers.
        ReportId := ReviewSupport.InvoiceReportId();
        // As the selection loop's subscriber records it before the PDF is named.
        DocumentRecRef.GetTable(SalesInvoiceHeader);
        ReportFilenameContext.StartBatch();
        ReportFilenameContext.SetPendingFile(DocumentRecRef, ReportId, '', Enum::"Report Filename Output Route"::Disk);

        PermissionsMock.Set(RestrictedSetTok);
        if SalesInvoiceHeader.ReadPermission() then
            Error(UserCanReadInvoicesErr);
        // Vendor Send to Disk and the zip's PDF.
        Name := ElectronicDocumentFormat.GetAttachmentFileName(SalesInvoiceHeader, SalesInvoiceHeader."No.", InvoiceDocumentNameTok, PdfCodeTok);
        // Customer Send to Disk, the subscriber's steps.
        Active := ReportFilenameMgt.IsActive();
        if Active then begin
            IsDefault := ReportFilenameMgt.IsBusinessCentralsDefaultName(Baseline, InvoiceDocumentNameTok, SalesInvoiceHeader."No.", PdfCodeTok);
            if IsDefault then
                Named := ReportFilenameMgt.TryResolve(ReportId, Enum::"Report Filename Output Route"::Disk, DocumentRecRef, '', Resolved);
        end;
        PermissionsMock.ClearAssignments();

        if Name <> Baseline then
            Error(WrongNameErr, Baseline, Name);
        // With the feature on, the customer's steps must reach resolving the pattern, or nothing is proven.
        if Active <> FeatureOn then
            Error(RestrictedSendToDiskErr, 'IsActive', Active);
        if FeatureOn and not IsDefault then
            Error(RestrictedSendToDiskErr, 'IsBusinessCentralsDefaultName', IsDefault);
        if Named then
            Error(RestrictedUserNamedErr, Resolved);
    end;

    /// <summary>
    /// A PDF named only through GetAttachmentFileName (vendor Send to Disk) takes the pattern, with the
    /// extension lower case as Base Application 30 writes it, though it reaches the event upper case.
    /// </summary>
    [Test]
    procedure AFileNamedThroughGetAttachmentFileNameTakesThePatternAndALowerCaseExtension()
    var
        Pattern: Record "Report Filename Pattern";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ReportFilenameContext: Codeunit "Report Filename Context";
        DocumentRecRef: RecordRef;
        Name: Text;
    begin
        Prepare();
        ReviewSupport.AddPattern(Pattern, ReviewSupport.InvoiceReportId(), DiskPatternTok, Enum::"Report Filename Output Route"::Disk);
        TestData.PostNewInvoice(SalesInvoiceHeader);
        DocumentRecRef.GetTable(SalesInvoiceHeader);

        // As OnSendToDiskForVendOnBeforeSendFileLoop records it before SendToDiskForVend names the file.
        ReportFilenameContext.StartBatch();
        ReportFilenameContext.SetPendingFile(DocumentRecRef, ReviewSupport.InvoiceReportId(), '', Enum::"Report Filename Output Route"::Disk);
        Name := ElectronicDocumentFormat.GetAttachmentFileName(SalesInvoiceHeader, SalesInvoiceHeader."No.", InvoiceDocumentNameTok, PdfCodeTok);

        if Name <> DiskPrefixTok + SalesInvoiceHeader."No." + '.' + PdfTok then
            Error(WrongNameErr, DiskPrefixTok + SalesInvoiceHeader."No." + '.' + PdfTok, Name);
    end;

    /// <summary>
    /// One email attachment holding several invoices is named for all of them, not for one. With no
    /// email address on the customer, SendEmailToCust renders the whole selection into one PDF.
    /// </summary>
    [Test]
    procedure OneEmailAttachmentForSeveralInvoicesIsNamedForAllOfThem()
    var
        Pattern: Record "Report Filename Pattern";
        FirstInvoice: Record "Sales Invoice Header";
        SecondInvoice: Record "Sales Invoice Header";
        Selection: Record "Sales Invoice Header";
        ReportSelections: Record "Report Selections";
        EmailCapture: Codeunit "Filename Email Capture";
        RecordVariant: Variant;
        CustomerNo: Code[20];
        Emails: List of [Text];
        Name: Text;
    begin
        Prepare();
        CustomerNo := TestData.CreateCustomer();
        TestData.PostNewInvoice(CustomerNo, FirstInvoice);
        TestData.PostNewInvoice(CustomerNo, SecondInvoice);
        ReviewSupport.AddPattern(Pattern, ReviewSupport.InvoiceReportId(), EmailPatternTok, Enum::"Report Filename Output Route"::Email);

        Selection.SetFilter("No.", '%1|%2', FirstInvoice."No.", SecondInvoice."No.");
        RecordVariant := Selection;
        EmailCapture.Start(true);
        BindSubscription(EmailCapture);
        // No document number: the email is for the selection, not for one document.
        ReportSelections.SendEmailToCust(InvoiceUsage(), RecordVariant, '', EmailDocumentNameTok, false, CustomerNo);
        UnbindSubscription(EmailCapture);

        // One email with one combined PDF, not one per invoice.
        Emails := EmailCapture.CapturedEmails();
        if (Emails.Count() <> 1) or (EmailCapture.CapturedDownloads().Count() <> 0) then
            Error(NotOneEmailErr, Emails.Count(), EmailCapture.CapturedDownloads().Count());
        Name := Emails.Get(1);
        if StrPos(Name, OneAttachmentTok) <> 1 then
            Error(NotOneEmailErr, 1, Name);
        if (StrPos(Name, FirstInvoice."No.") = 0) or (StrPos(Name, SecondInvoice."No.") = 0) then
            Error(NotNamedForAllErr, FirstInvoice."No.", SecondInvoice."No.", Name);
    end;

    /// <summary>
    /// After Attach as PDF, a file uploaded to the same document keeps the name it was uploaded with,
    /// and so does one uploaded while a report rendered earlier is still remembered.
    /// </summary>
    [Test]
    procedure AFileUploadedAfterAttachAsPdfKeepsItsOwnName()
    var
        Pattern: Record "Report Filename Pattern";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        OtherInvoice: Record "Sales Invoice Header";
        DocumentAttachment: Record "Document Attachment";
        ReportSelections: Record "Report Selections";
        ReportFilenameContext: Codeunit "Report Filename Context";
        TempBlob: Codeunit "Temp Blob";
        DocumentRecRef: RecordRef;
        RecordVariant: Variant;
    begin
        Prepare();
        ReviewSupport.AddPattern(Pattern, ReviewSupport.InvoiceReportId(), AttachPatternTok, Enum::"Report Filename Output Route"::AttachAsPdf);
        TestData.PostNewInvoice(SalesInvoiceHeader);
        // The other document armed in the last step.
        TestData.PostNewInvoice(OtherInvoice);
        RecordVariant := SalesInvoiceHeader;
        ReportSelections.SaveAsDocumentAttachment(
            InvoiceUsage(), RecordVariant, SalesInvoiceHeader."No.", SalesInvoiceHeader."Bill-to Customer No.", false);
        ExpectAttachment(SalesInvoiceHeader."No.", AttachPrefixTok + SalesInvoiceHeader."No.", PdfTok);

        DocumentRecRef.GetTable(SalesInvoiceHeader);
        WriteSomething(TempBlob);
        DocumentAttachment.SaveAttachment(DocumentRecRef, UploadedFileTok + '.' + DocxTok, TempBlob);
        ExpectAttachment(SalesInvoiceHeader."No.", UploadedFileTok, DocxTok);

        // A render remembered from earlier in the session (an email, say) is no report attachment.
        ReportFilenameContext.SetRenderedDocument(DocumentRecRef, ReviewSupport.InvoiceReportId());
        Clear(DocumentAttachment);
        DocumentAttachment.SaveAttachment(DocumentRecRef, SecondUploadedFileTok + '.' + DocxTok, TempBlob);
        ReportFilenameContext.ClearLastRendered();
        ExpectAttachment(SalesInvoiceHeader."No.", SecondUploadedFileTok, DocxTok);

        // As a half-failed Attach as PDF leaves it: still marked, one save armed with the same content.
        // A non-PDF upload keeps its name...
        ReportFilenameContext.StartAttachAsPdf();
        ReportFilenameContext.ArmAttachAsPdf(DocumentRecRef.RecordId(), ReviewSupport.InvoiceReportId(), TempBlob);
        Clear(DocumentAttachment);
        DocumentAttachment.SaveAttachment(DocumentRecRef, ThirdUploadedFileTok + '.' + DocxTok, TempBlob);
        ExpectAttachment(SalesInvoiceHeader."No.", ThirdUploadedFileTok, DocxTok);

        // ...and so does a PDF uploaded to a document other than the one armed.
        ReportFilenameContext.ArmAttachAsPdf(OtherInvoice.RecordId(), ReviewSupport.InvoiceReportId(), TempBlob);
        Clear(DocumentAttachment);
        DocumentAttachment.SaveAttachment(DocumentRecRef, UploadedPdfTok + '.' + PdfTok, TempBlob);
        ReportFilenameContext.EndAttachAsPdf();
        ExpectAttachment(SalesInvoiceHeader."No.", UploadedPdfTok, PdfTok);
    end;

    /// <summary>
    /// A PDF uploaded after Attach as PDF failed on the same document (armed, not saved) keeps its name.
    /// </summary>
    [Test]
    procedure APdfUploadedAfterAFailedAttachAsPdfKeepsItsOwnName()
    var
        Pattern: Record "Report Filename Pattern";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentAttachment: Record "Document Attachment";
        ReportSelections: Record "Report Selections";
        ReportFilenameContext: Codeunit "Report Filename Context";
        FailingAttach: Codeunit "Filename Failing Attach";
        TempBlob: Codeunit "Temp Blob";
        DocumentRecRef: RecordRef;
        RecordVariant: Variant;
    begin
        Prepare();
        ReviewSupport.AddPattern(Pattern, ReviewSupport.InvoiceReportId(), AttachPatternTok, Enum::"Report Filename Output Route"::AttachAsPdf);
        TestData.PostNewInvoice(SalesInvoiceHeader);
        RecordVariant := SalesInvoiceHeader;

        BindSubscription(FailingAttach);
        asserterror ReportSelections.SaveAsDocumentAttachment(
            InvoiceUsage(), RecordVariant, SalesInvoiceHeader."No.", SalesInvoiceHeader."Bill-to Customer No.", false);
        UnbindSubscription(FailingAttach);
        if GetLastErrorText() <> FailingAttach.FailureText() then
            Error(UnexpectedAttachErrorErr, GetLastErrorText());

        DocumentRecRef.GetTable(SalesInvoiceHeader);
        WriteSomething(TempBlob);
        DocumentAttachment.SaveAttachment(DocumentRecRef, UploadedFileTok + '.' + PdfTok, TempBlob);
        ReportFilenameContext.EndAttachAsPdf();
        ExpectAttachment(SalesInvoiceHeader."No.", UploadedFileTok, PdfTok);
    end;

    /// <summary>
    /// Customer Send to Disk replaces Business Central's own name (keeping its extension as written),
    /// but keeps a name another extension gave, even with a matching pattern.
    /// </summary>
    [Test]
    procedure SendToDiskNamesBusinessCentralsNameAndKeepsAPartnersName()
    var
        Pattern: Record "Report Filename Pattern";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DiskCapture: Codeunit "Filename Disk Capture";
        PartnerName: Codeunit "Filename Partner Name";
        Baseline: Text;
        Expected: Text;
        Name: Text;
    begin
        Prepare();
        ReviewSupport.AddPattern(Pattern, ReviewSupport.InvoiceReportId(), DiskPatternTok, Enum::"Report Filename Output Route"::Disk);
        TestData.PostNewInvoice(SalesInvoiceHeader);
        BindSubscription(DiskCapture);

        ReviewSupport.SetFeature(false);
        SendToDisk(SalesInvoiceHeader);
        Baseline := DiskCapture.TakeName();
        ReviewSupport.SetFeature(true);

        SendToDisk(SalesInvoiceHeader);
        Name := DiskCapture.TakeName();
        Expected := DiskPrefixTok + SalesInvoiceHeader."No." + SuffixOf(Baseline);
        if Name <> Expected then
            Error(WrongNameErr, Expected, Name);

        BindSubscription(PartnerName);
        SendToDisk(SalesInvoiceHeader);
        Name := DiskCapture.TakeName();
        UnbindSubscription(PartnerName);
        UnbindSubscription(DiskCapture);
        if Name <> PartnerName.PartnerName() then
            Error(PartnerNameOverriddenErr, PartnerName.PartnerName(), Name);
    end;

    /// <summary>
    /// The rebuilt default matches Base Application's name for XML, ZIP and PDF, except the extension's
    /// case (29 writes it upper case, 30 lower case). Fails if GetAttachmentFileName's rule changes.
    /// </summary>
    [Test]
    procedure TheRebuiltDefaultIsTheNameBaseApplicationBuilds()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocumentRecRef: RecordRef;
        DocumentType: Text;
    begin
        // No pattern, so GetAttachmentFileName returns Business Central's own name.
        Prepare();
        TestData.PostNewInvoice(SalesInvoiceHeader);
        DocumentRecRef.GetTable(SalesInvoiceHeader);
        DocumentType := ElectronicDocumentFormat.GetDocumentType(DocumentRecRef);

        ExpectRebuiltDefault(SalesInvoiceHeader, DocumentType, XmlCodeTok);
        ExpectRebuiltDefault(SalesInvoiceHeader, DocumentType, ZipCodeTok);
        ExpectRebuiltDefault(SalesInvoiceHeader, DocumentType, PdfCodeTok);
    end;

    /// <summary>
    /// Only Business Central's default is recognised, with its extension in either case - also when the
    /// 250-character cut reaches into the extension.
    /// </summary>
    [Test]
    procedure OnlyBusinessCentralsDefaultIsRecognised()
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        DefaultName: Text;
        Stem: Text;
        LongDocumentType: Text;
    begin
        DefaultName := ReportFilenameMgt.BusinessCentralsDocumentFileName(InvoiceDocumentNameTok, TestDocumentNoTok, XmlCodeTok);
        Stem := CopyStr(DefaultName, 1, StrLen(DefaultName) - 3);

        ExpectRecognised(Stem + 'xml', InvoiceDocumentNameTok, XmlCodeTok, true, 'xml');
        ExpectRecognised(Stem + 'XML', InvoiceDocumentNameTok, XmlCodeTok, true, 'XML');
        ExpectRecognised(Stem + 'Xml', InvoiceDocumentNameTok, XmlCodeTok, true, 'Xml');
        ExpectRecognised(UpperCase(Stem) + 'xml', InvoiceDocumentNameTok, XmlCodeTok, false, '');
        ExpectRecognised(Stem + 'zip', InvoiceDocumentNameTok, XmlCodeTok, false, '');
        ExpectRecognised(Stem + 'xmlx', InvoiceDocumentNameTok, XmlCodeTok, false, '');
        ExpectRecognised(PartnerXmlNameTok, InvoiceDocumentNameTok, XmlCodeTok, false, '');
        ExpectRecognised('', InvoiceDocumentNameTok, XmlCodeTok, false, '');

        // Long enough that the 250-character cut takes the extension's last letter.
        LongDocumentType := PadStr('', 251 - StrLen(ReportFilenameMgt.BusinessCentralsDocumentFileName('', TestDocumentNoTok, XmlCodeTok)), 'T');
        DefaultName := ReportFilenameMgt.BusinessCentralsDocumentFileName(LongDocumentType, TestDocumentNoTok, XmlCodeTok);
        if CopyStr(DefaultName, StrLen(DefaultName) - 2) <> '.xm' then
            Error(WrongNameErr, '...' + '.xm', DefaultName);
        Stem := CopyStr(DefaultName, 1, StrLen(DefaultName) - 2);
        ExpectRecognised(Stem + 'xm', LongDocumentType, XmlCodeTok, true, 'xm');
        ExpectRecognised(Stem + 'XM', LongDocumentType, XmlCodeTok, true, 'XM');
        ExpectRecognised(Stem + 'xn', LongDocumentType, XmlCodeTok, false, '');
    end;

    /// <summary>
    /// The PDF in a "PDF &amp; Electronic Document" zip takes the electronic document's extension case
    /// (lower case if unseen); vendor Send to Disk is always lower case.
    /// </summary>
    [Test]
    procedure AZipsPdfTakesTheCaseOfItsElectronicDocument()
    var
        Pattern: Record "Report Filename Pattern";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        Prepare();
        ReviewSupport.AddPattern(Pattern, ReviewSupport.InvoiceReportId(), DiskPatternTok, Enum::"Report Filename Output Route"::Any);
        TestData.PostNewInvoice(SalesInvoiceHeader);

        ReportFilenameContext.NoteExtensionCasing(false);
        ExpectPendingPdf(SalesInvoiceHeader, Enum::"Report Filename Output Route"::PdfAndElectronicDocument, DiskPrefixTok + SalesInvoiceHeader."No." + '.PDF');
        ReportFilenameContext.NoteExtensionCasing(true);
        ExpectPendingPdf(SalesInvoiceHeader, Enum::"Report Filename Output Route"::PdfAndElectronicDocument, DiskPrefixTok + SalesInvoiceHeader."No." + '.pdf');
        ReportFilenameContext.ForgetExtensionCasing();
        ExpectPendingPdf(SalesInvoiceHeader, Enum::"Report Filename Output Route"::PdfAndElectronicDocument, DiskPrefixTok + SalesInvoiceHeader."No." + '.pdf');

        ReportFilenameContext.NoteExtensionCasing(false);
        ExpectPendingPdf(SalesInvoiceHeader, Enum::"Report Filename Output Route"::Disk, DiskPrefixTok + SalesInvoiceHeader."No." + '.pdf');
        ReportFilenameContext.ForgetExtensionCasing();
    end;

    local procedure ExpectRebuiltDefault(SalesInvoiceHeader: Record "Sales Invoice Header"; DocumentType: Text; Extension: Code[3])
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        Built: Text;
        Rebuilt: Text;
    begin
        Built := ElectronicDocumentFormat.GetAttachmentFileName(SalesInvoiceHeader, SalesInvoiceHeader."No.", DocumentType, Extension);
        Rebuilt := ReportFilenameMgt.BusinessCentralsDocumentFileName(DocumentType, SalesInvoiceHeader."No.", Extension);
        if (StrLen(Built) <> StrLen(Rebuilt)) or
           (CopyStr(Built, 1, StrLen(Built) - StrLen(Extension)) <> CopyStr(Rebuilt, 1, StrLen(Rebuilt) - StrLen(Extension))) or
           (LowerCase(Built) <> LowerCase(Rebuilt))
        then
            Error(WrongNameErr, Built, Rebuilt);
        if not ReportFilenameMgt.IsBusinessCentralsDefaultName(Built, DocumentType, SalesInvoiceHeader."No.", Extension) then
            Error(NotRecognisedErr, Built, true);
    end;

    local procedure ExpectRecognised(CurrentName: Text; DocumentType: Text; Extension: Code[3]; Expected: Boolean; ExpectedWrittenExtension: Text)
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        WrittenExtension: Text;
    begin
        if ReportFilenameMgt.IsBusinessCentralsDefaultName(CurrentName, DocumentType, TestDocumentNoTok, Extension, WrittenExtension) <> Expected then
            Error(NotRecognisedErr, CurrentName, Expected);
        if WrittenExtension <> ExpectedWrittenExtension then
            Error(WrongNameErr, ExpectedWrittenExtension, WrittenExtension);
    end;

    local procedure ExpectPendingPdf(var SalesInvoiceHeader: Record "Sales Invoice Header"; Channel: Enum "Report Filename Output Route"; Expected: Text)
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ReportFilenameContext: Codeunit "Report Filename Context";
        DocumentRecRef: RecordRef;
        Name: Text;
    begin
        DocumentRecRef.GetTable(SalesInvoiceHeader);
        ReportFilenameContext.StartBatch();
        ReportFilenameContext.SetPendingFile(DocumentRecRef, ReviewSupport.InvoiceReportId(), InvoiceDocumentNameTok, Channel);
        Name := ElectronicDocumentFormat.GetAttachmentFileName(SalesInvoiceHeader, SalesInvoiceHeader."No.", InvoiceDocumentNameTok, PdfCodeTok);
        if Name <> Expected then
            Error(WrongNameErr, Expected, Name);
    end;

    local procedure SuffixOf(FileName: Text): Text
    var
        DotPosition: Integer;
    begin
        DotPosition := FileName.LastIndexOf('.');
        if DotPosition <= 1 then
            exit('');
        exit(CopyStr(FileName, DotPosition));
    end;

    /// <summary>
    /// A scheduled report whose root data item is an Integer loop (report 910: CopyLoop, then Posted
    /// Assembly Header) is named from the filter on the child data item.
    /// </summary>
    [Test]
    [HandlerFunctions('PostedAssemblyOrderRequestPageHandler')]
    procedure AScheduledReportIsNamedFromTheFilterOnAChildDataItem()
    var
        Pattern: Record "Report Filename Pattern";
        JobQueueEntry: Record "Job Queue Entry";
        ReportFilenameInboxMgt: Codeunit "Report Filename Inbox Mgt.";
        Parameters: Text;
        Filename: Text;
    begin
        Prepare();
        InsertPostedAssemblyOrder(FirstAssemblyNoTok);
        InsertPostedAssemblyOrder(SecondAssemblyNoTok);
        ReviewSupport.AddPattern(Pattern, Report::"Posted Assembly Order", AssemblyPatternTok, Enum::"Report Filename Output Route"::Any);

        // A page is not shown with a write transaction open.
        Commit();
        Parameters := Report.RunRequestPage(Report::"Posted Assembly Order");
        ExpectBothDataItems(Parameters);

        // Stored as scheduling stores them; not run, only the name is asked for.
        JobQueueEntry.Init();
        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Report;
        JobQueueEntry."Object ID to Run" := Report::"Posted Assembly Order";
        JobQueueEntry.Insert(false);
        JobQueueEntry.SetReportParameters(Parameters);
        JobQueueEntry.Modify(false);

        if not ReportFilenameInboxMgt.TryResolveForJobQueueEntry(JobQueueEntry, Filename) then
            Error(ScheduledNotNamedErr, AssemblyPrefixTok + FirstAssemblyNoTok);
        if Filename <> AssemblyPrefixTok + FirstAssemblyNoTok then
            Error(WrongNameErr, AssemblyPrefixTok + FirstAssemblyNoTok, Filename);
    end;

    /// <summary>
    /// Clear Report keeps the table, so the pattern covers every report on it.
    /// </summary>
    [Test]
    procedure ClearReportKeepsTheTable()
    var
        Pattern: Record "Report Filename Pattern";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PatternCard: TestPage "Report Filename Pattern Card";
    begin
        Prepare();
        ReviewSupport.AddPattern(Pattern, ReviewSupport.InvoiceReportId(), EmailPatternTok, Enum::"Report Filename Output Route"::Any);

        PatternCard.OpenEdit();
        PatternCard.GoToRecord(Pattern);
        PatternCard.ClearReport.Invoke();
        if PatternCard.ReportName.Value() <> '' then
            Error(ReportNotClearedErr, PatternCard.ReportName.Value());
        if PatternCard.TableCaption.Value() <> SalesInvoiceHeader.TableCaption() then
            Error(TableNotKeptErr, SalesInvoiceHeader.TableCaption(), PatternCard.TableCaption.Value());
        PatternCard.Close();

        Pattern.Get(Pattern."Entry No.");
        if (Pattern."Report ID" <> 0) or (Pattern."Table No." <> Database::"Sales Invoice Header") then
            Error(TableNotKeptErr, SalesInvoiceHeader.TableCaption(), Pattern."Table No.");
    end;

    /// <summary>
    /// Test Pattern shows the tested route's default name: Base Application's for Send to Disk and
    /// Attach as PDF (caption in the document's language); for email, which depends on the caller, a
    /// message instead of a name.
    /// </summary>
    [Test]
    procedure TestPatternShowsTheDefaultNameOfTheRouteTested()
    var
        Pattern: Record "Report Filename Pattern";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        ReportDistributionManagement: Codeunit "Report Distribution Management";
        DocumentRecRef: RecordRef;
        Expected: Text;
        Filename: Text;
        NameComesFrom: Text;
        Why: Text;
        FromThisPattern: Boolean;
    begin
        Prepare();
        ReviewSupport.AddPattern(Pattern, ReviewSupport.InvoiceReportId(), DiskPatternTok, Enum::"Report Filename Output Route"::Any);
        // Off, so the page shows Business Central's own name.
        Pattern.Enabled := false;
        Pattern.Modify();
        TestData.PostNewInvoice(SalesInvoiceHeader);
        DocumentRecRef.GetTable(SalesInvoiceHeader);
        Expected := ElectronicDocumentFormat.GetAttachmentFileName(
            SalesInvoiceHeader, SalesInvoiceHeader."No.", ElectronicDocumentFormat.GetDocumentType(DocumentRecRef), PdfCodeTok);

        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, Enum::"Report Filename Output Route"::Disk, SalesInvoiceHeader.RecordId(), Filename, NameComesFrom, Why, FromThisPattern);
        if Filename <> Expected then
            Error(WrongNameErr, Expected, Filename);

        Expected := StrSubstNo(AttachAsPdfDefaultTok, ReviewSupport.InvoiceReportId(),
            ReportDistributionManagement.GetReportCaption(ReviewSupport.InvoiceReportId(), ReportDistributionManagement.GetDocumentLanguageCode(DocumentRecRef)),
            SalesInvoiceHeader."No.") + '.' + PdfTok;
        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, Enum::"Report Filename Output Route"::AttachAsPdf, SalesInvoiceHeader.RecordId(), Filename, NameComesFrom, Why, FromThisPattern);
        if Filename <> Expected then
            Error(WrongNameErr, Expected, Filename);

        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, Enum::"Report Filename Output Route"::Email, SalesInvoiceHeader.RecordId(), Filename, NameComesFrom, Why, FromThisPattern);
        if StrPos(LowerCase(Filename), '.' + PdfTok) > 0 then
            Error(ExactEmailDefaultErr, Filename);
    end;

    /// <summary>
    /// A leftover render of another kind of record (a customer) does not name an email for no document.
    /// </summary>
    [Test]
    procedure AnEmailForNoDocumentIsNotNamedAfterAnUnrelatedRender()
    var
        Pattern: Record "Report Filename Pattern";
        Customer: Record Customer;
        ReportFilenameContext: Codeunit "Report Filename Context";
        DocumentMailing: Codeunit "Document-Mailing";
        Rendered: RecordRef;
        Baseline: Text[250];
        Name: Text[250];
    begin
        Prepare();
        ReviewSupport.AddPattern(Pattern, ReviewSupport.InvoiceReportId(), EmailPatternTok, Enum::"Report Filename Output Route"::Email);
        ReviewSupport.SetFeature(false);
        DocumentMailing.GetAttachmentFileName(Baseline, '', EmailDocumentNameTok, InvoiceUsage());
        ReviewSupport.SetFeature(true);

        Customer.Get(TestData.CreateCustomer());
        Customer.SetRecFilter();
        Rendered.GetTable(Customer);
        ReportFilenameContext.SetRenderedDocument(Rendered, ReviewSupport.InvoiceReportId());
        DocumentMailing.GetAttachmentFileName(Name, '', EmailDocumentNameTok, InvoiceUsage());
        ReportFilenameContext.ClearLastRendered();
        ReportFilenameContext.ClearHeldDocument();

        if Name <> Baseline then
            Error(WrongNameErr, Baseline, Name);
    end;

    /// <summary>
    /// A document set aside (another number was asked for) is given back only to a request for its own
    /// number, never to an email for no document.
    /// </summary>
    [Test]
    procedure ADocumentSetAsideIsNotGivenToAnEmailThatNamesNoDocument()
    var
        Pattern: Record "Report Filename Pattern";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ReportFilenameContext: Codeunit "Report Filename Context";
        DocumentMailing: Codeunit "Document-Mailing";
        Rendered: RecordRef;
        Baseline: Text[250];
        Ignored: Text[250];
        Name: Text[250];
    begin
        Prepare();
        ReviewSupport.AddPattern(Pattern, ReviewSupport.InvoiceReportId(), EmailPatternTok, Enum::"Report Filename Output Route"::Email);
        ReviewSupport.SetFeature(false);
        DocumentMailing.GetAttachmentFileName(Baseline, '', EmailDocumentNameTok, InvoiceUsage());
        ReviewSupport.SetFeature(true);

        TestData.PostNewInvoice(SalesInvoiceHeader);
        Rendered.GetTable(SalesInvoiceHeader);
        ReportFilenameContext.SetRenderedDocument(Rendered, ReviewSupport.InvoiceReportId());
        // Another number is asked for, so the rendered invoice is set aside.
        DocumentMailing.GetAttachmentFileName(Ignored, UnknownDocumentNoTok, EmailDocumentNameTok, InvoiceUsage());

        DocumentMailing.GetAttachmentFileName(Name, '', EmailDocumentNameTok, InvoiceUsage());
        ReportFilenameContext.ClearHeldDocument();

        if Name <> Baseline then
            Error(WrongNameErr, Baseline, Name);
    end;

    /// <summary>
    /// A PDF left pending by a failed Send to Disk does not name the same document's electronic document.
    /// </summary>
    [Test]
    procedure APendingPdfIsNotUsedForTheSameDocumentsElectronicDocument()
    var
        Pattern: Record "Report Filename Pattern";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ReportFilenameContext: Codeunit "Report Filename Context";
        DocumentRecRef: RecordRef;
        Name: Text;
    begin
        Prepare();
        ReviewSupport.AddPattern(Pattern, ReviewSupport.InvoiceReportId(), DiskPatternTok, Enum::"Report Filename Output Route"::Any);
        TestData.PostNewInvoice(SalesInvoiceHeader);
        DocumentRecRef.GetTable(SalesInvoiceHeader);

        ReportFilenameContext.SetPendingFile(DocumentRecRef, ReviewSupport.InvoiceReportId(), '', Enum::"Report Filename Output Route"::Disk);
        Name := ElectronicDocumentFormat.GetAttachmentFileName(SalesInvoiceHeader, SalesInvoiceHeader."No.", InvoiceDocumentNameTok, XmlCodeTok);

        if StrPos(Name, DiskPrefixTok) = 1 then
            Error(PendingPdfReusedErr, Name);
    end;

    /// <summary>
    /// The recorded Excel export is used only while report 29 runs for it; another report rendering
    /// first, or report 29 started again, forgets it, so a failed export never names a later workbook.
    /// </summary>
    [Test]
    procedure AnExcelExportIsNamedOnlyWhileReport29RunsForIt()
    var
        Pattern: Record "Report Filename Pattern";
        FinancialReport: Record "Financial Report";
        ReportFilenameContext: Codeunit "Report Filename Context";
        ReportFilenameFinRepSub: Codeunit "Report Filename Fin. Rep. Sub.";
    begin
        Prepare();
        // Needed so the feature can name something and the export is recorded.
        Pattern.Init();
        Pattern."Report ID" := Report::"Account Schedule";
        Pattern.Validate("Table No.", Database::"Financial Report");
        Pattern.Validate("File Name Pattern", FinancialReportPatternTok);
        Pattern.Enabled := true;
        Pattern.Insert(true);
        FinancialReport.Get(TestData.CreateFinancialReport(FinancialReportDescriptionTok, false));

        RecordExcelExport(ReportFilenameFinRepSub, FinancialReport);
        ReportFilenameContext.StartExcelExportRun();
        if not ReportFilenameContext.IsExcelExportRunning() then
            Error(ExcelStateErr, 'the armed run of report 29 is not running');
        ReportFilenameContext.EndExcelExportRun();
        ExpectExcelExportForgotten(ReportFilenameContext, 'report 29 ended');

        // Another report renders before report 29 starts.
        RecordExcelExport(ReportFilenameFinRepSub, FinancialReport);
        ReportFilenameContext.NoteReportRun(Report::"Standard Sales - Invoice");
        ReportFilenameContext.StartExcelExportRun();
        ExpectExcelExportForgotten(ReportFilenameContext, 'another report rendered first');

        // Report 29 starts again with nothing new armed.
        RecordExcelExport(ReportFilenameFinRepSub, FinancialReport);
        ReportFilenameContext.StartExcelExportRun();
        ReportFilenameContext.StartExcelExportRun();
        ExpectExcelExportForgotten(ReportFilenameContext, 'report 29 started again without the action');
    end;

    local procedure RecordExcelExport(var ReportFilenameFinRepSub: Codeunit "Report Filename Fin. Rep. Sub."; FinancialReport: Record "Financial Report")
    begin
        ReportFilenameFinRepSub.RecordExcelExport(FinancialReport.Name, FinancialReport."Financial Report Column Group",
            FinancialReport."Financial Report Row Group" <> '', '');
    end;

    local procedure ExpectExcelExportForgotten(var ReportFilenameContext: Codeunit "Report Filename Context"; Situation: Text)
    begin
        if ReportFilenameContext.IsExcelExportRunning() then
            Error(ExcelStateErr, Situation + ', yet the export still counts as running');
        if ReportFilenameContext.HasRunSubjectFor(Report::"Export Acc. Sched. to Excel") then
            Error(ExcelStateErr, Situation + ', yet the financial report is still recorded for it');
    end;

    local procedure Prepare()
    var
        FilenameProofGuard: Codeunit "Filename Proof Guard";
    begin
        // Also switches the feature on and refuses to run in an unsafe environment.
        FilenameProofGuard.ClearPatterns();
        TestData.Initialize();
        TestData.SetupDocumentReports();
    end;

    local procedure InvoiceUsage(): Integer
    begin
        exit(Enum::"Report Selection Usage"::"S.Invoice".AsInteger());
    end;

    local procedure SendToDisk(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        ReportSelections: Record "Report Selections";
        RecordVariant: Variant;
    begin
        SalesInvoiceHeader.SetRecFilter();
        RecordVariant := SalesInvoiceHeader;
        ReportSelections.SendToDiskForCust(
            Enum::"Report Selection Usage"::"S.Invoice", RecordVariant, SalesInvoiceHeader."No.", InvoiceDocumentNameTok, SalesInvoiceHeader."Bill-to Customer No.");
    end;

    local procedure InsertPostedAssemblyOrder(DocumentNo: Code[20])
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
    begin
        PostedAssemblyHeader.Init();
        PostedAssemblyHeader."No." := DocumentNo;
        PostedAssemblyHeader.Insert();
    end;

    [RequestPageHandler]
    procedure PostedAssemblyOrderRequestPageHandler(var PostedAssemblyOrder: TestRequestPage "Posted Assembly Order")
    begin
        PostedAssemblyOrder."Posted Assembly Header".SetFilter("No.", FirstAssemblyNoTok);
        PostedAssemblyOrder.OK().Invoke();
    end;

    /// <summary>
    /// Precondition: the parameters hold the Integer root and the filtered child data item.
    /// </summary>
    local procedure ExpectBothDataItems(Parameters: Text)
    var
        ReportDataItems: Record "Report Data Items";
        RootName: Text;
        HeaderName: Text;
    begin
        ReportDataItems.SetRange("Report ID", Report::"Posted Assembly Order");
        ReportDataItems.FindSet();
        repeat
            if (ReportDataItems."Indentation Level" = 0) and (RootName = '') then
                RootName := ReportDataItems.Name;
            if (ReportDataItems."Related Table ID" = Database::"Posted Assembly Header") and (HeaderName = '') then
                HeaderName := ReportDataItems.Name;
        until ReportDataItems.Next() = 0;
        if (StrPos(Parameters, StrSubstNo(DataItemTok, RootName)) = 0) or
           (StrPos(Parameters, StrSubstNo(DataItemTok, HeaderName)) = 0) or
           (StrPos(Parameters, FirstAssemblyNoTok) = 0)
        then
            Error(ParametersErr, RootName, HeaderName, FirstAssemblyNoTok, Parameters);
    end;

    local procedure WriteSomething(var TempBlob: Codeunit "Temp Blob")
    var
        Content: OutStream;
    begin
        TempBlob.CreateOutStream(Content);
        Content.WriteText(UploadedFileTok);
    end;

    local procedure ExpectAttachment(DocumentNo: Code[20]; FileName: Text; FileExtension: Text)
    begin
        if not ReviewSupport.HasAttachment(Database::"Sales Invoice Header", DocumentNo, FileName, FileExtension) then
            Error(AttachmentMissingErr, FileName, FileExtension, ReviewSupport.ListAttachments(Database::"Sales Invoice Header", DocumentNo));
    end;

    var
        ReviewSupport: Codeunit "Filename Review Support";
        TestData: Codeunit "Filename Test Data";
        MissingTestSetupErr: Label 'The document fixtures did not create their posting setup and accounts.';
        SamePostedInvoiceErr: Label 'Two posted invoice fixtures returned the same invoice.';
        SameDraftInvoiceErr: Label 'Repeated fixture setup reused a draft invoice number.';
        DocumentReportNotReplacedErr: Label 'The document report fixture kept the previous report selection.';
        PaymentTermsDescriptionTok: Label 'Filename custom payment terms', Locked = true;
        UnexpectedInvoiceSelectionsErr: Label 'The invoice fixture must configure exactly one report selection.';
        ObsoleteTableOfferedErr: Label 'Obsolete table %1 is offered as a report subject.', Comment = '%1 = Table ID';
        EmptyNoticeSentId: Guid;
        EmptyNoticeRecalled: Boolean;
        EmptyNoticeErr: Label 'The patterns list''s notice that no pattern is set up %1.', Comment = '%1 what went wrong';
        RestrictedSetTok: Label 'Rep. Filename Test', Locked = true;
        UnknownDocumentNoTok: Label 'RFM-NO-SUCH-DOC', Locked = true;
        EmailDocumentNameTok: Label 'Sales Invoice', Locked = true;
        InvoiceDocumentNameTok: Label 'Invoice', Locked = true;
        EmailPatternTok: Label 'Mail-[No.]', Locked = true;
        AttachPatternTok: Label 'Attached-[No.]', Locked = true;
        AttachPrefixTok: Label 'Attached-', Locked = true;
        DiskPatternTok: Label 'Disk-[No.]', Locked = true;
        DiskPrefixTok: Label 'Disk-', Locked = true;
        FinancialReportPatternTok: Label 'FR-[Name]', Locked = true;
        FinancialReportDescriptionTok: Label 'Report Filename Excel Export', Locked = true;
        AssemblyPatternTok: Label 'Assembly-[No.]', Locked = true;
        AssemblyPrefixTok: Label 'Assembly-', Locked = true;
        FirstAssemblyNoTok: Label 'RFM-PA-1', Locked = true;
        SecondAssemblyNoTok: Label 'RFM-PA-2', Locked = true;
        DataItemTok: Label '<DataItem name="%1">', Comment = '%1 the data item name', Locked = true;
        UploadedFileTok: Label 'Terms', Locked = true;
        SecondUploadedFileTok: Label 'Terms Two', Locked = true;
        ThirdUploadedFileTok: Label 'Terms Three', Locked = true;
        UploadedPdfTok: Label 'Uploaded Contract', Locked = true;
        DocxTok: Label 'docx', Locked = true;
        PdfTok: Label 'pdf', Locked = true;
        PdfCodeTok: Label 'PDF', Locked = true;
        XmlCodeTok: Label 'XML', Locked = true;
        ZipCodeTok: Label 'ZIP', Locked = true;
        TestDocumentNoTok: Label 'RFM-TEST-1', Locked = true;
        PartnerXmlNameTok: Label 'Partner-A.xml', Locked = true;
        AttachAsPdfDefaultTok: Label '%1 %2 %3', Comment = '%1 report id, %2 report caption, %3 document number', Locked = true;
        OneAttachmentTok: Label '1 attachments: ', Locked = true;
        PrintPatternTok: Label 'Print-[Bill-to Customer No.]', Locked = true;
        PrintPayloadTok: Label '{"filterviews":%1,"intent":"Print"}', Comment = '%1 the filterviews array', Locked = true;
        InvoiceCaptionTok: Label 'Sales - Invoice', Locked = true;
        UserCanReadInvoicesErr: Label 'The restricted user can read posted sales invoices, so this test proves nothing.';
        RestrictedUserNamedErr: Label 'A user who cannot read the invoice was given the name %1; Business Central''s own name should stand.', Comment = '%1 the name';
        RestrictedSendToDiskErr: Label 'For the restricted user, %1 returned %2.', Comment = '%1 the step, %2 what it returned';
        ParametersErr: Label 'The request page parameters should hold data items %1 and %2, filtered to %3: %4', Comment = '%1 root data item, %2 header data item, %3 order number, %4 the parameters';
        NotOneEmailErr: Label 'Expected one email with one attachment for the two invoices; got %1 email(s) and %2.', Comment = '%1 emails captured, %2 downloads captured or what the email held';
        NotRecognisedErr: Label 'Whether %1 is Business Central''s default name: expected %2.', Comment = '%1 the name, %2 the expected answer';
        WrongNameErr: Label 'Expected the file name %1, got %2.', Comment = '%1 expected, %2 actual';
        UserCanReadReportSelectionsErr: Label 'The restricted user can read Report Selections, so this test proves nothing.';
        NotNamedForAllErr: Label 'One attachment for invoices %1 and %2 should be named for both, but is called %3.', Comment = '%1 first invoice, %2 second invoice, %3 the name';
        AttachmentMissingErr: Label 'Expected an attachment %1.%2. The document has: %3', Comment = '%1 name, %2 extension, %3 the attachments';
        UnexpectedAttachErrorErr: Label 'Attach as PDF should have failed between arming and saving, but failed with: %1', Comment = '%1 the error';
        PartnerNameOverriddenErr: Label 'Another extension named the file %1, and that name should stand, but it was downloaded as %2.', Comment = '%1 the partner name, %2 the name downloaded';
        ScheduledNotNamedErr: Label 'The scheduled report was not named; expected %1.', Comment = '%1 the expected name';
        ReportNotClearedErr: Label 'Clear Report left the report %1 on the pattern.', Comment = '%1 the report';
        TableNotKeptErr: Label 'Clear Report should keep the table %1, but the pattern shows %2.', Comment = '%1 expected table, %2 what is shown';
        PendingPdfReusedErr: Label 'A PDF left pending for Send to Disk named the same document''s electronic document: %1.', Comment = '%1 the name';
        ExcelStateErr: Label 'Excel export: %1.', Comment = '%1 what went wrong';
        ExactEmailDefaultErr: Label 'For email Test Pattern should say that the default depends on the route, but shows the exact name %1.', Comment = '%1 the name shown';
}
