codeunit 143001 "Library - Spesometro"
{

    trigger OnRun()
    begin
    end;

    var
        VATReportSetup: Record "VAT Report Setup";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        RecordCount: array[7] of Integer;
        ConstModuleType: Option A,B,C,D,E,H,Z;
        ProgModuleErr: Label 'The progressive number did of module type %1 did not match the expected.';
        DetailAggregatedMixtureErr: Label 'Mixture of C and D records.';
        InvalidRecordTypeErr: Label 'The record type %1 is not valid.';
        ConstFormat: Option AN,CB,CB12,CF,CN,PI,DA,DT,DN,D4,D6,NP,NU,NUp,Nx,PC,PR,QU,PN,VP;
        ConstType: Option FE,FE1,FE2,FR,FR1,FR2,NE,NR,DF,FN,SE,TA,FA,SA,BL,BL1,BL2;
        IncorrectContentErr: Label 'Line no %1, position %2 has incorrect content.';
        BlockValueNotFoundErr: Label 'Block with key %1 did not match the expected value.';
        TaxRepresentativeTxt: Label 'Tax Representative';

    [Scope('OnPrem')]
    procedure CreateCustomer(IndividualPerson: Boolean; Resident: Option; UseVATRegNo: Boolean; UseFiscalCode: Boolean): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Address, LibraryUtility.GenerateRandomCode(Customer.FieldNo(Address), DATABASE::Customer));
        Customer.Validate(Name, LibraryUtility.GenerateRandomCode(Customer.FieldNo(Name), DATABASE::Customer));
        Customer.Validate("Country/Region Code", GetCountryCode());
        Customer.Validate(City, LibraryUtility.GenerateRandomCode(Customer.FieldNo(City), DATABASE::Customer));
        Customer.Validate("Individual Person", IndividualPerson);
        Customer.Validate(Resident, Resident);

        if UseVATRegNo then
            Customer.Validate(
              "VAT Registration No.", LibraryUtility.GenerateRandomCode(Customer.FieldNo("VAT Registration No."), DATABASE::Customer));

        if UseFiscalCode then
            Customer."Fiscal Code" := LibraryUtility.GenerateRandomCode(Customer.FieldNo("Fiscal Code"), DATABASE::Customer);

        if IndividualPerson and (Resident = Customer.Resident::"Non-Resident") then begin
            Customer.Validate("First Name", LibraryUtility.GenerateRandomCode(Customer.FieldNo("First Name"), DATABASE::Customer));
            Customer.Validate("Last Name", LibraryUtility.GenerateRandomCode(Customer.FieldNo("Last Name"), DATABASE::Customer));
            Customer.Validate("Date of Birth", CalcDate('<-' + Format(LibraryRandom.RandInt(100)) + 'Y>'));
            Customer.Validate(
              "Place of Birth", LibraryUtility.GenerateRandomCode(Customer.FieldNo("Place of Birth"), DATABASE::Customer))
        end;

        Customer.Modify(true);
        exit(Customer."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateVendor(IndividualPerson: Boolean; Resident: Option; UseVatRegNo: Boolean; UseFiscalCode: Boolean): Code[20]
    var
        CountryRegion: Record "Country/Region";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(Address, LibraryUtility.GenerateRandomCode(Vendor.FieldNo(Address), DATABASE::Vendor));
        Vendor.Validate(Name, LibraryUtility.GenerateRandomCode(Vendor.FieldNo(Name), DATABASE::Vendor));
        Vendor.Validate("Individual Person", IndividualPerson);
        Vendor.Validate(Resident, Resident);
        Vendor.Validate("Country/Region Code", GetCountryCode());

        CountryRegion.SetFilter("Foreign Country/Region Code", '<>%1', '');
        CountryRegion.FindFirst();
        Vendor.Validate("Country/Region Code", CountryRegion.Code);
        Vendor.Validate(City, LibraryUtility.GenerateRandomCode(Vendor.FieldNo(City), DATABASE::Vendor));

        if UseVatRegNo then
            Vendor.Validate(
              "VAT Registration No.", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("VAT Registration No."), DATABASE::Vendor));

        if UseFiscalCode then
            Vendor."Fiscal Code" := LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Fiscal Code"), DATABASE::Vendor);

        if IndividualPerson then begin
            Vendor.Validate("First Name", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("First Name"), DATABASE::Vendor));
            Vendor.Validate("Last Name", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Last Name"), DATABASE::Vendor));
            Vendor.Validate(Gender, Vendor.Gender::Male);
            Vendor.Validate("Date of Birth", CalcDate('<-' + Format(LibraryRandom.RandInt(100)) + 'Y>'));
            Vendor.Validate("Birth City", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Birth City"), DATABASE::Vendor));
            Vendor.Validate(
              "Birth County", CopyStr(LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Birth County"), DATABASE::Vendor), 1, 2));
            if Resident = Vendor.Resident::"Non-Resident" then
                Vendor.Validate("Birth Country/Region Code", GetCountryCode());
        end;

        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateAppointmentCode(): Code[2]
    var
        AppointmentCode: Record "Appointment Code";
    begin
        AppointmentCode.Init();
        AppointmentCode.Validate(Code, LibraryUtility.GenerateRandomCode(AppointmentCode.FieldNo(Code), DATABASE::"Appointment Code"));
        if AppointmentCode.Insert() then;
        exit(AppointmentCode.Code);
    end;

    [Scope('OnPrem')]
    procedure ReadValue(TextFile: BigText; LineNo: Integer; ValuePosition: Integer; ValueLength: Integer) SubText: Text[1024]
    begin
        SubText := ''; // Required for PreCAL.
        TextFile.GetSubText(SubText, (LineNo - 1) * 1900 + ValuePosition, ValueLength);
    end;

    [Scope('OnPrem')]
    procedure ReadBlockValue(var TextFile: BigText; LineNo: Integer; "Key": Text): Text
    var
        FullValue: Text;
        Index: Integer;
        SingleValue: Text;
        Pos: Integer;
    begin
        FullValue := '';
        for Index := 0 to 74 do begin
            Pos := 90 + Index * 24;
            if ReadValue(TextFile, LineNo, Pos, StrLen(Key)) = Key then begin
                SingleValue := ReadValue(TextFile, LineNo, Pos + 8, 16);
                // Note: Possible issue if the value starts with '+'. The file format does not support any escaping.
                if SingleValue[1] = '+' then
                    FullValue += ReadValue(TextFile, LineNo, Pos + 9, 15)
                else
                    FullValue += ReadValue(TextFile, LineNo, Pos + 8, 16)
            end
        end;
        exit(FullValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyStructure(var TextFile: BigText; var ReportType: Option Standard,Corrective,Cancellation; TransNo: Integer; TotalTransNo: Integer; OriginalReportNo: Code[20]; StartDate: Date; EndDate: Date)
    var
        Index: Integer;
        CurrentLineType: Text;
        LineType: Text;
        ProgModule: Integer;
    begin
        // Verify line structure
        CurrentLineType := '';
        Clear(RecordCount);
        for Index := 1 to Round(TextFile.Length / 1900, 1, '>') do begin
            VerifyLine(TextFile, Index);
            LineType := ReadValue(TextFile, Index, 1, 1);

            // Verify progressive module numbering
            Evaluate(ConstModuleType, LineType);
            RecordCount[ConstModuleType + 1] += 1;
            if LineType in ['B' .. 'E'] then begin
                Evaluate(ProgModule, ReadValue(TextFile, Index, 18, 8));
                Assert.AreEqual(ProgModule, RecordCount[ConstModuleType + 1], StrSubstNo(ProgModuleErr, LineType));
            end;

            // Verify no aggregated/detailed mixture
            if LineType in ['C', 'D'] then begin
                if CurrentLineType = '' then
                    CurrentLineType := LineType;
                if CurrentLineType <> LineType then
                    Error(DetailAggregatedMixtureErr);
            end;
        end;

        // Verify Header
        VerifyHeader(TextFile, 1, TransNo, TotalTransNo, StartDate, EndDate);
        VerifyBRecord(TextFile, 2, CurrentLineType, ReportType, OriginalReportNo, StartDate);
        if Round(TextFile.Length / 1900, 1, '>') > 3 then
            VerifyERecord(TextFile, Round(TextFile.Length / 1900, 1, '>') - 1);
        VerifyFooter(TextFile, Round(TextFile.Length / 1900, 1, '>'));
    end;

    [Scope('OnPrem')]
    procedure VerifyLine(var TextFile: BigText; LineNo: Integer)
    var
        CompanyInformation: Record "Company Information";
        RecordType: Text;
        LastCtrlChar: Text[3];
    begin
        VATReportSetup.Get();
        RecordType := ReadValue(TextFile, LineNo, 1, 1);
        if not (RecordType in ['A' .. 'E', 'Z']) then
            Error(InvalidRecordTypeErr, RecordType);

        if RecordType in ['B', 'C', 'E'] then
            VerifyValue(TextFile, GetCompanyRegNo(), LineNo, 2, 16, ConstFormat::AN);
        CompanyInformation.Get();
        if RecordType in ['D'] then
            VerifyValue(TextFile, CompanyInformation.GetTaxCode(), LineNo, 2, 16, ConstFormat::AN);

        LastCtrlChar[1] := 'A';
        LastCtrlChar[2] := 13;
        LastCtrlChar[3] := 10;
        VerifyValue(TextFile, LastCtrlChar, LineNo, 1898, 3, ConstFormat::AN);
    end;

    [Scope('OnPrem')]
    procedure VerifyHeader(TextFile: BigText; LineNo: Integer; TransNo: Integer; TotalTransNo: Integer; StartDate: Date; EndDate: Date)
    var
        CompanyInformation: Record "Company Information";
        SpesometroAppointment: Record "Spesometro Appointment";
        AppointmentFieldName: Option "First Name","Last Name",Gender,"Date of Birth",Municipality,Province,"Fiscal Code";
    begin
        CompanyInformation.Get();
        VATReportSetup.Get();
        VerifyValue(TextFile, 'A', LineNo, 1, 1, ConstFormat::AN);
        VerifyValue(TextFile, 'NSP00', LineNo, 16, 5, ConstFormat::AN);
        if TotalTransNo > 1 then begin
            VerifyValue(TextFile, FormatNumber(Format(TransNo), 4), LineNo, 522, 4, ConstFormat::NU);
            VerifyValue(TextFile, FormatNumber(Format(TotalTransNo), 4), LineNo, 526, 4, ConstFormat::NU);
        end else begin
            VerifyValue(TextFile, '0000', LineNo, 522, 4, ConstFormat::NU);
            VerifyValue(TextFile, '0000', LineNo, 526, 4, ConstFormat::NU);
        end;

        if VATReportSetup."Intermediary VAT Reg. No." <> '' then begin
            VerifyValue(TextFile, '10', LineNo, 21, 2, ConstFormat::NU);
            VerifyValue(TextFile, VATReportSetup."Intermediary VAT Reg. No.", LineNo, 23, 16, ConstFormat::AN);
        end else begin
            VerifyValue(TextFile, '01', LineNo, 21, 2, ConstFormat::NU);
            if StartDate <> 0D then
                if GetSpesometroAppointment(SpesometroAppointment, StartDate, EndDate) then
                    VerifyValue(TextFile, SpesometroAppointment.GetValueOf(AppointmentFieldName::"Fiscal Code"), LineNo, 23, 16, ConstFormat::AN)
                else
                    VerifyValue(TextFile, CompanyInformation.GetTaxCode(), LineNo, 23, 16, ConstFormat::AN);
        end;

        VerifyValue(TextFile, PadStr(' ', 14), LineNo, 2, 14, ConstFormat::AN);
        VerifyValue(TextFile, PadStr(' ', 483), LineNo, 39, 483, ConstFormat::AN);
        VerifyValue(TextFile, PadStr(' ', 1024), LineNo, 530, 1024, ConstFormat::AN);
        VerifyValue(TextFile, PadStr(' ', 1368 - 1024), LineNo, 530 + 1024, 1368 - 1024, ConstFormat::AN);
    end;

    [Scope('OnPrem')]
    procedure VerifyBRecord(TextFile: BigText; LineNo: Integer; LineType: Text; ReportType: Option Standard,Corrective,Cancellation; OriginalReportNo: Code[20]; StartDate: Date)
    var
        CompanyInfo: Record "Company Information";
        OrgVATReportHeader: Record "VAT Report Header";
        LineTypeOption: Option FA,SA,BL,FE,FR,NE,NR,DF,FN,SE,TU,TA;
        Index: Integer;
        TypeCount: array[12] of Integer;
        CheckValue: Text;
        Type: Text;
    begin
        CompanyInfo.Get();
        VerifyValue(TextFile, 'B', LineNo, 1, 1, ConstFormat::AN);
        VerifyValue(TextFile, GetCompanyRegNo(), LineNo, 2, 16, ConstFormat::CF);
        VerifyValue(TextFile, '08106710158', LineNo, 74, 16, ConstFormat::AN);

        case ReportType of
            ReportType::Standard:
                CheckValue := '100';
            ReportType::Corrective:
                CheckValue := '010';
            ReportType::Cancellation:
                CheckValue := '001';
        end;
        VerifyValue(TextFile, CheckValue, LineNo, 90, 3, ConstFormat::AN);

        if ReportType = ReportType::Standard then
            VerifyValue(TextFile, PadStr('', 23, '0'), LineNo, 93, 23, ConstFormat::AN)
        else
            if OriginalReportNo <> '' then begin
                OrgVATReportHeader.Get(OriginalReportNo);
                OrgVATReportHeader.TestField("Tax Auth. Receipt No.");
                VerifyValue(
                  TextFile, FormatPadding(ConstFormat::NUp, OrgVATReportHeader."Tax Auth. Receipt No.", 17), LineNo, 93, 17, ConstFormat::NU);
                VerifyValue(
                  TextFile, FormatPadding(ConstFormat::NUp, OrgVATReportHeader."Tax Auth. Document No.", 18), LineNo, 110, 18, ConstFormat::NU);
            end;

        if ReportType <> ReportType::Cancellation then begin
            if LineType = 'C' then
                VerifyValue(TextFile, '10', LineNo, 128, 2, ConstFormat::AN)
            else
                VerifyValue(TextFile, '01', LineNo, 128, 2, ConstFormat::AN);
        end else
            VerifyValue(TextFile, '00', LineNo, 128, 2, ConstFormat::AN);

        for Index := 1 to Round(TextFile.Length / 1900, 1, '>') do begin
            Type := '';
            if ReadValue(TextFile, Index, 1, 1) in ['C' .. 'E'] then
                Type := ReadValue(TextFile, Index, 90, 2);
            if Type <> '' then begin
                Evaluate(LineTypeOption, Type);  // Assumption: Each record only have one customer/"VAT report line" per line in the file
                TypeCount[LineTypeOption + 1] := 1;
            end;
        end;

        for Index := 1 to 11 do
            VerifyValue(TextFile, Format(TypeCount[Index], 1, '<integer>'), LineNo, 129 + Index, 1, ConstFormat::CB);

        VATReportSetup.Get();
        if VATReportSetup."Intermediary VAT Reg. No." <> '' then begin
            VerifyValue(TextFile, VATReportSetup."Intermediary VAT Reg. No.", LineNo, 583, 16, ConstFormat::CF);
            VerifyValue(TextFile, VATReportSetup."Intermediary CAF Reg. No.", LineNo, 599, 5, ConstFormat::NUp);
            if VATReportSetup."Intermediary CAF Reg. No." <> '' then
                VerifyValue(TextFile, '2', LineNo, 604, 1, ConstFormat::NU)
            else
                VerifyValue(TextFile, '1', LineNo, 604, 1, ConstFormat::NU);
            if VATReportSetup."Intermediary Date" <> 0D then
                VerifyValue(TextFile, FormatDate(VATReportSetup."Intermediary Date", ConstFormat::DT), LineNo, 606, 8, ConstFormat::DT)
            else
                VerifyValue(TextFile, '00000000', LineNo, 606, 8, ConstFormat::NU);
        end else
            VerifyValue(TextFile, '0', LineNo, 604, 1, ConstFormat::NU);

        VerifyValue(TextFile, GetNumericValue(CompanyInfo."VAT Registration No."), LineNo, 142, 11, ConstFormat::PI);
        VerifyValue(TextFile, EncodeString(DelChr(CompanyInfo."Industrial Classification", '=', '.')), LineNo, 153, 6, ConstFormat::AN);
        VerifyValue(TextFile, CleanPhoneNumber(CompanyInfo."Phone No."), LineNo, 159, 12, ConstFormat::AN);
        VerifyValue(TextFile, CleanPhoneNumber(CompanyInfo."Fax No."), LineNo, 171, 12, ConstFormat::AN);
        VerifyValue(TextFile, CopyStr(CompanyInfo."E-Mail", 1, 50), LineNo, 183, 50, ConstFormat::AN);
        VerifyValue(TextFile, CopyStr(CompanyInfo.Name, 1, 60), LineNo, 328, 60, ConstFormat::AN);

        if StartDate <> 0D then
            VerifyValue(TextFile, FormatDate(StartDate, ConstFormat::DA), LineNo, 388, 4, ConstFormat::DA);
    end;

    [Scope('OnPrem')]
    procedure VerifyERecord(var TextFile: BigText; LineNo: Integer)
    var
        CompanyInfo: Record "Company Information";
        Index: Integer;
        TypeCount: array[17] of Integer;
        Type: Text;
    begin
        CompanyInfo.Get();
        VATReportSetup.Get();
        VerifyValue(TextFile, 'E', LineNo, 1, 1, ConstFormat::AN);
        VerifyValue(TextFile, GetCompanyRegNo(), LineNo, 2, 16, ConstFormat::CF);
        VerifyValue(TextFile, '08106710158', LineNo, 74, 16, ConstFormat::AN);

        for Index := 1 to ArrayLen(TypeCount) do
            TypeCount[Index] := 0;
        for Index := 1 to Round(TextFile.Length / 1900, 1, '>') do begin
            Type := '';
            if ReadValue(TextFile, Index, 1, 1) in ['C', 'D'] then
                Type := ReadValue(TextFile, Index, 90, 2);

            if Type <> '' then begin
                Evaluate(ConstType, Type);  // Assumption: Each record only have one customer/"VAT report line" per line in the file
                case ConstType of
                    ConstType::BL:
                        begin
                            if VerifyBlockValue(TextFile, Index, 'BL002002', FormatPadding(ConstFormat::CB, '1', 16), true, false) then
                                TypeCount[ConstType::BL + 1] += 1;
                            if VerifyBlockValue(TextFile, Index, 'BL002003', FormatPadding(ConstFormat::CB, '1', 16), true, false) then
                                TypeCount[ConstType::BL1 + 1] += 1;
                            if VerifyBlockValue(TextFile, Index, 'BL002004', FormatPadding(ConstFormat::CB, '1', 16), true, false) then
                                TypeCount[ConstType::BL2 + 1] += 1;
                        end;
                    ConstType::FE:
                        if VerifyBlockValue(TextFile, Index, 'FE001003', FormatPadding(ConstFormat::CB, '1', 16), true, false) then
                            TypeCount[ConstType::FE2 + 1] += 1
                        else
                            TypeCount[ConstType::FE1 + 1] += 1;
                    ConstType::FR:
                        if VerifyBlockValue(TextFile, Index, 'FR001002', FormatPadding(ConstFormat::CB, '1', 16), true, false) then
                            TypeCount[ConstType::FR2 + 1] += 1
                        else
                            TypeCount[ConstType::FR1 + 1] += 1;
                    else
                        TypeCount[ConstType + 1] += 1;
                end;
            end;
        end;

        VerifyERecordCount(TextFile, LineNo, 'TA001001', TypeCount, ConstType::FA);
        VerifyERecordCount(TextFile, LineNo, 'TA002001', TypeCount, ConstType::SA);
        VerifyERecordCount(TextFile, LineNo, 'TA003001', TypeCount, ConstType::BL);
        VerifyERecordCount(TextFile, LineNo, 'TA003002', TypeCount, ConstType::BL1);
        VerifyERecordCount(TextFile, LineNo, 'TA003003', TypeCount, ConstType::BL2);
        VerifyERecordCount(TextFile, LineNo, 'TA004001', TypeCount, ConstType::FE1);
        VerifyERecordCount(TextFile, LineNo, 'TA004002', TypeCount, ConstType::FE2);
        VerifyERecordCount(TextFile, LineNo, 'TA005001', TypeCount, ConstType::FR1);
        VerifyERecordCount(TextFile, LineNo, 'TA005002', TypeCount, ConstType::FR2);
        VerifyERecordCount(TextFile, LineNo, 'TA006001', TypeCount, ConstType::NE);
        VerifyERecordCount(TextFile, LineNo, 'TA007001', TypeCount, ConstType::NR);
        VerifyERecordCount(TextFile, LineNo, 'TA008001', TypeCount, ConstType::DF);
        VerifyERecordCount(TextFile, LineNo, 'TA009001', TypeCount, ConstType::FN);
        VerifyERecordCount(TextFile, LineNo, 'TA010001', TypeCount, ConstType::SE);
        VerifyBlockValue(TextFile, LineNo, 'TA011001', FormatPadding(ConstFormat::NP, '0', 16), true, true);
    end;

    [Scope('OnPrem')]
    procedure VerifyERecordCount(var TextFile: BigText; LineNo: Integer; BlockKey: Text; TypeCount: array[13] of Integer; TypeKey: Integer)
    begin
        VerifyBlockValue(TextFile, LineNo, BlockKey, FormatPadding(ConstFormat::NP, Format(TypeCount[TypeKey + 1]), 16), true, true);
    end;

    [Scope('OnPrem')]
    procedure VerifyFooter(TextFile: BigText; LineNo: Integer)
    var
        Index: Integer;
        RecordCount: array[7] of Integer;
        RecordType: Option ,A,B,C,D,E,H,Z;
        Type: Text;
    begin
        VerifyValue(TextFile, 'Z', LineNo, 1, 1, ConstFormat::AN);

        for Index := 1 to Round(TextFile.Length / 1900, 1, '>') do begin
            Type := '';
            Type := ReadValue(TextFile, Index, 1, 1);
            if Type <> '' then begin
                Evaluate(RecordType, Type);
                RecordCount[RecordType] += 1;
            end;
        end;

        for Index := 2 to 5 do
            VerifyValue(TextFile, FormatNumber(Format(RecordCount[Index]), 9), LineNo, 16 + (Index - 2) * 9, 9, ConstFormat::NU);
    end;

    [Scope('OnPrem')]
    procedure VerifyValue(TextFile: BigText; ExpectedValue: Text; LineNo: Integer; Position: Integer; Length: Integer; FormatValue: Option)
    begin
        Assert.AreEqual(
          FormatPadding(FormatValue, ExpectedValue, Length), ReadValue(TextFile, LineNo, Position, Length),
          StrSubstNo(IncorrectContentErr, LineNo, Position));
    end;

    [Scope('OnPrem')]
    procedure VerifyBlockValue(var TextFile: BigText; LineNo: Integer; "Key": Text; Value: Text; AllowEmpty: Boolean; ThrowError: Boolean): Boolean
    var
        FullValue: Text;
        MaxLength: Integer;
    begin
        FullValue := ReadBlockValue(TextFile, LineNo, Key);
        if (FullValue = '') and AllowEmpty then
            exit(false);

        if StrLen(FullValue) > StrLen(Value) then
            MaxLength := StrLen(FullValue)
        else
            MaxLength := StrLen(Value);

        if ThrowError then begin
            Assert.AreEqual(FormatPadding(ConstFormat::AN, Value, MaxLength), FullValue, StrSubstNo(BlockValueNotFoundErr, Key));
            exit(true);
        end;
        if FormatPadding(ConstFormat::AN, Value, MaxLength) = FullValue then
            exit(true);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure FormatPadding(ValueFormat: Option; Value: Text; Length: Integer): Text
    begin
        case ValueFormat of
            ConstFormat::CN, ConstFormat::NUp:
                exit(PadStr('', Length - StrLen(Value), '0') + Value);
            ConstFormat::NU, ConstFormat::CB, ConstFormat::DA, ConstFormat::DT, ConstFormat::DN, ConstFormat::D4,
          ConstFormat::D6, ConstFormat::NP, ConstFormat::Nx, ConstFormat::PC, ConstFormat::QU, ConstFormat::CB12,
          ConstFormat::VP:
                exit(PadStr(' ', Length - StrLen(Value)) + Value);
            ConstFormat::PI, ConstFormat::AN, ConstFormat::CF, ConstFormat::PR:
                exit(UpperCase(Value) + PadStr(' ', Length - StrLen(Value)));
        end;
        exit(Value);
    end;

    [Scope('OnPrem')]
    procedure FormatDate(InputDate: Date; OutputFormat: Option): Text
    begin
        case OutputFormat of
            ConstFormat::DT, ConstFormat::DN:
                exit(Format(InputDate, 0, '<Day,2><Month,2><Year4>'));
            ConstFormat::DA:
                exit(Format(InputDate, 0, '<Year4>'));
            ConstFormat::D4:
                exit(Format(InputDate, 0, '<Day,2><Month,2>'));
            ConstFormat::D6:
                exit(Format(InputDate, 0, '<Month,2><Year4>'));
        end;
        exit(Format(InputDate));
    end;

    [Scope('OnPrem')]
    procedure FormatNumber(NumericValue: Code[20]; FieldLength: Integer) FormattedNumericValue: Text[20]
    var
        Index: Integer;
    begin
        FormattedNumericValue := NumericValue;
        for Index := 1 to FieldLength - StrLen(NumericValue) do
            FormattedNumericValue := '0' + FormattedNumericValue;
    end;

    [Scope('OnPrem')]
    procedure CleanPhoneNumber(PhoneNumber: Text): Text
    begin
        exit(DelChr(PhoneNumber, '=', DelChr(PhoneNumber, '=', '0123456789')));
    end;

    [Scope('OnPrem')]
    procedure GetVendorFiscalCode(var Vendor: Record Vendor; var VATEntry: Record "VAT Entry"): Text
    begin
        if VATEntry."Fiscal Code" <> '' then
            exit(VATEntry."Fiscal Code");

        exit(Vendor."Fiscal Code");
    end;

    [Scope('OnPrem')]
    procedure GetVendorVATRegNo(var Vendor: Record Vendor; var VATEntry: Record "VAT Entry"): Text
    begin
        if VATEntry."VAT Registration No." <> '' then
            exit(VATEntry."VAT Registration No.");

        exit(Vendor."VAT Registration No.");
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure GetThresholdAmount(): Decimal
    begin
        exit(999999);
    end;

    [Scope('OnPrem')]
    procedure InsertSpesometroAppointment(var SpesometroAppointment: Record "Spesometro Appointment"; AppointmentCode: Code[2]; VendorNo: Code[20]; StartingDate: Date; EndingDate: Date)
    begin
        Clear(SpesometroAppointment);
        SpesometroAppointment.Validate("Appointment Code", AppointmentCode);
        SpesometroAppointment.Validate("Vendor No.", VendorNo);
        SpesometroAppointment.Validate("Starting Date", StartingDate);
        SpesometroAppointment.Validate("Ending Date", EndingDate);
        SpesometroAppointment.Validate(Designation, 'Designation');
        SpesometroAppointment.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure GetSpesometroAppointment(var SpesometroAppointment: Record "Spesometro Appointment"; StartDate: Date; EndDate: Date): Boolean
    var
        CompanyInfo: Record "Company Information";
    begin
        if SpesometroAppointment.FindAppointmentByDate(StartDate, EndDate) then
            exit(true);

        // Fallback: Tax Representative, use a virtual entry
        CompanyInfo.Get();
        if CompanyInfo."Tax Representative No." <> '' then begin
            SpesometroAppointment.Init();
            SpesometroAppointment."Appointment Code" := '06'; // Tax Representative
            SpesometroAppointment."Vendor No." := CompanyInfo."Tax Representative No.";
            SpesometroAppointment."Starting Date" := StartDate;
            SpesometroAppointment."Ending Date" := 0D;
            SpesometroAppointment.Designation := TaxRepresentativeTxt;
            exit(true);
        end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure GetCountryCode(): Code[10]
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        CompanyInformation.Get();
        CountryRegion.SetFilter(Code, '<>%1', CompanyInformation."Country/Region Code");
        CountryRegion.SetFilter("EU Country/Region Code", '');
        LibraryERM.FindCountryRegion(CountryRegion);
        CountryRegion.Validate("Foreign Country/Region Code", Format(LibraryRandom.RandInt(100)));
        CountryRegion.Modify(true);
        exit(CountryRegion.Code);
    end;

    [Scope('OnPrem')]
    procedure GetNumericValue(FullText: Code[20]): Code[20]
    var
        Position: Integer;
        Character: Code[1];
        Number: Code[20];
    begin
        repeat
            Position := Position + 1;
            Character := CopyStr(FullText, Position, 1);
            if Character in ['0' .. '9'] then
                Number := Number + CopyStr(FullText, Position, 1);
        until Position >= StrLen(FullText);
        exit(Number);
    end;

    [Scope('OnPrem')]
    procedure GetRandomDate(): Date
    begin
        exit(CalcDate('<-CM-1M-1D+' + Format(LibraryRandom.RandInt(28)) + 'D>'));
    end;

    [Scope('OnPrem')]
    procedure GetPostfix(InputStr: Text; Length: Integer): Text
    var
        InputLength: Integer;
    begin
        InputLength := StrLen(InputStr);
        if InputLength > Length then
            exit(CopyStr(InputStr, InputLength - Length + 1, Length));
        exit(InputStr);
    end;

    [Scope('OnPrem')]
    procedure EncodeString(InputText: Text): Text
    var
        Length: Integer;
        Output: Text;
        IndexWrite: Integer;
        Index: Integer;
    begin
        Length := StrLen(InputText);
        Output := '';
        IndexWrite := 1;
        for Index := 1 to Length do
            if InputText[Index] <> 0 then
                if InputText[Index] in ['a' .. 'z', 'A' .. 'Z', '0' .. '9', '-', ',', ' ', '@', '.', '_'] then begin
                    Output[IndexWrite] := InputText[Index];
                    IndexWrite += 1;
                end;
        exit(UpperCase(Output));
    end;

    [Scope('OnPrem')]
    procedure CleanString(InputStr: Text) OutputStr: Text
    var
        Index: Integer;
        IndexWrite: Integer;
    begin
        OutputStr := PadStr(' ', StrLen(InputStr));
        IndexWrite := 1;
        for Index := 1 to StrLen(InputStr) do
            if InputStr[Index] in ['a' .. 'z', 'A' .. 'Z', '0' .. '9', '-', ',', ' ', '@', '.', '_'] then begin
                OutputStr[IndexWrite] := InputStr[Index];
                IndexWrite += 1;
            end;
        OutputStr[IndexWrite] := 0;
    end;

    local procedure GetCompanyRegNo(): Text
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        if CompanyInformation."Fiscal Code" <> '' then
            exit(CompanyInformation."Fiscal Code");

        exit(CompanyInformation."VAT Registration No.");
    end;
}

