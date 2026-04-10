#pragma warning disable AA0247
table 14905 "Letter of Attorney Header"
{
    Caption = 'Letter of Attorney Header';
    LookupPageID = "Letter of Attorney List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; "Document Date"; Date)
        {
            Caption = 'Document Date';

            trigger OnValidate()
            begin
                TestStatusOpen();

                if "Document Date" <> 0D then
                    "Validity Date" := CalcDate('<+15D>', "Document Date")
                else
                    "Validity Date" := 0D;
            end;
        }
        field(3; "Validity Date"; Date)
        {
            Caption = 'Validity Date';

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(4; "Letter of Attorney No."; Code[20])
        {
            Caption = 'Letter of Attorney No.';

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(10; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee;

            trigger OnValidate()
            begin
                TestStatusOpen();
                if "Employee No." <> '' then begin
                    Employee.Get("Employee No.");
                    "Employee Full Name" := Employee."First Name" + ' ' +
                      Employee."Middle Name" + ' ' + Employee."Last Name";
                    "Employee Job Title" := Employee."Job Title";
                end else begin
                    "Employee Full Name" := '';
                    "Employee Job Title" := '';
                end;
            end;
        }
        field(11; "Employee Full Name"; Text[100])
        {
            Caption = 'Employee Full Name';

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(12; "Employee Job Title"; Text[50])
        {
            Caption = 'Employee Job Title';

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(16; "Source Document Type"; Option)
        {
            Caption = 'Source Document Type';
            OptionCaption = ' ,Quote,Order,Invoice,,Blanket Order';
            OptionMembers = " ",Quote,"Order",Invoice,,"Blanket Order";

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(17; "Source Document No."; Code[20])
        {
            Caption = 'Source Document No.';

            trigger OnLookup()
            begin
                LookupSourceDocument();
            end;

            trigger OnValidate()
            begin
                TestStatusOpen();
                if "Source Document No." <> '' then begin
                    PurchHeader.Get("Source Document Type" - 1, "Source Document No.");
                    Validate("Buy-from Vendor No.", PurchHeader."Buy-from Vendor No.");
                    "Document Description" :=
                      StrSubstNo(Text002,
                        PurchHeader."Document Type", PurchHeader."No.", PurchHeader."Document Date");
                end else
                    Validate("Buy-from Vendor No.", '');
            end;
        }
        field(20; "Buy-from Vendor No."; Code[20])
        {
            Caption = 'Buy-from Vendor No.';
            TableRelation = Vendor;

            trigger OnValidate()
            begin
                TestStatusOpen();
                if "Buy-from Vendor No." <> '' then begin
                    Vendor.Get("Buy-from Vendor No.");
                    "Buy-from Vendor Name" := Vendor.Name + Vendor."Name 2";
                end else
                    "Buy-from Vendor Name" := '';
            end;
        }
        field(21; "Buy-from Vendor Name"; Text[250])
        {
            Caption = 'Buy-from Vendor Name';

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(30; "Document Description"; Text[100])
        {
            Caption = 'Document Description';

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(40; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Released';
            OptionMembers = Open,Released;
        }
        field(45; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(46; "Last Modified"; DateTime)
        {
            Caption = 'Last Modified';
            Editable = false;
        }
        field(50; "Realization Check"; Text[30])
        {
            Caption = 'Realization Check';
        }
        field(97; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Letter of Attorney No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        LetterOfAttorneyLine: Record "Letter of Attorney Line";
    begin
        TestStatusOpen();

        LetterOfAttorneyLine.SetRange("Letter of Attorney No.", "No.");
        LetterOfAttorneyLine.DeleteAll();
    end;

    trigger OnInsert()
    var
        NoSeries: Codeunit "No. Series";
    begin
        if "No." = '' then begin
            PurchSetup.Get();
            PurchSetup.TestField("Letter of Attorney Nos.");
            "No." := NoSeries.GetNextNo(PurchSetup."Letter of Attorney Nos.");
        end;

        Validate("Document Date", WorkDate());

        CompanyInformation.Get();
        "User ID" := UserId;
        "Last Modified" := CurrentDateTime;

        Validate("Source Document No.");
    end;

    trigger OnModify()
    begin
        "User ID" := UserId;
        "Last Modified" := CurrentDateTime;
    end;

    trigger OnRename()
    begin
        Error(Text003, TableCaption);
    end;

    var
        Vendor: Record Vendor;
        PurchHeader: Record "Purchase Header";
        CompanyInformation: Record "Company Information";
        PurchSetup: Record "Purchases & Payables Setup";
        Employee: Record Employee;
#pragma warning disable AA0074
        Text001: Label 'Existing Letter of Attorney Lines will be deleted. Continue?';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label '%1 No. %2 from %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label 'You cannot rename %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

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
    procedure CreateAttorneyLetterLines()
    var
        PurchaseLine: Record "Purchase Line";
        LetterOfAttorneyLine: Record "Letter of Attorney Line";
    begin
        TestStatusOpen();

        LetterOfAttorneyLine.Reset();
        LetterOfAttorneyLine.SetRange("Letter of Attorney No.", "No.");
        if LetterOfAttorneyLine.FindFirst() then begin
            if not Confirm(Text001) then
                exit;
            LetterOfAttorneyLine.DeleteAll();
        end;

        PurchaseLine.SetRange("Document Type", "Source Document Type" - 1);
        PurchaseLine.SetRange("Document No.", "Source Document No.");
        if PurchaseLine.FindSet() then
            repeat
                if (PurchaseLine."Qty. to Receive" <> 0) or
                   (PurchaseLine.Type = PurchaseLine.Type::" ")
                then begin
                    LetterOfAttorneyLine.Init();
                    LetterOfAttorneyLine."Letter of Attorney No." := "No.";
                    LetterOfAttorneyLine."Line No." := PurchaseLine."Line No.";
                    case PurchaseLine.Type of
                        PurchaseLine.Type::Item:
                            LetterOfAttorneyLine.Type := LetterOfAttorneyLine.Type::Item;
                        PurchaseLine.Type::"Fixed Asset":
                            LetterOfAttorneyLine.Type := LetterOfAttorneyLine.Type::"Fixed Asset";
                        else
                            LetterOfAttorneyLine.Type := LetterOfAttorneyLine.Type::" "
                    end;
                    if LetterOfAttorneyLine.Type in [LetterOfAttorneyLine.Type::Item, LetterOfAttorneyLine.Type::"Fixed Asset"] then
                        LetterOfAttorneyLine."No." := PurchaseLine."No."
                    else
                        LetterOfAttorneyLine."No." := '';
                    LetterOfAttorneyLine.Description := PurchaseLine.Description;
                    LetterOfAttorneyLine."Description 2" := PurchaseLine."Description 2";
                    LetterOfAttorneyLine.Quantity := PurchaseLine."Qty. to Receive";
                    LetterOfAttorneyLine."Unit of Measure Code" := PurchaseLine."Unit of Measure Code";
                    LetterOfAttorneyLine."Unit of Measure" := PurchaseLine."Unit of Measure";
                    LetterOfAttorneyLine.Insert();
                end;
            until PurchaseLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure Print()
    var
        LetterOfAttorneyHeader: Record "Letter of Attorney Header";
    begin
        LetterOfAttorneyHeader := Rec;
        LetterOfAttorneyHeader.SetRecFilter();
        REPORT.RunModal(REPORT::"Letter of Attorney M-2A", true, false, LetterOfAttorneyHeader);
    end;

    [Scope('OnPrem')]
    procedure TestStatusOpen()
    begin
        TestField(Status, Status::Open);
    end;

    [Scope('OnPrem')]
    procedure AssistEdit(): Boolean
    var
        NoSeries: Codeunit "No. Series";
    begin
        PurchSetup.Get();
        PurchSetup.TestField("Letter of Attorney Nos.");
        if NoSeries.LookupRelatedNoSeries(PurchSetup."Letter of Attorney Nos.", xRec."No. Series", "No. Series") then begin
            "No." := NoSeries.GetNextNo("No. Series");
            exit(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure LookupSourceDocument()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        if "Source Document Type" = "Source Document Type"::" " then
            exit;
        PurchaseHeader.FilterGroup(2);
        PurchaseHeader.SetRange("Document Type", "Source Document Type" - 1);
        if "Source Document Type" = "Source Document Type"::Invoice then
            PurchaseHeader.SetRange("Empl. Purchase", false);
        PurchaseHeader.FilterGroup(0);
        if PAGE.RunModal(0, PurchaseHeader) = ACTION::LookupOK then
            Validate("Source Document No.", PurchaseHeader."No.");
    end;
}

