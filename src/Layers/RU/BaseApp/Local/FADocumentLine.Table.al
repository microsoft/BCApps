#pragma warning disable AA0247
table 12477 "FA Document Line"
{
    Caption = 'FA Document Line';
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

            trigger OnValidate()
            var
                DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
            begin
                if "FA No." = '' then
                    exit;

                GetFADocHeader();
                "Posting Date" := FADocHeader."Posting Date";
                "FA Posting Date" := FADocHeader."FA Posting Date";

                GetFA("FA No.");
                FA.TestField(Blocked, false);
                FA.TestField(Inactive, false);
                Description := FA.Description;
                "FA Location Code" := FA."FA Location Code";
                "FA Employee No." := FA."Responsible Employee";
                Status := FA.Status;
                Check(FADocHeader."FA Location Code", FADocHeader."New FA Location Code", FADocHeader."FA Employee No.");

                SetDepreciationBook();
                CalcQty();
                if FADeprBook.Get("FA No.", "Depreciation Book Code") then
                    "FA Posting Group" := FADeprBook."FA Posting Group";

                "New FA No." := "FA No.";
                if FADeprBook.Get("New FA No.", "New Depreciation Book Code") then
                    "New FA Posting Group" := FADeprBook."FA Posting Group";

                DimMgt.AddDimSource(DefaultDimSource, Database::"Fixed Asset", "FA No.");
                CreateDim(DefaultDimSource);
            end;
        }
        field(5; "New FA No."; Code[20])
        {
            Caption = 'New FA No.';
            TableRelation = "Fixed Asset";

            trigger OnValidate()
            begin
                if "New FA No." = '' then
                    exit;

                GetFA("New FA No.");
                FA.TestField(Blocked, false);
                FA.TestField(Inactive, false);
            end;
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
        field(13; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(14; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount';

            trigger OnValidate()
            begin
                "Book Value" := Amount * "Value %" / 100;
            end;
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

            trigger OnValidate()
            var
                FADeprBook: Record "FA Depreciation Book";
            begin
                FA.Get("FA No.");
                FADeprBook.Get("FA No.", "Depreciation Book Code");
                FADeprBook.SetFilter("FA Posting Date Filter", '<=%1', "FA Posting Date");
                FADeprBook.CalcFields(Quantity, "Book Value");
                if FA."Undepreciable FA" then begin
                    if Quantity > FADeprBook.Quantity then
                        TestField(Quantity, FADeprBook.Quantity);
                    if FADeprBook.Quantity > 0 then
                        "Value %" := Quantity / FADeprBook.Quantity * 100;
                end else begin
                    Quantity := 1;
                    "Value %" := 100;
                end;
                Validate(Amount, FADeprBook."Book Value");
            end;
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

            trigger OnLookup()
            begin
                LookupShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(28; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));

            trigger OnLookup()
            begin
                LookupShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
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
        field(37; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(44; "FA Location Code"; Code[10])
        {
            Caption = 'FA Location Code';
            TableRelation = "FA Location";

            trigger OnValidate()
            var
                FALocation: Record "FA Location";
            begin
                if FALocation.Get("FA Location Code") then
                    "FA Employee No." := FALocation."Employee No.";
            end;
        }
        field(45; "FA Employee No."; Code[20])
        {
            Caption = 'FA Employee No.';
            TableRelation = Employee;
        }
        field(46; "New Depreciation Book Code"; Code[10])
        {
            Caption = 'New Depreciation Book Code';
            TableRelation = "Depreciation Book";
        }
        field(47; "New FA Posting Group"; Code[20])
        {
            Caption = 'New FA Posting Group';
            TableRelation = "FA Posting Group";
        }
        field(50; "Item Receipt No."; Code[20])
        {
            Caption = 'Item Receipt No.';
            TableRelation = "Invt. Document Header"."No." where("Document Type" = const(Receipt));
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

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
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
        FA: Record "Fixed Asset";
        FASetup: Record "FA Setup";
        FADocHeader: Record "FA Document Header";
        FADeprBook: Record "FA Depreciation Book";
        DimMgt: Codeunit DimensionManagement;

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" :=
            DimMgt.GetRecDefaultDimID(
                Rec, CurrFieldNo, DefaultDimSource, "Source Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
    end;

    [Scope('OnPrem')]
    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', "Document Type", "Document No.", "Line No."));
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    [Scope('OnPrem')]
    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    [Scope('OnPrem')]
    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        Rec.ValidateShortcutDimCode(FieldNumber, ShortcutDimCode);
    end;

    [Scope('OnPrem')]
    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    [Scope('OnPrem')]
    procedure GetFADocHeader()
    begin
        TestField("Document No.");
        if ("Document Type" <> FADocHeader."Document Type") or ("Document No." <> FADocHeader."No.") then
            FADocHeader.Get(Rec."Document Type", Rec."Document No.");
    end;

    local procedure GetFA(FANo: Code[20])
    begin
        if FA."No." <> FANo then
            FA.Get(FANo);
    end;

    [Scope('OnPrem')]
    procedure SetDepreciationBook()
    begin
        FASetup.Get();
        case "Document Type" of
            "Document Type"::Writeoff:
                begin
                    Validate("Depreciation Book Code", FASetup."Release Depr. Book");
                    "New Depreciation Book Code" := '';
                end;
            "Document Type"::Release:
                begin
                    Validate("Depreciation Book Code", FASetup."Default Depr. Book");
                    "New Depreciation Book Code" := FASetup."Release Depr. Book";
                end;
            "Document Type"::Movement:
                begin
                    Validate("Depreciation Book Code", FASetup."Release Depr. Book");
                    "New Depreciation Book Code" := FASetup."Release Depr. Book";
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure ShowComments()
    var
        FAComment: Record "FA Comment";
        FAComments: Page "FA Comments";
    begin
        TestField("Document No.");
        TestField("Line No.");
        FAComment.SetRange("Document Type", "Document Type");
        FAComment.SetRange("Document No.", "Document No.");
        FAComment.SetRange("Document Line No.", "Line No.");
        FAComments.SetTableView(FAComment);
        FAComments.RunModal();
    end;

    [Scope('OnPrem')]
    procedure CalcQty()
    begin
        if FADeprBook.Get("FA No.", "Depreciation Book Code") then begin
            FADeprBook.SetFilter("FA Posting Date Filter", '<=%1', "FA Posting Date");
            FADeprBook.CalcFields(Quantity, "Book Value");
            "Value %" := 100;
            Validate(Amount, FADeprBook."Book Value");
            if FA."Undepreciable FA" then
                Quantity := FADeprBook.Quantity
            else
                Quantity := 1;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetFAComments(var Comment: array[5] of Text[80]; Type: Integer)
    var
        FAComment: Record "FA Comment";
        Index: Integer;
    begin
        Clear(Comment);
        Index := 0;
        FAComment.Reset();
        FAComment.SetCurrentKey("Document Type", "Document No.", "Document Line No.", Type);
        FAComment.SetRange("Document Type", "Document Type");
        FAComment.SetRange("Document No.", "Document No.");
        FAComment.SetRange("Document Line No.", "Line No.");
        FAComment.SetRange(Type, Type);
        if FAComment.FindSet() then
            repeat
                Index += 1;
                Comment[Index] := FAComment.Comment
            until (FAComment.Next() = 0) or (Index = ArrayLen(Comment));
    end;

    [Scope('OnPrem')]
    procedure Check(FALocationCode: Code[10]; NewFALocationCode: Code[10]; FAEmployeeNo: Code[20])
    begin
        GetFA("FA No.");
        if Status > Status::Repair then
            FA.FieldError(Status);

        case "Document Type" of
            "Document Type"::Movement:
                begin
                    if FALocationCode <> '' then
                        FA.TestField("FA Location Code", FALocationCode);
                    if "FA Location Code" <> NewFALocationCode then
                        Validate("FA Location Code", NewFALocationCode);
                end;
            "Document Type"::Writeoff:
                begin
                    if FALocationCode <> '' then
                        FA.TestField("FA Location Code", FALocationCode);
                    if FAEmployeeNo <> '' then
                        FA.TestField("Responsible Employee", FAEmployeeNo);
                end;
        end;
    end;
}

