// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

using System.IO;

codeunit 8142 "Report Filename Excel Sub."
{
    // Temporary stand-in until Base Application raises a file name event for the financial report
    // workbook that Export Acc. Sched. to Excel downloads (ask 4); then this codeunit is removed.
    // Every hook on that path passes the name read-only, so the download is taken over and made
    // again under the new name. File Management.DownloadHandler is Scope('OnPrem'), which is why
    // this app targets OnPrem.

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
        // Re-entry from this subscriber's own download is recognised by name, not a flag, so a
        // download that failed half way cannot leave naming switched off.
        if DownloadingName <> '' then begin
            if ToFileName = DownloadingName then
                exit;
            Clear(DownloadingName);
        end;
        if not ToFileName.EndsWith(ExcelExtensionTok) then
            exit;
        if not ReportFilenameMgt.IsActive() then
            exit;
        // Only the workbook report 29 is writing right now, not any other workbook.
        if not ReportFilenameContext.IsExcelExportRunning() then
            exit;
        if not ReportFilenameFinRepSub.TryNameExcelDownload(NewFileName) then
            exit;

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
