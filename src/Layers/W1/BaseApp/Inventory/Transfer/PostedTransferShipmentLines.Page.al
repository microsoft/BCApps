// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using Microsoft.Finance.Dimension;

page 5758 "Posted Transfer Shipment Lines"
{
    Caption = 'Posted Transfer Shipment Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Transfer Shipment Line";

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
                    ToolTip = 'Specifies the number of the item that will be transferred.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the description of the item that is transferred.';
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
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
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
                        TransShptHeader: Record "Transfer Shipment Header";
                    begin
                        TransShptHeader.Get(Rec."Document No.");
                        PAGE.Run(PAGE::"Posted Transfer Shipment", TransShptHeader);
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

    var
        TempTransShptLine: Record "Transfer Shipment Line" temporary;
        DocumentNoHideValue: Boolean;

    local procedure IsFirstLine(DocNo: Code[20]; LineNo: Integer): Boolean
    var
        TransShptLine: Record "Transfer Shipment Line";
    begin
        TempTransShptLine.Reset();
        TempTransShptLine.CopyFilters(Rec);
        TempTransShptLine.SetRange("Document No.", DocNo);
        if not TempTransShptLine.FindFirst() then begin
            TransShptLine.CopyFilters(Rec);
            TransShptLine.SetRange("Document No.", DocNo);
            TransShptLine.FindFirst();
            TempTransShptLine := TransShptLine;
            TempTransShptLine.Insert();
        end;
        if TempTransShptLine."Line No." = LineNo then
            exit(true);
    end;

    local procedure DocumentNoOnFormat()
    begin
        if not IsFirstLine(Rec."Document No.", Rec."Line No.") then
            DocumentNoHideValue := true;
    end;
}

