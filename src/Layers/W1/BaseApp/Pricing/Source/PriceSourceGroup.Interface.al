// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Source;

interface "Price Source Group"
{
    /// <summary>
    /// "Price Source Group" enum is a subset of the "Price Source Type" enum. 
    /// The group limits allowed Source Types, e.g. for Customer group the Vendor source type is not supported.
    /// Returns true if the passed price source type belongs to the price source group.
    /// </summary>
    /// <param name="SourceType">Price source type</param>
    procedure IsSourceTypeSupported(SourceType: Enum "Price Source Type"): Boolean;

    /// <summary>
    /// Some of source types are mapped to the price source groups that is used in setup. 
    /// If the source type does not belong to one group then it returns group All.
    /// </summary>
    /// <returns>the source group.</returns>
    procedure GetGroup() SourceGroup: Enum "Price Source Group";
}