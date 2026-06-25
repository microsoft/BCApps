#if not CLEANSCHEMA32
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.CashDesk;

using System.Reflection;

table 11748 "Cash Desk Rep. Selections CZP"
{
    Caption = 'Cash Desk Report Selections';
#if not CLEAN29
    LookupPageId = "Report Selection Cash Desk CZP";
    ObsoleteState = Pending;
    ObsoleteTag = '29.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '32.0';
#endif
    ObsoleteReason = 'The table is replaced by a standard table "Report Selections" to store report selections for cash documents.';

    fields
    {
        field(1; Usage; Enum "Cash Desk Rep. Sel. Usage CZP")
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
        CashDeskRepSelectionsCZP: Record "Cash Desk Rep. Selections CZP";
        ObsoleteTableErr: Label 'The "Cash Desk Rep. Selections CZP" table is replaced by a standard table "Report Selections" to store report selections for cash documents. For insert or modify operations, please use "Report Sel. - Cash Desk CZP" page instead.';

    procedure NewRecord()
    begin
        CashDeskRepSelectionsCZP.SetRange(Usage, Usage);
        if CashDeskRepSelectionsCZP.FindLast() and (CashDeskRepSelectionsCZP.Sequence <> '') then
            Sequence := IncStr(CashDeskRepSelectionsCZP.Sequence)
        else
            Sequence := '1';
    end;
}
#endif