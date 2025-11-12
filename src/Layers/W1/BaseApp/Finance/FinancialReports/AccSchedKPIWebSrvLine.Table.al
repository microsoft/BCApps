// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

table 136 "Acc. Sched. KPI Web Srv. Line"
{
    Caption = 'Acc. Sched. KPI Web Srv. Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Acc. Schedule Name"; Code[10])
        {
            Caption = 'Row Definition Name';
            NotBlank = true;
            TableRelation = "Acc. Schedule Name";
        }
        field(2; "Acc. Schedule Description"; Text[80])
        {
            CalcFormula = lookup("Acc. Schedule Name".Description where(Name = field("Acc. Schedule Name")));
            Caption = 'Row Definition Description';
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

