namespace System.Environment.Configuration;

using System.Azure.Identity;
using System.Security.User;
using System.Reflection;
using System.Threading;

table 1513 "Notification Schedule"
{
    Caption = 'Notification Schedule';
    DrillDownPageID = "Notification Schedule";
    LookupPageID = "Notification Schedule";
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup";
        }
        field(2; "Notification Type"; Enum "Notification Entry Type")
        {
            Caption = 'Notification Type';
        }
        field(3; Recurrence; Enum "Notification Schedule Type")
        {
            Caption = 'Recurrence';
            InitValue = Instantly;
        }
        field(4; Time; Time)
        {
            Caption = 'Time';
            InitValue = 120000T;
        }
        field(5; "Daily Frequency"; Option)
        {
            Caption = 'Daily Frequency';
            InitValue = Weekday;
            OptionCaption = 'Weekday,Daily';
            OptionMembers = Weekday,Daily;

            trigger OnValidate()
            begin
                UpdateDailyFrequency();
            end;
        }
        field(6; Monday; Boolean)
        {
            Caption = 'Monday';
            InitValue = true;
        }
        field(7; Tuesday; Boolean)
        {
            Caption = 'Tuesday';
            InitValue = true;
        }
        field(8; Wednesday; Boolean)
        {
            Caption = 'Wednesday';
            InitValue = true;
        }
        field(9; Thursday; Boolean)
        {
            Caption = 'Thursday';
            InitValue = true;
        }
        field(10; Friday; Boolean)
        {
            Caption = 'Friday';
            InitValue = true;
        }
        field(11; Saturday; Boolean)
        {
            Caption = 'Saturday';
        }
        field(12; Sunday; Boolean)
        {
            Caption = 'Sunday';
        }
        field(13; "Date of Month"; Integer)
        {
            Caption = 'Date of Month';
            MaxValue = 31;
            MinValue = 1;
        }
        field(14; "Monthly Notification Date"; Option)
        {
            Caption = 'Monthly Notification Date';
            OptionCaption = 'First Workday,Last Workday,Custom';
            OptionMembers = "First Workday","Last Workday",Custom;
        }
        field(15; "Last Scheduled Job"; Guid)
        {
            Caption = 'Last Scheduled Job';
            TableRelation = "Job Queue Entry";
        }
    }

    keys
    {
        key(Key1; "User ID", "Notification Type")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if Rec.Recurrence = Rec.Recurrence::Instantly then
            JobQueueEntry.ReuseExistingJobFromUserCategoryCodeunitAndParamString(UserId(), NotifyNowLbl, CODEUNIT::"Notification Entry Dispatcher", '', OneMinuteFromNow())
        else
            JobQueueEntry.ReuseExistingJobFromUserCategoryCodeunitAndParamString(UserId(), NotifyLaterLbl, CODEUNIT::"Notification Entry Dispatcher", '', OneMinuteFromNow());
    end;

    trigger OnModify()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if Rec.Recurrence = Rec.Recurrence::Instantly then
            JobQueueEntry.ReuseExistingJobFromUserCategoryCodeunitAndParamString(UserId(), NotifyNowLbl, CODEUNIT::"Notification Entry Dispatcher", '', OneMinuteFromNow())
        else
            JobQueueEntry.ReuseExistingJobFromUserCategoryCodeunitAndParamString(UserId(), NotifyLaterLbl, CODEUNIT::"Notification Entry Dispatcher", '', OneMinuteFromNow());
    end;

    var
        NotifyNowDescriptionTxt: Label 'Instant Notification Job', MaxLength = 30;
        NoPermissionsErr: Label 'You are not allowed to send notifications, but your system administrator can give you permission to do so. Specifically, ask for the %1 for the %2 table.', Comment = '%1 Permission Type; %2 Table Name';
        NotifyNowLbl: Label 'NOTIFYNOW', Locked = true;
        WritePermissionTok: Label 'Insert, Modify, and Delete permissions';
        ReadPermissionTok: Label 'Read Permission';
        NotifyLaterLbl: Label 'NOTIFYLTR', Locked = true;
        NotificationTelemetryCategoryTxt: Label 'Notifications', Locked = true;
        SchedulingNotificationTelemetryTxt: Label 'Scheduling notification', Locked = true;
        ScheduleLaterRecipientIDErr: Label 'Recipient User ID is empty', Locked = true;

    procedure CreateNewRecord(NewUserID: Code[50]; NewNotificationType: Enum "Notification Entry Type")
    begin
        Rec.Init();
        Rec."User ID" := NewUserID;
        Rec."Notification Type" := NewNotificationType;
        Rec.Insert();
    end;

    local procedure UpdateDailyFrequency()
    begin
        Rec.Monday := true;
        Rec.Tuesday := true;
        Rec.Wednesday := true;
        Rec.Thursday := true;
        Rec.Friday := true;
        Rec.Saturday := Rec."Daily Frequency" <> Rec."Daily Frequency"::Weekday;
        Rec.Sunday := Rec."Daily Frequency" <> Rec."Daily Frequency"::Weekday;
    end;

    local procedure GetFirstWorkdateOfMonth(CurrentDate: Date): Date
    var
        Day: Option ,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday;
    begin
        if Date2DWY(CalcDate('<-CM>', CurrentDate), 1) in [Day::Saturday, Day::Sunday] then
            exit(CalcDate('<-CM+WD1>', CurrentDate));

        exit(CalcDate('<-CM>', CurrentDate))
    end;

    local procedure GetScheduledFirstWorkdateOfMonth(CurrentDateTime: DateTime; ScheduledTime: Time) ScheduledDateTime: DateTime
    var
        CurrentDate: Date;
    begin
        CurrentDate := DT2Date(CurrentDateTime);
        ScheduledDateTime := CreateDateTime(GetFirstWorkdateOfMonth(CurrentDate), ScheduledTime);

        if ScheduledDateTime < CurrentDateTime then
            ScheduledDateTime := CreateDateTime(GetFirstWorkdateOfMonth(CalcDate('<+1M>', CurrentDate)), ScheduledTime);
    end;

    local procedure GetLastWorkdateOfMonth(CurrentDate: Date): Date
    var
        Day: Option ,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday;
    begin
        if Date2DWY(CalcDate('<+CM>', CurrentDate), 1) in [Day::Saturday, Day::Sunday] then
            exit(CalcDate('<+CM-WD5>', CurrentDate));

        exit(CalcDate('<+CM>', CurrentDate))
    end;

    local procedure GetScheduledLastWorkdateOfMonth(CurrentDateTime: DateTime; ScheduledTime: Time) ScheduledDateTime: DateTime
    var
        CurrentDate: Date;
    begin
        CurrentDate := DT2Date(CurrentDateTime);
        ScheduledDateTime := CreateDateTime(GetLastWorkdateOfMonth(CurrentDate), ScheduledTime);

        if ScheduledDateTime < CurrentDateTime then
            ScheduledDateTime := CreateDateTime(GetLastWorkdateOfMonth(CalcDate('<+1M>', CurrentDate)), ScheduledTime);
    end;

    local procedure GetLastDateOfMonth(CurrentDate: Date): Date
    begin
        exit(CalcDate('<+CM>', CurrentDate))
    end;

    local procedure GetScheduledCustomWorkdateOfMonth(CurrentDateTime: DateTime; ScheduledTime: Time; ScheduledDay: Integer): DateTime
    var
        CurrentDate: Date;
        CurrentTime: Time;
        CurrentDay: Integer;
        CurrentMonth: Integer;
        CurrentYear: Integer;
    begin
        CurrentDate := DT2Date(CurrentDateTime);
        CurrentTime := DT2Time(CurrentDateTime);
        CurrentDay := Date2DMY(CurrentDate, 1);
        CurrentMonth := Date2DMY(CurrentDate, 2);
        CurrentYear := Date2DMY(CurrentDate, 3);

        if (ScheduledDay = CurrentDay) and (CurrentTime < ScheduledTime) then
            exit(CreateDateTime(DMY2Date(ScheduledDay, CurrentMonth, CurrentYear), ScheduledTime));

        if ScheduledDay <= CurrentDay then begin
            CurrentDate := CalcDate('<+1M>', CurrentDate);
            CurrentMonth := Date2DMY(CurrentDate, 2);
            CurrentYear := Date2DMY(CurrentDate, 3);
        end;

        CurrentDate := GetLastDateOfMonth(CurrentDate);
        if ScheduledDay > Date2DMY(CurrentDate, 1) then
            exit(CreateDateTime(CurrentDate, ScheduledTime));
        exit(CreateDateTime(DMY2Date(ScheduledDay, CurrentMonth, CurrentYear), ScheduledTime))
    end;

    local procedure GetScheduledWeekDay(CurrentDateTime: DateTime; ScheduledTime: Time): DateTime
    var
        CurrentDate: Date;
        CurrentTime: Time;
        WeekDays: array[7] of Boolean;
        Idx: Integer;
        NextWeekDayIdx: Integer;
        CurrWeekDay: Integer;
        NextWeekDay: Integer;
    begin
        CurrentDate := DT2Date(CurrentDateTime);
        CurrentTime := DT2Time(CurrentDateTime);

        CurrWeekDay := Date2DWY(CurrentDate, 1);
        NextWeekDay := CurrWeekDay;

        WeekDays[1] := Monday;
        WeekDays[2] := Tuesday;
        WeekDays[3] := Wednesday;
        WeekDays[4] := Thursday;
        WeekDays[5] := Friday;
        WeekDays[6] := Saturday;
        WeekDays[7] := Sunday;

        if WeekDays[CurrWeekDay] and (CurrentTime < ScheduledTime) then
            exit(CreateDateTime(CurrentDate, ScheduledTime));

        for Idx := 0 to 6 do begin
            NextWeekDayIdx := ((CurrWeekDay + Idx) mod 7) + 1;
            if WeekDays[NextWeekDayIdx] then begin
                NextWeekDay := NextWeekDayIdx;
                break;
            end;
        end;

        exit(CreateDateTime(CalcDate(StrSubstNo('<+WD%1>', NextWeekDay), CurrentDate), ScheduledTime));
    end;

    procedure CalculateExecutionTime(DateTime: DateTime): DateTime
    begin
        if Rec.Recurrence <> Rec.Recurrence::Instantly then
            DateTime := CalculateRecipientDateTime(DateTime);

        case Recurrence of
            Recurrence::Instantly:
                exit(CurrentDateTime);
            Recurrence::Daily,
          Recurrence::Weekly:
                exit(CalculateClientTimeFromRecTimezone(GetScheduledWeekDay(DateTime, Time)));
            Recurrence::Monthly:
                case "Monthly Notification Date" of
                    "Monthly Notification Date"::"First Workday":
                        exit(CalculateClientTimeFromRecTimezone(GetScheduledFirstWorkdateOfMonth(DateTime, Time)));
                    "Monthly Notification Date"::"Last Workday":
                        exit(CalculateClientTimeFromRecTimezone(GetScheduledLastWorkdateOfMonth(DateTime, Time)));
                    "Monthly Notification Date"::Custom:
                        exit(CalculateClientTimeFromRecTimezone(GetScheduledCustomWorkdateOfMonth(DateTime, Time, "Date of Month")));
                end;
        end;
    end;

    local procedure CalculateRecipientDateTime(DateTime: DateTime): DateTime
    var
        UserPersonalization: Record "User Personalization";
        TypeHelper: Codeunit "Type Helper";
    begin
        UserPersonalization.SetFilter("User ID", Rec."User ID");
        if not UserPersonalization.FindFirst() then
            exit(DateTime);

        exit(TypeHelper.ConvertDateTimeFromUTCToTimeZone(DateTime, UserPersonalization."Time Zone"));
    end;

    local procedure CalculateClientTimeFromRecTimezone(DateTime: DateTime): DateTime
    var
        UserPersonalization: Record "User Personalization";
        TypeHelper: Codeunit "Type Helper";
    begin
        UserPersonalization.SetFilter("User ID", Rec."User ID");
        if not UserPersonalization.FindFirst() then
            exit(DateTime);
        // Convert the time from the requester's timezone to utc then to the recipient's timezone
        exit(TypeHelper.ConvertDateTimeFromInputTimeZoneToClientTimezone(DateTime, UserPersonalization."Time Zone"));
    end;

    local procedure Schedule(RecipientUserID: Code[50])
    begin
        Session.LogMessage('0000F6A', SchedulingNotificationTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, GetTelemetryDimensions());

        if Recurrence = Recurrence::Instantly then
            ScheduleNow()
        else
            ScheduleForLater(RecipientUserID);
    end;

    local procedure CheckRequiredPermissions()
    var
        [SecurityFiltering(SecurityFilter::Ignored)]
        DummySentNotificationEntry: Record "Sent Notification Entry";
        DummyNotificationSetup: Record "Notification Setup";
    begin
        if not DummySentNotificationEntry.WritePermission() then
            Error(NoPermissionsErr, WritePermissionTok, DummySentNotificationEntry.TableName());
        if not DummyNotificationSetup.ReadPermission() then
            Error(NoPermissionsErr, ReadPermissionTok, DummyNotificationSetup.TableName());
    end;

    procedure ScheduleNotification(NotificationEntry: Record "Notification Entry")
    begin
        // Try to get a schedule if none exist use the default record values
        if not Get(NotificationEntry."Recipient User ID", NotificationEntry.Type) then
            if Get('', NotificationEntry.Type) then;

        // It will always send instantly if only a default record exists
        // User must have a schedule for it to be sent later
        Schedule(NotificationEntry."Recipient User ID");
    end;

    local procedure OneMinuteFromNow(): DateTime
    begin
        exit(CurrentDateTime + 60000);
    end;

    local procedure ScheduleNow()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueCategory: Record "Job Queue Category";
        AzureADGraphUser: Codeunit "Azure AD Graph User";
    begin
        CheckRequiredPermissions();

        if JobQueueEntry.ReuseExistingJobFromUserCategoryCodeunitAndParamString(UserId(), NotifyNowLbl, CODEUNIT::"Notification Entry Dispatcher", '', OneMinuteFromNow()) then
            exit;

        if AzureADGraphUser.IsUserDelegated() then // can't use JQ
            SendNotificationInForeground()
        else begin
            JobQueueCategory.InsertRec(NotifyNowLbl, CopyStr(NotifyNowDescriptionTxt, 1, 30));
            JobQueueEntry.ScheduleJobQueueEntryForLater(
              CODEUNIT::"Notification Entry Dispatcher", OneMinuteFromNow(), NotifyNowLbl, '');
        end;
    end;

    local procedure ScheduleForLater(RecipientUserID: Code[50])
    var
        JobQueueEntry: Record "Job Queue Entry";
        NotificationEntry: Record "Notification Entry";
        AzureADGraphUser: Codeunit "Azure AD Graph User";
        ExecutionDateTime: DateTime;
    begin
        CheckRequiredPermissions();

        if RecipientUserID = '' then begin
            // If the JQ runs on an empty userid, it will fail.
            // This is only possible from the onmodify trigger and using SMTP Mail Setup
            Session.LogMessage('0000GD1', ScheduleLaterRecipientIDErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', NotificationTelemetryCategoryTxt);
            exit;
        end;

        ExecutionDateTime := CalculateExecutionTime(CurrentDateTime);

        if AzureADGraphUser.IsUserDelegated() then // can't use JQ
            SendNotificationInForeground();

        NotificationEntry.SetRange("Recipient User ID", RecipientUserID);
        NotificationEntry.SetRange(Type, "Notification Type");

        if JobQueueEntry.ReuseExistingJobFromUserCategoryCodeunitAndParamString(UserId(), NotifyLaterLbl, CODEUNIT::"Notification Entry Dispatcher", CopyStr(NotificationEntry.GetView(), 1, MaxStrLen(JobQueueEntry."Parameter String")), ExecutionDateTime) then
            exit;

        JobQueueEntry.ScheduleJobQueueEntryForLater(
          CODEUNIT::"Notification Entry Dispatcher", ExecutionDateTime, NotifyLaterLbl, NotificationEntry.GetView());
        Rec."Last Scheduled Job" := JobQueueEntry.ID;
        Rec.Modify();
    end;

    local procedure GetTelemetryDimensions() Dimensions: Dictionary of [Text, Text]
    begin
        Dimensions.Add('Category', NotificationTelemetryCategoryTxt);

        Dimensions.Add('Recurrance', Format(Rec.Recurrence.AsInteger()));
        Dimensions.Add('NotificationType', Format(Rec."Notification Type"));
        Dimensions.Add('DailyFrequency', Format(Rec."Daily Frequency"));
        Dimensions.Add('DateOfMonth', Format(Rec."Date of Month"));
        Dimensions.Add('Monday', Format(Rec.Monday));
        Dimensions.Add('Tuesday', Format(Rec.Tuesday));
        Dimensions.Add('Wednesday', Format(Rec.Wednesday));
        Dimensions.Add('Thursday', Format(Rec.Thursday));
        Dimensions.Add('Friday', Format(Rec.Friday));
        Dimensions.Add('Saturday', Format(Rec.Saturday));
        Dimensions.Add('Sunday', Format(Rec.Sunday));
        Dimensions.Add('LastScheduledJob', Format(Rec."Last Scheduled Job"));
        Dimensions.Add('MonthlyNotificationDate', Format(Rec."Monthly Notification Date"));
        Dimensions.Add('Time', Format(Rec.Time));
    end;

    local procedure SendNotificationInForeground()
    var
        TempJobQueueEntry: Record "Job Queue Entry" temporary;
    begin
        Codeunit.Run(CODEUNIT::"Notification Entry Dispatcher", TempJobQueueEntry);
    end;
}

