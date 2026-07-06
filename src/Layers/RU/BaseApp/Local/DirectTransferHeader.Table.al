#if not CLEANSCHEMA28
#pragma warning disable AA0247
table 12458 "Direct Transfer Header"
{
    Caption = 'Direct Transfer Header';
    DataCaptionFields = "No.";
    LookupPageID = "Posted Direct Transfers";
    ObsoleteState = Removed;
    ObsoleteReason = 'Direct Transfer feature merge to W1.';
    ObsoleteTag = '28.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; "Transfer-from Code"; Code[10])
        {
            Caption = 'Transfer-from Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(3; "Transfer-from Name"; Text[100])
        {
            Caption = 'Transfer-from Name';
        }
        field(4; "Transfer-from Name 2"; Text[50])
        {
            Caption = 'Transfer-from Name 2';
        }
        field(5; "Transfer-from Address"; Text[100])
        {
            Caption = 'Transfer-from Address';
        }
        field(6; "Transfer-from Address 2"; Text[50])
        {
            Caption = 'Transfer-from Address 2';
        }
        field(7; "Transfer-from Post Code"; Code[20])
        {
            Caption = 'Transfer-from Post Code';
            TableRelation = "Post Code";
        }
        field(8; "Transfer-from City"; Text[30])
        {
            Caption = 'Transfer-from City';
        }
        field(9; "Transfer-from County"; Text[30])
        {
            Caption = 'Transfer-from County';
        }
        field(10; "Trsf.-from Country/Region Code"; Code[10])
        {
            Caption = 'Trsf.-from Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(11; "Transfer-to Code"; Code[10])
        {
            Caption = 'Transfer-to Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(12; "Transfer-to Name"; Text[100])
        {
            Caption = 'Transfer-to Name';
        }
        field(13; "Transfer-to Name 2"; Text[50])
        {
            Caption = 'Transfer-to Name 2';
        }
        field(14; "Transfer-to Address"; Text[100])
        {
            Caption = 'Transfer-to Address';
        }
        field(15; "Transfer-to Address 2"; Text[50])
        {
            Caption = 'Transfer-to Address 2';
        }
        field(16; "Transfer-to Post Code"; Code[20])
        {
            Caption = 'Transfer-to Post Code';
            TableRelation = "Post Code";
        }
        field(17; "Transfer-to City"; Text[30])
        {
            Caption = 'Transfer-to City';
        }
        field(18; "Transfer-to County"; Text[30])
        {
            Caption = 'Transfer-to County';
        }
        field(19; "Trsf.-to Country/Region Code"; Code[10])
        {
            Caption = 'Trsf.-to Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(20; "Transfer Order Date"; Date)
        {
            Caption = 'Transfer Order Date';
        }
        field(21; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(22; Comment; Boolean)
        {
            CalcFormula = exist("Inventory Comment Line" where("Document Type" = const("Posted Transfer Receipt"),
                                                                "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(23; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(24; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(25; "Transfer Order No."; Code[20])
        {
            Caption = 'Transfer Order No.';
            TableRelation = "Transfer Header";
            ValidateTableRelation = false;
        }
        field(26; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(30; "Transfer-from Contact"; Text[100])
        {
            Caption = 'Transfer-from Contact';
        }
        field(31; "Transfer-to Contact"; Text[100])
        {
            Caption = 'Transfer-to Contact';
        }
        field(32; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            TableRelation = "Dimension Set Entry";
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Transfer-from Code", "Transfer-to Code", "Posting Date", "Transfer Order Date")
        {
        }
    }

}
#endif