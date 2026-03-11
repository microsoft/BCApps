Provides a way to access information about the subscribed SKUs and the corresponding service plans. It uses two collections: one that stores the subscribed SKUs and the other that stores the corresponding service plans of the SKU that we currently point to in the collection. ResetSubscribedSKU and ResetServicePlans will set the enumerators to the initial position. Use NextSubscribedSKU to advance the enumerator to the next subscribed SKU in the collection and NextServicePlan to advance to the next service plan of the SKU that the enumerator currently points to. 
You can specify whether to include unknown plans by using the SetIncludeUnknownPlans function.

Usage examples:
```
procedure GetSKUs()
var
    SKU: Record "YOUR SKU TABLE";
    AzureADLic: codeunit "Azure AD Licensing";
begin
    while AzureADLic.NextSubscribedSKU() do begin
        SKU.id := AzureADLic.SubscribedSKUId();
        SKU.PartNumber := AzureADLic.SubscribedSKUPartNumber();
        SKU.PrepaidUnitsInEnabledState := AzureADLic.SubscribedSKUPrepaidUnitsInEnabledState();
        SKU.ConsumedUnits := AzureADLic.SubscribedSKUConsumedUnits();
        SKU.insert();
    end;
end;
procedure GetPlansBySKUs()
var
    Plan: Record "YOUR PLAN TABLE";
    AzureADLic: codeunit "Azure AD Licensing";
begin
    while AzureADLic.NextSubscribedSKU() do begin
        AzureADLic.ResetServicePlans();
        while AzureADLic.NextServicePlan() do begin
            Plan.ServicePlanId := AzureADLic.ServicePlanId();
            Plan.ServicePlanName := AzureADLic.ServicePlanName();
            Plan.SKUId := AzureADLic.SubscribedSKUId();
            Plan.insert();
        end;
    end;
end;
```

