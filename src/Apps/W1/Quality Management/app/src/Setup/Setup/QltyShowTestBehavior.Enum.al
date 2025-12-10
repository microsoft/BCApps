// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Setup.Setup;

/// <summary>
/// Defines when to automatically show the tests.
/// </summary>
enum 20401 "Qlty. Show Test Behavior"
{
    Caption = 'Quality Show Test Behavior';

    value(0; "Automatic and manually created tests")
    {
        Caption = 'Automatic and manually created tests';
    }
    value(1; "Only manually created tests")
    {
        Caption = 'Only manually created tests';
    }
    value(2; "Do not show created tests")
    {
        Caption = 'Do not show created tests';
    }
}
