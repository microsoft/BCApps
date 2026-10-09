// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50170 "Filename Proof Attachment"
{
    // The two routes on a document's Print/Send menu that this feature reached last.
    //
    //   Attach as PDF   Report Selections.SaveAsDocumentAttachment, which renders the report and
    //                   writes a Document Attachment row. Business Central names it itself, as
    //                   "1304 Sales - Quote 1002" - report id, report caption, document number.
    //   Send to Disk    Report Selections.SendToDiskForCust, which writes a file to the client.
    //
    // Both were specified from the start and neither was built until 24 September 2026. The other
    // three actions on that same ribbon - Send by Email, Print and Download as PDF - have named
    // from a pattern all along, which is what made the gap easy to miss: the menu looked covered.
    //
    // Attach as PDF is the one that matters most. It carries no Scope, so it works online as well
    // as on-premises, and it is on every sales and purchase document. Send to Disk runs online too,
    // though only Base Application may call it there, and its hook exists only from Base
    // Application 28.4.
    //
    // Names are read from the manager's own integration event rather than from a second subscriber
    // on the platform event. Subscriber order is unspecified, so a second subscriber may run first
    // and read nothing - it would pass while proving nothing, which is worse than failing.

    SingleInstance = true;

    trigger OnRun()
    begin
        ProveAttachmentRoute();
    end;

    /// <summary>
    /// Attach as PDF names the attachment from the pattern, and the name it produced is the name
    /// that lands on the document's Attached Documents.
    /// </summary>
    procedure ProveAttachmentRoute()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        BaselineExtension: Text;
        BaselineName: Text;
        BaselineType: Text;
        Expected: Text;
        Stored: Text;
        StoredExtension: Text;
        StoredType: Text;
    begin
        FilenameProofLogMgt.StartNewRun();

        if not FirstInvoice(SalesInvoiceHeader) then begin
            ProofSupport.LogLine('Setup', NoInvoiceMsg);
            FilenameProofLogMgt.Flush();
            exit;
        end;
        ProofSupport.LogLine('10 Invoice', SalesInvoiceHeader."No.");

        ProofGuard.ClearPatterns();
        RemoveAttachments(SalesInvoiceHeader);

        // The control arm, and the part this proof was missing when it first passed. Attach as
        // PDF is run once with NO pattern, so Business Central names it its own way, and the
        // extension and file type it produces are recorded. Everything below is compared against
        // THOSE rather than against what this feature produced - a proof that compares the stored
        // name with the name we handed over compares one value with itself and cannot fail.
        //
        // It could not fail, and it did not: the first version of this passed while the
        // attachment landed with a blank extension and a File Type of Other.
        Commit();
        if not Codeunit.Run(Codeunit::"Filename Proof Attach PDF", SalesInvoiceHeader) then
            ProofSupport.LogLine('10 Unnamed run returned', GetLastErrorText());
        ReadStoredAttachment(SalesInvoiceHeader, BaselineName, BaselineExtension, BaselineType);
        ProofSupport.LogLine('10 Business Central names it', BaselineName);
        ProofSupport.LogLine('10 with extension', BaselineExtension);
        ProofSupport.LogLine('10 and file type', BaselineType);

        RemoveAttachments(SalesInvoiceHeader);
        CreatePattern(Enum::"Report Filename Output Route"::AttachAsPdf);

        Clear(CapturedName);
        Clear(CapturedChannel);

        // Committed before the route is called, not for tidiness: this route RENDERS a report,
        // and Business Central refuses to render one while a write transaction is open. The
        // setup above deletes attachments and inserts a pattern, so without this the render
        // fails and the failure arrives as "an error occurred and the transaction is stopped",
        // which names neither the cause nor the place. Measured: the same call succeeds with no
        // prior writes and fails with them.
        Commit();

        // Isolated: the render writes, and can fail on company setup this proof does not control.
        // The name is decided before anything is stored, so a failure here is not the verdict.
        if not Codeunit.Run(Codeunit::"Filename Proof Attach PDF", SalesInvoiceHeader) then
            ProofSupport.LogLine('11 Attach as PDF returned', GetLastErrorText());

        ProofSupport.LogLine('12 Name the route produced', CapturedName);
        ProofSupport.LogLine('13 Channel it was named on', Format(CapturedChannel));

        // What the manager produced. The extension is deliberately not asserted here - whether
        // this route's name carries one is Base Application's convention, and the manager copies
        // whatever it was handed rather than deciding. The stored row below is the real check.
        if CapturedName.StartsWith(SalesInvoiceHeader."No.") then
            ProofSupport.LogLine('RESULT Attach as PDF names its output from the pattern', PassMsg)
        else
            ProofSupport.LogLine('RESULT Attach as PDF names its output from the pattern',
                StrSubstNo(ExpectedButGotMsg, SalesInvoiceHeader."No.", CapturedName));

        if CapturedChannel = CapturedChannel::AttachAsPdf then
            ProofSupport.LogLine('RESULT it is named on the Attachment channel', PassMsg)
        else
            ProofSupport.LogLine('RESULT it is named on the Attachment channel',
                StrSubstNo(ExpectedButGotMsg, Format(Enum::"Report Filename Output Route"::AttachAsPdf), Format(CapturedChannel)));

        // The row that actually landed. Reading the event alone would prove the manager ran, not
        // that Business Central kept what it was given.
        ReadStoredAttachment(SalesInvoiceHeader, Stored, StoredExtension, StoredType);
        ProofSupport.LogLine('14 Name stored on the document', Stored);
        ProofSupport.LogLine('14 with extension', StoredExtension);
        ProofSupport.LogLine('14 and file type', StoredType);

        // Reassembled, because Base Application SPLITS the name it is handed: "103001.pdf" is
        // stored as File Name "103001" with File Extension "pdf". Measured 24 September 2026 -
        // and it is why the extension has to be handed back rather than left off, since that
        // split is where the extension and the file type come from.
        if StoredExtension <> '' then
            Expected := Stored + ExtensionSeparatorTok + StoredExtension
        else
            Expected := Stored;

        if (Stored <> '') and (Expected = CapturedName) then
            ProofSupport.LogLine('RESULT the stored attachment carries that name', PassMsg)
        else
            ProofSupport.LogLine('RESULT the stored attachment carries that name',
                StrSubstNo(ExpectedButGotMsg, CapturedName, Expected));

        // Naming a file must not cost it its extension or its type. Base Application works both
        // out from the name this feature hands back, downstream of the hook, so a name returned
        // without its extension produces an attachment nobody can open.
        if StoredExtension = BaselineExtension then
            ProofSupport.LogLine('RESULT naming it keeps the extension', PassMsg)
        else
            ProofSupport.LogLine('RESULT naming it keeps the extension',
                StrSubstNo(ExpectedButGotMsg, BaselineExtension, StoredExtension));

        if StoredType = BaselineType then
            ProofSupport.LogLine('RESULT naming it keeps the file type', PassMsg)
        else
            ProofSupport.LogLine('RESULT naming it keeps the file type',
                StrSubstNo(ExpectedButGotMsg, BaselineType, StoredType));

        ProveASecondAttachmentGetsItsOwnName(SalesInvoiceHeader, Stored);

        ProveTheChannelIsMatched(SalesInvoiceHeader);

        RemoveAttachments(SalesInvoiceHeader);
        ProofGuard.ClearPatterns();
        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// A pattern for the Save channel must not name the attachment.
    ///
    /// Attach as PDF renders the report, and that render reaches OnGetFilename with intent
    /// "Save" - so this one action is seen by two of this feature's hooks, on two channels. The
    /// question that raises is whether they interfere: does a pattern an administrator wrote for
    /// Save end up naming a document's attachment, which is not what they asked for?
    ///
    /// Answered by running the route twice, once with no pattern at all and once with a Save
    /// pattern, and insisting the stored attachment is the same both times. Comparing against
    /// what Business Central produces rather than against anything this feature produced, so the
    /// check cannot pass by agreeing with itself.
    /// </summary>
    procedure ProveSaveDoesNotNameTheAttachment()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        Default: Text;
        DefaultExtension: Text;
        DefaultType: Text;
        WithSave: Text;
        WithSaveExtension: Text;
        WithSaveType: Text;
    begin
        FilenameProofLogMgt.StartNewRun();

        if not FirstInvoice(SalesInvoiceHeader) then begin
            ProofSupport.LogLine('Setup', NoInvoiceMsg);
            FilenameProofLogMgt.Flush();
            exit;
        end;

        ProofGuard.ClearPatterns();
        RemoveAttachments(SalesInvoiceHeader);
        Commit();
        if not Codeunit.Run(Codeunit::"Filename Proof Attach PDF", SalesInvoiceHeader) then
            ProofSupport.LogLine('30 Unnamed run returned', GetLastErrorText());
        ReadStoredAttachment(SalesInvoiceHeader, Default, DefaultExtension, DefaultType);
        ProofSupport.LogLine('30 With no pattern at all', Default);

        RemoveAttachments(SalesInvoiceHeader);
        CreatePattern(Enum::"Report Filename Output Route"::Save);
        Commit();
        if not Codeunit.Run(Codeunit::"Filename Proof Attach PDF", SalesInvoiceHeader) then
            ProofSupport.LogLine('31 Run with a Save pattern returned', GetLastErrorText());
        ReadStoredAttachment(SalesInvoiceHeader, WithSave, WithSaveExtension, WithSaveType);
        ProofSupport.LogLine('31 With a Save pattern', WithSave);

        if WithSave = Default then
            ProofSupport.LogLine('RESULT a Save pattern does not name the attachment', PassMsg)
        else
            ProofSupport.LogLine('RESULT a Save pattern does not name the attachment',
                StrSubstNo(ExpectedButGotMsg, Default, WithSave));

        RemoveAttachments(SalesInvoiceHeader);
        ProofGuard.ClearPatterns();
        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// Attaching the same document a second time gives the second attachment a name of its own,
    /// as Business Central does without a pattern. Base Application numbers a name already taken
    /// in Document Attachment.InsertAttachment, which runs after the hook this feature names the
    /// file in - so a pattern's name is numbered exactly as Business Central's own. Checked because
    /// a name replaced at the hook could, in principle, bypass that; measured on 28 September 2026
    /// that it does not, with this feature's own numbering switched off.
    /// </summary>
    /// <param name="SalesInvoiceHeader">The document, already carrying one named attachment.</param>
    /// <param name="FirstName">The name the first attachment was stored under.</param>
    local procedure ProveASecondAttachmentGetsItsOwnName(var SalesInvoiceHeader: Record "Sales Invoice Header"; FirstName: Text)
    var
        DocumentAttachment: Record "Document Attachment";
        SecondName: Text;
        SecondExtension: Text;
        SecondType: Text;
    begin
        // The render refuses to start inside a write transaction; see ProveAttachmentRoute.
        Commit();
        if not Codeunit.Run(Codeunit::"Filename Proof Attach PDF", SalesInvoiceHeader) then
            ProofSupport.LogLine('15 Second Attach as PDF returned', GetLastErrorText());
        ReadStoredAttachment(SalesInvoiceHeader, SecondName, SecondExtension, SecondType);
        ProofSupport.LogLine('15 Second attachment stored as', SecondName);

        DocumentAttachment.SetRange("Table ID", Database::"Sales Invoice Header");
        DocumentAttachment.SetRange("No.", SalesInvoiceHeader."No.");
        if (DocumentAttachment.Count() = 2) and (SecondName <> FirstName) and SecondName.StartsWith(FirstName) then
            ProofSupport.LogLine('RESULT a second attachment gets a name of its own', PassMsg)
        else
            ProofSupport.LogLine('RESULT a second attachment gets a name of its own',
                StrSubstNo(ExpectedButGotMsg, StrSubstNo(DistinctNameMsg, FirstName), SecondName));
    end;

    /// <summary>
    /// A pattern for another channel must not name this route. Without this, a pattern that
    /// matched every channel would satisfy the checks above and prove nothing about the channel.
    /// </summary>
    local procedure ProveTheChannelIsMatched(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        Pattern: Record "Report Filename Pattern";
    begin
        if not Pattern.FindFirst() then
            exit;

        ProofSupport.LimitToRoute(Pattern, Enum::"Report Filename Output Route"::Print);
        Pattern.Modify(true);

        RemoveAttachments(SalesInvoiceHeader);
        Clear(CapturedName);
        // Same reason as above: the pattern was just modified and the attachments deleted.
        Commit();
        if not Codeunit.Run(Codeunit::"Filename Proof Attach PDF", SalesInvoiceHeader) then;

        if CapturedName = '' then
            ProofSupport.LogLine('RESULT a pattern for another channel does not name this route', PassMsg)
        else
            ProofSupport.LogLine('RESULT a pattern for another channel does not name this route',
                StrSubstNo(ShouldNotHaveResolvedMsg, CapturedName));
    end;

    /// <summary>
    /// The name the manager produced, captured as it was produced. Both routes hand their name
    /// straight on, so there is nothing to read afterwards on either.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Report Filename Subscribers", 'OnAfterNamingDelivery', '', false, false)]
    local procedure CaptureDeliveryName(ReportId: Integer; Channel: Enum "Report Filename Output Route"; FileName: Text)
    begin
        CapturedName := CopyStr(FileName, 1, MaxStrLen(CapturedName));
        CapturedChannel := Channel;
    end;

    /// <summary>
    /// What landed on the document's own Attached Documents: the three columns a person sees.
    /// </summary>
    /// <param name="SalesInvoiceHeader">The document.</param>
    /// <param name="Name">Receives the attachment's name.</param>
    /// <param name="Extension">Receives its file extension.</param>
    /// <param name="FileType">Receives its file type, as the page shows it.</param>
    local procedure ReadStoredAttachment(var SalesInvoiceHeader: Record "Sales Invoice Header"; var Name: Text; var Extension: Text; var FileType: Text)
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        Clear(Name);
        Clear(Extension);
        Clear(FileType);

        DocumentAttachment.SetRange("Table ID", Database::"Sales Invoice Header");
        DocumentAttachment.SetRange("No.", SalesInvoiceHeader."No.");
        if not DocumentAttachment.FindLast() then
            exit;

        Name := DocumentAttachment."File Name";
        Extension := DocumentAttachment."File Extension";
        FileType := Format(DocumentAttachment."File Type");
    end;

    /// <summary>
    /// Clears the attachments this proof creates, so a second run is not reading the first one's.
    /// </summary>
    local procedure RemoveAttachments(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        DocumentAttachment.SetRange("Table ID", Database::"Sales Invoice Header");
        DocumentAttachment.SetRange("No.", SalesInvoiceHeader."No.");
        if not DocumentAttachment.IsEmpty() then
            DocumentAttachment.DeleteAll(true);
    end;

    local procedure CreatePattern(Channel: Enum "Report Filename Output Route")
    var
        Pattern: Record "Report Filename Pattern";
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"S.Invoice");
        if ReportSelections.FindFirst() then;

        Pattern.Init();
        Pattern.Validate("Table No.", Database::"Sales Invoice Header");
        Pattern.Validate("Report ID", ReportSelections."Report ID");
        ProofSupport.LimitToRoute(Pattern, Channel);
        Pattern.Validate("File Name Pattern", PatternTok);
        // Assigned rather than validated, as every other proof does: a pattern is created as a
        // draft, so code that means it to be live has to say so.
        Pattern.Enabled := true;
        Pattern.Insert(true);
    end;

    local procedure FirstInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"): Boolean
    begin
        SalesInvoiceHeader.SetFilter("Bill-to Customer No.", '<>%1', '');
        exit(SalesInvoiceHeader.FindFirst());
    end;

    var
        ProofGuard: Codeunit "Filename Proof Guard";
        ProofSupport: Codeunit "Filename Proof Support";
        CapturedChannel: Enum "Report Filename Output Route";
        CapturedName: Text[250];
        PatternTok: Label '[No.]', Locked = true;
        ExtensionSeparatorTok: Label '.', Locked = true;
        NoInvoiceMsg: Label 'No posted sales invoice in this company, so there is nothing to attach.';
        PassMsg: Label 'PASS';
        DistinctNameMsg: Label 'a second attachment named after %1 but not identical to it', Comment = '%1 the first attachment''s name';
        ExpectedButGotMsg: Label 'FAIL expected %1 but got %2', Comment = '%1 expected, %2 actual';
        ShouldNotHaveResolvedMsg: Label 'FAIL should not have been named, but got %1', Comment = '%1 the name produced';
}
