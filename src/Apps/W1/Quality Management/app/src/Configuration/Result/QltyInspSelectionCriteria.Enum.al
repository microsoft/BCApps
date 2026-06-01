// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Result;

/// <summary>
/// Used to help determine which inspection to use when conditional optional item tracking based blocking.
/// When evaluating if a document specific transactions are blocked, this determines which inspection(s) are considered.
/// </summary>
enum 20437 "Qlty. Insp. Selection Criteria"
{
    Caption = 'Quality Inspection Selection Criteria';

    value(0; "Any inspection that matches")
    {
        Caption = 'Any inspection that matches';
    }
    value(1; "Only the most recently modified inspection")
    {
        Caption = 'Only the most recently modified inspection';
    }
    value(2; "Only the newest inspection/re-inspection")
    {
        Caption = 'Only the newest inspection/re-inspection';
    }
    value(3; "Any finished inspection that matches")
    {
        Caption = 'Any finished inspection that matches';
    }
    value(4; "Only the most recently modified finished inspection")
    {
        Caption = 'Only the most recently modified finished inspection';
    }
    value(5; "Only the newest finished inspection/re-inspection")
    {
        Caption = 'Only the newest finished inspection/re-inspection';
    }
}
