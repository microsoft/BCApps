// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using System.Utilities;

/// <summary>
/// Codeunit Shpfy Log Entries (ID 30430).
/// </summary>
codeunit 30430 "Shpfy Log Entries"
{
    Access = Internal;

    var
        ReviewDataWarningLbl: Label 'Before downloading the escalation report, please review the request and response data for any sensitive information.\Do you want to continue?';
        ConnectionFailedErr: Label 'Failed to connect to Shopify API. Please verify your connection settings before escalating.';
        ShopNotFoundErr: Label 'Could not find the Shopify Shop associated with this log entry.';
        DownloadTitleLbl: Label 'Download Escalation Report';
        SubjectLbl: Label 'Subject: Technical Escalation: GraphQL 500 Error', Comment = 'GraphQL should not be translated.';
        IssueDescriptionLbl: Label 'Issue Description: I am a merchant using the Business Central app. A 500 Internal Server Error occurring during a specific process.';
        ImpactLbl: Label 'Impact: [Example: Unable to sync orders / Inventory not exporting]';
        ServerSideNoteLbl: Label 'The test shows that this is a server-side response and not a local browser or network issue.';
        EscalateNoteLbl: Label 'Please escalate this ticket to the Technical Support or Developer Support team to investigate the internal logs associated with the provided Request ID.';
        TechnicalDetailsLbl: Label 'Technical Details for Tier 2/Developer Support:';
        RequestIdLbl: Label 'Request ID: %1', Comment = '%1 = Shopify Request ID';
        TimestampLbl: Label 'Timestamp: %1 UTC', Comment = '%1 = Date and time';
        StoreUrlLbl: Label 'Store URL: %1', Comment = '%1 = Store URL';
        ApiVersionLbl: Label 'API Version: %1', Comment = '%1 = API version';
        AppNameLbl: Label 'App: Dynamics 365 Business Central';
        RequestLbl: Label 'Request:';
        ResponseLbl: Label 'Response:';
        DownloadRequestTitleLbl: Label 'Download Request file';
        DownloadResponseTitleLbl: Label 'Download Response file';
        DeleteLogEntriesLbl: Label 'Are you sure that you want to delete Shopify log entries?';
        EscalationDaysLimit: Integer;

    /// <summary>
    /// Check if a log entry can be escalated to Shopify support.
    /// Entry must have status code 500 and be within 14 days.
    /// </summary>
    /// <param name="LogEntry">The log entry to check.</param>
    /// <returns>True if the entry can be escalated, false otherwise.</returns>
    internal procedure CanEscalate(var LogEntry: Record "Shpfy Log Entry"): Boolean
    begin
        EscalationDaysLimit := 14;
        exit((LogEntry."Status Code" = '500') and (LogEntry."Date and Time" >= (CurrentDateTime() - (EscalationDaysLimit * 24 * 60 * 60 * 1000))));
    end;

    /// <summary>
    /// Delete log entries older than specified number of days.
    /// </summary>
    /// <param name="LogEntry">The log entry record to filter.</param>
    /// <param name="DaysOld">Number of days. Entries older than this will be deleted. Use 0 to delete all.</param>
    internal procedure DeleteEntries(var LogEntry: Record "Shpfy Log Entry"; DaysOld: Integer)
    begin
        if not Confirm(DeleteLogEntriesLbl) then
            exit;

        if DaysOld > 0 then begin
            LogEntry.SetFilter("Date and Time", '<=%1', CreateDateTime(Today - DaysOld, Time));
            if not LogEntry.IsEmpty() then
                LogEntry.DeleteAll(false);
            LogEntry.SetRange("Date and Time");
        end else
            if not LogEntry.IsEmpty() then
                LogEntry.DeleteAll(false);
    end;

    /// <summary>
    /// Download the request data from a log entry.
    /// </summary>
    /// <param name="LogEntry">The log entry to download the request from.</param>
    internal procedure DownloadRequest(var LogEntry: Record "Shpfy Log Entry")
    var
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
        ToFile: Text;
    begin
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(LogEntry.GetRequest());
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        ToFile := 'Request_' + Format(LogEntry."Entry No.") + '.json';
        File.DownloadFromStream(InStream, DownloadRequestTitleLbl, '', '(*.*)|*.*', ToFile);
    end;

    /// <summary>
    /// Download the response data from a log entry.
    /// </summary>
    /// <param name="LogEntry">The log entry to download the response from.</param>
    internal procedure DownloadResponse(var LogEntry: Record "Shpfy Log Entry")
    var
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
        ToFile: Text;
    begin
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(LogEntry.GetResponse());
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        ToFile := 'Response_' + Format(LogEntry."Entry No.") + '.json';
        File.DownloadFromStream(InStream, DownloadResponseTitleLbl, '', '(*.*)|*.*', ToFile);
    end;

    /// <summary>
    /// Test connection and download escalation report for the specified log entry.
    /// </summary>
    /// <param name="LogEntry">The log entry to generate the escalation report for.</param>
    internal procedure TestConnectionAndDownload(var LogEntry: Record "Shpfy Log Entry")
    var
        Shop: Record "Shpfy Shop";
    begin
        FindShopFromLogEntry(LogEntry, Shop);

        if not Shop.TestConnection() then
            Error(ConnectionFailedErr);

        if not Confirm(ReviewDataWarningLbl) then
            exit;

        DownloadEscalationReport(LogEntry, Shop);
    end;

    local procedure FindShopFromLogEntry(var LogEntry: Record "Shpfy Log Entry"; var Shop: Record "Shpfy Shop")
    var
        StoreUrl: Text;
    begin
        StoreUrl := ExtractStoreUrlFromLogUrl(LogEntry.URL);

        Shop.SetFilter("Shopify URL", '@*' + StoreUrl + '*');
        Shop.SetRange(Enabled, true);
        if not Shop.FindFirst() then
            Error(ShopNotFoundErr);
    end;

    local procedure ExtractStoreUrlFromLogUrl(LogUrl: Text[500]): Text
    var
        UrlParts: List of [Text];
        StorePart: Text;
    begin
        // URL format: https://{store}.myshopify.com/admin/api/{version}/graphql.json
        // We need to extract {store}.myshopify.com

        StorePart := LogUrl.ToLower();

        // Remove protocol
        if StorePart.Contains('://') then begin
            UrlParts := StorePart.Split('://');
            if UrlParts.Count() >= 2 then
                StorePart := UrlParts.Get(2);
        end;

        // Get the domain part (before /admin)
        if StorePart.Contains('/') then begin
            UrlParts := StorePart.Split('/');
            if UrlParts.Count() >= 1 then
                StorePart := UrlParts.Get(1);
        end;

        exit(StorePart);
    end;

    local procedure DownloadEscalationReport(var LogEntry: Record "Shpfy Log Entry"; var Shop: Record "Shpfy Shop")
    var
        TempBlob: Codeunit "Temp Blob";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        InStream: InStream;
        OutStream: OutStream;
        ReportContent: Text;
        ToFile: Text;
    begin
        ReportContent := GenerateEscalationReport(LogEntry, Shop, CommunicationMgt.GetApiVersion());

        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(ReportContent);
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);

        ToFile := 'ShopifyEscalation_' + Format(LogEntry."Entry No.") + '.txt';
        File.DownloadFromStream(InStream, DownloadTitleLbl, '', 'Text Files (*.txt)|*.txt', ToFile);
    end;

    local procedure GenerateEscalationReport(var LogEntry: Record "Shpfy Log Entry"; var Shop: Record "Shpfy Shop"; ApiVersion: Text): Text
    var
        ReportBuilder: TextBuilder;
    begin
        ReportBuilder.AppendLine(SubjectLbl);
        ReportBuilder.AppendLine('');
        ReportBuilder.AppendLine(IssueDescriptionLbl);
        ReportBuilder.AppendLine(ImpactLbl);
        ReportBuilder.AppendLine('');
        ReportBuilder.AppendLine(ServerSideNoteLbl);
        ReportBuilder.AppendLine(EscalateNoteLbl);
        ReportBuilder.AppendLine('');
        ReportBuilder.AppendLine(TechnicalDetailsLbl);
        ReportBuilder.AppendLine('');
        ReportBuilder.AppendLine(StrSubstNo(RequestIdLbl, LogEntry."Shpfy Request Id"));
        ReportBuilder.AppendLine(StrSubstNo(TimestampLbl, Format(LogEntry."Date and Time", 0, '<Year4>-<Month,2>-<Day,2> <Hours24,2>:<Minutes,2>:<Seconds,2>')));
        ReportBuilder.AppendLine(StrSubstNo(StoreUrlLbl, Shop.GetStoreName()));
        ReportBuilder.AppendLine(StrSubstNo(ApiVersionLbl, ApiVersion));
        ReportBuilder.AppendLine(AppNameLbl);
        ReportBuilder.AppendLine(RequestLbl);
        ReportBuilder.AppendLine(LogEntry.GetRequest());
        ReportBuilder.AppendLine(ResponseLbl);
        ReportBuilder.AppendLine(LogEntry.GetResponse());
        exit(ReportBuilder.ToText());
    end;
}
