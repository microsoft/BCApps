// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;

codeunit 28045 "WHT Purchase Line"
{

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnValidateNoOnAfterValidateVATProdPostingGroup', '', true, false)]
    local procedure OnValidateNoOnAfterValidateVATProdPostingGroup(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line")
    begin
        Rec.Validate("WHT Product Posting Group");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterInitHeaderDefaults', '', true, false)]
    local procedure OnAfterInitHeaderDefaults(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header")
    begin
        PurchLine."WHT Business Posting Group" := PurchHeader."WHT Business Posting Group";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnNotHandledCopyFromGLAccount', '', true, false)]
    local procedure OnNotHandledCopyFromGLAccount(var PurchaseLine: Record "Purchase Line"; GLAccount: Record "G/L Account")
    begin
        PurchaseLine."WHT Product Posting Group" := GLAccount."WHT Product Posting Group";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterAssignItemValues', '', true, false)]
    local procedure OnAfterAssignItemValues(var PurchLine: Record "Purchase Line"; Item: Record Item; CurrentFieldNo: Integer; PurchHeader: Record "Purchase Header")
    begin
        PurchLine."WHT Product Posting Group" := Item."WHT Product Posting Group";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterAssignFixedAssetValues', '', true, false)]
    local procedure OnAfterAssignFixedAssetValues(var PurchLine: Record "Purchase Line"; FixedAsset: Record "Fixed Asset"; PurchHeader: Record "Purchase Header")
    begin
        PurchLine."WHT Product Posting Group" := FixedAsset."WHT Product Posting Group";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterAssignItemChargeValues', '', true, false)]
    local procedure OnAfterAssignItemChargeValues(var PurchLine: Record "Purchase Line"; ItemCharge: Record "Item Charge"; PurchHeader: Record "Purchase Header")
    begin
        PurchLine."WHT Product Posting Group" := ItemCharge."WHT Product Posting Group";
    end;

}