// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

#if not CLEAN30
using System.Reflection;

codeunit 1225 "SEPA Country/Region Sync."
{
    Access = Internal;
    ObsoleteState = Pending;
    ObsoleteTag = '30.0';
    ObsoleteReason = 'Compatibility for the retained SEPA Allowed fields.';

    [EventSubscriber(ObjectType::Table, Database::"Country/Region", 'OnBeforeInsertEvent', '', false, false)]
    local procedure SynchronizeBeforeInsert(var Rec: Record "Country/Region"; RunTrigger: Boolean)
    var
        CountryRegionRef: RecordRef;
        LegacySEPAField: FieldRef;
        LegacyFieldNo: Integer;
        SEPAAllowed: Boolean;
    begin
        if Rec.IsTemporary() then
            exit;

        LegacyFieldNo := GetLegacyFieldNo();
        if LegacyFieldNo = 0 then
            exit;

        CountryRegionRef.GetTable(Rec);
        LegacySEPAField := CountryRegionRef.Field(LegacyFieldNo);
        SEPAAllowed := LegacySEPAField.Value;
        // Either API can initialize a new Boolean field from its default false value.
        SetBothFields(Rec, LegacyFieldNo, Rec."SEPA Payments Allowed" or SEPAAllowed);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Country/Region", 'OnBeforeModifyEvent', '', false, false)]
    local procedure SynchronizeBeforeModify(var Rec: Record "Country/Region"; var xRec: Record "Country/Region"; RunTrigger: Boolean)
    var
        PreviousCountryRegion: Record "Country/Region";
        CountryRegionRef: RecordRef;
        PreviousCountryRegionRef: RecordRef;
        LegacySEPAField: FieldRef;
        LegacyFieldNo: Integer;
        LegacySEPAAllowed: Boolean;
        PreviousLegacySEPAAllowed: Boolean;
    begin
        if Rec.IsTemporary() then
            exit;

        LegacyFieldNo := GetLegacyFieldNo();
        if LegacyFieldNo = 0 then
            exit;

        CountryRegionRef.GetTable(Rec);
        LegacySEPAField := CountryRegionRef.Field(LegacyFieldNo);
        LegacySEPAAllowed := LegacySEPAField.Value;
        if LegacySEPAAllowed = Rec."SEPA Payments Allowed" then
            exit;

        PreviousCountryRegion.ChangeCompany(Rec.CurrentCompany());
        if not PreviousCountryRegion.Get(Rec.Code) then
            exit;
        PreviousCountryRegionRef.GetTable(PreviousCountryRegion);
        LegacySEPAField := PreviousCountryRegionRef.Field(LegacyFieldNo);
        PreviousLegacySEPAAllowed := LegacySEPAField.Value;

        if (Rec."SEPA Payments Allowed" = PreviousCountryRegion."SEPA Payments Allowed") and
           (LegacySEPAAllowed <> PreviousLegacySEPAAllowed)
        then
            SetBothFields(Rec, LegacyFieldNo, LegacySEPAAllowed)
        else
            // The shared field wins if both fields changed or pre-existing data disagrees.
            SetBothFields(Rec, LegacyFieldNo, Rec."SEPA Payments Allowed");
    end;

    local procedure GetLegacyFieldNo(): Integer
    var
        LegacyField: Record Field;
    begin
        LegacyField.SetRange(TableNo, Database::"Country/Region");
        LegacyField.SetFilter("No.", '%1|%2|%3|%4', 10800, 11400, 13400, 2000005);
        LegacyField.SetRange(FieldName, 'SEPA Allowed');
        LegacyField.SetRange(Type, LegacyField.Type::Boolean);
        LegacyField.SetRange(Class, LegacyField.Class::Normal);
        LegacyField.SetFilter(ObsoleteState, '<>%1', LegacyField.ObsoleteState::Removed);
        if LegacyField.FindFirst() then
            exit(LegacyField."No.");
    end;

    local procedure SetBothFields(var CountryRegion: Record "Country/Region"; LegacyFieldNo: Integer; SEPAAllowed: Boolean)
    var
        CountryRegionRef: RecordRef;
        SEPAField: FieldRef;
    begin
        CountryRegion."SEPA Payments Allowed" := SEPAAllowed;
        CountryRegionRef.GetTable(CountryRegion);
        SEPAField := CountryRegionRef.Field(LegacyFieldNo);
        SEPAField.Value := SEPAAllowed;
        CountryRegionRef.SetTable(CountryRegion);
    end;
}
#endif
