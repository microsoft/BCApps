// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50194 "Filename Proof Elec. Doc."
{
    // The electronic document - the XML a Document Sending Profile writes to Disk or puts in a zip -
    // and the zip itself, on the Electronic Document output route.
    //
    // The real route runs: Document Sending Profile.Send, whose Disk step ends in File Management.
    // BLOBExport. Its OnBeforeBlobExport carries the name the file is downloaded under, and this
    // codeunit reads it there and takes the download over, so a test session without a client gets
    // the same name a person would. It does so only while a proof is running.
    //
    // Every check compares against the name Business Central produces with no pattern, read from
    // Business Central, never against what this feature says it produced.

    SingleInstance = true;

    /// <summary>
    /// An invoice's electronic document on Disk is named by a pattern on the Electronic Document route
    /// or on Any, and not by a pattern on Disk, which is the PDF's route.
    /// </summary>
    procedure ProveDiskElectronicDocument()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        Baseline: Text;
        Named: Text;
    begin
        FilenameProofLogMgt.StartNewRun();
        if not FindInvoice(SalesInvoiceHeader) then begin
            FilenameProofLogMgt.Flush();
            exit;
        end;

        ProofGuard.ClearPatterns();
        Baseline := DiskDownload(SalesInvoiceHeader, Enum::"Doc. Sending Profile Disk"::"Electronic Document");
        ProofSupport.LogLine('A0 With no pattern the electronic document is', Baseline);
        LogVerdict(BaselineIsBusinessCentralsTok, BusinessCentralsName(SalesInvoiceHeader), Baseline);

        CreatePattern(Enum::"Report Filename Output Route"::ElectronicDocument);
        Named := DiskDownload(SalesInvoiceHeader, Enum::"Doc. Sending Profile Disk"::"Electronic Document");
        ProofSupport.LogLine('A1 With an Electronic Document pattern', Named);
        LogVerdict(NamedByRouteTok, SalesInvoiceHeader."No." + SuffixOf(Baseline), Named);

        ProofGuard.ClearPatterns();
        CreatePattern(Enum::"Report Filename Output Route"::Any);
        Named := DiskDownload(SalesInvoiceHeader, Enum::"Doc. Sending Profile Disk"::"Electronic Document");
        ProofSupport.LogLine('A2 With an Any pattern', Named);
        LogVerdict(NamedByAnyTok, SalesInvoiceHeader."No." + SuffixOf(Baseline), Named);

        ProofGuard.ClearPatterns();
        CreatePattern(Enum::"Report Filename Output Route"::Disk);
        Named := DiskDownload(SalesInvoiceHeader, Enum::"Doc. Sending Profile Disk"::"Electronic Document");
        ProofSupport.LogLine('A3 With a Disk pattern', Named);
        LogVerdict(NotNamedByDiskTok, Baseline, Named);

        ProofGuard.ClearPatterns();
        RemoveProofFormat();
        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// A name another app gives the electronic document, through GetAttachmentFileName's own event, is
    /// kept: a pattern names the file only while its name is still Business Central's.
    /// </summary>
    procedure ProveAnotherAppsNameStands()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        Named: Text;
    begin
        FilenameProofLogMgt.StartNewRun();
        if not FindInvoice(SalesInvoiceHeader) then begin
            FilenameProofLogMgt.Flush();
            exit;
        end;

        ProofGuard.ClearPatterns();
        CreatePattern(Enum::"Report Filename Output Route"::Any);
        NameLikeAnotherApp := true;
        Named := DiskDownload(SalesInvoiceHeader, Enum::"Doc. Sending Profile Disk"::"Electronic Document");
        NameLikeAnotherApp := false;
        ProofSupport.LogLine('B0 Named by another app, with an Any pattern', Named);
        LogVerdict(AnotherAppsNameStandsTok, StrSubstNo(AnotherAppsNameTok, SalesInvoiceHeader."No."), Named);

        ProofGuard.ClearPatterns();
        RemoveProofFormat();
        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// "PDF &amp; Electronic Document" on Disk: the zip, and the electronic document inside it, take the
    /// pattern's name; the PDF beside them is named on its own route as before.
    /// </summary>
    procedure ProveZipOfBoth()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        Baseline: Text;
        BaselineEntries: Text;
        Named: Text;
    begin
        FilenameProofLogMgt.StartNewRun();
        if not FindInvoice(SalesInvoiceHeader) then begin
            FilenameProofLogMgt.Flush();
            exit;
        end;

        ProofGuard.ClearPatterns();
        Baseline := DiskDownload(SalesInvoiceHeader, Enum::"Doc. Sending Profile Disk"::"PDF & Electronic Document");
        BaselineEntries := CapturedEntries;
        ProofSupport.LogLine('C0 With no pattern the zip is', Baseline);
        ProofSupport.LogLine('C0 and holds', CapturedEntries);

        CreatePattern(Enum::"Report Filename Output Route"::Any);
        Named := DiskDownload(SalesInvoiceHeader, Enum::"Doc. Sending Profile Disk"::"PDF & Electronic Document");
        ProofSupport.LogLine('C1 With an Any pattern the zip is', Named);
        ProofSupport.LogLine('C1 and holds', CapturedEntries);
        LogVerdict(ZipNamedTok, SalesInvoiceHeader."No." + SuffixOf(Baseline), Named);
        LogVerdict(ZipEntriesNamedTok, EachNamed(BaselineEntries, SalesInvoiceHeader."No."), CapturedEntries);

        ProofGuard.ClearPatterns();
        RemoveProofFormat();
        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// Two invoices for one customer sent together: Business Central puts their electronic documents in
    /// one zip, which it names after a document. The zip and both documents in it take the pattern's
    /// names - the one case where the zip's name is not built from the electronic document's.
    /// </summary>
    procedure ProveTwoDocumentsInOneZip()
    var
        Candidate: Record "Sales Invoice Header";
        Other: Record "Sales Invoice Header";
        Selection: Record "Sales Invoice Header";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        Baseline: Text;
        BaselineEntries: Text;
        Named: Text;
        Found: Boolean;
    begin
        FilenameProofLogMgt.StartNewRun();
        Capturing := false;
        NameLikeAnotherApp := false;

        Candidate.SetCurrentKey("No.");
        Candidate.SetFilter("Bill-to Customer No.", '<>%1', '');
        if Candidate.FindSet() then
            repeat
                Other.SetCurrentKey("No.");
                Other.SetRange("Bill-to Customer No.", Candidate."Bill-to Customer No.");
                Other.SetFilter("No.", '>%1', Candidate."No.");
                Found := Other.FindFirst();
            until Found or (Candidate.Next() = 0);
        if not Found then begin
            ProofSupport.LogLine('Setup', NoTwoInvoicesMsg);
            FilenameProofLogMgt.Flush();
            exit;
        end;
        Selection.SetCurrentKey("No.");
        Selection.SetFilter("No.", '%1|%2', Candidate."No.", Other."No.");
        Selection.FindFirst();
        ProofSupport.LogLine('E Selection', Candidate."No." + ' and ' + Other."No.");

        ProofGuard.ClearPatterns();
        Baseline := DiskDownload(Selection, Enum::"Doc. Sending Profile Disk"::"Electronic Document");
        BaselineEntries := CapturedEntries;
        ProofSupport.LogLine('E0 With no pattern the zip is', Baseline);
        ProofSupport.LogLine('E0 and holds', BaselineEntries);

        CreatePattern(Enum::"Report Filename Output Route"::ElectronicDocument);
        Named := DiskDownload(Selection, Enum::"Doc. Sending Profile Disk"::"Electronic Document");
        ProofSupport.LogLine('E1 With an Electronic Document pattern the zip is', Named);
        ProofSupport.LogLine('E1 and holds', CapturedEntries);
        // Business Central names the zip from the document it finished on, the second.
        LogVerdict(TwoInOneZipNamedTok, Other."No." + SuffixOf(Baseline), Named);
        LogVerdict(TwoInOneZipEntriesTok,
            Candidate."No." + SuffixOf(FirstEntry(BaselineEntries)) + EntrySeparatorTok + Other."No." + SuffixOf(FirstEntry(BaselineEntries)), CapturedEntries);

        ProofGuard.ClearPatterns();
        RemoveProofFormat();
        FilenameProofLogMgt.Flush();
    end;

    local procedure FirstEntry(Entries: Text): Text
    begin
        if Entries.IndexOf(EntrySeparatorTok) = 0 then
            exit(Entries);
        exit(CopyStr(Entries, 1, Entries.IndexOf(EntrySeparatorTok) - 1));
    end;

    /// <summary>
    /// The electronic document service gets Business Central's own name, whatever the patterns say: the
    /// service's delivery code receives the name and may rely on it.
    /// </summary>
    procedure ProveServiceDeliveryIsNotRenamed()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
    begin
        FilenameProofLogMgt.StartNewRun();
        if not FindInvoice(SalesInvoiceHeader) then begin
            FilenameProofLogMgt.Flush();
            exit;
        end;

        ProofGuard.ClearPatterns();
        CreatePattern(Enum::"Report Filename Output Route"::Any);
        Clear(CapturedServiceName);
        // Made here, outside the isolated send, so its failure cannot take the format with it.
        ElectronicFormatCode();
        Capturing := true;
        // The service is not set up here, so sending to it fails - after the name is handed over.
        Commit();
        if Codeunit.Run(Codeunit::"Filename Proof Send Service", SalesInvoiceHeader) then;
        Capturing := false;
        ProofSupport.LogLine('D0 The service was handed, with an Any pattern', CapturedServiceName);
        LogVerdict(ServiceNotRenamedTok, BusinessCentralsName(SalesInvoiceHeader), CapturedServiceName);

        ProofGuard.ClearPatterns();
        RemoveProofFormat();
        FilenameProofLogMgt.Flush();
    end;

    local procedure FindInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"): Boolean
    begin
        // This codeunit lives for the session, so a proof that failed half-way must not leave the
        // next one capturing or naming like another app.
        Capturing := false;
        NameLikeAnotherApp := false;
        SalesInvoiceHeader.SetFilter("Bill-to Customer No.", '<>%1', '');
        if not SalesInvoiceHeader.FindFirst() then begin
            ProofSupport.LogLine('Setup', NoSalesInvoiceMsg);
            exit(false);
        end;
        SalesInvoiceHeader.SetRecFilter();
        ProofSupport.LogLine('Invoice', SalesInvoiceHeader."No.");
        exit(true);
    end;

    /// <summary>
    /// What Business Central itself calls the invoice's electronic document.
    /// </summary>
    local procedure BusinessCentralsName(var SalesInvoiceHeader: Record "Sales Invoice Header"): Text
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        exit(ElectronicDocumentFormat.GetAttachmentFileName(
            SalesInvoiceHeader, SalesInvoiceHeader."No.", ElectronicDocumentFormat.GetDocumentType(SalesInvoiceHeader), XmlTok));
    end;

    /// <summary>
    /// Sends the invoice through a Document Sending Profile whose only option is the given Disk option,
    /// and returns the name the file is downloaded under.
    /// </summary>
    local procedure DiskDownload(var SalesInvoiceHeader: Record "Sales Invoice Header"; Option: Enum "Doc. Sending Profile Disk"): Text
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        RecordVariant: Variant;
    begin
        DocumentSendingProfile.Init();
        DocumentSendingProfile.Disk := Option;
        DocumentSendingProfile."Disk Format" := ElectronicFormatCode();
        RecordVariant := SalesInvoiceHeader;

        Clear(CapturedDownload);
        Clear(CapturedEntries);
        Capturing := true;
        // The route renders a report, and Business Central refuses to render with a write transaction open.
        Commit();
        // Send, as Post and Send and the Send action do. TrySendToDisk, the Disk action, sets Disk to PDF
        // first, so it never writes an electronic document.
        DocumentSendingProfile.Send(
            Enum::"Report Selection Usage"::"S.Invoice".AsInteger(), RecordVariant, SalesInvoiceHeader."No.", SalesInvoiceHeader."Bill-to Customer No.", DocumentNameTok,
            SalesInvoiceHeader.FieldNo("Bill-to Customer No."), SalesInvoiceHeader.FieldNo("No."));
        Capturing := false;
        exit(CapturedDownload);
    end;

    /// <summary>
    /// An electronic document format of the proof's own for posted sales invoices, whose export writes
    /// a fixed, minimal XML. Business Central builds the file's name in SendElectronically whatever the
    /// format, and a format's export only fills the file - so this proves the naming exactly, without
    /// the validation a real format such as PEPPOL applies to the demonstration company's data.
    /// Removed again by RemoveProofFormat.
    /// </summary>
    internal procedure ElectronicFormatCode(): Code[20]
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        if not ElectronicDocumentFormat.Get(ProofFormatTok, ElectronicDocumentFormat.Usage::"Sales Invoice") then begin
            ElectronicDocumentFormat.Init();
            ElectronicDocumentFormat.Code := ProofFormatTok;
            ElectronicDocumentFormat.Usage := ElectronicDocumentFormat.Usage::"Sales Invoice";
            ElectronicDocumentFormat.Description := ProofFormatTok;
            ElectronicDocumentFormat."Codeunit ID" := Codeunit::"Filename Proof Export";
            ElectronicDocumentFormat.Insert(false);
        end;
        exit(ElectronicDocumentFormat.Code);
    end;

    /// <summary>
    /// Takes the proof's electronic document format away again.
    /// </summary>
    internal procedure RemoveProofFormat()
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        ElectronicDocumentFormat.SetRange(Code, ProofFormatTok);
        ElectronicDocumentFormat.DeleteAll(false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"File Management", 'OnBeforeBlobExport', '', false, false)]
    local procedure CaptureDownload(var TempBlob: Codeunit "Temp Blob"; Name: Text; CommonDialog: Boolean; var IsHandled: Boolean; var Result: Text)
    begin
        if not Capturing then
            exit;
        CapturedDownload := Name;
        CapturedEntries := EntriesOf(TempBlob, Name);
        IsHandled := true;
        Result := Name;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Electronic Document Format", 'OnAfterSendElectronically', '', false, false)]
    local procedure CaptureServiceName(var ElectronicDocumentFormat: Record "Electronic Document Format"; var ClientFileName: Text[250]; DocumentVariant: Variant; ElectronicFormat: Code[20])
    begin
        if Capturing then
            CapturedServiceName := ClientFileName;
    end;

    /// <summary>
    /// Names the electronic document the way another app would - through GetAttachmentFileName's own
    /// event - while the proof asks for it.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Electronic Document Format", 'OnBeforeGetAttachmentFileName', '', false, false)]
    local procedure NameAsAnotherApp(RecordVariant: Variant; DocumentNo: Code[20]; DocumentType: Text; Extension: Code[3]; var IsHandled: Boolean; var FileName: Text[250])
    begin
        if not NameLikeAnotherApp then
            exit;
        if Extension <> XmlTok then
            exit;
        FileName := StrSubstNo(AnotherAppsNameTok, DocumentNo);
        IsHandled := true;
    end;

    /// <summary>
    /// The names of the entries in a zip, joined, in the order the zip holds them; blank for a file
    /// that is not a zip.
    /// </summary>
    local procedure EntriesOf(var TempBlob: Codeunit "Temp Blob"; Name: Text): Text
    var
        DataCompression: Codeunit "Data Compression";
        Entries: List of [Text];
        Entry: Text;
        Joined: Text;
    begin
        if not Name.ToLower().EndsWith(ZipSuffixTok) then
            exit('');
        DataCompression.OpenZipArchive(TempBlob, false);
        DataCompression.GetEntryList(Entries);
        DataCompression.CloseZipArchive();
        foreach Entry in Entries do begin
            if Joined <> '' then
                Joined += EntrySeparatorTok;
            Joined += Entry;
        end;
        exit(Joined);
    end;

    /// <summary>
    /// The entries Business Central's own zip holds, each renamed to the document number with its own
    /// extension - what a pattern of [No.] makes of every entry.
    /// </summary>
    local procedure EachNamed(Entries: Text; DocumentNo: Code[20]): Text
    var
        Entry: Text;
        Joined: Text;
    begin
        foreach Entry in Entries.Split(EntrySeparatorTok) do begin
            if Joined <> '' then
                Joined += EntrySeparatorTok;
            Joined += DocumentNo + SuffixOf(Entry);
        end;
        exit(Joined);
    end;

    local procedure CreatePattern(Route: Enum "Report Filename Output Route")
    var
        Pattern: Record "Report Filename Pattern";
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"S.Invoice");
        ReportSelections.SetFilter("Report ID", '<>%1', 0);
        if not ReportSelections.FindFirst() then begin
            ProofSupport.LogLine('Setup', NoReportSelectionMsg);
            exit;
        end;

        Pattern.Init();
        Pattern.Validate("Table No.", Database::"Sales Invoice Header");
        Pattern.Validate("Report ID", ReportSelections."Report ID");
        ProofSupport.LimitToRoute(Pattern, Route);
        Pattern.Validate("File Name Pattern", PatternTok);
        Pattern.Enabled := true;
        Pattern.Insert(true);
    end;

    local procedure LogVerdict(Verdict: Text; Expected: Text; Actual: Text)
    begin
        if Actual = Expected then
            ProofSupport.LogLine('RESULT ' + Verdict, PassMsg)
        else
            ProofSupport.LogLine('RESULT ' + Verdict, StrSubstNo(ExpectedButGotMsg, Expected, Actual));
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

    var
        ProofGuard: Codeunit "Filename Proof Guard";
        ProofSupport: Codeunit "Filename Proof Support";
        Capturing: Boolean;
        NameLikeAnotherApp: Boolean;
        CapturedDownload: Text;
        CapturedEntries: Text;
        CapturedServiceName: Text;
        PatternTok: Label '[No.]', Locked = true;
        ProofFormatTok: Label 'ZZPROOF', Locked = true;
        XmlTok: Label 'XML', Locked = true;
        ZipSuffixTok: Label '.zip', Locked = true;
        EntrySeparatorTok: Label ' + ', Locked = true;
        DocumentNameTok: Label 'Invoice', Locked = true;
        AnotherAppsNameTok: Label 'Another-app-%1.xml', Comment = '%1 the document number', Locked = true;
        BaselineIsBusinessCentralsTok: Label 'with no pattern the electronic document has Business Central''s own name', Locked = true;
        NamedByRouteTok: Label 'a pattern on the Electronic Document route names the electronic document', Locked = true;
        NamedByAnyTok: Label 'a pattern on Any names the electronic document', Locked = true;
        NotNamedByDiskTok: Label 'a pattern on Disk leaves the electronic document alone', Locked = true;
        AnotherAppsNameStandsTok: Label 'a name another app gives the electronic document stands', Locked = true;
        ZipNamedTok: Label 'the zip of a PDF and an electronic document is named from the pattern', Locked = true;
        ZipEntriesNamedTok: Label 'the electronic document and the PDF in that zip are named from the pattern', Locked = true;
        TwoInOneZipNamedTok: Label 'the zip of two invoices'' electronic documents is named from the pattern', Locked = true;
        TwoInOneZipEntriesTok: Label 'both electronic documents in that zip are named from the pattern', Locked = true;
        NoTwoInvoicesMsg: Label 'No customer has two posted sales invoices in this company, so there is no selection to send.';
        ServiceNotRenamedTok: Label 'the electronic document service is handed Business Central''s own name', Locked = true;
        NoSalesInvoiceMsg: Label 'No posted sales invoice in this company, so there is nothing to send.';
        NoReportSelectionMsg: Label 'No report is selected for sales invoices, so no pattern can name one.';
        PassMsg: Label 'PASS';
        ExpectedButGotMsg: Label 'FAIL expected %1 but got %2', Comment = '%1 expected, %2 actual';
}
