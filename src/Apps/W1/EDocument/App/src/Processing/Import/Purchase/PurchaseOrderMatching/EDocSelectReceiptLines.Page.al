// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import.Purchase;

using Microsoft.Purchases.History;

page 6130 "E-Doc. Select Receipt Lines"
{
    ApplicationArea = All;
    Caption = 'Available Receipt Lines';
    PageType = Worksheet;
    SourceTable = "Purch. Rcpt. Line";
    SourceTableTemporary = true;
    Editable = false;
    Extensible = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(LineInInvoice)
            {
                Caption = 'Received invoice line';
                field(EDocumentPurchaseLineDescription; EDocumentPurchaseLine.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the e-document line.';
                }
                field(EDocumentPurchaseLineQuantity; EDocumentPurchaseLine.Quantity)
                {
                    ApplicationArea = All;
                    Caption = 'Quantity';
                    ToolTip = 'Specifies the quantity of the e-document line.';
                }
            }
            repeater(Lines)
            {
                Caption = 'Existing receipt lines';
                field("Order No."; Rec."Order No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the order number of the purchase order.';
                    StyleExpr = StyleExpr;
                }
                field("Order Line No."; Rec."Order Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the line number of the purchase order.';
                    StyleExpr = StyleExpr;
                }
                field("Receipt No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'Receipt No.';
                    ToolTip = 'Specifies the document number of the purchase receipt.';
                    StyleExpr = StyleExpr;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the purchase line.';
                    StyleExpr = StyleExpr;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the quantity of the receipt line.';
                    AutoFormatType = 0;
                }
                field("Quantity Invoiced"; Rec."Quantity Invoiced")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the quantity that has already been invoiced.';
                    AutoFormatType = 0;
                }
            }
        }
    }
    actions
    {
        area(Navigation)
        {
            action(OpenOrder)
            {
                ApplicationArea = All;
                Caption = 'Open posted purchase receipt';
                ToolTip = 'Opens the posted purchase receipt.';
                Image = PostedReceipt;
                Scope = Repeater;

                trigger OnAction()
                var
                    PurchaseReceiptHeader: Record "Purch. Rcpt. Header";
                begin
                    if not PurchaseReceiptHeader.Get(Rec."Document No.") then
                        Error(ReceiptCantBeFoundErr);
                    Page.Run(Page::"Posted Purchase Receipt", PurchaseReceiptHeader);
                end;
            }
        }
        area(Processing)
        {
            action(RemoveMatches)
            {
                ApplicationArea = All;
                Caption = 'Remove receipt matches';
                ToolTip = 'Remove all the receipt matches for the current e-document line';
                Image = RemoveLine;

                trigger OnAction()
                begin
                    EDocPOMatching.RemoveAllReceiptMatchesForEDocumentLine(EDocumentPurchaseLine);
                    CurrPage.Close();
                end;
            }
        }
    }

    var
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocPOMatching: Codeunit "E-Doc. PO Matching";
        StyleExpr: Text;
        ReceiptCantBeFoundErr: Label 'The purchase receipt cannot be found.';

    trigger OnOpenPage()
    begin
        EDocPOMatching.LoadAvailableReceiptLinesForEDocumentLine(EDocumentPurchaseLine, Rec);
    end;

    trigger OnAfterGetRecord()
    begin
        StyleExpr := EDocPOMatching.IsReceiptLineMatchedToEDocumentLine(Rec, EDocumentPurchaseLine) ? 'Strong' : '';
    end;

    internal procedure SetEDocumentPurchaseLine(EDocumentPurchaseLineLocal: Record "E-Document Purchase Line")
    begin
        EDocumentPurchaseLine := EDocumentPurchaseLineLocal;
    end;

    internal procedure GetSelectedReceiptLines(var SelectedReceiptLines: Record "Purch. Rcpt. Line" temporary)
    begin
        CurrPage.SetSelectionFilter(Rec);
        if Rec.FindSet() then
            repeat
                Clear(SelectedReceiptLines);
                SelectedReceiptLines := Rec;
                SelectedReceiptLines.Insert();
            until Rec.Next() = 0;
    end;

}