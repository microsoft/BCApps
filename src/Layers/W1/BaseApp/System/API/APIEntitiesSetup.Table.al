namespace Microsoft.API;

using Microsoft.Finance.GeneralLedger.Journal;

table 5466 "API Entities Setup"
{
    Caption = 'API Entities Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; PrimaryKey; Code[20])
        {
            Caption = 'PrimaryKey', Locked = true;
        }
        field(3; "Customer Payments Batch Name"; Code[10])
        {
            Caption = 'Customer Payments Batch Name';
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = const('CASHRCPT'));
        }
        field(4; "Demo Company API Initialized"; Boolean)
        {
            Caption = 'Demo Company API Initialized';
        }
    }

    keys
    {
        key(Key1; PrimaryKey)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        "Customer Payments Batch Name" := DefaultCustomerPaymentsBatchNameTxt;
    end;

    var
        DefaultCustomerPaymentsBatchNameTxt: Label 'GENERAL', Comment = 'It should be translated the same way as Default Journal Batch Name';

    procedure SafeGet()
    begin
        if not Get() then
            Insert(true);
    end;
}

