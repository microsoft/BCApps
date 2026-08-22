// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.User;


/// <summary>
/// Used for setting date flow filters against the Last Login time field on the user details page.
/// </summary>
enum 774 "User Detail Date Filter"
{
    value(0; Blank)
    {
    }
    value(1; "7 Days")
    {
        Caption = '7 Days';
    }
    value(2; "30 Days")
    {
        Caption = '30 Days';
    }
    value(3; "90 Days")
    {
        Caption = '90 Days';
    }
}