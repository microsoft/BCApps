// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Finance.Dimension;
using Microsoft.Sales.Document;
using Microsoft.Utilities;

/// <summary>
/// Lists posted sales shipment lines for selection when creating sales invoices from shipped orders.
/// </summary>
page 5708 "Get Shipment Lines"
{
    Caption = 'Get Shipment Lines';
    Editable = false;
    PageType = List;
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
                    ApplicationArea = Suite;
                    HideValue = DocumentNoHideValue;
                    StyleExpr = 'Strong';
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = Suite;
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Suite;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Suite;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a description of posted sales shipments.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
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
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location from where inventory items to the customer on the sales document are to be shipped by default.';
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Suite;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of item units, resource hours, general ledger account payments, or cost that have been shipped to the customer.';
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Appl.-to Item Entry"; Rec."Appl.-to Item Entry")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Quantity Invoiced"; Rec."Quantity Invoiced")
                {
                    ApplicationArea = Suite;
                }
                field("Qty. Shipped Not Invoiced"; Rec."Qty. Shipped Not Invoiced")
                {
                    ApplicationArea = Suite;
                }
                field(OrderNo; Rec."Order No.")
                {
                    Caption = 'Order No.';
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the sales order that this shipment was posted from.';
                    Visible = false;
                }
                field(ExternalDocumentNo; Rec."External Document No.")
                {
                    Caption = 'External Document No.';
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number that the customer uses in their own system to refer to this sales document.';
                    Visible = false;
                }
                field(YourReference; Rec."Your Reference")
                {
                    Caption = 'Your Reference';
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the customer''s reference. The content will be printed on sales documents.';
                    Visible = false;
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
                    ApplicationArea = Suite;
                    Caption = 'Show Document';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the selected line exists on.';

                    trigger OnAction()
                    var
                        PageManagement: Codeunit "Page Management";
                    begin
                        SalesShptHeader.Get(Rec."Document No.");
                        PageManagement.PageRun(SalesShptHeader);
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
                        CurrPage.SaveRecord();
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

    trigger OnQueryClosePage(CloseAction: Action) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnQueryClosePage(CloseAction, Result, IsHandled, Rec);
        if IsHandled then
            exit(Result);

        if CloseAction in [ACTION::OK, ACTION::LookupOK] then
            CreateLines();
    end;

    var
        SalesShptHeader: Record "Sales Shipment Header";
        SalesHeader: Record "Sales Header";
        TempSalesShptLine: Record "Sales Shipment Line" temporary;
        SalesGetShpt: Codeunit "Sales-Get Shipment";
        DocumentNoHideValue: Boolean;

    /// <summary>
    /// Sets the sales header for filtering shipment lines.
    /// </summary>
    /// <param name="SalesHeader2">The sales header to filter shipment lines for.</param>
    procedure SetSalesHeader(var SalesHeader2: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetSalesHeader(SalesHeader2, IsHandled, SalesHeader);
        if IsHandled then
            exit;

        SalesHeader.Get(SalesHeader2."Document Type", SalesHeader2."No.");
        SalesHeader.TestField("Document Type", SalesHeader."Document Type"::Invoice);
    end;

    local procedure IsFirstDocLine() Result: Boolean
    var
        SalesShptLine: Record "Sales Shipment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsFirstDocLine(Rec, TempSalesShptLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        TempSalesShptLine.Reset();
        TempSalesShptLine.CopyFilters(Rec);
        TempSalesShptLine.SetRange("Document No.", Rec."Document No.");
        if not TempSalesShptLine.FindFirst() then begin
            SalesShptLine.CopyFilters(Rec);
            SalesShptLine.SetRange("Document No.", Rec."Document No.");
            SalesShptLine.SetFilter("Qty. Shipped Not Invoiced", '<>0');
            if SalesShptLine.FindFirst() then begin
                TempSalesShptLine := SalesShptLine;
                TempSalesShptLine.Insert();
            end;
        end;
        if Rec."Line No." = TempSalesShptLine."Line No." then
            exit(true);
    end;

    /// <summary>
    /// Creates invoice lines from the selected shipment lines.
    /// </summary>
    procedure CreateLines()
    begin
        CurrPage.SetSelectionFilter(Rec);
        SalesGetShpt.SetSalesHeader(SalesHeader);
        OnCreateLinesOnAfterSalesGetShptSetSalesHeader(SalesHeader, Rec);
        SalesGetShpt.CreateInvLines(Rec);
    end;

    local procedure DocumentNoOnFormat()
    begin
        if not IsFirstDocLine() then
            DocumentNoHideValue := true;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnQueryClosePage(CloseAction: Action; var Result: Boolean; var IsHandled: Boolean; var SalesShipmentLine: Record "Sales Shipment Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSetSalesHeader(var SalesHeader2: Record "Sales Header"; var IsHandled: Boolean; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCreateLinesOnAfterSalesGetShptSetSalesHeader(var SalesHeader: Record "Sales Header"; var SalesShipmentLine: Record "Sales Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsFirstDocLine(var SalesShipmentLine: Record "Sales Shipment Line"; var TempSalesShipmentLine: Record "Sales Shipment Line" temporary; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

