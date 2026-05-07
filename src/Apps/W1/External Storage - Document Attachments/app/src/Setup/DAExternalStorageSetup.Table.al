// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExternalStorage.DocumentAttachments;

using Microsoft.Foundation.Attachment;
using System.Threading;
using System.Utilities;

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
            ToolTip = 'Specifies if the External Storage feature is enabled. Enable this to start using external storage for document attachments.';

            trigger OnValidate()
            var
                ConfirmManagement: Codeunit "Confirm Management";
                DAFeatureTelemetry: Codeunit "DA Feature Telemetry";
                DisclaimerMsg: Label 'You are about to enable External Storage.\\When this feature is enabled, files will be stored outside the Business Central service boundary.\Microsoft does not manage, back up, or restore data stored in external storage.\\You are responsible for the configuration, security, compliance, backup, and recovery of all externally stored files.\This feature is provided as-is, and you enable it at your own risk.\\Do you want to continue?';
                DisableSetupErr: Label 'Cannot disable External Storage because there are files stored externally.\\To disable this feature:\1. Open the Document Attachments - External Storage page.\2. Use "Copy from External To Internal" to restore files.\3. Then disable the feature.';
            begin
                if not xRec.Enabled and Rec.Enabled then
                    if not ConfirmManagement.GetResponseOrDefault(DisclaimerMsg) then begin
                        Rec.Enabled := false;
                        exit;
                    end;

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
            CalcFormula = exist("Document Attachment" where("Stored Externally" = const(true)));
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
}
