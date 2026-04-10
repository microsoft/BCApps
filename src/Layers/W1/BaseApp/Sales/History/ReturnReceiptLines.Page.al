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
/// Lists posted sales return receipt lines with navigation to related documents and orders.
/// </summary>
page 6667 "Return Receipt Lines"
{
    Caption = 'Return Receipt Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Return Receipt Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    HideValue = DocumentNoHideValue;
                    StyleExpr = 'Strong';
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = SalesReturnOrder;
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
                    ApplicationArea = SalesReturnOrder;
                    Visible = true;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = SalesReturnOrder;
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
                field("Appl.-to Item Entry"; Rec."Appl.-to Item Entry")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Quantity Invoiced"; Rec."Quantity Invoiced")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("Return Order No."; Rec."Return Order No.")
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
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Show Document';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the selected line exists on.';

                    trigger OnAction()
                    var
                        ReturnRcptHeader: Record "Return Receipt Header";
                        PageManagement: Codeunit "Page Management";
                    begin
                        ReturnRcptHeader.Get(Rec."Document No.");
                        PageManagement.PageRun(ReturnRcptHeader);
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
        if AssignmentType = AssignmentType::Sale then
            Rec.SetRange("Sell-to Customer No.", SellToCustomerNo);
        Rec.FilterGroup(2);
        Rec.SetRange(Type, Rec.Type::Item);
        Rec.SetFilter(Quantity, '<>0');
        Rec.SetRange(Correction, false);
        Rec.SetRange("Job No.", '');
        Rec.FilterGroup(0);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            LookupOKOnPush();
    end;

    var
        FromReturnRcptLine: Record "Return Receipt Line";
        TempReturnRcptLine: Record "Return Receipt Line" temporary;
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        AssignItemChargeSales: Codeunit "Item Charge Assgnt. (Sales)";
        AssignItemChargePurch: Codeunit "Item Charge Assgnt. (Purch.)";
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
        ReturnRcptLine: Record "Return Receipt Line";
    begin
        TempReturnRcptLine.Reset();
        TempReturnRcptLine.CopyFilters(Rec);
        TempReturnRcptLine.SetRange("Document No.", DocNo);
        if not TempReturnRcptLine.FindFirst() then begin
            ReturnRcptLine.CopyFilters(Rec);
            ReturnRcptLine.SetRange("Document No.", DocNo);
            ReturnRcptLine.FindFirst();
            TempReturnRcptLine := ReturnRcptLine;
            TempReturnRcptLine.Insert();
        end;
        if TempReturnRcptLine."Line No." = LineNo then
            exit(true);
    end;

    local procedure LookupOKOnPush()
    begin
        FromReturnRcptLine.Copy(Rec);
        CurrPage.SetSelectionFilter(FromReturnRcptLine);
        if FromReturnRcptLine.FindFirst() then
            // CETAF start
            if AssignmentType = AssignmentType::Sale then begin
                ItemChargeAssgntSales."Unit Cost" := UnitCost;
                AssignItemChargeSales.CreateRcptChargeAssgnt(FromReturnRcptLine, ItemChargeAssgntSales);
            end else
                if AssignmentType = AssignmentType::Purchase then begin
                    ItemChargeAssgntPurch."Unit Cost" := UnitCost;
                    AssignItemChargePurch.CreateReturnRcptChargeAssgnt(FromReturnRcptLine, ItemChargeAssgntPurch);
                end;
    end;

    local procedure DocumentNoOnFormat()
    begin
        if not IsFirstLine(Rec."Document No.", Rec."Line No.") then
            DocumentNoHideValue := true;
    end;
}

