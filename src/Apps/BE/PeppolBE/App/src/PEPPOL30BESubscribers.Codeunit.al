// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol.BE;

using Microsoft.Finance.VAT.Calculation;
using Microsoft.Peppol;

codeunit 37314 "PEPPOL30 BE Subscribers"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Access = Internal;

    [EventSubscriber(ObjectType::Table, Database::"PEPPOL 3.0 Setup", OnAfterInsertEvent, '', false, false)]
    local procedure OnAfterInsertPEPPOL30Setup(var Rec: Record "PEPPOL 3.0 Setup"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        Rec."PEPPOL 3.0 Sales Format" := Rec."PEPPOL 3.0 Sales Format"::"PEPPOL 3.0 - BE Sales";
        Rec."PEPPOL 3.0 Service Format" := Rec."PEPPOL 3.0 Service Format"::"PEPPOL 3.0 - BE Service";
        Rec.Modify();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"PEPPOL30 Common", 'OnAfterGetSalesTotals', '', false, false)]
    local procedure OnAfterGetSalesTotalsRemovePaymentDiscount(PostedDocHeaderRecRef: RecordRef; var TempVATAmtLine: Record "VAT Amount Line" temporary; PEPPOLFormat: Enum "PEPPOL 3.0 Format")
    begin
        // In Belgium the payment discount must not reduce the PEPPOL document totals, so the XML matches
        // the invoice printout and VAT is reported on the full amount. Clearing the payment discount on the
        // VAT amount line buffer keeps TaxableAmount, TaxExclusiveAmount, TaxInclusiveAmount, PayableAmount and
        // the payment discount AllowanceCharge aligned with the printout.
        if not (PEPPOLFormat in [PEPPOLFormat::"PEPPOL 3.0 - BE Sales", PEPPOLFormat::"PEPPOL 3.0 - BE Service"]) then
            exit;

        if TempVATAmtLine.FindSet() then
            repeat
                if TempVATAmtLine."Pmt. Discount Amount" <> 0 then begin
                    TempVATAmtLine."Pmt. Discount Amount" := 0;
                    TempVATAmtLine.Modify();
                end;
            until TempVATAmtLine.Next() = 0;
    end;
}
