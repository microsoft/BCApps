// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

using Microsoft.EServices.EDocument;
using System.Reflection;
using System.Threading;

codeunit 8136 "Report Filename Inbox Mgt."
{
    // The scheduled route. Job Queue Start Report renders with REPORT.SaveAs into the Report Inbox
    // row's stream, and Report Inbox names the download itself; the name is decided when the row
    // is inserted and read back when the entry is downloaded.

    Access = Internal;

    /// <param name="Filename">Receives the name, without extension.</param>
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
    /// An entry may have no record (a batch run over a filter), which is why the request page
    /// filters are supplied as well.
    /// </summary>
    [TryFunction]
    local procedure TryOpenRecordToProcess(var JobQueueEntry: Record "Job Queue Entry"; var SourceRecRef: RecordRef)
    begin
        SourceRecRef.Get(JobQueueEntry."Record ID to Process");
        SourceRecRef.SetRecFilter();
    end;

    /// <summary>
    /// Builds the same filterviews shape the platform hands to GetFilename on the interactive
    /// routes. Every data item is read, not only the first: a report whose first data item is an
    /// Integer loop (e.g. report 910) keeps the business table's filter in a child.
    /// </summary>
    /// <param name="FilterViews">Empty when no data item carries a view.</param>
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

    local procedure EscapeForJson(ViewText: Text): Text
    begin
        exit(ViewText.Replace(BackslashTok, BackslashTok + BackslashTok).Replace(QuoteTok, BackslashTok + QuoteTok));
    end;

    /// <returns>The file name including its extension, or empty when no pattern applied.</returns>
    internal procedure GetDownloadFileName(var ReportInbox: Record "Report Inbox"): Text
    begin
        if ReportInbox."File Name" = '' then
            exit('');

        exit(ReportInbox."File Name" + ReportInbox.Suffix());
    end;

    /// <summary>
    /// FOR TESTS ONLY - nothing in the app subscribes, and being internal, only the test app can.
    /// Report Filename Inbox Sub. performs the download itself, so this is the only way a test can
    /// see the name it is made under.
    /// </summary>
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
