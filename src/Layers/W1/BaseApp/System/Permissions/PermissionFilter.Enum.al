// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

enum 9003 "Permission Filter"
{
    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; No)
    {
        Caption = 'No';
    }
    value(2; Yes)
    {
        Caption = 'Yes';
    }
    value(3; Indirect)
    {
        Caption = 'Indirect';
    }
}