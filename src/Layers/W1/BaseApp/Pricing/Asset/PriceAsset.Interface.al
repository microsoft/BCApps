// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Asset;

using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;

interface "Price Asset"
{
    /// <summary>
    /// The method fills the Price Asset parameter with "Asset No." and other data from the asset defined in the implementation codeunit. 
    /// </summary>
    /// <param name="PriceAsset">the record gets filled with data</param>
    procedure GetNo(var PriceAsset: Record "Price Asset")

    /// <summary>
    /// The method fills the Price Asset parameter with "Asset ID" and other data from the asset defined in the implementation codeunit. 
    /// </summary>
    /// <param name="PriceAsset">the record gets filled with data</param>
    procedure GetId(var PriceAsset: Record "Price Asset")

    /// <summary>
    /// The method runs the modal page for looking up for an asset.
    /// </summary>
    /// <param name="PriceAsset">Defines the default asset to be shown on opening of the lookup page</param>
    /// <returns>true if the lookup is completed</returns>
    procedure IsLookupOK(var PriceAsset: Record "Price Asset"): Boolean

    /// <summary>
    /// The method validates if the unit of measure exists for the asset. 
    /// Not used. This validation should happen in IsLookupUnitOfMeasureOK.
    /// </summary>
    /// <param name="PriceAsset">The asset with "Unit of Measure Code" that should be validated</param>
    procedure ValidateUnitOfMeasure(var PriceAsset: Record "Price Asset"): Boolean

    /// <summary>
    /// The method runs the modal page for looking up for a unit of measure.
    /// </summary>
    /// <param name="PriceAsset">Defines the default unit of measure to be shown on opening of the lookup page</param>
    /// <returns>true if the lookup is completed</returns>
    procedure IsLookupUnitOfMeasureOK(var PriceAsset: Record "Price Asset"): Boolean

    /// <summary>
    /// The method runs the modal page for looking up for an item variant.
    /// </summary>
    /// <param name="PriceAsset">Defines the default item variant to be shown on opening of the lookup page</param>
    /// <returns>true if the lookup is completed</returns>
    procedure IsLookupVariantOK(var PriceAsset: Record "Price Asset"): Boolean

    /// <summary>
    /// The method should return true for an asset that requires "Asset No." to be filled. 
    /// In W1 returns false just for one asset type - All.
    /// </summary>
    /// <returns>true if "Asset No." must be filled</returns>
    procedure IsAssetNoRequired(): Boolean;

    /// <summary>
    /// The method is called in case there is no a price list line that matches all filters defined by the document/journal line. 
    /// As a result, the PriceListLine parameter gets pricing data from an asset card or another source.
    /// </summary>
    /// <param name="PriceCalculationBuffer">Contains data from a document/journal line</param>
    /// <param name="AmountType">Price or Discount</param>
    /// <param name="PriceListLine">gets filled with default data from an asset card or another source</param>
    procedure FillBestLine(PriceCalculationBuffer: Record "Price Calculation Buffer"; AmountType: Enum "Price Amount Type"; var PriceListLine: Record "Price List Line")

    /// <summary>
    /// The method should add the filters for PriceListLine related to the PriceAsset, 
    /// e.g., besides "Asset Type" and "Asset No." Item adds "Varian Code", Resource adds "Work Type Code" 
    /// </summary>
    /// <param name="PriceAsset">current price asset</param>
    /// <param name="PriceListLine">the variable that gets additional filters</param>
    /// <returns>not used</returns>
    procedure FilterPriceLines(PriceAsset: Record "Price Asset"; var PriceListLine: Record "Price List Line") Result: Boolean;

    /// <summary>
    /// The method should add assets related to the current one to build the multi-level PriceAssetList.
    /// E.g., a resource asset can add up to two levels: "Resource Group" and "All resources" to setup the hierarchical search,
    /// while an item asset adds "Item Discount Group" at the same level as "Item" is, so both participate in search simultaneously.
    /// </summary>
    /// <param name="PriceAsset">the current asset</param>
    /// <param name="PriceAssetList">the list gets filled with one or more assets</param>
    procedure PutRelatedAssetsToList(PriceAsset: Record "Price Asset"; var PriceAssetList: Codeunit "Price Asset List")

    /// <summary>
    /// The method should fill the PriceAsset with asset related data from the PriceCalculationBuffer.
    /// Used in Add() method of the "Price Asset List" codeunit.
    /// </summary>
    /// <param name="PriceAsset">the asset to be added to the list</param>
    /// <param name="PriceCalculationBuffer">the buffer containing asset's data</param>
    procedure FillFromBuffer(var PriceAsset: Record "Price Asset"; PriceCalculationBuffer: Record "Price Calculation Buffer")
}