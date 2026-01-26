// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Environment;
using System.IO;
using System.Utilities;

report 2000002 "File International Payments"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/BankMgt/Payment/FileInternationalPayments.rdlc';
    Caption = 'File International Payments';
    Permissions = TableData "Cust. Ledger Entry" = rim,
                  TableData "Vendor Ledger Entry" = rim,
                  TableData "Gen. Journal Line" = rim;
    ProcessingOnly = false;
    UseRequestPage = true;

    dataset
    {
        dataitem("Payment Journal Line"; "Payment Journal Line")
        {
            DataItemTableView = sorting("Bank Account", "Beneficiary Bank Account No.", Status, "Account Type", "Account No.", "Currency Code", "Posting Date");

            trigger OnAfterGetRecord()
            var
                IbanTransfer: Boolean;
                NewGroupLoc: Boolean;
            begin
                // normal transaction
                case "Account Type" of
                    "Account Type"::Customer:
                        FillCustomerData("Payment Journal Line");
                    "Account Type"::Vendor:
                        FillVendorData("Payment Journal Line");
                end;

                // ISO-codering
                ISOCurCode := "ISO Currency Code";
                if Country.Get(ISOCountCode) and (Country."ISO Code" <> '') then
                    ISOCountCode := Country."ISO Code";

                ExecutionDate := "Posting Date";
                IbanTransfer := ("Beneficiary IBAN" <> '') and Country."IBAN Country/Region";
                if IbanTransfer then begin
                    IndConcBeneficAccountNoIBAN := '1';
                    BankAccNo := DelChr("Beneficiary IBAN");
                end else begin
                    IndConcBeneficAccountNoIBAN := ' ';
                    BankAccNo := "Beneficiary Bank Account No.";
                end;

                // overflow of message string (> 140 chars) is not tested
                if "Payment Message" = '' then
                    Reference := "External Document No."
                else
                    Reference := "Payment Message";

                if StrLen(References + ' ' + Reference) > 140 then
                    if EBSetup."Cut off Payment Message Texts" then
                        References := CopyStr(References, 1, 136) + ' ...'
                    else
                        WriteDataRecord();

                if References = '' then
                    References := Reference
                else
                    References := CopyStr(References + ' ' + Reference, 1, 140);

                Amt[1] := Amt[1] + Amount;

                NewGroupLoc := CheckNewGroup();
                if NewGroupLoc then
                    WriteDataRecord();
            end;

            trigger OnPreDataItem()
            var
                PmtJnlLineLoc: Record "Payment Journal Line";
            begin
                // Preliminary checks
                // bank
                PmtJnlLineLoc.CopyFilters("Payment Journal Line");
                PmtJnlLineLoc.FindFirst();
                GetBankAccount(PmtJnlLineLoc."Bank Account");

                if BankAcc."Currency Code" <> '' then begin
                    Currency.Get(BankAcc."Currency Code");
                    BankAccISOCurrCode := Currency."ISO Code";
                end;

                // This has only to be filled in if different from the Bank Account
                BankAccNoCosts := '';
                Clear(BankExecution);

                if ExecutionDate <> 0D then
                    ModifyAll("Posting Date", ExecutionDate);

                if ExecutionDate <> 0D then
                    SetRange("Posting Date", ExecutionDate);

                Clear(xFile);
                xFile.TextMode := true;
                xFile.WriteMode := true;
                FromFile := RBMgt.ServerTempFileName('txt');
                xFile.Create(FromFile);

                WriteHeaderRecord();
            end;
        }
        dataitem(Docket; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(BankAcc_BankBranchNo; BankAcc."Bank Branch No.")
            {
            }
            column(BankAcc_Name; BankAcc.Name)
            {
            }
            column(CompanyInfo_Name; CompanyInfo.Name)
            {
            }
            column(CompanyInfo_City; CompanyInfo.City)
            {
            }
            column(CompanyInfo_EnterpriseNo; CompanyInfo."Enterprise No.")
            {
            }
            column(InscriptionNo; InscriptionNo)
            {
            }
            column(BankAcc_BankAccNo; BankAcc."Bank Account No.")
            {
            }
            column(ExecutionDate; Format(ExecutionDate))
            {
            }
            column(FileName; FileName)
            {
            }
            column(PaymentNoRecordCounter; PaymentNo * 6 + RecordCounter)
            {
                DecimalPlaces = 0 : 0;
            }
            column(TotalAmount1; TotalAmount[1])
            {
            }
            column(PaymentNo; PaymentNo)
            {
                DecimalPlaces = 0 : 0;
            }
            column(RcptDateCaption; RcptDateCaptionLbl)
            {
            }
            column(EmptyStringCaption; EmptyStringCaptionLbl)
            {
            }
            column(CodeCaption; CodeCaptionLbl)
            {
            }
            column(NameFinInstitutionCaption; NameFinInstitutionCaptionLbl)
            {
            }
            column(ApplicationCodeCaption; ApplicationCodeCaptionLbl)
            {
            }
            column(V51Caption; V51CaptionLbl)
            {
            }
            column(OrderingCustNameCaption; OrderingCustNameCaptionLbl)
            {
            }
            column(OrderingCustCityCaption; OrderingCustCityCaptionLbl)
            {
            }
            column(OrderingCustIdNoCaption; OrderingCustIdNoCaptionLbl)
            {
            }
            column(InscriptionNoCaption; InscriptionNoCaptionLbl)
            {
            }
            column(DebitAccNoCaption; DebitAccNoCaptionLbl)
            {
            }
            column(ExecutionDateCaption; ExecutionDateCaptionLbl)
            {
            }
            column(FileNameCaption; FileNameCaptionLbl)
            {
            }
            column(NoOfRecordsCaption; NoOfRecordsCaptionLbl)
            {
            }
            column(TotalAmtsCaption; TotalAmtsCaptionLbl)
            {
            }
            column(PaymentNoCaption; PaymentNoCaptionLbl)
            {
            }
            column(OrderingCustSignatureCaption; OrderingCustSignatureCaptionLbl)
            {
            }
            column(AddresseeSignCaption; AddresseeSignCaptionLbl)
            {
            }
            column(SalariesCaption; SalariesCaptionLbl)
            {
            }
            column(NonSalariesCaption; NonSalariesCaptionLbl)
            {
            }
            column(PmtTypeSpecificationCaption; PmtTypeSpecificationCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                WriteTrailerRecord();
                xFile.Close();

                // basename of file for printing on 'borderel'
                FileName := ConvertStr(FileName, '\', '/');
                while StrPos(FileName, '/') > 0 do
                    FileName := CopyStr(FileName, StrPos(FileName, '/') + 1);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(JournalTemplateName; GenJnlLine."Journal Template Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Template Name';
                        NotBlank = true;
                        TableRelation = "Gen. Journal Template";
                        ToolTip = 'Specifies the name of the journal template that is used for the posting.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            GenJnlTemplate.SetRange(Type, GenJnlTemplate.Type::General);
                            GenJnlTemplate.Name := GenJnlLine."Journal Template Name";
                            if GenJnlTemplate.Find('=><') then;
                            if PAGE.RunModal(0, GenJnlTemplate) = ACTION::LookupOK then
                                GenJnlLine."Journal Template Name" := GenJnlTemplate.Name;
                        end;

                        trigger OnValidate()
                        begin
                            GenJnlLineJournalTemplateNameOnAfterValidate();
                        end;
                    }
                    field(JournalBatchName; GenJnlLine."Journal Batch Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Batch';
                        Lookup = true;
                        NotBlank = true;
                        ToolTip = 'Specifies the name of the general journal batch to which you want the journal lines to be transferred.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            GenJnlLine.TestField("Journal Template Name");
                            GenJnlTemplate.Get(GenJnlLine."Journal Template Name");
                            GenJnlBatch.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
                            GenJnlBatch.Name := GenJnlLine."Journal Batch Name";
                            if GenJnlBatch.Find('=><') then;
                            if PAGE.RunModal(0, GenJnlBatch) = ACTION::LookupOK then
                                GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
                        end;

                        trigger OnValidate()
                        begin
                            GenJnlLine.TestField("Journal Template Name");
                            GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
                            GenJnlBatch.TestField("No. Series");
                        end;
                    }
                    field(AutomaticPosting; AutomaticPosting)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post General Journal Lines';
                        ToolTip = 'Specifies if you want to transfer the postings in the general journal to the general ledger. You may want to leave this field blank for international payments, so that you can enter the exact exchange rate upon receiving the bank file.';
                    }
                    field(IncludeDimText; IncludeDimText)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Dimensions';
                        Editable = false;
                        Enabled = IncludeDimTextEnable;
                        ToolTip = 'Specifies the dimensions that you want to include in the report. The option is only available if the Summarize Gen. Jnl. Lines field in the Electronic Banking Setup window is selected.';

                        trigger OnAssistEdit()
                        var
                            DimSelectionBuf: Record "Dimension Selection Buffer";
                        begin
                            DimSelectionBuf.SetDimSelectionMultiple(3, REPORT::"File International Payments", IncludeDimText);
                        end;
                    }
                    field(ExecutionDate; ExecutionDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Execution Date';
                        ToolTip = 'Specifies the desired execution date if you want an execution date that is different than the posting date on the payment journal lines. The date you enter here will overwrite the posting date on the selected journal lines.';
                    }
                    field(InscriptionNo; InscriptionNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inscription No.';
                        ToolTip = 'Specifies the inscription number that appears on the intra-community declaration disk. The number is included in the file and printed on the accompanying document.';
                    }
                    field(FileName; FileName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'File Name';
                        ToolTip = 'Specifies the name of the domiciliation file that you want to submit.';
                        Visible = false;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            IncludeDimTextEnable := true;
        end;

        trigger OnOpenPage()
        var
            DimSelectionBuf: Record "Dimension Selection Buffer";
        begin
            IncludeDimTextEnable := EBSetup."Summarize Gen. Jnl. Lines";
            IncludeDimText := DimSelectionBuf.GetDimSelectionText(3, REPORT::"File International Payments", '');
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        ClearAll();
        EBSetup.Get();
    end;

    trigger OnPostReport()
    var
        PaymentJournalPost: Report "Payment Journal Post";
        BalancingPostingDate: Date;
    begin
        Download(FromFile, '', '', AllFilesDescriptionTxt, FullFileName);

        // The BalancingPostingDate should be the same as in the Export Header
        if ExecutionDate <> 0D then
            BalancingPostingDate := ExecutionDate
        else
            BalancingPostingDate := Today;
        PaymentJournalPost.SetParameters(GenJnlLine, AutomaticPosting,
          REPORT::"File International Payments", BalancingPostingDate);
        PaymentJournalPost.SetTableView("Payment Journal Line");
        PaymentJournalPost.RunModal();
    end;

    trigger OnPreReport()
    begin
        EnterpriseNo := '';
        CompanyInfo.Get();
        if CompanyInfo."Enterprise No." = '' then
            EnterpriseNo := '00000000000'
        else begin
            if not EnterpriseNoCheck.MOD97Check(CompanyInfo."Enterprise No.") then
                Error(Text000);
            EnterpriseNo := '0' + PaymJnlManagement.ConvertToDigit(CompanyInfo."Enterprise No.", MaxStrLen(EnterpriseNo));
        end;

        Client[1] := CopyStr(CompanyInfo.Name, 1, MaxStrLen(Client[1]));
        Client[2] := CopyStr(CompanyInfo.Address, 1, MaxStrLen(Client[2]));
        Client[3] := CopyStr(CompanyInfo."Address 2", 1, MaxStrLen(Client[3]));
        Client[4] := CopyStr(CompanyInfo."Post Code" + ' ' + CompanyInfo.City, 1, MaxStrLen(Client[4]));

        if not (ClientTypeManagement.GetCurrentClientType() in [CLIENTTYPE::Desktop, CLIENTTYPE::Windows]) then
            FullFileName := RBMgt.GetFileName(FileName)
        else begin
            if FileName = '' then
                Error(Text006);

            if Exists(FileName) then
                if not Confirm(Text018, false, FileName) then
                    Error(Text019, FileName);

            FullFileName := FileName;
        end;

        if FullFileName = '' then
            FullFileName := InternationalPaymentsFileNameTxt;

        for RecordCounter := 1 to ArrayLen(DataRecord) do
            DataRecord[RecordCounter] := (CopyStr('111111100110', RecordCounter, 1) = '1');
        RecordCounter := 0;
    end;

    var
        Text000: Label 'Enterprise number in the Company Information table is not valid.';
        Text006: Label 'You must enter a file name.';
        Text010: Label 'Journal %1 is not a general journal.';
        Text016: Label 'The combination of invoices and credit memos for %1 %2 has caused an attempt to write a negative amount to the payment file. The format of the file does not allow this.', Comment = 'Parameter 1 - account type (,Customer,Vendor), 2 - account number.';
        CompanyInfo: Record "Company Information";
        EBSetup: Record "Electronic Banking Setup";
        Cust: Record Customer;
        Vend: Record Vendor;
        BankAcc: Record "Bank Account";
        Country: Record "Country/Region";
        CustBankAcc: Record "Customer Bank Account";
        VendBankAcc: Record "Vendor Bank Account";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Currency: Record Currency;
        RBMgt: Codeunit "File Management";
        PaymJnlManagement: Codeunit PmtJrnlManagement;
        EnterpriseNoCheck: Codeunit VATLogicalTests;
        ClientTypeManagement: Codeunit "Client Type Management";
        xFile: File;
        ExecutionDate: Date;
        ISOCurCode: Code[10];
        ISOCountCode: Code[10];
        InscriptionNo: Code[10];
        BankAccISOCurrCode: Code[3];
        EnterpriseNo: Text[11];
        BankAccNo: Text[34];
        IndConcBeneficAccountNoIBAN: Text[1];
        IndConcBeneficAccountNoBIC: Text[1];
        BankAccNoCosts: Text[30];
        References: Text[250];
        Reference: Text[250];
        FileName: Text;
        Client: array[4] of Text[50];
        Remittee: array[4] of Text[50];
        BankRemittee: array[4] of Text[50];
        BankExecution: array[4] of Text[70];
        IncludeDimText: Text[250];
        FromFile: Text[250];
        FullFileName: Text;
        RecordCounter: Integer;
        PaymentNo: Decimal;
        Amt: array[2] of Decimal;
        TotalAmount: array[2] of Decimal;
        AutomaticPosting: Boolean;
        DataRecord: array[12] of Boolean;
        Text018: Label 'The %1 already exists.\\Do you want to replace the existing file?';
        Text019: Label 'The file %1 already exists.';
        IncludeDimTextEnable: Boolean;
        RcptDateCaptionLbl: Label 'Receipt Date';
        EmptyStringCaptionLbl: Label '......  /  ......  /  ......';
        CodeCaptionLbl: Label 'Code';
        NameFinInstitutionCaptionLbl: Label 'Name Financial Institution';
        ApplicationCodeCaptionLbl: Label 'Application Code';
        V51CaptionLbl: Label '51';
        OrderingCustNameCaptionLbl: Label 'Ordering Customer''s Name';
        OrderingCustCityCaptionLbl: Label 'Ordering Customer''s City';
        OrderingCustIdNoCaptionLbl: Label 'Ordering Customer''s Identification No.';
        InscriptionNoCaptionLbl: Label 'Sequence No.';
        DebitAccNoCaptionLbl: Label 'Debit Account No.';
        ExecutionDateCaptionLbl: Label 'Execution Date';
        FileNameCaptionLbl: Label 'File Name';
        NoOfRecordsCaptionLbl: Label 'No. of Records';
        TotalAmtsCaptionLbl: Label 'Total Amounts';
        PaymentNoCaptionLbl: Label 'No. of Payments';
        OrderingCustSignatureCaptionLbl: Label 'Ordering Customer''s Signature(s)';
        AddresseeSignCaptionLbl: Label 'Addressee''s Signature(s)';
        SalariesCaptionLbl: Label 'Salaries (*)';
        NonSalariesCaptionLbl: Label 'Non-Salaries';
        PmtTypeSpecificationCaptionLbl: Label '(*) Please specify payment type ("Salaries" or "Non-Salaries") in the upper right corner of the issue voucher.';
        AllFilesDescriptionTxt: Label 'All Files (*.*)|*.*', Comment = '{Split=r''\|''}{Locked=s''1''}';
        InternationalPaymentsFileNameTxt: Label 'InternationalPayments.txt';

    [Scope('OnPrem')]
    procedure FillCustomerData(PaymentJnlLine: Record "Payment Journal Line")
    begin
        Cust.Get(PaymentJnlLine."Account No.");

        if Cust."Country/Region Code" <> '' then
            ISOCountCode := Cust."Country/Region Code"
        else
            ISOCountCode := 'BE';
        Remittee[1] := CopyStr(Cust.Name, 1, MaxStrLen(Remittee[1]));
        Remittee[2] := CopyStr(Cust.Address, 1, MaxStrLen(Remittee[2]));
        Remittee[3] := CopyStr(Cust."Address 2", 1, MaxStrLen(Remittee[3]));
        Remittee[4] := CopyStr(Cust."Post Code" + ' ' + Cust.City + ' ' + Cust."Country/Region Code", 1, MaxStrLen(Remittee[4]));
        // bank
        Clear(BankRemittee);
        CustBankAcc.Get(PaymentJnlLine."Account No.", PaymentJnlLine."Beneficiary Bank Account");
        if PaymentJnlLine."SWIFT Code" <> '' then begin
            BankRemittee[1] := PaymentJnlLine."SWIFT Code";
            IndConcBeneficAccountNoBIC := '1';
        end else begin
            FillCustBankRemittee(CustBankAcc);
            IndConcBeneficAccountNoBIC := ' ';
        end;

        OnAfterFillCustData(PaymentJnlLine, BankRemittee, IndConcBeneficAccountNoBIC);
    end;

    [Scope('OnPrem')]
    procedure FillVendorData(PaymentJnlLine: Record "Payment Journal Line")
    begin
        Vend.Get(PaymentJnlLine."Account No.");

        if Vend."Country/Region Code" <> '' then
            ISOCountCode := Vend."Country/Region Code"
        else
            ISOCountCode := 'BE';
        Remittee[1] := CopyStr(Vend.Name, 1, MaxStrLen(Remittee[1]));
        Remittee[2] := CopyStr(Vend.Address, 1, MaxStrLen(Remittee[2]));
        Remittee[3] := CopyStr(Vend."Address 2", 1, MaxStrLen(Remittee[3]));
        Remittee[4] := CopyStr(Vend."Post Code" + ' ' + Vend.City + ' ' + Vend."Country/Region Code", 1, MaxStrLen(Remittee[4]));
        // bank account data
        Clear(BankRemittee);
        VendBankAcc.Get(PaymentJnlLine."Account No.", PaymentJnlLine."Beneficiary Bank Account");
        if PaymentJnlLine."SWIFT Code" <> '' then begin
            BankRemittee[1] := PaymentJnlLine."SWIFT Code";
            IndConcBeneficAccountNoBIC := '1';
        end else begin
            FillVendBankRemittee(VendBankAcc);
            IndConcBeneficAccountNoBIC := ' ';
        end;

        OnAfterFillVendData(PaymentJnlLine, BankRemittee, IndConcBeneficAccountNoBIC);
    end;

    local procedure FillCustBankRemittee(CustBankAcc: Record "Customer Bank Account")
    begin
        FillBankRemittee(CustBankAcc.Name, CustBankAcc.Address, CustBankAcc."Address 2", CustBankAcc.City);
    end;

    local procedure FillVendBankRemittee(VendBankAcc: Record "Vendor Bank Account")
    begin
        FillBankRemittee(VendBankAcc.Name, VendBankAcc.Address, VendBankAcc."Address 2", VendBankAcc.City);
    end;

    local procedure FillBankRemittee(Name: Text[100]; Address: Text[100]; Address2: Text[50]; City: Text[30])
    begin
        BankRemittee[1] := CopyStr(Name, 1, MaxStrLen(BankRemittee[1]));
        BankRemittee[2] := CopyStr(Address, 1, MaxStrLen(BankRemittee[2]));
        BankRemittee[3] := CopyStr(Address2, 1, MaxStrLen(BankRemittee[3]));
        BankRemittee[4] := CopyStr(City, 1, MaxStrLen(BankRemittee[4]));
    end;

    [Scope('OnPrem')]
    procedure WriteHeaderRecord()
    begin
        xFile.Write(
            '0' +// header record
            Format(Today, 6, '<day,2><month,2><year,2>') + // creation data of carrier
            Format('', 12) +
            Format(BankAcc."Bank Branch No.", 3) +
            '51' +
            Format(InscriptionNo, 10) +
            Format(EnterpriseNo, 11) +
            Format(EnterpriseNo, 11) +
            ' ' +
            '3' +
            Format('', 12) +
            '1' +
            Format('', 4) +
            '1' +
            Format('', 52));
    end;

    [Scope('OnPrem')]
    procedure WriteDataRecord()
    begin
        if Amt[1] <= 0 then
            Error(Text016, "Payment Journal Line"."Account Type", "Payment Journal Line"."Account No.");

        // number of payment records
        PaymentNo := PaymentNo + 1;

        DataRecord[8] := (StrLen(References) > 35);
        // Subdivision 01 Mandatory
        xFile.Write(
            '1' +
            PaymJnlManagement.DecimalNumeralZeroFormat(PaymentNo, 4) +
            '01' +
            Format(ExecutionDate, 6, '<day,2><month,2><year,2>') +
            Format('', 16) +
            Format(ISOCurCode, 3) +
            Format('', 1) +
            'C' +
            PaymJnlManagement.DecimalNumeralZeroFormat(Amt[1] * 100, 15) +
            Format('', 1) +
            Format(BankAccISOCurrCode, 9) +
            Format(PaymJnlManagement.ConvertToDigit(BankAcc."Bank Account No.", 12), 12) +
            Format('', 22) +
            Format('', 1) +
            Format('', 34));
        // Subdivision 02
        if DataRecord[2] then begin
            RecordCounter := RecordCounter + 1;
            xFile.Write(
              '1' +
              PaymJnlManagement.DecimalNumeralZeroFormat(PaymentNo, 4) +
              '02' +
              Format(Client[1], 35) +
              Format(Client[2], 35) +
              Format(Client[3], 35) +
              Format('', 16));
        end;
        // Subdivision 03
        if DataRecord[3] then begin
            RecordCounter := RecordCounter + 1;
            xFile.Write(
              '1' +
              PaymJnlManagement.DecimalNumeralZeroFormat(PaymentNo, 4) +
              '03' +
              Format(Client[4], 35) +
              Format('', 10) +
              Format(BankExecution[1], 35) +
              Format(BankExecution[2], 35) +
              Format('', 6));
        end else
            Clear(BankExecution);
        // Subdivision 04 Mandatory
        xFile.Write(
          '1' +
          PaymJnlManagement.DecimalNumeralZeroFormat(PaymentNo, 4) +
          '04' +
          Format('', 80) +
          Format(BankRemittee[1], 35) +
          Format(IndConcBeneficAccountNoBIC, 1) +
          Format('', 5));
        // Subdivision 05
        xFile.Write(
          '1' +
          PaymJnlManagement.DecimalNumeralZeroFormat(PaymentNo, 4) +
          '05' +
          Format(BankRemittee[2], 35) +
          Format(BankRemittee[3], 35) +
          Format(BankRemittee[4], 35) +
          Format('', 10) +
          Format('', 6));
        // Subdivision 06 Mandatory
        xFile.Write(
          '1' +
          PaymJnlManagement.DecimalNumeralZeroFormat(PaymentNo, 4) +
          '06' +
          Format(BankAccNo, 34) +
          Format(Remittee[1], 35) +
          Format(Remittee[2], 35) +
          Format(IndConcBeneficAccountNoIBAN) +
          // Indication concerning the beneficiary's account number
          Format("Payment Journal Line"."Bank ISO Country/Region Code", 2) +
          Format('', 14));
        // Subdivision 07
        xFile.Write(
          '1' +
          PaymJnlManagement.DecimalNumeralZeroFormat(PaymentNo, 4) +
          '07' +
          Format(Remittee[3], 35) +
          Format(Remittee[4], 35) +
          Format('', 10) +
          Format(CopyStr(References, 1, 35), 35) +
          Format('', 6));
        // Subdivision 08
        if DataRecord[8] then begin
            RecordCounter := RecordCounter + 1;
            xFile.Write(
              '1' +
              PaymJnlManagement.DecimalNumeralZeroFormat(PaymentNo, 4) +
              '08' +
              Format(CopyStr(References, 36), 105) +
              Format('', 16));
        end;
        // Subdivision 09
        if DataRecord[9] then begin
            RecordCounter := RecordCounter + 1;
            xFile.Write(
              '1' +
              PaymJnlManagement.DecimalNumeralZeroFormat(PaymentNo, 4) +
              '09' +
              Format('', 70) +
              Format('', 35) +
              Format('', 16));
        end;
        // Subdivision 10 Mandatory
        xFile.Write(
          '1' +
          PaymJnlManagement.DecimalNumeralZeroFormat(PaymentNo, 4) +
          '10' +
          Format('', 35) +
          Format("Payment Journal Line"."Code Payment Method", 3, '<text>') +
          Format("Payment Journal Line"."Code Expenses", 3, '<text>') +
          Format('', 1) +
          Format('', 3) +
          Format('', 6) +
          Format(BankAccNoCosts, 12) +
          ' ' +
          Format(ISOCountCode, 2) +
          Format('', 55));

        // totals for balancing amount in LCY
        TotalAmount[1] := TotalAmount[1] + Amt[1];

        Clear(Amt);
        References := '';
    end;

    [Scope('OnPrem')]
    procedure WriteTrailerRecord()
    begin
        xFile.Write(
            '9' +
            PaymJnlManagement.DecimalNumeralZeroFormat(PaymentNo * 6 + RecordCounter, 6) +
            // *6 -> always six subdep.
            PaymJnlManagement.DecimalNumeralZeroFormat(PaymentNo, 6) +
            PaymJnlManagement.DecimalNumeralZeroFormat(TotalAmount[1] * 100, 15) +
            Format('', 100));
    end;

    [Scope('OnPrem')]
    procedure GetBankAccount(BankAccCode: Code[20])
    begin
        if BankAcc."No." <> BankAccCode then
            if not BankAcc.Get(BankAccCode) then
                BankAcc.Init();
    end;

    [Scope('OnPrem')]
    procedure CheckNewGroup(): Boolean
    var
        PmtJnlLineLoc: Record "Payment Journal Line";
        NewGroupLoc: Boolean;
    begin
        NewGroupLoc := false;
        PmtJnlLineLoc.Copy("Payment Journal Line");
        if PmtJnlLineLoc.Next() = 1 then begin
            if (PmtJnlLineLoc."Account No." <> "Payment Journal Line"."Account No.") or
               (PmtJnlLineLoc."Currency Code" <> "Payment Journal Line"."Currency Code") or
               (PmtJnlLineLoc."Posting Date" <> "Payment Journal Line"."Posting Date")
            then
                NewGroupLoc := true;
        end else
            NewGroupLoc := true;
        exit(NewGroupLoc);
    end;

    local procedure GenJnlLineJournalTemplateNameOnAfterValidate()
    begin
        GenJnlTemplate.Get(GenJnlLine."Journal Template Name");
        if GenJnlTemplate.Type <> GenJnlTemplate.Type::General then
            Error(Text010, GenJnlTemplate.Name);
    end;

    internal procedure SetFileName(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillCustData(var PaymentJournalLine: Record "Payment Journal Line"; var BankRemittee: array[4] of Text[50]; var IndConcBeneficAccountNoBIC: Text[1])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillVendData(var PaymentJournalLine: Record "Payment Journal Line"; var BankRemittee: array[4] of Text[50]; var IndConcBeneficAccountNoBIC: Text[1])
    begin
    end;
}

