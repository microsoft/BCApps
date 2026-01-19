// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExternalStorage.DocumentAttachments;

using System.Threading;
using System.Utilities;

/// <summary>
/// Setup page for External Storage functionality.
/// Allows configuration of automatic upload and deletion policies.
/// </summary>
page 8750 "DA External Storage Setup"
{
    PageType = Card;
    SourceTable = "DA External Storage Setup";
    Caption = 'External Storage Setup';
    UsageCategory = None;
    ApplicationArea = Basic, Suite;
    InsertAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    Permissions = tabledata "DA External Storage Setup" = rmid,
                  tabledata "Job Queue Entry" = r;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field(Enabled; Rec.Enabled)
                {
                    ToolTip = 'Specifies if the External Storage feature is enabled. Enable this to start using external storage for document attachments.';
                    Importance = Promoted;
                }
                field("Root Folder"; Rec."Root Folder")
                {
                    ShowMandatory = true;
                    Editable = false;
                    trigger OnAssistEdit()
                    begin
                        SelectRootFolder();
                    end;
                }
            }
            group(UploadAndDeletePolicy)
            {
                Caption = 'Upload and Delete Policy';
                field("Delete from BC after Upload"; Rec."Delete from BC after Upload")
                {
                    trigger OnValidate()
                    begin
                        UpdateDeleteAfterVisibility();
                        CurrPage.Update(false);
                    end;
                }
                field("Delete After"; Rec."Delete After")
                {
                    ShowMandatory = true;
                    Enabled = ShowDeleteAfter;
                }
                field("Scheduled Upload"; Rec."Scheduled Upload") { }
                field("Delete from External Storage"; Rec."Delete from External Storage") { }
            }

            group(JobQueueInformation)
            {
                Caption = 'Job Queue Information';
                field("Job Queue Entry ID"; Rec."Job Queue Entry ID")
                {
                    ToolTip = 'Specifies the ID of the job queue entry for automatic synchronization.';

                    trigger OnDrillDown()
                    begin
                        ShowJobQueueEntry();
                    end;
                }
                field(JobQueueStatus; GetJobQueueStatus())
                {
                    Caption = 'Job Queue Status';
                    Editable = false;
                    ToolTip = 'Specifies the current status of the job queue entry.';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(StorageSync)
            {
                Caption = 'Storage Sync';
                Image = Process;
                ToolTip = 'Run the synchronization job to move document attachments to or from external storage.';

                trigger OnAction()
                begin
                    Report.Run(Report::"DA External Storage Sync");
                end;
            }
            action(MigrateFiles)
            {
                Caption = 'Migrate Files';
                Image = MoveToNextPeriod;
                ToolTip = 'Migrate all document attachments from the previous environment/company folder to the current environment/company folder.';

                trigger OnAction()
                begin
                    Report.Run(Report::"DA External Storage Migration");
                end;
            }
            action(ShowCurrentHash)
            {
                Caption = 'Show Current Environment Hash';
                Image = Copy;
                ToolTip = 'Show the current environment hash used in the folder structure in external storage.';

                trigger OnAction()
                begin
                    ShowCurrentEnvironmentHash();
                end;
            }
        }
        area(Navigation)
        {
            action(ShowJobQueue)
            {
                Caption = 'Show Job Queue Entry';
                Image = JobListSetup;
                ToolTip = 'View the job queue entry for automatic synchronization.';

                trigger OnAction()
                begin
                    ShowJobQueueEntry();
                end;
            }
            action(DocumentAttachments)
            {
                Caption = 'Document Attachments';
                Image = Document;
                ToolTip = 'Open the document attachment list with information about the external storage.';
                RunObject = page "Document Attachment - External";
            }
        }
        area(Promoted)
        {
            actionref(StorageSync_Promoted; StorageSync)
            {
            }
            actionref(MigrateFiles_Promoted; MigrateFiles)
            {
            }
            actionref(DocumentAttachments_Promoted; DocumentAttachments)
            {
            }
            group(InfoGroup)
            {
                Caption = 'Info';
                actionref(ShowCurrentHash_Promoted; ShowCurrentHash)
                {
                }
                actionref(ShowJobQueue_Promoted; ShowJobQueue)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
        UpdateDeleteAfterVisibility();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateDeleteAfterVisibility();
    end;

    var
        ShowDeleteAfter: Boolean;

    local procedure UpdateDeleteAfterVisibility()
    begin
        ShowDeleteAfter := not Rec."Delete from BC after Upload";
    end;

    local procedure SelectRootFolder()
    var
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        ConfirmManagement: Codeunit "Confirm Management";
        NoFolderSelectedLbl: Label 'No folder selected. Do you want to clear the current root folder?';
        FolderPath: Text;
    begin
        FolderPath := DAExternalStorageImpl.SelectRootFolder();
        if FolderPath <> '' then begin
            Rec."Root Folder" := CopyStr(FolderPath, 1, MaxStrLen(Rec."Root Folder"));
            CurrPage.Update();
        end else begin
            if ConfirmManagement.GetResponseOrDefault(NoFolderSelectedLbl, false) then
                Rec."Root Folder" := '';
            CurrPage.Update();
        end;
    end;

    local procedure ShowCurrentEnvironmentHash()
    var
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
    begin
        DAExternalStorageImpl.ShowCurrentEnvironmentHash();
    end;

    local procedure ShowJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if not IsNullGuid(Rec."Job Queue Entry ID") then
            if JobQueueEntry.Get(Rec."Job Queue Entry ID") then
                Page.Run(Page::"Job Queue Entry Card", JobQueueEntry);
    end;

    local procedure GetJobQueueStatus(): Text
    var
        JobQueueEntry: Record "Job Queue Entry";
        NotCreatedLbl: Label 'Not Created';
        DeletedLbl: Label 'Deleted';
    begin
        if IsNullGuid(Rec."Job Queue Entry ID") then
            exit(NotCreatedLbl);

        if not JobQueueEntry.Get(Rec."Job Queue Entry ID") then
            exit(DeletedLbl);

        exit(Format(JobQueueEntry.Status));
    end;
}
