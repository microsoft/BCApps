// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Log;

/// <summary>
/// Codeunit to build and log activity entries for a specific table and field.
/// Currently first party applications only to allow for future API changes. 
/// </summary>

enum 3111 "Activity Log Type"
{
    Extensible = false;
    Scope = OnPrem;

    value(0; "AL")
    {
        Caption = 'AL', Locked = true;
    }
    value(1; "AI")
    {
        Caption = 'AI', Locked = true;
    }

}