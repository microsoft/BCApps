// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

codeunit 302 "Allocate Reserv. Equally" implements "Allocate Reservation"
{
    var
        DescriptionTxt: Label 'Even distribution. If the quantity on hand is ample enough to fulfill all demands, the program will do so. In case of insufficiency, it will equitably distribute the remaining quantity among the demands.';


    procedure Allocate(var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        ReservWkshLine: Record "Reservation Wksh. Line";
        AverageQty: Decimal;
        QtyToReserveBase: Decimal;
        LeftToAllocateEntries: Integer;
        IsHandled: Boolean;
    begin
        ReservWkshLine.Copy(ReservationWkshLine);
        ReservWkshLine.FilterGroup := 2;
        ReservWkshLine.SetFilter("Item No.", ReservationWkshLine.GetFilter("Item No."));
        ReservWkshLine.SetFilter("Variant Code", ReservationWkshLine.GetFilter("Variant Code"));
        ReservWkshLine.SetFilter("Location Code", ReservationWkshLine.GetFilter("Location Code"));
        ReservWkshLine.FilterGroup := 0;
        ReservWkshLine.SetCurrentKey("Journal Batch Name", "Item No.", "Variant Code", "Location Code", "Remaining Qty. to Reserve");
        IsHandled := false;
        OnAllocateOnAfterReservationWorksheetLinePrepare(ReservWkshLine, ReservationWkshLine, IsHandled);
        if IsHandled then
            exit;

        if not ReservWkshLine.FindSet(true) then
            exit;

        repeat
            ReservWkshLine.SetRange("Item No.", ReservWkshLine."Item No.");
            ReservWkshLine.SetRange("Variant Code", ReservWkshLine."Variant Code");
            ReservWkshLine.SetRange("Location Code", ReservWkshLine."Location Code");
            ReservWkshLine.SetRange(Accept, false);
            LeftToAllocateEntries := ReservWkshLine.Count();
            ReservWkshLine.SetRange(Accept);
            ReservWkshLine.FindSet(true);
            repeat
                if not ReservWkshLine.Accept then begin
                    AverageQty := ReservWkshLine."Avail. Qty. to Reserve (Base)" / LeftToAllocateEntries;
                    QtyToReserveBase := MinValue(AverageQty, ReservWkshLine."Rem. Qty. to Reserve (Base)");
                    QtyToReserveBase := Round(QtyToReserveBase, GetRoundingPrecision(ReservWkshLine."Rem. Qty. to Reserve (Base)"), '<');
                    ReservWkshLine.Validate("Qty. to Reserve (Base)", QtyToReserveBase);
                    ReservWkshLine.Modify(true);
                    LeftToAllocateEntries := LeftToAllocateEntries - 1;
                end;
            until ReservWkshLine.Next() = 0;
            ReservWkshLine.FindLast();
            ReservWkshLine.SetRange("Item No.");
            ReservWkshLine.SetRange("Variant Code");
            ReservWkshLine.SetRange("Location Code");
        until ReservWkshLine.Next() = 0;
    end;

    procedure AllocationCompleted(var ReservationWkshLine: Record "Reservation Wksh. Line"): Boolean
    var
        ReservWkshLine: Record "Reservation Wksh. Line";
    begin
        ReservWkshLine.Copy(ReservationWkshLine);
        ReservWkshLine.SetRange(Accept, false);
        exit(ReservWkshLine.IsEmpty());
    end;

    procedure DeleteAllocation(var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        ReservWkshLine: Record "Reservation Wksh. Line";
    begin
        ReservWkshLine.Copy(ReservationWkshLine);
        ReservWkshLine.SetRange(Accept, false);
        if not ReservWkshLine.FindSet(true) then
            exit;

        repeat
            ReservWkshLine.Validate("Qty. to Reserve", 0);
            ReservWkshLine.Modify();
        until ReservWkshLine.Next() = 0;
    end;

    procedure GetDescription(): Text
    begin
        exit(DescriptionTxt);
    end;

    local procedure GetRoundingPrecision(Number: Decimal): Decimal
    var
        NoOfDecimals: Integer;
        DecimalPart: Decimal;
    begin
        DecimalPart := Number - Round(Number, 1, '<');
        if DecimalPart = 0 then
            NoOfDecimals := 0
        else
            while DecimalPart <> 0 do begin
                DecimalPart := DecimalPart * 10;
                NoOfDecimals := NoOfDecimals + 1;
                DecimalPart := DecimalPart - Round(DecimalPart, 1, '<');
            end;

        exit(1 / Power(10, NoOfDecimals));
    end;

    local procedure MinValue(A: Decimal; B: Decimal): Decimal
    begin
        if A <= B then
            exit(A);

        exit(B);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAllocateOnAfterReservationWorksheetLinePrepare(var ReservationWkshLine2: Record "Reservation Wksh. Line"; var ReservationWkshLine: Record "Reservation Wksh. Line"; var IsHandled: Boolean)
    begin
    end;
}
