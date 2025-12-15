// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Document;

/// <summary>
/// Used to help lists and filters quickly identify which test is the most recent reinspection.
/// </summary>
enum 20412 "Qlty. Iteration State"
{
    Caption = 'Quality Iteration State';

    value(0; "Newer reinspection available")
    {
        Caption = 'Newer reinspection available';
    }
    value(1; "Most recent")
    {
        Caption = 'Most recent';
    }
}
