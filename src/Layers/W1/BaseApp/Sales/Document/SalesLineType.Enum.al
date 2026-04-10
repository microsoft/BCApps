// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

/// <summary>
/// Defines the types of entries that can be added to a sales document line.
/// </summary>
enum 37 "Sales Line Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Represents an empty line type used for comments or blank lines in sales documents.
    /// </summary>
    value(0; " ") { Caption = ' '; }
    /// <summary>
    /// Represents a general ledger account entry on a sales document line.
    /// </summary>
    value(1; "G/L Account") { Caption = 'G/L Account'; }
    /// <summary>
    /// Represents an inventory item entry on a sales document line.
    /// </summary>
    value(2; "Item") { Caption = 'Item'; }
    /// <summary>
    /// Represents a resource entry such as labor or services on a sales document line.
    /// </summary>
    value(3; "Resource") { Caption = 'Resource'; }
    /// <summary>
    /// Represents a fixed asset entry on a sales document line.
    /// </summary>
    value(4; "Fixed Asset") { Caption = 'Fixed Asset'; }
    /// <summary>
    /// Represents an item charge entry used to allocate additional costs to items on a sales document line.
    /// </summary>
    value(5; "Charge (Item)") { Caption = 'Charge (Item)'; }
    /// <summary>
    /// Represents an allocation account entry used to distribute amounts across multiple accounts on a sales document line.
    /// </summary>
    value(10; "Allocation Account") { Caption = 'Allocation Account'; }
}
