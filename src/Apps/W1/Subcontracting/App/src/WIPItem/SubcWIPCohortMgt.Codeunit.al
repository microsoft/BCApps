// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;
using Microsoft.Inventory.Transfer;

codeunit 20584 "Subc. WIP Cohort Mgt."
{
    Access = Internal;
    SingleInstance = true;
    Permissions = tabledata "Subc. WIP Activation" = RIM,
                  tabledata "Subc. WIP Lineage" = RI,
                  tabledata "Subc. WIP Order Alias" = RIM,
                  tabledata "Production Order" = RM;

    var
        Continuations: Dictionary of [Guid, Guid];
        TargetStatuses: Dictionary of [Guid, Integer];
        ContinuationCompany: Text;
        IntegrityErr: Label 'The subcontracting WIP identity of production order %1 is inconsistent.', Comment = '%1 = Production order number';

    internal procedure InitializeCompany()
    begin
        InitializeCompany(CompanyName());
    end;

    local procedure InitializeCompany(TargetCompany: Text)
    var
        Activation: Record "Subc. WIP Activation";
        ProductionOrder: Record "Production Order";
    begin
        Activation.ChangeCompany(TargetCompany);
        ProductionOrder.ChangeCompany(TargetCompany);
        if Activation.Get('') then
            if Activation.Version = 1 then
                exit;
        Activation.LockTable();
        if not Activation.Get('') then begin
            Activation.Init();
            if not Activation.Insert() then
                Activation.Get('');
        end;
        if Activation.Version = 1 then
            exit;

        ProductionOrder.LockTable();
        if ProductionOrder.FindSet(true) then
            repeat
                Enroll(ProductionOrder, "Subc. WIP Cohort"::Legacy);
                ProductionOrder.Modify();
                SaveAlias(ProductionOrder);
            until ProductionOrder.Next() = 0;
        Activation.Version := 1;
        Activation.Modify();
    end;

    internal procedure IsTracked(Status: Enum "Production Order Status"; OrderNo: Code[20]): Boolean
    var
        Lineage: Record "Subc. WIP Lineage";
        Alias: Record "Subc. WIP Order Alias";
    begin
        if not Alias.Get(Status, OrderNo) then
            exit(false);
        Lineage.Get(Alias."Lineage ID");
        exit((Lineage.Cohort = Lineage.Cohort::StateV1) and (Lineage.Version = 1));
    end;

    internal procedure GetLineage(Status: Enum "Production Order Status"; OrderNo: Code[20]): Guid
    var
        Alias: Record "Subc. WIP Order Alias";
    begin
        if Alias.Get(Status, OrderNo) then
            exit(Alias."Lineage ID");
    end;

    internal procedure FilterLedger(var Entry: Record "Subcontractor WIP Ledger Entry"; Status: Enum "Production Order Status"; OrderNo: Code[20])
    begin
        if IsTracked(Status, OrderNo) then
            Entry.SetRange("Lineage ID", GetLineage(Status, OrderNo))
        else
            Entry.SetRange("State Tracked", false);
    end;

    internal procedure FilterTransfers(var Line: Record "Transfer Line"; Status: Enum "Production Order Status"; OrderNo: Code[20])
    begin
        if IsTracked(Status, OrderNo) then
            Line.SetRange("Subc. WIP Lineage ID", GetLineage(Status, OrderNo))
        else
            Line.SetRange("Subc. State Tracked", false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", OnBeforeInsertEvent, '', false, false)]
    local procedure SetRoutingLineage(var Rec: Record "Prod. Order Routing Line"; RunTrigger: Boolean)
    var
        ProductionOrder: Record "Production Order";
    begin
        if Rec.IsTemporary() then
            exit;
        Clear(Rec."Subc. WIP Lineage ID");
        ProductionOrder.ChangeCompany(Rec.CurrentCompany());
        if ProductionOrder.Get(Rec.Status, Rec."Prod. Order No.") then
            if ProductionOrder."Subc. WIP Cohort" = ProductionOrder."Subc. WIP Cohort"::StateV1 then
                Rec."Subc. WIP Lineage ID" := ProductionOrder."Subc. WIP Lineage ID";
    end;

    local procedure Enroll(var ProductionOrder: Record "Production Order"; Cohort: Enum "Subc. WIP Cohort")
    var
        Lineage: Record "Subc. WIP Lineage";
    begin
        Lineage.ChangeCompany(ProductionOrder.CurrentCompany());
        Lineage.ID := CreateGuid();
        Lineage.Cohort := Cohort;
        Lineage.Version := 1;
        Lineage.Insert();
        ProductionOrder."Subc. WIP Lineage ID" := Lineage.ID;
        ProductionOrder."Subc. WIP Cohort" := Cohort;
        ProductionOrder."Subc. WIP Version" := 1;
    end;

    local procedure SaveAlias(ProductionOrder: Record "Production Order")
    var
        Alias: Record "Subc. WIP Order Alias";
    begin
        Alias.ChangeCompany(ProductionOrder.CurrentCompany());
        if Alias.Get(ProductionOrder.Status, ProductionOrder."No.") then begin
            // A native number can be reused after deletion; extant ledger entries retain their lineage.
            Alias."Lineage ID" := ProductionOrder."Subc. WIP Lineage ID";
            Alias.Modify();
            exit;
        end;
        Alias.Status := ProductionOrder.Status;
        Alias."Order No." := ProductionOrder."No.";
        Alias."Lineage ID" := ProductionOrder."Subc. WIP Lineage ID";
        Alias.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Production Order", OnBeforeInsertEvent, '', false, false)]
    local procedure EnrollNewOrder(var Rec: Record "Production Order"; RunTrigger: Boolean)
    var
        Lineage: Record "Subc. WIP Lineage";
        LineageID: Guid;
        TargetStatus: Integer;
    begin
        if Rec.IsTemporary() then
            exit;
        InitializeCompany(Rec.CurrentCompany());
        if ContinuationCompany <> Rec.CurrentCompany() then begin
            Continuations.Clear();
            TargetStatuses.Clear();
        end;
        if Continuations.Get(Rec."Subc. Continuation Token", LineageID) then begin
            TargetStatuses.Get(Rec."Subc. Continuation Token", TargetStatus);
            Continuations.Remove(Rec."Subc. Continuation Token");
            TargetStatuses.Remove(Rec."Subc. Continuation Token");
            if Rec.Status.AsInteger() <> TargetStatus then
                RaiseIntegrityError(Rec."No.");
            Lineage.ChangeCompany(Rec.CurrentCompany());
            Lineage.Get(LineageID);
            Rec."Subc. WIP Lineage ID" := Lineage.ID;
            Rec."Subc. WIP Cohort" := Lineage.Cohort;
            Rec."Subc. WIP Version" := Lineage.Version;
        end else
            Enroll(Rec, "Subc. WIP Cohort"::StateV1);
        Clear(Rec."Subc. Continuation Token");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Production Order", OnAfterInsertEvent, '', false, false)]
    local procedure SaveNewOrder(var Rec: Record "Production Order"; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary() then
            SaveAlias(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Production Order", OnBeforeModifyEvent, '', false, false)]
    local procedure ProtectIdentity(var Rec: Record "Production Order"; var xRec: Record "Production Order"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() or IsNullGuid(xRec."Subc. WIP Lineage ID") then
            exit;
        if (Rec."Subc. WIP Lineage ID" <> xRec."Subc. WIP Lineage ID") or
           (Rec."Subc. WIP Cohort" <> xRec."Subc. WIP Cohort") or
           (Rec."Subc. WIP Version" <> xRec."Subc. WIP Version")
        then
            RaiseIntegrityError(Rec."No.");
    end;

    local procedure AuthorizeContinuation(var ToProductionOrder: Record "Production Order"; FromProductionOrder: Record "Production Order")
    var
        Source: Record "Production Order";
    begin
        InitializeCompany(FromProductionOrder.CurrentCompany());
        Source.ChangeCompany(FromProductionOrder.CurrentCompany());
        Source.Get(FromProductionOrder.Status, FromProductionOrder."No.");
        if not IsNullGuid(FromProductionOrder."Subc. WIP Lineage ID") and
           (Source."Subc. WIP Lineage ID" <> FromProductionOrder."Subc. WIP Lineage ID")
        then
            RaiseIntegrityError(FromProductionOrder."No.");
        Continuations.Clear();
        TargetStatuses.Clear();
        ContinuationCompany := FromProductionOrder.CurrentCompany();
        ToProductionOrder."Subc. Continuation Token" := CreateGuid();
        Continuations.Add(ToProductionOrder."Subc. Continuation Token", Source."Subc. WIP Lineage ID");
        TargetStatuses.Add(ToProductionOrder."Subc. Continuation Token", ToProductionOrder.Status.AsInteger());
    end;

    local procedure RaiseIntegrityError(OrderNo: Code[20])
    var
        IntegrityErrorInfo: ErrorInfo;
    begin
        IntegrityErrorInfo.Message := StrSubstNo(IntegrityErr, OrderNo);
        IntegrityErrorInfo.ErrorType := ErrorType::Internal;
        Error(IntegrityErrorInfo);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Production Order", OnAfterRenameEvent, '', false, false)]
    local procedure SaveRenamedOrder(var Rec: Record "Production Order"; var xRec: Record "Production Order"; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary() then
            SaveAlias(Rec);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Prod. Order Status Management", OnTransProdOrderOnBeforeToProdOrderInsert, '', false, false)]
    local procedure ContinueStatus(var ToProdOrder: Record "Production Order"; FromProdOrder: Record "Production Order")
    begin
        AuthorizeContinuation(ToProdOrder, FromProdOrder);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Prod. Order Status Management", OnBeforeTransferReopenProdOrderInsert, '', false, false)]
    local procedure ContinueReopen(var ProductionOrder: Record "Production Order"; FromProductionOrder: Record "Production Order")
    begin
        AuthorizeContinuation(ProductionOrder, FromProductionOrder);
    end;
}
