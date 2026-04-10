// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

/// <summary>
/// Temporary table for managing consolidation process data and codeunit instances during business unit consolidation operations.
/// Contains process identification and business unit context for consolidation workflows.
/// </summary>
/// <remarks>
/// Used internally during consolidation processing to maintain state and context across consolidation operations.
/// Links consolidation process instances with specific business units for tracking and management.
/// </remarks>
table 141 "Bus. Unit Consolidation Data"
{
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the consolidation process instance.
        /// </summary>
        field(1; "Consolidation Process Id"; Integer)
        {
        }
        /// <summary>
        /// Code of the business unit being processed in this consolidation operation.
        /// </summary>
        field(2; "Business Unit Code"; Code[20])
        {
        }
    }

    var
        Consolidate: Codeunit Consolidate;

    /// <summary>
    /// Retrieves the consolidation codeunit instance associated with this data record.
    /// </summary>
    /// <param name="ConsolidateToGet">Variable to receive the consolidation codeunit instance</param>
    procedure GetConsolidate(var ConsolidateToGet: Codeunit Consolidate)
    begin
        ConsolidateToGet := Consolidate;
    end;

    /// <summary>
    /// Sets the consolidation codeunit instance for this data record.
    /// </summary>
    /// <param name="ConsolidateToSet">Consolidation codeunit instance to store</param>
    procedure SetConsolidate(var ConsolidateToSet: Codeunit Consolidate)
    begin
        Consolidate := ConsolidateToSet;
    end;


}
