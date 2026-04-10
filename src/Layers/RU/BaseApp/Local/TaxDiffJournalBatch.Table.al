#pragma warning disable AA0247
table 17304 "Tax Diff. Journal Batch"
{
    Caption = 'Tax Diff. Journal Batch';
    DataCaptionFields = Name, Description;
    LookupPageID = "Tax Difference Journal Batches";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            NotBlank = true;
            TableRelation = "Gen. Journal Template";
        }
        field(2; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(3; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(4; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";

            trigger OnValidate()
            begin
                if "Reason Code" <> xRec."Reason Code" then begin
                    ModifyLines(FieldNo("Reason Code"));
                    Modify();
                end;
            end;
        }
        field(7; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TaxDiffJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        TaxDiffJnlLine.SetRange("Journal Batch Name", Name);
        TaxDiffJnlLine.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        LockTable();
    end;

    trigger OnRename()
    begin
        TaxDiffJnlLine.SetRange("Journal Template Name", xRec."Journal Template Name");
        TaxDiffJnlLine.SetRange("Journal Batch Name", xRec.Name);
        if TaxDiffJnlLine.Find('-') then
            repeat
                TaxDiffJnlLine.Rename("Journal Template Name", Name, TaxDiffJnlLine."Line No.");
            until TaxDiffJnlLine.Next() = 0;
    end;

    var
        TaxDiffJnlTemplate: Record "Tax Diff. Journal Template";
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";

    [Scope('OnPrem')]
    procedure SetupNewBatch()
    begin
        TaxDiffJnlTemplate.Get("Journal Template Name");
        "No. Series" := TaxDiffJnlTemplate."No. Series";
        "Reason Code" := TaxDiffJnlTemplate."Reason Code";
    end;

    [Scope('OnPrem')]
    procedure ModifyLines(FieldNumber: Integer)
    begin
        TaxDiffJnlLine.LockTable();
        TaxDiffJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        TaxDiffJnlLine.SetRange("Journal Batch Name", Name);
        if TaxDiffJnlLine.Find('-') then
            repeat
                case FieldNumber of
                    FieldNo("Reason Code"):
                        TaxDiffJnlLine.Validate("Reason Code", "Reason Code");
                end;
                TaxDiffJnlLine.Modify(true);
            until TaxDiffJnlLine.Next() = 0;
    end;
}

