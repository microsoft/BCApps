// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Worksheet;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Ledger;

page 5773 "Warehouse Pick Summary Part"
{
    PageType = CardPart;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "Warehouse Pick Summary";
    SourceTableTemporary = true;
    Editable = false;

    layout
    {
        area(Content)
        {
            group(Calculation)
            {
                ShowCaption = false;
                Visible = (not IsActiveWhseWorksheetVisible) and (Rec."Qty. to Handle (Base)" > 0);

                group(MovementWorksheet)
                {
                    ShowCaption = false;
                    Visible = IsCalledFromMovementWorksheet;

                    field("Takeable Qty."; Rec."Potential Pickable Qty.")
                    {
                        Caption = 'Takeable Qty.';
                        ToolTip = 'Specifies the maximum quantity that can be considered for moving. This quantity consists of items in all the bins excluding Receipt bins, bins that are blocked, dedicated, blocked by item tracking or items that are being picked. This quantity cannot be more than the total quantity in the warehouse including adjustment bins.';
                    }
                }
                group(NonMovementWorksheet)
                {
                    ShowCaption = false;
                    Visible = not IsCalledFromMovementWorksheet;

                    field("Pickable Qty."; Rec."Potential Pickable Qty.")
                    {
                        Caption = 'Pickable Qty.';
                        ToolTip = 'Specifies the maximum quantity that can be considered for picking. This quantity consists of items in pickable bins excluding bins that are blocked, dedicated, blocked by item tracking or items that are being picked. This quantity cannot be more than the total quantity in the warehouse including adjustment bins.';
                    }
                }

                field(QtyAvailableToPick; Rec."Qty. Available to Pick")
                {
                    Caption = 'Pickable Qty. (Actual)';
                    ToolTip = 'Specifies the quantity that is actually available to pick.';
                    Visible = false;
                }

                group(Details)
                {
                    ShowCaption = false;

                    group(TakeableQtyDetails)
                    {
                        Caption = 'Takeable Qty. Details';
                        Visible = IsCalledFromMovementWorksheet;

                        field("Qty. in Takeable Bins"; Rec."Qty. in Pickable Bins")
                        {
                            Caption = 'Qty. in Takeable Bins';
                            ToolTip = 'Specifies the quantity in takeable bins. The quantity is not reduced by item tracking.';

                            trigger OnDrillDown()
                            begin
                                Rec.ShowBinContents(BinTypeFilter::ExcludeReceive);
                            end;
                        }
                    }
                    group(PickableQtyDetails)
                    {
                        Caption = 'Pickable Qty. Details';
                        Visible = not IsCalledFromMovementWorksheet;

                        field("Qty. in Pickable Bins"; Rec."Qty. in Pickable Bins")
                        {
                            ToolTip = 'Specifies the quantity in pickable bins. The quantity is not reduced by item tracking or items that are being picked.';

                            trigger OnDrillDown()
                            begin
                                Rec.ShowBinContents(BinTypeFilter::OnlyPickBins);
                            end;
                        }
                    }
                    field("Qty. in Warehouse"; Rec."Qty. in Warehouse")
                    {
                        ToolTip = 'Specifies the quantity in warehouse.';

                        trigger OnDrillDown()
                        var
                            WarehouseEntry: Record "Warehouse Entry";
                            WarehouseEntriesPage: Page "Warehouse Entries";
                        begin
                            WarehouseEntry.SetRange("Item No.", Rec."Item No.");
                            WarehouseEntry.SetRange("Location Code", Rec."Location Code");
                            WarehouseEntry.SetRange("Variant Code", Rec."Variant Code");
                            WarehouseEntriesPage.SetTableView(WarehouseEntry);
                            WarehouseEntriesPage.Run();
                        end;
                    }
                    group(TrackingEnabled1)
                    {
                        ShowCaption = false;
                        Visible = IsTrackingVisible;

                        field("Qty. in Blocked Item Tracking"; Rec."Qty. in Blocked Item Tracking")
                        {
                            ToolTip = 'Specifies the quantity in blocked item tracking for the pickable/takeable bins.';
                        }
                    }
                    group(QtyAssigned)
                    {
                        ShowCaption = false;
                        Visible = Rec."Qty. assigned" > 0;

                        field("Qty. Assigned"; Rec."Qty. Assigned")
                        {
                            Caption = 'Qty. Handled Across Source Lines';
                            ToolTip = 'Specifies the quantity that has been handled for other source lines. If tracking is enabled, then the same source line is also included. The quantity consists of the current execution of create warehouse pick action.';
                        }
                    }

                    field("Qty. in Active Pick Lines"; Rec."Qty. in Active Pick Lines")
                    {
                        ToolTip = 'Specifies the quantity assigned in active warehouse pick documents.';
                        Visible = false;
                    }
                    field(QtyAvailableInInventory; Rec."Qty. in Inventory")
                    {
                        ToolTip = 'Specifies the quantity in the inventory.';
                        Visible = false;
                    }
                }
            }

            group("Warehouse Worksheet")
            {
                Visible = IsActiveWhseWorksheetVisible;
                Caption = 'Exists in Warehouse Worksheet';

                field("Worksheet Batch Name"; ActiveWorksheetBatchNameText)
                {
                    Caption = 'Batch Name';
                    ToolTip = 'Specifies the pick worksheet batch that is preventing the creation of a warehouse pick. A pick worksheet line in the specified batch is blocking the creation of warehouse pick for the selected line.';

                    trigger OnDrillDown()
                    begin
                        Rec.ShowPickWorksheet(ActiveWorksheetLine, true);
                    end;
                }
            }

            group("Impact of Reservations")
            {
                Visible = IsReservationImpactVisible;

                field("Available Qty. Not in Ship Bin"; Rec."Available Qty. Not in Ship Bin")
                {
                    Caption = 'Avail. Qty. Excluding Shipment Bin';
                    ToolTip = 'Specifies the quantity available to pick in the warehouse excluding the shipment bins, bins that are blocked, dedicated, blocked by item tracking or items that are being picked.';

                    trigger OnDrillDown()
                    begin
                        Rec.ShowBinContents(BinTypeFilter::ExcludeShip);
                    end;
                }
                field("Qty. Reserved in Warehouse"; Rec."Qty. Reserved in Warehouse")
                {
                    Caption = 'Reserved Qty. in Warehouse';
                    ToolTip = 'Specifies the quantity reserved in warehouse. This quantity consists of inventory from reservation including inventory that is picked or being picked but not yet shipped or consumed. It excludes the quantity blocked by bins, item tracking or reserved against dedicated bins.';
                }
                field("Qty. Res. in Pick/Ship Bins"; Rec."Qty. Res. in Pick/Ship Bins")
                {
                    Caption = 'Reserved Qty. in Pick/Ship Bins';
                    ToolTip = 'Specifies the quantity reserved in pick/ship bins.';
                }
                field("Qty. Reserved for this Line"; Rec."Qty. Reserved for this Line")
                {
                    Caption = 'Reserved Qty. for Current Line';
                    ToolTip = 'Specifies the quantity reserved for the selected line.';
                }

                group(TrackingEnabled2)
                {
                    ShowCaption = false;
                    Visible = IsTrackingVisible;

                    field("Qty. Block. Item Tracking Res."; Rec."Qty. Block. Item Tracking Res.")
                    {
                        Caption = 'Qty. in Blocked Item Tracking';
                        ToolTip = 'Specifies the quantity in blocked item tracking for the quantity reserved in warehouse.';
                    }
                }

                field("Qty. in Active Pick Lines Res."; Rec."Qty. in Active Pick Lines Res.")
                {
                    Caption = 'Qty. in Active Pick Lines';
                    ToolTip = 'Specifies the quantity assigned in active warehouse pick documents.';
                    Visible = false;
                }

                field(Impact; ReservationImpactValue)
                {
                    Caption = 'Impact';
                    ToolTip = 'Specifies the impact of reservations on the quantity available to pick. Pickable quantity is reduced by the quantity reserved in warehouse by other documents.';
                    DecimalPlaces = 0 : 5;
                    StyleExpr = ReservationImpactStyle;
                }
            }
            field("Qty. Handled (Base)"; Rec."Qty. Handled (Base)")
            {
                StyleExpr = QtyToHandleStyle;
                ToolTip = 'Specifies the number of items on the line that have been handled in this warehouse activity.';
            }
        }
    }

    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        ActiveWorksheetLine: Record "Whse. Worksheet Line";
        BinTypeFilter: Option ExcludeReceive,ExcludeShip,OnlyPickBins;
        IsCalledFromMovementWorksheet: Boolean;
        IsTrackingVisible: Boolean;
        IsReservationImpactVisible: Boolean;
        ReservationImpactValue: Decimal;
        ReservationImpactStyle: Text;
        QtyToHandleStyle: Text;
        IsActiveWhseWorksheetVisible: Boolean;
        ActiveWorksheetBatchNameText: Text;

    trigger OnAfterGetCurrRecord()
    var
        ItemTrackingManagement: Codeunit "Item Tracking Management";
    begin
        IsTrackingVisible := ItemTrackingManagement.GetWhseItemTrkgSetup(Rec."Item No.", WhseItemTrackingSetup);
        IsReservationImpactVisible := Rec."Qty. reserved in warehouse" > 0;

        if IsReservationImpactVisible then
            SetReservationImpactValue();
        QtyToHandleStyle := Rec.SetQtyToHandleStyle();

        if ActiveWorksheetLine.GetBySystemId(Rec.ActiveWhseWorksheetLine) then begin
            IsActiveWhseWorksheetVisible := true;
            ActiveWorksheetBatchNameText := ActiveWorksheetLine.Name;
        end
        else begin
            Clear(ActiveWorksheetBatchNameText);
            Clear(ActiveWorksheetLine);
            Clear(IsActiveWhseWorksheetVisible);
        end;
    end;

    internal procedure SetRecords(var WarehousePickSummary: Record "Warehouse Pick Summary")
    begin
        if WarehousePickSummary.FindFirst() then
            Rec.Copy(WarehousePickSummary, true);
    end;

    internal procedure SetCalledFromMovementWorksheet(CalledFromMovementWorksheet: Boolean)
    begin
        IsCalledFromMovementWorksheet := CalledFromMovementWorksheet;
    end;

    local procedure SetReservationImpactValue()
    var
        CreatePick: Codeunit "Create Pick";
        AvailabilityAfterReservationImpactValue: Decimal;
    begin
        AvailabilityAfterReservationImpactValue := CreatePick.CalcAvailabilityAfterReservationImpact(Rec."Available qty. not in ship bin", Rec."Qty. reserved in warehouse", Rec."Qty. res. in pick/ship bins", Rec."Qty. reserved for this line");
        if AvailabilityAfterReservationImpactValue < Rec."Potential pickable qty." then
            ReservationImpactValue := (Rec."Potential pickable qty." - AvailabilityAfterReservationImpactValue) * -1
        else
            ReservationImpactValue := 0;
        ReservationImpactStyle := SetReservationImpactStyle();
    end;

    local procedure SetReservationImpactStyle(): Text
    begin
        if ReservationImpactValue < 0 then
            exit('attention')
        else
            exit('favorable');
    end;
}
