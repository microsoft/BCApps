// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Calculation;

page 7026 "Price Calculation Method Card"
{
    Caption = 'Price Calculation Method';
    PageType = Card;
    RefreshOnActivate = true;
    SourceTable = "Price Calculation Setup";
    SourceTableTemporary = true;
    Extensible = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    DataCaptionExpression = format(Rec.Method);

    layout
    {
        area(content)
        {
            part(SaleSetup; "Price Calculation Setup Lines")
            {
                Caption = 'Sale Price Calculation';
                ShowFilter = false;
                ApplicationArea = Basic, Suite;
                SubPageView = where(Type = const(Sale));
            }
            part(PurchaseSetup; "Price Calculation Setup Lines")
            {
                Caption = 'Purchase Price Calculation';
                ShowFilter = false;
                ApplicationArea = Basic, Suite;
                SubPageView = where(Type = const(Purchase));
            }
        }
    }

    trigger OnInit()
    var
        FeaturePriceCalculation: Codeunit "Feature - Price Calculation";
    begin
        FeaturePriceCalculation.FailIfFeatureDisabled();
    end;

    procedure Set(CurrMethod: Enum "Price Calculation Method")
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
        TempPriceCalculationSetup: Record "Price Calculation Setup" temporary;
    begin
        Rec.Reset();
        Rec.DeleteAll();

        PriceCalculationSetup.SetRange(Method, CurrMethod);
        PriceCalculationSetup.SetRange(Default, true);
        if PriceCalculationSetup.FindSet() then
            repeat
                Rec := PriceCalculationSetup;
                Rec.Insert();
            until PriceCalculationSetup.Next() = 0;
        PriceCalculationSetup.SetRange(Default, false);
        if PriceCalculationSetup.FindSet() then
            repeat
                if not IsAssetTypeSet(PriceCalculationSetup) then begin
                    Rec := PriceCalculationSetup;
                    Rec.Insert();
                end;
            until PriceCalculationSetup.Next() = 0;

        TempPriceCalculationSetup.Copy(Rec, true);
        CurrPage.SaleSetup.Page.SetData(TempPriceCalculationSetup);
        CurrPage.PurchaseSetup.Page.SetData(TempPriceCalculationSetup);
    end;

    local procedure IsAssetTypeSet(PriceCalculationSetup: Record "Price Calculation Setup") Result: Boolean;
    begin
        Rec.Reset();
        Rec.SetRange(Type, PriceCalculationSetup.Type);
        Rec.SetRange("Asset Type", PriceCalculationSetup."Asset Type");
        Result := not Rec.IsEmpty();
        Rec.Reset();
    end;
}