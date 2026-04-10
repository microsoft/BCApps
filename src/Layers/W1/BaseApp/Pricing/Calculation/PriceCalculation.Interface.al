// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Calculation;

using Microsoft.Pricing.PriceList;

interface "Price Calculation"
{
    /// <summary>
    /// Save the source line as an interface variable inside the price calculation codeunit
    /// </summary>
    /// <param name="LineWithPrice">The interface parameter for the document or journal line.</param>
    /// <returns>The updated source line.</returns>
    procedure Init(LineWithPrice: Interface "Line With Price"; PriceCalculationSetup: Record "Price Calculation Setup")

    /// <summary>
    /// After the calculation is done by calling ApplyPrice() or ApplyDiscount() 
    /// the updated line is retrieved by this method. 
    /// </summary>
    /// <param name="Line">The updated source line.</param>
    procedure GetLine(var Line: Variant)

    /// <summary>
    /// Executes the calcluation of the discount amount. 
    /// </summary>
    procedure ApplyDiscount()

    /// <summary>
    /// Executes the calculation of the price or cost.
    /// </summary>
    /// <param name="CalledByFieldNo">The id of the field that caused the calculation.</param>
    procedure ApplyPrice(CalledByFieldNo: Integer)

    /// <summary>
    /// Returns the number of price list lines with discounts that fit the source line.
    /// </summary>
    /// <param name="ShowAll">If true it widens the filters set to the price list line.</param>
    /// <returns>Number of price list lines with discounts that fit the source line.</returns>
    procedure CountDiscount(ShowAll: Boolean) Result: Integer;

    /// <summary>
    /// Returnes the number of price list lines with prices that fit the source line.
    /// </summary>
    /// <param name="ShowAll">If true it widens the filters set to the price list line.</param>
    /// <returns>Number of price list lines with prices that fit the source line.</returns>
    procedure CountPrice(ShowAll: Boolean) Result: Integer;

    /// <summary>
    /// Returns the list of price list lines with discount that fit the source line.
    /// </summary>
    /// <param name="TempPriceListLine">the temporary buffer containing the price list line that fit the source line.</param>
    /// <param name="ShowAll">If true it widens the filters set to the price list line.</param>
    /// <returns>true if any price list line is found</returns>
    procedure FindDiscount(var TempPriceListLine: Record "Price List Line"; ShowAll: Boolean) Found: Boolean;

    /// <summary>
    /// Returns the list of price list lines with prices ot costs that fit the source line.
    /// </summary>
    /// <param name="TempPriceListLine">the temporary buffer containing the price list line that fit the source line.</param>
    /// <param name="ShowAll">If true it widens the filters set to the price list line.</param>
    /// <returns>true if any price list line is found</returns>
    procedure FindPrice(var TempPriceListLine: Record "Price List Line"; ShowAll: Boolean) Found: Boolean;

    /// <summary>
    /// Returns true if exists any price list line with discount that fit the source line. 
    /// </summary>
    /// <param name="ShowAll">If true it widens the filters set to the price list line.</param>
    /// <returns>true if any price list line is found</returns>
    procedure IsDiscountExists(ShowAll: Boolean) Result: Boolean;

    /// <summary>
    /// Returns true if exists any price list line with price or cost that fit the source line. 
    /// </summary>
    /// <param name="ShowAll">If true it widens the filters set to the price list line.</param>
    /// <returns>true if any price list line is found</returns>
    procedure IsPriceExists(ShowAll: Boolean) Result: Boolean;

    /// <summary>
    /// Allows to pick from the list of price list lines with disocunt that fit the source line.
    /// </summary>
    procedure PickDiscount()

    /// <summary>
    /// Allows to pick from the list of price list lines with price or cost that fit the source line.
    /// </summary>
    procedure PickPrice()

    /// <summary>
    /// Opens the list page for reviewing existing prices. 
    /// </summary>
    /// <param name="TempPriceListLine">The buffer with the found price list lines.</param>
    procedure ShowPrices(var TempPriceListLine: Record "Price List Line")
}