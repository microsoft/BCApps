// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import.Purchase;

using Microsoft.Bank.Reconciliation;

/// <summary>
/// Selects Text-to-Account Mapping candidates that are applicable to a given line description and vendor.
/// Only records whose Mapping Text is a case-insensitive substring of the line description are returned;
/// this prevents unrelated mappings from being presented as candidates when an invoice line is being matched.
/// </summary>
codeunit 6245 "E-Doc. TTA Candidate Filter"
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    /// <summary>
    /// Populates TempTextToAccMapping with Text-to-Account Mapping records that satisfy both:
    ///   1. Vendor No. is blank (global mapping) or equals VendorNo.
    ///   2. Mapping Text is a case-insensitive substring of LineDescription.
    /// The caller-supplied temporary table is cleared and reset before population.
    /// </summary>
    procedure GetCandidates(LineDescription: Text[250]; VendorNo: Code[20]; var TempTextToAccMapping: Record "Text-to-Account Mapping" temporary)
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
    begin
        TempTextToAccMapping.Reset();
        TempTextToAccMapping.DeleteAll();

        if LineDescription = '' then
            exit;

        TextToAccMapping.SetFilter("Vendor No.", '%1|%2', '', VendorNo);
        if not TextToAccMapping.FindSet() then
            exit;

        repeat
            if TextToAccMapping."Mapping Text" <> '' then
                if StrPos(UpperCase(LineDescription), UpperCase(TextToAccMapping."Mapping Text")) > 0 then begin
                    TempTextToAccMapping := TextToAccMapping;
                    TempTextToAccMapping.Insert();
                end;
        until TextToAccMapping.Next() = 0;
    end;
}
