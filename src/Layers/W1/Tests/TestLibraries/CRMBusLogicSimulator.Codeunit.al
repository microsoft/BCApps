codeunit 139192 "CRM Bus. Logic Simulator"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        SalesOrderIsNotEditableErr: Label 'CRM Sales order is not editable.';
        ReadOnlyEntityCannotBeUpdatedErr: Label 'The entity cannot be updated because it is read-only.';
        InactiveInvoiceCannotBePaidErr: Label 'The invoice cannot be paid because it is not in active state.';
        PriceListLineAlreadyExistsErr: Label 'This product and unit combination has a price for this price list.';
        ProductIdMissingErr: Label 'The product id is missing.';
        CRMTimeDiffSeconds: Integer;

    [Scope('OnPrem')]
    procedure SetCRMTimeDiff(TimeDiffSeconds: Integer)
    begin
        CRMTimeDiffSeconds := TimeDiffSeconds;
    end;

    local procedure CurrentCRMDateTime(): DateTime
    begin
        exit(CurrentDateTime() + (CRMTimeDiffSeconds * 1000));
    end;

    [EventSubscriber(ObjectType::Table, Database::"CRM Transactioncurrency", 'OnBeforeInsertEvent', '', false, false)]
    local procedure ValidateCurrencyOnInsert(var Rec: Record "CRM Transactioncurrency"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;
        // ISOCurrencyCode and ExchangeRate must not be zero
        Rec.TestField(ISOCurrencyCode);
        Rec.TestField(ExchangeRate);
    end;

    [EventSubscriber(ObjectType::Table, Database::"CRM Product", 'OnBeforeInsertEvent', '', false, false)]
    local procedure ValidateProductOnInsert(var Rec: Record "CRM Product"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;
        Rec.StateCode := Rec.StateCode::Active;
    end;

    [EventSubscriber(ObjectType::Table, Database::"CRM Productpricelevel", 'OnBeforeInsertEvent', '', false, false)]
    local procedure ValidateProductPriceLevelOnInsert(var Rec: Record "CRM Productpricelevel"; RunTrigger: Boolean)
    var
        CRMProductpricelevel: Record "CRM Productpricelevel";
    begin
        if Rec.IsTemporary then
            exit;
        // PriceLevelID and ProductID must not be blank
        Rec.TestField(PriceLevelId);
        if IsNullGuid(Rec.ProductId) then
            Error(ProductIdMissingErr);
        // (Product + UoM) should be unique
        CRMProductpricelevel.SetRange(PriceLevelId, Rec.PriceLevelId);
        CRMProductpricelevel.SetRange(ProductId, Rec.ProductId);
        CRMProductpricelevel.SetRange(UoMId, Rec.UoMId);
        if not CRMProductpricelevel.IsEmpty() then
            Error(PriceListLineAlreadyExistsErr);
    end;

    [EventSubscriber(ObjectType::Table, Database::"CRM Invoicedetail", 'OnBeforeInsertEvent', '', false, false)]
    local procedure ValidateSalesInvoiceLineOnInsert(var Rec: Record "CRM Invoicedetail"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;
        // CRM blanks BaseAmount and ExtendedAmount
        Rec.BaseAmount := 0;
        Rec.ExtendedAmount := 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::"CRM Salesorder", 'OnBeforeModifyEvent', '', false, false)]
    local procedure ValidateSalesOrderOnModify(var Rec: Record "CRM Salesorder"; var xRec: Record "CRM Salesorder"; RunTrigger: Boolean)
    var
        xCRMSalesorder: Record "CRM Salesorder";
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if Rec.IsTemporary then
            exit;

        if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then
            exit;

        xCRMSalesorder := Rec;
        xCRMSalesorder.Find();
        if (Rec.StateCode = Rec.StateCode::Submitted) and (xCRMSalesorder.StateCode = Rec.StateCode::Submitted) and RunTrigger then
            Error(SalesOrderIsNotEditableErr);

        RecalculateSalesOrder(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"CRM Salesorderdetail", 'OnBeforeModifyEvent', '', false, false)]
    local procedure ValidateSalesOrderDetailOnBeforeModify(var Rec: Record "CRM Salesorderdetail"; var xRec: Record "CRM Salesorderdetail"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;

        Rec.BaseAmount := (Rec.PricePerUnit - Rec.VolumeDiscountAmount) * Rec.Quantity;
        Rec.ExtendedAmount := Rec.BaseAmount - Rec.ManualDiscountAmount + Rec.Tax;
    end;

    [EventSubscriber(ObjectType::Table, Database::"CRM Salesorderdetail", 'OnAfterModifyEvent', '', false, false)]
    local procedure ValidateSalesOrderDetailOnAfterModify(var Rec: Record "CRM Salesorderdetail"; var xRec: Record "CRM Salesorderdetail"; RunTrigger: Boolean)
    var
        CRMSalesorder: Record "CRM Salesorder";
    begin
        if Rec.IsTemporary then
            exit;

        CRMSalesorder.Get(Rec.SalesOrderId);
        RecalculateSalesOrder(CRMSalesorder);
        CRMSalesorder.Modify();
    end;

    [EventSubscriber(ObjectType::Table, Database::"CRM Invoice", 'OnBeforeModifyEvent', '', false, false)]
    local procedure ValidateSalesInvoiceOnBeforeModify(var Rec: Record "CRM Invoice"; var xRec: Record "CRM Invoice"; RunTrigger: Boolean)
    var
        xCRMInvoice: Record "CRM Invoice";
    begin
        if Rec.IsTemporary then
            exit;

        xCRMInvoice := Rec;
        xCRMInvoice.Find();
        if Rec.StateCode = Rec.StateCode::Paid then
            case xCRMInvoice.StateCode of
                xCRMInvoice.StateCode::Paid:
                    Error(ReadOnlyEntityCannotBeUpdatedErr);
                xCRMInvoice.StateCode::Canceled:
                    Error(InactiveInvoiceCannotBePaidErr);
            end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"CRM Account", 'OnBeforeInsertEvent', '', false, false)]
    local procedure ValidateCRMAccountCreatedOnOnBeforeInsert(var Rec: Record "CRM Account"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or not RunTrigger then
            exit;
        Rec.CreatedOn := CurrentCRMDateTime();
        Rec.ModifiedOn := Rec.CreatedOn;
    end;

    [EventSubscriber(ObjectType::Table, Database::"CRM Account", 'OnBeforeModifyEvent', '', false, false)]
    local procedure ValidateCRMAccountCreatedOnOnBeforeModify(var Rec: Record "CRM Account"; var xRec: Record "CRM Account"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or not RunTrigger then
            exit;
        Rec.ModifiedOn := CurrentCRMDateTime();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Synch. Helper", 'OnBeforeFulfillSalesOrder', '', false, false)]
    local procedure HandleOnBeforeFulfillSalesOrder(var SalesOrderId: Guid)
    var
        CRMSalesorder: Record "CRM Salesorder";
    begin
        if CRMSalesorder.Get(SalesOrderId) then begin
            CRMSalesorder.StateCode := CRMSalesorder.StateCode::Fulfilled;
            CRMSalesorder.Modify();
        end;
    end;


    local procedure RecalculateSalesOrder(var CRMSalesorder: Record "CRM Salesorder")
    var
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        TotalHeaderDiscountAmount: Decimal;
    begin
        CRMSalesorderdetail.SetRange(SalesOrderId, CRMSalesorder.SalesOrderId);
        CRMSalesorderdetail.CalcSums(ManualDiscountAmount, BaseAmount, Tax);

        CRMSalesorder.TotalLineItemDiscountAmount := CRMSalesorderdetail.ManualDiscountAmount;
        CRMSalesorder.TotalLineItemAmount := CRMSalesorderdetail.BaseAmount - CRMSalesorder.TotalLineItemDiscountAmount;
        CRMSalesorder.TotalTax := CRMSalesorderdetail.Tax;
        TotalHeaderDiscountAmount :=
          CRMSalesorder.DiscountAmount + Round(CRMSalesorder.TotalLineItemAmount * CRMSalesorder.DiscountPercentage / 100);
        CRMSalesorder.TotalDiscountAmount := TotalHeaderDiscountAmount + CRMSalesorder.TotalLineItemDiscountAmount;
        CRMSalesorder.TotalAmountLessFreight := CRMSalesorder.TotalLineItemAmount - TotalHeaderDiscountAmount;
        CRMSalesorder.TotalAmount := CRMSalesorder.TotalAmountLessFreight + CRMSalesorder.FreightAmount + CRMSalesorder.TotalTax;
    end;
}

