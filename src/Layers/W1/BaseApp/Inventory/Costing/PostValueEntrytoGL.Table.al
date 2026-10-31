// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Setup;

table 5811 "Post Value Entry to G/L"
{
    Caption = 'Post Value Entry to G/L';
    DataClassification = CustomerContent;
    DrillDownPageId = "Post Value Entries to G/L";
    LookupPageId = "Post Value Entries to G/L";

    fields
    {
        field(1; "Value Entry No."; Integer)
        {
            Caption = 'Value Entry No.';
            ToolTip = 'Specifies the number of the value entry whose cost is waiting to be posted to the general ledger.';
            TableRelation = "Value Entry";
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the number of the item that the value entry is for.';
            TableRelation = Item;
        }
        field(3; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the posting date of the value entry.';
        }
    }

    keys
    {
        key(Key1; "Value Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Item No.", "Posting Date")
        {
        }
        key(Key3; "Item No.")
        {
        }
    }

    fieldgroups
    {
    }

    /// <summary>
    /// Checks whether the value entry referenced by this record has no remaining cost that report "Post Inventory Cost to G/L" can post.
    /// This is the case when the value entry no longer exists, or when its actual cost (and its expected cost, if expected cost posting to G/L is enabled)
    /// has been fully posted to the general ledger in both local and additional reporting currency.
    /// </summary>
    /// <returns>True if the record is no longer needed to post inventory cost to the general ledger.</returns>
    procedure HasNothingToPostToGL(): Boolean
    var
        ValueEntry: Record "Value Entry";
        InventorySetup: Record "Inventory Setup";
    begin
        // Read committed data only, so that posted amounts of an uncommitted posting are not taken into account.
        ValueEntry.ReadIsolation := IsolationLevel::ReadCommitted;
        ValueEntry.SetLoadFields(
            "Cost Amount (Actual)", "Cost Posted to G/L", "Cost Amount (Actual) (ACY)", "Cost Posted to G/L (ACY)",
            "Cost Amount (Expected)", "Expected Cost Posted to G/L", "Cost Amount (Expected) (ACY)", "Exp. Cost Posted to G/L (ACY)");
        if not ValueEntry.Get("Value Entry No.") then
            exit(true);

        InventorySetup.GetRecordOnce();
        exit(IsFullyPostedToGL(ValueEntry, InventorySetup."Expected Cost Posting to G/L"));
    end;

    /// <summary>
    /// Checks whether the cost of a value entry has been fully posted to the general ledger, using the same amounts as report "Post Inventory Cost to G/L".
    /// </summary>
    /// <param name="ValueEntry">The value entry to check.</param>
    /// <param name="ExpectedCostPostingToGL">Specifies whether expected cost is posted to the general ledger.</param>
    /// <returns>True if no actual cost, and no expected cost when expected cost posting is enabled, remains to be posted.</returns>
    procedure IsFullyPostedToGL(ValueEntry: Record "Value Entry"; ExpectedCostPostingToGL: Boolean) Result: Boolean
    begin
        Result :=
            (ValueEntry."Cost Amount (Actual)" = ValueEntry."Cost Posted to G/L") and
            (ValueEntry."Cost Amount (Actual) (ACY)" = ValueEntry."Cost Posted to G/L (ACY)");

        if Result and ExpectedCostPostingToGL then
            Result :=
                (ValueEntry."Cost Amount (Expected)" = ValueEntry."Expected Cost Posted to G/L") and
                (ValueEntry."Cost Amount (Expected) (ACY)" = ValueEntry."Exp. Cost Posted to G/L (ACY)");

        OnAfterIsFullyPostedToGL(ValueEntry, ExpectedCostPostingToGL, Result);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsFullyPostedToGL(ValueEntry: Record "Value Entry"; ExpectedCostPostingToGL: Boolean; var Result: Boolean)
    begin
    end;
}

