// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;

codeunit 149930 "Subc WIP Concurrent Action"
{
    Access = Internal;
    TableNo = "Subc WIP Concurrent Signal";
    EventSubscriberInstance = Manual;

    trigger OnRun()
    var
        Order: Record "Production Order";
        ManufacturingSetup: Record "Manufacturing Setup";
        CohortMgt: Codeunit "Subc. WIP Cohort Mgt.";
        Fixture: Codeunit "Subc. WIP Upgrade Fixture";
        Subscriber: Codeunit "Subc WIP Concurrent Action";
    begin
        case Rec.Action of
            'PrepareCutover':
                begin
                    if not ManufacturingSetup.Get() then
                        ManufacturingSetup.Insert(false);
                    Order.Status := Order.Status::Planned;
                    Order."No." := Rec."Order No.";
                    Order.Insert(false);
                    Fixture.RestorePreactivationColumns();
                end;
            'Activate':
                begin
                    Subscriber.SetRace(Rec);
                    BindSubscription(Subscriber);
                    CohortMgt.InitializeCompany();
                    UnbindSubscription(Subscriber);
                    Order.Get(Order.Status::Planned, Rec."Order No.");
                    Assert.AreEqual(Order."Subc. WIP Cohort"::Legacy, Order."Subc. WIP Cohort", 'The root that existed before cutover must stay legacy.');
                    Assert.IsFalse(IsNullGuid(Order."Subc. WIP Lineage ID"), 'Cutover cannot omit the existing root.');
                end;
            'CreateHeader':
                begin
                    Order.Status := Order.Status::Planned;
                    Order."No." := Rec."Order No.";
                    Order.Insert(Rec."Run Trigger");
                    Rec.Cohort := Order."Subc. WIP Cohort";
                    Rec."Lineage ID" := Order."Subc. WIP Lineage ID";
                    Rec.Modify();
                end;
            'PrepareClaims':
                PrepareClaims(Rec);
            'Claim', 'Probe':
                ConfirmClaim(Rec);
            'ReleaseClaim':
                ReleaseClaim(Rec);
            'VerifyClaims':
                VerifyClaims(Rec);
            else
                Error('Unknown WIP concurrency fixture action.');
        end;
    end;

    var
        Race: Record "Subc WIP Concurrent Signal";
        Assert: Codeunit Assert;
        Workers: Codeunit "Subc WIP Concurrent Worker";
        Warehouse: Codeunit "Subc. Warehouse Library";

    internal procedure SetRace(Signal: Record "Subc WIP Concurrent Signal")
    begin
        Race := Signal;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Subc. WIP Activation", OnAfterInsertEvent, '', false, false)]
    local procedure PauseBeforeEnumeration(var Rec: Record "Subc. WIP Activation"; RunTrigger: Boolean)
    var
        Creator: Record "Subc WIP Concurrent Signal";
        CompetingSessionID: Integer;
    begin
        if IsNullGuid(Race."Run ID") or (Rec.Version <> 0) then
            exit;
        Creator.Get(Race."Run ID", 2);
        CompetingSessionID := Workers.StartWorker(Creator);
        Workers.WaitForBlocked(CompetingSessionID);
        Race.Get(Race."Run ID", Race.Worker);
        Race."Blocked Observed" := true;
        Race.Modify();
    end;

    local procedure PrepareClaims(Signal: Record "Subc WIP Concurrent Signal")
    var
        Order: Record "Production Order";
        Header: Record "Purchase Header";
        Line: Record "Purchase Line";
        OtherHeader: Record "Purchase Header";
        OtherLine: Record "Purchase Line";
        Receipt: Record "Purch. Rcpt. Line";
        Entry: Record "Subcontractor WIP Ledger Entry";
        Control: Record "Subc WIP Concurrent Signal";
        Management: Codeunit "Subc. Management Library";
        I: Integer;
    begin
        Management.Initialize();
        for I := 1 to 2 do begin
            Warehouse.CreateStateWIPPurchaseOrder(Order, Header, Line, 10, 1, true, false, true);
            Warehouse.PostBackgroundStateWIPSupply(Order, Line);
            Warehouse.ReceiveStateWIP(Header, Line, 7, Receipt);
            Warehouse.FindStateWIPEntry(Entry, Line, Entry."WIP State"::Processed);
            Control.Init();
            Control."Run ID" := Signal."Run ID";
            Control.Worker := 2 * I - 1;
            Control.Action := 'Claim';
            Control."Ledger Entry No." := Entry."Entry No.";
            Control."Purchase Order No." := Line."Document No.";
            Control."Purchase Line No." := Line."Line No.";
            if I = 2 then
                Control.Action := 'Probe';
            Control.Insert();
            if I = 1 then begin
                Warehouse.CreateNextStateWIPPurchaseOrder(Line, OtherHeader, OtherLine, true);
                Assert.AreNotEqual(Header."No.", OtherHeader."No.", 'The onward and return proposals must belong to distinct real current purchase orders.');
                Control.Worker := 2;
                Control."Purchase Order No." := OtherLine."Document No.";
                Control."Purchase Line No." := OtherLine."Line No.";
                Control.Insert();
            end;
        end;
    end;

    local procedure ConfirmClaim(var Signal: Record "Subc WIP Concurrent Signal")
    var
        Selected: Record "Subc. Transfer Proposal" temporary;
        Entry: Record "Subcontractor WIP Ledger Entry";
        Line: Record "Purchase Line";
        ProductionLine: Record "Prod. Order Line";
        Vendor: Record Vendor;
        Header: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Competing: Record "Subc WIP Concurrent Signal";
        Probe: Record "Subc WIP Concurrent Signal";
        Proposals: Codeunit "Subc. Transfer Proposal Mgt.";
        CompetingSessionID: Integer;
        ProbeSessionID: Integer;
        ToLocation: Code[10];
        PreviousOperation: Code[10];
    begin
        Entry.Get(Signal."Ledger Entry No.");
        Line.Get(Line."Document Type"::Order, Signal."Purchase Order No.", Signal."Purchase Line No.");
        ProductionLine.Get(ProductionLine.Status::Released, Line."Prod. Order No.", Line."Prod. Order Line No.");
        ToLocation := ProductionLine."Location Code";
        if Signal.Worker = 2 then begin
            Vendor.Get(Line."Buy-from Vendor No.");
            ToLocation := Vendor."Subc. Location Code";
            PreviousOperation := Entry."Operation No.";
        end;
        Selected."Entry No." := 1;
        Selected."Purchase Order No." := Line."Document No.";
        Selected."Purchase Line No." := Line."Line No.";
        Selected."Item No." := Entry."Item No.";
        Selected."Variant Code" := Entry."Variant Code";
        Selected."Production Order No." := Line."Prod. Order No.";
        Selected."Production Order Line No." := Line."Prod. Order Line No.";
        Selected."Operation No." := Line."Operation No.";
        Selected."Work Center No." := Line."Work Center No.";
        Selected."Routing No." := Line."Routing No.";
        Selected."Routing Reference No." := Line."Routing Reference No.";
        Selected."WIP Item" := true;
        Selected."State Tracked" := true;
        Selected."WIP State" := Entry."WIP State";
        Selected."Transfer-from Code" := Entry."Location Code";
        Selected."Transfer-to Code" := ToLocation;
        Selected."Previous Operation No." := PreviousOperation;
        Selected."Unit of Measure Code" := ProductionLine."Unit of Measure Code";
        Selected."Qty. per Unit of Measure" := ProductionLine."Qty. per Unit of Measure";
        Selected."Available Quantity (Base)" := 7;
        Selected."Source Position No." := Entry."Source Position No.";
        Selected."Supply Lot ID" := Entry."Supply Lot ID";
        Selected."Quantity to Transfer" := 5;
        Selected.Insert();
        if Signal.Worker = 2 then
            Proposals.Configure(false, false, true, false, '', '', '', '', '', '')
        else
            Proposals.Configure(true, false, false, true, '', '', '', '', '', '');
        Proposals.LockSources(Selected);
        if Signal.Worker = 1 then begin
            Competing.Get(Signal."Run ID", 2);
            CompetingSessionID := Workers.StartWorker(Competing);
            Workers.WaitForBlocked(CompetingSessionID);
            Probe.Get(Signal."Run ID", 3);
            ProbeSessionID := Workers.StartWorker(Probe);
            Assert.IsTrue(Workers.WaitForEnd(ProbeSessionID), 'The disjoint-key probe timed out.');
            Probe.Get(Signal."Run ID", 3);
            Assert.IsTrue(Probe.Succeeded, 'A disjoint complete source must acquire the real confirmation locks while the first source is held: ' + Probe.Failure);
            Signal."Blocked Observed" := true;
            if Signal."Expected Available" = 1 then
                PostOne(Signal);
        end;
        Proposals.AddWIP(Line, ProductionLine, Entry."Location Code", ToLocation, PreviousOperation, 5, ProductionLine."Unit of Measure Code");
        Proposals.Revalidate(Selected);
        if Signal.Action = 'Claim' then begin
            Warehouse.CreateStateWIPClaim(Line, Entry, 5, Header, TransferLine);
            Signal."Transfer Order No." := Header."No.";
        end;
        Signal.Modify();
    end;

    local procedure VerifyClaims(Signal: Record "Subc WIP Concurrent Signal")
    var
        Leader: Record "Subc WIP Concurrent Signal";
        Competitor: Record "Subc WIP Concurrent Signal";
        Entry: Record "Subcontractor WIP Ledger Entry";
        Headers: Record "Transfer Header";
        Availability: Codeunit "Subc. WIP Availability";
    begin
        Leader.Get(Signal."Run ID", 1);
        Competitor.Get(Signal."Run ID", 2);
        Assert.IsTrue(Workers.WaitForEnd(Competitor."Session ID"), 'The competing confirmation timed out.');
        Competitor.Get(Signal."Run ID", 2);
        Assert.IsTrue(Leader."Blocked Observed", 'The second confirmation must actually contend for the first locked source.');
        Assert.IsTrue(Competitor.Done and not Competitor.Succeeded, 'The stale five-unit proposal must fail, not silently clamp.');
        Assert.IsTrue(Competitor.Failure.Contains('changed'), 'The competitor must fail fresh proposal revalidation, not unrelated setup.');
        Entry.Get(Leader."Ledger Entry No.");
        Assert.AreEqual(5, Availability.OpenClaim(Entry."Source Position No.", Entry."WIP State", Entry."Supply Lot ID", '', 0), 'Only the first five units may be allocated.');
        Assert.AreEqual(Signal."Expected Available", Availability.Available(Entry."Source Position No.", Entry."WIP State", Entry."Supply Lot ID", '', 0), 'The second session must reread the committed custody and claim balance.');
        Headers.SetRange("Subcontr. Purch. Order No.", Competitor."Purchase Order No.");
        Assert.RecordIsEmpty(Headers);
    end;

    local procedure ReleaseClaim(Signal: Record "Subc WIP Concurrent Signal")
    var
        Leader: Record "Subc WIP Concurrent Signal";
        Header: Record "Transfer Header";
    begin
        Leader.Get(Signal."Run ID", 1);
        Header.Get(Leader."Transfer Order No.");
        Header.Delete(true);
    end;

    local procedure PostOne(Signal: Record "Subc WIP Concurrent Signal")
    var
        Entry: Record "Subcontractor WIP Ledger Entry";
        Line: Record "Purchase Line";
        Header: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        PostShipment: Codeunit "TransferOrder-Post Shipment";
        PostReceipt: Codeunit "TransferOrder-Post Receipt";
    begin
        Entry.Get(Signal."Ledger Entry No.");
        Line.Get(Line."Document Type"::Order, Signal."Purchase Order No.", Signal."Purchase Line No.");
        Warehouse.CreateStateWIPClaim(Line, Entry, 1, Header, TransferLine);
        PostShipment.SetSuppressCommit(true);
        PostShipment.Run(Header);
        Header.Get(Header."No.");
        PostReceipt.SetSuppressCommit(true);
        PostReceipt.Run(Header);
    end;
}
