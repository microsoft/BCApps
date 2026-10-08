#pragma warning disable AA0247
table 17301 "Tax Diff. Posting Group"
{
    Caption = 'Tax Diff. Posting Group';
    LookupPageID = "Tax Diff. Posting Groups";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[30])
        {
            Caption = 'Description';
        }
        field(3; "CTA Tax Account"; Code[20])
        {
            Caption = 'CTA Tax Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("CTA Tax Account");
            end;
        }
        field(4; "CTL Tax Account"; Code[20])
        {
            Caption = 'CTL Tax Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("CTL Tax Account");
            end;
        }
        field(8; "DTA Tax Account"; Code[20])
        {
            Caption = 'DTA Tax Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("DTA Tax Account");
            end;
        }
        field(9; "DTL Tax Account"; Code[20])
        {
            Caption = 'DTL Tax Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("DTL Tax Account");
            end;
        }
        field(10; "CTA Account"; Code[20])
        {
            Caption = 'CTA Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("CTA Account");
            end;
        }
        field(11; "CTL Account"; Code[20])
        {
            Caption = 'CTL Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("CTL Account");
            end;
        }
        field(12; "DTA Account"; Code[20])
        {
            Caption = 'DTA Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("DTA Account");
            end;
        }
        field(13; "DTL Account"; Code[20])
        {
            Caption = 'DTL Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("DTL Account");
            end;
        }
        field(14; "DTA Disposal Account"; Code[20])
        {
            Caption = 'DTA Disposal Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("DTA Disposal Account");
            end;
        }
        field(15; "DTL Disposal Account"; Code[20])
        {
            Caption = 'DTL Disposal Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("DTL Disposal Account");
            end;
        }
        field(16; "DTA Transfer Bal. Account"; Code[20])
        {
            Caption = 'DTA Transfer Bal. Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("DTA Transfer Bal. Account");
            end;
        }
        field(17; "DTL Transfer Bal. Account"; Code[20])
        {
            Caption = 'DTL Transfer Bal. Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("DTL Transfer Bal. Account");
            end;
        }
        field(18; "CTA Transfer Tax Account"; Code[20])
        {
            Caption = 'CTA Transfer Tax Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("CTA Transfer Tax Account");
            end;
        }
        field(19; "CTL Transfer Tax Account"; Code[20])
        {
            Caption = 'CTL Transfer Tax Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("CTL Transfer Tax Account");
            end;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description)
        {
        }
    }

    local procedure CheckGLAcc(AccNo: Code[20])
    var
        GLAcc: Record "G/L Account";
    begin
        if AccNo <> '' then begin
            GLAcc.Get(AccNo);
            GLAcc.CheckGLAcc();
        end;
    end;
}

