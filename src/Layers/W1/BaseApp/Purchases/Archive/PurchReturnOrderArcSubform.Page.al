// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Archive;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Item.Catalog;

page 6645 "Purch Return Order Arc Subform"
{
    Caption = 'Lines';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Purchase Line Archive";
    SourceTableView = where("Document Type" = const("Return Order"));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Advanced;
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
                field(Nonstock; Rec.Nonstock)
                {
                    ApplicationArea = PurchReturnOrder;
                    Visible = false;
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = PurchReturnOrder;
                    Visible = false;
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = PurchReturnOrder;
                    Visible = false;
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = PurchReturnOrder;
                    Visible = false;
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = PurchReturnOrder;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies a description of the purchase return order. ';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = PurchReturnOrder;
                    Importance = Additional;
                    Visible = false;
                }
                field("Drop Shipment"; Rec."Drop Shipment")
                {
                    ApplicationArea = PurchReturnOrder;
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
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = PurchReturnOrder;
                    BlankZero = true;
                    ToolTip = 'Specifies how many units are being returned.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Suite;
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    ApplicationArea = PurchReturnOrder;
                    BlankZero = true;
                }
                field("Indirect Cost %"; Rec."Indirect Cost %")
                {
                    ApplicationArea = PurchReturnOrder;
                    Visible = false;
                }
                field("Unit Cost (LCY)"; Rec."Unit Cost (LCY)")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the cost, in LCY, of one unit of the item or resource on the line.';
                    Visible = false;
                }
                field("Unit Price (LCY)"; Rec."Unit Price (LCY)")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the price, in LCY, of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
                    Visible = false;
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = PurchReturnOrder;
                    BlankZero = true;
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = PurchReturnOrder;
                    BlankZero = true;
                }
                field("Return Qty. to Ship"; Rec."Return Qty. to Ship")
                {
                    ApplicationArea = PurchReturnOrder;
                    BlankZero = true;
                }
                field("Return Qty. Shipped"; Rec."Return Qty. Shipped")
                {
                    ApplicationArea = PurchReturnOrder;
                    BlankZero = true;
                }
                field("Line Discount Amount"; Rec."Line Discount Amount")
                {
                    ApplicationArea = PurchReturnOrder;
                    Visible = false;
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Visible = false;
                }
                field("Inv. Discount Amount"; Rec."Inv. Discount Amount")
                {
                    ApplicationArea = PurchReturnOrder;
                    Visible = false;
                }
                field("Qty. to Receive"; Rec."Qty. to Receive")
                {
                    ApplicationArea = PurchReturnOrder;
                    BlankZero = true;
                }
                field("Quantity Received"; Rec."Quantity Received")
                {
                    ApplicationArea = PurchReturnOrder;
                    BlankZero = true;
                }
                field("Qty. to Invoice"; Rec."Qty. to Invoice")
                {
                    ApplicationArea = PurchReturnOrder;
                    BlankZero = true;
                }
                field("Quantity Invoiced"; Rec."Quantity Invoiced")
                {
                    ApplicationArea = PurchReturnOrder;
                    BlankZero = true;
                }
                field("Allow Item Charge Assignment"; Rec."Allow Item Charge Assignment")
                {
                    ApplicationArea = PurchReturnOrder;
                    Visible = false;
                }
                field("Requested Receipt Date"; Rec."Requested Receipt Date")
                {
                    ApplicationArea = PurchReturnOrder;
                    Visible = false;
                }
                field("Promised Receipt Date"; Rec."Promised Receipt Date")
                {
                    ApplicationArea = PurchReturnOrder;
                    Visible = false;
                }
                field("Planned Receipt Date"; Rec."Planned Receipt Date")
                {
                    ApplicationArea = PurchReturnOrder;
                }
                field("Expected Receipt Date"; Rec."Expected Receipt Date")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the date on which the received items were expected.';
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = PurchReturnOrder;
                }
                field("Lead Time Calculation"; Rec."Lead Time Calculation")
                {
                    ApplicationArea = PurchReturnOrder;
                    Visible = false;
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the related project.';
                    Visible = false;
                }
                field("Planning Flexibility"; Rec."Planning Flexibility")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Inbound Whse. Handling Time"; Rec."Inbound Whse. Handling Time")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Blanket Order No."; Rec."Blanket Order No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Visible = false;
                }
                field("Blanket Order Line No."; Rec."Blanket Order Line No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Visible = false;
                }
                field("Appl.-to Item Entry"; Rec."Appl.-to Item Entry")
                {
                    ApplicationArea = PurchReturnOrder;
                    Visible = false;
                }
                field("Deferral Code"; Rec."Deferral Code")
                {
                    ApplicationArea = PurchReturnOrder;
                }
                field("Returns Deferral Start Date"; Rec."Returns Deferral Start Date")
                {
                    ApplicationArea = PurchReturnOrder;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = DimVisible1;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = DimVisible2;
                }
                field(ShortcutDimCode3; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension value code that is linked to the purchase line archive';
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(3),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible3;
                }
                field(ShortcutDimCode4; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension value code that is linked to the purchase line archive';
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(4),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible4;
                }
                field(ShortcutDimCode5; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension value code that is linked to the purchase line archive';
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(5),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible5;
                }
                field(ShortcutDimCode6; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension value code that is linked to the purchase line archive';
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(6),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible6;
                }
                field(ShortcutDimCode7; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension value code that is linked to the purchase line archive';
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(7),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible7;
                }
                field(ShortcutDimCode8; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension value code that is linked to the purchase line archive';
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(8),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible8;
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
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    ToolTip = 'View or add comments for the record.';

                    trigger OnAction()
                    begin
                        Rec.ShowLineComments();
                    end;
                }
                action("Document &Line Tracking")
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
                action(DeferralSchedule)
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Deferral Schedule';
                    Image = PaymentPeriod;
                    ToolTip = 'View the deferral schedule that governs how expenses paid with this purchase document were deferred to different accounting periods when the document was posted.';

                    trigger OnAction()
                    begin
                        Rec.ShowDeferrals();
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetDimensionsVisibility();
    end;

    trigger OnAfterGetRecord()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    protected var
        ShortcutDimCode: array[8] of Code[20];
        DimVisible1: Boolean;
        DimVisible2: Boolean;
        DimVisible3: Boolean;
        DimVisible4: Boolean;
        DimVisible5: Boolean;
        DimVisible6: Boolean;
        DimVisible7: Boolean;
        DimVisible8: Boolean;

    procedure ShowDocumentLineTracking()
    var
        DocumentLineTracking: Page "Document Line Tracking";
    begin
        Clear(DocumentLineTracking);
        DocumentLineTracking.SetSourceDoc(
            "Document Line Source Type"::"Purchase Return Order", Rec."Document No.", Rec."Line No.", Rec."Blanket Order No.", Rec."Blanket Order Line No.", '', 0);
        DocumentLineTracking.RunModal();
    end;

    local procedure SetDimensionsVisibility()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimVisible1 := false;
        DimVisible2 := false;
        DimVisible3 := false;
        DimVisible4 := false;
        DimVisible5 := false;
        DimVisible6 := false;
        DimVisible7 := false;
        DimVisible8 := false;

        DimMgt.UseShortcutDims(
          DimVisible1, DimVisible2, DimVisible3, DimVisible4, DimVisible5, DimVisible6, DimVisible7, DimVisible8);

        Clear(DimMgt);
    end;
}

