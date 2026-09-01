// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.Bank.Setup;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Sales.Customer;

/// <summary>
/// Populates the payment export data buffer with information from direct debit collection entries
/// for SEPA direct debit processing. Formats and validates data for XML export compliance.
/// </summary>
codeunit 1231 "SEPA DD-Fill Export Buffer"
{
    Permissions = TableData "Payment Export Data" = rimd;
    TableNo = "Payment Export Data";

    trigger OnRun()
    begin
    end;

    var
        HasErrorsErr: Label 'The file export has one or more errors.\\For each line to be exported, resolve the errors displayed to the right and then try to export again.';

    /// <summary>
    /// Fills the payment export data buffer with information from direct debit collection entries.
    /// Validates entries through the configured check codeunit, retrieves mandate and customer information,
    /// and formats data according to SEPA direct debit standards for XML export processing.
    /// </summary>
    /// <param name="DirectDebitCollectionEntry">The source direct debit collection entries to process for export.</param>
    /// <param name="PaymentExportData">The target payment export data buffer to populate with formatted export data.</param>
    procedure FillExportBuffer(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var PaymentExportData: Record "Payment Export Data")
    var
        BankAccount: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        DirectDebitCollection: Record "Direct Debit Collection";
        GLSetup: Record "General Ledger Setup";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        TempDirectDebitCollectionEntry: Record "Direct Debit Collection Entry" temporary;
    begin
        TempDirectDebitCollectionEntry.CopyFilters(DirectDebitCollectionEntry);
        CODEUNIT.Run(CODEUNIT::"SEPA DD-Prepare Source", TempDirectDebitCollectionEntry);

        TempDirectDebitCollectionEntry.SetAutoCalcFields("Applies-to Entry Document No.", "Applies-to Entry Description");

        if not TempDirectDebitCollectionEntry.FindSet() then
            exit;

        DirectDebitCollection.Get(TempDirectDebitCollectionEntry."Direct Debit Collection No.");
        BankAccount.Get(DirectDebitCollection."To Bank Account No.");
        GetDDExportImportSetup(BankAccount, BankExportImportSetup);
        BankExportImportSetup.TestField("Check Export Codeunit");
        repeat
            CODEUNIT.Run(BankExportImportSetup."Check Export Codeunit", TempDirectDebitCollectionEntry);
        until TempDirectDebitCollectionEntry.Next() = 0;

        if DirectDebitCollection.HasPaymentFileErrors() then begin
            Commit();
            Error(HasErrorsErr);
        end;

        GLSetup.Get();
        GLSetup.TestField("LCY Code");

        TempDirectDebitCollectionEntry.FindSet();
        PaymentExportData.Reset();
        if PaymentExportData.FindLast() then;
        repeat
            PaymentExportData.Init();
            PaymentExportData."Entry No." += 1;
            PaymentExportData.SetPreserveNonLatinCharacters(BankExportImportSetup."Preserve Non-Latin Characters");
            PaymentExportData.SetBankAsSenderBank(BankAccount);
            PaymentExportData.SetCreditorIdentifier(BankAccount);
            PaymentExportData."SEPA Direct Debit Mandate ID" := TempDirectDebitCollectionEntry."Mandate ID";
            SEPADirectDebitMandate.Get(TempDirectDebitCollectionEntry."Mandate ID");
            PaymentExportData."SEPA DD Mandate Signed Date" := SEPADirectDebitMandate."Date of Signature";

            TempDirectDebitCollectionEntry."Sequence Type" :=
              UpdateSourceEntrySequenceType(TempDirectDebitCollectionEntry);

            PaymentExportData.Validate(PaymentExportData."SEPA Direct Debit Seq. Type", TempDirectDebitCollectionEntry."Sequence Type");
            PaymentExportData."Transfer Date" := TempDirectDebitCollectionEntry."Transfer Date";
            PaymentExportData."Document No." := TempDirectDebitCollectionEntry."Applies-to Entry Document No.";
            PaymentExportData.Amount := TempDirectDebitCollectionEntry."Transfer Amount";
            PaymentExportData."Currency Code" := GLSetup.GetCurrencyCode(TempDirectDebitCollectionEntry."Currency Code");

            Customer.Get(TempDirectDebitCollectionEntry."Customer No.");
            CustomerBankAccount.Get(Customer."No.", SEPADirectDebitMandate."Customer Bank Account Code");
            PaymentExportData.SetCustomerAsRecipient(Customer, CustomerBankAccount);

            PaymentExportData.Validate(PaymentExportData."SEPA Partner Type", Customer."Partner Type");
            PaymentExportData.Validate(PaymentExportData."SEPA Instruction Priority", PaymentExportData."SEPA Instruction Priority"::NORMAL);
            PaymentExportData.Validate(PaymentExportData."SEPA Payment Method", PaymentExportData."SEPA Payment Method"::TRF);
            PaymentExportData.Validate(PaymentExportData."SEPA Charge Bearer", PaymentExportData."SEPA Charge Bearer"::SLEV);

            PaymentExportData."SEPA Batch Booking" := false;
            PaymentExportData."Message ID" := DirectDebitCollection."Message ID";
            PaymentExportData."Payment Information ID" := TempDirectDebitCollectionEntry."Transaction ID";
            PaymentExportData."End-to-End ID" := TempDirectDebitCollectionEntry."Transaction ID";
            PaymentExportData."Message to Recipient 1" := TempDirectDebitCollectionEntry."Applies-to Entry Description";
            PaymentExportData."Message to Recipient 2" := TempDirectDebitCollectionEntry."Message to Recipient";

            OnBeforeInsertPaymentExportData(PaymentExportData, TempDirectDebitCollectionEntry);
            PaymentExportData.Insert(true);
        until TempDirectDebitCollectionEntry.Next() = 0;
    end;

    /// <summary>
    /// Retrieves the direct debit export/import setup for the specified bank account.
    /// Allows customization through integration events before falling back to the standard setup method.
    /// </summary>
    /// <param name="BankAccount">The bank account to get the export/import setup for.</param>
    /// <param name="BankExportImportSetup">Returns the configured export/import setup for direct debit processing.</param>
    local procedure GetDDExportImportSetup(BankAccount: Record "Bank Account"; var BankExportImportSetup: Record "Bank Export/Import Setup")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDDExportImportSetup(BankAccount, BankExportImportSetup, IsHandled);
        if IsHandled then
            exit;

        BankAccount.GetDDExportImportSetup(BankExportImportSetup);
    end;

    /// <summary>
    /// Updates the sequence type for a direct debit collection entry based on mandate status.
    /// For new entries, determines the appropriate sequence type and updates the mandate counter.
    /// Existing entries retain their current sequence type.
    /// </summary>
    /// <param name="TempDirectDebitCollectionEntry">The temporary direct debit collection entry to process.</param>
    /// <returns>The appropriate sequence type for the collection entry based on mandate history.</returns>
    local procedure UpdateSourceEntrySequenceType(TempDirectDebitCollectionEntry: Record "Direct Debit Collection Entry" temporary) SequenceType: Integer
    var
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
    begin
        if TempDirectDebitCollectionEntry.Status <> TempDirectDebitCollectionEntry.Status::New then
            exit(TempDirectDebitCollectionEntry."Sequence Type");

        SEPADirectDebitMandate.Get(TempDirectDebitCollectionEntry."Mandate ID");
        SequenceType := SEPADirectDebitMandate.GetSequenceType();
        SEPADirectDebitMandate.UpdateCounter();

        DirectDebitCollectionEntry := TempDirectDebitCollectionEntry;
        if DirectDebitCollectionEntry.Find() then begin
            DirectDebitCollectionEntry."Sequence Type" := SequenceType;
            DirectDebitCollectionEntry.Modify();
        end;
    end;

    /// <summary>
    /// Integration event that allows customization of the direct debit export/import setup retrieval process.
    /// Subscribers can provide alternative logic for determining the appropriate setup configuration.
    /// </summary>
    /// <param name="BankAccount">The bank account for which to retrieve the export/import setup.</param>
    /// <param name="BankExportImportSetup">The export/import setup to be populated or customized.</param>
    /// <param name="IsHandled">Set to true if the subscriber handles the setup retrieval completely.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDDExportImportSetup(BankAccount: Record "Bank Account"; var BankExportImportSetup: Record "Bank Export/Import Setup"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event that allows customization of payment export data before insertion.
    /// Subscribers can modify export data fields or add additional validation logic.
    /// </summary>
    /// <param name="PaymentExportData">The payment export data record being prepared for insertion.</param>
    /// <param name="TempDirectDebitCollectionEntry">The source direct debit collection entry providing the data.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPaymentExportData(var PaymentExportData: Record "Payment Export Data"; var TempDirectDebitCollectionEntry: Record "Direct Debit Collection Entry" temporary)
    begin
    end;
}

