namespace System.Diagnostics;

using System.IO;
using System.Security.AccessControl;
using System.Telemetry;

#pragma warning disable AS0018
codeunit 423 "Change Log Management"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = TableData "Change Log Setup" = r,
                  TableData "Change Log Setup (Table)" = r,
                  TableData "Change Log Setup (Field)" = r,
                  TableData "Change Log Entry" = ri,
                  TableData "Field Monitoring Setup" = r;
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        ChangeLogSetup: Record "Change Log Setup";
        FieldMonitoringSetup: Record "Field Monitoring Setup";
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
        TempChangeLogSetupTable: Record "Change Log Setup (Table)" temporary;
        ChangeLogSetupField: Record "Change Log Setup (Field)";
        TempChangeLogSetupField: Record "Change Log Setup (Field)" temporary;
        MonitorSensitiveFieldData: Codeunit "Monitor Sensitive Field Data";
        ChangeLogSetupRead: Boolean;
        MonitorSensitiveFieldSetupRead: Boolean;
        CannotSelectTableErr: Label 'Change log cannot be enabled for the table %1.', Comment = '%1: Table caption.';
        ChangeLogFieldAddedTxt: Label 'Field added to changelog configuration', Locked = true;
        ChangeLogFieldUpdatedTxt: Label 'Field logging changed in changelog configuration', Locked = true;
        ChangeLogFieldDeletedTxt: Label 'Field removed from changelog configuration', Locked = true;
        ChangeLogCategoryLbl: Label 'Change Log', Locked = true;

    procedure GetDatabaseTableTriggerSetup(TableID: Integer; var LogInsert: Boolean; var LogModify: Boolean; var LogDelete: Boolean; var LogRename: Boolean)
    begin
        // Do not add events that allow control of LogInsert, LogModify, LogDelete, LogRename or IsHandled.

        if LogDelete and LogInsert and LogModify and LogRename then
            exit;

        if CompanyName = '' then
            exit;

        if TableID = Database::"Change Log Entry" then
            exit;

        if IsAlwaysLoggedTable(TableID) then begin
            LogInsert := true;
            LogModify := true;
            LogDelete := true;
            LogRename := true;
            exit;
        end;

        if not ChangeLogSetupRead then begin
            if ChangeLogSetup.Get() then;
            ChangeLogSetupRead := true;
        end;

        if not MonitorSensitiveFieldSetupRead then begin
            if FieldMonitoringSetup.Get() then;
            MonitorSensitiveFieldSetupRead := true;
        end;

        if not (ChangeLogSetup."Change Log Activated" or FieldMonitoringSetup."Monitor Status") then
            exit;

        if not TempChangeLogSetupTable.Get(TableID) then begin
            if not ChangeLogSetupTable.Get(TableID) then begin
                TempChangeLogSetupTable.Init();
                TempChangeLogSetupTable."Table No." := TableID;
            end else
                TempChangeLogSetupTable := ChangeLogSetupTable;
            TempChangeLogSetupTable.Insert();
        end;

        if not MonitorSensitiveFieldData.CheckIfTableIsMonitored(TempChangeLogSetupTable, FieldMonitoringSetup, ChangeLogSetup) then
            exit;

        LogInsert := LogInsert or (TempChangeLogSetupTable."Log Insertion" <> TempChangeLogSetupTable."Log Insertion"::" ");
        LogModify := LogModify or (TempChangeLogSetupTable."Log Modification" <> TempChangeLogSetupTable."Log Modification"::" ");
        LogRename := LogRename or (TempChangeLogSetupTable."Log Modification" <> TempChangeLogSetupTable."Log Modification"::" ");
        LogDelete := LogDelete or (TempChangeLogSetupTable."Log Deletion" <> TempChangeLogSetupTable."Log Deletion"::" ");
    end;

    procedure IsLogActive(TableNumber: Integer; FieldNumber: Integer; TypeOfChange: Option Insertion,Modification,Deletion): Boolean
    begin
        // Do not add events that allow control of return value

        if IsAlwaysLoggedTable(TableNumber) then
            exit(true);

        if TableNumber = Database::"Change Log Entry" then
            exit(false);

        if not ChangeLogSetupRead then begin
            if ChangeLogSetup.Get() then;
            ChangeLogSetupRead := true;
        end;

        if not MonitorSensitiveFieldSetupRead then begin
            if FieldMonitoringSetup.Get() then;
            MonitorSensitiveFieldSetupRead := true;
        end;

        if not (ChangeLogSetup."Change Log Activated" or FieldMonitoringSetup."Monitor Status") then
            exit(false);

        if not TempChangeLogSetupTable.Get(TableNumber) then begin
            if not ChangeLogSetupTable.Get(TableNumber) then begin
                TempChangeLogSetupTable.Init();
                TempChangeLogSetupTable."Table No." := TableNumber;
            end else
                TempChangeLogSetupTable := ChangeLogSetupTable;
            TempChangeLogSetupTable.Insert();
        end;

        if not MonitorSensitiveFieldData.CheckIfTableIsMonitored(TempChangeLogSetupTable, FieldMonitoringSetup, ChangeLogSetup) then
            exit(false);

        case TypeOfChange of
            TypeOfChange::Insertion:
                if TempChangeLogSetupTable."Log Insertion" = TempChangeLogSetupTable."Log Insertion"::"Some Fields" then
                    exit(IsFieldLogActive(TableNumber, FieldNumber, TypeOfChange))
                else
                    exit(TempChangeLogSetupTable."Log Insertion" = TempChangeLogSetupTable."Log Insertion"::"All Fields");
            TypeOfChange::Modification:
                if TempChangeLogSetupTable."Log Modification" = TempChangeLogSetupTable."Log Modification"::"Some Fields" then
                    exit(IsFieldLogActive(TableNumber, FieldNumber, TypeOfChange))
                else
                    exit(TempChangeLogSetupTable."Log Modification" = TempChangeLogSetupTable."Log Modification"::"All Fields");
            TypeOfChange::Deletion:
                if TempChangeLogSetupTable."Log Deletion" = TempChangeLogSetupTable."Log Deletion"::"Some Fields" then
                    exit(IsFieldLogActive(TableNumber, FieldNumber, TypeOfChange))
                else
                    exit(TempChangeLogSetupTable."Log Deletion" = TempChangeLogSetupTable."Log Deletion"::"All Fields");
        end;
    end;

    local procedure IsFieldLogActive(TableNumber: Integer; FieldNumber: Integer; TypeOfChange: Option Insertion,Modification,Deletion): Boolean
    begin
        if FieldNumber = 0 then
            exit(true);

        if not TempChangeLogSetupField.Get(TableNumber, FieldNumber) then begin
            if not ChangeLogSetupField.Get(TableNumber, FieldNumber) then begin
                TempChangeLogSetupField.Init();
                TempChangeLogSetupField."Table No." := TableNumber;
                TempChangeLogSetupField."Field No." := FieldNumber;
            end else
                TempChangeLogSetupField := ChangeLogSetupField;
            TempChangeLogSetupField.Insert();
        end;

        if TempChangeLogSetupField."Monitor Sensitive Field" then
            if not FieldMonitoringSetup."Monitor Status" then
                exit(false);

        case TypeOfChange of
            TypeOfChange::Insertion:
                exit(TempChangeLogSetupField."Log Insertion");
            TypeOfChange::Modification:
                exit(TempChangeLogSetupField."Log Modification");
            TypeOfChange::Deletion:
                exit(TempChangeLogSetupField."Log Deletion");
        end;
    end;

    procedure IsAlwaysLoggedTable(TableID: Integer) AlwaysLogTable: Boolean
    begin
        AlwaysLogTable :=
          TableID in
          [Database::User,
           Database::"User Property",
           Database::"Access Control",
           Database::"Permission Set",
           Database::Permission,
           Database::"Change Log Setup",
           Database::"Change Log Setup (Table)",
           Database::"Change Log Setup (Field)",
           9004, // Plan
           9005, // UserPlan
           Database::"Tenant Permission Set Rel.",
           Database::"Tenant Permission Set",
           Database::"Tenant Permission",
           Database::"Field Monitoring Setup"];

        if not AlwaysLogTable then
            OnAfterIsAlwaysLoggedTable(TableID, AlwaysLogTable);
    end;

    procedure InsertLogEntry(var FldRef: FieldRef; var xFldRef: FieldRef; var RecRef: RecordRef; TypeOfChange: Enum "Change Log Entry Type"; IsReadable: Boolean)
    var
        ChangeLogEntry: Record "Change Log Entry";
        KeyFldRef: FieldRef;
        KeyRef1: KeyRef;
        i: Integer;
    begin
        if RecRef.CurrentCompany <> ChangeLogEntry.CurrentCompany then
            ChangeLogEntry.ChangeCompany(RecRef.CurrentCompany);

        if MonitorSensitiveFieldData.IsIgnoredMonitorField(RecRef, FldRef) then
            exit;

        OnInsertLogEntryOnBeforeInitChangeLogEntry(ChangeLogEntry);
        ChangeLogEntry.Init();
        ChangeLogEntry."Date and Time" := CurrentDateTime;
        ChangeLogEntry.Time := DT2Time(ChangeLogEntry."Date and Time");
        ChangeLogEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(ChangeLogEntry."User ID"));
        ChangeLogEntry."Table No." := RecRef.Number;
        ChangeLogEntry."Field No." := FldRef.Number;
        ChangeLogEntry."Type of Change" := TypeOfChange;
        if (RecRef.Number = Database::"User Property") and (FldRef.Number in [2 .. 5]) then begin // Password like
            ChangeLogEntry."Old Value" := '*';
            ChangeLogEntry."New Value" := '*';
        end else begin
            if TypeOfChange <> TypeOfChange::Insertion then
                if IsReadable then
                    ChangeLogEntry."Old Value" := Format(xFldRef.Value, 0, 9)
                else
                    ChangeLogEntry."Old Value" := '';
            if TypeOfChange <> TypeOfChange::Deletion then
                ChangeLogEntry."New Value" := Format(FldRef.Value, 0, 9);
        end;

        ChangeLogEntry."Record ID" := RecRef.RecordId;
        ChangeLogEntry."Primary Key" := CopyStr(RecRef.GetPosition(false), 1, MaxStrLen(ChangeLogEntry."Primary Key"));

        KeyRef1 := RecRef.KeyIndex(1);
        for i := 1 to KeyRef1.FieldCount do begin
            KeyFldRef := KeyRef1.FieldIndex(i);

            case i of
                1:
                    begin
                        ChangeLogEntry."Primary Key Field 1 No." := KeyFldRef.Number;
                        ChangeLogEntry."Primary Key Field 1 Value" :=
                          CopyStr(Format(KeyFldRef.Value, 0, 9), 1, MaxStrLen(ChangeLogEntry."Primary Key Field 1 Value"));
                    end;
                2:
                    begin
                        ChangeLogEntry."Primary Key Field 2 No." := KeyFldRef.Number;
                        ChangeLogEntry."Primary Key Field 2 Value" :=
                          CopyStr(Format(KeyFldRef.Value, 0, 9), 1, MaxStrLen(ChangeLogEntry."Primary Key Field 2 Value"));
                    end;
                3:
                    begin
                        ChangeLogEntry."Primary Key Field 3 No." := KeyFldRef.Number;
                        ChangeLogEntry."Primary Key Field 3 Value" :=
                          CopyStr(Format(KeyFldRef.Value, 0, 9), 1, MaxStrLen(ChangeLogEntry."Primary Key Field 3 Value"));
                    end;
            end;
        end;

        OnInsertLogEntryOnBeforeChangeLogEntryValidateChangedRecordSystemId(ChangeLogEntry, RecRef, FldRef);
        ChangeLogEntry.Validate("Changed Record SystemId", RecRef.Field(RecRef.SystemIdNo).Value);
        MonitorSensitiveFieldData.HandleMonitorSensitiveFields(ChangeLogEntry, TempChangeLogSetupField, RecRef, FldRef, IsAlwaysLoggedTable(RecRef.Number), FieldMonitoringSetup."Monitor Status");

        ChangeLogEntry.Insert(true);
    end;

    procedure LogInsertion(var RecRef: RecordRef)
    var
        FldRef: FieldRef;
        i: Integer;
    begin
        OnBeforeLogInsertion(RecRef);
        if RecRef.IsTemporary then
            exit;

        if not IsLogActive(RecRef.Number, 0, 0) then
            exit;
        for i := 1 to RecRef.FieldCount do begin
            FldRef := RecRef.FieldIndex(i);
            if HasValue(FldRef) then
                if IsNormalField(FldRef) then
                    if IsLogActive(RecRef.Number, FldRef.Number, 0) then
                        InsertLogEntry(FldRef, FldRef, RecRef, "Change Log Entry Type"::Insertion, true);
        end;

        OnAfterLogInsertion(RecRef);
    end;

    procedure LogModification(var RecRef: RecordRef)
    var
        xRecRef: RecordRef;
        FldRef: FieldRef;
        xFldRef: FieldRef;
        i: Integer;
        IsReadable: Boolean;
    begin
        OnBeforeLogModification(RecRef);
        if RecRef.IsTemporary then
            exit;

        if not IsLogActive(RecRef.Number, 0, 1) then
            exit;

        xRecRef.Open(RecRef.Number, false, RecRef.CurrentCompany());
        xRecRef.ReadIsolation := xRecRef.ReadIsolation::ReadCommitted;
        OnLogModificationOnBeforeCheckSecurityFiltering(xRecRef);
        xRecRef."SecurityFiltering" := SECURITYFILTER::Filtered;
        OnLogModificationOnAfterCheckSecurityFiltering(xRecRef);
        if xRecRef.ReadPermission() then begin
            IsReadable := true;
            if not xRecRef.Get(RecRef.RecordId) then
                exit;
        end;

        OnLogModificationOnBeforeRecRefLoopStart(RecRef, xRecRef);
        for i := 1 to RecRef.FieldCount do begin
            FldRef := RecRef.FieldIndex(i);
            xFldRef := xRecRef.FieldIndex(i);
            if IsNormalField(FldRef) then
                if FldRef.Value <> xFldRef.Value then
                    if IsLogActive(RecRef.Number, FldRef.Number, 1) then
                        InsertLogEntry(FldRef, xFldRef, RecRef, "Change Log Entry Type"::Modification, IsReadable);
        end;

        OnAfterLogModification(RecRef);
    end;

    procedure LogRename(var RecRef: RecordRef; var xRecRefParam: RecordRef)
    var
        xRecRef: RecordRef;
        FldRef: FieldRef;
        xFldRef: FieldRef;
        i: Integer;
    begin
        OnBeforeLogRename(RecRef, xRecRefParam);
        if RecRef.IsTemporary then
            exit;

        if not IsLogActive(RecRef.Number, 0, 1) then
            exit;

        xRecRef.Open(xRecRefParam.Number, false, RecRef.CurrentCompany);
        xRecRef.ReadIsolation := xRecRef.ReadIsolation::ReadCommitted;
        xRecRef.Get(xRecRefParam.RecordId);
        for i := 1 to RecRef.FieldCount do begin
            FldRef := RecRef.FieldIndex(i);
            xFldRef := xRecRef.FieldIndex(i);
            if IsNormalField(FldRef) then
                if FldRef.Value <> xFldRef.Value then
                    if IsLogActive(RecRef.Number, FldRef.Number, 1) then
                        InsertLogEntry(FldRef, xFldRef, RecRef, "Change Log Entry Type"::Modification, true);
        end;
    end;

    procedure LogDeletion(var RecRef: RecordRef)
    var
        FldRef: FieldRef;
        i: Integer;
    begin
        OnBeforeLogDeletion(RecRef);
        if RecRef.IsTemporary then
            exit;

        if not IsLogActive(RecRef.Number, 0, 2) then
            exit;
        for i := 1 to RecRef.FieldCount do begin
            FldRef := RecRef.FieldIndex(i);
            if HasValue(FldRef) then
                if IsNormalField(FldRef) then
                    if IsLogActive(RecRef.Number, FldRef.Number, 2) then
                        InsertLogEntry(FldRef, FldRef, RecRef, "Change Log Entry Type"::Deletion, true);
        end;

        OnAfterLogDeletion(RecRef);
    end;

    procedure IsNormalField(FieldRef: FieldRef): Boolean
    begin
        exit(FieldRef.Class = FieldClass::Normal)
    end;

    procedure HasValue(FldRef: FieldRef): Boolean
    var
        HasValue: Boolean;
        Int: Integer;
        Dec: Decimal;
        D: Date;
        T: Time;
    begin
        case FldRef.Type of
            FieldType::Boolean:
                HasValue := FldRef.Value();
            FieldType::Option:
                HasValue := true;
            FieldType::Integer:
                begin
                    Int := FldRef.Value();
                    HasValue := Int <> 0;
                end;
            FieldType::Decimal:
                begin
                    Dec := FldRef.Value();
                    HasValue := Dec <> 0;
                end;
            FieldType::Date:
                begin
                    D := FldRef.Value();
                    HasValue := D <> 0D;
                end;
            FieldType::Time:
                begin
                    T := FldRef.Value();
                    HasValue := T <> 0T;
                end;
            FieldType::BLOB:
                HasValue := false;
            else
                HasValue := Format(FldRef.Value) <> '';
        end;

        exit(HasValue);
    end;

    procedure InitChangeLog()
    begin
        ChangeLogSetupRead := false;
        MonitorSensitiveFieldSetupRead := false;
        TempChangeLogSetupField.DeleteAll();
        TempChangeLogSetupTable.DeleteAll();
    end;

    procedure EvaluateTextToFieldRef(InputText: Text; var FieldRef: FieldRef): Boolean
    var
        DateFormulaVar: DateFormula;
        IntVar: Integer;
        DecimalVar: Decimal;
        DateVar: Date;
        TimeVar: Time;
        DateTimeVar: DateTime;
        BoolVar: Boolean;
        DurationVar: Duration;
        BigIntVar: BigInteger;
        GUIDVar: Guid;
    begin
        if FieldRef.Class in [FieldClass::FlowField, FieldClass::FlowFilter] then
            exit(true);

        case FieldRef.Type of
            FieldType::Integer, FieldType::Option:
                if Evaluate(IntVar, InputText) then begin
                    FieldRef.Value := IntVar;
                    exit(true);
                end;
            FieldType::Decimal:
                if Evaluate(DecimalVar, InputText, 9) then begin
                    FieldRef.Value := DecimalVar;
                    exit(true);
                end;
            FieldType::Date:
                if Evaluate(DateVar, InputText, 9) then begin
                    FieldRef.Value := DateVar;
                    exit(true);
                end;
            FieldType::Time:
                if Evaluate(TimeVar, InputText, 9) then begin
                    FieldRef.Value := TimeVar;
                    exit(true);
                end;
            FieldType::DateTime:
                if Evaluate(DateTimeVar, InputText, 9) then begin
                    FieldRef.Value := DateTimeVar;
                    exit(true);
                end;
            FieldType::Boolean:
                if Evaluate(BoolVar, InputText, 9) then begin
                    FieldRef.Value := BoolVar;
                    exit(true);
                end;
            FieldType::Duration:
                if Evaluate(DurationVar, InputText, 9) then begin
                    FieldRef.Value := DurationVar;
                    exit(true);
                end;
            FieldType::BigInteger:
                if Evaluate(BigIntVar, InputText) then begin
                    FieldRef.Value := BigIntVar;
                    exit(true);
                end;
            FieldType::GUID:
                if Evaluate(GUIDVar, InputText, 9) then begin
                    FieldRef.Value := GUIDVar;
                    exit(true);
                end;
            FieldType::Code, FieldType::Text:
                begin
                    if StrLen(InputText) > FieldRef.Length then begin
                        FieldRef.Value := PadStr(InputText, FieldRef.Length);
                        exit(false);
                    end;
                    FieldRef.Value := InputText;
                    exit(true);
                end;
            FieldType::DateFormula:
                if Evaluate(DateFormulaVar, InputText, 9) then begin
                    FieldRef.Value := DateFormulaVar;
                    exit(true);
                end;
        end;

        exit(false);
    end;

    local procedure AddChangeLogSetupFieldToDimensions(var ChangeLogSetupFieldRec: Record "Change Log Setup (Field)"; var Dimensions: Dictionary of [Text, Text])
    begin
        Dimensions.Add('Category', ChangelogCategoryLbl);
        Dimensions.Add('TableNumber', Format(ChangeLogSetupFieldRec."Table No."));
        Dimensions.Add('TableCaption', ChangeLogSetupFieldRec."Table Caption");
        Dimensions.Add('FieldNumber', Format(ChangeLogSetupFieldRec."Field No."));
        Dimensions.Add('FieldCaption', ChangeLogSetupFieldRec."Field Caption");
        Dimensions.Add('LogInsertion', Format(ChangeLogSetupFieldRec."Log Insertion"));
        Dimensions.Add('LogModification', Format(ChangeLogSetupFieldRec."Log Modification"));
        Dimensions.Add('LogDeletion', Format(ChangeLogSetupFieldRec."Log Deletion"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Change Log Setup (Table)", 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnBeforeInsertChangeLogSetup(var Rec: Record "Change Log Setup (Table)"; RunTrigger: Boolean)
    begin
        if Rec."Table No." = Database::"Change Log Entry" then begin
            Rec.CalcFields("Table Caption");
            Error(CannotSelectTableErr, ChangeLogSetupTable."Table Caption");
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Change Log Setup (Table)", 'OnBeforeRenameEvent', '', false, false)]
    local procedure OnBeforeRenameChangeLogSetup(var Rec: Record "Change Log Setup (Table)"; var xRec: Record "Change Log Setup (Table)"; RunTrigger: Boolean)
    begin
        if Rec."Table No." = Database::"Change Log Entry" then begin
            Rec.CalcFields("Table Caption");
            Error(CannotSelectTableErr, ChangeLogSetupTable."Table Caption");
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Change Log Setup (Field)", 'OnAfterRenameEvent', '', false, false)]
    local procedure OnAfterRenameChangeLogSetupField(var Rec: Record "Change Log Setup (Field)"; var xRec: Record "Change Log Setup (Field)"; RunTrigger: Boolean)
    var
        Telemetry: Codeunit "Telemetry";
        TranslationHelper: Codeunit "Translation Helper";
        Dimensions: Dictionary of [Text, Text];
    begin
        if Rec.IsTemporary then
            exit;

        TranslationHelper.SetGlobalLanguageToDefault();

        AddChangeLogSetupFieldToDimensions(Rec, Dimensions);
        Dimensions.Add('LogInsertionOld', Format(xRec."Log Insertion"));
        Dimensions.Add('LogModificationOld', Format(xRec."Log Modification"));
        Dimensions.Add('LogDeletionOld', Format(xRec."Log Deletion"));
        Telemetry.LogMessage('0000LA0', ChangeLogFieldUpdatedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);

        TranslationHelper.RestoreGlobalLanguage();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Change Log Setup (Field)", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyChangeLogSetupField(var Rec: Record "Change Log Setup (Field)"; var xRec: Record "Change Log Setup (Field)"; RunTrigger: Boolean)
    var
        Telemetry: Codeunit "Telemetry";
        TranslationHelper: Codeunit "Translation Helper";
        Dimensions: Dictionary of [Text, Text];
    begin
        if Rec.IsTemporary then
            exit;

        TranslationHelper.SetGlobalLanguageToDefault();

        AddChangeLogSetupFieldToDimensions(Rec, Dimensions);
        Dimensions.Add('LogInsertionOld', Format(xRec."Log Insertion"));
        Dimensions.Add('LogModificationOld', Format(xRec."Log Modification"));
        Dimensions.Add('LogDeletionOld', Format(xRec."Log Deletion"));
        Telemetry.LogMessage('0000LA1', ChangeLogFieldUpdatedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);

        TranslationHelper.RestoreGlobalLanguage();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Change Log Setup (Field)", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertChangeLogSetupField(var Rec: Record "Change Log Setup (Field)")
    var
        Telemetry: Codeunit "Telemetry";
        TranslationHelper: Codeunit "Translation Helper";
        Dimensions: Dictionary of [Text, Text];
    begin
        if Rec.IsTemporary then
            exit;

        TranslationHelper.SetGlobalLanguageToDefault();

        AddChangeLogSetupFieldToDimensions(Rec, Dimensions);
        Telemetry.LogMessage('0000LA2', ChangeLogFieldAddedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);

        TranslationHelper.RestoreGlobalLanguage();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Change Log Setup (Field)", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteChangeLogSetupField(var Rec: Record "Change Log Setup (Field)")
    var
        Telemetry: Codeunit "Telemetry";
        TranslationHelper: Codeunit "Translation Helper";
        Dimensions: Dictionary of [Text, Text];
    begin
        if Rec.IsTemporary then
            exit;

        TranslationHelper.SetGlobalLanguageToDefault();

        AddChangeLogSetupFieldToDimensions(Rec, Dimensions);
        Telemetry.LogMessage('0000LA3', ChangeLogFieldDeletedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);

        TranslationHelper.RestoreGlobalLanguage();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLogInsertion(var RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLogModification(var RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLogDeletion(var RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertLogEntryOnBeforeChangeLogEntryValidateChangedRecordSystemId(var ChangeLogEntry: Record "Change Log Entry"; RecRef: RecordRef; FldRef: FieldRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLogDeletion(var RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLogInsertion(var RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLogModification(var RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLogRename(var RecRef: RecordRef; var xRecRefParam: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsAlwaysLoggedTable(TableID: Integer; var AlwaysLogTable: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogModificationOnAfterCheckSecurityFiltering(var xRecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogModificationOnBeforeCheckSecurityFiltering(var xRecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogModificationOnBeforeRecRefLoopStart(var RecRef: RecordRef; var xRecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertLogEntryOnBeforeInitChangeLogEntry(var ChangeLogEntry: Record "Change Log Entry")
    begin
    end;
}
#pragma warning restore AS0018

