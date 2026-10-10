// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;

codeunit 137141 "SCM Quantity Ready to Start"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityReadyToStartFieldExistsWithDefaultValue()
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecordRef.Open(Database::"Prod. Order Routing Line");
        Assert.IsTrue(RecordRef.FieldExist(7308), 'Quantity Ready to Start field must exist on Prod. Order Routing Line.');
        RecordRef.Close();

        ProdOrderRoutingLine.Init();
        RecordRef.GetTable(ProdOrderRoutingLine);
        FieldRef := RecordRef.Field(7308);

        Assert.AreEqual('Quantity Ready to Start', Format(FieldRef.Caption), 'Unexpected caption for Quantity Ready to Start field.');
        Assert.AreEqual(0, FieldRef.Value, 'Quantity Ready to Start must default to 0 on a new routing line.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityReadyToStartRemainsZeroUntilPredecessorThresholdReached()
    var
        FirstRoutingLine: Record "Prod. Order Routing Line";
        SecondRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderNo: Code[20];
    begin
        ProdOrderNo := GetNewProdOrderNo();
        CreateProdOrderRoutingLine(FirstRoutingLine, FirstRoutingLine.Status::Released, ProdOrderNo, 'R1', 0, '10', '', '20', 10, 4);
        CreateProdOrderRoutingLine(SecondRoutingLine, SecondRoutingLine.Status::Released, ProdOrderNo, 'R1', 0, '20', '10', '', 10, 0);

        AddCapacityLedgerOutput(ProdOrderNo, 0, 'R1', '10', 3);
        FirstRoutingLine.Modify(true);

        AssertQuantityReadyToStart(FirstRoutingLine, 10);
        AssertQuantityReadyToStart(SecondRoutingLine, 0);

        AddCapacityLedgerOutput(ProdOrderNo, 0, 'R1', '10', 2);
        FirstRoutingLine.Modify(true);

        AssertQuantityReadyToStart(SecondRoutingLine, 5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityReadyToStartUsesMinimumAcrossImmediatePredecessors()
    var
        FirstRoutingLine: Record "Prod. Order Routing Line";
        SecondRoutingLine: Record "Prod. Order Routing Line";
        ThirdRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderNo: Code[20];
    begin
        ProdOrderNo := GetNewProdOrderNo();
        CreateProdOrderRoutingLine(FirstRoutingLine, FirstRoutingLine.Status::Released, ProdOrderNo, 'R2', 0, '10', '', '30', 10, 4);
        CreateProdOrderRoutingLine(SecondRoutingLine, SecondRoutingLine.Status::Released, ProdOrderNo, 'R2', 0, '20', '', '30', 8, 0);
        CreateProdOrderRoutingLine(ThirdRoutingLine, ThirdRoutingLine.Status::Released, ProdOrderNo, 'R2', 0, '30', '10', '', 10, 0);

        AddCapacityLedgerOutput(ProdOrderNo, 0, 'R2', '10', 6);
        AddCapacityLedgerOutput(ProdOrderNo, 0, 'R2', '20', 9);
        SecondRoutingLine.Modify(true);

        AssertQuantityReadyToStart(ThirdRoutingLine, 6);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityReadyToStartUsesMinimumAcrossImmediatePredecessorsIncludingZero()
    var
        FirstRoutingLine: Record "Prod. Order Routing Line";
        SecondRoutingLine: Record "Prod. Order Routing Line";
        ThirdRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderNo: Code[20];
    begin
        // First predecessor requires zero output (Input Quantity = 0, Send-Ahead Quantity = 0) and has posted
        // zero output, so it is itself ready with a genuine Quantity Ready to Start of 0 - not "unset".
        ProdOrderNo := GetNewProdOrderNo();
        CreateProdOrderRoutingLine(FirstRoutingLine, FirstRoutingLine.Status::Released, ProdOrderNo, 'R4', 0, '10', '', '30', 0, 0);
        CreateProdOrderRoutingLine(SecondRoutingLine, SecondRoutingLine.Status::Released, ProdOrderNo, 'R4', 0, '20', '', '30', 10, 0);
        CreateProdOrderRoutingLine(ThirdRoutingLine, ThirdRoutingLine.Status::Released, ProdOrderNo, 'R4', 0, '30', '10', '', 10, 0);

        AddCapacityLedgerOutput(ProdOrderNo, 0, 'R4', '20', 10);
        SecondRoutingLine.Modify(true);

        // The true minimum across predecessors (0 and 10) is 0 and must not be overwritten by the later,
        // larger predecessor value.
        AssertQuantityReadyToStart(ThirdRoutingLine, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertingNewFirstOperationRecalculatesQuantityReadyToStart()
    var
        OriginalFirstRoutingLine: Record "Prod. Order Routing Line";
        DependentRoutingLine: Record "Prod. Order Routing Line";
        NewFirstRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderNo: Code[20];
    begin
        ProdOrderNo := GetNewProdOrderNo();
        CreateProdOrderRoutingLine(OriginalFirstRoutingLine, OriginalFirstRoutingLine.Status::"Firm Planned", ProdOrderNo, 'R3', 0, '10', '', '20', 7, 0);
        CreateProdOrderRoutingLine(DependentRoutingLine, DependentRoutingLine.Status::"Firm Planned", ProdOrderNo, 'R3', 0, '20', '10', '', 7, 0);
        AssertQuantityReadyToStart(OriginalFirstRoutingLine, 7);

        CreateProdOrderRoutingLine(NewFirstRoutingLine, NewFirstRoutingLine.Status::"Firm Planned", ProdOrderNo, 'R3', 0, '05', '', '10', 7, 0);
        OriginalFirstRoutingLine.Get(OriginalFirstRoutingLine.Status::"Firm Planned", ProdOrderNo, 0, 'R3', '10');
        OriginalFirstRoutingLine.Validate("Previous Operation No.", '05');
        OriginalFirstRoutingLine.Modify(true);

        AssertQuantityReadyToStart(NewFirstRoutingLine, 7);
        AssertQuantityReadyToStart(OriginalFirstRoutingLine, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletingFirstOperationPromotesNextOperationReadiness()
    var
        FirstRoutingLine: Record "Prod. Order Routing Line";
        SecondRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderNo: Code[20];
    begin
        ProdOrderNo := GetNewProdOrderNo();
        CreateProdOrderRoutingLine(FirstRoutingLine, FirstRoutingLine.Status::"Firm Planned", ProdOrderNo, 'R4', 0, '10', '', '20', 11, 0);
        CreateProdOrderRoutingLine(SecondRoutingLine, SecondRoutingLine.Status::"Firm Planned", ProdOrderNo, 'R4', 0, '20', '10', '', 11, 0);

        FirstRoutingLine.Delete(true);

        AssertQuantityReadyToStart(SecondRoutingLine, 11);
    end;

    local procedure CreateProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; Status: Enum "Production Order Status"; ProdOrderNo: Code[20]; RoutingNo: Code[20]; RoutingReferenceNo: Integer; OperationNo: Code[10]; PreviousOperationNo: Code[30]; NextOperationNo: Code[30]; InputQuantity: Decimal; SendAheadQuantity: Decimal)
    begin
        ProdOrderRoutingLine.Init();
        ProdOrderRoutingLine.Status := Status;
        ProdOrderRoutingLine."Prod. Order No." := ProdOrderNo;
        ProdOrderRoutingLine."Routing No." := RoutingNo;
        ProdOrderRoutingLine."Routing Reference No." := RoutingReferenceNo;
        ProdOrderRoutingLine."Operation No." := OperationNo;
        ProdOrderRoutingLine."Previous Operation No." := PreviousOperationNo;
        ProdOrderRoutingLine."Next Operation No." := NextOperationNo;
        ProdOrderRoutingLine."Input Quantity" := InputQuantity;
        ProdOrderRoutingLine."Send-Ahead Quantity" := SendAheadQuantity;
        ProdOrderRoutingLine.Insert(true);
    end;

    local procedure AddCapacityLedgerOutput(ProdOrderNo: Code[20]; RoutingReferenceNo: Integer; RoutingNo: Code[20]; OperationNo: Code[10]; OutputQuantity: Decimal)
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
    begin
        CapacityLedgerEntry.SetCurrentKey("Entry No.");
        if CapacityLedgerEntry.FindLast() then;
        CapacityLedgerEntry.Init();
        CapacityLedgerEntry."Entry No." += 1;
        CapacityLedgerEntry."Order Type" := CapacityLedgerEntry."Order Type"::Production;
        CapacityLedgerEntry."Order No." := ProdOrderNo;
        CapacityLedgerEntry."Routing Reference No." := RoutingReferenceNo;
        CapacityLedgerEntry."Routing No." := RoutingNo;
        CapacityLedgerEntry."Operation No." := OperationNo;
        CapacityLedgerEntry."Output Quantity" := OutputQuantity;
        CapacityLedgerEntry.Insert(true);
    end;

    local procedure AssertQuantityReadyToStart(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ExpectedQuantityReadyToStart: Decimal)
    begin
        ProdOrderRoutingLine.Get(ProdOrderRoutingLine.Status, ProdOrderRoutingLine."Prod. Order No.", ProdOrderRoutingLine."Routing Reference No.", ProdOrderRoutingLine."Routing No.", ProdOrderRoutingLine."Operation No.");
        Assert.AreEqual(ExpectedQuantityReadyToStart, GetQuantityReadyToStart(ProdOrderRoutingLine), StrSubstNo('Unexpected Quantity Ready to Start for operation %1.', ProdOrderRoutingLine."Operation No."));
    end;

    local procedure GetQuantityReadyToStart(ProdOrderRoutingLine: Record "Prod. Order Routing Line"): Decimal
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecordRef.GetTable(ProdOrderRoutingLine);
        FieldRef := RecordRef.Field(7308);
        exit(FieldRef.Value);
    end;

    local procedure GetNewProdOrderNo(): Code[20]
    begin
        exit(CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 20));
    end;
}

