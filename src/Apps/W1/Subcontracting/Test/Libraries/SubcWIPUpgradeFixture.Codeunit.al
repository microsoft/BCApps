// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Purchases.Document;

codeunit 149928 "Subc. WIP Upgrade Fixture"
{
    Access = Internal;
    Subtype = Upgrade;

    [CommitBehavior(CommitBehavior::Error)]
    internal procedure UseLegacySummaryOrder(var ProductionOrder: Record "Production Order")
    var
        Lineage: Record "Subc. WIP Lineage";
        RoutingLine: Record "Prod. Order Routing Line";
        Entry: Record "Subcontractor WIP Ledger Entry";
        PurchaseLine: Record "Purchase Line";
        Transfer: DataTransfer;
        EmptyGuid: Guid;
    begin
        Entry.SetProductionOrderFilter(ProductionOrder, false);
        if not Entry.IsEmpty() then
            Error('Prepare the summary cohort before posting WIP.');
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        if not PurchaseLine.IsEmpty() then
            Error('Prepare the summary cohort before creating purchase lines.');
        // The summary's pre-activation receipt fixtures intentionally retain unsplit legacy custody.
        // Restrict this upgrade-only fixture to the freshly created order, never company-wide activation.
        Lineage.Get(ProductionOrder."Subc. WIP Lineage ID");
        Lineage.Cohort := Lineage.Cohort::Legacy;
        Lineage.Modify();
        Transfer.SetTables(Database::"Production Order", Database::"Production Order");
        Transfer.AddSourceFilter(ProductionOrder.FieldNo(Status), '%1', ProductionOrder.Status);
        Transfer.AddSourceFilter(ProductionOrder.FieldNo("No."), '%1', ProductionOrder."No.");
        Transfer.AddConstantValue("Subc. WIP Cohort"::Legacy, ProductionOrder.FieldNo("Subc. WIP Cohort"));
        Transfer.CopyFields();
        Clear(Transfer);
        Transfer.SetTables(Database::"Prod. Order Routing Line", Database::"Prod. Order Routing Line");
        Transfer.AddSourceFilter(RoutingLine.FieldNo(Status), '%1', ProductionOrder.Status);
        Transfer.AddSourceFilter(RoutingLine.FieldNo("Prod. Order No."), '%1', ProductionOrder."No.");
        Transfer.AddConstantValue(EmptyGuid, RoutingLine.FieldNo("Subc. WIP Lineage ID"));
        Transfer.CopyFields();
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
    end;

    [CommitBehavior(CommitBehavior::Error)]
    internal procedure RestorePreactivationColumns()
    var
        ProductionOrder: Record "Production Order";
        RoutingLine: Record "Prod. Order Routing Line";
        Activation: Record "Subc. WIP Activation";
        Alias: Record "Subc. WIP Order Alias";
        Lineage: Record "Subc. WIP Lineage";
        Entry: Record "Subcontractor WIP Ledger Entry";
        Transfer: DataTransfer;
        EmptyGuid: Guid;
    begin
        Entry.SetRange("State Tracked", true);
        if not Entry.IsEmpty() then
            Error('Prepare the upgrade fixture before posting StateV1 WIP.');
        // Model the old schema's defaults without adding a bypass to production identity guards.
        // Call only in rollback-isolated tests, before posting any StateV1 WIP.
        Transfer.SetTables(Database::"Production Order", Database::"Production Order");
        Transfer.AddConstantValue(0, ProductionOrder.FieldNo("Subc. WIP Cohort"));
        Transfer.AddConstantValue(EmptyGuid, ProductionOrder.FieldNo("Subc. WIP Lineage ID"));
        Transfer.AddConstantValue(0, ProductionOrder.FieldNo("Subc. WIP Version"));
        Transfer.AddConstantValue(EmptyGuid, ProductionOrder.FieldNo("Subc. Continuation Token"));
        Transfer.CopyFields();
        Clear(Transfer);
        Transfer.SetTables(Database::"Prod. Order Routing Line", Database::"Prod. Order Routing Line");
        Transfer.AddConstantValue(EmptyGuid, RoutingLine.FieldNo("Subc. WIP Lineage ID"));
        Transfer.CopyFields();
        Alias.DeleteAll();
        Lineage.DeleteAll();
        Activation.DeleteAll();
    end;
}
