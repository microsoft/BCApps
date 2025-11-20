// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Pricing;

page 6083 "Serv. Price Adjmt. Detail"
{
    Caption = 'Serv. Price Adjmt. Detail';
    DataCaptionExpression = FormCaption();
    PageType = List;
    SourceTable = "Serv. Price Adjustment Detail";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Serv. Price Adjmt. Gr. Code"; Rec."Serv. Price Adjmt. Gr. Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the service price adjustment group that applies to the posted service line.';
                    Visible = ServPriceAdjmtGrCodeVisible;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type for the service item line to be adjusted.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Work Type"; Rec."Work Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the work type of the resource.';
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service item, resource, resource group, or service cost, of which the price will be adjusted, based on the value selected in the Type field.';
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
    }

    trigger OnInit()
    begin
        ServPriceAdjmtGrCodeVisible := true;
    end;

    trigger OnOpenPage()
    var
        ServPriceAdjmtGroup: Record "Service Price Adjustment Group";
        ShowColumn: Boolean;
    begin
        ShowColumn := true;
        if Rec.GetFilter("Serv. Price Adjmt. Gr. Code") <> '' then
            if ServPriceAdjmtGroup.Get(Rec."Serv. Price Adjmt. Gr. Code") then
                ShowColumn := false
            else
                Rec.Reset();
        ServPriceAdjmtGrCodeVisible := ShowColumn;
    end;

    var
        ServPriceAdjmtGrCodeVisible: Boolean;

    local procedure FormCaption(): Text[180]
    var
        ServPriceAdjmtGrp: Record "Service Price Adjustment Group";
    begin
        if Rec.GetFilter("Serv. Price Adjmt. Gr. Code") <> '' then
            if ServPriceAdjmtGrp.Get(Rec."Serv. Price Adjmt. Gr. Code") then
                exit(StrSubstNo('%1 %2', Rec."Serv. Price Adjmt. Gr. Code", ServPriceAdjmtGrp.Description));
    end;
}

