// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Document;

codeunit 28021 "WHT Sales Line"
{

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnValidateNoOnAfterValidateVATProdPostingGroup', '', true, false)]
    local procedure OnValidateNoOnAfterValidateVATProdPostingGroup(var Rec: Record "Sales Line"; var xRec: Record "Sales Line")
    begin
        Rec.Validate("WHT Product Posting Group");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterAssignGLAccountValues', '', true, false)]
    local procedure OnAfterAssignGLAccountValues(var SalesLine: Record "Sales Line"; GLAccount: Record "G/L Account"; SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary)
    begin
        SalesLine."WHT Product Posting Group" := GLAccount."WHT Product Posting Group";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterAssignItemValues', '', true, false)]
    local procedure OnAfterAssignItemValues(var SalesLine: Record "Sales Line"; Item: Record Item; SalesHeader: Record "Sales Header"; var xSalesLine: Record "Sales Line"; CurrentFieldNo: Integer)
    begin
        SalesLine."WHT Product Posting Group" := Item."WHT Product Posting Group";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterAssignResourceValues', '', true, false)]
    local procedure OnAfterAssignResourceValues(var SalesLine: Record "Sales Line"; Resource: Record Resource; SalesHeader: Record "Sales Header")
    begin
        SalesLine."WHT Product Posting Group" := Resource."WHT Product Posting Group";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterAssignItemChargeValues', '', true, false)]
    local procedure OnAfterAssignItemChargeValues(var SalesLine: Record "Sales Line"; ItemCharge: Record "Item Charge"; SalesHeader: Record "Sales Header")
    begin
        SalesLine."WHT Product Posting Group" := ItemCharge."WHT Product Posting Group";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterInitHeaderDefaults', '', true, false)]
    local procedure OnAfterInitHeaderDefaults(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; xSalesLine: Record "Sales Line")
    begin
        SalesLine."WHT Business Posting Group" := SalesHeader."WHT Business Posting Group";
    end;
}
