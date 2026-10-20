// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.Reporting.FileNaming;

codeunit 149531 "Filename Review Support"
{
    // Helpers shared by the review tests and the end-to-end tests.

    Access = Internal;

    /// <summary>
    /// The first report selection for posted sales invoices that has a report.
    /// </summary>
    internal procedure InvoiceReportId(): Integer
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetCurrentKey(Usage, Sequence);
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"S.Invoice");
        if ReportSelections.FindSet() then
            repeat
                if ReportSelections."Report ID" <> 0 then
                    exit(ReportSelections."Report ID");
            until ReportSelections.Next() = 0;
        Error(NoInvoiceReportErr);
    end;

    internal procedure SetFeature(Enabled: Boolean)
    var
        ReportFilenameSetup: Record "Report Filename Setup";
    begin
        if not ReportFilenameSetup.Get() then begin
            ReportFilenameSetup.Init();
            ReportFilenameSetup.Insert();
        end;
        ReportFilenameSetup.Enabled := Enabled;
        ReportFilenameSetup.Modify();
    end;

    internal procedure AddPattern(var Pattern: Record "Report Filename Pattern"; ReportId: Integer; PatternText: Text; Route: Enum "Report Filename Output Route")
    var
        FilenameProofSupport: Codeunit "Filename Proof Support";
    begin
        Clear(Pattern);
        Pattern.Init();
        Pattern.Validate("Report ID", ReportId);
        Pattern.Validate("File Name Pattern", CopyStr(PatternText, 1, MaxStrLen(Pattern."File Name Pattern")));
        FilenameProofSupport.LimitToRoute(Pattern, Route);
        Pattern.Enabled := true;
        Pattern.Insert(true);
    end;

    internal procedure HasAttachment(TableNo: Integer; DocumentNo: Code[20]; FileName: Text; FileExtension: Text): Boolean
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        DocumentAttachment.SetRange("Table ID", TableNo);
        DocumentAttachment.SetRange("No.", DocumentNo);
        if DocumentAttachment.FindSet() then
            repeat
                if (DocumentAttachment."File Name" = FileName) and (LowerCase(DocumentAttachment."File Extension") = LowerCase(FileExtension)) then
                    exit(true);
            until DocumentAttachment.Next() = 0;
    end;

    /// <summary>
    /// The document's attachments as Name.extension, comma-separated, for a failure message.
    /// </summary>
    internal procedure ListAttachments(TableNo: Integer; DocumentNo: Code[20]) Listed: Text
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        DocumentAttachment.SetRange("Table ID", TableNo);
        DocumentAttachment.SetRange("No.", DocumentNo);
        if DocumentAttachment.FindSet() then
            repeat
                if Listed <> '' then
                    Listed += ', ';
                Listed += DocumentAttachment."File Name" + '.' + DocumentAttachment."File Extension";
            until DocumentAttachment.Next() = 0;
    end;

    var
        NoInvoiceReportErr: Label 'No report is set up for posted sales invoices in Report Selections.';
}
