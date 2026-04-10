// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

/// <summary>
/// Defines the types of master data entities that can have default dimensions.
/// Used to categorize parent records in default dimension assignments for API integration.
/// </summary>
enum 352 "Default Dimension Parent Type"
{
    /// <summary>
    /// No specific parent type defined.
    /// Default value when parent type classification is not needed.
    /// </summary>
    value(0; " ")
    {
        Caption = ' ';
    }
    /// <summary>
    /// Customer master data entity.
    /// Used for default dimensions associated with customer records.
    /// </summary>
    value(1; Customer)
    {
        Caption = 'Customer';
    }
    /// <summary>
    /// Item master data entity.
    /// Used for default dimensions associated with item records.
    /// </summary>
    value(2; "Item")
    {
        Caption = 'Item';
    }
    /// <summary>
    /// Vendor master data entity.
    /// Used for default dimensions associated with vendor records.
    /// </summary>
    value(3; "Vendor")
    {
        Caption = 'Vendor';
    }
    /// <summary>
    /// Employee master data entity.
    /// Used for default dimensions associated with employee records.
    /// </summary>
    value(4; "Employee")
    {
        Caption = 'Employee';
    }
}
