codeunit 143040 "Library VAT Statement"
{
    // Library Codeunit for ES VAT statements functionality


    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";

    [Scope('OnPrem')]
    procedure CreateAEATTransreferenceFormatXML(var AEATTransferenceFormatXML: Record "AEAT Transference Format XML"; VATStatementName: Code[10]; No: Integer; Description: Text[250]; LineType: Option; IndentationLevel: Integer; ParentLineNo: Integer; ValueType: Option; Value: Text[250]; Box: Code[5]; Ask: Boolean)
    begin
        Clear(AEATTransferenceFormatXML);
        AEATTransferenceFormatXML.Validate("VAT Statement Name", VATStatementName);
        AEATTransferenceFormatXML.Validate("Line Type", LineType);
        AEATTransferenceFormatXML.Validate(Description, Description);
        AEATTransferenceFormatXML.Validate("Indentation Level", IndentationLevel);
        AEATTransferenceFormatXML.Validate("No.", No);
        AEATTransferenceFormatXML.Validate("Parent Line No.", ParentLineNo);
        AEATTransferenceFormatXML.Validate("Value Type", ValueType);
        AEATTransferenceFormatXML.Validate(Value, Value);
        AEATTransferenceFormatXML.Validate(Box, Box);
        AEATTransferenceFormatXML.Validate(Ask, Ask);
        AEATTransferenceFormatXML.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateAEATTransreferenceFormatTxt(var AEATTransferenceFormat: Record "AEAT Transference Format"; VATStatementName: Code[10]; No: Integer; Position: Integer; Length: Integer; Type: Option; SubType: Option; Value: Text[250]; Box: Code[5])
    begin
        Clear(AEATTransferenceFormat);
        AEATTransferenceFormat.Validate("VAT Statement Name", VATStatementName);
        AEATTransferenceFormat.Validate("No.", No);
        AEATTransferenceFormat.Validate(Position, Position);
        AEATTransferenceFormat.Validate(Length, Length);
        AEATTransferenceFormat.Validate(Type, Type);
        AEATTransferenceFormat.Validate(Subtype, SubType);
        AEATTransferenceFormat.Validate(Value, Value);
        AEATTransferenceFormat.Validate(Description,
          LibraryUtility.GenerateRandomCode(AEATTransferenceFormat.FieldNo(Description), DATABASE::"AEAT Transference Format"));
        AEATTransferenceFormat.Validate(Box, Box);
        AEATTransferenceFormat.Insert(true);
    end;
}

