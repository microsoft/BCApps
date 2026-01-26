// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Environment;
using System.IO;
using System.Utilities;

report 2000001 "File Domestic Payments"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/BankMgt/Payment/FileDomesticPayments.rdlc';
    Caption = 'File Domestic Payments';
    Permissions = TableData "Cust. Ledger Entry" = rim,
                  TableData "Vendor Ledger Entry" = rim,
                  TableData "Gen. Journal Line" = rim;
    ProcessingOnly = false;
    UseRequestPage = true;

    dataset
    {
        dataitem(Loop; "Integer")
        {
            DataItemTableView = sorting(Number);
            dataitem("Payment Journal Line"; "Payment Journal Line")
            {
                DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Account Type", "Account No.");

                trigger OnAfterGetRecord()
                var
                    NewGroupLoc: Boolean;
                begin
                    case "Account Type" of
                        "Account Type"::Customer:
                            FillCustomerData("Payment Journal Line");
                        "Account Type"::Vendor:
                            FillVendorData("Payment Journal Line");
                    end;

                    BankAccNo := "Beneficiary Bank Account No.";

                    // OGM written on line basis
                    if "Separate Line" then begin
                        if "Standard Format Message" then begin
                            ReferenceType := '8';
                            References := PaymJnlManagement.ConvertToDigit("Payment Message", 12);
                        end else begin
                            // partial payment
                            ReferenceType := '3';
                            if "Payment Message" = '' then
                                References := "External Document No."
                            else
                                References := "Payment Message";
                        end;
                        Amt[1] := Amount;
                        WriteDataRecord();
                    end else begin
                        // none OGM is grouped in OnPostSection-trigger of GroupFooter section
                        ReferenceType := '3';

                        // overflow of reference string is not test (> 106 chars)
                        if "Payment Message" = '' then
                            Reference := "External Document No."
                        else
                            Reference := "Payment Message";

                        if StrLen(References + ' ' + Reference) > 106 then
                            if EBSetup."Cut off Payment Message Texts" then
                                References := CopyStr(References, 1, 102) + ' ...'
                            else
                                WriteDataRecord();

                        if References = '' then
                            References := Reference
                        else
                            References := CopyStr(References + ' ' + Reference, 1, 106);

                        Amt[1] := Amt[1] + Amount;
                        CurrencyCode := "Currency Code";
                        NewGroupLoc := CheckNewGroup();
                        if NewGroupLoc then
                            WriteDataRecord();
                    end;
                end;

                trigger OnPostDataItem()
                begin
                    SetRange("Separate Line");
                end;

                trigger OnPreDataItem()
                var
                    PmtJnlLineLoc: Record "Payment Journal Line";
                begin
                    SetRange("Separate Line");

                    if Loop.Number = 1 then begin
                        PmtJnlLineLoc.CopyFilters("Payment Journal Line");
                        PmtJnlLineLoc.FindFirst();
                        GetBankAccount(PmtJnlLineLoc."Bank Account");
                        InterbankClearingCode := BankAcc."Interbank Clearing Code";

                        if ExecutionDate <> 0D then
                            ModifyAll("Posting Date", ExecutionDate);

                        PaymJnlTest.CheckPostingDate("Payment Journal Line", GenJnlLine."Journal Template Name");
                    end;

                    SetRange("Separate Line", (Loop.Number = 1));

                    if ExecutionDate <> 0D then
                        SetRange("Posting Date", ExecutionDate);

                    OnAfterCheckPostingDate("Payment Journal Line", GenJnlLine);

                    if Loop.Number = 1 then begin
                        Clear(xFile);
                        xFile.TextMode := true;
                        xFile.WriteMode := true;
                        FromFile := RBMgt.ServerTempFileName('txt');
                        xFile.Create(FromFile);

                        VersionCode := '5';
                        AmtFactor := 100;
                        WriteHeaderRecord();
                    end;
                end;
            }

            trigger OnPreDataItem()
            begin
                // 1 time for OGM and 1 time for none OGM
                SetRange(Number, 1, 2);
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
            column(CompanyInfoName; CompanyInfo.Name)
            {
            }
            column(CompanyInfoCity; CompanyInfo.City)
            {
            }
            column(CompanyInfoEnterpriseNo; CompanyInfo."Enterprise No.")
            {
            }
            column(InscriptionNo; InscriptionNo)
            {
            }
            column(BankAccBankAccNo; BankAcc."Bank Account No.")
            {
            }
            column(ExecutionDate; Format(ExecutionDate))
            {
            }
            column(FileName; FileName)
            {
            }
            column(PaymentNo2; PaymentNo * 2)
            {
                DecimalPlaces = 0 : 0;
            }
            column(TotalAmt1; TotalAmount[1])
            {
                AutoFormatExpression = CurrencyCode;
                AutoFormatType = 1;
            }
            column(TotalAccNoDecimal; TotalAccNoDecimal)
            {
                DecimalPlaces = 0 : 0;
            }
            column(PaymentNo; PaymentNo)
            {
                DecimalPlaces = 0 : 0;
            }
            column(ReceiptDateCaption; ReceiptDateCaptionLbl)
            {
            }
            column(EmptyStringCaption; EmptyStringCaptionLbl)
            {
            }
            column(BankBranchNoCaption; BankBranchNoCaptionLbl)
            {
            }
            column(BankAccNameCaption; BankAccNameCaptionLbl)
            {
            }
            column(AppCodeCaption; AppCodeCaptionLbl)
            {
            }
            column(V01Caption; V01CaptionLbl)
            {
            }
            column(CompanyInfoNameCaption; CompanyInfoNameCaptionLbl)
            {
            }
            column(CompanyInfoCityCaption; CompanyInfoCityCaptionLbl)
            {
            }
            column(CompanyInfoEnterpriseNoCaption; CompanyInfoEnterpriseNoCaptionLbl)
            {
            }
            column(InscriptionNoCaption; InscriptionNoCaptionLbl)
            {
            }
            column(BankAccNoCaption; BankAccNoCaptionLbl)
            {
            }
            column(ExecutionDateCaption; ExecutionDateCaptionLbl)
            {
            }
            column(FileNameCaption; FileNameCaptionLbl)
            {
            }
            column(PaymentNo2Caption; PaymentNo2CaptionLbl)
            {
            }
            column(TotalAmt1Caption; TotalAmt1CaptionLbl)
            {
            }
            column(TotalAccNoDecimalCaption; TotalAccNoDecimalCaptionLbl)
            {
            }
            column(PaymentNoCaption; PaymentNoCaptionLbl)
            {
            }
            column(OrderCustsSigsCaption; OrderCustsSigsCaptionLbl)
            {
            }
            column(AddrsSigsCaption; AddrsSigsCaptionLbl)
            {
            }
            column(SalariesCaption; SalariesCaptionLbl)
            {
            }
            column(NonSalariesCaption; NonSalariesCaptionLbl)
            {
            }
            column(PmtTypeTextCaption; PmtTypeTextCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                WriteTrailerRecord();
                xFile.Close();

                // basename of file to print on 'borderel'
                FileName := ConvertStr(FileName, '\', '/');
                while StrPos(FileName, '/') > 0 do
                    FileName := CopyStr(FileName, StrPos(FileName, '/') + 1);

                // max 15 positions
                if StrLen(Format(TotalAccNoDecimal, 0, 2)) > 15 then
                    Evaluate(TotalAccNoDecimal,
                      CopyStr(Format(TotalAccNoDecimal, 0, 2),
                        StrLen(Format(TotalAccNoDecimal, 0, 2)) - 14));
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
                    field("GenJnlLine.""Journal Template Name"""; GenJnlLine."Journal Template Name")
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
                    field("GenJnlLine.""Journal Batch Name"""; GenJnlLine."Journal Batch Name")
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
                        ToolTip = 'Specifies if you want to transfer the postings in the general journal to the general ledger. You may want to leave this field blank for international payments, so you can enter the exact exchange rate upon receiving the bank file.';
                    }
                    field(IncludeDimText; IncludeDimText)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Dimensions';
                        Editable = false;
                        ToolTip = 'Specifies the dimensions that you want to include in the report. The option is only available if the Summarize Gen. Jnl. Lines field in the Electronic Banking Setup window is selected.';

                        trigger OnAssistEdit()
                        var
                            DimSelectionBuf: Record "Dimension Selection Buffer";
                        begin
                            DimSelectionBuf.SetDimSelectionMultiple(3, REPORT::"File Domestic Payments", IncludeDimText);
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

        trigger OnOpenPage()
        var
            DimSelectionBuf: Record "Dimension Selection Buffer";
        begin
            IncludeDimText := DimSelectionBuf.GetDimSelectionText(3, REPORT::"File Domestic Payments", '');
        end;
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
          REPORT::"File Domestic Payments", BalancingPostingDate);
        PaymentJournalPost.SetTableView("Payment Journal Line");
        PaymentJournalPost.RunModal();
    end;

    trigger OnPreReport()
    begin
        // preliminary checks
        EnterpriseNo := '';
        CompanyInfo.Get();
        if CompanyInfo."Enterprise No." = '' then
            EnterpriseNo := '00000000000'
        else begin
            if not EnterpriseNoCheck.MOD97Check(CompanyInfo."Enterprise No.") then
                Error(Text000);
            EnterpriseNo := '0' + PaymJnlManagement.ConvertToDigit(CompanyInfo."Enterprise No.", MaxStrLen(EnterpriseNo));
        end;

        if not (ClientTypeManagement.GetCurrentClientType() in [CLIENTTYPE::Desktop, CLIENTTYPE::Windows]) then
            FullFileName := RBMgt.GetFileName(FileName)
        else begin
            if FileName = '' then
                Error(Text006);

            if Exists(FileName) then
                if not Confirm(Text016, false, FileName) then
                    Error(Text017, FileName);

            FullFileName := FileName;

            if FullFileName = '' then
                FullFileName := DomesticPaymentsFileNameTxt;
        end;
    end;

    var
        Text000: Label 'The enterprise number in table company information is not valid.';
        Text006: Label 'You must enter a file name.';
        Text011: Label 'Journal %1 is not a general journal.';
        Text014: Label 'The combination of invoices and credit memos for %1 %2 has caused an attempt to write a negative amount to the payment file. The format of the file does not allow this.', Comment = 'Parameter 1 - account type (,Customer,Vendor), 2 - account number.';
        CompanyInfo: Record "Company Information";
        EBSetup: Record "Electronic Banking Setup";
        Cust: Record Customer;
        Vend: Record Vendor;
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        BankAcc: Record "Bank Account";
        PaymJnlManagement: Codeunit PmtJrnlManagement;
        PaymJnlTest: Codeunit CheckPaymJnlLine;
        EnterpriseNoCheck: Codeunit VATLogicalTests;
        RBMgt: Codeunit "File Management";
        ClientTypeManagement: Codeunit "Client Type Management";
        xFile: File;
        ExecutionDate: Date;
        InscriptionNo: Code[10];
        CurrencyCode: Code[10];
        EnterpriseNo: Text[11];
        BankAccNo: Text[30];
        BankAccNoText: Text[12];
        References: Text[250];
        Reference: Text[250];
        ReferenceType: Text[1];
        FileName: Text;
        Remittee: array[4] of Text[50];
        VersionCode: Text[1];
        IncludeDimText: Text[250];
        FullFileName: Text;
        InterbankClearingCode: Integer;
        PaymentNo: Decimal;
        Amt: array[2] of Decimal;
        TotalAmount: array[2] of Decimal;
        AccNoDecimal: Decimal;
        TotalAccNoDecimal: Decimal;
        AmtFactor: Decimal;
        AutomaticPosting: Boolean;
        FromFile: Text[250];
        Text016: Label 'The %1 already exists.\\Do you want to replace the existing file?';
        Text017: Label 'The file %1 already exists.';
        ReceiptDateCaptionLbl: Label 'Receipt Date';
        EmptyStringCaptionLbl: Label '......  /  ......  /  ......';
        BankBranchNoCaptionLbl: Label 'Code';
        BankAccNameCaptionLbl: Label 'Name Financial Institution';
        AppCodeCaptionLbl: Label 'Application Code';
        V01CaptionLbl: Label '01';
        CompanyInfoNameCaptionLbl: Label 'Ordering Customer''s Name';
        CompanyInfoCityCaptionLbl: Label 'Odering Customer''s City';
        CompanyInfoEnterpriseNoCaptionLbl: Label 'Ordering Customer''s Identification No.';
        InscriptionNoCaptionLbl: Label 'Sequence No.';
        BankAccNoCaptionLbl: Label 'Debit Account No.';
        ExecutionDateCaptionLbl: Label 'Execution Date';
        FileNameCaptionLbl: Label 'File Name';
        PaymentNo2CaptionLbl: Label 'No. of Records';
        TotalAmt1CaptionLbl: Label 'Total Amounts';
        TotalAccNoDecimalCaptionLbl: Label 'Total Credit Account Nos.';
        PaymentNoCaptionLbl: Label 'No. of Payments';
        OrderCustsSigsCaptionLbl: Label 'Ordering Customer''s Signature(s)';
        AddrsSigsCaptionLbl: Label 'Addressee''s Signature(s)';
        SalariesCaptionLbl: Label 'Salaries (*)';
        NonSalariesCaptionLbl: Label 'Non-Salaries';
        PmtTypeTextCaptionLbl: Label '(*) Please specify payment type ("Salaries" or "Non-Salaries") in the upper right corner of the issue voucher.';
        AllFilesDescriptionTxt: Label 'All Files (*.*)|*.*', Comment = '{Split=r''\|''}{Locked=s''1''}';
        DomesticPaymentsFileNameTxt: Label 'DomesticPayments.txt';

    [Scope('OnPrem')]
    procedure FillCustomerData(PaymentJnlLine: Record "Payment Journal Line")
    begin
        Cust.Get(PaymentJnlLine."Account No.");
        Remittee[1] := CopyStr(Cust.Name, 1, MaxStrLen(Remittee[1]));
        Remittee[2] := CopyStr(Cust.Address, 1, MaxStrLen(Remittee[2]));
        Remittee[3] := PaymJnlManagement.ConvertToDigit(CopyStr(Cust."Post Code", 1), MaxStrLen(Remittee[3]));
        Remittee[4] := CopyStr(Cust.City, 1, MaxStrLen(Remittee[4]));
    end;

    [Scope('OnPrem')]
    procedure FillVendorData(PaymentJnlLine: Record "Payment Journal Line")
    begin
        Vend.Get(PaymentJnlLine."Account No.");
        Remittee[1] := CopyStr(Vend.Name, 1, MaxStrLen(Remittee[1]));
        Remittee[2] := CopyStr(Vend.Address, 1, MaxStrLen(Remittee[2]));
        Remittee[3] := PaymJnlManagement.ConvertToDigit(CopyStr(Vend."Post Code", 1), MaxStrLen(Remittee[3]));
        Remittee[4] := CopyStr(Vend.City, 1, MaxStrLen(Remittee[4]));
    end;

    [Scope('OnPrem')]
    procedure WriteHeaderRecord()
    begin
        xFile.Write(
            // '00000'  // header record
            '0' +
            Format(InterbankClearingCode, 1) +
            '000' +
            Format(Today, 6, '<day,2><month,2><year,2>') +
            Format(BankAcc."Bank Branch No.", 3) +
            '01' +
            Format(ExecutionDate, 6, '<day,2><month,2><year,2>') +
            ' ' +
            '000' +
            PaymJnlManagement.ConvertToDigit(BankAcc."Bank Account No.", 12) +
            Format(CompanyInfo.Name, 26) +
            Format(CompanyInfo.Address, 26) +
            Format(PaymJnlManagement.ConvertToDigit(CompanyInfo."Post Code", 4), 4) +
            Format(CompanyInfo.City, 22) +
            '0' +
            Format(InscriptionNo, 10) +
            Format(VersionCode, 1));
    end;

    [Scope('OnPrem')]
    procedure WriteDataRecord()
    begin
        if Amt[1] <= 0 then
            Error(Text014, "Payment Journal Line"."Account Type", "Payment Journal Line"."Account No.");

        // Number of Payment Records
        PaymentNo := PaymentNo + 1;
        BankAccNoText := PaymJnlManagement.ConvertToDigit(BankAccNo, 12);
        xFile.Write(
            '1' +
            PaymJnlManagement.DecimalNumeralZeroFormat(PaymentNo, 4) +
            Format('', 8) +
            PadStr('', 10, '0') +
            Format(BankAccNoText, 12) +
            PaymJnlManagement.DecimalNumeralZeroFormat(Amt[1] * AmtFactor, 12) +
            Format(Remittee[1], 26) +
            '0' +
            Format(References, 53) +
            Format(ReferenceType, 1));
        xFile.Write(
            '2' +
            PaymJnlManagement.DecimalNumeralZeroFormat(PaymentNo, 4) +
            '0' +
            Format(Remittee[2], 26) +
            Format(Remittee[3], 4) +
            Format(Remittee[4], 22) +
            Format(CopyStr(References, 54), 53) +
            '0' +
            Format('', 16));

        // Total for Trailer record
        TotalAmount[1] := TotalAmount[1] + Amt[1];
        // Trailer Record has the Sum of All Account Numbers
        Evaluate(AccNoDecimal, BankAccNoText);
        TotalAccNoDecimal := TotalAccNoDecimal + AccNoDecimal;

        Clear(Amt);
        References := '';
    end;

    [Scope('OnPrem')]
    procedure WriteTrailerRecord()
    begin
        xFile.Write(
            '9' +
            PaymJnlManagement.DecimalNumeralZeroFormat(PaymentNo * 2, 4) +
            PaymJnlManagement.DecimalNumeralZeroFormat(PaymentNo, 4) +
            PaymJnlManagement.DecimalNumeralZeroFormat(TotalAmount[1] * AmtFactor, 12) +
            PaymJnlManagement.DecimalNumeralZeroFormat(TotalAccNoDecimal, 15) +
            Format(EnterpriseNo, 11) +
            Format('', 81));
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
            if PmtJnlLineLoc."Account No." <> "Payment Journal Line"."Account No." then
                NewGroupLoc := true;
        end else
            NewGroupLoc := true;
        exit(NewGroupLoc);
    end;

    local procedure GenJnlLineJournalTemplateNameOnAfterValidate()
    begin
        GenJnlTemplate.Get(GenJnlLine."Journal Template Name");
        if GenJnlTemplate.Type <> GenJnlTemplate.Type::General then
            Error(Text011, GenJnlTemplate.Name);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckPostingDate(var PaymentJournalLine: Record "Payment Journal Line"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
}

