// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Pricing;
using Microsoft.Service.Reports;
using Microsoft.Utilities;
using System.Environment.Configuration;
using System.TestLibraries.Utilities;

codeunit 136104 "Service Posting - Credit Memo"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Service] [Credit Memo]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryService: Codeunit "Library - Service";
        UseContractTemplateConfirm: Label 'Do you want to create the contract using a contract template?';
        UnknownError: Label 'Unknown error.';
        LibraryUtilityOnPrem: Codeunit "Library - Utility OnPrem";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryResource: Codeunit "Library - Resource";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;
        DocumentHeaderNo: Code[20];
        DocumentType: Enum "Gen. Journal Document Type";
        ServiceHeaderExistError: Label 'The %1 must not exist. Identification fields and value: %2=''%3'',%4=''%5''.';
        AmountMustMatchError: Label 'Amount in %1, %2 must match.';
        ContractNo: Code[20];
        FilePath: Text[1024];
        CreditMemoError: Label 'A Service Credit Memo cannot be created because Service %1 %2 has at least one unposted Service Invoice linked to it.';
        InvoiceError: Label 'Invoice cannot be created because amount to invoice for this invoice period is zero.';
        ExpectedConfirm: Label 'The Credit Memo doesn''t have a Corrected Invoice No. Do you want to continue?';
        AmountError: Label '%1 must be %2 in %3.';
        CorrectionErr: Label '%1 must be negative in ledger entry for G/L Account %2.';
        ControlShouldBeDisabledErr: Label 'Control should be disabled';
        ControlShouldBeEnabledErr: Label 'Control should be enabled';

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCrdtMemoCrtnFrmCreateCrdtM()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
        CreditMemoNo: Code[20];
    begin
        // [SCENARIO] Post the Invoice and create Credit Memo from Create Credit Memo function.
        // 1. Create and Sign a Service Contract with any Customer.
        // 2. Post the Invoice and create Credit Memo from Create Credit Memo function.
        // 3. Verify that the Service Lines in the Credit Memo correspond to the Service Lines in the Service Contract.

        // [GIVEN] Create and sign Service Contract. Post the Service Invoice.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine);

        SignServContractDoc.SignContract(ServiceContractHeader);
        PostServiceInvoice(ServiceContractHeader."Contract No.");

        // [WHEN] Create Service Credit Memo from Create Contract Line Credit Memos.
        CreditMemoNo := CreateContractLineCreditMemo(ServiceContractLine);

        // [THEN] Match the values in the Service Credit Memo Line with the values in the Service Contract Line.
        VerifyCrditMemoLnWithContrctLn(ServiceContractLine, CreditMemoNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCrdtMemoCrtnFrmRemCntrctLn()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        TempServiceContractLine: Record "Service Contract Line" temporary;
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // [SCENARIO] Post the Invoice and create Credit Memo by running Remove Lines from Contract report.
        // 1. Create and Sign a Service Contract with any Customer having field Automatic Credit Memos as TRUE on Service Contract Header.
        // 2. Post the Invoice and create Credit Memo by running Remove Lines from Contract report.
        // 3. Verify that the Service Line in the Credit Memo corresponds to the Service Line in the Service Contract.

        // [GIVEN] Create Service Contract with Automatic Credit Memo as TRUE and sign Service Contract. Post the Service Invoice.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine);
        ServiceContractHeader.Validate("Automatic Credit Memos", true);
        ServiceContractHeader.Modify(true);

        SignServContractDoc.SignContract(ServiceContractHeader);
        PostServiceInvoice(ServiceContractHeader."Contract No.");

        // Get refreshed instance of Service Contract Line and save Service Contract Lines in temporary table.
        ServiceContractLine.Get(ServiceContractLine."Contract Type", ServiceContractLine."Contract No.", ServiceContractLine."Line No.");
        SaveServiceContractLinesInTemp(TempServiceContractLine, ServiceContractLine);

        // [WHEN] Create Service Credit Memo by running Remove Lines from Contract report.
        RemoveLinesFromContract(ServiceContractLine);

        // [THEN] Match the values in the Service Credit Memo Line with the values in the Service Contract Line.
        FindServiceCreditMemo(ServiceHeader, ServiceContractHeader."Contract No.");
        VerifyCrditMmLnWthTempCntrctLn(TempServiceContractLine, ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCrdtMemoCrtnFrmDelCntrctLn()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        ServiceContractLine2: Record "Service Contract Line";
        TempServiceContractLine: Record "Service Contract Line" temporary;
        SignServContractDoc: Codeunit SignServContractDoc;
        LockOpenServContract: Codeunit "Lock-OpenServContract";
    begin
        // [SCENARIO] Post the Invoice and create Credit Memo by deleting Service Contract Lines from Service Contract.
        // 1. Create and Sign a Service Contract with any Customer having field Automatic Credit Memos as TRUE on Service Contract Header.
        // 2. Post the Invoice and create Credit Memo by deleting Service Contract Lines from Service Contract.
        // 3. Verify that the Service Lines in the Credit Memo correspond to the Service Lines in the Service Contract.

        // [GIVEN] Create Service Contract with Automatic Credit Memo as TRUE and sign Service Contract. Post the Service Invoice.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine);
        ServiceContractHeader.Validate("Automatic Credit Memos", true);
        ServiceContractHeader.Modify(true);

        SignServContractDoc.SignContract(ServiceContractHeader);
        PostServiceInvoice(ServiceContractHeader."Contract No.");

        // Get refreshed instance of Service Contract Header and save Service Contract Lines in temporary table.
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        SaveServiceContractLinesInTemp(TempServiceContractLine, ServiceContractLine);

        // [WHEN] Open Service Contract. Create Service Credit Memo by deleting Service Contract Lines from Service Contract.
        LockOpenServContract.OpenServContract(ServiceContractHeader);
        ServiceContractLine2.SetRange("Contract Type", ServiceContractHeader."Contract Type");
        ServiceContractLine2.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceContractLine2.DeleteAll(true);

        // [THEN] Match the values in the Service Credit Memo Line with the values in the Service Contract Line.
        FindServiceCreditMemo(ServiceHeader, ServiceContractHeader."Contract No.");
        VerifyCrditMmLnWthTempCntrctLn(TempServiceContractLine, ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure TestCrdtMemoCrtnFrmGtPrpdCntrc()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        SignServContractDoc: Codeunit SignServContractDoc;
        ServContractManagement: Codeunit ServContractManagement;
    begin
        // [SCENARIO] Create and post the Invoice and create Credit Memo using the Get Prepaid Contract Entries.
        // 1. Create and Sign a Service Contract with any Customer.
        // 2. Create and post the Invoice and create Credit Memo using the Get Prepaid Contract Entries.
        // 3. Verify that the Service Lines in the Credit Memo correspond to the Service Lines in the Service Contract.

        // [GIVEN] Create and sign Service Contract. Post the Service Invoice.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine);
        ServiceContractHeader.Validate("Starting Date", CalcDate('<-CM>', WorkDate()));  // Validate first date of month.
        ServiceContractHeader.Validate(Prepaid, true);
        ServiceContractHeader.Modify(true);

        SignServContractDoc.SignContract(ServiceContractHeader);
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServContractManagement.InitCodeUnit();
        ServContractManagement.CreateInvoice(ServiceContractHeader);
        PostServiceInvoice(ServiceContractHeader."Contract No.");

        // [WHEN] Create Service Credit Memo by inserting Credit Memo Header and running Get Prepaid Contract Entries.
        LibraryService.CreateServiceHeader(
          ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", ServiceContractHeader."Customer No.");
        GetPrepaidContractEntry(ServiceHeader, ServiceContractHeader."Contract No.");

        // [THEN] Match the values in the Service Credit Memo Line with the values in the Service Contract Line.
        VerifyCrdtMmLnWthPrpdCntrctLn(ServiceContractLine, ServiceHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreditMemoCreation()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [SCENARIO] Create a new Credit Memo - Service Header, Service Lines for Item, G/L Account and Resource.
        // 2. Verify that the application allows creation of Service Credit Memo Lines.

        // Setup.
        Initialize();

        // [WHEN] Create Service Credit Memo by inserting Credit Memo Header and Service Credit Memo Lines.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        CreateServiceCreditMemoLine(ServiceHeader);

        // [THEN] Verify that the Service Credit Memo Lines are created.
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestPrtCrdtMmCrtnFrmCrteCrdtMm()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceContractLine2: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
        ServContractManagement: Codeunit ServContractManagement;
        LockOpenServContract: Codeunit "Lock-OpenServContract";
        CreditMemoNo: Code[20];
        ExpirationDate: Date;
    begin
        // [SCENARIO] Create and post the Invoice. Change Contract "Expiration Date" on Service Contract Lines one by one and create Credit Memo from "Create Credit Memo" function for each Service Contract Line.
        // 1. Create and Sign a Service Contract with any Customer.
        // 2. Create and post the Invoice. Change Contract Expiration Date on Service Contract Lines one by one and create Credit Memo from
        // Create Credit Memo function for each Service Contract Line.
        // 3. Verify that the Service Lines in the Credit Memo correspond to the Service Lines in the Service Contract.

        // [GIVEN] Create and sign Service Contract. Post the Service Invoice.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine);
        ServiceContractHeader.Validate("Starting Date", CalcDate('<-CM>', WorkDate()));  // Validate first date of month.
        ServiceContractHeader.Validate(Prepaid, true);
        ServiceContractHeader.Modify(true);

        SignServContractDoc.SignContract(ServiceContractHeader);
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServContractManagement.InitCodeUnit();
        ServContractManagement.CreateInvoice(ServiceContractHeader);
        PostServiceInvoice(ServiceContractHeader."Contract No.");

        // [WHEN] Change "Expiration Date" on Lines one by one and create Service Credit Memo from Create Contract Line Credit Memo.
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        LockOpenServContract.OpenServContract(ServiceContractHeader);
        FindServiceContractLines(ServiceContractLine2, ServiceContractHeader);
        ExpirationDate := CalcDate('<+1D>', ServiceContractHeader."Starting Date");  // Expiration Date should be set after Starting Date.
        repeat
            ServiceContractLine2.Validate("Credit Memo Date", ExpirationDate);
            ServiceContractLine2.Validate("Contract Expiration Date", ExpirationDate);
            ServiceContractLine2.Modify(true);
            ExpirationDate := CalcDate('<+1D>', ExpirationDate);  // Take different dates for different lines adding one day each time.
            CreditMemoNo := ServContractManagement.CreateContractLineCreditMemo(ServiceContractLine2, false);
        until ServiceContractLine2.Next() = 0;

        // [THEN] Match the values in the Service Credit Memo Line with the values in the Service Contract Line.
        VerifyCrditMemoLnWithContrctLn(ServiceContractLine2, CreditMemoNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestPrtCrdtMmCrtnFrmDlCntrctLn()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        ServiceContractLine2: Record "Service Contract Line";
        TempServiceContractLine: Record "Service Contract Line" temporary;
        SignServContractDoc: Codeunit SignServContractDoc;
        LockOpenServContract: Codeunit "Lock-OpenServContract";
    begin
        // [SCENARIO] Post the Invoice and create Credit Memo by deleting Service Contract Lines from Service Contract one by one.
        // 1. Create and Sign a Service Contract with any Customer having field Automatic Credit Memos as TRUE on Service Contract Header.
        // 2. Post the Invoice and create Credit Memo by deleting Service Contract Lines from Service Contract one by one.
        // 3. Verify that the Service Lines in the Credit Memo correspond to the Service Lines in the Service Contract.

        // [GIVEN] Create Service Contract with Automatic Credit Memo as TRUE and sign Service Contract. Post the Service Invoice.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine);
        ServiceContractHeader.Validate("Automatic Credit Memos", true);
        ServiceContractHeader.Modify(true);

        SignServContractDoc.SignContract(ServiceContractHeader);
        PostServiceInvoice(ServiceContractHeader."Contract No.");

        // Get refreshed instance of Service Contract Header and save Service Contract Lines in temporary table.
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        SaveServiceContractLinesInTemp(TempServiceContractLine, ServiceContractLine);

        // [WHEN] Open Service Contract. Create Service Credit Memo by deleting Service Contract Lines from Service Contract one by one.
        LockOpenServContract.OpenServContract(ServiceContractHeader);
        FindServiceContractLines(ServiceContractLine2, ServiceContractHeader);
        repeat
            ServiceContractLine2.Delete(true);  // Delete one line at a time.
        until ServiceContractLine2.Next() = 0;

        // [THEN] Match the values in the Service Credit Memo Line with the values in the Service Contract Line.
        FindServiceCreditMemo(ServiceHeader, ServiceContractHeader."Contract No.");
        VerifyCrditMmLnWthTempCntrctLn(TempServiceContractLine, ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestPrtCrdtMmCrtnFrmRmCntrctLn()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        TempServiceContractLine: Record "Service Contract Line" temporary;
        SignServContractDoc: Codeunit SignServContractDoc;
        LockOpenServContract: Codeunit "Lock-OpenServContract";
    begin
        // [SCENARIO] Post the Invoice and create Credit Memo by running Remove Lines from Contract report for one Service Contract Line at a time.
        // 1. Create and Sign a Service Contract with any Customer having field Automatic Credit Memos as TRUE on Service Contract Header.
        // 2. Post the Invoice and create Credit Memo by running Remove Lines from Contract report for one Service Contract Line at a time.
        // 3. Verify that the Service Line in the Credit Memo corresponds to the Service Line in the Service Contract.

        // [GIVEN] Create Service Contract with Automatic Credit Memo as TRUE and sign Service Contract. Post the Service Invoice.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine);
        ServiceContractHeader.Validate("Automatic Credit Memos", true);
        ServiceContractHeader.Modify(true);

        SignServContractDoc.SignContract(ServiceContractHeader);
        PostServiceInvoice(ServiceContractHeader."Contract No.");

        // Get refreshed instance of Service Contract Line and save Service Contract Lines in temporary table.
        ServiceContractLine.Get(ServiceContractLine."Contract Type", ServiceContractLine."Contract No.", ServiceContractLine."Line No.");
        SaveServiceContractLinesInTemp(TempServiceContractLine, ServiceContractLine);

        // [WHEN] Create Service Credit Memo by running Remove Lines from Contract report for one Service Contract Line at a time.
        FindServiceContractLines(ServiceContractLine, ServiceContractHeader);
        repeat
            LockOpenServContract.OpenServContract(ServiceContractHeader);
            RemoveLinesFromContractFrOneLn(ServiceContractLine);
        until ServiceContractLine.Next() = 0;

        // [THEN] Match the values in the Service Credit Memo Line with the values in the Service Contract Line.
        FindServiceCreditMemo(ServiceHeader, ServiceContractHeader."Contract No.");
        VerifyCrditMmLnWthTempCntrctLn(TempServiceContractLine, ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCrdtMmCrtnAfterDltnCrdtMem()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        ServiceContractLine2: Record "Service Contract Line";
        TempServiceContractLine: Record "Service Contract Line" temporary;
        SignServContractDoc: Codeunit SignServContractDoc;
        LockOpenServContract: Codeunit "Lock-OpenServContract";
    begin
        // [SCENARIO] Create a new Credit Memo by deleting the remaining Service Contract Lines from Service Contract.
        // 1. Create and Sign a Service Contract with any Customer having field Automatic Credit Memos as TRUE on Service Contract Header.
        // 2. Post the Invoice and create a Credit Memo by deleting the first Service Contract Line from Service Contract.
        // 3. Delete the Credit Memo created in Step 2.
        // 4. Create a new Credit Memo by deleting the remaining Service Contract Lines from Service Contract.
        // 5. Verify that the Service Lines in the Credit Memo correspond to the Service Lines in the Service Contract.

        // [GIVEN] Create Service Contract with Automatic Credit Memo as TRUE and sign Service Contract. Post the Service Invoice.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine);
        ServiceContractHeader.Validate("Automatic Credit Memos", true);
        ServiceContractHeader.Modify(true);

        SignServContractDoc.SignContract(ServiceContractHeader);
        PostServiceInvoice(ServiceContractHeader."Contract No.");

        // [GIVEN] Open Service Contract. Create Service Credit Memo by deleting the first Service Contract Line from Service Contract.
        // [WHEN] Delete the Credit Memo and create a new Credit Memo by deleting remaining lines.
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        LockOpenServContract.OpenServContract(ServiceContractHeader);
        FindServiceContractLines(ServiceContractLine2, ServiceContractHeader);
        ServiceContractLine2.Delete(true);

        FindServiceCreditMemo(ServiceHeader, ServiceContractHeader."Contract No.");
        ServiceHeader.Delete(true);

        // Get refreshed instance of Service Contract Header and save Service Contract Lines in temporary table.
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        SaveServiceContractLinesInTemp(TempServiceContractLine, ServiceContractLine);

        LockOpenServContract.OpenServContract(ServiceContractHeader);
        ServiceContractLine2.DeleteAll(true);

        // [THEN] Match the values in the Service Credit Memo Line with the values in the Service Contract Line.
        FindServiceCreditMemo(ServiceHeader, ServiceContractHeader."Contract No.");
        VerifyCrditMmLnWthTempCntrctLn(TempServiceContractLine, ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCrdtMemoDltnFrmCrtCrdtM()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // [SCENARIO] Post the Invoice and create Credit Memo from Create Credit Memo function. Delete the Credit Memo.
        // 1. Create and Sign a Service Contract with any Customer.
        // 2. Post the Invoice and create Credit Memo from Create Credit Memo function.
        // 3. Delete the Credit Memo.
        // 4. Verify that the value of the field No. of Unposted Credit Memos in the Service Contract Header is 0.

        // [GIVEN] Create and sign Service Contract. Post the Service Invoice. Create Service Credit Memo from Create Contract Line
        // Credit Memo.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine);
        SignServContractDoc.SignContract(ServiceContractHeader);
        PostServiceInvoice(ServiceContractHeader."Contract No.");
        CreateContractLineCreditMemo(ServiceContractLine);

        // [WHEN] Delete the Credit Memo.
        FindServiceCreditMemo(ServiceHeader, ServiceContractHeader."Contract No.");
        ServiceHeader.Delete(true);

        // [THEN] Check that the value of the field No. of Unposted Credit Memos in the Service Contract Header is 0 .
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.CalcFields("No. of Unposted Credit Memos");
        ServiceContractHeader.TestField("No. of Unposted Credit Memos", 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure TestCrdtMemoDltnFrmGtPrpdCntrc()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        SignServContractDoc: Codeunit SignServContractDoc;
        ServContractManagement: Codeunit ServContractManagement;
        Assert: Codeunit Assert;
        CreditMemoNo: Code[20];
    begin
        // [SCENARIO] Create and post the Invoice and create Credit Memo using the Get Prepaid Contract Entries. Delete the Credit Memo.
        // 1. Create and Sign a Service Contract with any Customer.
        // 2. Create and post the Invoice and create Credit Memo using the Get Prepaid Contract Entries.
        // 3. Delete the Credit Memo.
        // 4. Verify that the Credit Memo has been deleted.

        // [GIVEN] Create and sign Service Contract. Post the Service Invoice. Create Service Credit Memo by inserting Credit Memo Header and running Get Prepaid Contract Entries.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine);
        ServiceContractHeader.Validate("Starting Date", CalcDate('<-CM>', WorkDate()));  // Validate first date of month.
        ServiceContractHeader.Validate(Prepaid, true);
        ServiceContractHeader.Modify(true);

        SignServContractDoc.SignContract(ServiceContractHeader);
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServContractManagement.InitCodeUnit();
        ServContractManagement.CreateInvoice(ServiceContractHeader);
        PostServiceInvoice(ServiceContractHeader."Contract No.");

        LibraryService.CreateServiceHeader(
          ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", ServiceContractHeader."Customer No.");
        GetPrepaidContractEntry(ServiceHeader, ServiceContractHeader."Contract No.");

        // [WHEN] Delete the Credit Memo.
        CreditMemoNo := ServiceHeader."No.";
        ServiceHeader.Delete(true);

        // [THEN] Check that the Credit Memo has been deleted.
        Assert.IsFalse(
          ServiceHeader.Get(ServiceHeader."Document Type"::"Credit Memo", CreditMemoNo),
          StrSubstNo(
            ServiceHeaderExistError,
            ServiceHeader.TableCaption(), ServiceHeader.FieldCaption("Document Type"),
            ServiceHeader."Document Type", ServiceHeader.FieldCaption("No."), ServiceHeader."No."));
    end;

    [Test]
    [HandlerFunctions('InvoiceESConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCreditMemoPostingFrNullQty()
    var
        ServiceHeader: Record "Service Header";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Create a new Credit Memo - Service Header, Service Lines for Item, G/L Account and Resource with 0 Quantity. Post the Credit Memo.
        // 1. Create a new Credit Memo - Service Header, Service Lines for Item, G/L Account and Resource with 0 Quantity.
        // 2. Post the Credit Memo.
        // 3. Verify that the application generates an error as 'There is nothing to post'.

        // [GIVEN] Create Service Credit Memo by inserting Credit Memo Header and Service Credit Memo Lines.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        CreateServiceCreditMemoLine(ServiceHeader);

        // [WHEN] Post the Credit Memo.
        ExecuteConfirmHandlerInvoiceES();
        asserterror LibraryService.PostServiceOrder(ServiceHeader, false, false, false);

        // [THEN] Verify that the application generates an error as 'There is nothing to post'.
        Assert.AreEqual(StrSubstNo(DocumentErrorsMgt.GetNothingToPostErrorMsg()), GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('InvoiceESConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCreditMemoPostingFrGLAcct()
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // [SCENARIO] Create a new Credit Memo - Service Header, Service Lines for G/L Account with random Quantity. Post the Credit Memo.
        // 1. Create a new Credit Memo - Service Header, Service Lines for G/L Account with random Quantity.
        // 2. Post the Credit Memo.
        // 3. Verify that the Service Cr. Memo Line, G/L Entry, Detailed Cust. Ledger Entry and VAT Entry tables correspond to the
        // relevant Credit Memo Lines.

        // [GIVEN] Create Service Credit Memo by inserting Credit Memo Header and Service Credit Memo Lines.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        CreateServCrdtMmLnGLAccWithQty(ServiceHeader);

        // [WHEN] Save Service Credit Memo Lines in temporary table and post the Credit Memo.
        SaveServCreditMemoLinesInTemp(TempServiceLine, ServiceHeader);
        ExecuteConfirmHandlerInvoiceES();
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);

        // [THEN] Match the values in the Service Cr. Memo Line, G/L Entry, Detailed Cust. Ledger Entry and VAT Entry tables with the values in the Service Credit Memo Line.
        VerifyCrdtMmLnWthPstdCrdtMmLn(TempServiceLine);
        VerifyCreditMemoGLEntries(TempServiceLine);
        VerifyCreditMemoDetCustLedEnt(TempServiceLine);
        VerifyCreditMemoVATEntries(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('InvoiceESConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCreditMemoPostingForItem()
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // [SCENARIO] Create a new Credit Memo - Service Header, Service Lines for Item with random Quantity. Post the Credit Memo.
        // 1. Create a new Credit Memo - Service Header, Service Lines for Item with random Quantity.
        // 2. Post the Credit Memo.
        // 3. Verify that the Service Cr. Memo Line, G/L Entry, Detailed Cust. Ledger Entry and VAT Entry tables correspond to the
        // relevant Credit Memo Lines.

        // [GIVEN] Create Service Credit Memo by inserting Credit Memo Header and Service Credit Memo Lines.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        CreateServCrdtMmLneItemWithQty(ServiceHeader);

        // [WHEN] Save Service Credit Memo Lines in temporary table and post the Credit Memo.
        SaveServCreditMemoLinesInTemp(TempServiceLine, ServiceHeader);
        ExecuteConfirmHandlerInvoiceES();
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);

        // [THEN] Match the values in the Service Cr. Memo Line, G/L Entry, Detailed Cust. Ledger Entry, VAT Entry and Value Entry tables with the values in the Service Credit Memo Line.
        VerifyCrdtMmLnWthPstdCrdtMmLn(TempServiceLine);
        VerifyCreditMemoGLEntries(TempServiceLine);
        VerifyCreditMemoDetCustLedEnt(TempServiceLine);
        VerifyCreditMemoVATEntries(TempServiceLine);
        VerifyCreditMemoValueEntries(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('InvoiceESConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCreditMemoPostingFrResourc()
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // [SCENARIO] Post Service Credit Memo - Service Header, Service Lines for Resource with random Quantity
        // 1. Create a new Credit Memo - Service Header, Service Lines for Resource with random Quantity.
        // 2. Post the Credit Memo.
        // 3. Verify that the Service Cr. Memo Line, G/L Entry, Detailed Cust. Ledger Entry and VAT Entry tables correspond to the
        // relevant Credit Memo Lines.

        // [GIVEN] Create Service Credit Memo by inserting Credit Memo Header and Service Credit Memo Lines.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        CreateServCrdtMmLnRsrceWithQty(ServiceHeader);

        // [WHEN] Save Service Credit Memo Lines in temporary table and post the Credit Memo.
        SaveServCreditMemoLinesInTemp(TempServiceLine, ServiceHeader);
        ExecuteConfirmHandlerInvoiceES();
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);

        // [THEN] Match the values in the Service Cr. Memo Line, G/L Entry, Detailed Cust. Ledger Entry and VAT Entry tables with the values in the Service Credit Memo Line.
        VerifyCrdtMmLnWthPstdCrdtMmLn(TempServiceLine);
        VerifyCreditMemoGLEntries(TempServiceLine);
        VerifyCreditMemoDetCustLedEnt(TempServiceLine);
        VerifyCreditMemoVATEntries(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('InvoiceESConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCrditMemoPostingFrDiffType()
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // [SCENARIO] Post Service Credit Memo - Service Header, Service Lines for all Types with random Quantity.
        // 1. Create a new Credit Memo - Service Header, Service Lines for all Types with random Quantity.
        // 2. Post the Credit Memo.
        // 3. Verify that the Service Cr. Memo Line, G/L Entry, Detailed Cust. Ledger Entry and VAT Entry tables correspond to the
        // relevant Credit Memo Lines.

        // [GIVEN] Create Service Credit Memo by inserting Credit Memo Header and Service Credit Memo Lines.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        CreateServCrdtMmLnGLAccWithQty(ServiceHeader);
        CreateServCrdtMmLneItemWithQty(ServiceHeader);
        CreateServCrdtMmLnRsrceWithQty(ServiceHeader);

        // [WHEN] Save Service Credit Memo Lines in temporary table and post the Credit Memo.
        SaveServCreditMemoLinesInTemp(TempServiceLine, ServiceHeader);
        ExecuteConfirmHandlerInvoiceES();
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);

        // [THEN] Match the values in the Service Cr. Memo Line, G/L Entry, Detailed Cust. Ledger Entry and VAT Entry tables with the values in the Service Credit Memo Line.
        VerifyCrdtMmLnWthPstdCrdtMmLn(TempServiceLine);
        VerifyCreditMemoGLEntries(TempServiceLine);
        VerifyCreditMemoDetCustLedEnt(TempServiceLine);
        VerifyCreditMemoVATEntries(TempServiceLine);
        TempServiceLine.SetRange(Type, TempServiceLine.Type::Item);
        VerifyCreditMemoValueEntries(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('InvoiceESConfirmHandler,ApplyServCustEntrsModalFormHandler')]
    [Scope('OnPrem')]
    procedure TestCreditMemoAppToFieldsCrdMm()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Applies-to]
        // [SCENARIO]  "Applies-to ID" field on the Service Credit Header is filled in with the number of Service Credit Memo created
        // 1. Create and post Sales Credit Memo.
        // 2. Create a new Service Credit Memo - Service Header, Service Lines for all Types with random Quantity.
        // 3. Apply Customer Entries through Apply Entries function and select the Sales Credit Memo created for application.
        // 4. Verify that the Applies-to ID field on the Service Credit Memo Header is filled in with the number of the Service Credit Memo
        // created and the fields Applies-to Doc. Type and Applies-to Doc. No. are blank.

        // [GIVEN] Create and post Sales Credit Memo. Create Service Credit Memo by inserting Credit Memo Header and Service Credit Memo Lines.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateSalesCreditMemo(SalesHeader, Customer."No.");
        ExecuteConfirmHandlerInvoiceES();
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, false);

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", Customer."No.");
        CreateServCrdtMmLnGLAccWithQty(ServiceHeader);
        CreateServCrdtMmLneItemWithQty(ServiceHeader);
        CreateServCrdtMmLnRsrceWithQty(ServiceHeader);

        // [WHEN] Apply Customer Entries through Apply Entries function and select the Sales Credit Memo created for application.
        DocumentHeaderNo := DocumentNo;
        DocumentType := CustLedgerEntry."Document Type"::"Credit Memo";
        CODEUNIT.Run(CODEUNIT::"Service Header Apply", ServiceHeader);

        // [THEN] Check that Applies-to ID field on the Service Credit Header is filled in with the number of Service Credit Memo created
        // [THEN] the fields Applies-to Doc. Type and Applies-to Doc. No. are blank.
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        ServiceHeader.TestField("Applies-to ID", ServiceHeader."No.");
        ServiceHeader.TestField("Applies-to Doc. Type", ServiceHeader."Applies-to Doc. Type"::" ");
        ServiceHeader.TestField("Applies-to Doc. No.", '');
    end;

    [Test]
    [HandlerFunctions('ApplyServCustEntrsModalFormHandler,InvoiceESConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCreditMemoAppToFieldsInv()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Applies-to]
        // [SCENARIO] "Applies-to ..." fields on the Service Credit Header are filled correctly according to Sales Invoice created.
        // 1. Create and post Sales Invoice.
        // 2. Create a new Service Credit Memo - Service Header, Service Lines for all Types with random Quantity.
        // 3. Apply Customer Entries through Applies-to Doc. No. lookup and select the Sales Invoice created for application.
        // 4. Verify that the Applies-to Doc. No. field on Service Credit Memo Header is filled in with the number of the Invoice created.

        // [GIVEN] Create Service Credit Memo by inserting Credit Memo Header and Service Credit Memo Lines.
        Initialize();
        LibrarySales.CreateCustomer(Customer);

        CreateSalesInvoice(SalesHeader, Customer."No.");
        ExecuteConfirmHandlerInvoiceES();
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, false);

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", Customer."No.");
        UpdatePaymentMethodCode(ServiceHeader, Customer."Payment Method Code");
        CreateServCrdtMmLnGLAccWithQty(ServiceHeader);
        CreateServCrdtMmLneItemWithQty(ServiceHeader);
        CreateServCrdtMmLnRsrceWithQty(ServiceHeader);

        // [WHEN] Apply Customer Entries through Applies-to Doc No. lookup and select the Sales Credit Memo created for application.
        DocumentHeaderNo := DocumentNo;
        DocumentType := CustLedgerEntry."Document Type"::Invoice;
        ApplyCustLedgerEntries(ServiceHeader, DocumentNo, CustLedgerEntry."Document Type"::Invoice);

        // [THEN] Check that Applies-to fields on the Service Credit Header are filled correctly according to Sales Invoice created.
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        ServiceHeader.TestField("Applies-to Doc. Type", ServiceHeader."Applies-to Doc. Type"::Invoice);
        ServiceHeader.TestField("Applies-to Doc. No.", DocumentNo);
    end;

    [Test]
    [HandlerFunctions('ApplyServCustEntrsModalFormHandler,InvoiceESConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCreditMemoAppToCrMm()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Applies-to]
        // [SCENARIO] "Applies-to ..." fields on the Service Credit Header are filled correctly according to Sales Credit Memo created.
        // 1. Create and post Sales Credit Memo.
        // 2. Create a new Service Credit Memo - Service Header, Service Lines for all Types with random Quantity.
        // 3. Apply Customer Entries through Applies-to Doc. No. lookup and select the Sales Credit Memo created for application.
        // 4. Verify that the Applies-to Doc. No. field on Service Credit Memo Header is filled in with the number of Credit Memo created.

        // [GIVEN] Create Service Credit Memo by inserting Credit Memo Header and Service Credit Memo Lines.
        Initialize();
        LibrarySales.CreateCustomer(Customer);

        CreateSalesCreditMemo(SalesHeader, Customer."No.");
        ExecuteConfirmHandlerInvoiceES();
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, false);

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", Customer."No.");
        CreateServCrdtMmLnGLAccWithQty(ServiceHeader);
        CreateServCrdtMmLneItemWithQty(ServiceHeader);
        CreateServCrdtMmLnRsrceWithQty(ServiceHeader);

        // [WHEN] Apply Customer Entries through Applies-to Doc. No. lookup and select the Sales Credit Memo created for application.
        DocumentHeaderNo := DocumentNo;
        DocumentType := CustLedgerEntry."Document Type"::"Credit Memo";
        ApplyCustLedgerEntries(ServiceHeader, DocumentNo, CustLedgerEntry."Document Type"::"Credit Memo");

        // [THEN] Check that Applies-to fields on the Service Credit Header are filled correctly according to Sales Credit Memo created.
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        ServiceHeader.TestField("Applies-to Doc. Type", ServiceHeader."Applies-to Doc. Type"::"Credit Memo");
        ServiceHeader.TestField("Applies-to Doc. No.", DocumentNo);
    end;

    [Test]
    [HandlerFunctions('ApplyServCustEntrsModalFormHandler,InvoiceESConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCustLedgerEntryCorrection()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Item: Record Item;
        ServiceInvoiceHeader: Record "Service Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ServiceInvoiceAmount: Decimal;
        ServiceInvoiceQuantity: Decimal;
        ServiceInvoiceUnitPrice: Decimal;
    begin
        // [SCENARIO] "Remaining Amount" in the Customer Ledger Entry for posted Service Invoice is the difference of "Amount Including VAT" of the Service Invoice and the Amount Including VAT of the Service Credit Memo.
        // 1. Create and post a Service Invoice - create Service Header, Service Line.
        // 2. Create a new Service Credit Memo - Service Header, Service Lines for Type Item with Quantity equal to that of Service Invoice
        // Line and Unit Price less than that of Invoice.
        // 3. Apply Customer Entries through Apply Entries function and select the Service Invoice created for application. Post the
        // Service Credit Memo.
        // 4. Check that the Remaining Amount in the Customer Ledger Entry for posted Service Invoice is the difference of the Amount
        // Including VAT of the Service Invoice and the Amount Including VAT of the Service Credit Memo.

        // [GIVEN] Create and post a Service Invoice - Create Service Header, Service Line. Create Service Credit Memo - Service Header and
        // Service Line.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateItemWithPrice(Item);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");
        ServiceHeader.Validate("Prices Including VAT", true);
        ServiceHeader.Modify(true);

        CreateServiceLineWithRandomQty(ServiceLine, ServiceHeader, Item."No.");
        ServiceInvoiceAmount := ServiceLine."Amount Including VAT";
        ServiceInvoiceUnitPrice := ServiceLine."Unit Price";
        ServiceInvoiceQuantity := ServiceLine.Quantity;
        ExecuteConfirmHandlerInvoiceES();
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);

        ServiceInvoiceHeader.SetRange("Pre-Assigned No.", ServiceHeader."No.");
        ServiceInvoiceHeader.FindFirst();
        DocumentHeaderNo := ServiceInvoiceHeader."No.";
        DocumentType := CustLedgerEntry."Document Type"::Invoice;

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", Customer."No.");
        UpdatePaymentMethodCode(ServiceHeader, Customer."Payment Method Code");
        ServiceHeader.Validate("Prices Including VAT", true);
        ServiceHeader.Modify(true);

        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate(Quantity, ServiceInvoiceQuantity);  // Quantity of Credit Memo should be same as that of Invoice.
        // Validate Unit Price less than that of Invoice.
        ServiceLine.Validate("Unit Price", ServiceInvoiceUnitPrice - 1);
        ServiceLine.Modify(true);

        // [WHEN] Apply Customer Entries through Apply Entries function and select the Service Invoice created for application. Post the Service Credit Memo.
        CODEUNIT.Run(CODEUNIT::"Service Header Apply", ServiceHeader);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");  // Get refreshed instance.
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);

        // [THEN] Check that the Remaining Amount in the Customer Ledger Entry for posted Service Invoice is the difference of
        // [THEN] the Amount Including VAT of the Service Invoice and the Amount Including VAT of the Service Credit Memo.
        VerifyCustLedgEntryRemAmount(ServiceInvoiceHeader."No.", ServiceLine."Amount Including VAT", ServiceInvoiceAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreditMemoPostWithCorrection()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Correction]
        // [SCENARIO 356056] G/L entries posted as "Correction" by Credit Memo - Service Header, Service Lines for G/L Account.
        // 1. Create a new Credit Memo - Service Header, Service Lines for G/L Account.
        // 2. Verify that the application posts negative debit and credit amounts for corrective entries

        // [GIVEN] Set Credit Memo As "Correction"
        Initialize();
        SetCreditMemoAsCorrection();

        // [WHEN] Create Service Credit Memo by inserting Credit Memo Header and Service Credit Memo Lines.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceLine(
          ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());
        ServiceLine.Validate(Quantity, 1);
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        ServiceLine.Modify(true);

        // [WHEN] Post the Credit Memo.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Verify that the G/L entries posted as "Correction"
        VerifyCreditMemoCorrectionGLEntries(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure MatchAmountCreditMemoInvoice()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        SignServContractDoc: Codeunit SignServContractDoc;
        CreditMemoNo: Code[20];
    begin
        // [SCENARIO 158079] Service credit memo provides same amounts as invoiced amounts when created from same service contract.

        // [GIVEN] Create and sign Service Contract.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine);
        SignServContractDoc.SignContract(ServiceContractHeader);

        // [WHEN] Post the Service Invoice. Create Service Credit Memo from Contract. Post the Credit Memo.
        PostServiceInvoice(ServiceContractHeader."Contract No.");
        CreditMemoNo := CreateContractLineCreditMemo(ServiceContractLine);

        ServiceHeader.Get(ServiceHeader."Document Type"::"Credit Memo", CreditMemoNo);
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);

        // [THEN] Match the values in the Service Credit Memo Line with the values in the Service Contract Line.
        // [THEN] Match the Amount in Service Invoice and Credit Memo.
        VerifyCreditMemoWithContract(ServiceContractHeader."Contract No.");
        VerifyAmountInvoiceCreditMemo(ServiceContractHeader."Contract No.");
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CreditLimitWarningOnOrder()
    var
        Customer: Record Customer;
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ServiceHeader: Record "Service Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        CreditWarnings: Option;
    begin
        // [SCENARIO 158079] The application creates credit limit warning when creating a service order on the Customer Card.

        // [GIVEN] Setup Credit Warning field on Sales and Receivables Setup. Create Customer, Service Order for the Customer.
        Initialize();
        SalesReceivablesSetup.Get();
        CreditWarnings := SalesReceivablesSetup."Credit Warnings";
        SalesReceivablesSetup.Validate("Credit Warnings", SalesReceivablesSetup."Credit Warnings"::"Both Warnings");
        SalesReceivablesSetup.Modify(true);
        LibrarySales.CreateCustomer(Customer);
        CreateServiceOrder(ServiceHeader, Customer."No.");

        // [WHEN] Post the Service Order as Ship and Invoice.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Creating Service Order with same Customer creates credit limit warning handled by Form Handler.
        Clear(ServiceHeader);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");

        // 4. TearDown: Reset the value of Credit Warning field on Sales and Receivables Setup.
        SalesReceivablesSetup.Validate("Credit Warnings", CreditWarnings);
        SalesReceivablesSetup.Modify(true);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse,MessageHandler,ReportHandlerContractInvoice')]
    [Scope('OnPrem')]
    procedure ContractInvoiceReport()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
        CreateInvoices: Option "Create Invoices","Print Only";
    begin
        // [SCENARIO 160852] Contract Invoice Report run successfully from Create Contract Invoices Report.

        // [GIVEN] Create and Sign Service Contract.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine);
        SignServContractDoc.SignContract(ServiceContractHeader);

        // set Global Variable for Report Handler.
        ContractNo := ServiceContractHeader."Contract No.";
        Commit();

        // [WHEN] Run Report Create Service Invoice with Print Only Option and Save Service Invoice Report automatically run from it.
        CreateServiceInvoiceFromReport(ServiceContractHeader."Contract No.", CreateInvoices::"Print Only");

        // [THEN] Verify that Saved Report have some data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceByContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // [SCENARIO 168064] "Customer No." and "Line Amount" in Service Invoice Header and Line after posting Service Invoice with the line copied from Service Contract.

        // [GIVEN] Create and sign Service Contract, get and copy Service Lines.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine);
        SignServContractDoc.SignContract(ServiceContractHeader);
        GetServiceLinesFromContract(ServiceLine, ServiceContractHeader."Contract No.");
        CopyServiceLines(ServiceLine, TempServiceLine);

        // [WHEN] Post the Service Invoice.
        PostServiceInvoice(ServiceContractHeader."Contract No.");

        // [THEN] Verify the Customer and Line Amount in Service Invocie Header and Service Invoice Line.
        VerifyServiceInvoiceHeaderLine(TempServiceLine, ServiceContractHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoCreationError()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // [SCENARIO 172908] Error occurs on Creation of Service Credit Memo from Service Contract having Unposted Service Invoices.

        // [GIVEN] Create and sign Service Contract.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine);
        SignServContractDoc.SignContract(ServiceContractHeader);

        // [WHEN] Create Service Credit Memo from Service Contract.
        asserterror CreateContractLineCreditMemo(ServiceContractLine);

        // [THEN] Verify error occurs "Service Credit Memo cannot be created".
        Assert.AreEqual(
          StrSubstNo(CreditMemoError, ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No."),
          GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse,MessageHandler')]
    [Scope('OnPrem')]
    procedure InvoiceCreationError()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
        ServContractManagement: Codeunit ServContractManagement;
    begin
        // [SCENARIO 172908] Error occurs on Creation of Service Invoice from Service Contract having Unposted Service Credit Memo.

        // [GIVEN] Create and sign Service Contract, Post the Service Invoice.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine);
        SignServContractDoc.SignContract(ServiceContractHeader);

        PostServiceInvoice(ServiceContractHeader."Contract No.");

        // [WHEN] Create Service Credit Memo from Service Contract and Create Service Invoice.
        CreateContractLineCreditMemo(ServiceContractLine);

        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServContractManagement.InitCodeUnit();
        asserterror ServContractManagement.CreateInvoice(ServiceContractHeader);

        // [THEN] Verify error occurs "Invoice cannot be created".
        Assert.AreEqual(StrSubstNo(InvoiceError), GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure FieldsOnServiceLedgerEntry()
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // [SCENARIO 235040] Posting a Service Credit Memo with a Service Lines of Type Item and Resource with Contract No.

        // [GIVEN] Create and sign Service Contract. Post the Service Invoice.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine);
        SignServContractDoc.SignContract(ServiceContractHeader);
        PostServiceInvoice(ServiceContractHeader."Contract No.");

        // [WHEN] Create and Post the Service Credit Memo using the Contract No.
        LibraryService.CreateServiceHeader(
          ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", ServiceContractHeader."Customer No.");
        CreateCreditMemoItemLine(ServiceHeader, ServiceContractHeader."Contract No.");
        CreateCreditMemoResourceLine(ServiceHeader, ServiceContractHeader."Contract No.");
        SaveServCreditMemoLinesInTemp(TempServiceLine, ServiceHeader);
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);

        // [THEN] Verify program populates correct values on Service Ledger Entry after posting service credit memos with Contracts No.
        // [THEN] Verify that the G/L Entry created correspond with the relevant Service Credit Memo Lines.
        VerifyCreditMemoServiceLedger(TempServiceLine);
        VerifyCreditMemoGLEntries(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoCheckItemLedgerEntry()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
        ServiceCreditMemo: TestPage "Service Credit Memo";
        No: Code[20];
        CustomerNo: Code[20];
        Quantity: Decimal;
    begin
        // [SCENARIO 143443] Create Service Credit Memo, post it and verify Item Ledger Entry.

        // [GIVEN] Find Item, create Service Contract, sign it and create Customer without Price Including VAT.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateServiceContract(ServiceContractHeader, ServiceContractLine);
        SignServContractDoc.SignContract(ServiceContractHeader);
        CustomerNo := CustomerWithPriceIncludingVAT(false);

        // [WHEN] Create Service Credit Memo with Contract No and post it.
        No := LibraryService.CreateServiceCreditMemoHeaderUsingPage();
        CreateCreditMemoLine(No, CustomerNo, ServiceLine.Type::Item, Item."No.");
        InsertContractNoOnServiceLine(No, ServiceContractHeader."Contract No.");
        ServiceCreditMemoOpenEdit(ServiceCreditMemo, No);
        Quantity := ServiceCreditMemo.ServLines.Quantity.AsDecimal();
        ServiceCreditMemo.Post.Invoke();

        // [THEN] Verify the Item Ledger Entry for the posted Service Credit Memo.
        VerifyServiceCreditMemoItemLedgerEntry(No, Item."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoTypeCost()
    var
        ServiceLine: Record "Service Line";
        ServiceCost: Record "Service Cost";
        ServiceCreditMemo: TestPage "Service Credit Memo";
        No: Code[20];
        CustomerNo: Code[20];
        Quantity: Decimal;
    begin
        // [SCENARIO 143443] Create Service Credit Memo for Type Cost, post it and verify the Service Ledger Entries.

        // [GIVEN] Find Service Cost, create Customer without Price Including VAT.
        Initialize();
        LibraryService.FindServiceCost(ServiceCost);
        CustomerNo := CustomerWithPriceIncludingVAT(false);

        // [WHEN] Create Service Credit Memo and post it.
        No := LibraryService.CreateServiceCreditMemoHeaderUsingPage();
        CreateCreditMemoLine(No, CustomerNo, ServiceLine.Type::Cost, ServiceCost.Code);
        ServiceCreditMemoOpenEdit(ServiceCreditMemo, No);
        Quantity := ServiceCreditMemo.ServLines.Quantity.AsDecimal();
        ServiceCreditMemo.Post.Invoke();

        // [THEN] Verify the Service Ledger Entries for the posted Service Credit Memo.
        VerifyCreditMemoServiceLedgerEntry(No, CustomerNo, ServiceCost.Code, Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoTypeGLAccount()
    var
        GLAccount: Record "G/L Account";
        ServiceLine: Record "Service Line";
        ServiceCreditMemo: TestPage "Service Credit Memo";
        No: Code[20];
        CustomerNo: Code[20];
        Quantity: Decimal;
    begin
        // [SCENARIO 143443] Create Service Credit Memo for Type GL Account, post it and verify the Service Ledger Entries.

        // [GIVEN] Find GL Account with Direct Posting True, create Customer with Price Including VAT.
        Initialize();
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        CustomerNo := CustomerWithPriceIncludingVAT(true);

        // [WHEN] Create Service Credit Memo and post it.
        No := LibraryService.CreateServiceCreditMemoHeaderUsingPage();
        CreateCreditMemoLine(No, CustomerNo, ServiceLine.Type::"G/L Account", GLAccount."No.");
        ServiceCreditMemoOpenEdit(ServiceCreditMemo, No);
        Quantity := ServiceCreditMemo.ServLines.Quantity.AsDecimal();
        ServiceCreditMemo.Post.Invoke();

        // [THEN] Verify the Service Ledger Entries for the posted Service Credit Memo.
        VerifyCreditMemoServiceLedgerEntry(No, CustomerNo, GLAccount."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoTypeItem()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        ServiceCreditMemo: TestPage "Service Credit Memo";
        No: Code[20];
        CustomerNo: Code[20];
        Quantity: Decimal;
    begin
        // [SCENARIO 143443] Create Service Credit Memo for Type Item, post it and verify the Service Ledger Entries.

        // [GIVEN] Find Item, create Customer with Price Including VAT.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CustomerNo := CustomerWithPriceIncludingVAT(true);

        // [WHEN] Create Service Credit Memo and post it.
        No := LibraryService.CreateServiceCreditMemoHeaderUsingPage();
        CreateCreditMemoLine(No, CustomerNo, ServiceLine.Type::Item, Item."No.");
        ServiceCreditMemoOpenEdit(ServiceCreditMemo, No);
        Quantity := ServiceCreditMemo.ServLines.Quantity.AsDecimal();
        ServiceCreditMemo.Post.Invoke();

        // [THEN] Verify the Service Ledger Entries for the posted Service Credit Memo.
        VerifyCreditMemoServiceLedgerEntry(No, CustomerNo, Item."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoTypeResource()
    var
        ServiceLine: Record "Service Line";
        ServiceCreditMemo: TestPage "Service Credit Memo";
        No: Code[20];
        CustomerNo: Code[20];
        ResourceNo: Code[20];
        Quantity: Decimal;
    begin
        // [SCENARIO 143443] Create Service Credit Memo for Type Resource, post it and verify the Service Ledger Entries.

        // [GIVEN] Create Resource, create Customer with Price Including VAT.
        Initialize();
        ResourceNo := LibraryResource.CreateResourceNo();
        CustomerNo := CustomerWithPriceIncludingVAT(true);

        // [WHEN] Create Service Credit Memo and post it.
        No := LibraryService.CreateServiceCreditMemoHeaderUsingPage();
        CreateCreditMemoLine(No, CustomerNo, ServiceLine.Type::Resource, ResourceNo);
        ServiceCreditMemoOpenEdit(ServiceCreditMemo, No);
        Quantity := ServiceCreditMemo.ServLines.Quantity.AsDecimal();
        ServiceCreditMemo.Post.Invoke();

        // [THEN] Verify the Service Ledger Entries for the posted Service Credit Memo.
        VerifyCreditMemoServiceLedgerEntry(No, CustomerNo, ResourceNo, Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoByPage()
    var
        Customer: Record Customer;
        Item: Record Item;
        ServiceLine: Record "Service Line";
        ServiceCreditMemo: TestPage "Service Credit Memo";
        No: Code[20];
        Quantity: Decimal;
    begin
        // [SCENARIO 143444] Create and Post Service Credit Memo and Validate Posted Service Credit Memo Line.

        // [GIVEN] Create Customer.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);

        // [WHEN] Create Service Credit Memo and Post.
        No := LibraryService.CreateServiceCreditMemoHeaderUsingPage();
        CreateCreditMemoLine(No, Customer."No.", ServiceLine.Type::Item, Item."No.");
        ServiceCreditMemoOpenEdit(ServiceCreditMemo, No);
        Quantity := ServiceCreditMemo.ServLines.Quantity.AsDecimal();
        ServiceCreditMemo.Post.Invoke();

        // [THEN] Check Posted Service Credit Memo Line.
        VerifyPostedServiceCreditMemoLine(Customer."No.", ServiceLine.Type::Item, Item."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('PostedServiceCrMemoPH')]
    [Scope('OnPrem')]
    procedure ShowPostedDocumentForPostedServiceCrMemo()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ServiceHeaderNo: Code[20];
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 377063] Posted Service Credit Memo is shown after "Show Posted Document" action from customer ledger entry

        // [GIVEN] Posted Service Credit Memo
        ServiceHeaderNo := CreatePostServiceCrMemo();
        FindServiceCrMemoHeader(ServiceCrMemoHeader, ServiceHeaderNo);

        // [GIVEN] Customer ledger entry linked to the posted Service Credit Memo
        FindCustLedgEntry(CustLedgerEntry, ServiceCrMemoHeader."No.", ServiceCrMemoHeader."Customer No.");

        // [WHEN] Perform "Show Posted Document" action
        // [THEN] Page "Posted Service Credit Memo" is opened for the posted Service Credit Memo
        // [THEN] CustLedgerEntry.ShowDoc() return TRUE
        LibraryVariableStorage.Enqueue(ServiceCrMemoHeader."No."); // used in PostedServiceInvoicePH
        LibraryVariableStorage.Enqueue(ServiceCrMemoHeader."Customer No."); // used in PostedServiceInvoicePH
        Assert.IsTrue(CustLedgerEntry.ShowDoc(), ServiceCrMemoHeader.TableCaption());
        // Verify values in PostedServiceCrMemoPH
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoControlsDisabledBeforeCustomerSelected()
    var
        LibraryApplicationArea: Codeunit "Library - Application Area";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [UI]
        // [Scenario]  Actions on Sales Quote Page not enabled if no customer selected
        Initialize();

        // [WHEN] Sales Quote page is opened on SaaS
        SalesCreditMemo.OpenNew();

        // [THEN] All controls related to customer (and on SaaS) are disabled
#if not CLEAN26
        Assert.IsFalse(SalesCreditMemo.Statistics.Enabled(), ControlShouldBeDisabledErr);
#endif
        Assert.IsFalse(SalesCreditMemo.SalesStatistics.Enabled(), ControlShouldBeDisabledErr);
        Assert.IsFalse(SalesCreditMemo.CalculateInvoiceDiscount.Enabled(), ControlShouldBeDisabledErr);
        Assert.IsFalse(SalesCreditMemo.ApplyEntries.Enabled(), ControlShouldBeDisabledErr);
        Assert.IsFalse(SalesCreditMemo.TestReport.Enabled(), ControlShouldBeDisabledErr);
        Assert.IsFalse(SalesCreditMemo.GetStdCustSalesCodes.Enabled(), ControlShouldBeDisabledErr);

        SalesCreditMemo.Close();

        // [WHEN] Sales Quotes page is opened with no application area
        LibraryApplicationArea.DisableApplicationAreaSetup();
        SalesCreditMemo.OpenNew();

        // [THEN] All controls related to customer (and not on SaaS) are disabled
        Assert.IsFalse(SalesCreditMemo.Release.Enabled(), ControlShouldBeDisabledErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoControlsEnabledAfterCustomerSelected()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        LibraryApplicationArea: Codeunit "Library - Application Area";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [UI]
        // [Scenario]  Actions on Sales Quote Page are enabled if customer selected
        Initialize();

        // [GIVEN] A sample sales credit memo
        LibrarySales.CreateCustomer(Customer);
        CreateSalesCreditMemo(SalesHeader, Customer."No.");

        // [WHEN] Sales credit memo page is opened on SaaS
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.GotoRecord(SalesHeader);

        // [THEN] All controls related to customer (and on SaaS) are enabled
#if not CLEAN26
        Assert.IsTrue(SalesCreditMemo.Statistics.Enabled(), ControlShouldBeEnabledErr);
#endif
        Assert.IsTrue(SalesCreditMemo.SalesStatistics.Enabled(), ControlShouldBeEnabledErr);
        Assert.IsTrue(SalesCreditMemo.CalculateInvoiceDiscount.Enabled(), ControlShouldBeEnabledErr);
        Assert.IsTrue(SalesCreditMemo.ApplyEntries.Enabled(), ControlShouldBeEnabledErr);
        Assert.IsTrue(SalesCreditMemo.TestReport.Enabled(), ControlShouldBeEnabledErr);
        Assert.IsTrue(SalesCreditMemo.GetStdCustSalesCodes.Enabled(), ControlShouldBeEnabledErr);

        SalesCreditMemo.Close();

        // [WHEN] Sales Quotes page is opened with no application area
        LibraryApplicationArea.DisableApplicationAreaSetup();
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.GotoRecord(SalesHeader);

        // [THEN] All controls related to customer (and not on SaaS) are enabled
        Assert.IsTrue(SalesCreditMemo.Release.Enabled(), ControlShouldBeEnabledErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourceUsageEntryPostedInResourceLedgerOnCreditMemo()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ResLedgerEntry: Record "Res. Ledger Entry";
    begin
        // [FEATURE] [Resource] [Usage] [Credit Memo]
        // [SCENARIO 230230] Negative resource usage entry should be created in the resource ledger when posting a service credit memo for a resource

        Initialize();

        // [GIVEN] Service credit memo for a resource "R". "Quantity" = 5, "Unit Price" = 8
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, LibraryResource.CreateResourceNo());
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(20));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandIntInRange(100, 200));
        ServiceLine.Modify(true);

        // [WHEN] Post the credit memo
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);

        // [THEN] Resource ledger entry with type "Usage" is created. Quantity = -5, "Total Price" = -40
        ResLedgerEntry.SetRange("Resource No.", ServiceLine."No.");
        ResLedgerEntry.SetRange("Entry Type", ResLedgerEntry."Entry Type"::Usage);
        ResLedgerEntry.FindFirst();
        ResLedgerEntry.TestField(Quantity, -ServiceLine.Quantity);
        ResLedgerEntry.TestField("Total Price", -ServiceLine.Quantity * ServiceLine."Unit Price");
        ResLedgerEntry.TestField("Document No.", ServiceHeader."Last Posting No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse,MessageHandler,RemoveLinesFromContractRequestHandler')]
    [Scope('OnPrem')]
    procedure VerifyCrdtMemoUnitPriceCreatedFrmRemovalOfExpiredContractLine()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceContractLine2: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        LockOpenServContract: Codeunit "Lock-OpenServContract";
        ServContractManagement: Codeunit ServContractManagement;
        SignServContractDoc: Codeunit SignServContractDoc;
        ExpirationDate: Date;
        ExpectedAmount: Decimal;
    begin
        //[SCENARIO 565322] Service Contract - Issue in auto creation of Credit Memo when Removal of expired line is done
        Initialize();

        // [GIVEN] Create Service Contract with Automatic Credit Memos as TRUE.
        CreateServiceContract(ServiceContractHeader, ServiceContractLine);
        ServiceContractHeader.Validate("Starting Date", CalcDate('<-CM>', WorkDate()));  // Validate first date of month.
        ServiceContractHeader.Validate("First Service Date", CalcDate('<-CM>', WorkDate()));
        ServiceContractHeader.Validate("Automatic Credit Memos", true);
        ServiceContractHeader.Modify(true);

        // [GIVEN] Sign Service Contract and Create and Post Service Invoice.
        SignServContractDoc.SignContract(ServiceContractHeader);
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServContractManagement.InitCodeUnit();
        ServContractManagement.CreateInvoice(ServiceContractHeader);
        PostServiceInvoice(ServiceContractHeader."Contract No.");

        // [GIVEN] Change "Expiration Date" on First Line .
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        LockOpenServContract.OpenServContract(ServiceContractHeader);
        FindServiceContractLines(ServiceContractLine2, ServiceContractHeader);
        ExpirationDate := ServiceContractHeader."Starting Date";
        ServiceContractLine2.Validate("Credit Memo Date", ExpirationDate);
        ServiceContractLine2.Validate("Contract Expiration Date", ExpirationDate);
        ServiceContractLine2.Validate("Invoiced to Date", ExpirationDate);
        ServiceContractLine2.Modify(true);
        Commit();

        // [WHEN] Create Service Credit Memo by running Remove Lines from Contract report.
        LibraryVariableStorage.Enqueue(ServiceContractLine2."Contract Expiration Date");
        Report.Run(Report::"Remove Lines from Contract", true, false, ServiceContractLine2);

        ExpectedAmount :=
              Round(
                ServContractManagement.CalcContractLineAmount(
                ServiceContractLine2."Line Amount", ServiceContractLine2."Starting Date", ServiceContractLine2."Contract Expiration Date"));

        // [THEN] Verify the values in the Service Credit Memo Line with the Expected.
        FindServiceCreditMemo(ServiceHeader, ServiceContractHeader."Contract No.");
        VerifyCrdtMemoUnitPriceOfExpiredContractLine(ServiceHeader."No.", ExpectedAmount);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Posting - Credit Memo");
        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Posting - Credit Memo");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Posting - Credit Memo");
    end;

    local procedure ApplyCustLedgerEntries(var ServiceHeader: Record "Service Header"; SalesInvoiceHeaderNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ServApplyCustomerEntries: Page "Serv. Apply Customer Entries";
    begin
        CustLedgerEntry.SetRange("Document Type", DocumentType);
        CustLedgerEntry.SetRange("Document No.", SalesInvoiceHeaderNo);
        CustLedgerEntry.FindFirst();

        Clear(ServApplyCustomerEntries);
        ServApplyCustomerEntries.SetService(ServiceHeader, CustLedgerEntry, ServiceHeader.FieldNo("Applies-to Doc. No."));
        ServApplyCustomerEntries.SetTableView(CustLedgerEntry);
        ServApplyCustomerEntries.SetRecord(CustLedgerEntry);
        ServApplyCustomerEntries.LookupMode(true);
        if ServApplyCustomerEntries.RunModal() = ACTION::LookupOK then begin
            ServApplyCustomerEntries.GetCustLedgEntry(CustLedgerEntry);
            ServiceHeader."Applies-to Doc. Type" := CustLedgerEntry."Document Type";
            ServiceHeader."Applies-to Doc. No." := CustLedgerEntry."Document No.";
            ServiceHeader.Modify(true);
        end;
    end;

    local procedure CopyServiceLines(var FromServiceLine: Record "Service Line"; var ToTempServiceLine: Record "Service Line" temporary)
    begin
        if FromServiceLine.FindSet() then
            repeat
                ToTempServiceLine.Init();
                ToTempServiceLine := FromServiceLine;
                ToTempServiceLine.Insert();
            until FromServiceLine.Next() = 0
    end;

    local procedure CreateContractLineCreditMemo(var ServiceContractLine: Record "Service Contract Line") CreditMemoNo: Code[20]
    var
        ServContractManagement: Codeunit ServContractManagement;
    begin
        ServiceContractLine.SetRange("Contract Type", ServiceContractLine."Contract Type");
        ServiceContractLine.SetRange("Contract No.", ServiceContractLine."Contract No.");
        ServiceContractLine.FindSet();
        ServContractManagement.InitCodeUnit();
        repeat
            CreditMemoNo := ServContractManagement.CreateContractLineCreditMemo(ServiceContractLine, false);
        until ServiceContractLine.Next() = 0;
        exit(CreditMemoNo);
    end;

    local procedure CreateItemWithPrice(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);
    end;

    local procedure CreateSalesCreditMemo(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        // Create Sales Header and Sales Line with any random Quantity and Qty. to Ship as 0.
        CreateItemWithPrice(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        SalesLine.Validate("Qty. to Ship", 0);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        // Create Sales Header and Sales Line with any random Quantity.
        CreateItemWithPrice(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
    end;

    local procedure CreateServiceContract(var ServiceContractHeader: Record "Service Contract Header"; var ServiceContractLine: Record "Service Contract Line")
    var
        Customer: Record Customer;
    begin
        // Create Service Contract Header, Service Contract Line and validate Annual Amount and Starting Date in Service Contract Header.
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);

        ServiceContractHeader.CalcFields("Calcd. Annual Amount");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractHeader."Calcd. Annual Amount");
        ServiceContractHeader.Validate("Starting Date", ServiceContractHeader."Starting Date");
        ServiceContractHeader.Modify(true);
    end;

    local procedure CreateServiceContractLine(var ServiceContractLine: Record "Service Contract Line"; ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceItem: Record "Service Item";
        Counter: Integer;
    begin
        // Create 2 to 10 Service Contract Lines - Boundary 2 is important.
        for Counter := 1 to LibraryRandom.RandIntInRange(2, 10) do begin
            Clear(ServiceItem);
            LibraryService.CreateServiceItem(ServiceItem, ServiceContractHeader."Customer No.");
            LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
            ServiceContractLine.Validate("Line Value", LibraryRandom.RandDecInRange(3, 1000, 2));  // Validate any value greater than 3 as minimum value should be 3.
            ServiceContractLine.Validate("Service Period", ServiceContractHeader."Service Period");
            ServiceContractLine.Validate("Contract Expiration Date", ServiceContractHeader."Starting Date");
            ServiceContractLine.Modify(true);
        end;
    end;

    local procedure CreateServiceCreditMemoLine(ServiceHeader: Record "Service Header")
    begin
        CreateServCreditMemoLineItem(ServiceHeader);
        CreateServCreditMemoLineGLAcc(ServiceHeader);
        CreateServCreditMemoLineResrce(ServiceHeader);
    end;

    local procedure CreateServiceInvoiceFromReport(ContractNo: Code[20]; CreateInvoices: Option)
    var
        ServiceContractHeader: Record "Service Contract Header";
        CreateContractInvoices: Report "Create Contract Invoices";
    begin
        ServiceContractHeader.SetRange("Contract No.", ContractNo);
        ServiceContractHeader.FindFirst();
        CreateContractInvoices.SetTableView(ServiceContractHeader);
        CreateContractInvoices.SetOptions(WorkDate(), ServiceContractHeader."Next Invoice Date", CreateInvoices);
        CreateContractInvoices.UseRequestPage(false);
        CreateContractInvoices.RunModal();
    end;

    local procedure CreateServiceOrder(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20])
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Create Service Item, Create Service Header, Service Item Line and Service Line of Type Item.
        LibraryService.CreateServiceItem(ServiceItem, CustomerNo);
        CreateItemWithPrice(Item);
        ServiceItem.Validate("Item No.", Item."No.");
        ServiceItem.Modify(true);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateServiceLine(ServiceHeader, ServiceItem."Item No.");
    end;

    local procedure CreatePostServiceCrMemo(): Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        CreateServiceLineWithRandomQty(ServiceLine, ServiceHeader, LibraryInventory.CreateItemNo());
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        exit(ServiceHeader."No.");
    end;

    local procedure LineWithQuantityAndUnitPrice(var ServiceLine: Record "Service Line")
    begin
        // Using the Random function because value is not important.
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        ServiceLine.Modify(true);
    end;

    local procedure CreateCreditMemoResourceLine(ServiceHeader: Record "Service Header"; ContractNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, LibraryResource.CreateResourceNo());
        ServiceLine.Validate("Contract No.", ContractNo);
        LineWithQuantityAndUnitPrice(ServiceLine);
    end;

    local procedure CreateCreditMemoItemLine(ServiceHeader: Record "Service Header"; ContractNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        ServiceLine.Validate("Contract No.", ContractNo);
        LineWithQuantityAndUnitPrice(ServiceLine);
    end;

    local procedure CreateServCreditMemoLineItem(ServiceHeader: Record "Service Header")
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        Counter: Integer;
    begin
        // Create 2 to 10 Service Lines - Boundary 2 is important.
        CreateItemWithPrice(Item);
        for Counter := 1 to LibraryRandom.RandIntInRange(2, 10) do begin
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
            ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
            ServiceLine.Modify(true);
            Item.Next();
        end;
    end;

    local procedure CreateServCrdtMmLneItemWithQty(ServiceHeader: Record "Service Header")
    var
        Items: Array[10] of Record Item;
        ServiceLine: Record "Service Line";
        Counter: Integer;
        N: Integer;
    begin
        N := LibraryRandom.RandIntInRange(2, 10);

        for Counter := 1 to N do
            CreateItemWithPrice(Items[N]);

        // Create 2 to 10 Service Lines - Boundary 2 is important.
        for Counter := 1 to N do begin
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Items[N]."No.");
            LineWithQuantityAndUnitPrice(ServiceLine);
        end;
    end;

    local procedure CreateServCreditMemoLineGLAcc(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
        GLAccountNo: Code[20];
        Counter: Integer;
    begin
        // Create 2 to 10 Service Lines - Boundary 2 is important.
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        for Counter := 1 to LibraryRandom.RandIntInRange(2, 10) do begin
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", GLAccountNo);
            ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
            ServiceLine.Modify(true);
        end;
    end;

    local procedure CreateServCrdtMmLnGLAccWithQty(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
        GLAccountNo: Code[20];
        Counter: Integer;
    begin
        // Create 2 to 10 Service Lines - Boundary 2 is important.
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        for Counter := 1 to LibraryRandom.RandIntInRange(2, 10) do begin
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", GLAccountNo);
            LineWithQuantityAndUnitPrice(ServiceLine);
        end;
    end;

    local procedure CreateServCreditMemoLineResrce(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
        Counter: Integer;
        ResourceNo: Code[20];
    begin
        // Create 2 to 10 Service Lines - Boundary 2 is important.
        ResourceNo := LibraryResource.CreateResourceNo();
        for Counter := 1 to LibraryRandom.RandIntInRange(2, 10) do begin
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, ResourceNo);
            ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
            ServiceLine.Modify(true);
        end;
    end;

    local procedure CreateServCrdtMmLnRsrceWithQty(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
        Counter: Integer;
        ResourceNo: Code[20];
    begin
        // Create 2 to 10 Service Lines - Boundary 2 is important.
        ResourceNo := LibraryResource.CreateResourceNo();
        for Counter := 1 to LibraryRandom.RandIntInRange(2, 10) do begin
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, ResourceNo);
            LineWithQuantityAndUnitPrice(ServiceLine);
        end;
    end;

    local procedure CreateServiceLine(ServiceHeader: Record "Service Header"; No: Code[20])
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        ServiceItemLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceItemLine.FindFirst();
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, No);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        LineWithQuantityAndUnitPrice(ServiceLine);
    end;

    local procedure CreateServiceLineWithRandomQty(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ItemNo: Code[20])
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Required field - value is not important to test case.
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        ServiceLine.Modify(true);
    end;

    local procedure ExecuteConfirmHandlerInvoiceES()
    begin
        if Confirm(StrSubstNo(ExpectedConfirm)) then;
    end;

    local procedure FindServiceContractLines(var ServiceContractLine: Record "Service Contract Line"; ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractLine.SetRange("Contract Type", ServiceContractHeader."Contract Type");
        ServiceContractLine.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceContractLine.FindSet();
    end;

    local procedure FindServiceCreditMemo(var ServiceHeader: Record "Service Header"; ServiceContractNo: Code[20])
    begin
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::"Credit Memo");
        ServiceHeader.SetRange("Contract No.", ServiceContractNo);
        ServiceHeader.FindFirst();
    end;

    local procedure FindServiceCrMemoHeader(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; PreAssignedNo: Code[20])
    begin
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        ServiceCrMemoHeader.FindFirst();
    end;

    local procedure FindCustLedgEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentNo: Code[20]; CustomerNo: Code[20])
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindFirst();
    end;

    local procedure GetPrepaidContractEntry(ServiceHeader: Record "Service Header"; ServiceContractNo: Code[20])
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        GetPrepaidContractEntries: Report "Get Prepaid Contract Entries";
    begin
        GetPrepaidContractEntries.UseRequestPage(false);
        GetPrepaidContractEntries.Initialize(ServiceHeader);
        ServiceLedgerEntry.SetRange("Service Contract No.", ServiceContractNo);
        GetPrepaidContractEntries.SetTableView(ServiceLedgerEntry);
        GetPrepaidContractEntries.RunModal();
    end;

    local procedure GetServiceLinesFromContract(var ServiceLine: Record "Service Line"; ContractNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Invoice);
        ServiceHeader.SetRange("Contract No.", ContractNo);
        ServiceHeader.FindFirst();
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindSet();
    end;

    local procedure PostServiceInvoice(ServiceContractNo: Code[20])
    var
        ServiceDocumentRegister: Record "Service Document Register";
        ServiceHeader: Record "Service Header";
    begin
        // Find the Service Invoice by searching in Service Document Register.
        ServiceDocumentRegister.SetRange("Source Document Type", ServiceDocumentRegister."Source Document Type"::Contract);
        ServiceDocumentRegister.SetRange("Source Document No.", ServiceContractNo);
        ServiceDocumentRegister.SetRange("Destination Document Type", ServiceDocumentRegister."Destination Document Type"::Invoice);
        ServiceDocumentRegister.FindFirst();
        ServiceHeader.Get(ServiceHeader."Document Type"::Invoice, ServiceDocumentRegister."Destination Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);
    end;

    local procedure RemoveLinesFromContract(var ServiceContractLine: Record "Service Contract Line")
    begin
        ServiceContractLine.SetRange("Contract Type", ServiceContractLine."Contract Type");
        ServiceContractLine.SetRange("Contract No.", ServiceContractLine."Contract No.");
        REPORT.RunModal(REPORT::"Remove Lines from Contract", false, true, ServiceContractLine);
    end;

    local procedure RemoveLinesFromContractFrOneLn(ServiceContractLine: Record "Service Contract Line")
    begin
        ServiceContractLine.SetRange("Line No.", ServiceContractLine."Line No.");
        RemoveLinesFromContract(ServiceContractLine);
    end;

    local procedure SaveServiceContractLinesInTemp(var TempServiceContractLine: Record "Service Contract Line" temporary; ServiceContractLine: Record "Service Contract Line")
    begin
        ServiceContractLine.SetRange("Contract Type", ServiceContractLine."Contract Type");
        ServiceContractLine.SetRange("Contract No.", ServiceContractLine."Contract No.");
        ServiceContractLine.FindSet();
        repeat
            TempServiceContractLine.Init();
            TempServiceContractLine := ServiceContractLine;
            TempServiceContractLine.Insert();
        until ServiceContractLine.Next() = 0;
    end;

    local procedure SaveServCreditMemoLinesInTemp(var TempServiceLine: Record "Service Line" temporary; ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindSet();
        repeat
            TempServiceLine.Init();
            TempServiceLine := ServiceLine;
            TempServiceLine.Insert();
        until ServiceLine.Next() = 0;
    end;

    local procedure UpdatePaymentMethodCode(var ServiceHeader: Record "Service Header"; PaymentMethodCode: Code[10])
    begin
        ServiceHeader.Validate("Payment Method Code", PaymentMethodCode);
        ServiceHeader.Modify(true);
    end;

    local procedure CreateCreditMemoLine(No: Code[20]; CustomerNo: Code[20]; Type: Enum "Service Document Type"; No2: Code[20])
    var
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        ServiceCreditMemoOpenEdit(ServiceCreditMemo, No);
        ServiceCreditMemo."Customer No.".SetValue(CustomerNo);
        ServiceCreditMemo.ServLines.Type.SetValue(Type);
        ServiceCreditMemo.ServLines."No.".SetValue(No2);
        ServiceCreditMemo.ServLines.Quantity.SetValue(LibraryRandom.RandDec(100, 2));  // Using random value for Quantity.
        ServiceCreditMemo.ServLines.New();
        ServiceCreditMemo.OK().Invoke();
    end;

    local procedure CustomerWithPriceIncludingVAT(PricesIncludingVAT: Boolean): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Prices Including VAT", PricesIncludingVAT);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure InsertContractNoOnServiceLine(DocumentNo: Code[20]; ContractNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::"Credit Memo");
        ServiceLine.SetRange("Document No.", DocumentNo);
        ServiceLine.FindFirst();
        ServiceLine.Validate("Contract No.", ContractNo);
        ServiceLine.Modify(true);
    end;

    local procedure ServiceCreditMemoOpenEdit(var ServiceCreditMemo: TestPage "Service Credit Memo"; No: Code[20])
    begin
        ServiceCreditMemo.OpenEdit();
        ServiceCreditMemo.FILTER.SetFilter("No.", No);
    end;

    local procedure SetCreditMemoAsCorrection()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.Validate("Mark Cr. Memos as Corrections", true);
        GLSetup.Modify();
    end;

    local procedure VerifyAmountInvoiceCreditMemo(ContractNo: Code[20])
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        CrMemoAmount: Decimal;
        ServiceInvoiceAmount: Decimal;
    begin
        ServiceInvoiceLine.SetRange("Contract No.", ContractNo);
        ServiceInvoiceLine.FindSet();
        repeat
            ServiceInvoiceAmount += ServiceInvoiceLine."Line Amount";
        until ServiceInvoiceLine.Next() = 0;

        ServiceCrMemoLine.SetRange("Contract No.", ContractNo);
        ServiceCrMemoLine.FindSet();
        repeat
            CrMemoAmount += ServiceCrMemoLine."Line Amount";
        until ServiceCrMemoLine.Next() = 0;

        // AreNearlyEqual is needed because CreateContractLineCreditMemo does create lines
        // without a rounding adjustment at the document level that is done during Invoice posting
        Assert.AreNearlyEqual(
          ServiceInvoiceAmount, CrMemoAmount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountMustMatchError, ServiceInvoiceLine.TableCaption(), ServiceCrMemoLine.TableCaption()));
    end;

    local procedure VerifyCrditMemoLnWithContrctLn(ServiceContractLine: Record "Service Contract Line"; CreditMemoNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify that the Service Line created corresponds with the relevant Service Contract Line.
        ServiceContractLine.SetRange("Contract Type", ServiceContractLine."Contract Type");
        ServiceContractLine.SetRange("Contract No.", ServiceContractLine."Contract No.");
        ServiceContractLine.FindSet();
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::"Credit Memo");
        ServiceLine.SetRange("Document No.", CreditMemoNo);
        ServiceLine.FindSet();
        repeat
            ServiceLine.Next();  // The first line of Credit Memo contains only Description
            ServiceLine.TestField("Customer No.", ServiceContractLine."Customer No.");
            ServiceLine.TestField("Service Item No.", ServiceContractLine."Service Item No.");
            ServiceLine.Next();
        until ServiceContractLine.Next() = 0;
    end;

    local procedure VerifyCrditMmLnWthTempCntrctLn(var TempServiceContractLine: Record "Service Contract Line" temporary; CreditMemoNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify that the Service Line created corresponds with the relevant Service Contract Line saved in temporary table.
        TempServiceContractLine.FindSet();
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::"Credit Memo");
        ServiceLine.SetRange("Document No.", CreditMemoNo);
        ServiceLine.FindSet();
        repeat
            ServiceLine.Next();  // The first line of Credit Memo contains only Description.
            ServiceLine.TestField("Customer No.", TempServiceContractLine."Customer No.");
            ServiceLine.TestField("Service Item No.", TempServiceContractLine."Service Item No.");
            ServiceLine.Next();
        until TempServiceContractLine.Next() = 0;
    end;

    local procedure VerifyCrdtMmLnWthPrpdCntrctLn(ServiceContractLine: Record "Service Contract Line"; CreditMemoNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify that the Service Line created corresponds with the relevant Service Contract Line.
        ServiceContractLine.SetRange("Contract Type", ServiceContractLine."Contract Type");
        ServiceContractLine.SetRange("Contract No.", ServiceContractLine."Contract No.");
        ServiceContractLine.FindSet();
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::"Credit Memo");
        ServiceLine.SetRange("Document No.", CreditMemoNo);
        ServiceLine.FindSet();
        ServiceLine.Next();  // The first line of Credit Memo contains only Description.
        repeat
            ServiceLine.TestField("Customer No.", ServiceContractLine."Customer No.");
            ServiceLine.TestField("Service Item No.", ServiceContractLine."Service Item No.");
            ServiceLine.Next();
        until ServiceContractLine.Next() = 0;
    end;

    local procedure VerifyCrdtMmLnWthPstdCrdtMmLn(var TempServiceLine: Record "Service Line" temporary)
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        // Verify that the Posted Service Credit Memo Lines created corresponds with the relevant Service Credit Memo Lines.
        TempServiceLine.FindSet();
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", TempServiceLine."Document No.");
        ServiceCrMemoHeader.FindFirst();
        repeat
            ServiceCrMemoLine.Get(ServiceCrMemoHeader."No.", TempServiceLine."Line No.");  // Line No in unposted/posted documents are same.
            ServiceCrMemoLine.TestField("Customer No.", TempServiceLine."Customer No.");
            ServiceCrMemoLine.TestField(Type, TempServiceLine.Type);
            ServiceCrMemoLine.TestField("No.", TempServiceLine."No.");
            ServiceCrMemoLine.TestField("Location Code", TempServiceLine."Location Code");
            ServiceCrMemoLine.TestField(Quantity, TempServiceLine.Quantity);
            ServiceCrMemoLine.TestField("Unit Price", TempServiceLine."Unit Price");
            ServiceCrMemoLine.TestField("Unit Cost (LCY)", TempServiceLine."Unit Cost (LCY)");
            ServiceCrMemoLine.TestField("Line Discount %", TempServiceLine."Line Discount %");
            ServiceCrMemoLine.TestField("Line Discount Amount", TempServiceLine."Line Discount Amount");
            ServiceCrMemoLine.TestField(Amount, TempServiceLine.Amount);
            Assert.AreNearlyEqual(
              ServiceCrMemoLine."Amount Including VAT", TempServiceLine."Amount Including VAT", LibraryERM.GetAmountRoundingPrecision(),
              StrSubstNo(AmountError, ServiceCrMemoLine.FieldCaption("Amount Including VAT"),
                TempServiceLine."Amount Including VAT", ServiceCrMemoLine.TableCaption()));
            ServiceCrMemoLine.TestField("Allow Invoice Disc.", TempServiceLine."Allow Invoice Disc.");
            ServiceCrMemoLine.TestField("Inv. Discount Amount", TempServiceLine."Inv. Discount Amount");
            ServiceCrMemoLine.TestField("Line Amount", TempServiceLine."Line Amount");
            ServiceCrMemoLine.TestField("Service Item No.", TempServiceLine."Service Item No.");
        until TempServiceLine.Next() = 0;
    end;

    local procedure VerifyCreditMemoGLEntries(var TempServiceLine: Record "Service Line" temporary)
    var
        GLEntry: Record "G/L Entry";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        // Verify that the G/L Entry created correspond with the relevant Service Credit Memo Lines.
        TempServiceLine.FindFirst();
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", TempServiceLine."Document No.");
        ServiceCrMemoHeader.FindFirst();
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::"Credit Memo");
        GLEntry.SetRange("Document No.", ServiceCrMemoHeader."No.");
        GLEntry.SetRange("Source Type", GLEntry."Source Type"::Customer);
        GLEntry.FindSet();
        repeat
            GLEntry.TestField("Posting Date", TempServiceLine."Posting Date");
            GLEntry.TestField("Source No.", TempServiceLine."Bill-to Customer No.");
        until GLEntry.Next() = 0;
    end;

    local procedure VerifyCreditMemoDetCustLedEnt(var TempServiceLine: Record "Service Line" temporary)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        // Verify that the Detailed Customer Ledger Entry created correspond with the relevant Service Credit Memo Lines.
        TempServiceLine.FindFirst();
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", TempServiceLine."Document No.");
        ServiceCrMemoHeader.FindFirst();
        DetailedCustLedgEntry.SetRange("Document Type", DetailedCustLedgEntry."Document Type"::"Credit Memo");
        DetailedCustLedgEntry.SetRange("Document No.", ServiceCrMemoHeader."No.");
        DetailedCustLedgEntry.FindSet();
        repeat
            DetailedCustLedgEntry.TestField("Posting Date", TempServiceLine."Posting Date");
            DetailedCustLedgEntry.TestField("Customer No.", TempServiceLine."Bill-to Customer No.");
        until DetailedCustLedgEntry.Next() = 0;
    end;

    local procedure VerifyCreditMemoVATEntries(var TempServiceLine: Record "Service Line" temporary)
    var
        VATEntry: Record "VAT Entry";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        // Verify that the VAT Entry created correspond with the relevant Service Credit Memo Lines.
        TempServiceLine.FindFirst();
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", TempServiceLine."Document No.");
        ServiceCrMemoHeader.FindFirst();
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::"Credit Memo");
        VATEntry.SetRange("Document No.", ServiceCrMemoHeader."No.");
        VATEntry.FindSet();
        repeat
            VATEntry.TestField("Posting Date", TempServiceLine."Posting Date");
            VATEntry.TestField("Bill-to/Pay-to No.", TempServiceLine."Bill-to Customer No.");
        until VATEntry.Next() = 0;
    end;

    local procedure VerifyCreditMemoValueEntries(var TempServiceLine: Record "Service Line" temporary)
    var
        ValueEntry: Record "Value Entry";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        // Verify that the Value Entry created correspond with the relevant Service Credit Memo Lines.
        TempServiceLine.FindSet();
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", TempServiceLine."Document No.");
        ServiceCrMemoHeader.FindFirst();
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Service Credit Memo");
        ValueEntry.SetRange("Document No.", ServiceCrMemoHeader."No.");
        repeat
            ValueEntry.SetRange("Order Line No.", TempServiceLine."Line No.");
            ValueEntry.FindFirst();
            ValueEntry.TestField("Item No.", TempServiceLine."No.");
            ValueEntry.TestField("Posting Date", TempServiceLine."Posting Date");
            ValueEntry.TestField("Source No.", TempServiceLine."Customer No.");
            ValueEntry.TestField("Location Code", TempServiceLine."Location Code");
        until TempServiceLine.Next() = 0;
    end;

    local procedure VerifyCreditMemoWithContract(ContractNo: Code[20])
    var
        ServiceContractLine: Record "Service Contract Line";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        ServiceCrMemoLine.SetRange("Contract No.", ContractNo);
        ServiceCrMemoLine.FindSet();
        ServiceContractLine.SetRange("Contract Type", ServiceContractLine."Contract Type"::Contract);
        ServiceContractLine.SetRange("Contract No.", ContractNo);
        ServiceContractLine.FindSet();
        repeat
            ServiceContractLine.TestField("Service Item No.", ServiceCrMemoLine."Service Item No.");
            ServiceContractLine.Next();
        until ServiceCrMemoLine.Next() = 0;
    end;

    local procedure VerifyCustLedgEntryRemAmount(ServiceInvoiceHeaderNo: Code[20]; ServiceCreditMemoAmtIncVAT: Decimal; ServiceInvoiceAmtIncVAT: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Verify that the Remaining Amount in the Customer Ledger Entry for Service Invoice applied is the difference of the Amount
        // Includig VAT of the Service Invoice and the Service Credit Memo.
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", ServiceInvoiceHeaderNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields("Remaining Amount");
        CustLedgerEntry.TestField("Remaining Amount", ServiceInvoiceAmtIncVAT - ServiceCreditMemoAmtIncVAT);
    end;

    local procedure VerifyPostedServiceCreditMemoLine(CustomerNo: Code[20]; Type: Enum "Service Document Type"; No: Code[20]; Quantity: Decimal)
    var
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        ServiceCrMemoLine.SetRange("Customer No.", CustomerNo);
        ServiceCrMemoLine.FindFirst();
        ServiceCrMemoLine.TestField(Type, Type);
        ServiceCrMemoLine.TestField("No.", No);
        ServiceCrMemoLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyServiceInvoiceHeaderLine(var TempServiceLine: Record "Service Line" temporary; ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        ServiceInvoiceHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceInvoiceHeader.FindFirst();
        ServiceInvoiceHeader.TestField("Customer No.", ServiceContractHeader."Customer No.");
        TempServiceLine.FindSet();
        repeat
            ServiceInvoiceLine.Get(ServiceInvoiceHeader."No.", TempServiceLine."Line No.");
            TempServiceLine.TestField("Line Amount", ServiceInvoiceLine."Line Amount");
            TempServiceLine.TestField("Customer No.", ServiceInvoiceLine."Customer No.");
        until TempServiceLine.Next() = 0;
    end;

    local procedure VerifyCreditMemoServiceLedger(var ServiceLine: Record "Service Line")
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        ServiceLine.FindSet();
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", ServiceLine."Document No.");
        ServiceCrMemoHeader.FindFirst();
        ServiceLedgerEntry.SetRange("Document Type", ServiceLedgerEntry."Document Type"::"Credit Memo");
        ServiceLedgerEntry.SetRange("Document No.", ServiceCrMemoHeader."No.");
        ServiceLedgerEntry.FindSet();
        repeat
            ServiceLedgerEntry.TestField(Quantity, ServiceLine.Quantity);
            ServiceLedgerEntry.TestField("Customer No.", ServiceLine."Customer No.");
            ServiceLedgerEntry.TestField("Unit Price", ServiceLine."Unit Price");
            ServiceLedgerEntry.TestField("Unit Cost", ServiceLine."Unit Cost (LCY)");
            ServiceLedgerEntry.TestField(
              "Cost Amount", Round(ServiceLine.Quantity * ServiceLine."Unit Cost (LCY)", GeneralLedgerSetup."Amount Rounding Precision"));
            ServiceLedgerEntry.Next();
        until ServiceLine.Next() = 0;
    end;

    local procedure VerifyCreditMemoServiceLedgerEntry(PreAssignedNo: Code[20]; CustomerNo: Code[20]; No: Code[20]; Quantity: Decimal)
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        ServiceCrMemoHeader.FindFirst();
        ServiceLedgerEntry.SetRange("Document Type", ServiceLedgerEntry."Document Type"::"Credit Memo");
        ServiceLedgerEntry.SetRange("Document No.", ServiceCrMemoHeader."No.");
        ServiceLedgerEntry.FindFirst();
        ServiceLedgerEntry.TestField("Entry Type", ServiceLedgerEntry."Entry Type"::Sale);
        ServiceLedgerEntry.TestField("Customer No.", CustomerNo);
        ServiceLedgerEntry.TestField("No.", No);
        ServiceLedgerEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyServiceCreditMemoItemLedgerEntry(PreAssignedNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        ServiceCrMemoHeader.FindFirst();
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Service Credit Memo");
        ItemLedgerEntry.SetRange("Document No.", ServiceCrMemoHeader."No.");
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        ItemLedgerEntry.TestField("Item No.", ItemNo);
        ItemLedgerEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyCreditMemoCorrectionGLEntries(DocumentNo: Code[20])
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        GLEntry: Record "G/L Entry";
    begin
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", DocumentNo);
        ServiceCrMemoHeader.FindFirst();
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::"Credit Memo");
        GLEntry.SetRange("Document No.", ServiceCrMemoHeader."No.");
        GLEntry.SetRange("Source Type", GLEntry."Source Type"::Customer);
        GLEntry.FindSet();
        repeat
            if GLEntry."Debit Amount" > 0 then
                Error(CorrectionErr, GLEntry.FieldCaption("Debit Amount"), GLEntry."G/L Account No.");
            if GLEntry."Credit Amount" > 0 then
                Error(CorrectionErr, GLEntry.FieldCaption("Credit Amount"), GLEntry."G/L Account No.");
        until GLEntry.Next() = 0;
    end;

    local procedure VerifyCrdtMemoUnitPriceOfExpiredContractLine(ServiceHeaderNo: Code[20]; ExpectedAmount: Decimal);
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::"Credit Memo");
        ServiceLine.SetRange("Document No.", ServiceHeaderNo);
        ServiceLine.SetRange("Line Amount", ExpectedAmount);
        Assert.RecordIsNotEmpty(ServiceLine);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalse(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := not (Question = UseContractTemplateConfirm);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Handle Message.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyServCustEntrsModalFormHandler(var ServApplyCustomerEntries: Page "Serv. Apply Customer Entries"; var Response: Action)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document Type", DocumentType);
        CustLedgerEntry.SetRange("Document No.", DocumentHeaderNo);
        CustLedgerEntry.FindFirst();
        ServApplyCustomerEntries.SetCustLedgEntry(CustLedgerEntry);
        ServApplyCustomerEntries.SetCustApplId(false);
        Response := ACTION::LookupOK;
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure ReportHandlerContractInvoice(var ContractInvoicing: Report "Contract Invoicing")
    var
        ServiceContractHeader: Record "Service Contract Header";
    begin
        ServiceContractHeader.SetRange("Contract No.", ContractNo);
        ContractInvoicing.SetTableView(ServiceContractHeader);
        ContractInvoicing.UseRequestPage(false);
        FilePath := TemporaryPath + Format(ServiceContractHeader."Contract No.") + '.xlsx';
        ContractInvoicing.SaveAsExcel(FilePath);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServContrctTemplateListHandler(var ServiceContractTemplateList: Page "Service Contract Template List"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure InvoiceESConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := (Question = ExpectedConfirm);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceCrMemoPH(var PostedServiceCreditMemo: TestPage "Posted Service Credit Memo")
    begin
        PostedServiceCreditMemo."No.".AssertEquals(LibraryVariableStorage.DequeueText());
        PostedServiceCreditMemo."Customer No.".AssertEquals(LibraryVariableStorage.DequeueText());
    end;

    [RequestPageHandler]
    procedure RemoveLinesFromContractRequestHandler(var RemoveLinesFromReport: TestRequestPage "Remove Lines from Contract")
    var
        ExpiredDateVariant: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpiredDateVariant);
        RemoveLinesFromReport.DelToDate.SetValue(ExpiredDateVariant);
        RemoveLinesFromReport.OK().Invoke();
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
    end;
}

