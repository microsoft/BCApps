// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExternalStorage.DocumentAttachments;

using Microsoft.Foundation.Attachment;
using System.Telemetry;

/// <summary>
/// Provides telemetry logging for External Storage - Document Attachments feature.
/// </summary>
codeunit 8754 "DA Feature Telemetry"
{
    Access = Internal;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ExternalStorageTok: Label 'External Storage - Document Attachments', Locked = true;
        ExternalStorageCategoryLbl: Label 'External Storage', Locked = true;

    internal procedure LogFeatureEnabled()
    begin
        FeatureTelemetry.LogUptake('0000RNO', ExternalStorageTok, Enum::"Feature Uptake Status"::"Set up");
    end;

    internal procedure LogFeatureDisabled()
    begin
        FeatureTelemetry.LogUptake('0000RNP', ExternalStorageTok, Enum::"Feature Uptake Status"::"Undiscovered");
    end;

    internal procedure LogFeatureUsed()
    begin
        FeatureTelemetry.LogUptake('0000RNQ', ExternalStorageTok, Enum::"Feature Uptake Status"::Used);
    end;

    internal procedure LogFileUploaded(DocumentAttachment: Record "Document Attachment")
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        GetTelemetryDimensions(DocumentAttachment, 'Upload', Dimensions);
        FeatureTelemetry.LogUsage('0000RNR', ExternalStorageTok, 'File Uploaded', Dimensions);
    end;

    internal procedure LogFileDownloaded(DocumentAttachment: Record "Document Attachment")
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        GetTelemetryDimensions(DocumentAttachment, 'Download', Dimensions);
        FeatureTelemetry.LogUsage('0000RNS', ExternalStorageTok, 'File Downloaded', Dimensions);
    end;

    internal procedure LogFileDeleted(DocumentAttachment: Record "Document Attachment")
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        GetTelemetryDimensions(DocumentAttachment, 'Delete', Dimensions);
        FeatureTelemetry.LogUsage('0000RNT', ExternalStorageTok, 'File Deleted', Dimensions);
    end;

    internal procedure LogCompanyMigration()
    begin
        FeatureTelemetry.LogUsage('0000RNU', ExternalStorageTok, 'Company Migration');
    end;

    internal procedure LogManualSync()
    begin
        FeatureTelemetry.LogUsage('0000RNV', ExternalStorageTok, 'Manual Sync');
    end;

    internal procedure LogAutoSync()
    begin
        FeatureTelemetry.LogUsage('0000RNW', ExternalStorageTok, 'Auto Sync');
    end;

    internal procedure LogRootFolderConfigured()
    begin
        FeatureTelemetry.LogUsage('0000RNX', ExternalStorageTok, 'Root Folder Configured');
    end;

    local procedure GetTelemetryDimensions(DocumentAttachment: Record "Document Attachment"; Operation: Text; var Dimensions: Dictionary of [Text, Text])
    var
        TableName: Text;
    begin
        Clear(Dimensions);
        Dimensions.Add('Category', ExternalStorageCategoryLbl);
        Dimensions.Add('Operation', Operation);
        Dimensions.Add('User ID', UserId());
        Dimensions.Add('File Name', DocumentAttachment."File Name");
        Dimensions.Add('File Extension', DocumentAttachment."File Extension");
        Dimensions.Add('Table ID', Format(DocumentAttachment."Table ID"));
        
        if TryGetTableName(DocumentAttachment."Table ID", TableName) then
            Dimensions.Add('Table Name', TableName);
        
        Dimensions.Add('Document No.', DocumentAttachment."No.");
        Dimensions.Add('Stored Externally', Format(DocumentAttachment."Stored Externally"));
        Dimensions.Add('Stored Internally', Format(DocumentAttachment."Stored Internally"));
        
        if DocumentAttachment."External File Path" <> '' then
            Dimensions.Add('Has External Path', 'Yes')
        else
            Dimensions.Add('Has External Path', 'No');
        
        if DocumentAttachment."External Upload Date" <> 0DT then
            Dimensions.Add('Upload Date', Format(DocumentAttachment."External Upload Date", 0, 9));
    end;

    [TryFunction]
    local procedure TryGetTableName(TableID: Integer; var TableName: Text)
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableID, false);
        TableName := RecRef.Name;
        RecRef.Close();
    end;
}
