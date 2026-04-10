// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using System.Reflection;
using System.Security.AccessControl;

table 1182 "Journal User Preferences"
{
    Caption = 'Journal User Preferences';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Integer)
        {
            AutoIncrement = true;
            Caption = 'ID';
            Editable = false;
            NotBlank = true;
        }
        field(2; "Page ID"; Integer)
        {
            Caption = 'Page ID';
            NotBlank = true;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Page));
        }
        field(3; "User ID"; Guid)
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Security ID" where("License Type" = const("Full User"));
        }
        field(4; "Is Simple View"; Boolean)
        {
            Caption = 'Is Simple View';
        }
        field(5; User; Code[50])
        {
            CalcFormula = lookup(User."User Name" where("User Security ID" = field("User ID"),
                                                         "License Type" = const("Full User")));
            Caption = 'User';
            FieldClass = FlowField;
        }
        field(6; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
    }

    keys
    {
        key(Key1; ID, "Page ID", "User ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        "User ID" := UserSecurityId();
    end;
}

