// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 7226 EACorpCardBatchStatus
{
    Access = Internal;
    Caption = 'Corp Card Batch Status';

    value(0; Started)
    {
        Caption = 'Started';
    }
    value(1; Completed)
    {
        Caption = 'Completed';
    }
    value(2; Failed)
    {
        Caption = 'Failed';
    }
}