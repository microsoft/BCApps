#pragma warning disable AA0247
table 17216 "Tax Register Dim. Value Comb."
{
    Caption = 'Tax Register Dim. Value Comb.';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Dimension 1 Code"; Code[20])
        {
            Caption = 'Dimension 1 Code';
            NotBlank = true;
            TableRelation = Dimension.Code;
        }
        field(2; "Dimension 1 Value Code"; Code[20])
        {
            Caption = 'Dimension 1 Value Code';
            NotBlank = true;
            TableRelation = "Dimension Value".Code where("Dimension Code" = field("Dimension 1 Code"));
        }
        field(3; "Dimension 2 Code"; Code[20])
        {
            Caption = 'Dimension 2 Code';
            TableRelation = Dimension.Code;
        }
        field(4; "Dimension 2 Value Code"; Code[20])
        {
            Caption = 'Dimension 2 Value Code';
            TableRelation = "Dimension Value".Code where("Dimension Code" = field("Dimension 2 Code"));
        }
        field(5; "Type Limit"; Option)
        {
            Caption = 'Type Limit';
            OptionCaption = 'Value,Blocked';
            OptionMembers = Value,Blocked;
        }
        field(100; "Tax Register No."; Code[10])
        {
            Caption = 'Tax Register No.';
            TableRelation = "Tax Register"."No.";
        }
        field(101; "Line No."; Integer)
        {
            Caption = 'Line No.';
            MinValue = 0;
        }
        field(102; "Section Code"; Code[10])
        {
            Caption = 'Section Code';
            NotBlank = true;
            TableRelation = "Tax Register Section";
        }
    }

    keys
    {
        key(Key1; "Section Code", "Tax Register No.", "Line No.", "Dimension 1 Code", "Dimension 1 Value Code", "Dimension 2 Code", "Dimension 2 Value Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TaxRegSection.Get("Section Code");
        TaxRegSection.ValidateChangeDeclaration();

        TaxRegDimDefValue.Reset();
        TaxRegDimDefValue.SetRange("Section Code", "Section Code");
        TaxRegDimDefValue.SetRange("Tax Register No.", "Tax Register No.");
        TaxRegDimDefValue.SetRange("Line No.", "Line No.");
        TaxRegDimDefValue.SetRange("Dimension 1 Code", "Dimension 1 Code");
        TaxRegDimDefValue.SetRange("Dimension 1 Value Code", "Dimension 1 Value Code");
        TaxRegDimDefValue.SetRange("Dimension 2 Code", "Dimension 2 Code");
        TaxRegDimDefValue.SetRange("Dimension 2 Value Code", "Dimension 2 Value Code");
        TaxRegDimDefValue.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        if "Tax Register No." = '' then
            TestField("Line No.", 0);
        if "Dimension 2 Code" = '' then
            TestField("Dimension 2 Value Code", '');
        TaxRegSection.Get("Section Code");
        TaxRegSection.ValidateChangeDeclaration();
    end;

    trigger OnModify()
    begin
        TaxRegSection.Get("Section Code");
        TaxRegSection.ValidateChangeDeclaration();
    end;

    var
        TaxRegSection: Record "Tax Register Section";
        TaxRegDimDefValue: Record "Tax Register Dim. Def. Value";
}

