// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Tooling;

/// <summary>
/// The supported activity types for creating scheduled based sampling profiles
/// </summary>
enum 1932 "Perf. Profile Activity Type"
{
    Access = Public;
    Extensible = false;

    /// <summary>
    /// The web client activity type
    /// </summary>
    value(0; "Web Client")
    {
        Caption = 'Activity in the browser';
    }

    /// <summary>
    /// The background activity type
    /// </summary>
    value(1; "Background")
    {
        Caption = 'Background Tasks';
    }

    /// <summary>
    /// The web api activity type
    /// </summary>
    value(2; "Web API Client")
    {
        Caption = 'Web Service Calls';
    }
}