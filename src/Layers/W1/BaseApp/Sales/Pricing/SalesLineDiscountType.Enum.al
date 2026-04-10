// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Pricing;

/// <summary>
/// Defines the type of entity that a sales line discount applies to, such as Item or Item Discount Group.
/// </summary>
enum 7021 "Sales Line Discount Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; Item)
    {
        /// <summary>
        /// Specifies that the discount applies to a specific item.
        /// </summary>
        Caption = 'Item';
    }
    value(1; "Item Disc. Group")
    {
        /// <summary>
        /// Specifies that the discount applies to all items within a designated item discount group.
        /// </summary>
        Caption = 'Item Discount Group';
    }
}
