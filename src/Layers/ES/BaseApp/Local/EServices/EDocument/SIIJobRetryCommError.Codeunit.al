// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

codeunit 10754 "SII Job Retry Comm. Error"
{

    trigger OnRun()
    begin
        HandleCommunicationErrorDocuments();
    end;

    var
        SIIJobManagement: Codeunit "SII Job Management";
        JobType: Option HandlePending,HandleCommError,InitialUpload;

    local procedure HandleCommunicationErrorDocuments()
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        SIIDocUploadState.CreateCommunicationErrorRetries();
        SIIJobManagement.RenewJobQueueEntry(JobType::HandlePending);
    end;

    [Scope('OnPrem')]
    procedure ScheduleJobForRetry()
    begin
        SIIJobManagement.RenewJobQueueEntry(JobType::HandleCommError);
    end;
}

