// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Dispositions;

/// <summary>
/// Determines how entries are created, whether to just create entries or also immediately post them.
/// </summary>
enum 20449 "Qlty. Item Adj. Post Behavior"
{
    Extensible = true;
    Caption = 'Quality Item Adjustment Posting Behavior';

    value(0; "Prepare only")
    {
        Caption = 'Prepare only';
    }
    value(1; Post)
    {
        Caption = 'Post';
    }
}
