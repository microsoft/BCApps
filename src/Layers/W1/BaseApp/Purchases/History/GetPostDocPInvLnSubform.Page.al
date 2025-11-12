// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Purchases.Document;

page 5857 "Get Post.Doc - P.InvLn Subform"
{
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Purch. Inv. Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Suite;
                    HideValue = DocumentNoHideValue;
                    Lookup = false;
                    StyleExpr = 'Strong';
                    ToolTip = 'Specifies the number of the invoice that this line belongs to.';
                }
#pragma warning disable AA0100
                field("PurchInvHeader.""Posting Date"""; PurchInvHeader."Posting Date")
#pragma warning restore AA0100
                {
                    ApplicationArea = Suite;
                    Caption = 'Posting Date';
                    ToolTip = 'Specifies the posting date of the record.';
                }
                field("Expected Receipt Date"; Rec."Expected Receipt Date")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the date when the items were expected.';
                    Visible = false;
                }
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the vendor who delivered the items.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the line type.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Item Reference No."; Rec."Item Reference No.")
                {
                    AccessByPermission = tabledata "Item Reference" = R;
                    ApplicationArea = Suite, ItemReferences;
                    ToolTip = 'Specifies the referenced item number.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Nonstock; Rec.Nonstock)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that this item is a catalog item.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies either the name of, or a description of, the item or general ledger account.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies information in addition to the description.';
                    Visible = false;
                }
                field("Return Reason Code"; Rec."Return Reason Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the code explaining why the item was returned.';
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code for the location where the invoice line is registered.';
                    Visible = false;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                    Visible = false;
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
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the quantity posted from the line.';
                }
                field(RemainingQty; RemainingQty)
                {
                    ApplicationArea = Suite;
                    Caption = 'Remaining Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity from the posted document line that remains in inventory, meaning that it has not been sold, returned, or consumed.';
                }
                field(AppliedQty; GetAppliedQty())
                {
                    ApplicationArea = Suite;
                    Caption = 'Applied Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many units of the item that have been applied.';
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the name of the item or resource''s unit of measure, such as piece or hour.';
                    Visible = false;
                }
                field("Unit Cost (LCY)"; Rec."Unit Cost (LCY)")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the cost, in LCY, of one unit of the item or resource on the line.';
                    Visible = false;
                }
                field(RevUnitCostLCY; RevUnitCostLCY)
                {
                    ApplicationArea = SalesReturnOrder;
                    AutoFormatType = 2;
                    Caption = 'Reverse Unit Cost (LCY)';
                    ToolTip = 'Specifies the unit cost that will appear on the new document lines.';
                    Visible = false;
                }
                field(DirectUnitCost; DirectUnitCost)
                {
                    ApplicationArea = SalesReturnOrder;
                    AutoFormatExpression = PurchInvHeader."Currency Code";
                    AutoFormatType = 2;
                    Caption = 'Direct Unit Cost';
                    ToolTip = 'Specifies the direct unit cost. ';
                    Visible = false;
                }
                field(LineAmount; LineAmount)
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = PurchInvHeader."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Line Amount';
                    ToolTip = 'Specifies the net amount, excluding any invoice discount amount, that must be paid for products on the line.';
                }
#pragma warning disable AA0100
                field("PurchInvHeader.""Currency Code"""; PurchInvHeader."Currency Code")
#pragma warning restore AA0100
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Currency Code';
                    ToolTip = 'Specifies the code for the currency that amounts are shown in.';
                    Visible = false;
                }
#pragma warning disable AA0100
                field("PurchInvHeader.""Prices Including VAT"""; PurchInvHeader."Prices Including VAT")
#pragma warning restore AA0100
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Prices Including VAT';
                    ToolTip = 'Specifies if the Unit Price and Line Amount fields on document lines should be shown with or without VAT.';
                    Visible = false;
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the discount percentage that is granted for the item on the line.';
                }
                field("Line Discount Amount"; Rec."Line Discount Amount")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the discount amount that is granted for the item on the line.';
                    Visible = false;
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies if the invoice line is included when the invoice discount is calculated.';
                    Visible = false;
                }
                field("Inv. Discount Amount"; Rec."Inv. Discount Amount")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the total calculated invoice discount amount for the line.';
                    Visible = false;
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the number of the related project.';
                    Visible = false;
                }
                field("Blanket Order No."; Rec."Blanket Order No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the number of the blanket order that the record originates from.';
                    Visible = false;
                }
                field("Blanket Order Line No."; Rec."Blanket Order Line No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the number of the blanket order line that the record originates from.';
                    Visible = false;
                }
                field("Appl.-to Item Entry"; Rec."Appl.-to Item Entry")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the number of the item ledger entry that the document or journal line is applied to.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("Show Document")
                {
                    ApplicationArea = Suite;
                    Caption = 'Show Document';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the selected line exists on.';

                    trigger OnAction()
                    begin
                        ShowDocument();
                    end;
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
                action("Item &Tracking Lines")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    ShortCutKey = 'Ctrl+Alt+I';
                    ToolTip = 'View or edit serial, lot and package numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    begin
                        ItemTrackingLines();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DocumentNoHideValue := false;
        DocumentNoOnFormat();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        if not IsVisible then
            exit(false);

        IsHandled := false;
        OnFindRecordOnBeforeFind(Rec, Which, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if Rec.Find(Which) then begin
            PurchInvLine := Rec;
            while true do begin
                ShowRec := IsShowRec(Rec);
                if ShowRec then
                    exit(true);
                if Rec.Next(1) = 0 then begin
                    Rec := PurchInvLine;
                    if Rec.Find(Which) then
                        while true do begin
                            ShowRec := IsShowRec(Rec);
                            if ShowRec then
                                exit(true);
                            if Rec.Next(-1) = 0 then
                                exit(false);
                        end;
                end;
            end;
        end;
        exit(false);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        RealSteps: Integer;
        NextSteps: Integer;
    begin
        if Steps = 0 then
            exit;

        PurchInvLine := Rec;
        repeat
            NextSteps := Rec.Next(Steps / Abs(Steps));
            ShowRec := IsShowRec(Rec);
            if ShowRec then begin
                RealSteps := RealSteps + NextSteps;
                PurchInvLine := Rec;
            end;
        until (NextSteps = 0) or (RealSteps = Steps);
        Rec := PurchInvLine;
        Rec.Find();
        exit(RealSteps);
    end;

    trigger OnOpenPage()
    begin
    end;

    var
        ToPurchHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        TempPurchInvLine: Record "Purch. Inv. Line" temporary;
        RemainingQty: Decimal;
        RevUnitCostLCY: Decimal;
        DirectUnitCost: Decimal;
        LineAmount: Decimal;
        RevQtyFilter: Boolean;
        FillExactCostReverse: Boolean;
        IsVisible: Boolean;
        ShowRec: Boolean;

    protected var
        DocumentNoHideValue: Boolean;

    local procedure IsFirstDocLine(): Boolean
    var
        PurchInvHeader2: Record "Purch. Inv. Header";
        PurchInvLine2: Record "Purch. Inv. Line";
        RemainingQty2: Decimal;
        RevUnitCostLCY2: Decimal;
    begin
        TempPurchInvLine.Reset();
        TempPurchInvLine.CopyFilters(Rec);
        TempPurchInvLine.SetRange("Document No.", Rec."Document No.");
        if not TempPurchInvLine.FindFirst() then begin
            PurchInvHeader2 := PurchInvHeader;
            RemainingQty2 := RemainingQty;
            RevUnitCostLCY2 := RevUnitCostLCY;
            PurchInvLine2.CopyFilters(Rec);
            PurchInvLine2.SetRange("Document No.", Rec."Document No.");
            if not PurchInvLine2.FindSet() then
                exit(false);
            repeat
                ShowRec := IsShowRec(PurchInvLine2);
                if ShowRec then begin
                    TempPurchInvLine := PurchInvLine2;
                    TempPurchInvLine.Insert();
                end;
            until (PurchInvLine2.Next() = 0) or ShowRec;
            PurchInvHeader := PurchInvHeader2;
            RemainingQty := RemainingQty2;
            RevUnitCostLCY := RevUnitCostLCY2;
        end;

        if Rec."Document No." <> PurchInvHeader."No." then
            PurchInvHeader.Get(Rec."Document No.");

        DirectUnitCost := Rec."Direct Unit Cost";
        LineAmount := Rec."Line Amount";

        exit(Rec."Line No." = TempPurchInvLine."Line No.");
    end;

    local procedure IsShowRec(PurchInvLine2: Record "Purch. Inv. Line"): Boolean
    var
        IsHandled: Boolean;
        ReturnValue: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsShowRec(Rec, PurchInvLine2, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        RemainingQty := 0;
        if PurchInvLine2."Document No." <> PurchInvHeader."No." then
            PurchInvHeader.Get(PurchInvLine2."Document No.");
        if PurchInvHeader."Prepayment Invoice" then
            exit(false);
        if RevQtyFilter then begin
            if PurchInvHeader."Currency Code" <> ToPurchHeader."Currency Code" then
                exit(false);
            if PurchInvLine2.Type = PurchInvLine2.Type::" " then
                exit(PurchInvLine2."Attached to Line No." = 0);
        end;
        if PurchInvLine2.Type <> PurchInvLine2.Type::Item then
            exit(true);
        if (PurchInvLine2."Job No." <> '') or PurchInvLine2.IsProdOrder() then
            exit(not RevQtyFilter);
        PurchInvLine2.CalcReceivedPurchNotReturned(RemainingQty, RevUnitCostLCY, FillExactCostReverse);
        if not RevQtyFilter then
            exit(true);
        exit(RemainingQty > 0);
    end;

    procedure Initialize(NewToPurchHeader: Record "Purchase Header"; NewRevQtyFilter: Boolean; NewFillExactCostReverse: Boolean; NewVisible: Boolean)
    begin
        ToPurchHeader := NewToPurchHeader;
        RevQtyFilter := NewRevQtyFilter;
        FillExactCostReverse := NewFillExactCostReverse;
        IsVisible := NewVisible;

        if IsVisible then begin
            TempPurchInvLine.Reset();
            TempPurchInvLine.DeleteAll();
        end;
    end;

    local procedure GetAppliedQty(): Decimal
    begin
        if (Rec.Type = Rec.Type::Item) and (Rec.Quantity - RemainingQty > 0) then
            exit(Rec.Quantity - RemainingQty);
        exit(0);
    end;

    procedure GetSelectedLine(var FromPurchInvLine: Record "Purch. Inv. Line")
    begin
        FromPurchInvLine.Copy(Rec);
        CurrPage.SetSelectionFilter(FromPurchInvLine);
    end;

    local procedure ShowDocument()
    begin
        if not PurchInvHeader.Get(Rec."Document No.") then
            exit;
        PAGE.Run(PAGE::"Posted Purchase Invoice", PurchInvHeader);
    end;

    local procedure ItemTrackingLines()
    var
        FromPurchInvLine: Record "Purch. Inv. Line";
    begin
        GetSelectedLine(FromPurchInvLine);
        FromPurchInvLine.ShowItemTrackingLines();
    end;

    local procedure DocumentNoOnFormat()
    begin
        if not IsFirstDocLine() then
            DocumentNoHideValue := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsShowRec(var PurchInvLine: Record "Purch. Inv. Line"; var PurchInvLine2: Record "Purch. Inv. Line"; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindRecordOnBeforeFind(var PurchInvLine: Record "Purch. Inv. Line"; var Which: Text; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

