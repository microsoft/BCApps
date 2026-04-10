namespace Microsoft.AccountantPortal;

using Microsoft.Finance.GeneralLedger.Setup;

codeunit 1344 "Acct. WebServices Mgt."
{
    // Contains helper functions when creating web services specific to the Accounting portal.


    trigger OnRun()
    begin
    end;

    procedure FormatAmountString(Amount: Decimal) FormattedAmount: Text
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        FormatString: Text;
        AmountDecimalPlaces: Text[5];
        LocalCurrencySymbol: Text[10];
    begin
        if GeneralLedgerSetup.FindFirst() then begin
            AmountDecimalPlaces := GeneralLedgerSetup."Amount Decimal Places";
            LocalCurrencySymbol := GeneralLedgerSetup.GetCurrencySymbol();
        end else begin
            AmountDecimalPlaces := '';
            LocalCurrencySymbol := '';
        end;

        if AmountDecimalPlaces <> '' then
            FormatString := LocalCurrencySymbol + '<Precision,' + AmountDecimalPlaces + '><Standard Format,0>';

        FormattedAmount := Format(Amount, 0, FormatString);
    end;
}

