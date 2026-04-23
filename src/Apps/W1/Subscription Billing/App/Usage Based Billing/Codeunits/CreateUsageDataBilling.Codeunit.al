namespace Microsoft.SubscriptionBilling;

codeunit 8023 "Create Usage Data Billing"
{
    TableNo = "Usage Data Import";

    var
        UsageDataProcessing: Interface "Usage Data Processing";

    trigger OnRun()
    begin
        UsageDataImport.Copy(Rec);
        Code();
        Rec := UsageDataImport;
    end;

    local procedure Code()
    var
        UsageDataSupplier: Record "Usage Data Supplier";
    begin
        UsageDataImport.SetFilter("Processing Status", '<>%1', Enum::"Processing Status"::Closed);
        if UsageDataImport.FindSet() then
            repeat
                UsageDataSupplier.Get(UsageDataImport."Supplier No.");
                UsageDataProcessing := UsageDataSupplier.Type;
                ValidateImportedData();
                if not (UsageDataImport."Processing Status" = "Processing Status"::Error) then
                    CreateUsageDataBillingFromImport();
                if not (UsageDataImport."Processing Status" = "Processing Status"::Error) then
                    UpdateImportStatus();
            until UsageDataImport.Next() = 0;
    end;

    local procedure CreateUsageDataBillingFromImport()
    begin
        UsageDataProcessing.CreateBillingData(UsageDataImport);
    end;

    internal procedure CollectServiceCommitments(var TempServiceCommitment: Record "Subscription Line" temporary; ServiceObjectNo: Code[20]; SubscriptionEndDate: Date)
    begin
        FillTempServiceCommitment(TempServiceCommitment, ServiceObjectNo, SubscriptionEndDate);
        OnAfterCollectServiceCommitments(TempServiceCommitment, ServiceObjectNo, SubscriptionEndDate);
    end;

    internal procedure CreateUsageDataBillingFromTempServiceCommitments(var TempServiceCommitment: Record "Subscription Line"; SupplierNo: Code[20]; UsageDataGenericImportGlobal: Record "Usage Data Generic Import")
    begin
        repeat
            CreateUsageDataBillingFromTempServiceCommitment(TempServiceCommitment, SupplierNo, UsageDataGenericImportGlobal);
        until TempServiceCommitment.Next() = 0;
        OnAfterCreateUsageDataBillingFromTempSubscriptionLines(TempServiceCommitment);
    end;

    local procedure CreateUsageDataBillingFromTempServiceCommitment(var TempServiceCommitment: Record "Subscription Line"; SupplierNo: Code[20]; UsageDataGenericImportGlobal: Record "Usage Data Generic Import")
    var
        UsageDataBilling: Record "Usage Data Billing";
        UsageDataSupplier: Record "Usage Data Supplier";
        CurrencyCode: Code[10];
    begin
        UsageDataSupplier.Get(SupplierNo);
        CurrencyCode := UsageDataGenericImportGlobal.GetCurrencyCode();

        UsageDataBilling.InitFrom(
            UsageDataGenericImportGlobal."Usage Data Import Entry No.",
            UsageDataGenericImportGlobal."Subscription Header No.",
            UsageDataGenericImportGlobal."Product ID",
            UsageDataGenericImportGlobal."Product Name",
            UsageDataGenericImportGlobal."Billing Period Start Date",
            UsageDataGenericImportGlobal."Billing Period End Date",
            UsageDataGenericImportGlobal.Quantity);
        UsageDataBilling."Supplier No." := SupplierNo;
        UsageDataBilling.Partner := TempServiceCommitment.Partner;
        UsageDataBilling."Subscription Header No." := TempServiceCommitment."Subscription Header No.";
        UsageDataBilling."Subscription Contract No." := TempServiceCommitment."Subscription Contract No.";
        UsageDataBilling."Subscription Contract Line No." := TempServiceCommitment."Subscription Contract Line No.";
        UsageDataBilling."Subscription Line Entry No." := TempServiceCommitment."Entry No.";
        UsageDataBilling."Subscription Line Description" := TempServiceCommitment.Description;
        UsageDataBilling."Usage Base Pricing" := TempServiceCommitment."Usage Based Pricing";
        UsageDataBilling."Pricing Unit Cost Surcharge %" := TempServiceCommitment."Pricing Unit Cost Surcharge %";
        if CurrencyCode = TempServiceCommitment."Currency Code" then
            UsageDataBilling."Currency Code" := CurrencyCode
        else
            UsageDataBilling.AlignContractCurrency(TempServiceCommitment, CurrencyCode);
        UsageDataBilling.CalculateAmounts(UsageDataSupplier, CurrencyCode, UsageDataGenericImportGlobal.Cost, UsageDataGenericImportGlobal."Cost Amount", UsageDataGenericImportGlobal.Price, UsageDataGenericImportGlobal.Amount);
        UsageDataBilling.UpdateRebilling();
        UsageDataBilling."Entry No." := 0;

        OnBeforInsertUsageDataBilling(UsageDataBilling, UsageDataGenericImportGlobal);

        UsageDataBilling.Insert(true);
        UsageDataBilling.InsertMetadata();

        OnAfterCreateUsageDataBillingFromTempSubscriptionLine(TempServiceCommitment, UsageDataBilling);
    end;


    local procedure FillTempServiceCommitment(var TempServiceCommitment: Record "Subscription Line" temporary; ServiceObjectNo: Code[20]; SubscriptionEndDate: Date)
    var
        ServiceCommitment: Record "Subscription Line";
    begin
        TempServiceCommitment.Reset();
        TempServiceCommitment.DeleteAll(false);
        ServiceCommitment.SetRange("Subscription Header No.", ServiceObjectNo);
        ServiceCommitment.SetFilter("Subscription Line End Date", '>=%1|%2', SubscriptionEndDate, 0D);
        ServiceCommitment.SetRange("Usage Based Billing", true);
        if ServiceCommitment.FindSet() then
            repeat
                if not TempServiceCommitment.Get(ServiceCommitment."Entry No.") then begin
                    TempServiceCommitment := ServiceCommitment;
                    TempServiceCommitment.Insert(false);
                end;
            until ServiceCommitment.Next() = 0;
    end;

    local procedure ValidateImportedData()
    begin
        UsageDataProcessing.ValidateImportedData(UsageDataImport);
    end;

    local procedure UpdateImportStatus()
    var
        UsageDataBilling: Record "Usage Data Billing";
    begin
        UsageDataProcessing.UpdateImportStatus(UsageDataImport);
        if UsageDataImport."Processing Status" = Enum::"Processing Status"::Error then
            exit;
        UsageDataBilling.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
        UsageDataBilling.SetRange("Processing Status", Enum::"Processing Status"::Error);
        if not UsageDataBilling.IsEmpty() then begin
            UsageDataImport.SetErrorReason(UsageDataLinesProcessingErr);
            UsageDataImport.Modify(false);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateUsageDataBillingFromTempSubscriptionLine(var TempSubscriptionLine: Record "Subscription Line"; var UsageDataBilling: Record "Usage Data Billing")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateUsageDataBillingFromTempSubscriptionLines(var TempSubscriptionLine: Record "Subscription Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCollectServiceCommitments(var TempSubscriptionLine: Record "Subscription Line" temporary; SubscriptionHeaderNo: Code[20]; SubscriptionLineEndDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforInsertUsageDataBilling(var UsageDataBilling: Record "Usage Data Billing"; UsageDataGenericImportGlobal: Record "Usage Data Generic Import")
    begin
    end;


    var
        UsageDataImport: Record "Usage Data Import";
        UsageDataLinesProcessingErr: Label 'Errors were detected when processing the usage data lines.';
}
