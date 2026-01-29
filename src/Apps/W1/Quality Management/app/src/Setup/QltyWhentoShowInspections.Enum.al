// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Setup;

/// <summary>
/// Defines when to automatically show the inspections.
/// </summary>
enum 20401 "Qlty. When to Show Inspections"
{
    Caption = 'When to Show Inspections';

    value(0; "Always")
    {
        Caption = 'Always';
    }
    value(1; "Only manually created inspections")
    {
        Caption = 'Only manually created inspections';
    }
    value(2; "Never")
    {
        Caption = 'Never';
    }
}
