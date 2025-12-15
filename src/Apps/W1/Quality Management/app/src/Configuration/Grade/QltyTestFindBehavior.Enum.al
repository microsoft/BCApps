// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Grade;

/// <summary>
/// Used to help determine which test to use when conditional optional lot/serial item tracking based blocking.
/// When evaluating if a document specific transactions are blocked, this determines which test(s) are considered.
/// </summary>
enum 20437 "Qlty. Test Find Behavior"
{
    Caption = 'Quality Inspection Find Behavior';

    value(0; Any)
    {
        Caption = 'Any test that matches';
    }
    value(1; MostRecentModified)
    {
        Caption = 'Only the most recently modified test';
    }
    value(2; HighestRetestNumber)
    {
        Caption = 'Only the newest test/re-test';
    }
    value(3; AnyFinished)
    {
        Caption = 'Any finished test that matches';
    }
    value(4; MostRecentFinishedModified)
    {
        Caption = 'Only the most recently modified finished test';
    }
    value(5; HighestFinishedRetestNumber)
    {
        Caption = 'Only the newest finished test/re-test';
    }
}
