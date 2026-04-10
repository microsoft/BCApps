// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Finance.Dimension;
using Microsoft.Purchases.Document;

page 6657 "Return Shipment Lines"
{
    Caption = 'Return Shipment Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Return Shipment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    HideValue = DocumentNoHideValue;
                    StyleExpr = 'Strong';
                }
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.")
                {
                    ApplicationArea = PurchReturnOrder;
                }
                field("Buy-from Vendor Name"; Rec."Buy-from Vendor Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = PurchReturnOrder;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = PurchReturnOrder;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = PurchReturnOrder;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = All;
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
                    ApplicationArea = PurchReturnOrder;
                    Visible = true;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = PurchReturnOrder;
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
                field("Appl.-to Item Entry"; Rec."Appl.-to Item Entry")
                {
                    ApplicationArea = PurchReturnOrder;
                    Visible = false;
                }
                field("Return Order No."; Rec."Return Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Visible = false;
                }
                field("Quantity Invoiced"; Rec."Quantity Invoiced")
                {
                    ApplicationArea = PurchReturnOrder;
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
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Show Document';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the selected line exists on.';

                    trigger OnAction()
                    var
                        ReturnShptHeader: Record "Return Shipment Header";
                    begin
                        ReturnShptHeader.Get(Rec."Document No.");
                        PAGE.Run(PAGE::"Posted Return Shipment", ReturnShptHeader);
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
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DocumentNoHideValue := false;
        DocumentNoOnFormat();
    end;

    trigger OnOpenPage()
    begin
        Rec.FilterGroup(2);
        Rec.SetRange(Type, Rec.Type::Item);
        Rec.SetFilter(Quantity, '<>0');
        Rec.SetRange(Correction, false);
        Rec.SetRange("Job No.", '');
        OnOpenPageOnSetFilters(Rec);
        Rec.FilterGroup(0);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            LookupOKOnPush();
    end;

    var
        FromReturnShptLine: Record "Return Shipment Line";
        TempReturnShptLine: Record "Return Shipment Line" temporary;
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        AssignItemChargePurch: Codeunit "Item Charge Assgnt. (Purch.)";
        UnitCost: Decimal;
        DocumentNoHideValue: Boolean;

    procedure Initialize(NewItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; NewUnitCost: Decimal)
    begin
        ItemChargeAssgntPurch := NewItemChargeAssgntPurch;
        UnitCost := NewUnitCost;
    end;

    local procedure IsFirstLine(DocNo: Code[20]; LineNo: Integer): Boolean
    var
        ReturnShptLine: Record "Return Shipment Line";
    begin
        TempReturnShptLine.Reset();
        TempReturnShptLine.CopyFilters(Rec);
        TempReturnShptLine.SetRange("Document No.", DocNo);
        if not TempReturnShptLine.FindFirst() then begin
            ReturnShptLine.CopyFilters(Rec);
            ReturnShptLine.SetRange("Document No.", DocNo);
            ReturnShptLine.FindFirst();
            TempReturnShptLine := ReturnShptLine;
            TempReturnShptLine.Insert();
        end;
        if TempReturnShptLine."Line No." = LineNo then
            exit(true);
    end;

    local procedure LookupOKOnPush()
    begin
        FromReturnShptLine.Copy(Rec);
        CurrPage.SetSelectionFilter(FromReturnShptLine);
        if FromReturnShptLine.FindFirst() then begin
            ItemChargeAssgntPurch."Unit Cost" := UnitCost;
            AssignItemChargePurch.CreateShptChargeAssgnt(FromReturnShptLine, ItemChargeAssgntPurch);
        end;
    end;

    local procedure DocumentNoOnFormat()
    begin
        if not IsFirstLine(Rec."Document No.", Rec."Line No.") then
            DocumentNoHideValue := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenPageOnSetFilters(var ReturnShipmentLine: Record "Return Shipment Line")
    begin
    end;
}

