// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

codeunit 15000230 TestEmpolyeesUnlimited
{

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure TestNoOfEmployees(): Boolean
    begin
        exit(true);
    end;
}

