#pragma warning disable AA0247
table 17215 "Tax Register Dim. Comb."
{
    Caption = 'Tax Register Dim. Comb.';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Dimension 1 Code"; Code[20])
        {
            Caption = 'Dimension 1 Code';
            NotBlank = true;
            TableRelation = Dimension.Code;
        }
        field(2; "Dimension 2 Code"; Code[20])
        {
            Caption = 'Dimension 2 Code';
            TableRelation = Dimension.Code;
        }
        field(3; "Combination Restriction"; Option)
        {
            Caption = 'Combination Restriction';
            NotBlank = true;
            OptionCaption = 'Limited,Blocked';
            OptionMembers = Limited,Blocked;
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
        field(103; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
    }

    keys
    {
        key(Key1; "Section Code", "Tax Register No.", "Line No.", "Dimension 1 Code", "Dimension 2 Code")
        {
            Clustered = true;
        }
        key(Key2; "Section Code", "Entry No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TaxRegSection.Get("Section Code");
        TaxRegSection.ValidateChangeDeclaration();

        TaxRegDimValueComb.Reset();
        TaxRegDimValueComb.SetRange("Section Code", "Section Code");
        TaxRegDimValueComb.SetRange("Tax Register No.", "Tax Register No.");
        TaxRegDimValueComb.SetRange("Line No.", "Line No.");
        if ("Dimension 2 Code" = '') or ("Dimension 1 Code" < "Dimension 2 Code") then begin
            TaxRegDimValueComb.SetRange("Dimension 1 Code", "Dimension 1 Code");
            TaxRegDimValueComb.SetRange("Dimension 2 Code", "Dimension 2 Code");
        end else begin
            TaxRegDimValueComb.SetRange("Dimension 1 Code", "Dimension 2 Code");
            TaxRegDimValueComb.SetRange("Dimension 2 Code", "Dimension 1 Code");
        end;
        if not TaxRegDimValueComb.IsEmpty() then
            TaxRegDimValueComb.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        if "Tax Register No." = '' then
            TestField("Line No.", 0);
        TaxRegSection.Get("Section Code");
        TaxRegSection.ValidateChangeDeclaration();

        TaxRegDimComb.Reset();
        TaxRegDimComb.SetCurrentKey("Section Code", "Entry No.");
        if TaxRegDimComb.FindLast() then
            "Entry No." := TaxRegDimComb."Entry No." + 1
        else
            "Entry No." := 1;
    end;

    trigger OnModify()
    begin
        TaxRegSection.Get("Section Code");
        TaxRegSection.ValidateChangeDeclaration();
    end;

    var
        TaxRegSection: Record "Tax Register Section";
        TaxRegDimValueComb: Record "Tax Register Dim. Value Comb.";
        TaxRegDimComb: Record "Tax Register Dim. Comb.";
}

