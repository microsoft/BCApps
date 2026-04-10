// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Request;

page 5793 "Source Documents"
{
    Caption = 'Source Documents';
    DataCaptionFields = Type, "Location Code";
    Editable = false;
    PageType = List;
    SourceTable = "Warehouse Request";
    SourceTableView = sorting(Type, "Location Code", "Completely Handled", "Document Status", "Expected Receipt Date", "Shipment Date", "Source Document", "Source No.");

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Visible = false;
                }
                field("Expected Receipt Date"; Rec."Expected Receipt Date")
                {
                    ApplicationArea = Warehouse;
                    Visible = ExpectedReceiptDateVisible;
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = Warehouse;
                    Visible = ShipmentDateVisible;
                }
                field("Put-away / Pick No."; Rec."Put-away / Pick No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Source Document"; Rec."Source Document")
                {
                    ApplicationArea = Warehouse;
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Destination Type"; Rec."Destination Type")
                {
                    ApplicationArea = Warehouse;
                }
                field("Destination No."; Rec."Destination No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("Shipping Advice"; Rec."Shipping Advice")
                {
                    ApplicationArea = Warehouse;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
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
                action(Card)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';

                    trigger OnAction()
                    begin
                        Rec.ShowSourceDocumentCard();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Card_Promoted; Card)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateVisible();
    end;

    trigger OnInit()
    begin
        ShipmentDateVisible := true;
        ExpectedReceiptDateVisible := true;
    end;

    var
        ExpectedReceiptDateVisible: Boolean;
        ShipmentDateVisible: Boolean;

    procedure GetResult(var WhseReq: Record "Warehouse Request")
    begin
        CurrPage.SetSelectionFilter(WhseReq);
    end;

    local procedure UpdateVisible()
    begin
        ExpectedReceiptDateVisible := Rec.Type = Rec.Type::Inbound;
        ShipmentDateVisible := Rec.Type = Rec.Type::Outbound;
    end;

}

