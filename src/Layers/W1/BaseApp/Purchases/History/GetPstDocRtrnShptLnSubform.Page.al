// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Item.Catalog;

page 5858 "Get Pst.Doc-RtrnShptLn Subform"
{
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Return Shipment Line";

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
                    ToolTip = 'Specifies the number of the return shipment.';
                }
                field("Pay-to Vendor No."; Rec."Pay-to Vendor No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.")
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
                    ToolTip = 'Specifies either the name of, or a description of, the item, general ledger account, or item charge.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Return Reason Code"; Rec."Return Reason Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    DrillDown = false;
                    Lookup = false;
                    ToolTip = 'Specifies the currency code for the amount on this line.';
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the code for the location where items on the line are placed.';
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
                    ToolTip = 'Specifies the number of units of the item, general ledger account, or item charge specified on the line.';
                }
                field("Return Qty. Shipped Not Invd."; Rec."Return Qty. Shipped Not Invd.")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the quantity of the returned item that has been posted as shipped but that has not yet been posted as invoiced.';
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
                field("Appl.-to Item Entry"; Rec."Appl.-to Item Entry")
                {
                    ApplicationArea = SalesReturnOrder;
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
                    ApplicationArea = SalesReturnOrder;
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
        IsHandled := false;
        OnFindRecordOnBeforeFind(Rec, Which, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(Rec.Find(Which));
    end;

    trigger OnOpenPage()
    begin
    end;

    var
        ReturnShptLine: Record "Return Shipment Line";
        TempReturnShptLine: Record "Return Shipment Line" temporary;
        DocumentNoHideValue: Boolean;

    local procedure IsFirstDocLine(): Boolean
    begin
        TempReturnShptLine.Reset();
        TempReturnShptLine.CopyFilters(Rec);
        TempReturnShptLine.SetRange("Document No.", Rec."Document No.");
        if not TempReturnShptLine.FindFirst() then begin
            ReturnShptLine.CopyFilters(Rec);
            ReturnShptLine.SetRange("Document No.", Rec."Document No.");
            if not ReturnShptLine.FindFirst() then
                exit(false);
            TempReturnShptLine := ReturnShptLine;
            TempReturnShptLine.Insert();
        end;

        exit(Rec."Line No." = TempReturnShptLine."Line No.");
    end;

    procedure GetSelectedLine(var FromReturnShptLine: Record "Return Shipment Line")
    begin
        FromReturnShptLine.Copy(Rec);
        CurrPage.SetSelectionFilter(FromReturnShptLine);
    end;

    local procedure ShowDocument()
    var
        ReturnShptHeader: Record "Return Shipment Header";
    begin
        if not ReturnShptHeader.Get(Rec."Document No.") then
            exit;
        PAGE.Run(PAGE::"Posted Return Shipment", ReturnShptHeader);
    end;

    local procedure ItemTrackingLines()
    var
        FromReturnShptLine: Record "Return Shipment Line";
    begin
        GetSelectedLine(FromReturnShptLine);
        FromReturnShptLine.ShowItemTrackingLines();
    end;

    local procedure DocumentNoOnFormat()
    begin
        if not IsFirstDocLine() then
            DocumentNoHideValue := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindRecordOnBeforeFind(var ReturnShipmentLine: Record "Return Shipment Line"; var Which: Text; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

