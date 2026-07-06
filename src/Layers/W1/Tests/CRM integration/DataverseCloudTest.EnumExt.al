// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

// Test-only extension of the "Dataverse Cloud" enum, simulating a partner adding support for a
// sovereign cloud with its own "Dataverse Cloud Endpoints" implementation.
enumextension 139200 "Dataverse Cloud Test" extends "Dataverse Cloud"
{
    value(139200; TestSovereign)
    {
        Caption = 'Test Sovereign';
        Implementation = "Dataverse Cloud Endpoints" = "Test Dataverse Cloud Endpoints";
    }
}
