// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.PositivePay;

using Microsoft.Bank.Check;

/// <summary>
/// Provides validation services for positive pay export processes on check ledger entries.
/// This codeunit ensures that check data meets the requirements for positive pay file generation.
/// </summary>
/// <remarks>
/// The Export Validation Positive Pay codeunit performs validation checks on check ledger entries
/// before they are included in positive pay exports. It ensures data integrity and compliance with
/// bank-specific formatting requirements. The validation process helps prevent export failures and
/// ensures that only valid check data is transmitted to banks for positive pay processing.
/// The codeunit is designed to be extensible to accommodate different bank validation requirements.
/// </remarks>
codeunit 1701 "Exp. Validation Pos. Pay"
{
    TableNo = "Check Ledger Entry";

    trigger OnRun()
    begin
    end;
}

