// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Catalog;

table 5719 "Nonstock Item Setup"
{
    Caption = 'Nonstock Item Setup';
    DataClassification = CustomerContent;
    DrillDownPageID = "Catalog Item Setup";
    LookupPageID = "Catalog Item Setup";

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "No. Format"; Enum "Nonstock Item No. Format")
        {
            Caption = 'No. Format';
            trigger OnValidate()
            begin
                if "No. Format" = "No. Format"::"Item No. Series" then
                    "No. Format Separator" := '';
            end;
        }
        field(3; "No. Format Separator"; Code[1])
        {
            Caption = 'No. Format Separator';
            trigger OnValidate()
            begin
                if "No. Format" = "No. Format"::"Item No. Series" then
                    if "No. Format Separator" <> '' then
                        FieldError("No. Format");
            end;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

