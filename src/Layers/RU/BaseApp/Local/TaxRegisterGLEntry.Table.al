#pragma warning disable AA0247
table 17209 "Tax Register G/L Entry"
{
    Caption = 'Tax Register G/L Entry';
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
            TableRelation = "Tax Register Section";
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
        field(12; "Entry Type"; Option)
        {
            Caption = 'Entry Type';
            OptionCaption = ' ,Incoming,Spending';
            OptionMembers = " ",Incoming,Spending;
        }
        field(13; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(15; "Amount (Document)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Amount (Document)';
            Editable = false;
        }
        field(19; "Term Entry Line Code"; Code[10])
        {
            Caption = 'Term Entry Line Code';
        }
        field(21; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Amount';
        }
        field(23; "Credit Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Credit Amount';
            Editable = false;
        }
        field(25; "Debit Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Debit Amount';
            Editable = false;
        }
        field(38; "Where Used Register IDs"; Code[61])
        {
            Caption = 'Where Used Register IDs';
        }
        field(50; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(60; "Debit Dimension 1 Value Code"; Code[20])
        {
            CaptionClass = GetDebitCaptionClass(1);
            Caption = 'Debit Dimension 1 Value Code';
        }
        field(61; "Debit Dimension 2 Value Code"; Code[20])
        {
            CaptionClass = GetDebitCaptionClass(2);
            Caption = 'Debit Dimension 2 Value Code';
        }
        field(62; "Debit Dimension 3 Value Code"; Code[20])
        {
            CaptionClass = GetDebitCaptionClass(3);
            Caption = 'Debit Dimension 3 Value Code';
        }
        field(70; "Credit Dimension 1 Value Code"; Code[20])
        {
            CaptionClass = GetCreditCaptionClass(1);
            Caption = 'Credit Dimension 1 Value Code';
        }
        field(71; "Credit Dimension 2 Value Code"; Code[20])
        {
            CaptionClass = GetCreditCaptionClass(2);
            Caption = 'Credit Dimension 2 Value Code';
        }
        field(72; "Credit Dimension 3 Value Code"; Code[20])
        {
            CaptionClass = GetCreditCaptionClass(3);
            Caption = 'Credit Dimension 3 Value Code';
        }
        field(101; "Ledger Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Ledger Entry No.';
            TableRelation = "G/L Entry"."Entry No.";
        }
        field(102; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund,,,,,Receipt,Shipment,Return Rcpt.,Return Shpt.,,,,,,,Positive Adj.,Negative Adj.';
            OptionMembers = " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund,,,,,Receipt,Shipment,"Return Rcpt.","Return Shpt.",,,,,,,"Positive Adj.","Negative Adj.";
        }
        field(103; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(106; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(107; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        field(109; "Source Type"; Enum "Gen. Journal Source Type")
        {
            Caption = 'Source Type';
        }
        field(110; "Source No."; Code[20])
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
        field(121; "Dimension 1 Value Code"; Code[20])
        {
            CaptionClass = TaxRegMgt.GetDimCaptionClass("Section Code", 1);
            Caption = 'Dimension 1 Value Code';
        }
        field(122; "Dimension 2 Value Code"; Code[20])
        {
            CaptionClass = TaxRegMgt.GetDimCaptionClass("Section Code", 2);
            Caption = 'Dimension 2 Value Code';
        }
        field(123; "Dimension 3 Value Code"; Code[20])
        {
            CaptionClass = TaxRegMgt.GetDimCaptionClass("Section Code", 3);
            Caption = 'Dimension 3 Value Code';
        }
        field(124; "Dimension 4 Value Code"; Code[20])
        {
            CaptionClass = TaxRegMgt.GetDimCaptionClass("Section Code", 4);
            Caption = 'Dimension 4 Value Code';
        }
        field(186; "Debit Account No."; Code[20])
        {
            Caption = 'Debit Account No.';
            TableRelation = "G/L Account"."No.";
        }
        field(187; "Credit Account No."; Code[20])
        {
            Caption = 'Credit Account No.';
            TableRelation = "G/L Account"."No.";
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
        key(Key9; "Where Used Register IDs", "Ledger Entry No.")
        {
        }
    }

    fieldgroups
    {
    }

    var
        GLCorrAnalysisView: Record "G/L Corr. Analysis View";
        TaxRegisterName: Record "Tax Register";
        TaxRegMgt: Codeunit "Tax Register Mgt.";
#pragma warning disable AA0074
        Text000: Label '1,5,,Debit Dimension 1 Value Code';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text001: Label '1,5,,Debit Dimension 2 Value Code';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text002: Label '1,5,,Debit Dimension 3 Value Code';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text003: Label '1,5,,Credit Dimension 1 Value Code';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text004: Label '1,5,,Credit Dimension 2 Value Code';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text005: Label '1,5,,Credit Dimension 3 Value Code';
#pragma warning restore AA0074

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
    procedure SetFieldFilter(FieldNumber: Integer) FieldInList: Boolean
    begin
        FieldInList := FieldNumber = FieldNo(Amount);
    end;

    [Scope('OnPrem')]
    procedure SourceName() Result: Text[250]
    var
        Employee: Record "Bank Account";
        Cust: Record Customer;
        Vend: Record Vendor;
        FA: Record "Fixed Asset";
    begin
        case "Source Type" of
            "Source Type"::Customer:
                if Cust.Get("Source No.") then
                    Result := CopyStr(Cust.Name, 1, MaxStrLen(Result));
            "Source Type"::Vendor:
                if Vend.Get("Source No.") then
                    Result := CopyStr(Vend.Name, 1, MaxStrLen(Result));
            "Source Type"::"Bank Account":
                if Employee.Get("Source No.") then
                    Result := CopyStr(Employee.Name, 1, MaxStrLen(Result));
            "Source Type"::"Fixed Asset":
                if FA.Get("Source No.") then
                    Result := CopyStr(FA.Description, 1, MaxStrLen(Result));
        end;
    end;

    [Scope('OnPrem')]
    procedure FormTitle(): Text[250]
    var
        TaxRegName: Record "Tax Register";
    begin
        TaxRegName.SetRange("Section Code", "Section Code");
        TaxRegName.SetFilter("Register ID", DelChr(GetFilter("Where Used Register IDs"), '=', '~'));
        if TaxRegName.Find('-') then
            if TaxRegName.Next() = 0 then
                exit(TaxRegName.Description);
    end;

    [Scope('OnPrem')]
    procedure GetDebitCaptionClass(AnalysisViewDimType: Integer): Text[250]
    begin
        if TaxRegisterName.Get("Section Code", FormTitle()) then
            if TaxRegisterName."G/L Corr. Analysis View Code" <> '' then
                GLCorrAnalysisView.Get(TaxRegisterName."G/L Corr. Analysis View Code");
        case AnalysisViewDimType of
            1:
                begin
                    if GLCorrAnalysisView."Debit Dimension 1 Code" <> '' then
                        exit('1,5,' + GLCorrAnalysisView."Debit Dimension 1 Code");
                    exit(Text000);
                end;
            2:
                begin
                    if GLCorrAnalysisView."Debit Dimension 2 Code" <> '' then
                        exit('1,5,' + GLCorrAnalysisView."Debit Dimension 2 Code");
                    exit(Text001);
                end;
            3:
                begin
                    if GLCorrAnalysisView."Debit Dimension 3 Code" <> '' then
                        exit('1,5,' + GLCorrAnalysisView."Debit Dimension 3 Code");
                    exit(Text002);
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetCreditCaptionClass(AnalysisViewDimType: Integer): Text[250]
    begin
        if TaxRegisterName.Get("Section Code", FormTitle()) then
            if TaxRegisterName."G/L Corr. Analysis View Code" <> '' then
                GLCorrAnalysisView.Get(TaxRegisterName."G/L Corr. Analysis View Code");
        case AnalysisViewDimType of
            1:
                begin
                    if GLCorrAnalysisView."Credit Dimension 1 Code" <> '' then
                        exit('1,5,' + GLCorrAnalysisView."Credit Dimension 1 Code");
                    exit(Text003);
                end;
            2:
                begin
                    if GLCorrAnalysisView."Credit Dimension 2 Code" <> '' then
                        exit('1,5,' + GLCorrAnalysisView."Credit Dimension 2 Code");
                    exit(Text004);
                end;
            3:
                begin
                    if GLCorrAnalysisView."Credit Dimension 3 Code" <> '' then
                        exit('1,5,' + GLCorrAnalysisView."Credit Dimension 3 Code");
                    exit(Text005);
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure CopyFromGLCorrEntry(GLCorrespondenceEntry: Record "G/L Correspondence Entry")
    var
        GLEntry: Record "G/L Entry";
    begin
        "Posting Date" := GLCorrespondenceEntry."Posting Date";
        "Amount (Document)" := GLCorrespondenceEntry.Amount;
        Amount := GLCorrespondenceEntry.Amount;
        Correction := GLCorrespondenceEntry.Amount < 0;
        if Correction then
            "Credit Amount" := -GLCorrespondenceEntry.Amount
        else
            "Debit Amount" := GLCorrespondenceEntry.Amount;
        "Ledger Entry No." := GLCorrespondenceEntry."Debit Entry No.";
        "Document Type" := GLCorrespondenceEntry."Document Type".AsInteger();
        "Document No." := GLCorrespondenceEntry."Document No.";
        GLEntry.Get(GLCorrespondenceEntry."Debit Entry No.");
        Description := GLEntry.Description;
        "Source Type" := GLCorrespondenceEntry."Debit Source Type";
        "Source No." := GLCorrespondenceEntry."Debit Source No.";
        "Debit Account No." := GLCorrespondenceEntry."Debit Account No.";
        "Credit Account No." := GLCorrespondenceEntry."Credit Account No.";
    end;
}

