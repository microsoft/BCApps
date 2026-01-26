// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank.Statement;

codeunit 11406 "Imp. SEPA CAMT Pre-Mapping"
{
    TableNo = "CBG Statement Line";

    trigger OnRun()
    var
        ImpBankTransDataUpdates: Codeunit "Imp. Bank Trans. Data Updates";
    begin
        ImpBankTransDataUpdates.InheritDataFromParentToChildNodes(Rec."Data Exch. Entry No.");
    end;
}

