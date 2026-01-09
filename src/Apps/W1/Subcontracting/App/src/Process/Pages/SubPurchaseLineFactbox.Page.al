// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Purchases.Document;

page 99001518 "Sub. Purchase Line Factbox"
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
                ToolTip = 'Specifies the depended Production Order of this Subcontracting Purchase Order.';
                trigger OnDrillDown()
                var
                begin
                    ShowProductionOrder(Rec);
                end;
            }
            field(ShowTransOrder; GetTransferOrderNo(Rec))
            {
                Caption = 'Transfer Order';
                ToolTip = 'Specifies the depended Transfer Order of this Subcontracting Purchase Order.';
                trigger OnDrillDown()
                var
                begin
                    SubcontractingFactboxMgmt.ShowTransferOrdersAndReturnOrder(Rec, true, false);
                end;
            }
            field(NoOfTransOrder; GetNoOfTransferOrders(Rec))
            {
                Caption = 'No. of Transfer Orders';
                ToolTip = 'Specifies the number of Transfer Orders created for this Subcontracting Purchase Order.';
                trigger OnDrillDown()
                var
                begin
                    SubcontractingFactboxMgmt.ShowTransferOrdersAndReturnOrder(Rec, true, false);
                end;
            }
            field(ShowReturnTransOrder; GetReturnTransferOrderNo(Rec))
            {
                Caption = 'Return Transfer Order';
                ToolTip = 'Specifies the depended Return Transfer Order of this Subcontracting Purchase Order.';
                trigger OnDrillDown()
                var
                begin
                    SubcontractingFactboxMgmt.ShowTransferOrdersAndReturnOrder(Rec, true, true);
                end;
            }
            field(ShowProdOrderRouting; GetNoOfProductionOrderRoutings(Rec))
            {
                Caption = 'Production Routing';
                ToolTip = 'Specifies the depended Production Routing of this Subcontracting Purchase Order.';
                trigger OnDrillDown()
                var
                begin
                    ShowProductionOrderRouting(Rec);
                end;
            }
            field(ShowProdOrderComponents; GetNoOfProductionComponents(Rec))
            {
                Caption = 'Production Components';
                ToolTip = 'Specifies the depended Production Components of this Subcontracting Purchase Order.';

                trigger OnDrillDown()
                var
                begin
                    ShowProductionOrderComponents(Rec);
                end;
            }
            field(SubcontractingPrices; StrSubstNo(PlaceholderLbl, SubcontractingFactboxMgmt.CalcNoOfPurchasePrices(Rec)))
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
        SubcontractingFactboxMgmt: Codeunit "Sub. Factbox Mgmt.";

    local procedure GetNoOfProductionComponents(RecRelatedVariant: Variant): Integer
    begin
        exit(SubcontractingFactboxMgmt.CalcNoOfProductionOrderComponents(RecRelatedVariant))
    end;

    local procedure GetNoOfProductionOrderRoutings(RecRelatedVariant: Variant): Integer
    begin
        exit(SubcontractingFactboxMgmt.CalcNoOfProductionOrderRoutings(RecRelatedVariant))
    end;

    local procedure GetTransferOrderNo(RecRelatedVariant: Variant): Code[20]
    begin
        exit(SubcontractingFactboxMgmt.GetTransferOrderNo(RecRelatedVariant))
    end;

    local procedure GetReturnTransferOrderNo(RecRelatedVariant: Variant): Code[20]
    begin
        exit(SubcontractingFactboxMgmt.GetReturnTransferOrderNo(RecRelatedVariant))
    end;

    local procedure ShowProductionOrderComponents(RecRelatedVariant: Variant)
    begin
        SubcontractingFactboxMgmt.ShowProductionOrderComponents(RecRelatedVariant);
    end;

    local procedure ShowSubcontractorPrices()
    begin
        SubcontractingFactboxMgmt.ShowSubcontractorPrices(Rec);
    end;

    local procedure ShowProductionOrderRouting(RecRelatedVariant: Variant)
    begin
        SubcontractingFactboxMgmt.ShowProductionOrderRouting(RecRelatedVariant);
    end;

    local procedure ShowProductionOrder(RecRelatedVariant: Variant)
    begin
        SubcontractingFactboxMgmt.ShowProductionOrder(RecRelatedVariant);
    end;

    local procedure GetNoOfTransferOrders(RecRelatedVariant: Variant): Integer
    begin
        exit(SubcontractingFactboxMgmt.GetNoOfTransferOrders(RecRelatedVariant))
    end;

    var
        PlaceholderLbl: Label '%1', Locked = true;
}