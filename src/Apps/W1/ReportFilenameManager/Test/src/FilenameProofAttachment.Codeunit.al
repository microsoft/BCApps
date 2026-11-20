// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.Reporting.FileNaming;
using Microsoft.Sales.History;

codeunit 149520 "Filename Proof Attachment"
{
    // Proofs for Attach as PDF (SaveAsDocumentAttachment, which stores a Document Attachment row).
    // Names are read from the manager's own OnAfterNamingDelivery, not from a second subscriber on
    // the platform event: subscriber order is unspecified, so that one could run first and read nothing.

    SingleInstance = true;

    trigger OnRun()
    begin
        ProveAttachmentRoute();
    end;

    /// <summary>
    /// Attach as PDF names the attachment from the pattern, and that name lands on Attached Documents.
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

        TestData.PostNewInvoice(SalesInvoiceHeader);
        ProofSupport.LogLine('10 Invoice', SalesInvoiceHeader."No.");

        ProofGuard.ClearPatterns();
        RemoveAttachments(SalesInvoiceHeader);

        // Control: run once with no pattern and record Business Central's own extension and file
        // type; the checks below compare against those, not against what this feature produced.
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

        // Codeunit.Run with its result used must not start inside a write transaction.
        Commit();

        // Isolated: the render can fail on company setup, which then ends only this run.
        if not Codeunit.Run(Codeunit::"Filename Proof Attach PDF", SalesInvoiceHeader) then
            ProofSupport.LogLine('11 Attach as PDF returned', GetLastErrorText());

        ProofSupport.LogLine('12 Name the route produced', CapturedName);
        ProofSupport.LogLine('13 Channel it was named on', Format(CapturedChannel));

        // The extension is not asserted here: the manager copies whatever it was handed. The
        // stored row below is the real check.
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

        // The event alone proves the manager ran, not that Business Central kept the name.
        ReadStoredAttachment(SalesInvoiceHeader, Stored, StoredExtension, StoredType);
        ProofSupport.LogLine('14 Name stored on the document', Stored);
        ProofSupport.LogLine('14 with extension', StoredExtension);
        ProofSupport.LogLine('14 and file type', StoredType);

        // Base Application splits the name: "103001.pdf" is stored as "103001" and "pdf", and that
        // split is where the extension and file type come from.
        if StoredExtension <> '' then
            Expected := Stored + ExtensionSeparatorTok + StoredExtension
        else
            Expected := Stored;

        if (Stored <> '') and (Expected = CapturedName) then
            ProofSupport.LogLine('RESULT the stored attachment carries that name', PassMsg)
        else
            ProofSupport.LogLine('RESULT the stored attachment carries that name',
                StrSubstNo(ExpectedButGotMsg, CapturedName, Expected));

        // A name returned without its extension would be stored with no File Extension.
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
    /// A Save pattern must not name the attachment: the stored name is the same with and without one.
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

        TestData.PostNewInvoice(SalesInvoiceHeader);

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
    /// A second attachment of the same document gets a name of its own: Document Attachment
    /// numbers a taken name after the naming hook, so a pattern's name is numbered too.
    /// </summary>
    /// <param name="SalesInvoiceHeader">Already carries one named attachment.</param>
    local procedure ProveASecondAttachmentGetsItsOwnName(var SalesInvoiceHeader: Record "Sales Invoice Header"; FirstName: Text)
    var
        DocumentAttachment: Record "Document Attachment";
        SecondName: Text;
        SecondExtension: Text;
        SecondType: Text;
    begin
        // Codeunit.Run with its result used must not start inside a write transaction.
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
    /// A pattern for another channel must not name this route.
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
        // Codeunit.Run with its result used must not start inside a write transaction.
        Commit();
        if not Codeunit.Run(Codeunit::"Filename Proof Attach PDF", SalesInvoiceHeader) then;

        if CapturedName = '' then
            ProofSupport.LogLine('RESULT a pattern for another channel does not name this route', PassMsg)
        else
            ProofSupport.LogLine('RESULT a pattern for another channel does not name this route',
                StrSubstNo(ShouldNotHaveResolvedMsg, CapturedName));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Report Filename Subscribers", 'OnAfterNamingDelivery', '', false, false)]
    local procedure CaptureDeliveryName(ReportId: Integer; Channel: Enum "Report Filename Output Route"; FileName: Text)
    begin
        CapturedName := CopyStr(FileName, 1, MaxStrLen(CapturedName));
        CapturedChannel := Channel;
    end;

    /// <param name="FileType">Receives the file type as the page shows it.</param>
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
        // A pattern is created as a draft.
        Pattern.Enabled := true;
        Pattern.Insert(true);
    end;

    var
        ProofGuard: Codeunit "Filename Proof Guard";
        ProofSupport: Codeunit "Filename Proof Support";
        TestData: Codeunit "Filename Test Data";
        CapturedChannel: Enum "Report Filename Output Route";
        CapturedName: Text[250];
        PatternTok: Label '[No.]', Locked = true;
        ExtensionSeparatorTok: Label '.', Locked = true;
        PassMsg: Label 'PASS';
        DistinctNameMsg: Label 'a second attachment named after %1 but not identical to it', Comment = '%1 the first attachment''s name';
        ExpectedButGotMsg: Label 'FAIL expected %1 but got %2', Comment = '%1 expected, %2 actual';
        ShouldNotHaveResolvedMsg: Label 'FAIL should not have been named, but got %1', Comment = '%1 the name produced';
}
