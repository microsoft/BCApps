// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import.Purchase;

using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.Finance.Dimension;
using Microsoft.eServices.EDocument;
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
                field(OrderMatched; OrderMatchedCaption)
                {
                    ApplicationArea = All;
                    Caption = 'Order matched';
                    Editable = false;
                    Visible = IsEDocumentLinkedToAnyPOLine;
                }
                field(MatchWarnings; MatchWarningsCaption)
                {
                    ApplicationArea = All;
                    Caption = 'Match warnings';
                    Editable = false;
                    Visible = HasEDocumentOrderMatchWarnings;
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
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Editable = true;
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
                    action(MatchToOrderLines)
                    {
                        ApplicationArea = All;
                        Caption = 'Match to Order Lines';
                        Image = LinkWithExisting;
                        ToolTip = 'Match this incoming invoice line to purchase order lines.';
                        Scope = Repeater;

                        trigger OnAction()
                        var
                            SelectedPOLines: Record "Purchase Line" temporary;
                            EDocPOMatching: Codeunit "E-Doc. PO Matching";
                            EDocSelectPOLinesPage: Page "E-Doc. Select PO Lines";
                        begin
                            EDocSelectPOLinesPage.SetEDocumentPurchaseLine(Rec);
                            EDocSelectPOLinesPage.LookupMode := true;
                            if EDocSelectPOLinesPage.RunModal() <> Action::LookupOK then
                                exit;
                            EDocSelectPOLinesPage.GetSelectedPOLines(SelectedPOLines);
                            EDocPOMatching.LinkPOLinesToEDocumentLine(SelectedPOLines, Rec);
                            CurrPage.Update();
                        end;
                    }
                    action(SpecifyReceiptLines)
                    {
                        ApplicationArea = All;
                        Caption = 'Specify Receipt Lines';
                        Image = ReceiptLines;
                        ToolTip = 'Specify the corresponding receipt lines to the matched order line.';
                        Scope = Repeater;
                        Enabled = IsLineMatchedToOrderLine;

                        trigger OnAction()
                        var
                            SelectedReceiptLines: Record "Purch. Rcpt. Line" temporary;
                            EDocPOMatching: Codeunit "E-Doc. PO Matching";
                            EDocSelectReceiptLinesPage: Page "E-Doc. Select Receipt Lines";
                        begin
                            EDocSelectReceiptLinesPage.SetEDocumentPurchaseLine(Rec);
                            EDocSelectReceiptLinesPage.LookupMode := true;
                            if EDocSelectReceiptLinesPage.RunModal() <> Action::LookupOK then
                                exit;
                            EDocSelectReceiptLinesPage.GetSelectedReceiptLines(SelectedReceiptLines);
                            EDocPOMatching.LinkReceiptLinesToEDocumentLine(SelectedReceiptLines, Rec);
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
                }
            }
        }
    }

    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocumentPOMatchWarnings: Record "E-Doc PO Match Warnings";
        EDocPurchaseHistMapping: Codeunit "E-Doc. Purchase Hist. Mapping";
        EDocPOMatching: Codeunit "E-Doc. PO Matching";
        AdditionalColumns, OrderMatchedCaption, MatchWarningsCaption : Text;
        LineAmount: Decimal;
        DimVisible1, DimVisible2, HasAdditionalColumns, IsEDocumentLinkedToAnyPOLine, IsLineMatchedToOrderLine, HasEDocumentOrderMatchWarnings : Boolean;
        HistoryCantBeRetrievedErr: Label 'The purchase invoice that matched historically with this line can''t be opened.';

    trigger OnOpenPage()
    begin
        SetDimensionsVisibility();
        if EDocumentPurchaseHeader.Get(Rec."E-Document Entry No.") then;
        IsEDocumentLinkedToAnyPOLine := EDocPOMatching.IsEDocumentLinkedToAnyPOLine(EDocumentPurchaseHeader);
        EDocPOMatching.CalculatePOMatchWarnings(EDocumentPurchaseHeader, EDocumentPOMatchWarnings);

    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(LineAmount);
    end;

    trigger OnAfterGetRecord()
    begin
        if EDocumentPurchaseLine.Get(Rec."E-Document Entry No.", Rec."Line No.") then;
        AdditionalColumns := Rec.AdditionalColumnsDisplayText();
        SetHasAdditionalColumns();
        UpdateCalculatedAmounts(false);
        IsLineMatchedToOrderLine := EDocPOMatching.IsEDocumentLineLinkedToAnyPOLine(EDocumentPurchaseLine);
        OrderMatchedCaption := IsLineMatchedToOrderLine ? GetSummaryOfMatchedOrders() : 'Not matched';
        HasEDocumentOrderMatchWarnings := not EDocumentPOMatchWarnings.IsEmpty();
        MatchWarningsCaption := HasEDocumentOrderMatchWarnings ? 'There are warnings' : 'No warnings';
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
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
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
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
    begin
        if EDocPurchLineFieldSetup.IsEmpty() then begin
            HasAdditionalColumns := false;
            exit;
        end;

        EDocumentPurchaseHeader.Get(Rec."E-Document Entry No.");
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

    local procedure GetSummaryOfMatchedOrders(): Text
    var
        EDocPOMatching: Codeunit "E-Doc. PO Matching";
        LinkedPurchaseLines: Record "Purchase Line" temporary;
        MatchedPO: Code[20];
    begin
        EDocPOMatching.LoadPOLinesLinkedToEDocumentLine(EDocumentPurchaseLine, LinkedPurchaseLines);
        if LinkedPurchaseLines.Count() = 1 then
            exit(StrSubstNo('Matched to order %1 %2', LinkedPurchaseLines."Document No.", LinkedPurchaseLines.Description));
        if LinkedPurchaseLines.FindSet() then
            repeat
                if MatchedPO = '' then
                    MatchedPO := LinkedPurchaseLines."Document No."
                else
                    if MatchedPO <> LinkedPurchaseLines."Document No." then
                        exit(StrSubstNo('Matched to orders %1, %2, ...', MatchedPO, LinkedPurchaseLines."Document No."));
            until LinkedPurchaseLines.Next() = 0;
        exit(StrSubstNo('Matched to order %1 (multiple)', MatchedPO));
    end;

}