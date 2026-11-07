#if not CLEANSCHEMA27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

table 310 "No. Series Relationship"
{
    Caption = 'No. Series Relationship';
    ObsoleteReason = 'No. Series is moved to Business Foundation';
    ObsoleteState = Moved;
    ObsoleteTag = '24.0';
    MovedTo = 'f3552374-a1f2-4356-848e-196002525837';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
            TableRelation = "No. Series";
        }
        field(2; "Series Code"; Code[20])
        {
            Caption = 'Series Code';
            NotBlank = true;
            TableRelation = "No. Series";
        }
        field(3; Description; Text[100])
        {
            CalcFormula = lookup("No. Series".Description where(Code = field(Code)));
            Caption = 'Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Series Description"; Text[100])
        {
            CalcFormula = lookup("No. Series".Description where(Code = field("Series Code")));
            Caption = 'Series Description';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Code", "Series Code")
        {
            Clustered = true;
        }
    }

}
#endif