// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.GeneralLedger.Setup;
using System.Environment;
using System.Telemetry;

table 11603 "BAS Business Unit"
{
    Caption = 'BAS Business Unit';
    DataClassification = CustomerContent;

    fields
    {
        field(2; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
            NotBlank = true;
            TableRelation = Company.Name;
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                FeatureTelemetry.LogUptake('0000HK6', APACBASTok, Enum::"Feature Uptake Status"::"Used");
                FeatureTelemetry.LogUsage('0000HK7', APACBASTok, 'APAC Business Activity Statement Completed');
            end;
        }
        field(4; "BAS Version"; Integer)
        {
            Caption = 'BAS Version';

            trigger OnLookup()
            begin
                if "Company Name" <> CompanyName then
                    BASCalcSheet.ChangeCompany("Company Name");
                BASCalcSheet.SetRange(A1, "Document No.");
                if PAGE.RunModal(PAGE::"BAS Calc. Schedule List", BASCalcSheet, BASCalcSheet."BAS Version") = ACTION::LookupOK then
                    Validate("BAS Version", BASCalcSheet."BAS Version");
            end;

            trigger OnValidate()
            begin
                if "Company Name" <> CompanyName then
                    BASCalcSheet.ChangeCompany("Company Name");
                BASCalcSheet.Get("Document No.", "BAS Version");
            end;
        }
        field(5; "Document No."; Code[11])
        {
            Caption = 'Document No.';

            trigger OnLookup()
            begin
                if "Company Name" <> CompanyName then
                    BASCalcSheet.ChangeCompany("Company Name");
                if PAGE.RunModal(PAGE::"BAS Calc. Schedule List", BASCalcSheet, BASCalcSheet.A1) = ACTION::LookupOK then
                    Validate("Document No.", BASCalcSheet.A1);
                "BAS Version" := BASCalcSheet."BAS Version";
            end;

            trigger OnValidate()
            begin
                if "Document No." <> '' then begin
                    if "Company Name" <> CompanyName then
                        BASCalcSheet.ChangeCompany("Company Name");
                    BASCalcSheet.SetRange(A1, "Document No.");
                    BASCalcSheet.FindFirst();
                end else
                    "BAS Version" := 0;
            end;
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

    trigger OnInsert()
    begin
        GLSetup.Get();
        GLSetup.TestField("BAS Group Company", true);
    end;

    trigger OnModify()
    begin
        GLSetup.Get();
        GLSetup.TestField("BAS Group Company", true);
    end;

    var
        GLSetup: Record "General Ledger Setup";
        BASCalcSheet: Record "BAS Calculation Sheet";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        APACBASTok: Label 'APAC Business Activity Statement', Locked = true;
}
