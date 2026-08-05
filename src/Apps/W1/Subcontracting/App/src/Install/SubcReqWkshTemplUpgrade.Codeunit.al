// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Requisition;
using System.Upgrade;

#pragma warning disable AS0072, AS0136
codeunit 20572 "Subc. Req Wksh Templ Upgrade"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    begin
        UpgradeReqWkshTemplateType();
    end;

    internal procedure UpgradeReqWkshTemplateType()
    var
        SubcUpgradeTagDefExt: Codeunit "Subc. Upgrade Tag Def. Ext.";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(SubcUpgradeTagDefExt.GetReqWkshTemplateTypeUpgradeTag()) then
            exit;

        MigrateReqWkshTemplateTypeFromLegacyValue();

        UpgradeTag.SetUpgradeTag(SubcUpgradeTagDefExt.GetReqWkshTemplateTypeUpgradeTag());
    end;

    // Idempotent by design: only rows still holding the pre-renumbering raw value are matched,
    // so re-running this after a successful migration (or during reinstall) is a no-op.
    internal procedure MigrateReqWkshTemplateTypeFromLegacyValue()
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        ReqWkshTemplateRecordRef: RecordRef;
        TypeFieldRef: FieldRef;
        PageIDFieldRef: FieldRef;
    begin
        ReqWkshTemplateRecordRef.Open(Database::"Req. Wksh. Template");
        TypeFieldRef := ReqWkshTemplateRecordRef.Field(ReqWkshTemplate.FieldNo("Type"));
        PageIDFieldRef := ReqWkshTemplateRecordRef.Field(ReqWkshTemplate.FieldNo("Page ID"));
        TypeFieldRef.SetRange(LegacySubcontractingTypeValue());
        if ReqWkshTemplateRecordRef.FindSet(true) then
            repeat
                TypeFieldRef.Value := ReqWkshTemplate.Type::Subcontracting.AsInteger();
                PageIDFieldRef.Value := Page::"Subc. Subcontracting Worksheet";
                ReqWkshTemplateRecordRef.Modify();
            until ReqWkshTemplateRecordRef.Next() = 0;
        ReqWkshTemplateRecordRef.Close();
    end;

    local procedure LegacySubcontractingTypeValue(): Integer
    begin
        // Raw value the Subcontracting enum extension value used before the object renumbering (Bug 644283).
        exit(99001500);
    end;
}
#pragma warning restore AS0072, AS0136
