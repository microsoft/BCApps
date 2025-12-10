// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import.Purchase;

using Microsoft.Purchases.Document;

page 6116 "E-Doc. Select PO Lines"
{
    ApplicationArea = All;
    Caption = 'Available Purchase Order Lines';
    PageType = List;
    SourceTable = "Purchase Line";
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
                Caption = 'Existing order lines';
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the document number of the purchase order.';
                    StyleExpr = StyleExpr;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of the purchase line.';
                    StyleExpr = StyleExpr;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the item, resource, or G/L account.';
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
                    ToolTip = 'Specifies the quantity ordered.';
                    AutoFormatType = 0;
                }
                field("Quantity Received"; Rec."Quantity Received")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the quantity that has already been received.';
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
                Caption = 'Open purchase order';
                ToolTip = 'Opens the purchase order.';
                Image = ViewOrder;
                Scope = Repeater;

                trigger OnAction()
                var
                    PurchaseHeader: Record "Purchase Header";
                begin
                    if not PurchaseHeader.Get("Purchase Document Type"::Order, Rec."Document No.") then
                        Error(POCantBeFoundErr);
                    Page.Run(Page::"Purchase Order", PurchaseHeader);
                end;
            }
        }
        area(Processing)
        {
            action(RemoveMatches)
            {
                ApplicationArea = All;
                Caption = 'Remove matches';
                ToolTip = 'Remove all the matches for the current e-document line';
                Image = RemoveLine;

                trigger OnAction()
                begin
                    EDocPOMatching.RemoveAllMatchesForEDocumentLine(EDocumentPurchaseLine);
                    CurrPage.Close();
                end;
            }
        }
    }

    var
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocPOMatching: Codeunit "E-Doc. PO Matching";
        StyleExpr: Text;
        POCantBeFoundErr: Label 'The purchase order can''t be found.';

    trigger OnOpenPage()
    begin
        EDocPOMatching.LoadAvailablePOLinesForEDocumentLine(EDocumentPurchaseLine, Rec);
    end;

    trigger OnAfterGetRecord()
    begin
        StyleExpr := EDocPOMatching.IsPOLineMatchedToEDocumentLine(Rec, EDocumentPurchaseLine) ? 'Strong' : '';
    end;

    internal procedure SetEDocumentPurchaseLine(EDocumentPurchaseLineLocal: Record "E-Document Purchase Line")
    begin
        EDocumentPurchaseLine := EDocumentPurchaseLineLocal;
    end;

    internal procedure GetSelectedPOLines(var SelectedPurchaseLines: Record "Purchase Line" temporary)
    begin
        CurrPage.SetSelectionFilter(Rec);
        if Rec.FindSet() then
            repeat
                Clear(SelectedPurchaseLines);
                SelectedPurchaseLines := Rec;
                SelectedPurchaseLines.Insert();
            until Rec.Next() = 0;
    end;

}