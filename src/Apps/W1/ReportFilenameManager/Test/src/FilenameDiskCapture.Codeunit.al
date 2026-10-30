// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.Foundation.Reporting;

codeunit 149532 "Filename Disk Capture"
{
    // Reads the name Send to Disk downloads under and handles the download, so no client download
    // is attempted. The event is raised after the naming events, so this is the name the user would get.

    Access = Internal;
    EventSubscriberInstance = Manual;

    var
        LastName: Text;

    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnBeforeDownloadAttachmentFromStream', '', false, false)]
    local procedure CaptureDownload(var TempReportSelections: Record "Report Selections" temporary; RecordVariant: Variant; var AttachmentInStream: InStream; ClientAttachmentFileName: Text; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;
        LastName := ClientAttachmentFileName;
        IsHandled := true;
    end;

    internal procedure TakeName() Name: Text
    begin
        Name := LastName;
        Clear(LastName);
    end;
}
