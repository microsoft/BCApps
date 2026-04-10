namespace System.Diagnostics;

using System.Email;
using System.Environment.Configuration;
using System.Globalization;
using System.Media;
using System.Privacy;
using System.Reflection;
using System.Security.AccessControl;
using System.Security.User;
using System.Telemetry;

codeunit 1392 "Monitor Sensitive Field"
{
    Permissions = tabledata "Field Monitoring Setup" = im;

    procedure ValidateTableNo(TableNo: Integer)
    var
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
    begin
        if not IsValidTable(TableNo) then
            Error(SystemTableErr);

        ChangeLogSetupTable.SetRange("Monitor Sensitive Field", false);
        ChangeLogSetupTable.SetRange("Table No.", TableNo);
        if not ChangeLogSetupTable.IsEmpty() then
            Error(TableMonitoredInChangeLogErr);
    end;

    procedure ValidateTableAndFieldNo(TableNo: Integer; FieldNo: Integer)
    begin
        ValidateTableNo(TableNo);

        if not IsValidField(TableNo, FieldNo) then
            Error(ValidTableAndFieldErr);
    end;

    procedure InsertChangeLogSetupTable(TableNo: Integer)
    var
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
    begin
        if not ChangeLogSetupTable.Get(TableNo) then begin
            ChangeLogSetupTable.Validate("Table No.", TableNo);
            ChangeLogSetupTable.Validate("Monitor Sensitive Field", true);
            ChangeLogSetupTable."Log Insertion" := ChangeLogSetupTable."Log Insertion"::"Some Fields";
            ChangeLogSetupTable."Log Modification" := ChangeLogSetupTable."Log Modification"::"Some Fields";
            ChangeLogSetupTable."Log Deletion" := ChangeLogSetupTable."Log Deletion"::"Some Fields";
            ChangeLogSetupTable.Insert(true);
        end;
    end;

    procedure DeleteChangeLogSetupTable(TableNo: integer; FieldNo: Integer)
    var
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
        ChangeLogSetupField: Record "Change Log Setup (Field)";
    begin
        ChangeLogSetupField.SetRange("Table No.", TableNo);
        ChangeLogSetupField.SetFilter("Field No.", '<>%1', FieldNo);

        if ChangeLogSetupField.IsEmpty() then begin
            ChangeLogSetupTable.Get(TableNo);
            ChangeLogSetupTable.Delete();
        end;
    end;

    procedure GetTableCaption(TableNo: Integer): Text
    var
        AllObj: Record AllObjWithCaption;
    begin
        AllObj.Get(AllObj."Object Type"::Table, TableNo);
        exit(AllObj."Object Caption");
    end;

    procedure GetNotificationCount(): integer
    var
        FieldMonitoringSetup: Record "Field Monitoring Setup";
        ChangeEntry: Record "Change Log Entry";
    begin
        if FieldMonitoringSetup.Get() then begin
            ChangeEntry.SetFilter("Field Log Entry Feature", '%1|%2', ChangeEntry."Field Log Entry Feature"::"Monitor Sensitive Fields", ChangeEntry."Field Log Entry Feature"::All);
            if ChangeEntry.Count > FieldMonitoringSetup."Notification Count" then
                exit(ChangeEntry.Count - FieldMonitoringSetup."Notification Count");
        end;
    end;

    procedure OpenDataSensitivityFilterPage()
    var
        DataSensitivity: Record "Data Sensitivity";
        FilterPageBuilder: FilterPageBuilder;
    begin
        FilterPageBuilder.PageCaption(PageCaptionTxt);
        FilterPageBuilder.AddTable(DataSensitivity.TableCaption(), Database::"Data Sensitivity");
        FilterPageBuilder.AddFieldNo(DataSensitivity.TableCaption(), DataSensitivity.FieldNo("Data Sensitivity"));
        FilterPageBuilder.AddFieldNo(DataSensitivity.TableCaption(), DataSensitivity.FieldNo("Table Caption"));
        FilterPageBuilder.AddFieldNo(DataSensitivity.TableCaption(), DataSensitivity.FieldNo("Field Caption"));

        if FilterPageBuilder.RunModal() then begin
            DataSensitivity.SetView(FilterPageBuilder.GetView(DataSensitivity.TableCaption()));
            ImportMonitorFieldsByDataSensitivity(DataSensitivity);
        end;
    end;

    procedure AddAllowedFieldFilters(var FieldTable: Record Field)
    begin
        FieldTable.SetRange(Class, FieldTable.Class::Normal);
        FieldTable.SetFilter(Type, StrSubstNo(FieldFilterTxt,
                FieldTable.Type::Boolean,
                FieldTable.Type::Text,
                FieldTable.Type::Code,
                FieldTable.Type::Decimal,
                FieldTable.Type::Integer,
                FieldTable.Type::BigInteger,
                FieldTable.Type::Date,
                FieldTable.Type::Time,
                FieldTable.Type::DateTime,
                FieldTable.Type::DateFormula,
                FieldTable.Type::Option,
                FieldTable.Type::Duration,
                FieldTable.Type::GUID));
        FieldTable.SetFilter("No.", '<2000000000');
    end;

    procedure AddValidTablesFilter(var AllObjWithCaption: Record AllObjWithCaption)
    begin
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        AllObjWithCaption.SetFilter("Object ID", TableIdFilter());
    end;

    procedure EnableMonitor(ShowConfirmMessage: Boolean)
    var
        FieldMonitoringSetup: Record "Field Monitoring Setup";
    begin
        GetSetupTable(FieldMonitoringSetup);

        if FieldMonitoringSetup."Email Account Name" = '' then
            Error(EmailAccountMissingErr);

        if FieldMonitoringSetup."Monitor Status" then
            exit;

        CheckUserHasValidContactEmail(FieldMonitoringSetup."User Id");

        if ShowConfirmMessage then
            if not Confirm(ConfirmEnableQst) then
                error('');

        SetMonitorStatus(FieldMonitoringSetup, true);
    end;

    procedure DisableMonitor()
    var
        FieldMonitoringSetup: Record "Field Monitoring Setup";
    begin
        GetSetupTable(FieldMonitoringSetup);
        if FieldMonitoringSetup."Monitor Status" = false then
            exit;

        SetMonitorStatus(FieldMonitoringSetup, false);
    end;

    procedure CheckUserHasValidContactEmail(MonitorUserId: Code[50])
    var
        User: record User;
    begin
        if MonitorUserId = '' then
            Error(UserNotFoundErr);

        User.SetRange("User Name", MonitorUserId);
        if not User.FindFirst() then
            Error(UserNotFoundErr);

        ShowUserCardIfMissingContactEmail(User);
    end;

    procedure ExcludeMonitorTablesFromChangeLog(var AllObjectWithCaption: Record AllObjWithCaption)
    var
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
    begin
        if AllObjectWithCaption.FindSet() then
            repeat
                if not ChangeLogSetupTable.Get(AllObjectWithCaption."Object ID") then
                    AllObjectWithCaption.Mark(true)
                else
                    if not ChangeLogSetupTable."Monitor Sensitive Field" then
                        AllObjectWithCaption.Mark(true);
            until AllObjectWithCaption.Next() = 0;

        AllObjectWithCaption.MarkedOnly(true);

        ChangeLogSetupTable.Init();
        ChangeLogSetupTable.SetRange("Monitor Sensitive Field", true);
        if not ChangeLogSetupTable.IsEmpty() then
            ShowChangeLogHiddenTablesNotification();
    end;

    procedure GetSetupTable(var FieldMonitoringSetup: Record "Field Monitoring Setup")
    begin
        if not FieldMonitoringSetup.Get() then
            FieldMonitoringSetup.Insert(false);
    end;

    procedure AddMonitoredField(TableNo: Integer; FieldNo: Integer; Notify: Boolean)
    var
        ChangeLogSetupField: record "Change Log Setup (Field)";
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
    begin
        if not IsValidTableAndField(TableNo, FieldNo) then
            exit;

        ChangeLogSetupTable.SetRange("Monitor Sensitive Field", false);
        ChangeLogSetupTable.SetRange("Table No.", TableNo);
        if not ChangeLogSetupTable.IsEmpty() then
            exit;

        if not ChangeLogSetupField.Get(TableNo, FieldNo) then begin
            InsertChangeLogSetupTable(TableNo);

            ChangeLogSetupField.Validate("Table No.", TableNo);
            ChangeLogSetupField.Validate("Field No.", FieldNo);
            ChangeLogSetupField.Validate(Notify, Notify);
            ChangeLogSetupField.Validate("Monitor Sensitive Field", true);
            ChangeLogSetupField.Validate("Log Deletion", true);
            ChangeLogSetupField.Validate("Log Insertion", true);
            ChangeLogSetupField.Validate("Log Modification", true);
            ChangeLogSetupField.Insert();
        end;
    end;

    procedure ImportFieldsBySensitivity(Sensitive: Boolean; Personal: Boolean; CompanyConfidential: Boolean)
    var
        DataSensitivity: Record "Data Sensitivity";
        FilterString: Text;
    begin
        if Sensitive then
            AddFilter(FilterString, format(DataSensitivity."Data Sensitivity"::Sensitive));
        if Personal then
            AddFilter(FilterString, format(DataSensitivity."Data Sensitivity"::Personal));
        if CompanyConfidential then
            AddFilter(FilterString, format(DataSensitivity."Data Sensitivity"::"Company Confidential"));
        DataSensitivity.SetFilter("Data Sensitivity", FilterString);

        ImportMonitorFieldsByDataSensitivity(DataSensitivity);
    end;

    procedure SetSetupTable(MonitorUserId: text[50]; EmailAccountId: Guid; EmailAccountName: Text[250]; EmailConnector: Enum "Email Connector")
    var
        FieldMonitoringSetup: Record "Field Monitoring Setup";
    begin
        GetSetupTable(FieldMonitoringSetup);
        FieldMonitoringSetup.Validate("User Id", MonitorUserId);
        FieldMonitoringSetup.Validate("Email Account Id", EmailAccountId);
        FieldMonitoringSetup.Validate("Email Account Name", EmailAccountName);
        FieldMonitoringSetup.Validate("Email Connector", EmailConnector);
        FieldMonitoringSetup.Modify();
    end;

    procedure ShowPromoteMonitorSensitiveFieldNotification()
    var
        DoesUserHavePermission: Boolean;
    begin
        ValidateUserPermissions(CopyStr(UserId(), 1, 50), DoesUserHavePermission);
        if not DoesUserHavePermission then
            exit;

        ShowPromotionNotification();
    end;

    internal procedure ShowPromotionNotification()
    var
        PromoteMonitorSensitiveFieldNotification: Notification;
    begin
        if IsMonitorEnabled() then
            exit;
        if not IsNotificationEnabled(GetPromoteMonitorFeatureNotificationId()) then
            exit;
        PromoteMonitorSensitiveFieldNotification.AddAction(EnableFieldMonitoringMsg, CODEUNIT::"Monitor Sensitive Field", 'OpenFieldMonitoringSetupWizard');
        CreateNotification(PromoteMonitorSensitiveFieldNotification, GetPromoteMonitorFeatureNotificationId(), PromoteMonitorFeatureMsg, NotificationScope::LocalScope);
        PromoteMonitorSensitiveFieldNotification.Send();
    end;

    procedure OpenFieldMonitoringSetupWizard(notification: Notification)
    begin
        Page.Run(Page::"Monitor Field Setup Wizard");
    end;

    procedure OpenFieldMonitoringWorksheet(notification: Notification)
    begin
        Page.Run(Page::"Monitored Fields Worksheet");
    end;

    procedure OpenFieldMonitoringSetup(notification: Notification)
    begin
        Page.Run(Page::"Field Monitoring Setup");
    end;

    local procedure ShowChangeLogHiddenTablesNotification()
    var
        ChangeLogHiddenTableNotification: Notification;
    begin
        if not IsNotificationEnabled(GetChangeLogHiddenTablesNotificationId()) then
            exit;

        ChangeLogHiddenTableNotification.AddAction(OpenWorksheetMsg, CODEUNIT::"Monitor Sensitive Field", 'OpenFieldMonitoringWorksheet');
        CreateNotification(ChangeLogHiddenTableNotification, GetChangeLogHiddenTablesNotificationId(), HiddenTablesNotificationMsg, NotificationScope::LocalScope);
        ChangeLogHiddenTableNotification.Send();
    end;

    local procedure IsMonitorEnabled(): Boolean
    var
        FieldMonitoringSetup: Record "Field Monitoring Setup";
    begin
        if not FieldMonitoringSetup.Get() then
            exit(false);
        exit(FieldMonitoringSetup."Monitor Status");
    end;

    local procedure CreateNotification(var MonitorNotification: Notification; Id: Text; Message: Text; MonitorNotificationScope: NotificationScope)
    begin
        MonitorNotification.Id := Id;
        MonitorNotification.Message(Message);
        MonitorNotification.Scope(MonitorNotificationScope);
        MonitorNotification.AddAction(DontShowThisAgainMsg, CODEUNIT::"Monitor Sensitive Field", 'DisableNotification');
    end;

    procedure DisableNotification(Notification: notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        case Notification.Id of
            GetChangeLogHiddenTablesNotificationId():
                MyNotifications.InsertDefault(Notification.Id, HiddenTablesNotificationNameTok,
                  HiddenTablesNotificationDescTok, false);
            GetPromoteMonitorFeatureNotificationId():
                MyNotifications.InsertDefault(Notification.Id, PromoteMonitorFeatureNotificationNameTok,
                  PromoteMonitorFeatureNotificationDescTok, false);
        end;

        MyNotifications.Disable(Notification.Id)
    end;

    local procedure IsNotificationEnabled(NotificationId: Guid): Boolean
    var
        MyNotifications: Record "My Notifications";
    begin
        exit(MyNotifications.IsEnabled(NotificationId));
    end;

    local procedure ImportMonitorFieldsByDataSensitivity(var DataSensitivity: Record "Data Sensitivity")
    begin
        if DataSensitivity.GetFilters = '' then
            exit;

        if DataSensitivity.FindSet() then
            repeat
                AddMonitoredField(DataSensitivity."Table No", DataSensitivity."Field No", false);
            until DataSensitivity.Next() = 0;
    end;

    local procedure IsValidTableAndField(TableNo: Integer; FieldNo: Integer): Boolean
    begin
        if not IsValidTable(TableNo) then
            exit(false);

        if not IsValidField(TableNo, FieldNo) then
            exit(false);

        exit(true);
    end;

    procedure IsValidTable(TableNo: Integer): Boolean
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        AllObjWithCaption.FilterGroup := 10;
        AllObjWithCaption.Setrange("Object ID", TableNo);
        AllObjWithCaption.Setrange("Object Type", AllObjWithCaption."Object Type"::Table);
        AllObjWithCaption.FilterGroup := 11;
        AllObjWithCaption.SetFilter("Object ID", TableIdFilter());
        exit(not AllObjWithCaption.IsEmpty());
    end;

    local procedure IsValidField(TableNo: Integer; FieldNo: Integer): Boolean
    var
        FieldTable: Record Field;
    begin
        AddAllowedFieldFilters(FieldTable);
        FieldTable.FilterGroup(2);
        FieldTable.SetRange(TableNo, TableNo);
        FieldTable.SetRange("No.", FieldNo);
        FieldTable.FilterGroup(0);
        if not FieldTable.IsEmpty() then
            exit(true);
    end;

    local procedure TableIdFilter(): Text
    begin
        // Exclude Change log tables: 402..405
        // Exclude Monitor sensitive field tables 1366
        // Exclude email system module tables: Email Outbox: 8888, Sent Email:8889, Email Message: 8900,Email Error:8901, Email Recipient:8903,  Email message Attachment: 8904
        exit(StrSubstNo(TableNoFilterTxt, 401, 406, 1365, 1367, 8887, 8890, 8899, 8902, 8905, Database::User, Database::"Data Sensitivity"));
    end;

    local procedure ShowUserCardIfMissingContactEmail(User: Record User)
    begin
        if User."Contact Email" = '' then begin
            if Confirm(UserMissingContactEmailQst) then
                Page.Run(Page::"User Card", User);
            Error('');
        end;
    end;

    local procedure SetMonitorStatus(var FieldMonitoringSetup: Record "Field Monitoring Setup"; Status: Boolean)
    var
        Attributes: Dictionary of [Text, Text];
    begin
        FieldMonitoringSetup."Monitor Status" := Status;
        FieldMonitoringSetup.Modify();

        Attributes.Add('MonitorStatus', Format(Status));
        Session.LogMessage('0000DD3', StrSubstNo(MonitorStatusChangeTxt, Format(Status)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Attributes);
    end;

    procedure ValidateUserPermissions(MonitorUserId: Code[50]; var DoesUserHavePermission: Boolean)
    var
        Permission: Record Permission;
        User: Record User;
    begin
        User.SetRange("User Name", MonitorUserId);
        if not User.FindFirst() then
            exit;

        DoesUserHavePermission := CheckPermission(User, Database::"Field Monitoring Setup", Permission."Read Permission"::Yes, Permission."Insert Permission"::Indirect,
            Permission."Modify Permission"::Yes, Permission."Delete Permission"::Indirect);
    end;

    procedure OpenUserCard(MonitorUserId: code[250])
    var
        User: Record User;
    begin
        User.SetRange("User Name", MonitorUserId);
        User.FindFirst();
        Page.Run(Page::"User Card", User);
    end;

    procedure GetPromoteMonitorFeatureNotificationId(): Guid
    begin
        exit(PromoteMonitorFeatureNotificationIdTxt);
    end;

    procedure GetChangeLogHiddenTablesNotificationId(): Guid
    begin
        exit(ChangeLogHiddenTablesNotificationIdTxt);
    end;

    local procedure CheckPermission(User: Record User; TableNo: Integer; ReadPermission: Option " ",Yes,Indirect; InsertPermission: Option " ",Yes,Indirect; ModifyPermission: Option " ",Yes,Indirect; DeletePermission: Option " ",Yes,Indirect): Boolean
    var
        Permission: Record Permission;
        EffectivePermissions: Codeunit "Effective Permissions Mgt.";
    begin
        EffectivePermissions.PopulatePermissionRecordWithEffectivePermissionsForObject(Permission, User."User Security ID",
           CopyStr(CompanyName(), 1, 50), Permission."Object Type"::"Table Data", TableNo);
        exit((Permission."Read Permission" = ReadPermission) and
            ((Permission."Insert Permission" = InsertPermission) or (Permission."Insert Permission" = Permission."Insert Permission"::Yes)) and
            (Permission."Modify Permission" = ModifyPermission) and
            ((Permission."Delete Permission" = DeletePermission) or (Permission."Delete Permission" = Permission."Delete Permission"::Yes)));
    end;

    local procedure AddFilter(var FilterString: Text; NewFilter: Text)
    begin
        if FilterString = '' then
            FilterString := NewFilter
        else
            FilterString := FilterString + '|' + NewFilter;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterAssistedSetup', '', false, false)]
    local procedure AddMonitorFieldSetupWizard()
    var
        GuidedExperience: Codeunit "Guided Experience";
        Language: Codeunit Language;
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
        GuidedExperienceType: Enum "Guided Experience Type";
        Info: ModuleInfo;
        CurrentGlobalLanguage: Integer;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        CurrentGlobalLanguage := GLOBALLANGUAGE();

        GuidedExperience.InsertAssistedSetup(MonitorSetupTitleTxt, MonitorSetupShortTitleTxt, HelpMonitorDescriptionTxt, 5, ObjectType::Page,
            Page::"Monitor Field Setup Wizard", AssistedSetupGroup::"Set Up Extended Security", '', VideoCategory::Uncategorized, HelpMonitorFieldChangeTxt);
        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            Page::"Monitor Field Setup Wizard", Language.GetDefaultApplicationLanguageId(), MonitorSetupTitleTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Change Log Setup", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnModifyChangeLogSetup(var Rec: Record "Change Log Setup"; var xRec: Record "Change Log Setup"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;

        if Rec."Change Log Activated" <> xRec."Change Log Activated" then
            Session.LogSecurityAudit(ChangeLogStatusTxt, SecurityOperationResult::Success,
                StrSubstNo(ChangeLogSetupValuesTxt, Format(Rec."Change Log Activated")), AuditCategory::PolicyManagement);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Change Log Setup", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnInsertChangeLogSetup(var Rec: Record "Change Log Setup"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;

        Session.LogSecurityAudit(ChangeLogStatusTxt, SecurityOperationResult::Success,
            StrSubstNo(ChangeLogSetupValuesTxt, Format(Rec."Change Log Activated")), AuditCategory::PolicyManagement);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Change Log Setup", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnDeleteChangeLogSetup(var Rec: Record "Change Log Setup"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;

        Session.LogSecurityAudit(ChangeLogStatusTxt, SecurityOperationResult::Success,
            StrSubstNo(ChangeLogSetupValuesTxt, EntryDeletedLbl), AuditCategory::PolicyManagement);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Field Monitoring Setup", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnModifyFieldMonitoringSetup(var Rec: Record "Field Monitoring Setup"; var xRec: Record "Field Monitoring Setup"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;

        if (Rec."Monitor Status" <> xRec."Monitor Status") or (Rec."User Id" <> xRec."User Id") or (Rec."Email Connector" <> xRec."Email Connector")
            or (Rec."Email Account Name" <> xRec."Email Account Name") or (Rec."Email Account Id" <> xRec."Email Account Id") then
            Session.LogSecurityAudit(MonitorSetupLbl, SecurityOperationResult::Success,
                StrSubstNo(MonitorSetupValuesLbl, Format(Rec."Monitor Status"), Rec."User Id", Rec."Email Connector", Rec."Email Account Name", Rec."Email Account Id"),
                AuditCategory::PolicyManagement);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Field Monitoring Setup", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnInsertFieldMonitoringSetup(var Rec: Record "Field Monitoring Setup"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;

        Session.LogSecurityAudit(MonitorSetupLbl, SecurityOperationResult::Success,
            StrSubstNo(MonitorSetupValuesLbl, Format(Rec."Monitor Status"), Rec."User Id", Rec."Email Connector", Rec."Email Account Name", Rec."Email Account Id"),
            AuditCategory::PolicyManagement);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Field Monitoring Setup", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnDeleteFieldMonitoringSetup(var Rec: Record "Field Monitoring Setup"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;

        Session.LogSecurityAudit(MonitorSetupLbl, SecurityOperationResult::Success,
            StrSubstNo(MonitorSetupValuesLbl, EntryDeletedLbl, Rec."User Id", Rec."Email Connector", Rec."Email Account Name", Rec."Email Account Id"),
            AuditCategory::PolicyManagement);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Access Control", 'OnAfterRenameEvent', '', false, false)]
    local procedure OnRenameAccessControl(var Rec: Record "Access Control"; var xRec: Record "Access Control")
    begin
        SendAccessControlTelemetryOnChange(Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Access Control", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnModifyAccessControl(var Rec: Record "Access Control"; var xRec: Record "Access Control")
    begin
        SendAccessControlTelemetryOnChange(Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Access Control", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnInsertAccessControl(var Rec: Record "Access Control")
    begin
        SendAccessControlTelemetry('Inserted', Rec)
    end;

    [EventSubscriber(ObjectType::Table, Database::"Access Control", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnDeleteAccessControl(var Rec: Record "Access Control")
    begin
        SendAccessControlTelemetry('Deleted', Rec)
    end;

    local procedure SendAccessControlTelemetryOnChange(Rec: Record "Access Control"; xRec: Record "Access Control")
    begin
        if (Rec."Role ID" <> xRec."Role ID") or (Rec."User Security ID" <> xRec."User Security ID") or (Rec."Company Name" <> xRec."Company Name")
            or (Rec.Scope <> xRec.Scope) or (Rec."App ID" <> xRec."App ID") then
            SendAccessControlTelemetry('Changed', Rec)
    end;

    local procedure SendAccessControlTelemetry(OperationType: Text; AccessControl: Record "Access Control")
    var
        User: Record User;
        LicenseType: Text;
    begin
        if AccessControl.IsTemporary() then
            exit;

        if User.Get(AccessControl."User Security ID") then
            LicenseType := Format(User."License Type")
        else
            LicenseType := 'Unknown';

        Session.LogSecurityAudit(AccessControlLbl, SecurityOperationResult::Success,
            StrSubstNo(AccessControlValuesLbl, OperationType, AccessControl."User Security ID", AccessControl."Role ID",
                AccessControl."Company Name", AccessControl.Scope, AccessControl."App ID", LicenseType),
            AuditCategory::UserManagement);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Telemetry Management", 'OnSendDailyTelemetry', '', true, true)]
    local procedure SendTelemetryOnActivityTelemetry()
    var
        ChangeLogSetupField: Record "Change Log Setup (Field)";
    begin
        ChangeLogSetupField.SetRange("Monitor Sensitive Field", true);
        Session.LogMessage('0000EVR', StrSubstNo(TraceTagTelemetryMsg, 'Monitor Sensitive Field', ChangeLogSetupField.Count),
            Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AlCompanyActivityCategoryTxt);
    end;

    var
        PageCaptionTxt: Label 'Add Fields To Monitor Fields Worksheet';
        SystemTableErr: Label 'You cannot monitor fields on the specified table. For example, the table ID might not exist or it might be a system table.';
        TableMonitoredInChangeLogErr: Label 'This table is monitored in Change log. If you want to monitor it here, please remove it from change log setup.';
        ValidTableAndFieldErr: Label 'You must choose a valid table and field. Field can not be blob, media or media set.';
        FieldFilterTxt: Label '%1|%2|%3|%4|%5|%6|%7|%8|%9|%10|%11|%12|%13', Locked = true;
        UserNotFoundErr: Label 'To start monitoring fields, you must specify the user who will receive notification emails when field values change.';
        UserMissingContactEmailQst: Label 'A contact email address is not specified for the user. Do you want to open the User page to set that up for the user now?';
        ConfirmEnableQst: Label 'Monitoring fields can impact performance. We recommend that you only monitor fields that contain sensitive data.';
        MonitorStatusChangeTxt: Label 'Sensitive field monitor status has changed to %1', Locked = true;
        TableNoFilterTxt: Label '1..%1|%2..%3|%4..%5|%6..%7|%8|%9..1999999999|%10|%11', Locked = true;
        EmailAccountMissingErr: label 'You must specify the email account to send notification email from when field values change. Specify the account in the Notification Email Account field. If no accounts are available, you can add one.';
        MonitorSetupTitleTxt: Label 'Set up field monitoring';
        MonitorSetupShortTitleTxt: Label 'Set up field monitoring';
        HelpMonitorFieldChangeTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2128531', Locked = true;
        HelpMonitorDescriptionTxt: Label 'You can monitor important fields when someone changes a value. Start field monitoring and specify the fields that you want to monitor. Then analyze the field monitoring telemetry.';
        DontShowThisAgainMsg: Label 'Don''t show this again.';
        EnableFieldMonitoringMsg: Label 'Enable Field Monitoring';
        OpenWorksheetMsg: Label 'Open the Monitored Fields Worksheet';
        HiddenTablesNotificationMsg: Label 'Some tables are hidden because they are contain fields that are being monitored for changes.';
        PromoteMonitorFeatureMsg: Label 'This page contains sensitive business data. You can set up a notification to alert you when data changes.';
        HiddenTablesNotificationNameTok: Label 'Notify users about hidden tables in the Change Log Setup.';
        HiddenTablesNotificationDescTok: Label 'Notify users that some tables are hidden in the Change Log Table List page because they contain fields that are being monitored for changes.';
        PromoteMonitorFeatureNotificationNameTok: Label 'Notify users about monitoring sensitive data.';
        PromoteMonitorFeatureNotificationDescTok: Label 'Notify users about monitoring sensitive data.';
        ChangeLogHiddenTablesNotificationIdTxt: Label '2e7fe3ad-6382-4cbd-93f8-79bad5b53854', Locked = true;
        PromoteMonitorFeatureNotificationIdTxt: Label '6a2fe3ad-6382-4acd-34f8-7dbad5b51245', Locked = true;
        ChangeLogStatusTxt: Label 'Change Log Setup', Locked = true;
        ChangeLogSetupValuesTxt: Label 'Change Log Setup status was changed to %1', Locked = true;
        MonitorSetupLbl: Label 'Sensitive Field Monitor Setup', Locked = true;
        AccessControlLbl: Label 'Access Control', Locked = true;
        MonitorSetupValuesLbl: Label 'Setup values were changed to: status: %1, recipient user: %2, email connector: %3, email account name: %4 and email account id: %5', Locked = true;
        AccessControlValuesLbl: Label 'Access Control record was %1: User Security ID: %2, Role ID: %3, Company Name: %4, Scope: %5, App ID: %6. User license type: %7.', Locked = true;
        EntryDeletedLbl: Label 'Deleted', Locked = true;
        TraceTagTelemetryMsg: Label '%1: %2', Locked = true;
        AlCompanyActivityCategoryTxt: Label 'AL Company Activity', Locked = true;
}