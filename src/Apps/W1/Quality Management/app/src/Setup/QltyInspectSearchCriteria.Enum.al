// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Setup;

/// <summary>
/// Controls how existing inspections are found.
/// In some scenarios it's only about the source record, in others it is only item tracking, and in some it's standard source, document, and template.
/// </summary>
enum 20403 "Qlty. Inspect. Search Criteria"
{
    Caption = 'Quality Inspection Search Criteria';

    value(0; "By Standard Source Fields")
    {
        Caption = 'By Standard Source Fields';
    }
    value(1; "By Source Record")
    {
        Caption = 'By Source Record';
    }
    value(2; "By Item Tracking")
    {
        Caption = 'By Item Tracking';
    }
    value(3; "By Document and Item only")
    {
        Caption = 'By Document and Item only';
    }
}
