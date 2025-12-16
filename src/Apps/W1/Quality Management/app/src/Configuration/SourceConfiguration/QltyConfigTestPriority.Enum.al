// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.SourceConfiguration;

/// <summary>
/// A configuration priority flag is used to help determine if a test takes precedence over other matching tests.
/// </summary>
enum 20464 "Qlty. Config. Test Priority"
{
    Caption = 'Quality Configuration Test Priority';

    value(0; Normal)
    {
        Caption = 'Normal';
    }
    value(1; Priority)
    {
        Caption = 'Priority';
    }
}
