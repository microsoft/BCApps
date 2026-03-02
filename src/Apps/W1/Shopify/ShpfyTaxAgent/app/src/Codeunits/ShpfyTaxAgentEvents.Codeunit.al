// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using System.Agents;

/// <summary>
/// Event subscribers that integrate the Tax Matching Agent into the Shopify order processing flow.
/// - Subscribes to OnAfterMapShopifyOrder (fired at the end of DoMapping in OrderMapping codeunit)
/// - Sets orders on hold when mapping succeeds, an enabled agent exists, and order has unmatched tax lines
/// - Creates agent tasks for held orders (includes agent configuration in the task message)
/// - Blocks sales document creation for held orders
/// </summary>
codeunit 30473 "Shpfy Tax Agent Events"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// After a Shopify order is mapped (customer, item, shipping, payment, tax area):
    /// If mapping succeeded, an enabled agent exists for this shop, and the order has unmatched
    /// tax lines, set the order on hold and create an agent task.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Order Events", OnAfterMapShopifyOrder, '', false, false)]
    local procedure OnAfterMapShopifyOrder(var ShopifyOrderHeader: Record "Shpfy Order Header"; Result: Boolean)
    var
        Agent: Record Agent;
        TaxAgentSetup: Record "Shpfy Tax Agent Setup";
        OrderLine: Record "Shpfy Order Line";
        TaxLine: Record "Shpfy Order Tax Line";
        HasUnmatchedTaxLines: Boolean;
    begin
        if not Result then
            exit;

        // Don't create duplicate tasks for orders already on hold
        if ShopifyOrderHeader."On Hold" then
            exit;

        // Verify an enabled agent exists for this shop before putting the order on hold
        if not FindTaxAgentForShop(ShopifyOrderHeader."Shop Code", Agent, TaxAgentSetup) then
            exit;

        // TODO: We should check if there is any agent task already created for this order

        // Check if this order has any tax lines without a Tax Jurisdiction Code (unmatched)
        OrderLine.SetRange("Shopify Order Id", ShopifyOrderHeader."Shopify Order Id");
        if OrderLine.FindSet() then
            repeat
                TaxLine.SetRange("Parent Id", OrderLine."Line Id");
                TaxLine.SetRange("Tax Jurisdiction Code", '');
                if not TaxLine.IsEmpty() then begin
                    HasUnmatchedTaxLines := true;
                    break;
                end;
            until OrderLine.Next() = 0;

        if not HasUnmatchedTaxLines then
            exit;

        // Place order on hold and create agent task
        ShopifyOrderHeader."On Hold" := true;
        ShopifyOrderHeader.Modify();

        CreateAgentTask(Agent, TaxAgentSetup, ShopifyOrderHeader);
    end;

    /// <summary>
    /// Before processing a sales document, block if the order is on hold (awaiting tax matching).
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Order Events", OnBeforeProcessSalesDocument, '', false, false)]
    local procedure OnBeforeProcessSalesDocument(var ShopifyOrderHeader: Record "Shpfy Order Header")
    begin
        if ShopifyOrderHeader."On Hold" then
            Error(OrderOnHoldErr, ShopifyOrderHeader."Shopify Order No.");
    end;

    local procedure CreateAgentTask(Agent: Record Agent; TaxAgentSetup: Record "Shpfy Tax Agent Setup"; ShopifyOrderHeader: Record "Shpfy Order Header")
    var
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        TaskTitle: Text[150];
        TaskMessage: Text;
    begin
        TaskTitle := CopyStr(StrSubstNo(TaskTitleLbl, ShopifyOrderHeader."Shopify Order No."), 1, MaxStrLen(TaskTitle));
        TaskMessage := StrSubstNo(
            TaskMessageLbl,
            ShopifyOrderHeader."Shopify Order No.",
            ShopifyOrderHeader."Ship-to Country/Region Code",
            ShopifyOrderHeader."Ship-to County",
            ShopifyOrderHeader."Shop Code",
            Format(TaxAgentSetup."Auto Create Tax Jurisdictions"),
            Format(TaxAgentSetup."Auto Create Tax Areas"),
            TaxAgentSetup."Tax Area Naming Pattern");

        AgentTaskMessageBuilder
            .Initialize(SystemSenderLbl, TaskMessage);

        AgentTaskBuilder
            .Initialize(Agent."User Security ID", TaskTitle)
            .SetExternalId(Format(ShopifyOrderHeader."Shopify Order Id"))
            .AddTaskMessage(AgentTaskMessageBuilder)
            .Create();
    end;

    local procedure FindTaxAgentForShop(ShopCode: Code[20]; var Agent: Record Agent; var TaxAgentSetup: Record "Shpfy Tax Agent Setup"): Boolean
    begin
        if not TaxAgentSetup.Get(ShopCode) then
            exit(false);

        if not Agent.Get(TaxAgentSetup."User Security ID") then
            exit(false);

        exit(Agent.State = Agent.State::Enabled);
    end;

    var
        TaskTitleLbl: Label 'Tax matching for Shopify order %1', Comment = '%1 is the Shopify order number';
        TaskMessageLbl: Label 'A Shopify order %1 has been imported and placed on hold for tax matching. The order ships to %2, %3. Please match the tax lines to BC Tax Jurisdictions and assign the correct Tax Area.\n\nShop Code: %4\nAuto Create Tax Jurisdictions: %5\nAuto Create Tax Areas: %6\nTax Area Naming Pattern: %7', Comment = '%1=Order No., %2=Country, %3=County/State, %4=Shop Code, %5=Auto Create Jurisdictions, %6=Auto Create Areas, %7=Naming Pattern', Locked = true;
        SystemSenderLbl: Label 'Shopify Connector', Locked = true;
        OrderOnHoldErr: Label 'Shopify order %1 is on hold and cannot be processed into a sales document.', Comment = '%1 is the Shopify order number';
}
