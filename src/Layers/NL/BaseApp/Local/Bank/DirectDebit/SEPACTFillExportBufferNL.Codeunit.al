namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.HumanResources.Employee;

codeunit 11435 "SEPA CT-Fill Export Buffer NL"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SEPA CT-Fill Export Buffer", 'OnBeforeSetSEPAInstructionPriority', '', false, false)]
    local procedure SetSEPAInstructionPriority(var PaymentExportData: Record "Payment Export Data"; var TempGenJnlLine: Record "Gen. Journal Line" temporary; var IsHandled: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if IsHandled then
            exit;

        GeneralLedgerSetup.Get();
        if not GeneralLedgerSetup."Local SEPA Instr. Priority" then
            exit;

        PaymentExportData.CollectDataFromLocalSource(TempGenJnlLine);
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Payment Export Data", 'OnAfterSetEmployeeAsRecipient', '', false, false)]
    local procedure SetEmployeeCountryRegion(var Sender: Record "Payment Export Data"; Employee: Record Employee)
    begin
        Sender."Recipient Bank Country/Region" := Employee."Country/Region Code";
    end;
}
