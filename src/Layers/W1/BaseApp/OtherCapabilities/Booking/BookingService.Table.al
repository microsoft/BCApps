namespace Microsoft.Booking;

using Microsoft.Finance.GeneralLedger.Setup;

table 6703 "Booking Service"
{
    Caption = 'Booking Service';
    ExternalName = 'BookingService';
    TableType = Exchange;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Service ID"; Text[50])
        {
            Caption = 'Service ID';
            ExternalName = 'ServiceId';
        }
        field(2; "Display Name"; Text[100])
        {
            Caption = 'Display Name';
            ExternalName = 'DisplayName';
        }
        field(3; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(4; Price; Decimal)
        {
            Caption = 'Price';
        }
        field(6; "Internal Notes"; Text[250])
        {
            Caption = 'Internal Notes';
            ExternalName = 'InternalNotes';
        }
        field(7; "Default Duration Minutes"; Integer)
        {
            Caption = 'Default Duration Minutes';
            ExternalName = 'DefaultDurationMinutes';
            InitValue = 60;
        }
        field(8; "Default Email Reminder"; Text[250])
        {
            Caption = 'Default Email Reminder';
            ExternalName = 'DefaultEmailReminder';
        }
        field(9; "Default Email Reminder Set"; Boolean)
        {
            Caption = 'Default Email Reminder Set';
            ExternalName = 'IsDefaultEmailReminderSet';
        }
        field(10; "Default Email Reminder Minutes"; Integer)
        {
            Caption = 'Default Email Reminder Minutes';
            ExternalName = 'DefaultEmailReminderMinutes';
        }
        field(14; "Pricing Type"; Integer)
        {
            Caption = 'Pricing Type';
            ExternalName = 'PricingType';
            InitValue = 3;
        }
        field(15; Currency; Text[10])
        {
            Caption = 'Currency';
        }
        field(17; "Exclude From Self Service"; Boolean)
        {
            Caption = 'Exclude From Self Service';
            ExternalName = 'ExcludeFromSelfService';
        }
        field(28; "Last Modified Time"; DateTime)
        {
            Caption = 'Last Modified Time';
            ExternalName = 'LastModifiedTime';
        }
    }

    keys
    {
        key(Key1; "Display Name")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        CheckCurrency();
    end;

    trigger OnModify()
    begin
        CheckCurrency();
    end;

    local procedure CheckCurrency()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if Currency = '' then begin
            GeneralLedgerSetup.Get();
            Currency := GeneralLedgerSetup."LCY Code";
        end;
    end;
}

