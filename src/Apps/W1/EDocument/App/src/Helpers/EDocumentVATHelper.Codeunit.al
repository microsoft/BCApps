// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.Finance.VAT.Clause;
using Microsoft.Finance.VAT.Setup;

codeunit 6403 "E-Document VAT Helper"
{
    procedure GetVATClauseInfo(VATBusPostingGroup: Code[20]; VATProductPostingGroup: Code[20]; LanguageCode: Code[10]; var VATEXCode: Text; var VATClauseDescription: Text)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATClause: Record "VAT Clause";
    begin
        VATEXCode := '';
        VATClauseDescription := '';
        if not VATPostingSetup.Get(VATBusPostingGroup, VATProductPostingGroup) then
            exit;
        if VATPostingSetup."VAT Clause Code" = '' then
            exit;
        if not VATClause.Get(VATPostingSetup."VAT Clause Code") then
            exit;
        VATClause.TranslateDescription(LanguageCode);
        VATEXCode := VATClause."VATEX Code";
        VATClauseDescription := VATClause.Description;
    end;
}
