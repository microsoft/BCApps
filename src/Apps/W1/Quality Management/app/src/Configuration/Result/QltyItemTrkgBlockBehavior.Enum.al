// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Result;

/// <summary>
/// How to apply conditional item tracking based blocking.
/// </summary>
enum 20427 "Qlty. Item Trkg Block Behavior"
{
    Caption = 'Quality Item Tracking Blocking Behavior';

    value(0; Allow)
    {
        Caption = 'Allow';
    }
    value(1; Block)
    {
        Caption = 'Block';
    }
    value(2; "Allow finished only")
    {
        Caption = 'Allow finished only';
    }
}
