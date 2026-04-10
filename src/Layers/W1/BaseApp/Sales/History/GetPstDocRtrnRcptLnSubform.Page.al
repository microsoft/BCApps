// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Utilities;

/// <summary>
/// Displays posted return receipt lines as a subform for line selection during document retrieval.
/// </summary>
page 5853 "Get Pst.Doc-RtrnRcptLn Subform"
{
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Return Receipt Line";

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
                    ToolTip = 'Specifies the number of the return receipt.';
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
                    ToolTip = 'Specifies either the name of, or the description of, the item, general ledger account, or item charge.';
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
                    ToolTip = 'Specifies the location in which the return receipt line was registered.';
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
                field("Return Qty. Rcd. Not Invd."; Rec."Return Qty. Rcd. Not Invd.")
                {
                    ApplicationArea = SalesReturnOrder;
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
                field("Appl.-from Item Entry"; Rec."Appl.-from Item Entry")
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
        ReturnValue: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindRecord(Which, Rec, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        exit(Rec.Find(Which));
    end;

    trigger OnOpenPage()
    begin
    end;

    var
        ReturnRcptLine: Record "Return Receipt Line";
        TempReturnRcptLine: Record "Return Receipt Line" temporary;
        DocumentNoHideValue: Boolean;

    local procedure IsFirstDocLine(): Boolean
    begin
        TempReturnRcptLine.Reset();
        TempReturnRcptLine.CopyFilters(Rec);
        TempReturnRcptLine.SetRange("Document No.", Rec."Document No.");
        if not TempReturnRcptLine.FindFirst() then begin
            ReturnRcptLine.CopyFilters(Rec);
            ReturnRcptLine.SetRange("Document No.", Rec."Document No.");
            if not ReturnRcptLine.FindFirst() then
                exit(false);
            TempReturnRcptLine := ReturnRcptLine;
            TempReturnRcptLine.Insert();
        end;

        exit(Rec."Line No." = TempReturnRcptLine."Line No.");
    end;

    /// <summary>
    /// Gets the currently selected return receipt line with selection filter applied.
    /// </summary>
    /// <param name="FromReturnRcptLine">Returns the selected return receipt line.</param>
    procedure GetSelectedLine(var FromReturnRcptLine: Record "Return Receipt Line")
    begin
        FromReturnRcptLine.Copy(Rec);
        CurrPage.SetSelectionFilter(FromReturnRcptLine);
    end;

    local procedure ShowDocument()
    var
        ReturnRcptHeader: Record "Return Receipt Header";
        PageManagement: Codeunit "Page Management";
    begin
        if not ReturnRcptHeader.Get(Rec."Document No.") then
            exit;
        PageManagement.PageRun(ReturnRcptHeader);
    end;

    local procedure ItemTrackingLines()
    var
        FromReturnRcptLine: Record "Return Receipt Line";
    begin
        GetSelectedLine(FromReturnRcptLine);
        FromReturnRcptLine.ShowItemTrackingLines();
    end;

    local procedure DocumentNoOnFormat()
    begin
        if not IsFirstDocLine() then
            DocumentNoHideValue := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindRecord(var Which: Text; var ReturnReceiptLine: Record "Return Receipt Line"; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
    end;
}

