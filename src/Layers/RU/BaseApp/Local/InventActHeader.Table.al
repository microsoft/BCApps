#pragma warning disable AA0247
table 14908 "Invent. Act Header"
{
    Caption = 'Invent. Act Header';
    LookupPageID = "Invent. Act List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                TestStatus();
            end;
        }
        field(2; "Inventory Date"; Date)
        {
            Caption = 'Inventory Date';

            trigger OnValidate()
            begin
                TestStatus();
            end;
        }
        field(3; "Reason Document Type"; Option)
        {
            Caption = 'Reason Document Type';
            OptionCaption = 'Order,Resolution,Regulation';
            OptionMembers = "Order",Resolution,Regulation;

            trigger OnValidate()
            begin
                TestStatus();
            end;
        }
        field(4; "Reason Document No."; Code[20])
        {
            Caption = 'Reason Document No.';

            trigger OnValidate()
            begin
                TestStatus();
            end;
        }
        field(5; "Reason Document Date"; Date)
        {
            Caption = 'Reason Document Date';

            trigger OnValidate()
            begin
                TestStatus();
            end;
        }
        field(6; "Act Date"; Date)
        {
            Caption = 'Act Date';

            trigger OnValidate()
            begin
                TestStatus();
            end;
        }
        field(10; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Released';
            OptionMembers = Open,Released;
        }
        field(11; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
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
        fieldgroup(DropDown; "No.", "Inventory Date", "Act Date")
        {
        }
    }

    trigger OnDelete()
    var
        InventActLine: Record "Invent. Act Line";
    begin
        TestStatus();

        InventActLine.SetRange("Act No.", "No.");
        if InventActLine.FindFirst() then
            InventActLine.DeleteAll();
    end;

    trigger OnInsert()
    var
        NoSeries: Codeunit "No. Series";
    begin
        if "No." = '' then begin
            GLSetup.Get();
            GLSetup.TestField("Contractor Invent. Act Nos.");
            "No." := NoSeries.GetNextNo(GLSetup."Contractor Invent. Act Nos.");
        end;

        "Act Date" := WorkDate();
        "Inventory Date" := WorkDate();
    end;

    var
        GLSetup: Record "General Ledger Setup";

    [Scope('OnPrem')]
    procedure Release()
    begin
        Status := Status::Released;
        Modify();
    end;

    [Scope('OnPrem')]
    procedure Reopen()
    begin
        Status := Status::Open;
        Modify();
    end;

    [Scope('OnPrem')]
    procedure TestStatus()
    begin
        TestField(Status, Status::Open);
    end;

    [Scope('OnPrem')]
    procedure AssistEdit(): Boolean
    var
        NoSeries: Codeunit "No. Series";
    begin
        GLSetup.Get();
        GLSetup.TestField("Contractor Invent. Act Nos.");
        if NoSeries.LookupRelatedNoSeries(GLSetup."Contractor Invent. Act Nos.", xRec."No. Series", "No. Series") then begin
            "No." := NoSeries.GetNextNo("No. Series");
            exit(true);
        end;
    end;
}

