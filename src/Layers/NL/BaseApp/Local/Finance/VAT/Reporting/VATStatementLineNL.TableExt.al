// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

tableextension 11388 "VAT Statement Line NL" extends "VAT Statement Line"
{
    fields
    {
        field(11400; "Elec. Tax Decl. Category Code"; Code[10])
        {
            Caption = 'Elec. Tax Decl. Category Code';
            DataClassification = CustomerContent;
            TableRelation = "Elec. Tax Decl. VAT Category";
        }
    }

    keys
    {
        key(Key2; "Elec. Tax Decl. Category Code")
        {
        }
    }

    procedure UpdateElecTaxDeclCategoryCode()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateElecTaxDeclCategoryCode(Rec, IsHandled);
        if IsHandled then
            exit;

        "Elec. Tax Decl. Category Code" := xRec."Elec. Tax Decl. Category Code";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateElecTaxDeclCategoryCode(var VATStatementLine: Record "VAT Statement Line"; var IsHandled: Boolean)
    begin
    end;
}

