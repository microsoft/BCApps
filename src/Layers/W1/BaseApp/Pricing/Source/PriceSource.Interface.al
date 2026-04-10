// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Source;

using Microsoft.Pricing.PriceList;

interface "Price Source"
{
    /// <summary>
    /// The method fills the Price Source parameter with "Source No." and other data from the source defined in the implementation codeunit. 
    /// </summary>
    /// <param name="PriceSource">the record gets filled with data</param>
    procedure GetNo(var PriceSource: Record "Price Source")

    /// <summary>
    /// The method fills the Price Source parameter with "Source ID" and other data from the source defined in the implementation codeunit. 
    /// </summary>
    /// <param name="PriceSource">the record gets filled with data</param>
    procedure GetId(var PriceSource: Record "Price Source")

    /// <summary>
    /// The method should return true if the source can define both price and discount.
    /// If the price source is relevant only for prices 
    /// it should return true when AmountType is Price, and false if AmountType is Discount
    /// E.g., "Customer Price Group" is not relevant for discounts, "Customer Discount Group" is not relevant for prices.
    /// </summary>
    /// <param name="AmountType">Current amount type: price or discount</param>
    /// <returns>true if the price source is relevant for the AmountType</returns>
    procedure IsForAmountType(AmountType: Enum "Price Amount Type"): Boolean

    /// <summary>
    /// The method runs the modal page for looking up for a price source.
    /// </summary>
    /// <param name="PriceSource">Defines the default price source to be shown on opening of the lookup page</param>
    /// <returns>true if the lookup is completed</returns>
    procedure IsLookupOK(var PriceSource: Record "Price Source"): Boolean

    /// <summary>
    /// The method should throw an error if the price source does not support the parent source, but "Parent Source No" is filled, 
    /// and vice versa, if the parent source is supported but "Parent Source No" is empty or inconsistent.
    /// E.g., "Job Task" is the only price source that supports "Job" price source as a parent.
    /// </summary>
    /// <param name="PriceSource">Current price source</param>
    /// <returns>true is the parent is supported and validated</returns>
    procedure VerifyParent(var PriceSource: Record "Price Source") Result: Boolean

    /// <summary>
    /// The method should return true for a source that requires "Source No." to be filled. 
    /// In W1 returns false for group source types: "All", "All Customers", "All Vendors", "All Jobs".
    /// </summary>
    /// <returns>true is "Source No." must be filled</returns>
    procedure IsSourceNoAllowed() Result: Boolean;

    /// <summary>
    /// The method should return "Source No." of the related Customer, Vendor, or Job.
    /// E.g., "Job Task" returns the parent job's "Source No.",
    /// so the detailed price calculation setup defined for the job will be applied for all Job Tasks.
    /// </summary>
    /// <param name="PriceSource">Current price source</param>
    /// <returns>"Source No." of the related customer, vendor, or job</returns>
    procedure GetGroupNo(PriceSource: Record "Price Source"): Code[20];
}
