#pragma warning disable AA0247
table 12472 "Posted FA Doc. Line"
{
    Caption = 'Posted FA Doc. Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'Writeoff,Release,Movement';
            OptionMembers = Writeoff,Release,Movement;
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "FA No."; Code[20])
        {
            Caption = 'FA No.';
            TableRelation = "Fixed Asset";
        }
        field(5; "New FA No."; Code[20])
        {
            Caption = 'New FA No.';
        }
        field(6; "FA Posting Date"; Date)
        {
            Caption = 'FA Posting Date';
        }
        field(7; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(8; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            TableRelation = "Depreciation Book";
        }
        field(12; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(13; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(14; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount';
        }
        field(15; "Book Value"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Book Value';
        }
        field(16; "Value %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Value %';
        }
        field(18; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(24; "FA Posting Group"; Code[20])
        {
            Caption = 'FA Posting Group';
            TableRelation = "FA Posting Group";
        }
        field(27; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(28; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(30; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = ' ,Montage,Operation,Maintenance,Repair';
            OptionMembers = " ",Montage,Operation,Maintenance,Repair;
        }
        field(36; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(44; "FA Location Code"; Code[10])
        {
            Caption = 'FA Location Code';
            TableRelation = "FA Location";
        }
        field(45; "FA Employee No."; Code[20])
        {
            Caption = 'FA Employee No.';
            TableRelation = Employee;
        }
        field(46; "New Depreciation Book Code"; Code[10])
        {
            Caption = 'New Depreciation Book Code';
        }
        field(50; "Item Receipt No."; Code[20])
        {
            Caption = 'Item Receipt No.';
            TableRelation = "Invt. Document Header"."No." where("Document Type" = const(Receipt));
        }
        field(51; Canceled; Boolean)
        {
            Caption = 'Canceled';
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
        key(Key1; "Document Type", "Document No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        DimMgt: Codeunit DimensionManagement;
#pragma warning disable AA0074
        Text14700: Label 'The selected FA Movement Act lines will be canceled.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text14701: Label 'FA Movement between Depreciation Books must be canceled using standard Cancel Entries function.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text14702: Label 'FA Movement must be last operation.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text14703: Label 'FA Movement Act lines have been canceled.';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text14704: Label 'FA Movement Act line %1 is already canceled.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', TableCaption(), "Document No.", "Line No."));
    end;

    [Scope('OnPrem')]
    procedure ShowComments()
    var
        PostedFAComment: Record "Posted FA Comment";
        PostedFAComments: Page "Posted FA Comments";
    begin
        TestField("Document No.");
        TestField("Line No.");
        PostedFAComment.SetRange("Document Type", "Document Type");
        PostedFAComment.SetRange("Document No.", "Document No.");
        PostedFAComment.SetRange("Document Line No.", "Line No.");
        PostedFAComments.SetTableView(PostedFAComment);
        PostedFAComments.RunModal();
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
        PostedFAComment.SetRange("Document No.", "Document No.");
        PostedFAComment.SetRange("Document Line No.", "Line No.");
        PostedFAComment.SetRange(Type, Type);
        if PostedFAComment.FindSet() then
            repeat
                Index += 1;
                Comment[Index] := PostedFAComment.Comment
            until (PostedFAComment.Next() = 0) or (Index = ArrayLen(Comment));
    end;

    [Scope('OnPrem')]
    procedure CancelFALocationMovement(var PstdFADocLine: Record "Posted FA Doc. Line")
    var
        FALedgEntry: Record "FA Ledger Entry";
        FA: Record "Fixed Asset";
        FADocPost: Codeunit "FA Document-Post";
        LedgEntriesCanceled: Boolean;
    begin
        if not Confirm(Text14700, false) then
            exit;
        if PstdFADocLine.FindSet() then
            repeat
                if PstdFADocLine.Canceled then
                    Error(Text14704, PstdFADocLine."Line No.");
                if PstdFADocLine."Depreciation Book Code" <> PstdFADocLine."New Depreciation Book Code" then
                    Error(Text14701);
                if FADocPost.FoundLateEntries(
                     PstdFADocLine."FA No.",
                     PstdFADocLine."Depreciation Book Code",
                     PstdFADocLine."Posting Date")
                then
                    Error(Text14702);
                FALedgEntry.SetCurrentKey("FA No.", "Entry No.", "Document No.");
                FALedgEntry.SetRange("Document No.", PstdFADocLine."Document No.");
                FALedgEntry.SetFilter("FA No.", PstdFADocLine."FA No.");
                if FALedgEntry.FindFirst() then begin
                    FA.Get(PstdFADocLine."FA No.");
                    FA.Validate("FA Location Code", FALedgEntry."FA Location Code");
                    FA.Validate("Responsible Employee", FALedgEntry."Employee No.");
                    FA.Modify(true);
                end;
                FALedgEntry.ModifyAll(Correction, true);
                FALedgEntry.ModifyAll("Canceled from FA No.", PstdFADocLine."FA No.");
                FALedgEntry.ModifyAll("FA No.", '');
                PstdFADocLine.Canceled := true;
                PstdFADocLine.Modify();
                LedgEntriesCanceled := true;
            until PstdFADocLine.Next() = 0;
        if LedgEntriesCanceled then
            Message(Text14703);
    end;
}

