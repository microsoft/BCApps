// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Setup;

/// <summary>
/// Defines when to automatically show the inspections.
/// </summary>
enum 20401 "Qlty. Show Inspection Behavior"
{
    Caption = 'Quality Show Inspection Behavior';

    value(0; "Automatic and manually created inspections")
    {
        Caption = 'Automatic and manually created inspections';
    }
    value(1; "Only manually created inspections")
    {
        Caption = 'Only manually created inspections';
    }
    value(2; "Do not show created inspections")
    {
        Caption = 'Do not show created inspections';
    }
}
