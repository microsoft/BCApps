// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50182 "Filename Disk Capture"
{
    // Reads the name Send to Disk downloads a customer document under, at the last point Base
    // Application raises before the download, and takes the download over: a test session has no
    // client to receive a file. Report Selections raises this event after the naming event the
    // feature answers, so what it reads is the name the user would get. Bound manually.

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

    /// <summary>
    /// The name of the last download, and forgets it.
    /// </summary>
    internal procedure TakeName() Name: Text
    begin
        Name := LastName;
        Clear(LastName);
    end;
}
