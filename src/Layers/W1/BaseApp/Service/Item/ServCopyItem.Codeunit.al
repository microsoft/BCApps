// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Service.Maintenance;
using Microsoft.Service.Resources;

codeunit 6472 "Serv. Copy Item"
{
    var
        CopyItem: Codeunit "Copy Item";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Item", 'OnAfterCopyItem', '', false, false)]
    local procedure OnAfterCopyItem(var CopyItemBuffer: Record "Copy Item Buffer"; SourceItem: Record Item; var TargetItem: Record Item)
    begin
        CopyTroubleshootingSetup(SourceItem."No.", TargetItem."No.", CopyItemBuffer);
        CopyItemResourceSkills(SourceItem."No.", TargetItem."No.", CopyItemBuffer);
    end;

    local procedure CopyTroubleshootingSetup(FromItemNo: Code[20]; ToItemNo: Code[20]; var CopyItemBuffer: Record "Copy Item Buffer")
    var
        TroubleshootingSetup: Record "Troubleshooting Setup";
        RecRef: RecordRef;
    begin
        if not CopyItemBuffer.Troubleshooting then
            exit;

        TroubleshootingSetup.SetRange(Type, TroubleshootingSetup.Type::Item);

        RecRef.GetTable(TroubleshootingSetup);
        CopyItem.CopyItemRelatedTableFromRecRef(RecRef, TroubleshootingSetup.FieldNo("No."), FromItemNo, ToItemNo);
    end;

    local procedure CopyItemResourceSkills(FromItemNo: Code[20]; ToItemNo: Code[20]; var CopyItemBuffer: Record "Copy Item Buffer")
    var
        ResourceSkill: Record "Resource Skill";
        RecRef: RecordRef;
    begin
        if not CopyItemBuffer."Resource Skills" then
            exit;

        ResourceSkill.SetRange(Type, ResourceSkill.Type::Item);

        RecRef.GetTable(ResourceSkill);
        CopyItem.CopyItemRelatedTableFromRecRef(RecRef, ResourceSkill.FieldNo("No."), FromItemNo, ToItemNo);
    end;
}
