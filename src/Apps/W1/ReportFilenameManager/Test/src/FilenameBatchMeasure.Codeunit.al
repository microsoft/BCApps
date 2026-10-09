// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50190 "Filename Batch Measure"
{
    // Measures what happens when one action produces several files with the same name, in every
    // Base Application workflow where that can happen and that can be driven from AL in a container.
    // It records observations; it is not a pass or fail test. Run it with
    // Invoke-NavContainerCodeunit and read the log lines beginning "B" with readlog.ps1.
    //
    // Two names are compared in each case: Business Central's own, with no pattern, and a pattern
    // that names every file of the run the same way. A second Report Selections row for the
    // usage is added for the run and removed again afterwards, which is how one action comes to
    // produce two files: Base Application loops over the report selections.
    //
    // Not driven here, and why:
    //   the Outlook add-in, which needs an Outlook host;
    //   reminder automation and the email download fallback, whose own code is a loop of
    //   Email Item.AddAttachment and Data Compression.AddEntry, both measured directly below;
    //   the browser's handling of two downloads with one name, which needs a person's browser and
    //   is measured with the web client instead.

    SingleInstance = true;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    var
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        Measure: Codeunit "Filename Batch Measure";
    begin
        FilenameProofGuard.AssertSafeEnvironment();
        FilenameProofLogMgt.StartNewRun();
        BindSubscription(Measure);

        MeasureDataCompression();
        MeasureEmailMessage();
        MeasureEmailNameForAnotherDocument();

        if FindInvoice() then begin
            AddSecondSelection();
            Commit();

            FilenameProofGuard.ClearPatterns();
            Commit();
            MeasureZip(NoPatternTok);
            MeasureSendToDisk(Measure, NoPatternTok);
            MeasureAttach(NoPatternTok);

            SetSameNamePattern();
            Commit();
            MeasureZip(SameNamePatternTok);
            MeasureSendToDisk(Measure, SameNamePatternTok);
            MeasureAttach(SameNamePatternTok);

            FilenameProofGuard.ClearPatterns();
            RemoveSecondSelection();
            Commit();
        end else
            ProofSupport.LogLine('B0 Setup', NoInvoiceMsg);

        UnbindSubscription(Measure);
        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// Names a pattern gives that repeat within one zip, or one Send to Disk, are numbered the way Base
    /// Application numbers a repeated attachment; Base Application's own names are left as they are.
    /// Two report selections for the invoice usage produce two files from one action. Every verdict
    /// compares against names written out here, never against what the feature reports it produced.
    /// </summary>
    procedure ProveRepeatedNamesAreNumbered()
    var
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        Measure: Codeunit "Filename Batch Measure";
        Names: List of [Text];
    begin
        FilenameProofGuard.AssertSafeEnvironment();
        FilenameProofLogMgt.StartNewRun();
        BindSubscription(Measure);

        if not FindInvoice() then begin
            ProofSupport.LogLine(NumberedVerdictTok, NoInvoiceMsg);
            UnbindSubscription(Measure);
            FilenameProofLogMgt.Flush();
            exit;
        end;
        AddSecondSelection();
        Commit();

        // Base Application's own names: two files, one name, untouched.
        FilenameProofGuard.ClearPatterns();
        Commit();
        ZipEntries(Names);
        VerdictSameTwice(BaseAppZipVerdictTok, Names);
        DiskNames(Measure, Names);
        VerdictSameTwice(BaseAppDiskVerdictTok, Names);

        // A pattern that names both files alike: the second is numbered.
        SetSameNamePattern();
        Commit();
        ZipEntries(Names);
        VerdictExactly(NumberedZipVerdictTok, Names, SameNamePatternTok + UpperPdfTok, SameNamePatternTok + NumberOneTok + UpperPdfTok);
        DiskNames(Measure, Names);
        VerdictExactly(NumberedDiskVerdictTok, Names, SameNamePatternTok + UpperPdfTok, SameNamePatternTok + NumberOneTok + UpperPdfTok);

        FilenameProofGuard.ClearPatterns();
        RemoveSecondSelection();
        Commit();
        UnbindSubscription(Measure);
        FilenameProofLogMgt.Flush();
    end;

    local procedure ZipEntries(var Names: List of [Text])
    var
        FinishedZip: Codeunit "Data Compression";
        ZipBlob: Codeunit "Temp Blob";
    begin
        Clear(Names);
        Clear(ZipCompression);
        ZipCompression.CreateZipArchive();
        if not RunStep(Step::Zip) then begin
            ProofSupport.LogLine('B7 Zip could not be built', GetLastErrorText());
            exit;
        end;
        ZipCompression.SaveZipArchive(ZipBlob);
        ZipCompression.CloseZipArchive();
        FinishedZip.OpenZipArchive(ZipBlob, false);
        FinishedZip.GetEntryList(Names);
        FinishedZip.CloseZipArchive();
    end;

    local procedure DiskNames(var Measure: Codeunit "Filename Batch Measure"; var Names: List of [Text])
    begin
        Measure.StartCapture();
        if not RunStep(Step::Disk) then
            ProofSupport.LogLine('B7 Send to Disk error', GetLastErrorText());
        Names := Measure.CapturedList();
    end;

    local procedure VerdictSameTwice(Verdict: Text; var Names: List of [Text])
    var
        First: Text;
        Second: Text;
    begin
        ProofSupport.LogLine(StrSubstNo(NamesLineLbl, Verdict), NamesText(Names));
        if Names.Count() <> 2 then begin
            ProofSupport.LogLine(Verdict, StrSubstNo(FailCountMsg, Names.Count()));
            exit;
        end;
        Names.Get(1, First);
        Names.Get(2, Second);
        if First = Second then
            ProofSupport.LogLine(Verdict, StrSubstNo(PassUntouchedMsg, First))
        else
            ProofSupport.LogLine(Verdict, StrSubstNo(FailTouchedMsg, First, Second));
    end;

    local procedure VerdictExactly(Verdict: Text; var Names: List of [Text]; ExpectedFirst: Text; ExpectedSecond: Text)
    var
        First: Text;
        Second: Text;
    begin
        ProofSupport.LogLine(StrSubstNo(NamesLineLbl, Verdict), NamesText(Names));
        if Names.Count() <> 2 then begin
            ProofSupport.LogLine(Verdict, StrSubstNo(FailCountMsg, Names.Count()));
            exit;
        end;
        Names.Get(1, First);
        Names.Get(2, Second);
        if (First = ExpectedFirst) and (Second = ExpectedSecond) then
            ProofSupport.LogLine(Verdict, StrSubstNo(PassNumberedMsg, First, Second))
        else
            ProofSupport.LogLine(Verdict, StrSubstNo(FailNumberedMsg, ExpectedFirst, ExpectedSecond, First, Second));
    end;

    local procedure NamesText(var Names: List of [Text]) Listed: Text
    var
        Name: Text;
    begin
        foreach Name in Names do
            Listed += Name + ' | ';
    end;

    internal procedure CapturedList(): List of [Text]
    begin
        exit(Captured);
    end;

    /// <summary>
    /// The zip Base Application builds in four places - the "PDF &amp; Electronic Document" zip, the
    /// email download fallback's Attachments.zip, Custom Layout Reporting's zip - all go through
    /// Data Compression.AddEntry. What it does with a second entry of the same name decides all of them.
    /// </summary>
    local procedure MeasureDataCompression()
    var
        DataCompression: Codeunit "Data Compression";
        FinishedZip: Codeunit "Data Compression";
        ZipBlob: Codeunit "Temp Blob";
        Entries: List of [Text];
        Entry: Text;
        Listed: Text;
    begin
        DataCompression.CreateZipArchive();
        AddTextEntry(DataCompression, DuplicateEntryTok, FirstContentTok);
        if TryAddTextEntry(DataCompression, DuplicateEntryTok, SecondContentTok) then
            ProofSupport.LogLine('B1 Data Compression, a second entry with the same name', AcceptedMsg)
        else
            ProofSupport.LogLine('B1 Data Compression, a second entry with the same name', StrSubstNo(RefusedMsg, GetLastErrorText()));

        DataCompression.SaveZipArchive(ZipBlob);
        DataCompression.CloseZipArchive();
        FinishedZip.OpenZipArchive(ZipBlob, false);
        FinishedZip.GetEntryList(Entries);
        foreach Entry in Entries do
            Listed += Entry + ' | ';
        ProofSupport.LogLine('B1 Data Compression, entries in the saved zip', StrSubstNo(EntriesMsg, Entries.Count(), Listed));
        if Entries.Count() > 0 then
            ProofSupport.LogLine('B1 Data Compression, content read back for the name', ReadEntry(FinishedZip, DuplicateEntryTok));
        FinishedZip.CloseZipArchive();
    end;

    /// <summary>
    /// The email routes that put several report files on one email - reminder automation, and the
    /// Outlook draft - add them as attachments to one message.
    /// </summary>
    local procedure MeasureEmailMessage()
    var
        EmailMessage: Codeunit "Email Message";
        ContentBlob: Codeunit "Temp Blob";
        ContentStream: InStream;
        Attachments: Integer;
        Listed: Text;
    begin
        // The address is joined here so that no label holds one (CodeCop AA0240).
        EmailMessage.Create(RecipientNameTok + '@' + RecipientDomainTok, SubjectTok, '');
        WriteContent(ContentBlob, FirstContentTok);
        ContentBlob.CreateInStream(ContentStream);
        EmailMessage.AddAttachment(DuplicateEntryTok, PdfContentTypeTok, ContentStream);
        Clear(ContentBlob);
        WriteContent(ContentBlob, SecondContentTok);
        ContentBlob.CreateInStream(ContentStream);
        EmailMessage.AddAttachment(DuplicateEntryTok, PdfContentTypeTok, ContentStream);

        if EmailMessage.Attachments_First() then
            repeat
                Attachments += 1;
                Listed += EmailMessage.Attachments_GetName() + ' | ';
            until EmailMessage.Attachments_Next() = 0;
        ProofSupport.LogLine('B2 Email Message, two attachments with the same name', StrSubstNo(EntriesMsg, Attachments, Listed));

        // The message was never queued or sent, so it is an orphan, and Email Message's own cleanup
        // removes it with its attachments. Started at this message's id and limited to one, it
        // touches nothing else. Until 8 October it was left behind, one per run.
        EmailMessage.DeleteOrphanedMessages(EmailMessage.GetId(), 1);
    end;

    /// <summary>
    /// Whether the email name for one document can come from another document rendered just before.
    /// Reminder automation renders the reminder, then asks for each overdue invoice's attachment name,
    /// then renders the invoices, then names the reminder's own attachment. The email hook names from
    /// the document last rendered. This reproduces the order with two invoices: invoice A is recorded
    /// as rendered, and the name is asked for invoice B.
    /// </summary>
    local procedure MeasureEmailNameForAnotherDocument()
    var
        InvoiceA: Record "Sales Invoice Header";
        InvoiceB: Record "Sales Invoice Header";
        Pattern: Record "Report Filename Pattern";
        ReportFilenameContext: Codeunit "Report Filename Context";
        DocumentMailing: Codeunit "Document-Mailing";
        RenderedRecRef: RecordRef;
        AttachmentFileName: Text[250];
    begin
        InvoiceA.SetFilter("Bill-to Customer No.", '<>%1', '');
        if not InvoiceA.FindFirst() then
            exit;
        InvoiceB.SetFilter("No.", '<>%1', InvoiceA."No.");
        if not InvoiceB.FindFirst() then
            exit;

        FilenameProofGuard.ClearPatterns();
        Pattern.Init();
        Pattern.Validate("Table No.", Database::"Sales Invoice Header");
        Pattern.Validate("File Name Pattern", NumberPatternTok);
        Pattern.Enabled := true;
        Pattern.Insert(true);

        InvoiceA.SetRecFilter();
        RenderedRecRef.GetTable(InvoiceA);
        ReportFilenameContext.SetRenderedDocument(RenderedRecRef, Report::"Standard Sales - Invoice");
        DocumentMailing.GetAttachmentFileName(AttachmentFileName, InvoiceB."No.", DocumentNameTok, Enum::"Report Selection Usage"::"S.Invoice".AsInteger());
        ReportFilenameContext.ClearRenderedDocument();

        ProofSupport.LogLine('B6 Rendered just before', InvoiceA."No.");
        ProofSupport.LogLine('B6 Email attachment name asked for', InvoiceB."No.");
        ProofSupport.LogLine('B6 Name given', AttachmentFileName);
        FilenameProofGuard.ClearPatterns();
        Commit();
    end;

    /// <summary>
    /// "PDF &amp; Electronic Document": SendToZipForCust adds one PDF per report selection.
    /// </summary>
    local procedure MeasureZip(Situation: Text)
    var
        FinishedZip: Codeunit "Data Compression";
        ZipBlob: Codeunit "Temp Blob";
        Entries: List of [Text];
        Entry: Text;
        Listed: Text;
    begin
        Clear(ZipCompression);
        ZipCompression.CreateZipArchive();
        if not RunStep(Step::Zip) then begin
            ProofSupport.LogLine(StrSubstNo(ZipLbl, Situation), StrSubstNo(RefusedMsg, GetLastErrorText()));
            exit;
        end;
        ZipCompression.SaveZipArchive(ZipBlob);
        ZipCompression.CloseZipArchive();
        FinishedZip.OpenZipArchive(ZipBlob, false);
        FinishedZip.GetEntryList(Entries);
        FinishedZip.CloseZipArchive();
        foreach Entry in Entries do
            Listed += Entry + ' | ';
        ProofSupport.LogLine(StrSubstNo(ZipLbl, Situation), StrSubstNo(EntriesMsg, Entries.Count(), Listed));
    end;

    /// <summary>
    /// Runs one report step through Filename Batch Measure Step, so that a step which fails is
    /// isolated and its error read - a render writes, which a TryFunction does not allow.
    /// </summary>
    local procedure RunStep(NewStep: Option None,Zip,Disk,Attach): Boolean
    begin
        Step := NewStep;
        Commit();
        ClearLastError();
        exit(Codeunit.Run(Codeunit::"Filename Batch Measure Step"));
    end;

    /// <summary>
    /// The step Filename Batch Measure Step was started for. Called from that codeunit only.
    /// </summary>
    internal procedure RunCurrentStep()
    var
        ReportSelections: Record "Report Selections";
        RecordVariant: Variant;
    begin
        RecordVariant := SalesInvoiceHeader;
        case Step of
            Step::Zip:
                ReportSelections.SendToZipForCust(
                    Enum::"Report Selection Usage"::"S.Invoice", RecordVariant, SalesInvoiceHeader."No.", SalesInvoiceHeader."Bill-to Customer No.", ZipCompression);
            Step::Disk:
                ReportSelections.SendToDiskForCust(
                    Enum::"Report Selection Usage"::"S.Invoice", RecordVariant, SalesInvoiceHeader."No.", DocumentNameTok, SalesInvoiceHeader."Bill-to Customer No.");
            Step::Attach:
                ReportSelections.SaveAsDocumentAttachment(
                    Enum::"Report Selection Usage"::"S.Invoice".AsInteger(), RecordVariant, SalesInvoiceHeader."No.", SalesInvoiceHeader."Bill-to Customer No.", false);
        end;
    end;

    /// <summary>
    /// Send to Disk: SendToDiskForCust downloads one PDF per report selection. The download itself
    /// cannot happen in a session without a browser, so the name each download is about to use is
    /// read at Base Application's own last event before it, and the download is skipped.
    /// </summary>
    local procedure MeasureSendToDisk(var Measure: Codeunit "Filename Batch Measure"; Situation: Text)
    begin
        Measure.StartCapture();
        if not RunStep(Step::Disk) then
            ProofSupport.LogLine(StrSubstNo(DiskErrorLbl, Situation), GetLastErrorText());
        ProofSupport.LogLine(StrSubstNo(DiskLbl, Situation), StrSubstNo(EntriesMsg, Measure.CapturedCount(), Measure.CapturedNames()));
    end;

    /// <summary>
    /// Attach as PDF: SaveAsDocumentAttachment stores one attachment per report selection on the
    /// document. The rows it adds are read back and then removed.
    /// </summary>
    local procedure MeasureAttach(Situation: Text)
    var
        DocumentAttachment: Record "Document Attachment";
        LastIdBefore: Integer;
        Listed: Text;
        Rows: Integer;
    begin
        DocumentAttachment.SetRange("Table ID", Database::"Sales Invoice Header");
        DocumentAttachment.SetRange("No.", SalesInvoiceHeader."No.");
        if DocumentAttachment.FindLast() then
            LastIdBefore := DocumentAttachment.ID;
        Commit();

        if not RunStep(Step::Attach) then
            ProofSupport.LogLine(StrSubstNo(AttachErrorLbl, Situation), GetLastErrorText());

        DocumentAttachment.SetFilter(ID, '>%1', LastIdBefore);
        if DocumentAttachment.FindSet() then
            repeat
                Rows += 1;
                Listed += DocumentAttachment."File Name" + '.' + DocumentAttachment."File Extension" + ' | ';
            until DocumentAttachment.Next() = 0;
        ProofSupport.LogLine(StrSubstNo(AttachLbl, Situation), StrSubstNo(EntriesMsg, Rows, Listed));
        DocumentAttachment.DeleteAll(false);
        Commit();
    end;

    /// <summary>
    /// Records the name Send to Disk is about to download under, at Base Application's last event
    /// before the download, and skips the download a session without a browser cannot make.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnBeforeDownloadAttachmentFromStream', '', false, false)]
    local procedure CaptureDownload(var TempReportSelections: Record "Report Selections" temporary; RecordVariant: Variant; var AttachmentInStream: InStream; ClientAttachmentFileName: Text; var IsHandled: Boolean)
    begin
        Captured.Add(ClientAttachmentFileName);
        IsHandled := true;
    end;

    internal procedure StartCapture()
    begin
        Clear(Captured);
    end;

    internal procedure CapturedCount(): Integer
    begin
        exit(Captured.Count());
    end;

    internal procedure CapturedNames() Listed: Text
    var
        Name: Text;
    begin
        foreach Name in Captured do
            Listed += Name + ' | ';
    end;

    local procedure FindInvoice(): Boolean
    begin
        SalesInvoiceHeader.Reset();
        SalesInvoiceHeader.SetFilter("Bill-to Customer No.", '<>%1', '');
        if not SalesInvoiceHeader.FindFirst() then
            exit(false);
        SalesInvoiceHeader.SetRecFilter();
        ProofSupport.LogLine('B0 Invoice', SalesInvoiceHeader."No.");
        exit(true);
    end;

    /// <summary>
    /// A second report for the invoice usage, the same report as the first. Two rows for one usage is
    /// what a company has when it sends, say, an invoice and its terms; the same report twice keeps
    /// every other difference out of the measurement.
    /// </summary>
    local procedure AddSecondSelection()
    var
        ReportSelections: Record "Report Selections";
        Existing: Record "Report Selections";
    begin
        RemoveSecondSelection();
        Existing.SetRange(Usage, Existing.Usage::"S.Invoice");
        Existing.FindFirst();
        ReportSelections := Existing;
        ReportSelections.Sequence := SecondSequenceTok;
        ReportSelections.Insert(false);

        Existing.Reset();
        Existing.SetRange(Usage, Existing.Usage::"S.Invoice");
        ProofSupport.LogLine('B0 Report selections for S.Invoice during the run', Format(Existing.Count()));
    end;

    local procedure RemoveSecondSelection()
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"S.Invoice");
        ReportSelections.SetRange(Sequence, SecondSequenceTok);
        ReportSelections.DeleteAll(false);
    end;

    local procedure SetSameNamePattern()
    var
        Pattern: Record "Report Filename Pattern";
    begin
        FilenameProofGuard.ClearPatterns();
        Pattern.Init();
        Pattern.Validate("Table No.", Database::"Sales Invoice Header");
        Pattern.Validate("File Name Pattern", SameNamePatternTok);
        Pattern.Enabled := true;
        Pattern.Insert(true);
    end;

    local procedure AddTextEntry(var DataCompression: Codeunit "Data Compression"; EntryName: Text; Content: Text)
    var
        ContentBlob: Codeunit "Temp Blob";
        ContentStream: InStream;
    begin
        WriteContent(ContentBlob, Content);
        ContentBlob.CreateInStream(ContentStream);
        DataCompression.AddEntry(ContentStream, EntryName);
    end;

    [TryFunction]
    local procedure TryAddTextEntry(var DataCompression: Codeunit "Data Compression"; EntryName: Text; Content: Text)
    begin
        AddTextEntry(DataCompression, EntryName, Content);
    end;

    local procedure WriteContent(var ContentBlob: Codeunit "Temp Blob"; Content: Text)
    var
        ContentOutStream: OutStream;
    begin
        ContentBlob.CreateOutStream(ContentOutStream);
        ContentOutStream.WriteText(Content);
    end;

    local procedure ReadEntry(var FinishedZip: Codeunit "Data Compression"; EntryName: Text) Content: Text
    var
        EntryBlob: Codeunit "Temp Blob";
        EntryOutStream: OutStream;
        EntryInStream: InStream;
    begin
        EntryBlob.CreateOutStream(EntryOutStream);
        FinishedZip.ExtractEntry(EntryName, EntryOutStream);
        EntryBlob.CreateInStream(EntryInStream);
        EntryInStream.ReadText(Content);
    end;

    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FilenameProofGuard: Codeunit "Filename Proof Guard";
        ProofSupport: Codeunit "Filename Proof Support";
        ZipCompression: Codeunit "Data Compression";
        Captured: List of [Text];
        Step: Option None,Zip,Disk,Attach;
        NoPatternTok: Label 'no pattern', Locked = true;
        SameNamePatternTok: Label 'SameName', Locked = true;
        NumberPatternTok: Label 'Invoice-[No.]', Locked = true;
        UpperPdfTok: Label '.PDF', Locked = true;
        NamesLineLbl: Label 'B7 Names behind "%1"', Comment = '%1 the verdict', Locked = true;
        NumberOneTok: Label ' (1)', Locked = true;
        NumberedVerdictTok: Label 'RESULT repeated names in one batch', Locked = true;
        BaseAppZipVerdictTok: Label 'RESULT Business Central''s own zip entry names are left as they are', Locked = true;
        BaseAppDiskVerdictTok: Label 'RESULT Business Central''s own Send to Disk names are left as they are', Locked = true;
        NumberedZipVerdictTok: Label 'RESULT a name repeated in one zip is numbered', Locked = true;
        NumberedDiskVerdictTok: Label 'RESULT a name repeated in one Send to Disk is numbered', Locked = true;
        PassUntouchedMsg: Label 'PASS - both files keep Business Central''s own name %1; the feature did not change a name it did not give.', Comment = '%1 the name';
        FailTouchedMsg: Label 'FAIL - with no pattern the two files should keep Business Central''s one name, but are %1 and %2.', Comment = '%1 first, %2 second';
        PassNumberedMsg: Label 'PASS - %1 and %2.', Comment = '%1 first name, %2 second name';
        FailNumberedMsg: Label 'FAIL - expected %1 and %2, got %3 and %4.', Comment = '%1 and %2 expected, %3 and %4 actual';
        FailCountMsg: Label 'FAIL - expected two files, got %1.', Comment = '%1 how many';
        SecondSequenceTok: Label 'ZZMEASURE', Locked = true;
        DuplicateEntryTok: Label 'Same.pdf', Locked = true;
        FirstContentTok: Label 'first', Locked = true;
        SecondContentTok: Label 'second', Locked = true;
        RecipientNameTok: Label 'measure', Locked = true;
        RecipientDomainTok: Label 'example.com', Locked = true;
        SubjectTok: Label 'Duplicate attachment names', Locked = true;
        PdfContentTypeTok: Label 'application/pdf', Locked = true;
        DocumentNameTok: Label 'Invoice', Locked = true;
        ZipLbl: Label 'B3 PDF & Electronic Document zip, %1', Comment = '%1 no pattern or the pattern', Locked = true;
        DiskLbl: Label 'B4 Send to Disk downloads, %1', Comment = '%1 no pattern or the pattern', Locked = true;
        DiskErrorLbl: Label 'B4 Send to Disk error, %1', Comment = '%1 no pattern or the pattern', Locked = true;
        AttachLbl: Label 'B5 Attach as PDF rows, %1', Comment = '%1 no pattern or the pattern', Locked = true;
        AttachErrorLbl: Label 'B5 Attach as PDF error, %1', Comment = '%1 no pattern or the pattern', Locked = true;
        EntriesMsg: Label '%1: %2', Comment = '%1 how many, %2 their names', Locked = true;
        AcceptedMsg: Label 'accepted, no error', Locked = true;
        RefusedMsg: Label 'refused: %1', Comment = '%1 the error', Locked = true;
        NoInvoiceMsg: Label 'No posted sales invoice with a customer, so the report workflows cannot be measured.', Locked = true;
}
