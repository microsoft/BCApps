// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

codeunit 11602 "Import Subsidiary"
{

    trigger OnRun()
    begin
        BASMngmt.ImportSubsidiaries();
        Clear(BASMngmt);
    end;

    var
        BASMngmt: Codeunit "BAS Management";
}

