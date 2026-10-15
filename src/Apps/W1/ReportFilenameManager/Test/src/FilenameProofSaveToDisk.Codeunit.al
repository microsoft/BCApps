// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50175 "Filename Proof Save To Disk"
{
    // Send to Disk: the Disk = PDF option of a Document Sending Profile, which renders the report
    // and hands the PDF straight to a client download. Two halves in Base Application,
    // SendToDiskForCust and SendToDiskForVend, named by two different hooks in this feature.
    //
    // This route was subscribed on 24 September 2026 and never worked: the customer hook stood down
    // whenever the name was not empty, and Base Application always fills it in first. Nothing ran
    // the route, so nothing noticed. This proof runs it for real.
    //
    // WHAT IS READ, AND WHY THERE
    //
    // Customer half: the name is read at the download helper's own event, OnBeforeDownload-
    // AttachmentFromStream, which Base Application raises with the name it is about to download
    // under - after every naming subscriber has run, whatever their order. That is the name a
    // person would receive, so the checks compare it with what Business Central produces on its
    // own, never with what this feature says it produced.
    //
    // Vendor half: this feature performs the download itself, so the name never reaches an event
    // Base Application raises. It is read from the manager's own OnAfterNamingDelivery, and the
    // control arm - no naming at all without a pattern, none for another channel - is what keeps
    // the check from agreeing with itself.

    SingleInstance = true;

    trigger OnRun()
    begin
        ProveCustomerDocument();
        ProveVendorDocument();
        ProveASelectionOfSeveralInvoices();
    end;

    /// <summary>
    /// Send to Disk for a posted sales invoice downloads under the pattern's name, keeps Business
    /// Central's own name without one, leaves a pattern for another channel alone, and does not
    /// override a subscriber that renamed the file deliberately.
    /// </summary>
    procedure ProveCustomerDocument()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        Baseline: Text;
        Expected: Text;
    begin
        FilenameProofLogMgt.StartNewRun();

        // An invoice of the proof's own to send.
        TestData.PostNewInvoice(SalesInvoiceHeader);
        ProofSupport.LogLine('40 Invoice', SalesInvoiceHeader."No.");

        ProofGuard.ClearPatterns();

        // The control arm: no pattern, so this is Business Central's own name.
        RunCustomerRoute(SalesInvoiceHeader, '40 Unnamed run returned');
        Baseline := DownloadName;
        ProofSupport.LogLine('40 Business Central downloads it as', Baseline);

        if Baseline <> '' then
            ProofSupport.LogLine('RESULT Send to Disk reached the download for a customer document', PassMsg)
        else
            ProofSupport.LogLine('RESULT Send to Disk reached the download for a customer document',
                StrSubstNo(ExpectedButGotMsg, NonEmptyTok, Baseline));

        CreatePattern(Database::"Sales Invoice Header", Enum::"Report Selection Usage"::"S.Invoice", Enum::"Report Filename Output Route"::Disk);
        RunCustomerRoute(SalesInvoiceHeader, '41 Named run returned');
        ProofSupport.LogLine('41 With a Save to Disk pattern it downloads as', DownloadName);
        ProofSupport.LogLine('41 Channel it was named on', Format(CapturedChannel));

        // The extension is Business Central's, taken from its own name: it passes 'pdf' as a
        // Code[3], and a Code value is upper case, so its name ends in .PDF. Measured - the first run
        // of this proof expected .pdf and failed on a name that was otherwise exactly right.
        Expected := SalesInvoiceHeader."No." + SuffixOf(Baseline);
        if DownloadName = Expected then
            ProofSupport.LogLine('RESULT Send to Disk downloads a customer document under the pattern''s name', PassMsg)
        else
            ProofSupport.LogLine('RESULT Send to Disk downloads a customer document under the pattern''s name',
                StrSubstNo(ExpectedButGotMsg, Expected, DownloadName));

        if CapturedChannel = CapturedChannel::Disk then
            ProofSupport.LogLine('RESULT it is named on the Save to Disk channel', PassMsg)
        else
            ProofSupport.LogLine('RESULT it is named on the Save to Disk channel',
                StrSubstNo(ExpectedButGotMsg, Format(Enum::"Report Filename Output Route"::Disk), Format(CapturedChannel)));

        // A subscriber that renamed the file on purpose keeps its name. Which of the two runs first
        // is unspecified: if the rename runs after this feature it wins by overwriting, and if it
        // runs before, this feature must see a name that is no longer Business Central's and stand
        // down. Either way the file must carry the rename.
        RenameAsAnotherExtension := true;
        RunCustomerRoute(SalesInvoiceHeader, '42 Run with a renaming subscriber returned');
        RenameAsAnotherExtension := false;
        // The renaming subscriber writes the extension as it arrives, a Code, so upper case.
        Expected := RenamedPrefixTok + SalesInvoiceHeader."No." + UpperCase(SuffixOf(Baseline));
        ProofSupport.LogLine('42 With a renaming subscriber it downloads as', DownloadName);
        if DownloadName = Expected then
            ProofSupport.LogLine('RESULT a subscriber that renamed the file keeps its name', PassMsg)
        else
            ProofSupport.LogLine('RESULT a subscriber that renamed the file keeps its name',
                StrSubstNo(ExpectedButGotMsg, Expected, DownloadName));

        // A pattern for another channel must leave the route exactly as Business Central names it.
        MovePatternToPrint();
        RunCustomerRoute(SalesInvoiceHeader, '43 Run with a Print pattern returned');
        ProofSupport.LogLine('43 With a Print pattern it downloads as', DownloadName);
        if DownloadName = Baseline then
            ProofSupport.LogLine('RESULT a pattern for another channel leaves the customer route alone', PassMsg)
        else
            ProofSupport.LogLine('RESULT a pattern for another channel leaves the customer route alone',
                StrSubstNo(ExpectedButGotMsg, Baseline, DownloadName));

        ProofGuard.ClearPatterns();
        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// Send to Disk for a posted purchase invoice is named from the pattern on the Save to Disk
    /// channel, is not named without one, and is not named by a pattern for another channel.
    /// </summary>
    procedure ProveVendorDocument()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        Baseline: Text;
        Expected: Text;
    begin
        FilenameProofLogMgt.StartNewRun();

        // A purchase invoice of the proof's own, for a vendor of its own.
        TestData.PostNewPurchaseInvoice(PurchInvHeader);
        ProofSupport.LogLine('50 Purchase invoice', PurchInvHeader."No.");

        ProofGuard.ClearPatterns();

        RunVendorRoute(PurchInvHeader, '50 Unnamed run returned');
        Baseline := DownloadName;
        ProofSupport.LogLine('50 Business Central downloads it as', Baseline);
        if CapturedName = '' then
            ProofSupport.LogLine('RESULT without a pattern the vendor route is not named', PassMsg)
        else
            ProofSupport.LogLine('RESULT without a pattern the vendor route is not named',
                StrSubstNo(ShouldNotHaveResolvedMsg, CapturedName));

        CreatePattern(Database::"Purch. Inv. Header", Enum::"Report Selection Usage"::"P.Invoice", Enum::"Report Filename Output Route"::Disk);
        RunVendorRoute(PurchInvHeader, '51 Named run returned');
        ProofSupport.LogLine('51 With a Save to Disk pattern it is named', CapturedName);
        ProofSupport.LogLine('51 Channel it was named on', Format(CapturedChannel));

        // Lower case: the vendor document is named inside GetAttachmentFileName's own event, in place of
        // Business Central's name, so there is no case of Business Central's to copy (ask 8).
        Expected := PurchInvHeader."No." + LowerCase(SuffixOf(Baseline));
        if CapturedName = Expected then
            ProofSupport.LogLine('RESULT Send to Disk names a vendor document from the pattern', PassMsg)
        else
            ProofSupport.LogLine('RESULT Send to Disk names a vendor document from the pattern',
                StrSubstNo(ExpectedButGotMsg, Expected, CapturedName));

        // The name the download is issued under. Base Application performs the vendor download itself
        // and raises OnBeforeDownloadAttachmentFromStream with the name just before it, which
        // CaptureDownloadName reads - so this is the name the user gets, whether or not this session
        // can complete the download.
        if DownloadName = Expected then
            ProofSupport.LogLine('RESULT the vendor download is issued under that name', PassMsg)
        else
            ProofSupport.LogLine('RESULT the vendor download is issued under that name',
                StrSubstNo(ExpectedButGotMsg, Expected, DownloadName));

        if CapturedChannel = CapturedChannel::Disk then
            ProofSupport.LogLine('RESULT the vendor document is named on the Save to Disk channel', PassMsg)
        else
            ProofSupport.LogLine('RESULT the vendor document is named on the Save to Disk channel',
                StrSubstNo(ExpectedButGotMsg, Format(Enum::"Report Filename Output Route"::Disk), Format(CapturedChannel)));

        MovePatternToPrint();
        RunVendorRoute(PurchInvHeader, '52 Run with a Print pattern returned');
        if CapturedName = '' then
            ProofSupport.LogLine('RESULT a pattern for another channel leaves the vendor route alone', PassMsg)
        else
            ProofSupport.LogLine('RESULT a pattern for another channel leaves the vendor route alone',
                StrSubstNo(ShouldNotHaveResolvedMsg, CapturedName));

        ProofGuard.ClearPatterns();
        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// Two invoices for one customer, sent together, are one PDF - and the file is named after both,
    /// not after the one the selection happens to sit on.
    /// </summary>
    procedure ProveASelectionOfSeveralInvoices()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        FirstNo: Code[20];
        SecondNo: Code[20];
        Baseline: Text;
        Expected: Text;
    begin
        FilenameProofLogMgt.StartNewRun();

        TwoInvoicesOfOneCustomer(FirstNo, SecondNo, SalesInvoiceHeader);
        ProofSupport.LogLine('45 Selection', FirstNo + ' and ' + SecondNo);

        ProofGuard.ClearPatterns();
        RunManyRoute(SalesInvoiceHeader, '45 Unnamed run returned');
        Baseline := DownloadName;
        ProofSupport.LogLine('45 Business Central downloads the selection as', Baseline);

        CreatePattern(Database::"Sales Invoice Header", Enum::"Report Selection Usage"::"S.Invoice", Enum::"Report Filename Output Route"::Disk);
        RunManyRoute(SalesInvoiceHeader, '46 Named run returned');
        ProofSupport.LogLine('46 With a Save to Disk pattern it downloads as', DownloadName);

        // Both numbers, joined by the pattern's separator, in the field's own order.
        Expected := FirstNo + '-' + SecondNo + SuffixOf(Baseline);
        if DownloadName = Expected then
            ProofSupport.LogLine('RESULT a selection of several invoices is named after all of them', PassMsg)
        else
            ProofSupport.LogLine('RESULT a selection of several invoices is named after all of them',
                StrSubstNo(ExpectedButGotMsg, Expected, DownloadName));

        ProofGuard.ClearPatterns();
        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// Two invoices posted for one new customer, in the order of their numbers, and a selection of
    /// exactly those two.
    /// </summary>
    local procedure TwoInvoicesOfOneCustomer(var FirstNo: Code[20]; var SecondNo: Code[20]; var Selection: Record "Sales Invoice Header")
    var
        InvoiceNos: List of [Code[20]];
    begin
        TestData.PostInvoicesOfOneCustomer(2, InvoiceNos);
        FirstNo := InvoiceNos.Get(1);
        SecondNo := InvoiceNos.Get(2);
        Selection.Reset();
        Selection.SetFilter("No.", '%1|%2', FirstNo, SecondNo);
        Selection.FindFirst();
    end;

    local procedure RunManyRoute(var SalesInvoiceHeader: Record "Sales Invoice Header"; FailureLabel: Text)
    begin
        ClearCaptures();
        Commit();
        if not Codeunit.Run(Codeunit::"Filename Proof Send Disk Many", SalesInvoiceHeader) then
            ProofSupport.LogLine(FailureLabel, GetLastErrorText());
    end;

    local procedure RunCustomerRoute(var SalesInvoiceHeader: Record "Sales Invoice Header"; FailureLabel: Text)
    begin
        ClearCaptures();
        // The route renders a report, and Business Central refuses to render while a write
        // transaction is open - the pattern setup above has just written.
        Commit();
        // The route ends in a client download, which a session without a client may refuse. The
        // name is decided before that, so a failure here is logged and is not the verdict.
        if not Codeunit.Run(Codeunit::"Filename Proof Send Disk", SalesInvoiceHeader) then
            ProofSupport.LogLine(FailureLabel, GetLastErrorText());
    end;

    local procedure RunVendorRoute(var PurchInvHeader: Record "Purch. Inv. Header"; FailureLabel: Text)
    begin
        ClearCaptures();
        Commit();
        if not Codeunit.Run(Codeunit::"Filename Proof Send Disk Vend", PurchInvHeader) then begin
            LastRunError := GetLastErrorText();
            ProofSupport.LogLine(FailureLabel, LastRunError);
        end;
    end;

    local procedure ClearCaptures()
    begin
        Clear(LastRunError);
        Clear(CapturedName);
        Clear(CapturedChannel);
        Clear(DownloadName);
    end;

    /// <summary>
    /// The name Base Application is about to download the file under. Raised after every naming
    /// subscriber on the customer half has run, so its order relative to them does not matter.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnBeforeDownloadAttachmentFromStream', '', false, false)]
    local procedure CaptureDownloadName(var TempReportSelections: Record "Report Selections" temporary; RecordVariant: Variant; var AttachmentInStream: InStream; ClientAttachmentFileName: Text; var IsHandled: Boolean)
    begin
        DownloadName := CopyStr(ClientAttachmentFileName, 1, MaxStrLen(DownloadName));
    end;

    /// <summary>
    /// Stands in for a partner extension that renames Send to Disk files on purpose.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnSendToDiskForCustOnBeforeDownloadAttachment', '', false, false)]
    local procedure RenameLikeAnotherExtension(var TempReportSelections: Record "Report Selections" temporary; RecordVariant: Variant; DocumentNo: Code[20]; DocumentName: Text; Extension: Code[3]; var ClientAttachmentFileName: Text)
    begin
        if RenameAsAnotherExtension then
            ClientAttachmentFileName := RenamedPrefixTok + DocumentNo + '.' + Extension;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Report Filename Subscribers", 'OnAfterNamingDelivery', '', false, false)]
    local procedure CaptureDeliveryName(ReportId: Integer; Channel: Enum "Report Filename Output Route"; FileName: Text)
    begin
        if Channel <> Channel::Disk then
            exit;
        CapturedName := CopyStr(FileName, 1, MaxStrLen(CapturedName));
        CapturedChannel := Channel;
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

    /// <summary>
    /// The extension on a name, dot included, as Business Central wrote it.
    /// </summary>
    local procedure SuffixOf(FileName: Text): Text
    var
        DotPosition: Integer;
    begin
        DotPosition := FileName.LastIndexOf('.');
        if DotPosition <= 1 then
            exit('');
        exit(CopyStr(FileName, DotPosition));
    end;

    local procedure MovePatternToPrint()
    var
        Pattern: Record "Report Filename Pattern";
    begin
        if not Pattern.FindFirst() then
            exit;
        ProofSupport.LimitToRoute(Pattern, Enum::"Report Filename Output Route"::Print);
        Pattern.Modify(true);
    end;

    var
        ProofGuard: Codeunit "Filename Proof Guard";
        ProofSupport: Codeunit "Filename Proof Support";
        TestData: Codeunit "Filename Test Data";
        CapturedChannel: Enum "Report Filename Output Route";
        CapturedName: Text[250];
        DownloadName: Text[250];
        RenameAsAnotherExtension: Boolean;
        LastRunError: Text;
        PatternTok: Label '[No.]', Locked = true;
        RenamedPrefixTok: Label 'Renamed-', Locked = true;
        NonEmptyTok: Label 'a name', Locked = true;
        NoReportSelectionMsg: Label 'No report is selected for usage %1, so no pattern can name it.', Comment = '%1 the report selection usage';
        PassMsg: Label 'PASS';
        ExpectedButGotMsg: Label 'FAIL expected %1 but got %2', Comment = '%1 expected, %2 actual';
        ShouldNotHaveResolvedMsg: Label 'FAIL should not have been named, but got %1', Comment = '%1 the name produced';
}
