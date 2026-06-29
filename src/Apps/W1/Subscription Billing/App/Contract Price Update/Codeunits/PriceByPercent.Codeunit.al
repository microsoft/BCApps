namespace Microsoft.SubscriptionBilling;

using Microsoft.Finance.Currency;

codeunit 8012 "Price By Percent" implements "Contract Price Update"
{
    var
        PriceUpdateTemplate: Record "Price Update Template";
        ServiceCommitment: Record "Subscription Line";
        ContractPriceUpdateLine: Record "Sub. Contr. Price Update Line";
        PriceUpdateManagement: Codeunit "Price Update Management";
        IncludeServiceCommitmentUpToDate: Date;
        PerformUpdateOnDate: Date;

#pragma warning disable AL0920
    internal procedure SetPriceUpdateParameters(NewPriceUpdateTemplate: Record "Price Update Template"; NewIncludeServiceCommitmentUpToDate: Date; NewPerformUpdateOnDate: Date)
#pragma warning restore AL0920
    begin
        PriceUpdateTemplate := NewPriceUpdateTemplate;
        IncludeServiceCommitmentUpToDate := NewIncludeServiceCommitmentUpToDate;
        PerformUpdateOnDate := NewPerformUpdateOnDate;
    end;

#pragma warning disable AL0920
    internal procedure ApplyFilterOnServiceCommitments()
#pragma warning restore AL0920
    begin
        PriceUpdateManagement.TestIncludeServiceCommitmentUpToDate(IncludeServiceCommitmentUpToDate);
        PriceUpdateManagement.GetAndApplyFiltersOnServiceCommitment(ServiceCommitment, PriceUpdateTemplate, IncludeServiceCommitmentUpToDate);
    end;

#pragma warning disable AL0920
    internal procedure CreatePriceUpdateProposal()
#pragma warning restore AL0920
    begin
        if ServiceCommitment.FindSet() then
            repeat
                if not ContractPriceUpdateLine.PriceUpdateLineExists(ServiceCommitment) then begin
                    ContractPriceUpdateLine.InitNewLine();
                    ContractPriceUpdateLine."Price Update Template Code" := PriceUpdateTemplate.Code;
                    ContractPriceUpdateLine.UpdatePerformUpdateOn(ServiceCommitment, PerformUpdateOnDate);
                    ContractPriceUpdateLine.UpdateFromServiceCommitment(ServiceCommitment);
                    ContractPriceUpdateLine.UpdateFromContract(ServiceCommitment.Partner, ServiceCommitment."Subscription Contract No.");
                    CalculateNewPrice(PriceUpdateTemplate."Update Value %", ContractPriceUpdateLine);
                    ContractPriceUpdateLine."Next Price Update" := CalcDate(PriceUpdateTemplate."Price Binding Period", ContractPriceUpdateLine."Perform Update On");
                    OnAfterCalculateNewPriceForSubscriptionLine(ServiceCommitment, ContractPriceUpdateLine, PriceUpdateTemplate, PerformUpdateOnDate);
                    if ContractPriceUpdateLine.ShouldContractPriceUpdateLineBeInserted() then
                        ContractPriceUpdateLine.Insert(false)
                    else
                        ContractPriceUpdateLine.ShowContractPriceUpdateLineNotInsertedNotification();
                end;
            until ServiceCommitment.Next() = 0;
    end;

#pragma warning disable AL0920
    internal procedure CalculateNewPrice(UpdatePercentValue: Decimal; var NewContractPriceUpdateLine: Record "Sub. Contr. Price Update Line")
#pragma warning restore AL0920
    var
        Currency: Record Currency;
    begin
        Currency.InitRoundingPrecision();
        NewContractPriceUpdateLine."New Calculation Base" := Round(NewContractPriceUpdateLine."Old Calculation Base" + NewContractPriceUpdateLine."Old Calculation Base" * UpdatePercentValue / 100, Currency."Amount Rounding Precision");
        NewContractPriceUpdateLine."New Price" := Round(NewContractPriceUpdateLine."Old Price" + NewContractPriceUpdateLine."Old Price" * UpdatePercentValue / 100, Currency."Unit-Amount Rounding Precision");
        NewContractPriceUpdateLine."New Amount" := Round(NewContractPriceUpdateLine."New Price" * NewContractPriceUpdateLine.Quantity, Currency."Amount Rounding Precision");
        NewContractPriceUpdateLine."New Calculation Base %" := NewContractPriceUpdateLine."Old Calculation Base %";
        NewContractPriceUpdateLine."Discount Amount" := Round(NewContractPriceUpdateLine."Discount %" * NewContractPriceUpdateLine."New Amount" / 100, Currency."Amount Rounding Precision");
        NewContractPriceUpdateLine."New Amount" := NewContractPriceUpdateLine."New Amount" - NewContractPriceUpdateLine."Discount Amount";
        NewContractPriceUpdateLine."Additional Amount" := NewContractPriceUpdateLine."New Amount" - NewContractPriceUpdateLine."Old Amount";
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnAfterCalculateNewPriceForSubscriptionLine(SubscriptionLine: Record "Subscription Line"; var SubContrPriceUpdateLine: Record "Sub. Contr. Price Update Line"; PriceUpdateTemplate: Record "Price Update Template"; PerformUpdateOnDate: Date)
    begin
    end;
}
