// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 7224 EACorpCardExcpType
{
    Access = Internal;
    Caption = 'Corp Card Exception Type';

    value(0; CardNotFound)
    {
        Caption = 'Card Not Found';
    }
    value(1; EmpNotFound)
    {
        Caption = 'Employee Not Found';
    }
    value(2; DupDetected)
    {
        Caption = 'Duplicate Detected';
    }
    value(3; MapMissing)
    {
        Caption = 'Mapping Missing';
    }
    value(4; Validation)
    {
        Caption = 'Validation';
    }
    value(5; Integration)
    {
        Caption = 'Integration';
    }
}