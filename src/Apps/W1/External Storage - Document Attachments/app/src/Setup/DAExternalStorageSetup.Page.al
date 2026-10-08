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
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    Permissions = tabledata "DA External Storage Setup" = rimd,
                  tabledata "Job Queue Entry" = r;
    InherentPermissions = X;
    InherentEntitlements = X;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field(Enabled; Rec.Enabled)
                {
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
                field(CurrentEnvironmentHash; CurrentEnvironmentHash)
                {
                    Caption = 'Current Environment Hash';
                    ToolTip = 'Specifies the current environment hash used in the folder structure in external storage.';
                    Editable = false;
                }
            }
            group(UploadAndDeletePolicy)
            {
                Caption = 'Upload and Delete Policy';
                field("Delete from External Storage"; Rec."Delete from External Storage") { }
                field("Automatic Verified Cleanup"; Rec."Automatic Verified Cleanup") { }
                field("Cleanup Batch Size"; Rec."Cleanup Batch Size") { }
                field("Cleanup Run Minutes"; Rec."Cleanup Run Minutes") { }
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
            action(ScheduleInternalCleanup)
            {
                Caption = 'Schedule Pending Validation';
                Image = Job;
                ToolTip = 'Validate previously pending requests independently. Successful readback still leaves internal cleanup blocked, with references and content retained and no database storage reclamation.';

                trigger OnAction()
                var
                    CleanupManagement: Codeunit "DA Internal Cleanup Mgt.";
                begin
                    CleanupManagement.ScheduleCleanup(Rec);
                    Rec.Modify();
                end;
            }
        }
        area(Navigation)
        {
            action(DocumentAttachments)
            {
                Caption = 'Document Attachments';
                Image = Document;
                ToolTip = 'Open the document attachment list with information about the external storage.';
                RunObject = page "Document Attachment - External";
            }
            action(InternalCleanupRequests)
            {
                Caption = 'Internal Cleanup Requests';
                Image = Log;
                ToolTip = 'View and manage pending, failed, and blocked internal cleanup requests.';
                RunObject = page "DA Internal Cleanup Entries";
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
        }
    }

    trigger OnOpenPage()
    var
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
        CurrentEnvironmentHash := DAExternalStorageImpl.GetCurrentEnvironmentHash();
    end;

    var
        CurrentEnvironmentHash: Text[32];

    local procedure SelectRootFolder()
    var
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        ConfirmManagement: Codeunit "Confirm Management";
        NoFolderSelectedLbl: Label 'No folder selected. Do you want to clear the current root folder?';
        ChangeRootFolderWarningLbl: Label 'Changing the root folder while files are stored externally may cause issues accessing existing files.\\Existing files will remain in the old folder and new files will be stored in the new folder.\\Do you want to continue?';
        FolderPath: Text;
    begin
        FolderPath := DAExternalStorageImpl.SelectRootFolder();

        // Check if there are uploaded files and warn about changing root folder
        Rec.CalcFields("Has Uploaded Files");
        if Rec."Has Uploaded Files" then
            if not ConfirmManagement.GetResponseOrDefault(ChangeRootFolderWarningLbl, false) then
                exit;

        if FolderPath <> '' then begin
            Rec."Root Folder" := CopyStr(FolderPath, 1, MaxStrLen(Rec."Root Folder"));
            CurrPage.Update();
        end else begin
            if ConfirmManagement.GetResponseOrDefault(NoFolderSelectedLbl, false) then
                Rec."Root Folder" := '';
            CurrPage.Update();
        end;
    end;
}
