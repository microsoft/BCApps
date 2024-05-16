// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved. 
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Integration.Graph;

/// <summary>
/// The supported request header for the Microsoft Graph API
/// </summary>
enum 9353 "Graph Request Header"
{
    Access = Public;
    Extensible = false;

    /// <summary>
    /// If-Match Request Header
    /// </summary>
    value(0; "If-Match")
    {
        Caption = 'If-Match', Locked = true;
    }

    /// <summary>
    /// If-None-Match Request Header
    /// </summary>
    value(10; "If-None-Match")
    {
        Caption = 'If-None-Match', Locked = true;
    }

    /// <summary>
    /// Prefer Request Header
    /// </summary>
    value(20; Prefer)
    {
        Caption = 'Prefer', Locked = true;
    }

    /// <summary>
    /// ConsistencyLevel Request Header
    /// </summary>
    value(30; ConsistencyLevel)
    {
        Caption = 'ConsistencyLevel', Locked = true;
    }
}