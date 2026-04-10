// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Finance.Dimension;
using Microsoft.Purchases.Document;

page 6648 "Get Return Shipment Lines"
{
    Caption = 'Get Return Shipment Lines';
    Editable = false;
    PageType = List;
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
                    StyleExpr = 'Strong';
                }
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = SalesReturnOrder;
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
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Appl.-to Item Entry"; Rec."Appl.-to Item Entry")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Quantity Invoiced"; Rec."Quantity Invoiced")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("Return Qty. Shipped Not Invd."; Rec."Return Qty. Shipped Not Invd.")
                {
                    ApplicationArea = SalesReturnOrder;
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
                action("Show Document")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Show Document';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the selected line exists on.';

                    trigger OnAction()
                    begin
                        ReturnShptHeader.Get(Rec."Document No.");
                        PAGE.Run(PAGE::"Posted Return Shipment", ReturnShptHeader);
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
                action("Item &Tracking Entries")
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
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Show Document_Promoted"; "Show Document")
                {
                }
                actionref("Item &Tracking Entries_Promoted"; "Item &Tracking Entries")
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DocumentNoHideValue := false;
        DocumentNoOnFormat();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            LookupOKOnPush();
    end;

    var
        PurchHeader: Record "Purchase Header";
        ReturnShptHeader: Record "Return Shipment Header";
        TempReturnShptLine: Record "Return Shipment Line" temporary;
        GetReturnShipments: Codeunit "Purch.-Get Return Shipments";
        DocumentNoHideValue: Boolean;

    procedure SetPurchHeader(var PurchHeader2: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        PurchHeader.Get(PurchHeader2."Document Type", PurchHeader2."No.");
        IsHandled := false;
        OnSetPurchHeaderOnBegoreTestIsCreditMemo(PurchHeader, IsHandled);
        if not IsHandled then
            PurchHeader.TestField("Document Type", PurchHeader."Document Type"::"Credit Memo");
    end;

    local procedure IsFirstDocLine(): Boolean
    var
        ReturnShptLine: Record "Return Shipment Line";
    begin
        OnBeforeIsFirstDocLine(Rec, TempReturnShptLine);

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
        if Rec."Line No." = TempReturnShptLine."Line No." then
            exit(true);
    end;

    local procedure LookupOKOnPush()
    begin
        CurrPage.SetSelectionFilter(Rec);
        GetReturnShipments.SetPurchHeader(PurchHeader);
        GetReturnShipments.CreateInvLines(Rec);
    end;

    local procedure DocumentNoOnFormat()
    begin
        if not IsFirstDocLine() then
            DocumentNoHideValue := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsFirstDocLine(var ReturnShipmentLine: Record "Return Shipment Line"; var TempReturnShipmentLine: Record "Return Shipment Line" temporary);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetPurchHeaderOnBegoreTestIsCreditMemo(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;
}

