// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Company;

using Microsoft.Finance.VAT.Registration;

tableextension 11379 "Company Information NL" extends "Company Information"
{
    fields
    {
        field(11400; "Fiscal Entity No."; Text[20])
        {
            Caption = 'Fiscal Entity No.';
            DataClassification = OrganizationIdentifiableInformation;

            trigger OnValidate()
            var
                VATRegNoFormat: Record "VAT Registration No. Format";
            begin
                VATRegNoFormat.Test("Fiscal Entity No.", "Country/Region Code", '', DATABASE::"Company Information");
            end;
        }
    }

    procedure GetVATIdentificationNo(PartOfFiscalEntity: Boolean) Result: Text[20]
    begin
        Get();
        if PartOfFiscalEntity then
            Result := "Fiscal Entity No."
        else
            Result := "VAT Registration No.";
        if CopyStr(UpperCase(Result), 1, 2) = 'NL' then
            Result := DelStr(Result, 1, 2);
    end;
}

