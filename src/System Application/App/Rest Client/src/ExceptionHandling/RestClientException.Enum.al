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
    value(100; UnknownException)
    {
        Caption = 'Unknown Exception';
    }
    value(101; ConnectionFailed)
    {
        Caption = 'Connection Failed';
    }
    value(102; BlockedByEnvironment)
    {
        Caption = 'Blocked By Environment';
    }
    value(103; RequestFailed)
    {
        Caption = 'Request Failed';
    }
    value(201; InvalidJson)
    {
        Caption = 'Invalid Json';
    }
    value(202; InvalidXml)
    {
        Caption = 'Invalid Xml';
    }
}