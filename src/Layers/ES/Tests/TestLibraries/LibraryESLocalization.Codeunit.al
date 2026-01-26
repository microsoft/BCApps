codeunit 143000 "Library - ES Localization"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";

    [Scope('OnPrem')]
    procedure CreateCountryRegionEUVATRegistrationNo(var CountryRegion: Record "Country/Region")
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("EU Country/Region Code", CountryRegion.Code);
        CountryRegion.Validate("VAT Registration No. digits", CreateUniqueVATRegistrationNoFormat(CountryRegion));
        CountryRegion.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateCountryRegionCodeEUVATRegistrationNo(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        CreateCountryRegionEUVATRegistrationNo(CountryRegion);
        exit(CountryRegion.Code);
    end;

    [Scope('OnPrem')]
    procedure CreateEntryExitPoint(var EntryExitPoint: Record "Entry/Exit Point")
    begin
        EntryExitPoint.Init();
        EntryExitPoint.Validate(Code, LibraryUtility.GenerateRandomCode(EntryExitPoint.FieldNo(Code), DATABASE::"Entry/Exit Point"));
        EntryExitPoint.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateTransportMethod(var TransportMethod: Record "Transport Method")
    begin
        TransportMethod.Init();
        TransportMethod.Validate(Code, LibraryUtility.GenerateRandomCode(TransportMethod.FieldNo(Code), DATABASE::"Transport Method"));
        TransportMethod.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateInstallment(var Installment: Record Installment; PaymentTermsCode: Code[10])
    var
        RecRef: RecordRef;
    begin
        Installment.Init();
        Installment.Validate("Payment Terms Code", PaymentTermsCode);
        RecRef.GetTable(Installment);
        Installment.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, Installment.FieldNo("Line No.")));
        Installment.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreatePaymentDay(var PaymentDay: Record "Payment Day"; TableName: Option; "Code": Code[20]; PmtDay: Integer)
    begin
        PaymentDay.Init();
        PaymentDay.Validate("Table Name", TableName);
        PaymentDay.Validate(Code, Code);
        PaymentDay.Validate("Day of the month", PmtDay);
        PaymentDay.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateUniqueVATRegistrationNoFormat(CountryRegion: Record "Country/Region"): Integer
    var
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
    begin
        LibraryERM.CreateVATRegistrationNoFormat(VATRegistrationNoFormat, CountryRegion.Code);
        VATRegistrationNoFormat.Validate(Format, LibraryUtility.GenerateGUID());
        VATRegistrationNoFormat.Modify(true);
        exit(StrLen(VATRegistrationNoFormat.Format));
    end;
}

