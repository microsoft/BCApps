// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using System.Environment.Configuration;
using System.Security.Encryption;
using System.Upgrade;
using System.Utilities;

codeunit 148241 "Banking FI Lifecycle Capture"
{
    trigger OnRun()
    begin
        Capture();
    end;

    var
        Assert: Codeunit Assert;
        Tags: Codeunit "Banking Payments Tags FI";
        UpgradeTag: Codeunit "Upgrade Tag";
        TempBlob: Codeunit "Temp Blob";
        Cryptography: Codeunit "Cryptography Management";
        SnapshotExistsErr: Label 'A Finnish banking lifecycle snapshot already exists for this phase. Keep its evidence; use a separate disposable company for another scenario.';
        FixtureCompanyErr: Label 'Run this fixture only in a disposable company whose name starts with FI-UPGRADE-.';
        NonEmptyFixtureErr: Label 'Seed legacy table %1 before capturing the populated-company lifecycle fixture. An empty table is not preservation evidence.', Comment = '%1 = table ID';
        DefaultFixtureErr: Label 'Seed at least one non-default value in legacy table %1 field %2 before capturing this fixture.', Comment = '%1 = table ID, %2 = field number';
        DifferentTargetErr: Label 'Legacy table %1 field %2 needs at least one value different from its replacement before capture; identical values cannot demonstrate that the field was migrated.', Comment = '%1 = table ID, %2 = field number';
        EditedTargetErr: Label 'Change at least one of the 41 migrated target fields so it differs from its retained legacy field before capturing the no-recopy phase.';
        UncopiedRowsErr: Label 'Legacy table %1 needs at least one SystemId absent from replacement table %2 before capture; existing counterparts alone cannot demonstrate a real row copy.', Comment = '%1 = source table ID, %2 = target table ID';
        MissingSchemaErr: Label 'Lifecycle fixture table %1 field %2 is unavailable. Initial migration requires the retained legacy schema; schema absence is not an empty-company fixture.', Comment = '%1 = table ID, %2 = field number';
        UnsupportedFieldErr: Label 'Lifecycle fixture table %1 field %2 has an unsupported content type. Extend the fixture explicitly instead of dropping this field.', Comment = '%1 = table ID, %2 = field number';
        StableVersionErr: Label 'Publish, install or complete the current app data upgrade before capturing this fixture. Metadata and data versions must agree.';
        CompletedVersionErr: Label 'First verify the completed migration at this data version before editing targets and capturing the no-recopy phase.';
        UpgradeRequiredErr: Label 'Run the actual native app data upgrade to a higher version before verification. Publishing, syncing or fabricating a completion tag is not upgrade evidence.';

    [CommitBehavior(CommitBehavior::Error)]
    procedure Capture()
    var
        Snapshot: Record "Banking FI Lifecycle Snapshot";
        Module: ModuleInfo;
        CompletedTarget: Boolean;
    begin
        RequireFixtureCompany();
        GetBankingModule(Module);
        if Module.AppVersion() <> Module.DataVersion() then
            Error(StableVersionErr);
        CompletedTarget := HasCompletedMigration();
        Snapshot.SetRange("Completed Target", CompletedTarget);
        Snapshot.LockTable();
        if not Snapshot.IsEmpty() then
            Error(SnapshotExistsErr);
        if CompletedTarget then begin
            RequireHeaders(false);
            Snapshot.Reset();
            Snapshot.SetRange("Completed Target", false);
            Snapshot.SetRange("Source SystemId", CreateGuidZero());
            Snapshot.FindSet();
            repeat
                if Snapshot."Verified Data Version" <> Format(Module.DataVersion()) then
                    Error(CompletedVersionErr);
            until Snapshot.Next() = 0;
            RequireEditedTarget();
        end else
            RequireInactiveFeature();

        CaptureMappings(CompletedTarget, Format(Module.DataVersion()));
        RequireHeaders(CompletedTarget);
    end;

    [CommitBehavior(CommitBehavior::Error)]
    procedure VerifyUpgrade()
    var
        Snapshot: Record "Banking FI Lifecycle Snapshot";
        Module: ModuleInfo;
        CompletedTarget: Boolean;
    begin
        RequireFixtureCompany();
        GetBankingModule(Module);
        Assert.IsTrue(HasCompletedMigration(), 'Only a completed real migration can be verified.');
#if not CLEAN30
        VerifyActivatedFeature();
#endif
        Snapshot.SetRange("Completed Target", true);
        CompletedTarget := not Snapshot.IsEmpty();
        RequireHeaders(CompletedTarget);
        Snapshot.Reset();
        Snapshot.SetRange("Completed Target", CompletedTarget);
        Snapshot.FindSet(true);
        repeat
            if (Module.AppVersion() <> Module.DataVersion()) or
               (Module.DataVersion() <= Version.Create(Snapshot."Captured Data Version"))
            then
                Error(UpgradeRequiredErr);
            VerifySnapshot(Snapshot, false);
            Snapshot."Verified Data Version" := Format(Module.DataVersion());
            Snapshot.Modify();
        until Snapshot.Next() = 0;
    end;

    [CommitBehavior(CommitBehavior::Error)]
    procedure VerifyRollback()
    var
        Snapshot: Record "Banking FI Lifecycle Snapshot";
        Module: ModuleInfo;
    begin
        RequireFixtureCompany();
        GetBankingModule(Module);
        Assert.IsFalse(HasCompletedMigration(), 'A failed cutover must not retain its completion tag.');
        RequireInactiveFeature();
        RequireHeaders(false);
        Snapshot.SetRange("Completed Target", false);
        Snapshot.FindSet();
        repeat
            Assert.AreEqual(Snapshot."Captured Data Version", Format(Module.DataVersion()), 'A failed upgrade must not advance the installed data version.');
            VerifySnapshot(Snapshot, true);
        until Snapshot.Next() = 0;
    end;

    local procedure CaptureMappings(CompletedTarget: Boolean; DataVersion: Text)
    begin
        CaptureMapping(CompletedTarget, DataVersion, 32000000, 13534, 0, 0);
        CaptureMapping(CompletedTarget, DataVersion, 32000001, 13525, 0, 0);
        CaptureMapping(CompletedTarget, DataVersion, 32000002, 13521, 0, 0);
        CaptureMapping(CompletedTarget, DataVersion, 32000003, 13519, 0, 0);
        CaptureMapping(CompletedTarget, DataVersion, 32000004, 13522, 0, 0);
        CaptureMapping(CompletedTarget, DataVersion, 81, 81, 32000000, 13511);
        CaptureMapping(CompletedTarget, DataVersion, 81, 81, 32000001, 13512);
        CaptureMapping(CompletedTarget, DataVersion, 81, 81, 32000002, 13513);
        CaptureMapping(CompletedTarget, DataVersion, 81, 81, 32000003, 13514);
        CaptureMapping(CompletedTarget, DataVersion, 81, 81, 32000004, 13515);
        CaptureMapping(CompletedTarget, DataVersion, 181, 181, 32000000, 13511);
        CaptureMapping(CompletedTarget, DataVersion, 181, 181, 32000001, 13512);
        CaptureMapping(CompletedTarget, DataVersion, 181, 181, 32000002, 13513);
        CaptureMapping(CompletedTarget, DataVersion, 181, 181, 32000003, 13514);
        CaptureMapping(CompletedTarget, DataVersion, 181, 181, 32000004, 13515);
        CaptureMapping(CompletedTarget, DataVersion, 3, 3, 32000001, 13516);
        CaptureMapping(CompletedTarget, DataVersion, 38, 38, 32000000, 13512);
        CaptureMapping(CompletedTarget, DataVersion, 38, 38, 32000001, 13513);
        CaptureMapping(CompletedTarget, DataVersion, 38, 38, 32000002, 13514);
        CaptureMapping(CompletedTarget, DataVersion, 122, 122, 32000000, 13512);
        CaptureMapping(CompletedTarget, DataVersion, 122, 122, 32000001, 13513);
        CaptureMapping(CompletedTarget, DataVersion, 122, 122, 32000002, 13514);
        CaptureMapping(CompletedTarget, DataVersion, 317, 317, 32000000, 13517);
        CaptureMapping(CompletedTarget, DataVersion, 25, 25, 32000000, 13512);
        CaptureMapping(CompletedTarget, DataVersion, 25, 25, 32000001, 13513);
        CaptureMapping(CompletedTarget, DataVersion, 25, 25, 32000002, 13514);
        CaptureMapping(CompletedTarget, DataVersion, 25, 25, 32000003, 13515);
        CaptureMapping(CompletedTarget, DataVersion, 312, 312, 32000000, 13519);
        CaptureMapping(CompletedTarget, DataVersion, 23, 23, 32000000, 13520);
        CaptureMapping(CompletedTarget, DataVersion, 288, 288, 13400, 13521);
        CaptureMapping(CompletedTarget, DataVersion, 288, 288, 32000001, 13522);
        CaptureMapping(CompletedTarget, DataVersion, 1383, 1383, 32000000, 13520);
        CaptureMapping(CompletedTarget, DataVersion, 287, 287, 32000001, 13522);
        CaptureMapping(CompletedTarget, DataVersion, 112, 112, 32000000, 13511);
        CaptureMapping(CompletedTarget, DataVersion, 21, 21, 32000000, 13511);
        CaptureMapping(CompletedTarget, DataVersion, 21, 21, 32000001, 13516);
        CaptureMapping(CompletedTarget, DataVersion, 297, 297, 32000000, 13511);
        CaptureMapping(CompletedTarget, DataVersion, 298, 298, 32000000, 13511);
        CaptureMapping(CompletedTarget, DataVersion, 296, 296, 32000000, 13511);
        CaptureMapping(CompletedTarget, DataVersion, 311, 311, 32000000, 13523);
        CaptureMapping(CompletedTarget, DataVersion, 311, 311, 32000001, 13524);
        CaptureMapping(CompletedTarget, DataVersion, 311, 311, 32000002, 13525);
        CaptureMapping(CompletedTarget, DataVersion, 311, 311, 32000003, 13526);
        CaptureMapping(CompletedTarget, DataVersion, 311, 311, 32000004, 13527);
        CaptureMapping(CompletedTarget, DataVersion, 311, 311, 32000005, 13528);
        CaptureMapping(CompletedTarget, DataVersion, 5992, 5992, 32000000, 13511);
    end;

    local procedure CaptureMapping(CompletedTarget: Boolean; DataVersion: Text; SourceTableId: Integer; TargetTableId: Integer; SourceFieldNo: Integer; TargetFieldNo: Integer)
    var
        Snapshot: Record "Banking FI Lifecycle Snapshot";
        Source: RecordRef;
        Target: RecordRef;
        Defaults: RecordRef;
        Values: JsonObject;
        Output: OutStream;
        FieldNo: Integer;
        HasNonDefault: Boolean;
        HasDifferentTarget: Boolean;
    begin
        FieldNo := SourceFieldNo;
        if CompletedTarget then begin
            Source.Open(TargetTableId);
            FieldNo := TargetFieldNo;
        end else
            Source.Open(SourceTableId);
        Target.Open(TargetTableId);
        if (FieldNo <> 0) and not Source.FieldExist(FieldNo) then
            Error(MissingSchemaErr, Source.Number(), FieldNo);
        if Source.IsEmpty() then
            Error(NonEmptyFixtureErr, Source.Number());
        Defaults.Open(Source.Number(), true);
        Defaults.Init();

        Snapshot."Completed Target" := CompletedTarget;
        Snapshot."Source Table ID" := SourceTableId;
        Snapshot."Source Field No." := SourceFieldNo;
        Snapshot."Target Table ID" := TargetTableId;
        Snapshot."Target Field No." := TargetFieldNo;
        Snapshot."Captured Data Version" := CopyStr(DataVersion, 1, MaxStrLen(Snapshot."Captured Data Version"));
        Snapshot."Expected Count" := Source.Count();
        Snapshot."Expected Target Count" := Source.Count();
        if not CompletedTarget and (SourceFieldNo = 0) then begin
            Snapshot."Expected Target Count" := CountExpectedTargetRows(Source, Target);
            if Snapshot."Expected Target Count" = Target.Count() then
                Error(UncopiedRowsErr, SourceTableId, TargetTableId);
            Values := ReadTargetBaseline(Target);
            Snapshot."Target Before".CreateOutStream(Output, TextEncoding::UTF8);
            Values.WriteTo(Output);
        end;
        Snapshot.Insert();
        Snapshot."Expected Count" := 0;
        Snapshot."Expected Target Count" := 0;
        Source.FindSet();
        repeat
            Clear(Snapshot.SystemId);
            Clear(Snapshot."Values");
            Clear(Snapshot."Target Before");
            Snapshot."Source SystemId" := Source.Field(2000000000).Value;
            Values := ReadValues(Source, FieldNo);
            Snapshot."Values".CreateOutStream(Output, TextEncoding::UTF8);
            Values.WriteTo(Output);
            if not CompletedTarget and (SourceFieldNo <> 0) then begin
                Values := ReadValues(Source, TargetFieldNo);
                Snapshot."Target Before".CreateOutStream(Output, TextEncoding::UTF8);
                Values.WriteTo(Output);
                HasNonDefault := HasNonDefault or (ReadField(Source.Field(FieldNo)) <> ReadField(Defaults.Field(FieldNo)));
                HasDifferentTarget := HasDifferentTarget or (ReadField(Source.Field(FieldNo)) <> ReadField(Source.Field(TargetFieldNo)));
            end;
            Snapshot.Insert();
        until Source.Next() = 0;
        if not CompletedTarget and (SourceFieldNo <> 0) and not HasNonDefault then
            Error(DefaultFixtureErr, SourceTableId, SourceFieldNo);
        if not CompletedTarget and (SourceFieldNo <> 0) and not HasDifferentTarget then
            Error(DifferentTargetErr, SourceTableId, SourceFieldNo);
        Defaults.Close();
        Target.Close();
        Source.Close();
    end;

    local procedure VerifySnapshot(Snapshot: Record "Banking FI Lifecycle Snapshot"; Rollback: Boolean)
    var
        Source: RecordRef;
        Target: RecordRef;
    begin
        Target.Open(Snapshot."Target Table ID");
        if IsNullGuid(Snapshot."Source SystemId") then begin
            if not Rollback then
                Assert.AreEqual(Snapshot."Expected Target Count", Target.Count(), StrSubstNo('Target table %1 has unexpected rows.', Target.Number()));
            if not Snapshot."Completed Target" and (Snapshot."Source Field No." = 0) then
                VerifyTargetBaseline(Target, Snapshot, Rollback);
            if not Snapshot."Completed Target" then begin
                Source.Open(Snapshot."Source Table ID");
                Assert.AreEqual(Snapshot."Expected Count", Source.Count(), 'Lifecycle migration must not remove or add retained source rows.');
                Source.Close();
            end;
        end else begin
            if not Snapshot."Completed Target" then begin
                Source.Open(Snapshot."Source Table ID");
                Assert.IsTrue(Source.GetBySystemId(Snapshot."Source SystemId"), 'Retained source identity must survive cutover or rollback.');
                VerifyValues(Source, Snapshot, false, Snapshot."Source Field No.");
                Source.Close();
            end;
            if not Rollback or (Snapshot."Source Field No." <> 0) then begin
                Assert.IsTrue(Target.GetBySystemId(Snapshot."Source SystemId"), 'Target rows must preserve their original SystemId.');
                VerifyValues(Target, Snapshot, Rollback, Snapshot."Target Field No.");
            end;
        end;
        Target.Close();
    end;

    local procedure CountExpectedTargetRows(Source: RecordRef; Target: RecordRef) ExpectedCount: Integer
    var
        Identity: Guid;
    begin
        ExpectedCount := Source.Count() + Target.Count();
        Source.FindSet();
        repeat
            Identity := Source.Field(2000000000).Value;
            if Target.GetBySystemId(Identity) then
                ExpectedCount -= 1;
        until Source.Next() = 0;
    end;

    local procedure ReadTargetBaseline(Target: RecordRef): JsonObject
    var
        Baseline: JsonObject;
    begin
        if Target.FindSet() then
            repeat
                Baseline.Add(Format(Target.Field(2000000000).Value, 0, 9), ReadValues(Target, 0));
            until Target.Next() = 0;
        exit(Baseline);
    end;

    local procedure VerifyTargetBaseline(Target: RecordRef; var Snapshot: Record "Banking FI Lifecycle Snapshot"; Rollback: Boolean)
    var
        Baseline: JsonObject;
        ExpectedRow: JsonToken;
        Input: InStream;
        IdentityText: Text;
        Identity: Guid;
    begin
        Snapshot.CalcFields("Target Before");
        Snapshot."Target Before".CreateInStream(Input, TextEncoding::UTF8);
        Baseline.ReadFrom(Input);
        if Rollback then
            Assert.AreEqual(Baseline.Keys().Count(), Target.Count(), 'Failed migration must preserve exactly the pre-existing replacement rows.');
        foreach IdentityText in Baseline.Keys() do begin
            Evaluate(Identity, IdentityText);
            Assert.IsTrue(Target.GetBySystemId(Identity), 'A pre-existing target identity must survive cutover or rollback.');
            Baseline.Get(IdentityText, ExpectedRow);
            VerifyObject(Target, Snapshot, ExpectedRow.AsObject(), 0);
        end;
    end;

    local procedure ReadValues(Reference: RecordRef; FieldNo: Integer): JsonObject
    var
        Values: JsonObject;
        Field: FieldRef;
        Index: Integer;
    begin
        if FieldNo = 0 then begin
            for Index := 1 to Reference.FieldCount() do begin
                Field := Reference.FieldIndex(Index);
                if (Field.Class = FieldClass::Normal) and (Field.Number > 0) and (Field.Number < 2000000000) then
                    Values.Add(Format(Field.Number, 0, 9), ReadField(Field));
            end;
        end else
            Values.Add('value', ReadField(Reference.Field(FieldNo)));
        // Native identity and audit values are compared independently of business-field names.
        for Index := 2000000000 to 2000000004 do
            Values.Add(Format(Index, 0, 9), ReadField(Reference.Field(Index)));
        exit(Values);
    end;

    local procedure ReadField(Field: FieldRef): Text
    var
        Input: InStream;
        Ordinal: Integer;
        HashAlgorithm: Option MD5,SHA1,SHA256,SHA384,SHA512;
    begin
        case Field.Type of
            FieldType::Blob:
                begin
                    Clear(TempBlob);
                    TempBlob.FromFieldRef(Field);
                    TempBlob.CreateInStream(Input);
                    exit(Format(TempBlob.Length(), 0, 9) + ':' + Cryptography.GenerateHash(Input, HashAlgorithm::SHA256));
                end;
            FieldType::Media, FieldType::MediaSet, FieldType::TableFilter:
                Error(UnsupportedFieldErr, Field.Record().Number(), Field.Number);
            FieldType::Option:
                begin
                    Ordinal := Field.Value;
                    exit(Format(Ordinal, 0, 9));
                end;
        end;
        exit(Format(Field.Value, 0, 9));
    end;

    local procedure VerifyValues(Reference: RecordRef; var Snapshot: Record "Banking FI Lifecycle Snapshot"; TargetBefore: Boolean; FieldNo: Integer)
    var
        Expected: JsonObject;
        Input: InStream;
    begin
        if TargetBefore then begin
            Snapshot.CalcFields("Target Before");
            Snapshot."Target Before".CreateInStream(Input, TextEncoding::UTF8);
        end else begin
            Snapshot.CalcFields("Values");
            Snapshot."Values".CreateInStream(Input, TextEncoding::UTF8);
        end;
        Expected.ReadFrom(Input);
        VerifyObject(Reference, Snapshot, Expected, FieldNo);
    end;

    local procedure VerifyObject(Reference: RecordRef; Snapshot: Record "Banking FI Lifecycle Snapshot"; Expected: JsonObject; FieldNo: Integer)
    var
        ExpectedValue: JsonToken;
        ValueKey: Text;
        ValueFieldNo: Integer;
    begin
        Assert.IsTrue(Expected.Keys().Count() > 5, 'Snapshot values must contain business data as well as native identity/audit fields.');
        foreach ValueKey in Expected.Keys() do begin
            if ValueKey = 'value' then
                ValueFieldNo := FieldNo
            else
                Evaluate(ValueFieldNo, ValueKey, 9);
            Assert.IsTrue(Reference.FieldExist(ValueFieldNo), StrSubstNo('Missing target field %1 in table %2.', ValueKey, Reference.Number()));
            Expected.Get(ValueKey, ExpectedValue);
            Assert.AreEqual(ExpectedValue.AsValue().AsText(), ReadField(Reference.Field(ValueFieldNo)),
                StrSubstNo('Lifecycle mismatch: table %1, source field %2, SystemId %3, value %4.', Reference.Number(), Snapshot."Source Field No.", Reference.Field(2000000000).Value, ValueKey));
        end;
    end;

    local procedure RequireHeaders(CompletedTarget: Boolean)
    var
        Snapshot: Record "Banking FI Lifecycle Snapshot";
        Details: Record "Banking FI Lifecycle Snapshot";
    begin
        Snapshot.SetRange("Completed Target", CompletedTarget);
        Snapshot.SetRange("Source SystemId", CreateGuidZero());
        Assert.AreEqual(46, Snapshot.Count(), 'Capture all five table mappings and all 41 field mappings before lifecycle verification.');
        Snapshot.FindSet();
        repeat
            Assert.IsTrue(Snapshot."Expected Count" > 0, 'An empty mapping is not populated-company preservation evidence.');
            Details.SetRange("Completed Target", CompletedTarget);
            Details.SetRange("Source Table ID", Snapshot."Source Table ID");
            Details.SetRange("Source Field No.", Snapshot."Source Field No.");
            Details.SetFilter("Source SystemId", '<>%1', CreateGuidZero());
            Assert.AreEqual(Snapshot."Expected Count", Details.Count(), 'Every captured row must retain its snapshot evidence.');
        until Snapshot.Next() = 0;
    end;

    local procedure RequireEditedTarget()
    var
        Snapshot: Record "Banking FI Lifecycle Snapshot";
        Reference: RecordRef;
        DifferentValue: Boolean;
    begin
        Snapshot.SetRange("Completed Target", false);
        Snapshot.SetFilter("Source Field No.", '>0');
        Snapshot.SetFilter("Source SystemId", '<>%1', CreateGuidZero());
        Snapshot.FindSet();
        repeat
            Reference.Open(Snapshot."Target Table ID");
            Assert.IsTrue(Reference.GetBySystemId(Snapshot."Source SystemId"), 'Migrated target identities must exist before no-recopy capture.');
            if not Reference.FieldExist(Snapshot."Source Field No.") then
                Error(MissingSchemaErr, Reference.Number(), Snapshot."Source Field No.");
            DifferentValue := ReadField(Reference.Field(Snapshot."Target Field No.")) <> ReadField(Reference.Field(Snapshot."Source Field No."));
            Reference.Close();
            if DifferentValue then
                exit;
        until Snapshot.Next() = 0;
        Error(EditedTargetErr);
    end;

    local procedure RequireFixtureCompany()
    begin
        if not CompanyName().StartsWith('FI-UPGRADE-') then
            Error(FixtureCompanyErr);
    end;

    local procedure GetBankingModule(var Module: ModuleInfo)
    var
        AppId: Guid;
    begin
        Evaluate(AppId, '7899cd5a-e428-4835-a1cc-261472c5dcdf');
        NavApp.GetModuleInfo(AppId, Module);
    end;

    local procedure HasCompletedMigration(): Boolean
    begin
        Assert.IsFalse(UpgradeTag.HasUpgradeTagSkipped(Tags.GetMigrationTag(), CopyStr(CompanyName(), 1, 30)), 'A skipped migration tag is not lifecycle completion.');
        exit(UpgradeTag.HasUpgradeTag(Tags.GetMigrationTag()));
    end;

    local procedure RequireInactiveFeature()
    var
        FeatureManagementFacade: Codeunit "Feature Management Facade";
    begin
        Assert.IsFalse(FeatureManagementFacade.IsEnabled('BankingAndPaymentsFI'), 'The before/rollback fixture requires the feature inactive.');
    end;

#if not CLEAN30
    local procedure VerifyActivatedFeature()
    var
        Feature: Codeunit "Banking Payments Feature FI";
    begin
        Feature.EnsureEnabled();
    end;
#endif

    local procedure CreateGuidZero() ZeroGuid: Guid
    begin
        Clear(ZeroGuid);
    end;
}
