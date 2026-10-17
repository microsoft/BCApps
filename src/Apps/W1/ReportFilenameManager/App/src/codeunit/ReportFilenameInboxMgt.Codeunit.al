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
        FilterViews: Text;
        HasRecord: Boolean;
    begin
        HasRecord := TryOpenRecordToProcess(JobQueueEntry, SourceRecRef);
        if not HasRecord then
            Clear(SourceRecRef);

        // With no record and no readable parameters nothing says which records the run covers, and
        // falling back to the whole table would name the file after records it may not contain.
        if not TryFilterViewsFromParameters(JobQueueEntry, FilterViews) then
            if not HasRecord then
                exit(false);

        exit(ReportFilenameMgt.TryResolve(JobQueueEntry."Object ID to Run", Channel::Scheduled,
            SourceRecRef, FilterViews, Filename));
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
    /// every route: one entry per data item that carries a view, with the data item's table.
    ///
    /// Every data item, not only the first. A report whose first data item is an Integer loop -
    /// report 910 Posted Assembly Order, CopyLoop over Posted Assembly Header - keeps the filter
    /// on its business table in a child, and with only the first view the resolver found no filter
    /// for the subject and named the file after the whole table. Each data item's table is read
    /// from Report Data Items, by the name the parameters give it.
    /// </summary>
    /// <param name="JobQueueEntry">The entry being run.</param>
    /// <param name="FilterViews">Receives the filterviews array, empty when no data item carries a view.</param>
    [TryFunction]
    local procedure TryFilterViewsFromParameters(var JobQueueEntry: Record "Job Queue Entry"; var FilterViews: Text)
    var
        ReportDataItems: Record "Report Data Items";
        ParametersXml: XmlDocument;
        DataItemNodes: XmlNodeList;
        DataItemNode: XmlNode;
        NameAttribute: XmlAttribute;
        Entries: TextBuilder;
        ViewText: Text;
    begin
        FilterViews := '';
        if not XmlDocument.ReadFrom(JobQueueEntry.GetReportParameters(), ParametersXml) then
            Error('');
        if not ParametersXml.SelectNodes(DataItemsPathTok, DataItemNodes) then
            Error('');

        foreach DataItemNode in DataItemNodes do begin
            ViewText := DataItemNode.AsXmlElement().InnerText();
            if ViewText <> '' then
                if DataItemNode.AsXmlElement().Attributes().Get(NameAttributeTok, NameAttribute) then begin
                    ReportDataItems.SetRange("Report ID", JobQueueEntry."Object ID to Run");
                    ReportDataItems.SetRange(Name, NameAttribute.Value());
                    if ReportDataItems.FindFirst() then
                        if ReportDataItems."Related Table ID" <> 0 then begin
                            if Entries.Length() > 0 then
                                Entries.Append(',');
                            Entries.Append(StrSubstNo(FilterViewEntryTok, EscapeForJson(NameAttribute.Value()), ReportDataItems."Related Table ID", EscapeForJson(ViewText)));
                        end;
                end;
        end;

        if Entries.Length() > 0 then
            FilterViews := '[' + Entries.ToText() + ']';
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
    /// FOR TESTS ONLY - nothing in the app subscribes, and being internal, only the test app can.
    /// Raised when a scheduled entry is about to be downloaded under a name this feature decided.
    ///
    /// It has to be here: Report Filename Inbox Sub. performs that download itself, so nothing in
    /// Business Central sees the name afterwards, and this is the only way a test can establish that
    /// the download really is made under the decided name.
    /// </summary>
    /// <param name="ReportInbox">The entry being downloaded.</param>
    /// <param name="FileName">The name it is being downloaded under, including the extension.</param>
    [IntegrationEvent(false, false)]
    internal procedure OnBeforeDownloadWithResolvedName(var ReportInbox: Record "Report Inbox"; FileName: Text)
    begin
    end;

    var
        DataItemsPathTok: Label '//DataItems/DataItem', Locked = true;
        NameAttributeTok: Label 'name', Locked = true;
        FilterViewEntryTok: Label '{"name":"%1","tableid":%2,"view":"%3"}', Comment = '%1 data item name, %2 table id, %3 the view', Locked = true;
        QuoteTok: Label '"', Locked = true;
        BackslashTok: Label '\', Locked = true;
}
