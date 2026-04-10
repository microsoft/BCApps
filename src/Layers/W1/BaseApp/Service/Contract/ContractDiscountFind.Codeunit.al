// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

codeunit 5941 "ContractDiscount-Find"
{
    TableNo = "Contract/Service Discount";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindContractDiscount(Rec, IsHandled);
        if IsHandled then
            exit;

        ContractServDiscount.Copy(Rec);

        ContractServDiscount.SetRange("Contract Type", ContractServDiscount."Contract Type"::Contract);
        ContractServDiscount.SetRange("Contract No.", ContractServDiscount."Contract No.");
        ContractServDiscount.SetRange(Type, ContractServDiscount.Type);
        ContractServDiscount.SetFilter("No.", '%1|%2', ContractServDiscount."No.", '');
        ContractServDiscount.SetRange("Starting Date", 0D, ContractServDiscount."Starting Date");
        if not ContractServDiscount.FindLast() then
            ContractServDiscount."Discount %" := 0;

        Rec := ContractServDiscount;
    end;

    var
        ContractServDiscount: Record "Contract/Service Discount";

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindContractDiscount(var ContractServiceDiscount: Record "Contract/Service Discount"; var IsHandled: Boolean);
    begin
    end;
}

