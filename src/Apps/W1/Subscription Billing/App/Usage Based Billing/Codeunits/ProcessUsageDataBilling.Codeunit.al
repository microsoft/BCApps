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
        CreditedQtyExceedsSubscribedQtyErr: Label 'The usage data for Subscription %1 adds up to a quantity of %2, which credits more than the quantity of %3 that is currently subscribed.', Comment = '%1=Subscription Header No., %2=Total quantity of the usage data, %3=Quantity of the Subscription';

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

            UsageDataBilling.SetRange(Partner, "Service Partner"::Vendor);
            if UsageDataBilling.FindSet(true) then
                repeat
                    CalculateVendorUsageDataBillingPrice(UsageDataBilling);
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
        UsageDataBillingChanged: Boolean;
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
                        // The surcharge is put on the cost the vendor is charged for the charge period, so that the margin is kept.
                        Amount := ChargePeriodCostAmount(UsageDataBilling, ServiceCommitment) * (1 + UsageDataBilling."Pricing Unit Cost Surcharge %" / 100);
                        if UsageDataBilling.Quantity <> 0 then
                            UnitPrice := Amount / Abs(UsageDataBilling.Quantity)
                        else
                            UnitPrice := 0;
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
            UsageDataBillingChanged := true;
        end;
        // The cost of customer usage data covers the charge period like its Amount. An option that an extension prices keeps the imported Cost Amount.
        if IsKnownUsageBasedPricing(UsageDataBilling."Usage Base Pricing") then
            if SetCostAmount(UsageDataBilling, ChargePeriodCostAmount(UsageDataBilling, ServiceCommitment)) then
                UsageDataBillingChanged := true;
        if UsageDataBillingChanged then
            UsageDataBilling.Modify(true);
    end;

    local procedure CalculateVendorUsageDataBillingPrice(var UsageDataBilling: Record "Usage Data Billing")
    var
        VendorContract: Record "Vendor Subscription Contract";
        VendorContractLine: Record "Vend. Sub. Contract Line";
        ServiceCommitment: Record "Subscription Line";
        IsHandled: Boolean;
        CostAmount: Decimal;
    begin
        if not UsageDataBilling.IsPartnerVendor() then
            exit;
        if not GetVendorContractData(VendorContract, VendorContractLine, ServiceCommitment, UsageDataBilling) then
            exit;

        if IsKnownUsageBasedPricing(UsageDataBilling."Usage Base Pricing") then
            CostAmount := ChargePeriodCostAmount(UsageDataBilling, ServiceCommitment)
        else begin
            // Extensions that add a pricing option may not subscribe to this event, so an unhandled option keeps the imported Cost Amount.
            IsHandled := false;
            OnUsageBasedPricingElseCaseOnCalculateVendorUsageDataBillingPrice(CostAmount, UsageDataBilling, VendorContract, IsHandled);
            if not IsHandled then
                exit;
        end;

        if SetCostAmount(UsageDataBilling, CostAmount) then
            UsageDataBilling.Modify(true);
    end;

    local procedure IsKnownUsageBasedPricing(UsageBasedPricing: Enum "Usage Based Pricing"): Boolean
    begin
        exit(UsageBasedPricing in ["Usage Based Pricing"::"Usage Quantity", "Usage Based Pricing"::"Fixed Quantity", "Usage Based Pricing"::"Unit Cost Surcharge"]);
    end;

    local procedure SetCostAmount(var UsageDataBilling: Record "Usage Data Billing"; CostAmountForAbsoluteQuantity: Decimal): Boolean
    var
        Currency: Record Currency;
        CostAmount: Decimal;
    begin
        SetCurrency(Currency, UsageDataBilling."Currency Code");
        CostAmount := RoundWithSignOfQuantity(CostAmountForAbsoluteQuantity, UsageDataBilling.Quantity, Currency);
        if UsageDataBilling."Cost Amount" = CostAmount then
            exit(false);
        UsageDataBilling."Cost Amount" := CostAmount;
        exit(true);
    end;

    local procedure ProcessServiceCommitment(var UsageDataBilling: Record "Usage Data Billing"; var QuantityBeforeProcessingPerSubscription: Dictionary of [Code[20], Decimal])
    var
        ServiceObject: Record "Subscription Header";
        ServiceCommitment: Record "Subscription Line";
        LastUsageDataBilling: Record "Usage Data Billing";
        NewServiceObjectQuantity: Decimal;
        SubscriptionQuantity: Decimal;
        CurrencyCode: Code[10];
        UnitPrice: Decimal;
        UnitCost: Decimal;
        TotalQuantity: Decimal;
        TotalAmount: Decimal;
        UnitCostPerBillingBasePeriod: Decimal;
        QuantityOfUnitCost: Decimal;
        CreditedQuantity: Decimal;
        PriceIsPerBillingBasePeriod: Boolean;
        UnitCostIsPerBillingBasePeriod: Boolean;
        UsageDataBillingIsAccepted: Boolean;
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
        // Another Subscription Line of this import may already have changed the quantity of the Subscription.
        SubscriptionQuantity := QuantityBeforeProcessingPerSubscription.Get(ServiceObject."No.");
        UnitPrice := ServiceCommitment.Price;
        UnitCost := ServiceCommitment."Unit Cost";

        FindUsageDataBilling(LastUsageDataBilling, false, UsageDataImport."Entry No.", ServiceCommitment);
        CurrencyCode := LastUsageDataBilling."Currency Code";
        // The cost per Billing Base Period is the Price of a vendor Subscription Line and the Unit Cost of a customer Subscription Line, so it is calculated once.
        if ServiceCommitment."Usage Based Pricing" in ["Usage Based Pricing"::"Usage Quantity", "Usage Based Pricing"::"Unit Cost Surcharge"] then
            UnitCostPerBillingBasePeriod := CalculateUnitCostPerBillingBasePeriod(LastUsageDataBilling, UsageDataImport."Entry No.", ServiceCommitment, QuantityOfUnitCost);

        case ServiceCommitment."Usage Based Pricing" of
            "Usage Based Pricing"::"Usage Quantity":
                begin
                    CalculateSumsFromUsageDataBilling(LastUsageDataBilling, UsageDataImport."Entry No.", ServiceCommitment, TotalQuantity, TotalAmount);
                    NewServiceObjectQuantity := TotalQuantity;
                    // Usage data billing accepted by an earlier run has already changed the quantity of the Subscription, which is therefore no longer
                    // the quantity its credit was checked against.
                    UsageDataBillingIsAccepted := IsUsageDataBillingAccepted(UsageDataImport."Entry No.", ServiceCommitment);
                    if not UsageDataBillingIsAccepted then
                        if FindCreditNotCoveredBySubscribedQuantity(UsageDataImport."Entry No.", ServiceCommitment, SubscriptionQuantity, CreditedQuantity) then begin
                            SetUsageDataBillingToError(ServiceCommitment, StrSubstNo(CreditedQtyExceedsSubscribedQtyErr, ServiceObject."No.", CreditedQuantity, SubscriptionQuantity));
                            exit;
                        end;
                    if NewServiceObjectQuantity <> 0 then begin
                        if ServiceCommitment.IsPartnerCustomer() then
                            UnitPrice := TotalAmount / NewServiceObjectQuantity;
                    end else
                        UnitPrice := 0;
                    // Rebilling usage data states a change of the quantity subscribed before the import, so a rebilling credit reduces that quantity.
                    // Each Subscription Line of the Subscription is processed separately, but the change must be added to the Subscription only once.
                    if LastUsageDataBilling.Rebilling then
                        if UsageDataBillingIsAccepted then
                            NewServiceObjectQuantity := ServiceObject.Quantity
                        else
                            NewServiceObjectQuantity += SubscriptionQuantity;
                    // Other usage data states the quantity itself. A credit cannot do that, so the Subscription keeps its quantity.
                    if NewServiceObjectQuantity < 0 then
                        NewServiceObjectQuantity := ServiceObject.Quantity;
                end;
            "Usage Based Pricing"::"Fixed Quantity":
                ;
            "Usage Based Pricing"::"Unit Cost Surcharge":
                if NewServiceObjectQuantity <> 0 then begin
                    if ServiceCommitment.IsPartnerCustomer() then begin
                        UsageDataSupplier.Get(UsageDataImport."Supplier No.");
                        // A supplier that delivers the Unit Price states the price of the customer, so no surcharge is calculated.
                        if UsageDataSupplier."Unit Price from Import" then begin
                            CalculateSumsFromUsageDataBilling(LastUsageDataBilling, UsageDataImport."Entry No.", ServiceCommitment, TotalQuantity, TotalAmount);
                            UnitPrice := TotalAmount / NewServiceObjectQuantity;
                        end else
                            CalculatePriceFromUnitCostPerBillingBasePeriod(UnitPrice, PriceIsPerBillingBasePeriod, UnitCostPerBillingBasePeriod, QuantityOfUnitCost, 1 + LastUsageDataBilling."Pricing Unit Cost Surcharge %" / 100);
                    end;
                end else
                    UnitPrice := 0;
            else begin
                IsHandled := false;
                OnUsageBasedPricingElseCaseOnProcessSubscriptionLine(UnitCost, NewServiceObjectQuantity, ServiceCommitment, LastUsageDataBilling, IsHandled);
                if not IsHandled then
                    Error(UsageBasedPricingOptionNotImplementedErr, Format(ServiceCommitment."Usage Based Pricing"), ServiceCommitment.FieldCaption("Usage Based Pricing"), CodeunitObjectLbl,
                                                                    CurrentCodeunitNameLbl, ProcessServiceCommitmentProcedureNameLbl);
            end;
        end;

        if ServiceCommitment.IsPartnerVendor() then
            CalculateVendorPrice(UnitPrice, PriceIsPerBillingBasePeriod, UnitCost, ServiceCommitment, UnitCostPerBillingBasePeriod, QuantityOfUnitCost);

        UpdateServiceObjectQuantity(ServiceCommitment."Subscription Header No.", NewServiceObjectQuantity);
        //Note: Service commitment will be recalculated if the quantity in service object changes
        Commit();
        ServiceCommitment.Get(ServiceCommitment."Entry No.");
        if ServiceCommitment.IsPartnerCustomer() then
            CalculateCustomerUnitCost(UnitCost, UnitCostIsPerBillingBasePeriod, ServiceCommitment, UnitCostPerBillingBasePeriod, QuantityOfUnitCost);
        UpdateServiceCommitment(LastUsageDataBilling, ServiceCommitment, UnitPrice, UnitCost, CurrencyCode, PriceIsPerBillingBasePeriod, UnitCostIsPerBillingBasePeriod);
        if UsageDataBilling.Rebilling then begin
            ServiceCommitment."Next Billing Date" := UsageDataBilling."Charge Start Date";
            ServiceCommitment.Modify();
        end;

        OnAfterProcessSubscriptionLine(ServiceCommitment);
    end;

    local procedure CalculateVendorPrice(var UnitPrice: Decimal; var PriceIsPerBillingBasePeriod: Boolean; UnitCost: Decimal; ServiceCommitment: Record "Subscription Line"; UnitCostPerBillingBasePeriod: Decimal; TotalQuantity: Decimal)
    begin
        UnitPrice := UnitCost;
        if ServiceCommitment."Usage Based Pricing" in ["Usage Based Pricing"::"Usage Quantity", "Usage Based Pricing"::"Unit Cost Surcharge"] then
            CalculatePriceFromUnitCostPerBillingBasePeriod(UnitPrice, PriceIsPerBillingBasePeriod, UnitCostPerBillingBasePeriod, TotalQuantity, 1);
    end;

    local procedure CalculateCustomerUnitCost(var UnitCost: Decimal; var UnitCostIsPerBillingBasePeriod: Boolean; ServiceCommitment: Record "Subscription Line"; UnitCostPerBillingBasePeriod: Decimal; TotalQuantity: Decimal)
    begin
        if not (ServiceCommitment."Usage Based Pricing" in ["Usage Based Pricing"::"Usage Quantity", "Usage Based Pricing"::"Unit Cost Surcharge"]) then
            exit;
        // Like the Price, the Unit Cost of a Subscription Line is stated per Billing Base Period, while the cost of the usage data covers the charge period.
        UnitCostIsPerBillingBasePeriod := true;
        // A credit does not state a new cost.
        if TotalQuantity <= 0 then
            UnitCost := ServiceCommitment."Unit Cost"
        else
            UnitCost := UnitCostPerBillingBasePeriod;
    end;

    local procedure CalculatePriceFromUnitCostPerBillingBasePeriod(var UnitPrice: Decimal; var PriceIsPerBillingBasePeriod: Boolean; UnitCostPerBillingBasePeriod: Decimal; TotalQuantity: Decimal; UnitCostFactor: Decimal)
    begin
        // A credit does not state a new price.
        if TotalQuantity <= 0 then begin
            UnitPrice := 0;
            exit;
        end;
        UnitPrice := UnitCostPerBillingBasePeriod * UnitCostFactor;
        PriceIsPerBillingBasePeriod := true;
        // A Subscription Line cannot take over a negative price.
        if UnitPrice < 0 then
            UnitPrice := 0;
    end;

    local procedure CalculateSumsFromUsageDataBilling(LastUsageDataBilling: Record "Usage Data Billing"; UsageDataImportEntryNo: Integer; ServiceCommitment: Record "Subscription Line"; var TotalQuantity: Decimal; var TotalAmount: Decimal)
    var
        UsageDataBilling: Record "Usage Data Billing";
    begin
        FilterUsageDataBillingOfLastChargeEndDate(UsageDataBilling, LastUsageDataBilling, UsageDataImportEntryNo, ServiceCommitment);
        UsageDataBilling.CalcSums(Quantity, Amount);
        TotalQuantity := UsageDataBilling.Quantity;
        TotalAmount := UsageDataBilling.Amount;
    end;

    local procedure FilterUsageDataBillingOfLastChargeEndDate(var UsageDataBilling: Record "Usage Data Billing"; LastUsageDataBilling: Record "Usage Data Billing"; UsageDataImportEntryNo: Integer; ServiceCommitment: Record "Subscription Line")
    begin
        UsageDataBilling.FilterOnUsageDataImportAndServiceCommitment(UsageDataImportEntryNo, ServiceCommitment);
        UsageDataBilling.SetRange("Document Type", UsageDataBilling."Document Type"::None);
        UsageDataBilling.SetRange("Charge End Date", LastUsageDataBilling."Charge End Date");
        UsageDataBilling.ExcludeProcessingStatusError();
    end;

    local procedure FindCreditNotCoveredBySubscribedQuantity(UsageDataImportEntryNo: Integer; ServiceCommitment: Record "Subscription Line"; SubscriptionQuantity: Decimal; var CreditedQuantity: Decimal): Boolean
    var
        UsageDataBilling: Record "Usage Data Billing";
        ChargeEndDate: Date;
        ChargePeriodQuantity: Decimal;
    begin
        // Every charge period of the import is billed, so the credit of each one must be covered, not only that of the last one.
        UsageDataBilling.SetCurrentKey("Usage Data Import Entry No.", "Subscription Header No.", "Subscription Line Entry No.", Partner, "Document Type", "Charge End Date");
        UsageDataBilling.FilterOnUsageDataImportAndServiceCommitment(UsageDataImportEntryNo, ServiceCommitment);
        UsageDataBilling.SetRange("Document Type", UsageDataBilling."Document Type"::None);
        UsageDataBilling.ExcludeProcessingStatusError();
        UsageDataBilling.SetLoadFields(Quantity, "Charge End Date");
        if not UsageDataBilling.FindSet() then
            exit(false);
        ChargeEndDate := UsageDataBilling."Charge End Date";
        ChargePeriodQuantity := 0;
        repeat
            if UsageDataBilling."Charge End Date" <> ChargeEndDate then begin
                if not CreditedQuantityIsCovered(ChargePeriodQuantity, SubscriptionQuantity) then begin
                    CreditedQuantity := ChargePeriodQuantity;
                    exit(true);
                end;
                ChargeEndDate := UsageDataBilling."Charge End Date";
                ChargePeriodQuantity := 0;
            end;
            ChargePeriodQuantity += UsageDataBilling.Quantity;
        until UsageDataBilling.Next() = 0;
        CreditedQuantity := ChargePeriodQuantity;
        exit(not CreditedQuantityIsCovered(ChargePeriodQuantity, SubscriptionQuantity));
    end;

    local procedure CreditedQuantityIsCovered(UsageQuantity: Decimal; SubscriptionQuantity: Decimal): Boolean
    begin
        if UsageQuantity >= 0 then
            exit(true);
        exit(Abs(UsageQuantity) <= SubscriptionQuantity);
    end;

    local procedure IsUsageDataBillingAccepted(UsageDataImportEntryNo: Integer; ServiceCommitment: Record "Subscription Line"): Boolean
    var
        UsageDataBilling: Record "Usage Data Billing";
    begin
        UsageDataBilling.FilterOnUsageDataImportAndServiceCommitment(UsageDataImportEntryNo, ServiceCommitment);
        UsageDataBilling.SetRange("Document Type", UsageDataBilling."Document Type"::None);
        UsageDataBilling.SetFilter("Processing Status", '<>%1&<>%2', Enum::"Processing Status"::Error, Enum::"Processing Status"::Ok);
        exit(UsageDataBilling.IsEmpty());
    end;

    local procedure SetUsageDataBillingToError(ServiceCommitment: Record "Subscription Line"; ReasonText: Text)
    var
        UsageDataBilling: Record "Usage Data Billing";
    begin
        UsageDataBilling.FilterOnUsageDataImportAndServiceCommitment(UsageDataImport."Entry No.", ServiceCommitment);
        UsageDataBilling.SetRange("Document No.", '');
        UsageDataBilling.ExcludeProcessingStatusError();
        if UsageDataBilling.FindSet(true) then
            repeat
                UsageDataBilling.SetReason(ReasonText);
                UsageDataBilling."Processing Status" := Enum::"Processing Status"::Error;
                UsageDataBilling.Modify(false);
            until UsageDataBilling.Next() = 0;
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

    local procedure UpdateServiceCommitment(LastUsageDataBilling: Record "Usage Data Billing"; var ServiceCommitment: Record "Subscription Line"; UnitPrice: Decimal; UnitCost: Decimal; CurrencyCode: Code[10]; PriceIsPerBillingBasePeriod: Boolean; UnitCostIsPerBillingBasePeriod: Boolean)
    var
        Currency: Record Currency;
        CurrencyExchRate: Record "Currency Exchange Rate";
        ServiceCommitmentUnitPrice: Decimal;
        ServiceCommitmentUnitCost: Decimal;
        ServiceCommitmentUnitCostLCY: Decimal;
        RoundingPrecision: Decimal;
        ServiceCommitmentUpdated: Boolean;
        BillingReferenceDateChanged: Boolean;
    begin
        if UnitPrice = 0 then
            exit;
        SetCurrency(Currency, ServiceCommitment."Currency Code");

        ServiceCommitment.UnitPriceAndCostForPeriod(ServiceCommitment."Billing Rhythm", LastUsageDataBilling."Charge Start Date", LastUsageDataBilling."Charge End Date", ServiceCommitmentUnitPrice, ServiceCommitmentUnitCost, ServiceCommitmentUnitCostLCY, BillingReferenceDateChanged);
        if PriceIsPerBillingBasePeriod then
            ServiceCommitmentUnitPrice := ServiceCommitment.Price;
        if UnitCostIsPerBillingBasePeriod then
            ServiceCommitmentUnitCost := ServiceCommitment."Unit Cost";

        SetRoundingPrecision(RoundingPrecision, UnitPrice, Currency);
        if Round(ServiceCommitmentUnitPrice, RoundingPrecision) <> UnitPrice then begin
            ServiceCommitment.Price := UnitPrice;
            if ServiceCommitment."Currency Code" <> CurrencyCode then
                ServiceCommitment.Price := CurrencyExchRate.ExchangeAmtFCYToFCY(LastUsageDataBilling."Charge End Date", CurrencyCode, ServiceCommitment."Currency Code", ServiceCommitment.Price);

            ServiceCommitment.Validate(Price, ServiceCommitment.Price);
            ServiceCommitment.Validate("Calculation Base Amount", ServiceCommitment.Price / (ServiceCommitment."Calculation Base %" / 100));
            ServiceCommitmentUpdated := true;
        end;

        if ServiceCommitment.Partner = ServiceCommitment.Partner::Customer then begin
            SetRoundingPrecision(RoundingPrecision, UnitCost, Currency);
            if (Round(ServiceCommitmentUnitCost, RoundingPrecision) <> UnitCost) and (ServiceCommitment.Partner = ServiceCommitment.Partner::Customer) then begin
                ServiceCommitment."Unit Cost" := UnitCost;
                if ServiceCommitment."Currency Code" = CurrencyCode then
                    ServiceCommitment."Unit Cost (LCY)" := ServiceCommitment."Unit Cost"
                else
                    ServiceCommitment."Unit Cost (LCY)" := CurrencyExchRate.ExchangeAmtFCYToLCY(LastUsageDataBilling."Charge End Date", CurrencyCode, ServiceCommitment."Unit Cost", CurrencyExchRate.ExchangeRate(LastUsageDataBilling."Charge End Date", CurrencyCode));
                ServiceCommitmentUpdated := true;
            end;
        end;

        if not ServiceCommitmentUpdated then
            exit;

        ServiceCommitment.Modify(false);
    end;

    local procedure GetCustomerContractData(var CustomerContract: Record "Customer Subscription Contract"; var CustomerContractLine: Record "Cust. Sub. Contract Line"; var ServiceCommitment: Record "Subscription Line"; UsageDataBilling: Record "Usage Data Billing")
    begin
        CustomerContract.Get(UsageDataBilling."Subscription Contract No.");
        CustomerContractLine.Get(UsageDataBilling."Subscription Contract No.", UsageDataBilling."Subscription Contract Line No.");
        CustomerContractLine.GetServiceCommitment(ServiceCommitment);
    end;

    local procedure GetVendorContractData(var VendorContract: Record "Vendor Subscription Contract"; var VendorContractLine: Record "Vend. Sub. Contract Line"; var ServiceCommitment: Record "Subscription Line"; UsageDataBilling: Record "Usage Data Billing"): Boolean
    begin
        VendorContract.Get(UsageDataBilling."Subscription Contract No.");
        VendorContractLine.Get(UsageDataBilling."Subscription Contract No.", UsageDataBilling."Subscription Contract Line No.");
        exit(VendorContractLine.GetServiceCommitment(ServiceCommitment));
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

    local procedure CalculateUnitCostPerBillingBasePeriod(LastUsageDataBilling: Record "Usage Data Billing"; UsageDataImportEntryNo: Integer; ServiceCommitment: Record "Subscription Line"; var TotalQuantity: Decimal): Decimal
    var
        UsageDataBilling: Record "Usage Data Billing";
        TotalCostAmount: Decimal;
        TotalQuantityInBillingBasePeriods: Decimal;
        TotalUnitCostAmount: Decimal;
        OnlyUnitCostDelivered: Boolean;
    begin
        // A supplier Unit Cost is stated per Billing Base Period and is taken over weighted by quantity; a delivered Cost Amount is
        // divided by the Billing Base Periods it covers, which differ between usage data with different Charge Start Dates.
        FilterUsageDataBillingOfLastChargeEndDate(UsageDataBilling, LastUsageDataBilling, UsageDataImportEntryNo, ServiceCommitment);
        OnlyUnitCostDelivered := true;
        UsageDataBilling.SetLoadFields(Quantity, "Unit Cost", "Cost Amount", "Cost Amount from Unit Cost", "Charge Start Date", "Charge End Date");
        if UsageDataBilling.FindSet() then
            repeat
                OnlyUnitCostDelivered := OnlyUnitCostDelivered and UsageDataBilling."Cost Amount from Unit Cost";
                TotalQuantity += UsageDataBilling.Quantity;
                TotalUnitCostAmount += UsageDataBilling."Unit Cost" * UsageDataBilling.Quantity;
                TotalCostAmount += UsageDataBilling."Cost Amount";
                TotalQuantityInBillingBasePeriods += UsageDataBilling.Quantity * ServiceCommitment.ChargePeriodShareOfBillingBasePeriod(UsageDataBilling."Charge Start Date", UsageDataBilling."Charge End Date");
            until UsageDataBilling.Next() = 0;

        if OnlyUnitCostDelivered then begin
            if TotalQuantity <= 0 then
                exit(0);
            exit(TotalUnitCostAmount / TotalQuantity);
        end;
        if TotalQuantityInBillingBasePeriods <= 0 then
            exit(0);
        exit(TotalCostAmount / TotalQuantityInBillingBasePeriods);
    end;

    local procedure ChargePeriodCostAmount(UsageDataBilling: Record "Usage Data Billing"; SubscriptionLine: Record "Subscription Line"): Decimal
    begin
        // Like the Amount of customer usage data, the cost is calculated for the absolute quantity and gets the sign of the quantity when rounded.
        if UsageDataBilling."Cost Amount from Unit Cost" then
            exit(SubscriptionLine.UnitAmountForChargePeriod(UsageDataBilling."Unit Cost", UsageDataBilling."Charge Start Date", UsageDataBilling."Charge End Date") * Abs(UsageDataBilling.Quantity));
        if UsageDataBilling.Quantity < 0 then
            exit(-UsageDataBilling."Cost Amount");
        exit(UsageDataBilling."Cost Amount");
    end;

    local procedure RoundWithSignOfQuantity(AmountForAbsoluteQuantity: Decimal; Quantity: Decimal; Currency: Record Currency): Decimal
    begin
        if Quantity < 0 then
            exit(-Round(AmountForAbsoluteQuantity, Currency."Amount Rounding Precision"));
        exit(Round(AmountForAbsoluteQuantity, Currency."Amount Rounding Precision"));
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

    [IntegrationEvent(false, false)]
    local procedure OnUsageBasedPricingElseCaseOnProcessSubscriptionLine(var UnitCost: Decimal; var NewServiceObjectQuantity: Decimal; var SubscriptionLine: Record "Subscription Line"; LastUsageDataBilling: Record "Usage Data Billing"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUsageBasedPricingElseCaseOnCalculateCustomerUsageDataBillingPrice(var UnitPrice: Decimal; var Amount: Decimal; var UsageDataBilling: Record "Usage Data Billing"; CustomerSubscriptionContract: Record "Customer Subscription Contract"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised when vendor usage data is priced by an option of "Usage Based Pricing" that this codeunit does not know.
    /// If no subscriber handles it, the Cost Amount of the usage data billing is kept as imported.
    /// </summary>
    /// <param name="CostAmount">The cost for the absolute quantity of the usage data billing. The caller rounds it and gives it the sign of the quantity, as for the Amount of customer usage data.</param>
    /// <param name="UsageDataBilling">The vendor usage data billing being priced.</param>
    /// <param name="VendorSubscriptionContract">The vendor contract of the usage data billing.</param>
    /// <param name="IsHandled">Set to true when CostAmount was calculated.</param>
    [IntegrationEvent(false, false)]
    local procedure OnUsageBasedPricingElseCaseOnCalculateVendorUsageDataBillingPrice(var CostAmount: Decimal; var UsageDataBilling: Record "Usage Data Billing"; VendorSubscriptionContract: Record "Vendor Subscription Contract"; var IsHandled: Boolean)
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
