#pragma warning disable AA0247
table 12471 "Posted FA Doc. Header"
{
    Caption = 'Posted FA Doc. Header';
    DataCaptionFields = "No.";
    LookupPageID = "Posted FA Document List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'Writeoff,Release,Movement';
            OptionMembers = Writeoff,Release,Movement;
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(3; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(6; "FA Posting Date"; Date)
        {
            Caption = 'FA Posting Date';
        }
        field(8; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(9; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(10; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(11; "Purchaser Code"; Code[20])
        {
            Caption = 'Purchaser Code';
            TableRelation = "Salesperson/Purchaser";
        }
        field(12; Comment; Boolean)
        {
            CalcFormula = exist("Posted FA Comment" where("Document Type" = field("Document Type"),
                                                           "Document No." = field("No."),
                                                           "Document Line No." = const(0)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(15; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";
        }
        field(16; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(20; "Posting No."; Code[10])
        {
            Caption = 'Posting No.';
        }
        field(22; "Reason Document No."; Code[20])
        {
            Caption = 'Reason Document No.';
        }
        field(23; "Reason Document Date"; Date)
        {
            Caption = 'Reason Document Date';
        }
        field(24; "FA Location Code"; Code[10])
        {
            Caption = 'FA Location Code';
            TableRelation = "FA Location";
        }
        field(25; "New FA Location Code"; Code[10])
        {
            Caption = 'New FA Location Code';
            TableRelation = "FA Location";
        }
        field(26; "FA Employee No."; Code[20])
        {
            Caption = 'FA Employee No.';
            TableRelation = Employee;
        }
        field(27; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
        }
        field(50; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(51; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;
        }
    }

    keys
    {
        key(Key1; "Document Type", "No.")
        {
            Clustered = true;
        }
        key(Key2; "No.", "FA Posting Date")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TestField("No. Printed");
        LockTable();

        CommentLine.SetRange("Table Name", "Document Type");
        CommentLine.SetRange("No.", "No.");
        CommentLine.DeleteAll();

        PostedFADocLine.SetRange("Document Type", "Document Type");
        PostedFADocLine.SetRange("Document No.", "No.");
        if PostedFADocLine.FindFirst() then
            PostedFADocLine.DeleteAll();
    end;

    var
        CommentLine: Record "Comment Line";
        PostedFADocLine: Record "Posted FA Doc. Line";
        DimMgt: Codeunit DimensionManagement;

    [Scope('OnPrem')]
    procedure Navigate()
    var
        NavigateForm: Page Navigate;
    begin
        NavigateForm.SetDoc("FA Posting Date", "No.");
        NavigateForm.Run();
    end;

    [Scope('OnPrem')]
    procedure GetFAComments(var Comment: array[5] of Text[80]; Type: Integer)
    var
        PostedFAComment: Record "Posted FA Comment";
        Index: Integer;
    begin
        Clear(Comment);
        Index := 0;
        PostedFAComment.Reset();
        PostedFAComment.SetCurrentKey("Document Type", "Document No.", "Document Line No.", Type);
        PostedFAComment.SetRange("Document Type", "Document Type");
        PostedFAComment.SetRange("Document No.", "No.");
        PostedFAComment.SetRange("Document Line No.", 0);
        PostedFAComment.SetRange(Type, Type);
        if PostedFAComment.FindSet() then
            repeat
                Index += 1;
                Comment[Index] := PostedFAComment.Comment
            until (PostedFAComment.Next() = 0) or (Index = ArrayLen(Comment));
    end;

    [Scope('OnPrem')]
    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "No."));
    end;
}

