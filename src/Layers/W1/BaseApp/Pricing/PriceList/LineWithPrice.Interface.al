// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.PriceList;

using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.Source;

interface "Line With Price"
{
    /// <summary>
    /// Returns the table number of the internal record line.
    /// </summary>
    /// <returns>The table id of the source line.</returns>
    procedure GetTableNo(): Integer

    /// <summary>
    /// Setup the internal record line. Applicable for the journal lines that does not have a header record.
    /// The PriceType parameter defines what type of price is going to be calculated.
    /// </summary>
    /// <param name="PriceType">the price type for which the price or discount will be calculated.</param>
    /// <param name="Line">the source record line</param>
    procedure SetLine(PriceType: Enum "Price Type"; Line: Variant)

    /// <summary>
    /// Setup the internal records - line and header. Applicable for the document lines.
    /// The PriceType parameter defines what type of price is going to be calculated.
    /// </summary>
    /// <param name="PriceType">the price type for which the price or discount will be calculated.</param>
    /// <param name="Header">the source record header</param>
    /// <param name="Line">the source record line</param>
    procedure SetLine(PriceType: Enum "Price Type"; Header: Variant; Line: Variant)

    /// <summary>
    /// This method allows to overwrite the internal price source list that is normally filled by SetLine() method.
    /// </summary>
    /// <param name="NewPriceSourceList">The new list of sources that should be attached to the line</param>
    procedure SetSources(var NewPriceSourceList: codeunit "Price Source List")

    /// <summary>
    /// After the calculations are done this method allows to get the updated internal record line.
    /// </summary>
    /// <param name="Line">The updated record line</param>
    procedure GetLine(var Line: Variant)

    /// <summary>
    /// After the calculations are done this method allows to get the updated internal record line and header.
    /// </summary>
    /// <param name="Line">The updated record line</param>
    /// <param name="Line">The updated record header</param>
    procedure GetLine(var Header: Variant; var Line: Variant)

    /// <summary>
    /// Returns the asset type of the internal record line.
    /// </summary>
    /// <returns>The asset type of the internal record line.</returns>
    procedure GetAssetType() AssetType: Enum "Price Asset Type";

    /// <summary>
    /// Returns the price type that was set by the SetLine() method.
    /// </summary>
    /// <returns>The price type</returns>
    procedure GetPriceType(): Enum "Price Type"

    /// <summary>
    /// This method defines if the source line should be updated after the search for a price list line is done.
    /// </summary>
    /// <param name="AmountType">The amount type</param>
    /// <param name="FoundPrice">If FoundPrice is true this method returns true</param>
    /// <param name="CalledByFieldNo">The number of the field that caused the calculation</param>
    /// <returns>If the price amount should be updated</returns>
    procedure IsPriceUpdateNeeded(AmountType: enum "Price Amount Type"; FoundPrice: Boolean; CalledByFieldNo: Integer) Result: Boolean;

    /// <summary>
    /// The calculation of the price defines if the discount allowed for this line.
    /// This method should be called after the price is calculated.
    /// </summary>
    /// <returns>If the discount allowed for this line</returns>
    procedure IsDiscountAllowed() Result: Boolean;

    /// <summary>
    /// Verification of the line before price calculation, usually some TESTFIELD calls.
    /// </summary>
    procedure Verify()

    /// <summary>
    /// Copy asset and source data to the buffer to search for a detailed price calculation setup.
    /// </summary>
    /// <param name="DtldPriceCalculationSetup">The buffer record that get values of filters for search</param>
    /// <returns>If the internal record line is consistent and all filters for detailed setup are in place</returns>
    procedure SetAssetSourceForSetup(var DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup"): Boolean

    /// <summary>
    /// Copy the fields related for price calculation to the buffer that is used in calculation handlers.
    /// </summary>
    /// <param name="PriceCalculationBufferMgt">The buffer that got filled</param>
    /// <returns>If all the internal record line is consistent and can fill the buffer</returns>
    procedure CopyToBuffer(var PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt."): Boolean

    /// <summary>
    /// This method is called after the calculation and allow to do corrections.
    /// </summary>
    /// <param name="AmountType">The amount type</param>
    procedure Update(AmountType: enum "Price Amount Type")

    /// <summary>
    /// After calculation is done, and the right price list line is found this method copies required fields
    /// to the internal record line. The amount type defines what amount will be copied.
    /// </summary>
    /// <param name="AmountType">the amount type.</param>
    /// <param name="PriceListLine">The price list line that should define the price or discount.</param>
    procedure SetPrice(AmountType: enum "Price Amount Type"; PriceListLine: Record "Price List Line")

    /// <summary>
    /// The method SetPrice() copies amounts to the internal record line. 
    /// This method calls the validation triggers on the amount defined by AmountType parameter.
    /// </summary>
    /// <param name="AmountType">the amount type</param>
    procedure ValidatePrice(AmountType: enum "Price Amount Type")
}