// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExternalStorage.DocumentAttachments;

using Microsoft.Foundation.Attachment;
using System.Threading;

/// <summary>
/// Setup table for External Storage functionality.
/// Contains configuration settings for automatic upload and deletion policies.
/// </summary>
table 8750 "DA External Storage Setup"
{
    Caption = 'External Storage Setup';
    DataClassification = CustomerContent;
    Access = Internal;
    Permissions = tabledata "Job Queue Entry" = rimd;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; Enabled; Boolean)
        {
            Caption = 'Enabled';
            ToolTip = 'Specifies if the External Storage feature is enabled.';

            trigger OnValidate()
            var
                DAFeatureTelemetry: Codeunit "DA Feature Telemetry";
                DisableSetupErr: Label 'Cannot disable External Storage setup because there are files uploaded using this configuration. Please delete the uploaded files before disabling the setup.';
            begin
                if xRec.Enabled and not Rec.Enabled then begin
                    CalcFields("Has Uploaded Files");
                    if "Has Uploaded Files" then
                        Error(DisableSetupErr);
                end;

                if Enabled then
                    DAFeatureTelemetry.LogFeatureEnabled()
                else
                    DAFeatureTelemetry.LogFeatureDisabled();
            end;
        }
        field(6; "Scheduled Upload"; Boolean)
        {
            Caption = 'Scheduled Upload';
            ToolTip = 'Specifies if files should be uploaded automatically with using the Job Queue. When enabled, a Job Queue entry is created to run the upload process in the background.';

            trigger OnValidate()
            begin
                ManageJobQueue();
            end;
        }
        field(7; "Delete from External Storage"; Boolean)
        {
            Caption = 'Delete External File on Attachment Delete';
            ToolTip = 'Specifies if files should be deleted from external storage when the attachment is deleted from Business Central.';
            InitValue = true;
        }
        field(10; "Root Folder"; Text[250])
        {
            Caption = 'Root Folder';
            ToolTip = 'Specifies the root folder path where attachments will be stored in external storage.';

            trigger OnValidate()
            var
                DAFeatureTelemetry: Codeunit "DA Feature Telemetry";
            begin
                if "Root Folder" <> '' then
                    DAFeatureTelemetry.LogRootFolderConfigured();
            end;
        }
        field(12; "Job Queue Entry ID"; Guid)
        {
            Caption = 'Job Queue Entry ID';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies the ID of the job queue entry for automatic synchronization.';
        }
        field(25; "Has Uploaded Files"; Boolean)
        {
            Caption = 'Has Uploaded Files';
            FieldClass = FlowField;
            CalcFormula = exist("Document Attachment" where("Uploaded Externally" = const(true)));
            Editable = false;
            ToolTip = 'Specifies if files have been uploaded using this configuration.';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    local procedure ManageJobQueue()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if "Scheduled Upload" then begin
            // Create job queue if it doesn't exist
            if IsNullGuid("Job Queue Entry ID") or not JobQueueEntry.Get("Job Queue Entry ID") then
                CreateJobQueue()
            else
                // Reactivate if it exists but is not ready
                if JobQueueEntry.Status <> JobQueueEntry.Status::Ready then begin
                    JobQueueEntry.Status := JobQueueEntry.Status::Ready;
                    JobQueueEntry.Modify(true);
                end;
        end else
            // Delete or set to on hold when Auto Upload is disabled
            if not IsNullGuid("Job Queue Entry ID") then
                if JobQueueEntry.Get("Job Queue Entry ID") then begin
                    JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
                    JobQueueEntry.Modify(true);
                end;
    end;

    local procedure CreateJobQueue()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueCategoryLbl: Label 'EXTATTACH', Locked = true;
        JobQueueDescriptionLbl: Label 'External Storage - Automatic Upload';
        OneAmTime: Time;
    begin
        OneAmTime := 010000T; // 1:00 AM

        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Report;
        JobQueueEntry."Object ID to Run" := Report::"DA External Storage Sync";
        JobQueueEntry.Description := JobQueueDescriptionLbl;
        JobQueueEntry."Job Queue Category Code" := JobQueueCategoryLbl;
        JobQueueEntry."Run in User Session" := false;
        JobQueueEntry."Maximum No. of Attempts to Run" := 3;

        // Schedule for 1 AM daily
        JobQueueEntry."Earliest Start Date/Time" := CreateDateTime(Today() + 1, OneAmTime);
        if Time() < OneAmTime then
            JobQueueEntry."Earliest Start Date/Time" := CreateDateTime(Today(), OneAmTime);

        JobQueueEntry."Recurring Job" := true;
        JobQueueEntry."No. of Minutes between Runs" := 1440; // 24 hours

        // Set report parameters to upload to external storage
        JobQueueEntry."Report Request Page Options" := true;

        JobQueueEntry.Status := JobQueueEntry.Status::Ready;
        JobQueueEntry.Insert(true);

        "Job Queue Entry ID" := JobQueueEntry.ID;
        Modify();
    end;

    internal procedure DeleteJobQueue()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if not IsNullGuid("Job Queue Entry ID") then
            if JobQueueEntry.Get("Job Queue Entry ID") then
                JobQueueEntry.Delete(true);

        Clear("Job Queue Entry ID");
        Modify();
    end;
}
