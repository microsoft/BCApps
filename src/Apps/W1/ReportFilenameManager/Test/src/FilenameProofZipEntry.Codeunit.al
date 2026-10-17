// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50176 "Filename Proof Zip Entry"
{
    // The PDF inside a "PDF & Electronic Document" zip - the option a Document Sending Profile offers
    // for both E-Mail Attachment and Disk. Base Application builds that zip in SendToZipForCust and
    // SendToZipForVend, and names the PDF entry through Electronic Document Format.GetAttachmentFileName.
    //
    // The zip functions are called directly and the names are read back out of the archive itself,
    // with Data Compression.GetEntryList. That is the name a person finds when they open the zip, and
    // it involves no client download, so nothing here has to be inferred from an error message.
    //
    // Every check compares against the entry Business Central produces with no pattern, never against
    // what this feature says it produced.

    SingleInstance = true;

    trigger OnRun()
    begin
        ProveCustomerZip();
        ProveVendorZip();
        ProveAStaleEntryCannotNameAnotherDocument();
        ProveASelectionInOneZip();
    end;

    /// <summary>
    /// The PDF in a customer document's zip is named from a pattern on the With Electronic Document
    /// channel or on Any, and not by a pattern on Save to Disk.
    /// </summary>
    procedure ProveCustomerZip()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        Baseline: Text;
    begin
        FilenameProofLogMgt.StartNewRun();

        // An invoice of the proof's own to zip, filtered to itself.
        TestData.PostNewInvoice(SalesInvoiceHeader);
        ProofSupport.LogLine('60 Invoice', SalesInvoiceHeader."No.");

        ProofGuard.ClearPatterns();
        Baseline := CustomerEntry(SalesInvoiceHeader);
        ProofSupport.LogLine('60 With no pattern the zip holds', Baseline);
        if Baseline <> '' then
            ProofSupport.LogLine('RESULT the customer zip holds a PDF entry', PassMsg)
        else
            ProofSupport.LogLine('RESULT the customer zip holds a PDF entry', StrSubstNo(ExpectedButGotMsg, NonEmptyTok, Baseline));

        ProveEachChannel(Database::"Sales Invoice Header", Enum::"Report Selection Usage"::"S.Invoice", SalesInvoiceHeader."No.", Baseline, true, SalesInvoiceHeader, '6');

        ProofGuard.ClearPatterns();
        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// The vendor twin of ProveCustomerZip.
    /// </summary>
    procedure ProveVendorZip()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        Baseline: Text;
    begin
        FilenameProofLogMgt.StartNewRun();

        // A purchase invoice of the proof's own, for a vendor of its own, filtered to itself.
        TestData.PostNewPurchaseInvoice(PurchInvHeader);
        ProofSupport.LogLine('70 Purchase invoice', PurchInvHeader."No.");

        ProofGuard.ClearPatterns();
        Baseline := VendorEntry(PurchInvHeader);
        ProofSupport.LogLine('70 With no pattern the zip holds', Baseline);
        if Baseline <> '' then
            ProofSupport.LogLine('RESULT the vendor zip holds a PDF entry', PassMsg)
        else
            ProofSupport.LogLine('RESULT the vendor zip holds a PDF entry', StrSubstNo(ExpectedButGotMsg, NonEmptyTok, Baseline));

        ProveEachChannel(Database::"Purch. Inv. Header", Enum::"Report Selection Usage"::"P.Invoice", PurchInvHeader."No.", Baseline, false, PurchInvHeader, '7');

        ProofGuard.ClearPatterns();
        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// A recorded zip entry that was never used cannot name a different document.
    ///
    /// The entry is recorded just before the PDF renders and used when the zip names it. If the render
    /// fails in between, the entry is left behind in the session, and the next call to Business
    /// Central's naming function with the same document type - for any document - reaches the naming
    /// hook. It must decline, so that document keeps Business Central's own name, rather than be named
    /// after the one that failed.
    ///
    /// A failed render is not something this proof can cause on demand, so the leftover entry is
    /// recorded directly, exactly as the "before each file" subscriber records it.
    /// </summary>
    procedure ProveAStaleEntryCannotNameAnotherDocument()
    var
        FirstInvoice: Record "Sales Invoice Header";
        SecondInvoice: Record "Sales Invoice Header";
        ReportSelections: Record "Report Selections";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ReportFilenameContext: Codeunit "Report Filename Context";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        FirstRecRef: RecordRef;
        DocumentType: Text;
        Baseline: Text;
        WithLeftover: Text;
    begin
        FilenameProofLogMgt.StartNewRun();

        // Two invoices of the proof's own, each filtered to itself.
        TestData.PostNewInvoice(FirstInvoice);
        TestData.PostNewInvoice(SecondInvoice);
        ProofSupport.LogLine('80 Entry left behind for', FirstInvoice."No.");
        ProofSupport.LogLine('80 Document then named', SecondInvoice."No.");

        ReportSelections.SetRange(Usage, ReportSelections.Usage::"S.Invoice");
        ReportSelections.SetFilter("Report ID", '<>%1', 0);
        if not ReportSelections.FindFirst() then begin
            ProofSupport.LogLine('Setup', StrSubstNo(NoReportSelectionMsg, Format(ReportSelections.Usage::"S.Invoice")));
            FilenameProofLogMgt.Flush();
            exit;
        end;
        DocumentType := Format(ReportSelections.Usage);

        ProofGuard.ClearPatterns();
        CreatePattern(Database::"Sales Invoice Header", Enum::"Report Selection Usage"::"S.Invoice", Enum::"Report Filename Output Route"::PdfAndElectronicDocument);

        // What Business Central calls the second invoice with nothing left behind. The pattern is live,
        // but no entry is recorded, so the naming hook stands aside.
        Baseline := ElectronicDocumentFormat.GetAttachmentFileName(SecondInvoice, SecondInvoice."No.", DocumentType, PdfExtensionTok);
        ProofSupport.LogLine('80 With nothing left behind', Baseline);

        FirstRecRef.GetTable(FirstInvoice);
        ReportFilenameContext.SetPendingFile(FirstRecRef, ReportSelections."Report ID", DocumentType, Enum::"Report Filename Output Route"::PdfAndElectronicDocument);
        WithLeftover := ElectronicDocumentFormat.GetAttachmentFileName(SecondInvoice, SecondInvoice."No.", DocumentType, PdfExtensionTok);
        ProofSupport.LogLine('81 With the first invoice''s entry left behind', WithLeftover);

        LogVerdict(StaleEntryTok, Baseline, WithLeftover);

        ProofGuard.ClearPatterns();
        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// Two invoices for one customer zipped together are one PDF entry, named after both of them.
    /// </summary>
    procedure ProveASelectionInOneZip()
    var
        Selection: Record "Sales Invoice Header";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        InvoiceNos: List of [Code[20]];
        FirstNo: Code[20];
        SecondNo: Code[20];
        Baseline: Text;
        Entry: Text;
    begin
        FilenameProofLogMgt.StartNewRun();

        // Two invoices of the proof's own for one new customer, in the order of their numbers.
        TestData.PostInvoicesOfOneCustomer(2, InvoiceNos);
        FirstNo := InvoiceNos.Get(1);
        SecondNo := InvoiceNos.Get(2);

        Selection.SetFilter("No.", '%1|%2', FirstNo, SecondNo);
        Selection.FindFirst();
        ProofSupport.LogLine('90 Selection', FirstNo + ' and ' + SecondNo);

        ProofGuard.ClearPatterns();
        Baseline := CustomerEntry(Selection);
        ProofSupport.LogLine('90 With no pattern the zip holds', Baseline);

        CreatePattern(Database::"Sales Invoice Header", Enum::"Report Selection Usage"::"S.Invoice", Enum::"Report Filename Output Route"::PdfAndElectronicDocument);
        NoteBusinessCentralsCase(Baseline);
        Entry := CustomerEntry(Selection);
        ProofSupport.LogLine('91 With a PDF & Electronic Document pattern', Entry);
        LogVerdict(SelectionInOneZipTok, FirstNo + '-' + SecondNo + SuffixOf(Baseline), Entry);

        ProofGuard.ClearPatterns();
        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// The three patterns that settle the channel question, one after another on the same document.
    /// </summary>
    local procedure ProveEachChannel(SourceTableNo: Integer; Usage: Enum "Report Selection Usage"; DocumentNo: Code[20]; Baseline: Text; IsCustomer: Boolean; DocumentVariant: Variant; Step: Text)
    var
        Expected: Text;
        Entry: Text;
        Side: Text;
    begin
        if IsCustomer then
            Side := CustomerTok
        else
            Side := VendorTok;

        // The extension in the case Business Central wrote it in.
        NoteBusinessCentralsCase(Baseline);
        Expected := DocumentNo + SuffixOf(Baseline);

        ProofGuard.ClearPatterns();
        CreatePattern(SourceTableNo, Usage, Enum::"Report Filename Output Route"::PdfAndElectronicDocument);
        Entry := EntryFor(IsCustomer, DocumentVariant);
        ProofSupport.LogLine(Step + '1 With a PDF & Electronic Document pattern', Entry);
        ProofSupport.LogLine(Step + '1 Channel it was named on', Format(CapturedChannel));
        LogVerdict(StrSubstNo(NamedFromPatternTok, Side), Expected, Entry);
        LogVerdict(StrSubstNo(NamedOnChannelTok, Side),
            Format(Enum::"Report Filename Output Route"::PdfAndElectronicDocument), Format(CapturedChannel));

        ProofGuard.ClearPatterns();
        CreatePattern(SourceTableNo, Usage, Enum::"Report Filename Output Route"::Any);
        Entry := EntryFor(IsCustomer, DocumentVariant);
        ProofSupport.LogLine(Step + '2 With an Any pattern', Entry);
        LogVerdict(StrSubstNo(NamedByAnyTok, Side), Expected, Entry);

        // Save to Disk is the pattern an administrator is most likely to expect to reach the zip, and
        // the decision was that it does not: the zip has its own channel.
        ProofGuard.ClearPatterns();
        CreatePattern(SourceTableNo, Usage, Enum::"Report Filename Output Route"::Disk);
        Entry := EntryFor(IsCustomer, DocumentVariant);
        ProofSupport.LogLine(Step + '3 With a Save to Disk pattern', Entry);
        LogVerdict(StrSubstNo(NotNamedBySaveToDiskTok, Side), Baseline, Entry);
    end;

    /// <summary>
    /// What the real "PDF &amp; Electronic Document" route has done by the time it names the PDF entry:
    /// SendElectronically has named the electronic document earlier in the same zip, and the feature has
    /// noted the case Business Central wrote its extension in. These proofs call the zip function on its
    /// own, so the case Business Central wrote this entry in, with no pattern, is noted the same way -
    /// otherwise the outcome would depend on what ran earlier in the session. The real route, electronic
    /// document included, is proven by Filename Proof Elec. Doc.
    /// </summary>
    /// <param name="Baseline">The entry Business Central wrote with no pattern.</param>
    local procedure NoteBusinessCentralsCase(Baseline: Text)
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        ReportFilenameContext.NoteExtensionCasing(SuffixOf(Baseline) = LowerCase(SuffixOf(Baseline)));
    end;

    local procedure EntryFor(IsCustomer: Boolean; DocumentVariant: Variant): Text
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        if IsCustomer then begin
            SalesInvoiceHeader := DocumentVariant;
            SalesInvoiceHeader.SetRecFilter();
            exit(CustomerEntry(SalesInvoiceHeader));
        end;
        PurchInvHeader := DocumentVariant;
        PurchInvHeader.SetRecFilter();
        exit(VendorEntry(PurchInvHeader));
    end;

    /// <summary>
    /// Builds the zip exactly as the Document Sending Profile does for a customer document, and
    /// returns the name of the PDF entry in it.
    /// </summary>
    local procedure CustomerEntry(var SalesInvoiceHeader: Record "Sales Invoice Header"): Text
    var
        ReportSelections: Record "Report Selections";
        DataCompression: Codeunit "Data Compression";
        RecordVariant: Variant;
    begin
        Clear(CapturedChannel);
        // The route renders a report, and Business Central refuses to render with a write transaction open.
        Commit();
        RecordVariant := SalesInvoiceHeader;
        DataCompression.CreateZipArchive();
        ReportSelections.SendToZipForCust(
            Enum::"Report Selection Usage"::"S.Invoice", RecordVariant, SalesInvoiceHeader."No.", SalesInvoiceHeader."Bill-to Customer No.", DataCompression);
        exit(OnlyEntry(DataCompression));
    end;

    local procedure VendorEntry(var PurchInvHeader: Record "Purch. Inv. Header"): Text
    var
        ReportSelections: Record "Report Selections";
        DataCompression: Codeunit "Data Compression";
        RecordVariant: Variant;
    begin
        Clear(CapturedChannel);
        Commit();
        RecordVariant := PurchInvHeader;
        DataCompression.CreateZipArchive();
        ReportSelections.SendToZipForVend(
            Enum::"Report Selection Usage"::"P.Invoice", RecordVariant, PurchInvHeader."No.", PurchInvHeader."Pay-to Vendor No.", DataCompression);
        exit(OnlyEntry(DataCompression));
    end;

    /// <summary>
    /// The one entry the zip holds. More than one would mean more than one report is selected for the
    /// usage, and the proof would be reading an arbitrary one, so that is logged rather than hidden.
    /// </summary>
    local procedure OnlyEntry(var DataCompression: Codeunit "Data Compression"): Text
    var
        FinishedZip: Codeunit "Data Compression";
        ZipBlob: Codeunit "Temp Blob";
        Entries: List of [Text];
        Entry: Text;
    begin
        // Saved and reopened for reading, because an archive still being written refuses to list
        // its entries - measured: "Cannot access entries in Create mode". Reading the saved archive
        // is also the stronger check: it is the file a person would open.
        DataCompression.SaveZipArchive(ZipBlob);
        DataCompression.CloseZipArchive();
        FinishedZip.OpenZipArchive(ZipBlob, false);
        FinishedZip.GetEntryList(Entries);
        FinishedZip.CloseZipArchive();
        if Entries.Count() <> 1 then
            ProofSupport.LogLine('Entries in the zip', Format(Entries.Count()));
        if Entries.Count() = 0 then
            exit('');
        Entries.Get(1, Entry);
        exit(Entry);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Report Filename Subscribers", 'OnAfterNamingDelivery', '', false, false)]
    local procedure CaptureDeliveryChannel(ReportId: Integer; Channel: Enum "Report Filename Output Route"; FileName: Text)
    begin
        CapturedChannel := Channel;
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

    local procedure CreatePattern(SourceTableNo: Integer; Usage: Enum "Report Selection Usage"; Channel: Enum "Report Filename Output Route")
    var
        Pattern: Record "Report Filename Pattern";
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange(Usage, Usage);
        ReportSelections.SetFilter("Report ID", '<>%1', 0);
        if not ReportSelections.FindFirst() then begin
            ProofSupport.LogLine('Setup', StrSubstNo(NoReportSelectionMsg, Format(Usage)));
            exit;
        end;

        Pattern.Init();
        Pattern.Validate("Table No.", SourceTableNo);
        Pattern.Validate("Report ID", ReportSelections."Report ID");
        ProofSupport.LimitToRoute(Pattern, Channel);
        Pattern.Validate("File Name Pattern", PatternTok);
        Pattern.Enabled := true;
        Pattern.Insert(true);
    end;

    var
        ProofGuard: Codeunit "Filename Proof Guard";
        ProofSupport: Codeunit "Filename Proof Support";
        TestData: Codeunit "Filename Test Data";
        CapturedChannel: Enum "Report Filename Output Route";
        PatternTok: Label '[No.]', Locked = true;
        NonEmptyTok: Label 'an entry', Locked = true;
        CustomerTok: Label 'customer', Locked = true;
        VendorTok: Label 'vendor', Locked = true;
        NamedFromPatternTok: Label 'the PDF in a %1 zip is named from the pattern', Comment = '%1 customer or vendor', Locked = true;
        NamedOnChannelTok: Label 'the PDF in a %1 zip is named on the PDF & Electronic Document output route', Comment = '%1 customer or vendor', Locked = true;
        NamedByAnyTok: Label 'a pattern on Any names the PDF in a %1 zip', Comment = '%1 customer or vendor', Locked = true;
        NotNamedBySaveToDiskTok: Label 'a Save to Disk pattern leaves the PDF in a %1 zip alone', Comment = '%1 customer or vendor', Locked = true;
        StaleEntryTok: Label 'a zip entry left behind cannot name a different document', Locked = true;
        SelectionInOneZipTok: Label 'two invoices zipped together are named after both of them', Locked = true;
        PdfExtensionTok: Label 'pdf', Locked = true;
        NoReportSelectionMsg: Label 'No report is selected for usage %1, so no pattern can name it.', Comment = '%1 the report selection usage';
        PassMsg: Label 'PASS';
        ExpectedButGotMsg: Label 'FAIL expected %1 but got %2', Comment = '%1 expected, %2 actual';
}
