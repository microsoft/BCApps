// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Setup;

/// <summary>
/// Determines the item tracking behavior, and can be used to help determine whether to require item tracking before finishing an inspection.
/// </summary>
enum 20418 "Qlty. Item Tracking Behavior"
{
    Caption = 'Quality Item Tracking Behavior';

    value(0; "Allow without Item Tracking")
    {
        Caption = 'Allow without Item Tracking';
    }
    value(1; "Allow only posted Item Tracking")
    {
        Caption = 'Allow only posted Item Tracking';
    }
    value(2; "Allow reserved or posted Item Tracking")
    {
        Caption = 'Allow reserved or posted Item Tracking';
    }
    value(3; "Allow any non-empty value")
    {
        Caption = 'Allow any non-empty value';
    }
}
