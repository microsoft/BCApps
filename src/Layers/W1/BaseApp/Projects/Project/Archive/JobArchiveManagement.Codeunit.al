// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Archive;

using System.Utilities;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Foundation.Comment;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Setup;
using Microsoft.Sales.Document;

codeunit 5139 "Job Archive Management"
{
    Permissions = tabledata "Job Archive" = ri,
                  tabledata "Job Task Archive" = rim,
                  tabledata "Job Planning Line Archive" = rim,
                  tabledata "Comment Line" = r,
                  tabledata "Comment Line Archive" = ri;

    trigger OnRun()
    begin
    end;

    var
        RecordLinkManagement: Codeunit "Record Link Management";

        RestoreQst: Label 'Do you want to Restore %1 %2 Version %3?', Comment = '%1 = Job Caption, %2 = Job No., %3 = Version No.';
        RestoreMsg: Label '%1 %2 has been restored.', Comment = '%1 = Job Caption, %2 = Job No.';
        ArchiveQst: Label 'Archive %1 no.: %2?', Comment = '%1 = Job Caption, %2 = Job No.';
        JobArchiveMsg: Label 'Project %1 has been archived.', Comment = '%1 = Project No.';
        MissingJobErr: Label 'Project %1 does not exist anymore.\It is not possible to restore the Project.', Comment = '%1 = Project No.';
        CompletedJobStatusErr: Label 'Status must not be Completed in order to restore the Project: No. = %1', Comment = '%1 = Project No.';
        JobLedgerEntryExistErr: Label 'Project Ledger Entries exist for Project No. %1.\It is not possible to restore the Project.', Comment = '%1 = Project No.';
        SalesInvoiceExistErr: Label 'Outstanding Sales Invoice exists for Project No. %1.\It is not possible to restore the Project.', Comment = '%1 = Project No.';

    procedure AutoArchiveJob(var Job: Record Job)
    var
        JobSetup: Record "Jobs Setup";
    begin
        JobSetup.Get();
        case JobSetup."Archive Jobs" of
            JobSetup."Archive Jobs"::Always:
                StoreJob(Job, false);
            JobSetup."Archive Jobs"::Question:
                ArchiveJob(Job);
        end;
    end;

    procedure ArchiveJob(var Job: Record "Job")
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if ConfirmManagement.GetResponseOrDefault(
             StrSubstNo(ArchiveQst, Job.TableCaption(), Job."No."), true)
        then begin
            StoreJob(Job, false);
            Message(JobArchiveMsg, Job."No.");
        end;
    end;

    procedure StoreJob(var Job: Record Job; InteractionExist: Boolean)
    var
        JobArchive: Record "Job Archive";
        JobTask: Record "Job Task";
        JobTaskArchive: Record "Job Task Archive";
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLineArchive: Record "Job Planning Line Archive";
        CommentLineTableName: Enum "Comment Line Table Name";
    begin
        JobArchive.Init();
        JobArchive.TransferFields(Job);
        JobArchive."Archived By" := CopyStr(UserId(), 1, MaxStrLen(JobArchive."Archived By"));
        JobArchive."Date Archived" := Today();
        JobArchive."Time Archived" := Time();
        JobArchive."Version No." := GetNextVersionNo(Database::Job, Job."No.");
        JobArchive."Interaction Exist" := InteractionExist;
        RecordLinkManagement.CopyLinks(Job, JobArchive);
        OnStoreJobOnBeforeInsertJobArchive(Job, JobArchive);
        JobArchive.Insert();

        StoreComments(CommentLineTableName::Job, JobArchive."No.", JobArchive."Version No.");

        OnStoreJobOnBeforeStoreJobTaskAndJobPlanningLine(JobTask, JobPlanningLine, Job);

        JobTask.SetRange("Job No.", Job."No.");
        if JobTask.FindSet() then
            repeat
                JobTaskArchive.Init();
                JobTaskArchive.TransferFields(JobTask);
                JobTaskArchive."Version No." := JobArchive."Version No.";
                RecordLinkManagement.CopyLinks(JobTask, JobTaskArchive);
                OnStoreJobOnBeforeInsertJobTaskArchive(JobTask, JobTaskArchive);
                JobTaskArchive.Insert();
                AddCalculatedValuesToJobTaskArchive(JobTaskArchive, JobTask);
            until JobTask.Next() = 0;

        JobPlanningLine.SetRange("Job No.", Job."No.");
        if JobPlanningLine.FindSet() then
            repeat
                JobPlanningLineArchive.Init();
                JobPlanningLineArchive.TransferFields(JobPlanningLine);
                JobPlanningLineArchive."Version No." := JobArchive."Version No.";
                RecordLinkManagement.CopyLinks(JobPlanningLine, JobPlanningLineArchive);
                OnStoreJobOnBeforeInsertJobPlanningLineArchive(JobPlanningLine, JobPlanningLineArchive);
                JobPlanningLineArchive.Insert();
                AddCalculatedValuesToJobPlanningLineArchive(JobPlanningLineArchive, JobPlanningLine);
            until JobPlanningLine.Next() = 0;

        OnAfterStoreJob(Job, JobArchive);
    end;

    local procedure AddCalculatedValuesToJobPlanningLineArchive(var JobPlanningLineArchive: Record "Job Planning Line Archive"; var JobPlanningLine: Record "Job Planning Line")
    begin
        JobPlanningLine.CalcFields("Invoiced Amount (LCY)", "Invoiced Cost Amount (LCY)", "Qty. Transferred to Invoice", "Qty. Invoiced",
                "Reserved Quantity", "Reserved Qty. (Base)", "Pick Qty.", "Pick Qty. (Base)", "Qty. on Journal");
        JobPlanningLineArchive."Invoiced Amount (LCY)" := JobPlanningLine."Invoiced Amount (LCY)";
        JobPlanningLineArchive."Invoiced Cost Amount (LCY)" := JobPlanningLine."Invoiced Cost Amount (LCY)";
        JobPlanningLineArchive."Qty. Transferred to Invoice" := JobPlanningLine."Qty. Transferred to Invoice";
        JobPlanningLineArchive."Qty. Invoiced" := JobPlanningLine."Qty. Invoiced";
        JobPlanningLineArchive."Reserved Quantity" := JobPlanningLine."Reserved Quantity";
        JobPlanningLineArchive."Reserved Qty. (Base)" := JobPlanningLine."Reserved Qty. (Base)";
        JobPlanningLineArchive."Pick Qty." := JobPlanningLine."Pick Qty.";
        JobPlanningLineArchive."Qty. on Journal" := JobPlanningLine."Qty. on Journal";
        OnAddCalculatedValuesToJobPlanningLineArchiveOnBeforeModifyJobPlanningLineArchive(JobPlanningLine, JobPlanningLineArchive);
        JobPlanningLineArchive.Modify(true);
    end;

    local procedure AddCalculatedValuesToJobTaskArchive(var JobTaskArchive: Record "Job Task Archive"; var JobTask: Record "Job Task")
    begin
        JobTask.CalcFields("Usage (Total Cost)", "Usage (Total Price)", "Contract (Invoiced Price)", "Contract (Invoiced Cost)",
            "Outstanding Orders", "Amt. Rcd. Not Invoiced");
        JobTaskArchive."Usage (Total Cost)" := JobTask."Usage (Total Cost)";
        JobTaskArchive."Usage (Total Price)" := JobTask."Usage (Total Price)";
        JobTaskArchive."Contract (Invoiced Price)" := JobTask."Contract (Invoiced Price)";
        JobTaskArchive."Contract (Invoiced Cost)" := JobTask."Contract (Invoiced Cost)";
        JobTaskArchive."Outstanding Orders" := JobTask."Outstanding Orders";
        JobTaskArchive."Amt. Rcd. Not Invoiced" := JobTask."Amt. Rcd. Not Invoiced";
        OnAddCalculatedValuesToJobTaskArchiveOnBeforeModifyJobTaskArchive(JobTask, JobTaskArchive);
        JobTaskArchive.Modify(true);
    end;

    local procedure StoreComments(TableName: Enum "Comment Line Table Name"; DocNo: Code[20]; VersionNo: Integer)
    var
        CommentLine: Record "Comment Line";
        CommentLineArchive: Record "Comment Line Archive";
    begin
        CommentLine.SetRange("Table Name", TableName);
        CommentLine.SetRange("No.", DocNo);
        if CommentLine.FindSet() then
            repeat
                CommentLineArchive.Init();
                CommentLineArchive.TransferFields(CommentLine);
                CommentLineArchive."Version No." := VersionNo;
                CommentLineArchive.Insert();
            until CommentLine.Next() = 0;
    end;

    local procedure RestoreComments(TableName: Enum "Comment Line Table Name"; DocNo: Code[20]; VersionNo: Integer)
    var
        CommentLine: Record "Comment Line";
        CommentLineArchive: Record "Comment Line Archive";
    begin
        CommentLineArchive.SetRange("Table Name", TableName);
        CommentLineArchive.SetRange("No.", DocNo);
        CommentLineArchive.SetRange("Version No.", VersionNo);
        if CommentLineArchive.FindSet() then
            repeat
                CommentLine.Init();
                CommentLine.TransferFields(CommentLineArchive);
                CommentLine.Insert();
            until CommentLineArchive.Next() = 0;
    end;

    procedure RestoreJob(var JobArchive: Record "Job Archive")
    var
        Job: Record Job;
        CommentLine: Record "Comment Line";
        ConfirmManagement: Codeunit "Confirm Management";
        RestoreArchivedJob: Boolean;
    begin
        CheckJobRestorePermissions(Job, JobArchive);

        RestoreArchivedJob := false;
        if ConfirmManagement.GetResponseOrDefault(
            StrSubstNo(RestoreQst, Job.TableCaption(), JobArchive."No.", JobArchive."Version No."), true)
        then
            RestoreArchivedJob := true;

        if RestoreArchivedJob then begin
            CommentLine.SetRange("Table Name", CommentLine."Table Name"::Job);
            CommentLine.SetRange("No.", Job."No.");
            if not CommentLine.IsEmpty() then
                CommentLine.DeleteAll();

            Job.Delete();
            OnRestoreJobOnAfterDeleteJob(Job);

            Job.Init();
            Job."No." := JobArchive."No.";
            Job.TransferFields(JobArchive);
            OnRestoreJobOnBeforeInsertJob(JobArchive, Job);
            Job.Insert(true);
            RecordLinkManagement.CopyLinks(JobArchive, Job);
            Job.Modify(true);

            RestoreComments(CommentLine."Table Name"::Job, JobArchive."No.", JobArchive."Version No.");
            RestoreJobTasks(JobArchive, Job);
            OnAfterRestoreJob(JobArchive, Job);
            Message(RestoreMsg, Job.TableCaption(), JobArchive."No.");
        end;
    end;

    local procedure RestoreJobTasks(var JobArchive: Record "Job Archive"; Job: Record Job)
    var
        JobTask: Record "Job Task";
        JobTaskDimension: Record "Job Task Dimension";
        JobTaskArchive: Record "Job Task Archive";
        JobPlanningLine: Record "Job Planning Line";
    begin
        OnBeforeDeleteJobTasks(JobTask, JobTaskDimension, JobPlanningLine, JobArchive, Job);
        JobTask.SetRange("Job No.", Job."No.");
        if not JobTask.IsEmpty() then
            JobTask.DeleteAll();

        JobTaskDimension.SetRange("Job No.", Job."No.");
        if not JobTaskDimension.IsEmpty() then
            JobTaskDimension.DeleteAll();

        JobPlanningLine.SetRange("Job No.", Job."No.");
        if not JobPlanningLine.IsEmpty() then
            JobPlanningLine.DeleteAll();

        JobTaskArchive.SetRange("Job No.", JobArchive."No.");
        JobTaskArchive.SetRange("Version No.", JobArchive."Version No.");
        if JobTaskArchive.FindSet() then
            repeat
                RestoreSingleJobTask(JobTaskArchive, Job);
                RestoreJobPlanningLines(JobTaskArchive);
            until JobTaskArchive.Next() = 0;
    end;

    local procedure RestoreSingleJobTask(JobTaskArchive: Record "Job Task Archive"; Job: Record Job)
    var
        JobTask: Record "Job Task";
        JobTaskDimension: Record "Job Task Dimension";
    begin
        JobTaskDimension.SetRange("Job No.", Job."No.");
        JobTaskDimension.SetRange("Job Task No.", JobTaskArchive."Job Task No.");
        if not JobTaskDimension.IsEmpty() then
            JobTaskDimension.DeleteAll();

        JobTask.Init();
        JobTask.TransferFields(JobTaskArchive);
        OnRestoreSingleJobTaskOnBeforeInsertJobTask(JobTaskArchive, JobTask);
        JobTask.Insert(true);
        RecordLinkManagement.CopyLinks(JobTaskArchive, JobTask);
        JobTask.Modify(true);
        OnAfterRestoreSingleJobTask(JobTaskArchive, JobTask);
    end;

    local procedure RestoreJobPlanningLines(var JobTaskArchive: Record "Job Task Archive")
    var
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLineArchive: Record "Job Planning Line Archive";
    begin
        JobPlanningLineArchive.SetRange("Job No.", JobTaskArchive."Job No.");
        JobPlanningLineArchive.SetRange("Job Task No.", JobTaskArchive."Job Task No.");
        JobPlanningLineArchive.SetRange("Version No.", JobTaskArchive."Version No.");
        if JobPlanningLineArchive.FindSet() then
            repeat
                JobPlanningLine.Init();
                JobPlanningLine.TransferFields(JobPlanningLineArchive);
                OnRestoreJobPlanningLinesOnBeforeInsertJobPlanningLine(JobPlanningLineArchive, JobPlanningLine);
                JobPlanningLine.Insert(true);
                RecordLinkManagement.CopyLinks(JobPlanningLineArchive, JobPlanningLine);
                JobPlanningLine.Modify(true);
                OnAfterRestoreSingleJobPlanningLine(JobPlanningLineArchive, JobPlanningLine);
            until JobPlanningLineArchive.Next() = 0;
    end;

    local procedure CheckJobRestorePermissions(var Job: Record Job; var JobArchive: Record "Job Archive")
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        SalesLine: Record "Sales Line";
    begin
        if not Job.Get(JobArchive."No.") then
            Error(MissingJobErr, JobArchive."No.");

        if Job.Status = Job.Status::Completed then
            Error(CompletedJobStatusErr, Job."No.");

        JobLedgerEntry.SetRange("Job No.", Job."No.");
        if not JobLedgerEntry.IsEmpty() then
            Error(JobLedgerEntryExistErr, Job."No.");

        SalesLine.SetRange("Job No.", Job."No.");
        if not SalesLine.IsEmpty() then
            Error(SalesInvoiceExistErr, Job."No.");

        OnAfterCheckJobRestorePermissions(JobArchive, Job);
    end;

    procedure GetNextVersionNo(TableId: Integer; DocNo: Code[20]) VersionNo: Integer
    var
        JobArchive: Record "Job Archive";
    begin
        case TableId of
            DATABASE::Job:
                begin
                    JobArchive.LockTable();
                    JobArchive.SetRange("No.", DocNo);
                    if JobArchive.FindLast() then
                        exit(JobArchive."Version No." + 1);

                    exit(1);
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnStoreJobOnBeforeInsertJobArchive(Job: Record Job; var JobArchive: Record "Job Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnStoreJobOnBeforeInsertJobTaskArchive(JobTask: Record "Job Task"; var JobTaskArchive: Record "Job Task Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnStoreJobOnBeforeInsertJobPlanningLineArchive(JobPlanningLine: Record "Job Planning Line"; var JobPlanningLineArchive: Record "Job Planning Line Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterStoreJob(Job: Record Job; var JobArchive: Record "Job Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRestoreJob(JobArchive: Record "Job Archive"; var Job: Record Job)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreJobOnAfterDeleteJob(Job: Record Job)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRestoreSingleJobTask(JobTaskArchive: Record "Job Task Archive"; var JobTask: Record "Job Task")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRestoreSingleJobPlanningLine(JobPlanningLineArchive: Record "Job Planning Line Archive"; var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddCalculatedValuesToJobTaskArchiveOnBeforeModifyJobTaskArchive(var JobTask: Record "Job Task"; var JobTaskArchive: Record "Job Task Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddCalculatedValuesToJobPlanningLineArchiveOnBeforeModifyJobPlanningLineArchive(var JobPlanningLine: Record "Job Planning Line"; var JobPlanningLineArchive: Record "Job Planning Line Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckJobRestorePermissions(JobArchive: Record "Job Archive"; var Job: Record Job)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreSingleJobTaskOnBeforeInsertJobTask(var JobTaskArchive: Record "Job Task Archive"; var JobTask: Record "Job Task")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreJobPlanningLinesOnBeforeInsertJobPlanningLine(var JobPlanningLineArchive: Record "Job Planning Line Archive"; var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreJobOnBeforeInsertJob(JobArchive: Record "Job Archive"; var Job: Record Job)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnStoreJobOnBeforeStoreJobTaskAndJobPlanningLine(var JobTask: Record "Job Task"; var JobPlanningLine: Record "Job Planning Line"; var Job: Record Job)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteJobTasks(var JobTask: Record "Job Task"; var JobTaskDimension: Record "Job Task Dimension"; var JobPlanningLine: Record "Job Planning Line"; var JobArchive: Record "Job Archive"; Job: Record Job)
    begin
    end;
}

