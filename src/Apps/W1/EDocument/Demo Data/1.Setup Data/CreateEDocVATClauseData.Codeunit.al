// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.DemoData;

using Microsoft.DemoData.Finance;
using Microsoft.Finance.VAT.Clause;

codeunit 5398 "Create E-Doc. VAT Clause Data"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        UpdateVATClauseVATEXCodes();
    end;

    local procedure UpdateVATClauseVATEXCodes()
    var
        VATClause: Record "VAT Clause";
        CreateVATPostingGroups: Codeunit "Create VAT Posting Groups";
    begin
        if VATClause.Get(CreateVATPostingGroups.NoVAT()) then begin
            VATClause."VATEX Code" := VATEXCodeNoVATLbl;
            VATClause.Modify();
        end;
    end;

    var
        VATEXCodeNoVATLbl: Label 'VATEX-EU-O', MaxLength = 30, Locked = true;
}
