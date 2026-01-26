// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.CRM.Contact;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

codeunit 11600 "ABN Management"
{

    trigger OnRun()
    begin
    end;

    var
        Text1450000: Label 'You can enter only numbers in this field.';
        Text1450001: Label 'You should enter an 11 or 13-digit number in this field.';
        Text1450002: Label 'The number is invalid.';
        Text1450003: Label 'The number already exists for %1 %2. Do you wish to continue?';

    procedure CheckABN(ABN: Text[13]; Which: Option Customer,Vendor,Internal,Contact)
    var
        CheckDigit: Integer;
        AbnDigit: array[13] of Integer;
        WeightFactor: array[13] of Integer;
        AbnWeightSum: Integer;
        i: Integer;
        j: Integer;
        WeightLength: Integer;
        Reminder: Integer;
        IsHandled: Boolean;
        LengthCheck: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckABN(ABN, Which, IsHandled);
        if IsHandled then
            exit;

        if ABN = '' then
            exit;

        if StrPos(ABN, ' ') <> 0 then
            Error(Text1450000);

        LengthCheck := (StrLen(ABN) <> 13);

        if LengthCheck then
            LengthCheck := (StrLen(ABN) <> 11);

        if LengthCheck then
            Error(Text1450001);

        if (StrLen(ABN) = 13) and (which = Which::Internal) then begin
            WeightLength := 15;
            for i := 1 to StrLen(ABN) do begin
                Evaluate(j, ABN[i]);
                AbnWeightSum += j * (WeightLength - 1);
            end;
            Reminder := AbnWeightSum mod 11;
            CheckDigit := 11 - Reminder;
            if CheckDigit <> 0 then
                Error(Text1450002);
            if CheckDigit <> ABN[StrLen(ABN)] then
                Error(Text1450002);
        end else begin
            j := -1;
            CheckDigit := 89;
            Clear(AbnDigit);
            Clear(WeightFactor);
            Clear(AbnWeightSum);

            for i := 1 to 11 do begin
                if not Evaluate(AbnDigit[i], CopyStr(ABN, i, 1)) then
                    Error(Text1450000);
                if i = 1 then begin
                    AbnDigit[i] := AbnDigit[i] - 1;
                    WeightFactor[i] := 10;
                end else begin
                    j += 2;
                    WeightFactor[i] := j;
                end;
                AbnWeightSum += (WeightFactor[i] * AbnDigit[i]);
            end;

            if AbnWeightSum mod CheckDigit <> 0 then
                Error(Text1450002);
        end;

        CheckForDuplicates(ABN, Which);
    end;

    local procedure CheckForDuplicates(ABN: Text[11]; Which: Option Customer,Vendor,Internal,Contact)
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Contact: Record Contact;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckForDuplicates(ABN, Which, IsHandled);
        if IsHandled then
            exit;

        case Which of
            Which::Vendor:
                begin
                    Vendor.SetCurrentKey(ABN);
                    Vendor.SetRange(ABN, ABN);
                    if Vendor.FindFirst() then
                        if not Confirm(Text1450003, false, Vendor.TableCaption(), Vendor."No.") then
                            Error('');
                end;
            Which::Customer:
                begin
                    Customer.SetCurrentKey(ABN);
                    Customer.SetRange(ABN, ABN);
                    if Customer.FindFirst() then
                        if not Confirm(Text1450003, false, Customer.TableCaption(), Customer."No.") then
                            Error('');
                end;
            Which::Contact:
                begin
                    Contact.SetCurrentKey(ABN, Type);
                    Contact.SetRange(ABN, ABN);
                    Contact.SetRange(Type, Contact.Type::Company);
                    if Contact.FindFirst() then
                        if not Confirm(Text1450003, false, Contact.TableCaption(), Contact."No.") then
                            Error('');
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckABN(ABN: Text[11]; Which: Option Customer,Vendor,Internal,Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckForDuplicates(ABN: Text[11]; Which: Option Customer,Vendor,Internal,Contact; var IsHandled: Boolean)
    begin
    end;
}

