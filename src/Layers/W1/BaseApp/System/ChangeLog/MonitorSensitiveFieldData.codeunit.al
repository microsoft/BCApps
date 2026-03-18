namespace System.Diagnostics;

using Microsoft.Utilities;
using System.Security.AccessControl;

codeunit 1367 "Monitor Sensitive Field Data"
{
    Permissions = tabledata "Field Monitoring Setup" = im;

    procedure CheckIfTableIsMonitored(var TempChangeLogSetupTable: Record "Change Log Setup (Table)" temporary; FieldMonitoringSetup: Record "Field Monitoring Setup"; ChangeLogSetup: Record "Change Log Setup"): Boolean
    begin
        if TempChangeLogSetupTable."Monitor Sensitive Field" then
            exit(FieldMonitoringSetup."Monitor Status")
        else
            exit(ChangeLogSetup."Change Log Activated")
    end;

    procedure HandleMonitorSensitiveFields(var ChangeLogEntry: Record "Change Log Entry"; var TempChangeLogSetupField: Record "Change Log Setup (Field)" temporary; RecRef: RecordRef; FldRef: FieldRef; IsAlwaysLoggedTable: Boolean; IsMonitorEnabled: Boolean)
    var
        MonitorFieldNotification: Enum "Monitor Field Notification";
        Attributes: Dictionary of [Text, Text];
        IsAlwaysLoggedMonitorTableActive, IsMonitoredFieldActive : Boolean;
    begin
        IsAlwaysLoggedMonitorTableActive := IsAlwaysLoggedMonitorTable(ChangeLogEntry, RecRef, FldRef, IsAlwaysLoggedTable);
        IsMonitoredFieldActive := IsMonitoredField(TempChangeLogSetupField, RecRef, FldRef, IsMonitorEnabled);

        if IsAlwaysLoggedMonitorTableActive or IsMonitoredFieldActive then begin
            if not IsAlwaysLoggedMonitorTableActive then
                ChangeLogEntry."Field Log Entry Feature" := ChangeLogEntry."Field Log Entry Feature"::"Monitor Sensitive Fields";

            if IsMonitoredFieldActive then begin
                if TempChangeLogSetupField.Notify then
                    MonitoredFieldNotification.SendEmailNotificationOfSensitiveFieldChange(RecRef, ChangeLogEntry, MonitorFieldNotification)
                else
                    MonitorFieldNotification := MonitorFieldNotification::"Turned Off";
                ChangeLogEntry."Notification Status" := MonitorFieldNotification;
            end;

            Attributes.Add('TableCaption', RecRef.Caption);
            Attributes.Add('TableNumber', Format(RecRef.Number));
            Attributes.Add('FieldCaption', FldRef.Caption);
            Attributes.Add('FieldNumber', Format(FldRef.Number));
            Session.LogMessage('0000CTE', StrSubstNo(SensitiveFieldValueHasChangedTxt, FldRef.Caption, FldRef.Number, RecRef.Caption, RecRef.Number),
                Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Attributes);
        end;
    end;

    procedure IsIgnoredMonitorField(Recref: RecordRef; FldRef: FieldRef): Boolean
    var
        FieldMonitoringSetup: Record "Field Monitoring Setup";
        ChangeLogSetupField: Record "Change Log Setup (Field)";
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
    begin
        case Recref.Number of
            Database::"Field Monitoring Setup":
                exit(FldRef.Number = FieldMonitoringSetup.FieldNo("Notification Count"));
            Database::"Change Log Setup (Field)":
                if RecRef.Field(ChangeLogSetupTable.FieldNo("Monitor Sensitive Field")).Value then
                    exit((FldRef.Number <> ChangeLogSetupField.FieldNo("Table No.")) and
                        (FldRef.Number <> ChangeLogSetupField.FieldNo("Field No.")) and
                        (FldRef.Number <> ChangeLogSetupField.FieldNo(Notify)));
            Database::"Change Log Setup (Table)":
                exit(RecRef.Field(ChangeLogSetupTable.FieldNo("Monitor Sensitive Field")).Value);
        end;
    end;

    procedure OpenChangedRecordPage(TableNo: Integer; FieldNo: Integer; RecordSystemID: Guid)
    var
        PageManagement: Codeunit "Page Management";
        RecRef: RecordRef;
    begin
        if TableNo = Database::"Change Log Entry" then
            exit;

        RecRef.Open(TableNo);
        if RecRef.IsTemporary or IsNullGuid(RecordSystemID) then
            exit;

        if not RecRef.GetBySystemId(RecordSystemID) then begin
            Message(NoAvailablePageMsg);
            Error('');
        end;

        if not PageManagement.PageRunAtField(RecRef, FieldNo, false) then begin
            Message(NoAvailablePageMsg);
            Error('');
        end;
    end;

    procedure ResetNotificationCount()
    var
        FieldMonitoringSetup: Record "Field Monitoring Setup";
        ChangeEntry: Record "Change Log Entry";
    begin
        if FieldMonitoringSetup.Get() then begin
            ChangeEntry.SetFilter("Field Log Entry Feature", '%1|%2', ChangeEntry."Field Log Entry Feature"::"Monitor Sensitive Fields", ChangeEntry."Field Log Entry Feature"::All);

            FieldMonitoringSetup."Notification Count" := ChangeEntry.Count;
            FieldMonitoringSetup.Modify();
        end;
    end;

    local procedure IsAlwaysLoggedMonitorTable(var ChangeLogEntry: Record "Change Log Entry"; RecRef: RecordRef; FldRef: FieldRef; IsAlwaysLoggedTable: Boolean): Boolean
    var
        User: Record User;
        FieldMonitoringSetup: Record "Field Monitoring Setup";
        ChangeLogSetupField: Record "Change Log Setup (Field)";
        MonitorFieldNotification: Enum "Monitor Field Notification";
    begin
        if IsAlwaysLoggedTable then
            ChangeLogEntry."Field Log Entry Feature" := ChangeLogEntry."Field Log Entry Feature"::All;

        case RecRef.Number of
            Database::User:
                if FldRef.Number = User.FieldNo("Contact Email") then
                    ChangeLogEntry."Field Log Entry Feature" := ChangeLogEntry."Field Log Entry Feature"::All;

            Database::"Change Log Setup (Field)":
                if RecRef.Field(ChangeLogSetupField.FieldNo("Monitor Sensitive Field")).Value then
                    ChangeLogEntry."Field Log Entry Feature" := ChangeLogEntry."Field Log Entry Feature"::"Monitor Sensitive Fields";

            Database::"Field Monitoring Setup":
                begin
                    ChangeLogEntry."Field Log Entry Feature" := ChangeLogEntry."Field Log Entry Feature"::"Monitor Sensitive Fields";
                    if FldRef.Number in [FieldMonitoringSetup.FieldNo("User Id"), FieldMonitoringSetup.FieldNo("Monitor Status")] then begin
                        MonitoredFieldNotification.SendEmailNotificationOfSensitiveFieldChange(RecRef, ChangeLogEntry, MonitorFieldNotification);
                        ChangeLogEntry."Notification Status" := MonitorFieldNotification;
                    end;
                end;
        end;
        exit(ChangeLogEntry."Field Log Entry Feature" in [ChangeLogEntry."Field Log Entry Feature"::All, ChangeLogEntry."Field Log Entry Feature"::"Monitor Sensitive Fields"]);
    end;

    local procedure IsMonitoredField(var TempChangeLogSetupField: Record "Change Log Setup (Field)" temporary; Recref: RecordRef; FldRef: FieldRef; IsMonitorEnabled: Boolean): Boolean
    var
        MonitorSensitiveField: Codeunit "Monitor Sensitive Field";
    begin
        if IsMonitorEnabled then
            if TempChangeLogSetupField.Get(RecRef.Number, FldRef.Number) then
                if MonitorSensitiveField.IsValidTable(Recref.Number) then
                    exit(TempChangeLogSetupField."Monitor Sensitive Field");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Change Log Setup (Field)", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertMonitoredField(var Rec: Record "Change Log Setup (Field)"; RunTrigger: Boolean)
    var
        Attributes: Dictionary of [Text, Text];
    begin
        if Rec.IsTemporary then
            exit;

        if Rec."Monitor Sensitive Field" then begin
            Rec.CalcFields("Table Caption");
            Rec.CalcFields("Field Caption");
            Attributes.Add('TableCaption', Rec."Table Caption");
            Attributes.Add('TableNumber', Format(Rec."Table No."));
            Attributes.Add('FieldCaption', Rec."Field Caption");
            Attributes.Add('FieldNumber', Format(Rec."Field No."));
            Session.LogMessage('0000EMW', StrSubstNo(SensitiveFieldVAddedTxt, Rec."Field Caption", Format(Rec."Field No."), Rec."Table Caption", Format(Rec."Table No.")),
                Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Attributes);
        end
    end;

    [EventSubscriber(ObjectType::Table, Database::"Change Log Setup (Field)", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteMonitoredField(var Rec: Record "Change Log Setup (Field)"; RunTrigger: Boolean)
    var
        Attributes: Dictionary of [Text, Text];
    begin
        if Rec.IsTemporary then
            exit;

        if Rec."Monitor Sensitive Field" then begin
            Rec.CalcFields("Table Caption");
            Rec.CalcFields("Field Caption");
            Attributes.Add('TableCaption', Rec."Table Caption");
            Attributes.Add('TableNumber', Format(Rec."Table No."));
            Attributes.Add('FieldCaption', Rec."Field Caption");
            Attributes.Add('FieldNumber', Format(Rec."Field No."));
            Session.LogMessage('0000EMW', StrSubstNo(SensitiveFieldVRemovedTxt, Rec."Field Caption", Format(Rec."Field No."), Rec."Table Caption", Format(Rec."Table No.")),
                Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Attributes);
        end
    end;

    var
        MonitoredFieldNotification: Codeunit "Monitored Field Notification";
        NoAvailablePageMsg: Label 'There is not a page to open for this entry';
        SensitiveFieldValueHasChangedTxt: Label 'Sensitive field value has changed: %1 (%2) in table %3 (%4) ', Locked = true;
        SensitiveFieldVAddedTxt: Label 'Sensitive field added to monitor: %1 (%2) in table %3 (%4)', Locked = true;
        SensitiveFieldVRemovedTxt: Label 'Sensitive field removed from monitor: %1 (%2) in table %3 (%4)', Locked = true;

}