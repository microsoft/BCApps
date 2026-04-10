// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

table 1431 "Named Forward Link"
{
    Caption = 'Named Forward Link';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Name; Code[30])
        {
            Caption = 'Name';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(3; Link; Text[250])
        {
            Caption = 'Link';
            DataClassification = SystemMetadata;
            ExtendedDatatype = URL;
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure Load()
    begin
        OnLoad();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLoad()
    begin
    end;
}

