// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using System.Reflection;

table 7000013 "Cartera Report Selections"
{
    Caption = 'Cartera Report Selections';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Usage; Enum "Report Selection Usage Cartera")
        {
            Caption = 'Usage';
        }
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
                CalcFields("Report Name");
            end;
        }
        field(4; "Report Name"; Text[30])
        {
            CalcFormula = lookup(Object.Name where(Type = const(Report),
                                                    ID = field("Report ID")));
            Caption = 'Report Name';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; Usage, Sequence)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        CarteraReportSelection2: Record "Cartera Report Selections";

    [Scope('OnPrem')]
    procedure NewRecord()
    begin
        CarteraReportSelection2.SetRange(Usage, Usage);
        if CarteraReportSelection2.FindLast() and (CarteraReportSelection2.Sequence <> '') then
            Sequence := IncStr(CarteraReportSelection2.Sequence)
        else
            Sequence := '1';
    end;
}

