// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

enum 9883 "Permission Set Scope"
{
    Caption = 'Permission Set Scope';
    Extensible = false;

    value(0; Blank)
    {
        Caption = ' ', Locked = true;
    }
    value(1; UserDefined)
    {
        Caption = 'User-Defined';
    }
    value(2; Extension)
    {
        Caption = 'Extension';
    }
    value(3; System)
    {
        Caption = 'System';
    }
}