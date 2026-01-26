// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

table 15000001 "Remittance Payment Order"
{
    Caption = 'Remittance Payment Order';
    DrillDownPageID = "Remittance Payment Order";
    LookupPageID = "Remittance Payment Order";
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Integer)
        {
            Caption = 'ID';
            Editable = false;
        }
        field(2; Comment; Text[50])
        {
            Caption = 'Comment';
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Export,Return';
            OptionMembers = Export,Return;
        }
        field(10; Date; Date)
        {
            Caption = 'Date';
            Editable = false;
        }
        field(11; Time; Time)
        {
            Caption = 'Time';
            Editable = false;
        }
        field(20; Canceled; Boolean)
        {
            Caption = 'Canceled';
            Editable = false;
        }
        field(30; "Number Sent"; Integer)
        {
            BlankZero = true;
            CalcFormula = count ("Waiting Journal" where("Payment Order ID - Sent" = field(ID)));
            Caption = 'Number Sent';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31; "Number Approved"; Integer)
        {
            BlankZero = true;
            CalcFormula = count ("Waiting Journal" where("Payment Order ID - Approved" = field(ID)));
            Caption = 'Number Approved';
            Editable = false;
            FieldClass = FlowField;
        }
        field(32; "Number Settled"; Integer)
        {
            BlankZero = true;
            CalcFormula = count ("Waiting Journal" where("Payment Order ID - Settled" = field(ID)));
            Caption = 'Number Settled';
            Editable = false;
            FieldClass = FlowField;
        }
        field(33; "Number Rejected"; Integer)
        {
            BlankZero = true;
            CalcFormula = count ("Waiting Journal" where("Payment Order ID - Rejected" = field(ID)));
            Caption = 'Number Rejected';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
        key(Key2; Date)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        PaymentOrderData: Record "Payment Order Data";
        WaitingJournal: Record "Waiting Journal";
    begin
        PaymentOrderData.SetRange("Payment Order No.", ID);
        PaymentOrderData.DeleteAll();
        WaitingJournal.SetRange(Reference, ID);
        WaitingJournal.DeleteAll();
    end;
}

