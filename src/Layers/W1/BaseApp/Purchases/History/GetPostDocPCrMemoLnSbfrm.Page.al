// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Item.Catalog;

page 5859 "Get Post.Doc-P.Cr.MemoLn Sbfrm"
{
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Purch. Cr. Memo Line";

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
                    ToolTip = 'Specifies the credit memo number.';
                }
#pragma warning disable AA0100
                field("PurchCrMemoHeader.""Posting Date"""; PurchCrMemoHeader."Posting Date")
#pragma warning restore AA0100
                {
                    ApplicationArea = Suite;
                    Caption = 'Posting Date';
                    ToolTip = 'Specifies the posting date of the record.';
                }
                field("Expected Receipt Date"; Rec."Expected Receipt Date")
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
                    ApplicationArea = Suite;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Suite;
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
                    ApplicationArea = Suite;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Suite;
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
                    ApplicationArea = Location;
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
                    ApplicationArea = Suite;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Suite;
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
                field(DirectUnitCost; DirectUnitCost)
                {
                    ApplicationArea = SalesReturnOrder;
                    AutoFormatExpression = PurchCrMemoHeader."Currency Code";
                    AutoFormatType = 2;
                    Caption = 'Direct Unit Cost';
                    ToolTip = 'Specifies the direct unit cost. ';
                    Visible = false;
                }
                field(LineAmount; LineAmount)
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = PurchCrMemoHeader."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Line Amount';
                    ToolTip = 'Specifies the net amount, excluding any invoice discount amount, that must be paid for products on the line.';
                }
#pragma warning disable AA0100
                field("PurchCrMemoHeader.""Currency Code"""; PurchCrMemoHeader."Currency Code")
#pragma warning restore AA0100
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Currency Code';
                    ToolTip = 'Specifies the code for the currency that amounts are shown in.';
                    Visible = false;
                }
#pragma warning disable AA0100
                field("PurchCrMemoHeader.""Prices Including VAT"""; PurchCrMemoHeader."Prices Including VAT")
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
                }
                field("Line Discount Amount"; Rec."Line Discount Amount")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Inv. Discount Amount"; Rec."Inv. Discount Amount")
                {
                    ApplicationArea = SalesReturnOrder;
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
                        ShowLineDimensions();
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

        if Rec.Find(Which) then begin
            PurchCrMemoLine := Rec;
            while true do begin
                ShowRec := IsShowRec(Rec);
                if ShowRec then
                    exit(true);
                if Rec.Next(1) = 0 then begin
                    Rec := PurchCrMemoLine;
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

        PurchCrMemoLine := Rec;
        repeat
            NextSteps := Rec.Next(Steps / Abs(Steps));
            ShowRec := IsShowRec(Rec);
            if ShowRec then begin
                RealSteps := RealSteps + NextSteps;
                PurchCrMemoLine := Rec;
            end;
        until (NextSteps = 0) or (RealSteps = Steps);
        Rec := PurchCrMemoLine;
        Rec.Find();
        exit(RealSteps);
    end;

    trigger OnOpenPage()
    begin
    end;

    var
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        TempPurchCrMemoLine: Record "Purch. Cr. Memo Line" temporary;
        DirectUnitCost: Decimal;
        LineAmount: Decimal;
        DocumentNoHideValue: Boolean;
        ShowRec: Boolean;

    local procedure IsFirstDocLine(): Boolean
    begin
        TempPurchCrMemoLine.Reset();
        TempPurchCrMemoLine.CopyFilters(Rec);
        TempPurchCrMemoLine.SetRange("Document No.", Rec."Document No.");
        if not TempPurchCrMemoLine.FindFirst() then begin
            PurchCrMemoLine.CopyFilters(Rec);
            PurchCrMemoLine.SetRange("Document No.", Rec."Document No.");
            if not PurchCrMemoLine.FindFirst() then
                exit(false);
            TempPurchCrMemoLine := PurchCrMemoLine;
            TempPurchCrMemoLine.Insert();
        end;

        if Rec."Document No." <> PurchCrMemoHeader."No." then
            PurchCrMemoHeader.Get(Rec."Document No.");

        DirectUnitCost := Rec."Direct Unit Cost";
        LineAmount := Rec."Line Amount";

        exit(Rec."Line No." = TempPurchCrMemoLine."Line No.");
    end;

    local procedure IsShowRec(PurchCrMemoLine2: Record "Purch. Cr. Memo Line") Result: Boolean
    begin
        if PurchCrMemoLine2."Document No." <> PurchCrMemoHeader."No." then
            PurchCrMemoHeader.Get(PurchCrMemoLine2."Document No.");
        if PurchCrMemoHeader."Prepayment Credit Memo" then
            exit(false);

        Result := true;
        OnAfterIsShowRec(PurchCrMemoLine2, Result);
    end;

    procedure GetSelectedLine(var FromPurchCrMemoLine: Record "Purch. Cr. Memo Line")
    begin
        FromPurchCrMemoLine.Copy(Rec);
        CurrPage.SetSelectionFilter(FromPurchCrMemoLine);
    end;

    local procedure ShowDocument()
    begin
        if not PurchCrMemoHeader.Get(Rec."Document No.") then
            exit;
        PAGE.Run(PAGE::"Posted Purchase Credit Memo", PurchCrMemoHeader);
    end;

    local procedure ShowLineDimensions()
    var
        FromPurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        GetSelectedLine(FromPurchCrMemoLine);
        FromPurchCrMemoLine.ShowDimensions();
    end;

    local procedure ItemTrackingLines()
    var
        FromPurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        GetSelectedLine(FromPurchCrMemoLine);
        FromPurchCrMemoLine.ShowItemTrackingLines();
    end;

    local procedure DocumentNoOnFormat()
    begin
        if not IsFirstDocLine() then
            DocumentNoHideValue := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsShowRec(PurchCrMemoLine2: Record "Purch. Cr. Memo Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindRecordOnBeforeFind(var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; var Which: Text; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

