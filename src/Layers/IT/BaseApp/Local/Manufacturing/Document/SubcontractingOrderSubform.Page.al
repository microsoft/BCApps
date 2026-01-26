// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

page 12153 "Subcontracting Order Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "Purchase Line";
    SourceTableView = where("Document Type" = filter(Order));

    layout
    {
        area(content)
        {
            repeater(Control1130000)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the line type.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the document number.';

                    trigger OnValidate()
                    begin
                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                        NoOnAfterValidate();
                    end;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the code of the variant for which another variant can serve as a substitute.';
                    Visible = false;
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the VAT product posting group for the line.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a description.';
                }
                field("Return Reason Code"; Rec."Return Reason Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the reason for returning the item.';
                    Visible = false;
                }
                field("Prod. Order No."; Rec."Prod. Order No.")
                {
                    ApplicationArea = Manufacturing;
                    Editable = false;
                    ToolTip = 'Specifies the document number.';
                }
                field("Prod. Order Line No."; Rec."Prod. Order Line No.")
                {
                    ApplicationArea = Manufacturing;
                    Editable = false;
                    ToolTip = 'Specifies the line number.';
                    Visible = false;
                }
                field("Operation No."; Rec."Operation No.")
                {
                    ApplicationArea = Manufacturing;
                    Editable = false;
                    ToolTip = 'Specifies the number.';
                }
                field("Work Center No."; Rec."Work Center No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the work center that is assigned the work.';
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the warehouse location.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    ToolTip = 'Specifies the quantity.';
                }
                field("Reserved Quantity"; Rec."Reserved Quantity")
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    ToolTip = 'Specifies the number of items that are reserved.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the unit of measure for the item.';
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the unit of measure for the item.';
                    Visible = false;
                }
#if not CLEAN27
                field("WIP Item"; Rec."WIP Item")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies if the item is a work in process (WIP) item.';
                    ObsoleteReason = 'Preparation for replacement by Subcontracting app';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                }
                field("WIP Qty at Subc.Loc. (Base)"; Rec."WIP Qty at Subc.Loc. (Base)")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of work in process (WIP) items that are at the subcontracting location.';
                    ObsoleteReason = 'Preparation for replacement by Subcontracting app';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                }
#endif
                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    ToolTip = 'Specifies the direct unit cost that is associated with the document.';
                }
                field("Indirect Cost %"; Rec."Indirect Cost %")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the indirect cost percent.';
                    Visible = false;
                }
                field("Unit Cost (LCY)"; Rec."Unit Cost (LCY)")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the unit cost in your currency.';
                    Visible = false;
                }
                field("Unit Price (LCY)"; Rec."Unit Price (LCY)")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the unit price in your currency.';
                    Visible = false;
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    ToolTip = 'Specifies the total amount for the document line.';
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    ToolTip = 'Specifies the discount percent for the document line.';
                }
                field("Line Discount Amount"; Rec."Line Discount Amount")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the discount amount for the document line.';
                    Visible = false;
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies if you can add an invoice discount.';
                    Visible = false;
                }
                field("Inv. Discount Amount"; Rec."Inv. Discount Amount")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the invoice discount amount.';
                    Visible = false;
                }
                field("Qty. to Receive"; Rec."Qty. to Receive")
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    ToolTip = 'Specifies the number of items that will be received.';
                }
                field("Quantity Received"; Rec."Quantity Received")
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    ToolTip = 'Specifies the number of items that have been received.';
                }
#if not CLEAN27
                field("Not Proc. WIP Qty to Receive"; Rec."Not Proc. WIP Qty to Receive")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the non-processed portion of work in process (WIP) items that are still at the subcontracting location.';
                    ObsoleteReason = 'Preparation for replacement by Subcontracting app';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                }
#endif
                field("Qty. to Invoice"; Rec."Qty. to Invoice")
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    ToolTip = 'Specifies the number of items that can be invoiced.';
                }
                field("Quantity Invoiced"; Rec."Quantity Invoiced")
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    ToolTip = 'Specifies the number of items that have been invoiced.';
                }
                field("Allow Item Charge Assignment"; Rec."Allow Item Charge Assignment")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies if you can assign item charges.';
                    Visible = false;
                }
                field("Qty. to Assign"; Rec."Qty. to Assign")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of items that can be assigned.';

                    trigger OnDrillDown()
                    begin
                        CurrPage.SaveRecord();
                        Rec.ShowItemChargeAssgnt();
                        UpdateForm(false);
                    end;
                }
                field("Qty. Assigned"; Rec."Qty. Assigned")
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    ToolTip = 'Specifies the number of items that have been assigned.';

                    trigger OnDrillDown()
                    begin
                        CurrPage.SaveRecord();
                        Rec.ShowItemChargeAssgnt();
                        UpdateForm(false);
                    end;
                }
                field("Requested Receipt Date"; Rec."Requested Receipt Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the wanted date of receipt.';
                    Visible = false;
                }
                field("Promised Receipt Date"; Rec."Promised Receipt Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the date of receipt that the vendor has promised.';
                    Visible = false;
                }
                field("Planned Receipt Date"; Rec."Planned Receipt Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the date when the items are planned to be received.';
                }
                field("Expected Receipt Date"; Rec."Expected Receipt Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the expected date of receipt.';
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the date when the order was registered.';
                }
                field("Lead Time Calculation"; Rec."Lead Time Calculation")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a date formula for the amount of time that it takes to replenish the item. This field is used to calculate the date fields on order and order proposal lines.';
                    Visible = false;
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the item number that is assigned to the job.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                    end;
                }
                field("Planning Flexibility"; Rec."Planning Flexibility")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies if flexibility is allowed or not.';
                    Visible = false;
                }
                field(Finished; Rec.Finished)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies if the document is finished';
                    Visible = false;
                }
                field("Whse. Outstanding Qty. (Base)"; Rec."Whse. Outstanding Qty. (Base)")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the remaining quantity of the item on stock.';
                    Visible = false;
                }
                field("Inbound Whse. Handling Time"; Rec."Inbound Whse. Handling Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a date formula for the inbound warehouse handling time for the location.';
                    Visible = false;
                }
                field("Blanket Order No."; Rec."Blanket Order No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the document number.';
                    Visible = false;
                }
                field("Blanket Order Line No."; Rec."Blanket Order Line No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the line number.';
                    Visible = false;
                }
                field("Appl.-to Item Entry"; Rec."Appl.-to Item Entry")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the item ledger entry that applies to the transaction.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
                    ApplicationArea = Manufacturing;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(3),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    ToolTip = 'Specifies a code for a shortcut dimension.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(3, ShortcutDimCode[3]);
                    end;
                }
                field("ShortcutDimCode[4]"; ShortcutDimCode[4])
                {
                    ApplicationArea = Manufacturing;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(4),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    ToolTip = 'Specifies a code for a shortcut dimension.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(4, ShortcutDimCode[4]);
                    end;
                }
                field("ShortcutDimCode[5]"; ShortcutDimCode[5])
                {
                    ApplicationArea = Manufacturing;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(5),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    ToolTip = 'Specifies a code for a shortcut dimension.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(5, ShortcutDimCode[5]);
                    end;
                }
                field("ShortcutDimCode[6]"; ShortcutDimCode[6])
                {
                    ApplicationArea = Manufacturing;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(6),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    ToolTip = 'Specifies a code for a shortcut dimension.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(6, ShortcutDimCode[6]);
                    end;
                }
                field("ShortcutDimCode[7]"; ShortcutDimCode[7])
                {
                    ApplicationArea = Manufacturing;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(7),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    ToolTip = 'Specifies a code for a shortcut dimension.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(7, ShortcutDimCode[7]);
                    end;
                }
                field("ShortcutDimCode[8]"; ShortcutDimCode[8])
                {
                    ApplicationArea = Manufacturing;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(8),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    ToolTip = 'Specifies a code for a shortcut dimension.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(8, ShortcutDimCode[8]);
                    end;
                }
#if not CLEAN27
                field("UoM for Pricelist"; Rec."UoM for Pricelist")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the unit of measure for the pricelist.';
                    ObsoleteReason = 'Preparation for replacement by Subcontracting app';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                }
                field("Base UM Qty/Pricelist UM Qty"; Rec."Base UM Qty/Pricelist UM Qty")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the quantity of the base unit of measure or the pricelist unit of measure.';
                    ObsoleteReason = 'Preparation for replacement by Subcontracting app';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                }
                field("Pricelist UM Qty/Base UM Qty"; Rec."Pricelist UM Qty/Base UM Qty")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the quantity of the pricelist unit of measure or the base unit of measure.';
                    ObsoleteReason = 'Preparation for replacement by Subcontracting app';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                }
                field("Pricelist Cost"; Rec."Pricelist Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the cost of the pricelist.';
                    ObsoleteReason = 'Preparation for replacement by Subcontracting app';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                }
#endif
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
                action("Calculate &Invoice Discount")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Calculate &Invoice Discount';
                    Image = CalculateInvoiceDiscount;
                    ToolTip = 'Calculate the invoice discount for the document.';

                    trigger OnAction()
                    begin
                        ApproveCalcInvDisc();
                    end;
                }
                action("E&xplode BOM")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'E&xplode BOM';
                    Image = ExplodeBOM;
                    ToolTip = 'View the items that are part of the bill of materials.';

                    trigger OnAction()
                    begin
                        ExplodeBOM();
                    end;
                }
                action("Insert &Ext. Texts")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Insert &Ext. Texts';
                    Image = Text;
                    ToolTip = 'Add external text.';

                    trigger OnAction()
                    begin
                        InsertExtendedText(true);
                    end;
                }
                group("Drop Shipment")
                {
                    Caption = 'Drop Shipment';
                    Image = Delivery;
                    action("Sales &Order")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Sales &Order';
                        Image = Document;
                        ToolTip = 'View the related sales order.';

                        trigger OnAction()
                        begin
                            OpenSalesOrderForm();
                        end;
                    }
                }
                group("Speci&al Order")
                {
                    Caption = 'Speci&al Order';
                    Image = SpecialOrder;
                    action(Action1905579504)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Sales &Order';
                        Image = Document;
                        ToolTip = 'View the related sales order.';

                        trigger OnAction()
                        begin
                            OpenSpecOrderSalesOrderForm();
                        end;
                    }
                }
                action(Reserve)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Reserve';
                    Ellipsis = true;
                    Image = Reserve;
                    ToolTip = 'Mark this as reserved.';

                    trigger OnAction()
                    begin
                        Rec.Find();
                        Rec.ShowReservation();
                    end;
                }
                action("Order &Tracking")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Order &Tracking';
                    Image = OrderTracking;
                    ToolTip = 'View the order tracking.';

                    trigger OnAction()
                    begin
                        ShowTracking();
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
                    action(Period)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Period';
                        Image = Period;
                        ToolTip = 'View the related period.';

                        trigger OnAction()
                        begin
                            PurchAvailabilityMgt.ShowItemAvailabilityFromPurchLine(Rec, "Item Availability Type"::Period);
                        end;
                    }
                    action(Variant)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Variant';
                        Image = ItemVariant;
                        ToolTip = 'View the related variant.';

                        trigger OnAction()
                        begin
                            PurchAvailabilityMgt.ShowItemAvailabilityFromPurchLine(Rec, "Item Availability Type"::Variant);
                        end;
                    }
                    action(Location)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Location';
                        Image = Warehouse;
                        ToolTip = 'View the related location.';

                        trigger OnAction()
                        begin
                            PurchAvailabilityMgt.ShowItemAvailabilityFromPurchLine(Rec, "Item Availability Type"::Location);
                        end;
                    }
                }
                action("Reservation Entries")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Reservation Entries';
                    Image = ReservationLedger;
                    ToolTip = 'View the related reservation entries.';

                    trigger OnAction()
                    begin
                        Rec.ShowReservationEntries(true);
                    end;
                }
                action(Dimensions)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View the related dimensions.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
                action("Item Charge &Assignment")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Item Charge &Assignment';
                    ToolTip = 'View or edit item charge assignment for the document.';

                    trigger OnAction()
                    begin
                        ItemChargeAssgnt();
                    end;
                }
                action("Item Tracking &Lines")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Item Tracking &Lines';
                    Image = ItemTrackingLines;
                    ToolTip = 'View the item tracking lines.';

                    trigger OnAction()
                    begin
                        Rec.OpenItemTrackingLines();
                    end;
                }
                action("Production Order")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Production Order';
                    Image = "Order";
                    ToolTip = 'View the related production order.';

                    trigger OnAction()
                    begin
                        ShowProdOrder();
                    end;
                }
                action("Production &Order Routing")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Production &Order Routing';
                    ToolTip = 'View the related production order routing.';

                    trigger OnAction()
                    begin
                        ShowProdOrdRouting();
                    end;
                }
                action("Production Order &Components")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Production Order &Components';
                    ToolTip = 'View the related production order components.';

                    trigger OnAction()
                    begin
                        ShowProdOrdComponents();
                    end;
                }
                action("Transfer Order Lines")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Transfer Order Lines';
                    ToolTip = 'View the related transfer order lines.';

                    trigger OnAction()
                    begin
                        ShowTransferOrder();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.Type := xRec.Type;
        Clear(ShortcutDimCode);
    end;

    var
        PurchAvailabilityMgt: Codeunit "Purch. Availability Mgt.";
        TransferExtendedText: Codeunit "Transfer Extended Text";
        ShortcutDimCode: array[8] of Code[20];

    [Scope('OnPrem')]
    procedure ApproveCalcInvDisc()
    begin
        CODEUNIT.Run(CODEUNIT::"Purch.-Disc. (Yes/No)", Rec);
    end;

    [Scope('OnPrem')]
    procedure CalcInvDisc()
    begin
        CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", Rec);
    end;

    [Scope('OnPrem')]
    procedure ExplodeBOM()
    begin
        CODEUNIT.Run(CODEUNIT::"Purch.-Explode BOM", Rec);
    end;

    [Scope('OnPrem')]
    procedure OpenSalesOrderForm()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: Page "Sales Order";
    begin
        SalesHeader.SetRange("No.", Rec."Sales Order No.");
        SalesOrder.SetTableView(SalesHeader);
        SalesOrder.Editable := false;
        SalesOrder.Run();
    end;

    [Scope('OnPrem')]
    procedure InsertExtendedText(Unconditionally: Boolean)
    begin
        if TransferExtendedText.PurchCheckIfAnyExtText(Rec, Unconditionally) then begin
            CurrPage.SaveRecord();
            TransferExtendedText.InsertPurchExtText(Rec);
        end;
        if TransferExtendedText.MakeUpdate() then
            UpdateForm(true);
    end;

    [Scope('OnPrem')]
    procedure ShowTracking()
    var
        OrderTracking: Page "Order Tracking";
    begin
        OrderTracking.SetVariantRec(Rec, Rec."No.", Rec."Outstanding Qty. (Base)", Rec."Expected Receipt Date", Rec."Expected Receipt Date");
        OrderTracking.RunModal();
    end;

    [Scope('OnPrem')]
    procedure ItemChargeAssgnt()
    begin
        Rec.ShowItemChargeAssgnt();
    end;

    [Scope('OnPrem')]
    procedure OpenSpecOrderSalesOrderForm()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: Page "Sales Order";
    begin
        SalesHeader.SetRange("No.", Rec."Special Order Sales No.");
        SalesOrder.SetTableView(SalesHeader);
        SalesOrder.Editable := false;
        SalesOrder.Run();
    end;

    [Scope('OnPrem')]
    procedure UpdateForm(SetSaveRecord: Boolean)
    begin
        CurrPage.Update(SetSaveRecord);
    end;

    [Scope('OnPrem')]
    procedure ShowProdOrdComponents()
    var
        ProdOrdComp: Record "Prod. Order Component";
    begin
        ProdOrdComp.SetRange(Status, ProdOrdComp.Status::Released);
        ProdOrdComp.SetRange("Prod. Order No.", Rec."Prod. Order No.");
        ProdOrdComp.SetRange("Prod. Order Line No.", Rec."Prod. Order Line No.");
        PAGE.Run(0, ProdOrdComp);
    end;

    [Scope('OnPrem')]
    procedure ShowProdOrder()
    var
        ProductionOrder: Record "Production Order";
        RelProdOrderForm: Page "Released Production Order";
    begin
        ProductionOrder.SetRange(Status, ProductionOrder.Status::Released);
        ProductionOrder.SetRange("No.", Rec."Prod. Order No.");

        if ProductionOrder.FindFirst() then begin
            RelProdOrderForm.SetTableView(ProductionOrder);
            RelProdOrderForm.Editable := false;
            RelProdOrderForm.Run();
        end;
    end;

    [Scope('OnPrem')]
    procedure ShowProdOrdRouting()
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrdRoutForm: Page "Prod. Order Routing";
    begin
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", Rec."Prod. Order No.");
        ProdOrderRoutingLine.SetRange("Routing Reference No.", Rec."Prod. Order Line No.");
        if ProdOrderRoutingLine.FindFirst() then begin
            ProdOrdRoutForm.SetTableView(ProdOrderRoutingLine);
            ProdOrdRoutForm.Editable := false;
            ProdOrdRoutForm.Run();
        end;
    end;

    [Scope('OnPrem')]
    procedure ShowTransferOrder()
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetRange("Subcontr. Purch. Order No.", Rec."Document No.");
        TransferLine.SetRange("Subcontr. Purch. Order Line", Rec."Line No.");
        TransferLine.SetRange("Derived From Line No.", 0);
        PAGE.Run(0, TransferLine);
    end;

    local procedure NoOnAfterValidate()
    begin
        InsertExtendedText(false);
        if (Rec.Type = Rec.Type::"Charge (Item)") and (Rec."No." <> xRec."No.") and
           (xRec."No." <> '')
        then
            CurrPage.SaveRecord();
    end;
}

