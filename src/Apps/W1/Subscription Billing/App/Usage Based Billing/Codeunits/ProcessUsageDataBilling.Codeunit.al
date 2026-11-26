namespace Microsoft.SubscriptionBilling;

using Microsoft.Finance.Currency;

codeunit 8026 "Process Usage Data Billing"
{
    TableNo = "Usage Data Import";

    var
        UsageDataImport: Record "Usage Data Import";
        UsageDataSupplier: Record "Usage Data Supplier";
        DateTimeManagement: Codeunit "Date Time Management";
        ContractItemMgt: Codeunit "Sub. Contracts Item Management";
        ProgressTracker: Codeunit "Sub. Billing Progress Tracker";
        ProcessBillingLbl: Label 'Processing usage based billing...';
        ImportEntryDetailLbl: Label 'Import Entry No. %1', Comment = '%1 = Usage Data Import Entry No.';
        DoesNotExistErr: Label 'No data found for processing step %1.', Comment = '%1=Name of the processing step';
        ProcessServiceCommitmentProcedureNameLbl: Label 'ProcessServiceCommitment', Locked = true;
        UsageBasedPricingOptionNotImplementedErr: Label 'Unknown option %1 for %2.\\Object Type: %3 Object Name: %4, Procedure: %5', Comment = '%1=Format("Calculation Base Type"), %2 = Fieldcaption for "Calculation Base Type", %3 = Object Type, %4 = Object Name, %5 = Procedure Name';
        CalculateCustomerUsageDataBillingPriceProcedureNameLbl: Label 'CalculateCustomerUsageDataBillingPrice', Locked = true;
        CodeunitObjectLbl: Label 'Codeunit', Locked = true;
        CurrentCodeunitNameLbl: Label 'Process Usage Data Billing', Locked = true;
        NoContractFoundInUsageDataBillingErr: Label 'No contract (for Subscription %1) found for processing step %2.', Comment = '%1=Subscription Header No., %2=Processing Step';
        ChargePeriodWithoutBillingBasePeriodErr: Label 'The price and unit cost of Subscription Line %1 of Subscription %2 cannot be updated from the usage data, because the charge period from %3 to %4 does not cover any part of a billing base period.', Comment = '%1=Subscription Line Description, %2=Subscription Header No., %3=Charge Start Date, %4=Charge End Date';

    trigger OnRun()
    begin
        UsageDataImport.Copy(Rec);
        Code();
        Rec := UsageDataImport;
    end;

    local procedure Code()
    var
        UsageDataBilling: Record "Usage Data Billing";
        SubscriptionLineEntryNoList: List of [Integer];
        QuantityBeforeProcessingPerSubscription: Dictionary of [Code[20], Decimal];
        Counter: Integer;
        DetailText: Text;
    begin
        OnBeforeProcessUsageDataBilling(UsageDataImport);
        if UsageDataImport."Processing Status" = Enum::"Processing Status"::Closed then
            exit;
        UsageDataImport.SetStatus(Enum::"Processing Status"::None);

        FilterUnprocessedUsageDataBilling(UsageDataBilling, UsageDataImport."Entry No.");
        if not UsageDataBilling.IsEmpty then begin
            UsageDataBilling.ExcludeProcessingStatusError();

            UsageDataBilling.SetRange(Partner, "Service Partner"::Customer);
            if UsageDataBilling.FindSet(true) then
                repeat
                    CalculateCustomerUsageDataBillingPrice(UsageDataBilling);
                until UsageDataBilling.Next() = 0;

            UsageDataBilling.SetRange(Partner);
            this.ProgressTracker.StartActivity(ProcessBillingLbl, UsageDataBilling.Count());
            DetailText := StrSubstNo(ImportEntryDetailLbl, UsageDataImport."Entry No.");
            if UsageDataBilling.FindSet() then
                repeat
                    Counter += 1;
                    this.ProgressTracker.UpdateProgress(Counter, DetailText);
                    if SubscriptionLineEntryNoList.IndexOf(UsageDataBilling."Subscription Line Entry No.") = 0 then begin
                        SubscriptionLineEntryNoList.Add(UsageDataBilling."Subscription Line Entry No.");
                        ProcessServiceCommitment(UsageDataBilling, QuantityBeforeProcessingPerSubscription);
                    end;
                until UsageDataBilling.Next() = 0;
            this.ProgressTracker.Finish();

            SetProcessedUsageDataBillingToOk(UsageDataImport."Entry No.");
            UsageDataImport.UpdateProcessingStatus();
        end else begin
            UsageDataBilling.SetRange("Subscription Contract No.");
            if UsageDataBilling.FindFirst() then begin
                UsageDataImport.SetErrorReason(StrSubstNo(NoContractFoundInUsageDataBillingErr, UsageDataBilling."Subscription Header No.", UsageDataImport."Processing Step"));
                UsageDataBilling.SetReason(StrSubstNo(NoContractFoundInUsageDataBillingErr, UsageDataBilling."Subscription Header No.", UsageDataImport."Processing Step"));
                UsageDataBilling."Processing Status" := Enum::"Processing Status"::Error;
                UsageDataBilling.Modify(false);
            end
            else
                UsageDataImport.SetErrorReason(StrSubstNo(DoesNotExistErr, UsageDataImport."Processing Step"));
            UsageDataImport.Modify(false);
        end;
        OnAfterProcessUsageDataBilling(UsageDataImport);
    end;

    local procedure FilterUnprocessedUsageDataBilling(var UsageDataBilling: Record "Usage Data Billing"; UsageDataImportEntryNo: Integer)
    begin
        UsageDataBilling.SetRange("Usage Data Import Entry No.", UsageDataImportEntryNo);
        UsageDataBilling.SetRange("Document No.", '');
        UsageDataBilling.SetFilter("Subscription Contract No.", '<>%1', '');
    end;

    local procedure SetProcessedUsageDataBillingToOk(UsageDataImportEntryNo: Integer)
    var
        UsageDataBilling: Record "Usage Data Billing";
    begin
        // The filters are set here and not taken from the caller, because a record passed by value carries its field values but not its filters.
        FilterUnprocessedUsageDataBilling(UsageDataBilling, UsageDataImportEntryNo);
        UsageDataBilling.ExcludeProcessingStatusError();

        // Lines carrying a reason have to be validated one by one, because the Reason blob is cleared in OnValidate.
        UsageDataBilling.SetFilter("Reason (Preview)", '<>%1', '');
        if UsageDataBilling.FindSet(true) then
            repeat
                UsageDataBilling.Validate("Processing Status", Enum::"Processing Status"::Ok);
                UsageDataBilling.Modify(true);
            until UsageDataBilling.Next() = 0;

        // The remaining lines have no reason to clear. The processing status is set last, so that the filter still matches.
        UsageDataBilling.SetRange("Reason (Preview)", '');
        UsageDataBilling.SetFilter("Processing Status", '<>%1&<>%2', Enum::"Processing Status"::Error, Enum::"Processing Status"::Ok);
        UsageDataBilling.ModifyAll("Processing Date", Today(), "Processing Time", Time(), "Processing Status", Enum::"Processing Status"::Ok, false);
    end;

    local procedure CalculateCustomerUsageDataBillingPrice(var UsageDataBilling: Record "Usage Data Billing")
    var
        Currency: Record Currency;
        CustomerContract: Record "Customer Subscription Contract";
        CustomerContractLine: Record "Cust. Sub. Contract Line";
        ServiceCommitment: Record "Subscription Line";
        ServiceObject: Record "Subscription Header";
        IsHandled: Boolean;
        Amount: Decimal;
        UnitPrice: Decimal;
    begin
        if not UsageDataBilling.IsPartnerCustomer() then
            exit;
        GetCustomerContractData(CustomerContract, CustomerContractLine, ServiceCommitment, UsageDataBilling);
        SetCurrency(Currency, UsageDataBilling."Currency Code");
        UsageDataSupplier.Get(UsageDataImport."Supplier No.");

        if UsageDataSupplier."Unit Price from Import" then begin
            UnitPrice := UsageDataBilling."Unit Price";
            Amount := UsageDataBilling.Amount;
        end else
            case UsageDataBilling."Usage Base Pricing" of
                "Usage Based Pricing"::"Usage Quantity":
                    begin
                        Amount := ServiceCommitment.Amount;
                        ServiceObject.Get(ServiceCommitment."Subscription Header No.");
                        ServiceObject.TestField(Type, ServiceObject.Type::Item);
                        ContractItemMgt.GetSalesPriceForItem(UnitPrice, ServiceObject."Source No.", Abs(UsageDataBilling.Quantity), CustomerContract."Currency Code", CustomerContract."Sell-to Customer No.", CustomerContract."Bill-to Customer No.");
                        Amount := UnitPrice * Abs(UsageDataBilling.Quantity);
                        CalculateUsageDataPrices(Amount, UnitPrice, ServiceCommitment, UsageDataBilling, Abs(UsageDataBilling.Quantity));
                    end;
                "Usage Based Pricing"::"Fixed Quantity":
                    begin
                        Amount := ServiceCommitment.Amount;
                        ServiceCommitment.CalcFields("Quantity");
                        CalculateUsageDataPrices(Amount, UnitPrice, ServiceCommitment, UsageDataBilling, ServiceCommitment."Quantity");
                    end;
                "Usage Based Pricing"::"Unit Cost Surcharge":
                    begin
                        UnitPrice := UsageDataBilling."Unit Cost" * (1 + UsageDataBilling."Pricing Unit Cost Surcharge %" / 100);
                        Amount := UnitPrice * UsageDataBilling.Quantity;
                    end;
                else begin
                    IsHandled := false;
                    OnUsageBasedPricingElseCaseOnCalculateCustomerUsageDataBillingPrice(UnitPrice, Amount, UsageDataBilling, CustomerContract, IsHandled);
                    if not IsHandled then
                        Error(UsageBasedPricingOptionNotImplementedErr, Format(ServiceCommitment."Usage Based Pricing"), ServiceCommitment.FieldCaption("Usage Based Pricing"), CodeunitObjectLbl,
                                                                        CurrentCodeunitNameLbl, CalculateCustomerUsageDataBillingPriceProcedureNameLbl);
                end;

            end;

        if (UsageDataBilling.Amount <> Round(Amount, Currency."Amount Rounding Precision")) or
           (UsageDataBilling."Unit Price" <> Round(UnitPrice, Currency."Unit-Amount Rounding Precision"))
        then begin
            UsageDataBilling."Unit Price" := Round(UnitPrice, Currency."Unit-Amount Rounding Precision");
            UsageDataBilling.Amount := Round(Amount, Currency."Amount Rounding Precision");
            if UsageDataBilling.Quantity < 0 then
                UsageDataBilling.Amount *= -1;
            UsageDataBilling.Modify(true);
        end;
    end;

    local procedure ProcessServiceCommitment(var UsageDataBilling: Record "Usage Data Billing"; var QuantityBeforeProcessingPerSubscription: Dictionary of [Code[20], Decimal])
    var
        ServiceObject: Record "Subscription Header";
        ServiceCommitment: Record "Subscription Line";
        LastUsageDataBilling: Record "Usage Data Billing";
        InvalidUsageDataBilling: Record "Usage Data Billing";
        NewServiceObjectQuantity: Decimal;
        CurrencyCode: Code[10];
        UnitPrice: Decimal;
        UnitCost: Decimal;
        TotalQuantity: Decimal;
        TotalQuantityInBillingBasePeriods: Decimal;
        SubscriptionQuantityInBillingBasePeriods: Decimal;
        AverageBillingBasePeriods: Decimal;
        TotalAmount: Decimal;
        TotalCostAmount: Decimal;
        Tolerance: Decimal;
        NumberOfUsageDataBillings: Integer;
        IsHandled: Boolean;
    begin
        OnBeforeProcessSubscriptionLine(ServiceCommitment);

        if UsageDataBilling."Subscription Line Entry No." = 0 then
            exit;
        if not ServiceCommitment.Get(UsageDataBilling."Subscription Line Entry No.") then
            exit;

        ServiceObject.Get(ServiceCommitment."Subscription Header No.");
        ServiceObject.TestField(Type, ServiceObject.Type::Item);
        if not QuantityBeforeProcessingPerSubscription.ContainsKey(ServiceObject."No.") then
            QuantityBeforeProcessingPerSubscription.Add(ServiceObject."No.", ServiceObject.Quantity);
        NewServiceObjectQuantity := ServiceObject.Quantity;

        FindUsageDataBilling(LastUsageDataBilling, false, UsageDataImport."Entry No.", ServiceCommitment);
        // Only these pricings convert the usage data to billing base periods, so only they need a charge period that covers one.
        if ServiceCommitment."Usage Based Pricing" in ["Usage Based Pricing"::"Usage Quantity", "Usage Based Pricing"::"Unit Cost Surcharge"] then
            if FindUsageDataBillingWithoutBillingBasePeriod(InvalidUsageDataBilling, UsageDataImport."Entry No.", ServiceCommitment) then begin
                SetUsageDataBillingToError(UsageDataImport."Entry No.", ServiceCommitment, StrSubstNo(ChargePeriodWithoutBillingBasePeriodErr, ServiceCommitment.Description, ServiceCommitment."Subscription Header No.", InvalidUsageDataBilling."Charge Start Date", InvalidUsageDataBilling."Charge End Date"));
                exit;
            end;
        CurrencyCode := LastUsageDataBilling."Currency Code";
        UnitPrice := ServiceCommitment.Price;
        UnitCost := ServiceCommitment."Unit Cost";

        case ServiceCommitment."Usage Based Pricing" of
            "Usage Based Pricing"::"Usage Quantity":
                begin
                    CalculateSumsFromUsageDataBilling(LastUsageDataBilling, UsageDataImport."Entry No.", ServiceCommitment, TotalQuantity, TotalQuantityInBillingBasePeriods, AverageBillingBasePeriods, TotalAmount, TotalCostAmount, NumberOfUsageDataBillings);
                    NewServiceObjectQuantity := TotalQuantity;
                    CalculateUnitPriceAndCostPerBillingBasePeriod(UnitPrice, UnitCost, Tolerance, ServiceCommitment, CurrencyCode, TotalQuantityInBillingBasePeriods, TotalAmount, TotalCostAmount, NumberOfUsageDataBillings);
                    // Each Subscription Line of the Subscription is processed separately, but the rebilled quantity must be added to the Subscription only once.
                    if LastUsageDataBilling.Rebilling then
                        NewServiceObjectQuantity += QuantityBeforeProcessingPerSubscription.Get(ServiceObject."No.");
                end;
            "Usage Based Pricing"::"Fixed Quantity":
                ;
            "Usage Based Pricing"::"Unit Cost Surcharge":
                if NewServiceObjectQuantity <> 0 then begin
                    CalculateSumsFromUsageDataBilling(LastUsageDataBilling, UsageDataImport."Entry No.", ServiceCommitment, TotalQuantity, TotalQuantityInBillingBasePeriods, AverageBillingBasePeriods, TotalAmount, TotalCostAmount, NumberOfUsageDataBillings);
                    // The imported quantity does not change the Subscription quantity here, so the amounts are spread over the Subscription quantity,
                    // converted to billing base periods with the average billing base periods of the usage data.
                    SubscriptionQuantityInBillingBasePeriods := NewServiceObjectQuantity * AverageBillingBasePeriods;
                    CalculateUnitPriceAndCostPerBillingBasePeriod(UnitPrice, UnitCost, Tolerance, ServiceCommitment, CurrencyCode, SubscriptionQuantityInBillingBasePeriods, TotalAmount, TotalCostAmount, NumberOfUsageDataBillings);
                end else begin
                    UnitCost := 0;
                    UnitPrice := 0;
                end;
            else begin
                IsHandled := false;
                OnUsageBasedPricingElseCaseOnProcessSubscriptionLine(UnitCost, NewServiceObjectQuantity, ServiceCommitment, LastUsageDataBilling, IsHandled);
                if not IsHandled then
                    Error(UsageBasedPricingOptionNotImplementedErr, Format(ServiceCommitment."Usage Based Pricing"), ServiceCommitment.FieldCaption("Usage Based Pricing"), CodeunitObjectLbl,
                                                                    CurrentCodeunitNameLbl, ProcessServiceCommitmentProcedureNameLbl);
            end;
        end;

        if ServiceCommitment.IsPartnerVendor() then
            UnitPrice := UnitCost;

        UpdateServiceObjectQuantity(ServiceCommitment."Subscription Header No.", NewServiceObjectQuantity);
        //Note: Service commitment will be recalculated if the quantity in service object changes
        Commit();
        ServiceCommitment.Get(ServiceCommitment."Entry No.");
        UpdateServiceCommitment(LastUsageDataBilling, ServiceCommitment, UnitPrice, UnitCost, CurrencyCode, Tolerance);
        if UsageDataBilling.Rebilling then begin
            ServiceCommitment."Next Billing Date" := UsageDataBilling."Charge Start Date";
            ServiceCommitment.Modify();
        end;

        OnAfterProcessSubscriptionLine(ServiceCommitment);
    end;

    local procedure CalculateSumsFromUsageDataBilling(LastUsageDataBilling: Record "Usage Data Billing"; UsageDataImportEntryNo: Integer; ServiceCommitment: Record "Subscription Line"; var TotalQuantity: Decimal; var TotalQuantityInBillingBasePeriods: Decimal; var AverageBillingBasePeriods: Decimal; var TotalAmount: Decimal; var TotalCostAmount: Decimal; var NumberOfUsageDataBillings: Integer)
    var
        UsageDataBilling: Record "Usage Data Billing";
        BillingBasePeriods: Decimal;
        TotalBillingBasePeriods: Decimal;
        TotalAbsQuantity: Decimal;
        TotalAbsQuantityInBillingBasePeriods: Decimal;
    begin
        TotalQuantity := 0;
        TotalQuantityInBillingBasePeriods := 0;
        AverageBillingBasePeriods := 0;
        TotalAmount := 0;
        TotalCostAmount := 0;
        NumberOfUsageDataBillings := 0;
        UsageDataBilling.FilterOnUsageDataImportAndServiceCommitment(UsageDataImportEntryNo, ServiceCommitment);
        UsageDataBilling.SetRange("Document Type", UsageDataBilling."Document Type"::None);
        UsageDataBilling.SetRange("Charge End Date", LastUsageDataBilling."Charge End Date");
        UsageDataBilling.ExcludeProcessingStatusError();
        UsageDataBilling.SetLoadFields(Quantity, Amount, "Cost Amount", "Charge Start Date", "Charge End Date");
        if UsageDataBilling.FindSet() then
            repeat
                // Usage data billings can have different charge start dates, so each quantity is weighted with the billing base periods of its own charge period.
                BillingBasePeriods := GetBillingBasePeriodsInChargePeriod(ServiceCommitment, UsageDataBilling."Charge Start Date", UsageDataBilling."Charge End Date");
                TotalQuantity += UsageDataBilling.Quantity;
                TotalQuantityInBillingBasePeriods += UsageDataBilling.Quantity * BillingBasePeriods;
                TotalAbsQuantity += Abs(UsageDataBilling.Quantity);
                TotalAbsQuantityInBillingBasePeriods += Abs(UsageDataBilling.Quantity) * BillingBasePeriods;
                TotalBillingBasePeriods += BillingBasePeriods;
                TotalAmount += UsageDataBilling.Amount;
                TotalCostAmount += UsageDataBilling."Cost Amount";
                NumberOfUsageDataBillings += 1;
            until UsageDataBilling.Next() = 0;

        // Weighted by the absolute quantity, so that reversed quantities cannot cancel each other out and the average stays within the billing base periods of the usage data.
        if TotalAbsQuantity <> 0 then
            AverageBillingBasePeriods := TotalAbsQuantityInBillingBasePeriods / TotalAbsQuantity
        else
            if NumberOfUsageDataBillings <> 0 then
                AverageBillingBasePeriods := TotalBillingBasePeriods / NumberOfUsageDataBillings;
    end;

    local procedure CalculateUnitPriceAndCostPerBillingBasePeriod(var UnitPrice: Decimal; var UnitCost: Decimal; var Tolerance: Decimal; ServiceCommitment: Record "Subscription Line"; CurrencyCode: Code[10]; QuantityInBillingBasePeriods: Decimal; TotalAmount: Decimal; TotalCostAmount: Decimal; NumberOfUsageDataBillings: Integer)
    begin
        if QuantityInBillingBasePeriods = 0 then begin
            UnitCost := 0;
            UnitPrice := 0;
            exit;
        end;
        UnitCost := TotalCostAmount / QuantityInBillingBasePeriods;
        if ServiceCommitment.IsPartnerCustomer() then
            UnitPrice := TotalAmount / QuantityInBillingBasePeriods;
        Tolerance := GetAmountRoundingTolerance(CurrencyCode, NumberOfUsageDataBillings, QuantityInBillingBasePeriods);
    end;

    local procedure GetAmountRoundingTolerance(CurrencyCode: Code[10]; NumberOfUsageDataBillings: Integer; QuantityInBillingBasePeriods: Decimal): Decimal
    var
        Currency: Record Currency;
    begin
        // Each summed amount is rounded to the amount rounding precision, so a price per billing base period derived from the sum can deviate by up to half that precision per amount, spread over the quantity in billing base periods.
        SetCurrency(Currency, CurrencyCode);
        exit(Currency."Amount Rounding Precision" / 2 * NumberOfUsageDataBillings / Abs(QuantityInBillingBasePeriods));
    end;

    local procedure UpdateServiceObjectQuantity(ServiceObjectNo: Code[20]; NewQuantity: Decimal)
    var
        ServiceObject: Record "Subscription Header";
    begin
        if not ServiceObject.Get(ServiceObjectNo) then
            exit;
        if (ServiceObject.Quantity = NewQuantity) then
            exit;
        ServiceObject.SetHideValidationDialog(true);
        ServiceObject.Validate(Quantity, NewQuantity);
        ServiceObject.Modify(false);
    end;

    local procedure UpdateServiceCommitment(LastUsageDataBilling: Record "Usage Data Billing"; var ServiceCommitment: Record "Subscription Line"; UnitPrice: Decimal; UnitCost: Decimal; CurrencyCode: Code[10]; Tolerance: Decimal)
    var
        CurrencyExchRate: Record "Currency Exchange Rate";
        ServiceCommitmentUpdated: Boolean;
    begin
        if UnitPrice = 0 then
            exit;

        // Unit price and unit cost are per billing base period, as the Subscription Line stores them.
        if Abs(ServiceCommitment.Price - UnitPrice) > Tolerance then begin
            ServiceCommitment.Price := UnitPrice;
            if ServiceCommitment."Currency Code" <> CurrencyCode then
                ServiceCommitment.Price := CurrencyExchRate.ExchangeAmtFCYToFCY(LastUsageDataBilling."Charge End Date", CurrencyCode, ServiceCommitment."Currency Code", ServiceCommitment.Price);

            ServiceCommitment.Validate(Price, ServiceCommitment.Price);
            ServiceCommitment.Validate("Calculation Base Amount", ServiceCommitment.Price / (ServiceCommitment."Calculation Base %" / 100));
            ServiceCommitmentUpdated := true;
        end;

        if (ServiceCommitment.Partner = ServiceCommitment.Partner::Customer) and (Abs(ServiceCommitment."Unit Cost" - UnitCost) > Tolerance) then begin
            ServiceCommitment."Unit Cost" := UnitCost;
            if ServiceCommitment."Currency Code" = CurrencyCode then
                ServiceCommitment."Unit Cost (LCY)" := ServiceCommitment."Unit Cost"
            else
                ServiceCommitment."Unit Cost (LCY)" := CurrencyExchRate.ExchangeAmtFCYToLCY(LastUsageDataBilling."Charge End Date", CurrencyCode, ServiceCommitment."Unit Cost", CurrencyExchRate.ExchangeRate(LastUsageDataBilling."Charge End Date", CurrencyCode));
            ServiceCommitmentUpdated := true;
        end;

        if not ServiceCommitmentUpdated then
            exit;

        ServiceCommitment.Modify(false);
    end;

    local procedure GetBillingBasePeriodsInChargePeriod(ServiceCommitment: Record "Subscription Line"; ChargeStartDate: Date; ChargeEndDate: Date): Decimal
    begin
        // UnitPriceForPeriod is linear in Price, so a price of 1 yields the number of billing base periods in the charge period.
        ServiceCommitment.Price := 1;
        exit(ServiceCommitment.UnitPriceForPeriod(ChargeStartDate, ChargeEndDate));
    end;

    local procedure GetCustomerContractData(var CustomerContract: Record "Customer Subscription Contract"; var CustomerContractLine: Record "Cust. Sub. Contract Line"; var ServiceCommitment: Record "Subscription Line"; UsageDataBilling: Record "Usage Data Billing")
    begin
        CustomerContract.Get(UsageDataBilling."Subscription Contract No.");
        CustomerContractLine.Get(UsageDataBilling."Subscription Contract No.", UsageDataBilling."Subscription Contract Line No.");
        CustomerContractLine.GetServiceCommitment(ServiceCommitment);
    end;

    local procedure SetCurrency(var Currency: Record Currency; CurrencyCode: Code[10])
    begin
        if CurrencyCode <> '' then
            Currency.Get(CurrencyCode)
        else
            Currency.InitRoundingPrecision();
    end;

    local procedure FindUsageDataBilling(var FoundUsageDataBilling: Record "Usage Data Billing"; SortAscending: Boolean; UsageDataImportEntryNo: Integer; ServiceCommitment: Record "Subscription Line")
    var
        UsageDataBilling: Record "Usage Data Billing";
    begin
        UsageDataBilling.SetCurrentKey("Charge End Date");
        UsageDataBilling.SetAscending("Charge End Date", SortAscending);
        UsageDataBilling.FilterOnUsageDataImportAndServiceCommitment(UsageDataImportEntryNo, ServiceCommitment);
        UsageDataBilling.SetRange("Document Type", UsageDataBilling."Document Type"::None);
        UsageDataBilling.ExcludeProcessingStatusError();
        if UsageDataBilling.FindFirst() then
            FoundUsageDataBilling := UsageDataBilling;
    end;

    local procedure FindUsageDataBillingWithoutBillingBasePeriod(var FoundUsageDataBilling: Record "Usage Data Billing"; UsageDataImportEntryNo: Integer; ServiceCommitment: Record "Subscription Line"): Boolean
    var
        UsageDataBilling: Record "Usage Data Billing";
    begin
        UsageDataBilling.FilterOnUsageDataImportAndServiceCommitment(UsageDataImportEntryNo, ServiceCommitment);
        UsageDataBilling.SetRange("Document Type", UsageDataBilling."Document Type"::None);
        UsageDataBilling.ExcludeProcessingStatusError();
        UsageDataBilling.SetLoadFields("Charge Start Date", "Charge End Date");
        if UsageDataBilling.FindSet() then
            repeat
                if GetBillingBasePeriodsInChargePeriod(ServiceCommitment, UsageDataBilling."Charge Start Date", UsageDataBilling."Charge End Date") <= 0 then begin
                    FoundUsageDataBilling := UsageDataBilling;
                    exit(true);
                end;
            until UsageDataBilling.Next() = 0;
        exit(false);
    end;

    local procedure SetUsageDataBillingToError(UsageDataImportEntryNo: Integer; ServiceCommitment: Record "Subscription Line"; ReasonText: Text)
    var
        UsageDataBilling: Record "Usage Data Billing";
    begin
        // This blocks the whole Subscription Line for this import: all its usage data billings are set to Error, not only the one with the invalid charge period.
        UsageDataBilling.FilterOnUsageDataImportAndServiceCommitment(UsageDataImportEntryNo, ServiceCommitment);
        UsageDataBilling.SetRange("Document Type", UsageDataBilling."Document Type"::None);
        UsageDataBilling.ExcludeProcessingStatusError();
        if UsageDataBilling.FindSet(true) then
            repeat
                UsageDataBilling.SetReason(ReasonText);
                UsageDataBilling."Processing Status" := Enum::"Processing Status"::Error;
                UsageDataBilling.Modify(false);
            until UsageDataBilling.Next() = 0;
    end;

    local procedure CalculateUsageDataPrices(var Amount: Decimal; var UnitPrice: Decimal; ServiceCommitment: Record "Subscription Line"; var UsageDataBilling: Record "Usage Data Billing"; Quantity: Decimal)
    begin
        if (ServiceCommitment."Discount %" = 100) or (Quantity = 0) then begin
            UnitPrice := 0;
            Amount := 0;
            exit;
        end;
        OnBeforeCalculateUsageDataUnitPriceForPeriod(UnitPrice, ServiceCommitment, UsageDataBilling);
        UnitPrice := ServiceCommitment.UnitPriceForPeriod(UsageDataBilling."Charge Start Date", UsageDataBilling."Charge End Date");
        OnAfterCalculateUsageDataUnitPriceForPeriod(UnitPrice, ServiceCommitment, UsageDataBilling);
        Amount := UnitPrice * Quantity;
    end;

    internal procedure SetRoundingPrecision(var RoundingPrecision: Decimal; UnitPrice: Decimal; Currency: Record Currency)
    begin
        RoundingPrecision := DateTimeManagement.GetRoundingPrecision(DateTimeManagement.GetNumberOfDecimals(UnitPrice));
        if RoundingPrecision = 1 then begin
            Currency.InitRoundingPrecision();
            RoundingPrecision := Currency."Unit-Amount Rounding Precision";
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessUsageDataBilling(UsageDataImport: Record "Usage Data Import")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessUsageDataBilling(UsageDataImport: Record "Usage Data Import")
    begin
    end;

    /// <summary>
    /// Raised in ProcessServiceCommitment for a Usage Based Pricing that is not handled by Subscription Billing.
    /// UnitCost is passed in and returned per billing base period of the Subscription Line, as stored in its Unit Cost field.
    /// Set IsHandled to true when the pricing is handled.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnUsageBasedPricingElseCaseOnProcessSubscriptionLine(var UnitCost: Decimal; var NewServiceObjectQuantity: Decimal; var SubscriptionLine: Record "Subscription Line"; LastUsageDataBilling: Record "Usage Data Billing"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUsageBasedPricingElseCaseOnCalculateCustomerUsageDataBillingPrice(var UnitPrice: Decimal; var Amount: Decimal; var UsageDataBilling: Record "Usage Data Billing"; CustomerSubscriptionContract: Record "Customer Subscription Contract"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessSubscriptionLine(var SubscriptionLine: Record "Subscription Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessSubscriptionLine(var SubscriptionLine: Record "Subscription Line")
    begin
    end;

    /// <summary>
    /// Raised before UnitPriceForPeriod is called in CalculateUsageDataPrices.
    /// Passes the UnitPrice that was calculated prior to the period scaling (for example, a tier-calculated
    /// per-unit price from GetSalesPriceForItem). Subscribers can observe this value and store it for later use.
    /// No code is skipped - UnitPriceForPeriod always runs after this event.
    /// </summary>
    /// <param name="UnitPrice">The unit price before period scaling (read-only for subscribers).</param>
    /// <param name="ServiceCommitment">The subscription line for the current billing.</param>
    /// <param name="UsageDataBilling">The usage data billing record for the current period.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateUsageDataUnitPriceForPeriod(UnitPrice: Decimal; var ServiceCommitment: Record "Subscription Line"; var UsageDataBilling: Record "Usage Data Billing")
    begin
    end;

    /// <summary>
    /// Raised after the unit price for the billing period has been calculated via UnitPriceForPeriod.
    /// Subscribers can override UnitPrice with a custom value (for example, a price from a different source or price list).
    /// </summary>
    /// <param name="UnitPrice">The calculated unit price for the period. Subscribers can override this value.</param>
    /// <param name="ServiceCommitment">The subscription line for the current billing.</param>
    /// <param name="UsageDataBilling">The usage data billing record for the current period.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateUsageDataUnitPriceForPeriod(var UnitPrice: Decimal; var ServiceCommitment: Record "Subscription Line"; var UsageDataBilling: Record "Usage Data Billing")
    begin
    end;
}
