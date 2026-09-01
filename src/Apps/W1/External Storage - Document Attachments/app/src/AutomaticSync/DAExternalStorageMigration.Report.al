// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExternalStorage.DocumentAttachments;

using Microsoft.Foundation.Attachment;

/// <summary>
/// Report for migrating document attachments from previous environment/company folder to current environment/company folder.
/// Can be scheduled via job queue for background processing.
/// </summary>
report 8753 "DA External Storage Migration"
{
    Caption = 'External Storage Migration';
    ProcessingOnly = true;
    UseRequestPage = true;
    Extensible = false;
    ApplicationArea = All;
    UsageCategory = None;
    Permissions = tabledata "DA External Storage Setup" = r,
                  tabledata "Document Attachment" = rimd;

    dataset
    {
        dataitem(DocumentAttachment; "Document Attachment")
        {
            trigger OnPreDataItem()
            begin
                // Filter for files that are uploaded externally and need migration
                SetRange("Stored Externally", true);
                SetFilter("External File Path", '<>%1', '');

                TotalCount := Count();

                if TotalCount = 0 then begin
                    if GuiAllowed() then
                        Message(NoFilesToMigrateLbl);
                    CurrReport.Break();
                end;

                ProcessedCount := 0;
                MigratedCount := 0;
                FailedCount := 0;

                if GuiAllowed() then
                    Dialog.Open(ProcessingMsg, TotalCount);
            end;

            trigger OnAfterGetRecord()
            begin
                ProcessedCount += 1;

                if GuiAllowed() then
                    Dialog.Update(1, ProcessedCount);

                // Check if file needs migration
                if ExternalStorageImpl.IsFileFromAnotherEnvironmentOrCompany(DocumentAttachment) then
                    if ExternalStorageImpl.MigrateFileToCurrentEnvironment(DocumentAttachment) then
                        MigratedCount += 1
                    else
                        FailedCount += 1;

                Commit(); // Commit after each record to avoid lost in communication error with external storage service
            end;

            trigger OnPostDataItem()
            begin
                if MigratedCount > 0 then
                    LogMigrationTelemetry();

                if GuiAllowed() then begin
                    if TotalCount <> 0 then
                        Dialog.Close();

                    if MigratedCount > 0 then
                        Message(MigrationCompletedMsg, MigratedCount, FailedCount)
                    else
                        Message(NoFilesToMigrateLbl);
                end;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content)
            {
                group(General)
                {
                    Caption = 'General';
                    label(InfoLabel)
                    {
                        ApplicationArea = All;
                        Caption = 'This report will migrate all document attachments from a previous environment or company folder to the current environment/company folder in external storage.';
                    }
                }
            }
        }
    }

    var
        ExternalStorageImpl: Codeunit "DA External Storage Impl.";
        Dialog: Dialog;
        FailedCount: Integer;
        MigratedCount: Integer;
        ProcessedCount: Integer;
        TotalCount: Integer;
        MigrationCompletedMsg: Label '%1 file(s) have been successfully migrated to the current company folder. %2 failed.', Comment = '%1 = Number of migrated files, %2 = Number of failed migrations';
        NoFilesToMigrateLbl: Label 'No files need to be migrated.';
        ProcessingMsg: Label 'Processing #1###### attachments...', Comment = '%1 - Total Number of Attachments';

    local procedure LogMigrationTelemetry()
    var
        DAFeatureTelemetry: Codeunit "DA Feature Telemetry";
    begin
        DAFeatureTelemetry.LogCompanyMigration();
    end;
}
