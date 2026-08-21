// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 7225 "EA Corp Card Create Mode"
{
    Access = Internal;
    Caption = 'Corp Card Create Mode';

    value(0; AutoDraft)
    {
        Caption = 'Auto Draft';
    }
    value(1; ManualLink)
    {
        Caption = 'Manual Link';
    }
}