// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

codeunit 11000008 "Check BBV"
{
    // BBV Controle

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
                        Rec."Error Message" := StrSubstNo(Text1000000,
                            Rec.FieldCaption(Amount),
                            Rec.FieldCaption("Nature of the Payment"));
                        exit;
                    end;
                Rec."Nature of the Payment"::"Transito Trade":
                    if (Rec."Item No." = '') or (Rec."Traders No." = '') then begin
                        Rec."Error Message" := StrSubstNo(Text1000001,
                            Rec.FieldCaption("Nature of the Payment"),
                            Rec.FieldCaption("Item No."),
                            Rec.FieldCaption("Traders No."));
                        exit;
                    end;
                Rec."Nature of the Payment"::"Invisible- and Capital Transactions":
                    if Rec."Description Payment" = '' then begin
                        Rec."Error Message" := StrSubstNo(Text1000002,
                            Rec.FieldCaption("Nature of the Payment"),
                            Rec.FieldCaption("Description Payment"));
                        exit;
                    end;
                Rec."Nature of the Payment"::"Transfer to Own Account",
              Rec."Nature of the Payment"::"Other Registrated BFI":
                    if (Rec."Description Payment" = '') or
                       (Rec."Registration No. DNB" = '')
                    then begin
                        Rec."Error Message" :=
                          StrSubstNo(
                            Text1000003,
                            Rec.FieldCaption("Nature of the Payment"),
                            Rec.FieldCaption("Description Payment"),
                            Rec.FieldCaption("Registration No. DNB"));
                        exit;
                    end;
            end;

        if Rec."Transfer Cost Domestic" = Rec."Transfer Cost Domestic"::"Balancing Account Holder" then
            Rec.Warning := Text1000005;

        if (Rec."Bank Name" = '') or (Rec."Bank City" = '') then begin
            Rec."Error Message" := StrSubstNo(Text1000004,
                Rec.FieldCaption("Bank Name"),
                Rec.FieldCaption("Bank City"));
            exit;
        end;

        if Rec."Bank Name" = '' then begin
            Rec."Error Message" := StrSubstNo(Text1000006, Rec.FieldCaption("Bank Name"));
            exit;
        end;

        if Rec."Bank City" = '' then begin
            Rec."Error Message" := StrSubstNo(Text1000006, Rec.FieldCaption("Bank City"));
            exit;
        end;

        if Rec."Account Holder Address" = '' then begin
            Rec."Error Message" := StrSubstNo(Text1000006, Rec.FieldCaption("Account Holder Address"));
            exit;
        end;

        if Rec."Acc. Hold. Country/Region Code" = '' then begin
            Rec."Error Message" := StrSubstNo(Text1000006, Rec.FieldCaption("Acc. Hold. Country/Region Code"));
            exit;
        end;

        if Rec."Bank Country/Region Code" = '' then begin
            Rec."Error Message" := StrSubstNo(Text1000006, Rec.FieldCaption("Bank Country/Region Code"));
            exit;
        end;
    end;

    var
        Text1000000: Label '%1 exceeds the maximum limit, %2 must be filled in';
        Text1000001: Label '%1 is transito trade, %2 and %3 must be filled in';
        Text1000002: Label '%1 is invisible- and capital transactions, %2 must be filled in';
        Text1000003: Label '%1 is transfer or sundry, %2 and %3 must be filled in';
        Text1000004: Label '%1 and %2  must be filled in';
        Text1000005: Label 'With protocol BBV, the domestic transfer cost always are for the principal';
        Text1000006: Label '%1 must be filled in';
}

