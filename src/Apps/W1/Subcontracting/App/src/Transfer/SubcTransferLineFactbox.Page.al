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
                ToolTip = 'Specifies the dependent Purchase Order of this Subcontracting Transfer Order.';
                trigger OnDrillDown()
                begin
                    ShowPurchaseOrder(Rec);
                end;
            }
            field(ShowProdOrder; Rec."Prod. Order No.")
            {
                Caption = 'Production Order';
                ToolTip = 'Specifies the dependent Production Order of this Subcontracting Transfer Order.';
                trigger OnDrillDown()
                begin
                    ShowProductionOrder(Rec);
                end;
            }
            field(ShowProdOrderRouting; GetNoOfProductionOrderRoutings(Rec))
            {
                Caption = 'Production Routing';
                ToolTip = 'Specifies the dependent Production Routing of this Subcontracting Transfer Order.';
                trigger OnDrillDown()
                begin
                    ShowProductionOrderRouting(Rec);
                end;
            }
            field(ShowProdOrderComponents; GetNoOfProductionComponents(Rec))
            {
                Caption = 'Production Component';
                ToolTip = 'Specifies the dependent Production Components of this Subcontracting Transfer Order.';

                trigger OnDrillDown()
                begin
                    ShowProductionOrderComponents(Rec);
                end;
            }
        }
    }
    var
        SubcProdOrderFactboxMgmt: Codeunit "Subc. ProdO. Factbox Mgmt.";
        SubcPurchFactboxMgmt: Codeunit "Subc. Purch. Factbox Mgmt.";

    local procedure GetNoOfProductionComponents(RecRelatedVariant: Variant): Integer
    begin
        exit(SubcProdOrderFactboxMgmt.CalcNoOfProductionOrderComponents(RecRelatedVariant))
    end;

    local procedure GetNoOfProductionOrderRoutings(RecRelatedVariant: Variant): Integer
    begin
        exit(SubcProdOrderFactboxMgmt.CalcNoOfProductionOrderRoutings(RecRelatedVariant))
    end;

    local procedure ShowProductionOrder(RecRelatedVariant: Variant)
    begin
        SubcProdOrderFactboxMgmt.ShowProductionOrder(RecRelatedVariant);
    end;

    local procedure ShowProductionOrderRouting(RecRelatedVariant: Variant)
    begin
        SubcProdOrderFactboxMgmt.ShowProductionOrderRouting(RecRelatedVariant);
    end;

    local procedure ShowProductionOrderComponents(RecRelatedVariant: Variant)
    begin
        SubcProdOrderFactboxMgmt.ShowProductionOrderComponents(RecRelatedVariant);
    end;

    local procedure ShowPurchaseOrder(RecRelatedVariant: Variant)
    begin
        SubcPurchFactboxMgmt.ShowPurchaseOrder(RecRelatedVariant);
    end;
}
