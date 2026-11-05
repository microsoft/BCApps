// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.EServices.EDocument;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.Reporting.FileNaming;
using Microsoft.Sales.History;
using System.EMail;
using System.Reflection;
using System.Threading;

codeunit 149535 "Filename End-To-End Tests"
{
    // The whole user flow: pattern set up and changed on the Pattern Card, feature switched in Setup,
    // and the file produced by the action a user takes.

    Subtype = Test;
    TestPermissions = Disabled;

    /// <summary>
    /// Attach as PDF follows the pattern set up and changed on the card, and falls back to Business
    /// Central's own name once the feature is switched off.
    /// </summary>
    [Test]
    [HandlerFunctions('PickChosenReportHandler')]
    procedure AttachAsPdfFollowsWhatIsSetUpOnThePages()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        PrepareThroughPages(SalesInvoiceHeader, FirstPatternTok);

        AttachFromThePostedInvoice(SalesInvoiceHeader);
        ExpectAttachment(SalesInvoiceHeader."No.", FirstPrefixTok + SalesInvoiceHeader."No.");

        ChangePatternOnTheCard(SecondPatternTok);
        AttachFromThePostedInvoice(SalesInvoiceHeader);
        ExpectAttachment(SalesInvoiceHeader."No.", SecondPrefixTok + SalesInvoiceHeader."No.");

        SwitchFeatureOnTheSetupPage(false);
        AttachFromThePostedInvoice(SalesInvoiceHeader);
        // Business Central's own name for Attach as PDF: report id, report caption, document number.
        ExpectStandardAttachment(SalesInvoiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('PickChosenReportHandler')]
    procedure SendToDiskFollowsWhatIsSetUpOnThePages()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DiskCapture: Codeunit "Filename Disk Capture";
        StandardName: Text;
    begin
        PrepareThroughPages(SalesInvoiceHeader, FirstPatternTok);
        BindSubscription(DiskCapture);

        SendToDisk(SalesInvoiceHeader);
        ExpectName(FirstPrefixTok + SalesInvoiceHeader."No." + PdfExtensionTok, DiskCapture.TakeName());

        ChangePatternOnTheCard(SecondPatternTok);
        SendToDisk(SalesInvoiceHeader);
        ExpectName(SecondPrefixTok + SalesInvoiceHeader."No." + PdfExtensionTok, DiskCapture.TakeName());

        SwitchFeatureOnTheSetupPage(false);
        StandardName := ElectronicDocumentFormat.GetAttachmentFileName(SalesInvoiceHeader, SalesInvoiceHeader."No.", InvoiceDocumentNameTok, PdfTok);
        SendToDisk(SalesInvoiceHeader);
        ExpectStandardName(StandardName, DiskCapture.TakeName());
        UnbindSubscription(DiskCapture);
    end;

    /// <summary>
    /// The same flow, read from the email's attachment, captured before the email is sent.
    /// </summary>
    [Test]
    [HandlerFunctions('PickChosenReportHandler')]
    procedure EmailFollowsWhatIsSetUpOnThePages()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentMailing: Codeunit "Document-Mailing";
        StandardName: Text[250];
        Emailed: Text;
    begin
        PrepareThroughPages(SalesInvoiceHeader, FirstPatternTok);

        Emailed := EmailAttachmentNames(SalesInvoiceHeader);
        ExpectListed(FirstPrefixTok + SalesInvoiceHeader."No." + PdfExtensionTok, Emailed);

        ChangePatternOnTheCard(SecondPatternTok);
        Emailed := EmailAttachmentNames(SalesInvoiceHeader);
        ExpectListed(SecondPrefixTok + SalesInvoiceHeader."No." + PdfExtensionTok, Emailed);

        SwitchFeatureOnTheSetupPage(false);
        DocumentMailing.GetAttachmentFileName(
            StandardName, SalesInvoiceHeader."No.", InvoiceDocumentNameTok, Enum::"Report Selection Usage"::"S.Invoice".AsInteger());
        Emailed := EmailAttachmentNames(SalesInvoiceHeader);
        // One email with one attachment, under Business Central's own name.
        ExpectStandardName(StrSubstNo(OneAttachmentTok, StandardName), Emailed);
    end;

    /// <summary>
    /// The same flow, read from the Report Inbox entry the job queue run writes.
    /// </summary>
    [Test]
    [HandlerFunctions('PickChosenReportHandler')]
    procedure ScheduledReportFollowsWhatIsSetUpOnThePages()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        PrepareThroughPages(SalesInvoiceHeader, FirstPatternTok);

        ExpectName(FirstPrefixTok + SalesInvoiceHeader."No.", ScheduledInboxName(SalesInvoiceHeader));

        ChangePatternOnTheCard(SecondPatternTok);
        ExpectName(SecondPrefixTok + SalesInvoiceHeader."No.", ScheduledInboxName(SalesInvoiceHeader));

        SwitchFeatureOnTheSetupPage(false);
        // With the feature off nothing is stored, and the entry downloads under Business Central's name.
        ExpectName('', ScheduledInboxName(SalesInvoiceHeader));
    end;

    local procedure PrepareThroughPages(var SalesInvoiceHeader: Record "Sales Invoice Header"; PatternText: Text)
    var
        FilenameProofGuard: Codeunit "Filename Proof Guard";
        PatternCard: TestPage "Report Filename Pattern Card";
    begin
        FilenameProofGuard.ClearPatterns();
        TestData.Initialize();
        TestData.SetupDocumentReports();
        ReviewSupport.SetFeature(false);
        SwitchFeatureOnTheSetupPage(true);
        TestData.PostNewInvoice(SalesInvoiceHeader);

        ChosenReportId := ReviewSupport.InvoiceReportId();
        PatternCard.OpenNew();
        PatternCard.ReportName.AssistEdit();
        PatternCard."File Name Pattern".SetValue(PatternText);
        PatternCard.Enabled.SetValue(true);
        PatternCard.Close();
    end;

    local procedure ChangePatternOnTheCard(PatternText: Text)
    var
        Pattern: Record "Report Filename Pattern";
        PatternCard: TestPage "Report Filename Pattern Card";
    begin
        Pattern.FindFirst();
        PatternCard.OpenEdit();
        PatternCard.GoToRecord(Pattern);
        PatternCard."File Name Pattern".SetValue(PatternText);
        PatternCard.Close();
    end;

    local procedure SwitchFeatureOnTheSetupPage(Enabled: Boolean)
    var
        SetupPage: TestPage "Report Filename Setup";
    begin
        SetupPage.OpenEdit();
        SetupPage.Enabled.SetValue(Enabled);
        SetupPage.Close();
    end;

    local procedure AttachFromThePostedInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.GoToRecord(SalesInvoiceHeader);
        PostedSalesInvoice.AttachAsPDF.Invoke();
        PostedSalesInvoice.Close();
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

    /// <summary>
    /// Read and stopped at Document-Mailing's OnBeforeSendEmail.
    /// </summary>
    local procedure EmailAttachmentNames(SalesInvoiceHeader: Record "Sales Invoice Header") Names: Text
    var
        ReportSelections: Record "Report Selections";
        EmailCapture: Codeunit "Filename Email Capture";
        Captured: Text;
        RecordVariant: Variant;
    begin
        SalesInvoiceHeader.SetRecFilter();
        RecordVariant := SalesInvoiceHeader;
        EmailCapture.Start(true);
        BindSubscription(EmailCapture);
        ReportSelections.SendEmailToCust(
            Enum::"Report Selection Usage"::"S.Invoice".AsInteger(), RecordVariant, SalesInvoiceHeader."No.", InvoiceDocumentNameTok, false, SalesInvoiceHeader."Bill-to Customer No.");
        UnbindSubscription(EmailCapture);
        foreach Captured in EmailCapture.CapturedEmails() do
            Names += Captured;
        foreach Captured in EmailCapture.CapturedDownloads() do
            Names += Captured;
        if Names = '' then
            Error(NoEmailErr, SalesInvoiceHeader."No.");
    end;

    /// <summary>
    /// Schedules the report as a user would, runs the job queue's report runner, and returns the
    /// File Name of the Report Inbox entry it wrote.
    /// </summary>
    local procedure ScheduledInboxName(SalesInvoiceHeader: Record "Sales Invoice Header"): Text
    var
        JobQueueEntry: Record "Job Queue Entry";
        ReportInbox: Record "Report Inbox";
    begin
        JobQueueEntry.Init();
        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Report;
        JobQueueEntry."Object ID to Run" := ChosenReportId;
        JobQueueEntry."Record ID to Process" := SalesInvoiceHeader.RecordId();
        JobQueueEntry."Report Output Type" := JobQueueEntry."Report Output Type"::PDF;
        JobQueueEntry.Description := CopyStr(ScheduledDescriptionTok, 1, MaxStrLen(JobQueueEntry.Description));
        JobQueueEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(JobQueueEntry."User ID"));
        JobQueueEntry.Insert(true);
        Commit();

        if not Codeunit.Run(Codeunit::"Job Queue Start Report", JobQueueEntry) then
            Error(ScheduledRunFailedErr, GetLastErrorText());

        ReportInbox.SetRange("Job Queue Log Entry ID", JobQueueEntry.ID);
        if not ReportInbox.FindLast() then
            Error(NoInboxEntryErr);
        exit(ReportInbox."File Name");
    end;

    local procedure ExpectAttachment(DocumentNo: Code[20]; FileName: Text)
    begin
        if not ReviewSupport.HasAttachment(Database::"Sales Invoice Header", DocumentNo, FileName, PdfTok) then
            Error(AttachmentMissingErr, FileName, PdfTok, ReviewSupport.ListAttachments(Database::"Sales Invoice Header", DocumentNo));
    end;

    local procedure ExpectStandardAttachment(DocumentNo: Code[20])
    var
        DocumentAttachment: Record "Document Attachment";
        Expected: Text;
    begin
        Expected := Format(ChosenReportId) + ' ';
        DocumentAttachment.SetRange("Table ID", Database::"Sales Invoice Header");
        DocumentAttachment.SetRange("No.", DocumentNo);
        if DocumentAttachment.FindSet() then
            repeat
                if (StrPos(DocumentAttachment."File Name", Expected) = 1) and (StrPos(DocumentAttachment."File Name", DocumentNo) > 0) and
                    (LowerCase(DocumentAttachment."File Extension") = PdfTok)
                then
                    exit;
            until DocumentAttachment.Next() = 0;
        Error(AttachmentMissingErr, Expected + '... ' + DocumentNo, PdfTok, ReviewSupport.ListAttachments(Database::"Sales Invoice Header", DocumentNo));
    end;

    local procedure ExpectName(Expected: Text; Actual: Text)
    begin
        if LowerCase(Actual) <> LowerCase(Expected) then
            Error(WrongNameErr, Expected, Actual);
    end;

    local procedure ExpectStandardName(Expected: Text; Actual: Text)
    begin
        if Actual = '' then
            Error(NothingCapturedErr);
        if Actual <> Expected then
            Error(StillNamedErr, Expected, Actual);
    end;

    local procedure ExpectListed(Expected: Text; Listed: Text)
    begin
        if StrPos(LowerCase(Listed), LowerCase(Expected)) = 0 then
            Error(NotListedErr, Expected, Listed);
    end;

    [ModalPageHandler]
    procedure PickChosenReportHandler(var ReportLookup: TestPage "Report Filename Report Lookup")
    var
        ReportMetadata: Record "Report Metadata";
    begin
        ReportMetadata.Get(ChosenReportId);
        ReportLookup.GoToRecord(ReportMetadata);
        ReportLookup.OK().Invoke();
    end;

    var
        ReviewSupport: Codeunit "Filename Review Support";
        TestData: Codeunit "Filename Test Data";
        ChosenReportId: Integer;
        FirstPatternTok: Label 'Invoice-[No.]', Locked = true;
        FirstPrefixTok: Label 'Invoice-', Locked = true;
        SecondPatternTok: Label 'NewInvoice-[No.]', Locked = true;
        SecondPrefixTok: Label 'NewInvoice-', Locked = true;
        InvoiceDocumentNameTok: Label 'Invoice', Locked = true;
        ScheduledDescriptionTok: Label 'Report Filename Manager end-to-end test', Locked = true;
        PdfTok: Label 'pdf', Locked = true;
        PdfExtensionTok: Label '.pdf', Locked = true;
        WrongNameErr: Label 'Expected the file name %1, got %2.', Comment = '%1 expected, %2 actual';
        NotListedErr: Label 'Expected an attachment %1 on the email; it has %2.', Comment = '%1 expected name, %2 the attachments';
        StillNamedErr: Label 'With the feature switched off the file should have Business Central''s own name %1, but is %2.', Comment = '%1 the standard name, %2 the name';
        NothingCapturedErr: Label 'With the feature switched off no file was captured.';
        OneAttachmentTok: Label '1 attachments: %1 | ', Comment = '%1 the attachment name', Locked = true;
        AttachmentMissingErr: Label 'Expected an attachment %1.%2. The document has: %3', Comment = '%1 name, %2 extension, %3 the attachments';
        NoEmailErr: Label 'No email was built for invoice %1.', Comment = '%1 the invoice';
        ScheduledRunFailedErr: Label 'The scheduled run failed: %1', Comment = '%1 the error';
        NoInboxEntryErr: Label 'The scheduled run wrote no Report Inbox entry.';
}
