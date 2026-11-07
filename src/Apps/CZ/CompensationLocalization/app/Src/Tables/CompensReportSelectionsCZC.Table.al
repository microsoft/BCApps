#if not CLEANSCHEMA32
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Compensations;

using Microsoft.Foundation.Reporting;
using System.Reflection;

table 31271 "Compens. Report Selections CZC"
{
    Caption = 'Compensation Report Selections';
#if not CLEAN29
    LookupPageId = "Compens. Report Selections CZC";
    ObsoleteState = Pending;
    ObsoleteTag = '29.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '32.0';
#endif
    ObsoleteReason = 'The table is replaced by a standard table "Report Selections" to store report selections for compensations.';

    fields
    {
        field(1; Usage; Enum "Compens. Report Sel. Usage CZC")
        {
            Caption = 'Usage';
            DataClassification = CustomerContent;
        }
        field(2; Sequence; Code[10])
        {
            Caption = 'Sequence';
            Numeric = true;
            DataClassification = CustomerContent;
        }
        field(3; "Report ID"; Integer)
        {
            Caption = 'Report ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                CalcFields("Report Caption");
            end;
        }
        field(4; "Report Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Report), "Object ID" = field("Report ID")));
            Caption = 'Report Caption';
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
        key(Key2; "Report ID")
        {
        }
    }

    trigger OnInsert()
    begin
        Error(ObsoleteTableErr);
    end;

    trigger OnModify()
    begin
        Error(ObsoleteTableErr);
    end;

    var
        LastReportSelections: Record "Report Selections";
        ObsoleteTableErr: Label 'The "Compens. Report Selections CZC" table is replaced by a standard table "Report Selections" to store report selections for compensations. For insert or modify operations, please use "Report Selection - Comp. CZC" page instead.';

    procedure NewRecord()
    begin
        LastReportSelections.SetRange(Usage, Usage);
        if LastReportSelections.FindLast() and (LastReportSelections.Sequence <> '') then
            Sequence := IncStr(LastReportSelections.Sequence)
        else
            Sequence := '1';
    end;
}
#endif