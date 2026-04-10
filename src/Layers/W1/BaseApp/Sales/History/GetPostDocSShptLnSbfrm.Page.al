// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Utilities;

/// <summary>
/// Displays posted sales shipment lines as a subform for line selection during document retrieval.
/// </summary>
page 5851 "Get Post.Doc - S.ShptLn Sbfrm"
{
    Caption = 'Lines';
    Editable = false;
    PageType = ListPart;
    SaveValues = true;
    SourceTable = "Sales Shipment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    HideValue = DocumentNoHideValue;
                    Lookup = false;
                    StyleExpr = 'Strong';
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("Item Reference No."; Rec."Item Reference No.")
                {
                    AccessByPermission = tabledata "Item Reference" = R;
                    ApplicationArea = Suite, ItemReferences;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field(Nonstock; Rec.Nonstock)
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies either the name of or the description of the item, general ledger account or item charge.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = SalesReturnOrder;
                    Importance = Additional;
                    Visible = false;
                }
                field("Return Reason Code"; Rec."Return Reason Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the location in which the invoice line was registered.';
                    Visible = false;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the number of units of the item, general ledger account, or item charge on the line.';
                }
                field("Qty. Shipped Not Invoiced"; Rec."Qty. Shipped Not Invoiced")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field(QtyNotReturned; QtyNotReturned)
                {
                    ApplicationArea = SalesReturnOrder;
                    AutoFormatType = 0;
                    Caption = 'Qty. Not Returned';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity from the posted document line that has been shipped to the customer and not returned by the customer.';
                }
                field(QtyReturned; GetQtyReturned())
                {
                    ApplicationArea = SalesReturnOrder;
                    AutoFormatType = 0;
                    Caption = 'Qty. Returned';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity that was returned.';
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = SalesReturnOrder;
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
                    AutoFormatExpression = '';
                    Caption = 'Reverse Unit Cost (LCY)';
                    ToolTip = 'Specifies the unit cost that will appear on the new document lines.';
                    Visible = false;
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Blanket Order No."; Rec."Blanket Order No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Blanket Order Line No."; Rec."Blanket Order Line No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Appl.-from Item Entry"; Rec."Appl.-from Item Entry")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Appl.-to Item Entry"; Rec."Appl.-to Item Entry")
                {
                    ApplicationArea = SalesReturnOrder;
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
                action(ShowDocument)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Show Document';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the selected line exists on.';

                    trigger OnAction()
                    begin
                        ShowPostedShipment();
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
                action(ItemTrackingLines)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    ShortCutKey = 'Ctrl+Alt+I';
                    ToolTip = 'View or edit serial, lot and package numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    begin
                        ShowShptItemTrackingLines();
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
        if not Visible then
            exit(false);

        IsHandled := false;
        OnFindRecordOnBeforeFind(Rec, Which, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if Rec.Find(Which) then begin
            SalesShptLine := Rec;
            while true do begin
                ShowRec := IsShowRec(Rec);
                if ShowRec then
                    exit(true);
                if Rec.Next(1) = 0 then begin
                    Rec := SalesShptLine;
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

        SalesShptLine := Rec;
        repeat
            NextSteps := Rec.Next(Steps / Abs(Steps));
            ShowRec := IsShowRec(Rec);
            if ShowRec then begin
                RealSteps := RealSteps + NextSteps;
                SalesShptLine := Rec;
            end;
        until (NextSteps = 0) or (RealSteps = Steps);
        Rec := SalesShptLine;
        Rec.Find();
        exit(RealSteps);
    end;

    trigger OnOpenPage()
    begin
    end;

    var
        SalesShptLine: Record "Sales Shipment Line";
        TempSalesShptLine: Record "Sales Shipment Line" temporary;
        QtyNotReturned: Decimal;
        RevUnitCostLCY: Decimal;
        RevQtyFilter: Boolean;
        FillExactCostReverse: Boolean;
        Visible: Boolean;
        ShowRec: Boolean;
        DocumentNoHideValue: Boolean;

    local procedure IsFirstDocLine(): Boolean
    var
        SalesShptLine2: Record "Sales Shipment Line";
        QtyNotReturned2: Decimal;
        RevUnitCostLCY2: Decimal;
    begin
        TempSalesShptLine.Reset();
        TempSalesShptLine.CopyFilters(Rec);
        TempSalesShptLine.SetRange("Document No.", Rec."Document No.");
        if not TempSalesShptLine.FindFirst() then begin
            QtyNotReturned2 := QtyNotReturned;
            RevUnitCostLCY2 := RevUnitCostLCY;
            SalesShptLine2.CopyFilters(Rec);
            SalesShptLine2.SetRange("Document No.", Rec."Document No.");
            if not SalesShptLine2.FindSet() then
                exit(false);
            repeat
                ShowRec := IsShowRec(SalesShptLine2);
                if ShowRec then begin
                    TempSalesShptLine := SalesShptLine2;
                    TempSalesShptLine.Insert();
                end;
            until (SalesShptLine2.Next() = 0) or ShowRec;
            QtyNotReturned := QtyNotReturned2;
            RevUnitCostLCY := RevUnitCostLCY2;
        end;

        exit(Rec."Line No." = TempSalesShptLine."Line No.");
    end;

    local procedure IsShowRec(SalesShptLine2: Record "Sales Shipment Line"): Boolean
    var
        IsHandled: Boolean;
        ReturnValue: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsShowRec(Rec, SalesShptLine2, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        QtyNotReturned := 0;
        if RevQtyFilter and (SalesShptLine2.Type = SalesShptLine2.Type::" ") then
            exit(SalesShptLine2."Attached to Line No." = 0);
        if SalesShptLine2.Type <> SalesShptLine2.Type::Item then
            exit(true);
        SalesShptLine2.CalcShippedSaleNotReturned(QtyNotReturned, RevUnitCostLCY, FillExactCostReverse);
        if not RevQtyFilter then
            exit(true);
        exit(QtyNotReturned > 0);
    end;

    local procedure GetQtyReturned(): Decimal
    begin
        if (Rec.Type = Rec.Type::Item) and (Rec.Quantity - QtyNotReturned > 0) then
            exit(Rec.Quantity - QtyNotReturned);
        exit(0);
    end;

    /// <summary>
    /// Initializes the subform with filter and visibility settings.
    /// </summary>
    /// <param name="NewRevQtyFilter">Specifies whether to filter for reversible quantities.</param>
    /// <param name="NewFillExactCostReverse">Specifies whether to fill exact cost reverse.</param>
    /// <param name="NewVisible">Specifies whether the subform is visible.</param>
    procedure Initialize(NewRevQtyFilter: Boolean; NewFillExactCostReverse: Boolean; NewVisible: Boolean)
    begin
        RevQtyFilter := NewRevQtyFilter;
        FillExactCostReverse := NewFillExactCostReverse;
        Visible := NewVisible;

        if Visible then begin
            TempSalesShptLine.Reset();
            TempSalesShptLine.DeleteAll();
        end;
    end;

    /// <summary>
    /// Gets the currently selected shipment line with selection filter applied.
    /// </summary>
    /// <param name="FromSalesShptLine">Returns the selected sales shipment line.</param>
    procedure GetSelectedLine(var FromSalesShptLine: Record "Sales Shipment Line")
    begin
        FromSalesShptLine.Copy(Rec);
        CurrPage.SetSelectionFilter(FromSalesShptLine);
    end;

    local procedure ShowPostedShipment()
    var
        SalesShptHeader: Record "Sales Shipment Header";
        PageManagement: Codeunit "Page Management";
    begin
        if not SalesShptHeader.Get(Rec."Document No.") then
            exit;
        PageManagement.PageRun(SalesShptHeader);
    end;

    local procedure ShowShptItemTrackingLines()
    var
        FromSalesShptLine: Record "Sales Shipment Line";
    begin
        GetSelectedLine(FromSalesShptLine);
        FromSalesShptLine.ShowItemTrackingLines();
    end;

    local procedure DocumentNoOnFormat()
    begin
        if not IsFirstDocLine() then
            DocumentNoHideValue := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsShowRec(var SalesShipmentLine: Record "Sales Shipment Line"; var SalesShipmentLine2: Record "Sales Shipment Line"; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindRecordOnBeforeFind(var SalesShipmentLine: Record "Sales Shipment Line"; var Which: Text; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

