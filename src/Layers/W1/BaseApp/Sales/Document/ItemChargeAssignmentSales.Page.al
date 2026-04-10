// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Inventory.Item;
using Microsoft.Sales.History;

/// <summary>
/// Displays and manages the allocation of item charges across sales shipment and return receipt lines.
/// </summary>
page 5814 "Item Charge Assignment (Sales)"
{
    AutoSplitKey = true;
    Caption = 'Item Charge Assignment (Sales)';
    DataCaptionExpression = DataCaption;
    DelayedInsert = true;
    InsertAllowed = false;
    PageType = Worksheet;
    PopulateAllFields = true;
    RefreshOnActivate = true;
    SourceTable = "Item Charge Assignment (Sales)";

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
                }
                field("Applies-to Doc. No."; Rec."Applies-to Doc. No.")
                {
                    ApplicationArea = ItemCharges;
                    Editable = false;
                }
                field("Applies-to Doc. Line No."; Rec."Applies-to Doc. Line No.")
                {
                    ApplicationArea = ItemCharges;
                    Editable = false;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = ItemCharges;
                    Editable = false;
                    StyleExpr = Rec."Qty. to Handle" <> Rec."Qty. to Assign";
                    Style = Unfavorable;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = ItemCharges;
                    StyleExpr = Rec."Qty. to Handle" <> Rec."Qty. to Assign";
                    Style = Unfavorable;
                }
                field("Qty. to Assign"; Rec."Qty. to Assign")
                {
                    ApplicationArea = ItemCharges;

                    trigger OnValidate()
                    begin
                        if SalesLine2.Quantity * Rec."Qty. to Assign" < 0 then
                            Error(Text000,
                              Rec.FieldCaption("Qty. to Assign"), SalesLine2.FieldCaption(Quantity));
                        QtytoAssignOnAfterValidate();
                    end;
                }
                field("Qty. to Handle"; Rec."Qty. to Handle")
                {
                    ApplicationArea = ItemCharges;

                    trigger OnValidate()
                    begin
                        if SalesLine2.Quantity * Rec."Qty. to Handle" < 0 then
                            Error(Text000,
                                Rec.FieldCaption("Qty. to Handle"), SalesLine2.FieldCaption(Quantity));
                        QtytoAssignOnAfterValidate();
                    end;
                }
                field("Qty. Assigned"; Rec."Qty. Assigned")
                {
                    ApplicationArea = ItemCharges;
                }
                field("Amount to Assign"; Rec."Amount to Assign")
                {
                    ApplicationArea = ItemCharges;
                    Editable = false;
                }
                field("Amount to Handle"; Rec."Amount to Handle")
                {
                    ApplicationArea = ItemCharges;
                    Editable = false;
                }
                field(GrossWeight; GrossWeight)
                {
                    ApplicationArea = ItemCharges;
                    AutoFormatType = 0;
                    BlankZero = true;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 4;
                    Editable = false;
                    ToolTip = 'Specifies the initial weight of one unit of the item. The value may be used to complete customs documents and waybills.';
                }
                field(UnitVolume; UnitVolume)
                {
                    ApplicationArea = ItemCharges;
                    AutoFormatType = 0;
                    BlankZero = true;
                    Caption = 'Unit Volume';
                    DecimalPlaces = 0 : 4;
                    Editable = false;
                    ToolTip = 'Specifies the volume of one unit of the item. The value may be used to complete customs documents and waybills.';
                }
                field(QtyToShipBase; QtyToShipBase)
                {
                    ApplicationArea = ItemCharges;
                    AutoFormatType = 0;
                    BlankZero = true;
                    Caption = 'Qty. to Ship (Base)';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the item on the documents line for this item charge assignment have not yet been posted as shipped.';
                }
                field(QtyShippedBase; QtyShippedBase)
                {
                    ApplicationArea = ItemCharges;
                    AutoFormatType = 0;
                    BlankZero = true;
                    Caption = 'Qty. Shipped (Base)';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the item on the documents line for this item charge assignment have been posted as shipped.';
                }
                field(QtyToRetReceiveBase; QtyToRetReceiveBase)
                {
                    ApplicationArea = ItemCharges;
                    AutoFormatType = 0;
                    BlankZero = true;
                    Caption = 'Return Qty. to Receive (Base)';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies a value if the sales line on this assignment line Specifies units that have not been posted as a received return from your customer.';
                }
                field(QtyRetReceivedBase; QtyRetReceivedBase)
                {
                    ApplicationArea = ItemCharges;
                    AutoFormatType = 0;
                    BlankZero = true;
                    Caption = 'Return Qty. Received (Base)';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the number of returned units that have been posted as received on the sales line on this assignment line.';
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
                            AutoFormatType = 0;
                            Caption = 'Total (Qty.)';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the total quantity of the item charge that you can assign to the related document line.';
                        }
                        field(AssignableAmount; AssignableAmount)
                        {
                            ApplicationArea = ItemCharges;
                            AutoFormatType = 0;
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
                            AutoFormatType = 0;
                            Caption = 'Qty. to Assign';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the total quantity of the item charge that you can assign to the related document line.';
                        }
                        field(TotalAmountToAssign; TotalAmountToAssign)
                        {
                            ApplicationArea = ItemCharges;
                            AutoFormatType = 1;
                            AutoFormatExpression = '';
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
                            AutoFormatType = 0;
                            Caption = 'Rem. Qty. to Assign';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            Style = Unfavorable;
                            StyleExpr = RemQtyToAssign <> 0;
                            ToolTip = 'Specifies the quantity of the item charge that you have not yet assigned to items in the assignment lines.';
                        }
                        field(RemAmountToAssign; RemAmountToAssign)
                        {
                            ApplicationArea = ItemCharges;
                            AutoFormatType = 1;
                            AutoFormatExpression = '';
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
                            AutoFormatType = 0;
                            Caption = 'Qty. to Handle';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the total quantity of the item charge that you can assign to the related document line.';
                        }
                        field(TotalAmountToHandle; TotalAmountToHandle)
                        {
                            ApplicationArea = ItemCharges;
                            AutoFormatType = 1;
                            AutoFormatExpression = '';
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
                            AutoFormatType = 0;
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
                            AutoFormatType = 1;
                            AutoFormatExpression = '';
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
                action(GetShipmentLines)
                {
                    AccessByPermission = TableData "Sales Shipment Header" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Get &Shipment Lines';
                    Image = Shipment;
                    ToolTip = 'Select multiple shipments to the same customer because you want to combine them on one invoice.';

                    trigger OnAction()
                    var
                        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
                        ShipmentLines: Page "Sales Shipment Lines";
                    begin
                        SalesLine2.TestField("Qty. to Invoice");

                        ItemChargeAssgntSales.SetRange("Document Type", Rec."Document Type");
                        ItemChargeAssgntSales.SetRange("Document No.", Rec."Document No.");
                        ItemChargeAssgntSales.SetRange("Document Line No.", Rec."Document Line No.");

                        ShipmentLines.SetTableView(SalesShptLine);
                        if ItemChargeAssgntSales.FindLast() then
                            ShipmentLines.InitializeSales(ItemChargeAssgntSales, SalesLine2."Sell-to Customer No.", UnitCost)
                        else
                            ShipmentLines.InitializeSales(Rec, SalesLine2."Sell-to Customer No.", UnitCost);

                        ShipmentLines.LookupMode(true);
                        ShipmentLines.RunModal();
                    end;
                }
                action(GetReturnReceiptLines)
                {
                    AccessByPermission = TableData "Return Receipt Header" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Get &Return Receipt Lines';
                    Image = ReturnReceipt;
                    ToolTip = 'Select a posted purchase return receipt for the item that you want to assign the item charge to, for example, if you received an invoice for the item charge after you posted the original purchase return.';

                    trigger OnAction()
                    var
                        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
                        ReceiptLines: Page "Return Receipt Lines";
                    begin
                        ItemChargeAssgntSales.SetRange("Document Type", Rec."Document Type");
                        ItemChargeAssgntSales.SetRange("Document No.", Rec."Document No.");
                        ItemChargeAssgntSales.SetRange("Document Line No.", Rec."Document Line No.");

                        ReceiptLines.SetTableView(ReturnRcptLine);
                        if ItemChargeAssgntSales.FindLast() then
                            ReceiptLines.InitializeSales(ItemChargeAssgntSales, SalesLine2."Sell-to Customer No.", UnitCost)
                        else
                            ReceiptLines.InitializeSales(Rec, SalesLine2."Sell-to Customer No.", UnitCost);

                        ReceiptLines.LookupMode(true);
                        ReceiptLines.RunModal();
                    end;
                }
                action(SuggestItemChargeAssignment)
                {
                    AccessByPermission = TableData "Item Charge" = R;
                    ApplicationArea = ItemCharges;
                    Caption = 'Suggest Item &Charge Assignment';
                    Image = Suggest;
                    ToolTip = 'Use a function that assigns and distributes the item charge when the document has more than one line of type Item. You can select between four distribution methods. ';

                    trigger OnAction()
                    var
                        AssignItemChargeSales: Codeunit "Item Charge Assgnt. (Sales)";
                    begin
                        AssignItemChargeSales.SuggestAssignment(SalesLine2, AssignableQty, AssignableAmount, AssignableQty, AssignableAmount);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Item Charge', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(GetShipmentLines_Promoted; GetShipmentLines)
                {
                }
                actionref(SuggestItemChargeAssignment_Promoted; SuggestItemChargeAssignment)
                {
                }
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
            SalesLine2.TestField("Shipment No.", '');
            SalesLine2.TestField("Return Receipt No.", '');
        end;
    end;

    trigger OnOpenPage()
    begin
        Rec.FilterGroup(2);
        Rec.SetRange("Document Type", SalesLine2."Document Type");
        Rec.SetRange("Document No.", SalesLine2."Document No.");
        Rec.SetRange("Document Line No.", SalesLine2."Line No.");
        Rec.SetRange("Item Charge No.", SalesLine2."No.");
        Rec.FilterGroup(0);
    end;

    var
        SalesLine: Record "Sales Line";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'The sign of %1 must be the same as the sign of %2 of the item charge.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
        SalesLine2: Record "Sales Line";
        ReturnRcptLine: Record "Return Receipt Line";
        SalesShptLine: Record "Sales Shipment Line";
        DataCaption: Text[250];
        QtyToRetReceiveBase: Decimal;
        QtyRetReceivedBase: Decimal;
        QtyToShipBase: Decimal;
        QtyShippedBase: Decimal;
        UnitCost: Decimal;
        AssignableQty: Decimal;
        TotalQtyToAssign: Decimal;
        RemQtyToAssign: Decimal;
        AssignableAmount: Decimal;
        TotalAmountToAssign: Decimal;
        RemAmountToAssign: Decimal;
        TotalQtyToHandle: Decimal;
        RemQtyToHandle: Decimal;
        TotalAmountToHandle: Decimal;
        RemAmountToHandle: Decimal;
        GrossWeight: Decimal;
        UnitVolume: Decimal;

    local procedure UpdateQtyAssgnt()
    var
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
    begin
        SalesLine2.CalcFields("Qty. to Assign", "Item Charge Qty. to Handle", "Qty. Assigned");
        AssignableQty := SalesLine2."Qty. to Invoice" + SalesLine2."Quantity Invoiced" - SalesLine2."Qty. Assigned";
        OnUpdateQtyAssgntOnAfterAssignableQty(SalesLine2, AssignableQty);

        if AssignableQty <> 0 then
            UnitCost := AssignableAmount / AssignableQty
        else
            UnitCost := 0;

        ItemChargeAssgntSales.Reset();
        ItemChargeAssgntSales.SetCurrentKey("Document Type", "Document No.", "Document Line No.");
        ItemChargeAssgntSales.SetRange("Document Type", Rec."Document Type");
        ItemChargeAssgntSales.SetRange("Document No.", Rec."Document No.");
        ItemChargeAssgntSales.SetRange("Document Line No.", Rec."Document Line No.");
        ItemChargeAssgntSales.CalcSums("Qty. to Assign", "Amount to Assign", "Qty. to Handle", "Amount to Handle");
        TotalQtyToAssign := ItemChargeAssgntSales."Qty. to Assign";
        TotalAmountToAssign := ItemChargeAssgntSales."Amount to Assign";
        TotalQtyToHandle := ItemChargeAssgntSales."Qty. to Handle";
        TotalAmountToHandle := ItemChargeAssgntSales."Amount to Handle";

        RemQtyToAssign := AssignableQty - TotalQtyToAssign;
        RemAmountToAssign := AssignableAmount - TotalAmountToAssign;
        RemQtyToHandle := AssignableQty - TotalQtyToHandle;
        RemAmountToHandle := AssignableAmount - TotalAmountToHandle;
    end;

    local procedure UpdateQty()
    begin
        case Rec."Applies-to Doc. Type" of
            "Sales Applies-to Document Type"::Quote, "Sales Applies-to Document Type"::Order, "Sales Applies-to Document Type"::Invoice:
                begin
                    SalesLine.Get(Rec."Applies-to Doc. Type", Rec."Applies-to Doc. No.", Rec."Applies-to Doc. Line No.");
                    QtyToShipBase := SalesLine."Qty. to Ship (Base)";
                    QtyShippedBase := SalesLine."Qty. Shipped (Base)";
                    QtyToRetReceiveBase := 0;
                    QtyRetReceivedBase := 0;
                    GrossWeight := SalesLine."Gross Weight";
                    UnitVolume := SalesLine."Unit Volume";
                end;
            "Sales Applies-to Document Type"::"Return Order", "Sales Applies-to Document Type"::"Credit Memo":
                begin
                    SalesLine.Get(Rec."Applies-to Doc. Type", Rec."Applies-to Doc. No.", Rec."Applies-to Doc. Line No.");
                    QtyToRetReceiveBase := SalesLine."Return Qty. to Receive (Base)";
                    QtyRetReceivedBase := SalesLine."Return Qty. Received (Base)";
                    QtyToShipBase := 0;
                    QtyShippedBase := 0;
                    GrossWeight := SalesLine."Gross Weight";
                    UnitVolume := SalesLine."Unit Volume";
                end;
            "Sales Applies-to Document Type"::"Return Receipt":
                begin
                    ReturnRcptLine.Get(Rec."Applies-to Doc. No.", Rec."Applies-to Doc. Line No.");
                    QtyToRetReceiveBase := 0;
                    QtyRetReceivedBase := ReturnRcptLine."Quantity (Base)";
                    QtyToShipBase := 0;
                    QtyShippedBase := 0;
                    GrossWeight := ReturnRcptLine."Gross Weight";
                    UnitVolume := ReturnRcptLine."Unit Volume";
                end;
            "Sales Applies-to Document Type"::Shipment:
                begin
                    SalesShptLine.Get(Rec."Applies-to Doc. No.", Rec."Applies-to Doc. Line No.");
                    QtyToRetReceiveBase := 0;
                    QtyRetReceivedBase := 0;
                    QtyToShipBase := 0;
                    QtyShippedBase := SalesShptLine."Quantity (Base)";
                    GrossWeight := SalesShptLine."Gross Weight";
                    UnitVolume := SalesShptLine."Unit Volume";
                end;
        end;

        OnAfterUpdateQty(Rec, QtyToShipBase, QtyShippedBase, QtyToRetReceiveBase, QtyRetReceivedBase, GrossWeight, UnitVolume);
    end;

    /// <summary>
    /// Initializes the page with the sales line and assignable amount.
    /// </summary>
    /// <param name="NewSalesLine">The sales line with the item charge.</param>
    /// <param name="NewLineAmt">The line amount available for assignment.</param>
    procedure Initialize(NewSalesLine: Record "Sales Line"; NewLineAmt: Decimal)
    begin
        SalesLine2 := NewSalesLine;
        DataCaption := SalesLine2."No." + ' ' + SalesLine2.Description;
        AssignableAmount := NewLineAmt;
    end;

    local procedure QtytoAssignOnAfterValidate()
    begin
        CurrPage.SaveRecord();
        UpdateQtyAssgnt();
        CurrPage.Update(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateQty(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; var QtyToShipBase: Decimal; var QtyShippedBase: Decimal; var QtyToRetReceiveBase: Decimal; var QtyRetReceivedBase: Decimal; var GrossWeight: Decimal; var UnitVolume: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateQtyAssgntOnAfterAssignableQty(var SalesLine: Record "Sales Line"; var AssignableQty: Decimal)
    begin
    end;
}

