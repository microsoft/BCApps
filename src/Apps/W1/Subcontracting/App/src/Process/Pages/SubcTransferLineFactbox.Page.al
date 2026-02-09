// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;

page 99001501 "Subc. Transfer Line Factbox"
{
    ApplicationArea = Manufacturing;
    Caption = 'Subcontracting Details';
    Editable = false;
    PageType = CardPart;
    SourceTable = "Transfer Line";

    layout
    {
        area(Content)
        {
            field(ShowPurchOrder; Rec."Subcontr. Purch. Order No.")
            {
                Caption = 'Purchase Order';
                ToolTip = 'Specifies the depended Purchase Order of this Subcontracting Transfer Order.';
                trigger OnDrillDown()
                var
                begin
                    ShowPurchaseOrder(Rec);
                end;
            }
            field(ShowProdOrder; Rec."Prod. Order No.")
            {
                Caption = 'Production Order';
                ToolTip = 'Specifies the depended Production Order of this Subcontracting Transfer Order.';
                trigger OnDrillDown()
                var
                begin
                    ShowProductionOrder(Rec);
                end;
            }
            field(ShowProdOrderRouting; GetNoOfProductionOrderRoutings(Rec))
            {
                Caption = 'Production Routing';
                ToolTip = 'Specifies the depended Production Routing of this Subcontracting Transfer Order.';
                trigger OnDrillDown()
                var
                begin
                    ShowProductionOrderRouting(Rec);
                end;
            }
            field(ShowProdOrderComponents; GetNoOfProductionComponents(Rec))
            {
                Caption = 'Production Component';
                ToolTip = 'Specifies the depended Production Components of this Subcontracting Transfer Order.';

                trigger OnDrillDown()
                var
                begin
                    ShowProductionOrderComponents(Rec);
                end;
            }
        }
    }
    var
        SubcFactboxMgmt: Codeunit "Subc. Factbox Mgmt.";

    local procedure GetNoOfProductionComponents(RecRelatedVariant: Variant): Integer
    begin
        exit(SubcFactboxMgmt.CalcNoOfProductionOrderComponents(RecRelatedVariant))
    end;

    local procedure GetNoOfProductionOrderRoutings(RecRelatedVariant: Variant): Integer
    begin
        exit(SubcFactboxMgmt.CalcNoOfProductionOrderRoutings(RecRelatedVariant))
    end;

    local procedure ShowProductionOrder(RecRelatedVariant: Variant)
    begin
        SubcFactboxMgmt.ShowProductionOrder(RecRelatedVariant);
    end;

    local procedure ShowProductionOrderRouting(RecRelatedVariant: Variant)
    begin
        SubcFactboxMgmt.ShowProductionOrderRouting(RecRelatedVariant);
    end;

    local procedure ShowProductionOrderComponents(RecRelatedVariant: Variant)
    begin
        SubcFactboxMgmt.ShowProductionOrderComponents(RecRelatedVariant);
    end;

    local procedure ShowPurchaseOrder(RecRelatedVariant: Variant)
    begin
        SubcFactboxMgmt.ShowPurchaseOrder(RecRelatedVariant);
    end;
}