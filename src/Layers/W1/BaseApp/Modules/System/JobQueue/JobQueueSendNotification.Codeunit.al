namespace System.Threading;

using System;
using System.Environment.Configuration;
using System.Utilities;

codeunit 454 "Job Queue - Send Notification"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        RecordLink: Record "Record Link";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRun(Rec, RecordLink, IsHandled);
        if not IsHandled then begin
            RecordLink."Link ID" := 0;
            RecordLink."Record ID" := Rec.RecordId();
            if Rec.Status = Rec.Status::Error then
                RecordLink.Description := CopyStr(Rec."Error Message", 1, MaxStrLen(RecordLink.Description))
            else
                RecordLink.Description := Rec.Description;
            SetURL(Rec, RecordLink);
            RecordLink.Type := RecordLink.Type::Note;
            RecordLink.Created := CurrentDateTime();
            RecordLink."User ID" := UserId();
            RecordLink.Company := CompanyName();
            RecordLink.Notify := true;
            RecordLink."To User ID" := Rec."User ID";
            SetText(Rec, RecordLink);
            RecordLink.Insert();
        end;

        OnAfterRun(Rec, RecordLink);
    end;

    var
        ErrorWhenProcessingTxt: Label 'Error when processing ''%1''.', Comment = '%1 = Job queue entry description';
        ErrorMessageLabelTxt: Label 'Error message:';
        JobQueueFinishedTxt: Label '''%1'' finished successfully.', Comment = '%1 = job description, e.g. ''Post Sales Order 1234''';
        JobQueueFailedNotificationIdTxt: Label '9a3203a3-35a5-4598-941b-2d6c9f08b9bf', Locked = true;
        JobQueueSingleTaskFailedMsg: Label 'The Job "%1" scheduled by %2 experienced an issue.', Comment = '%1=Job Queue Entry description, %2 = User Id';
        JobQueueMultipleTaskFailedMsg: Label 'There are %1 scheduled jobs experiencing an issue.', Comment = '%1=Failed job count';
        JobQueueFailedNotificationDescLbl: Label 'This notification is sent when one or more jobs in the job queue fail.';
        JobQueueSingleTaskFailedRestartJobActionLbl: Label 'Restart failed job';
        JobQueueFailedShowMoreDetailActionLbl: Label 'Show more details';
        JobQueueFailedDisableActionLbl: Label 'Don''t show again';
        CannotRestartFailedJobErr: Label 'Cannot restart the failed job because the job queue entry cannot be found.';
        CannotShowMoreDetailErr: Label 'Cannot show more details for this failed job because the job queue entry cannot be found.';

    internal procedure SendNotificationWhenJobFailed()
    var
        JobQueueEntry: Record "Job Queue Entry";
        MyNotifications: Record "My Notifications";
        JobQueueFailedNotificationSetup: Record "Job Queue Notification Setup";
        JobQueueMgt: Codeunit "Job Queue Management";
        PageMyNotifications: Page "My Notifications";
        JobFailedCount: Integer;
    begin
        if JobQueueFailedNotificationSetup.IsEmpty() then
            JobQueueFailedNotificationSetup.Insert();
        JobQueueFailedNotificationSetup.FindLast();

        if not JobQueueFailedNotificationSetup.InProductNotification then
            exit;

        if not MyNotifications.Get(UserId, JobQueueFailedNotificationIdTxt) then
            PageMyNotifications.InitializeNotificationsWithDefaultState();
        if not MyNotifications.IsEnabled(JobQueueFailedNotificationIdTxt) then
            exit;

        if JobQueueFailedNotificationSetup.NotifyUserInitiatingTask and JobQueueFailedNotificationSetup.NotifyJobQueueAdmin then begin
            if not JobQueueMgt.CheckUserInJobQueueAdminList(UserId()) then
                JobQueueEntry.SetRange("User ID", UserId());
        end else
            if JobQueueFailedNotificationSetup.NotifyUserInitiatingTask then
                JobQueueEntry.SetRange("User ID", UserId())
            else
                if JobQueueFailedNotificationSetup.NotifyJobQueueAdmin then begin
                    if not JobQueueMgt.CheckUserInJobQueueAdminList(UserId()) then
                        exit;
                end else
                    exit;

        JobQueueEntry.SetRange(Status, JobQueueEntry.Status::Error);

        if JobQueueEntry.IsEmpty() then
            exit;

        JobFailedCount := JobQueueEntry.Count;
        JobQueueEntry.FindSet();

        if JobQueueFailedNotificationSetup.NotifyWhenJobFailed then
            SendFailedJobNotification(JobQueueEntry, JobFailedCount)
        else
            if JobQueueFailedNotificationSetup.NotifyAfterThreshold then
                if JobFailedCount >= JobQueueFailedNotificationSetup.Threshold1 then
                    SendFailedJobNotification(JobQueueEntry, JobFailedCount);
    end;

    local procedure SendFailedJobNotification(var JobQueueEntry: Record "Job Queue Entry"; JobFailedCount: Integer)
    var
        JobFailedNotification: Notification;
    begin
        JobFailedNotification.Id := JobQueueFailedNotificationIdTxt;
        JobFailedNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
        if JobFailedCount = 1 then begin
            JobFailedNotification.Message := StrSubstNo(JobQueueSingleTaskFailedMsg, JobQueueEntry.Description, JobQueueEntry."User ID");
            JobFailedNotification.AddAction(JobQueueSingleTaskFailedRestartJobActionLbl, CODEUNIT::"Job Queue - Send Notification", 'RestartFailedJob');
            JobFailedNotification.AddAction(JobQueueFailedShowMoreDetailActionLbl, CODEUNIT::"Job Queue - Send Notification", 'ShowMoreDetailForSingleFailedJob');
            JobFailedNotification.AddAction(JobQueueFailedDisableActionLbl, CODEUNIT::"Job Queue - Send Notification", 'DisableNotification');
            JobFailedNotification.SetData('JobQueueEntryId', Format(JobQueueEntry.ID));
            JobFailedNotification.Send();
        end else begin
            JobFailedNotification.Message := StrSubstNo(JobQueueMultipleTaskFailedMsg, JobFailedCount);
            JobFailedNotification.AddAction(JobQueueFailedShowMoreDetailActionLbl, CODEUNIT::"Job Queue - Send Notification", 'ShowMoreDetailForMultipleFailedJobs');
            JobFailedNotification.AddAction(JobQueueFailedDisableActionLbl, CODEUNIT::"Job Queue - Send Notification", 'DisableNotification');
            JobFailedNotification.Send();
        end;
    end;

    internal procedure GetJobQueueFailedNotificationId(): Guid
    begin
        exit(JobQueueFailedNotificationIdTxt);
    end;

    internal procedure GetJobQueueSingleTaskFailedMsg(): Text
    begin
        exit(JobQueueSingleTaskFailedMsg);
    end;

    internal procedure GetJobQueueMultipleTaskFailedMsg(): Text
    begin
        exit(JobQueueMultipleTaskFailedMsg);
    end;

    internal procedure RestartFailedJob(JobFailedNotification: Notification)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if JobQueueEntry.Get(JobFailedNotification.GetData('JobQueueEntryId')) then
            JobQueueEntry.Restart()
        else
            Error(CannotRestartFailedJobErr);
    end;

    internal procedure ShowMoreDetailForSingleFailedJob(JobFailedNotification: Notification)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if JobQueueEntry.Get(JobFailedNotification.GetData('JobQueueEntryId')) then
            Page.Run(Page::"Job Queue Entry Card", JobQueueEntry)
        else
            Error(CannotShowMoreDetailErr);
    end;

    internal procedure ShowMoreDetailForMultipleFailedJobs(JobFailedNotification: Notification)
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueMgt: Codeunit "Job Queue Management";
    begin
        if not JobQueueMgt.CheckUserInJobQueueAdminList(UserId()) then
            JobQueueEntry.SetRange("User ID", UserId());
        JobQueueEntry.SetRange(Status, JobQueueEntry.Status::Error);
        Page.Run(Page::"Job Queue Entries", JobQueueEntry);
    end;

    internal procedure DisableNotification(JobFailedNotification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.Disable(JobQueueFailedNotificationIdTxt);
    end;

    [EventSubscriber(ObjectType::Page, Page::"My Notifications", 'OnInitializingNotificationWithDefaultState', '', false, false)]
    local procedure OnInitializingNotificationWithDefaultState()
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(JobQueueFailedNotificationIdTxt, 'Job Queue Failed Notification', JobQueueFailedNotificationDescLbl, true);
    end;

    procedure SetJobQueueEntryStatusToOnHold(ModifyOnlyWhenReadOnlyNotification: Notification)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if not ModifyOnlyWhenReadOnlyNotification.HasData(JobQueueEntry.FieldName(ID)) then
            exit;

        if JobQueueEntry.Get(ModifyOnlyWhenReadOnlyNotification.GetData(JobQueueEntry.FieldName(ID))) then
            JobQueueEntry.SetStatus(JobQueueEntry.Status::"On Hold");
    end;

    local procedure SetURL(var JobQueueEntry: Record "Job Queue Entry"; var RecordLink: Record "Record Link")
    var
        Link: Text;
    begin
        // Generates a URL such as dynamicsnav://host:port/instance/company/runpage?page=672&$filter=
        // The intent is to open up the Job Queue Entries page and show the list of "my errors".
        // TODO: Leverage parameters ",JobQueueEntry,TRUE)" to take into account the filters, which will add the
        // following to the Url: &$filter=JobQueueEntry.Status IS 2 AND JobQueueEntry."User ID" IS <UserID>.
        // This will also require setting the filters on the record, such as:
        // SETFILTER(Status,'=2');
        // SETFILTER("User ID",'=%1',"User ID");
        Link := GetUrl(DefaultClientType, CompanyName, OBJECTTYPE::Page, PAGE::"Job Queue Entries") +
          StrSubstNo('&$filter=''%1''.''%2''%20IS%20''2''%20AND%20''%1''.''%3''%20IS%20''%4''&mode=View',
            HtmlEncode(JobQueueEntry.TableName), HtmlEncode(JobQueueEntry.FieldName(Status)), HtmlEncode(JobQueueEntry.FieldName("User ID")), HtmlEncode(JobQueueEntry."User ID"));

        RecordLink.URL1 := CopyStr(Link, 1, MaxStrLen(RecordLink.URL1));
    end;

    local procedure SetText(var JobQueueEntry: Record "Job Queue Entry"; var RecordLink: Record "Record Link")
    var
        RecordLinkManagement: Codeunit "Record Link Management";
        s: Text;
        lf: Text;
        c1: Byte;
    begin
        c1 := 13;
        lf[1] := c1;

        if JobQueueEntry.Status = JobQueueEntry.Status::Error then
            s := StrSubstNo(ErrorWhenProcessingTxt, JobQueueEntry.Description) + lf + ErrorMessageLabelTxt + ' ' + JobQueueEntry."Error Message"
        else
            s := StrSubstNo(JobQueueFinishedTxt, JobQueueEntry.Description);

        RecordLinkManagement.WriteNote(RecordLink, s);
    end;

    local procedure HtmlEncode(InText: Text[1024]): Text[1024]
    var
        SystemWebHttpUtility: DotNet HttpUtility;
    begin
        SystemWebHttpUtility := SystemWebHttpUtility.HttpUtility();
        exit(SystemWebHttpUtility.HtmlEncode(InText));
    end;


    [IntegrationEvent(false, false)]
    local procedure OnAfterRun(JobQueueEntry: Record "Job Queue Entry"; RecordLink: Record "Record Link")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var JobQueueEntry: Record "Job Queue Entry"; var RecordLink: Record "Record Link"; var IsHandled: Boolean)
    begin
    end;
}

