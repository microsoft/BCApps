// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.NoSeries;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Environment;
using System.IO;
using System.Utilities;

report 2000021 "File Domiciliations"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/BankMgt/Payment/FileDomiciliations.rdlc';
    Caption = 'File Domiciliations';
    Permissions = TableData "Cust. Ledger Entry" = rim,
                  TableData "Gen. Journal Line" = rim;
    ProcessingOnly = false;
    UseRequestPage = true;

    dataset
    {
        dataitem("Domiciliation Journal Line"; "Domiciliation Journal Line")
        {
            DataItemTableView = sorting("Bank Account No.", "Customer No.");
            RequestFilterFields = "Journal Template Name", "Journal Batch Name", "Bank Account No.", "Posting Date";

            trigger OnAfterGetRecord()
            begin
                if "Customer No." <> '' then
                    FillCustomerData("Domiciliation Journal Line");

                // OGM per line
                if "Applies-to Doc. Type" in
                   ["Applies-to Doc. Type"::Invoice, "Applies-to Doc. Type"::"Finance Charge Memo",
                    "Applies-to Doc. Type"::Reminder, "Applies-to Doc. Type"::Refund]
                then begin
                    Amt := -Amount;
                    TypeCode := 0;
                end else
                    if "Applies-to Doc. Type" in ["Applies-to Doc. Type"::Payment, "Applies-to Doc. Type"::"Credit Memo"] then begin
                        Amt := Amount;
                        TypeCode := 1;
                    end else
                        CurrReport.Skip();
                CurrencyCode := "Currency Code";
                WriteDataRecord();
            end;

            trigger OnPreDataItem()
            begin
                // additional selections
                SetRange(Status, Status::Marked);

                if GetRangeMin("Bank Account No.") <> GetRangeMax("Bank Account No.") then
                    exit;
                BankNo := GetRangeMin("Bank Account No.");
                // check on bankaccount
                BankAcc.Get(BankNo);
                if not PaymJnlManagement.Mod97Test(BankAcc."Bank Account No.") then
                    Error(Text007, BankAcc.Name);
                // test if lines with empt bank exist
                DomJnlLine.Reset();
                DomJnlLine.CopyFilters("Domiciliation Journal Line");
                DomJnlLine.SetRange(Status, DomJnlLine.Status::" ");
                DomJnlLine.SetRange("Bank Account No.", '');
                if DomJnlLine.Count > 0 then
                    if Confirm(Text008, true) then
                        if DomJnlLine.FindSet() then
                            repeat
                                DomJnlLine.Validate("Bank Account No.", BankNo);
                                DomJnlLine.Modify();
                            until DomJnlLine.Next() = 0;

                // test before filter on OGM
                if Count = 0 then
                    Error(Text009);

                // execution date replaces posting date
                if PivotDate <> 0D then begin
                    ModifyAll("Posting Date", PivotDate);
                    SetRange("Posting Date", PivotDate)
                end else begin
                    DomJnlLine.Reset();
                    DomJnlLine.CopyFilters("Domiciliation Journal Line");
                    DomJnlLine.FindFirst();
                    if DomJnlLine.Count <> "Domiciliation Journal Line".Count then
                        Error(Text010);
                end;

                Clear(xFile);
                xFile.TextMode := true;
                xFile.WriteMode := true;
                FromFile := RBMgt.ServerTempFileName('txt');
                xFile.Create(FromFile);
                if GetFilter("ISO Currency Code") = Text011 then begin
                    VersionCode := '5';
                    AmtFactor := 100
                end else begin
                    VersionCode := '2';
                    AmtFactor := 1
                end;
                WriteHeaderRecord();
            end;
        }
        dataitem(Docket; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(BankAccBankBranchNo; BankAcc."Bank Branch No.")
            {
            }
            column(BankAccName; BankAcc.Name)
            {
            }
            column(CompanyAddress1; CompanyAddress[1])
            {
            }
            column(CompanyAddress4; CompanyAddress[4])
            {
            }
            column(CompanyInfoEnterpriseNo; CompanyInfo."Enterprise No.")
            {
            }
            column(InscriptionNo; InscriptionNo)
            {
            }
            column(BankAccBankAccountNo; BankAcc."Bank Account No.")
            {
            }
            column(PivotDate; PivotDate)
            {
            }
            column(FileName; FileName)
            {
            }
            column(RecordCounter1; RecordCounter[1])
            {
            }
            column(TotalAmount1; TotalAmount[1])
            {
                AutoFormatExpression = CurrencyCode;
                AutoFormatType = 1;
            }
            column(TotalDomNoDecimal1; TotalDomNoDecimal[1])
            {
                DecimalPlaces = 0 : 0;
            }
            column(CompanyAddress2; CompanyAddress[2])
            {
            }
            column(CompanyAddress3; CompanyAddress[3])
            {
            }
            column(TotalDomNoDecimal2; TotalDomNoDecimal[2])
            {
                DecimalPlaces = 0 : 0;
            }
            column(TotalAmount2; TotalAmount[2])
            {
                AutoFormatExpression = CurrencyCode;
                AutoFormatType = 1;
            }
            column(RecordCounter2; RecordCounter[2])
            {
            }
            column(V0; '0')
            {
            }
            column(V1; '1')
            {
            }
            column(RecordCounter1RecordCounter2; RecordCounter[1] + RecordCounter[2])
            {
            }
            column(TotalAmount1TotalAmount2; TotalAmount[1] - TotalAmount[2])
            {
                AutoFormatExpression = CurrencyCode;
                AutoFormatType = 1;
            }
            column(ReceiptDateCaption; ReceiptDateCaptionLbl)
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
            column(V02Caption; V02CaptionLbl)
            {
            }
            column(CompanyAddress1Caption; CreditorNameCaptionLbl)
            {
            }
            column(CompanyAddress2Caption; CreditorAddressCaptionLbl)
            {
            }
            column(CreditorIdentificationNoCaption; CreditorIdentificationNoCaptionLbl)
            {
            }
            column(SequenceNoCaption; SequenceNoCaptionLbl)
            {
            }
            column(CreditAccountNoCaption; CreditAccountNoCaptionLbl)
            {
            }
            column(PivotDateCaption; PivotDateCaptionLbl)
            {
            }
            column(FileNameCaption; FileNameCaptionLbl)
            {
            }
            column(NoOfRecordsCaption; NoOfRecordsCaptionLbl)
            {
            }
            column(TotalAmountCaption; TotalAmountCaptionLbl)
            {
            }
            column(TotalDomNoCaption; TotalDomNoCaptionLbl)
            {
            }
            column(OrderingCustomersSignaturesCaption; OrderingCustomerSignatureCaptionLbl)
            {
            }
            column(SignatureFinancialInstitutionCaption; SignatureFinancialInstitutionCaptionLbl)
            {
            }
            column(IssueVoucherForDOMCaption; IssueVoucherForDOMCaptionLbl)
            {
            }
            column(TypeCodeCaption; TypeCodeCaptionLbl)
            {
            }
            column(ForIssueCaption; ForIssueCaptionLbl)
            {
            }
            column(ForReceiptCaption; ForReceiptCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                WriteTrailerRecord();
                xFile.Close();
                FormatAddress.Company(CompanyAddress, CompanyInfo);

                // Base name of file for printing on 'borderel'
                FileName := ConvertStr(FileName, '\', '/');
                while StrPos(FileName, '/') > 0 do
                    FileName := CopyStr(FileName, StrPos(FileName, '/') + 1);
            end;
        }
        dataitem(Posting; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnPreDataItem()
            var
                DomicilJnlLine2: Record "Domiciliation Journal Line";
            begin
                GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
                GenJnlLine.Reset();
                GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
                GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
                LastGenJnlLine.Copy(GenJnlLine);
                if LastGenJnlLine.FindLast() then;

                DomJnlLine.Copy("Domiciliation Journal Line");
                DomJnlLine.SetCurrentKey("Customer No.", "Applies-to Doc. Type", "Applies-to Doc. No.");
                DomJnlLine.SetRange(Status, DomJnlLine.Status::Processed);
                if DomJnlLine.FindSet() then begin
                    DocumentNo := NoSeriesBatch.GetNextNo(GenJnlBatch."No. Series", DomJnlLine."Posting Date");
                    repeat
                        SetGenJnlLine(DomJnlLine);
                        DomJnlLine.Status := DomJnlLine.Status::Posted;
                        DomJnlLine.Modify(true)
                    until DomJnlLine.Next() = 0
                end;
                SetGenJnlLine(TempDomJnlLine);

                DomJnlBatch.Get("Domiciliation Journal Line"."Journal Template Name", "Domiciliation Journal Line"."Journal Batch Name");
                DomJnlBatchName := IncStr(DomJnlBatch.Name);
                if DomJnlBatchName <> '' then begin
                    DomJnlBatch.Status := DomJnlBatch.Status::Processed;

                    DomJnlBatch.Modify(true);
                    DomJnlBatch.Status := DomJnlBatch.Status::" ";
                    DomJnlBatch.Name := DomJnlBatchName;
                    if DomJnlBatch.Insert(true) then;
                end;

                if DomJnlBatchName <> '' then begin
                    DomJnlLine.Reset();
                    DomJnlLine.SetRange("Journal Template Name", "Domiciliation Journal Line"."Journal Template Name");
                    DomJnlLine.SetRange("Journal Batch Name", DomJnlBatchName);
                    if DomJnlLine.FindLast() then
                        LineNo := DomJnlLine."Line No."
                    else
                        LineNo := 0;

                    // rename
                    DomJnlLine.Reset();
                    DomJnlLine.SetRange("Journal Template Name", "Domiciliation Journal Line"."Journal Template Name");
                    DomJnlLine.SetRange("Journal Batch Name", "Domiciliation Journal Line"."Journal Batch Name");
                    DomJnlLine.SetRange(Status, DomJnlLine.Status::" ", DomJnlLine.Status::Marked);
                    if DomJnlLine.FindSet() then
                        repeat
                            LineNo := LineNo + 10000;
                            DomicilJnlLine2 := DomJnlLine;
                            DomicilJnlLine2.Find();
                            DomicilJnlLine2.Rename(DomJnlLine."Journal Template Name", DomJnlBatchName, LineNo);
                        until DomJnlLine.Next() = 0;
                end;

                // post
                if AutomaticPosting then
                    CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post", GenJnlLine);
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
                    field(Var1; GenJnlLine."Journal Template Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Template Name';
                        TableRelation = "Gen. Journal Template";
                        ToolTip = 'Specifies the name of the journal template that is used for the posting.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            GenJnlTemplate.SetRange(Type, GenJnlTemplate.Type::General);
                            if PAGE.RunModal(0, GenJnlTemplate) = ACTION::LookupOK then
                                GenJnlLine."Journal Template Name" := GenJnlTemplate.Name;
                        end;
                    }
                    field(Var2; GenJnlLine."Journal Batch Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Batch';
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
                        ToolTip = 'Specifies if you want to transfer the postings in the general journal to the general ledger.';
                    }
                    field(PivotDate; PivotDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Pivot Date';
                        ToolTip = 'Specifies the desired pivot date if you want a pivot date that is different than the posting date on the domiciliation journal lines. The date you enter here will overwrite the posting date on the selected journal lines.';
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

    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        EBSetup.Get();
    end;

    trigger OnPostReport()
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        InStream: InStream;
        IsHandled: Boolean;
    begin
        FileMgt.BLOBImportFromServerFile(TempBlob, FromFile);
        IsHandled := false;
        OnPostReportOnBeforeDownloadXmlFile(TempBlob, IsHandled);
        if not IsHandled then begin
            TempBlob.CreateInStream(InStream);
            FileMgt.DownloadFromStreamHandler(InStream, '', '', AllFilesDescriptionTxt, FullFileName);
        end;
    end;

    trigger OnPreReport()
    begin
        // Preliminary Checks
        EnterpriseNo := '';
        CompanyInfo.Get();
        if CompanyInfo."Enterprise No." = '' then
            EnterpriseNo := '00000000000'
        else begin
            if not EnterpriseNoCheck.MOD97Check(CompanyInfo."Enterprise No.") then
                Error(Text000);
            EnterpriseNo := '0' + PaymJnlManagement.ConvertToDigit(CompanyInfo."Enterprise No.", MaxStrLen(EnterpriseNo));
        end;
        // Check General Journal
        GenJnlBatch.Reset();
        if not GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name") then
            Error(Text001, GenJnlLine.FieldCaption("Journal Batch Name"));

        if not (GenJnlBatch."Bal. Account Type" = GenJnlBatch."Bal. Account Type"::"G/L Account") then
            Error(Text002, GenJnlBatch.Name);

        if GenJnlBatch."Bal. Account No." = '' then
            Error(Text003, GenJnlBatch.Name);

        if not GLAcc.Get(GenJnlBatch."Bal. Account No.") then
            Error(Text004, GenJnlBatch."Bal. Account No.");

        if not (GLAcc."Account Type" = GLAcc."Account Type"::Posting) then
            Error(Text005, GLAcc."No.");

        if not (ClientTypeManagement.GetCurrentClientType() in [CLIENTTYPE::Desktop, CLIENTTYPE::Windows]) then
            FullFileName := RBMgt.GetFileName(FileName)
        else begin
            // filename
            if FileName = '' then
                Error(Text006);
            FullFileName := FileName;
        end;

        if FullFileName = '' then
            FullFileName := DomiciliationsPaymentsTxt;
    end;

    var
        Text000: Label 'Enterprise number in the Company Information table is not valid.';
        Text001: Label 'The %1 for posting is not specified.';
        Text002: Label 'The balance account type in %1 must be G/L Account.';
        Text003: Label 'The balance account number in %1 is not a valid G/L Account No.';
        Text004: Label '%1 in Journal Template is not a G/L Account No.';
        Text005: Label 'The account type in general ledger account %1 must be Posting.';
        Text006: Label 'You must enter a file name.';
        Text007: Label 'The bank account number in bank %1 is not valid.';
        Text008: Label 'Do you want to include domiciliations that do not have bank account numbers?';
        Text009: Label 'There are no domiciliation records.';
        Text010: Label 'There are domiciliation lines with different posting dates.';
        Text011: Label 'EUR';
        CompanyInfo: Record "Company Information";
        EBSetup: Record "Electronic Banking Setup";
        Cust: Record Customer;
        GLAcc: Record "G/L Account";
        BankAcc: Record "Bank Account";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        LastGenJnlLine: Record "Gen. Journal Line";
        DomJnlBatch: Record "Domiciliation Journal Batch";
        DomJnlLine: Record "Domiciliation Journal Line";
        TempDomJnlLine: Record "Domiciliation Journal Line" temporary;
        PaymJnlManagement: Codeunit PmtJrnlManagement;
        DomJnlManagement: Codeunit DomiciliationJnlManagement;
        FormatAddress: Codeunit "Format Address";
        EnterpriseNoCheck: Codeunit VATLogicalTests;
        NoSeriesBatch: Codeunit "No. Series - Batch";
        RBMgt: Codeunit "File Management";
        ClientTypeManagement: Codeunit "Client Type Management";
        xFile: File;
        PivotDate: Date;
        BankNo: Code[20];
        InscriptionNo: Code[10];
        DomJnlBatchName: Code[10];
        DocumentNo: Code[20];
        CurrencyCode: Code[10];
        Reference: Text[16];
        EnterpriseNo: Text[11];
        DomiciliationNo: Text[30];
        DomiciliationNoText: Text[16];
        FileName: Text[250];
        VersionCode: Text[1];
        CompanyAddress: array[8] of Text[100];
        FullFileName: Text;
        TypeCode: Integer;
        i: Integer;
        LineCounter: Integer;
        RecordCounter: array[2] of Integer;
        LineNo: Integer;
        Amt: Decimal;
        TotalAmount: array[2] of Decimal;
        TotalAmountLCY: array[2] of Decimal;
        DomNoDecimal: Decimal;
        TotalDomNoDecimal: array[2] of Decimal;
        AmtFactor: Decimal;
        AutomaticPosting: Boolean;
        FromFile: Text[250];
        ReceiptDateCaptionLbl: Label 'Receipt Date';
        EmptyStringCaptionLbl: Label '......  /  ......  /  ......';
        CodeCaptionLbl: Label 'Code';
        NameFinInstitutionCaptionLbl: Label 'Name Financial Institution';
        ApplicationCodeCaptionLbl: Label 'Application Code';
        V02CaptionLbl: Label '02';
        CreditorNameCaptionLbl: Label 'Creditor''s Name';
        CreditorAddressCaptionLbl: Label 'Creditor''s Address';
        CreditorIdentificationNoCaptionLbl: Label 'Creditor''s Identification No.';
        SequenceNoCaptionLbl: Label 'Sequence No.';
        CreditAccountNoCaptionLbl: Label 'Credit Account No.';
        PivotDateCaptionLbl: Label 'Pivot Date';
        FileNameCaptionLbl: Label 'File Name';
        NoOfRecordsCaptionLbl: Label 'No. of Records';
        TotalAmountCaptionLbl: Label 'Total Amounts';
        TotalDomNoCaptionLbl: Label 'Total Domiciliation Nos.';
        OrderingCustomerSignatureCaptionLbl: Label 'Ordering Customer''s Signature(s)';
        SignatureFinancialInstitutionCaptionLbl: Label 'Signature Financial Institution';
        IssueVoucherForDOMCaptionLbl: Label 'Issue voucher for DOM 80 collections and reimbursements';
        TypeCodeCaptionLbl: Label 'Type Code';
        ForIssueCaptionLbl: Label 'For issue,';
        ForReceiptCaptionLbl: Label 'For receipt,';
        TotalCaptionLbl: Label 'TOTAL', Comment = 'Total';
        AllFilesDescriptionTxt: Label 'All Files (*.*)|*.*', Comment = '{Split=r''\|''}{Locked=s''1''}';
        DomiciliationsPaymentsTxt: Label 'DomiciliationsPayments.txt';

    [Scope('OnPrem')]
    procedure FillCustomerData(DomicJnlLine: Record "Domiciliation Journal Line")
    begin
        if Cust."No." <> DomicJnlLine."Customer No." then begin
            Cust.Get(DomicJnlLine."Customer No.");
            DomiciliationNo := Cust."Domiciliation No.";
        end;
    end;

    [Scope('OnPrem')]
    procedure WriteHeaderRecord()
    begin
        xFile.Write(
              '00000' + // header record
              Format(Today, 6, '<day,2><month,2><year,2>') +
              Format(BankAcc."Bank Branch No.", 3) +
              '02' +
              Format(InscriptionNo, 10) +
              Format(EnterpriseNo, 11) +
              Format(EnterpriseNo, 11) +
              PaymJnlManagement.ConvertToDigit(BankAcc."Bank Account No.", 12) +
              VersionCode +
              ' ' +
              Format(PivotDate, 6, '<day,2><month,2><year,2>') +
              Format(' ', 60));
    end;

    [Scope('OnPrem')]
    procedure WriteDataRecord()
    begin
        if Amt > 0 then begin
            // number of payment records
            LineCounter := LineCounter + 1;

            DomiciliationNoText := PaymJnlManagement.ConvertToDigit(DomiciliationNo, 16);
            Reference := PaymJnlManagement.ConvertToDigit("Domiciliation Journal Line".Reference, 16);
            xFile.Write(
                  '1' +
                  PaymJnlManagement.DecimalNumeralZeroFormat(LineCounter, 4) +
                  Format(DomiciliationNo, 12) +
                  Format(TypeCode, 1) +
                  PaymJnlManagement.DecimalNumeralZeroFormat(Amt * AmtFactor, 12) +
                  Format(CompanyInfo.Name, 26) +
                  Format("Domiciliation Journal Line"."Message 1", 15) +
                  Format("Domiciliation Journal Line"."Message 2", 15) +
                  PaymJnlManagement.TextZeroFormat(Reference, 16) +
                  Format('', 30));

            i := TypeCode + 1;
            TotalAmount[i] := TotalAmount[i] + Amt;
            TotalAmountLCY[i] := TotalAmountLCY[i] + "Domiciliation Journal Line"."Amount (LCY)";
            RecordCounter[i] := RecordCounter[i] + 1;
            DomNoDecimal := 0;
            if DomiciliationNoText <> '' then
                Evaluate(DomNoDecimal, DomiciliationNoText);
            TotalDomNoDecimal[i] := TotalDomNoDecimal[i] + DomNoDecimal;

            "Domiciliation Journal Line".Status := "Domiciliation Journal Line".Status::Processed;
            "Domiciliation Journal Line".Processing := true;
            "Domiciliation Journal Line".Modify();
        end;
        Amt := 0;
    end;

    [Scope('OnPrem')]
    procedure WriteTrailerRecord()
    begin
        xFile.Write(
              '9' +
              PaymJnlManagement.DecimalNumeralZeroFormat(RecordCounter[1], 4) +
              PaymJnlManagement.DecimalNumeralZeroFormat(TotalAmount[1] * AmtFactor, 12) +
              PaymJnlManagement.DecimalNumeralZeroFormat(TotalDomNoDecimal[1], 15) +
              PaymJnlManagement.DecimalNumeralZeroFormat(RecordCounter[2], 4) +
              PaymJnlManagement.DecimalNumeralZeroFormat(TotalAmount[2] * AmtFactor, 12) +
              PaymJnlManagement.DecimalNumeralZeroFormat(TotalDomNoDecimal[2], 15) +
              Format('', 65));

        TempDomJnlLine := "Domiciliation Journal Line";
        TempDomJnlLine."Customer No." := GenJnlBatch."Bal. Account No.";
        TempDomJnlLine.Amount := -(TotalAmountLCY[1] + TotalAmountLCY[2]);
        TempDomJnlLine."Message 1" := '';
        TempDomJnlLine."Applies-to Doc. Type" := TempDomJnlLine."Applies-to Doc. Type"::" ";
        TempDomJnlLine."Applies-to Doc. No." := '';
        TempDomJnlLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure SetGenJnlLine(DomicJnlLine: Record "Domiciliation Journal Line")
    begin
        if DomicJnlLine."Pmt. Disc. Possible" <> 0 then
            DomJnlManagement.ModifyPmtDiscDueDate(DomicJnlLine);
        GenJnlLine.Init();
        GenJnlLine."Journal Template Name" := GenJnlBatch."Journal Template Name";
        GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
        GenJnlLine."Line No." := LastGenJnlLine."Line No." + 10000;
        GenJnlLine."Document No." := DocumentNo;
        GenJnlLine."Posting Date" := DomicJnlLine."Posting Date";
        GenJnlLine."Document Date" := DomicJnlLine."Posting Date";
        GenJnlLine.Validate(Amount, DomicJnlLine.Amount);
        if DomicJnlLine."Message 1" <> '' then
            GenJnlLine.Description := DomicJnlLine."Message 1";
        GenJnlLine."Reason Code" := DomicJnlLine."Reason Code";
        GenJnlLine."Source Code" := DomicJnlLine."Source Code";
        GenJnlLine."Source No." := DomicJnlLine."Customer No.";

        if DomicJnlLine."Applies-to Doc. Type" = DomJnlLine."Applies-to Doc. Type"::" " then begin
            GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"G/L Account");
            GenJnlLine.Validate("Account No.", DomicJnlLine."Customer No.");
            if GenJnlLine.Amount > 0 then
                GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment
            else
                GenJnlLine."Document Type" := GenJnlLine."Document Type"::Refund;
            GenJnlLine."Source No." := DomicJnlLine."Customer No.";
            GenJnlLine.Insert();
        end else begin
            Cust.Get(DomicJnlLine."Customer No.");
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
            GenJnlLine."Account No." := DomicJnlLine."Customer No.";
            if DomicJnlLine.Amount < 0 then
                GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment
            else
                GenJnlLine."Document Type" := GenJnlLine."Document Type"::Refund;
            GenJnlLine."Applies-to Doc. Type" := DomicJnlLine."Applies-to Doc. Type";
            GenJnlLine."Applies-to Doc. No." := DomicJnlLine."Applies-to Doc. No.";
            GenJnlLine."Currency Code" := DomicJnlLine."Currency Code";
            GenJnlLine."Currency Factor" := DomicJnlLine."Currency Factor";
            GenJnlLine."Bill-to/Pay-to No." := DomicJnlLine."Customer No.";
            GenJnlLine."Posting Group" := Cust."Customer Posting Group";
            GenJnlLine."Salespers./Purch. Code" := Cust."Salesperson Code";
            GenJnlLine."Source Type" := GenJnlLine."Source Type"::Customer;
            GenJnlLine."Dimension Set ID" := DomicJnlLine."Dimension Set ID";
            GenJnlLine.Insert();
        end;
        LastGenJnlLine := GenJnlLine;
    end;

    [Scope('OnPrem')]
    procedure SetGlobalPostingVariables(var NewGenJnlBatch: Record "Gen. Journal Batch"; var NewLastGenJnlLine: Record "Gen. Journal Line"; NewDocumentNo: Code[10])
    begin
        LastGenJnlLine := NewLastGenJnlLine;
        GenJnlBatch := NewGenJnlBatch;
        DocumentNo := NewDocumentNo;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostReportOnBeforeDownloadXmlFile(var TempBlob: Codeunit "Temp Blob"; var IsHandled: Boolean);
    begin
    end;
}

