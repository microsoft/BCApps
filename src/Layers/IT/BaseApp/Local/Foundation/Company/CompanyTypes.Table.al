// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Company;

table 12169 "Company Types"
{
    Caption = 'FatturaPA Fiscal Regimes';
    DrillDownPageID = "Company Types";
    LookupPageID = "Company Types";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[2])
        {
            Caption = 'Code';
            NotBlank = true;

            trigger OnValidate()
            begin
                if not IsValidFatturaPAFiscalRegimeCode(Code) then
                    Error(InvalidFiscalRegimeCodeErr, Code);
            end;
        }
        field(2; Description; Text[30])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure IsValidFatturaPAFiscalRegimeCode(FiscalRegimeCode: Code[2]): Boolean
    begin
        case FiscalRegimeCode of
            '01', '02', '03', '04', '05', '06', '07', '08', '09',
            '10', '11', '12', '13', '14', '15', '16', '17', '18', '19':
                exit(true);
        end;

        exit(false);
    end;

    var
        InvalidFiscalRegimeCodeErr: Label '%1 is not a valid FatturaPA fiscal regime code. Select a code from 01 through 19.', Comment = '%1 = invalid fiscal regime code';
}

