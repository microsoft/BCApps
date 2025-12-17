// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Document;

/// <summary>
/// Used to help lists and filters quickly identify which inspection is the most recent re-inspection.
/// </summary>
enum 20412 "Qlty. Iteration State"
{
    Caption = 'Quality Iteration State';

    value(0; "Newer re-inspection available")
    {
        Caption = 'Newer re-inspection available';
    }
    value(1; "Most recent")
    {
        Caption = 'Most recent';
    }
}
