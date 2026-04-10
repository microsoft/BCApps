// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

using Microsoft.Finance.Dimension;
using Microsoft.Service.Document;

page 5994 "Get Service Shipment Lines"
{
    Caption = 'Get Service Shipment Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Service Shipment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Service;
                    HideValue = DocumentNoHideValue;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                }
                field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = Service;
                    Visible = true;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Service;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Service;
                    Importance = Additional;
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Service;
                    DrillDown = false;
                    Lookup = false;
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
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location from where inventory items to the customer on the sales document are to be shipped by default.';
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Service;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Service;
                }
                field("Qty. Shipped Not Invoiced"; Rec."Qty. Shipped Not Invoiced")
                {
                    ApplicationArea = Service;
                }
                field("Quantity Invoiced"; Rec."Quantity Invoiced")
                {
                    ApplicationArea = Service;
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Appl.-to Item Entry"; Rec."Appl.-to Item Entry")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Order No."; Rec."Order No.")
                {
                    Caption = 'Order No.';
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service order that this shipment was posted from.';
                    Visible = false;
                }
                field("External Document No."; Rec."External Document No.")
                {
                    Caption = 'External Document No.';
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number that the customer uses in their own system to refer to this service document.';
                    Visible = false;
                }
                field("Your Reference"; Rec."Your Reference")
                {
                    Caption = 'Your Reference';
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the reference information that the customer uses in their own system to refer to this service document.';
                    Visible = false;
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
                action("Show Document")
                {
                    ApplicationArea = Service;
                    Caption = 'Show Document';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the selected line exists on.';

                    trigger OnAction()
                    begin
                        ServiceShptHeader.Get(Rec."Document No.");
                        PAGE.Run(PAGE::"Posted Service Shipment", ServiceShptHeader);
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
                        Rec.ShowDimensions();
                    end;
                }
                action("Item &Tracking Entries")
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
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        StyleIsStrong := IsFirstDocLine();
        DocumentNoHideValue := not IsFirstDocLine();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then
            OKOnPush();
    end;

    var
        ServiceShptHeader: Record "Service Shipment Header";
        ServiceHeader: Record "Service Header";
        TempServiceShptLine: Record "Service Shipment Line" temporary;
        ServiceGetShpt: Codeunit "Service-Get Shipment";
        StyleIsStrong: Boolean;
        DocumentNoHideValue: Boolean;

    procedure SetServiceHeader(var ServiceHeader2: Record "Service Header")
    begin
        ServiceHeader.Get(ServiceHeader2."Document Type", ServiceHeader2."No.");
        ServiceHeader.TestField("Document Type", ServiceHeader."Document Type"::Invoice);
    end;

    local procedure IsFirstDocLine(): Boolean
    var
        ServiceShptLine: Record "Service Shipment Line";
    begin
        TempServiceShptLine.Reset();
        TempServiceShptLine.CopyFilters(Rec);
        TempServiceShptLine.SetRange("Document No.", Rec."Document No.");
        if not TempServiceShptLine.FindFirst() then begin
            ServiceShptLine.CopyFilters(Rec);
            ServiceShptLine.SetRange("Document No.", Rec."Document No.");
            if not ServiceShptLine.FindFirst() then
                exit(false);
            TempServiceShptLine := ServiceShptLine;
            TempServiceShptLine.Insert();
        end;
        if Rec."Line No." = TempServiceShptLine."Line No." then
            exit(true);
    end;

    local procedure OKOnPush()
    begin
        GetShipmentLines();
        CurrPage.Close();
    end;

    procedure GetShipmentLines()
    begin
        CurrPage.SetSelectionFilter(Rec);
        ServiceGetShpt.SetServiceHeader(ServiceHeader);
        ServiceGetShpt.CreateInvLines(Rec);
    end;
}

