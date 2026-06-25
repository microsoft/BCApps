namespace Microsoft.Sample.Loyalty;

table 50100 "Loyalty Member"
{
    Caption = 'Loyalty Member';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;
        }
        field(2; "Member Name"; Text[100])
        {
            Caption = 'Member Name';
        }
        field(3; "Email Address"; Text[80])
        {
            Caption = 'Email Address';
        }
        field(4; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            DataClassification = ToBeClassified;
        }
        field(5; "Loyalty Tier"; Enum "Loyalty Tier")
        {
            Caption = 'Loyalty Tier';
            DataClassification = CustomerContent;
        }
        field(6; "Points Balance"; Integer)
        {
            Caption = 'Points Balance';
            DataClassification = ToBeClassified;
        }
        field(7; "Sponsor No."; Code[20])
        {
            Caption = 'Sponsor No.';
            TableRelation = "Loyalty Member"."No.";
            DataClassification = CustomerContent;
        }
        field(8; "Card No."; Code[20])
        {
            Caption = 'Card No.';
            DataClassification = CustomerContent;
            ObsoleteState = Removed;
            ObsoleteReason = 'Loyalty cards are no longer issued.';
            ObsoleteTag = '26.0';
        }
        field(10; "Total Points"; Integer)
        {
            Caption = 'Total Points';
            FieldClass = FlowField;
            CalcFormula = sum("Loyalty Point Entry".Points where("Member No." = field("No.")));
            Editable = false;
        }
        field(11; "Entry Count"; Integer)
        {
            Caption = 'Entry Count';
            FieldClass = FlowField;
            CalcFormula = count("Loyalty Point Entry" where("Member No." = field("No.")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }
}
