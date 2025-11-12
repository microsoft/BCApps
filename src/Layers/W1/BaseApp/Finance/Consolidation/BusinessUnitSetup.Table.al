// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using System.Environment;
using System.Globalization;

table 1827 "Business Unit Setup"
{
    Caption = 'Business Unit Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
        }
        field(2; Include; Boolean)
        {
            Caption = 'Include';
        }
        field(3; Completed; Boolean)
        {
            Caption = 'Completed';
        }
    }

    keys
    {
        key(Key1; "Company Name")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Company: Record Company;

    procedure FillTable(ConsolidatedCompany: Text[30])
    var
        Language: Record Language;
    begin
        Company.SetFilter(Name, '<>%1', ConsolidatedCompany);
        if not Company.FindSet() then
            exit;

        Language.Init();

        if Company.FindSet() then
            repeat
                // Use a table that all users can access, and check whether users have permissions to open the company.
                if Language.ChangeCompany(Company.Name) then begin
                    "Company Name" := Company.Name;
                    Include := true;
                    Insert();
                end;
            until Company.Next() = 0;
    end;
}

