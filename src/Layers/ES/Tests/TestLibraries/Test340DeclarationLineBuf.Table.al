table 144050 "Test 340 Declaration Line Buf."
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; Type; Option)
        {
            DataClassification = SystemMetadata;
            OptionMembers = " ",Purchase,Sale;
        }
        field(3; "Document Type"; Option)
        {
            DataClassification = SystemMetadata;
            OptionMembers = " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund,,,,,,,,,,,,,,,Bill;
        }
        field(4; "Document No."; Code[20])
        {
            DataClassification = SystemMetadata;
        }
        field(5; "VAT Document No."; Code[35])
        {
            DataClassification = SystemMetadata;
        }
        field(6; "Posting Date"; Date)
        {
            DataClassification = SystemMetadata;
        }
        field(7; "CV No."; Code[20])
        {
            DataClassification = SystemMetadata;
        }
        field(8; "Tax %"; Decimal)
        {
            DataClassification = SystemMetadata;
            AutoFormatType = 0;
        }
        field(9; "No. of Registers"; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(15; "Operation Code"; Code[1])
        {
            DataClassification = SystemMetadata;
        }
        field(16; "Collection Date"; Date)
        {
            DataClassification = SystemMetadata;
        }
        field(17; "Collection Amount"; Decimal)
        {
            DataClassification = SystemMetadata;
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(18; "Collection Payment Method"; Code[20])
        {
            DataClassification = SystemMetadata;
        }
        field(19; "Collection Bank Acc./Check No."; Text[35])
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Assert: Codeunit Assert;
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        ValueNotFoundForFieldMsg: Label 'Field %1 not found. Position #%2.';

    local procedure AmountToText(Amount: Decimal; FieldLen: Integer): Text[30]
    begin
        exit(IntegerToText(Round(Amount * 100, 1), FieldLen));
    end;

    local procedure IntegerToText(Number: Integer; FieldLen: Integer) IntegerText: Text[30]
    begin
        IntegerText := Format(Number, FieldLen, '<Integer>');
        exit(ConvertStr(IntegerText, ' ', '0'));
    end;

    local procedure DateToText(Date: Date; FieldLen: Integer) DateText: Text[8]
    begin
        if Date <> 0D then
            DateText := Format(Date, FieldLen, '<Year4><Month,2><Day,2>');
        exit(PadStr(DateText, FieldLen, '0'));
    end;

    [Scope('OnPrem')]
    procedure FieldToText(FieldID: Integer): Text[500]
    begin
        case FieldID of
            FieldNo("Tax %"):
                exit(AmountToText("Tax %", GetFieldLen(FieldID)));
            FieldNo("Posting Date"):
                exit(DateToText("Posting Date", GetFieldLen(FieldID)));
            FieldNo("No. of Registers"):
                exit(IntegerToText("No. of Registers", GetFieldLen(FieldID)));
            FieldNo("Document No."):
                exit(PadStr("Document No.", GetFieldLen(FieldID), ' '));
            FieldNo("VAT Document No."):
                exit(PadStr("VAT Document No.", GetFieldLen(FieldID), ' '));
            FieldNo("Operation Code"):
                exit(PadStr("Operation Code", GetFieldLen(FieldID), ' '));
            FieldNo("Collection Date"):
                exit(DateToText("Collection Date", GetFieldLen(FieldID)));
            FieldNo("Collection Amount"):
                exit(AmountToText("Collection Amount", GetFieldLen(FieldID)));
            FieldNo("Collection Payment Method"):
                exit(PadStr("Collection Payment Method", GetFieldLen(FieldID), ' '));
            FieldNo("Collection Bank Acc./Check No."):
                exit(PadStr("Collection Bank Acc./Check No.", GetFieldLen(FieldID), ' '));
        end;
    end;

    [Scope('OnPrem')]
    procedure GetFieldData(FieldID: Integer; var Text: Text[500]; var Pos: Integer; var Len: Integer)
    begin
        Pos := GetFieldPos(FieldID);
        Len := GetFieldLen(FieldID);
        Text := FieldToText(FieldID);
    end;

    [Scope('OnPrem')]
    procedure GetFieldLen(FieldID: Integer): Integer
    begin
        case FieldID of
            0:
                exit(500); // Record line length
            FieldNo("Tax %"):
                exit(5);
            FieldNo("Posting Date"):
                exit(8);
            FieldNo("No. of Registers"):
                exit(2);
            FieldNo("VAT Document No."):
                exit(18);
            FieldNo("Document No."):
                exit(18);
            FieldNo("Operation Code"):
                exit(1);
            FieldNo("Collection Date"):
                exit(8);
            FieldNo("Collection Amount"):
                exit(13);
            FieldNo("Collection Payment Method"):
                exit(1);
            FieldNo("Collection Bank Acc./Check No."):
                exit(34);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetFieldPos(FieldID: Integer): Integer
    var
        Offset: Integer;
    begin
        if Type = Type::Sale then
            Offset := 95; // e.g. Collection Date: 350 - Purchase, 445 - Sale
        case FieldID of
            FieldNo("Operation Code"):
                exit(100);
            FieldNo("Posting Date"):
                exit(109);
            FieldNo("Tax %"):
                exit(117);
            FieldNo("No. of Registers"):
                begin
                    if Type = Type::Sale then
                        exit(244);
                    exit(254);
                end;
            FieldNo("VAT Document No."):
                exit(178);
            FieldNo("Document No."):
                exit(218);
            FieldNo("Collection Date"):
                exit(350 + Offset);
            FieldNo("Collection Amount"):
                exit(358 + Offset);
            FieldNo("Collection Payment Method"):
                exit(371 + Offset);
            FieldNo("Collection Bank Acc./Check No."):
                exit(372 + Offset);
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateTaxAmount(NewTaxPct: Decimal; NewAmount: Decimal; NoOfRegs: Integer)
    begin
        "Tax %" := NewTaxPct;
        "Collection Amount" := NewAmount;
        "No. of Registers" := NoOfRegs;
        Modify();
    end;

    [Scope('OnPrem')]
    procedure VerifyField(Line: Text[1024]; FieldID: Integer)
    var
        ActualFieldValue: Text[1024];
        ExpectedFieldValue: Text[1024];
    begin
        ActualFieldValue := LibraryTextFileValidation.ReadValue(Line, GetFieldPos(FieldID), GetFieldLen(FieldID));
        ExpectedFieldValue := FieldToText(FieldID);
        Assert.AreEqual(ExpectedFieldValue, ActualFieldValue, StrSubstNo(ValueNotFoundForFieldMsg, FieldID, GetFieldPos(FieldID)));
    end;
}
