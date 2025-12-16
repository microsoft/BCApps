// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template.Test;

/// <summary>
/// Helps note the expected wizard test state.
/// </summary>
enum 20421 "Qlty. Test Wizard State"
{
    Caption = 'Quality Test Wizard State';

    value(0; Complete)
    {
        Caption = 'Complete';
    }
    value(1; "In Progress")
    {
        Caption = 'In Progress';
    }
}
