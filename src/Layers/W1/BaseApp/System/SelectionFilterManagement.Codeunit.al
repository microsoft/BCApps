namespace System.Text;

using Microsoft.CashFlow.Account;
using Microsoft.CashFlow.Forecast;
using Microsoft.CostAccounting.Account;
using Microsoft.CostAccounting.Budget;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Team;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.HumanResources.Employee;
using Microsoft.Intercompany.Partner;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Reminder;
using System.Automation;
using System.Security.AccessControl;

codeunit 46 SelectionFilterManagement
{

    trigger OnRun()
    begin
    end;

    /// <summary>
    /// Get a filter for the selected field from a provided record. Ranges will be used inside the filter were possible.
    /// </summary>
    /// <param name="TempRecRef">Record used to determine the field filter.</param>
    /// <param name="SelectionFieldID">The field for which the filter will be constructed.</param>
    /// <returns>The filter for the provided field ID. For example, '1..3|6'.</returns>
    /// <remarks>This method queries the database intensively, can cause perfomance issues and even cause database server exceptions. Consider using the overload with ComputeRangesUsingRecords set to false.</remarks>
    procedure GetSelectionFilter(var TempRecRef: RecordRef; SelectionFieldID: Integer): Text
    var
        [SecurityFiltering(SecurityFilter::Ignored)]
        RecRef: RecordRef;
        FieldRef: FieldRef;
        FirstRecRef: Text;
        LastRecRef: Text;
        SelectionFilter: Text;
        SavePos: Text;
        TempRecRefCount: Integer;
        More: Boolean;
    begin
        if TempRecRef.IsTemporary then begin
            RecRef := TempRecRef.Duplicate();
            RecRef.Reset();
        end else
            RecRef.Open(TempRecRef.Number, false, TempRecRef.CurrentCompany);

        TempRecRefCount := TempRecRef.Count();
        if TempRecRefCount > 0 then begin
            TempRecRef.Ascending(true);
            TempRecRef.Find('-');
            while TempRecRefCount > 0 do begin
                TempRecRefCount := TempRecRefCount - 1;
                RecRef.SetPosition(TempRecRef.GetPosition());
                RecRef.Find();
                FieldRef := RecRef.Field(SelectionFieldID);
                FirstRecRef := Format(FieldRef.Value);
                LastRecRef := FirstRecRef;
                More := TempRecRefCount > 0;
                while More do
                    if RecRef.Next() = 0 then
                        More := false
                    else begin
                        SavePos := TempRecRef.GetPosition();
                        TempRecRef.SetPosition(RecRef.GetPosition());
                        if not TempRecRef.Find() then begin
                            More := false;
                            TempRecRef.SetPosition(SavePos);
                        end else begin
                            FieldRef := RecRef.Field(SelectionFieldID);
                            LastRecRef := Format(FieldRef.Value);
                            TempRecRefCount := TempRecRefCount - 1;
                            if TempRecRefCount = 0 then
                                More := false;
                        end;
                    end;
                if SelectionFilter <> '' then
                    SelectionFilter := SelectionFilter + '|';
                if FirstRecRef = LastRecRef then
                    SelectionFilter := SelectionFilter + AddQuotes(FirstRecRef)
                else
                    SelectionFilter := SelectionFilter + AddQuotes(FirstRecRef) + '..' + AddQuotes(LastRecRef);
                if TempRecRefCount > 0 then
                    TempRecRef.Next();
            end;
            exit(SelectionFilter);
        end;
    end;

    procedure CreateFilterFromTempTable(var SourceTempRecRef: RecordRef; var RecRef: RecordRef; SelectionFieldID: Integer): Text
    var
        FieldRef: FieldRef;
        FirstRecRef: Text[1024];
        LastRecRef: Text[1024];
        SelectionFilter: Text;
        SavePos: Text;
        TempRecRefCount: Integer;
        More: Boolean;
    begin
        TempRecRefCount := SourceTempRecRef.Count();
        if TempRecRefCount = 0 then
            exit('');

        SourceTempRecRef.Ascending(true);
        SourceTempRecRef.FindFirst();
        while TempRecRefCount > 0 do begin
            TempRecRefCount := TempRecRefCount - 1;
            RecRef.SetPosition(SourceTempRecRef.GetPosition());
            RecRef.Find();
            FieldRef := RecRef.Field(SelectionFieldID);
            FirstRecRef := Format(FieldRef.Value);
            LastRecRef := FirstRecRef;
            More := TempRecRefCount > 0;
            while More do
                if RecRef.Next() = 0 then
                    More := false
                else begin
                    SavePos := SourceTempRecRef.GetPosition();
                    SourceTempRecRef.SetPosition(RecRef.GetPosition());
                    if not SourceTempRecRef.Find() then begin
                        More := false;
                        SourceTempRecRef.SetPosition(SavePos);
                    end else begin
                        FieldRef := RecRef.Field(SelectionFieldID);
                        LastRecRef := Format(FieldRef.Value);
                        TempRecRefCount := TempRecRefCount - 1;
                        if TempRecRefCount = 0 then
                            More := false;
                    end;
                end;
            if SelectionFilter <> '' then
                SelectionFilter := SelectionFilter + '|';
            if FirstRecRef = LastRecRef then
                SelectionFilter := SelectionFilter + AddQuotes(FirstRecRef)
            else
                SelectionFilter := SelectionFilter + AddQuotes(FirstRecRef) + '..' + AddQuotes(LastRecRef);
            if TempRecRefCount > 0 then
                SourceTempRecRef.Next();
        end;
        exit(SelectionFilter);
    end;

    procedure AddQuotes(inString: Text): Text
    begin
        inString := ReplaceString(inString, '''', '''''');
        if DelChr(inString, '=', ' &|()*@<>=.!?') = inString then
            exit(inString);
        exit('''' + inString + '''');
    end;

    procedure ReplaceString(String: Text; FindWhat: Text; ReplaceWith: Text) NewString: Text
    begin
        while STRPOS(String, FindWhat) > 0 do begin
            NewString := NewString + DELSTR(String, STRPOS(String, FindWhat)) + ReplaceWith;
            String := COPYSTR(String, STRPOS(String, FindWhat) + STRLEN(FindWhat));
        end;
        NewString := NewString + String;
    end;

    procedure GetSelectionFilterForItem(var Item: Record Item): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Item);
        exit(GetSelectionFilter(RecRef, Item.FieldNo("No.")));
    end;

#if not CLEAN25
    [Obsolete('Replaced by same procedure in codeunit Serv. Selection Filter Mgt.', '25.0')]
    procedure GetSelectionFilterForServiceItem(var ServiceItem: Record Microsoft.Service.Item."Service Item"): Text
    var
        ServSelectionFilterMgt: Codeunit "Serv. Selection Filter Mgt.";
    begin
        exit(ServSelectionFilterMgt.GetSelectionFilterForServiceItem(ServiceItem));
    end;
#endif

    procedure GetSelectionFilterForDimensionValue(var DimVal: Record "Dimension Value"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(DimVal);
        exit(GetSelectionFilter(RecRef, DimVal.FieldNo(Code)));
    end;

    procedure GetSelectionFilterForCurrency(var Currency: Record Currency): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Currency);
        exit(GetSelectionFilter(RecRef, Currency.FieldNo(Code)));
    end;

    procedure GetSelectionFilterForCustomerPriceGroup(var CustomerPriceGroup: Record "Customer Price Group"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(CustomerPriceGroup);
        exit(GetSelectionFilter(RecRef, CustomerPriceGroup.FieldNo(Code)));
    end;

    procedure GetSelectionFilterForLocation(var Location: Record Location): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Location);
        exit(GetSelectionFilter(RecRef, Location.FieldNo(Code)));
    end;

    procedure GetSelectionFilterForGLAccount(var GLAccount: Record "G/L Account"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(GLAccount);
        exit(GetSelectionFilter(RecRef, GLAccount.FieldNo("No.")));
    end;

    procedure GetSelectionFilterForGLAccountCategory(var GLAccountCategory: Record "G/L Account Category"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(GLAccountCategory);
        exit(GetSelectionFilter(RecRef, GLAccountCategory.FieldNo("Entry No.")));
    end;


    procedure GetSelectionFilterForCustomer(var Customer: Record Customer): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Customer);
        exit(GetSelectionFilter(RecRef, Customer.FieldNo("No.")));
    end;

    procedure GetSelectionFilterForContact(var Contact: Record Contact): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Contact);
        exit(GetSelectionFilter(RecRef, Contact.FieldNo("No.")));
    end;

    procedure GetSelectionFilterForVendor(var Vendor: Record Vendor): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Vendor);
        exit(GetSelectionFilter(RecRef, Vendor.FieldNo("No.")));
    end;

    procedure GetSelectionFilterForResource(var Resource: Record Resource): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Resource);
        exit(GetSelectionFilter(RecRef, Resource.FieldNo("No.")));
    end;

    procedure GetSelectionFilterForInventoryPostingGroup(var InventoryPostingGroup: Record "Inventory Posting Group"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(InventoryPostingGroup);
        exit(GetSelectionFilter(RecRef, InventoryPostingGroup.FieldNo(Code)));
    end;

    procedure GetSelectionFilterForGLBudgetName(var GLBudgetName: Record "G/L Budget Name"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(GLBudgetName);
        exit(GetSelectionFilter(RecRef, GLBudgetName.FieldNo(Name)));
    end;

    procedure GetSelectionFilterForBusinessUnit(var BusinessUnit: Record "Business Unit"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(BusinessUnit);
        exit(GetSelectionFilter(RecRef, BusinessUnit.FieldNo(Code)));
    end;

    procedure GetSelectionFilterForICPartner(var ICPartner: Record "IC Partner"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(ICPartner);
        exit(GetSelectionFilter(RecRef, ICPartner.FieldNo(Code)));
    end;

    procedure GetSelectionFilterForCashFlow(var CashFlowForecast: Record "Cash Flow Forecast"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(CashFlowForecast);
        exit(GetSelectionFilter(RecRef, CashFlowForecast.FieldNo("No.")));
    end;

    procedure GetSelectionFilterForCashFlowAccount(var CashFlowAccount: Record "Cash Flow Account"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(CashFlowAccount);
        exit(GetSelectionFilter(RecRef, CashFlowAccount.FieldNo("No.")));
    end;

    procedure GetSelectionFilterForCostBudgetName(var CostBudgetName: Record "Cost Budget Name"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(CostBudgetName);
        exit(GetSelectionFilter(RecRef, CostBudgetName.FieldNo(Name)));
    end;

    procedure GetSelectionFilterForCostCenter(var CostCenter: Record "Cost Center"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(CostCenter);
        exit(GetSelectionFilter(RecRef, CostCenter.FieldNo(Code)));
    end;

    procedure GetSelectionFilterForCostObject(var CostObject: Record "Cost Object"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(CostObject);
        exit(GetSelectionFilter(RecRef, CostObject.FieldNo(Code)));
    end;

    procedure GetSelectionFilterForCostType(var CostType: Record "Cost Type"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(CostType);
        exit(GetSelectionFilter(RecRef, CostType.FieldNo("No.")));
    end;

    procedure GetSelectionFilterForCampaign(var Campaign: Record Campaign): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Campaign);
        exit(GetSelectionFilter(RecRef, Campaign.FieldNo("No.")));
    end;

    procedure GetSelectionFilterForEmployee(var Employee: Record Employee): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Employee);
        exit(GetSelectionFilter(RecRef, Employee.FieldNo("No.")));
    end;

    procedure GetSelectionFilterForLotNoInformation(var LotNoInformation: Record "Lot No. Information"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(LotNoInformation);
        exit(GetSelectionFilter(RecRef, LotNoInformation.FieldNo("Lot No.")));
    end;

    procedure GetSelectionFilterForPackageNoInformation(var PackageNoInformation: Record "Package No. Information"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(PackageNoInformation);
        exit(GetSelectionFilter(RecRef, PackageNoInformation.FieldNo("Package No.")));
    end;

    procedure GetSelectionFilterForSerialNoInformation(var SerialNoInformation: Record "Serial No. Information"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(SerialNoInformation);
        exit(GetSelectionFilter(RecRef, SerialNoInformation.FieldNo("Serial No.")));
    end;

    procedure GetSelectionFilterForCustomerDiscountGroup(var CustomerDiscountGroup: Record "Customer Discount Group"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(CustomerDiscountGroup);
        exit(GetSelectionFilter(RecRef, CustomerDiscountGroup.FieldNo(Code)));
    end;

    procedure GetSelectionFilterForItemDiscountGroup(var ItemDiscountGroup: Record "Item Discount Group"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(ItemDiscountGroup);
        exit(GetSelectionFilter(RecRef, ItemDiscountGroup.FieldNo(Code)));
    end;

    procedure GetSelectionFilterForItemCategory(var ItemCategory: Record "Item Category"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(ItemCategory);
        exit(GetSelectionFilter(RecRef, ItemCategory.FieldNo(Code)));
    end;

    procedure GetSelectionFilterForIssueReminder(var ReminderHeader: Record "Reminder Header"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(ReminderHeader);
        exit(GetSelectionFilter(RecRef, ReminderHeader.FieldNo("No.")));
    end;

    procedure GetSelectionFilterForWorkflowStepInstance(var WorkflowStepInstance: Record "Workflow Step Instance"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(WorkflowStepInstance);
        exit(GetSelectionFilter(RecRef, WorkflowStepInstance.FieldNo("Original Workflow Step ID")));
    end;

    procedure GetSelectionFilterForWorkflowBuffer(var TempWorkflowBuffer: Record "Workflow Buffer" temporary): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(TempWorkflowBuffer);
        exit(GetSelectionFilter(RecRef, TempWorkflowBuffer.FieldNo("Workflow Code")));
    end;

    procedure GetSelectionFilterForResponsibilityCenter(var ResponsibilityCenter: Record "Responsibility Center"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(ResponsibilityCenter);
        exit(GetSelectionFilter(RecRef, ResponsibilityCenter.FieldNo(Code)));
    end;

    procedure GetSelectionFilterForSalesPersonPurchaser(var SalespersonPurchaser: Record "Salesperson/Purchaser"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(SalespersonPurchaser);
        exit(GetSelectionFilter(RecRef, SalespersonPurchaser.FieldNo(Code)));
    end;

    procedure GetSelectionFilterForItemVariant(var ItemVariant: Record "Item Variant"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(ItemVariant);
        exit(GetSelectionFilter(RecRef, ItemVariant.FieldNo(Code)));
    end;

    procedure GetSelectionFilterForFixedAsset(var FixedAsset: Record "Fixed Asset"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(FixedAsset);
        exit(GetSelectionFilter(RecRef, FixedAsset.FieldNo("No.")));
    end;

    procedure GetSelectionFilterForSalesHeader(var SalesHeader: Record "Sales Header"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(SalesHeader);
        exit(GetSelectionFilter(RecRef, SalesHeader.FieldNo("No.")));
    end;

    procedure GetSelectionFilterForPurchaseHeader(var PurchaseHeader: Record "Purchase Header"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(PurchaseHeader);
        exit(GetSelectionFilter(RecRef, PurchaseHeader.FieldNo("No.")));
    end;

    procedure GetSelectionFilterForTransferHeader(var TransferHeader: Record "Transfer Header"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(TransferHeader);
        exit(GetSelectionFilter(RecRef, TransferHeader.FieldNo("No.")));
    end;

    procedure GetSelectionFilterForAggregatePermissionSetRoleId(var AggregatePermissionSet: Record "Aggregate Permission Set"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(AggregatePermissionSet);
        exit(GetSelectionFilter(RecRef, AggregatePermissionSet.FieldNo("Role ID")));
    end;

    procedure GetSelectionFilterForJob(var Job: Record Job): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Job);
        exit(GetSelectionFilter(RecRef, Job.FieldNo("No.")));
    end;

    procedure GetSelectionFilterForJobTask(var JobTask: Record "Job Task"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(JobTask);
        exit(GetSelectionFilter(RecRef, JobTask.FieldNo("Job Task No.")));
    end;

    /// <summary>
    /// Get a filter for the selected field from a provided record. Ranges will be used inside the filter were possible.
    /// The values in the selected field must be unique and sorted in ascending order.
    /// </summary>
    /// <param name="SourceRecRef">Record used to determine the field filter.</param>
    /// <param name="SelectionFieldID">The field for which the filter will be constructed.</param>
    /// <param name="ComputeRangesUsingRecords">Specify if the computations should be performed on records, or in-memory structures.
    /// If the parameter is false, the database load is greatly reduced, but the memory footprint is bigger</param>
    /// <returns>The filter for the provided field ID. For example, '1..3|6'.</returns>
    procedure GetSelectionFilter(var SourceRecRef: RecordRef; SelectionFieldID: Integer; ComputeRangesUsingRecords: Boolean): Text
    var
        NoFiltersRecRef: RecordRef;
        SelectedValues: List of [Text];
        AllValues: List of [Text];
        Ranges: List of [Text];
        Range: Text;
        SelectionFilter: Text;
    begin
        if ComputeRangesUsingRecords then
            exit(GetSelectionFilter(SourceRecRef, SelectionFieldID));

        GetRecordRefWithoutFilters(SourceRecRef, NoFiltersRecRef);
        GetFieldValues(SourceRecRef, SelectionFieldID, SelectedValues);
        GetFieldValues(NoFiltersRecRef, SelectionFieldID, AllValues);
        ComputeRanges(SelectedValues, AllValues, Ranges);

        foreach Range in Ranges do
            SelectionFilter += Range + '|';
        exit(SelectionFilter.TrimEnd('|'));
    end;

    // Optimize the filter to make use of ranges.
    local procedure ComputeRanges(var SelectedValues: List of [Text]; var AllValues: List of [Text]; var Ranges: List of [Text])
    var
        CurrentRangeLength: Integer;
        i: Integer;
    begin
        if SelectedValues.Count() < 3 then begin
            Ranges.AddRange(SelectedValues);
            exit;
        end;

        CurrentRangeLength := 1;

        for i := 2 to SelectedValues.Count() do
            if not AreSelectedValuesConsecutive(SelectedValues.Get(i - 1), SelectedValues.Get(i), AllValues) then begin
                // If the range contains only one element, add it into the list.
                if (CurrentRangeLength = 1) then
                    Ranges.Add(SelectedValues.Get(i - CurrentRangeLength))
                else
                    // Build the range ending at the previous element.
                    Ranges.Add(SelectedValues.Get(i - CurrentRangeLength) + '..' + SelectedValues.Get(i - 1));

                // After finding the a range, initialize the length by 1 to build the next range.
                CurrentRangeLength := 1;
            end else
                CurrentRangeLength += 1;

        // Handle the last element.
        if (CurrentRangeLength = 1) then
            Ranges.Add(SelectedValues.Get(i))
        else
            Ranges.Add(SelectedValues.Get(i - CurrentRangeLength + 1) + '..' + SelectedValues.Get(i));
    end;

    // A comparer used to determine if subsequent selected values are also subsequent within all values. AllValues is passed by var to save up memory.
    local procedure AreSelectedValuesConsecutive(FirstSelectedValue: Text; SecondSelectedValue: Text; var AllValues: List of [Text]): Boolean
    begin
        exit((AllValues.IndexOf(SecondSelectedValue) - AllValues.IndexOf(FirstSelectedValue)) = 1);
    end;

    local procedure GetFieldValues(var ValuesRecRef: RecordRef; SelectionFieldID: Integer; var FoundValues: List of [Text])
    var
        SelectionFieldRef: FieldRef;
        SelectionFieldValue: Text;
    begin
        if ValuesRecRef.FindSet() then
            repeat
                SelectionFieldRef := ValuesRecRef.Field(SelectionFieldID);
                SelectionFieldValue := Format(SelectionFieldRef.Value);
                FoundValues.Add(AddQuotes(SelectionFieldValue));
            until ValuesRecRef.Next() = 0;
    end;

    local procedure GetRecordRefWithoutFilters(var FilteredRecRef: RecordRef; var NoFiltersRecRef: RecordRef)
    begin
        if FilteredRecRef.IsTemporary() then begin
            NoFiltersRecRef := FilteredRecRef.Duplicate();
            NoFiltersRecRef.Reset();
        end else
            NoFiltersRecRef.Open(FilteredRecRef.Number);
    end;

    procedure GetMaximumNumberOfParametersInSQLQuery(): Integer
    begin
        exit(2000);
    end;

#if not CLEAN25
    [Obsolete('Replaced by same procedure in codeunit Serv. Selection Filter Mgt.', '25.0')]
    procedure GetSelectionFilterForServiceHeader(var ServiceHeader: Record Microsoft.Service.Document."Service Header"): Text
    var
        ServSelectionFilterMgt: Codeunit "Serv. Selection Filter Mgt.";
    begin
        exit(ServSelectionFilterMgt.GetSelectionFilterForServiceHeader(ServiceHeader));
    end;
#endif
}

