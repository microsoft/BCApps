// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Setup;

using System.Reflection;

table 856 "Cash Flow Report Selection"
{
    Caption = 'Cash Flow Report Selection';
    DataClassification = CustomerContent;

    fields
    {
        field(2; Sequence; Code[10])
        {
            Caption = 'Sequence';
            Numeric = true;
        }
        field(3; "Report ID"; Integer)
        {
            Caption = 'Report ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));

            trigger OnValidate()
            begin
                CalcFields("Report Caption");
            end;
        }
        field(4; "Report Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Report),
                                                                           "Object ID" = field("Report ID")));
            Caption = 'Report Caption';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; Sequence)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        CashFlowReportSelection: Record "Cash Flow Report Selection";

    procedure NewRecord()
    begin
        if CashFlowReportSelection.FindLast() and (CashFlowReportSelection.Sequence <> '') then
            Sequence := IncStr(CashFlowReportSelection.Sequence)
        else
            Sequence := '1';
    end;
}

