// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Finance.VAT.Clause;
using Microsoft.Finance.VAT.Setup;

codeunit 37222 "PEPPOL VAT Helper"
{
    /// <summary>
    /// Resolves VAT Bus./Prod. Posting Group to VATEX Code and VAT Clause Description.
    /// If a translation exists for the given language code, the translated description is returned.
    /// </summary>
    /// <param name="VATBusPostingGroup">The VAT Business Posting Group code.</param>
    /// <param name="VATProductPostingGroup">The VAT Product Posting Group code.</param>
    /// <param name="LanguageCode">The language code for VAT Clause description translation. Empty for default.</param>
    /// <param name="VATEXCode">Return value: the VATEX exemption reason code from the VAT Clause.</param>
    /// <param name="VATClauseDescription">Return value: the VAT Clause description, translated if available.</param>
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
