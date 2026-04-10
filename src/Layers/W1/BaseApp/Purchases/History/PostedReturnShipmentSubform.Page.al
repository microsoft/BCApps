// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Item.Catalog;

page 6651 "Posted Return Shipment Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Return Shipment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = PurchReturnOrder;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = PurchReturnOrder;
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
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies a description of the shipment that was returned to vendor, that was posted';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Return Reason Code"; Rec."Return Reason Code")
                {
                    ApplicationArea = PurchReturnOrder;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = PurchReturnOrder;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = PurchReturnOrder;
                    Visible = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = PurchReturnOrder;
                    BlankZero = true;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = PurchReturnOrder;
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = PurchReturnOrder;
                    Visible = false;
                }
                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    ApplicationArea = PurchReturnOrder;
                    BlankZero = true;
                }
                field("Quantity Invoiced"; Rec."Quantity Invoiced")
                {
                    ApplicationArea = PurchReturnOrder;
                }
                field("Return Qty. Shipped Not Invd."; Rec."Return Qty. Shipped Not Invd.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies the quantity from the line that has been posted as shipped but that has not yet been posted as invoiced.';
                    Visible = false;
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Visible = false;
                }
                field("Appl.-to Item Entry"; Rec."Appl.-to Item Entry")
                {
                    ApplicationArea = PurchReturnOrder;
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
                field(Correction; Rec.Correction)
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    Enabled = true;
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
                action("&Undo Return Shipment")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = '&Undo Return Shipment';
                    Image = UndoShipment;
                    ToolTip = 'Undo the quantity posting made with the return shipment. A corrective line is inserted in the posted document, and the Return Qty. Shipped and Return Shpd. Not Invd. fields on the return order are set to zero.';

                    trigger OnAction()
                    begin
                        UndoReturnShipment();
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
                    ApplicationArea = PurchReturnOrder;
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
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Item Credit Memo &Lines';
                    Image = CreditMemo;
                    ToolTip = 'View the related credit memo lines.';

                    trigger OnAction()
                    begin
                        PageShowItemPurchCrMemoLines();
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
    end;

    local procedure UndoReturnShipment()
    var
        ReturnShptLine: Record "Return Shipment Line";
    begin
        ReturnShptLine.Copy(Rec);
        CurrPage.SetSelectionFilter(ReturnShptLine);
        CODEUNIT.Run(CODEUNIT::"Undo Return Shipment Line", ReturnShptLine);
    end;

    local procedure PageShowItemPurchCrMemoLines()
    begin
        Rec.TestField(Type, Rec.Type::Item);
        Rec.ShowItemPurchCrMemoLines();
    end;

    procedure ShowDocumentLineTracking()
    var
        DocumentLineTrackingPage: Page "Document Line Tracking";
    begin
        Clear(DocumentLineTrackingPage);
        DocumentLineTrackingPage.SetSourceDoc(
            "Document Line Source Type"::"Return Shipment", Rec."Document No.", Rec."Line No.", Rec."Return Order No.", Rec."Return Order Line No.", '', 0);
        DocumentLineTrackingPage.RunModal();
    end;
}

