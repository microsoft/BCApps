// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.ElectronicFundsTransfer;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.IO;

codeunit 10095 "Export EFT (RB)"
{

    trigger OnRun()
    begin
    end;

    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        CompanyInformation: Record "Company Information";
        FileManagement: Codeunit "File Management";
        FileName: Text;
        FileDate: Date;
        DummyModifierValues: array[26] of Code[1];
        PaymentsThisAcct: Integer;
        CurrencyType: Code[10];
        AcctNo: Code[20];
        AcctName: Text[30];
        AcctLanguage: Option "E  English","F  French";
        RecipientAddress: Text[80];
        RecipientCity: Text[30];
        RecipientCountryCode: Text[30];
        RecipientCounty: Text[30];
        RecipientPostCode: Code[20];
        RecipientBankAcctNo: Text[30];
        RecipientTransitNo: Text[20];
        RecipientBankNo: Text[20];
        RecipientBankAcctCurrencyCode: Code[10];
        RecipientBankAcctCountryCode: Code[10];
        AlreadyExistsErr: Label 'The file already exists. Check the "Last E-Pay Export File Name" field in the bank account.';
        ReferErr: Label 'Either Account type or balance account type must refer to either a vendor or a customer for an electronic payment.';
        IsBlockedErr: Label 'Account type is blocked for processing.';
        PrivacyBlockedErr: Label 'Account type is blocked for privacy.';

    [Scope('OnPrem')]
    procedure StartExportFile(var TempEFTExportWorkset: Record "EFT Export Workset" temporary; BankAccountNo: Code[20]; DataExchEntryNo: Integer; var EFTValues: Codeunit "EFT Values")
    var
        ACHRBHeader: Record "ACH RB Header";
        GLSetup: Record "General Ledger Setup";
        DataExchColumnDef: Record "Data Exch. Column Def";
        ExportEFTACH: Codeunit "Export EFT (ACH)";
        i: Integer;
        FedID: Text[30];
        DateInteger: Integer;
    begin
        ExportEFTACH.BuildIDModifier(DummyModifierValues);

        CompanyInformation.Get();
        CompanyInformation.TestField("Federal ID No.");

        BankAccount.LockTable();
        BankAccount.Get(BankAccountNo);
        BankAccount.TestField("Export Format", BankAccount."Export Format"::CA);
        BankAccount.TestField("Transit No.");
        BankAccount.TestField("Last E-Pay Export File Name");
        BankAccount.TestField("Bank Acc. Posting Group");
        BankAccount.TestField(Blocked, false);
        BankAccount.TestField("Client No.");
        BankAccount.TestField("Client Name");

        if TempEFTExportWorkset."Bank Payment Type" =
           TempEFTExportWorkset."Bank Payment Type"::"Electronic Payment-IAT"
        then begin
            TempEFTExportWorkset.TestField("Transaction Code");
            TempEFTExportWorkset.TestField("Company Entry Description");
        end;

        FileName := FileManagement.ServerTempFileName('');

        if BankAccount."Last ACH File ID Modifier" = '' then
            BankAccount."Last ACH File ID Modifier" := '1'
        else begin
            i := 1;
            while (i < ArrayLen(DummyModifierValues)) and
                  (BankAccount."Last ACH File ID Modifier" <> DummyModifierValues[i])
            do
                i := i + 1;
            if i = ArrayLen(DummyModifierValues) then
                i := 1
            else
                i := i + 1;

            BankAccount."Last ACH File ID Modifier" := DummyModifierValues[i];
        end;
        if not EFTValues.IsSetFileCreationNumber() then
            BankAccount."Last E-Pay File Creation No." := BankAccount."Last E-Pay File Creation No." + 1;
        BankAccount.Modify();

        if Exists(FileName) then
            Error(AlreadyExistsErr);

        FileDate := Today;
        EFTValues.SetNoOfRec(1);
        EFTValues.SetNoOfCustInfoRec(0);
        EFTValues.SetTotalFileDebit(0);
        EFTValues.SetTotalFileCredit(0);
        EFTValues.SetTransactions(0);
        EFTValues.SetFileCreationNumber(BankAccount."Last E-Pay File Creation No.");
        FedID := CompanyInformation."Federal ID No.";

        if TempEFTExportWorkset."Currency Code" = '' then begin
            GLSetup.Get();
            CurrencyType := GLSetup."LCY Code";
        end else
            CurrencyType := TempEFTExportWorkset."Currency Code";

        ACHRBHeader.Get(DataExchEntryNo);
        ACHRBHeader."Record Count" := EFTValues.GetNoOfRec();
        ACHRBHeader."Record Type" := 'A';
        ACHRBHeader."Transaction Code" := 'HDR';
        ACHRBHeader."Client Number" := BankAccount."Client No.";
        ACHRBHeader."Client Name" := BankAccount."Client Name";
        ACHRBHeader."Federal ID No." := DelChr(FedID, '=', ' .,-');
        ACHRBHeader."File Creation Number" := BankAccount."Last E-Pay File Creation No.";
        ACHRBHeader."File Creation Date" := JulianDate(FileDate);
        ACHRBHeader.Validate("Settlement Date", TempEFTExportWorkset.UserSettleDate);
        // if can find the column definition, get the value of the Data Format and assign it to DateFormat variable
        FindDataExchColumnDefWithMapping(
            DataExchColumnDef, DataExchEntryNo, DATABASE::"ACH RB Header", ACHRBHeader.FieldNo("File Creation Date"));
        if DataExchColumnDef."Data Format" <> '' then begin
            Evaluate(DateInteger, Format(FileDate, DataExchColumnDef.Length, DataExchColumnDef."Data Format"));
            ACHRBHeader."File Creation Date" := DateInteger;
        end;

        ACHRBHeader."Currency Type" := CurrencyType;
        ACHRBHeader."Input Type" := '1';
        ACHRBHeader."Input Qualifier" := BankAccount."Input Qualifier";
        OnBeforeACHRBHeaderModify(ACHRBHeader, BankAccount);
        ACHRBHeader.Modify();
    end;

    [Scope('OnPrem')]
    procedure ExportElectronicPayment(var TempEFTExportWorkset: Record "EFT Export Workset" temporary; PaymentAmount: Decimal; SettleDate: Date; DataExchEntryNo: Integer; DataExchLineDefCode: Code[20]; var EFTValues: Codeunit "EFT Values"): Code[30]
    var
        DemandCredit: Boolean;
    begin
        // NOTE:  If PaymentAmount is Positive, then we are Receiving money.
        // If PaymentAmount is Negative, then we are Sending money.
        if PaymentAmount = 0 then
            exit('');
        DemandCredit := (PaymentAmount < 0);
        PaymentAmount := Abs(PaymentAmount);

        if EFTValues.GetParentBoolean() then
            if DemandCredit then
                EFTValues.SetTotalFileCredit(EFTValues.GetTotalFileCredit() + PaymentAmount)
            else
                EFTValues.SetTotalFileDebit(EFTValues.GetTotalFileDebit() + PaymentAmount);

        GetRecipientData(TempEFTExportWorkset);
        WriteRecord(TempEFTExportWorkset, PaymentAmount, SettleDate, DataExchEntryNo, DataExchLineDefCode,
          EFTValues.GetParentBoolean(), EFTValues);

        exit(GenerateFullTraceNoCode(EFTValues.GetTraceNo()));
    end;

    [Scope('OnPrem')]
    procedure EndExportFile(DataExchEntryNo: Integer; var EFTValues: Codeunit "EFT Values"): Boolean
    var
        ACHRBFooter: Record "ACH RB Footer";
    begin
        ACHRBFooter.Get(DataExchEntryNo);
        ACHRBFooter."Record Type" := 'Z';
        ACHRBFooter."Transaction Code" := 'TRL';
        ACHRBFooter."Client Number" := BankAccount."Client No.";
        EFTValues.SetNoOfRec(EFTValues.GetNoOfRec() + 1);
        ACHRBFooter."Record Count" := EFTValues.GetNoOfRec();
        ACHRBFooter."Credit Payment Transactions" := EFTValues.GetTransactions();
        ACHRBFooter."Total File Credit" := EFTValues.GetTotalFileCredit();
        ACHRBFooter."Zero Fill" := 0;
        ACHRBFooter."Number of Cust Info Records" := EFTValues.GetNoOfCustInfoRec();
        ACHRBFooter."File Creation Number" := EFTValues.GetFileCreationNumber();
        OnBeforeACHRBFooterModify(ACHRBFooter, BankAccount."No.");
        ACHRBFooter.Modify();

        exit(true);
    end;

    local procedure GenerateFullTraceNoCode(TraceNo: Integer): Code[30]
    var
        TraceCode: Text;
    begin
        TraceCode := '';
        TraceCode := Format(BankAccount."Last E-Pay File Creation No." + TraceNo);
        exit(TraceCode);
    end;

    local procedure GetRecipientData(var TempEFTExportWorkset: Record "EFT Export Workset" temporary)
    var
        AcctType: Text[1];
    begin
        if TempEFTExportWorkset."Account Type" = TempEFTExportWorkset."Account Type"::Vendor then begin
            AcctType := 'V';
            AcctNo := TempEFTExportWorkset."Account No.";
        end else
            if TempEFTExportWorkset."Account Type" = TempEFTExportWorkset."Account Type"::Customer then begin
                AcctType := 'C';
                AcctNo := TempEFTExportWorkset."Account No.";
            end else
                if TempEFTExportWorkset."Bal. Account Type" = TempEFTExportWorkset."Bal. Account Type"::Vendor then begin
                    AcctType := 'V';
                    AcctNo := TempEFTExportWorkset."Bal. Account No.";
                end else
                    if TempEFTExportWorkset."Bal. Account Type" = TempEFTExportWorkset."Bal. Account Type"::Customer then begin
                        AcctType := 'C';
                        AcctNo := TempEFTExportWorkset."Bal. Account No.";
                    end else
                        Error(ReferErr);

        if AcctType = 'V' then
            GetRecipientDataFromVendor(TempEFTExportWorkset)
        else
            if AcctType = 'C' then
                GetRecipientDataFromCustomer(TempEFTExportWorkset);
    end;

    local procedure GetRecipientDataFromVendor(var TempEFTExportWorkset: Record "EFT Export Workset" temporary)
    var
        VendorBankAccount: Record "Vendor Bank Account";
        EFTRecipientBankAccountMgt: Codeunit "EFT Recipient Bank Account Mgt";
    begin
        if AcctNo <> Vendor."No." then begin
            Vendor.Get(AcctNo);
            Vendor.TestField(Blocked, Vendor.Blocked::" ");
            Vendor.TestField("Privacy Blocked", false);
            PaymentsThisAcct := 0;
        end else
            PaymentsThisAcct := PaymentsThisAcct + 1;
        AcctName := CopyStr(Vendor.Name, 1, 30);
        AcctLanguage := Vendor."Bank Communication";
        RecipientAddress := CopyStr(Vendor.Address, 1, 35) + ' ' + CopyStr(Vendor."Address 2", 1, 35);
        RecipientCity := Vendor.City;
        RecipientCountryCode := GetCountryISOCode(Vendor."Country/Region Code");
        RecipientCounty := Vendor.County;
        RecipientPostCode := Vendor."Post Code";

        EFTRecipientBankAccountMgt.GetRecipientVendorBankAccount(VendorBankAccount, TempEFTExportWorkset, AcctNo);

        VendorBankAccount.TestField("Bank Account No.");
        RecipientBankNo := VendorBankAccount."Bank Branch No.";
        RecipientTransitNo := VendorBankAccount."Transit No.";
        RecipientBankAcctNo := VendorBankAccount."Bank Account No.";
        RecipientBankAcctCurrencyCode := VendorBankAccount."Currency Code";
        RecipientBankAcctCountryCode := GetCountryISOCode(VendorBankAccount."Country/Region Code");
    end;

    local procedure GetRecipientDataFromCustomer(var TempEFTExportWorkset: Record "EFT Export Workset" temporary)
    var
        CustomerBankAccount: Record "Customer Bank Account";
        EFTRecipientBankAccountMgt: Codeunit "EFT Recipient Bank Account Mgt";
    begin
        if AcctNo <> Customer."No." then begin
            Customer.Get(AcctNo);
            if Customer."Privacy Blocked" then
                Error(PrivacyBlockedErr);
            if Customer.Blocked in [Customer.Blocked::All] then
                Error(IsBlockedErr);

            PaymentsThisAcct := 0;
        end else
            PaymentsThisAcct := PaymentsThisAcct + 1;
        AcctName := CopyStr(Customer.Name, 1, 30);
        AcctLanguage := Customer."Bank Communication";
        RecipientAddress := CopyStr(Customer.Address, 1, 35) + ' ' + CopyStr(Customer."Address 2", 1, 35);
        RecipientCity := Customer.City;
        RecipientCountryCode := GetCountryISOCode(Customer."Country/Region Code");
        RecipientCounty := Customer.County;
        RecipientPostCode := Customer."Post Code";

        EFTRecipientBankAccountMgt.GetRecipientCustomerBankAccount(CustomerBankAccount, TempEFTExportWorkset, AcctNo);

        CustomerBankAccount.TestField("Bank Account No.");
        RecipientBankNo := CustomerBankAccount."Bank Branch No.";
        RecipientTransitNo := CustomerBankAccount."Transit No.";
        RecipientBankAcctNo := CustomerBankAccount."Bank Account No.";
        RecipientBankAcctCurrencyCode := CustomerBankAccount."Currency Code";
        RecipientBankAcctCountryCode := GetCountryISOCode(CustomerBankAccount."Country/Region Code");
    end;

    procedure JulianDate(NormalDate: Date): Integer
    var
        Year: Integer;
        Days: Integer;
    begin
        Year := Date2DMY(NormalDate, 3);
        Days := (NormalDate - DMY2Date(1, 1, Year)) + 1;
        exit((Year mod 100) * 1000 + Days);
    end;

    local procedure WriteRecord(var TempEFTExportWorkset: Record "EFT Export Workset" temporary; PaymentAmount: Decimal; SettleDate: Date; DataExchEntryNo: Integer; DataExchLineDefCode: Code[20]; IsParent: Boolean; var EFTValues: Codeunit "EFT Values")
    var
        ACHRBDetail: Record "ACH RB Detail";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DateInteger: Integer;
    begin
        if IsParent then
            EFTValues.SetTransactions(EFTValues.GetTransactions() + 1);
        EFTValues.SetNoOfRec(EFTValues.GetNoOfRec() + 1);
        EFTValues.SetTraceNo(EFTValues.GetNoOfRec());
        EFTValues.SetDataExchEntryNo(DataExchEntryNo);

        ACHRBDetail.Get(DataExchEntryNo, DataExchLineDefCode);
        ACHRBDetail."Record Count" := EFTValues.GetNoOfRec();
        ACHRBDetail."Transaction Code" := TempEFTExportWorkset."Transaction Code";
        ACHRBDetail."Client Number" := BankAccount."Client No.";
        ACHRBDetail."Customer/Vendor Number" := AcctNo;
        ACHRBDetail."Vendor/Customer Name" := AcctName;
        ACHRBDetail."Payment Number" := PaymentsThisAcct;
        ACHRBDetail."Document No." := TempEFTExportWorkset."Document No.";
        ACHRBDetail."External Document No." := TempEFTExportWorkset."External Document No.";
        ACHRBDetail."Applies-to Doc. No." := TempEFTExportWorkset."Applies-to Doc. No.";
        ACHRBDetail."Payment Reference" := TempEFTExportWorkset."Payment Reference";
        ACHRBDetail."File Creation Number" := EFTValues.GetFileCreationNumber();

        if RecipientBankAcctCountryCode = 'CA' then begin
            ACHRBDetail."Bank No." := RecipientBankNo;
            ACHRBDetail."Transit Routing No." := RecipientTransitNo;
        end else
            if RecipientBankAcctCountryCode = 'US' then
                ACHRBDetail."Transit Routing No." := RecipientTransitNo;

        ACHRBDetail."Recipient Bank No." := RecipientBankAcctNo;
        ACHRBDetail."Payment Amount" := PaymentAmount;
        ACHRBDetail."Payment Date" := JulianDate(SettleDate);
        // if can find the column definition, get the value of the Data Format and assign it to DateFormat variable
        FindDataExchColumnDefWithMapping(
            DataExchColumnDef, DataExchEntryNo, DATABASE::"ACH RB Detail", ACHRBDetail.FieldNo("Payment Date"));
        if DataExchColumnDef."Data Format" <> '' then begin
            Evaluate(DateInteger, Format(SettleDate, DataExchColumnDef.Length, DataExchColumnDef."Data Format"));
            ACHRBDetail."Payment Date" := DateInteger;
        end;

        ACHRBDetail."Language Code" := Format(AcctLanguage);
        ACHRBDetail."Client Name" := BankAccount."Client Name";

        if RecipientBankAcctCurrencyCode = '' then
            ACHRBDetail."Currency Code" := CurrencyType
        else
            ACHRBDetail."Currency Code" := RecipientBankAcctCurrencyCode;

        if RecipientCountryCode = 'CA' then
            ACHRBDetail.Country := 'CAN'
        else
            if RecipientCountryCode = 'US' then
                ACHRBDetail.Country := 'USA';

        if IsParent then
            EFTValues.SetNoOfCustInfoRec(EFTValues.GetNoOfCustInfoRec() + 1);
        ACHRBDetail.AD1NoOfRec := EFTValues.GetNoOfRec();
        ACHRBDetail."AD1Client No" := BankAccount."Client No.";
        ACHRBDetail."AD1Company Name" := CompanyInformation.Name;
        ACHRBDetail.AD1Address := CopyStr(CompanyInformation.Address, 1, 35) + ' ' +
          CopyStr(CompanyInformation."Address 2", 1, 35);
        ACHRBDetail."AD1City State" := CompanyInformation.City + '*' + CompanyInformation.County + '\';
        ACHRBDetail."AD1Region Code/Post Code" := GetCountryISOCode(CompanyInformation."Country/Region Code") + '*' +
          CompanyInformation."Post Code" + '\';

        if IsParent then
            EFTValues.SetNoOfCustInfoRec(EFTValues.GetNoOfCustInfoRec() + 1);
        ACHRBDetail.AD2NoOfRec := EFTValues.GetNoOfRec();
        ACHRBDetail."AD2Client No" := BankAccount."Client No.";
        ACHRBDetail."AD2Recipient Address" := RecipientAddress;
        ACHRBDetail."AD2Recipient City/County" := RecipientCity + '*' + RecipientCounty + '\';
        ACHRBDetail."AD2Region Code/Post Code" := RecipientCountryCode + '*' + RecipientPostCode + '\';
        ACHRBDetail."AD2Transaction Type Code" := Format(TempEFTExportWorkset."Transaction Type Code");
        ACHRBDetail."AD2Company Entry Description" := TempEFTExportWorkset."Company Entry Description";

        if (TempEFTExportWorkset."Payment Related Information 1" <> '') or (TempEFTExportWorkset."Payment Related Information 2" <> '') then begin
            ACHRBDetail."Client Number" := BankAccount."Client No.";
            ACHRBDetail.RRNoOfRec := EFTValues.GetNoOfRec();
            ACHRBDetail."RRClient No" := BankAccount."Client No.";
            ACHRBDetail."RRPayment Related Info1" := TempEFTExportWorkset."Payment Related Information 1";
            ACHRBDetail."RRPayment Related Info2" := TempEFTExportWorkset."Payment Related Information 2";
            OnBeforeACHRBDetailModify(ACHRBDetail, TempEFTExportWorkset, BankAccount."No.", SettleDate);
            ACHRBDetail.Modify();
            EFTValues.SetNoOfCustInfoRec(EFTValues.GetNoOfCustInfoRec() + 1);
        end else begin
            OnBeforeACHRBDetailModify(ACHRBDetail, TempEFTExportWorkset, BankAccount."No.", SettleDate);
            ACHRBDetail.Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure GetDateFormatString(DataExchEntryNo: Integer; FieldName: Text[250]): Text[100]
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        FindDataExchColumnDef(DataExchColumnDef, DataExchEntryNo, FieldName);
        exit(DataExchColumnDef."Data Format");
    end;

    local procedure GetCountryISOCode(CountryRegionCode: Code[10]): Code[2]
    var
        CountryRegion: Record "Country/Region";
    begin
        if CountryRegion.Get(CountryRegionCode) then
            exit(CountryRegion."ISO Code");
    end;

    [Scope('OnPrem')]
    procedure FindDataExchColumnDef(var DataExchColumnDef: Record "Data Exch. Column Def"; DataExchEntryNo: Integer; FieldName: Text[250])
    var
        DataExch: Record "Data Exch.";
    begin
        Clear(DataExchColumnDef);

        if not DataExch.Get(DataExchEntryNo) then
            exit;

        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExch."Data Exch. Def Code");
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", DataExch."Data Exch. Line Def Code");
        DataExchColumnDef.SetRange(Name, FieldName);
        if DataExchColumnDef.FindFirst() then;
    end;

    procedure FindDataExchColumnDefWithMapping(var DataExchColumnDef: Record "Data Exch. Column Def"; DataExchEntryNo: Integer; TableID: Integer; FieldNo: Integer)
    var
        DataExch: Record "Data Exch.";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        RecRef: RecordRef;
        FieldRefLocal: FieldRef;
    begin
        if not DataExch.Get(DataExchEntryNo) then
            exit;

        RecRef.Open(TableID);
        FieldRefLocal := RecRef.Field(FieldNo);

        FindDataExchColumnDef(DataExchColumnDef, DataExchEntryNo, FieldRefLocal.Name);

        if DataExchColumnDef."Column No." <> 0 then
            exit;

        DataExchFieldMapping.SetRange("Data Exch. Def Code", DataExch."Data Exch. Def Code");
        DataExchFieldMapping.SetRange("Data Exch. Line Def Code", DataExch."Data Exch. Line Def Code");
        DataExchFieldMapping.SetRange("Table ID", TableID);
        DataExchFieldMapping.SetRange("Field ID", FieldNo);

        if not DataExchFieldMapping.FindFirst() then
            exit;

        if DataExchColumnDef.Get(DataExch."Data Exch. Def Code", DataExch."Data Exch. Line Def Code", DataExchFieldMapping."Column No.") then;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeACHRBHeaderModify(var ACHRBHeader: Record "ACH RB Header"; BankAccount: Record "Bank Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeACHRBDetailModify(var ACHRBDetail: Record "ACH RB Detail"; var TempEFTExportWorkset: Record "EFT Export Workset" temporary; BankAccNo: Code[20]; SettleDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeACHRBFooterModify(var ACHRBFooter: Record "ACH RB Footer"; BankAccNo: Code[20])
    begin
    end;
}

