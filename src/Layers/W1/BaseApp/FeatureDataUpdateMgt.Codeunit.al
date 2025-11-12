// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment.Configuration;

using System.Threading;

codeunit 2614 "Feature Data Update Mgt."
{
    local procedure ShowTaskLog(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        JobQueueLogEntry.SetRange(ID, FeatureDataUpdateStatus."Task ID");
        PAGE.RunModal(PAGE::"Job Queue Log Entries", JobQueueLogEntry);
    end;

    local procedure LogError(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        JobQueueLogEntry.Init();
        JobQueueLogEntry."Entry No." := 0;
        JobQueueLogEntry.ID := FeatureDataUpdateStatus."Task ID";
        JobQueueLogEntry."Object Type to Run" := JobQueueLogEntry."Object Type to Run"::Codeunit;
        JobQueueLogEntry."Object ID to Run" := CODEUNIT::"Update Feature Data";
        JobQueueLogEntry.Description := FeatureDataUpdateStatus."Feature Key";
        JobQueueLogEntry.Status := JobQueueLogEntry.Status::Error;
        JobQueueLogEntry."Error Message" := CopyStr(GetLastErrorText(), 1, MaxStrLen(JobQueueLogEntry."Error Message"));
        JobQueueLogEntry.SetErrorCallStack(GetLastErrorCallstack());
        JobQueueLogEntry."Start Date/Time" := FeatureDataUpdateStatus."Start Date/Time";
        JobQueueLogEntry."End Date/Time" := CurrentDateTime;
        JobQueueLogEntry."User ID" := CopyStr(UserId, 1, MaxStrLen(JobQueueLogEntry."User ID"));
        JobQueueLogEntry.Insert(true);
    end;

    procedure LogTask(FeatureDataUpdateStatus: Record "Feature Data Update Status"; Description: Text; StartDateTime: DateTime)
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        JobQueueLogEntry.Init();
        JobQueueLogEntry."Entry No." := 0;
        JobQueueLogEntry.ID := FeatureDataUpdateStatus."Task ID";
        JobQueueLogEntry."Object Type to Run" := JobQueueLogEntry."Object Type to Run"::Codeunit;
        JobQueueLogEntry."Object ID to Run" := CODEUNIT::"Update Feature Data";
        if Description = '' then
            JobQueueLogEntry.Description := FeatureDataUpdateStatus."Feature Key"
        else
            JobQueueLogEntry.Description := CopyStr(Description, 1, MaxStrLen(JobQueueLogEntry.Description));
        JobQueueLogEntry.Status := JobQueueLogEntry.Status::Success;
        JobQueueLogEntry."Start Date/Time" := StartDateTime;
        JobQueueLogEntry."End Date/Time" := CurrentDateTime();
        JobQueueLogEntry."User ID" := CopyStr(UserId, 1, MaxStrLen(JobQueueLogEntry."User ID"));
        JobQueueLogEntry.Insert(true);
    end;

    procedure FeatureKeyMatches(FeatureDataUpdateStatus: Record "Feature Data Update Status"; FeatureToUpdate: Enum "Feature To Update"): Boolean
    begin
        if FeatureToUpdate.Names.Contains(FeatureDataUpdateStatus."Feature Key") then
            exit(FeatureToUpdate.AsInteger() =
                FeatureToUpdate.Ordinals.Get(FeatureToUpdate.Names.IndexOf(FeatureDataUpdateStatus."Feature Key")));
        exit(false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Feature Management Facade", 'OnGetImplementation', '', false, false)]
    local procedure OnGetImplementation(FeatureDataUpdateStatus: Record "Feature Data Update Status"; var FeatureDataUpdate: Interface "Feature Data Update"; var ImplementedId: Text[50]);
    var
        FeatureToUpdate: Enum "Feature To Update";
    begin
        if FeatureToUpdate.Names.Contains(FeatureDataUpdateStatus."Feature Key") then begin
            FeatureToUpdate :=
                "Feature To Update".FromInteger(
                    FeatureToUpdate.Ordinals.Get(FeatureToUpdate.Names.IndexOf(FeatureDataUpdateStatus."Feature Key")));
            FeatureDataUpdate := FeatureToUpdate;
            ImplementedId := FeatureDataUpdateStatus."Feature Key";
        end else
            ImplementedId := '';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Feature Data Error Handler", 'OnLogError', '', false, false)]
    local procedure LogErrorHandler(FeatureDataUpdateStatus: Record "Feature Data Update Status");
    begin
        LogError(FeatureDataUpdateStatus);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Feature Management Facade", 'OnShowTaskLog', '', false, false)]
    local procedure OnShowTaskLog(FeatureDataUpdateStatus: Record "Feature Data Update Status");
    begin
        ShowTaskLog(FeatureDataUpdateStatus);
    end;
}
