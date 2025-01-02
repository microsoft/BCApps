#if not CLEANSCHEMA23
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Environment.Configuration;

using System.Media;
using System.Globalization;
using System.Apps;

table 1803 "Assisted Setup"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Caption = 'Assisted Setup';
    ReplicateData = false;
    ObsoleteState = Removed;
    ObsoleteTag = '23.0';
    ObsoleteReason = 'The Assisted Setup module and its objects have been consolidated in the Guided Experience module. Use the Guided Experience Item table instead.';

    fields
    {
        field(1; "Page ID"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Page ID';
        }
        field(2; Name; Text[2048])
        {
            DataClassification = SystemMetadata;
            Caption = 'Name';
        }
        field(7; "Video Url"; Text[250])
        {
            DataClassification = SystemMetadata;
            Caption = 'Video Url';
        }
        field(8; Icon; Media)
        {
            DataClassification = SystemMetadata;
            Caption = 'Icon';
        }
        field(11; "Help Url"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Help Url';
        }
        field(19; "App ID"; Guid)
        {
            Caption = 'App ID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(20; "Extension Name"; Text[250])
        {
            Caption = 'Extension Name';
            FieldClass = FlowField;
            CalcFormula = lookup("Published Application".Name where(ID = field("App ID"), "Tenant Visible" = const(true)));
            Editable = false;
        }
        field(21; "Group Name"; Enum "Assisted Setup Group")
        {
            DataClassification = SystemMetadata;
            Caption = 'Group';
            Editable = false;
        }
        field(22; Completed; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Completed';
            Editable = false;
        }
        field(23; "Video Category"; Enum "Video Category")
        {
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(24; Description; Text[1024])
        {
            DataClassification = CustomerContent;
            Caption = 'Description';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Page ID")
        {
            Clustered = true;
        }
    }


    trigger OnDelete()
    var
        Translation: Codeunit Translation;
    begin
        Translation.Delete(Rec);
    end;
}
#endif