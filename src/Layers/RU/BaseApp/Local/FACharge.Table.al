#pragma warning disable AA0247
table 14907 "FA Charge"
{
    Caption = 'FA Charge';
    LookupPageID = "FA Charge List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; Description; Text[30])
        {
            Caption = 'Description';
        }
        field(3; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            begin
                if xRec."Gen. Prod. Posting Group" <> "Gen. Prod. Posting Group" then
                    if GenProdPostingGrp.ValidateVatProdPostingGroup(GenProdPostingGrp, "Gen. Prod. Posting Group") then
                        Validate("VAT Prod. Posting Group", GenProdPostingGrp."Def. VAT Prod. Posting Group");
            end;
        }
        field(4; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(5; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(6; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        field(7; "Exclude Cost for TA"; Boolean)
        {
            Caption = 'Exclude Cost for TA';
        }
        field(8; "G/L Acc. for Released FA"; Code[20])
        {
            Caption = 'G/L Acc. for Released FA';
            TableRelation = "G/L Account";
        }
        field(17300; "Tax Difference Code"; Code[10])
        {
            Caption = 'Tax Difference Code';
            TableRelation = "Tax Difference" where("Source Code Mandatory" = const(true),
                                                    "Depreciation Bonus" = const(false));
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
        fieldgroup(DropDown; "No.", Description)
        {
        }
    }

    trigger OnDelete()
    begin
        DimMgt.DeleteDefaultDim(DATABASE::"FA Charge", "No.");
    end;

    trigger OnRename()
    begin
        DimMgt.RenameDefaultDim(DATABASE::"FA Charge", xRec."No.", "No.");
    end;

    var
        GenProdPostingGrp: Record "Gen. Product Posting Group";
        DimMgt: Codeunit DimensionManagement;

    [Scope('OnPrem')]
    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(DATABASE::"FA Charge", "No.", FieldNumber, ShortcutDimCode);
            Modify();
        end;
    end;
}

