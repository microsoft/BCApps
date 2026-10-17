// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50185 "Filename End-To-End Tests"
{
    // The whole user flow, from the pages to the file: the pattern is created and changed on the
    // Pattern Card, the feature switched on and off in Report Filename Setup, and the file produced
    // by the action a user takes. Everything else in this suite either reads a page or creates a
    // pattern in code; these connect the two.
    //
    // Each test posts an invoice of its own, so what is named is a document the test created.

    Subtype = Test;
    TestPermissions = Disabled;

    /// <summary>
    /// Attach as PDF, from the posted invoice's own action: named by the pattern set up on the card,
    /// renamed when the pattern is changed on the card, and given Business Central's own name once
    /// the feature is switched off in Setup.
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

    /// <summary>
    /// Send to Disk: the same flow, read from the name the download is given.
    /// </summary>
    [Test]
    [HandlerFunctions('PickChosenReportHandler')]
    procedure SendToDiskFollowsWhatIsSetUpOnThePages()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DiskCapture: Codeunit "Filename Disk Capture";
        Name: Text;
    begin
        PrepareThroughPages(SalesInvoiceHeader, FirstPatternTok);
        BindSubscription(DiskCapture);

        SendToDisk(SalesInvoiceHeader);
        ExpectName(FirstPrefixTok + SalesInvoiceHeader."No." + PdfExtensionTok, DiskCapture.TakeName());

        ChangePatternOnTheCard(SecondPatternTok);
        SendToDisk(SalesInvoiceHeader);
        ExpectName(SecondPrefixTok + SalesInvoiceHeader."No." + PdfExtensionTok, DiskCapture.TakeName());

        SwitchFeatureOnTheSetupPage(false);
        SendToDisk(SalesInvoiceHeader);
        Name := DiskCapture.TakeName();
        UnbindSubscription(DiskCapture);
        if StrPos(Name, SecondPrefixTok) = 1 then
            Error(StillNamedErr, Name);
    end;

    /// <summary>
    /// The emailed invoice: the same flow, read from the attachment on the email Base Application
    /// builds, stopped before it is sent.
    /// </summary>
    [Test]
    [HandlerFunctions('PickChosenReportHandler')]
    procedure EmailFollowsWhatIsSetUpOnThePages()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Emailed: Text;
    begin
        PrepareThroughPages(SalesInvoiceHeader, FirstPatternTok);

        Emailed := EmailAttachmentNames(SalesInvoiceHeader);
        ExpectListed(FirstPrefixTok + SalesInvoiceHeader."No." + PdfExtensionTok, Emailed);

        ChangePatternOnTheCard(SecondPatternTok);
        Emailed := EmailAttachmentNames(SalesInvoiceHeader);
        ExpectListed(SecondPrefixTok + SalesInvoiceHeader."No." + PdfExtensionTok, Emailed);

        SwitchFeatureOnTheSetupPage(false);
        Emailed := EmailAttachmentNames(SalesInvoiceHeader);
        if StrPos(Emailed, SecondPrefixTok) > 0 then
            Error(StillNamedErr, Emailed);
    end;

    /// <summary>
    /// A scheduled report: the same flow, read from the Report Inbox entry the job queue run writes.
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

    /// <summary>
    /// No patterns, the feature switched on in Setup, an invoice of the test's own, and a pattern for
    /// the invoice report created on the Pattern Card the way an administrator creates it.
    /// </summary>
    local procedure PrepareThroughPages(var SalesInvoiceHeader: Record "Sales Invoice Header"; PatternText: Text)
    var
        FilenameProofGuard: Codeunit "Filename Proof Guard";
        PatternCard: TestPage "Report Filename Pattern Card";
    begin
        FilenameProofGuard.ClearPatterns();
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
    /// The names of the attachments on the invoice's email, read where Base Application has named
    /// them and before it sends - or, with no email account set up, before it downloads them instead.
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
    /// Schedules the invoice report for the invoice exactly as scheduling a report does, runs the job
    /// queue's own report runner against it, and returns the File Name of the Report Inbox entry it
    /// wrote.
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
        StillNamedErr: Label 'With the feature switched off the file should have Business Central''s own name, but is %1.', Comment = '%1 the name';
        AttachmentMissingErr: Label 'Expected an attachment %1.%2. The document has: %3', Comment = '%1 name, %2 extension, %3 the attachments';
        NoEmailErr: Label 'No email was built for invoice %1.', Comment = '%1 the invoice';
        ScheduledRunFailedErr: Label 'The scheduled run failed: %1', Comment = '%1 the error';
        NoInboxEntryErr: Label 'The scheduled run wrote no Report Inbox entry.';
}
