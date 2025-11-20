// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using System.Threading;

codeunit 485 "Change Global Dim Err. Handler"
{
    TableNo = "Change Global Dim. Log Entry";

    trigger OnRun()
    begin
        Rec.LockTable();
        if not Rec.Get(Rec."Table ID") then
            exit;
        Rec.Status := Rec.Status::Incomplete;
        Rec."Session ID" := -1;
        Rec."Server Instance ID" := -1;
        Rec.Modify();
        LogError(Rec);
        Rec.SendTraceTagOnError();
    end;

    local procedure LogError(ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry")
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        JobQueueLogEntry.Init();
        JobQueueLogEntry."Entry No." := 0;
        JobQueueLogEntry.ID := ChangeGlobalDimLogEntry."Task ID";
        JobQueueLogEntry."Object Type to Run" := JobQueueLogEntry."Object Type to Run"::Codeunit;
        JobQueueLogEntry."Object ID to Run" := CODEUNIT::"Change Global Dimensions";
        JobQueueLogEntry.Description := ChangeGlobalDimLogEntry."Table Name";
        JobQueueLogEntry.Status := JobQueueLogEntry.Status::Error;
        JobQueueLogEntry."Error Message" := GetLastErrorText;
        JobQueueLogEntry.SetErrorCallStack(GetLastErrorCallstack);
        JobQueueLogEntry."Start Date/Time" := CurrentDateTime;
        JobQueueLogEntry."End Date/Time" := JobQueueLogEntry."Start Date/Time";
        JobQueueLogEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(JobQueueLogEntry."User ID"));
        JobQueueLogEntry.Insert(true);
    end;
}

