// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.SourceConfiguration;

/// <summary>
/// The target of a source configuration. This can be either a chained table or a test, or only item tracking.
/// </summary>
enum 20400 "Qlty. Target Type"
{
    Caption = 'Quality Target Type';

    value(0; "Chained table")
    {
        Caption = 'Chained table';
    }
    value(1; Test)
    {
        Caption = 'Test';
    }
    value(2; "Item Tracking only")
    {
        Caption = 'Item Tracking only';
    }
}
