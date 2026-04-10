// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Automation;

enum 1535 "Approval Action"
{
    Extensible = true;
    value(1; Approve)
    {
        Caption = 'Approve';
    }
    value(2; Delegate)
    {
        Caption = 'Delegate';
    }
    value(3; Reject)
    {
        Caption = 'Reject';
    }
}
