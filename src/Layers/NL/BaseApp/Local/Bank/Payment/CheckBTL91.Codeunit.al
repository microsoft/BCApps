// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

codeunit 11000007 "Check BTL91"
{
    TableNo = "Proposal Line";

    trigger OnRun()
    var
        FreelyTransferableMaximum: Record "Freely Transferable Maximum";
    begin
        FreelyTransferableMaximum.Get(Rec."Acc. Hold. Country/Region Code", Rec."Currency Code");

        if Rec.Amount > FreelyTransferableMaximum.Amount then
            case Rec."Nature of the Payment" of
                Rec."Nature of the Payment"::" ":
                    begin
                        Rec."Error Message" := StrSubstNo(Text1000000, Rec.FieldCaption(Amount), Rec.FieldCaption("Nature of the Payment"));
                        exit;
                    end;
                Rec."Nature of the Payment"::"Transito Trade":
                    if (Rec."Item No." = '') or (Rec."Traders No." = '') then begin
                        Rec."Error Message" :=
                          StrSubstNo(
                            Text1000002,
                            Rec.FieldCaption("Nature of the Payment"),
                            Rec.FieldCaption("Item No."),
                            Rec.FieldCaption("Traders No."));
                        exit;
                    end;
                Rec."Nature of the Payment"::"Invisible- and Capital Transactions":
                    if Rec."Description Payment" = '' then begin
                        Rec."Error Message" := StrSubstNo(Text1000003, Rec.FieldCaption("Nature of the Payment"), Rec.FieldCaption("Description Payment"));
                        exit;
                    end;
                Rec."Nature of the Payment"::"Transfer to Own Account", Rec."Nature of the Payment"::"Other Registrated BFI":
                    if (Rec."Description Payment" = '') or (Rec."Registration No. DNB" = '') then begin
                        Rec."Error Message" :=
                          StrSubstNo(
                            Text1000004,
                            Rec.FieldCaption("Nature of the Payment"),
                            Rec.FieldCaption("Description Payment"),
                            Rec.FieldCaption("Registration No. DNB"));
                        exit;
                    end;
            end;

        if (Rec."Bank Name" = '') or (Rec."Bank City" = '') then begin
            Rec."Error Message" := StrSubstNo(Text1000005, Rec.FieldCaption("Bank Name"), Rec.FieldCaption("Bank City"));
            exit;
        end;

        if (Rec."Bank Country/Region Code" = '') and ((Rec."Bank Name" = '') or (Rec."Bank City" = '')) then begin
            Rec."Error Message" := StrSubstNo(Text1000006,
                Rec.FieldCaption("Bank Country/Region Code"),
                Rec.FieldCaption("Bank Name"),
                Rec.FieldCaption("Bank City"));
            exit;
        end;

        if StrLen(Rec."SWIFT Code") > 11 then
            Rec."Error Message" := StrSubstNo(Text1000008, Rec.FieldCaption("SWIFT Code"));

        if (Rec."Transfer Cost Domestic" = Rec."Transfer Cost Domestic"::"Balancing Account Holder") and
           (Rec."Transfer Cost Foreign" = Rec."Transfer Cost Foreign"::Principal)
        then begin
            Rec."Error Message" := StrSubstNo(Text1000007, Rec.FieldCaption("Transfer Cost Domestic"), Rec.FieldCaption("Transfer Cost Foreign"));
            exit;
        end;

        OnAfterOnRun(Rec);
    end;

    var
        Text1000000: Label '%1 exceeds the maximum limit, %2 must be entered. The default value is ''goods''.';
        Text1000002: Label '%1 is transito trade, %2 and %3 must be filled in';
        Text1000003: Label '%1 is invisible- and capital transactions, %2 must be filled in';
        Text1000004: Label '%1 is transfer or sundry, %2 and %3 must be filled in';
        Text1000005: Label '%1 and %2  must be filled in';
        Text1000006: Label 'When %1 is empty, %3 and %4 must be entered.';
        Text1000007: Label 'When %1 is Beneficiary, %1 and %2 must be equal';
        Text1000008: Label '%1 must not exceed 11 characters.';

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var ProposalLine: Record "Proposal Line")
    begin
    end;
}

