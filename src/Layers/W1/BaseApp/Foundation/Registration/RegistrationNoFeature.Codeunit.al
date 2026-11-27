// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Registration;

using Microsoft.Foundation.Company;
using System.Environment.Configuration;

codeunit 7403 "Registration No. Feature" implements "Feature Data Update"
{
    Permissions = tabledata "Feature Data Update Status" = r;

    var
        FeatureKeyTok: Label 'GlobalRegistrationNumbers', Locked = true, MaxLength = 50;
        FeatureDisabledErr: Label 'Enable the global registration numbers feature in Feature Management before using this page.';
        CannotDisableErr: Label 'The global registration numbers feature cannot be disabled after a company has completed its data update.';
        DescriptionTxt: Label 'Review localized legal registration numbers before activating the global registration framework. Each differing value requires an explicit decision. Posted documents are not migrated.';
        PendingReviewErr: Label 'Review the registration number migration for %1 and choose a resolution before activating the feature.', Comment = '%1 = Record ID';
        ChangedRecordErr: Label 'Registration data for %1 changed after review. Refresh the registration number migration and review it again.', Comment = '%1 = Record ID';
        NumberTooLongErr: Label 'The registration number exceeds the maximum length of %1 characters.', Comment = '%1 = Maximum registration number length';
        InvalidMappingErr: Label 'The registration number migration mapping for %1 is no longer available. Refresh the migration review.', Comment = '%1 = Record ID';

    procedure GetFeatureKey(): Text[50]
    begin
        exit(FeatureKeyTok);
    end;

    procedure IsEnabled(): Boolean
    var
        FeatureKey: Record "Feature Key";
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        FeatureManagementFacade: Codeunit "Feature Management Facade";
    begin
        if not FeatureKey.Get(GetFeatureKey()) then
            exit(false);
        if FeatureKey.Enabled <> FeatureKey.Enabled::"All Users" then
            exit(false);
        if not FeatureManagementFacade.IsEnabled(GetFeatureKey(), false) then
            exit(false);
        if not FeatureDataUpdateStatus.Get(GetFeatureKey(), CompanyName()) then
            exit(false);
        exit(FeatureDataUpdateStatus."Feature Status" = FeatureDataUpdateStatus."Feature Status"::Complete);
    end;

    procedure IsDataUpdateRequired(): Boolean
    begin
        exit(true);
    end;

    procedure CheckEnabled()
    begin
        if not IsEnabled() then
            Error(FeatureDisabledErr);
    end;

    procedure ReviewData()
    begin
        Commit();
        Page.RunModal(Page::"Registration No. Migration");
    end;

    procedure GetTaskDescription(): Text
    begin
        exit(DescriptionTxt);
    end;

    procedure AfterUpdate(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    begin
    end;

    [CommitBehavior(CommitBehavior::Error)]
    procedure UpdateData(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        Migration: Record "Registration No. Migration";
        TempCurrentMigration: Record "Registration No. Migration" temporary;
        FeatureDataUpdateMgt: Codeunit "Feature Data Update Mgt.";
        StartDateTime: DateTime;
    begin
        StartDateTime := CurrentDateTime();
        RefreshMigration();
        Migration.SetRange(Resolution, Migration.Resolution::Pending);
        if Migration.FindFirst() then
            Error(PendingReviewErr, Migration."Record ID");
        CollectMigrationCandidates(TempCurrentMigration);
        Migration.Reset();
        if Migration.FindSet(true) then
            repeat
                ApplyResolution(Migration, TempCurrentMigration);
            until Migration.Next() = 0;
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, Migration.TableCaption(), StartDateTime);
    end;

    procedure RefreshMigration()
    var
        Migration: Record "Registration No. Migration";
        TempMigration: Record "Registration No. Migration" temporary;
    begin
        CollectMigrationCandidates(TempMigration);
        Migration.LockTable();
        if Migration.FindSet(true) then
            repeat
                if not TempMigration.Get(Migration."Record ID") then
                    Migration.Delete();
            until Migration.Next() = 0;
        TempMigration.Reset();
        if TempMigration.FindSet() then
            repeat
                if Migration.Get(TempMigration."Record ID") then begin
                    if not SameValues(Migration, TempMigration) then begin
                        Migration := TempMigration;
                        Migration.Modify();
                    end;
                end else begin
                    Migration := TempMigration;
                    Migration.Insert();
                end;
            until TempMigration.Next() = 0;
    end;

    local procedure CollectMigrationCandidates(var TempMigration: Record "Registration No. Migration" temporary)
    var
        CompanyInformation: Record "Company Information";
    begin
        OnCollectMigrationCandidates(TempMigration);
        if CompanyInformation.Get() then
            if not TempMigration.Get(CompanyInformation.RecordId) then
                AddMigrationCandidate(
                    TempMigration, CompanyInformation, CompanyInformation.FieldNo("Registration No."),
                    CompanyInformation.FieldNo("Registration Number"), CompanyInformation.FieldNo("Country/Region Code"));
    end;

    procedure AddMigrationCandidate(var TempMigration: Record "Registration No. Migration" temporary; SourceRecord: Variant; LocalFieldNo: Integer; RegistrationFieldNo: Integer; CountryFieldNo: Integer)
    var
        SourceRecordRef: RecordRef;
        LocalRegistrationNo: Text;
        RegistrationNo: Text;
    begin
        SourceRecordRef.GetTable(SourceRecord);
        LocalRegistrationNo := SourceRecordRef.Field(LocalFieldNo).Value;
        RegistrationNo := SourceRecordRef.Field(RegistrationFieldNo).Value;
        if (LocalRegistrationNo = '') or (LocalRegistrationNo = RegistrationNo) then
            exit;
        if (StrLen(LocalRegistrationNo) > MaxStrLen(TempMigration."Local Registration No.")) or
           (StrLen(RegistrationNo) > MaxStrLen(TempMigration."Registration Number"))
        then
            Error(NumberTooLongErr, MaxStrLen(TempMigration."Registration Number"));
        TempMigration.Init();
        TempMigration."Record ID" := SourceRecordRef.RecordId;
        TempMigration."Record Type" := CopyStr(SourceRecordRef.Caption, 1, MaxStrLen(TempMigration."Record Type"));
        TempMigration."Local Registration No." := CopyStr(LocalRegistrationNo, 1, MaxStrLen(TempMigration."Local Registration No."));
        TempMigration."Registration Number" := CopyStr(RegistrationNo, 1, MaxStrLen(TempMigration."Registration Number"));
        TempMigration."Country/Region Code" := SourceRecordRef.Field(CountryFieldNo).Value;
        TempMigration."Local Field No." := LocalFieldNo;
        TempMigration."Registration Field No." := RegistrationFieldNo;
        TempMigration."Country Field No." := CountryFieldNo;
        TempMigration.Insert();
    end;

    local procedure SameValues(Migration: Record "Registration No. Migration"; CurrentMigration: Record "Registration No. Migration"): Boolean
    begin
        exit(
            (Migration."Local Registration No." = CurrentMigration."Local Registration No.") and
            (Migration."Registration Number" = CurrentMigration."Registration Number") and
            (Migration."Country/Region Code" = CurrentMigration."Country/Region Code") and
            (Migration."Local Field No." = CurrentMigration."Local Field No.") and
            (Migration."Registration Field No." = CurrentMigration."Registration Field No.") and
            (Migration."Country Field No." = CurrentMigration."Country Field No."));
    end;

    local procedure ApplyResolution(Migration: Record "Registration No. Migration"; var TempCurrentMigration: Record "Registration No. Migration" temporary)
    var
        RegistrationNoMgt: Codeunit "Registration No. Mgt.";
        SourceRecordRef: RecordRef;
        RegistrationField: FieldRef;
    begin
        if not (Migration.Resolution in [Migration.Resolution::"Use Local", Migration.Resolution::"Keep W1"]) then
            Error(PendingReviewErr, Migration."Record ID");
        SourceRecordRef.Open(Migration."Record ID".TableNo);
        SourceRecordRef.LockTable();
        SourceRecordRef.Get(Migration."Record ID");
        if not TempCurrentMigration.Get(Migration."Record ID") then
            Error(InvalidMappingErr, Migration."Record ID");
        if not SameValues(Migration, TempCurrentMigration) then
            Error(ChangedRecordErr, Migration."Record ID");
        if (Format(SourceRecordRef.Field(Migration."Local Field No.").Value) <> Migration."Local Registration No.") or
           (Format(SourceRecordRef.Field(Migration."Registration Field No.").Value) <> Migration."Registration Number") or
           (Format(SourceRecordRef.Field(Migration."Country Field No.").Value) <> Migration."Country/Region Code")
        then
            Error(ChangedRecordErr, Migration."Record ID");
        if Migration.Resolution = Migration.Resolution::"Use Local" then begin
            RegistrationField := SourceRecordRef.Field(Migration."Registration Field No.");
            RegistrationField.Validate(Migration."Local Registration No.");
            if Format(RegistrationField.Value) <> Migration."Local Registration No." then
                Error(ChangedRecordErr, Migration."Record ID");
            RegistrationNoMgt.ValidateMigrationRegistrationNo(Migration."Local Registration No.", Migration."Country/Region Code", Migration."Record ID");
            SourceRecordRef.Modify(true);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCollectMigrationCandidates(var TempMigration: Record "Registration No. Migration" temporary)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Feature Management Facade", 'OnAfterFeatureDisableConfirmed', '', false, false)]
    local procedure PreventDisableAfterMigration(FeatureKey: Record "Feature Key")
    var
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
    begin
        if FeatureKey.ID <> GetFeatureKey() then
            exit;
        FeatureDataUpdateStatus.SetRange("Feature Key", GetFeatureKey());
        FeatureDataUpdateStatus.SetRange("Feature Status", FeatureDataUpdateStatus."Feature Status"::Complete);
        if not FeatureDataUpdateStatus.IsEmpty() then
            Error(CannotDisableErr);
    end;
}
