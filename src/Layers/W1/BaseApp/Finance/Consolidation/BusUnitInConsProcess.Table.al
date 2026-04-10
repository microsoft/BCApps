// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

/// <summary>
/// Tracks business units participating in consolidation processes with exchange rates and status information.
/// Maintains consolidation process state and currency exchange rate history for business unit processing.
/// </summary>
/// <remarks>
/// Links business units to consolidation processes for tracking progress and maintaining exchange rate context.
/// Used for monitoring consolidation status and preserving historical exchange rate information during processing.
/// </remarks>
table 1831 "Bus. Unit In Cons. Process"
{
    Caption = 'Business Unit in Consolidation Process';
    ReplicateData = false;
    Extensible = false;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Identifier linking this business unit to a specific consolidation process instance.
        /// </summary>
        field(1; "Consolidation Process Id"; Integer)
        {
            TableRelation = "Consolidation Process";
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Code of the business unit participating in the consolidation process.
        /// </summary>
        field(2; "Business Unit Code"; Code[20])
        {
            ToolTip = 'Specifies the code of the business unit.';
            TableRelation = "Business Unit";
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Default data import method configured for this business unit (Database or API).
        /// </summary>
        field(3; "Default Data Import Method"; Option)
        {
            OptionCaption = 'Database,API';
            OptionMembers = Database,API;
            FieldClass = FlowField;
            CalcFormula = lookup("Business Unit"."Default Data Import Method" where(Code = field("Business Unit Code")));
        }
        /// <summary>
        /// Current status of the business unit in the consolidation process workflow.
        /// </summary>
        field(4; "Status"; Option)
        {
            OptionCaption = 'Not started,Importing data,Consolidating,Finished,Error';
            ToolTip = 'Specifies the status of the business unit in the consolidation process.';
            OptionMembers = NotStarted,ImportingData,Consolidating,Finished,Error;
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Average exchange rate used for income statement translation during consolidation.
        /// </summary>
        field(5; "Average Exchange Rate"; Decimal)
        {
            ToolTip = 'Specifies the average exchange rate of the business unit.';
            AutoFormatType = 0;
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Closing exchange rate used for balance sheet translation during consolidation.
        /// </summary>
        field(6; "Closing Exchange Rate"; Decimal)
        {
            ToolTip = 'Specifies the closing exchange rate of the business unit.';
            AutoFormatType = 0;
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Previous period's closing exchange rate for comparison and validation purposes.
        /// </summary>
        field(7; "Last Closing Exchange Rate"; Decimal)
        {
            ToolTip = 'Specifies the last closing exchange rate considered when adjusting balances in re-runs for this business unit.';
            AutoFormatType = 0;
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Source of currency exchange rates for this business unit (Local or Business Unit specific).
        /// </summary>
        field(8; "Currency Exchange Rate Table"; Option)
        {
            DataClassification = CustomerContent;
            OptionMembers = "Local","Business Unit";
            OptionCaption = 'Local,Business Unit';
            ToolTip = 'Specifies the currency exchange rate table of the business unit.';
        }
        /// <summary>
        /// Starting date for the consolidation period being processed.
        /// </summary>
        field(9; "Starting Date"; Date)
        {
            ToolTip = 'Specifies the starting date of the consolidation.';
            FieldClass = FlowField;
            CalcFormula = lookup("Consolidation Process"."Starting Date" where(Id = field("Consolidation Process Id")));
        }
        /// <summary>
        /// Ending date for the consolidation period being processed.
        /// </summary>
        field(10; "Ending Date"; Date)
        {
            ToolTip = 'Specifies the ending date of the consolidation.';
            FieldClass = FlowField;
            CalcFormula = lookup("Consolidation Process"."Ending Date" where(Id = field("Consolidation Process Id")));
        }
        /// <summary>
        /// Currency code of the business unit for exchange rate calculations and translation.
        /// </summary>
        field(11; "Currency Code"; Code[10])
        {
            ToolTip = 'Specifies the currency code of the business unit.';
            DataClassification = CustomerContent;
        }
    }
    keys
    {
        key(Key1; "Consolidation Process Id", "Business Unit Code")
        {
            Clustered = true;
        }
    }
}
