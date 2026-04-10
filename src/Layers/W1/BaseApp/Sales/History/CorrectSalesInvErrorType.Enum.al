// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

/// <summary>
/// Defines error types that prevent the correction or cancellation of posted sales invoices.
/// </summary>
enum 1303 "Correct Sales Inv. Error Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Indicates that the invoice cannot be corrected because it has already been paid.
    /// </summary>
    value(0; "IsPaid") { }
    /// <summary>
    /// Indicates that the invoice cannot be corrected because the customer is blocked.
    /// </summary>
    value(1; "CustomerBlocked") { }
    /// <summary>
    /// Indicates that the invoice cannot be corrected because an item on the invoice is blocked.
    /// </summary>
    value(2; "ItemBlocked") { }
    /// <summary>
    /// Indicates that the invoice cannot be corrected because a related G/L account is blocked.
    /// </summary>
    value(3; "AccountBlocked") { }
    /// <summary>
    /// Indicates that the invoice cannot be corrected because it has already been corrected.
    /// </summary>
    value(4; "IsCorrected") { }
    /// <summary>
    /// Indicates that the invoice cannot be corrected because it is itself a corrective document.
    /// </summary>
    value(5; "IsCorrective") { }
    /// <summary>
    /// Indicates that the invoice cannot be corrected due to number series configuration for invoices.
    /// </summary>
    value(6; "SerieNumInv") { }
    /// <summary>
    /// Indicates that the invoice cannot be corrected due to number series configuration for credit memos.
    /// </summary>
    value(7; "SerieNumCM") { }
    /// <summary>
    /// Indicates that the invoice cannot be corrected due to number series configuration for posted credit memos.
    /// </summary>
    value(8; "SerieNumPostCM") { }
    /// <summary>
    /// Indicates that the invoice cannot be corrected because items have already been returned.
    /// </summary>
    value(9; "ItemIsReturned") { }
    /// <summary>
    /// Indicates that the invoice cannot be corrected because it was created from a sales order.
    /// </summary>
    value(10; "FromOrder") { }
    /// <summary>
    /// Indicates that the invoice cannot be corrected because posting is not allowed in the period.
    /// </summary>
    value(11; "PostingNotAllowed") { }
    /// <summary>
    /// Indicates that the invoice cannot be corrected because one or more lines originated from a sales order.
    /// </summary>
    value(12; "LineFromOrder") { }
    /// <summary>
    /// Indicates that the invoice cannot be corrected because an item has an unsupported type.
    /// </summary>
    value(13; "WrongItemType") { }
    /// <summary>
    /// Indicates that the invoice cannot be corrected because one or more lines are linked to a project.
    /// </summary>
    value(14; "LineFromJob") { }
    /// <summary>
    /// Indicates that the invoice cannot be corrected due to a dimension error on a line.
    /// </summary>
    value(15; "DimErr") { }
    /// <summary>
    /// Indicates that the invoice cannot be corrected due to a dimension combination error on a line.
    /// </summary>
    value(16; "DimCombErr") { }
    /// <summary>
    /// Indicates that the invoice cannot be corrected due to a dimension combination error on the header.
    /// </summary>
    value(17; "DimCombHeaderErr") { }
    /// <summary>
    /// Indicates that the invoice cannot be corrected due to an external document number error.
    /// </summary>
    value(18; "ExtDocErr") { }
    /// <summary>
    /// Indicates that the invoice cannot be corrected because the inventory posting period is closed.
    /// </summary>
    value(19; "InventoryPostClosed") { }
    /// <summary>
    /// Indicates that the invoice cannot be corrected because an item variant on the invoice is blocked.
    /// </summary>
    value(20; "ItemVariantBlocked") { }
}
