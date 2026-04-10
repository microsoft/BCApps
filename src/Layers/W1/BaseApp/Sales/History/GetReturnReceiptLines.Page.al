// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Finance.Dimension;
using Microsoft.Sales.Document;
using Microsoft.Utilities;

/// <summary>
/// Lists posted return receipt lines for selection when creating sales credit memos from received returns.
/// </summary>
page 6638 "Get Return Receipt Lines"
{
    Caption = 'Get Return Receipt Lines';
    Editable = false;
    PageType = List;
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
                    StyleExpr = 'Strong';
                }
                field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = true;
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
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies a description of posted sales return receipts.';
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
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the quantity of the item on the line.';
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
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Quantity Invoiced"; Rec."Quantity Invoiced")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("Return Qty. Rcd. Not Invd."; Rec."Return Qty. Rcd. Not Invd.")
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
                    var
                        PageManagement: Codeunit "Page Management";
                    begin
                        ReturnRcptHeader.Get(Rec."Document No.");
                        PageManagement.PageRun(ReturnRcptHeader);
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
        ReturnRcptHeader: Record "Return Receipt Header";
        SalesHeader: Record "Sales Header";
        TempReturnRcptLine: Record "Return Receipt Line" temporary;
        SalesGetReturnReceipts: Codeunit "Sales-Get Return Receipts";
        DocumentNoHideValue: Boolean;

    /// <summary>
    /// Sets the sales header for filtering return receipt lines.
    /// </summary>
    /// <param name="SalesHeader2">The sales header to filter return receipt lines for.</param>
    procedure SetSalesHeader(var SalesHeader2: Record "Sales Header")
    begin
        SalesHeader.Get(SalesHeader2."Document Type", SalesHeader2."No.");
        SalesHeader.TestField("Document Type", SalesHeader."Document Type"::"Credit Memo");
    end;

    local procedure IsFirstDocLine(): Boolean
    var
        ReturnRcptLine: Record "Return Receipt Line";
    begin
        OnBeforeIsFirstDocLine(Rec, TempReturnRcptLine);

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
        if Rec."Line No." = TempReturnRcptLine."Line No." then
            exit(true);
    end;

    local procedure LookupOKOnPush()
    begin
        CurrPage.SetSelectionFilter(Rec);
        SalesGetReturnReceipts.SetSalesHeader(SalesHeader);
        SalesGetReturnReceipts.CreateInvLines(Rec);
    end;

    local procedure DocumentNoOnFormat()
    begin
        if not IsFirstDocLine() then
            DocumentNoHideValue := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsFirstDocLine(var ReturnReceiptLine: Record "Return Receipt Line"; var TempReturnReceiptLine: Record "Return Receipt Line" temporary);
    begin
    end;
}

