#if not CLEANSCHEMA25 
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

using System.Reflection;

table 8452 "Advanced Intrastat Checklist"
{
    Caption = 'Advanced Intrastat Checklist';
    ObsoleteState = Removed;
    ObsoleteTag = '25.0';
    ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Object Type"; Option)
        {
            Caption = 'Object Type';
            OptionMembers = ,,,Report,,Codeunit;
        }
        field(2; "Object Id"; Integer)
        {
            Caption = 'Object Id';
        }
        field(3; "Object Name"; Text[250])
        {
            Caption = 'Object Name';
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = field("Object Type"), "Object ID" = field("Object Id")));
        }
        field(4; "Field No."; Integer)
        {
            Caption = 'Field No.';
            NotBlank = true;
        }
        field(5; "Field Name"; Text[250])
        {
            Caption = 'Field Name';
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = lookup(Field."Field Caption" where(TableNo = const(263), "No." = field("Field No.")));
        }
        field(6; "Filter Expression"; Text[1024])
        {
            Caption = 'Filter Expression';
        }
        field(7; "Record View String"; Text[1024])
        {
            Caption = 'Record View String';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(8; "Reversed Filter Expression"; Boolean)
        {
            Caption = 'Reversed Filter Expression';
        }
    }

    keys
    {
        key(Key1; "Object Type", "Object Id", "Field No.")
        {
            Clustered = true;
        }
    }
}

 
#endif
