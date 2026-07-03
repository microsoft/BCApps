// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

codeunit 301 "Allocate Reserv. Basic" implements "Allocate Reservation"
{
    var
        DescriptionTxt: Label 'Basic distribution. If the current stock is enough to satisfy all demands, the program will automatically do that. However, if the quantity falls short, the user is required to manually input the quantity to be allocated to each demand.';


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
        ReservWkshLine.SetCurrentKey("Journal Batch Name", "Item No.", "Variant Code", "Location Code");
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
            end;
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
