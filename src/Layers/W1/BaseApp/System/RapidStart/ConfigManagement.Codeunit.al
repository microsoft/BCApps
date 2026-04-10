#pragma warning disable AS0018
namespace System.IO;

using Microsoft.Purchases.Pricing;
using Microsoft.Sales.Pricing;
using System.Environment;
using System.Reflection;
using System.Security.AccessControl;
using System.Utilities;

codeunit 8616 "Config. Management"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        TempFieldRec: Record "Field" temporary;
        ConfigProgressBar: Codeunit "Config. Progress Bar";
        ConfigPackageMgt: Codeunit "Config. Package Management";
        HideDialog: Boolean;

        NoCompanyNameSpecifiedErr: Label 'You must specify a company name.';
#pragma warning disable AA0470
        CopyTableDataQst: Label 'Do you want to copy the data from the %1 table in %2?';
        TableDataCopiedSuccessfullyMsg: Label 'Data from the %1 table in %2 has been copied successfully.';
        CopySelectedTableDataQst: Label 'Do you want to copy the data from the selected tables in %1?';
        SelectedTableDataCopiedSuccessfullyMsg: Label 'Data from the selected tables in %1 has been copied successfully.';
#pragma warning restore AA0470
        SameCompanyErr: Label 'The base company must not be the same as the current company.';
#pragma warning disable AA0470
        TableContainsDataErr: Label 'The %1 table in %2 already contains data.\\You must delete the data from the table before you can use this function.';
        NoDataInTableErr: Label 'There is no data in the %1 table in %2.\\You must set up the table in %3 manually.';
#pragma warning restore AA0470
        ProcessingTablesMsg: Label 'Processing tables';

    procedure CopyDataDialog(NewCompanyName: Text[30]; var ConfigLine: Record "Config. Line")
    var
        ConfirmTableText: Text[250];
        MessageTableText: Text[250];
        SingleTable: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyDataDialog(ConfigLine, NewCompanyName, IsHandled);
        if IsHandled then
            exit;
        if NewCompanyName = '' then
            Error(NoCompanyNameSpecifiedErr);
        if not ConfigLine.FindFirst() then
            exit;
        SingleTable := ConfigLine.Next() = 0;
        if SingleTable then begin
            ConfirmTableText := StrSubstNo(CopyTableDataQst, ConfigLine.Name, NewCompanyName);
            MessageTableText := StrSubstNo(TableDataCopiedSuccessfullyMsg, ConfigLine.Name, NewCompanyName);
        end else begin
            ConfirmTableText := StrSubstNo(CopySelectedTableDataQst, NewCompanyName);
            MessageTableText := StrSubstNo(SelectedTableDataCopiedSuccessfullyMsg, NewCompanyName);
        end;
        if not Confirm(ConfirmTableText, SingleTable) then
            exit;
        if ConfigLine.FindSet() then
            repeat
                CopyData(ConfigLine);
            until ConfigLine.Next() = 0;
        Commit();
        Message(MessageTableText)
    end;

    local procedure CopyData(var ConfigLine: Record "Config. Line")
    var
        BaseCompanyName: Text[30];
    begin
        ConfigLine.CheckBlocked();
        ConfigLine.FilterGroup := 2;
        BaseCompanyName := ConfigLine.GetRangeMax("Company Filter (Source Table)");
        ConfigLine.FilterGroup := 0;
        if BaseCompanyName = CompanyName then
            Error(SameCompanyErr);
        ConfigLine.CalcFields("No. of Records", "No. of Records (Source Table)");
        if ConfigLine."No. of Records" <> 0 then
            Error(
              TableContainsDataErr,
              ConfigLine.Name, CompanyName);
        if ConfigLine."No. of Records (Source Table)" = 0 then
            Error(
              NoDataInTableErr,
              ConfigLine.Name, BaseCompanyName, CompanyName);
        TransferContents(ConfigLine."Table ID", BaseCompanyName, true);
    end;

    procedure TransferContents(TableID: Integer; NewCompanyName: Text[30]; CopyTable: Boolean): Boolean
    begin
        TempFieldRec.DeleteAll();
        if CopyTable then
            MarkPostValidationData(Database::Microsoft.CRM.Contact.Contact, 5053);
        TransferContent(TableID, NewCompanyName, CopyTable);
        TempFieldRec.DeleteAll();
        exit(true);
    end;

    local procedure TransferContent(TableNumber: Integer; NewCompanyName: Text[30]; CopyTable: Boolean)
    var
        FieldRec: Record "Field";
        FromCompanyRecRef: RecordRef;
        ToCompanyRecRef: RecordRef;
        FromCompanyFieldRef: FieldRef;
        ToCompanyFieldRef: FieldRef;
    begin
        if not CopyTable then
            exit;
        FromCompanyRecRef.Open(TableNumber, false, NewCompanyName);
        if FromCompanyRecRef.IsEmpty() then begin
            FromCompanyRecRef.Close();
            exit;
        end;
        FromCompanyRecRef.Find('-');
        ToCompanyRecRef.Open(TableNumber, false, CompanyName);
        FieldRec.SetRange(TableNo, TableNumber);
        FieldRec.SetRange(ObsoleteState, FieldRec.ObsoleteState::No);
        repeat
            if FieldRec.FindSet() then begin
                ToCompanyRecRef.Init();
                repeat
                    if not TempFieldRec.Get(TableNumber, FieldRec."No.") then begin
                        FromCompanyFieldRef := FromCompanyRecRef.Field(FieldRec."No.");
                        ToCompanyFieldRef := ToCompanyRecRef.Field(FieldRec."No.");
                        OnTransferContentOnBeforeToCompanyFieldRefValue(FieldRec, FromCompanyFieldRef);
                        ToCompanyFieldRef.Value(FromCompanyFieldRef.Value);
                    end;
                until FieldRec.Next() = 0;
                ToCompanyRecRef.Insert(true);
            end;
        until FromCompanyRecRef.Next() = 0;
        // Treatment of fields that require post-validation:
        TempFieldRec.SetRange(TableNo, TableNumber);
        TempFieldRec.SetRange(ObsoleteState, TempFieldRec.ObsoleteState::No);
        if TempFieldRec.FindSet() then begin
            FromCompanyRecRef.Find('-');
            repeat
                ToCompanyRecRef.SetPosition(FromCompanyRecRef.GetPosition());
                ToCompanyRecRef.Find('=');
                TempFieldRec.FindSet();
                repeat
                    FromCompanyFieldRef := FromCompanyRecRef.Field(TempFieldRec."No.");
                    ToCompanyFieldRef := ToCompanyRecRef.Field(TempFieldRec."No.");
                    ToCompanyFieldRef.Value(FromCompanyFieldRef.Value);
                until TempFieldRec.Next() = 0;
                ToCompanyRecRef.Modify(true);
            until FromCompanyRecRef.Next() = 0;
        end;

        FromCompanyRecRef.Close();
        ToCompanyRecRef.Close();
    end;

    local procedure MarkPostValidationData(TableNo: Integer; FieldNo: Integer)
    begin
        TempFieldRec.Init();
        TempFieldRec.TableNo := TableNo;
        TempFieldRec."No." := FieldNo;
        if TempFieldRec.Insert() then;
    end;

    procedure FindPage(TableID: Integer): Integer
    var
        PageID: Integer;
    begin
        case TableID of
            Database::Microsoft.Foundation.Company."Company Information":
                exit(Page::Microsoft.Foundation.Company."Company Information");
            Database::Microsoft.Inventory.Location."Responsibility Center":
                exit(Page::Microsoft.Inventory.Location."Responsibility Center List");
            Database::Microsoft.Foundation.Period."Accounting Period":
                exit(Page::Microsoft.Foundation.Period."Accounting Periods");
            Database::Microsoft.Finance.GeneralLedger.Setup."General Ledger Setup":
                exit(Page::Microsoft.Finance.GeneralLedger.Setup."General Ledger Setup");
            Database::Microsoft.Foundation.NoSeries."No. Series":
                exit(Page::Microsoft.Foundation.NoSeries."No. Series");
            Database::Microsoft.Foundation.NoSeries."No. Series Line":
                exit(Page::Microsoft.Foundation.NoSeries."No. Series Lines");
            Database::Microsoft.Finance.GeneralLedger.Account."G/L Account":
                exit(Page::Microsoft.Finance.GeneralLedger.Account."Chart of Accounts");
            Database::Microsoft.Finance.GeneralLedger.Setup."Gen. Business Posting Group":
                exit(Page::Microsoft.Finance.GeneralLedger.Setup."Gen. Business Posting Groups");
            Database::Microsoft.Finance.GeneralLedger.Setup."Gen. Product Posting Group":
                exit(Page::Microsoft.Finance.GeneralLedger.Setup."Gen. Product Posting Groups");
            Database::Microsoft.Finance.GeneralLedger.Setup."General Posting Setup":
                exit(Page::Microsoft.Finance.GeneralLedger.Setup."General Posting Setup");
            Database::Microsoft.Finance.VAT.Setup."VAT Business Posting Group":
                exit(Page::Microsoft.Finance.VAT.Setup."VAT Business Posting Groups");
            Database::Microsoft.Finance.VAT.Setup."VAT Product Posting Group":
                exit(Page::Microsoft.Finance.VAT.Setup."VAT Product Posting Groups");
            Database::Microsoft.Finance.VAT.Setup."VAT Posting Setup":
                exit(Page::Microsoft.Finance.VAT.Setup."VAT Posting Setup");
            Database::Microsoft.Finance.FinancialReports."Acc. Schedule Name":
                exit(Page::Microsoft.Finance.FinancialReports."Account Schedule Names");
            Database::Microsoft.Finance.FinancialReports."Column Layout Name":
                exit(Page::Microsoft.Finance.FinancialReports."Column Layout Names");
            Database::Microsoft.Finance.GeneralLedger.Budget."G/L Budget Name":
                exit(Page::Microsoft.Finance.GeneralLedger.Budget."G/L Budget Names");
            Database::Microsoft.Finance.VAT.Reporting."VAT Statement Template":
                exit(Page::Microsoft.Finance.VAT.Reporting."VAT Statement Templates");
            Database::Microsoft.Inventory.Intrastat."Tariff Number":
                exit(Page::Microsoft.Inventory.Intrastat."Tariff Numbers");
            Database::Microsoft.Inventory.Intrastat."Transaction Type":
                exit(Page::Microsoft.Inventory.Intrastat."Transaction Types");
            Database::Microsoft.Inventory.Intrastat."Transaction Specification":
                exit(Page::Microsoft.Inventory.Intrastat."Transaction Specifications");
            Database::Microsoft.Inventory.Intrastat."Transport Method":
                exit(Page::Microsoft.Inventory.Intrastat."Transport Methods");
            Database::Microsoft.Inventory.Intrastat."Entry/Exit Point":
                exit(Page::Microsoft.Inventory.Intrastat."Entry/Exit Points");
            Database::Microsoft.Inventory.Intrastat."Area":
                exit(Page::Microsoft.Inventory.Intrastat.Areas);
            Database::Microsoft.Inventory.Intrastat.Territory:
                exit(Page::Microsoft.Inventory.Intrastat.Territories);
            Database::Microsoft.Finance.SalesTax."Tax Jurisdiction":
                exit(Page::Microsoft.Finance.SalesTax."Tax Jurisdictions");
            Database::Microsoft.Finance.SalesTax."Tax Group":
                exit(Page::Microsoft.Finance.SalesTax."Tax Groups");
            Database::Microsoft.Finance.SalesTax."Tax Detail":
                exit(Page::Microsoft.Finance.SalesTax."Tax Details");
            Database::Microsoft.Finance.SalesTax."Tax Area":
                exit(Page::Microsoft.Finance.SalesTax."Tax Area");
            Database::Microsoft.Finance.SalesTax."Tax Area Line":
                exit(Page::Microsoft.Finance.SalesTax."Tax Area Line");
            Database::Microsoft.Foundation.AuditCodes."Source Code":
                exit(Page::Microsoft.Foundation.AuditCodes."Source Codes");
            Database::Microsoft.Foundation.AuditCodes."Reason Code":
                exit(Page::Microsoft.Foundation.AuditCodes."Reason Codes");
            Database::Microsoft.Utilities."Standard Text":
                exit(Page::Microsoft.Utilities."Standard Text Codes");
            Database::Microsoft.Finance.Consolidation."Business Unit":
                exit(Page::Microsoft.Finance.Consolidation."Business Unit List");
            Database::Microsoft.Finance.Dimension.Dimension:
                exit(Page::Microsoft.Finance.Dimension.Dimensions);
            Database::Microsoft.Finance.Dimension."Default Dimension Priority":
                exit(Page::Microsoft.Finance.Dimension."Default Dimension Priorities");
            Database::Microsoft.Finance.Dimension."Dimension Combination":
                exit(Page::Microsoft.Finance.Dimension."Dimension Combinations");
            Database::Microsoft.Finance.Analysis."Analysis View":
                exit(Page::Microsoft.Finance.Analysis."Analysis View List");
            Database::Microsoft.Foundation.Address."Post Code":
                exit(Page::Microsoft.Foundation.Address."Post Codes");
            Database::Microsoft.Foundation.Address."Country/Region":
                exit(Page::Microsoft.Foundation.Address."Countries/Regions");
            Database::System.Globalization.Language:
                exit(Page::System.Globalization.Languages);
            Database::Microsoft.Finance.Currency.Currency:
                exit(Page::Microsoft.Finance.Currency.Currencies);
            Database::Microsoft.Bank.BankAccount."Bank Account":
                exit(Page::Microsoft.Bank.BankAccount."Bank Account List");
            Database::Microsoft.Bank.BankAccount."Bank Account Posting Group":
                exit(Page::Microsoft.Bank.BankAccount."Bank Account Posting Groups");
            Database::System.Diagnostics."Change Log Setup (Table)":
                exit(Page::System.Diagnostics."Change Log Setup (Table) List");
            Database::System.Diagnostics."Change Log Setup (Field)":
                exit(Page::System.Diagnostics."Change Log Setup (Field) List");
            Database::Microsoft.Sales.Setup."Sales & Receivables Setup":
                exit(Page::Microsoft.Sales.Setup."Sales & Receivables Setup");
            Database::Microsoft.Sales.Customer.Customer:
                exit(Page::Microsoft.Sales.Customer."Customer List");
            Database::Microsoft.Sales.Customer."Customer Posting Group":
                exit(Page::Microsoft.Sales.Customer."Customer Posting Groups");
            Database::Microsoft.Foundation.PaymentTerms."Payment Terms":
                exit(Page::Microsoft.Foundation.PaymentTerms."Payment Terms");
            Database::Microsoft.Bank.BankAccount."Payment Method":
                exit(Page::Microsoft.Bank.BankAccount."Payment Methods");
            Database::Microsoft.Sales.Reminder."Reminder Attachment Text":
                exit(Page::Microsoft.Sales.Reminder."Reminder Attachment Text");
            Database::Microsoft.Sales.Reminder."Reminder Email Text":
                exit(Page::Microsoft.Sales.Reminder."Reminder Email Text");
            Database::Microsoft.Sales.Reminder."Reminder Terms":
                exit(Page::Microsoft.Sales.Reminder."Reminder Terms List");
            Database::Microsoft.Sales.Reminder."Reminder Level":
                exit(Page::Microsoft.Sales.Reminder."Reminder Levels");
            Database::Microsoft.Sales.Reminder."Reminder Text":
                exit(Page::Microsoft.Sales.Reminder."Reminder Text");
            Database::Microsoft.Sales.FinanceCharge."Finance Charge Terms":
                exit(Page::Microsoft.Sales.FinanceCharge."Finance Charge Terms");
            Database::Microsoft.Foundation.Shipping."Shipment Method":
                exit(Page::Microsoft.Foundation.Shipping."Shipment Methods");
            Database::Microsoft.Foundation.Shipping."Shipping Agent":
                exit(Page::Microsoft.Foundation.Shipping."Shipping Agents");
            Database::Microsoft.Foundation.Shipping."Shipping Agent Services":
                exit(Page::Microsoft.Foundation.Shipping."Shipping Agent Services");
            Database::"Customer Discount Group":
                exit(Page::"Customer Disc. Groups");
            Database::Microsoft.CRM.Team."Salesperson/Purchaser":
                exit(Page::Microsoft.CRM.Team."Salespersons/Purchasers");
            Database::Microsoft.CRM.Setup."Marketing Setup":
                exit(Page::Microsoft.CRM.Setup."Marketing Setup");
            Database::Microsoft.CRM.Duplicates."Duplicate Search String Setup":
                exit(Page::Microsoft.CRM.Duplicates."Duplicate Search String Setup");
            Database::Microsoft.CRM.Contact.Contact:
                exit(Page::Microsoft.CRM.Contact."Contact List");
            Database::Microsoft.CRM.BusinessRelation."Business Relation":
                exit(Page::Microsoft.CRM.BusinessRelation."Business Relations");
            Database::Microsoft.CRM.Setup."Mailing Group":
                exit(Page::Microsoft.CRM.Setup."Mailing Groups");
            Database::Microsoft.CRM.Setup."Industry Group":
                exit(Page::Microsoft.CRM.Setup."Industry Groups");
            Database::Microsoft.CRM.Setup."Web Source":
                exit(Page::Microsoft.CRM.Setup."Web Sources");
            Database::Microsoft.CRM.Interaction."Interaction Group":
                exit(Page::Microsoft.CRM.Interaction."Interaction Groups");
            Database::Microsoft.CRM.Interaction."Interaction Template":
                exit(Page::Microsoft.CRM.Interaction."Interaction Templates");
            Database::Microsoft.CRM.Setup."Job Responsibility":
                exit(Page::Microsoft.CRM.Setup."Job Responsibilities");
            Database::Microsoft.CRM.Setup."Organizational Level":
                exit(Page::Microsoft.CRM.Setup."Organizational Levels");
            Database::Microsoft.CRM.Campaign."Campaign Status":
                exit(Page::Microsoft.CRM.Campaign."Campaign Status");
            Database::Microsoft.CRM.Task.Activity:
                exit(Page::Microsoft.CRM.Task.Activity);
            Database::Microsoft.CRM.Team.Team:
                exit(Page::Microsoft.CRM.Team.Teams);
            Database::Microsoft.CRM.Profiling."Profile Questionnaire Header":
                exit(Page::Microsoft.CRM.Profiling."Profile Questionnaires");
            Database::Microsoft.CRM.Opportunity."Sales Cycle":
                exit(Page::Microsoft.CRM.Opportunity."Sales Cycles");
            Database::Microsoft.CRM.Opportunity."Close Opportunity Code":
                exit(Page::Microsoft.CRM.Opportunity."Close Opportunity Codes");
            Database::Microsoft.Purchases.Setup."Purchases & Payables Setup":
                exit(Page::Microsoft.Purchases.Setup."Purchases & Payables Setup");
            Database::Microsoft.Purchases.Vendor.Vendor:
                exit(Page::Microsoft.Purchases.Vendor."Vendor List");
            Database::Microsoft.Purchases.Vendor."Vendor Posting Group":
                exit(Page::Microsoft.Purchases.Vendor."Vendor Posting Groups");
            Database::Microsoft.Inventory.Item.Catalog.Purchasing:
                exit(Page::Microsoft.Inventory.Item.Catalog."Purchasing Codes");
            Database::Microsoft.Inventory.Setup."Inventory Setup":
                exit(Page::Microsoft.Inventory.Setup."Inventory Setup");
            Database::Microsoft.Inventory.Item.Catalog."Nonstock Item Setup":
                exit(Page::Microsoft.Inventory.Item.Catalog."Catalog Item Setup");
            Database::Microsoft.Inventory.Tracking."Item Tracking Code":
                exit(Page::Microsoft.Inventory.Tracking."Item Tracking Codes");
            Database::Microsoft.Inventory.Item.Item:
                exit(Page::Microsoft.Inventory.Item."Item List");
            Database::Microsoft.Inventory.Item.Catalog."Nonstock Item":
                exit(Page::Microsoft.Inventory.Item.Catalog."Catalog Item List");
            Database::Microsoft.Inventory.Item."Inventory Posting Group":
                exit(Page::Microsoft.Inventory.Item."Inventory Posting Groups");
            Database::Microsoft.Inventory.Item."Inventory Posting Setup":
                exit(Page::Microsoft.Inventory.Item."Inventory Posting Setup");
            Database::Microsoft.Foundation.UOM."Unit of Measure":
                exit(Page::Microsoft.Foundation.UOM."Units of Measure");
            Database::"Customer Price Group":
                exit(Page::"Customer Price Groups");
            Database::Microsoft.Inventory.Item."Item Discount Group":
                exit(Page::Microsoft.Inventory.Item."Item Disc. Groups");
            Database::Microsoft.Inventory.Item.Catalog.Manufacturer:
                exit(Page::Microsoft.Inventory.Item.Catalog.Manufacturers);
            Database::Microsoft.Inventory.Item."Item Category":
                exit(Page::Microsoft.Inventory.Item."Item Categories");
            Database::Microsoft.Utilities."Rounding Method":
                exit(Page::Microsoft.Utilities."Rounding Methods");
            Database::Microsoft.Inventory.Location.Location:
                exit(Page::Microsoft.Inventory.Location."Location List");
            Database::Microsoft.Inventory.Transfer."Transfer Route":
                exit(Page::Microsoft.Inventory.Transfer."Transfer Routes");
            Database::Microsoft.Inventory.Location."Stockkeeping Unit":
                exit(Page::Microsoft.Inventory.Location."Stockkeeping Unit List");
            Database::Microsoft.Warehouse.Setup."Warehouse Setup":
                exit(Page::Microsoft.Warehouse.Setup."Warehouse Setup");
            Database::Microsoft.Projects.Resources.Setup."Resources Setup":
                exit(Page::Microsoft.Projects.Resources.Setup."Resources Setup");
            Database::Microsoft.Projects.Resources.Resource.Resource:
                exit(Page::Microsoft.Projects.Resources.Resource."Resource List");
            Database::Microsoft.Projects.Resources.Resource."Resource Group":
                exit(Page::Microsoft.Projects.Resources.Resource."Resource Groups");
            Database::Microsoft.Utilities."Work Type":
                exit(Page::Microsoft.Utilities."Work Types");
            Database::Microsoft.Projects.Project.Setup."Jobs Setup":
                exit(Page::Microsoft.Projects.Project.Setup."Jobs Setup");
            Database::Microsoft.Projects.Project.Job."Job Posting Group":
                exit(Page::Microsoft.Projects.Project.Job."Job Posting Groups");
            Database::Microsoft.FixedAssets.Setup."FA Setup":
                exit(Page::Microsoft.FixedAssets.Setup."Fixed Asset Setup");
            Database::Microsoft.FixedAssets.FixedAsset."Fixed Asset":
                exit(Page::Microsoft.FixedAssets.FixedAsset."Fixed Asset List");
            Database::Microsoft.FixedAssets.Insurance.Insurance:
                exit(Page::Microsoft.FixedAssets.Insurance."Insurance List");
            Database::Microsoft.FixedAssets.FixedAsset."FA Posting Group":
                exit(Page::Microsoft.FixedAssets.FixedAsset."FA Posting Groups");
            Database::Microsoft.FixedAssets.Journal."FA Journal Template":
                exit(Page::Microsoft.FixedAssets.Journal."FA Journal Templates");
            Database::Microsoft.FixedAssets.Journal."FA Reclass. Journal Template":
                exit(Page::Microsoft.FixedAssets.Journal."FA Reclass. Journal Templates");
            Database::Microsoft.FixedAssets.Insurance."Insurance Journal Template":
                exit(Page::Microsoft.FixedAssets.Insurance."Insurance Journal Templates");
            Database::Microsoft.FixedAssets.Depreciation."Depreciation Book":
                exit(Page::Microsoft.FixedAssets.Depreciation."Depreciation Book List");
            Database::Microsoft.FixedAssets.Setup."FA Class":
                exit(Page::Microsoft.FixedAssets.Setup."FA Classes");
            Database::Microsoft.FixedAssets.Setup."FA Subclass":
                exit(Page::Microsoft.FixedAssets.Setup."FA Subclasses");
            Database::Microsoft.FixedAssets.Setup."FA Location":
                exit(Page::Microsoft.FixedAssets.Setup."FA Locations");
            Database::Microsoft.FixedAssets.Insurance."Insurance Type":
                exit(Page::Microsoft.FixedAssets.Insurance."Insurance Types");
            Database::Microsoft.FixedAssets.Maintenance.Maintenance:
                exit(Page::Microsoft.FixedAssets.Maintenance.Maintenance);
            Database::Microsoft.HumanResources.Setup."Human Resources Setup":
                exit(Page::Microsoft.HumanResources.Setup."Human Resources Setup");
            Database::Microsoft.HumanResources.Employee.Employee:
                exit(Page::Microsoft.HumanResources.Employee."Employee List");
            Database::Microsoft.HumanResources.Absence."Cause of Absence":
                exit(Page::Microsoft.HumanResources.Absence."Causes of Absence");
            Database::Microsoft.HumanResources.Setup."Cause of Inactivity":
                exit(Page::Microsoft.HumanResources.Setup."Causes of Inactivity");
            Database::Microsoft.HumanResources.Setup."Grounds for Termination":
                exit(Page::Microsoft.HumanResources.Setup."Grounds for Termination");
            Database::Microsoft.HumanResources.Setup."Employment Contract":
                exit(Page::Microsoft.HumanResources.Setup."Employment Contracts");
            Database::Microsoft.HumanResources.Setup.Qualification:
                exit(Page::Microsoft.HumanResources.Setup.Qualifications);
            Database::Microsoft.HumanResources.Setup.Relative:
                exit(Page::Microsoft.HumanResources.Setup.Relatives);
            Database::Microsoft.HumanResources.Setup."Misc. Article":
                exit(Page::Microsoft.HumanResources.Employee."Misc. Article Information");
            Database::Microsoft.HumanResources.Setup.Confidential:
                exit(Page::Microsoft.HumanResources.Setup.Confidential);
            Database::Microsoft.HumanResources.Setup."Employee Statistics Group":
                exit(Page::Microsoft.HumanResources.Setup."Employee Statistics Groups");
            Database::Microsoft.HumanResources.Setup.Union:
                exit(Page::Microsoft.HumanResources.Setup.Unions);
            Database::Microsoft.Manufacturing.Capacity."Capacity Unit of Measure":
                exit(Page::Microsoft.Manufacturing.Capacity."Capacity Units of Measure");
            Database::Microsoft.CostAccounting.Account."Cost Type":
                exit(Page::Microsoft.CostAccounting.Account."Cost Type List");
            Database::Microsoft.CostAccounting.Journal."Cost Journal Template":
                exit(Page::Microsoft.CostAccounting.Journal."Cost Journal Templates");
            Database::Microsoft.CostAccounting.Allocation."Cost Allocation Source":
                exit(Page::Microsoft.CostAccounting.Allocation."Cost Allocation");
            Database::Microsoft.CostAccounting.Allocation."Cost Allocation Target":
                exit(Page::Microsoft.CostAccounting.Allocation."Cost Allocation Target List");
            Database::Microsoft.CostAccounting.Setup."Cost Accounting Setup":
                exit(Page::Microsoft.CostAccounting.Setup."Cost Accounting Setup");
            Database::Microsoft.CostAccounting.Budget."Cost Budget Name":
                exit(Page::Microsoft.CostAccounting.Budget."Cost Budget Names");
            Database::Microsoft.CostAccounting.Account."Cost Center":
                exit(Page::Microsoft.CostAccounting.Account."Chart of Cost Centers");
            Database::Microsoft.CostAccounting.Account."Cost Object":
                exit(Page::Microsoft.CostAccounting.Account."Chart of Cost Objects");
            Database::Microsoft.CashFlow.Setup."Cash Flow Setup":
                exit(Page::Microsoft.CashFlow.Setup."Cash Flow Setup");
            Database::Microsoft.CashFlow.Forecast."Cash Flow Forecast":
                exit(Page::Microsoft.CashFlow.Forecast."Cash Flow Forecast List");
            Database::Microsoft.CashFlow.Account."Cash Flow Account":
                exit(Page::Microsoft.CashFlow.Account."Chart of Cash Flow Accounts");
            Database::Microsoft.CashFlow.Setup."Cash Flow Manual Expense":
                exit(Page::Microsoft.CashFlow.Setup."Cash Flow Manual Expenses");
            Database::Microsoft.CashFlow.Setup."Cash Flow Manual Revenue":
                exit(Page::Microsoft.CashFlow.Setup."Cash Flow Manual Revenues");
            Database::Microsoft.Intercompany.Partner."IC Partner":
                exit(Page::Microsoft.Intercompany.Partner."IC Partner List");
            Database::Microsoft.Foundation.Calendar."Base Calendar":
                exit(Page::Microsoft.Foundation.Calendar."Base Calendar List");
            Database::Microsoft.Sales.FinanceCharge."Finance Charge Text":
                exit(Page::Microsoft.Sales.Reminder."Reminder Text");
            Database::Microsoft.Sales.FinanceCharge."Currency for Fin. Charge Terms":
                exit(Page::Microsoft.Sales.FinanceCharge."Currencies for Fin. Chrg Terms");
            Database::Microsoft.Sales.Reminder."Currency for Reminder Level":
                exit(Page::Microsoft.Sales.Reminder."Currencies for Reminder Level");
            Database::Microsoft.Finance.Currency."Currency Exchange Rate":
                exit(Page::Microsoft.Finance.Currency."Currency Exchange Rates");
            Database::Microsoft.Finance.VAT.Reporting."VAT Statement Name":
                exit(Page::Microsoft.Finance.VAT.Reporting."VAT Statement Names");
            Database::Microsoft.Finance.VAT.Reporting."VAT Statement Line":
                exit(Page::Microsoft.Finance.VAT.Reporting."VAT Statement");
            Database::Microsoft.Foundation.NoSeries."No. Series Relationship":
                exit(Page::Microsoft.Foundation.NoSeries."No. Series Relationships");
            Database::System.Security.User."User Setup":
                exit(Page::System.Security.User."User Setup");
            Database::Microsoft.Finance.GeneralLedger.Journal."Gen. Journal Template":
                exit(Page::Microsoft.Finance.GeneralLedger.Journal."General Journal Template List");
            Database::Microsoft.Finance.GeneralLedger.Journal."Gen. Journal Batch":
                exit(Page::Microsoft.Finance.GeneralLedger.Journal."General Journal Batches");
            Database::Microsoft.Finance.GeneralLedger.Journal."Gen. Journal Line":
                exit(Page::Microsoft.Finance.GeneralLedger.Journal."General Journal");
            Database::Microsoft.Inventory.Journal."Item Journal Template":
                exit(Page::Microsoft.Inventory.Journal."Item Journal Template List");
            Database::Microsoft.Inventory.Journal."Item Journal Batch":
                exit(Page::Microsoft.Inventory.Journal."Item Journal Batches");
            Database::Microsoft.Sales.Customer."Customer Bank Account":
                exit(Page::Microsoft.Sales.Customer."Customer Bank Account List");
            Database::Microsoft.Purchases.Vendor."Vendor Bank Account":
                exit(Page::Microsoft.Purchases.Vendor."Vendor Bank Account List");
            Database::"Cust. Invoice Disc.":
                exit(Page::"Cust. Invoice Discounts");
            Database::Microsoft.Purchases.Vendor."Vendor Invoice Disc.":
                exit(Page::Microsoft.Purchases.Vendor."Vend. Invoice Discounts");
            Database::Microsoft.Finance.Dimension."Dimension Value":
                exit(Page::Microsoft.Finance.Dimension."Dimension Value List");
            Database::Microsoft.Finance.Dimension."Dimension Value Combination":
                exit(Page::Microsoft.Finance.Dimension."Dimension Combinations");
            Database::Microsoft.Finance.Dimension."Default Dimension":
                exit(Page::Microsoft.Finance.Dimension."Default Dimensions");
            Database::Microsoft.Finance.Dimension."Dimension Translation":
                exit(Page::Microsoft.Finance.Dimension."Dimension Translations");
            Database::Microsoft.Finance.Dimension."Dimension Set Entry":
                exit(Page::Microsoft.Finance.Dimension."Dimension Set Entries");
            Database::Microsoft.Finance.VAT.Reporting."VAT Report Setup":
                exit(Page::Microsoft.Finance.VAT.Reporting."VAT Report Setup");
            Database::Microsoft.Finance.VAT.Registration."VAT Registration No. Format":
                exit(Page::Microsoft.Finance.VAT.Registration."VAT Registration No. Formats");
            Database::Microsoft.Finance.GeneralLedger.Ledger."G/L Entry":
                exit(Page::Microsoft.Finance.GeneralLedger.Ledger."General Ledger Entries");
            Database::Microsoft.Sales.Receivables."Cust. Ledger Entry":
                exit(Page::Microsoft.Sales.Receivables."Customer Ledger Entries");
            Database::Microsoft.Purchases.Payables."Vendor Ledger Entry":
                exit(Page::Microsoft.Purchases.Payables."Vendor Ledger Entries");
            Database::Microsoft.Inventory.Ledger."Item Ledger Entry":
                exit(Page::Microsoft.Inventory.Ledger."Item Ledger Entries");
            Database::Microsoft.Sales.Document."Sales Header":
                exit(Page::Microsoft.Sales.Document."Sales List");
            Database::Microsoft.Purchases.Document."Purchase Header":
                exit(Page::Microsoft.Purchases.Document."Purchase List");
            Database::Microsoft.Finance.GeneralLedger.Ledger."G/L Register":
                exit(Page::Microsoft.Finance.GeneralLedger.Ledger."G/L Registers");
            Database::Microsoft.Inventory.Ledger."Item Register":
                exit(Page::Microsoft.Inventory.Ledger."Item Registers");
            Database::Microsoft.Inventory.Journal."Item Journal Line":
                exit(Page::Microsoft.Inventory.Journal."Item Journal Lines");
            Database::Microsoft.Sales.History."Sales Shipment Header":
                exit(Page::Microsoft.Sales.History."Posted Sales Shipments");
            Database::Microsoft.Sales.History."Sales Invoice Header":
                exit(Page::Microsoft.Sales.History."Posted Sales Invoices");
            Database::Microsoft.Sales.History."Sales Cr.Memo Header":
                exit(Page::Microsoft.Sales.History."Posted Sales Credit Memos");
            Database::Microsoft.Purchases.History."Purch. Rcpt. Header":
                exit(Page::Microsoft.Purchases.History."Posted Purchase Receipts");
            Database::Microsoft.Purchases.History."Purch. Inv. Header":
                exit(Page::Microsoft.Purchases.History."Posted Purchase Invoices");
            Database::Microsoft.Purchases.History."Purch. Cr. Memo Hdr.":
                exit(Page::Microsoft.Purchases.History."Posted Purchase Credit Memos");
            Database::"Sales Price":
                exit(Page::"Sales Prices");
            Database::"Purchase Price":
                exit(Page::"Purchase Prices");
            Database::Microsoft.Pricing.PriceList."Price List Line":
                exit(Page::Microsoft.Pricing.PriceList."Price List Line Review");
            Database::Microsoft.Finance.VAT.Ledger."VAT Entry":
                exit(Page::Microsoft.Finance.VAT.Ledger."VAT Entries");
            Database::Microsoft.FixedAssets.Ledger."FA Ledger Entry":
                exit(Page::Microsoft.FixedAssets.Ledger."FA Ledger Entries");
            Database::Microsoft.Inventory.Ledger."Value Entry":
                exit(Page::Microsoft.Inventory.Ledger."Value Entries");
            Database::Microsoft.Foundation.AuditCodes."Source Code Setup":
                exit(Page::Microsoft.Foundation.AuditCodes."Source Code Setup");
            else begin
                OnFindPage(TableID, PageID);
                exit(PageID);
            end;
        end;
    end;

    procedure GetConfigTables(var AllObj: Record AllObj; IncludeWithDataOnly: Boolean; IncludeRelatedTables: Boolean; IncludeDimensionTables: Boolean; IncludeLicensedTablesOnly: Boolean; IncludeReferringTable: Boolean)
    var
        TempInt: Record "Integer" temporary;
        TableInfo: Record "Table Information";
        ConfigLine: Record "Config. Line";
        "Field": Record "Field";
        NextLineNo: Integer;
        NextVertNo: Integer;
        Include: Boolean;
    begin
        if not HideDialog then
            ConfigProgressBar.Init(AllObj.Count, 1, ProcessingTablesMsg);

        TempInt.DeleteAll();

        NextLineNo := 10000;
        ConfigLine.Reset();
        if ConfigLine.FindLast() then
            NextLineNo := ConfigLine."Line No." + 10000;

        NextVertNo := 0;
        ConfigLine.SetCurrentKey("Vertical Sorting");
        if ConfigLine.FindLast() then
            NextVertNo := ConfigLine."Vertical Sorting" + 1;

        if AllObj.FindSet() then
            repeat
                if not HideDialog then
                    ConfigProgressBar.Update(AllObj."Object Name");
                Include := true;
                if IncludeWithDataOnly then begin
                    Include := false;
                    TableInfo.SetRange("Company Name", CompanyName);
                    TableInfo.SetRange("Table No.", AllObj."Object ID");
                    if TableInfo.FindFirst() then
                        if TableInfo."No. of Records" > 0 then
                            Include := true;
                end;
                if Include then begin
                    if IncludeReferringTable then
                        InsertTempInt(TempInt, AllObj."Object ID", IncludeLicensedTablesOnly);
                    if IncludeRelatedTables then begin
                        ConfigPackageMgt.SetFieldFilter(Field, AllObj."Object ID", 0);
                        Field.SetFilter(RelationTableNo, '<>%1&<>%2&..%3', 0, AllObj."Object ID", 99000999);
                        if Field.FindSet() then
                            repeat
                                InsertTempInt(TempInt, Field.RelationTableNo, IncludeLicensedTablesOnly);
                            until Field.Next() = 0;
                    end;
                    if IncludeDimensionTables then
                        if CheckDimTables(AllObj."Object ID") then begin
                            InsertDimTables(TempInt, IncludeLicensedTablesOnly);
                            IncludeDimensionTables := false;
                        end;
                end;
            until AllObj.Next() = 0;

        if TempInt.FindSet() then
            repeat
                InsertConfigLine(TempInt.Number, NextLineNo, NextVertNo);
            until TempInt.Next() = 0;

        if not HideDialog then
            ConfigProgressBar.Close();
    end;

    local procedure InsertConfigLine(TableID: Integer; var NextLineNo: Integer; var NextVertNo: Integer)
    var
        ConfigLine: Record "Config. Line";
    begin
        ConfigLine.Init();
        ConfigLine.Validate("Line Type", ConfigLine."Line Type"::Table);
        ConfigLine.Validate("Table ID", TableID);
        ConfigLine."Line No." := NextLineNo;
        NextLineNo := NextLineNo + 10000;
        ConfigLine."Vertical Sorting" := NextVertNo;
        NextVertNo := NextVertNo + 1;
        ConfigLine.Insert(true);
    end;

    local procedure CheckDimTables(TableID: Integer): Boolean
    var
        "Field": Record "Field";
    begin
        ConfigPackageMgt.SetFieldFilter(Field, TableID, 0);
        if Field.FindSet() then
            repeat
                if IsDimSetIDField(Field.TableNo, Field."No.") then
                    exit(true);
            until Field.Next() = 0;
    end;

    local procedure CheckTable(TableID: Integer): Boolean
    begin
        exit(IsNormalTable(TableID) and TableIsInAllowedRange(TableID));
    end;

    local procedure InsertDimTables(var TempInt: Record "Integer"; IncludeLicensedTablesOnly: Boolean)
    begin
        InsertTempInt(TempInt, Database::Microsoft.Finance.Dimension.Dimension, IncludeLicensedTablesOnly);
        InsertTempInt(TempInt, Database::Microsoft.Finance.Dimension."Dimension Value", IncludeLicensedTablesOnly);
        InsertTempInt(TempInt, Database::Microsoft.Finance.Dimension."Dimension Combination", IncludeLicensedTablesOnly);
        InsertTempInt(TempInt, Database::Microsoft.Finance.Dimension."Dimension Value Combination", IncludeLicensedTablesOnly);
        InsertTempInt(TempInt, Database::Microsoft.Finance.Dimension."Dimension Set Entry", IncludeLicensedTablesOnly);
        InsertTempInt(TempInt, Database::Microsoft.Finance.Dimension."Dimension Set Tree Node", IncludeLicensedTablesOnly);
        InsertTempInt(TempInt, Database::Microsoft.Finance.Dimension."Default Dimension", IncludeLicensedTablesOnly);
        InsertTempInt(TempInt, Database::Microsoft.Finance.Dimension."Default Dimension Priority", IncludeLicensedTablesOnly);
    end;

    procedure IsDefaultDimTable(TableID: Integer) Result: Boolean
    begin
        case TableID of
            Database::Microsoft.Finance.GeneralLedger.Account."G/L Account",
            Database::Microsoft.Sales.Customer.Customer,
            Database::Microsoft.Purchases.Vendor.Vendor,
            Database::Microsoft.Inventory.Item.Item,
            Database::Microsoft.Projects.Resources.Resource."Resource Group",
            Database::Microsoft.Projects.Resources.Resource.Resource,
            Database::Microsoft.Projects.Project.Job.Job,
            Database::Microsoft.Bank.BankAccount."Bank Account",
            Database::Microsoft.HumanResources.Employee.Employee,
            Database::Microsoft.FixedAssets.FixedAsset."Fixed Asset",
            Database::Microsoft.FixedAssets.Insurance.Insurance,
            Database::Microsoft.Inventory.Location."Responsibility Center",
            Database::Microsoft.CRM.Team."Salesperson/Purchaser",
            Database::Microsoft.CRM.Campaign.Campaign,
            Database::Microsoft.CashFlow.Setup."Cash Flow Manual Expense",
            Database::Microsoft.CashFlow.Setup."Cash Flow Manual Revenue":
                exit(true);
        end;

        OnAfterIsDefaultDimTable(TableID, Result);
    end;

    procedure IsDimSetIDTable(TableID: Integer) Result: Boolean
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableID);
        Result := RecRef.FieldExist(Database::Microsoft.Finance.Dimension."Dimension Set Entry");
        OnAfterIsDimSetIDTable(TableID, Result);
    end;

    local procedure IsDimSetIDField(TableID: Integer; FieldID: Integer): Boolean
    var
        ConfigValidateMgt: Codeunit "Config. Validate Management";
    begin
        exit(
          (FieldID = Database::Microsoft.Finance.Dimension."Dimension Set Entry") or
          (ConfigValidateMgt.GetRelationTableID(TableID, FieldID) = Database::Microsoft.Finance.Dimension."Dimension Value"));
    end;

    local procedure TableIsInAllowedRange(TableID: Integer) Result: Boolean
    begin
        // This condition duplicates table relation of ConfigLine."Table ID" field to prevent runtime errors
        Result := TableID in [1 .. 99000999,
                              Database::"Permission Set",
                              Database::Permission,
                              Database::"Tenant Permission Set Rel.",
                              Database::"Tenant Permission Set",
                              Database::"Tenant Permission"];
    end;

    local procedure IsNormalTable(TableID: Integer): Boolean
    var
        TableMetadata: Record "Table Metadata";
    begin
        if TableMetadata.Get(TableID) then
            exit(TableMetadata.TableType = TableMetadata.TableType::Normal);
    end;

    procedure IsSystemTable(TableID: Integer) Result: Boolean
    begin
        Result := (TableID > 2000000000) and not (TableID in [Database::"Permission Set",
                                                              Database::Permission,
                                                              Database::"Tenant Permission Set Rel.",
                                                              Database::"Tenant Permission Set",
                                                              Database::"Tenant Permission"]);
    end;

    procedure AssignParentLineNos()
    var
        ConfigLine: Record "Config. Line";
        LastAreaLineNo: Integer;
        LastGroupLineNo: Integer;
    begin
        ConfigLine.Reset();
        ConfigLine.SetCurrentKey("Vertical Sorting");
        if ConfigLine.FindSet() then
            repeat
                case ConfigLine."Line Type" of
                    ConfigLine."Line Type"::Area:
                        begin
                            ConfigLine."Parent Line No." := 0;
                            LastAreaLineNo := ConfigLine."Line No.";
                            LastGroupLineNo := 0;
                        end;
                    ConfigLine."Line Type"::Group:
                        begin
                            ConfigLine."Parent Line No." := LastAreaLineNo;
                            LastGroupLineNo := ConfigLine."Line No.";
                        end;
                    ConfigLine."Line Type"::Table:
                        if LastGroupLineNo <> 0 then
                            ConfigLine."Parent Line No." := LastGroupLineNo
                        else
                            ConfigLine."Parent Line No." := LastAreaLineNo;
                end;
                ConfigLine.Modify();
            until ConfigLine.Next() = 0;
    end;

    procedure MakeTableFilter(var ConfigLine: Record "Config. Line"; Export: Boolean) "Filter": Text
    var
        AddDimTables: Boolean;
    begin
        Filter := '';
        if ConfigLine.FindSet() then
            repeat
                ConfigLine.CheckBlocked();
                if (ConfigLine."Table ID" > 0) and (ConfigLine.Status <= ConfigLine.Status::Completed) then
                    Filter += Format(ConfigLine."Table ID") + '|';
                AddDimTables := AddDimTables or ConfigLine."Dimensions as Columns";
            until ConfigLine.Next() = 0;
        if AddDimTables and not Export then
            Filter += StrSubstNo('%1|%2|', Database::Microsoft.Finance.Dimension."Dimension Value", Database::Microsoft.Finance.Dimension."Default Dimension");
        if Filter <> '' then
            Filter := CopyStr(Filter, 1, StrLen(Filter) - 1);

        exit(Filter);
    end;

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    local procedure InsertTempInt(var TempInt: Record "Integer"; TableId: Integer; IncludeLicensedTablesOnly: Boolean)
    var
        ConfigLine: Record "Config. Line";
        EnvironmentInformation: Codeunit "Environment Information";
        EffectivePermissionsMgt: Codeunit "Effective Permissions Mgt.";
    begin
        if CheckTable(TableId) then begin
            TempInt.Number := TableId;

            ConfigLine.Init();
            ConfigLine."Line Type" := ConfigLine."Line Type"::Table;
            ConfigLine."Table ID" := TableId;
            if IncludeLicensedTablesOnly then begin
                if EnvironmentInformation.IsSaaS() then begin
                    if EffectivePermissionsMgt.HasDirectRIMPermissionsOnTableData(TableId) then
                        if TempInt.Insert() then;
                end
                else begin
                    ConfigLine.CalcFields("Licensed Table");
                    if ConfigLine."Licensed Table" then
                        if TempInt.Insert() then;
                end;
            end else
                if TempInt.Insert() then;
        end;
    end;

    procedure DimensionFieldID(): Integer
    begin
        exit(999999900);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindPage(TableID: Integer; var PageID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsDimSetIDTable(TableID: Integer; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsDefaultDimTable(TableID: Integer; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyDataDialog(var ConfigLine: Record "Config. Line"; NewCompanyName: Text[30]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferContentOnBeforeToCompanyFieldRefValue(FieldRec: Record "Field"; FromCompanyFieldRef: FieldRef)
    begin
    end;
}
#pragma warning restore AS0018

