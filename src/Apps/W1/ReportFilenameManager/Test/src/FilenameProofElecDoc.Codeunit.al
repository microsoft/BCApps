// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.Reporting.FileNaming;
using Microsoft.Sales.History;
using System.IO;
using System.Utilities;

codeunit 149544 "Filename Proof Elec. Doc."
{
    // Proofs for the electronic document and its zip on the Electronic Document route, through the
    // real Document Sending Profile.Send. The download name is read at File Management's
    // OnBeforeBlobExport, which takes the download over while a proof runs.

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
        PostInvoice(SalesInvoiceHeader);

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
        PostInvoice(SalesInvoiceHeader);

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
        PostInvoice(SalesInvoiceHeader);

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
    /// Two invoices of one customer sent together go in one zip; the zip and both documents in it
    /// take the pattern's names.
    /// </summary>
    procedure ProveTwoDocumentsInOneZip()
    var
        Selection: Record "Sales Invoice Header";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        InvoiceNos: List of [Code[20]];
        FirstNo: Code[20];
        SecondNo: Code[20];
        Baseline: Text;
        BaselineEntries: Text;
        Named: Text;
    begin
        FilenameProofLogMgt.StartNewRun();
        Capturing := false;
        NameLikeAnotherApp := false;

        TestData.PostInvoicesOfOneCustomer(2, InvoiceNos);
        FirstNo := InvoiceNos.Get(1);
        SecondNo := InvoiceNos.Get(2);
        Selection.SetCurrentKey("No.");
        Selection.SetFilter("No.", '%1|%2', FirstNo, SecondNo);
        Selection.FindFirst();
        ProofSupport.LogLine('E Selection', FirstNo + ' and ' + SecondNo);

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
        LogVerdict(TwoInOneZipNamedTok, SecondNo + SuffixOf(Baseline), Named);
        LogVerdict(TwoInOneZipEntriesTok,
            FirstNo + SuffixOf(FirstEntry(BaselineEntries)) + EntrySeparatorTok + SecondNo + SuffixOf(FirstEntry(BaselineEntries)), CapturedEntries);

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
    /// The electronic document service gets Business Central's own name whatever the patterns say.
    /// </summary>
    procedure ProveServiceDeliveryIsNotRenamed()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
    begin
        FilenameProofLogMgt.StartNewRun();
        PostInvoice(SalesInvoiceHeader);

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

    local procedure PostInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        // This codeunit lives for the session; reset what a proof that failed half-way left on.
        Capturing := false;
        NameLikeAnotherApp := false;
        TestData.PostNewInvoice(SalesInvoiceHeader);
        ProofSupport.LogLine('Invoice', SalesInvoiceHeader."No.");
    end;

    local procedure BusinessCentralsName(var SalesInvoiceHeader: Record "Sales Invoice Header"): Text
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        exit(ElectronicDocumentFormat.GetAttachmentFileName(
            SalesInvoiceHeader, SalesInvoiceHeader."No.", ElectronicDocumentFormat.GetDocumentType(SalesInvoiceHeader), XmlTok));
    end;

    // Sends through a profile whose only option is the given Disk option; returns the download name.
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
        // Committed before the send: with a PDF the route commits on its own (SaveReportAsPDFInTempBlob).
        Commit();
        // Send, not TrySendToDisk: that sets Disk to PDF first and never writes an electronic document.
        DocumentSendingProfile.Send(
            Enum::"Report Selection Usage"::"S.Invoice".AsInteger(), RecordVariant, SalesInvoiceHeader."No.", SalesInvoiceHeader."Bill-to Customer No.", DocumentNameTok,
            SalesInvoiceHeader.FieldNo("Bill-to Customer No."), SalesInvoiceHeader.FieldNo("No."));
        Capturing := false;
        exit(CapturedDownload);
    end;

    // The proof's own format, exporting a fixed XML: SendElectronically names the file whatever the
    // format, so this avoids a real format's (e.g. PEPPOL's) validation of the company's data.
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

    // Names the electronic document as another app would, while the proof asks for it.
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

    // Joined in zip order; blank for a file that is not a zip.
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

    // What a pattern of [No.] makes of every entry.
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
        TestData: Codeunit "Filename Test Data";
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
        ServiceNotRenamedTok: Label 'the electronic document service is handed Business Central''s own name', Locked = true;
        NoReportSelectionMsg: Label 'No report is selected for sales invoices, so no pattern can name one.';
        PassMsg: Label 'PASS';
        ExpectedButGotMsg: Label 'FAIL expected %1 but got %2', Comment = '%1 expected, %2 actual';
}
