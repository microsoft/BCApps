// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

codeunit 303 "Allocate Reserv Cust. Priority" implements "Allocate Reservation"
{
    var
        DescriptionTxt: Label 'Distribution based on Priority field in the customer card. The program will automatically fulfill all demands when the existing stock is sufficient. In cases of insufficient quantities, the system will prioritize supplying customers with the highest priority.';


    procedure Allocate(var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        ReservWkshLine: Record "Reservation Wksh. Line";
        IsHandled: Boolean;
    begin
        ReservWkshLine.Copy(ReservationWkshLine);
        ReservWkshLine.FilterGroup := 2;
        ReservWkshLine.SetFilter("Item No.", ReservationWkshLine.GetFilter("Item No."));
        ReservWkshLine.SetFilter("Variant Code", ReservationWkshLine.GetFilter("Variant Code"));
        ReservWkshLine.SetFilter("Location Code", ReservationWkshLine.GetFilter("Location Code"));
        ReservWkshLine.FilterGroup := 0;
        ReservWkshLine.SetCurrentKey("Journal Batch Name", "Item No.", "Variant Code", "Location Code", Priority);
        ReservWkshLine.Ascending(false);
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
            ReservWkshLine.SetRange(Priority, ReservWkshLine.Priority);
            ReservWkshLine.CalcSums("Qty. to Reserve (Base)", "Rem. Qty. to Reserve (Base)");
            if ReservWkshLine."Qty. to Reserve (Base)" + ReservWkshLine."Avail. Qty. to Reserve (Base)" >= ReservWkshLine."Rem. Qty. to Reserve (Base)"
            then begin
                ReservWkshLine.FindSet(true);
                repeat
                    if not ReservWkshLine.Accept then begin
                        ReservWkshLine.Validate("Qty. to Reserve", ReservWkshLine."Remaining Qty. to Reserve");
                        ReservWkshLine.Modify(true);
                    end;
                until ReservWkshLine.Next() = 0;
            end else
                if ReservWkshLine."Rem. Qty. to Reserve (Base)" > 0 then
                    exit;
            ReservWkshLine.FindLast();
            ReservWkshLine.SetRange("Item No.");
            ReservWkshLine.SetRange("Variant Code");
            ReservWkshLine.SetRange("Location Code");
            ReservWkshLine.SetRange(Priority);
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
    begin

    end;

    procedure GetDescription(): Text
    begin
        exit(DescriptionTxt);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAllocateOnAfterReservationWorksheetLinePrepare(var ReservationWkshLine2: Record "Reservation Wksh. Line"; var ReservationWkshLine: Record "Reservation Wksh. Line"; var IsHandled: Boolean)
    begin
    end;
}
