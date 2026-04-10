namespace Microsoft.API.Upgrade;

using Microsoft.Integration.Graph;
using Microsoft.Purchases.Document;
using Microsoft.Upgrade;
using System.Upgrade;

codeunit 5518 "API Fix Purchase Order"
{
    trigger OnRun()
    begin
        UpdateAPIPurchOrders();
    end;

    procedure UpdateAPIPurchOrders()
    var
        PurchaseHeader: Record "Purchase Header";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        GraphMgtPurchOrderBuffer: Codeunit "Graph Mgt - Purch Order Buffer";
    begin
        if PurchaseHeader.FindSet() then
            repeat
                GraphMgtPurchOrderBuffer.InsertOrModifyFromPurchaseHeader(PurchaseHeader);
            until PurchaseHeader.Next() = 0;

        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetNewPurchaseOrderEntityBufferUpgradeTag()) then
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetNewPurchaseOrderEntityBufferUpgradeTag());
    end;

}