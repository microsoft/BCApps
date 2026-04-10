// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

codeunit 5344 "CRM Product Name"
{

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure UNIQUE(): Text
    begin
        exit('MicrosoftDynamicsNavIntegration');
    end;

    procedure SHORT(): Text
    begin
        exit('Dynamics 365 Sales');
    end;

    procedure FULL(): Text
    begin
        exit('Microsoft Dynamics 365 Sales');
    end;

    [Scope('Cloud')]
    procedure CDSServiceName(): Text
    begin
        exit('Dataverse');
    end;

    procedure FSServiceName(): Text
    begin
        exit('Dynamics 365 Field Service');
    end;
}

