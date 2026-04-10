// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Item.Catalog;

/// <summary>
/// Displays the line items of a posted sales return receipt as a subform on the document page.
/// </summary>
page 6661 "Posted Return Receipt Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Return Receipt Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = SalesReturnOrder;
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
                field(Description; Rec.Description)
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies a description of the return receipt posted';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Return Reason Code"; Rec."Return Reason Code")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = SalesReturnOrder;
                    BlankZero = true;
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
                field("Quantity Invoiced"; Rec."Quantity Invoiced")
                {
                    ApplicationArea = SalesReturnOrder;
                    BlankZero = true;
                }
                field("Return Qty. Rcd. Not Invd."; Rec."Return Qty. Rcd. Not Invd.")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Appl.-to Item Entry"; Rec."Appl.-to Item Entry")
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
                field("Gross Weight"; Rec."Gross Weight")
                {
                    Caption = 'Unit Gross Weight';
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Net Weight"; Rec."Net Weight")
                {
                    Caption = 'Unit Net Weight';
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Unit Volume"; Rec."Unit Volume")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Units per Parcel"; Rec."Units per Parcel")
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
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("&Undo Return Receipt")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = '&Undo Return Receipt';
                    Image = Undo;
                    ToolTip = 'Undo the quantity posting made with the return receipt. A corrective line is inserted in the posted document and the Returned Qty. Received and Return Qty. Rcd. Not Invd. fields on the return order are set to zero.';

                    trigger OnAction()
                    begin
                        UndoReturnReceipt();
                    end;
                }
            }
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
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
                action(Comments)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    ToolTip = 'View or add comments for the record.';

                    trigger OnAction()
                    begin
                        Rec.ShowLineComments();
                    end;
                }
                action(DocumentLineTracking)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document &Line Tracking';
                    Image = Navigate;
                    ToolTip = 'View related open, posted, or archived documents or document lines.';

                    trigger OnAction()
                    begin
                        ShowDocumentLineTracking();
                    end;
                }
                action(ItemTrackingEntries)
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
                action(ItemCreditMemoLines)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Item Credit Memo &Lines';
                    Image = CreditMemo;
                    ToolTip = 'View the related credit memo lines.';

                    trigger OnAction()
                    begin
                        PageShowItemSalesCrMemoLines();
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
    end;

    local procedure UndoReturnReceipt()
    var
        ReturnRcptLine: Record "Return Receipt Line";
    begin
        ReturnRcptLine.Copy(Rec);
        CurrPage.SetSelectionFilter(ReturnRcptLine);
        CODEUNIT.Run(CODEUNIT::"Undo Return Receipt Line", ReturnRcptLine);
    end;

    local procedure PageShowItemSalesCrMemoLines()
    begin
        Rec.TestField(Type, Rec.Type::Item);
        Rec.ShowItemSalesCrMemoLines();
    end;

    /// <summary>
    /// Opens the document line tracking page for this return receipt line.
    /// </summary>
    procedure ShowDocumentLineTracking()
    var
        DocumentLineTrackingPage: Page "Document Line Tracking";
    begin
        Clear(DocumentLineTrackingPage);
        DocumentLineTrackingPage.SetSourceDoc(
            "Document Line Source Type"::"Return Receipt", Rec."Document No.", Rec."Line No.", Rec."Return Order No.", Rec."Return Order Line No.", '', 0);
        DocumentLineTrackingPage.RunModal();
    end;
}

