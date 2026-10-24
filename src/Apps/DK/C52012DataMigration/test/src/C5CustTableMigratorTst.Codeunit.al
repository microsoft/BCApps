// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved. 
// Licensed under the MIT License. See License.txt in the project root for license information. 
// ------------------------------------------------------------------------------------------------

codeunit 148003 "C5 CustTable Migrator Tst"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        CustomerDataMigrationFacade: Codeunit "Customer Data Migration Facade";
        C5HelperFunctions: Codeunit "C5 Helper Functions";
        CustPriceGroupTxt: Label 'PriceGr', Locked = true;
        PaymentTxt: Label 'Payment', Locked = true;
        SalesPersonTxt: Label 'Saleser', Locked = true;
        DeliveryTxt: Label 'Deliver', Locked = true;
        DiscGroupTxt: Label 'DiscGroup', Locked = true;
        ProcCodeTxt: Label 'ProcCody', Locked = true;
        CustNumTxt: Label 'MYC5CUST', Locked = true;
        AltCustNumTxt: Label 'MYC5Cust2', Locked = true;
        DepartmentTxt: Label 'SALESX';
        CostCenterTxt: Label 'CostCntX';
        PurposeTxt: Label 'PurposeX';
        Department2Txt: Label 'SALESY';
        CostCenter2Txt: Label 'CostCntY';
        Purpose2Txt: Label 'PurposeY';

    trigger OnRun();
    begin
        // [FEATURE] [C5 Data Migration]
    end;

    local procedure Initialize()
    var
        C5CustTable: Record "C5 CustTable";
        C5CustTrans: Record "C5 CustTrans";
        C5Payment: Record "C5 Payment";
        C5InventoryPriceGroup: Record "C5 InvenPriceGroup";
        C5Employee: Record "C5 Employee";
        C5Delivery: Record "C5 Delivery";
        C5CustDiscGroup: Record "C5 CustDiscGroup";
        C5ProcCode: Record "C5 ProcCode";
        C5CustContact: Record "C5 CustContact";
        Customer: Record Customer;
        CustomerPriceGroup: Record "Customer Price Group";
        MarketingSetup: Record "Marketing Setup";
        PaymentTerms: Record "Payment Terms";
        ShipmentMethod: Record "Shipment Method";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CustomerDiscountGroup: Record "Customer Discount Group";
        PaymentMethod: Record "Payment Method";
        GenJournalLine: Record "Gen. Journal Line";
        CountryRegion: Record "Country/Region";
        NoSeries: Record "No. Series";
        NoSeriesLines: Record "No. Series Line";
    begin
        Customer.DeleteAll();
        C5CustTable.DeleteAll();
        C5InventoryPriceGroup.DeleteAll();
        C5Employee.DeleteAll();
        C5Payment.DeleteAll();
        C5Delivery.DeleteAll();
        C5CustDiscGroup.DeleteAll();
        C5ProcCode.DeleteAll();
        C5CustContact.DeleteAll();
        CustomerPriceGroup.DeleteAll();
        PaymentTerms.DeleteAll();
        ShipmentMethod.DeleteAll();
        SalespersonPurchaser.DeleteAll();
        CustomerDiscountGroup.DeleteAll();
        PaymentMethod.DeleteAll();
        GenJournalLine.DeleteAll();
        CountryRegion.DeleteAll();
        NoSeries.DeleteAll();
        NoSeriesLines.DeleteAll();
        C5CustTrans.DeleteAll();

        CountryRegion.Init();
        CountryRegion.Validate(Code, 'AT');
        CountryRegion.Validate(Name, 'Austria');
        CountryRegion.Insert();

        NoSeries.Init();
        NoSeries.Code := 'G000CONT';
        NoSeries."Default Nos." := true;
        NoSeries.Insert();

        NoSeriesLines.Init();
        NoSeriesLines."Series Code" := 'G000CONT';
        NoSeriesLines."Starting Date" := WorkDate();
        NoSeriesLines."Starting No." := '8000';
        NoSeriesLines."Ending No." := '9500';
        NoSeriesLines.Insert();

        NoSeries.Init();
        NoSeries.Code := 'CUST';
        NoSeries."Manual Nos." := true;
        NoSeries."Default Nos." := true;
        NoSeries.Insert();

        NoSeriesLines.Init();
        NoSeriesLines."Series Code" := 'CUST';
        NoSeriesLines."Starting Date" := WorkDate();
        NoSeriesLines."Starting No." := '8000';
        NoSeriesLines."Ending No." := '9500';
        NoSeriesLines.Insert();

        if MarketingSetup.Get() then begin
            MarketingSetup."Autosearch for Duplicates" := false;
            MarketingSetup."Bus. Rel. Code for Customers" := 'CUST';
            MarketingSetup."Contact Nos." := 'G000CONT';
            MarketingSetup.Modify();
        end;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestCustTableMigrationWithCoA()
    var
        C5CustTable1: Record "C5 CustTable";
        C5CustTable2: Record "C5 CustTable";
    begin
        // [SCENARIO] Records from the C5 staging table for customers are migrated to Nav
        Initialize();

        // [GIVEN] Some records in the staging table are already present
        FillC5StagingTables(C5CustTable1, C5CustTable2);

        // [WHEN] The migrator is run
        Migrate(C5CustTable1, true);
        Migrate(C5CustTable2, true);

        // [THEN] New records are created in the customer table
        CheckCustomerExists(C5CustTable1);
        CheckCustomerExists(C5CustTable2);

        // [THEN] The Customer posting setup has been created and general journal lines have been created
        CheckCustomerPostingSetup(C5CustTable1);
        CheckCustomerPostingSetup(C5CustTable2);

        // [THEN] related records are migrated
        CheckRelatedEntitiesMigration(C5CustTable1, C5CustTable2);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestCustTableMigrationWithoutCoA()
    var
        C5CustTable1: Record "C5 CustTable";
        C5CustTable2: Record "C5 CustTable";
    begin
        // [SCENARIO] Records from the C5 staging table for customers are migrated to Nav
        Initialize();

        // [GIVEN] Some records in the staging table are already present
        FillC5StagingTables(C5CustTable1, C5CustTable2);

        // [WHEN] The migrator is run
        Migrate(C5CustTable1, false);
        Migrate(C5CustTable2, false);

        // [THEN] New records are created in the customer table
        CheckCustomerExists(C5CustTable1);
        CheckCustomerExists(C5CustTable2);

        // [THEN] The customer posting setup is empty and no general journal line has been created
        CheckCustomerPostingSetupIsEmpty(C5CustTable1);
        CheckCustomerPostingSetupIsEmpty(C5CustTable2);

        // [THEN] related records are migrated
        CheckRelatedEntitiesMigration(C5CustTable1, C5CustTable2);
    end;

    local procedure CheckRelatedEntitiesMigration(C5CustTable1: Record "C5 CustTable"; C5CustTable2: Record "C5 CustTable")
    begin
        CheckDefaultDimensionExists(C5CustTable1.Account);
        CheckDefaultDimensionExists(C5CustTable2.Account);
        CheckPaymentTermsExist();
        CheckCustomerPriceGroupExists();
        CheckSalesPersonExists();
        CheckShipmentMethodExists();
        CheckCustomerDiscountGroupExists();
        CheckPaymentMethodExists();
        CheckContacts();
    end;

    local procedure CheckContacts()
    var
        Contact: Record Contact;
    begin
        Contact.SetRange(Name, CustNumTxt);
        Contact.FindFirst();
        Assert.AreEqual(Contact.Address, '123, Hobby Street', 'Contact address was migrated incorrectly');
        Assert.AreEqual(Contact."Address 2", 'DerbyShire, Area GoGoland', 'Contact address 2 was migrated incorrectly');
        Assert.AreEqual(Contact."Phone No.", '02345556262', 'Contact phone was migrated incorrectly');
        Assert.AreEqual(Contact."Post Code", 'AT-1100', 'Contact address was migrated incorrectly');
        Assert.AreEqual(Contact.City, 'Wien', 'Contact city was migrated incorrectly');
        Assert.AreEqual(Contact."Country/Region Code", 'AT', 'Contact Country was migrated incorrectly');
        Assert.AreEqual(Contact."E-Mail", CustNumTxt + '@mail.com', 'Contact Email was migrated incorrectly');

        Contact.SetRange(Name, 'Secondary Contact');
        Contact.FindFirst();
        Assert.AreEqual(Contact.Address, 'Address1', 'Contact address was migrated incorrectly');
        Assert.AreEqual(Contact."Address 2", 'Address2', 'Contact address 2 was migrated incorrectly');
        Assert.AreEqual(Contact."Phone No.", '12345678', 'Contact phone was migrated incorrectly');
        Assert.AreEqual(Contact."Mobile Phone No.", '12345678', 'Contact mobile was migrated incorrectly');
        Assert.AreEqual(Contact."Post Code", 'AT-1100', 'Contact address was migrated incorrectly');
        Assert.AreEqual(Contact.City, 'Wien', 'Contact city was migrated incorrectly');
        Assert.AreEqual(Contact."Country/Region Code", 'AT', 'Contact Country was migrated incorrectly');
        Assert.AreEqual(Contact."E-Mail", 'second@mail.com', 'Contact email was migrated incorrectly');
    end;

    local procedure Migrate(C5CustTable: Record "C5 CustTable"; ChartOfAccountsMigrated: boolean)
    var
        C5CustTableMigrator: Codeunit "C5 CustTable Migrator";
    begin
        C5CustTableMigrator.MigrateCustomer(CustomerDataMigrationFacade, C5CustTable.RecordId());
        C5CustTableMigrator.MigrateCustomerDimensions(CustomerDataMigrationFacade, C5CustTable.RecordId());
        C5CustTableMigrator.MigrateCustomerPostingGroups(CustomerDataMigrationFacade, C5CustTable.RecordId(), ChartOfAccountsMigrated);
        C5CustTableMigrator.MigrateCustomerTransactions(CustomerDataMigrationFacade, C5CustTable.RecordId(), ChartOfAccountsMigrated);
    end;

    local procedure CreateC5CustTableRecord(Acc: Text[10]; InvAccount: Text[10]; var C5CustTable: Record "C5 CustTable")
    var
        C5CustTable2: Record "C5 CustTable";
    begin
        C5CustTable.Init();
        if C5CustTable2.FindLast() then
            C5CustTable.RecId := C5CustTable2.RecId + 1;
        C5CustTable.Account := Acc;
        C5CustTable.Name := C5CustTable.Account;
        C5CustTable.SearchName := C5CustTable.Account + ' search';
        C5CustTable.Address1 := '123, Hobby Street';
        C5CustTable.Address2 := 'DerbyShire, Area GoGoland';
        C5CustTable.ZipCity := 'AT-1100 Wien';
        C5CustTable.Country := 'Austria';
        C5CustTable.Attention := 'Tim Nut';
        C5CustTable.Phone := '02345556262';
        C5CustTable.CellPhone := '028352757';
        C5CustTable.Email := C5CustTable.Account + '@mail.com';
        C5CustTable.Department := CopyStr(DepartmentTxt, 1, 10);
        C5CustTable.Centre := CopyStr(CostCenterTxt, 1, 10);
        C5CustTable.Purpose := CopyStr(PurposeTxt, 1, 10);
        C5CustTable.SalesGroup := 'SalesGr';
        C5CustTable.BalanceMax := 1415551;
        C5CustTable.Group := 'CustGrp';
        C5CustTable.PriceGroup := CopyStr(CustPriceGroupTxt, 1, 10);
        C5CustTable.Language_ := C5CustTable.Language_::English;
        C5CustTable.Payment := CopyStr(PaymentTxt, 1, 10);
        C5CustTable.SalesRep := CopyStr(SalesPersonTxt, 1, 10);
        C5CustTable.Delivery := CopyStr(DeliveryTxt, 1, 10);
        C5CustTable.TransportCode := 'PARAVION';
        C5CustTable.DiscGroup := CopyStr(DiscGroupTxt, 1, 10);
        C5CustTable.Blocked := C5CustTable.Blocked::No;
        C5CustTable.InvoiceAccount := CopyStr(InvAccount, 1, 10);
        C5CustTable.PaymentMode := CopyStr(ProcCodeTxt, 1, 10);
        C5CustTable.Fax := 'FaxeKondi';
        C5CustTable.VatNumber := 'ATU' + Format(LibraryRandom.RandIntInRange(10000000, 99999999));
        C5CustTable.URL := 'www.aliddr.com';
        C5CustTable.Vat := 'VATPosting';
        C5CustTable.Insert(true);
    end;

    local procedure CreateC5InvenPriceGroup()
    var
        C5InvenPriceGroup: Record "C5 InvenPriceGroup";
    begin
        C5InvenPriceGroup.Init();
        C5InvenPriceGroup.Group := CopyStr(CustPriceGroupTxt, 1, 10);
        C5InvenPriceGroup.GroupName := 'My CPG Description';
        C5InvenPriceGroup.InclVat := C5InvenPriceGroup.InclVat::Yes;
        C5InvenPriceGroup.Insert(true);
    end;

    local procedure FillC5StagingTables(var C5CustTable1: Record "C5 CustTable"; var C5CustTable2: Record "C5 CustTable")
    begin
        CreateC5InvenPriceGroup();
        CreateC5Payment();
        CreateC5Employee();
        CreateC5Delivery();
        CreateC5CustDiscGroup();
        CreateC5ProcCode();
        CreateC5CustTableRecord(CopyStr(CustNumTxt, 1, 10), '', C5CustTable1);
        CreateC5CustTableRecord(CopyStr(AltCustNumTxt, 1, 10), CopyStr(CustNumTxt, 1, 10), C5CustTable2);
        CreateC5CustGroup();
        CreateC5CustTrans();
        CreateC5CustContact();
    end;

    local procedure CheckCustomerPriceGroupExists()
    var
        CustomerPriceGroup: Record "Customer Price Group";
    begin
        CustomerPriceGroup.SetRange(Code, CustPriceGroupTxt);
        CustomerPriceGroup.SetRange(Description, 'My CPG Description');
        CustomerPriceGroup.SetRange("Price Includes VAT", true);
        Assert.IsFalse(CustomerPriceGroup.IsEmpty(), 'Customer price group was not found.');
    end;

    local procedure CreateC5Payment()
    var
        C5Payment: Record "C5 Payment";
    begin
        C5Payment.Init();
        C5Payment.Payment := CopyStr(PaymentTxt, 1, 10);
        C5Payment.Txt := 'My payment';
        C5Payment.Method := C5Payment.Method::"Cur. month";
        C5Payment.UnitCode := C5Payment.UnitCode::Day;
        C5Payment.Qty := 5;
        C5Payment.Insert(true);
    end;

    local procedure CreateC5CustContact()
    var
        C5CustContact: Record "C5 CustContact";
    begin
        C5CustContact.Init();
        C5CustContact.RecId := 1;
        C5CustContact.Account := CopyStr(CustNumTxt, 1, 10);
        C5CustContact.Name := CopyStr(CustNumTxt, 1, 10);
        C5CustContact.Address1 := '123, Hobby Street';
        C5CustContact.Address2 := 'DerbyShire, Area GoGoland';
        C5CustContact.Phone := '02345556262';
        C5CustContact.ZipCity := 'AT-1100 Wien';
        C5CustContact.Country := 'Austria';
        C5CustContact.Email := C5CustContact.Account + '@mail.com';
        C5CustContact.PrimaryContact := C5CustContact.PrimaryContact::Yes;
        C5CustContact.Insert(true);

        C5CustContact.Init();
        C5CustContact.RecId := 2;
        C5CustContact.Account := CopyStr(CustNumTxt, 1, 10);
        C5CustContact.Name := 'Secondary Contact';
        C5CustContact.Address1 := 'Address1';
        C5CustContact.Address2 := 'Address2';
        C5CustContact.Phone := '12345678';
        C5CustContact.CellPhone := '12345678';
        C5CustContact.ZipCity := 'AT-1100 Wien';
        C5CustContact.Country := 'Austria';
        C5CustContact.Email := 'second@mail.com';
        C5CustContact.Insert(true);
    end;

    local procedure CheckPaymentTermsExist()
    var
        PaymentTerms: Record "Payment Terms";
        DueDateFormula: DateFormula;
    begin
        PaymentTerms.SetRange(Code, PaymentTxt);
        PaymentTerms.SetRange(Description, 'My payment');
        Evaluate(DueDateFormula, '<CM+5D>');
        PaymentTerms.SetRange("Due Date Calculation", DueDateFormula);
        Assert.IsFalse(PaymentTerms.IsEmpty(), 'The payment terms were not found.');
    end;

    local procedure CreateC5Employee()
    var
        C5Employee: Record "C5 Employee";
    begin
        C5Employee.Init();
        C5Employee.Employee := CopyStr(SalesPersonTxt, 1, 10);
        C5Employee.EmployeeType := C5Employee.EmployeeType::"Sales rep.";
        C5Employee.Name := 'Gert Thomas';
        C5Employee.Phone := '123455';
        C5Employee.Email := 'gertThomas@c5.com';
        C5Employee.Insert(true);
    end;

    local procedure CheckSalesPersonExists()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        SalespersonPurchaser.SetRange(Code, SalesPersonTxt);
        SalespersonPurchaser.SetRange(Name, 'Gert Thomas');
        SalespersonPurchaser.SetRange("Phone No.", '123455');
        SalespersonPurchaser.SetRange("E-Mail", 'gertThomas@c5.com');
        Assert.IsFalse(SalespersonPurchaser.IsEmpty(), 'The sales person purchaser was not found.');
    end;

    local procedure CreateC5Delivery()
    var
        C5Delivery: Record "C5 Delivery";
    begin
        C5Delivery.Init();
        C5Delivery.Delivery := CopyStr(DeliveryTxt, 1, 10);
        C5Delivery.Name := 'By Avion';
        C5Delivery.Insert(true);
    end;

    local procedure CheckShipmentMethodExists()
    var
        ShipmentMethod: Record "Shipment Method";
    begin
        ShipmentMethod.SetRange(Code, DeliveryTxt);
        ShipmentMethod.SetRange(Description, 'By Avion');
        Assert.IsFalse(ShipmentMethod.IsEmpty(), 'The shipment method was not found.');
    end;

    local procedure CreateC5CustDiscGroup()
    var
        C5CustDiscGroup: Record "C5 CustDiscGroup";
    begin
        C5CustDiscGroup.Init();
        C5CustDiscGroup.DiscGroup := CopyStr(DiscGroupTxt, 1, 10);
        C5CustDiscGroup.Comment := 'A comment for disc group';
        C5CustDiscGroup.Insert(true);
    end;

    local procedure CheckCustomerDiscountGroupExists()
    var
        CustomerDiscountGroup: Record "Customer Discount Group";
    begin
        CustomerDiscountGroup.SetRange(Code, DiscGroupTxt);
        CustomerDiscountGroup.SetRange(Description, 'A comment for disc group');
        Assert.IsFalse(CustomerDiscountGroup.IsEmpty(), 'The customer discount group was not found.');
    end;

    local procedure CreateC5ProcCode()
    var
        C5ProcCode: Record "C5 ProcCode";
    begin
        C5ProcCode.Init();
        C5ProcCode.Type := C5ProcCode.Type::Customer;
        C5ProcCode.Code := CopyStr(ProcCodeTxt, 1, 10);
        C5ProcCode.Name := 'Proc Code full name';
        C5ProcCode.Insert(true);
    end;

    local procedure CheckPaymentMethodExists()
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.SetRange(Code, ProcCodeTxt);
        PaymentMethod.SetRange(Description, 'Proc Code full name');
        Assert.IsFalse(PaymentMethod.IsEmpty(), 'The payment method was not found.');
    end;

    local procedure CheckDefaultDimensionExists(Customer: Text[10])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.SetRange("Table ID", Database::Customer);
        DefaultDimension.SetRange("No.", Customer);
        DefaultDimension.SetRange("Dimension Code", 'C5DEPARTMENT');
        DefaultDimension.FindFirst();
        Assert.AreEqual(Uppercase(DepartmentTxt), DefaultDimension."Dimension Value Code", 'Incorrect department in default dimension.');

        DefaultDimension.SetRange("Dimension Code", 'C5COSTCENTRE');
        DefaultDimension.FindFirst();
        Assert.AreEqual(Uppercase(CostCenterTxt), DefaultDimension."Dimension Value Code", 'Incorrect cost center in default dimension.');

        DefaultDimension.SetRange("Dimension Code", 'C5PURPOSE');
        DefaultDimension.FindFirst();
        Assert.AreEqual(Uppercase(PurposeTxt), DefaultDimension."Dimension Value Code", 'Incorrect purpose in default dimension.');
    end;

    local procedure CheckCustomerExists(C5CustTable: Record "C5 CustTable")
    var
        Customer: Record Customer;
    begin
        Customer.SetRange("No.", UpperCase(C5CustTable.Account));
        Customer.FindFirst();
        Assert.AreEqual(Customer.Name, C5CustTable.Name, 'Name not migrated');
        Assert.AreEqual(Customer."Search Name", UpperCase(C5CustTable.SearchName), 'Search name not migrated');
        Assert.AreEqual(Customer.Address, C5CustTable.Address1, 'Address1 not migrated');
        Assert.AreEqual(Customer."Address 2", C5CustTable.Address2, 'Address2 not migrated');
        Assert.AreEqual(Customer."Post Code", 'AT-1100', 'Post code not migrated');
        Assert.AreEqual(Customer."Country/Region Code", 'AT', 'Country not migrated');
        Assert.AreEqual(Customer.Contact, C5CustTable.Attention, 'Attention not migrated');
        Assert.AreEqual(Customer."Phone No.", C5CustTable.Phone, 'Phone not migrated');
        Assert.AreEqual(Customer."Telex No.", C5CustTable.CellPhone, 'Cellphone not migrated');
        Assert.AreEqual(Customer."Credit Limit (LCY)", C5CustTable.BalanceMax, 'BalanceMax not migrated');
        Assert.AreEqual(Customer."Currency Code", C5CustTable.Currency, 'Currency not migrated');
        Assert.AreEqual(Customer."Customer Price Group", UpperCase(C5CustTable.PriceGroup), 'Pricegroup not migrated');
        Assert.AreEqual(Customer."Language Code", C5HelperFunctions.GetLanguageCodeForC5Language(C5CustTable.Language_), 'Language not migrated');
        Assert.AreEqual(Customer."Payment Terms Code", UpperCase(C5CustTable.Payment), 'Payment not migrated');
        Assert.AreEqual(Customer."Salesperson Code", UpperCase(C5CustTable.SalesRep), 'SalesRep not migrated');
        Assert.AreEqual(Customer."Shipment Method Code", UpperCase(C5CustTable.Delivery), 'Delivery not migrated');
        Assert.AreEqual(Customer."Invoice Disc. Code", UpperCase(C5CustTable.DiscGroup), 'Disc group not migrated');
        Assert.AreEqual(Customer.Blocked, Customer.Blocked::" ", 'Blocked not migrated');
        Assert.AreEqual(Customer."Bill-to Customer No.", UpperCase(C5CustTable.InvoiceAccount), 'InvoiceAccount not migrated');
        Assert.AreEqual(Customer."Payment Method Code", UpperCase(C5CustTable.PaymentMode), 'Payment mode not migrated');
        Assert.AreEqual(Customer."Fax No.", C5CustTable.Fax, 'Fax not migrated');
        Assert.AreEqual(Customer."VAT Registration No.", UpperCase(C5CustTable.VatNumber), 'Vat number not migrated');
        Assert.AreEqual(Customer."Home Page", C5CustTable.URL, 'Url not migrated');
        Assert.AreEqual(Customer."E-Mail", C5CustTable.Email, 'Email not migrated');
    end;

    local procedure CheckCustomerPostingSetupIsEmpty(C5CustTable: Record "C5 CustTable")
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
    begin
        Customer.SetRange("No.", UpperCase(C5CustTable.Account));
        Customer.FindFirst();
        // check customer posting group
        Assert.AreEqual('', Customer."Customer Posting Group", 'Customer Posting group migrated from CustGroup');

        Assert.RecordIsEmpty(GenJournalLine);
    end;

    local procedure CheckCustomerPostingSetup(C5CustTable: Record "C5 CustTable")
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustomerPostingGroup: Record "Customer Posting Group";
        DimensionSetEntry: Record "Dimension Set Entry";
        Customer: Record Customer;
    begin
        Customer.SetRange("No.", UpperCase(C5CustTable.Account));
        Customer.FindFirst();
        // check customer posting group
        Assert.AreEqual('CUSTGRP', Customer."Customer Posting Group", 'Customer Posting group was not migrated from CustGroup');
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        Assert.AreEqual('82020', CustomerPostingGroup."Receivables Account", 'incorrect receivables acc');

        // check general journal line
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Customer);
        GenJournalLine.SetRange("Account No.", C5CustTable.Account);
        GenJournalLine.FindFirst();
        Assert.AreEqual('CUSTMIGR', GenJournalLine."Journal Batch Name", 'Hard coded batch name incorrect');
        Assert.AreEqual(1000, GenJournalLine.Amount, 'Incorrect amount');
        Assert.AreEqual('C5MIGRATE', GenJournalLine."Document No.", 'Incorrect document number');
        Assert.AreEqual(DMY2Date(10, 4, 2014), GenJournalLine."Document Date", 'incorrect doc date');
        Assert.AreEqual(DMY2Date(10, 4, 2014), GenJournalLine."Posting Date", 'incorrect posting date');
        Assert.AreEqual(DMY2Date(12, 5, 2014), GenJournalLine."Due Date", 'incorrect due date');
        Assert.AreNotEqual('', GenJournalLine.Description, 'Empty discription');
        Assert.AreEqual(CustomerPostingGroup."Receivables Account", GenJournalLine."Bal. Account No.", 'Balance account was different than expected.');

        // check dimension on the general line
        DimensionSetEntry.SetRange("Dimension Set ID", GenJournalLine."Dimension Set ID");
        DimensionSetEntry.SetRange("Dimension Code", 'C5DEPARTMENT');
        DimensionSetEntry.FindFirst();
        Assert.AreEqual(Uppercase(Department2Txt), DimensionSetEntry."Dimension Value Code", 'Incorrect department code');
        DimensionSetEntry.SetRange("Dimension Code", 'C5COSTCENTRE');
        DimensionSetEntry.FindFirst();
        Assert.AreEqual(Uppercase(CostCenter2Txt), DimensionSetEntry."Dimension Value Code", 'Incorrect cost center code');
        DimensionSetEntry.SetRange("Dimension Code", 'C5PURPOSE');
        DimensionSetEntry.FindFirst();
        Assert.AreEqual(Uppercase(Purpose2Txt), DimensionSetEntry."Dimension Value Code", 'Incorrect purpose code');
    end;

    local procedure CreateC5CustGroup(): Text[10]
    var
        C5CustGroup: Record "C5 CustGroup";
        C5LedTable: Record "C5 LedTable";
    begin
        C5CustGroup.Init();
        C5CustGroup.RecId := 987654;
        C5CustGroup.Group := 'CustGrp';
        C5CustGroup.GroupName := 'Full group name';

        C5LedTable.DeleteAll();
        C5CustGroup.GroupAccount := '82020';
        C5LedTable.RecId := C5CustGroup.RecId;
        C5LedTable.Account := C5CustGroup.GroupAccount;
        C5LedTable.Insert();
        C5HelperFunctions.CreateGLAccount(C5CustGroup.GroupAccount);
        C5CustGroup.Insert(true);
        exit(C5CustGroup.Group);
    end;

    local procedure CreateC5CustTrans()
    var
        C5CustTrans: Record "C5 CustTrans";
    begin
        C5CustTrans.Init();
        C5CustTrans.RecId := 1;
        C5CustTrans.Account := CopyStr(CustNumTxt, 1, 10);
        C5CustTrans.Open := C5CustTrans.Open::Yes;
        C5CustTrans.BudgetCode := C5CustTrans.BudgetCode::Actual;
        C5CustTrans.Voucher := 352533;
        C5CustTrans.InvoiceNumber := 'MyInvoice';
        C5CustTrans.Txt := 'Some text';
        C5CustTrans.Date_ := DMY2Date(10, 4, 2014);
        C5CustTrans.DueDate := DMY2Date(12, 5, 2014);
        C5CustTrans.AmountMST := 1000;
        C5CustTrans.Department := CopyStr(Department2Txt, 1, 10);
        C5CustTrans.Centre := CopyStr(CostCenter2Txt, 1, 10);
        C5CustTrans.Purpose := CopyStr(Purpose2Txt, 1, 10);
        C5CustTrans.Insert();

        C5CustTrans.Init();
        C5CustTrans.RecId := 2;
        C5CustTrans.Account := CopyStr(AltCustNumTxt, 1, 10);
        C5CustTrans.Open := C5CustTrans.Open::Yes;
        C5CustTrans.BudgetCode := C5CustTrans.BudgetCode::Actual;
        C5CustTrans.Voucher := 352533;
        C5CustTrans.InvoiceNumber := 'MyInvoice2';
        C5CustTrans.Txt := 'Some text';
        C5CustTrans.Date_ := DMY2Date(10, 4, 2014);
        C5CustTrans.DueDate := DMY2Date(12, 5, 2014);
        C5CustTrans.AmountMST := 1000;
        C5CustTrans.Department := CopyStr(Department2Txt, 1, 10);
        C5CustTrans.Centre := CopyStr(CostCenter2Txt, 1, 10);
        C5CustTrans.Purpose := CopyStr(Purpose2Txt, 1, 10);
        C5CustTrans.Insert();
    end;
}
