namespace System.Integration;

using System;
using System.Apps;
using System.Azure.Identity;
using System.Environment;
using System.Integration.Excel;
using System.IO;
using System.Globalization;
using System.Reflection;
using System.Utilities;

codeunit 6710 ODataUtility
{
    Permissions = TableData "Tenant Web Service OData" = rimd,
                  TableData "Tenant Web Service Columns" = rimd,
                  TableData "Tenant Web Service Filter" = rimd,
                  TableData "Tenant Web Service" = r;

    trigger OnRun()
    begin
    end;

    var
        EnvironmentInfo: Codeunit "Environment Information";
        Language: Codeunit Language;
        WorksheetWriter: DotNet WorksheetWriter;
        WorkbookWriter: DotNet WorkbookWriter;
        ODataProtocolVersion: Option V3,V4;
        BalanceSheetHeadingTxt: Label 'Balance Sheet';
        BalanceSheetNameTxt: Label 'BalanceSheet', Locked = true;
        CompanyTxt: Label 'Company';
        CurrencyTxt: Label 'Currency';
        PrintedTxt: Label 'Printed';
        AsOfDateTxt: Label 'As of Date';
        DesciptionTxt: Label 'Description';
        BalanceTxt: Label 'Balance';
        PrintDollarLinesTxt: Label 'Print 0 Value Lines';
        SummaryTrialBalanceHeadingTxt: Label 'Summary Trial Balance';
        SummaryTrialBalanceNameTxt: Label 'SummaryTrialBalance', Locked = true;
        FromDateTxt: Label 'From Date';
        ToDateTxt: Label 'To Date';
        NoTxt: Label 'No.';
        NameTxt: Label 'Name';
        TotalDebitActivitiesTxt: Label 'Total Debit Activities';
        TotalCreditActivitiesTxt: Label 'Total Credit Activities';
        EndingBalanceTxt: Label 'Ending Balance';
        BeginningBalanceTxt: Label 'Beginning Balance';
        IncomeStatementHeadingTxt: Label 'Income Statement';
        IncomeStatementNameTxt: Label 'IncomeStatement', Locked = true;
        AccountNameTxt: Label 'Account Name';
        NetChangeTxt: Label 'Net Change';
        StatementOfRetainedEarningsHeadingTxt: Label 'Statement of Retained Earnings';
        StatementOfRetainedEarningsNameTxt: Label 'StatementOfRetainedEarnings', Locked = true;
        StartingDateTxt: Label 'Starting Date';
        EndingDateTxt: Label 'Ending Date';
        AgedAccountsPayableHeadingTxt: Label 'Aged Accounts Payable';
        AgedAccountsPayableNameTxt: Label 'AgedAccountsPayable', Locked = true;
        AgedAccountsReceivableHeaderTxt: Label 'Aged Accounts Receivable';
        AgedAccountsReceivableNameTxt: Label 'AgedAccountsReceivable', Locked = true;
        BalanceDueTxt: Label 'Balance Due';
        CurrentTxt: Label 'Current';
        UpTo30DaysTxt: Label 'Up to 30 Days';
        Days31To60Txt: Label '31-60 Days';
        Over60DaysTxt: Label 'Over 60 Days';
        AgedByTxt: Label 'Aged By';
        AgedAsOfDateTxt: Label 'Aged as of Date';
        DueDateTxt: Label 'Due Date';
        CashFlowHeadingTxt: Label 'Cash Flow Statement';
        CashFlowNameTxt: Label 'CashFlow', Locked = true;
        PeriodStartTxt: Label 'Period Start';
        PeriodEndTxt: Label 'Period End';
        DescriptionStaticTxt: Label 'Description', Locked = true;
        BalanceStaticTxt: Label 'Balance', Locked = true;
        NoStaticTxt: Label 'No.', Locked = true;
        NameStaticTxt: Label 'Name', Locked = true;
        BeginningBalanceStaticTxt: Label 'Beginning Balance', Locked = true;
        TotalDebitStaticTxt: Label 'Total Debit Activities', Locked = true;
        TotalCreditStaticTxt: Label 'Total Credit Activities', Locked = true;
        EndingBalanceStaticTxt: Label 'Ending Balance', Locked = true;
        AccountNameStaticTxt: Label 'Account Name', Locked = true;
        NetChangeStaticTxt: Label 'Net Change', Locked = true;
        BalanceDueStaticTxt: Label 'Balance Due', Locked = true;
        CurrentStaticTxt: Label 'Current', Locked = true;
        UpTo30StaticTxt: Label 'Up to 30 Days', Locked = true;
        Days31To60StaticTxt: Label '31-60 Days', Locked = true;
        Over60StaticTxt: Label 'Over 60 Days', Locked = true;
        WebServiceErr: Label 'The webservice %1 required for this excel report is missing.', Comment = '%1 - Web service name';
        ODataUtilityTelemetryCategoryTxt: Label 'AL OData Utility', Locked = true;
        NoTokenForMetadataTelemetryErr: Label 'Access token could not be retrieved.', Locked = true;
        FailedToSendRequestErr: Label 'The request could not be sent. Details: %1.', Comment = '%1 = a more detailed error message';
        ErrorStatusCodeReturnedErr: Label 'The request failed with status code: %1.', Comment = '%1 = a http status code, for example 401';
        BearerTokenTemplateTxt: Label 'Bearer %1', Locked = true;
        CallingEndpointTxt: Label 'Calling endpoint %1 with correlation id %2', Locked = true;
        EditInExcelUsageWithCentralizedDeploymentsTxt: Label 'Edit in Excel invoked with "Use Centralized deployments" = %1', Locked = true;
        SaveFileDialogTitleMsg: Label 'Save XML file';
        MetadataFileNameTxt: Label 'metadata.xml', Locked = true;
        SaveFileDialogFilterMsg: Label 'XML Files (*.xml)|*.xml';

    [TryFunction]
    procedure GenerateSelectText(ServiceNameParam: Text; ObjectTypeParam: Option ,,,,,"Codeunit",,,"Page","Query"; var SelectTextParam: Text)
    var
        TenantWebServiceColumns: Record "Tenant Web Service Columns";
        TenantWebService: Record "Tenant Web Service";
        FirstColumn: Boolean;
    begin
        if TenantWebService.Get(ObjectTypeParam, ServiceNameParam) then begin
            FirstColumn := true;
            TenantWebServiceColumns.SetRange(TenantWebServiceID, TenantWebService.RecordId);

            if TenantWebServiceColumns.Find('-') then begin
                SelectTextParam := '$select=';
                repeat
                    if not FirstColumn then
                        SelectTextParam += ','
                    else
                        FirstColumn := false;

                    SelectTextParam += TenantWebServiceColumns."Field Name";
                until TenantWebServiceColumns.Next() = 0;
            end;
        end;
    end;

    [TryFunction]
    procedure GenerateODataV3FilterText(ServiceNameParam: Text; ObjectTypeParam: Option ,,,,,"Codeunit",,,"Page","Query"; var FilterTextParam: Text)
    begin
        ODataProtocolVersion := ODataProtocolVersion::V3;
        FilterTextParam := GenerateFilterText(ServiceNameParam, ObjectTypeParam);
        if FilterTextParam <> '' then
            FilterTextParam := StrSubstNo('$filter=%1', FilterTextParam);
    end;

    [TryFunction]
    procedure GenerateODataV4FilterText(ServiceNameParam: Text; ObjectTypeParam: Option ,,,,,"Codeunit",,,"Page","Query"; var FilterTextParam: Text)
    begin
        ODataProtocolVersion := ODataProtocolVersion::V4;
        FilterTextParam := GenerateFilterText(ServiceNameParam, ObjectTypeParam);
        if FilterTextParam <> '' then
            FilterTextParam := StrSubstNo('$filter=%1', FilterTextParam);
    end;

    local procedure GenerateFilterText(ServiceNameParam: Text; ObjectTypeParam: Option ,,,,,"Codeunit",,,"Page","Query"): Text
    var
        TenantWebService: Record "Tenant Web Service";
        TableItemFilterTextDictionary: DotNet GenericDictionary2;
        FilterText: Text;
    begin
        if TenantWebService.Get(ObjectTypeParam, ServiceNameParam) then begin
            TableItemFilterTextDictionary := TableItemFilterTextDictionary.Dictionary();
            GetNAVFilters(TenantWebService, TableItemFilterTextDictionary);
            FilterText := CombineFiltersFromTables(TenantWebService, TableItemFilterTextDictionary);
        end;

        exit(FilterText);
    end;

    procedure GenerateODataV3Url(ServiceRootUrlParam: Text; ServiceNameParam: Text; ObjectTypeParam: Option ,,,,,,,,"Page","Query"): Text
    begin
        exit(GenerateUrl(ServiceRootUrlParam, ServiceNameParam, ObjectTypeParam, ODataProtocolVersion::V3));
    end;

    procedure GenerateODataV4Url(ServiceRootUrlParam: Text; ServiceNameParam: Text; ObjectTypeParam: Option ,,,,,,,,"Page","Query"): Text
    begin
        exit(GenerateUrl(ServiceRootUrlParam, ServiceNameParam, ObjectTypeParam, ODataProtocolVersion::V4));
    end;

    local procedure GenerateUrl(ServiceRootUrlParam: Text; ServiceNameParam: Text; ObjectTypeParam: Option ,,,,,,,,"Page","Query"; ODataProtocolVersionParam: Option V3,V4): Text
    var
        TenantWebService: Record "Tenant Web Service";
        TenantWebServiceOData: Record "Tenant Web Service OData";
        WebServiceManagement: Codeunit "Web Service Management";
        ODataUrl: Text;
        SelectText: Text;
        FilterText: Text;
    begin
        if TenantWebService.Get(ObjectTypeParam, ServiceNameParam) then begin
            TenantWebServiceOData.SetRange(TenantWebServiceID, TenantWebService.RecordId);

            if TenantWebServiceOData.FindFirst() then begin
                SelectText := WebServiceManagement.GetODataSelectClause(TenantWebServiceOData);
                if ODataProtocolVersionParam = ODataProtocolVersionParam::V3 then
                    FilterText := WebServiceManagement.GetODataFilterClause(TenantWebServiceOData)
                else
                    FilterText := WebServiceManagement.GetODataV4FilterClause(TenantWebServiceOData);
            end;
        end;

        ODataUrl := BuildUrl(ServiceRootUrlParam, SelectText, FilterText);
        exit(ODataUrl);
    end;

    local procedure BuildUrl(ServiceRootUrlParam: Text; SelectTextParam: Text; FilterTextParam: Text): Text
    var
        ODataUrl: Text;
        preSelectTextConjunction: Text;
    begin
        if StrPos(ServiceRootUrlParam, '?tenant=') > 0 then
            preSelectTextConjunction := '&'
        else
            preSelectTextConjunction := '?';

        if (StrLen(SelectTextParam) > 0) and (StrLen(FilterTextParam) > 0) then
            ODataUrl := ServiceRootUrlParam + preSelectTextConjunction + SelectTextParam + '&' + FilterTextParam
        else
            if StrLen(SelectTextParam) > 0 then
                ODataUrl := ServiceRootUrlParam + preSelectTextConjunction + SelectTextParam
            else
                // FilterText is based on SelectText, so it doesn't make sense to have only the FilterText.
                ODataUrl := ServiceRootUrlParam;

        exit(ODataUrl);
    end;

    local procedure CombineFiltersFromTables(var TenantWebService: Record "Tenant Web Service"; TableItemFilterTextDictionaryParam: DotNet GenericDictionary2): Text
    var
        WebServiceManagement: Codeunit "Web Service Management";
        KeyValuePair: DotNet GenericKeyValuePair2;
        ODataFilterGenerator: DotNet ODataFilterGenerator;
        "Filter": Text;
        Conjunction: Text;
        DataItemFilterText: Text;
        FilterTextForSelectedColumns: Text;
    begin
        foreach KeyValuePair in TableItemFilterTextDictionaryParam do begin
            FilterTextForSelectedColumns := WebServiceManagement.RemoveUnselectedColumnsFromFilter(TenantWebService, KeyValuePair.Key, KeyValuePair.Value);
            case TenantWebService."Object Type" of
                TenantWebService."Object Type"::Page:
                    DataItemFilterText := ODataFilterGenerator.CreateODataV4Filter(KeyValuePair.Key, FilterTextForSelectedColumns, 0);
                TenantWebService."Object Type"::Query:
                    DataItemFilterText := ODataFilterGenerator.CreateODataV4Filter(KeyValuePair.Key, FilterTextForSelectedColumns,
                        TenantWebService."Object ID");
            end;
            Filter := StrSubstNo('%1%2%3', Filter, Conjunction, DataItemFilterText);
            Conjunction := ' and ';
        end;
        exit(Filter);
    end;

    [TryFunction]
    local procedure FindColumnsFromNAVFilters(var TenantWebService: Record "Tenant Web Service"; TableItemFilterTextDictionaryParam: DotNet GenericDictionary2; var ColumnListParam: DotNet GenericList1)
    var
        TenantWebServiceColumns: Record "Tenant Web Service Columns";
        FieldTable: Record "Field";
        Regex: DotNet Regex;
        LocalFilterSegments: DotNet Array;
        TempString1: DotNet String;
        TempString2: DotNet String;
        KeyValuePair: DotNet GenericKeyValuePair2;
        LocalFilterText: Text;
        I: Integer;
        Column: Text;
        IndexOfKeyStart: Integer;
        IndexOfValueEnd: Integer;
    begin
        // SORTING(No.) where(No=FILTER(01121212..01454545|31669966),Balance Due=FILTER(>0))

        foreach KeyValuePair in TableItemFilterTextDictionaryParam do begin
            LocalFilterText := DelStr(KeyValuePair.Value, 1, StrPos(KeyValuePair.Value, 'WHERE') + 5);  // becomes No=FILTER(01121212..01454545|31669966),Balance Due=FILTER(>0))
            LocalFilterText := DelStr(LocalFilterText, StrLen(LocalFilterText), 1); // remove ), becomes No=FILTER(01121212..01454545|31669966),Balance Due=FILTER(>0)
            LocalFilterSegments := Regex.Split(LocalFilterText, '=FILTER'); // No   (01121212..01454545|31669966),Balance Due   (>0)

            // Break all the filters into key value pairs.
            for I := 0 to LocalFilterSegments.Length - 2 do begin
                TempString1 := LocalFilterSegments.GetValue(I);
                TempString2 := LocalFilterSegments.GetValue(I + 1);
                IndexOfKeyStart := TempString1.LastIndexOf(',');
                IndexOfValueEnd := TempString2.LastIndexOf(',');

                // Start index of the key is either at the beginning or right after the comma.
                if IndexOfKeyStart > 0 then
                    IndexOfKeyStart := IndexOfKeyStart + 1
                else
                    IndexOfKeyStart := 0;

                // End index of the value is either right before the comma or at the end.  Make sure we don't confuse commas in last filter value.
                if (IndexOfValueEnd < 0) or (I = LocalFilterSegments.Length - 2) then
                    IndexOfValueEnd := TempString2.Length;

                Column := TempString1.Substring(IndexOfKeyStart, TempString1.Length - IndexOfKeyStart);

                // Add to the list if the field is in the dataset.
                FieldTable.SetRange(TableNo, KeyValuePair.Key);
                FieldTable.SetFilter(ObsoleteState, '<>%1', FieldTable.ObsoleteState::Removed);
                FieldTable.SetRange("Field Caption", Column);
                if FieldTable.FindFirst() then begin
                    TenantWebServiceColumns.SetRange(TenantWebServiceID, TenantWebService.RecordId);
                    TenantWebServiceColumns.SetRange("Data Item", KeyValuePair.Key);
                    TenantWebServiceColumns.SetRange("Field Number", FieldTable."No.");
                    if TenantWebServiceColumns.FindFirst() then
                        ColumnListParam.Add(Column);
                end;
            end;
        end;
    end;

    local procedure GetNAVFilters(var TenantWebService: Record "Tenant Web Service"; var TableItemFilterTextDictionaryParam: DotNet GenericDictionary2)
    var
        TenantWebServiceFilter: Record "Tenant Web Service Filter";
        WebServiceManagement: Codeunit "Web Service Management";
        FilterText: Text;
    begin
        TenantWebServiceFilter.SetRange(TenantWebServiceID, TenantWebService.RecordId());
        if TenantWebServiceFilter.Find('-') then
            repeat
                FilterText := WebServiceManagement.RetrieveTenantWebServiceFilter(TenantWebServiceFilter);
                if StrLen(FilterText) > 0 then
                    TableItemFilterTextDictionaryParam.Add(TenantWebServiceFilter."Data Item", FilterText);
            until TenantWebServiceFilter.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GetColumnsFromFilter(var TenantWebService: Record "Tenant Web Service"; FilterText: Text; var ColumnList: DotNet GenericList1)
    var
        TableItemFilterTextDictionary: DotNet GenericDictionary2;
    begin
        TableItemFilterTextDictionary := TableItemFilterTextDictionary.Dictionary();
        TableItemFilterTextDictionary.Add(1, FilterText);
        FindColumnsFromNAVFilters(TenantWebService, TableItemFilterTextDictionary, ColumnList);
    end;

    procedure EditJournalWorksheetInExcel(PageCaption: Text[240]; PageId: Text; JournalBatchName: Text; JournalTemplateName: Text)
    var
        EditinExcel: Codeunit "Edit in Excel";
        EditinExcelFilters: Codeunit "Edit in Excel Filters";
        ObjectId: Integer;
    begin
        EditinExcelFilters.AddFieldV2('Journal_Batch_Name', Enum::"Edit in Excel Filter Type"::Equal, JournalBatchName, Enum::"Edit in Excel Edm Type"::"Edm.String");
        EditinExcelFilters.AddFieldV2('Journal_Template_Name', Enum::"Edit in Excel Filter Type"::Equal, JournalTemplateName, Enum::"Edit in Excel Edm Type"::"Edm.String");

        Evaluate(ObjectId, CopyStr(PageId, 5));
        EditinExcel.EditPageInExcel(PageCaption, ObjectId, EditinExcelFilters);
    end;

#if not CLEAN26
    [Obsolete('Replaced by EditinExcelHandler.EditPageInExcel(PageCaption: Text[240]; ObjectId: Integer; CodeUnit "Filters")', '23.0')]
    procedure EditWorksheetInExcel(PageCaption: Text[240]; PageId: Text; "Filter": Text)
    var
        EditinExcel: Codeunit "Edit in Excel";
        ObjectId: Integer;
    begin
        Evaluate(ObjectId, CopyStr(PageId, 5));
        EditinExcel.EditPageInExcel(PageCaption, ObjectId);
    end;
#endif

    [Scope('OnPrem')]
    procedure GenerateExcelTemplateWorkBook(ObjectTypeParm: Option ,,,,,"Codeunit",,,"Page","Query"; ServiceNameParm: Text[50]; ShowDialogParm: Boolean; StatementType: Option BalanceSheet,SummaryTrialBalance,CashFlowStatement,StatementOfRetainedEarnings,AgedAccountsReceivable,AgedAccountsPayable,IncomeStatement)
    var
        Company: Record Company;
        TenantWebService: Record "Tenant Web Service";
        FileManagement: Codeunit "File Management";
        AzureADTenant: Codeunit "Azure AD Tenant";
        TempBlob: Codeunit "Temp Blob";
        OfficeAppInfo: DotNet OfficeAppInfo;
        WorkbookSettingsManager: DotNet WorkbookSettingsManager;
        SettingsObject: DotNet DynamicsExtensionSettings;
        NvOutStream: OutStream;
        NvInStream: InStream;
        HostName: Text;
        FileName: Text;
        TempFileName: Text[60];
    begin
        if not TenantWebService.Get(ObjectTypeParm, ServiceNameParm) then
            Error(WebServiceErr, ServiceNameParm);

        CreateOfficeAppInfo(OfficeAppInfo);

        HostName := GetHostName();
        if StrPos(HostName, '?') <> 0 then
            HostName := CopyStr(HostName, 1, StrPos(HostName, '?') - 1);

        TempFileName := ServiceNameParm + '.xltm';

        NavApp.GetResource('ExcelTemplates/' + TempFileName, NvInStream);

        TempBlob.CreateOutStream(NvOutStream);
        CopyStream(NvOutStream, NvInStream);

        // Collect data for template translations to match company generated for
        WorkbookWriter := WorkbookWriter.Open(NvOutStream);
        WorksheetWriter := WorkbookWriter.FirstWorksheet;

        case StatementType of
            StatementType::BalanceSheet:
                AddBalanceSheetCellValues();
            StatementType::SummaryTrialBalance:
                AddSummaryTrialBalancetCellValues();
            StatementType::AgedAccountsPayable:
                AddAgedAccountsPayableCellValues();
            StatementType::AgedAccountsReceivable:
                AddAgedAccountsReceivableCellValues();
            StatementType::CashFlowStatement:
                AddCashFlowStatementCellValues();
            StatementType::IncomeStatement:
                AddIncomeStatementCellValues();
            StatementType::StatementOfRetainedEarnings:
                AddStatementOfRetainedEarningsCellValues();
        end;

        WorkbookSettingsManager := WorkbookSettingsManager.WorkbookSettingsManager(WorkbookWriter.Document);

        SettingsObject := SettingsObject.DynamicsExtensionSettings();
        WorkbookSettingsManager.SettingsObject.Headers.Clear();
        if EnvironmentInfo.IsSaaS() then
            WorkbookSettingsManager.SettingsObject.Headers.Add('BCEnvironment', EnvironmentInfo.GetEnvironmentName());
        if Company.Get(TenantWebService.CurrentCompany) then
            WorkbookSettingsManager.SettingsObject.Headers.Add('Company', Format(Company.Id, 0, 4))
        else
            WorkbookSettingsManager.SettingsObject.Headers.Add('Company', TenantWebService.CurrentCompany);
        WorkbookSettingsManager.SetAppInfo(OfficeAppInfo);
        WorkbookSettingsManager.SetHostName(HostName);
        WorkbookSettingsManager.SetAuthenticationTenant(AzureADTenant.GetAadTenantId());
        WorkbookSettingsManager.SetLanguage(Language.GetCultureName(WindowsLanguage));
        WorkbookWriter.Close();

        FileName := TenantWebService."Service Name" + '.xltm';
        FileManagement.BLOBExport(TempBlob, FileName, ShowDialogParm);
    end;

    local procedure CreateOfficeAppInfo(var OfficeAppInfo: DotNet OfficeAppInfo) // Note: Keep this in sync with System Module - Edit in Excel - Edit in Excel Impl.
    var
        EditinExcelSettings: record "Edit in Excel Settings";
    begin
        OfficeAppInfo := OfficeAppInfo.OfficeAppInfo();
        if EditinExcelSettings.Get() and EditinExcelSettings."Use Centralized deployments" then begin
            OfficeAppInfo.Id := '61bcc63f-b860-4280-8280-3e4fb5ea7726';
            OfficeAppInfo.Store := 'EXCatalog';
            OfficeAppInfo.StoreType := 'EXCatalog';
            OfficeAppInfo.Version := '1.3.0.0';
        end else begin
            OfficeAppInfo.Id := 'WA104379629';
            OfficeAppInfo.Store := 'en-US';
            OfficeAppInfo.StoreType := 'OMEX';
            OfficeAppInfo.Version := '1.3.0.0';
        end;
        Session.LogMessage('0000F7M', StrSubstNo(EditInExcelUsageWithCentralizedDeploymentsTxt, EditinExcelSettings."Use Centralized deployments"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ODataUtilityTelemetryCategoryTxt);
    end;

    procedure ExternalizeName(Name: Text) ConvertedName: Text
    var
        CurrentPosition: Integer;
    begin
        ConvertedName := Name;

        // Mimics the behavior of the compiler when converting a field or web service name to OData.
        CurrentPosition := StrPos(ConvertedName, '%');
        while CurrentPosition > 0 do begin
            ConvertedName := DelStr(ConvertedName, CurrentPosition, 1);
            ConvertedName := InsStr(ConvertedName, 'Percent', CurrentPosition);
            CurrentPosition := StrPos(ConvertedName, '%');
        end;

        CurrentPosition := 1;

        while CurrentPosition <= StrLen(ConvertedName) do begin
            if ConvertedName[CurrentPosition] in [' ', '\', '/', '''', '"', '.', '(', ')', '-', ':'] then
                if CurrentPosition > 1 then begin
                    if ConvertedName[CurrentPosition - 1] = '_' then begin
                        ConvertedName := DelStr(ConvertedName, CurrentPosition, 1);
                        CurrentPosition -= 1;
                    end else
                        ConvertedName[CurrentPosition] := '_';
                end else
                    ConvertedName[CurrentPosition] := '_';

            CurrentPosition += 1;
        end;

        ConvertedName := RemoveTrailingUnderscore(ConvertedName);
    end;

    local procedure RemoveTrailingUnderscore(Input: Text): Text
    begin
        Input := DelChr(Input, '>', '_');
        exit(Input);
    end;

    local procedure AddBalanceSheetCellValues()
    begin
        WorksheetWriter.Name(BalanceSheetNameTxt);

        WorksheetWriter.UpdateCellValueText(2, 'B', BalanceSheetHeadingTxt);

        WorksheetWriter.SetCellValueText(4, 'B', CompanyTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(5, 'B', CurrencyTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(7, 'B', PrintedTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(8, 'B', AsOfDateTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(10, 'B', PrintDollarLinesTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.UpdateCellValueText(11, 'B', DesciptionTxt);
        WorksheetWriter.UpdateTableColumnHeader('BalanceSheetTable', DescriptionStaticTxt, DesciptionTxt);
        WorksheetWriter.UpdateCellValueText(11, 'C', BalanceTxt);
        WorksheetWriter.UpdateTableColumnHeader('BalanceSheetTable', BalanceStaticTxt, BalanceTxt);
    end;

    local procedure AddSummaryTrialBalancetCellValues()
    begin
        WorksheetWriter.Name(SummaryTrialBalanceNameTxt);

        WorksheetWriter.UpdateCellValueText(2, 'B', SummaryTrialBalanceHeadingTxt);
        WorksheetWriter.SetCellValueText(2, 'F', CompanyTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(4, 'B', PrintedTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(4, 'F', FromDateTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(5, 'F', ToDateTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(6, 'B', PrintDollarLinesTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.UpdateCellValueText(7, 'B', NoTxt);
        WorksheetWriter.UpdateTableColumnHeader('SummaryTrialBalanceTable', NoStaticTxt, NoTxt);
        WorksheetWriter.UpdateCellValueText(7, 'C', NameTxt);
        WorksheetWriter.UpdateTableColumnHeader('SummaryTrialBalanceTable', NameStaticTxt, NameTxt);
        WorksheetWriter.UpdateCellValueText(7, 'D', BeginningBalanceTxt);
        WorksheetWriter.UpdateTableColumnHeader('SummaryTrialBalanceTable', BeginningBalanceStaticTxt, BeginningBalanceTxt);
        WorksheetWriter.UpdateCellValueText(7, 'E', TotalDebitActivitiesTxt);
        WorksheetWriter.UpdateTableColumnHeader('SummaryTrialBalanceTable', TotalDebitStaticTxt, TotalDebitActivitiesTxt);
        WorksheetWriter.UpdateCellValueText(7, 'F', TotalCreditActivitiesTxt);
        WorksheetWriter.UpdateTableColumnHeader('SummaryTrialBalanceTable', TotalCreditStaticTxt, TotalCreditActivitiesTxt);
        WorksheetWriter.UpdateCellValueText(7, 'G', EndingBalanceTxt);
        WorksheetWriter.UpdateTableColumnHeader('SummaryTrialBalanceTable', EndingBalanceStaticTxt, EndingBalanceTxt);
    end;

    local procedure AddIncomeStatementCellValues()
    begin
        WorksheetWriter.Name(IncomeStatementNameTxt);

        WorksheetWriter.UpdateCellValueText(2, 'B', IncomeStatementHeadingTxt);

        WorksheetWriter.SetCellValueText(5, 'B', CompanyTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(6, 'B', CurrencyTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(7, 'B', PrintedTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(9, 'B', FromDateTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(10, 'B', ToDateTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(12, 'B', PrintDollarLinesTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.UpdateCellValueText(13, 'B', AccountNameTxt);
        WorksheetWriter.UpdateTableColumnHeader('IncomeStatementTable', AccountNameStaticTxt, AccountNameTxt);
        WorksheetWriter.UpdateCellValueText(13, 'C', NetChangeTxt);
        WorksheetWriter.UpdateTableColumnHeader('IncomeStatementTable', NetChangeStaticTxt, NetChangeTxt);
    end;

    local procedure AddStatementOfRetainedEarningsCellValues()
    begin
        WorksheetWriter.Name(StatementOfRetainedEarningsNameTxt);

        WorksheetWriter.UpdateCellValueText(2, 'B', StatementOfRetainedEarningsHeadingTxt);

        WorksheetWriter.SetCellValueText(5, 'B', CompanyTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(6, 'B', CurrencyTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(7, 'B', PrintedTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(9, 'B', StartingDateTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(10, 'B', EndingDateTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(12, 'B', PrintDollarLinesTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.UpdateCellValueText(13, 'B', DesciptionTxt);
        WorksheetWriter.UpdateTableColumnHeader('StatementofRetainedEarningsTable', DescriptionStaticTxt, DesciptionTxt);
        WorksheetWriter.UpdateCellValueText(13, 'C', NetChangeTxt);
        WorksheetWriter.UpdateTableColumnHeader('StatementofRetainedEarningsTable', NetChangeStaticTxt, NetChangeTxt);
    end;

    local procedure AddAgedAccountsPayableCellValues()
    begin
        WorksheetWriter.Name(AgedAccountsPayableNameTxt);

        WorksheetWriter.UpdateCellValueText(2, 'C', AgedAccountsPayableHeadingTxt);

        WorksheetWriter.SetCellValueText(2, 'G', CompanyTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(4, 'C', AgedAsOfDateTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(4, 'G', CurrencyTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(5, 'C', AgedByTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(5, 'D', DueDateTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(5, 'G', PrintedTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(6, 'H', PrintDollarLinesTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.UpdateCellValueText(7, 'C', NoTxt);
        WorksheetWriter.UpdateTableColumnHeader('AgedAccountsPayableTable', NoStaticTxt, NoTxt);
        WorksheetWriter.UpdateCellValueText(7, 'D', NameTxt);
        WorksheetWriter.UpdateTableColumnHeader('AgedAccountsPayableTable', NameStaticTxt, NameTxt);
        WorksheetWriter.UpdateCellValueText(7, 'E', BalanceDueTxt);
        WorksheetWriter.UpdateTableColumnHeader('AgedAccountsPayableTable', BalanceDueStaticTxt, BalanceDueTxt);
        WorksheetWriter.UpdateCellValueText(7, 'F', CurrentTxt);
        WorksheetWriter.UpdateTableColumnHeader('AgedAccountsPayableTable', CurrentStaticTxt, CurrentTxt);
        WorksheetWriter.UpdateCellValueText(7, 'G', UpTo30DaysTxt);
        WorksheetWriter.UpdateTableColumnHeader('AgedAccountsPayableTable', UpTo30StaticTxt, UpTo30DaysTxt);
        WorksheetWriter.UpdateCellValueText(7, 'H', Days31To60Txt);
        WorksheetWriter.UpdateTableColumnHeader('AgedAccountsPayableTable', Days31To60StaticTxt, Days31To60Txt);
        WorksheetWriter.UpdateCellValueText(7, 'I', Over60DaysTxt);
        WorksheetWriter.UpdateTableColumnHeader('AgedAccountsPayableTable', Over60StaticTxt, Over60DaysTxt);
    end;

    local procedure AddAgedAccountsReceivableCellValues()
    begin
        WorksheetWriter.Name(AgedAccountsReceivableNameTxt);

        WorksheetWriter.UpdateCellValueText(2, 'C', AgedAccountsReceivableHeaderTxt);

        WorksheetWriter.SetCellValueText(2, 'G', CompanyTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(4, 'C', AgedAsOfDateTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(4, 'G', CurrencyTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(5, 'C', AgedByTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(5, 'D', DueDateTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(5, 'G', PrintedTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(6, 'H', PrintDollarLinesTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.UpdateCellValueText(7, 'C', NoTxt);
        WorksheetWriter.UpdateTableColumnHeader('AgedAccountsReceivableTable', NoStaticTxt, NoTxt);
        WorksheetWriter.UpdateCellValueText(7, 'D', NameTxt);
        WorksheetWriter.UpdateTableColumnHeader('AgedAccountsReceivableTable', NameStaticTxt, NameTxt);
        WorksheetWriter.UpdateCellValueText(7, 'E', BalanceDueTxt);
        WorksheetWriter.UpdateTableColumnHeader('AgedAccountsReceivableTable', BalanceDueStaticTxt, BalanceDueTxt);
        WorksheetWriter.UpdateCellValueText(7, 'F', CurrentTxt);
        WorksheetWriter.UpdateTableColumnHeader('AgedAccountsReceivableTable', CurrentStaticTxt, CurrentTxt);
        WorksheetWriter.UpdateCellValueText(7, 'G', UpTo30DaysTxt);
        WorksheetWriter.UpdateTableColumnHeader('AgedAccountsReceivableTable', UpTo30StaticTxt, UpTo30DaysTxt);
        WorksheetWriter.UpdateCellValueText(7, 'H', Days31To60Txt);
        WorksheetWriter.UpdateTableColumnHeader('AgedAccountsReceivableTable', Days31To60StaticTxt, Days31To60Txt);
        WorksheetWriter.UpdateCellValueText(7, 'I', Over60DaysTxt);
        WorksheetWriter.UpdateTableColumnHeader('AgedAccountsReceivableTable', Over60StaticTxt, Over60DaysTxt);
    end;

    local procedure AddCashFlowStatementCellValues()
    begin
        WorksheetWriter.Name(CashFlowNameTxt);

        WorksheetWriter.UpdateCellValueText(2, 'B', CashFlowHeadingTxt);

        WorksheetWriter.SetCellValueText(5, 'B', CompanyTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(6, 'B', CurrencyTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(7, 'B', PrintedTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(9, 'B', PeriodStartTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(10, 'B', PeriodEndTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(12, 'B', PrintDollarLinesTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.UpdateCellValueText(13, 'B', DesciptionTxt);
        WorksheetWriter.UpdateTableColumnHeader('CashFlowTable', DescriptionStaticTxt, DesciptionTxt);
        WorksheetWriter.UpdateCellValueText(13, 'C', NetChangeTxt);
        WorksheetWriter.UpdateTableColumnHeader('CashFlowTable', NetChangeStaticTxt, NetChangeTxt);
    end;

    [Scope('OnPrem')]
    procedure GetTenantWebServiceMetadata(TenantWebService: Record "Tenant Web Service"; var TenantWebServiceMetadata: DotNet QueryMetadataReader)
    var
        AllObj: Record AllObj;
        ApplicationObjectMetadata: Record "Application Object Metadata";
        inStream: InStream;
    begin
        AllObj.Get(TenantWebService."Object Type", TenantWebService."Object ID");
        ApplicationObjectMetadata.Get(AllObj."App Runtime Package ID", TenantWebService."Object Type", TenantWebService."Object ID");
        if not ApplicationObjectMetadata.Metadata.HasValue() then
            exit;

        ApplicationObjectMetadata.CalcFields(Metadata);
        ApplicationObjectMetadata.Metadata.CreateInStream(inStream, TEXTENCODING::Windows);

        TenantWebServiceMetadata := TenantWebServiceMetadata.FromStream(inStream);
    end;

    [Scope('OnPrem')]
    procedure DownloadODataMetadataDocument()
    var
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        MetadataTempBlob: Codeunit "Temp Blob";
        HttpStatusCode: DotNet HttpStatusCode;
        ResponseHeaders: DotNet NameValueCollection;
        ResponseInStream: InStream;
        FileName: Text;
    begin
        MetadataTempBlob.CreateInStream(ResponseInStream);

        if not CreateMetadataWebRequest(HttpWebRequestMgt) then
            Error(FailedToSendRequestErr, GetLastErrorText());

        if not HttpWebRequestMgt.GetResponse(ResponseInStream, HttpStatusCode, ResponseHeaders) then
            Error(FailedToSendRequestErr, GetLastErrorText());

        if not HttpStatusCode.Equals(HttpStatusCode.OK) then
            Error(ErrorStatusCodeReturnedErr, HttpStatusCode);

        FileName := MetadataFileNameTxt;
        DownloadFromStream(ResponseInStream, SaveFileDialogTitleMsg, '', SaveFileDialogFilterMsg, FileName);
    end;

    [Scope('OnPrem')]
    procedure CreateMetadataWebRequest(var HttpWebRequestMgt: Codeunit "Http Web Request Mgt."): Boolean
    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        UrlHelper: Codeunit "Url Helper";
        Token: SecretText;
        Endpoint: Text;
        CorrelationId: Guid;
    begin
        if not EnvironmentInfo.IsSaaS() then
            exit(false);

        Endpoint := GetUrl(CLIENTTYPE::ODataV4) + '/$metadata';
        Token := AzureAdMgt.GetAccessTokenAsSecretText(UrlHelper.GetFixedEndpointWebServiceUrl(), '', false);
        if Token.IsEmpty() then begin
            Session.LogMessage('0000E51', NoTokenForMetadataTelemetryErr, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ODataUtilityTelemetryCategoryTxt);
            exit(false);
        end;

        CorrelationId := CreateGuid();
        Session.LogMessage('0000E53', StrSubstNo(CallingEndpointTxt, Endpoint, CorrelationId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ODataUtilityTelemetryCategoryTxt);

        HttpWebRequestMgt.Initialize(Endpoint);
        HttpWebRequestMgt.SetMethod('GET');
        HttpWebRequestMgt.AddHeader('Authorization', SecretStrSubstNo(BearerTokenTemplateTxt, Token));
        HttpWebRequestMgt.AddHeader('x-ms-correlation-id', CorrelationId);
        HttpWebRequestMgt.SetUserAgent('BusinessCentral/cod6170');
        exit(true);
    end;

    local procedure GetExcelAddinProviderServiceUrl(): Text
    var
        UrlHelper: Codeunit "Url Helper";
    begin
        exit(UrlHelper.GetExcelAddinProviderServiceUrl());
    end;

    procedure GetHostName(): Text
    begin
        if EnvironmentInfo.IsSaaS() then
            exit(GetExcelAddinProviderServiceUrl());
        exit(GetUrl(CLIENTTYPE::Web));
    end;
}

