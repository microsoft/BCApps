// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Document;

/// <summary>
/// Helps categorize how a line failed.
/// </summary>
enum 20435 "Qlty. Line Failure State"
{
    Caption = 'Quality Line Failure State';

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; "Failed from Acceptable Quality Level")
    {
        Caption = 'Failed from Acceptable Quality Level';
    }
    value(2; "Failed from Acceptance Criteria")
    {
        Caption = 'Failed from Acceptance Criteria';
    }
}
