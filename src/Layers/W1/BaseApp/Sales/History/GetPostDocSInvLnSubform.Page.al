// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Sales.Document;
using Microsoft.Utilities;

/// <summary>
/// Displays posted sales invoice lines as a subform for line selection during document retrieval.
/// </summary>
page 5852 "Get Post.Doc - S.InvLn Subform"
{
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Sales Invoice Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    HideValue = DocumentNoHideValue;
                    Lookup = false;
                    StyleExpr = 'Strong';
                    ToolTip = 'Specifies the invoice number.';
                }
#pragma warning disable AA0100
                field("SalesInvHeader.""Posting Date"""; SalesInvHeader."Posting Date")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posting Date';
                    ToolTip = 'Specifies the posting date of the record.';
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
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
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    Visible = false;
                }
                field("Return Reason Code"; Rec."Return Reason Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Visible = false;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
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
                    ApplicationArea = Basic, Suite;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(QtyNotReturned; QtyNotReturned)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 0;
                    Caption = 'Qty. Not Returned';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity from the posted document line that has been shipped to the customer and not returned by the customer.';
                }
                field(QtyReturned; GetQtyReturned())
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 0;
                    Caption = 'Qty. Returned';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity that was returned.';
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Unit Cost (LCY)"; Rec."Unit Cost (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the cost, in LCY, of one unit of the item or resource on the line.';
                    Visible = false;
                }
                field(RevUnitCostLCY; RevUnitCostLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 2;
                    AutoFormatExpression = '';
                    Caption = 'Reverse Unit Cost (LCY)';
                    ToolTip = 'Specifies the unit cost that will appear on the new document lines.';
                    Visible = false;
                }
                field(UnitPrice; UnitPrice)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = SalesInvHeader."Currency Code";
                    AutoFormatType = 2;
                    Caption = 'Unit Price';
                    ToolTip = 'Specifies the item''s unit price.';
                    Visible = false;
                }
                field(LineAmount; LineAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = SalesInvHeader."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Line Amount';
                    ToolTip = 'Specifies the net amount, excluding any invoice discount amount, that must be paid for products on the line.';
                }
#pragma warning disable AA0100
                field("SalesInvHeader.""Currency Code"""; SalesInvHeader."Currency Code")
#pragma warning restore AA0100
                {
                    ApplicationArea = Suite;
                    Caption = 'Currency Code';
                    ToolTip = 'Specifies the code for the currency that amounts are shown in.';
                    Visible = false;
                }
#pragma warning disable AA0100
                field("SalesInvHeader.""Prices Including VAT"""; SalesInvHeader."Prices Including VAT")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Prices Including VAT';
                    ToolTip = 'Specifies if the Unit Price and Line Amount fields on document lines should be shown with or without VAT.';
                    Visible = false;
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                }
                field("Line Discount Amount"; Rec."Line Discount Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Inv. Discount Amount"; Rec."Inv. Discount Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Blanket Order No."; Rec."Blanket Order No.")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Blanket Order Line No."; Rec."Blanket Order Line No.")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Appl.-from Item Entry"; Rec."Appl.-from Item Entry")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Appl.-to Item Entry"; Rec."Appl.-to Item Entry")
                {
                    ApplicationArea = Basic, Suite;
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
                    ApplicationArea = Basic, Suite;
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
            SalesInvLine := Rec;
            while true do begin
                ShowRec := IsShowRec(Rec);
                if ShowRec then
                    exit(true);
                if Rec.Next(1) = 0 then begin
                    Rec := SalesInvLine;
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

        SalesInvLine := Rec;
        repeat
            NextSteps := Rec.Next(Steps / Abs(Steps));
            ShowRec := IsShowRec(Rec);
            if ShowRec then begin
                RealSteps := RealSteps + NextSteps;
                SalesInvLine := Rec;
            end;
        until (NextSteps = 0) or (RealSteps = Steps);
        Rec := SalesInvLine;
        Rec.Find();
        exit(RealSteps);
    end;

    trigger OnOpenPage()
    begin
    end;

    var
        ToSalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        TempSalesInvLine: Record "Sales Invoice Line" temporary;
        QtyNotReturned: Decimal;
        RevUnitCostLCY: Decimal;
        UnitPrice: Decimal;
        LineAmount: Decimal;
        RevQtyFilter: Boolean;
        FillExactCostReverse: Boolean;
        IsVisible: Boolean;
        ShowRec: Boolean;

    protected var
        DocumentNoHideValue: Boolean;

    local procedure IsFirstDocLine(): Boolean
    var
        SalesInvHeader2: Record "Sales Invoice Header";
        SalesInvLine2: Record "Sales Invoice Line";
        QtyNotReturned2: Decimal;
        RevUnitCostLCY2: Decimal;
    begin
        TempSalesInvLine.Reset();
        TempSalesInvLine.CopyFilters(Rec);
        TempSalesInvLine.SetRange("Document No.", Rec."Document No.");
        if not TempSalesInvLine.FindFirst() then begin
            SalesInvHeader2 := SalesInvHeader;
            QtyNotReturned2 := QtyNotReturned;
            RevUnitCostLCY2 := RevUnitCostLCY;
            SalesInvLine2.CopyFilters(Rec);
            SalesInvLine2.SetRange("Document No.", Rec."Document No.");
            if not SalesInvLine2.FindSet() then
                exit(false);
            repeat
                ShowRec := IsShowRec(SalesInvLine2);
                if ShowRec then begin
                    TempSalesInvLine := SalesInvLine2;
                    TempSalesInvLine.Insert();
                end;
            until (SalesInvLine2.Next() = 0) or ShowRec;
            SalesInvHeader := SalesInvHeader2;
            QtyNotReturned := QtyNotReturned2;
            RevUnitCostLCY := RevUnitCostLCY2;
        end;

        if Rec."Document No." <> SalesInvHeader."No." then
            SalesInvHeader.Get(Rec."Document No.");

        UnitPrice := Rec."Unit Price";
        LineAmount := Rec."Line Amount";

        exit(Rec."Line No." = TempSalesInvLine."Line No.");
    end;

    local procedure IsShowRec(SalesInvLine2: Record "Sales Invoice Line"): Boolean
    var
        IsHandled: Boolean;
        ReturnValue: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsShowRec(Rec, SalesInvLine2, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        QtyNotReturned := 0;
        if SalesInvLine2."Document No." <> SalesInvHeader."No." then
            SalesInvHeader.Get(SalesInvLine2."Document No.");
        if SalesInvHeader."Prepayment Invoice" then
            exit(false);
        if RevQtyFilter then begin
            if SalesInvHeader."Currency Code" <> ToSalesHeader."Currency Code" then
                exit(false);
            if SalesInvLine2.Type = SalesInvLine2.Type::" " then
                exit(SalesInvLine2."Attached to Line No." = 0);
        end;

        IsHandled := false;
        OnIsShowRecOnBeforeCheckIsTypeNotItem(SalesInvLine2, QtyNotReturned, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        if SalesInvLine2.Type <> SalesInvLine2.Type::Item then
            exit(true);
        SalesInvLine2.CalcShippedSaleNotReturned(QtyNotReturned, RevUnitCostLCY, FillExactCostReverse);
        if not RevQtyFilter then
            exit(true);
        exit(QtyNotReturned > 0);
    end;

    local procedure GetQtyReturned() Result: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetQtyReturned(Rec, QtyNotReturned, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if (Rec.Type = Rec.Type::Item) and (Rec.Quantity - QtyNotReturned > 0) then
            exit(Rec.Quantity - QtyNotReturned);
        exit(0);
    end;

    /// <summary>
    /// Initializes the subform with target header, filter, and visibility settings.
    /// </summary>
    /// <param name="NewToSalesHeader">The target sales header for copying lines.</param>
    /// <param name="NewRevQtyFilter">Specifies whether to filter for reversible quantities.</param>
    /// <param name="NewFillExactCostReverse">Specifies whether to fill exact cost reverse.</param>
    /// <param name="NewVisible">Specifies whether the subform is visible.</param>
    procedure Initialize(NewToSalesHeader: Record "Sales Header"; NewRevQtyFilter: Boolean; NewFillExactCostReverse: Boolean; NewVisible: Boolean)
    begin
        ToSalesHeader := NewToSalesHeader;
        RevQtyFilter := NewRevQtyFilter;
        FillExactCostReverse := NewFillExactCostReverse;
        IsVisible := NewVisible;

        if IsVisible then begin
            TempSalesInvLine.Reset();
            TempSalesInvLine.DeleteAll();
        end;
    end;

    /// <summary>
    /// Gets the currently selected invoice line with selection filter applied.
    /// </summary>
    /// <param name="FromSalesInvLine">Returns the selected sales invoice line.</param>
    procedure GetSelectedLine(var FromSalesInvLine: Record "Sales Invoice Line")
    begin
        FromSalesInvLine.Copy(Rec);
        CurrPage.SetSelectionFilter(FromSalesInvLine);
    end;

    local procedure ShowDocument()
    var
        PageManagement: Codeunit "Page Management";
    begin
        if not SalesInvHeader.Get(Rec."Document No.") then
            exit;
        PageManagement.PageRun(SalesInvHeader);
    end;

    local procedure ItemTrackingLines()
    var
        FromSalesInvLine: Record "Sales Invoice Line";
    begin
        GetSelectedLine(FromSalesInvLine);
        FromSalesInvLine.ShowItemTrackingLines();
    end;

    local procedure DocumentNoOnFormat()
    begin
        if not IsFirstDocLine() then
            DocumentNoHideValue := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsShowRec(var SalesInvoiceLine: Record "Sales Invoice Line"; var SalesInvoiceLine2: Record "Sales Invoice Line"; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindRecordOnBeforeFind(var SalesInvoiceLine: Record "Sales Invoice Line"; var Which: Text; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsShowRecOnBeforeCheckIsTypeNotItem(var SalesInvoiceLine: Record "Sales Invoice Line"; var QtyNotReturned: Decimal; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetQtyReturned(var SalesInvoiceLine: Record "Sales Invoice Line"; QtyNotReturned: Decimal; var ReturnValue: Decimal; var IsHandled: Boolean)
    begin
    end;
}

