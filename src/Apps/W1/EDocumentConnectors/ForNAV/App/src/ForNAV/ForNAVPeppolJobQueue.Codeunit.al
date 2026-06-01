// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.ForNAV;

using System.Security.User;
using System.Threading;

codeunit 6412 "ForNAV Peppol Job Queue"
{
    Access = Internal;
    trigger OnRun()
    begin
        ProcessEntries();
    end;

    local procedure ProcessEntries()
    var
        Setup: Record "ForNAV Peppol Setup";
        JobQueueEntry: Record "Job Queue Entry";
        Enqueue: Codeunit "Job Queue - Enqueue";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Job Queue Category Code", Setup.GetForNAVCode());
        JobQueueEntry.SetRange(Status, JobQueueEntry.Status::"On Hold");
        JobQueueEntry.SetFilter(Status, '', JobQueueEntry.Status::"On Hold", JobQueueEntry.Status::Ready, JobQueueEntry.Status::Waiting, JobQueueEntry.Status::Error);
        if JobQueueEntry.FindSet() then
            repeat
                case JobQueueEntry.Status of
                    JobQueueEntry.Status::Error:
                        JobQueueEntry.Restart();
                    else
                        Enqueue.Run(JobQueueEntry);
                end;
            until JobQueueEntry.Next() = 0;
    end;

    internal procedure SetupJobQueue()
    begin
        SetupJobQueueCategory();
        SetupJobQueueEntry();
    end;

    local procedure SetupJobQueueCategory()
    var
        Setup: Record "ForNAV Peppol Setup";
        JobQueueCategory: Record "Job Queue Category";
        JobQueueDescriptionLbl: Label 'ForNAV Job Queue';
    begin
        if JobQueueCategory.Get(Setup.GetForNAVCode()) then
            exit;

        JobQueueCategory.Code := Setup.GetForNAVCode();
        JobQueueCategory.Description := CopyStr(JobQueueDescriptionLbl, 1, MaxStrLen(JobQueueCategory.Description));
        JobQueueCategory.Insert();
    end;

    local procedure SetupJobQueueEntry()
    var
        Setup: Record "ForNAV Peppol Setup";
        JobQueueEntry: Record "Job Queue Entry";
        Enqueue: Codeunit "Job Queue - Enqueue";
        JobQueueDescriptionLbl: Label 'Used by ForNAV to process incoming e-documents';
    begin
        JobQueueEntry.SetRange("Job Queue Category Code", Setup.GetForNAVCode());
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"ForNAV Peppol Job Queue");
        if JobQueueEntry.FindFirst() then begin
            Enqueue.Run(JobQueueEntry);
            exit;
        end;

        JobQueueEntry."Object ID to Run" := Codeunit::"ForNAV Peppol Job Queue";
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Job Queue Category Code" := Setup.GetForNAVCode();
        JobQueueEntry.Description := CopyStr(JobQueueDescriptionLbl, 1, MaxStrLen(JobQueueEntry.Description));
        JobQueueEntry.Validate("Run on Mondays", true);
        JobQueueEntry.Validate("Run on Tuesdays", true);
        JobQueueEntry.Validate("Run on Wednesdays", true);
        JobQueueEntry.Validate("Run on Thursdays", true);
        JobQueueEntry.Validate("Run on Fridays", true);
        JobQueueEntry.Validate("Run on Saturdays", true);
        JobQueueEntry.Validate("Run on Sundays", true);

        JobQueueEntry."No. of Minutes between Runs" := 30;
        Enqueue.Run(JobQueueEntry);
    end;

    procedure ProcessEntriesIfSuper()
    var
        UserPermissions: Codeunit "User Permissions";
    begin
        if UserPermissions.IsSuper(UserSecurityId()) then begin
            ProcessEntries();
            SelectLatestVersion();
        end;
    end;
}
