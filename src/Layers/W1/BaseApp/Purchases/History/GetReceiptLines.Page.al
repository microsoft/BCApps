// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Finance.Dimension;
using Microsoft.Purchases.Document;

page 5709 "Get Receipt Lines"
{
    Caption = 'Get Receipt Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Purch. Rcpt. Line";

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
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a description of additional receipts posted.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies information in addition to the description.';
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    DrillDown = false;
                    Lookup = false;
                    ToolTip = 'Specifies the currency that is used on the entry.';
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
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies a code for the location where you want the items to be placed when they are received.';
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the item or resource''s unit of measure, such as piece or hour.';
                    Visible = false;
                }
                field("Appl.-to Item Entry"; Rec."Appl.-to Item Entry")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the item ledger entry that the document or journal line is applied to.';
                    Visible = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the quantity of the item on the line.';
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the related project.';
                    Visible = false;
                }
                field("Expected Receipt Date"; Rec."Expected Receipt Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date you expect the items to be available in your warehouse. If you leave the field blank, it will be calculated as follows: Planned Receipt Date + Safety Lead Time + Inbound Warehouse Handling Time = Expected Receipt Date.';
                    Visible = false;
                }
                field("Quantity Invoiced"; Rec."Quantity Invoiced")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how many units of the item on the line have been posted as invoiced.';
                }
                field("Qty. Rcd. Not Invoiced"; Rec."Qty. Rcd. Not Invoiced")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the quantity of the received item that has been posted as received but that has not yet been posted as invoiced.';
                }
                field(OrderNo; OrderNo)
                {
                    Caption = 'Order No.';
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the line number of the order that created the entry.';
                }
                field(VendorOrderNo; VendorOrderNo)
                {
                    Caption = 'Vendor Order No.';
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the vendor''s order number.';
                }
                field(VendorShptNo; VendorShptNo)
                {
                    Caption = 'Vendor Shipment No.';
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the vendor''s shipment number. It is inserted in the corresponding field on the source document during posting.';
                }
                field("Vendor Item No."; Rec."Vendor Item No.")
                {
                    Caption = 'Vendor Item No.';
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number that the vendor uses for this item.';
                }
                field(ItemReferenceNo; ItemReferenceNo)
                {
                    Caption = 'Item Reference No.';
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the referenced item number.';
                }
                field("Pay-to Vendor No."; Rec."Pay-to Vendor No.")
                {
                    Caption = 'Pay-to Vendor No.';
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the vendor that you received the invoice from.';
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
                    begin
                        PurchRcptHeader.Get(Rec."Document No.");
                        PAGE.Run(PAGE::"Posted Purchase Receipt", PurchRcptHeader);
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
            group(Category_Category4)
            {
                Caption = 'Line', Comment = 'Generated from the PromotedActionCategories property index 3.';
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DocumentNoHideValue := false;
        DocumentNoOnFormat();
        GetDataFromRcptHeader();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        GetDataFromRcptHeader();
    end;

    trigger OnQueryClosePage(CloseAction: Action) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnQueryClosePage(CloseAction, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if CloseAction in [ACTION::OK, ACTION::LookupOK] then
            CreateLines();
    end;

    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        TempPurchRcptLine: Record "Purch. Rcpt. Line" temporary;
        GetReceipts: Codeunit "Purch.-Get Receipt";
        VendorOrderNo: Code[35];
        VendorShptNo: Code[35];
        OrderNo: Code[20];
        ItemReferenceNo: Code[50];

    protected var
        PurchHeader: Record "Purchase Header";
        DocumentNoHideValue: Boolean;

    procedure SetPurchHeader(var PurchHeader2: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetPurchHeader(PurchHeader2, IsHandled, PurchHeader);
        if IsHandled then
            exit;

        PurchHeader.Get(PurchHeader2."Document Type", PurchHeader2."No.");
        PurchHeader.TestField("Document Type", PurchHeader."Document Type"::Invoice);
    end;

    protected procedure IsFirstDocLine(): Boolean
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        OnBeforeIsFirstDocLine(Rec, TempPurchRcptLine);

        TempPurchRcptLine.Reset();
        TempPurchRcptLine.CopyFilters(Rec);
        TempPurchRcptLine.SetRange("Document No.", Rec."Document No.");
        if not TempPurchRcptLine.FindFirst() then begin
            PurchRcptLine.CopyFilters(Rec);
            PurchRcptLine.SetRange("Document No.", Rec."Document No.");
            PurchRcptLine.SetFilter("Qty. Rcd. Not Invoiced", '<>0');
            if PurchRcptLine.FindFirst() then begin
                TempPurchRcptLine := PurchRcptLine;
                TempPurchRcptLine.Insert();
            end;
        end;
        if Rec."Line No." = TempPurchRcptLine."Line No." then
            exit(true);
    end;

    local procedure CreateLines()
    begin
        CurrPage.SetSelectionFilter(Rec);
        GetReceipts.SetPurchHeader(PurchHeader);
        GetReceipts.CreateInvLines(Rec);
    end;

    local procedure DocumentNoOnFormat()
    begin
        if not IsFirstDocLine() then
            DocumentNoHideValue := true;
    end;

    local procedure GetDataFromRcptHeader()
    var
        SrcPurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        SrcPurchRcptHeader.Get(Rec."Document No.");
        VendorOrderNo := SrcPurchRcptHeader."Vendor Order No.";
        VendorShptNo := SrcPurchRcptHeader."Vendor Shipment No.";
        OrderNo := SrcPurchRcptHeader."Order No.";

        ItemReferenceNo := Rec."Item Reference No.";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetPurchHeader(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean; var PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnQueryClosePage(CloseAction: Action; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsFirstDocLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; var TempPurchRcptLine: Record "Purch. Rcpt. Line" temporary)
    begin
    end;
}

