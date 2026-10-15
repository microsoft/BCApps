// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50181 "Filename Review Support"
{
    // What the review tests and the end-to-end tests share: the report a posted sales invoice is
    // printed with, the feature switch, patterns, and reading attachments back. The documents they
    // name are their own, created by Filename Test Data.

    Access = Internal;

    /// <summary>
    /// The report Business Central prints, attaches and sends a posted sales invoice with: the first
    /// report selection for the usage that has a report.
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

    /// <summary>
    /// Switches the feature on or off, as the setup does.
    /// </summary>
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

    /// <summary>
    /// A live pattern for a report, on one route or on every route.
    /// </summary>
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

    /// <summary>
    /// Whether the document has an attachment of this name and extension.
    /// </summary>
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
    /// The attachments of the document, as Name.extension joined by a comma, for a failure message.
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
