// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50127 "Report Filename Excel Sub."
{
    // Stands in for one event Base Application does not raise yet: a file name event where Export
    // Acc. Sched. to Excel downloads a financial report's workbook, which it names after the
    // financial report's code. Every hook on that path passes the name read-only (Excel Buffer's
    // OnBeforeOpenUsingDocumentService, File Management's OnBeforeDownloadHandler), so the only way
    // to give it another name is to take the download over and make it again under that name.
    //
    // That takes File Management.DownloadHandler, which is Scope('OnPrem'): a Cloud app may not call
    // it (AL0296, measured on 28 September). Hence this app targets OnPrem, as Microsoft's own apps
    // alongside Base Application may - Shopify Connector, E-Document Core and Business Foundation do,
    // read from their manifests in the 28.4 container. During development this subscriber lived in a
    // separate app, only because an online sandbox accepts a Cloud app from a partner and nothing
    // else.
    //
    // WHAT THIS BECOMES
    //
    // Preferred: Base Application raises the file name event (ask 4), the manager subscribes and sets
    // the name from Report Filename Fin. Rep. Sub.TryNameExcelDownload, nobody takes a download over,
    // and this codeunit is removed.

    Access = Internal;
    SingleInstance = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"File Management", 'OnBeforeDownloadHandler', '', false, false)]
    local procedure OnBeforeDownloadHandler(var ToFolder: Text; ToFileName: Text; FromFileName: Text; var IsHandled: Boolean; var Downloaded: Boolean)
    var
        FileManagement: Codeunit "File Management";
        ReportFilenameFinRepSub: Codeunit "Report Filename Fin. Rep. Sub.";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        ReportFilenameContext: Codeunit "Report Filename Context";
        NewFileName: Text;
    begin
        if IsHandled then
            exit;
        // This subscriber's own download, re-entering: recognised by the name it is downloading under,
        // not by a flag alone, so a download that failed half way cannot leave Excel naming switched
        // off - any other download clears what it left behind.
        if DownloadingName <> '' then begin
            if ToFileName = DownloadingName then
                exit;
            Clear(DownloadingName);
        end;
        if not ToFileName.EndsWith(ExcelExtensionTok) then
            exit;
        if not ReportFilenameMgt.IsActive() then
            exit;
        // Only the workbook report 29 is writing right now, for the financial report the overview's
        // action recorded and armed - not any other workbook downloaded while something was left
        // behind (Report Filename Context.IsExcelExportRunning).
        if not ReportFilenameContext.IsExcelExportRunning() then
            exit;
        if not ReportFilenameFinRepSub.TryNameExcelDownload(NewFileName) then
            exit;

        // The download is made again through the same procedure, under the new name; the guard
        // keeps this subscriber out of its own call.
        DownloadingName := NewFileName;
        Downloaded := FileManagement.DownloadHandler(FromFileName, '', ToFolder, ExcelFilterTok, NewFileName);
        Clear(DownloadingName);
        IsHandled := true;
    end;

    var
        DownloadingName: Text;
        ExcelExtensionTok: Label '.xlsx', Locked = true;
        ExcelFilterTok: Label 'Excel Files (*.xlsx)|*.xlsx', Locked = true;
}
