// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Ledger;

page 5970 "Posted Service Shipment Lines"
{
    AutoSplitKey = true;
    Caption = 'Posted Service Shipment Lines';
    DataCaptionFields = "Document No.";
    DelayedInsert = true;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    SourceTable = "Service Shipment Line";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(SelectionFilter; SelectionFilter)
                {
                    ApplicationArea = Service;
                    Caption = 'Selection Filter';
                    OptionCaption = 'All Service Shipment Lines,Lines per Selected Service Item,Lines Not Item Related';
                    ToolTip = 'Specifies a selection filter.';

                    trigger OnValidate()
                    begin
                        SelectionFilterOnAfterValidate();
                    end;
                }
            }
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("Service Item Line No."; Rec."Service Item Line No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service item line to which this service line is linked.';
                    Visible = false;
                }
                field("Service Item No."; Rec."Service Item No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service item to which this service line is linked.';
                    Visible = false;
                }
                field("Service Item Serial No."; Rec."Service Item Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the serial number of the service item to which this shipment line is linked.';
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type of this shipment line.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the description of an item, resource, cost, or a standard text on the service line.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Service;
                    Importance = Additional;
                    ToolTip = 'Specifies information in addition to the description.';
                    Visible = false;
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for the type of work performed under the posted service order.';
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the number of item units, resource hours, general ledger account payments, or cost that have been shipped to the customer.';
                }
                field("Quantity Invoiced"; Rec."Quantity Invoiced")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies how many units of the item on the line have been posted as invoiced.';
                }
                field("Quantity Consumed"; Rec."Quantity Consumed")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the number of units of items, resource hours, general ledger account payments, or costs that have been posted as consumed.';
                }
                field("Qty. Shipped Not Invoiced"; Rec."Qty. Shipped Not Invoiced")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the quantity of the shipped item that has been posted as shipped but that has not yet been posted as invoiced.';
                }
                field("Fault Area Code"; Rec."Fault Area Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the fault area associated with this service line.';
                }
                field("Symptom Code"; Rec."Symptom Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the symptom associated with this service shipment line.';
                }
                field("Fault Code"; Rec."Fault Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the fault code associated with this service shipment line.';
                }
                field("Fault Reason Code"; Rec."Fault Reason Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the fault reason for the service shipment line.';
                    Visible = false;
                }
                field("Resolution Code"; Rec."Resolution Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the resolution associated with this service shipment line.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location, such as warehouse or distribution center, from which the items should be taken and where they should be registered.';
                    Visible = false;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                    Visible = false;
                }
                field("Spare Part Action"; Rec."Spare Part Action")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies whether the item has been used to replace the whole service item, one of the service item components, installed as a new component, or as a supplementary tool in the service process.';
                }
                field("Replaced Item Type"; Rec."Replaced Item Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type of the service item component replaced by the item on the service line.';
                }
                field("Replaced Item No."; Rec."Replaced Item No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service item component replaced by the item on the service line.';
                }
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the contract associated with the posted service order.';
                }
                field("Posting Group"; Rec."Posting Group")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code for the posting group used when the service line was posted.';
                    Visible = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the service line was posted.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
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
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Dimenions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
                action(ItemTrackingEntries)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Entries';
                    Image = ItemTrackingLedger;
                    ToolTip = 'View serial, lot or package numbers that are assigned to items.';

                    trigger OnAction()
                    begin
                        Rec.ShowItemTrackingLines();
                    end;
                }
                separator(Action27)
                {
                }
                action(ItemInvoiceLines)
                {
                    ApplicationArea = Service;
                    Caption = 'Item Invoice &Lines';
                    Image = ItemInvoice;
                    ToolTip = 'View posted sales invoice lines for the item. ';

                    trigger OnAction()
                    begin
                        Rec.TestField(Type, Rec.Type::Item);
                        Rec.ShowItemServInvLines();
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("&Order Tracking")
                {
                    ApplicationArea = ItemTracking;
                    Caption = '&Order Tracking';
                    Image = OrderTracking;
                    ToolTip = 'Track the connection of a supply to its corresponding demand. This can help you find the original demand that created a specific production order or purchase order.';

                    trigger OnAction()
                    begin
                        ShowTracking();
                    end;
                }
                separator(Action86)
                {
                }
                action(UndoShipment)
                {
                    ApplicationArea = Service;
                    Caption = '&Undo Shipment';
                    Image = UndoShipment;
                    ToolTip = 'Withdraw the line from the shipment. This is useful for making corrections, because the line is not deleted. You can make changes and post it again.';

                    trigger OnAction()
                    begin
                        UndoServShptPosting();
                    end;
                }
                action(UndoConsumption)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'U&ndo Consumption';
                    Image = Undo;
                    ToolTip = 'Cancel the consumption on the service order, for example because it was posted by mistake.';

                    trigger OnAction()
                    begin
                        UndoServConsumption();
                    end;
                }
            }
            action("&Navigate")
            {
                ApplicationArea = Service;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                begin
                    Rec.Navigate();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(UndoShipment_Promoted; UndoShipment)
                {
                }
                actionref(UndoConsumption_Promoted; UndoConsumption)
                {
                }
                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
            }
            group(Category_Line)
            {
                Caption = 'Line';

                actionref(ItemTrackingEntries_Promoted; ItemTrackingEntries)
                {
                }
                actionref(ItemInvoiceLines_Promoted; ItemInvoiceLines)
                {
                }
                actionref(Dimenions_Promoted; Dimenions)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetSecurityFilterOnRespCenter();
        Clear(SelectionFilter);
        SetSelectionFilter();
    end;

    var
        SelectionFilter: Option "All Shipment Lines","Lines per Selected Service Item","Lines Not Item Related";
        ServItemLineNo: Integer;

    procedure Initialize(ServItemLineNo2: Integer)
    begin
        ServItemLineNo := ServItemLineNo2;
    end;

    procedure SetSelectionFilter()
    begin
        case SelectionFilter of
            SelectionFilter::"All Shipment Lines":
                Rec.SetRange("Service Item Line No.");
            SelectionFilter::"Lines per Selected Service Item":
                Rec.SetRange("Service Item Line No.", ServItemLineNo);
            SelectionFilter::"Lines Not Item Related":
                Rec.SetFilter("Service Item Line No.", '=%1', 0);
        end;
        CurrPage.Update(false);
    end;

    local procedure ShowTracking()
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        TrackingForm: Page "Order Tracking";
    begin
        Rec.TestField(Type, Rec.Type::Item);
        if Rec."Item Shpt. Entry No." <> 0 then begin
            ItemLedgEntry.Get(Rec."Item Shpt. Entry No.");
            TrackingForm.SetItemLedgEntry(ItemLedgEntry);
        end else
            TrackingForm.SetMultipleItemLedgEntries(TempItemLedgEntry,
              DATABASE::"Service Shipment Line", 0, Rec."Document No.", '', 0, Rec."Line No.");
        TrackingForm.RunModal();
    end;

    local procedure UndoServShptPosting()
    var
        ServShptLine: Record "Service Shipment Line";
    begin
        ServShptLine.Copy(Rec);
        CurrPage.SetSelectionFilter(ServShptLine);
        CODEUNIT.Run(CODEUNIT::"Undo Service Shipment Line", ServShptLine);
    end;

    local procedure UndoServConsumption()
    var
        ServShptLine: Record "Service Shipment Line";
    begin
        ServShptLine.Copy(Rec);
        CurrPage.SetSelectionFilter(ServShptLine);
        CODEUNIT.Run(CODEUNIT::"Undo Service Consumption Line", ServShptLine);
    end;

    local procedure SelectionFilterOnAfterValidate()
    begin
        CurrPage.Update();
        SetSelectionFilter();
    end;
}

