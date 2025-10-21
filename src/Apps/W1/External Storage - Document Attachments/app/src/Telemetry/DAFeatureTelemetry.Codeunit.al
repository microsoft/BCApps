// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExternalStorage.DocumentAttachments;

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

    internal procedure LogFeatureEnabled()
    begin
        FeatureTelemetry.LogUptake('', ExternalStorageTok, Enum::"Feature Uptake Status"::"Set up");
    end;

    internal procedure LogFeatureDisabled()
    begin
        FeatureTelemetry.LogUptake('', ExternalStorageTok, Enum::"Feature Uptake Status"::"Undiscovered");
    end;

    internal procedure LogFeatureUsed()
    begin
        FeatureTelemetry.LogUptake('', ExternalStorageTok, Enum::"Feature Uptake Status"::Used);
    end;

    internal procedure LogFileUploaded()
    begin
        FeatureTelemetry.LogUsage('', ExternalStorageTok, 'File Uploaded');
    end;

    internal procedure LogFileDownloaded()
    begin
        FeatureTelemetry.LogUsage('', ExternalStorageTok, 'File Downloaded');
    end;

    internal procedure LogFileDeleted()
    begin
        FeatureTelemetry.LogUsage('', ExternalStorageTok, 'File Deleted');
    end;

    internal procedure LogCompanyMigration()
    begin
        FeatureTelemetry.LogUsage('', ExternalStorageTok, 'Company Migration');
    end;

    internal procedure LogManualSync()
    begin
        FeatureTelemetry.LogUsage('', ExternalStorageTok, 'Manual Sync');
    end;

    internal procedure LogAutoSync()
    begin
        FeatureTelemetry.LogUsage('', ExternalStorageTok, 'Auto Sync');
    end;

    internal procedure LogRootFolderConfigured()
    begin
        FeatureTelemetry.LogUsage('', ExternalStorageTok, 'Root Folder Configured');
    end;
}
