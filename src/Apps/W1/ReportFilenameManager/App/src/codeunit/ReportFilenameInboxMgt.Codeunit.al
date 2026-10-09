// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50121 "Report Filename Inbox Mgt."
{
    // The scheduled route, which reaches the manager through neither naming hook.
    //
    // Job Queue Start Report renders with REPORT.SaveAs into a stream, so the platform never
    // asks anybody for a name. The name is therefore decided here, at the moment the Report
    // Inbox row is inserted, and read back here when the entry is downloaded. The route is the
    // richest of the three despite that: the job queue entry carries the record the report is
    // about and the request page parameters it was scheduled with, so field, filter and
    // computed placeholders all resolve.

    Access = Internal;

    /// <summary>
    /// Resolves the name a scheduled report's output should download under.
    /// </summary>
    /// <param name="JobQueueEntry">The entry being run.</param>
    /// <param name="Filename">Receives the name, without extension.</param>
    /// <returns>True when a pattern applied.</returns>
    internal procedure TryResolveForJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry"; var Filename: Text): Boolean
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        SourceRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
    begin
        if not TryOpenRecordToProcess(JobQueueEntry, SourceRecRef) then
            Clear(SourceRecRef);

        exit(ReportFilenameMgt.TryResolve(JobQueueEntry."Object ID to Run", Channel::Scheduled,
            SourceRecRef, FilterViewsFromParameters(JobQueueEntry), Filename));
    end;

    /// <summary>
    /// The record the entry was scheduled against, when it has one. A job queue entry may name
    /// a report with no record at all - a batch run over a filter - which is why the filter
    /// from the request page parameters is supplied as well.
    /// </summary>
    [TryFunction]
    local procedure TryOpenRecordToProcess(var JobQueueEntry: Record "Job Queue Entry"; var SourceRecRef: RecordRef)
    begin
        SourceRecRef.Get(JobQueueEntry."Record ID to Process");
        SourceRecRef.SetRecFilter();
    end;

    /// <summary>
    /// Turns the request page parameters the report was scheduled with into the same shape the
    /// platform hands to GetFilename on the interactive routes, so one resolution path serves
    /// every route. Only the primary data item is needed: that is the one the manager binds
    /// to, because it is the only one present when a name is decided interactively.
    /// </summary>
    local procedure FilterViewsFromParameters(var JobQueueEntry: Record "Job Queue Entry"): Text
    var
        ReportMetadata: Record "Report Metadata";
        ParametersXml: XmlDocument;
        DataItemNode: XmlNode;
        ViewText: Text;
    begin
        if not ReportMetadata.Get(JobQueueEntry."Object ID to Run") then
            exit('');
        if ReportMetadata.FirstDataItemTableID = 0 then
            exit('');

        if not XmlDocument.ReadFrom(JobQueueEntry.GetReportParameters(), ParametersXml) then
            exit('');
        if not ParametersXml.SelectSingleNode(FirstDataItemPathTok, DataItemNode) then
            exit('');

        ViewText := DataItemNode.AsXmlElement().InnerText();
        if ViewText = '' then
            exit('');

        exit(StrSubstNo(FilterViewsTok, ReportMetadata.FirstDataItemTableID, EscapeForJson(ViewText)));
    end;

    /// <summary>
    /// A view contains double quotes whenever a filter value does, and the payload the manager
    /// reads is JSON.
    /// </summary>
    local procedure EscapeForJson(ViewText: Text): Text
    begin
        exit(ViewText.Replace(BackslashTok, BackslashTok + BackslashTok).Replace(QuoteTok, BackslashTok + QuoteTok));
    end;

    /// <summary>
    /// The name a Report Inbox entry downloads under, or an empty string when no pattern
    /// applied when it was produced - in which case Business Central names it exactly as it
    /// always has.
    /// </summary>
    /// <param name="ReportInbox">The entry being downloaded.</param>
    /// <returns>The file name including its extension.</returns>
    internal procedure GetDownloadFileName(var ReportInbox: Record "Report Inbox"): Text
    begin
        if ReportInbox."File Name" = '' then
            exit('');

        exit(ReportInbox."File Name" + ReportInbox.Suffix());
    end;

    /// <summary>
    /// Raised when a scheduled entry is about to be downloaded under a name this feature
    /// decided, so that the decision is observable from outside - which is also how the proof
    /// establishes that the download hook really is what names the file.
    ///
    /// Half of that reason is scaffolding. The proof needs this event to observe the download;
    /// a partner may or may not. It should stay in the shipped app only if there is a partner
    /// scenario for it, and not merely because it is here.
    /// </summary>
    /// <param name="ReportInbox">The entry being downloaded.</param>
    /// <param name="FileName">The name it is being downloaded under, including the extension.</param>
    [IntegrationEvent(false, false)]
    internal procedure OnBeforeDownloadWithResolvedName(var ReportInbox: Record "Report Inbox"; FileName: Text)
    begin
    end;

    var
        FirstDataItemPathTok: Label '//DataItems/DataItem[1]', Locked = true;
        FilterViewsTok: Label '[{"name":"Primary","tableid":%1,"view":"%2"}]', Comment = '%1 table id, %2 the view', Locked = true;
        QuoteTok: Label '"', Locked = true;
        BackslashTok: Label '\', Locked = true;
}
