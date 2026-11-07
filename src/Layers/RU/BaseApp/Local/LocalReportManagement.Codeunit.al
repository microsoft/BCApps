#pragma warning disable AA0247
codeunit 12401 "Local Report Management"
{

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
        Text004: Label 'must be greater than 0';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text005: Label 'must be less than 0';
#pragma warning restore AA0074
        Employee: Record Employee;
        CompanyInfo: Record "Company Information";
        DocumentSignature: Record "Document Signature";
        PostedDocumentSignature: Record "Posted Document Signature";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text008: Label '%1 BIC %2 corr. account %3 %4 %5 bank account %6';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text009: Label ', tel.: ';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text010: Label ', fax: ';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text011: Label '. S/a %1 in %2, i/a %3 BIC %4';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text013: Label '%1 No. %2';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text014: Label '%1 from %2';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text015: Label 'without VAT';
#pragma warning restore AA0074
        DecimalFractionSerarator: Text[1];
        AAAATxt: Label 'AAAA', Locked = true;
        KKKKTxt: Label 'KKKK', Locked = true;

    [Scope('OnPrem')]
    procedure RefreshDecimalPoints(var MaxDecimalPoints: Integer; Value: Decimal)
    var
        Text: Text[30];
        ZeroRight: Integer;
    begin
        if Value = 0 then
            exit;
        if DecimalFractionSerarator = '' then begin
            Text := Format(0.01);
            DecimalFractionSerarator := CopyStr(Text, 2, 1);
        end;
        Text := Format(Value);
        ZeroRight := StrPos(Text, DecimalFractionSerarator);
        if ZeroRight = 0 then
            exit;
        ZeroRight := StrLen(Text) - ZeroRight;
        if ZeroRight > MaxDecimalPoints then
            MaxDecimalPoints := ZeroRight;
    end;

    [Scope('OnPrem')]
    procedure FormatReportValue(Value: Decimal; DecPoint: Decimal): Text[100]
    var
        RoundingFactor: Decimal;
    begin
        if DecPoint = 0 then
            exit(Format(Round(Value, 1), 0, '<Sign><Integer Thousand>'));
        RoundingFactor := Power(10, 0 - DecPoint);
        exit(
          Format(
            Round(Value, RoundingFactor), 0, StrSubstNo('<Sign><Integer Thousand><Decimals,%1>', DecPoint + 1)));
    end;

    [Scope('OnPrem')]
    procedure FormatDate(Date: Date): Text
    begin
        exit(Format(Date, 0, '<Day,2>.<Month,2>.<Year4>'));
    end;

    [Scope('OnPrem')]
    procedure FormatAmount(DecValue: Decimal): Text
    begin
        exit(Format(DecValue, 0, '<Precision,2:2><Sign><Integer><Decimals><comma,.>'));
    end;

    [Scope('OnPrem')]
    procedure CheckAttributes(GenJnlLine: Record "Gen. Journal Line"; var DocAmount: Decimal; var PayerCode: array[5] of Code[20]; var PayerText: array[6] of Text[100]; var BenefeciaryCode: array[5] of Code[20]; var BenefeciaryText: array[6] of Text[130])
    var
        CompanyInfo: Record "Company Information";
        Customer: Record Customer;
        Vendor: Record Vendor;
        VendorBank: Record "Vendor Bank Account";
        CustomerBank: Record "Customer Bank Account";
        BankAccount: Record "Bank Account";
        BankAccount1: Record "Bank Account";
        CodeIndex: Option ,INN,BIC,"Corresp. Account","Current Account",KPP;
        TextIndex: Option ,Name,Name2,Bank,Bank2,City,Branch;
    begin
        Clear(PayerCode);
        Clear(PayerText);
        Clear(BenefeciaryCode);
        Clear(BenefeciaryCode);
        Clear(DocAmount);

        CompanyInfo.Get();

        GenJnlLine.TestField("Bal. Account Type", GenJnlLine."Bal. Account Type"::"Bank Account");
        BankAccount.Get(GenJnlLine."Bal. Account No.");
        if BankAccount."Currency Code" = '' then
            DocAmount := GenJnlLine."Amount (LCY)"
        else begin
            GenJnlLine.TestField("Currency Code", BankAccount."Currency Code");
            DocAmount := GenJnlLine.Amount;
        end;

        case GenJnlLine."Account Type" of
            GenJnlLine."Account Type"::"G/L Account":
                if not BankAccount."Use Client-Bank" then
                    GenJnlLine.FieldError("Account Type");
            GenJnlLine."Account Type"::Customer:
                if Customer.Get(GenJnlLine."Account No.") then
                    if CustomerBank.Get(GenJnlLine."Account No.", GenJnlLine."Beneficiary Bank Code") then begin
                        if (GenJnlLine.Amount > 0) and (GenJnlLine."Document Type" <> GenJnlLine."Document Type"::Refund) then
                            GenJnlLine.FieldError(Amount, Text005);
                        BenefeciaryCode[CodeIndex::INN] := DelChr(Customer."VAT Registration No.", '<>', ' ');
                        BenefeciaryCode[CodeIndex::KPP] := DelChr(Customer."KPP Code", '<>', ' ');
                        BenefeciaryText[TextIndex::Name] := DelChr(Customer.Name, '<>', ' ');
                        BenefeciaryText[TextIndex::Name2] := DelChr(Customer."Name 2", '<>', ' ');
                        BenefeciaryCode[CodeIndex::"Current Account"] := DelChr(CustomerBank."Bank Account No.", '<>', ' ');
                        BenefeciaryCode[CodeIndex::BIC] := DelChr(CustomerBank.BIC, '<>', ' ');
                        BenefeciaryCode[CodeIndex::"Corresp. Account"] := DelChr(CustomerBank."Bank Corresp. Account No.", '<>', ' ');
                        BenefeciaryText[TextIndex::Bank] := DelChr(CustomerBank.Name, '<>', ' ');
                        BenefeciaryText[TextIndex::Bank2] := DelChr(CustomerBank."Name 2", '<>', ' ');
                        ManageAbbrCity(BenefeciaryText[TextIndex::City], CustomerBank.City, CustomerBank."Abbr. City");
                        BenefeciaryText[TextIndex::Branch] := DelChr(CustomerBank."Bank Branch No.", '<>', ' ');
                    end;
            GenJnlLine."Account Type"::Vendor:
                if Vendor.Get(GenJnlLine."Account No.") then
                    if VendorBank.Get(GenJnlLine."Account No.", GenJnlLine."Beneficiary Bank Code") then begin
                        if GenJnlLine.Amount < 0 then
                            GenJnlLine.FieldError(Amount, Text004);
                        BenefeciaryCode[CodeIndex::INN] := DelChr(Vendor."VAT Registration No.", '<>', ' ');
                        BenefeciaryCode[CodeIndex::KPP] := DelChr(Vendor."KPP Code", '<>', ' ');
                        BenefeciaryText[TextIndex::Name] := DelChr(Vendor.Name, '<>', ' ');
                        BenefeciaryText[TextIndex::Name2] := DelChr(Vendor."Name 2", '<>', ' ');
                        BenefeciaryText[TextIndex::Branch] := DelChr(VendorBank."Bank Branch No.", '<>', ' ');
                        BenefeciaryCode[CodeIndex::"Current Account"] := DelChr(VendorBank."Bank Account No.", '<>', ' ');
                        BenefeciaryCode[CodeIndex::BIC] := DelChr(VendorBank.BIC, '<>', ' ');
                        BenefeciaryCode[CodeIndex::"Corresp. Account"] := DelChr(VendorBank."Bank Corresp. Account No.", '<>', ' ');
                        BenefeciaryText[TextIndex::Bank] := DelChr(VendorBank.Name, '<>', ' ');
                        BenefeciaryText[TextIndex::Bank2] := DelChr(VendorBank."Name 2", '<>', ' ');
                        ManageAbbrCity(BenefeciaryText[TextIndex::City], VendorBank.City, VendorBank."Abbr. City");
                    end;
            GenJnlLine."Account Type"::"Bank Account":
                if BankAccount1.Get(GenJnlLine."Account No.") then begin
                    BenefeciaryCode[CodeIndex::INN] := DelChr(CompanyInfo."VAT Registration No.", '<>', ' ');
                    BenefeciaryCode[CodeIndex::KPP] := DelChr(CompanyInfo."KPP Code", '<>', ' ');
                    BenefeciaryText[TextIndex::Name] := DelChr(CompanyInfo.Name, '<>', ' ');
                    BenefeciaryCode[CodeIndex::"Current Account"] := DelChr(BankAccount1."Bank Account No.", '<>', ' ');
                    BenefeciaryCode[CodeIndex::BIC] := DelChr(BankAccount1."Bank BIC", '<>', ' ');
                    BenefeciaryCode[CodeIndex::"Corresp. Account"] := DelChr(BankAccount1."Bank Corresp. Account No.", '<>', ' ');
                    BenefeciaryText[TextIndex::Bank] := DelChr(BankAccount1.Name, '<>', ' ');
                    BenefeciaryText[TextIndex::Bank2] := DelChr(BankAccount1."Name 2", '<>', ' ');
                    ManageAbbrCity(BenefeciaryText[TextIndex::City], BankAccount1.City, BankAccount1."Abbr. City");
                    BenefeciaryText[TextIndex::Branch] := DelChr(BankAccount1."Bank Branch No.", '<>', ' ');
                end;
        end;
        PayerCode[CodeIndex::INN] := DelChr(CompanyInfo."VAT Registration No.", '<>', ' ');
        PayerCode[CodeIndex::KPP] := DelChr(CompanyInfo."KPP Code", '<>', ' ');
        PayerText[TextIndex::Name] := DelChr(CompanyInfo.Name, '<>', ' ');
        PayerText[TextIndex::Name2] := DelChr(CompanyInfo."Name 2", '<>', ' ');
        PayerCode[CodeIndex::"Current Account"] := DelChr(BankAccount."Bank Account No.", '<>', ' ');
        PayerCode[CodeIndex::BIC] := DelChr(BankAccount."Bank BIC", '<>', ' ');
        PayerCode[CodeIndex::"Corresp. Account"] := DelChr(BankAccount."Bank Corresp. Account No.", '<>', ' ');
        PayerText[TextIndex::Bank] := DelChr(BankAccount.Name, '<>', ' ');
        PayerText[TextIndex::Bank2] := DelChr(BankAccount."Name 2", '<>', ' ');
        ManageAbbrCity(PayerText[TextIndex::City], BankAccount.City, BankAccount."Abbr. City");
        PayerText[TextIndex::Branch] := DelChr(BankAccount."Bank Branch No.", '<>', ' ');
    end;

    [Scope('OnPrem')]
    procedure PostedCheckAttributes(CheckLedgerEntries: Record "Check Ledger Entry"; var PayerCode: array[4] of Code[20]; var PayerText: array[6] of Text[100]; var BenefeciaryCode: array[4] of Code[20]; var BenefeciaryText: array[6] of Text[130])
    var
        CompanyInfo: Record "Company Information";
        Vendor: Record Vendor;
        VendorBank: Record "Vendor Bank Account";
        Customer: Record Customer;
        CustomerBank: Record "Customer Bank Account";
        BankAccount: Record "Bank Account";
        BankAccount1: Record "Bank Account";
        CodeIndex: Option ,VATRegNo,BIC,CorrAccNo,BankAccNo;
        TextIndex: Option ,Name,Name2,Bank,Bank2,City,Branch;
    begin
        Clear(PayerCode);
        Clear(PayerText);
        Clear(BenefeciaryCode);
        Clear(BenefeciaryCode);

        CompanyInfo.Get();

        BankAccount.Get(CheckLedgerEntries."Bank Account No.");

        case CheckLedgerEntries."Bal. Account Type" of
            CheckLedgerEntries."Bal. Account Type"::Customer:
                if Customer.Get(CheckLedgerEntries."Bal. Account No.") then
                    if CustomerBank.Get(CheckLedgerEntries."Bal. Account No.", CheckLedgerEntries."Beneficiary Bank Code") then begin
                        if CheckLedgerEntries.Amount > 0 then
                            CheckLedgerEntries.FieldError(Amount, Text005);
                        BenefeciaryCode[CodeIndex::VATRegNo] := DelChr(Customer."VAT Registration No.", '<>', ' ');
                        BenefeciaryText[TextIndex::Name] := DelChr(Customer.Name, '<>', ' ');
                        BenefeciaryText[TextIndex::Name2] := DelChr(Customer."Name 2", '<>', ' ');
                        BenefeciaryCode[CodeIndex::BankAccNo] := DelChr(CustomerBank."Bank Account No.", '<>', ' ');
                        BenefeciaryCode[CodeIndex::BIC] := DelChr(CustomerBank.BIC, '<>', ' ');
                        BenefeciaryCode[CodeIndex::CorrAccNo] := DelChr(CustomerBank."Bank Corresp. Account No.", '<>', ' ');
                        BenefeciaryText[TextIndex::Bank] := DelChr(CustomerBank.Name, '<>', ' ');
                        BenefeciaryText[TextIndex::Bank2] := DelChr(CustomerBank."Name 2", '<>', ' ');
                        ManageAbbrCity(BenefeciaryText[TextIndex::City], CustomerBank.City, CustomerBank."Abbr. City");
                        BenefeciaryText[TextIndex::Branch] := DelChr(CustomerBank."Bank Branch No.", '<>', ' ');
                    end;
            CheckLedgerEntries."Bal. Account Type"::Vendor:
                if Vendor.Get(CheckLedgerEntries."Bal. Account No.") then
                    if VendorBank.Get(CheckLedgerEntries."Bal. Account No.", CheckLedgerEntries."Beneficiary Bank Code") then begin
                        if CheckLedgerEntries.Amount > 0 then
                            CheckLedgerEntries.FieldError(Amount, Text004);
                        BenefeciaryCode[CodeIndex::VATRegNo] := DelChr(Vendor."VAT Registration No.", '<>', ' ');
                        BenefeciaryText[TextIndex::Name] := DelChr(Vendor.Name, '<>', ' ');
                        BenefeciaryText[TextIndex::Name2] := DelChr(Vendor."Name 2", '<>', ' ');
                        BenefeciaryCode[CodeIndex::BankAccNo] := DelChr(VendorBank."Bank Account No.", '<>', ' ');
                        BenefeciaryCode[CodeIndex::BIC] := DelChr(VendorBank.BIC, '<>', ' ');
                        BenefeciaryCode[CodeIndex::CorrAccNo] := DelChr(VendorBank."Bank Corresp. Account No.", '<>', ' ');
                        BenefeciaryText[TextIndex::Bank] := DelChr(VendorBank.Name, '<>', ' ');
                        BenefeciaryText[TextIndex::Bank2] := DelChr(VendorBank."Name 2", '<>', ' ');
                        ManageAbbrCity(BenefeciaryText[TextIndex::City], VendorBank.City, VendorBank."Abbr. City");
                        BenefeciaryText[TextIndex::Branch] := DelChr(VendorBank."Bank Branch No.", '<>', ' ');
                    end;
            CheckLedgerEntries."Bal. Account Type"::"Bank Account":
                if BankAccount1.Get(CheckLedgerEntries."Bal. Account No.") then begin
                    BenefeciaryCode[CodeIndex::VATRegNo] := DelChr(CompanyInfo."VAT Registration No.", '<>', ' ');
                    BenefeciaryText[TextIndex::Name] := DelChr(CompanyInfo.Name, '<>', ' ');
                    BenefeciaryCode[CodeIndex::BankAccNo] := DelChr(BankAccount1."Bank Account No.", '<>', ' ');
                    BenefeciaryCode[CodeIndex::BIC] := DelChr(BankAccount1."Bank BIC", '<>', ' ');
                    BenefeciaryCode[CodeIndex::CorrAccNo] := DelChr(BankAccount1."Bank Corresp. Account No.", '<>', ' ');
                    BenefeciaryText[TextIndex::Bank] := DelChr(BankAccount1.Name, '<>', ' ');
                    BenefeciaryText[TextIndex::Bank2] := DelChr(BankAccount1."Name 2", '<>', ' ');
                    ManageAbbrCity(BenefeciaryText[TextIndex::City], BankAccount1.City, BankAccount1."Abbr. City");
                    BenefeciaryText[TextIndex::Branch] := DelChr(BankAccount1."Bank Branch No.", '<>', ' ');
                end;
        end;
        PayerCode[CodeIndex::VATRegNo] := DelChr(CompanyInfo."VAT Registration No.", '<>', ' ');
        PayerText[TextIndex::Name] := DelChr(CompanyInfo.Name, '<>', ' ');
        PayerText[TextIndex::Name2] := DelChr(CompanyInfo."Name 2", '<>', ' ');
        PayerCode[CodeIndex::BankAccNo] := DelChr(BankAccount."Bank Account No.", '<>', ' ');
        PayerCode[CodeIndex::BIC] := DelChr(BankAccount."Bank BIC", '<>', ' ');
        PayerCode[CodeIndex::CorrAccNo] := DelChr(BankAccount."Bank Corresp. Account No.", '<>', ' ');
        PayerText[TextIndex::Bank] := DelChr(BankAccount.Name, '<>', ' ');
        PayerText[TextIndex::Bank2] := DelChr(BankAccount."Name 2", '<>', ' ');
        ManageAbbrCity(PayerText[TextIndex::City], BankAccount.City, BankAccount."Abbr. City");
        PayerText[TextIndex::Branch] := DelChr(BankAccount."Bank Branch No.", '<>', ' ');
    end;

    [Scope('OnPrem')]
    procedure GetCustInfo(RecordVariant: Variant; What: Option Name,Address; Type: Option Sell,Ship,Bill): Text
    var
        SalesHeader: Record "Sales Header";
        SalesShptHeader: Record "Sales Shipment Header";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ReturnRcptHeader: Record "Return Receipt Header";
        RecordRef: RecordRef;
        FullName: Text;
        FullAddress: Text;
    begin
        RecordRef.GetTable(RecordVariant);
        FullName := '';
        FullAddress := '';
        case RecordRef.Number of
            DATABASE::"Sales Header":
                begin
                    RecordRef.SetTable(SalesHeader);
                    case Type of
                        Type::Sell:
                            begin
                                FullName := GetCustName(SalesHeader."Sell-to Customer No.");
                                FullAddress :=
                                  GetFullAddr(
                                    SalesHeader."Sell-to Post Code", SalesHeader."Sell-to City",
                                    SalesHeader."Sell-to Address", SalesHeader."Sell-to Address 2", '', SalesHeader."Sell-to County");
                            end;
                        Type::Ship:
                            begin
                                FullName :=
                                  GetShipToAddrName(
                                    SalesHeader."Sell-to Customer No.",
                                    SalesHeader."Ship-to Code",
                                    SalesHeader."Ship-to Name",
                                    SalesHeader."Ship-to Name 2");
                                FullAddress :=
                                  GetFullAddr(
                                    SalesHeader."Ship-to Post Code", SalesHeader."Ship-to City",
                                    SalesHeader."Ship-to Address", SalesHeader."Ship-to Address 2", '', SalesHeader."Ship-to County");
                            end;
                        Type::Bill:
                            begin
                                FullName := GetCustName(SalesHeader."Bill-to Customer No.");
                                FullAddress :=
                                  GetFullAddr(
                                    SalesHeader."Bill-to Post Code", SalesHeader."Bill-to City",
                                    SalesHeader."Bill-to Address", SalesHeader."Bill-to Address 2", '', SalesHeader."Bill-to County");
                            end;
                    end;
                end;
            DATABASE::"Sales Shipment Header":
                begin
                    RecordRef.SetTable(SalesShptHeader);
                    case Type of
                        Type::Sell:
                            begin
                                FullName := GetCustName(SalesShptHeader."Sell-to Customer No.");
                                FullAddress :=
                                  GetFullAddr(
                                    SalesShptHeader."Sell-to Post Code", SalesShptHeader."Sell-to City",
                                    SalesShptHeader."Sell-to Address", SalesShptHeader."Sell-to Address 2", '', SalesShptHeader."Sell-to County");
                            end;
                        Type::Ship:
                            begin
                                FullName :=
                                  GetShipToAddrName(
                                    SalesShptHeader."Sell-to Customer No.",
                                    SalesShptHeader."Ship-to Code",
                                    SalesShptHeader."Ship-to Name",
                                    SalesShptHeader."Ship-to Name 2");
                                FullAddress :=
                                  GetFullAddr(
                                    SalesShptHeader."Ship-to Post Code", SalesShptHeader."Ship-to City",
                                    SalesShptHeader."Ship-to Address", SalesShptHeader."Ship-to Address 2", '', SalesShptHeader."Ship-to County");
                            end;
                        Type::Bill:
                            begin
                                FullName := GetCustName(SalesShptHeader."Bill-to Customer No.");
                                FullAddress :=
                                  GetFullAddr(
                                    SalesShptHeader."Bill-to Post Code", SalesShptHeader."Bill-to City",
                                    SalesShptHeader."Bill-to Address", SalesShptHeader."Bill-to Address 2", '', SalesShptHeader."Bill-to County");
                            end;
                    end;
                end;
            DATABASE::"Sales Invoice Header":
                begin
                    RecordRef.SetTable(SalesInvHeader);
                    case Type of
                        Type::Sell:
                            begin
                                FullName := GetCustName(SalesInvHeader."Sell-to Customer No.");
                                FullAddress :=
                                  GetFullAddr(
                                    SalesInvHeader."Sell-to Post Code", SalesInvHeader."Sell-to City",
                                    SalesInvHeader."Sell-to Address", SalesInvHeader."Sell-to Address 2", '', SalesInvHeader."Sell-to County");
                            end;
                        Type::Ship:
                            begin
                                FullName :=
                                  GetShipToAddrName(
                                    SalesInvHeader."Sell-to Customer No.",
                                    SalesInvHeader."Ship-to Code",
                                    SalesInvHeader."Ship-to Name",
                                    SalesInvHeader."Ship-to Name 2");
                                FullAddress :=
                                  GetFullAddr(
                                    SalesInvHeader."Ship-to Post Code", SalesInvHeader."Ship-to City",
                                    SalesInvHeader."Ship-to Address", SalesInvHeader."Ship-to Address 2", '', SalesInvHeader."Ship-to County");
                            end;
                        Type::Bill:
                            begin
                                FullName := GetCustName(SalesInvHeader."Bill-to Customer No.");
                                FullAddress :=
                                  GetFullAddr(
                                    SalesInvHeader."Bill-to Post Code", SalesInvHeader."Bill-to City",
                                    SalesInvHeader."Bill-to Address", SalesInvHeader."Bill-to Address 2", '', SalesInvHeader."Bill-to County");
                            end;
                    end;
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    RecordRef.SetTable(SalesCrMemoHeader);
                    case Type of
                        Type::Sell:
                            begin
                                FullName := GetCustName(SalesCrMemoHeader."Sell-to Customer No.");
                                FullAddress :=
                                  GetFullAddr(
                                    SalesCrMemoHeader."Sell-to Post Code", SalesCrMemoHeader."Sell-to City",
                                    SalesCrMemoHeader."Sell-to Address", SalesCrMemoHeader."Sell-to Address 2", '', SalesCrMemoHeader."Sell-to County");
                            end;
                        Type::Ship:
                            begin
                                FullName :=
                                  GetShipToAddrName(
                                    SalesCrMemoHeader."Sell-to Customer No.",
                                    SalesCrMemoHeader."Ship-to Code",
                                    SalesCrMemoHeader."Ship-to Name",
                                    SalesCrMemoHeader."Ship-to Name 2");
                                FullAddress :=
                                  GetFullAddr(
                                    SalesCrMemoHeader."Ship-to Post Code", SalesCrMemoHeader."Ship-to City",
                                    SalesCrMemoHeader."Ship-to Address", SalesCrMemoHeader."Ship-to Address 2", '', SalesCrMemoHeader."Ship-to County");
                            end;
                        Type::Bill:
                            begin
                                FullName := GetCustName(SalesCrMemoHeader."Bill-to Customer No.");
                                FullAddress :=
                                  GetFullAddr(
                                    SalesCrMemoHeader."Bill-to Post Code", SalesCrMemoHeader."Bill-to City",
                                    SalesCrMemoHeader."Bill-to Address", SalesCrMemoHeader."Bill-to Address 2", '', SalesCrMemoHeader."Bill-to County");
                            end;
                    end;
                end;
            DATABASE::"Return Receipt Header":
                begin
                    RecordRef.SetTable(ReturnRcptHeader);
                    case Type of
                        Type::Sell:
                            begin
                                FullName := GetCustName(ReturnRcptHeader."Sell-to Customer No.");
                                FullAddress :=
                                  GetFullAddr(
                                    ReturnRcptHeader."Sell-to Post Code", ReturnRcptHeader."Sell-to City",
                                    ReturnRcptHeader."Sell-to Address", ReturnRcptHeader."Sell-to Address 2", '', ReturnRcptHeader."Sell-to County");
                            end;
                        Type::Ship:
                            begin
                                FullName :=
                                  GetShipToAddrName(
                                    ReturnRcptHeader."Sell-to Customer No.",
                                    ReturnRcptHeader."Ship-to Code",
                                    ReturnRcptHeader."Ship-to Name",
                                    ReturnRcptHeader."Ship-to Name 2");
                                FullAddress :=
                                  GetFullAddr(
                                    ReturnRcptHeader."Ship-to Post Code", ReturnRcptHeader."Ship-to City",
                                    ReturnRcptHeader."Ship-to Address", ReturnRcptHeader."Ship-to Address 2", '', ReturnRcptHeader."Ship-to County");
                            end;
                        Type::Bill:
                            begin
                                FullName := GetCustName(ReturnRcptHeader."Bill-to Customer No.");
                                FullAddress :=
                                  GetFullAddr(
                                    ReturnRcptHeader."Bill-to Post Code", ReturnRcptHeader."Bill-to City",
                                    ReturnRcptHeader."Bill-to Address", ReturnRcptHeader."Bill-to Address 2", '', ReturnRcptHeader."Bill-to County");
                            end;
                    end;
                end;
        end;

        case What of
            What::Name:
                exit(FullName);
            What::Address:
                exit(FullAddress);
            else
                exit('');
        end;
    end;

    [Scope('OnPrem')]
    procedure GetFullAddr(PostCode: Code[20]; City: Text[30]; Address: Text[100]; Address2: Text[50]; Region: Text[30]; County: Text[30]) FullAddr: Text
    begin
        if PostCode <> '' then
            FullAddr := PostCode + ', ';
        if Region <> '' then
            FullAddr += Region + ', ';
        if County <> '' then
            FullAddr += County + ', ';
        if City <> '' then
            FullAddr := FullAddr + City + ', ';
        if Address <> '' then
            FullAddr := FullAddr + Address;
        if Address2 <> '' then
            FullAddr := FullAddr + ', ' + Address2;
    end;

    [Scope('OnPrem')]
    procedure GetEmpName(EmployeeNo: Code[20]): Text[50]
    begin
        if EmployeeNo <> '' then begin
            Employee.Get(EmployeeNo);
            exit(Employee."Last Name" + ' ' + Employee.Initials);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetEmpDepartment(EmployeeNo: Code[20]): Text[50]
    begin
        if EmployeeNo <> '' then begin
            Employee.Get(EmployeeNo);
            exit(Employee."Org. Unit Name");
        end;
    end;

    [Scope('OnPrem')]
    procedure GetEmpPosition(EmployeeNo: Code[20]): Text[50]
    begin
        if EmployeeNo <> '' then begin
            Employee.Get(EmployeeNo);
            exit(Employee."Job Title");
        end;
    end;

    [Scope('OnPrem')]
    procedure GetCompanyName(): Text[250]
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        if CompanyInfo."Full Name" <> '' then
            exit(CompanyInfo."Full Name");

        if CompanyInfo."Name 2" = '' then
            exit(CompanyInfo.Name);

        exit(CompanyInfo.Name + ' ' + DelChr(CompanyInfo."Name 2", '<'));
    end;

    [Scope('OnPrem')]
    procedure GetCompanyAddress() Addr: Text[200]
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        Addr := StrSubstNo('%1 %2, ', CompanyInfo."Post Code", CompanyInfo.City);
        if CompanyInfo."Address 2" = '' then
            Addr := Addr + CompanyInfo.Address
        else
            Addr := Addr + CompanyInfo.Address + ' ' + DelChr(CompanyInfo."Address 2", '<');
    end;

    [Scope('OnPrem')]
    procedure GetLegalAddress(): Text
    var
        CompanyAddress: Record "Company Address";
    begin
        CompanyAddress.SetRange("Address Type", CompanyAddress."Address Type"::Legal);
        if CompanyAddress.FindFirst() then
            exit(GetFullAddr(CompanyAddress."Post Code", CompanyAddress.City, CompanyAddress.Address, CompanyAddress."Address 2", CompanyAddress."Region Name", CompanyAddress.County));
    end;

    [Scope('OnPrem')]
    procedure GetUoMDesc(UoMCode: Code[10]): Text[30]
    var
        UoM: Record "Unit of Measure";
    begin
        if UoM.Get(UoMCode) then
            exit(UoM.Description);
    end;

    [Scope('OnPrem')]
    procedure GetCompanyBank(): Text[250]
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        exit(
              StrSubstNo(
                Text008,
                CompanyInfo."Bank Name",
                CompanyInfo."Bank BIC",
                CompanyInfo."Bank Corresp. Account No.",
                CompanyInfo."Bank City",
                CompanyInfo."Bank Branch No.",
                CompanyInfo."Bank Account No."));
    end;

    [Scope('OnPrem')]
    procedure ManageAbbrCity(var CityText: Text[130]; City: Text[30]; AbbrCity: Text[1])
    begin
        CityText := DelChr(City, '<>', ' ');
        if AbbrCity <> '' then
            CityText := AbbrCity + '. ' + CityText;
    end;

    [Scope('OnPrem')]
    procedure GetCompanyPhoneFax() PhoneFaxNo: Text[250]
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        if CompanyInfo."Phone No." <> '' then
            PhoneFaxNo := Text009 + CompanyInfo."Phone No.";
        if CompanyInfo."Fax No." <> '' then
            PhoneFaxNo += Text010 + CompanyInfo."Fax No.";
    end;

    [Scope('OnPrem')]
    procedure GetCompanyBankAttrib() BankAttributes: Text[250]
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        if (CompanyInfo."Bank Account No." <> '') and
           (CompanyInfo."Bank Name" <> '') and
           (CompanyInfo."Bank Corresp. Account No." <> '') and
           (CompanyInfo."Bank BIC" <> '')
        then
            BankAttributes :=
              StrSubstNo(
                Text011,
                CompanyInfo."Bank Account No.",
                CompanyInfo."Bank Name",
                CompanyInfo."Bank Corresp. Account No.",
                CompanyInfo."Bank BIC");
    end;

    [Scope('OnPrem')]
    procedure GetCustName(CustNo: Code[20]): Text[250]
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustNo);
        if Customer."Full Name" <> '' then
            exit(Customer."Full Name");

        if Customer."Name 2" = '' then
            exit(Customer.Name);

        exit(Customer.Name + ' ' + DelChr(Customer."Name 2", '<'));
    end;

    [Scope('OnPrem')]
    procedure GetCustPhoneFax(CustomerNo: Code[20]) PhoneFaxNo: Text[250]
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        if Customer."Phone No." <> '' then
            PhoneFaxNo := Text009 + Customer."Phone No.";
        if Customer."Fax No." <> '' then
            PhoneFaxNo += Text010 + Customer."Fax No.";
    end;

    [Scope('OnPrem')]
    procedure GetCustBankAttrib(CustomerNo: Code[20]; AgreementNo: Code[20]) BankAttributes: Text[250]
    var
        Customer: Record Customer;
        CustBankAccount: Record "Customer Bank Account";
        CustomerAgreement: Record "Customer Agreement";
        BankCode: Code[20];
    begin
        Customer.Get(CustomerNo);
        if AgreementNo <> '' then begin
            CustomerAgreement.Get(CustomerNo, AgreementNo);
            BankCode := CustomerAgreement."Default Bank Code";
        end else
            BankCode := Customer."Default Bank Code";
        if BankCode <> '' then begin
            CustBankAccount.Get(Customer."No.", BankCode);
            if (CustBankAccount."Bank Account No." <> '') and
               (CustBankAccount.Name <> '') and
               (CustBankAccount."Bank Corresp. Account No." <> '') and
               (CustBankAccount.BIC <> '')
            then
                BankAttributes :=
                  StrSubstNo(
                    Text011,
                    CustBankAccount."Bank Account No.",
                    CustBankAccount.Name + ' ' + CustBankAccount."Name 2",
                    CustBankAccount."Bank Corresp. Account No.",
                    CustBankAccount.BIC);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetSalesConsignerOKPOCode(ConsignerNo: Code[20]): Code[10]
    var
        Vendor: Record Vendor;
        CompanyInfo: Record "Company Information";
    begin
        if ConsignerNo <> '' then begin
            Vendor.Get(ConsignerNo);
            exit(Vendor."OKPO Code");
        end;
        CompanyInfo.Get();
        exit(CompanyInfo."OKPO Code");
    end;

    [Scope('OnPrem')]
    procedure GetCustOKPOCode(CustNo: Code[20]): Code[10]
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustNo);
        exit(Customer."OKPO Code")
    end;

    [Scope('OnPrem')]
    procedure GetShipToAddrName(CustNo: Code[20]; ShipToCode: Code[20]; ShipToName: Text[100]; ShipToName2: Text[50]): Text[250]
    var
        ShipToAddress: Record "Ship-to Address";
    begin
        if ShipToAddress.Get(CustNo, ShipToCode) then begin
            if ShipToAddress."Full Name" <> '' then
                exit(ShipToAddress."Full Name");

            if ShipToAddress."Name 2" = '' then
                exit(ShipToAddress.Name);

            exit(ShipToAddress.Name + ' ' + DelChr(ShipToAddress."Name 2", '<'));
        end;

        if ShipToName2 = '' then
            exit(ShipToName);

        exit(ShipToName + ' ' + DelChr(ShipToName2, '<'));
    end;

    [Scope('OnPrem')]
    procedure GetVendorName(VendorNo: Code[20]): Text[250]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        if Vendor."Full Name" <> '' then
            exit(Vendor."Full Name");

        if Vendor."Name 2" = '' then
            exit(Vendor.Name);

        exit(Vendor.Name + ' ' + DelChr(Vendor."Name 2", '<'));
    end;

    [Scope('OnPrem')]
    procedure GetVendorAddress(VendorNo: Code[20]): Text
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        exit(GetFullAddr(Vendor."Post Code", Vendor.City, Vendor.Address, Vendor."Address 2", '', Vendor.County));
    end;

    [Scope('OnPrem')]
    procedure GetVendBankAttrib(VendorNo: Code[20]) BankAttributes: Text[250]
    var
        Vendor: Record Vendor;
        VendBankAccount: Record "Vendor Bank Account";
    begin
        Vendor.Get(VendorNo);
        if Vendor."Default Bank Code" <> '' then begin
            VendBankAccount.Get(Vendor."No.", Vendor."Default Bank Code");
            if (VendBankAccount."Bank Account No." <> '') and
               (VendBankAccount.Name <> '') and
               (VendBankAccount."Bank Corresp. Account No." <> '') and
               (VendBankAccount.BIC <> '')
            then
                BankAttributes :=
                  StrSubstNo(
                    Text011,
                    VendBankAccount."Bank Account No.",
                    VendBankAccount.Name + ' ' + VendBankAccount."Name 2",
                    VendBankAccount."Bank Corresp. Account No.",
                    VendBankAccount.BIC);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetVendPhoneFax(VendorNo: Code[20]) PhoneFaxNo: Text[250]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        if Vendor."Phone No." <> '' then
            PhoneFaxNo := Text009 + Vendor."Phone No.";
        if Vendor."Fax No." <> '' then
            PhoneFaxNo += Text010 + Vendor."Fax No.";
    end;

    [Scope('OnPrem')]
    procedure GetRespCenterName(RespCenterNo: Code[10]): Text[100]
    var
        ResponsibilityCenter: Record "Responsibility Center";
    begin
        ResponsibilityCenter.Get(RespCenterNo);
        if ResponsibilityCenter."Name 2" = '' then
            exit(ResponsibilityCenter.Name);

        exit(ResponsibilityCenter.Name + ' ' + DelChr(ResponsibilityCenter."Name 2", '<'));
    end;

    [Scope('OnPrem')]
    procedure GetRespCenterAddress(RespCenterNo: Code[10]) Addr: Text[200]
    var
        ResponsibilityCenter: Record "Responsibility Center";
    begin
        ResponsibilityCenter.Get(RespCenterNo);
        Addr := StrSubstNo('%1 %2, ', ResponsibilityCenter."Post Code", ResponsibilityCenter.City);
        if ResponsibilityCenter."Address 2" = '' then
            Addr := Addr + ResponsibilityCenter.Address
        else
            Addr := Addr + ResponsibilityCenter.Address + ' ' + DelChr(ResponsibilityCenter."Address 2", '<');
    end;

    [Scope('OnPrem')]
    procedure GetRespCenterPhoneFax(RespCenterNo: Code[10]) PhoneFaxNo: Text[250]
    var
        ResponsibilityCenter: Record "Responsibility Center";
    begin
        ResponsibilityCenter.Get(RespCenterNo);
        if ResponsibilityCenter."Phone No." <> '' then
            PhoneFaxNo := Text009 + ResponsibilityCenter."Phone No.";
        if ResponsibilityCenter."Fax No." <> '' then
            PhoneFaxNo += Text010 + ResponsibilityCenter."Fax No.";
    end;

    [Scope('OnPrem')]
    procedure GetOKEICode(UnitOfMeasureCode: Code[10]) OKEICode: Code[3]
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if UnitOfMeasure.Get(UnitOfMeasureCode) then
            OKEICode := UnitOfMeasure."OKEI Code";
    end;

    [Scope('OnPrem')]
    procedure GetReleasedByName(PostedDocument: Boolean; TableID: Integer; DocumentType: Integer; DocumentNo: Code[20]): Text[250]
    var
        EmployeePosition: Text[250];
        EmployeeName: Text[250];
        EmployeeSignAuthorityDoc: Text[100];
    begin
        if GetDocSignEmplInfo(
             PostedDocument,
             TableID,
             DocumentType,
             DocumentNo,
             DocumentSignature."Employee Type"::ReleasedBy,
             EmployeePosition,
             EmployeeName,
             EmployeeSignAuthorityDoc)
        then
            exit(EmployeeName);

        CompanyInfo.Get();
        exit(CompanyInfo."Director Name");
    end;

    [Scope('OnPrem')]
    procedure GetDirectorName(PostedDocument: Boolean; TableID: Integer; DocumentType: Integer; DocumentNo: Code[20]): Text[250]
    var
        EmployeePosition: Text[250];
        EmployeeName: Text[250];
        EmployeeSignAuthorityDoc: Text[100];
    begin
        if GetDocSignEmplInfo(
             PostedDocument,
             TableID,
             DocumentType,
             DocumentNo,
             DocumentSignature."Employee Type"::Director,
             EmployeePosition,
             EmployeeName,
             EmployeeSignAuthorityDoc)
        then
            exit(EmployeeName);

        CompanyInfo.Get();
        exit(CompanyInfo."Director Name");
    end;

    [Scope('OnPrem')]
    procedure GetAccountantName(PostedDocument: Boolean; TableID: Integer; DocumentType: Integer; DocumentNo: Code[20]): Text[250]
    var
        EmployeePosition: Text[250];
        EmployeeName: Text[250];
        EmployeeSignAuthorityDoc: Text[100];
    begin
        if GetDocSignEmplInfo(
             PostedDocument,
             TableID,
             DocumentType,
             DocumentNo,
             DocumentSignature."Employee Type"::Accountant,
             EmployeePosition,
             EmployeeName,
             EmployeeSignAuthorityDoc)
        then
            exit(EmployeeName);

        CompanyInfo.Get();
        exit(CompanyInfo."Accountant Name");
    end;

    [Scope('OnPrem')]
    procedure GetPassedByName(PostedDocument: Boolean; TableID: Integer; DocumentType: Integer; DocumentNo: Code[20]): Text[250]
    var
        EmployeePosition: Text[250];
        EmployeeName: Text[250];
        EmployeeSignAuthorityDoc: Text[100];
    begin
        GetDocSignEmplInfo(
          PostedDocument,
          TableID,
          DocumentType,
          DocumentNo,
          DocumentSignature."Employee Type"::PassedBy,
          EmployeePosition,
          EmployeeName,
          EmployeeSignAuthorityDoc);

        exit(EmployeeName);
    end;

    [Scope('OnPrem')]
    procedure GetResponsibleName(PostedDocument: Boolean; TableID: Integer; DocumentType: Integer; DocumentNo: Code[20]): Text[250]
    var
        EmployeePosition: Text[250];
        EmployeeName: Text[250];
        EmployeeSignAuthorityDoc: Text[100];
    begin
        GetDocSignEmplInfo(
          PostedDocument,
          TableID,
          DocumentType,
          DocumentNo,
          DocumentSignature."Employee Type"::Responsible,
          EmployeePosition,
          EmployeeName,
          EmployeeSignAuthorityDoc);

        exit(EmployeeName);
    end;

    [Scope('OnPrem')]
    procedure GetDocSignEmplInfo(PostedDocument: Boolean; TableID: Integer; DocumentType: Integer; DocumentNo: Code[20]; EmployeeType: Integer; var EmployeeJobTitle: Text[250]; var EmployeeName: Text[250]; var EmployeeSignAuthorityDoc: Text[100]): Boolean
    begin
        if PostedDocument then begin
            if PostedDocumentSignature.Get(TableID, DocumentType, DocumentNo, EmployeeType) then begin
                EmployeeJobTitle := PostedDocumentSignature."Employee Job Title";
                EmployeeName := PostedDocumentSignature."Employee Name";
                EmployeeSignAuthorityDoc :=
                  GetSignAuthorityDoc(
                    PostedDocumentSignature."Warrant Description",
                    PostedDocumentSignature."Warrant No.",
                    PostedDocumentSignature."Warrant Date");
                exit(true);
            end;
        end else
            if DocumentSignature.Get(TableID, DocumentType, DocumentNo, EmployeeType) then begin
                EmployeeJobTitle := DocumentSignature."Employee Job Title";
                EmployeeName := DocumentSignature."Employee Name";
                EmployeeSignAuthorityDoc :=
                  GetSignAuthorityDoc(
                    DocumentSignature."Warrant Description",
                    DocumentSignature."Warrant No.",
                    DocumentSignature."Warrant Date");
                exit(true);
            end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure GetConsignerInfo(ConsignorNo: Code[20]; ResponsibilityCenter: Code[10]): Text[1024]
    begin
        if ConsignorNo <> '' then
            exit(
              GetVendorName(ConsignorNo) + ' ' +
              GetVendorAddress(ConsignorNo) +
              GetVendPhoneFax(ConsignorNo) +
              GetVendBankAttrib(ConsignorNo));

        if ResponsibilityCenter <> '' then
            exit(
              GetRespCenterName(ResponsibilityCenter) + ' ' +
              GetRespCenterAddress(ResponsibilityCenter) +
              GetRespCenterPhoneFax(ResponsibilityCenter) +
              GetCompanyBankAttrib());

        CompanyInfo.Get();
        exit(
          GetCompanyName() + ' ' +
          CompanyInfo."Ship-to Address" + ' ' + CompanyInfo."Ship-to Address 2" +
          GetCompanyPhoneFax() +
          GetCompanyBankAttrib());
    end;

    [Scope('OnPrem')]
    procedure GetPayerInfo(RecordVariant: Variant; CustomerNo: Code[20]; AgreementNo: Code[20]): Text
    begin
        exit(
          GetCustInfo(RecordVariant, 0, 2) + ' ' +
          GetCustInfo(RecordVariant, 1, 2) +
          GetCustPhoneFax(CustomerNo) +
          GetCustBankAttrib(CustomerNo, AgreementNo));
    end;

    [Scope('OnPrem')]
    procedure GetConsigneeInfo(RecordVariant: Variant; CustomerNo: Code[20]): Text
    begin
        exit(
          GetCustInfo(RecordVariant, 0, 1) + ' ' +
          GetCustInfo(RecordVariant, 1, 1) +
          GetCustPhoneFax(CustomerNo) +
          GetCustBankAttrib(CustomerNo, ''));
    end;

    [Scope('OnPrem')]
    procedure GetSignAuthorityDoc(WarrantDescription: Text[30]; WarrantNumber: Text[20]; WarrantDate: Date) SignAuthorityDoc: Text[100]
    begin
        SignAuthorityDoc := WarrantDescription;

        if WarrantNumber <> '' then
            SignAuthorityDoc :=
              StrSubstNo(
                Text013,
                SignAuthorityDoc,
                WarrantNumber);

        if WarrantDate <> 0D then
            SignAuthorityDoc :=
              StrSubstNo(
                Text014,
                SignAuthorityDoc,
                WarrantDate);
    end;

    [Scope('OnPrem')]
    procedure GetVATLedgerAmounInclVATFCY(VatLedgerLine: Record "VAT Ledger Line"): Text
    var
        PartialText: Text;
    begin
        PartialText := '';
        if VatLedgerLine.Partial then
            PartialText := LowerCase(VatLedgerLine.FieldCaption(Partial));
        exit(
          FormatCompoundExpr(
            FormatAmount(VatLedgerLine."Amount Including VAT"), PartialText));
    end;

    [Scope('OnPrem')]
    procedure GetVATLedgerItemRealizeDate(VATLedgerLine: Record "VAT Ledger Line"): Date
    begin
        if VATLedgerLine.Prepayment and (VATLedgerLine."C/V Type" = VATLedgerLine."C/V Type"::Customer) and (VATLedgerLine."Document Type" = VATLedgerLine."Document Type"::Invoice) then
            exit(VATLedgerLine."Real. VAT Entry Date");
        exit(VATLedgerLine."Unreal. VAT Entry Date");
    end;

    [Scope('OnPrem')]
    procedure GetVATLedgerXMLFileName(VATLedgerType: Option; AddSheet: Boolean) Result: Text
    var
        CompanyInformation: Record "Company Information";
        VATLedger: Record "VAT Ledger";
    begin
        CompanyInformation.Get();
        Result := 'NO_NDS.';

        if VATLedgerType = VATLedger.Type::Sales then
            Result += Format(9)
        else
            Result += Format(8);

        if AddSheet then
            Result += Format(1);

        // Add "_AAAA_KKKK_" value, where AAAA - admin SONO, KKKK - recipient SONO
        Result += '_';
        if CompanyInformation."Admin. Tax Authority SONO" <> '' then
            Result += CompanyInformation."Admin. Tax Authority SONO"
        else
            Result += AAAATxt;
        Result += '_';
        if CompanyInformation."Recipient Tax Authority SONO" <> '' then
            Result += CompanyInformation."Recipient Tax Authority SONO"
        else
            Result += KKKKTxt;
        Result += '_';

        Result += Format(CompanyInformation."VAT Registration No."); // INN
        if StrLen(CompanyInformation."VAT Registration No.") = 10 then  // The company is an organization
            Result += Format(CompanyInformation."KPP Code");
        Result += '_' + Format(Today, 8, '<Year4><Month,2><Day,2>'); // Date format YYYYMMDD
        Result += '_0' + ConvertStr(GetVATLedgerFormatVersion(), '.', '_');
        Result += '_N'; // Iteration number; added to create unique file names
    end;

    procedure GetVATLedgerFormatVersion(): Text
    begin
        exit('5.08');
    end;

    [Scope('OnPrem')]
    procedure VATExemptLine(VATBusPostingGr: Code[20]; VATProdPostingGr: Code[20]): Boolean
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if VATPostingSetup.Get(VATBusPostingGr, VATProdPostingGr) then
            exit(VATPostingSetup."VAT Exempt");
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure FormatVATExemptLine(var VATPct: Text; var VATAmount: Text)
    begin
        VATPct := Text015;
        VATAmount := Text015;
    end;

    [Scope('OnPrem')]
    procedure FormatTextValue(TextValue: Text): Text
    begin
        if DelChr(TextValue, '=', ' ') = '' then
            exit('-');

        exit(TextValue);
    end;

    [Scope('OnPrem')]
    procedure FormatCompoundExpr(Expr1: Text; Expr2: Text): Text
    var
        ResultExpr: Text;
    begin
        ResultExpr := '';
        if Expr1 <> '' then
            ResultExpr := Expr1;
        if Expr2 <> '' then
            if ResultExpr <> '' then
                ResultExpr := ResultExpr + '; ' + Expr2
            else
                ResultExpr := Expr2;
        exit(ResultExpr);
    end;

    [Scope('OnPrem')]
    procedure IsVATAgentVendor(CVNo: Code[20]; CVType: Option Vendor,Customer): Boolean
    var
        Vendor: Record Vendor;
    begin
        if CVType = CVType::Vendor then
            if Vendor.Get(CVNo) then
                exit(Vendor."VAT Agent");
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure IsForeignCurrency(CurrencyCode: Code[10]): Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if CurrencyCode = '' then
            exit(false);
        GeneralLedgerSetup.Get();
        exit(GeneralLedgerSetup."LCY Code" <> CurrencyCode);
    end;

    [Scope('OnPrem')]
    procedure IsConventionalCurrency(CurrencyCode: Code[10]): Boolean
    var
        Currency: Record Currency;
    begin
        if Currency.Get(CurrencyCode) then
            exit(Currency.Conventional);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure IsCustomerPrepayment(VATLedgerLine: Record "VAT Ledger Line"): Boolean
    begin
        exit(VATLedgerLine.Prepayment and (VATLedgerLine."C/V Type" = VATLedgerLine."C/V Type"::Customer) and (VATLedgerLine."Document Type" = VATLedgerLine."Document Type"::Invoice));
    end;

    [Scope('OnPrem')]
    procedure HasRelationalCurrCode(CurrencyCode: Code[10]; DocDate: Date): Boolean
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        if Currency.Get(CurrencyCode) then begin
            CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
            CurrencyExchangeRate.SetRange("Starting Date", 0D, DocDate);
            if CurrencyExchangeRate.FindLast() then
                exit(CurrencyExchangeRate."Relational Currency Code" <> '');
        end;
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure GetEAEUItemTariffNo_SalesLine(SalesLine: Record "Sales Line"): Code[20]
    var
        Item: Record Item;
    begin
        if SalesLine.Type = SalesLine.Type::Item then
            if Item.Get(SalesLine."No.") then
                if IsEAEUItem_SalesLine(SalesLine) then
                    exit(Item."Tariff No.");
    end;

    [Scope('OnPrem')]
    procedure GetEAEUItemTariffNo_SalesInvLine(SalesInvoiceLine: Record "Sales Invoice Line"): Code[20]
    var
        Item: Record Item;
    begin
        if SalesInvoiceLine.Type = SalesInvoiceLine.Type::Item then
            if Item.Get(SalesInvoiceLine."No.") then
                if IsEAEUItem_SalesInvLine(SalesInvoiceLine) then
                    exit(Item."Tariff No.");
    end;

    [Scope('OnPrem')]
    procedure GetEAEUItemTariffNo_SalesCrMemoLine(SalesCrMemoLine: Record "Sales Cr.Memo Line"): Code[20]
    var
        Item: Record Item;
    begin
        if SalesCrMemoLine.Type = SalesCrMemoLine.Type::Item then
            if Item.Get(SalesCrMemoLine."No.") then
                if IsEAEUItem_SalesCrMemoLine(SalesCrMemoLine) then
                    exit(Item."Tariff No.");
    end;

    [Scope('OnPrem')]
    procedure IsEAEUItem_ValueEntry(ValueEntryDocumentType: Enum "Cost Entry Type"; DocumentNo: Code[20]; DocumentLineNo: Integer): Boolean
    var
        DummyValueEntry: Record "Value Entry";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        case ValueEntryDocumentType of
            DummyValueEntry."Document Type"::"Sales Invoice":
                if SalesInvoiceLine.Get(DocumentNo, DocumentLineNo) then
                    exit(IsEAEUItem_SalesInvLine(SalesInvoiceLine));
            DummyValueEntry."Document Type"::"Sales Credit Memo":
                if SalesCrMemoLine.Get(DocumentNo, DocumentLineNo) then
                    exit(GetEAEUItemTariffNo_SalesCrMemoLine(SalesCrMemoLine) <> '');
        end;
    end;

    local procedure IsEAEUItem_SalesLine(SalesLine: Record "Sales Line"): Boolean
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        exit(
          IsEAEUItem_SalesDocLine(
            SalesLine."Location Code", SalesHeader."Ship-to Code", SalesHeader."Sell-to Customer No."));
    end;

    local procedure IsEAEUItem_SalesInvLine(SalesInvoiceLine: Record "Sales Invoice Line"): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(SalesInvoiceLine."Document No.");
        exit(
          IsEAEUItem_SalesDocLine(
            SalesInvoiceLine."Location Code", SalesInvoiceHeader."Ship-to Code", SalesInvoiceHeader."Sell-to Customer No."));
    end;

    local procedure IsEAEUItem_SalesCrMemoLine(SalesCrMemoLine: Record "Sales Cr.Memo Line"): Boolean
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.Get(SalesCrMemoLine."Document No.");
        exit(
          IsEAEUItem_SalesDocLine(
            SalesCrMemoLine."Location Code", SalesCrMemoHeader."Ship-to Code", SalesCrMemoHeader."Sell-to Customer No."));
    end;

    local procedure IsEAEUItem_SalesDocLine(LineLocationCode: Code[10]; HeaderShipToCode: Code[10]; SellToCustomerNo: Code[20]): Boolean
    var
        Location: Record Location;
        CountryRegion: Record "Country/Region";
        ShipToAddress: Record "Ship-to Address";
        Customer: Record Customer;
    begin
        if LineLocationCode <> '' then
            if Location.Get(LineLocationCode) then
                if CountryRegion.Get(Location."Country/Region Code") then
                    exit(CountryRegion.IsEAEUCountry());

        if HeaderShipToCode <> '' then
            if ShipToAddress.Get(SellToCustomerNo, HeaderShipToCode) then
                if CountryRegion.Get(ShipToAddress."Country/Region Code") then
                    exit(CountryRegion.IsEAEUCountry());

        Customer.Get(SellToCustomerNo);
        if CountryRegion.Get(Customer."Country/Region Code") then
            exit(CountryRegion.IsEAEUCountry());

        exit(false);
    end;
}

