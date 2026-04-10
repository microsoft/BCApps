#pragma warning disable AA0247
table 17315 "Tax Calc. G/L Entry"
{
    Caption = 'Tax Calc. G/L Entry';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Section Code"; Code[10])
        {
            Caption = 'Section Code';
            TableRelation = "Tax Calc. Section";
        }
        field(3; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(4; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            Editable = false;
        }
        field(5; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            Editable = false;
        }
        field(6; "Term Entry Line Code"; Code[10])
        {
            Caption = 'Term Entry Line Code';
        }
        field(7; Description; Text[70])
        {
            Caption = 'Description';
        }
        field(10; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Amount';
        }
        field(15; "Where Used Register IDs"; Code[61])
        {
            Caption = 'Where Used Register IDs';
        }
        field(21; "Ledger Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Ledger Entry No.';
            TableRelation = "G/L Entry";
        }
        field(22; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund,,,,,Receipt,Shipment,Return Rcpt.,Return Shpt.,,,,,,,Positive Adj.,Negative Adj.';
            OptionMembers = " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund,,,,,Receipt,Shipment,"Return Rcpt.","Return Shpt.",,,,,,,"Positive Adj.","Negative Adj.";
        }
        field(23; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(24; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        field(25; "Source Type"; Enum "Gen. Journal Source Type")
        {
            Caption = 'Source Type';
        }
        field(26; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = if ("Source Type" = const(Customer)) Customer
            else
            if ("Source Type" = const(Vendor)) Vendor
            else
            if ("Source Type" = const("Bank Account")) "Bank Account"
            else
            if ("Source Type" = const("Fixed Asset")) "Fixed Asset";
        }
        field(30; "Dimension 1 Value Code"; Code[20])
        {
            CaptionClass = TaxCalcMgt.GetDimCaptionClass("Section Code", 1);
            Caption = 'Dimension 1 Value Code';
        }
        field(31; "Dimension 2 Value Code"; Code[20])
        {
            CaptionClass = TaxCalcMgt.GetDimCaptionClass("Section Code", 2);
            Caption = 'Dimension 2 Value Code';
        }
        field(32; "Dimension 3 Value Code"; Code[20])
        {
            CaptionClass = TaxCalcMgt.GetDimCaptionClass("Section Code", 3);
            Caption = 'Dimension 3 Value Code';
        }
        field(33; "Dimension 4 Value Code"; Code[20])
        {
            CaptionClass = TaxCalcMgt.GetDimCaptionClass("Section Code", 4);
            Caption = 'Dimension 4 Value Code';
        }
        field(40; "Debit Account No."; Code[20])
        {
            Caption = 'Debit Account No.';
            TableRelation = "G/L Account"."No.";
        }
        field(41; "Credit Account No."; Code[20])
        {
            Caption = 'Credit Account No.';
            TableRelation = "G/L Account"."No.";
        }
        field(50; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(51; "Tax Factor"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = lookup("Tax Calc. Buffer Entry"."Tax Factor" where("Entry No." = field("Entry No."),
                                                                              Code = field("Code Filter")));
            Caption = 'Tax Factor';
            DecimalPlaces = 5 : 5;
            FieldClass = FlowField;
        }
        field(52; "Tax Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = lookup("Tax Calc. Buffer Entry"."Tax Amount" where("Entry No." = field("Entry No."),
                                                                              Code = field("Code Filter")));
            Caption = 'Tax Amount';
            DecimalPlaces = 2 :;
            FieldClass = FlowField;
        }
        field(53; "Code Filter"; Code[10])
        {
            Caption = 'Code Filter';
            FieldClass = FlowFilter;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Section Code", "Ending Date")
        {
        }
        key(Key3; "Section Code", "Starting Date")
        {
        }
        key(Key4; "Section Code", "Posting Date")
        {
        }
        key(Key5; "Section Code", "Dimension 1 Value Code", "Posting Date")
        {
        }
        key(Key6; "Section Code", "Dimension 2 Value Code", "Posting Date")
        {
        }
        key(Key7; "Section Code", "Dimension 3 Value Code", "Posting Date")
        {
        }
        key(Key8; "Section Code", "Dimension 4 Value Code", "Posting Date")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TaxCalcBufferEntry.SetRange("Entry No.", "Entry No.");
        TaxCalcBufferEntry.DeleteAll(true);
    end;

    var
        TaxCalcBufferEntry: Record "Tax Calc. Buffer Entry";
        TaxCalcMgt: Codeunit "Tax Calc. Mgt.";

    [Scope('OnPrem')]
    procedure Navigating()
    var
        Navigate: Page Navigate;
    begin
        Clear(Navigate);
        Navigate.SetDoc(Rec."Posting Date", Rec."Document No.");
        Navigate.Run();
    end;

    [Scope('OnPrem')]
    procedure DebitAccountName(): Text[100]
    var
        GLAcc: Record "G/L Account";
    begin
        if GLAcc.Get("Debit Account No.") then
            exit(GLAcc.Name);
    end;

    [Scope('OnPrem')]
    procedure CreditAccountName(): Text[100]
    var
        GLAcc: Record "G/L Account";
    begin
        if GLAcc.Get("Credit Account No.") then
            exit(GLAcc.Name);
    end;

    [Scope('OnPrem')]
    procedure SetFieldFilter(FieldNumber: Integer; TypeField: Option SumFields,CalcFields) FieldInList: Boolean
    begin
        case TypeField of
            TypeField::SumFields:
                FieldInList :=
                  FieldNumber in [
                                  FieldNo("Tax Amount"),
                                  FieldNo(Amount)
                                  ];
            TypeField::CalcFields:
                FieldInList :=
                  FieldNumber in [
                                  FieldNo("Tax Amount"),
                                  FieldNo("Tax Factor")
                                  ];
        end;
    end;

    [Scope('OnPrem')]
    procedure SourceName() Rezult: Text[250]
    var
        Employee: Record "Bank Account";
        Cust: Record Customer;
        Vend: Record Vendor;
        FA: Record "Fixed Asset";
    begin
        case "Source Type" of
            "Source Type"::Customer:
                if Cust.Get("Source No.") then
                    Rezult := CopyStr(Cust.Name, 1, MaxStrLen(Rezult));
            "Source Type"::Vendor:
                if Vend.Get("Source No.") then
                    Rezult := CopyStr(Vend.Name, 1, MaxStrLen(Rezult));
            "Source Type"::"Bank Account":
                if Employee.Get("Source No.") then
                    Rezult := CopyStr(Employee.Name, 1, MaxStrLen(Rezult));
            "Source Type"::"Fixed Asset":
                if FA.Get("Source No.") then
                    Rezult := CopyStr(FA.Description, 1, MaxStrLen(Rezult));
        end;
    end;

    [Scope('OnPrem')]
    procedure FormTitle(): Text[250]
    var
        TaxCalcHeader: Record "Tax Calc. Header";
    begin
        FilterGroup(2);
        TaxCalcHeader.SetRange("Section Code", "Section Code");
        TaxCalcHeader.SetFilter("Register ID", DelChr(GetFilter("Where Used Register IDs"), '=', '~'));
        FilterGroup(0);
        if TaxCalcHeader.FindSet() then
            if TaxCalcHeader.Next() = 0 then
                exit(TaxCalcHeader.Description);
    end;
}

