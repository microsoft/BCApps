// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Finance.Dimension;
using Microsoft.Purchases.Document;

page 5806 "Purch. Receipt Lines"
{
    Caption = 'Purch. Receipt Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Purch. Rcpt. Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    HideValue = DocumentNoHideValue;
                    StyleExpr = 'Strong';
                }
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of a list of purchases that were posted.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many units were posted as received or received and invoiced.';
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Unit Cost (LCY)"; Rec."Unit Cost (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the cost, in LCY, of one unit of the item or resource on the line.';
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
                field("Indirect Cost %"; Rec."Indirect Cost %")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Quantity Invoiced"; Rec."Quantity Invoiced")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Order No."; Rec."Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Order Line No."; Rec."Order Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Vendor Item No."; Rec."Vendor Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
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
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Document';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the selected line exists on.';

                    trigger OnAction()
                    var
                        PurchRcptHeader: Record "Purch. Rcpt. Header";
                    begin
                        PurchRcptHeader.Get(Rec."Document No.");
                        PAGE.Run(PAGE::"Posted Purchase Receipt", PurchRcptHeader);
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
                        CurrPage.SaveRecord();
                    end;
                }
                action("Item &Tracking Lines")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    ShortCutKey = 'Ctrl+Alt+I';
                    ToolTip = 'View or edit serial, lot and package numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    begin
                        Rec.ShowItemTrackingLines();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Show Document_Promoted"; "Show Document")
                {
                }
                actionref("Item &Tracking Lines_Promoted"; "Item &Tracking Lines")
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Line', Comment = 'Generated from the PromotedActionCategories property index 3.';
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DocumentNoHideValue := false;
        DocumentNoOnFormat();
    end;

    trigger OnInit()
    begin
        CurrPage.LookupMode := true;
    end;

    trigger OnOpenPage()
    begin
        Rec.FilterGroup(2);
        Rec.SetRange(Type, Rec.Type::Item);
        Rec.SetFilter(Quantity, '<>0');
        Rec.SetRange(Correction, false);
        Rec.FilterGroup(0);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            LookupOKOnPush();
    end;

    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        FromPurchRcptLine: Record "Purch. Rcpt. Line";
        TempPurchRcptLine: Record "Purch. Rcpt. Line" temporary;
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        AssignItemChargePurch: Codeunit "Item Charge Assgnt. (Purch.)";
        UnitCost: Decimal;
        DocumentNoHideValue: Boolean;

    procedure Initialize(NewItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; NewUnitCost: Decimal)
    begin
        ItemChargeAssgntPurch := NewItemChargeAssgntPurch;
        UnitCost := NewUnitCost;
        OnAfterInitialize(ItemChargeAssgntPurch, UnitCost);
    end;

    local procedure IsFirstDocLine(): Boolean
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        TempPurchRcptLine.Reset();
        TempPurchRcptLine.CopyFilters(Rec);
        TempPurchRcptLine.SetRange("Document No.", Rec."Document No.");
        if not TempPurchRcptLine.FindFirst() then begin
            Rec.FilterGroup(2);
            PurchRcptLine.CopyFilters(Rec);
            Rec.FilterGroup(0);
            PurchRcptLine.SetRange("Document No.", Rec."Document No.");
            if not PurchRcptLine.FindFirst() then
                exit(false);
            TempPurchRcptLine := PurchRcptLine;
            TempPurchRcptLine.Insert();
        end;
        if Rec."Line No." = TempPurchRcptLine."Line No." then
            exit(true);
    end;

    local procedure LookupOKOnPush()
    begin
        FromPurchRcptLine.Copy(Rec);
        CurrPage.SetSelectionFilter(FromPurchRcptLine);
        if FromPurchRcptLine.FindFirst() then begin
            ItemChargeAssgntPurch."Unit Cost" := UnitCost;
            AssignItemChargePurch.CreateRcptChargeAssgnt(FromPurchRcptLine, ItemChargeAssgntPurch);
        end;
    end;

    local procedure DocumentNoOnFormat()
    begin
        if not IsFirstDocLine() then
            DocumentNoHideValue := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitialize(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; var UnitCost: Decimal)
    begin
    end;
}

