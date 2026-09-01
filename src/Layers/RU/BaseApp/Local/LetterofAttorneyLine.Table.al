#pragma warning disable AA0247
table 14906 "Letter of Attorney Line"
{
    Caption = 'Letter of Attorney Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Letter of Attorney No."; Code[20])
        {
            Caption = 'Letter of Attorney No.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,Item,,Fixed Asset';
            OptionMembers = " ",Item,,"Fixed Asset";
        }
        field(6; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const(Item)) Item
            else
            if (Type = const("Fixed Asset")) "Fixed Asset";

            trigger OnValidate()
            begin
                if "No." <> '' then
                    case Type of
                        Type::Item:
                            begin
                                Item.Get("No.");
                                Description := Item.Description;
                                "Description 2" := Item."Description 2";
                            end;
                        Type::"Fixed Asset":
                            begin
                                FixedAsset.Get("No.");
                                Description := FixedAsset.Description;
                                "Description 2" := FixedAsset."Description 2";
                            end;
                    end;
            end;
        }
        field(11; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(12; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(15; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
        }
        field(20; "Unit of Measure"; Text[50])
        {
            Caption = 'Unit of Measure';
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = if (Type = const(Item)) "Item Unit of Measure".Code where("Item No." = field("No."))
            else
            "Unit of Measure";

            trigger OnValidate()
            begin
                TestStatusOpen();
                if "Unit of Measure Code" = '' then
                    "Unit of Measure" := ''
                else begin
                    UnitOfMeasure.Get("Unit of Measure Code");
                    "Unit of Measure" := UnitOfMeasure.Description;
                end;
            end;
        }
    }

    keys
    {
        key(Key1; "Letter of Attorney No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TestStatusOpen();
    end;

    trigger OnInsert()
    begin
        TestStatusOpen();
    end;

    trigger OnModify()
    begin
        TestStatusOpen();
    end;

    var
        Item: Record Item;
        FixedAsset: Record "Fixed Asset";
        LetterOfAttorneyHeader: Record "Letter of Attorney Header";
        UnitOfMeasure: Record "Unit of Measure";

    [Scope('OnPrem')]
    procedure TestStatusOpen()
    begin
        LetterOfAttorneyHeader.Get("Letter of Attorney No.");
        LetterOfAttorneyHeader.TestStatusOpen();
    end;
}

