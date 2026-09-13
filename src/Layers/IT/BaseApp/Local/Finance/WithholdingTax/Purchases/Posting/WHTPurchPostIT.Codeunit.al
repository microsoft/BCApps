// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Posting;

using Microsoft.Bank.Payment;
using Microsoft.Finance.WithholdingTax;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;

codeunit 12110 "WHT Purch.-Post IT"
{

    var
        WithhSocSec: Record "Purch. Withh. Contribution";
        CompWithhTax: Record "Computed Withholding Tax";
        CompSocSec: Record "Computed Contribution";

        ValueMustBeHigherhanZeroErr: Label '%1 the value in withholding tax must be higher than 0 when %2 is not blank.', Comment = '%1 - Withholding Tax Code, %2 - Total Amount';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforeCheckPostRestrictions', '', true, false)]
    local procedure OnBeforeCheckPostRestrictions(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
        CheckWithholdingTaxTotalAmount(PurchaseHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterDeleteAfterPosting', '', true, false)]
    local procedure OnAfterDeleteAfterPosting(PurchHeader: Record "Purchase Header"; PurchInvHeader: Record "Purch. Inv. Header"; PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; CommitIsSupressed: Boolean)
    begin
        if WithhSocSec.Get(PurchHeader."Document Type", PurchHeader."No.") then
            PostWithhSocSec(PurchHeader, PurchInvHeader."No.");

        WithhSocSec.SetRange("Document Type", PurchHeader."Document Type");
        WithhSocSec.SetRange("No.", PurchHeader."No.");
        WithhSocSec.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure PostWithhSocSec(PurchHeader: Record "Purchase Header"; GenJnlLineDocNo: Code[20])
    begin
        if WithhSocSec."Withholding Tax Code" <> '' then begin
            CompWithhTax.Init();
            CompWithhTax."Document Date" := PurchHeader."Document Date";
            CompWithhTax."Document No." := GenJnlLineDocNo;
            CompWithhTax."Posting Date" := PurchHeader."Posting Date";
            CompWithhTax."External Document No." := PurchHeader."Vendor Invoice No.";
            CompWithhTax."Vendor No." := PurchHeader."Buy-from Vendor No.";
            CompWithhTax."Total Amount" := GetCompWithhTaxTotalAmount();
            CompWithhTax."Remaining Amount" := GetCompWithhTaxTotalAmount();
            CompWithhTax."Base - Excluded Amount" := WithhSocSec."Base - Excluded Amount";
            CompWithhTax."Remaining - Excluded Amount" := WithhSocSec."Base - Excluded Amount";
            CompWithhTax."Non Taxable Amount By Treaty" := WithhSocSec."Non Taxable Amount By Treaty";
            CompWithhTax."Non Taxable Remaining Amount" := WithhSocSec."Non Taxable Amount By Treaty";
            CompWithhTax."Withholding Tax Code" := WithhSocSec."Withholding Tax Code";
            CompWithhTax."Related Date" := WithhSocSec."Date Related";
            CompWithhTax."Payment Date" := WithhSocSec."Payment Date";
            CompWithhTax."Currency Code" := WithhSocSec."Currency Code";
            CompWithhTax."WHT Amount Manual" := WithhSocSec."WHT Amount Manual";
            OnPostWithhSocSecOnBeforeCompWithhTaxInsert(CompWithhTax, WithhSocSec);
            CompWithhTax.Insert();
            if (WithhSocSec."Social Security Code" <> '') or
               (WithhSocSec."INAIL Code" <> '')
            then begin
                CompSocSec.Init();
                CompSocSec."Document Date" := PurchHeader."Document Date";
                CompSocSec."Document No." := GenJnlLineDocNo;
                CompSocSec."Posting Date" := PurchHeader."Posting Date";
                CompSocSec."External Document No." := PurchHeader."Vendor Invoice No.";
                CompSocSec."Vendor No." := PurchHeader."Buy-from Vendor No.";
                CompSocSec."Social Security Code" := WithhSocSec."Social Security Code";
                CompSocSec."Gross Amount" := WithhSocSec."Gross Amount";
                CompSocSec."Soc.Sec.Non Taxable Amount" := WithhSocSec."Soc.Sec.Non Taxable Amount";
                CompSocSec."Free-Lance Amount" := WithhSocSec."Free-Lance Amount";
                CompSocSec."Remaining Gross Amount" := WithhSocSec."Gross Amount";
                CompSocSec."Remaining Soc.Sec. Non Taxable" := WithhSocSec."Soc.Sec.Non Taxable Amount";
                CompSocSec."Remaining Free-Lance Amount" := WithhSocSec."Free-Lance Amount";
                CompSocSec."Currency Code" := WithhSocSec."Currency Code";
                CompSocSec."INAIL Code" := WithhSocSec."INAIL Code";
                CompSocSec."INAIL Gross Amount" := WithhSocSec."INAIL Gross Amount";
                CompSocSec."INAIL Non Taxable Amount" := WithhSocSec."INAIL Non Taxable Amount";
                CompSocSec."INAIL Free-Lance Amount" := WithhSocSec."INAIL Free-Lance Amount";
                CompSocSec."INAIL Remaining Gross Amount" := WithhSocSec."INAIL Gross Amount";
                CompSocSec."INAIL Rem. Non Tax. Amount" := WithhSocSec."INAIL Non Taxable Amount";
                CompSocSec."INAIL Rem. Free-Lance Amount" := WithhSocSec."INAIL Free-Lance Amount";
                CompSocSec.Insert();
            end;
        end;
    end;


    local procedure CheckWithholdingTaxTotalAmount(var PurchHeader: Record "Purchase Header")
    begin
        if PurchHeader.Invoice then
            if WithhSocSec.Get(PurchHeader."Document Type", PurchHeader."No.") and
               (WithhSocSec."Withholding Tax Code" <> '') and
               (WithhSocSec."Total Amount" = 0) and
               (PurchHeader."Document Type" = PurchHeader."Document Type"::Invoice)
            then
                Error(ValueMustBeHigherhanZeroErr,
                  WithhSocSec.FieldCaption("Total Amount"), WithhSocSec.FieldCaption("Withholding Tax Code"));

        OnAfterCheckWithholdingTaxTotalAmount(WithhSocSec, PurchHeader);
    end;

    local procedure GetCompWithhTaxTotalAmount(): Decimal
    begin
        if WithhSocSec."Document Type" <> WithhSocSec."Document Type"::"Credit Memo" then
            exit(WithhSocSec."Total Amount");

        exit(-WithhSocSec."Total Amount");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckWithholdingTaxTotalAmount(var WithhSocSec: Record "Purch. Withh. Contribution"; var PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostWithhSocSecOnBeforeCompWithhTaxInsert(var ComputedWithholdingTax: Record "Computed Withholding Tax"; PurchWithhContribution: Record "Purch. Withh. Contribution")
    begin
    end;

}