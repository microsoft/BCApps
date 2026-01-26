table 160800 "GL Accounts Conversion"
{
    Caption = 'GL Accounts Conversion';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Text[20])
        {
            Caption = 'No.';
            NotBlank = true;
            TableRelation = "G/L Account"."No.";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                OpprettMidlertidigKontonr();
            end;
        }
        field(4; "Account Type"; Option)
        {
            Caption = 'Account Type';
            OptionCaption = 'Posting,Heading,Total,Begin-Total,End-Total';
            OptionMembers = Posting,Heading,Total,"Begin-Total","End-Total";

            trigger OnValidate()
            var
            begin
                if ("Original Account No." <> '') and (xRec."Account Type" = xRec."Account Type"::Posting) then
                    Error('Nei! Du kan ikke endre %1 fra %2 til %3.\Poster på kontoen kan da ikke flyttes på fornuftig måte.',
                      FieldName("Account Type"), xRec."Account Type", "Account Type");

                Totaling := '';
                if "Account Type" = "Account Type"::Posting then begin
                    if "Account Type" <> xRec."Account Type" then
                        "Direct Posting" := true;
                end else
                    "Direct Posting" := false;
            end;
        }
        field(6; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(7; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(9; "Income/Balance"; Option)
        {
            Caption = 'Income/Balance';
            OptionCaption = 'Income Statement,Balance Sheet';
            OptionMembers = "Income Statement","Balance Sheet";
        }
        field(10; "Debit/Credit"; Option)
        {
            Caption = 'Debit/Credit';
            OptionCaption = 'Both,Debit,Credit';
            OptionMembers = Both,Debit,Credit;
        }
        field(11; "No. 2"; Code[20])
        {
            Caption = 'No. 2';
        }
        field(13; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(14; "Direct Posting"; Boolean)
        {
            Caption = 'Direct Posting';
            InitValue = true;
        }
        field(16; "Reconciliation Account"; Boolean)
        {
            Caption = 'Reconciliation Account';
        }
        field(17; "New Page"; Boolean)
        {
            Caption = 'New Page';
        }
        field(18; "No. of Blank Lines"; Integer)
        {
            Caption = 'No. of Blank Lines';
            MinValue = 0;
        }
        field(19; Indentation; Integer)
        {
            Caption = 'Indentation';
            MinValue = 0;
        }
        field(26; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(34; Totaling; Text[250])
        {
            Caption = 'Totaling';
            TableRelation = "G/L Account";
            ValidateTableRelation = false;
        }
        field(40; "Consol. Debit Acc."; Code[20])
        {
            Caption = 'Consol. Debit Acc.';
        }
        field(41; "Consol. Credit Acc."; Code[20])
        {
            Caption = 'Consol. Credit Acc.';
        }
        field(43; "Gen. Posting Type"; Option)
        {
            Caption = 'Gen. Posting Type';
            OptionCaption = ' ,Purchase,Sale';
            OptionMembers = " ",Purchase,Sale;
        }
        field(44; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";

            trigger OnValidate()
            var
                GenBusPostingGrp: Record "Gen. Business Posting Group";
            begin
                if xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group" then
                    if GenBusPostingGrp.ValidateVatBusPostingGroup(GenBusPostingGrp, "Gen. Bus. Posting Group") then
                        Validate("VAT Bus. Posting Group", GenBusPostingGrp."Def. VAT Bus. Posting Group");
            end;
        }
        field(45; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            var
                GenProdPostingGrp: Record "Gen. Product Posting Group";
            begin
                if xRec."Gen. Prod. Posting Group" <> "Gen. Prod. Posting Group" then
                    if GenProdPostingGrp.ValidateVatProdPostingGroup(GenProdPostingGrp, "Gen. Prod. Posting Group") then
                        Validate("VAT Prod. Posting Group", GenProdPostingGrp."Def. VAT Prod. Posting Group");
            end;
        }
        field(46; Picture; BLOB)
        {
            Caption = 'Picture';
            SubType = Bitmap;
        }
        field(49; "Automatic Ext. Texts"; Boolean)
        {
            Caption = 'Automatic Ext. Texts';
        }
        field(54; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
        }
        field(55; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
        }
        field(56; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";
        }
        field(57; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(58; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(63; "Exchange Rate Adjustment"; Option)
        {
            Caption = 'Exchange Rate Adjustment';
            OptionCaption = 'No Adjustment,Adjust Amount,Adjust Additional-Currency Amount';
            OptionMembers = "No Adjustment","Adjust Amount","Adjust Additional-Currency Amount";
        }
        field(101; "Original Account No."; Text[20])
        {
            Caption = 'Original Account No.';
            TableRelation = "G/L Account"."No.";
            ValidateTableRelation = false;
        }
        field(102; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(103; "Temp. Account No."; Text[20])
        {
            Caption = 'Temp. Account No.';
        }
        field(104; "Account Status"; Option)
        {
            Caption = 'Account Status';
            OptionCaption = 'Not Converted,Prepared,Converted';
            OptionMembers = "Not Converted",Prepared,Converted;
        }
        field(105; "Account Error"; Boolean)
        {
            Caption = 'Account Error';
            Editable = false;
        }
        field(106; "Formula Status"; Option)
        {
            Caption = 'Formula Status';
            OptionCaption = 'Not Converted,Prepared,Converted';
            OptionMembers = "Not Converted",Prepared,Converted;
        }
        field(107; "Internal Comment"; Text[100])
        {
            Caption = 'Internal Comment';
        }
        field(10000; Name; Text[30])
        {
            Caption = 'Name';
        }
        field(10001; "Search Name"; Code[30])
        {
            Caption = 'Search Name';
        }
    }

    keys
    {
        key(Key1; "Original Account No.", "Entry No.")
        {
        }
        key(Key2; "No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if "Original Account No." <> '' then begin
            // Sjekke at det ikke allerede er en konto med dette nummeret.
            KontoKonv.SetRange("Original Account No.", "Original Account No.");
            if KontoKonv.Find('-') then
                Error('Det finnes allerede en konto %1.', "Original Account No.");
        end else
            if KontoKonv.Get("Original Account No.", "Entry No.") then begin
                KontoKonv.SetRange("Original Account No.", "Original Account No.");
                KontoKonv.Find('+');
                "Entry No." := KontoKonv."Entry No." + 1;
            end;

        OpprettMidlertidigKontonr();
    end;

    var
        KontoKonv: Record "GL Accounts Conversion";

    procedure OpprettMidlertidigKontonr()
    begin
        Validate("Temp. Account No.", "No." + 'x');
    end;
}

