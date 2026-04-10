// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using System.Environment.Configuration;
using System.Reflection;

codeunit 702 "Sync.Dep.Fld-Utilities"
{
    Access = Public;

    trigger OnRun()
    begin

    end;

    /// <summary>
    /// Gets the previous record - xRec is not the previous version of the record it is the previous record on the page.
    /// If the update was not started from page, xRec will be same as the Rec.
    /// This function MUST be called before the update of the record is done, for example from OnBeforeModify trigger.
    /// </summary>
    /// <param name="CurrentRecord">Current record that we want to get a previous version of.</param>
    /// <param name="PreviousRecordRef">Previous record.</param>
    /// <returns>A boolean that indicates whether the previous record exists.</returns>
    procedure GetPreviousRecord(CurrentRecord: variant; var PreviousRecordRef: RecordRef): Boolean
    var
        DataTypeManagement: Codeunit "Data Type Management";
        CurrentRecordRef: RecordRef;
    begin
        if not DataTypeManagement.GetRecordRef(CurrentRecord, CurrentRecordRef) then
            exit(false);

        if CurrentRecordRef.IsTemporary() then
            exit(false);

        PreviousRecordRef.Open(CurrentRecordRef.Number());

        if not PreviousRecordRef.GetBySystemId(CurrentRecordRef.Field(CurrentRecordRef.SystemIdNo()).Value) then begin
            PreviousRecordRef.Init();
            exit(false);
        end;

        exit(true);
    end;

    /// <summary>
    /// Check if synchronization is disabled.
    /// By default is disabled when install or upgrade is in progress.
    /// In that cases is not suitable to run synchronization.
    /// </summary>
    /// <returns>A boolean that indicates whether the synchronization is disabled.</returns>
    procedure IsFieldSynchronizationDisabled() FieldSynchronizationDisabled: Boolean
    var
        DataUpgradeMgt: Codeunit "Data Upgrade Mgt.";
    begin
        FieldSynchronizationDisabled := NavApp.IsInstalling() or DataUpgradeMgt.IsUpgradeInProgress();
        OnAfterIsFieldSynchronizationDisabled(FieldSynchronizationDisabled);
    end;

    procedure SyncFields(var ObsoleteFieldValue: Boolean; var ValidFieldValue: Boolean)
    begin
        if ObsoleteFieldValue = ValidFieldValue then
            exit;

        if ValidFieldValue then
            ObsoleteFieldValue := ValidFieldValue;
        if ObsoleteFieldValue then
            ValidFieldValue := ObsoleteFieldValue;
    end;

    procedure SyncFields(var ObsoleteFieldValue: Boolean; var ValidFieldValue: Boolean; PrevObsoleteFieldValue: Boolean; PrevValidFieldValue: Boolean)
    begin
        if ObsoleteFieldValue = ValidFieldValue then
            exit;

        if (ObsoleteFieldValue = PrevObsoleteFieldValue) and (ValidFieldValue = PrevValidFieldValue) then
            exit;

        if ValidFieldValue <> PrevValidFieldValue then
            ObsoleteFieldValue := ValidFieldValue
        else
            if ObsoleteFieldValue <> PrevObsoleteFieldValue then
                ValidFieldValue := ObsoleteFieldValue
            else
                ObsoleteFieldValue := ValidFieldValue;
    end;

    procedure SyncFieldsCode10(var ObsoleteFieldValue: Code[10]; var ValidFieldValue: Code[10])
    begin
        if ObsoleteFieldValue = ValidFieldValue then
            exit;

        if ValidFieldValue <> '' then
            ObsoleteFieldValue := ValidFieldValue;
        if ObsoleteFieldValue <> '' then
            ValidFieldValue := ObsoleteFieldValue;
    end;

    procedure SyncFieldsCode10(var ObsoleteFieldValue: Code[10]; var ValidFieldValue: Code[10]; PrevObsoleteFieldValue: Code[10]; PrevValidFieldValue: Code[10])
    begin
        if ObsoleteFieldValue = ValidFieldValue then
            exit;

        if (ObsoleteFieldValue = PrevObsoleteFieldValue) and (ValidFieldValue = PrevValidFieldValue) then
            exit;

        if ValidFieldValue <> PrevValidFieldValue then
            ObsoleteFieldValue := ValidFieldValue
        else
            if ObsoleteFieldValue <> PrevObsoleteFieldValue then
                ValidFieldValue := ObsoleteFieldValue
            else
                ObsoleteFieldValue := ValidFieldValue;
    end;


    procedure SyncFieldsCode20(var ObsoleteFieldValue: Code[20]; var ValidFieldValue: Code[20])
    begin
        if ObsoleteFieldValue = ValidFieldValue then
            exit;

        if ValidFieldValue <> '' then
            ObsoleteFieldValue := ValidFieldValue;
        if ObsoleteFieldValue <> '' then
            ValidFieldValue := ObsoleteFieldValue;
    end;

    procedure SyncFieldsCode20(var ObsoleteFieldValue: Code[20]; var ValidFieldValue: Code[20]; PrevObsoleteFieldValue: Code[20]; PrevValidFieldValue: Code[20])
    begin
        if ObsoleteFieldValue = ValidFieldValue then
            exit;

        if (ObsoleteFieldValue = PrevObsoleteFieldValue) and (ValidFieldValue = PrevValidFieldValue) then
            exit;

        if ValidFieldValue <> PrevValidFieldValue then
            ObsoleteFieldValue := ValidFieldValue
        else
            if ObsoleteFieldValue <> PrevObsoleteFieldValue then
                ValidFieldValue := ObsoleteFieldValue
            else
                ObsoleteFieldValue := ValidFieldValue;
    end;

    procedure SyncFields(var ObsoleteFieldValue: Text; var ValidFieldValue: Text)
    begin
        if ObsoleteFieldValue = ValidFieldValue then
            exit;

        if ValidFieldValue <> '' then
            ObsoleteFieldValue := ValidFieldValue;
        if ObsoleteFieldValue <> '' then
            ValidFieldValue := ObsoleteFieldValue;
    end;

    procedure SyncFields(var ObsoleteFieldValue: Text; var ValidFieldValue: Text; PrevObsoleteFieldValue: Text; PrevValidFieldValue: Text)
    begin
        if ObsoleteFieldValue = ValidFieldValue then
            exit;

        if (ObsoleteFieldValue = PrevObsoleteFieldValue) and (ValidFieldValue = PrevValidFieldValue) then
            exit;

        if ValidFieldValue <> PrevValidFieldValue then
            ObsoleteFieldValue := ValidFieldValue
        else
            if ObsoleteFieldValue <> PrevObsoleteFieldValue then
                ValidFieldValue := ObsoleteFieldValue
            else
                ObsoleteFieldValue := ValidFieldValue;
    end;

    procedure SyncFields(var ObsoleteFieldValue: Date; var ValidFieldValue: Date; PrevObsoleteFieldValue: Date; PrevValidFieldValue: Date)
    begin
        if ObsoleteFieldValue = ValidFieldValue then
            exit;

        if (ObsoleteFieldValue = PrevObsoleteFieldValue) and (ValidFieldValue = PrevValidFieldValue) then
            exit;

        if ValidFieldValue <> PrevValidFieldValue then
            ObsoleteFieldValue := ValidFieldValue
        else
            if ObsoleteFieldValue <> PrevObsoleteFieldValue then
                ValidFieldValue := ObsoleteFieldValue
            else
                ObsoleteFieldValue := ValidFieldValue;
    end;

    procedure SyncFields(var ObsoleteFieldValue: DateTime; var ValidFieldValue: DateTime; PrevObsoleteFieldValue: DateTime; PrevValidFieldValue: DateTime)
    begin
        if ObsoleteFieldValue = ValidFieldValue then
            exit;

        if (ObsoleteFieldValue = PrevObsoleteFieldValue) and (ValidFieldValue = PrevValidFieldValue) then
            exit;

        if ValidFieldValue <> PrevValidFieldValue then
            ObsoleteFieldValue := ValidFieldValue
        else
            if ObsoleteFieldValue <> PrevObsoleteFieldValue then
                ValidFieldValue := ObsoleteFieldValue
            else
                ObsoleteFieldValue := ValidFieldValue;
    end;

    procedure SyncFields(var ObsoleteFieldValue: Integer; var ValidFieldValue: Integer)
    begin
        if ObsoleteFieldValue = ValidFieldValue then
            exit;

        if ValidFieldValue <> 0 then
            ObsoleteFieldValue := ValidFieldValue;
        if ObsoleteFieldValue <> 0 then
            ValidFieldValue := ObsoleteFieldValue;
    end;

    procedure SyncFields(var ObsoleteFieldValue: Integer; var ValidFieldValue: Integer; PrevObsoleteFieldValue: Integer; PrevValidFieldValue: Integer)
    begin
        if ObsoleteFieldValue = ValidFieldValue then
            exit;

        if (ObsoleteFieldValue = PrevObsoleteFieldValue) and (ValidFieldValue = PrevValidFieldValue) then
            exit;

        if ValidFieldValue <> PrevValidFieldValue then
            ObsoleteFieldValue := ValidFieldValue
        else
            if ObsoleteFieldValue <> PrevObsoleteFieldValue then
                ValidFieldValue := ObsoleteFieldValue
            else
                ObsoleteFieldValue := ValidFieldValue;
    end;

    procedure SyncFields(var ObsoleteFieldValue: Decimal; var ValidFieldValue: Decimal; PrevObsoleteFieldValue: Decimal; PrevValidFieldValue: Decimal)
    begin
        if ObsoleteFieldValue = ValidFieldValue then
            exit;

        if (ObsoleteFieldValue = PrevObsoleteFieldValue) and (ValidFieldValue = PrevValidFieldValue) then
            exit;

        if ValidFieldValue <> PrevValidFieldValue then
            ObsoleteFieldValue := ValidFieldValue
        else
            if ObsoleteFieldValue <> PrevObsoleteFieldValue then
                ValidFieldValue := ObsoleteFieldValue
            else
                ObsoleteFieldValue := ValidFieldValue;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsFieldSynchronizationDisabled(var FieldSynchronizationDisabled: Boolean)
    begin
    end;
}