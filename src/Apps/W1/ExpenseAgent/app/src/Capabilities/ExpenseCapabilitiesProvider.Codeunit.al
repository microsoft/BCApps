// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Derives the enabled/disabled state for each Expense Capability enum value.
/// To add a capability: (1) add a value to the enum (2) add a private "Is&lt;Name&gt;Enabled"
/// procedure that returns the derived boolean (3) add a case branch in "IsEnabled"
/// that dispatches to it. Unhandled enum values default to false.
/// </summary>
codeunit 6906 "Expense Capabilities Provider"
{
    Access = Internal;

    /// <summary>
    /// Returns whether the given capability is currently enabled.
    /// Dispatches to a dedicated <c>Is&lt;Name&gt;Enabled</c> procedure per
    /// capability so each derivation stays small and independently testable.
    /// Defaults to false for any enum value that does not have an explicit
    /// case branch.
    /// </summary>
    procedure IsEnabled(Capability: Enum "Expense Capability"): Boolean
    begin
        case Capability of
            Capability::Projects:
                exit(IsProjectsEnabled());
            Capability::PerDiemLocations:
                exit(IsPerDiemLocationsEnabled());
            Capability::ConsolidatedProjects:
                exit(IsConsolidatedProjectsEnabled());
        end;
        exit(false);
    end;

    local procedure IsProjectsEnabled(): Boolean
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        if not ExpenseAgentSetup.Get() then
            exit(false);
        exit(ExpenseAgentSetup."Enable Project Fields");
    end;

    local procedure IsPerDiemLocationsEnabled(): Boolean
    begin
        exit(true);
    end;

    local procedure IsConsolidatedProjectsEnabled(): Boolean
    begin
        exit(IsProjectsEnabled());
    end;

    /// <summary>
    /// Emits one buffer row per enum value with its derived boolean state.
    /// The Capability Name column holds the enum value identifier.
    /// </summary>
    internal procedure Populate(var ExpenseCapabilitiesBuffer: Record "Expense Capabilities Buffer" temporary)
    var
        ExpenseCapability: Enum "Expense Capability";
        CapabilityValueIndex: Integer;
        CapabilityNames: List of [Text];
        CapabilityOrdinals: List of [Integer];
        i: Integer;
    begin
        ExpenseCapabilitiesBuffer.Reset();
        ExpenseCapabilitiesBuffer.DeleteAll();

        CapabilityNames := ExpenseCapability.Names();
        CapabilityOrdinals := ExpenseCapability.Ordinals();

        for i := 1 to CapabilityOrdinals.Count() do begin
            CapabilityValueIndex := CapabilityOrdinals.Get(i);
            ExpenseCapability := Enum::"Expense Capability".FromInteger(CapabilityValueIndex);

            ExpenseCapabilitiesBuffer.Init();
            ExpenseCapabilitiesBuffer."Capability Name" := CopyStr(CapabilityNames.Get(i), 1, MaxStrLen(ExpenseCapabilitiesBuffer."Capability Name"));
            ExpenseCapabilitiesBuffer."Is Enabled" := IsEnabled(ExpenseCapability);
            ExpenseCapabilitiesBuffer.Insert();
        end;
    end;
}
