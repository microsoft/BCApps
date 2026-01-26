// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;

codeunit 11000009 "Check PAYMUL"
{
    TableNo = "Proposal Line";

    trigger OnRun()
    var
        BankAcc: Record "Bank Account";
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
                    if Rec."Description Payment" = '' then begin
                        Rec."Error Message" := StrSubstNo(
                            Text1000003,
                            Rec.FieldCaption("Nature of the Payment"),
                            Rec.FieldCaption("Description Payment"));
                        exit;
                    end;
            end;

        if (BankAcc."Acc. Hold. Country/Region Code" <> Rec."Bank Country/Region Code") and
           ((Rec."Bank Name" = '') or (Rec."Bank City" = ''))
        then begin
            Rec."Error Message" := StrSubstNo(Text1000004,
                Rec.FieldCaption("Bank Name"),
                Rec.FieldCaption("Bank City"));
            exit;
        end;

        if StrLen(Rec."Bank Account No.") <> 10 then
            Rec.Warning := StrSubstNo(Text1000008, Rec.FieldCaption("Bank Account No."));

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

        BankAcc.Get(Rec."Our Bank No.");
        if (Rec."Nature of the Payment" <> Rec."Nature of the Payment"::" ") and
           (BankAcc."Acc. Hold. Country/Region Code" = Rec."Bank Country/Region Code") and
           (Rec.Amount <= FreelyTransferableMaximum.Amount)
        then begin
            Rec.Warning := StrSubstNo(Text1000007,
                FreelyTransferableMaximum.FieldCaption(Amount),
                FreelyTransferableMaximum.TableCaption())
              ;
            exit;
        end;
    end;

    var
        Text1000000: Label '%1 exceeds the maximum limit, %2 must be filled';
        Text1000001: Label '%1 is transito trade, %2 and %3 must be entered';
        Text1000002: Label '%1 is invisible- and capital transactions, %2 must be entered';
        Text1000003: Label '%1 is transfer or sundry, %2 must be entered';
        Text1000004: Label '%1 and %2  must be filled';
        Text1000006: Label '%1 must be filled in';
        Text1000007: Label 'For Domestic transactions below  %1 in %2 , nature of the payment must not be specified.';
        Text1000008: Label 'The %1 should consist of 10 positions.';
}

