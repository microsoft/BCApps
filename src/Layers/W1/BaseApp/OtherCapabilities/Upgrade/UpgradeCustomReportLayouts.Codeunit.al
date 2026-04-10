// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

codeunit 104054 "Upgrade Custom Report Layouts"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    begin
        Codeunit.Run(Codeunit::"Upgrade Custom Report Impl.");
    end;
}