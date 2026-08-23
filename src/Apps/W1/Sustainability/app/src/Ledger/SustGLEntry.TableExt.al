namespace Microsoft.Sustainability.Ledger;

using Microsoft.Finance.GeneralLedger.Ledger;

tableextension 6282 "Sust. G/L Entry" extends "G/L Entry"
{
    fields
    {
        field(6210; "Sust. Collected"; Boolean)
        {
            Caption = 'Collected for Sustainability';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Specifies whether the entry has already been collected into a sustainability entry. The G/L - Sustainability Entry Relation table holds the details.';
        }
    }

    keys
    {
        key(SustCollected; "Sust. Collected", "G/L Account No.", "Posting Date")
        {
            SumIndexFields = Amount;
        }
    }
}
