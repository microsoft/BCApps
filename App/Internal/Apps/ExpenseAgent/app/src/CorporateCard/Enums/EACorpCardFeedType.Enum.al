// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 7220 EACorpCardFeedType
{
    Access = Internal;
    Caption = 'Corp Card Feed Type';

    value(0; DataExch)
    {
        Caption = 'Data Exchange';
    }
    value(1; API)
    {
        Caption = 'API';
    }
    value(2; CSV)
    {
        Caption = 'CSV';
    }
    value(3; ISO20022)
    {
        Caption = 'ISO20022';
    }
    value(4; CAMT)
    {
        Caption = 'CAMT';
    }
}