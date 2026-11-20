// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using System.Email;
using System.TestLibraries.Email;
using System.TestLibraries.Utilities;
using System.Text;
using System.Utilities;

codeunit 148012 "IRS 1099 Emailing Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryIRSReportingPeriod: Codeunit "Library IRS Reporting Period";
        LibraryIRS1099FormBox: Codeunit "Library IRS 1099 Form Box";
        LibraryIRS1099Document: Codeunit "Library IRS 1099 Document";
        LibraryEmail: Codeunit "Library - Email";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryPurchase: Codeunit "Library - Purchase";
        Assert: Codeunit "Assert";
        IsInitialized: Boolean;
        EmailSetupMissingErr: Label 'You must set up email in Business Central before you can send 1099 forms.';
        NoConsentErr: Label '%1 must be enabled on the vendor card.', Comment = '%1 - "Receiving 1099 E-Form Consent" field caption';
        EmptyEmailErr: Label '%1 must be set in the document or vendor card.', Comment = '%1 - "Vendor E-Mail" field caption';
        EnableConsentMessageTxt: Label 'You must enable the Receiving 1099 E-Form Consent field';
        SetEmailMessageTxt: Label 'Set the email in the document or in the vendor card';
        PropagateFieldToReleasedFormDocsQst: Label 'Do you want to propagate the %1 to all released 1099 form documents by this vendor?', Comment = '%1 = field caption';
        PropagateFieldToSubmittedFormDocsQst: Label 'Do you want to propagate the %1 to all submitted 1099 form documents by this vendor?', Comment = '%1 = field caption';

    [Test]
    procedure EmailFromListWhenEmailNotSetup()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099FormDocuments: TestPage "IRS 1099 Form Documents";
    begin
        // [SCENARIO 560521] Send email from 1099 form document list when email account is not set up.
        Initialize();
        DeleteEmailAccounts();

        // [GIVEN] 1099 form document for the vendor.
        MockFormDocument(IRS1099FormDocHeader, "IRS 1099 Form Doc. Status"::Released);

        // [WHEN] Press "Send Email" from the form document list.
        IRS1099FormDocuments.OpenEdit();
        IRS1099FormDocuments.Filter.SetFilter("Vendor No.", IRS1099FormDocHeader."Vendor No.");
        asserterror IRS1099FormDocuments.SendEmail.Invoke();

        // [THEN] The error "You must set up email in Business Central" is thrown.
        Assert.ExpectedError(EmailSetupMissingErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure EmailFromListWhenConsentAndEmailNotSet()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099FormDocuments: TestPage "IRS 1099 Form Documents";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [SCENARIO 560521] Send email from 1099 form document list when email and consent are not set.
        Initialize();

        // [GIVEN] Email account.
        LibraryEmail.SetUpEmailAccount();

        // [GIVEN] 1099 form document without email consent and without email.
        MockFormDocument(IRS1099FormDocHeader, "IRS 1099 Form Doc. Status"::Released);
        UpdateDocumentEmailAndConsent(IRS1099FormDocHeader, '', false);

        // [WHEN] Press "Send Email" from the form document list.
        ErrorMessagesPage.Trap();
        IRS1099FormDocuments.OpenEdit();
        IRS1099FormDocuments.Filter.SetFilter("Vendor No.", IRS1099FormDocHeader."Vendor No.");
        IRS1099FormDocuments.SendEmail.Invoke();

        // [THEN] Error Messages page is shown.
        // [THEN] Error "Receiving 1099 E-Form Consent must be enabled on the vendor card." is shown on the page.
        // [THEN] Error "Vendor E-Mail must be set in the document or vendor card." is shown on the page.
        Assert.ExpectedError('');
        ErrorMessagesPage.First();
        Assert.ExpectedMessage(
            StrSubstNo(NoConsentErr, IRS1099FormDocHeader.FieldCaption("Receiving 1099 E-Form Consent")),
            ErrorMessagesPage.Description.Value);
        ErrorMessagesPage.Next();
        Assert.ExpectedMessage(
            StrSubstNo(EmptyEmailErr, IRS1099FormDocHeader.FieldCaption("Vendor E-Mail")),
            ErrorMessagesPage.Description.Value);
    end;

    [Test]
    [HandlerFunctions('SendEmailReqPageHandler')]
    procedure EmailFromListWhenConsentAndEmailSet()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SentEmail: Record "Sent Email";
        IRS1099FormDocuments: TestPage "IRS 1099 Form Documents";
    begin
        // [SCENARIO 560521] Send email from 1099 form document list when email and emailing consent are set.
        Initialize();
        SentEmail.DeleteAll();

        // [GIVEN] Email account.
        LibraryEmail.SetUpEmailAccount();

        // [GIVEN] 1099 form document with email consent and email.
        MockFormDocument(IRS1099FormDocHeader, "IRS 1099 Form Doc. Status"::Released);
        UpdateDocumentEmailAndConsent(IRS1099FormDocHeader, LibraryUtility.GenerateRandomEmail(), true);

        // [WHEN] Press "Send Email" from the form document list.
        Commit();
        IRS1099FormDocuments.OpenEdit();
        IRS1099FormDocuments.Filter.SetFilter("Vendor No.", IRS1099FormDocHeader."Vendor No.");
        IRS1099FormDocuments.SendEmail.Invoke();

        // [THEN] Report "IRS 1099 Send Email" is run and one email is sent.
        // [THEN] "Copy B Sent" flag was set in 1099 form document.
        Assert.AreEqual(1, SentEmail.Count, 'One email must be sent.');
        IRS1099FormDocHeader.Get(IRS1099FormDocHeader.ID);
        Assert.IsTrue(IRS1099FormDocHeader."Copy B Sent", 'Copy B Sent must be set to true.');
    end;

    [Test]
    procedure EmailFromCardWhenEmailNotSetup()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099FormDocument: TestPage "IRS 1099 Form Document";
    begin
        // [SCENARIO 560521] Send email from 1099 form document card when email account is not set up.
        Initialize();
        DeleteEmailAccounts();

        // [GIVEN] 1099 form document for the vendor.
        MockFormDocument(IRS1099FormDocHeader, "IRS 1099 Form Doc. Status"::Released);

        // [WHEN] Press "Send Email" from the form document card.
        IRS1099FormDocument.OpenEdit();
        IRS1099FormDocument.Filter.SetFilter("Vendor No.", IRS1099FormDocHeader."Vendor No.");
        asserterror IRS1099FormDocument.SendEmail.Invoke();

        // [THEN] The error "You must set up email in Business Central" is thrown.
        Assert.ExpectedError(EmailSetupMissingErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure EmailFromCardWhenConsentAndEmailNotSet()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099FormDocument: TestPage "IRS 1099 Form Document";
    begin
        // [SCENARIO 560521] Send email from 1099 form document card when email and consent are not set.
        Initialize();

        // [GIVEN] Email account.
        LibraryEmail.SetUpEmailAccount();

        // [GIVEN] 1099 form document without email and without consent.
        MockFormDocument(IRS1099FormDocHeader, "IRS 1099 Form Doc. Status"::Released);
        UpdateDocumentEmailAndConsent(IRS1099FormDocHeader, '', false);

        // [WHEN] Press "Send Email" from the form document card.
        IRS1099FormDocument.OpenEdit();
        IRS1099FormDocument.Filter.SetFilter("Vendor No.", IRS1099FormDocHeader."Vendor No.");
        asserterror IRS1099FormDocument.SendEmail.Invoke();

        // [THEN] Error "You must enable the Receiving 1099 E-Form Consent field" is thrown.
        Assert.ExpectedError(EnableConsentMessageTxt);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure EmailFromCardWhenConsentSetAndEmailNotSet()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099FormDocument: TestPage "IRS 1099 Form Document";
    begin
        // [SCENARIO 560521] Send email from 1099 form document card when email is set and consent is not set.
        Initialize();

        // [GIVEN] Email account.
        LibraryEmail.SetUpEmailAccount();

        // [GIVEN] 1099 form document without email and with consent.
        MockFormDocument(IRS1099FormDocHeader, "IRS 1099 Form Doc. Status"::Released);
        UpdateDocumentEmailAndConsent(IRS1099FormDocHeader, '', true);

        // [WHEN] Press "Send Email" from the form document card.
        IRS1099FormDocument.OpenEdit();
        IRS1099FormDocument.Filter.SetFilter("Vendor No.", IRS1099FormDocHeader."Vendor No.");
        asserterror IRS1099FormDocument.SendEmail.Invoke();

        // [THEN] Error "Set the email in the document or in the vendor card" is thrown.
        Assert.ExpectedError(SetEmailMessageTxt);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('SendEmailReqPageHandler')]
    procedure EmailFromCardWhenConsentAndEmailSet()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SentEmail: Record "Sent Email";
        IRS1099FormDocument: TestPage "IRS 1099 Form Document";
    begin
        // [SCENARIO 560521] Send email from 1099 form document card when email and emailing consent are set.
        Initialize();
        SentEmail.DeleteAll();

        // [GIVEN] Email account.
        LibraryEmail.SetUpEmailAccount();

        // [GIVEN] 1099 form document with email and consent.
        MockFormDocument(IRS1099FormDocHeader, "IRS 1099 Form Doc. Status"::Released);
        UpdateDocumentEmailAndConsent(IRS1099FormDocHeader, LibraryUtility.GenerateRandomEmail(), true);

        // [WHEN] Press "Send Email" from the form document card.
        Commit();
        IRS1099FormDocument.OpenEdit();
        IRS1099FormDocument.Filter.SetFilter("Vendor No.", IRS1099FormDocHeader."Vendor No.");
        IRS1099FormDocument.SendEmail.Invoke();

        // [THEN] Report "IRS 1099 Send Email" is run and one email is sent.
        // [THEN] "Copy B Sent" flag was set in 1099 form document.
        Assert.AreEqual(1, SentEmail.Count, 'One email must be sent.');
        IRS1099FormDocHeader.Get(IRS1099FormDocHeader.ID);
        Assert.IsTrue(IRS1099FormDocHeader."Copy B Sent", 'Copy B Sent must be set to true.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure PropagateConsentToSubmittedDocument()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        DummyVendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        ConfirmQuestion: Text;
    begin
        // [SCENARIO 560521] Propagate email consent from vendor to submitted 1099 form document.
        Initialize();
        // [GIVEN] Submitted 1099 form document without email and without consent.
        MockFormDocument(IRS1099FormDocHeader, "IRS 1099 Form Doc. Status"::Submitted);
        UpdateDocumentEmailAndConsent(IRS1099FormDocHeader, '', false);

        // [GIVEN] Vendor with email and without consent.
        UpdateVendorEmailAndConsent(IRS1099FormDocHeader."Vendor No.", LibraryUtility.GenerateRandomEmail(), false);

        // [WHEN] Open the vendor card and set the email consent.
        VendorCard.OpenEdit();
        VendorCard.Filter.SetFilter("No.", IRS1099FormDocHeader."Vendor No.");
        VendorCard."Receive Elec. IRS Forms".SetValue(true);

        // [THEN] Confirm dialog with question "Do you want to propagate consent to submitted documents" is shown. Reply Yes.
        ConfirmQuestion := LibraryVariableStorage.DequeueText();
        Assert.AreEqual(
            StrSubstNo(PropagateFieldToSubmittedFormDocsQst, DummyVendor.FieldCaption("Receiving 1099 E-Form Consent")),
            ConfirmQuestion, 'Confirm dialog with question must be shown.');

        // [THEN] Consent was propagated to the 1099 form document.
        IRS1099FormDocHeader.Get(IRS1099FormDocHeader.ID);
        Assert.IsTrue(IRS1099FormDocHeader."Receiving 1099 E-Form Consent", 'Receiving 1099 E-Form Consent must be set to true.');
        Assert.AreEqual('', IRS1099FormDocHeader."Vendor E-Mail", 'Vendor E-Mail must be empty.');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure PropagateEmailToSubmittedDocument()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        DummyVendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        ConfirmQuestion: Text;
        VendorEmail: Text[80];
    begin
        // [SCENARIO 560521] Propagate email from vendor to submitted 1099 form document.
        Initialize();
        // [GIVEN] Submitted 1099 form document without email and with consent.
        MockFormDocument(IRS1099FormDocHeader, "IRS 1099 Form Doc. Status"::Submitted);
        UpdateDocumentEmailAndConsent(IRS1099FormDocHeader, '', true);

        // [GIVEN] Vendor without email and with consent.
        UpdateVendorEmailAndConsent(IRS1099FormDocHeader."Vendor No.", '', true);

        // [WHEN] Open the vendor card and set the email.
        VendorEmail := LibraryUtility.GenerateRandomEmail();
        VendorCard.OpenEdit();
        VendorCard.Filter.SetFilter("No.", IRS1099FormDocHeader."Vendor No.");
        VendorCard."E-Mail".SetValue(VendorEmail);

        // [THEN] Confirm dialog with question "Do you want to propagate email to submitted documents" is shown. Reply Yes.
        ConfirmQuestion := LibraryVariableStorage.DequeueText();
        Assert.AreEqual(
            StrSubstNo(PropagateFieldToSubmittedFormDocsQst, DummyVendor.FieldCaption("E-Mail")),
            ConfirmQuestion, 'Confirm dialog with question must be shown.');

        // [THEN] Consent was propagated to the 1099 form document.
        IRS1099FormDocHeader.Get(IRS1099FormDocHeader.ID);
        Assert.IsTrue(IRS1099FormDocHeader."Receiving 1099 E-Form Consent", 'Receiving 1099 E-Form Consent must be set to true.');
        Assert.AreEqual(VendorEmail, IRS1099FormDocHeader."Vendor E-Mail", 'Vendor E-Mail must be specified.');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure PropagateConsentToReleasedDocument()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        DummyVendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        ConfirmQuestion: Text;
    begin
        // [SCENARIO 560521] Propagate email consent from vendor to released 1099 form document.
        Initialize();

        // [GIVEN] Released 1099 form document without email and without consent.
        MockFormDocument(IRS1099FormDocHeader, "IRS 1099 Form Doc. Status"::Released);
        UpdateDocumentEmailAndConsent(IRS1099FormDocHeader, '', false);

        // [GIVEN] Vendor with email and without consent.
        UpdateVendorEmailAndConsent(IRS1099FormDocHeader."Vendor No.", LibraryUtility.GenerateRandomEmail(), false);

        // [WHEN] Open the vendor card and set the email consent.
        VendorCard.OpenEdit();
        VendorCard.Filter.SetFilter("No.", IRS1099FormDocHeader."Vendor No.");
        VendorCard."Receive Elec. IRS Forms".SetValue(true);

        // [THEN] Confirm dialog with question "Do you want to propagate consent to released documents" is shown. Reply Yes.
        ConfirmQuestion := LibraryVariableStorage.DequeueText();
        Assert.AreEqual(
            StrSubstNo(PropagateFieldToReleasedFormDocsQst, DummyVendor.FieldCaption("Receiving 1099 E-Form Consent")),
            ConfirmQuestion, 'Confirm dialog with question must be shown.');

        // [THEN] Consent was propagated to the 1099 form document.
        IRS1099FormDocHeader.Get(IRS1099FormDocHeader.ID);
        Assert.IsTrue(IRS1099FormDocHeader."Receiving 1099 E-Form Consent", 'Receiving 1099 E-Form Consent must be set to true.');
        Assert.AreEqual('', IRS1099FormDocHeader."Vendor E-Mail", 'Vendor E-Mail must be empty.');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure PropagateEmailToReleasedDocument()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        DummyVendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        ConfirmQuestion: Text;
        VendorEmail: Text[80];
    begin
        // [SCENARIO 560521] Propagate email from vendor to released 1099 form document.
        Initialize();

        // [GIVEN] Released 1099 form document without email and with consent.
        MockFormDocument(IRS1099FormDocHeader, "IRS 1099 Form Doc. Status"::Released);
        UpdateDocumentEmailAndConsent(IRS1099FormDocHeader, '', true);

        // [GIVEN] Vendor without email and with consent.
        UpdateVendorEmailAndConsent(IRS1099FormDocHeader."Vendor No.", '', true);

        // [WHEN] Open the vendor card and set the email.
        VendorEmail := LibraryUtility.GenerateRandomEmail();
        VendorCard.OpenEdit();
        VendorCard.Filter.SetFilter("No.", IRS1099FormDocHeader."Vendor No.");
        VendorCard."E-Mail".SetValue(VendorEmail);

        // [THEN] Confirm dialog with question "Do you want to propagate email to released documents" is shown. Reply Yes.
        ConfirmQuestion := LibraryVariableStorage.DequeueText();
        Assert.AreEqual(
            StrSubstNo(PropagateFieldToReleasedFormDocsQst, DummyVendor.FieldCaption("E-Mail")),
            ConfirmQuestion, 'Confirm dialog with question must be shown.');

        // [THEN] Email was propagated to the 1099 form document.
        IRS1099FormDocHeader.Get(IRS1099FormDocHeader.ID);
        Assert.IsTrue(IRS1099FormDocHeader."Receiving 1099 E-Form Consent", 'Receiving 1099 E-Form Consent must be set to true.');
        Assert.AreEqual(VendorEmail, IRS1099FormDocHeader."Vendor E-Mail", 'Vendor E-Mail must be specified.');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StatementEmailReqPageHandler')]
    procedure StatementCopiesEmailTheExplicitlyRegeneratedPdf()
    var
        CompanyInformation: Record "Company Information";
        SavedCompanyInformation: Record "Company Information";
        DocHeader: Record "IRS 1099 Form Doc. Header";
        IRSFormsData: Codeunit "IRS Forms Data";
        DocumentIDs: List of [Integer];
        DocumentID: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Both recipient copies use the document year and the explicitly regenerated cached PDF.
        Initialize();

        // [GIVEN] Synthetic payer P and fresh year-specific setup use the existing test email connector.
        SavedCompanyInformation.Get();
        CompanyInformation := SavedCompanyInformation;
        CompanyInformation.Name := 'SYNTHETIC IRS STATEMENT TEST';
        CompanyInformation.Address := '1 Test Street';
        CompanyInformation."Address 2" := '';
        CompanyInformation.City := 'Test City';
        CompanyInformation.County := 'WA';
        CompanyInformation."Post Code" := '00000';
        CompanyInformation."Federal ID No." := '000000001';
        CompanyInformation."Phone No." := '0000000000';
        CompanyInformation.Modify();
        LibraryEmail.SetUpEmailAccount();
        IRSFormsData.AddReportingPeriodsWithForms(2025);
        IRSFormsData.AddReportingPeriodsWithForms(2026);
        Commit();

        // [WHEN] Both forms and copies are generated, corrected, explicitly regenerated and mock-emailed.
        DocumentIDs.Add(VerifyStatementCopies('2025', 'MISC'));
        DocumentIDs.Add(VerifyStatementCopies('2025', 'NEC'));
        DocumentIDs.Add(VerifyStatementCopies('2026', 'MISC'));
        DocumentIDs.Add(VerifyStatementCopies('2026', 'NEC'));
        foreach DocumentID in DocumentIDs do begin
            DocHeader.Get(DocumentID);
            DocHeader.Status := DocHeader.Status::Released;
            DocHeader.Modify();
            Commit();
            VerifyEmailCopy(DocHeader, Enum::"IRS 1099 Form Report Type"::"Copy B");
            Commit();
            VerifyEmailCopy(DocHeader, Enum::"IRS 1099 Form Report Type"::"Copy 2");
        end;

        // [THEN] Each mock attachment equals its selected saved PDF, with no silent cache replacement.
        LibraryVariableStorage.AssertEmpty();
        CompanyInformation.Get();
        CompanyInformation.TransferFields(SavedCompanyInformation, false);
        CompanyInformation.Modify();
    end;

    [Test]
    [HandlerFunctions('StatementEmailReqPageHandler')]
    procedure StatementEmailRetainsExcludedAndZeroTipSourceValues()
    var
        CompanyInformation: Record "Company Information";
        SavedCompanyInformation: Record "Company Information";
        DocHeader: Record "IRS 1099 Form Doc. Header";
        ParentDocLine: Record "IRS 1099 Form Doc. Line";
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
        IRSFormsData: Codeunit "IRS Forms Data";
        Lines: JsonArray;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Emailing suppressed disclosures does not erase the excluded amounts or zero-tip codes.
        Initialize();

        // [GIVEN] MISC document D has qualifying rents but an excluded saved other-income parent.
        SavedCompanyInformation.Get();
        CompanyInformation := SavedCompanyInformation;
        CompanyInformation.Name := 'SYNTHETIC IRS STATEMENT TEST';
        CompanyInformation.Address := '1 Test Street';
        CompanyInformation."Address 2" := '';
        CompanyInformation.City := 'Test City';
        CompanyInformation.County := 'WA';
        CompanyInformation."Post Code" := '00000';
        CompanyInformation."Federal ID No." := '000000001';
        CompanyInformation."Phone No." := '0000000000';
        CompanyInformation.Modify();
        LibraryEmail.SetUpEmailAccount();
        IRSFormsData.AddReportingPeriodsWithForms(2026);
        CreateStatementDocument(DocHeader, '2026', 'MISC');
        ParentDocLine.Get('2026', DocHeader."Vendor No.", 'MISC', DocHeader.ID, 0);
        ParentDocLine.Validate(Amount, 500);
        ParentDocLine.Modify(true);
        Clear(ParentDocLine);
        ParentDocLine."Line No." := 1;
        LibraryIRS1099Document.MockFormDocumentLineForVendor(ParentDocLine, DocHeader.ID, '2026', DocHeader."Vendor No.", 'MISC', 'MISC-01');
        ParentDocLine.Validate(Amount, 2500);
        ParentDocLine.Modify(true);
        Commit();

        // [WHEN] Both excluded-parent copies are generated and mock-emailed.
        RegenerateCopy(DocHeader, Enum::"IRS 1099 Form Report Type"::"Copy B");
        RegenerateCopy(DocHeader, Enum::"IRS 1099 Form Report Type"::"Copy 2");
        DocHeader.Status := DocHeader.Status::Released;
        DocHeader.Modify();
        Commit();
        VerifyEmailCopy(DocHeader, Enum::"IRS 1099 Form Report Type"::"Copy B");
        Commit();
        VerifyEmailCopy(DocHeader, Enum::"IRS 1099 Form Report Type"::"Copy 2");

        // [THEN] The selected disclosure values still belong to D.
        SupplLine.Get(DocHeader.ID, 'MISC-13A');
        Assert.AreEqual(100, SupplLine.Amount, 'Excluded tips remain stored.');
        VerifyStoredOccupationCodes(DocHeader.ID, 'MISC-13B');

        // [GIVEN] The parent qualifies again but outgoing tips round to zero while overtime rounds up.
        DocHeader.Status := DocHeader.Status::Open;
        DocHeader.Modify();
        ParentDocLine.Get('2026', DocHeader."Vendor No.", 'MISC', DocHeader.ID, 0);
        ParentDocLine.Validate(Amount, 5000);
        ParentDocLine.Modify(true);
        SupplLine.Validate(Amount, 0.004);
        SupplLine.Modify(true);
        SupplLine.Get(DocHeader.ID, 'MISC-14');
        SupplLine.Validate(Amount, 0.006);
        SupplLine.Modify(true);
        Commit();

        // [WHEN] Both copies are deliberately regenerated and mock-emailed.
        Lines := LibraryIRS1099Document.GetStatementDataset(DocHeader);
        RegenerateCopy(DocHeader, Enum::"IRS 1099 Form Report Type"::"Copy B");
        RegenerateCopy(DocHeader, Enum::"IRS 1099 Form Report Type"::"Copy 2");
        DocHeader.Status := DocHeader.Status::Released;
        DocHeader.Modify();
        Commit();
        VerifyEmailCopy(DocHeader, Enum::"IRS 1099 Form Report Type"::"Copy B");
        Commit();
        VerifyEmailCopy(DocHeader, Enum::"IRS 1099 Form Report Type"::"Copy 2");

        // [THEN] The attachment source projects cents without codes, while rendering/sending retains raw disclosures.
        VerifyFractionalEmailDataset(Lines);
        SupplLine.Get(DocHeader.ID, 'MISC-13A');
        Assert.AreEqual(0.004, SupplLine.Amount, 'Email generation does not round saved tips.');
        SupplLine.Get(DocHeader.ID, 'MISC-14');
        Assert.AreEqual(0.006, SupplLine.Amount, 'Email generation does not round saved overtime.');
        VerifyStoredOccupationCodes(DocHeader.ID, 'MISC-13B');
        LibraryVariableStorage.AssertEmpty();
        CompanyInformation.Get();
        CompanyInformation.TransferFields(SavedCompanyInformation, false);
        CompanyInformation.Modify();
    end;

    [Test]
    [HandlerFunctions('CopySetupMessageHandler,StatementEmailReqPageHandler')]
    procedure Copied2027MiscStatementEmailsRegeneratedPdfs()
    var
        SavedCompanyInformation: Record "Company Information";
        DocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Standard next-year MISC setup produces both recipient attachments without disclosures.
        Initialize();

        // [GIVEN] D is an ordinary 2027 MISC document after copying standard 2026 setup.
        SetSyntheticStatementPayer(SavedCompanyInformation);
        LibraryEmail.SetUpEmailAccount();
        CreateCopiedOrdinaryStatement(DocHeader, 'MISC');
        Commit();

        // [WHEN] Both recipient PDFs are explicitly regenerated and sent through the connector mock.
        RegenerateCopy(DocHeader, Enum::"IRS 1099 Form Report Type"::"Copy B");
        RegenerateCopy(DocHeader, Enum::"IRS 1099 Form Report Type"::"Copy 2");
        DocHeader.Status := DocHeader.Status::Released;
        DocHeader.Modify();
        Commit();
        VerifyEmailCopy(DocHeader, Enum::"IRS 1099 Form Report Type"::"Copy B");
        Commit();
        VerifyEmailCopy(DocHeader, Enum::"IRS 1099 Form Report Type"::"Copy 2");

        // [THEN] Both mock attachments match their saved PDFs and contain only ordinary financial output.
        VerifyCopiedOrdinaryStatement(DocHeader, 'MISC-03 - Other Income');
        LibraryVariableStorage.AssertEmpty();
        RestoreStatementPayer(SavedCompanyInformation);
    end;

    [Test]
    [HandlerFunctions('CopySetupMessageHandler,StatementEmailReqPageHandler')]
    procedure Copied2027NecStatementEmailsRegeneratedPdfs()
    var
        SavedCompanyInformation: Record "Company Information";
        DocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Standard next-year NEC setup produces both recipient attachments without disclosures.
        Initialize();

        // [GIVEN] D is an ordinary 2027 NEC document after copying standard 2026 setup.
        SetSyntheticStatementPayer(SavedCompanyInformation);
        LibraryEmail.SetUpEmailAccount();
        CreateCopiedOrdinaryStatement(DocHeader, 'NEC');
        Commit();

        // [WHEN] Both recipient PDFs are explicitly regenerated and sent through the connector mock.
        RegenerateCopy(DocHeader, Enum::"IRS 1099 Form Report Type"::"Copy B");
        RegenerateCopy(DocHeader, Enum::"IRS 1099 Form Report Type"::"Copy 2");
        DocHeader.Status := DocHeader.Status::Released;
        DocHeader.Modify();
        Commit();
        VerifyEmailCopy(DocHeader, Enum::"IRS 1099 Form Report Type"::"Copy B");
        Commit();
        VerifyEmailCopy(DocHeader, Enum::"IRS 1099 Form Report Type"::"Copy 2");

        // [THEN] Both mock attachments match their saved PDFs and contain only ordinary financial output.
        VerifyCopiedOrdinaryStatement(DocHeader, 'NEC-01 - Nonemployee Compensation (box 1a)');
        LibraryVariableStorage.AssertEmpty();
        RestoreStatementPayer(SavedCompanyInformation);
    end;

    local procedure Initialize()
    var
        IRSReportingPeriod: Record "IRS Reporting Period";
    begin
        DeleteFormDocuments();
        IRSReportingPeriod.DeleteAll(true);

        if IsInitialized then
            exit;

        IsInitialized := true;
    end;

    local procedure DeleteFormDocuments()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        IRS1099FormDocHeader.ModifyAll(Status, IRS1099FormDocHeader.Status::Open);
        IRS1099FormDocHeader.DeleteAll(true);
    end;

    local procedure DeleteEmailAccounts()
    var
        TempEmailAccount: Record "Email Account";
        TestEmailAccount: Record "Test Email Account";
        EmailScenarioMock: Codeunit "Email Scenario Mock";
    begin
        EmailScenarioMock.DeleteAllMappings();
        TempEmailAccount.DeleteAll(true);
        TestEmailAccount.DeleteAll(true);
    end;

    local procedure MockFormDocument(var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; Status: Enum "IRS 1099 Form Doc. Status")
    var
        PeriodNo, FormNo, VendorNo, FormBoxNo : Code[20];
        DocID: Integer;
    begin
        PeriodNo := LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(WorkDate());
        FormNo := LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(WorkDate());
        FormBoxNo := LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(WorkDate(), FormNo);
        VendorNo := LibraryIRS1099FormBox.CreateVendorNoWithFormBox(WorkDate(), FormNo, FormBoxNo);
        LibraryIRS1099FormBox.CreateSingleFormStatementLine(WorkDate(), FormNo, FormBoxNo);
        DocID := LibraryIRS1099Document.MockFormDocumentForVendor(PeriodNo, VendorNo, FormNo, Status);
        LibraryIRS1099Document.MockFormDocumentLineForVendor(DocID, PeriodNo, VendorNo, FormNo, FormBoxNo);
        IRS1099FormDocHeader.Get(DocID);
    end;

    local procedure UpdateDocumentEmailAndConsent(var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; EmailAddress: Text[80]; EmailConsent: Boolean)
    begin
        IRS1099FormDocHeader."Vendor E-Mail" := EmailAddress;
        IRS1099FormDocHeader."Receiving 1099 E-Form Consent" := EmailConsent;
        IRS1099FormDocHeader.Modify();
    end;

    local procedure UpdateVendorEmailAndConsent(VendorNo: Code[20]; EmailAddress: Text[80]; EmailConsent: Boolean)
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Vendor."E-Mail" := EmailAddress;
        Vendor."Receiving 1099 E-Form Consent" := EmailConsent;
        Vendor.Modify();
    end;

    local procedure SetSyntheticStatementPayer(var SavedCompanyInformation: Record "Company Information")
    var
        CompanyInformation: Record "Company Information";
    begin
        SavedCompanyInformation.Get();
        CompanyInformation := SavedCompanyInformation;
        CompanyInformation.Name := 'SYNTHETIC IRS STATEMENT TEST';
        CompanyInformation.Address := '1 Test Street';
        CompanyInformation."Address 2" := '';
        CompanyInformation.City := 'Test City';
        CompanyInformation.County := 'WA';
        CompanyInformation."Post Code" := '00000';
        CompanyInformation."Federal ID No." := '000000001';
        CompanyInformation."Phone No." := '0000000000';
        CompanyInformation.Modify();
    end;

    local procedure RestoreStatementPayer(SavedCompanyInformation: Record "Company Information")
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.TransferFields(SavedCompanyInformation, false);
        CompanyInformation.Modify();
    end;

    local procedure CreateCopiedOrdinaryStatement(var DocHeader: Record "IRS 1099 Form Doc. Header"; FormNo: Code[20])
    var
        IRSFormsData: Codeunit "IRS Forms Data";
        PeriodNo: Code[20];
    begin
        IRSFormsData.AddReportingPeriodsWithForms(2026);
        PeriodNo := LibraryIRSReportingPeriod.CreateReportingPeriod(20270101D, 20271231D);
        LibraryIRSReportingPeriod.CopyPeriodSetup('2026', PeriodNo);
        CreateStatementDocument(DocHeader, PeriodNo, FormNo);
    end;

    local procedure VerifyCopiedOrdinaryStatement(DocHeader: Record "IRS 1099 Form Doc. Header"; ExpectedName: Text)
    var
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
        Lines: JsonArray;
        Line: JsonToken;
        Value: JsonToken;
    begin
        SupplLine.SetRange("Document ID", DocHeader.ID);
        Assert.IsTrue(SupplLine.IsEmpty(), 'The ordinary document has no saved supplemental rows.');
        Lines := LibraryIRS1099Document.GetStatementDataset(DocHeader);
        Assert.AreEqual(1, Lines.Count(), 'The attachment dataset contains only ordinary financial output.');
        Lines.Get(0, Line);
        Line.AsObject().Get('name', Value);
        Assert.AreEqual(ExpectedName, Value.AsValue().AsText(), 'The copied financial selector still renders.');
        Line.AsObject().Get('value', Value);
        Assert.AreEqual('5000', Value.AsValue().AsText(), 'The ordinary financial amount is unchanged.');
    end;

    local procedure CreateStatementDocument(var DocHeader: Record "IRS 1099 Form Doc. Header"; PeriodNo: Code[20]; FormNo: Code[20])
    var
        ParentDocLine: Record "IRS 1099 Form Doc. Line";
        FormBox: Record "IRS 1099 Form Box";
        Vendor: Record Vendor;
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
        ParentBox: Code[20];
        TipsBox: Code[20];
        CodesBox: Code[20];
        OvertimeBox: Code[20];
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Name := 'SYNTHETIC STATEMENT RECIPIENT';
        Vendor.Address := '2 Test Street';
        Vendor."Address 2" := '';
        Vendor.City := 'Test City';
        Vendor.County := 'WA';
        Vendor."Post Code" := '00000';
        Vendor."Federal ID No." := '000000101';
        Vendor.Modify();
        DocHeader.Get(LibraryIRS1099Document.MockFormDocumentForVendor(PeriodNo, Vendor."No.", FormNo, DocHeader.Status::Open));
        UpdateDocumentEmailAndConsent(DocHeader, 'recipient@example.test', true);
        if FormNo = 'NEC' then begin
            ParentBox := 'NEC-01';
            TipsBox := 'NEC-01B';
            CodesBox := 'NEC-01C';
            OvertimeBox := 'NEC-01D';
        end else begin
            ParentBox := 'MISC-03';
            TipsBox := 'MISC-13A';
            CodesBox := 'MISC-13B';
            OvertimeBox := 'MISC-14';
        end;
        LibraryIRS1099Document.MockFormDocumentLineForVendor(ParentDocLine, DocHeader.ID, PeriodNo, Vendor."No.", FormNo, ParentBox);
        FormBox.Get(PeriodNo, FormNo, ParentBox);
        ParentDocLine."Minimum Reportable Amount" := FormBox."Minimum Reportable Amount";
        ParentDocLine.Validate(Amount, 5000);
        ParentDocLine.Modify(true);
        if PeriodNo <> '2026' then
            exit;
        SupplLine."Document ID" := DocHeader.ID;
        SupplLine.Validate("Supplemental Box No.", TipsBox);
        SupplLine.Validate(Amount, 100);
        SupplLine.Insert(true);
        SupplLine.Init();
        SupplLine."Document ID" := DocHeader.ID;
        SupplLine.Validate("Supplemental Box No.", CodesBox);
        SupplLine.Validate("Occupation Code 1", '101');
        SupplLine.Validate("Occupation Code 2", '000');
        SupplLine.Insert(true);
        SupplLine.Init();
        SupplLine."Document ID" := DocHeader.ID;
        SupplLine.Validate("Supplemental Box No.", OvertimeBox);
        SupplLine.Validate(Amount, 50);
        SupplLine.Insert(true);
    end;

    local procedure VerifyStatementCopies(PeriodNo: Code[20]; FormNo: Code[20]): Integer
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        ParentDocLine: Record "IRS 1099 Form Doc. Line";
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
        TempPrintParams: Record "IRS 1099 Print Params";
        IRSFormsFacade: Codeunit "IRS Forms Facade";
        OriginalCopyB: Text;
        OriginalCopy2: Text;
    begin
        CreateStatementDocument(DocHeader, PeriodNo, FormNo);
        TempPrintParams."Report Type" := TempPrintParams."Report Type"::"Copy B";
        IRSFormsFacade.SaveContentForDocument(DocHeader, TempPrintParams, false);
        OriginalCopyB := GetSavedPdf(DocHeader.ID, TempPrintParams."Report Type");
        TempPrintParams."Report Type" := TempPrintParams."Report Type"::"Copy 2";
        IRSFormsFacade.SaveContentForDocument(DocHeader, TempPrintParams, false);
        OriginalCopy2 := GetSavedPdf(DocHeader.ID, TempPrintParams."Report Type");
        ParentDocLine.Get(PeriodNo, DocHeader."Vendor No.", FormNo, DocHeader.ID, 0);
        ParentDocLine.Validate(Amount, 6000);
        ParentDocLine.Modify(true);
        SupplLine.SetRange("Document ID", DocHeader.ID);
        SupplLine.SetRange("Value Type", SupplLine."Value Type"::Amount);
        if SupplLine.FindSet(true) then
            repeat
                SupplLine.Validate(Amount, SupplLine.Amount + 25);
                SupplLine.Modify(true);
            until SupplLine.Next() = 0;
        IRSFormsFacade.SaveContentForDocument(DocHeader, TempPrintParams, false);
        Assert.AreEqual(OriginalCopy2, GetSavedPdf(DocHeader.ID, TempPrintParams."Report Type"), 'Ordinary save must retain the issued Copy 2 bytes.');
        TempPrintParams."Report Type" := TempPrintParams."Report Type"::"Copy B";
        IRSFormsFacade.SaveContentForDocument(DocHeader, TempPrintParams, false);
        Assert.AreEqual(OriginalCopyB, GetSavedPdf(DocHeader.ID, TempPrintParams."Report Type"), 'Ordinary save must retain the issued Copy B bytes.');
        RegenerateCopy(DocHeader, TempPrintParams."Report Type");
        Assert.AreNotEqual(OriginalCopyB, GetSavedPdf(DocHeader.ID, TempPrintParams."Report Type"), 'Explicit replacement must regenerate Copy B.');
        Assert.AreEqual(OriginalCopy2, GetSavedPdf(DocHeader.ID, TempPrintParams."Report Type"::"Copy 2"), 'Replacing Copy B must not replace Copy 2.');
        RegenerateCopy(DocHeader, TempPrintParams."Report Type"::"Copy 2");
        Assert.AreNotEqual(OriginalCopy2, GetSavedPdf(DocHeader.ID, TempPrintParams."Report Type"::"Copy 2"), 'Explicit replacement must regenerate Copy 2.');
        exit(DocHeader.ID);
    end;

    local procedure GetSavedPdf(DocumentID: Integer; ReportType: Enum "IRS 1099 Form Report Type"): Text
    var
        FormReport: Record "IRS 1099 Form Report";
        Base64Convert: Codeunit "Base64 Convert";
        Content: InStream;
    begin
        FormReport.Get(DocumentID, ReportType);
        FormReport.CalcFields("File Content");
        FormReport."File Content".CreateInStream(Content);
        exit(Base64Convert.ToBase64(Content));
    end;

    local procedure RegenerateCopy(var DocHeader: Record "IRS 1099 Form Doc. Header"; ReportType: Enum "IRS 1099 Form Report Type")
    var
        TempPrintParams: Record "IRS 1099 Print Params";
        IRSFormsFacade: Codeunit "IRS Forms Facade";
    begin
        TempPrintParams."Report Type" := ReportType;
        IRSFormsFacade.SaveContentForDocument(DocHeader, TempPrintParams, true);
    end;

    local procedure VerifyEmailCopy(var DocHeader: Record "IRS 1099 Form Doc. Header"; ReportType: Enum "IRS 1099 Form Report Type")
    var
        SentEmail: Record "Sent Email";
        EmailMessage: Codeunit "Email Message";
        ConnectorMock: Codeunit "Connector Mock";
        FormDocument: TestPage "IRS 1099 Form Document";
        SentCount: Integer;
    begin
        SentCount := SentEmail.Count();
        LibraryVariableStorage.Enqueue(ReportType.AsInteger());
        FormDocument.OpenEdit();
        FormDocument.Filter.SetFilter(ID, Format(DocHeader.ID));
        FormDocument.SendEmail.Invoke();
        FormDocument.Close();
        Assert.AreEqual(SentCount + 1, SentEmail.Count(), 'Exactly one mock email must be sent.');
        Assert.IsTrue(EmailMessage.Get(ConnectorMock.GetEmailMessageID()), 'The message passed to the test connector is available.');
        Assert.IsTrue(EmailMessage.Attachments_First(), 'The recipient copy is attached.');
        Assert.AreEqual(GetSavedPdf(DocHeader.ID, ReportType), EmailMessage.Attachments_GetContentBase64(), 'The selected regenerated PDF and actual mock email attachment must match byte for byte.');
        Assert.AreEqual(0, EmailMessage.Attachments_Next(), 'No other recipient copy is attached.');
        DocHeader.Get(DocHeader.ID);
        Assert.IsTrue((ReportType = ReportType::"Copy B") and DocHeader."Copy B Sent" or
            (ReportType = ReportType::"Copy 2") and DocHeader."Copy 2 Sent", 'The selected copy has its sent flag.');
    end;

    local procedure VerifyFractionalEmailDataset(Lines: JsonArray)
    var
        Line: JsonToken;
        Name: JsonToken;
        Value: JsonToken;
        TipsFound: Boolean;
        OvertimeFound: Boolean;
    begin
        foreach Line in Lines do begin
            Line.AsObject().Get('name', Name);
            Line.AsObject().Get('value', Value);
            Assert.IsFalse(Name.AsValue().AsText().StartsWith('MISC-13B - '), 'Zero outgoing tips must not disclose saved codes in the attachment dataset.');
            if Name.AsValue().AsText().StartsWith('MISC-13A - ') then begin
                TipsFound := true;
                Assert.AreEqual('0', Value.AsValue().AsText(), 'The attachment projects tips to zero cents.');
            end;
            if Name.AsValue().AsText().StartsWith('MISC-14 - ') then begin
                OvertimeFound := true;
                Assert.AreEqual('0.01', Value.AsValue().AsText(), 'The attachment rounds overtime independently.');
            end;
        end;
        Assert.IsTrue(TipsFound, 'The positive raw tip row is projected, not deleted.');
        Assert.IsTrue(OvertimeFound, 'The overtime statement row must remain present.');
    end;

    local procedure VerifyStoredOccupationCodes(DocumentID: Integer; CodesBox: Code[20])
    var
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        SupplLine.Get(DocumentID, CodesBox);
        Assert.AreEqual('101', SupplLine."Occupation Code 1", 'The first occupation code remains stored.');
        Assert.AreEqual('000', SupplLine."Occupation Code 2", 'Leading zeros remain stored.');
    end;

    [MessageHandler]
    procedure CopySetupMessageHandler(Message: Text)
    begin
    end;

    [RequestPageHandler]
    procedure StatementEmailReqPageHandler(var SendEmail: TestRequestPage "IRS 1099 Send Email")
    begin
        SendEmail.ReportTypeField.SetValue(LibraryVariableStorage.DequeueInteger());
        SendEmail.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure SendEmailReqPageHandler(var IRS1099SendEmail: TestRequestPage "IRS 1099 Send Email")
    begin
        IRS1099SendEmail.ReportTypeField.SetValue(Enum::"IRS 1099 Email Report Type"::"Copy B");
        IRS1099SendEmail.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        Reply := true;
    end;
}