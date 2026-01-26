// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

/// <summary>
/// Opens General Ledger Entries page filtered by G/L register entry range.
/// Provides navigation from G/L register to related G/L entries for audit and analysis.
/// </summary>
/// <remarks>
/// TableNo = G/L Register. Filters G/L Entries by entry number range from the register.
/// Used for drill-down functionality from G/L Registers page to see detailed ledger entries.
/// Extensibility: OnBeforeRun event for custom navigation logic.
/// </remarks>
codeunit 235 "G/L Reg.-Gen. Ledger"
{
    TableNo = "G/L Register";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRun(Rec, IsHandled);
        if IsHandled then
            exit;

        GLEntry.SetCurrentKey("Transaction No.");
        GLEntry.SetRange("Transaction No.", Rec."No.");
        PAGE.Run(PAGE::"General Ledger Entries", GLEntry);
    end;

    var
        GLEntry: Record "G/L Entry";

    /// <summary>
    /// Integration event raised before opening the General Ledger Entries page.
    /// </summary>
    /// <param name="GLRegister">G/L register record containing entry range information</param>
    /// <param name="IsHandled">Set to true to skip default page opening logic</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(GLRegister: Record "G/L Register"; var IsHandled: Boolean)
    begin
    end;
}

