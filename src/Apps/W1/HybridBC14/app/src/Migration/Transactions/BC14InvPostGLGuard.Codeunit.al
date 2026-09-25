// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Ledger;

codeunit 46950 "BC14 Inv. Post. G/L Guard"
{
    SingleInstance = true;

    var
        SuppressInvtPostingToGL: Boolean;

    /// <summary>
    /// Toggles suppression of inventory cost posting to the G/L. It is turned on only for the
    /// duration of BC14 item journal posting (see "BC14 Item Journal Post Action"): rebuilding
    /// on-hand as positive adjustments must write the item and value ledger but must NOT post
    /// inventory cost to the G/L, because the G/L balances are migrated separately by the G/L entry
    /// migrator. Posting cost here as well would double-count inventory value and would additionally
    /// require the full Inventory Posting Setup and General Posting Setup accounts (Inventory
    /// Account, Inventory Adjmt. Account, ...) in the freshly-created target company.
    /// </summary>
    internal procedure SetSuppressInvtPostingToGL(Suppress: Boolean)
    begin
        SuppressInvtPostingToGL := Suppress;
    end;

    /// <summary>
    /// While suppression is active, short-circuit the entire inventory-to-G/L path at its entry
    /// point. Returning Result = false is the same signal the base app uses when a value entry has
    /// nothing to post to the G/L, so no Inventory Posting Setup lookup, no G/L account resolution
    /// and no account checks run. The item and value ledger entries are still written by the caller,
    /// so on-hand quantity and inventory value are preserved.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Posting To G/L", 'OnBeforeBufferInvtPosting', '', false, false)]
    local procedure SkipInvtPostingToGLDuringMigration(var ValueEntry: Record "Value Entry"; var Result: Boolean; var IsHandled: Boolean)
    begin
        if not SuppressInvtPostingToGL then
            exit;

        Result := false;
        IsHandled := true;
    end;
}
