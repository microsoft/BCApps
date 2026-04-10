// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Finance.Dimension;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Utilities;

/// <summary>
/// Lists posted sales shipment lines with navigation to related sales and purchase documents.
/// </summary>
page 5824 "Sales Shipment Lines"
{
    Caption = 'Sales Shipment Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Sales Shipment Line";

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
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
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
                    ApplicationArea = Basic, Suite;
                    Visible = true;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Appl.-to Item Entry"; Rec."Appl.-to Item Entry")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Quantity Invoiced"; Rec."Quantity Invoiced")
                {
                    ApplicationArea = Basic, Suite;
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
                        SalesShptHeader: Record "Sales Shipment Header";
                        PageManagement: Codeunit "Page Management";
                    begin
                        SalesShptHeader.Get(Rec."Document No.");
                        PageManagement.PageRun(SalesShptHeader);
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
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Show Document_Promoted"; "Show Document")
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
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
        if AssignmentType = AssignmentType::Sale then begin
            Rec.SetCurrentKey("Sell-to Customer No.");
            Rec.SetRange("Sell-to Customer No.", SellToCustomerNo);
        end;
        Rec.FilterGroup(2);
        SetFilters();
        Rec.FilterGroup(0);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            LookupOKOnPush();
    end;

    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        FromSalesShptLine: Record "Sales Shipment Line";
        TempSalesShptLine: Record "Sales Shipment Line" temporary;
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        AssignItemChargePurch: Codeunit "Item Charge Assgnt. (Purch.)";
        AssignItemChargeSales: Codeunit "Item Charge Assgnt. (Sales)";
        SellToCustomerNo: Code[20];
        UnitCost: Decimal;
        AssignmentType: Option Sale,Purchase;
        DocumentNoHideValue: Boolean;

    /// <summary>
    /// Initializes the page for sales item charge assignment.
    /// </summary>
    /// <param name="NewItemChargeAssgnt">The sales item charge assignment to initialize from.</param>
    /// <param name="NewSellToCustomerNo">The sell-to customer number.</param>
    /// <param name="NewUnitCost">The unit cost for the charge assignment.</param>
    procedure InitializeSales(NewItemChargeAssgnt: Record "Item Charge Assignment (Sales)"; NewSellToCustomerNo: Code[20]; NewUnitCost: Decimal)
    begin
        ItemChargeAssgntSales := NewItemChargeAssgnt;
        SellToCustomerNo := NewSellToCustomerNo;
        UnitCost := NewUnitCost;
        AssignmentType := AssignmentType::Sale;
    end;

    /// <summary>
    /// Initializes the page for purchase item charge assignment.
    /// </summary>
    /// <param name="NewItemChargeAssgnt">The purchase item charge assignment to initialize from.</param>
    /// <param name="NewUnitCost">The unit cost for the charge assignment.</param>
    procedure InitializePurchase(NewItemChargeAssgnt: Record "Item Charge Assignment (Purch)"; NewUnitCost: Decimal)
    begin
        ItemChargeAssgntPurch := NewItemChargeAssgnt;
        UnitCost := NewUnitCost;
        AssignmentType := AssignmentType::Purchase;
    end;

    local procedure IsFirstLine(DocNo: Code[20]; LineNo: Integer): Boolean
    var
        SalesShptLine: Record "Sales Shipment Line";
    begin
        TempSalesShptLine.Reset();
        TempSalesShptLine.CopyFilters(Rec);
        TempSalesShptLine.SetRange("Document No.", DocNo);
        if not TempSalesShptLine.FindFirst() then begin
            SalesShptLine.CopyFilters(Rec);
            SalesShptLine.SetRange("Document No.", DocNo);
            if SalesShptLine.FindFirst() then begin
                TempSalesShptLine := SalesShptLine;
                TempSalesShptLine.Insert();
            end;
        end;
        if TempSalesShptLine."Line No." = LineNo then
            exit(true);
    end;

    local procedure SetFilters()
    begin
        Rec.SetRange(Type, Rec.Type::Item);
        Rec.SetFilter(Quantity, '<>0');
        Rec.SetRange(Correction, false);
        Rec.SetRange("Job No.", '');

        OnAfterSetFilters(Rec);
    end;

    local procedure LookupOKOnPush()
    begin
        FromSalesShptLine.Copy(Rec);
        CurrPage.SetSelectionFilter(FromSalesShptLine);
        if FromSalesShptLine.FindFirst() then
            if AssignmentType = AssignmentType::Sale then begin
                ItemChargeAssgntSales."Unit Cost" := UnitCost;
                AssignItemChargeSales.CreateShptChargeAssgnt(FromSalesShptLine, ItemChargeAssgntSales);
            end else
                if AssignmentType = AssignmentType::Purchase then begin
                    ItemChargeAssgntPurch."Unit Cost" := UnitCost;
                    AssignItemChargePurch.CreateSalesShptChargeAssgnt(FromSalesShptLine, ItemChargeAssgntPurch);
                end;
    end;

    local procedure DocumentNoOnFormat()
    begin
        if not IsFirstLine(Rec."Document No.", Rec."Line No.") then
            DocumentNoHideValue := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilters(var SalesShipmentLine: Record "Sales Shipment Line")
    begin
    end;
}

