// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Document;

/// <summary>
/// Used to help lists and filters quickly identify which test is the most recent retest.
/// </summary>
enum 20412 "Qlty. Iteration State"
{
    Caption = 'Quality Iteration State';

    value(0; "Newer retest available")
    {
        Caption = 'Newer retest available';
    }
    value(1; "Most recent")
    {
        Caption = 'Most recent';
    }
}
