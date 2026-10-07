// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.VAT.Clause;

tableextension 7000130 "SII VAT Posting Setup" extends "VAT Posting Setup"
{
    fields
    {
        modify("VAT Clause Code")
        {
            trigger OnAfterValidate()
            begin
                CheckSalesSpecialSchemeCode();
            end;
        }
        field(10707; "Sales Special Scheme Code"; Enum "SII Sales Upload Scheme Code")
        {
            Caption = 'Sales Special Scheme Code';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                CheckSalesSpecialSchemeCode();
                "One Stop Shop Reporting" := false;
            end;
        }
        field(10708; "Purch. Special Scheme Code"; Enum "SII Purch. Upload Scheme Code")
        {
            Caption = 'Purch. Special Scheme Code';
            DataClassification = CustomerContent;
        }
        field(10709; "Ignore In SII"; Boolean)
        {
            Caption = 'Ignore In SII';
            DataClassification = CustomerContent;
        }
        field(10780; "One Stop Shop Reporting"; Boolean)
        {
            Caption = 'One Stop Shop Reporting';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestField("VAT Calculation Type", "VAT Calculation Type"::"Normal VAT");
                TestField("Sales Special Scheme Code", "Sales Special Scheme Code"::"17 Operations Under The One-Stop-Shop Regime");
            end;
        }
    }

    var
        InconsistencyOfRegimeCodeAndVATClauseErr: Label 'If the sales special scheme code is 01 General, the SII exemption code of the VAT clause must not be equal to E2 or E3.';

    local procedure CheckSalesSpecialSchemeCode()
    var
        VATClause: Record "VAT Clause";
    begin
        if "Sales Special Scheme Code" = "Sales Special Scheme Code"::" " then
            exit;

        if "VAT Clause Code" = '' then
            exit;

        VATClause.Get("VAT Clause Code");
        if (VATClause."SII Exemption Code" in
            [VATClause."SII Exemption Code"::"E2 Exempt on account of Article 21",
             VATClause."SII Exemption Code"::"E3 Exempt on account of Article 22"]) and
           ("Sales Special Scheme Code" = "Sales Special Scheme Code"::"01 General")
        then
            Error(InconsistencyOfRegimeCodeAndVATClauseErr);
    end;

}