namespace System.Threading;
using System.IO;
using System.Telemetry;

codeunit 9803 "Job Queue Telemetry"
{
    Access = Internal;
    SingleInstance = true;

    var
        Telemetry: Codeunit Telemetry;
        JobQueueEntriesCategoryTxt: Label 'AL JobQueueEntries', Locked = true;
        JobQueueEntryTaskCancelledTxt: Label 'Job queue entry task cancelled: %1', Comment = '%1 = Job queue id', Locked = true;
        ReusingExistingJobFromIdTxt: Label 'Reusing Job Queue', Locked = true;
        JobQueueEntryFinishedTxt: Label 'JobID = %1, ObjectType = %2, ObjectID = %3, Status = Finished, Result = %4, Company = %5, Scheduled Task Id = %6', Locked = true;
        JobQueueEntryStartedAllTxt: Label 'Job queue entry started: %1', Comment = '%1 = Job queue id', Locked = true;
        JobQueueEntryFinishedAllTxt: Label 'Job queue entry finished: %1', Comment = '%1 = Job queue id', Locked = true;
        JobQueueEntryErrorTxt: Label 'Job queue entry %1 errored after %2 attempts', Comment = '%1 = Job queue id, %2 = Number of attempts', Locked = true;
        JobQueueEntryErrorAllTxt: Label 'Job queue entry errored: %1', Comment = '%1 = Job queue id', Locked = true;
        JobQueueEntryEnqueuedAllTxt: Label 'Job queue entry enqueued: %1', Comment = '%1 = Job queue id', Locked = true;
        JobQueueEntryNotEnqueuedTxt: Label 'Job queue entry not enqueued: %1', Comment = '%1 = Job queue id', Locked = true;
        JobQueueEntrySkippedTxt: Label 'Job queue entry skipped: %1', Comment = '%1 = Job queue id', Locked = true;
        JobQueueEntryNotReadyToStartTxt: Label 'Job queue entry not ready to start: %1', Comment = '%1 = Job queue id', Locked = true;
        JobQueueEntryExpiredTxt: Label 'Job queue entry expired: %1', Comment = '%1 = Job queue id', Locked = true;
        JobQueueEntryRescheduledDueToStartEndTimeTxt: Label 'Job queue entry rescheduled due to start/end time: %1', Comment = '%1 = Job queue id', Locked = true;
        JobQueueEntryRescheduledAsWaitingTxt: Label 'Job queue entry rescheduled as waiting: %1', Comment = '%1 = Job queue id', Locked = true;
        NextWaitingJobQueueEntryActivatedTxt: Label 'Next waiting Job queue entry activated: %1', Comment = '%1 = Job queue id', Locked = true;

    procedure SetJobQueueTelemetryDimensions(var JobQueueEntry: Record "Job Queue Entry"; var Dimensions: Dictionary of [Text, Text])
    begin
        JobQueueEntry.CalcFields("Object Caption to Run");
        Dimensions.Add('Category', JobQueueEntriesCategoryTxt);
        Dimensions.Add('JobQueueId', Format(JobQueueEntry.ID, 0, 4));
        Dimensions.Add('JobQueueObjectName', Format(JobQueueEntry."Object Caption to Run"));
        Dimensions.Add('JobQueueObjectDescription', Format(JobQueueEntry.Description));
        Dimensions.Add('JobQueueObjectType', Format(JobQueueEntry."Object Type to Run"));
        Dimensions.Add('JobQueueObjectId', Format(JobQueueEntry."Object ID to Run"));
        Dimensions.Add('JobQueueStatus', Format(JobQueueEntry.Status));
        Dimensions.Add('JobQueueIsRecurring', Format(JobQueueEntry."Recurring Job"));
        Dimensions.Add('JobQueueEarliestStartDateTime', Format(JobQueueEntry."Earliest Start Date/Time", 0, 9)); // UTC time
        Dimensions.Add('JobQueueCompanyName', JobQueueEntry.CurrentCompany());
        Dimensions.Add('JobQueueScheduledTaskId', Format(JobQueueEntry."System Task ID", 0, 4));
        Dimensions.Add('JobQueueMaxNumberOfAttemptsToRun', Format(JobQueueEntry."Maximum No. of Attempts to Run"));
        Dimensions.Add('JobQueueNumberOfAttemptsToRun', Format(JobQueueEntry."No. of Attempts to Run"));
        Dimensions.Add('JobQueueCategory', Format(JobQueueEntry."Job Queue Category Code"));
        if JobQueueEntry."Starting Time" <> 0T then
            Dimensions.Add('JobQueueStartTime', Format(JobQueueEntry."Starting Time"));
        if JobQueueEntry."Ending Time" <> 0T then
            Dimensions.Add('JobQueueEndTime', Format(JobQueueEntry."Ending Time"));
    end;

    procedure SetJobQueueTelemetryDimensions(var JobQueueLogEntry: Record "Job Queue Log Entry"; var Dimensions: Dictionary of [Text, Text])
    begin
        JobQueueLogEntry.CalcFields("Object Caption to Run");
        Dimensions.Add('Category', JobQueueEntriesCategoryTxt);
        Dimensions.Add('JobQueueId', Format(JobQueueLogEntry.ID, 0, 4));
        Dimensions.Add('JobQueueObjectName', Format(JobQueueLogEntry."Object Caption to Run"));
        Dimensions.Add('JobQueueObjectDescription', Format(JobQueueLogEntry.Description));
        Dimensions.Add('JobQueueObjectType', Format(JobQueueLogEntry."Object Type to Run"));
        Dimensions.Add('JobQueueObjectId', Format(JobQueueLogEntry."Object ID to Run"));
        Dimensions.Add('JobQueueStatus', Format(JobQueueLogEntry.Status));
        Dimensions.Add('JobQueueEarliestStartDateTime', Format(JobQueueLogEntry."Start Date/Time", 0, 9)); // UTC time
        Dimensions.Add('JobQueueCompanyName', JobQueueLogEntry.CurrentCompany());
        Dimensions.Add('JobQueueScheduledTaskId', Format(JobQueueLogEntry."System Task ID", 0, 4));
        Dimensions.Add('JobQueueCategory', Format(JobQueueLogEntry."Job Queue Category Code"));
    end;

    procedure SendJobQueueSkippedTelemetry(var JobQueueEntry: Record "Job Queue Entry")
    var
        TranslationHelper: Codeunit "Translation Helper";
        Dimensions: Dictionary of [Text, Text];
    begin
        TranslationHelper.SetGlobalLanguageToDefault();

        SetJobQueueTelemetryDimensions(JobQueueEntry, Dimensions);
        Telemetry.LogMessage('0000P8K',
                                StrSubstNo(JobQueueEntrySkippedTxt, Format(JobQueueEntry.ID, 0, 4)),
                                Verbosity::Normal,
                                DataClassification::OrganizationIdentifiableInformation,
                                TelemetryScope::All,
                                Dimensions);

        TranslationHelper.RestoreGlobalLanguage();
    end;

    procedure SendJobQueueNotReadyToStartTelemetry(var JobQueueEntry: Record "Job Queue Entry")
    var
        TranslationHelper: Codeunit "Translation Helper";
        Dimensions: Dictionary of [Text, Text];
    begin
        TranslationHelper.SetGlobalLanguageToDefault();

        SetJobQueueTelemetryDimensions(JobQueueEntry, Dimensions);
        Telemetry.LogMessage('0000P8L',
                                StrSubstNo(JobQueueEntryNotReadyToStartTxt, Format(JobQueueEntry.ID, 0, 4)),
                                Verbosity::Normal,
                                DataClassification::OrganizationIdentifiableInformation,
                                TelemetryScope::All,
                                Dimensions);

        TranslationHelper.RestoreGlobalLanguage();
    end;

    procedure SendJobQueueRescheduledDueToStartEndTimeTelemetry(var JobQueueEntry: Record "Job Queue Entry")
    var
        TranslationHelper: Codeunit "Translation Helper";
        Dimensions: Dictionary of [Text, Text];
    begin
        TranslationHelper.SetGlobalLanguageToDefault();

        SetJobQueueTelemetryDimensions(JobQueueEntry, Dimensions);
        Telemetry.LogMessage('0000P9D',
                                StrSubstNo(JobQueueEntryRescheduledDueToStartEndTimeTxt, Format(JobQueueEntry.ID, 0, 4)),
                                Verbosity::Normal,
                                DataClassification::OrganizationIdentifiableInformation,
                                TelemetryScope::All,
                                Dimensions);

        TranslationHelper.RestoreGlobalLanguage();
    end;

    procedure SendJobQueueExpiredTelemetry(var JobQueueEntry: Record "Job Queue Entry")
    var
        TranslationHelper: Codeunit "Translation Helper";
        Dimensions: Dictionary of [Text, Text];
    begin
        TranslationHelper.SetGlobalLanguageToDefault();

        SetJobQueueTelemetryDimensions(JobQueueEntry, Dimensions);
        Telemetry.LogMessage('0000P9E',
                                StrSubstNo(JobQueueEntryExpiredTxt, Format(JobQueueEntry.ID, 0, 4)),
                                Verbosity::Normal,
                                DataClassification::OrganizationIdentifiableInformation,
                                TelemetryScope::All,
                                Dimensions);

        TranslationHelper.RestoreGlobalLanguage();
    end;

    procedure SendJobQueueRescheduleAsWaitingTelemetry(var JobQueueEntry: Record "Job Queue Entry")
    var
        TranslationHelper: Codeunit "Translation Helper";
        Dimensions: Dictionary of [Text, Text];
    begin
        TranslationHelper.SetGlobalLanguageToDefault();

        SetJobQueueTelemetryDimensions(JobQueueEntry, Dimensions);
        Telemetry.LogMessage('0000P9F',
                                StrSubstNo(JobQueueEntryRescheduledAsWaitingTxt, Format(JobQueueEntry.ID, 0, 4)),
                                Verbosity::Normal,
                                DataClassification::OrganizationIdentifiableInformation,
                                TelemetryScope::All,
                                Dimensions);

        TranslationHelper.RestoreGlobalLanguage();
    end;

    procedure SendWaitingJobQueueActivatedTelemetry(var JobQueueEntry: Record "Job Queue Entry")
    var
        TranslationHelper: Codeunit "Translation Helper";
        Dimensions: Dictionary of [Text, Text];
    begin
        TranslationHelper.SetGlobalLanguageToDefault();

        SetJobQueueTelemetryDimensions(JobQueueEntry, Dimensions);
        Telemetry.LogMessage('0000P9G',
                                StrSubstNo(NextWaitingJobQueueEntryActivatedTxt, Format(JobQueueEntry.ID, 0, 4)),
                                Verbosity::Normal,
                                DataClassification::OrganizationIdentifiableInformation,
                                TelemetryScope::All,
                                Dimensions);

        TranslationHelper.RestoreGlobalLanguage();
    end;

    internal procedure SendTraceOnJobQueueEntryScheduledTaskCancelled(var JobQueueEntry: Record "Job Queue Entry"; Success: Boolean)
    var
        TranslationHelper: Codeunit "Translation Helper";
        Dimensions: Dictionary of [Text, Text];
    begin
        TranslationHelper.SetGlobalLanguageToDefault();

        SetJobQueueTelemetryDimensions(JobQueueEntry, Dimensions);
        Dimensions.Add('JobQueueScheduledTaskExistedOnCancel', Format(Success));
        Telemetry.LogMessage('0000KZV',
                                StrSubstNo(JobQueueEntryTaskCancelledTxt, Format(JobQueueEntry.ID, 0, 4)),
                                Verbosity::Normal,
                                DataClassification::OrganizationIdentifiableInformation,
                                TelemetryScope::All,
                                Dimensions);

        TranslationHelper.RestoreGlobalLanguage();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnReuseExisingJobFromId', '', false, false)]
    local procedure EmitTelemetryOnReuseExisingJobFromId(JobQueueEntry: Record "Job Queue Entry"; ExecutionDateTime: DateTime)
    var
        TranslationHelper: Codeunit "Translation Helper";
        Dimensions: Dictionary of [Text, Text];
    begin
        TranslationHelper.SetGlobalLanguageToDefault();

        SetJobQueueTelemetryDimensions(JobQueueEntry, Dimensions);
        Dimensions.Add('JobQueueProposedExecutionDateTime', Format(ExecutionDateTime));
        Telemetry.LogMessage('0000F6B',
                                ReusingExistingJobFromIdTxt,
                                Verbosity::Normal,
                                DataClassification::OrganizationIdentifiableInformation,
                                TelemetryScope::ExtensionPublisher,
                                Dimensions);

        TranslationHelper.RestoreGlobalLanguage();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue - Enqueue", 'OnAfterEnqueueJobQueueEntry', '', false, false)]
    local procedure SendTraceOnAfterEnqueueJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry")
    var
        TranslationHelper: Codeunit "Translation Helper";
        Dimensions: Dictionary of [Text, Text];
    begin
        TranslationHelper.SetGlobalLanguageToDefault();

        SetJobQueueTelemetryDimensions(JobQueueEntry, Dimensions);

        if IsNullGuid(JobQueueEntry."System Task ID") then
            Telemetry.LogMessage('0000FNY',
                                    StrSubstNo(JobQueueEntryNotEnqueuedTxt, Format(JobQueueEntry.ID, 0, 4)),
                                    Verbosity::Warning,
                                    DataClassification::OrganizationIdentifiableInformation,
                                    TelemetryScope::All,
                                    Dimensions)
        else
            Telemetry.LogMessage('0000E24',
                                    StrSubstNo(JobQueueEntryEnqueuedAllTxt, Format(JobQueueEntry.ID, 0, 4)),
                                    Verbosity::Normal,
                                    DataClassification::OrganizationIdentifiableInformation,
                                    TelemetryScope::All,
                                    Dimensions);

        TranslationHelper.RestoreGlobalLanguage();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue Dispatcher", 'OnBeforeExecuteJob', '', false, false)]
    local procedure SendTraceOnJobQueueEntryStarted(var JobQueueEntry: Record "Job Queue Entry")
    var
        TranslationHelper: Codeunit "Translation Helper";
        Dimensions: Dictionary of [Text, Text];
    begin
        TranslationHelper.SetGlobalLanguageToDefault();

        SetJobQueueTelemetryDimensions(JobQueueEntry, Dimensions);
        Telemetry.LogMessage('0000E25',
                                StrSubstNo(JobQueueEntryStartedAllTxt, Format(JobQueueEntry.ID, 0, 4)),
                                Verbosity::Normal,
                                DataClassification::OrganizationIdentifiableInformation,
                                TelemetryScope::All,
                                Dimensions);

        TranslationHelper.RestoreGlobalLanguage();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue Dispatcher", 'OnAfterSuccessExecuteJob', '', false, false)]
    local procedure SendTraceOnJobQueueEntryFinishedSuccessfully(var JobQueueEntry: Record "Job Queue Entry")
    var
        TranslationHelper: Codeunit "Translation Helper";
        Dimensions: Dictionary of [Text, Text];
    begin
        TranslationHelper.SetGlobalLanguageToDefault();

        SetJobQueueTelemetryDimensions(JobQueueEntry, Dimensions);
        // Job has finished but JQE does not update to finished status when it does (By design)
        Dimensions.Set('JobQueueStatus', Format(JobQueueEntry.Status::Finished));
        Telemetry.LogMessage('000082C',
                                StrSubstNo(JobQueueEntryFinishedTxt, JobQueueEntry.ID, JobQueueEntry."Object Type to Run", JobQueueEntry."Object ID to Run", 'Success', JobQueueEntry.CurrentCompany(), JobQueueEntry."System Task ID"),
                                Verbosity::Normal,
                                DataClassification::OrganizationIdentifiableInformation,
                                TelemetryScope::ExtensionPublisher,
                                Dimensions);

        TranslationHelper.RestoreGlobalLanguage();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue Error Handler", 'OnBeforeLogError', '', false, false)]
    local procedure SendTraceOnJobQueueEntryErrored(var JobQueueLogEntry: Record "Job Queue Log Entry"; var JobQueueEntry: Record "Job Queue Entry")
    var
        TranslationHelper: Codeunit "Translation Helper";
        Dimensions: Dictionary of [Text, Text];
    begin
        TranslationHelper.SetGlobalLanguageToDefault();

        SetJobQueueTelemetryDimensions(JobQueueEntry, Dimensions);
        Dimensions.Add('JobQueueStacktrace', JobQueueLogEntry.GetErrorCallStack());
        Telemetry.LogMessage('0000HE7',
                                StrSubstNo(JobQueueEntryErrorAllTxt, Format(JobQueueEntry.ID, 0, 4)),
                                Verbosity::Warning,
                                DataClassification::OrganizationIdentifiableInformation,
                                TelemetryScope::All,
                                Dimensions);

        TranslationHelper.RestoreGlobalLanguage();
    end;

    internal procedure SendTraceOnJobQueueEntryFinalRunErrored(var JobQueueLogEntry: Record "Job Queue Log Entry"; var JobQueueEntry: Record "Job Queue Entry")
    var
        TranslationHelper: Codeunit "Translation Helper";
        Dimensions: Dictionary of [Text, Text];
    begin
        TranslationHelper.SetGlobalLanguageToDefault();

        SetJobQueueTelemetryDimensions(JobQueueEntry, Dimensions);
        Dimensions.Add('JobQueueStacktrace', JobQueueLogEntry.GetErrorCallStack());
        Telemetry.LogMessage('0000JRG',
                                StrSubstNo(JobQueueEntryErrorTxt, Format(JobQueueEntry.ID, 0, 4), Format(JobQueueEntry."No. of Attempts to Run")),
                                Verbosity::Warning,
                                DataClassification::OrganizationIdentifiableInformation,
                                TelemetryScope::All,
                                Dimensions);

        TranslationHelper.RestoreGlobalLanguage();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue Dispatcher", 'OnAfterSuccessHandleRequest', '', false, false)]
    local procedure SendTraceOnJobQueueEntryRequestFinishedSuccessfully(var JobQueueEntry: Record "Job Queue Entry"; JobQueueExecutionTime: Integer; PreviousTaskId: Guid)
    var
        TranslationHelper: Codeunit "Translation Helper";
        Dimensions: Dictionary of [Text, Text];
    begin
        TranslationHelper.SetGlobalLanguageToDefault();

        SetJobQueueTelemetryDimensions(JobQueueEntry, Dimensions);
        Dimensions.Add('JobQueueExecutionTimeInMs', Format(JobQueueExecutionTime));
        Dimensions.Set('JobQueueScheduledTaskId', Format(PreviousTaskId, 0, 4));
        Dimensions.Add('JobQueueNextScheduledTaskId', Format(JobQueueEntry."System Task ID", 0, 4));
        Telemetry.LogMessage('0000E26',
                                StrSubstNo(JobQueueEntryFinishedAllTxt, Format(JobQueueEntry.ID, 0, 4)),
                                Verbosity::Normal,
                                DataClassification::OrganizationIdentifiableInformation,
                                TelemetryScope::All,
                                Dimensions);

        TranslationHelper.RestoreGlobalLanguage();
    end;
}
