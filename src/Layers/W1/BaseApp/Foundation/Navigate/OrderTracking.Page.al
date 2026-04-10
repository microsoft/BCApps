// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Navigate;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;

page 99000822 "Order Tracking"
{
    Caption = 'Order Tracking';
    DataCaptionExpression = OrderTrackingMgt.GetCaption();
    PageType = Worksheet;
    SourceTable = "Order Tracking Entry";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(CurrItemNo; CurrItemNo)
                {
                    ApplicationArea = Planning;
                    Caption = 'Item No.';
                    Editable = false;
                    ToolTip = 'Specifies the number of the item related to the order.';
                }
                field(StartingDate; StartingDate)
                {
                    ApplicationArea = Planning;
                    Caption = 'Starting Date';
                    Editable = false;
                    ToolTip = 'Specifies the starting date for the time period for which you want to track the order.';
                }
                field(EndingDate; EndingDate)
                {
                    ApplicationArea = Planning;
                    Caption = 'Ending Date';
                    Editable = false;
                    ToolTip = 'Specifies the end date.';
                }
                field("Total Quantity"; CurrQuantity + DerivedTrackingQty)
                {
                    ApplicationArea = Planning;
                    AutoFormatType = 0;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the outstanding quantity on the line from which you opened the window.';
                }
                field("Untracked Quantity"; CurrUntrackedQuantity + DerivedTrackingQty)
                {
                    ApplicationArea = Planning;
                    AutoFormatType = 0;
                    Caption = 'Untracked Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the quantity not directly related to a countering demand or supply by order tracking or reservations.';

                    trigger OnDrillDown()
                    begin
                        if not IsPlanning then
                            Message(Text001)
                        else
                            PlanningTransparency.DrillDownUntrackedQty(OrderTrackingMgt.GetCaption());
                    end;
                }
            }
            repeater(Control16)
            {
                Editable = false;
                IndentationColumn = SuppliedByIndent;
                IndentationControls = Name;
                ShowCaption = false;
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Planning;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        LookupName();
                    end;
                }
                field("Demanded by"; Rec."Demanded by")
                {
                    ApplicationArea = Planning;
                    Visible = DemandedByVisible;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        LookupLine();
                    end;
                }
                field("Supplied by"; Rec."Supplied by")
                {
                    ApplicationArea = Planning;
                    Visible = SuppliedByVisible;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        LookupLine();
                    end;
                }
                field(Warning; Rec.Warning)
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Planning;
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Planning;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Planning;
                    AutoFormatType = 0;
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Expected Receipt Date"; Rec."Expected Receipt Date")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Planning;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(UntrackedButton)
            {
                ApplicationArea = Planning;
                Caption = '&Untracked Qty.';
                Enabled = UntrackedButtonEnable;
                Image = UntrackedQuantity;
                ToolTip = 'View the part of the tracked quantity that is not directly related to a demand or supply. ';

                trigger OnAction()
                begin
                    PlanningTransparency.DrillDownUntrackedQty(OrderTrackingMgt.GetCaption());
                end;
            }
            action(Show)
            {
                ApplicationArea = Planning;
                Caption = '&Show';
                Image = View;
                ToolTip = 'View the order tracking details.';

                trigger OnAction()
                begin
                    LookupName();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(Show_Promoted; Show)
                {
                }
                actionref(UntrackedButton_Promoted; UntrackedButton)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SuppliedbyOnFormat();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(OrderTrackingMgt.FindRecord(Which, Rec));
    end;

    trigger OnInit()
    begin
        UntrackedButtonEnable := true;
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(OrderTrackingMgt.GetNextRecord(Steps, Rec));
    end;

    trigger OnOpenPage()
    begin
        if not Item.Get(CurrItemNo) then
            Clear(Item);
        OrderTrackingMgt.FindRecords();
        DemandedByVisible := OrderTrackingMgt.IsSearchUp();
        SuppliedByVisible := not OrderTrackingMgt.IsSearchUp();

        CurrUntrackedQuantity := CurrQuantity - OrderTrackingMgt.TrackedQuantity();

        UntrackedButtonEnable := IsPlanning;
    end;

    var
        Item: Record Item;
        OrderTrackingMgt: Codeunit OrderTrackingManagement;
        PlanningTransparency: Codeunit "Planning Transparency";
        CurrItemNo: Code[20];
        CurrQuantity: Decimal;
        CurrUntrackedQuantity: Decimal;
        StartingDate: Date;
        EndingDate: Date;
        DerivedTrackingQty: Decimal;
        IsPlanning: Boolean;
#pragma warning disable AA0074
        Text001: Label 'Information about untracked quantity is only available for calculated planning lines.';
#pragma warning restore AA0074
        DemandedByVisible: Boolean;
        SuppliedByVisible: Boolean;
        UntrackedButtonEnable: Boolean;
        SuppliedByIndent: Integer;


    procedure SetReqLine(var CurrentReqLine: Record "Requisition Line")
    begin
        OrderTrackingMgt.SetReqLine(CurrentReqLine);

        CurrItemNo := CurrentReqLine."No.";
        CurrQuantity := CurrentReqLine."Quantity (Base)";
        StartingDate := CurrentReqLine."Due Date";
        EndingDate := CurrentReqLine."Due Date";

        IsPlanning := CurrentReqLine."Planning Line Origin" = CurrentReqLine."Planning Line Origin"::Planning;
        if IsPlanning then
            PlanningTransparency.SetCurrReqLine(CurrentReqLine);
    end;






    procedure SetPlanningComponent(var CurrentPlanningComponent: Record "Planning Component")
    begin
        OrderTrackingMgt.SetPlanningComponent(CurrentPlanningComponent);

        CurrItemNo := CurrentPlanningComponent."Item No.";
        DerivedTrackingQty := CurrentPlanningComponent."Expected Quantity (Base)" - CurrentPlanningComponent."Net Quantity (Base)";
        CurrQuantity := CurrentPlanningComponent."Net Quantity (Base)";
        StartingDate := CurrentPlanningComponent."Due Date";
        EndingDate := CurrentPlanningComponent."Due Date";
    end;

    procedure SetItemLedgEntry(var CurrentItemLedgEntry: Record "Item Ledger Entry")
    begin
        OrderTrackingMgt.SetItemLedgEntry(CurrentItemLedgEntry);

        CurrItemNo := CurrentItemLedgEntry."Item No.";
        CurrQuantity := CurrentItemLedgEntry."Remaining Quantity";
        StartingDate := CurrentItemLedgEntry."Posting Date";
        EndingDate := CurrentItemLedgEntry."Posting Date";
    end;

    procedure SetMultipleItemLedgEntries(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceBatchName: Code[10]; SourceProdOrderLine: Integer; SourceRefNo: Integer)
    begin
        // Used from posted shipment and receipt with item tracking.

        OrderTrackingMgt.SetMultipleItemLedgEntries(TempItemLedgEntry, SourceType, SourceSubtype, SourceID,
          SourceBatchName, SourceProdOrderLine, SourceRefNo);

        TempItemLedgEntry.CalcSums(TempItemLedgEntry."Remaining Quantity");

        CurrItemNo := TempItemLedgEntry."Item No.";
        CurrQuantity := TempItemLedgEntry."Remaining Quantity";
        StartingDate := TempItemLedgEntry."Posting Date";
        EndingDate := TempItemLedgEntry."Posting Date";
    end;



    procedure SetVariantRec(SourceRecordVar: Variant; NewItemNo: Code[20]; NewQuantity: Decimal; NewStartingDate: Date; NewEndingDate: Date)
    begin
        OrderTrackingMgt.SetSourceRecord(SourceRecordVar);

        CurrItemNo := NewItemNo;
        CurrQuantity := NewQuantity;
        StartingDate := NewStartingDate;
        EndingDate := NewEndingDate;
    end;

    local procedure LookupLine()
    var
        ReservationMgt: Codeunit "Reservation Management";
    begin
        ReservationMgt.LookupLine(Rec."For Type", Rec."For Subtype", Rec."For ID", Rec."For Batch Name", Rec."For Prod. Order Line", Rec."For Ref. No.");
    end;

    local procedure LookupName()
    var
        ReservationMgt: Codeunit "Reservation Management";
    begin
        ReservationMgt.LookupDocument(Rec."From Type", Rec."From Subtype", Rec."From ID", Rec."From Batch Name", Rec."From Prod. Order Line", Rec."From Ref. No.");
    end;

    local procedure SuppliedbyOnFormat()
    begin
        SuppliedByIndent := Rec.Level - 1;
    end;
}
