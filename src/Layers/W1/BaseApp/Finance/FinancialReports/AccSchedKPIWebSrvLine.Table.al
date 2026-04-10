// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

/// <summary>
/// Stores account schedule configurations for KPI web service exposure and external system integration.
/// Links account schedules to web service endpoints for external financial data access.
/// </summary>
/// <remarks>
/// Primary usage: Web service configuration, external system KPI data integration.
/// Integration: Links with Account Schedule system and web service publishing functionality.
/// Extensibility: Standard table extension patterns for additional web service properties.
/// </remarks>
table 136 "Acc. Sched. KPI Web Srv. Line"
{
    Caption = 'Acc. Sched. KPI Web Srv. Line';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Account schedule name identifying the row definition for web service exposure.
        /// </summary>
        field(1; "Acc. Schedule Name"; Code[10])
        {
            Caption = 'Row Definition Name';
            ToolTip = 'Specifies the row definition that the KPI web service is based on. To view or edit the selected financial report, choose the Edit Row Definition button.';
            NotBlank = true;
            TableRelation = "Acc. Schedule Name";
        }
        /// <summary>
        /// Description of the associated account schedule retrieved from the account schedule name record.
        /// </summary>
        field(2; "Acc. Schedule Description"; Text[80])
        {
            CalcFormula = lookup("Acc. Schedule Name".Description where(Name = field("Acc. Schedule Name")));
            Caption = 'Row Definition Description';
            ToolTip = 'Specifies the description of the row definition that the KPI web service is based on.';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Acc. Schedule Name")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

