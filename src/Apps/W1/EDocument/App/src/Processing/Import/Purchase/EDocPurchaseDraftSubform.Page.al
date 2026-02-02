// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import.Purchase;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;

page 6183 "E-Doc. Purchase Draft Subform"
{

    AutoSplitKey = true;
    Caption = 'Lines';
    InsertAllowed = true;
    LinksAllowed = false;
    DeleteAllowed = true;
    ModifyAllowed = true;
    PageType = ListPart;
    SourceTable = "E-Document Purchase Line";

    layout
    {
        area(Content)
        {
            repeater(DocumentLines)
            {
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Editable = true;
                }
                field(OrderMatched; OrderMatchedCaption)
                {
                    ApplicationArea = All;
                    Caption = 'Order line match';
                    Editable = false;
                    Visible = IsEDocumentMatchedToAnyPOLine;
                    ToolTip = 'Specifies whether this line is matched to a purchase order line.';

                    trigger OnDrillDown()
                    begin
                        OpenMatchedPurchaseOrder(Rec);
                    end;
                }
                field(MatchWarnings; MatchWarningsCaption)
                {
                    ApplicationArea = All;
                    Caption = 'Order match warnings';
                    Editable = false;
                    Visible = HasEDocumentOrderMatchWarnings;
                    StyleExpr = MatchWarningsStyleExpr;
                    ToolTip = 'Specifies any warnings related to matching this line to a purchase order line.';
                }
                field("Line Type"; Rec."[BC] Purchase Line Type")
                {
                    ApplicationArea = All;
                }
                field("No."; Rec."[BC] Purchase Type No.")
                {
                    ApplicationArea = All;
                    Lookup = true;
                    ShowMandatory = true;
                }
                field("Item Reference No."; Rec."[BC] Item Reference No.")
                {
                    ApplicationArea = All;
                    Lookup = true;
                    Visible = false;
                }
                field("Unit Of Measure"; Rec."[BC] Unit of Measure")
                {
                    ApplicationArea = All;
                    Lookup = true;
                }
                field("Variant Code"; Rec."[BC] Variant Code")
                {
                    ApplicationArea = All;
                    Lookup = true;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    Editable = true;

                    trigger OnValidate()
                    begin
                        UpdateCalculatedAmounts(true);
                    end;
                }
                field("Direct Unit Cost"; Rec."Unit Price")
                {
                    ApplicationArea = All;
                    Editable = true;
                    trigger OnValidate()
                    begin
                        UpdateCalculatedAmounts(true);
                    end;
                }
                field("Total Discount"; Rec."Total Discount")
                {
                    Caption = 'Line Discount';
                    ApplicationArea = All;
                    Editable = true;
                    trigger OnValidate()
                    begin
                        UpdateCalculatedAmounts(true);
                    end;
                }
                field("Line Amount"; LineAmount)
                {
                    ApplicationArea = All;
                    Caption = 'Line Amount';
                    ToolTip = 'Specifies the line amount.';
                    Editable = false;
                    AutoFormatType = 1;
                    AutoFormatExpression = Rec."Currency Code";
                }
                field("Deferral Code"; Rec."[BC] Deferral Code")
                {
                    ApplicationArea = All;
                }
                field("Shortcut Dimension 1 Code"; Rec."[BC] Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = DimVisible1;
                }
                field("Shortcut Dimension 2 Code"; Rec."[BC] Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = DimVisible2;
                }
                field(AdditionalColumns; AdditionalColumns)
                {
                    ApplicationArea = All;
                    Caption = 'Additional columns';
                    ToolTip = 'Specifies the additional columns considered.';
                    Editable = false;
                    Visible = HasAdditionalColumns;
                    trigger OnDrillDown()
                    begin
                        Page.RunModal(Page::"E-Doc Line Values.", Rec);
                    end;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(History)
            {
                ApplicationArea = All;
                Caption = 'Values from history';
                Image = History;
                ToolTip = 'The values for this line were retrieved from previously posted invoices. Open the invoice to see the values.';
                Visible = Rec."E-Doc. Purch. Line History Id" <> 0;
                trigger OnAction()
                begin
                    if not EDocPurchaseHistMapping.OpenPageWithHistoricMatch(Rec) then
                        Error(HistoryCantBeRetrievedErr);
                end;
            }
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                group("Order Matching")
                {
                    Caption = 'Order matching';
                    action(MatchToOrderLine)
                    {
                        ApplicationArea = All;
                        Caption = 'Match to order line';
                        Image = LinkWithExisting;
                        ToolTip = 'Match this incoming invoice line to a purchase order line.';
                        Scope = Repeater;

                        trigger OnAction()
                        var
                            TempSelectedPOLines: Record "Purchase Line" temporary;
                            EDocPOMatching: Codeunit "E-Doc. PO Matching";
                            EDocSelectPOLinesPage: Page "E-Doc. Select PO Lines";
                        begin
                            EDocSelectPOLinesPage.SetEDocumentPurchaseLine(Rec);
                            EDocSelectPOLinesPage.LookupMode := true;
                            if EDocSelectPOLinesPage.RunModal() <> Action::LookupOK then
                                exit;
                            EDocSelectPOLinesPage.GetSelectedPOLines(TempSelectedPOLines);
                            EDocPOMatching.MatchPOLinesToEDocumentLine(TempSelectedPOLines, Rec);
                            CurrPage.Update();
                        end;
                    }
                    action(SpecifyReceiptLines)
                    {
                        ApplicationArea = All;
                        Caption = 'Specify receipt line';
                        Image = ReceiptLines;
                        ToolTip = 'Specify the corresponding receipt line to the matched order line.';
                        Scope = Repeater;
                        Enabled = IsLineMatchedToOrderLine;

                        trigger OnAction()
                        var
                            TempSelectedReceiptLines: Record "Purch. Rcpt. Line" temporary;
                            EDocPOMatching: Codeunit "E-Doc. PO Matching";
                            EDocSelectReceiptLinesPage: Page "E-Doc. Select Receipt Lines";
                        begin
                            EDocSelectReceiptLinesPage.SetEDocumentPurchaseLine(Rec);
                            EDocSelectReceiptLinesPage.LookupMode := true;
                            if EDocSelectReceiptLinesPage.RunModal() <> Action::LookupOK then
                                exit;
                            EDocSelectReceiptLinesPage.GetSelectedReceiptLines(TempSelectedReceiptLines);
                            EDocPOMatching.MatchReceiptLinesToEDocumentLine(TempSelectedReceiptLines, Rec);
                            CurrPage.Update();
                        end;
                    }
                    action(OpenMatchedOrder)
                    {
                        ApplicationArea = All;
                        Caption = 'Open matched order';
                        Image = ViewOrder;
                        ToolTip = 'Opens the matched purchase order.';
                        Scope = Repeater;
                        Enabled = IsLineMatchedToOrderLine;

                        trigger OnAction()
                        begin
                            OpenMatchedPurchaseOrder(Rec);
                        end;
                    }
                    action(OpenMatchedReceipt)
                    {
                        ApplicationArea = All;
                        Caption = 'Open matched receipt';
                        Image = PostedReceipt;
                        ToolTip = 'Opens the matched purchase receipt.';
                        Scope = Repeater;
                        Enabled = IsLineMatchedToReceiptLine;

                        trigger OnAction()
                        var
                            TempPostedReceipts: Record "Purch. Rcpt. Header" temporary;
                            EDocPOMatching: Codeunit "E-Doc. PO Matching";
                            CountReceipts: Integer;
                        begin
                            EDocPOMatching.LoadReceiptsMatchedToEDocumentLine(Rec, TempPostedReceipts);
                            CountReceipts := TempPostedReceipts.Count();
                            if CountReceipts = 0 then
                                exit;
                            if CountReceipts = 1 then begin
                                TempPostedReceipts.FindFirst();
                                Page.Run(Page::"Posted Purchase Receipt", TempPostedReceipts);
                                exit;
                            end;
                            Page.Run(Page::"Posted Purchase Receipts", TempPostedReceipts);
                        end;
                    }
                    action(RemoveMatch)
                    {
                        ApplicationArea = All;
                        Caption = 'Remove match';
                        Image = CancelAllLines;
                        ToolTip = 'Removes any matches between this invoice line and purchase order or receipt lines.';
                        Scope = Repeater;
                        Enabled = IsLineMatchedToOrderLine or IsLineMatchedToReceiptLine;

                        trigger OnAction()
                        var
                            EDocPOMatching: Codeunit "E-Doc. PO Matching";
                        begin
                            EDocPOMatching.RemoveAllMatchesForEDocumentLine(Rec);
                            CurrPage.Update();
                        end;
                    }
                }
                group("Related Information")
                {
                    Caption = 'Related Information';
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
                            Rec.LookupDimensions();
                        end;
                    }
                    action(LookupItemReferences)
                    {
                        ApplicationArea = All;
                        Caption = 'Item References';
                        ToolTip = 'View item references for the vendor associated with this e-document.';
                        Image = Change;

                        trigger OnAction()
                        var
                            ItemReference: Record "Item Reference";
                            ItemReferencePage: Page "Item Reference Entries";
                        begin
                            EDocumentPurchaseHeader.TestField("[BC] Vendor No.");
                            ItemReference.SetRange("Reference Type", ItemReference."Reference Type"::Vendor);
                            ItemReference.SetRange("Reference Type No.", EDocumentPurchaseHeader."[BC] Vendor No.");
                            ItemReferencePage.SetTableView(ItemReference);
                            ItemReferencePage.Run();
                        end;
                    }
                }
            }
        }
    }

    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocumentPOMatchWarnings: Record "E-Doc PO Match Warning";
        EDocPurchaseHistMapping: Codeunit "E-Doc. Purchase Hist. Mapping";
        EDocPOMatching: Codeunit "E-Doc. PO Matching";
        AdditionalColumns, OrderMatchedCaption, MatchWarningsCaption, MatchWarningsStyleExpr : Text;
        LineAmount: Decimal;
        DimVisible1, DimVisible2, HasAdditionalColumns, IsEDocumentMatchedToAnyPOLine, IsLineMatchedToOrderLine, IsLineMatchedToReceiptLine, HasEDocumentOrderMatchWarnings : Boolean;
        HistoryCantBeRetrievedErr: Label 'The purchase invoice that matched historically with this line can''t be opened.';

    trigger OnOpenPage()
    begin
        SetDimensionsVisibility();
        UpdatePOMatching();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(LineAmount);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdatePOMatching();
    end;

    trigger OnAfterGetRecord()
    var
        MissingInfoLbl: Label 'Missing information for match';
        NotYetReceivedLbl: Label 'Not yet received';
        QuantityMismatchLbl: Label 'Quantity mismatch';
        NoWarningsLbl: Label 'No warnings';
    begin
        if EDocumentPurchaseLine.Get(Rec."E-Document Entry No.", Rec."Line No.") then;
        AdditionalColumns := Rec.AdditionalColumnsDisplayText();
        SetHasAdditionalColumns();
        UpdateCalculatedAmounts(false);
        IsLineMatchedToOrderLine := EDocPOMatching.IsEDocumentLineMatchedToAnyPOLine(EDocumentPurchaseLine);
        IsLineMatchedToReceiptLine := EDocPOMatching.IsEDocumentLineMatchedToAnyReceiptLine(EDocumentPurchaseLine);
        OrderMatchedCaption := IsLineMatchedToOrderLine ? GetSummaryOfMatchedOrders() : '';
        MatchWarningsStyleExpr := 'None';
        EDocumentPOMatchWarnings.SetRange("E-Doc. Purchase Line SystemId", Rec.SystemId);
        if EDocumentPOMatchWarnings.FindFirst() then begin
            case EDocumentPOMatchWarnings."Warning Type" of
                Enum::"E-Doc PO Match Warning"::MissingInformationForMatch:
                    MatchWarningsCaption := MissingInfoLbl;
                Enum::"E-Doc PO Match Warning"::NotYetReceived:
                    MatchWarningsCaption := NotYetReceivedLbl;
                Enum::"E-Doc PO Match Warning"::QuantityMismatch:
                    MatchWarningsCaption := QuantityMismatchLbl;
            end;
            MatchWarningsStyleExpr := 'Ambiguous';
        end
        else
            MatchWarningsCaption := NoWarningsLbl;
    end;

    internal procedure SetEDocumentPurchaseHeader(EDocPurchHeader: Record "E-Document Purchase Header")
    begin
        EDocumentPurchaseHeader := EDocPurchHeader;
    end;

    local procedure SetDimensionsVisibility()
    var
        DimMgt: Codeunit DimensionManagement;
        DimOther: Boolean;
    begin
        DimVisible1 := false;
        DimVisible2 := false;

        DimMgt.UseShortcutDims(
          DimVisible1, DimVisible2, DimOther, DimOther, DimOther, DimOther, DimOther, DimOther);
    end;

    local procedure UpdateCalculatedAmounts(UpdateParentRecord: Boolean)
    var
        TotalEDocPurchaseLine: Record "E-Document Purchase Line";
        EDocumentImportHelper: Codeunit "E-Document Import Helper";
        LineSubtotal: Decimal;
        DiscountExceedsSubtotalErr: Label 'Discount should not exceed the subtotal of the line';
    begin
        LineSubtotal := Rec.Quantity * Rec."Unit Price";
        LineAmount := LineSubtotal - Rec."Total Discount";
        if LineSubtotal = 0 then begin
            if Rec."Total Discount" > 0 then
                Error(DiscountExceedsSubtotalErr)
        end
        else
            if Rec."Total Discount" / LineSubtotal > 1 then
                Error(DiscountExceedsSubtotalErr);
        if not UpdateParentRecord then
            exit;
        if not EDocumentPurchaseHeader.Get(Rec."E-Document Entry No.") then
            exit;
        EDocumentPurchaseHeader."Sub Total" := 0;
        TotalEDocPurchaseLine.SetRange("E-Document Entry No.", Rec."E-Document Entry No.");
        if TotalEDocPurchaseLine.FindSet() then
            repeat
                EDocumentPurchaseHeader."Sub Total" += Round(TotalEDocPurchaseLine.Quantity * TotalEDocPurchaseLine."Unit Price", EDocumentImportHelper.GetCurrencyRoundingPrecision(EDocumentPurchaseHeader."Currency Code")) - TotalEDocPurchaseLine."Total Discount";
            until TotalEDocPurchaseLine.Next() = 0;
        EDocumentPurchaseHeader.Total := EDocumentPurchaseHeader."Sub Total" + EDocumentPurchaseHeader."Total VAT" - EDocumentPurchaseHeader."Total Discount";
        EDocumentPurchaseHeader.Modify();
        CurrPage.Update();
    end;

    local procedure SetHasAdditionalColumns()
    var
        EDocPurchLineFieldSetup: Record "ED Purchase Line Field Setup";
    begin
        if EDocPurchLineFieldSetup.IsEmpty() then begin
            HasAdditionalColumns := false;
            exit;
        end;

        if EDocumentPurchaseHeader."[BC] Vendor No." = '' then begin
            HasAdditionalColumns := false;
            exit;
        end;

        if Rec."E-Doc. Purch. Line History Id" = 0 then begin
            HasAdditionalColumns := false;
            exit;
        end;

        HasAdditionalColumns := true;
    end;

    local procedure OpenMatchedPurchaseOrder(SelectedEDocumentPurchaseLine: Record "E-Document Purchase Line")
    var
        TempPurchaseOrders: Record "Purchase Header" temporary;
        PurchaseOrder: Record "Purchase Header";
        CountPOs: Integer;
    begin
        EDocPOMatching.LoadPOsMatchedToEDocumentLine(SelectedEDocumentPurchaseLine, TempPurchaseOrders);
        CountPOs := TempPurchaseOrders.Count();
        if CountPOs = 0 then
            exit;
        if CountPOs = 1 then begin
            TempPurchaseOrders.FindFirst();
            PurchaseOrder.Get(TempPurchaseOrders."Document Type", TempPurchaseOrders."No.");
            Page.Run(Page::"Purchase Order", PurchaseOrder);
            exit;
        end;
        Page.Run(Page::"Purchase Orders", TempPurchaseOrders);
    end;

    local procedure UpdatePOMatching()
    begin
        IsEDocumentMatchedToAnyPOLine := EDocPOMatching.IsEDocumentMatchedToAnyPOLine(EDocumentPurchaseHeader);
        EDocPOMatching.CalculatePOMatchWarnings(EDocumentPurchaseHeader, EDocumentPOMatchWarnings);
        HasEDocumentOrderMatchWarnings := not EDocumentPOMatchWarnings.IsEmpty();
    end;

    local procedure GetSummaryOfMatchedOrders(): Text
    var
        TempLinkedPurchaseLines: Record "Purchase Line" temporary;
        MatchedPO: Code[20];
        MatchedToSingleOrderLbl: Label '%1 - %2', Comment = '%1 - Document No., %2 - Description';
        MatchedToSingleOrderMultipleLinesLbl: Label '%1 (multiple)', Comment = '%1 - Document No.';
        MatchedToMultipleOrdersLbl: Label '%1, %2, ...', Comment = '%1 - First Document No., %2 - Second Document No.';
    begin
        EDocPOMatching.LoadPOLinesMatchedToEDocumentLine(EDocumentPurchaseLine, TempLinkedPurchaseLines);
        if not TempLinkedPurchaseLines.FindFirst() then
            exit('');

        if TempLinkedPurchaseLines.Count() = 1 then
            exit(StrSubstNo(MatchedToSingleOrderLbl, TempLinkedPurchaseLines."Document No.", TempLinkedPurchaseLines.Description));

        MatchedPO := TempLinkedPurchaseLines."Document No.";
        TempLinkedPurchaseLines.SetFilter("Document No.", '<>%1', MatchedPO);

        if TempLinkedPurchaseLines.FindFirst() then
            exit(StrSubstNo(MatchedToMultipleOrdersLbl, MatchedPO, TempLinkedPurchaseLines."Document No."));

        exit(StrSubstNo(MatchedToSingleOrderMultipleLinesLbl, MatchedPO));
    end;

}
