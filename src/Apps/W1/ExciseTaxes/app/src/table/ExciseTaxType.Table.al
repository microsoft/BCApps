// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExciseTaxes;

table 7412 "Excise Tax Type"
{
    Caption = 'Excise Tax Type';
    DataClassification = CustomerContent;
    LookupPageId = "Excise Tax Types";
    DrillDownPageId = "Excise Tax Types";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Tax Basis"; Enum "Excise Tax Basis")
        {
            Caption = 'Tax Basis';
        }
        field(4; Enabled; Boolean)
        {
            Caption = 'Enabled';
        }
        field(5; "Report Caption"; Text[50])
        {
            Caption = 'Report Caption';
        }
        field(6; "Bonded Location Treatment"; Enum "Excise Bonded Loc. Treatment")
        {
            Caption = 'Bonded Location Treatment';
            ToolTip = 'Specifies how inventory movements involving bonded locations are treated for excise duty calculations, such as whether excise is ignored, suspended while in bond, or becomes due when goods are released from bond.';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    var
        ExciseTaxEntryPermission: Record "Excise Tax Entry Permission";
        ExciseTaxRate: Record "Excise Tax Rate";
    begin
        ExciseTaxEntryPermission.SetRange("Excise Tax Type Code", Code);
        if not ExciseTaxEntryPermission.IsEmpty() then
            Error(CannotDeleteTaxTypeWithRateConfigurationsErr, Code, ExciseTaxEntryPermission.TableCaption());

        ExciseTaxRate.SetRange("Excise Tax Type Code", Code);
        if not ExciseTaxRate.IsEmpty() then
            Error(CannotDeleteTaxTypeWithRateConfigurationsErr, Code, ExciseTaxRate.TableCaption());
    end;

    var
        CannotDeleteTaxTypeWithRateConfigurationsErr: Label 'Cannot delete tax type %1 because it has rate %2 entries.', Comment = '%1 = Excise Tax Type Code, %2 = Table Caption';
}