// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.Reporting.FileNaming;
using Microsoft.Sales.History;
using System.Email;
using System.IO;
using System.Utilities;

codeunit 149540 "Filename Batch Measure"
{
    // Records (not pass/fail) what happens when one action produces several files with the same
    // name, in the Base Application workflows below that can be driven from AL; log lines begin "B".
    // A second Report Selections row for the usage makes one action produce two files.

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

        PostInvoice();
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

        UnbindSubscription(Measure);
        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// Repeated pattern names within one zip or one Send to Disk are numbered as Base Application
    /// numbers a repeated attachment; Base Application's own names are left as they are.
    /// </summary>
    procedure ProveRepeatedNamesAreNumbered()
    var
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        ReportFilenameContext: Codeunit "Report Filename Context";
        Measure: Codeunit "Filename Batch Measure";
        Names: List of [Text];
        ZipSuffix: Text;
        DiskSuffix: Text;
    begin
        FilenameProofGuard.AssertSafeEnvironment();
        FilenameProofLogMgt.StartNewRun();
        BindSubscription(Measure);

        PostInvoice();
        AddSecondSelection();
        Commit();

        // Base Application's own names, untouched; their extension case is the one named files must carry.
        FilenameProofGuard.ClearPatterns();
        Commit();
        ZipEntries(Names);
        VerdictSameTwice(BaseAppZipVerdictTok, Names);
        ZipSuffix := FirstSuffix(Names);
        DiskNames(Measure, Names);
        VerdictSameTwice(BaseAppDiskVerdictTok, Names);
        DiskSuffix := FirstSuffix(Names);

        SetSameNamePattern();
        Commit();
        // Stands in for SendElectronically, which on the real route notes the extension case earlier.
        ReportFilenameContext.NoteExtensionCasing(ZipSuffix = LowerCase(ZipSuffix));
        ZipEntries(Names);
        VerdictExactly(NumberedZipVerdictTok, Names, SameNamePatternTok + ZipSuffix, SameNamePatternTok + NumberOneTok + ZipSuffix);
        DiskNames(Measure, Names);
        VerdictExactly(NumberedDiskVerdictTok, Names, SameNamePatternTok + DiskSuffix, SameNamePatternTok + NumberOneTok + DiskSuffix);

        FilenameProofGuard.ClearPatterns();
        RemoveSecondSelection();
        Commit();
        UnbindSubscription(Measure);
        FilenameProofLogMgt.Flush();
    end;

    // With its dot; blank when there is none.
    local procedure FirstSuffix(var Names: List of [Text]): Text
    var
        Name: Text;
        DotPosition: Integer;
    begin
        if Names.Count() = 0 then
            exit('');
        Name := Names.Get(1);
        DotPosition := Name.LastIndexOf('.');
        if DotPosition <= 1 then
            exit('');
        exit(CopyStr(Name, DotPosition));
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

    // The report zips Base Application builds (Report Selections, Electronic Document Format) add
    // their entries through Data Compression.AddEntry, so its handling of a repeated name decides them.
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

    // Reminder automation and the Outlook draft add several report files to one message.
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

        // Never queued, so an orphan; started at its id and limited to one, nothing else is touched.
        EmailMessage.DeleteOrphanedMessages(EmailMessage.GetId(), 1);
    end;

    // Whether one document's email name can come from another rendered just before, as in reminder
    // automation's order: invoice A is recorded as rendered, and the name is asked for invoice B.
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
        ReportFilenameContext.ClearLastRendered();
        ReportFilenameContext.ClearHeldDocument();

        ProofSupport.LogLine('B6 Rendered just before', InvoiceA."No.");
        ProofSupport.LogLine('B6 Email attachment name asked for', InvoiceB."No.");
        ProofSupport.LogLine('B6 Name given', AttachmentFileName);
        FilenameProofGuard.ClearPatterns();
        Commit();
    end;

    // "PDF & Electronic Document": one PDF per report selection.
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

    // Isolated through Codeunit.Run: a render writes, which a TryFunction does not allow
    // on-premises by default.
    local procedure RunStep(NewStep: Option None,Zip,Disk,Attach): Boolean
    begin
        Step := NewStep;
        Commit();
        ClearLastError();
        exit(Codeunit.Run(Codeunit::"Filename Batch Measure Step"));
    end;

    // Called from Filename Batch Measure Step only.
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

    // One download per report selection; the names are read just before and the downloads skipped.
    local procedure MeasureSendToDisk(var Measure: Codeunit "Filename Batch Measure"; Situation: Text)
    begin
        Measure.StartCapture();
        if not RunStep(Step::Disk) then
            ProofSupport.LogLine(StrSubstNo(DiskErrorLbl, Situation), GetLastErrorText());
        ProofSupport.LogLine(StrSubstNo(DiskLbl, Situation), StrSubstNo(EntriesMsg, Measure.CapturedCount(), Measure.CapturedNames()));
    end;

    // One attachment per report selection; the rows added are read back and removed.
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

    // Skips the download, so the measurement does not depend on a client.
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

    local procedure PostInvoice()
    var
        TestData: Codeunit "Filename Test Data";
    begin
        TestData.PostNewInvoice(SalesInvoiceHeader);
        ProofSupport.LogLine('B0 Invoice', SalesInvoiceHeader."No.");
    end;

    // The same report as the first, to keep every other difference out of the measurement.
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
        NamesLineLbl: Label 'B7 Names behind "%1"', Comment = '%1 the verdict', Locked = true;
        NumberOneTok: Label ' (1)', Locked = true;
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
}
