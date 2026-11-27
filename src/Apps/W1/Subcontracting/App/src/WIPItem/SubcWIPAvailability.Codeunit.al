// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;

codeunit 20582 "Subc. WIP Availability"
{
    Access = Internal;
    Permissions = tabledata "Subc. WIP Source Position" = RIM;

    var
        UnavailableErr: Label 'The quantity exceeds the available WIP quantity for the selected source and processing state.';
        SourceChangedErr: Label 'The WIP source of an allocated transfer cannot be changed. Delete its unshipped quantity and create a new proposal.';

    internal procedure EnsurePosition(var Entry: Record "Subcontractor WIP Ledger Entry")
    var
        Position: Record "Subc. WIP Source Position";
    begin
        Position.LockTable();
        Position.SetRange("Lineage ID", Entry."Lineage ID");
        Position.SetRange("Prod. Order Line No.", Entry."Prod. Order Line No.");
        Position.SetRange("Routing Reference No.", Entry."Routing Reference No.");
        Position.SetRange("Routing No.", Entry."Routing No.");
        Position.SetRange("Operation No.", Entry."Operation No.");
        Position.SetRange("Item No.", Entry."Item No.");
        Position.SetRange("Variant Code", Entry."Variant Code");
        Position.SetRange("Location Code", Entry."Location Code");
        Position.SetRange("In Transit", Entry."In Transit");
        if not Position.FindFirst() then begin
            Position.Init();
            Position."Lineage ID" := Entry."Lineage ID";
            Position."Prod. Order Line No." := Entry."Prod. Order Line No.";
            Position."Routing Reference No." := Entry."Routing Reference No.";
            Position."Routing No." := Entry."Routing No.";
            Position."Operation No." := Entry."Operation No.";
            Position."Item No." := Entry."Item No.";
            Position."Variant Code" := Entry."Variant Code";
            Position."Location Code" := Entry."Location Code";
            Position."In Transit" := Entry."In Transit";
            Position.Insert();
        end;
        Entry."Source Position No." := Position."Entry No.";
    end;

    internal procedure LockPosition(PositionNo: Integer)
    var
        Position: Record "Subc. WIP Source Position";
    begin
        if PositionNo = 0 then
            exit;
        Position.LockTable();
        Position.Get(PositionNo);
    end;

    internal procedure Balance(PositionNo: Integer; State: Enum "Subc. WIP Processing State"; LotID: Guid): Decimal
    var
        Entry: Record "Subcontractor WIP Ledger Entry";
    begin
        Entry.SetRange("State Tracked", true);
        Entry.SetRange("Source Position No.", PositionNo);
        Entry.SetRange("In Transit", false);
        Entry.SetRange("WIP State", State);
        Entry.SetRange("Supply Lot ID", LotID);
        Entry.CalcSums("Quantity (Base)");
        exit(Entry."Quantity (Base)");
    end;

    internal procedure OpenClaim(PositionNo: Integer; State: Enum "Subc. WIP Processing State"; LotID: Guid; ExcludeDocument: Code[20]; ExcludeLine: Integer): Decimal
    var
        Line: Record "Transfer Line";
        Result: Decimal;
    begin
        Line.SetRange("Subc. Source Position No.", PositionNo);
        Line.SetRange("Subc. WIP State", State);
        Line.SetRange("Subc. Supply Lot ID", LotID);
        Line.SetRange("Transfer WIP Item", true);
        Line.SetRange("Derived From Line No.", 0);
        if Line.FindSet() then
            repeat
                if (Line."Document No." <> ExcludeDocument) or (Line."Line No." <> ExcludeLine) then
                    if Line.Quantity > Line."Quantity Shipped" then
                        Result += Line.CalcBaseQty(Line.Quantity - Line."Quantity Shipped");
            until Line.Next() = 0;
        exit(Result);
    end;

    internal procedure Available(PositionNo: Integer; State: Enum "Subc. WIP Processing State"; LotID: Guid; ExcludeDocument: Code[20]; ExcludeLine: Integer): Decimal
    begin
        exit(Balance(PositionNo, State, LotID) - OpenClaim(PositionNo, State, LotID, ExcludeDocument, ExcludeLine));
    end;

    internal procedure CheckQuantity(PositionNo: Integer; State: Enum "Subc. WIP Processing State"; LotID: Guid; QuantityBase: Decimal; ExcludeDocument: Code[20]; ExcludeLine: Integer)
    begin
        LockPosition(PositionNo);
        if (QuantityBase < 0) or (QuantityBase > Available(PositionNo, State, LotID, ExcludeDocument, ExcludeLine)) then
            Error(UnavailableErr);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Line", OnBeforeModifyEvent, '', false, false)]
    local procedure CheckClaim(var Rec: Record "Transfer Line"; var xRec: Record "Transfer Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() or (Rec."Derived From Line No." <> 0) then
            exit;
        if xRec."Subc. State Tracked" then
            if not Rec."Subc. State Tracked" or (Rec."Subc. WIP Lineage ID" <> xRec."Subc. WIP Lineage ID") then
                Error(SourceChangedErr);
        if xRec."Subc. Source Position No." <> 0 then
            if (Rec."Subc. Source Position No." <> xRec."Subc. Source Position No.") or
               (Rec."Subc. WIP State" <> xRec."Subc. WIP State") or
               (Rec."Subc. Supply Lot ID" <> xRec."Subc. Supply Lot ID") or
               (Rec."Item No." <> xRec."Item No.") or
               (Rec."Variant Code" <> xRec."Variant Code") or
               (Rec."Transfer-from Code" <> xRec."Transfer-from Code") or
               not Rec."Transfer WIP Item"
            then
                Error(SourceChangedErr);
        if (xRec."Subc. Prod. Order No." = '') and (Rec."Subc. Prod. Order No." <> '') then
            SetIdentity(Rec);
        ValidateClaim(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Line", OnBeforeInsertEvent, '', false, false)]
    local procedure CheckNewClaim(var Rec: Record "Transfer Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        if Rec."Subc. Prod. Order No." = '' then begin
            Clear(Rec."Subc. WIP Lineage ID");
            Rec."Subc. State Tracked" := false;
            exit;
        end;
        SetIdentity(Rec);
        ValidateClaim(Rec);
    end;

    local procedure SetIdentity(var Line: Record "Transfer Line")
    var
        CohortMgt: Codeunit "Subc. WIP Cohort Mgt.";
    begin
        Line."Subc. WIP Lineage ID" := CohortMgt.GetLineage("Production Order Status"::Released, Line."Subc. Prod. Order No.");
        Line."Subc. State Tracked" := CohortMgt.IsTracked("Production Order Status"::Released, Line."Subc. Prod. Order No.");
    end;

    local procedure ValidateClaim(var Line: Record "Transfer Line")
    var
        Position: Record "Subc. WIP Source Position";
        ProductionLine: Record "Prod. Order Line";
        SourceOperation: Code[10];
        QuantityBase: Decimal;
    begin
        if Line."Transfer WIP Item" and Line."Subc. State Tracked" and IsNullGuid(Line."Subc. Supply Lot ID") then
            Line."Subc. Supply Lot ID" := CreateGuid();
        if not Line."Transfer WIP Item" or not Line."Subc. State Tracked" or
           (Line."Derived From Line No." <> 0)
        then
            exit;
        ProductionLine.LockTable();
        ProductionLine.Get(ProductionLine.Status::Released, Line."Subc. Prod. Order No.", Line."Subc. Prod. Order Line No.");
        QuantityBase := Line.CalcBaseQty(Line.Quantity - Line."Quantity Shipped");
        if Line."Subc. Source Position No." = 0 then begin
            if (QuantityBase < 0) or (QuantityBase > InitialAvailable(Line."Subc. WIP Lineage ID",
                Line."Subc. Prod. Order Line No.", ProductionLine."Quantity (Base)", Line."Document No.", Line."Line No."))
            then
                Error(UnavailableErr);
            exit;
        end;
        Position.Get(Line."Subc. Source Position No.");
        SourceOperation := Line."Subc. Operation No.";
        if not Line."Subc. Return Order" and (Line."Prev. Operation No." <> '') then
            SourceOperation := Line."Prev. Operation No.";
        if (Position."Lineage ID" <> Line."Subc. WIP Lineage ID") or
           (Position."Prod. Order Line No." <> Line."Subc. Prod. Order Line No.") or
           (Position."Routing Reference No." <> Line."Subc. Routing Reference No.") or
           (Position."Routing No." <> Line."Subc. Routing No.") or
           (Position."Operation No." <> SourceOperation) or
           (Position."Item No." <> Line."Item No.") or
           (Position."Variant Code" <> Line."Variant Code") or
           (Position."Location Code" <> Line."Transfer-from Code") or Position."In Transit"
        then
            Error(SourceChangedErr);
        CheckQuantity(Line."Subc. Source Position No.", Line."Subc. WIP State", Line."Subc. Supply Lot ID",
            QuantityBase, Line."Document No.", Line."Line No.");
    end;

    internal procedure InitialAvailable(LineageID: Guid; ProductionLineNo: Integer; ProductionQuantityBase: Decimal; ExcludeDocument: Code[20]; ExcludeLine: Integer): Decimal
    var
        Entry: Record "Subcontractor WIP Ledger Entry";
        Line: Record "Transfer Line";
        ClaimedBase: Decimal;
    begin
        Entry.SetRange("Lineage ID", LineageID);
        Entry.SetRange("Prod. Order Line No.", ProductionLineNo);
        Entry.SetRange("State Tracked", true);
        Entry.CalcSums("Quantity (Base)");
        Line.SetRange("Subc. WIP Lineage ID", LineageID);
        Line.SetRange("Subc. Prod. Order Line No.", ProductionLineNo);
        Line.SetRange("Subc. Source Position No.", 0);
        Line.SetRange("Transfer WIP Item", true);
        Line.SetRange("Subc. Return Order", false);
        Line.SetRange("Derived From Line No.", 0);
        if Line.FindSet() then
            repeat
                if (Line."Document No." <> ExcludeDocument) or (Line."Line No." <> ExcludeLine) then
                    if Line.Quantity > Line."Quantity Shipped" then
                        ClaimedBase += Line.CalcBaseQty(Line.Quantity - Line."Quantity Shipped");
            until Line.Next() = 0;
        exit(ProductionQuantityBase - Entry."Quantity (Base)" - ClaimedBase);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Line", OnBeforeDeleteEvent, '', false, false)]
    local procedure ReleaseClaim(var Rec: Record "Transfer Line"; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary() then
            LockPosition(Rec."Subc. Source Position No.");
    end;
}
