// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Purchases.Document;

page 99001518 "Subc. Purchase Line Factbox"
{
    ApplicationArea = Manufacturing;
    Caption = 'Subcontracting Details';
    Editable = false;
    PageType = CardPart;
    SourceTable = "Purchase Line";

    layout
    {
        area(Content)
        {
            field(ShowProdOrder; Rec."Prod. Order No.")
            {
                Caption = 'Production Order';
                ToolTip = 'Specifies the dependent Production Order of this Subcontracting Purchase Order.';
                trigger OnDrillDown()
                begin
                    ShowProductionOrder(Rec);
                end;
            }
            field(ShowTransOrder; GetTransferOrderNo(Rec))
            {
                Caption = 'Transfer Order';
                ToolTip = 'Specifies the dependent Transfer Order of this Subcontracting Purchase Order.';
                trigger OnDrillDown()
                begin
                    SubcPurchFactboxMgmt.ShowTransferOrdersAndReturnOrder(Rec, true, false);
                end;
            }
            field(NoOfTransOrder; GetNoOfTransferOrders(Rec))
            {
                Caption = 'No. of Transfer Orders';
                ToolTip = 'Specifies the number of Transfer Orders created for this Subcontracting Purchase Order.';
                trigger OnDrillDown()
                begin
                    SubcPurchFactboxMgmt.ShowTransferOrdersAndReturnOrder(Rec, true, false);
                end;
            }
            field(ShowReturnTransOrder; GetReturnTransferOrderNo(Rec))
            {
                Caption = 'Return Transfer Order';
                ToolTip = 'Specifies the dependent Return Transfer Order of this Subcontracting Purchase Order.';
                trigger OnDrillDown()
                begin
                    SubcPurchFactboxMgmt.ShowTransferOrdersAndReturnOrder(Rec, true, true);
                end;
            }
            field(ShowProdOrderRouting; GetNoOfProductionOrderRoutings(Rec))
            {
                Caption = 'Production Routing';
                ToolTip = 'Specifies the dependent Production Routing of this Subcontracting Purchase Order.';
                trigger OnDrillDown()
                begin
                    ShowProductionOrderRouting(Rec);
                end;
            }
            field(ShowProdOrderComponents; GetNoOfProductionComponents(Rec))
            {
                Caption = 'Production Components';
                ToolTip = 'Specifies the dependent Production Components of this Subcontracting Purchase Order.';

                trigger OnDrillDown()
                begin
                    ShowProductionOrderComponents(Rec);
                end;
            }
            field(SubcontractingPrices; StrSubstNo(PlaceholderLbl, SubcPurchFactboxMgmt.CalcNoOfPurchasePrices(Rec)))
            {
                Caption = 'Subcontractor Prices';
                DrillDown = true;
                Editable = true;
                ToolTip = 'Specifies how many special subcontractor prices your vendor grants you for the purchase line.';

                trigger OnDrillDown()
                begin
                    ShowSubcontractorPrices();
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

    local procedure GetTransferOrderNo(RecRelatedVariant: Variant): Code[20]
    begin
        exit(SubcPurchFactboxMgmt.GetTransferOrderNo(RecRelatedVariant))
    end;

    local procedure GetReturnTransferOrderNo(RecRelatedVariant: Variant): Code[20]
    begin
        exit(SubcPurchFactboxMgmt.GetReturnTransferOrderNo(RecRelatedVariant))
    end;

    local procedure ShowProductionOrderComponents(RecRelatedVariant: Variant)
    begin
        SubcProdOrderFactboxMgmt.ShowProductionOrderComponents(RecRelatedVariant);
    end;

    local procedure ShowSubcontractorPrices()
    begin
        SubcPurchFactboxMgmt.ShowSubcontractorPrices(Rec);
    end;

    local procedure ShowProductionOrderRouting(RecRelatedVariant: Variant)
    begin
        SubcProdOrderFactboxMgmt.ShowProductionOrderRouting(RecRelatedVariant);
    end;

    local procedure ShowProductionOrder(RecRelatedVariant: Variant)
    begin
        SubcProdOrderFactboxMgmt.ShowProductionOrder(RecRelatedVariant);
    end;

    local procedure GetNoOfTransferOrders(RecRelatedVariant: Variant): Integer
    begin
        exit(SubcPurchFactboxMgmt.GetNoOfTransferOrders(RecRelatedVariant))
    end;

    var
        PlaceholderLbl: Label '%1', Locked = true;
}
