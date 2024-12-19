// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.RestClient;

/// <summary>
/// This enum contains the exceptions of the Rest Client.
/// </summary>
enum 2351 "Rest Client Exception"
{
    /// <summary>
    /// Specifies that the exception is an unknown exception.
    /// </summary>
    value(100; UnknownException)
    {
        Caption = 'Unknown Exception';
    }
    /// <summary>
    /// Specifies that the connection failed.
    /// </summary>
    value(101; ConnectionFailed)
    {
        Caption = 'Connection Failed';
    }
    /// <summary>
    /// Specifies that the request is blocked by the environment.
    /// </summary>
    value(102; BlockedByEnvironment)
    {
        Caption = 'Blocked By Environment';
    }
    /// <summary>
    /// Specifies that the request failed.
    /// </summary>
    value(103; RequestFailed)
    {
        Caption = 'Request Failed';
    }
    /// <summary>
    /// Specifies that the content is not valid JSON.
    /// </summary>
    value(201; InvalidJson)
    {
        Caption = 'Invalid Json';
    }
    /// <summary>
    /// Specifies that the content is not valid XML.
    /// </summary>
    value(202; InvalidXml)
    {
        Caption = 'Invalid Xml';
    }
}