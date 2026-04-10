// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Apps.ExtensionGeneration;

table 135107 "Mock Proxy"
{
    Caption = 'Mock Proxy';
    ExternalName = 'mock_proxy';
    TableType = CRM;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; MockProxyId; Text[200])
        {
            Caption = 'Mock Proxy';
            Description = 'Unique identifier of the mock proxy.';
            ExternalAccess = Insert;
            ExternalName = 'mock_proxyid';
            ExternalType = 'Uniqueidentifier';
        }
        field(2; MockName; Text[200])
        {
            Caption = 'Mock Name';
            Description = 'Name of the mock entity';
            ExternalName = 'mockname';
            ExternalType = 'String';
        }
    }

    keys
    {
        key(PK; MockName)
        {
            Clustered = true;
        }
    }
}