// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using Microsoft.Finance.Dimension;
using Microsoft.Purchases.Document;

page 5759 "Posted Transfer Receipt Lines"
{
    Caption = 'Posted Transfer Receipt Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Transfer Receipt Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Location;
                    HideValue = DocumentNoHideValue;
                    StyleExpr = 'Strong';
                    ToolTip = 'Specifies the document number associated with this transfer line.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the number of the item that you want to transfer.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the description of the item being transferred.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies information in addition to the description of the item being transferred.';
                    Visible = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the quantity of the item specified on the line.';
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the name of the item or resource''s unit of measure, such as piece or hour.';
                }
                field("Receipt Date"; Rec."Receipt Date")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the receipt date of the transfer receipt line.';
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
                action(ShowDocument)
                {
                    ApplicationArea = Location;
                    Caption = 'Show Document';
                    Image = View;
                    ShortCutKey = 'Return';
                    ToolTip = 'Open the document that the selected line exists on.';

                    trigger OnAction()
                    var
                        TransRcptHeader: Record "Transfer Receipt Header";
                    begin
                        TransRcptHeader.Get(Rec."Document No.");
                        PAGE.Run(PAGE::"Posted Transfer Receipt", TransRcptHeader);
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

                actionref("Show Document_Promoted"; ShowDocument)
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

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            LookupOKOnPush();
    end;

    var
        FromTransRcptLine: Record "Transfer Receipt Line";
        TempTransRcptLine: Record "Transfer Receipt Line" temporary;
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        AssignItemChargePurch: Codeunit "Item Charge Assgnt. (Purch.)";
        UnitCost: Decimal;
        CreateCostDistrib: Boolean;
        DocumentNoHideValue: Boolean;

    procedure Initialize(NewItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; NewUnitCost: Decimal)
    begin
        ItemChargeAssgntPurch := NewItemChargeAssgntPurch;
        UnitCost := NewUnitCost;
        CreateCostDistrib := true;
    end;

    local procedure IsFirstLine(DocNo: Code[20]; LineNo: Integer): Boolean
    var
        TransRcptLine: Record "Transfer Receipt Line";
    begin
        TempTransRcptLine.Reset();
        TempTransRcptLine.CopyFilters(Rec);
        TempTransRcptLine.SetRange("Document No.", DocNo);
        if not TempTransRcptLine.FindFirst() then begin
            TransRcptLine.CopyFilters(Rec);
            TransRcptLine.SetRange("Document No.", DocNo);
            TransRcptLine.FindFirst();
            TempTransRcptLine := TransRcptLine;
            TempTransRcptLine.Insert();
        end;
        if TempTransRcptLine."Line No." = LineNo then
            exit(true);
    end;

    local procedure LookupOKOnPush()
    begin
        if CreateCostDistrib then begin
            FromTransRcptLine.Copy(Rec);
            CurrPage.SetSelectionFilter(FromTransRcptLine);
            if FromTransRcptLine.FindFirst() then begin
                ItemChargeAssgntPurch."Unit Cost" := UnitCost;
                AssignItemChargePurch.CreateTransferRcptChargeAssgnt(FromTransRcptLine, ItemChargeAssgntPurch);
            end;
        end;
    end;

    local procedure DocumentNoOnFormat()
    begin
        if not IsFirstLine(Rec."Document No.", Rec."Line No.") then
            DocumentNoHideValue := true;
    end;
}

