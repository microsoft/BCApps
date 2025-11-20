// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Archive;

page 6626 "Purchase Line Archive List"
{
    Caption = 'Purchase Line Archive List';
    Editable = false;
    PageType = List;
    SourceTable = "Purchase Line Archive";

    layout
    {
        area(content)
        {
            repeater(Control14)
            {
                ShowCaption = false;
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of purchase document.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the document number.';
                }
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the vendor who delivered the items.';
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the line.';
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry type.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the archived purchase line.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the record.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies information in addition to the description.';
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies a code for the location where you want the items to be placed when they are received.';
                    Visible = false;
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unit of measure used for the item, for example bottle or piece.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity of the record.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum of amounts in the Line Amount field on the purchase lines.';
                }
                field("Amount Including VAT"; Rec."Amount Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the net amount, including VAT, for this line.';
                }
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
                action(ShowDocument)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Document';
                    Image = View;
                    ToolTip = 'View the related document.';

                    trigger OnAction()
                    var
                        PurchaseHeaderArchive: Record "Purchase Header Archive";
                    begin
                        PurchaseHeaderArchive.Get(Rec."Document Type", Rec."Document No.", Rec."Doc. No. Occurrence", Rec."Version No.");
                        case Rec."Document Type" of
                            Rec."Document Type"::Order:
                                PAGE.Run(PAGE::"Purchase Order Archive", PurchaseHeaderArchive);
                            Rec."Document Type"::Quote:
                                PAGE.Run(PAGE::"Purchase Quote Archive", PurchaseHeaderArchive);
                            Rec."Document Type"::"Blanket Order":
                                PAGE.Run(PAGE::"Blanket Purchase Order Archive", PurchaseHeaderArchive);
                            Rec."Document Type"::"Return Order":
                                PAGE.Run(PAGE::"Purchase Return Order Archive", PurchaseHeaderArchive);
                        end;
                    end;
                }
            }
        }
    }
}

