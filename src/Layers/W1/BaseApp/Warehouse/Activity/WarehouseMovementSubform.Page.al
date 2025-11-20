// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Structure;

page 7316 "Warehouse Movement Subform"
{
    Caption = 'Lines';
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Warehouse Activity Line";
    SourceTableView = sorting("Activity Type", "No.", "Sorting Sequence No.")
                      where("Activity Type" = const(Movement));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Action Type"; Rec."Action Type")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the action type for the warehouse activity line.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the item number of the item to be handled, such as picked or put away.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a description of the item on the line.';
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the serial number to handle in the document.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        SerialNoOnAfterValidate();
                    end;
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the lot number to handle in the document.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        LotNoOnAfterValidate();
                    end;
                }
                field("Package No."; Rec."Package No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the package number to handle in the document.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        PackageNoOnAfterValidate();
                    end;
                }
                field("Expiration Date"; Rec."Expiration Date")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    ToolTip = 'Specifies the expiration date of the serial/lot numbers if you are putting items away.';
                    Visible = false;
                }
                field("Zone Code"; Rec."Zone Code")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Zone Code';
                    ToolTip = 'Specifies the zone code where the bin on this line is located.';
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Bin Code';
                    ToolTip = 'Specifies the bin where items on the line are handled.';

                    trigger OnValidate()
                    begin
                        BinCodeOnAfterValidate();
                    end;
                }
                field("Special Equipment Code"; Rec."Special Equipment Code")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Special Equipment Code';
                    ToolTip = 'Specifies the code of the equipment required when you perform the action on the line.';
                    Visible = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of the item to be handled, such as received, put-away, or assigned.';
                    Editable = false;
                }
                field("Qty. (Base)"; Rec."Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of the item to be handled, in the base unit of measure.';
                    Visible = false;
                }
                field("Qty. to Handle"; Rec."Qty. to Handle")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how many units to handle in this warehouse activity.';

                    trigger OnValidate()
                    begin
                        QtytoHandleOnAfterValidate();
                    end;
                }
                field("Qty. to Handle (Base)"; Rec."Qty. to Handle (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of items to be handled in this warehouse activity.';
                    Visible = false;
                }
                field("Qty. Outstanding"; Rec."Qty. Outstanding")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of items that have not yet been handled for this warehouse activity line.';
                }
                field("Qty. Outstanding (Base)"; Rec."Qty. Outstanding (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of items, expressed in the base unit of measure, that have not yet been handled for this warehouse activity line.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date when the warehouse activity must be completed.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity per unit of measure of the item on the line.';
                }
                field(Weight; Rec.Weight)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the weight of one item unit when measured in the specified unit of measure.';
                    Visible = false;
                }
                field(Cubage; Rec.Cubage)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the total cubage of items on the line, calculated based on the Quantity field.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(SplitWhseActivityLine)
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Split Line';
                    Image = Split;
                    ShortCutKey = 'Ctrl+F11';
                    ToolTip = 'Enable that the items can be taken or placed in more than one bin, for example, because the quantity in the suggested bin is insufficient to pick or move or there is not enough room to put away the required quantity.';

                    trigger OnAction()
                    begin
                        CallSplitLine();
                    end;
                }
                action(FillQtyToHandle)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Autofill Qty. To Handle';
                    Image = AutofillQtyToHandle;
                    Gesture = LeftSwipe;
                    ToolTip = 'Have the system enter the outstanding quantity in the Qty. to Handle field.';
                    Scope = Repeater;

                    trigger OnAction()
                    begin
                        Rec.AutofillQtyToHandleOnLine(Rec);
                    end;
                }
                action(ResetQtyToHandle)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Reset Qty. To Handle';
                    Image = UndoFluent;
                    Gesture = RightSwipe;
                    ToolTip = 'Have the system clear the value in the Qty. To Handle field.';
                    Scope = Repeater;

                    trigger OnAction()
                    begin
                        Rec.DeleteQtyToHandleOnLine(Rec);
                    end;
                }
                action(ChangeUnitOfMeasure)
                {
                    ApplicationArea = Suite;
                    Caption = '&Change Unit Of Measure';
                    Ellipsis = true;
                    Image = UnitConversions;
                    ToolTip = 'Specify which unit of measure you want to change during the warehouse activity, for example, because you want to ship an item in boxes although you store it in pallets.';

                    trigger OnAction()
                    begin
                        ChangeUOM();
                    end;
                }
            }
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("Bin Contents List")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Bin Contents List';
                    Image = BinContent;
                    ToolTip = 'View the contents of the selected bin and the parameters that define how items are routed through the bin.';

                    trigger OnAction()
                    begin
                        ShowBinContents();
                    end;
                }
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.Update(false);
    end;

    trigger OnOpenPage()
    begin
    end;

    procedure AutofillQtyToHandle()
    var
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        WhseActivLine.Copy(Rec);
        OnAutofillQtyToHandleOnBeforeRecAutofillQtyToHandle(WhseActivLine);
        Rec.AutofillQtyToHandle(WhseActivLine);
    end;

    procedure DeleteQtyToHandle()
    var
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        WhseActivLine.Copy(Rec);
        Rec.DeleteQtyToHandle(WhseActivLine);
    end;

    local procedure CallSplitLine()
    var
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        WhseActivLine.Copy(Rec);
        Rec.SplitLine(WhseActivLine);
        Rec.Copy(WhseActivLine);
        CurrPage.Update(false);
    end;

    local procedure ChangeUOM()
    var
        WhseActLine: Record "Warehouse Activity Line";
        WhseChangeOUM: Report "Whse. Change Unit of Measure";
    begin
        Rec.TestField("Action Type");
        Rec.TestField("Breakbulk No.", 0);
        Rec.TestField("Qty. to Handle");
        WhseChangeOUM.DefWhseActLine(Rec);
        WhseChangeOUM.RunModal();
        if WhseChangeOUM.ChangeUOMCode(WhseActLine) then
            Rec.ChangeUOMCode(Rec, WhseActLine);
        Clear(WhseChangeOUM);
        CurrPage.Update(false);
    end;

    procedure RegisterActivityYesNo()
    var
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        WhseActivLine.Copy(Rec);
        WhseActivLine.FilterGroup(3);
        WhseActivLine.SetRange(Breakbulk);
        WhseActivLine.FilterGroup(0);
        CODEUNIT.Run(CODEUNIT::"Whse.-Act.-Register (Yes/No)", WhseActivLine);
        Rec.Reset();
        Rec.SetCurrentKey("Activity Type", "No.", "Sorting Sequence No.");
        Rec.FilterGroup(4);
        Rec.SetRange("Activity Type", Rec."Activity Type");
        Rec.SetRange("No.", Rec."No.");
        Rec.FilterGroup(3);
        Rec.SetRange(Breakbulk, false);
        Rec.FilterGroup(0);
        CurrPage.Update(false);
    end;

    local procedure ShowBinContents()
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.ShowBinContents(Rec."Location Code", Rec."Item No.", Rec."Variant Code", '');
    end;

    protected procedure SerialNoOnAfterValidate()
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        ExpDate: Date;
        EntriesExist: Boolean;
    begin
        if Rec."Serial No." <> '' then
            ExpDate := ItemTrackingMgt.ExistingExpirationDate(Rec, false, EntriesExist);

        if ExpDate <> 0D then
            Rec."Expiration Date" := ExpDate;
    end;

    protected procedure LotNoOnAfterValidate()
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        ExpDate: Date;
        EntriesExist: Boolean;
    begin
        if Rec."Lot No." <> '' then
            ExpDate := ItemTrackingMgt.ExistingExpirationDate(Rec, false, EntriesExist);

        if ExpDate <> 0D then
            Rec."Expiration Date" := ExpDate;
    end;

    protected procedure PackageNoOnAfterValidate()
    begin
    end;

    protected procedure BinCodeOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    protected procedure QtytoHandleOnAfterValidate()
    begin
        CurrPage.SaveRecord();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAutofillQtyToHandleOnBeforeRecAutofillQtyToHandle(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;
}

