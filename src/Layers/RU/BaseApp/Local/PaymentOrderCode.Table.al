#pragma warning disable AA0247
table 14918 "Payment Order Code"
{
    Caption = 'Payment Order Code';
    LookupPageID = "Payment Order Codes";
    DataClassification = CustomerContent;

    fields
    {
        field(1; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Payment Reason,Tax Payment Type';
            OptionMembers = "Payment Reason","Tax Payment Type";
        }
        field(2; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(12484; "Reason Document No."; Code[10])
        {
            Caption = 'Reason Document No.';
        }
        field(12488; "Reason Document Type"; Option)
        {
            Caption = 'Reason Document Type';
            OptionCaption = ' ,TR-Number of requirement about taxes payment from TA,RS-Number of decision about installment,OT-Number of decision about deferral,VU-Number of act of materials in court,PR-Number of decision about suspension of penalty,AP-Number of control act,AR-number of executive document';
            OptionMembers = " ",TR,RS,OT,VU,PR,AP,AR;
        }
    }

    keys
    {
        key(Key1; Type, "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

