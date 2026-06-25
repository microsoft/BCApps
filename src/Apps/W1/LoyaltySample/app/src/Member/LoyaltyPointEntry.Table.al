namespace Microsoft.Sample.Loyalty;

table 50101 "Loyalty Point Entry"
{
    Caption = 'Loyalty Point Entry';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = CustomerContent;
            AutoIncrement = true;
        }
        field(2; "Member No."; Code[20])
        {
            Caption = 'Member No.';
            TableRelation = "Loyalty Member"."No.";
            DataClassification = CustomerContent;
        }
        field(3; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = CustomerContent;
        }
        field(4; Points; Integer)
        {
            Caption = 'Points';
            DataClassification = CustomerContent;
        }
        field(5; "Description"; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(6; "Customer Email"; Text[80])
        {
            Caption = 'Customer Email';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Member; "Member No.", "Posting Date")
        {
        }
    }
}
