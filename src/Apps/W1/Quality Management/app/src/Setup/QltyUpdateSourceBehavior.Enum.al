// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Setup;

/// <summary>
/// This flag is used to indicate whether or not to keep the source data updated.
/// </summary>
enum 20407 "Qlty. Update Source Behavior"
{
    Caption = 'Quality Update Source Behavior';

    value(0; "Update when source changes")
    {
        Caption = 'Update when source changes';
    }
    value(1; "Do not update")
    {
        Caption = 'Do not update';
    }
}
