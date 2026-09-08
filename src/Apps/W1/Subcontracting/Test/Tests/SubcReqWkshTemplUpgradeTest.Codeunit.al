// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Subcontracting;

codeunit 139994 "Subc. ReqWkshTemplUpgrade Test"
{
    // [FEATURE] Subcontracting Req. Wksh. Template Type Upgrade
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";

    [Test]
    procedure MigrationConvertsLegacyRawTypeValueToCurrentSubcontractingValue()
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
#pragma warning disable AL0432
        SubcReqWkshTemplUpgrade: Codeunit "Subc. Req Wksh Templ Upgrade";
#pragma warning restore AL0432
    begin
        // [SCENARIO 644283] Migrating "Req. Wksh. Template".Type converts the pre-renumbering raw value (99001500) to the current Subcontracting value (20500)
        Initialize();

        // [GIVEN] A Req. Wksh. Template whose Type field holds the legacy raw value 99001500, seeded through RecordRef/FieldRef
        CreateReqWkshTemplateWithRawTypeValue(ReqWkshTemplate, LegacySubcontractingTypeValue());

        // [WHEN] The Req. Wksh. Template Type migration runs
#pragma warning disable AL0432
        SubcReqWkshTemplUpgrade.MigrateReqWkshTemplateTypeFromLegacyValue();
#pragma warning restore AL0432

        // [THEN] The template's Type is the current, typed Subcontracting value
        ReqWkshTemplate.Get(ReqWkshTemplate.Name);
        Assert.AreEqual(ReqWkshTemplate.Type::Subcontracting, ReqWkshTemplate.Type, 'Type should be converted to the current Subcontracting value.');

        ReqWkshTemplate.Delete();
    end;

    [Test]
    procedure MigrationDoesNotAffectUnrelatedTemplateTypes()
    var
        PlanningReqWkshTemplate: Record "Req. Wksh. Template";
        LegacyReqWkshTemplate: Record "Req. Wksh. Template";
#pragma warning disable AL0432
        SubcReqWkshTemplUpgrade: Codeunit "Subc. Req Wksh Templ Upgrade";
#pragma warning restore AL0432
    begin
        // [SCENARIO 644283] Migrating "Req. Wksh. Template".Type does not touch templates that already have a valid, unrelated Type value
        Initialize();

        // [GIVEN] A Req. Wksh. Template with Type = Planning, set through the normal typed Validate
        CreateReqWkshTemplateWithTypedType(PlanningReqWkshTemplate, PlanningReqWkshTemplate.Type::Planning);

        // [GIVEN] A second Req. Wksh. Template holding the legacy raw value, so the migration has matching data to act on
        CreateReqWkshTemplateWithRawTypeValue(LegacyReqWkshTemplate, LegacySubcontractingTypeValue());

        // [WHEN] The Req. Wksh. Template Type migration runs
#pragma warning disable AL0432
        SubcReqWkshTemplUpgrade.MigrateReqWkshTemplateTypeFromLegacyValue();
#pragma warning restore AL0432

        // [THEN] The unrelated Planning template is unchanged
        PlanningReqWkshTemplate.Get(PlanningReqWkshTemplate.Name);
        Assert.AreEqual(PlanningReqWkshTemplate.Type::Planning, PlanningReqWkshTemplate.Type, 'Unrelated Planning template Type must remain unchanged.');

        PlanningReqWkshTemplate.Delete();
        LegacyReqWkshTemplate.Delete();
    end;

    [Test]
    procedure MigrationRunningTwiceIsHarmless()
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
#pragma warning disable AL0432
        SubcReqWkshTemplUpgrade: Codeunit "Subc. Req Wksh Templ Upgrade";
#pragma warning restore AL0432
    begin
        // [SCENARIO 644283] Running the Req. Wksh. Template Type migration a second time is a harmless no-op (idempotent)
        Initialize();

        // [GIVEN] A Req. Wksh. Template holding the legacy raw value, already migrated once
        CreateReqWkshTemplateWithRawTypeValue(ReqWkshTemplate, LegacySubcontractingTypeValue());
#pragma warning disable AL0432
        SubcReqWkshTemplUpgrade.MigrateReqWkshTemplateTypeFromLegacyValue();
#pragma warning restore AL0432
        ReqWkshTemplate.Get(ReqWkshTemplate.Name);
        Assert.AreEqual(ReqWkshTemplate.Type::Subcontracting, ReqWkshTemplate.Type, 'Type should be converted to the current Subcontracting value after the first run.');

        // [WHEN] The migration runs a second time
#pragma warning disable AL0432
        SubcReqWkshTemplUpgrade.MigrateReqWkshTemplateTypeFromLegacyValue();
#pragma warning restore AL0432

        // [THEN] The Type value remains the current, typed Subcontracting value and no error occurs
        ReqWkshTemplate.Get(ReqWkshTemplate.Name);
        Assert.AreEqual(ReqWkshTemplate.Type::Subcontracting, ReqWkshTemplate.Type, 'Re-running the migration must be harmless and keep the Subcontracting value.');

        ReqWkshTemplate.Delete();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. ReqWkshTemplUpgrade Test");
    end;

    local procedure CreateReqWkshTemplateWithRawTypeValue(var ReqWkshTemplate: Record "Req. Wksh. Template"; RawTypeValue: Integer)
    var
        ReqWkshTemplateRecordRef: RecordRef;
        TypeFieldRef: FieldRef;
    begin
        ReqWkshTemplate.Init();
        ReqWkshTemplate.Name := CopyStr(LibraryUtility.GenerateRandomCode(ReqWkshTemplate.FieldNo(Name), Database::"Req. Wksh. Template"), 1, MaxStrLen(ReqWkshTemplate.Name));
        ReqWkshTemplate.Insert();

        ReqWkshTemplateRecordRef.GetTable(ReqWkshTemplate);
        TypeFieldRef := ReqWkshTemplateRecordRef.Field(ReqWkshTemplate.FieldNo(Type));
        TypeFieldRef.Value := RawTypeValue;
        ReqWkshTemplateRecordRef.Modify();
    end;

    local procedure CreateReqWkshTemplateWithTypedType(var ReqWkshTemplate: Record "Req. Wksh. Template"; TypeValue: Enum "Req. Worksheet Template Type")
    begin
        ReqWkshTemplate.Init();
        ReqWkshTemplate.Validate(Name, CopyStr(LibraryUtility.GenerateRandomCode(ReqWkshTemplate.FieldNo(Name), Database::"Req. Wksh. Template"), 1, MaxStrLen(ReqWkshTemplate.Name)));
        ReqWkshTemplate.Validate(Type, TypeValue);
        ReqWkshTemplate.Insert(true);
    end;

    local procedure LegacySubcontractingTypeValue(): Integer
    begin
        // Raw value the Subcontracting enum extension value used before the object renumbering (Bug 644283).
        exit(99001500);
    end;
}
