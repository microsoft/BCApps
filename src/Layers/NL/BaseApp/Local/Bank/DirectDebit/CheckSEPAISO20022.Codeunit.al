// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;

codeunit 11000010 "Check SEPA ISO20022"
{
    TableNo = "Proposal Line";

    trigger OnRun()
    begin
        OnBeforeOnRun(Rec);

        // Check Vendor/Customer Bank Account
        if Rec.IBAN = '' then begin
            Rec."Error Message" := StrSubstNo(Text001, Rec.FieldCaption(IBAN), Rec.TableCaption);
            exit;
        end;

        if not CheckSWIFTCode(Rec) then
            exit;

        if Rec."Bank Country/Region Code" = '' then begin
            Rec."Error Message" := StrSubstNo(Text001, Rec.FieldCaption("Bank Country/Region Code"), Rec.TableCaption);
            exit;
        end;

        Country.Get(Rec."Bank Country/Region Code");

        if not Country."SEPA Allowed" then begin
            Rec."Error Message" := StrSubstNo(Text009, Country.FieldCaption("SEPA Allowed"), Country."SEPA Allowed",
                Rec.FieldCaption("Bank Country/Region Code"), Rec."Bank Country/Region Code");
            exit;
        end;

        if Rec."Acc. Hold. Country/Region Code" = '' then begin
            Rec."Error Message" := StrSubstNo(Text001, Rec.FieldCaption("Acc. Hold. Country/Region Code"), Rec.TableCaption);
            exit;
        end;

        // Check Our Bank Account
        BankAcc.Get(Rec."Our Bank No.");
        OnAfterBankAccGet(BankAcc);

        if BankAcc."Country/Region Code" = '' then begin
            Rec."Error Message" := StrSubstNo(Text004, BankAcc.FieldCaption("Country/Region Code"), Rec.FieldCaption("Our Bank No."), Rec."Our Bank No.");
            exit;
        end;

        if BankAcc.IBAN = '' then begin
            Rec."Error Message" := StrSubstNo(Text004, BankAcc.FieldCaption(IBAN), Rec.FieldCaption("Our Bank No."), Rec."Our Bank No.");
            exit;
        end;

        if not CheckBankSWIFTCode(Rec) then
            exit;

        if Country.Code <> BankAcc."Country/Region Code" then
            Country.Get(BankAcc."Country/Region Code");

        if not Country."SEPA Allowed" then begin
            Rec."Error Message" := StrSubstNo(Text003, Country.FieldCaption("SEPA Allowed"), Country."SEPA Allowed",
                BankAcc.FieldCaption("Country/Region Code"), BankAcc."Country/Region Code",
                Rec.FieldCaption("Our Bank No."), Rec."Our Bank No.");
            exit;
        end;

        // Check Company Information
        if not CheckCompanyInfoVATRegistrationNo(Rec) then
            exit;

        // Check Freely Tranferable Maximum
        FreelyTransferableMaximum.Get(Rec."Bank Country/Region Code", Rec."Currency Code");


        if Rec.Amount > FreelyTransferableMaximum.Amount then
            case Rec."Nature of the Payment" of
                Rec."Nature of the Payment"::" ":
                    begin
                        Rec."Error Message" := StrSubstNo(Text005, Rec.FieldCaption(Amount), Rec.FieldCaption("Nature of the Payment"));
                        exit;
                    end;
                Rec."Nature of the Payment"::"Transito Trade":
                    if (Rec."Item No." = '') or (Rec."Traders No." = '') then begin
                        Rec."Error Message" :=
                          StrSubstNo(
                            Text006,
                            Rec.FieldCaption("Nature of the Payment"),
                            Rec.FieldCaption("Item No."),
                            Rec.FieldCaption("Traders No."));
                        exit;
                    end;
                Rec."Nature of the Payment"::"Invisible- and Capital Transactions":
                    if Rec."Description Payment" = '' then begin
                        Rec."Error Message" := StrSubstNo(Text007, Rec.FieldCaption("Nature of the Payment"), Rec.FieldCaption("Description Payment"));
                        exit;
                    end;
                Rec."Nature of the Payment"::"Transfer to Own Account", Rec."Nature of the Payment"::"Other Registrated BFI":
                    if (Rec."Description Payment" = '') or (Rec."Registration No. DNB" = '') then begin
                        Rec."Error Message" :=
                          StrSubstNo(
                            Text008,
                            Rec.FieldCaption("Nature of the Payment"),
                            Rec.FieldCaption("Description Payment"),
                            Rec.FieldCaption("Registration No. DNB"));
                        exit;
                    end;
            end;

        OnAfterOnRun(Rec);
    end;

    var
        Text001: Label '%1 must be entered in %2.';
        Text002: Label '%1 must not exceed 11 characters.';
        Country: Record "Country/Region";
        Text003: Label '%1 cannot be %2 for %3:%4 of %5:%6.';
        BankAcc: Record "Bank Account";
        Text004: Label '%1 must be entered for %2:%3.';
        CompanyInfo: Record "Company Information";
        FreelyTransferableMaximum: Record "Freely Transferable Maximum";
        Text005: Label '%1 exceeds the maximum limit, %2 must be entered. The default value is ''goods''.';
        Text006: Label '%1 is transito trade, %2 and %3 must be filled in.';
        Text007: Label '%1 is invisible- and capital transactions, %2 must be filled in.';
        Text008: Label '%1 is transfer or sundry, %2 and %3 must be filled in.';
        Text009: Label '%1 cannot be %2 for %3:%4.';

    local procedure CheckCompanyInfoVATRegistrationNo(var ProposalLine: Record "Proposal Line") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCompanyInfoVATRegistrationNo(ProposalLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        CompanyInfo.Get();
        if CompanyInfo."VAT Registration No." = '' then begin
            ProposalLine."Error Message" := StrSubstNo(Text001, CompanyInfo.FieldCaption("VAT Registration No."), CompanyInfo.TableCaption());
            exit(false);
        end;

        exit(true);
    end;

    local procedure CheckBankSWIFTCode(var ProposalLine: Record "Proposal Line") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBankSWIFTCode(ProposalLine, BankAcc, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if BankAcc."SWIFT Code" = '' then begin
            ProposalLine."Error Message" := StrSubstNo(Text004, BankAcc.FieldCaption("SWIFT Code"), ProposalLine.FieldCaption("Our Bank No."), ProposalLine."Our Bank No.");
            exit(false);
        end;

        exit(true);
    end;

    local procedure CheckSWIFTCode(var ProposalLine: Record "Proposal Line") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSWIFTCode(ProposalLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if ProposalLine."SWIFT Code" = '' then begin
            ProposalLine."Error Message" := StrSubstNo(Text001, ProposalLine.FieldCaption("SWIFT Code"), ProposalLine.TableCaption());
            exit(false);
        end;

        if StrLen(ProposalLine."SWIFT Code") > 11 then begin
            ProposalLine."Error Message" := StrSubstNo(Text002, ProposalLine.FieldCaption("SWIFT Code"), ProposalLine.TableCaption());
            exit;
        end;

        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBankSWIFTCode(var ProposalLine: Record "Proposal Line"; BankAcc: Record "Bank Account"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCompanyInfoVATRegistrationNo(var ProposalLine: Record "Proposal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSWIFTCode(var ProposalLine: Record "Proposal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var ProposalLine: Record "Proposal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var ProposalLine: Record "Proposal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBankAccGet(var BankAcc: Record "Bank Account")
    begin
    end;
}

