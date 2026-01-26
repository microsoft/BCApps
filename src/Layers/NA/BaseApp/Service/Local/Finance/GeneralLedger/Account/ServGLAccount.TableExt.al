// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

using Microsoft.Service.Contract;


tableextension 10016 "Serv. G/L Account" extends "G/L Account"
{
    fields
    {
        modify("Tax Group Code")
        {
            trigger OnAfterValidate()
            begin
                if (xRec."Tax Group Code" <> '') and (Rec."Tax Group Code" = '') then
                    CheckServiceContractAccGroup(Rec."No.");
            end;
        }
    }

    var
        CannotRemoveTaxGroupErr: Label 'You cannot remove Tax Group Code from G/L Account :%1 because it is attached to Service Contract Group : %2.', Comment = '%1 - G/L Account No., %2 - Service Contract Group Code';

    local procedure CheckServiceContractAccGroup(GLAccNo: Code[20])
    var
        ServiceContractAccGroup: Record "Service Contract Account Group";
    begin
        ServiceContractAccGroup.SetRange("Non-Prepaid Contract Acc.", GLAccNo);
        if ServiceContractAccGroup.FindFirst() then
            Error(CannotRemoveTaxGroupErr, GLAccNo, ServiceContractAccGroup.Code);

        ServiceContractAccGroup.SetRange("Non-Prepaid Contract Acc.");

        ServiceContractAccGroup.SetRange("Prepaid Contract Acc.", GLAccNo);
        if ServiceContractAccGroup.FindFirst() then
            Error(CannotRemoveTaxGroupErr, GLAccNo, ServiceContractAccGroup.Code);
    end;
}