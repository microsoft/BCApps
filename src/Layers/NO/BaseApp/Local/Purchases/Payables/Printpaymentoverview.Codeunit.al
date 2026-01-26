// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

codeunit 15000003 "Print payment overview"
{

    trigger OnRun()
    var
        RemTools: Codeunit "Remittance Tools";
    begin
        RemTools.PrintPaymentOverview(0);
    end;
}

