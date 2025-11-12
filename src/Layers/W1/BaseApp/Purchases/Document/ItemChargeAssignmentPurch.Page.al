// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.History;
using Microsoft.Sales.History;
using System.Utilities;

page 5805 "Item Charge Assignment (Purch)"
{
    AutoSplitKey = true;
    Caption = 'Item Charge Assignment (Purch)';
    DataCaptionExpression = DataCaption;
    DelayedInsert = true;
    InsertAllowed = false;
    PageType = Worksheet;
    PopulateAllFields = true;
    RefreshOnActivate = true;
    SourceTable = "Item Charge Assignment (Purch)";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Applies-to Doc. Type"; Rec."Applies-to Doc. Type")
                {
                    ApplicationArea = ItemCharges;
                    Editable = false;
                    ToolTip = 'Specifies the type of the document that this document or journal line will be applied to when you post, for example to register payment.';
                }
                field("Applies-to Doc. No."; Rec."Applies-to Doc. No.")
                {
                    ApplicationArea = ItemCharges;
                    Editable = false;
                    ToolTip = 'Specifies the number of the document that this document or journal line will be applied to when you post, for example to register payment.';
                }
                field("Applies-to Doc. Line No."; Rec."Applies-to Doc. Line No.")
                {
                    ApplicationArea = ItemCharges;
                    Editable = false;
                    ToolTip = 'Specifies the number of the line on the document that this document or journal line will be applied to when you post, for example to register payment.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = ItemCharges;
                    Editable = false;
                    StyleExpr = Rec."Qty. to Handle" <> Rec."Qty. to Assign";
                    Style = Unfavorable;
                    ToolTip = 'Specifies the item number on the document line that this item charge is assigned to.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = ItemCharges;
                    StyleExpr = Rec."Qty. to Handle" <> Rec."Qty. to Assign";
                    Style = Unfavorable;
                    ToolTip = 'Specifies a description of the item on the document line that this item charge is assigned to.';
                }
                field("Qty. to Assign"; Rec."Qty. to Assign")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies how many units of the item charge will be assigned to the document line. If the document has more than one line of type Item, then this quantity reflects the distribution that you selected when you chose the Suggest Item Charge Assignment action.';

                    trigger OnValidate()
                    begin
                        if PurchLine2.Quantity * Rec."Qty. to Assign" < 0 then
                            Error(Text000,
                              Rec.FieldCaption("Qty. to Assign"), PurchLine2.FieldCaption(Quantity));
                        QtytoAssignOnAfterValidate();
                    end;
                }
                field("Qty. to Handle"; Rec."Qty. to Handle")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies how many items the item charge will be assigned to on the line. It can be either equal to Qty. to Assign or to zero. If it is zero, the item charge will not be assigned to the line.';
                    trigger OnValidate()
                    begin
                        if PurchLine2.Quantity * Rec."Qty. to Handle" < 0 then
                            Error(Text000,
                                Rec.FieldCaption("Qty. to Handle"), PurchLine2.FieldCaption(Quantity));
                        QtytoAssignOnAfterValidate();
                    end;
                }
                field("Qty. Assigned"; Rec."Qty. Assigned")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies the number of units of the item charge will be assigned to the document line.';
                }
                field("Amount to Assign"; Rec."Amount to Assign")
                {
                    ApplicationArea = ItemCharges;
                    Editable = false;
                    ToolTip = 'Specifies the value of the item charge that is going to be assigned to the document line.';
                }
                field("Amount to Handle"; Rec."Amount to Handle")
                {
                    ApplicationArea = ItemCharges;
                    Editable = false;
                    ToolTip = 'Specifies the value of the item charge that will be actually assigned to the document line.';
                }
                field("<Gross Weight>"; GrossWeight)
                {
                    ApplicationArea = ItemCharges;
                    BlankZero = true;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 4;
                    Editable = false;
                    ToolTip = 'Specifies the initial weight of one unit of the item. The value may be used to complete customs documents and waybills.';
                }
                field("<Unit Volume>"; UnitVolume)
                {
                    ApplicationArea = ItemCharges;
                    BlankZero = true;
                    Caption = 'Unit Volume';
                    DecimalPlaces = 0 : 4;
                    Editable = false;
                    ToolTip = 'Specifies the volume of one unit of the item. The value may be used to complete customs documents and waybills.';
                }
                field(QtyToReceiveBase; QtyToReceiveBase)
                {
                    ApplicationArea = ItemCharges;
                    BlankZero = true;
                    Caption = 'Qty. to Receive (Base)';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the item on the documents line for this item charge assignment have not yet been posted as received.';
                }
                field(QtyReceivedBase; QtyReceivedBase)
                {
                    ApplicationArea = ItemCharges;
                    BlankZero = true;
                    Caption = 'Qty. Received (Base)';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the item on the documents line for this item charge assignment have been posted as received.';
                }
                field(QtyToShipBase; QtyToShipBase)
                {
                    ApplicationArea = ItemCharges;
                    BlankZero = true;
                    Caption = 'Qty. to Ship (Base)';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the item on the documents line for this item charge assignment have not yet been posted as shipped.';
                }
                field(QtyShippedBase; QtyShippedBase)
                {
                    ApplicationArea = ItemCharges;
                    BlankZero = true;
                    Caption = 'Qty. Shipped (Base)';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the item on the documents line for this item charge assignment have been posted as shipped.';
                }
            }
            group(Control22)
            {
                ShowCaption = false;
                fixed(Control1900669001)
                {
                    ShowCaption = false;
                    group(Assignable)
                    {
                        Caption = 'Assignable';
                        field(AssignableQty; AssignableQty)
                        {
                            ApplicationArea = ItemCharges;
                            Caption = 'Total (Qty.)';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the total quantity of the item charge that you can assign to the related document line.';
                        }
                        field(AssgntAmount; AssgntAmount)
                        {
                            ApplicationArea = ItemCharges;
                            Caption = 'Total (Amount)';
                            DecimalPlaces = 2 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the total value of the item charge that you can assign to the related document line.';
                        }
                    }
                    group("To Assign")
                    {
                        Caption = 'To Assign';
                        field(TotalQtyToAssign; TotalQtyToAssign)
                        {
                            ApplicationArea = ItemCharges;
                            Caption = 'Qty. to Assign';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the total quantity of the item charge that you can assign to the related document line.';
                        }
                        field(TotalAmountToAssign; TotalAmountToAssign)
                        {
                            ApplicationArea = ItemCharges;
                            Caption = 'Amount to Assign';
                            DecimalPlaces = 2 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the total value of the item charge that you can assign to the related document line.';
                        }
                    }
                    group("Rem. to Assign")
                    {
                        Caption = 'Rem. to Assign';
                        field(RemQtyToAssign; RemQtyToAssign)
                        {
                            ApplicationArea = ItemCharges;
                            Caption = 'Rem. Qty. to Assign';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            Style = Unfavorable;
                            StyleExpr = RemQtyToAssign <> 0;
                            ToolTip = 'Specifies the quantity of the item charge that has not yet been assigned.';
                        }
                        field(RemAmountToAssign; RemAmountToAssign)
                        {
                            ApplicationArea = ItemCharges;
                            Caption = 'Rem. Amount to Assign';
                            DecimalPlaces = 2 : 5;
                            Editable = false;
                            Style = Unfavorable;
                            StyleExpr = RemAmountToAssign <> 0;
                            ToolTip = 'Specifies the value of the quantity of the item charge that has not yet been assigned.';
                        }
                    }
                    group("To Handle")
                    {
                        Caption = 'To Handle';
                        field(TotalQtyToHandle; TotalQtyToHandle)
                        {
                            ApplicationArea = ItemCharges;
                            Caption = 'Qty. to Handle';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the total quantity of the item charge that you can assign to the related document line.';
                        }
                        field(TotalAmountToHandle; TotalAmountToHandle)
                        {
                            ApplicationArea = ItemCharges;
                            Caption = 'Amount to Handle';
                            DecimalPlaces = 2 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the total value of the item charge that you can assign to the related document line.';
                        }
                    }
                    group("Rem. to Handle")
                    {
                        Caption = 'Rem. to Handle';
                        field(RemQtyToHandle; RemQtyToHandle)
                        {
                            ApplicationArea = ItemCharges;
                            Caption = 'Rem. Qty. to Handle';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            Style = Unfavorable;
                            StyleExpr = RemQtyToHandle <> 0;
                            ToolTip = 'Specifies the quantity of the item charge that you have not yet assigned to items in the assignment lines.';
                        }
                        field(RemAmountToHandle; RemAmountToHandle)
                        {
                            ApplicationArea = ItemCharges;
                            Caption = 'Rem. Amount to Handle';
                            DecimalPlaces = 2 : 5;
                            Editable = false;
                            Style = Unfavorable;
                            StyleExpr = RemAmountToHandle <> 0;
                            ToolTip = 'Specifies the value of the quantity of the item charge that has not yet been assigned.';
                        }
                    }
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
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(GetReceiptLines)
                {
                    AccessByPermission = TableData "Purch. Rcpt. Header" = R;
                    ApplicationArea = ItemCharges;
                    Caption = 'Get &Receipt Lines';
                    Image = Receipt;
                    ToolTip = 'Select a posted purchase receipt for the item that you want to assign the item charge to, for example, if you received an invoice for the item charge after you posted the original purchase receipt.';

                    trigger OnAction()
                    var
                        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
                    begin
                        PurchLine2.TestField("Qty. to Invoice");

                        ItemChargeAssgntPurch.SetRange("Document Type", Rec."Document Type");
                        ItemChargeAssgntPurch.SetRange("Document No.", Rec."Document No.");
                        ItemChargeAssgntPurch.SetRange("Document Line No.", Rec."Document Line No.");
                        OnGetReceiptLinesOnActionOnAfterItemChargeAssgntPurchSetFilters(Rec, PurchRcptLine, PurchLine);

                        OpenPurchReceiptLines(ItemChargeAssgntPurch);
                    end;
                }
                action(GetTransferReceiptLines)
                {
                    AccessByPermission = TableData "Transfer Header" = R;
                    ApplicationArea = Location;
                    Caption = 'Get &Transfer Receipt Lines';
                    Image = TransferReceipt;
                    ToolTip = 'Select a posted transfer receipt for the item that you want to assign the item charge to, for example, if you received an invoice for the item charge after you posted the original transfer receipt.';

                    trigger OnAction()
                    var
                        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
                    begin
                        ItemChargeAssgntPurch.SetRange("Document Type", Rec."Document Type");
                        ItemChargeAssgntPurch.SetRange("Document No.", Rec."Document No.");
                        ItemChargeAssgntPurch.SetRange("Document Line No.", Rec."Document Line No.");

                        TransferRcptLine.FilterGroup(2);
                        TransferRcptLine.SetFilter("Item No.", '<>%1', '');
                        TransferRcptLine.SetFilter(Quantity, '<>0');
                        TransferRcptLine.FilterGroup(0);
                        OnGetTransferReceiptLinesOnActionOnAfterItemChargeAssgntPurchSetFilters(Rec, TransferRcptLine, PurchLine);

                        OpenPostedTransferReceiptLines(ItemChargeAssgntPurch);
                    end;
                }
                action(GetReturnShipmentLines)
                {
                    AccessByPermission = TableData "Return Shipment Header" = R;
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Get Return &Shipment Lines';
                    Image = ReturnShipment;
                    ToolTip = 'Select a posted return shipment for the item that you want to assign the item charge to, for example, if you received an invoice for the item charge after you posted the original return shipment.';

                    trigger OnAction()
                    var
                        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
                    begin
                        ItemChargeAssgntPurch.SetRange("Document Type", Rec."Document Type");
                        ItemChargeAssgntPurch.SetRange("Document No.", Rec."Document No.");
                        ItemChargeAssgntPurch.SetRange("Document Line No.", Rec."Document Line No.");
                        OnGetReturnShipmentLinesOnActionOnAfterItemChargeAssgntPurchSetFilters(Rec, ReturnShptLine, PurchLine);

                        OpenReturnShipmentLines(ItemChargeAssgntPurch);
                    end;
                }
                action(GetSalesShipmentLines)
                {
                    AccessByPermission = TableData "Sales Shipment Header" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Get S&ales Shipment Lines';
                    Image = SalesShipment;
                    ToolTip = 'Select a posted sales shipment for the item that you want to assign the item charge to, for example, if you received an invoice for the item charge after you posted the original sales shipment.';

                    trigger OnAction()
                    var
                        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
                    begin
                        ItemChargeAssgntPurch.SetRange("Document Type", Rec."Document Type");
                        ItemChargeAssgntPurch.SetRange("Document No.", Rec."Document No.");
                        ItemChargeAssgntPurch.SetRange("Document Line No.", Rec."Document Line No.");
                        OnGetSalesShipmentLinesOnActionOnAfterItemChargeAssgntPurchSetFilters(Rec, SalesShptLine, PurchLine);

                        OpenSalesShipmentLines(ItemChargeAssgntPurch);
                    end;
                }
                action(GetReturnReceiptLines)
                {
                    AccessByPermission = TableData "Return Receipt Header" = R;
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Get Ret&urn Receipt Lines';
                    Image = ReturnReceipt;
                    ToolTip = 'Select a posted return receipt for the item that you want to assign the item charge to, for example, if you received an invoice for the item charge after you posted the original return receipt.';

                    trigger OnAction()
                    var
                        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
                    begin
                        ItemChargeAssgntPurch.SetRange("Document Type", Rec."Document Type");
                        ItemChargeAssgntPurch.SetRange("Document No.", Rec."Document No.");
                        ItemChargeAssgntPurch.SetRange("Document Line No.", Rec."Document Line No.");
                        OnGetReturnReceiptLinesOnActionOnAfterItemChargeAssgntPurchSetFilters(Rec, ReturnRcptLine, PurchLine);

                        OpenReturnReceiptLines(ItemChargeAssgntPurch);
                    end;
                }
                action(SuggestItemChargeAssignment)
                {
                    AccessByPermission = TableData "Item Charge" = R;
                    ApplicationArea = ItemCharges;
                    Caption = 'Suggest &Item Charge Assignment';
                    Ellipsis = true;
                    Image = Suggest;
                    ToolTip = 'Use a function that assigns and distributes the item charge when the document has more than one line of type Item. You can select between four distribution methods. ';

                    trigger OnAction()
                    var
                        AssignItemChargePurch: Codeunit "Item Charge Assgnt. (Purch.)";
                    begin
                        AssignItemChargePurch.SuggestAssgnt(PurchLine2, AssignableQty, AssgntAmount, AssignableQty, AssgntAmount);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(SuggestItemChargeAssignment_Promoted; SuggestItemChargeAssignment)
                {
                }
                actionref(GetReceiptLines_Promoted; GetReceiptLines)
                {
                }
                actionref(GetSalesShipmentLines_Promoted; GetSalesShipmentLines)
                {
                }
                actionref(GetTransferReceiptLines_Promoted; GetTransferReceiptLines)
                {
                }
                actionref(GetReturnReceiptLines_Promoted; GetReturnReceiptLines)
                {
                }
                actionref(GetReturnShipmentLines_Promoted; GetReturnShipmentLines)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Item Charge', Comment = 'Generated from the PromotedActionCategories property index 3.';

            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateQtyAssgnt();
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateQty();
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        if Rec."Document Type" = Rec."Applies-to Doc. Type" then begin
            PurchLine2.TestField("Receipt No.", '');
            PurchLine2.TestField("Return Shipment No.", '');
        end;
    end;

    trigger OnOpenPage()
    begin
        Rec.FilterGroup(2);
        Rec.SetRange("Document Type", PurchLine2."Document Type");
        Rec.SetRange("Document No.", PurchLine2."Document No.");
        Rec.SetRange("Document Line No.", PurchLine2."Line No.");
        Rec.SetRange("Item Charge No.", PurchLine2."No.");
        Rec.FilterGroup(0);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if RemAmountToAssign <> 0 then
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(Text001, RemAmountToAssign, Rec."Document Type", Rec."Document No."), true)
            then
                exit(false);
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'The sign of %1 must be the same as the sign of %2 of the item charge.';
        Text001: Label 'The remaining amount to assign is %1. It must be zero before you can post %2 %3.\ \Are you sure that you want to close the window?', Comment = '%2 = Document Type, %3 = Document No.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
        PurchLine: Record "Purchase Line";
        PurchLine2: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReturnShptLine: Record "Return Shipment Line";
        TransferRcptLine: Record "Transfer Receipt Line";
        SalesShptLine: Record "Sales Shipment Line";
        ReturnRcptLine: Record "Return Receipt Line";
        DataCaption: Text[250];
        QtyToReceiveBase: Decimal;
        QtyReceivedBase: Decimal;
        QtyToShipBase: Decimal;
        QtyShippedBase: Decimal;
        AssignableQty: Decimal;
        TotalQtyToAssign: Decimal;
        TotalQtyToHandle: Decimal;
        RemQtyToAssign: Decimal;
        RemQtyToHandle: Decimal;
        AssgntAmount: Decimal;
        TotalAmountToAssign: Decimal;
        TotalAmountToHandle: Decimal;
        RemAmountToAssign: Decimal;
        RemAmountToHandle: Decimal;
        GrossWeight: Decimal;
        UnitVolume: Decimal;

    local procedure UpdateQtyAssgnt()
    var
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        PurchLine2.CalcFields("Qty. to Assign", "Item Charge Qty. to Handle", "Qty. Assigned");
        AssignableQty :=
          PurchLine2."Qty. to Invoice" + PurchLine2."Quantity Invoiced" - PurchLine2."Qty. Assigned";

        ItemChargeAssgntPurch.Reset();
        ItemChargeAssgntPurch.SetCurrentKey("Document Type", "Document No.", "Document Line No.");
        ItemChargeAssgntPurch.SetRange("Document Type", Rec."Document Type");
        ItemChargeAssgntPurch.SetRange("Document No.", Rec."Document No.");
        ItemChargeAssgntPurch.SetRange("Document Line No.", Rec."Document Line No.");
        ItemChargeAssgntPurch.CalcSums("Qty. to Assign", "Amount to Assign", "Qty. to Handle", "Amount to Handle");
        TotalQtyToAssign := ItemChargeAssgntPurch."Qty. to Assign";
        TotalAmountToAssign := ItemChargeAssgntPurch."Amount to Assign";
        TotalQtyToHandle := ItemChargeAssgntPurch."Qty. to Handle";
        TotalAmountToHandle := ItemChargeAssgntPurch."Amount to Handle";

        RemQtyToAssign := AssignableQty - TotalQtyToAssign;
        RemAmountToAssign := AssgntAmount - TotalAmountToAssign;
        RemQtyToHandle := AssignableQty - TotalQtyToHandle;
        RemAmountToHandle := AssgntAmount - TotalAmountToHandle;
    end;

    local procedure UpdateQty()
    begin
        case Rec."Applies-to Doc. Type" of
            Rec."Applies-to Doc. Type"::Quote,
            Rec."Applies-to Doc. Type"::Order,
            Rec."Applies-to Doc. Type"::Invoice:
                begin
                    PurchLine.Get(Rec."Applies-to Doc. Type", Rec."Applies-to Doc. No.", Rec."Applies-to Doc. Line No.");
                    QtyToReceiveBase := PurchLine."Qty. to Receive (Base)";
                    QtyReceivedBase := PurchLine."Qty. Received (Base)";
                    QtyToShipBase := 0;
                    QtyShippedBase := 0;
                    GrossWeight := PurchLine."Gross Weight";
                    UnitVolume := PurchLine."Unit Volume";
                end;
            Rec."Applies-to Doc. Type"::"Return Order", Rec."Applies-to Doc. Type"::"Credit Memo":
                begin
                    PurchLine.Get(Rec."Applies-to Doc. Type", Rec."Applies-to Doc. No.", Rec."Applies-to Doc. Line No.");
                    QtyToReceiveBase := 0;
                    QtyReceivedBase := 0;
                    QtyToShipBase := PurchLine."Return Qty. to Ship (Base)";
                    QtyShippedBase := PurchLine."Return Qty. Shipped (Base)";
                    GrossWeight := PurchLine."Gross Weight";
                    UnitVolume := PurchLine."Unit Volume";
                end;
            Rec."Applies-to Doc. Type"::Receipt:
                begin
                    PurchRcptLine.Get(Rec."Applies-to Doc. No.", Rec."Applies-to Doc. Line No.");
                    QtyToReceiveBase := 0;
                    QtyReceivedBase := PurchRcptLine."Quantity (Base)";
                    QtyToShipBase := 0;
                    QtyShippedBase := 0;
                    GrossWeight := PurchRcptLine."Gross Weight";
                    UnitVolume := PurchRcptLine."Unit Volume";
                end;
            Rec."Applies-to Doc. Type"::"Return Shipment":
                begin
                    ReturnShptLine.Get(Rec."Applies-to Doc. No.", Rec."Applies-to Doc. Line No.");
                    QtyToReceiveBase := 0;
                    QtyReceivedBase := 0;
                    QtyToShipBase := 0;
                    QtyShippedBase := ReturnShptLine."Quantity (Base)";
                    GrossWeight := ReturnShptLine."Gross Weight";
                    UnitVolume := ReturnShptLine."Unit Volume";
                end;
            Rec."Applies-to Doc. Type"::"Transfer Receipt":
                begin
                    TransferRcptLine.Get(Rec."Applies-to Doc. No.", Rec."Applies-to Doc. Line No.");
                    QtyToReceiveBase := 0;
                    QtyReceivedBase := TransferRcptLine.Quantity;
                    QtyToShipBase := 0;
                    QtyShippedBase := 0;
                    GrossWeight := TransferRcptLine."Gross Weight";
                    UnitVolume := TransferRcptLine."Unit Volume";
                end;
            Rec."Applies-to Doc. Type"::"Sales Shipment":
                begin
                    SalesShptLine.Get(Rec."Applies-to Doc. No.", Rec."Applies-to Doc. Line No.");
                    QtyToReceiveBase := 0;
                    QtyReceivedBase := 0;
                    QtyToShipBase := 0;
                    QtyShippedBase := SalesShptLine."Quantity (Base)";
                    GrossWeight := SalesShptLine."Gross Weight";
                    UnitVolume := SalesShptLine."Unit Volume";
                end;
            Rec."Applies-to Doc. Type"::"Return Receipt":
                begin
                    ReturnRcptLine.Get(Rec."Applies-to Doc. No.", Rec."Applies-to Doc. Line No.");
                    QtyToReceiveBase := 0;
                    QtyReceivedBase := ReturnRcptLine."Quantity (Base)";
                    QtyToShipBase := 0;
                    QtyShippedBase := 0;
                    GrossWeight := ReturnRcptLine."Gross Weight";
                    UnitVolume := ReturnRcptLine."Unit Volume";
                end;
        end;

        OnAfterUpdateQty(Rec, QtyToReceiveBase, QtyReceivedBase, QtyToShipBase, QtyShippedBase, GrossWeight, UnitVolume);
    end;

    procedure Initialize(NewPurchLine: Record "Purchase Line"; NewLineAmt: Decimal)
    begin
        PurchLine2 := NewPurchLine;
        DataCaption := PurchLine2."No." + ' ' + PurchLine2.Description;
        AssgntAmount := NewLineAmt;
        OnAfterInitialize(PurchLine2, AssgntAmount);
    end;

    local procedure QtytoAssignOnAfterValidate()
    begin
        CurrPage.SaveRecord();
        UpdateQtyAssgnt();
        CurrPage.Update(false);
    end;

    local procedure OpenPurchReceiptLines(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)")
    var
        PurchReceiptLines: Page "Purch. Receipt Lines";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenPurchReceiptLines(Rec, ItemChargeAssignmentPurch, IsHandled);
        if IsHandled then
            exit;

        PurchReceiptLines.SetTableView(PurchRcptLine);
        if ItemChargeAssignmentPurch.FindLast() then
            PurchReceiptLines.Initialize(ItemChargeAssignmentPurch, PurchLine2."Unit Cost")
        else
            PurchReceiptLines.Initialize(Rec, PurchLine2."Unit Cost");
        PurchReceiptLines.LookupMode(true);
        PurchReceiptLines.RunModal();
    end;

    local procedure OpenPostedTransferReceiptLines(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)")
    var
        PostedTransferReceiptLines: Page "Posted Transfer Receipt Lines";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenPostedTransferReceiptLines(Rec, ItemChargeAssignmentPurch, IsHandled);
        if IsHandled then
            exit;

        PostedTransferReceiptLines.SetTableView(TransferRcptLine);
        if ItemChargeAssignmentPurch.FindLast() then
            PostedTransferReceiptLines.Initialize(ItemChargeAssignmentPurch, PurchLine2."Unit Cost")
        else
            PostedTransferReceiptLines.Initialize(Rec, PurchLine2."Unit Cost");

        PostedTransferReceiptLines.LookupMode(true);
        PostedTransferReceiptLines.RunModal();
    end;

    local procedure OpenReturnShipmentLines(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)")
    var
        ReturnShipmentLines: Page "Return Shipment Lines";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenReturnShipmentLines(Rec, ItemChargeAssignmentPurch, IsHandled);
        if IsHandled then
            exit;

        ReturnShipmentLines.SetTableView(ReturnShptLine);
        if ItemChargeAssignmentPurch.FindLast() then
            ReturnShipmentLines.Initialize(ItemChargeAssignmentPurch, PurchLine2."Unit Cost")
        else
            ReturnShipmentLines.Initialize(Rec, PurchLine2."Unit Cost");

        ReturnShipmentLines.LookupMode(true);
        ReturnShipmentLines.RunModal();
    end;

    local procedure OpenSalesShipmentLines(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)")
    var
        SalesShipmentLines: Page "Sales Shipment Lines";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenSalesShipmentLines(Rec, ItemChargeAssignmentPurch, IsHandled);
        if IsHandled then
            exit;

        SalesShipmentLines.SetTableView(SalesShptLine);
        if ItemChargeAssignmentPurch.FindLast() then
            SalesShipmentLines.InitializePurchase(ItemChargeAssignmentPurch, PurchLine2."Unit Cost")
        else
            SalesShipmentLines.InitializePurchase(Rec, PurchLine2."Unit Cost");

        SalesShipmentLines.LookupMode(true);
        SalesShipmentLines.RunModal();
    end;

    local procedure OpenReturnReceiptLines(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)")
    var
        ReturnReceiptLines: Page "Return Receipt Lines";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenReturnReceiptLines(Rec, ItemChargeAssignmentPurch, IsHandled);
        if IsHandled then
            exit;

        ReturnReceiptLines.SetTableView(ReturnRcptLine);
        if ItemChargeAssignmentPurch.FindLast() then
            ReturnReceiptLines.InitializePurchase(ItemChargeAssignmentPurch, PurchLine2."Unit Cost")
        else
            ReturnReceiptLines.InitializePurchase(Rec, PurchLine2."Unit Cost");

        ReturnReceiptLines.LookupMode(true);
        ReturnReceiptLines.RunModal();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitialize(var PurchaseLine: Record "Purchase Line"; var AssgntAmount: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateQty(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; var QtyToReceiveBase: Decimal; var QtyReceivedBase: Decimal; var QtyToShipBase: Decimal; var QtyShippedBase: Decimal; var GrossWeight: Decimal; var UnitVolume: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReceiptLinesOnActionOnAfterItemChargeAssgntPurchSetFilters(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; var PurchReceiptLines: Record "Purch. Rcpt. Line"; PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReturnReceiptLinesOnActionOnAfterItemChargeAssgntPurchSetFilters(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; var ReturnRcptLine: Record "Return Receipt Line"; PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReturnShipmentLinesOnActionOnAfterItemChargeAssgntPurchSetFilters(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; var ReturnShptLine: Record "Return Shipment Line"; PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSalesShipmentLinesOnActionOnAfterItemChargeAssgntPurchSetFilters(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; var SalesShptLine: Record "Sales Shipment Line"; PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetTransferReceiptLinesOnActionOnAfterItemChargeAssgntPurchSetFilters(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; var TransferRcptLine: Record "Transfer Receipt Line"; PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenPurchReceiptLines(var RecItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenReturnReceiptLines(var RecItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenReturnShipmentLines(var RecItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenPostedTransferReceiptLines(var RecItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenSalesShipmentLines(var RecItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; var IsHandled: Boolean)
    begin
    end;
}

