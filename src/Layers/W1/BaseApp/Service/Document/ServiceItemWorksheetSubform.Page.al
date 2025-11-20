// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Location;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Setup;

page 5907 "Service Item Worksheet Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Service Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type of the service line.';

                    trigger OnValidate()
                    begin
                        NoOnAfterValidate();
                    end;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnValidate()
                    var
                        Item: Record "Item";
                    begin
                        NoOnAfterValidate();
                        if Rec."Variant Code" = '' then
                            VariantCodeMandatory := Item.IsVariantMandatory(Rec.Type = Rec.Type::Item, Rec."No.");
                    end;
                }
                field("Item Reference No."; Rec."Item Reference No.")
                {
                    AccessByPermission = tabledata "Item Reference" = R;
                    ApplicationArea = Service, ItemReferences;
                    QuickEntry = false;
                    ToolTip = 'Specifies the referenced item number. If you enter a cross reference between yours and your vendor''s or customer''s item number, then this number will override the standard item number when you enter the reference number on a service document.';
                    Visible = ItemReferenceVisible;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ServItemReferenceMgt: Codeunit "Serv. Item Reference Mgt.";
                    begin
                        ServItemReferenceMgt.ServiceReferenceNoLookup(Rec);
                        NoOnAfterValidate();
                        CurrPage.Update();
                    end;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                    ShowMandatory = VariantCodeMandatory;

                    trigger OnValidate()
                    var
                        Item: Record "Item";
                    begin
                        if Rec."Variant Code" = '' then
                            VariantCodeMandatory := Item.IsVariantMandatory(Rec.Type = Rec.Type::Item, Rec."No.");
                    end;
                }
                field(Nonstock; Rec.Nonstock)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the item is a catalog item.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the description of an item, resource, cost, or a standard text on the line.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies information in addition to the description.';
                    Visible = false;
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for the type of work performed by the resource registered on this line.';
                    Visible = false;
                }
                field(Control86; Rec.Reserve)
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies whether a reservation can be made for items on this line.';
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the inventory location from where the items on the line should be taken and where they should be registered.';

                    trigger OnValidate()
                    begin
                        LocationCodeOnAfterValidate();
                    end;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the item or resource''s unit of measure, such as piece or hour.';
                    Visible = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of item units, resource hours, cost on the service line.';

                    trigger OnValidate()
                    begin
                        QuantityOnAfterValidate();
                    end;
                }
                field("Reserved Quantity"; Rec."Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies how many item units on this line have been reserved.';
                    Visible = false;
                }
                field("Fault Reason Code"; Rec."Fault Reason Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the fault reason for this service line.';
                }
                field("Fault Area Code"; Rec."Fault Area Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the fault area associated with this line.';
                }
                field("Symptom Code"; Rec."Symptom Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the symptom associated with this line.';
                }
                field("Fault Code"; Rec."Fault Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the fault associated with this line.';
                }
                field("Resolution Code"; Rec."Resolution Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the resolution associated with this line.';
                }
                field("Serv. Price Adjmt. Gr. Code"; Rec."Serv. Price Adjmt. Gr. Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service price adjustment group code that applies to this line.';
                    Visible = false;
                }
                field("Tax Liable"; Rec."Tax Liable")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies if the customer or vendor is liable for sales tax.';
                    Visible = false;
                }
                field("Tax Area Code"; Rec."Tax Area Code")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the tax area that is used to calculate and post sales tax.';
                    Visible = false;
                }
                field("Tax Group Code"; Rec."Tax Group Code")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the sales tax group code to which this item belongs.';
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the price of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the discount defined for a particular group, item, or combination of the two.';
                }
                field("Line Discount Amount"; Rec."Line Discount Amount")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the discount amount that is granted for the item on the line.';
                }
                field("Line Discount Type"; Rec."Line Discount Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type of the line discount assigned to this line.';
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the value of products on the worksheet line.';
                }
                field("Exclude Warranty"; Rec."Exclude Warranty")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the warranty discount is excluded on this line.';
                }
                field("Exclude Contract Discount"; Rec."Exclude Contract Discount")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the contract discount is excluded for the item, resource, or cost on this line.';
                }
                field(Warranty; Rec.Warranty)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that a warranty discount is available on this line of type Item or Resource.';
                }
                field("Warranty Disc. %"; Rec."Warranty Disc. %")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the percentage of the warranty discount that is valid for the items or resources on this line.';
                    Visible = false;
                }
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the contract, if the service order originated from a service contract.';
                }
                field("Contract Disc. %"; Rec."Contract Disc. %")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the contract discount percentage that is valid for the items, resources, and costs on this line.';
                    Visible = false;
                }
                field("VAT %"; Rec."VAT %")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the VAT percentage used to calculate Amount Including VAT on this line.';
                    Visible = false;
                }
                field("VAT Base Amount"; Rec."VAT Base Amount")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the amount that serves as a base for calculating the Amount Including VAT field.';
                    Visible = false;
                }
                field("Amount Including VAT"; Rec."Amount Including VAT")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the net amount, including VAT, for this line.';
                    Visible = false;
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
                    Visible = false;
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                    Visible = false;
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    Visible = false;
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    Visible = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the service line should be posted.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        PostingDateOnAfterValidate();
                    end;
                }
                field("Planned Delivery Date"; Rec."Planned Delivery Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the planned date that the shipment will be delivered at the customer''s address. If the customer requests a delivery date, the program calculates whether the items will be available for delivery on this date. If the items are available, the planned delivery date will be the same as the requested delivery date. If not, the program calculates the date that the items are available for delivery and enters this date in the Planned Delivery Date field.';
                }
                field("Needed by Date"; Rec."Needed by Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when you require the item to be available for a service order.';
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
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(3),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(3, ShortcutDimCode[3]);
                    end;
                }
                field("ShortcutDimCode[4]"; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(4),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(4, ShortcutDimCode[4]);
                    end;
                }
                field("ShortcutDimCode[5]"; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(5),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(5, ShortcutDimCode[5]);
                    end;
                }
                field("ShortcutDimCode[6]"; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(6),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(6, ShortcutDimCode[6]);
                    end;
                }
                field("ShortcutDimCode[7]"; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(7),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(7, ShortcutDimCode[7]);
                    end;
                }
                field("ShortcutDimCode[8]"; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(8),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(8, ShortcutDimCode[8]);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(SelectMultiItems)
            {
                AccessByPermission = TableData Item = R;
                ApplicationArea = Service;
                Caption = 'Select items';
                Ellipsis = true;
                Image = NewItem;
                ToolTip = 'Add two or more items from the full list of available items.';

                trigger OnAction()
                begin
                    Rec.SelectMultipleItems();
                end;
            }

            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Insert Ext. Texts")
                {
                    AccessByPermission = TableData "Extended Text Header" = R;
                    ApplicationArea = Service;
                    Caption = 'Insert &Ext. Texts';
                    Image = Text;
                    ToolTip = 'Insert the extended item description that is set up for the item that is being processed on the line.';

                    trigger OnAction()
                    begin
                        InsertExtendedText(true);
                    end;
                }
                action("Insert Starting Fee")
                {
                    ApplicationArea = Service;
                    Caption = 'Insert &Starting Fee';
                    Image = InsertStartingFee;
                    ToolTip = 'Add a general starting fee for the service order.';

                    trigger OnAction()
                    begin
                        InsertStartFee();
                    end;
                }
                action("Insert Travel Fee")
                {
                    ApplicationArea = Service;
                    Caption = 'Insert &Travel Fee';
                    Image = InsertTravelFee;
                    ToolTip = 'Add a general travel fee for the service order.';

                    trigger OnAction()
                    begin
                        InsertTravelFee();
                    end;
                }
                action(Reserve)
                {
                    ApplicationArea = Reservation;
                    Caption = 'Reserve';
                    Image = Reserve;
                    ToolTip = 'Reserve items for the selected line.';

                    trigger OnAction()
                    begin
                        Rec.Find();
                        Rec.ShowReservation();
                    end;
                }
                action("Order Tracking")
                {
                    ApplicationArea = Service;
                    Caption = 'Order Tracking';
                    Image = OrderTracking;
                    ToolTip = 'Tracks the connection of a supply to its corresponding demand. This can help you find the original demand that created a specific production order or purchase order.';

                    trigger OnAction()
                    begin
                        Rec.Find();
                        Rec.ShowTracking();
                    end;
                }
                action("&Catalog Items")
                {
                    AccessByPermission = TableData "Nonstock Item" = R;
                    ApplicationArea = Service;
                    Caption = '&Catalog Items';
                    Image = NonStockItem;
                    ToolTip = 'View the list of items that you do not carry in inventory. ';

                    trigger OnAction()
                    begin
                        Rec.ShowNonstock();
                    end;
                }
            }
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                group("Item Availability by")
                {
                    Caption = 'Item Availability by';
                    Image = ItemAvailability;
                    action("Event")
                    {
                        ApplicationArea = Planning;
                        Caption = 'Event';
                        Image = "Event";
                        ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                        trigger OnAction()
                        begin
                            ServAvailabilityMgt.ShowItemAvailabilityFromServLine(Rec, "Item Availability Type"::"Event");
                        end;
                    }
                    action(Period)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Period';
                        Image = Period;
                        ToolTip = 'View the projected quantity of the item over time according to time periods, such as day, week, or month.';

                        trigger OnAction()
                        begin
                            ServAvailabilityMgt.ShowItemAvailabilityFromServLine(Rec, "Item Availability Type"::Period);
                        end;
                    }
                    action(Variant)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Variant';
                        Image = ItemVariant;
                        ToolTip = 'View or edit the item''s variants. Instead of setting up each color of an item as a separate item, you can set up the various colors as variants of the item.';

                        trigger OnAction()
                        begin
                            ServAvailabilityMgt.ShowItemAvailabilityFromServLine(Rec, "Item Availability Type"::Variant);
                        end;
                    }
                    action(Location)
                    {
                        AccessByPermission = TableData Location = R;
                        ApplicationArea = Location;
                        Caption = 'Location';
                        Image = Warehouse;
                        ToolTip = 'View the actual and projected quantity of the item per location.';

                        trigger OnAction()
                        begin
                            ServAvailabilityMgt.ShowItemAvailabilityFromServLine(Rec, "Item Availability Type"::Location);
                        end;
                    }
                    action(Lot)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot';
                        Image = LotInfo;
                        RunObject = Page "Item Availability by Lot No.";
                        RunPageLink = "No." = field("No."),
                            "Location Filter" = field("Location Code"),
                            "Variant Filter" = field("Variant Code");
                        ToolTip = 'View the current and projected quantity of the item in each lot.';
                    }
                    action("BOM Level")
                    {
                        ApplicationArea = Planning;
                        Caption = 'BOM Level';
                        Image = BOMLevel;
                        ToolTip = 'View availability figures for items on bills of materials that show how many units of a parent item you can make based on the availability of child items.';

                        trigger OnAction()
                        begin
                            ServAvailabilityMgt.ShowItemAvailabilityFromServLine(Rec, "Item Availability Type"::BOM);
                        end;
                    }
                }
                action(Dimensions)
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
                action("Select Item Substitution")
                {
                    AccessByPermission = TableData "Item Substitution" = R;
                    ApplicationArea = Service;
                    Caption = 'Select Item Substitution';
                    Image = SelectItemSubstitution;
                    ToolTip = 'Select another item that has been set up to be traded instead of the original item if it is unavailable.';

                    trigger OnAction()
                    begin
                        SelectItemSubstitution();
                    end;
                }
                action("&Fault/Resol. Codes Relationships")
                {
                    ApplicationArea = Service;
                    Caption = '&Fault/Resol. Codes Relationships';
                    Image = FaultDefault;
                    ToolTip = 'View or edit the relationships between fault codes, including the fault, fault area, and symptom codes, as well as resolution codes and service item groups. It displays the existing combinations of these codes for the service item group of the service item from which you accessed the window and the number of occurrences for each one.';

                    trigger OnAction()
                    begin
                        SelectFaultResolutionCode();
                    end;
                }
                action("Item &Tracking Lines")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    ShortCutKey = 'Ctrl+Alt+I';
                    ToolTip = 'View or edit serial, lot and package numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    begin
                        Rec.OpenItemTrackingLines();
                    end;
                }
                action("Order &Promising Line")
                {
                    AccessByPermission = TableData "Order Promising Line" = R;
                    ApplicationArea = OrderPromising;
                    Caption = 'Order &Promising Line';
                    ToolTip = 'View the calculated delivery date.';

                    trigger OnAction()
                    begin
                        Rec.ShowOrderPromisingLine();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Item: Record Item;
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
        if Rec."Variant Code" = '' then
            VariantCodeMandatory := Item.IsVariantMandatory(Rec.Type = Rec.Type::Item, Rec."No.");
    end;

    trigger OnDeleteRecord(): Boolean
    var
        ServiceLineReserve: Codeunit "Service Line-Reserve";
    begin
        if (Rec.Quantity <> 0) and Rec.ItemExists(Rec."No.") then begin
            Commit();
            if not ServiceLineReserve.DeleteLineConfirm(Rec) then
                exit(false);
            ServiceLineReserve.DeleteLine(Rec);
        end;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec."Line No." := Rec.GetLineNo();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.Type := xRec.Type;
        Clear(ShortcutDimCode);
        Rec.Validate("Service Item Line No.", ServItemLineNo);
    end;

    trigger OnOpenPage()
    begin
        SetItemReferenceVisibility();
    end;

    var
        ServMgtSetup: Record "Service Mgt. Setup";
        ServAvailabilityMgt: Codeunit "Serv. Availability Mgt.";
        ServItemLineNo: Integer;
        ItemReferenceVisible: Boolean;
        VariantCodeMandatory: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot open the window because %1 is %2 in the %3 table.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
        ShortcutDimCode: array[8] of Code[20];

    procedure SetValues(TempServItemLineNo: Integer)
    begin
        ServItemLineNo := TempServItemLineNo;
        Rec.SetFilter("Service Item Line No.", '=%1|=%2', 0, ServItemLineNo);
    end;

    local procedure InsertStartFee()
    var
        ServOrderMgt: Codeunit ServOrderManagement;
    begin
        Clear(ServOrderMgt);
        if ServOrderMgt.InsertServCost(Rec, 1, true) then
            CurrPage.Update();
    end;

    local procedure InsertTravelFee()
    var
        ServOrderMgt: Codeunit ServOrderManagement;
    begin
        Clear(ServOrderMgt);
        if ServOrderMgt.InsertServCost(Rec, 0, true) then
            CurrPage.Update();
    end;

    procedure InsertExtendedText(Unconditionally: Boolean)
    var
        ServiceTransferExtText: Codeunit "Service Transfer Ext. Text";
    begin
        OnBeforeInsertExtendedText(Rec);
        if ServiceTransferExtText.ServCheckIfAnyExtText(Rec, Unconditionally) then begin
            CurrPage.SaveRecord();
            ServiceTransferExtText.InsertServExtText(Rec);
        end;
        if ServiceTransferExtText.MakeUpdate() then
            CurrPage.Update();
    end;

    local procedure SelectFaultResolutionCode()
    var
        ServItemLine: Record "Service Item Line";
        FaultResolutionRelation: Page "Fault/Resol. Cod. Relationship";
    begin
        ServMgtSetup.Get();
        case ServMgtSetup."Fault Reporting Level" of
            ServMgtSetup."Fault Reporting Level"::None:
                Error(
                  Text000,
                  ServMgtSetup.FieldCaption("Fault Reporting Level"), ServMgtSetup."Fault Reporting Level", ServMgtSetup.TableCaption());
        end;
        ServItemLine.Get(Rec."Document Type", Rec."Document No.", Rec."Service Item Line No.");
        Clear(FaultResolutionRelation);
        FaultResolutionRelation.SetDocument(DATABASE::"Service Line", Rec."Document Type".AsInteger(), Rec."Document No.", Rec."Line No.");
        FaultResolutionRelation.SetFilters(Rec."Symptom Code", Rec."Fault Code", Rec."Fault Area Code", ServItemLine."Service Item Group Code");
        FaultResolutionRelation.RunModal();
        CurrPage.Update(false);
    end;

    local procedure SelectItemSubstitution()
    begin
        Rec.ShowItemSub();
        Rec.Modify();
    end;

    protected procedure NoOnAfterValidate()
    begin
        InsertExtendedText(false);

        if (Rec.Reserve = Rec.Reserve::Always) and
           (Rec."Outstanding Qty. (Base)" <> 0) and
           (Rec."No." <> xRec."No.")
        then begin
            CurrPage.SaveRecord();
            Rec.AutoReserve();
            CurrPage.Update(false);
        end;
    end;

    protected procedure LocationCodeOnAfterValidate()
    begin
        if (Rec.Reserve = Rec.Reserve::Always) and
           (Rec."Outstanding Qty. (Base)" <> 0) and
           (Rec."Location Code" <> xRec."Location Code")
        then begin
            CurrPage.SaveRecord();
            Rec.AutoReserve();
            CurrPage.Update(false);
        end;
    end;

    protected procedure QuantityOnAfterValidate()
    begin
        if Rec.Type = Rec.Type::Item then
            case Rec.Reserve of
                Rec.Reserve::Always:
                    begin
                        CurrPage.SaveRecord();
                        Rec.AutoReserve();
                        CurrPage.Update(false);
                    end;
                Rec.Reserve::Optional:
                    if (Rec.Quantity < xRec.Quantity) and (xRec.Quantity > 0) then begin
                        CurrPage.SaveRecord();
                        CurrPage.Update(false);
                    end;
            end;
    end;

    protected procedure PostingDateOnAfterValidate()
    begin
        if (Rec.Reserve = Rec.Reserve::Always) and
           (Rec."Outstanding Qty. (Base)" <> 0) and
           (Rec."Posting Date" <> xRec."Posting Date")
        then begin
            CurrPage.SaveRecord();
            Rec.AutoReserve();
            CurrPage.Update(false);
        end;
    end;

    local procedure SetItemReferenceVisibility()
    var
        ItemReference: Record "Item Reference";
    begin
        ItemReferenceVisible := not ItemReference.IsEmpty();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertExtendedText(var ServiceLine: Record "Service Line")
    begin
    end;
}

