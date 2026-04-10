codeunit 139184 "CRM Bus. Logic Simulator Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CRM Integration] [Mock]
    end;

    var
        Assert: Codeunit Assert;
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        SalesOrderIsNotEditableErr: Label 'CRM Sales order is not editable.';
        ReadOnlyEntityCannotBeUpdatedErr: Label 'The entity cannot be updated because it is read-only.';
        InactiveInvoiceCannotBePaidErr: Label 'The invoice cannot be paid because it is not in active state.';
        PriceListLineAlreadyExistsErr: Label 'This product and unit combination has a price for this price list.';
        ProductIdMissingErr: Label 'The product id is missing.';
        ModifiedOnErr: Label 'ModifiedOn %1 should be bigger than CreatedOn %2';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ProductPriceLevelNeedsPriceLevelIDOnInsert()
    var
        CRMProductpricelevel: Record "CRM Productpricelevel";
    begin
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();

        CRMProductpricelevel.Init();
        asserterror CRMProductpricelevel.Insert();
        Assert.ExpectedTestFieldError(CRMProductpricelevel.FieldCaption(PriceLevelId), '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ProductPriceLevelMustHaveProductIDOnInsert()
    var
        CRMProductpricelevel: Record "CRM Productpricelevel";
    begin
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();

        CRMProductpricelevel.Init();
        CRMProductpricelevel.PriceLevelId := CreateGuid();
        asserterror CRMProductpricelevel.Insert();
        Assert.ExpectedError(ProductIdMissingErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ProductPriceLevelMustHaveUniqueProductAndUoMOnInsert()
    var
        CRMProductpricelevel: Record "CRM Productpricelevel";
    begin
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();

        CRMProductpricelevel.Init();
        CRMProductpricelevel.ProductPriceLevelId := CreateGuid();
        CRMProductpricelevel.PriceLevelId := CreateGuid();
        CRMProductpricelevel.ProductId := CreateGuid();
        CRMProductpricelevel.UoMId := CreateGuid();
        CRMProductpricelevel.Amount := 1.0;
        CRMProductpricelevel.Insert();
        // another line with the same pair of ProductId + UoMId
        CRMProductpricelevel.ProductPriceLevelId := CreateGuid();
        CRMProductpricelevel.Amount += 1;
        asserterror CRMProductpricelevel.Insert();
        Assert.ExpectedError(PriceListLineAlreadyExistsErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InvoiceDetailGetsBlankAmountsOnInsert()
    var
        CRMInvoicedetail: Record "CRM Invoicedetail";
    begin
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();

        CRMInvoicedetail.Init();
        CRMInvoicedetail.BaseAmount := 1.0;
        CRMInvoicedetail.ExtendedAmount := 2.0;
        CRMInvoicedetail.Insert();
        // handled by ValidateSalesInvoiceLineOnInsert
        CRMInvoicedetail.TestField(BaseAmount, 0);
        CRMInvoicedetail.TestField(ExtendedAmount, 0);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CurrencyWithZeroExchangeRateFailsOnInsert()
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
    begin
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();

        CRMTransactioncurrency.TransactionCurrencyId := CreateGuid();
        CRMTransactioncurrency.ISOCurrencyCode := '12345';
        asserterror CRMTransactioncurrency.Insert();
        // handled by ValidateCurrencyOnInsert
        Assert.ExpectedTestFieldError(CRMTransactioncurrency.FieldCaption(ExchangeRate), '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesOrderShouldNotBeEditableIfSubmitted()
    var
        CRMSalesorder: Record "CRM Salesorder";
    begin
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();

        CRMSalesorder.SalesOrderId := CreateGuid();
        CRMSalesorder.StateCode := CRMSalesorder.StateCode::Submitted;
        CRMSalesorder.LastBackofficeSubmit := 0D;
        CRMSalesorder.Insert();

        CRMSalesorder.LastBackofficeSubmit := Today;
        asserterror CRMSalesorder.Modify(true);

        Assert.ExpectedError(SalesOrderIsNotEditableErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesOrderAmountsShouldBeRecalculatedOnLineModify()
    var
        CRMSalesorder: Record "CRM Salesorder";
        CRMSalesorderdetail: array[2] of Record "CRM Salesorderdetail";
        DiscountPctAmount: Decimal;
    begin
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();

        // [GIVEN] the CRM Salesorder with one line
        CRMSalesorder.SalesOrderId := CreateGuid();
        CRMSalesorder.Insert();

        CRMSalesorderdetail[1].SalesOrderDetailId := CreateGuid();
        CRMSalesorderdetail[1].SalesOrderId := CRMSalesorder.SalesOrderId;
        CRMSalesorderdetail[1].Insert();
        // [GIVEN] the line contains volume and manual discounts
        CRMSalesorderdetail[1].Quantity := 10;
        CRMSalesorderdetail[1].ManualDiscountAmount := 400;
        CRMSalesorderdetail[1].VolumeDiscountAmount := 280;
        CRMSalesorderdetail[1].PricePerUnit := 4000;
        CRMSalesorderdetail[1].Tax := 5000;
        // [WHEN] Modify the order line
        CRMSalesorderdetail[1].Modify();
        // recalc in onModify
        // [THEN] the line is recalculated: BaseAmount, ExtendedAmount
        CRMSalesorderdetail[1].TestField(BaseAmount, (CRMSalesorderdetail[1].PricePerUnit - CRMSalesorderdetail[1].VolumeDiscountAmount) * CRMSalesorderdetail[1].Quantity);
        CRMSalesorderdetail[1].TestField(ExtendedAmount, CRMSalesorderdetail[1].BaseAmount - CRMSalesorderdetail[1].ManualDiscountAmount + CRMSalesorderdetail[1].Tax);
        // [GIVEN] added the second line
        CRMSalesorderdetail[2] := CRMSalesorderdetail[1];
        CRMSalesorderdetail[2].SalesOrderDetailId := CreateGuid();
        CRMSalesorderdetail[2].Insert();
        // [WHEN] Quantity, ManualDiscountAmount, and Tax are changed in the 2nd line
        CRMSalesorderdetail[2].Quantity := 5;
        CRMSalesorderdetail[2].ManualDiscountAmount := 250;
        CRMSalesorderdetail[2].Tax := 3000;
        CRMSalesorderdetail[2].Modify();
        // recalc in onModify
        // [THEN] the 2nd line is recalculated: BaseAmount, ExtendedAmount
        CRMSalesorderdetail[2].TestField(BaseAmount, (CRMSalesorderdetail[2].PricePerUnit - CRMSalesorderdetail[2].VolumeDiscountAmount) * CRMSalesorderdetail[2].Quantity);
        CRMSalesorderdetail[2].TestField(ExtendedAmount, CRMSalesorderdetail[2].BaseAmount - CRMSalesorderdetail[2].ManualDiscountAmount + CRMSalesorderdetail[2].Tax);
        // [THEN] the header is recalculated: TotalLineItemDiscountAmount, TotalLineItemAmount, TotalTax
        CRMSalesorder.Find();
        CRMSalesorder.TestField(
          TotalLineItemDiscountAmount,
          CRMSalesorderdetail[1].ManualDiscountAmount + CRMSalesorderdetail[2].ManualDiscountAmount);
        CRMSalesorder.TestField(
          TotalLineItemAmount,
          CRMSalesorderdetail[1].BaseAmount + CRMSalesorderdetail[2].BaseAmount - CRMSalesorder.TotalLineItemDiscountAmount);
        CRMSalesorder.TestField(TotalTax, CRMSalesorderdetail[1].Tax + CRMSalesorderdetail[2].Tax);
        // [THEN] TotalAmount = TotalLineItemAmount + Total Tax, as no discounts and freight on the header
        CRMSalesorder.TestField(TotalAmountLessFreight, CRMSalesorder.TotalLineItemAmount);
        CRMSalesorder.TestField(TotalDiscountAmount, CRMSalesorder.TotalLineItemDiscountAmount);
        CRMSalesorder.TestField(TotalAmount, CRMSalesorder.TotalLineItemAmount + CRMSalesorder.TotalTax);
        // [WHEN] add discounts and freight to the header
        CRMSalesorder.DiscountAmount := 3500;
        CRMSalesorder.FreightAmount := 1020;
        CRMSalesorder.DiscountPercentage := 9;
        CRMSalesorder.Modify();
        // recalc in onModify
        // [THEN] TotalAmount includes discounts and freight
        DiscountPctAmount := Round(CRMSalesorder.TotalLineItemAmount * CRMSalesorder.DiscountPercentage / 100);
        CRMSalesorder.TestField(TotalAmountLessFreight, CRMSalesorder.TotalLineItemAmount - DiscountPctAmount - CRMSalesorder.DiscountAmount);
        CRMSalesorder.TestField(TotalDiscountAmount, CRMSalesorder.TotalLineItemDiscountAmount + DiscountPctAmount + CRMSalesorder.DiscountAmount);
        CRMSalesorder.TestField(TotalAmount, CRMSalesorder.TotalAmountLessFreight + CRMSalesorder.FreightAmount + CRMSalesorder.TotalTax);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InvoiceIsReadOnlyIfStateIsPaid()
    var
        CRMInvoice: Record "CRM Invoice";
    begin
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();

        CRMInvoice.InvoiceId := CreateGuid();
        CRMInvoice.StateCode := CRMInvoice.StateCode::Paid;
        CRMInvoice.StatusCode := CRMInvoice.StatusCode::Partial;
        CRMInvoice.Insert();

        CRMInvoice.StatusCode := CRMInvoice.StatusCode::Complete;
        asserterror CRMInvoice.Modify();

        Assert.ExpectedError(ReadOnlyEntityCannotBeUpdatedErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InvoiceIsReadOnlyIfStateIsCancelled()
    var
        CRMInvoice: Record "CRM Invoice";
    begin
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();

        CRMInvoice.InvoiceId := CreateGuid();
        CRMInvoice.StateCode := CRMInvoice.StateCode::Canceled;
        CRMInvoice.StatusCode := CRMInvoice.StatusCode::Canceled;
        CRMInvoice.Insert();

        CRMInvoice.StateCode := CRMInvoice.StateCode::Paid;
        CRMInvoice.StatusCode := CRMInvoice.StatusCode::Complete;
        asserterror CRMInvoice.Modify();

        Assert.ExpectedError(InactiveInvoiceCannotBePaidErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CRMAccountModifiedOnDefinedOnModify()
    var
        CRMAccount: Record "CRM Account";
    begin
        // [SCENARIO] INSERT(TRUE) and MODIFY(TRUE) on CRM Account update "CreatedOn" and "ModifiedOn"
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();

        CRMAccount.Init();
        CRMAccount.AccountId := CreateGuid();
        // [WHEN] CRMAccount.INSERT(TRUE)
        CRMAccount.Insert(true);

        // [THEN] CreatedOn = ModifiedOn, both are not blank
        CRMAccount.TestField(CreatedOn);
        CRMAccount.TestField(ModifiedOn, CRMAccount.CreatedOn);

        // [WHEN] CRMAccount.MODIFY(TRUE) (a bit later to see a difference between CreatedOn and ModifiedOn)
        Sleep(50);
        CRMAccount.Modify(true);

        // [THEN] ModifiedOn > CreatedOn, both are not blank
        CRMAccount.TestField(CreatedOn);
        if CRMAccount.CreatedOn >= CRMAccount.ModifiedOn then
            Error(
              StrSubstNo(
                ModifiedOnErr, Format(CRMAccount.ModifiedOn, 0, 9), Format(CRMAccount.CreatedOn, 0, 9)));
    end;
}

