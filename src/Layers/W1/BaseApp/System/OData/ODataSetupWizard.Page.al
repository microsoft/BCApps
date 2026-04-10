namespace System.Integration;

using System;
using System.Environment;
using System.Environment.Configuration;
using System.Integration.Excel;
using System.Reflection;
using System.Utilities;

page 6711 "OData Setup Wizard"
{
    Caption = 'Reporting Data Setup';
    PageType = NavigatePage;
    SourceTable = "Tenant Web Service";
    SourceTableTemporary = true;
    UsageCategory = Administration;
    AdditionalSearchTerms = 'Setup up reporting data for your own reports';

    layout
    {
        area(content)
        {
            group(Control17)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and not (CurrentPage = 5);
#pragma warning disable AA0100
                field("MediaResourcesStandard.""Media Reference"""; MediaResourcesStandard."Media Reference")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Control19)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and (CurrentPage = 5);
#pragma warning disable AA0100
                field("MediaResourcesDone.""Media Reference"""; MediaResourcesDone."Media Reference")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Step1)
            {
                Visible = CurrentPage = 1;
                group("Para1.1")
                {
                    Caption = 'Welcome to Reporting Data Setup';
                    label("Para1.1.1_aslabel")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'You can create data sets that you can use for building reports in Excel, Power BI, or any other reporting tool that works with an OData data source.';
                    }
                    label("Whitespace1.1.1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = '';
                    }
                    label("Para1.1.2")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'For some tools such as Power BI, selecting columns or setting filters from this assisted setup guide will have no effect. After you complete the assisted setup, use Power BI Desktop to create or modify reports to use the newly created web service, selecting the columns and setting the filters as needed.';
                    }
                }
                group("Para1.2")
                {
                    Caption = 'Let''s go!';
                    label("Para1.2.1_aslabel")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Choose Next so you can create reporting data sets.';
                    }
                }
            }
            group(Step2)
            {
                Caption = '';
                Visible = CurrentPage = 2;
                group("Para2.1")
                {
                    Caption = 'I want to...';
                    field(ActionType; ActionType)
                    {
                        ApplicationArea = Basic, Suite;
                        OptionCaption = 'Create a new data set,Create a copy of an existing data set,Edit an existing data set';
                        ShowCaption = false;

                        trigger OnValidate()
                        begin
                            Rec."Object ID" := 0;
                            ClearTables();
                            ClearObjectType();
                            ClearName();
                        end;
                    }
                }
            }
            group(Step3)
            {
                InstructionalText = '';
                Visible = CurrentPage = 3;
                group("Para3.1")
                {
                    Caption = 'Select the data you would like to use for your reports and define a name for this data set.';
                    InstructionalText = '';
                    group(Control28)
                    {
                        ShowCaption = false;
                        Visible = ActionType > 0;
                        field(NameLookup; ServiceNameLookup)
                        {
                            ApplicationArea = Basic, Suite;
                            AssistEdit = false;
                            Caption = 'Name';
                            Lookup = true;

                            trigger OnLookup(var Text: Text): Boolean
                            var
                                TenantWebService: Record "Tenant Web Service";
                                TenantWebServicesLookup: Page "Tenant Web Services Lookup";
                            begin
                                TenantWebServicesLookup.LookupMode := true;
                                if TenantWebServicesLookup.RunModal() = ACTION::LookupOK then begin
                                    TenantWebServicesLookup.GetRecord(TenantWebService);
                                    ServiceNameLookup := TenantWebService."Service Name";
                                    ObjectTypeLookup := TenantWebService."Object Type";
                                    Rec."Object ID" := TenantWebService."Object ID";
                                end;
                                Rec."Service Name" := ServiceNameLookup;
                                Rec."Object Type" := ObjectTypeLookup;
                                Rec."Object ID" := TenantWebService."Object ID";
                                if ActionType = ActionType::"Create a copy of an existing data set" then
                                    Rec."Service Name" := ServiceNameEdit;
                                ClearTables();
                            end;

                            trigger OnValidate()
                            var
                                TenantWebService: Record "Tenant Web Service";
                            begin
                                TenantWebService.SetRange("Service Name", ServiceNameLookup);
                                if TenantWebService.FindFirst() then begin
                                    Rec."Service Name" := ServiceNameLookup;
                                    ObjectTypeLookup := TenantWebService."Object Type";
                                    Rec."Object Type" := ObjectTypeLookup;
                                    Rec."Object ID" := TenantWebService."Object ID";
                                    if ActionType = ActionType::"Create a copy of an existing data set" then
                                        Rec."Service Name" := ServiceNameEdit;
                                end else
                                    Error(UseLookupErr);
                            end;
                        }
                    }
                    group(Control32)
                    {
                        ShowCaption = false;
                        Visible = ActionType < 2;
                        field(ServiceNameEdit; ServiceNameEdit)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'New Name';
                            ExtendedDatatype = None;
                            ToolTip = 'Specifies the service name. Name cannot contain space(s).';

                            trigger OnValidate()
                            var
                                TenantWebService: Record "Tenant Web Service";
                                WebServiceManagement: Codeunit "Web Service Management";
                            begin
                                Rec."Service Name" := ServiceNameEdit;
                                if not WebServiceManagement.IsServiceNameValid(ServiceNameEdit) then
                                    Error(WebServiceNameNotValidErr);
                                if not (ActionType = ActionType::"Edit an existing data set") then begin
                                    TenantWebService.SetRange("Service Name", Rec."Service Name");
                                    if TenantWebService.FindFirst() then
                                        Error(DuplicateServiceNameErr);
                                end;
                            end;
                        }
                    }
                    field(ObjectTypeLookup; ObjectTypeLookup)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Data Source Type';
                        Enabled = ActionType = 0;
                        OptionCaption = ',,,,,,,,Page,Query';

                        trigger OnValidate()
                        begin
                            Rec."Object Type" := ObjectTypeLookup;
                            if Rec."Object Type" <> xRec."Object Type" then begin
                                ClearTables();
                                Rec."Object ID" := 0;
                            end;
                        end;
                    }
                    field("Object ID"; Rec."Object ID")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Data Source Id';
                        Enabled = ActionType = 0;
                        Lookup = true;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            AllObjWithCaption: Record AllObjWithCaption;
                            AllObjectsWithCaption: Page "All Objects with Caption";
                        begin
                            if ObjectTypeLookup = Rec."Object Type"::Page then begin
                                AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Page);
                                AllObjWithCaption.SetRange("Object Subtype", 'List')
                            end else
                                if ObjectTypeLookup = Rec."Object Type"::Query then
                                    AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Query);

                            AllObjectsWithCaption.SetTableView(AllObjWithCaption);

                            AllObjectsWithCaption.LookupMode := true;
                            if AllObjectsWithCaption.RunModal() = ACTION::LookupOK then begin
                                AllObjectsWithCaption.GetRecord(AllObjWithCaption);
                                if not ((AllObjWithCaption."Object Type" = AllObjWithCaption."Object Type"::Page) or
                                        (AllObjWithCaption."Object Type" = AllObjWithCaption."Object Type"::Query))
                                then
                                    Error(InvalidObjectTypeErr);
                                if (AllObjWithCaption."Object Type" = AllObjWithCaption."Object Type"::Page) and
                                   (AllObjWithCaption."Object Subtype" <> 'List')
                                then
                                    Error(InvalidPageTypeErr);
                                Rec."Object ID" := AllObjWithCaption."Object ID";
                                ObjectTypeLookup := AllObjWithCaption."Object Type";

                                if Rec."Object ID" <> xRec."Object ID" then
                                    ClearTables();
                            end;
                        end;

                        trigger OnValidate()
                        var
                            AllObjWithCaption: Record AllObjWithCaption;
                        begin
                            if ObjectTypeLookup = ObjectTypeLookup::Page then begin
                                AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Page);
                                AllObjWithCaption.SetRange("Object ID", Rec."Object ID");
                                if AllObjWithCaption.FindFirst() then
                                    if AllObjWithCaption."Object Subtype" <> 'List' then
                                        Error(InvalidPageTypeErr);
                            end;

                            if Rec."Object ID" <> xRec."Object ID" then
                                ClearTables();
                        end;
                    }
                    field(ObjectName; DisplayObjectName())
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Data Source Name';
                        Enabled = false;
                    }
                }
            }
            group(Step4)
            {
                Caption = '';
                Visible = CurrentPage = 4;
                group("Para4.1")
                {
                    Caption = 'Choose the Fields to include in your data set';
                    InstructionalText = 'Changing fields will clear previously set filters.';
                    part(ODataColSubForm; "OData Column Choose SubForm")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = ' ';
                    }
                }
            }
            group(Step5)
            {
                Visible = CurrentPage = 5;
                group("Para5.1")
                {
                    Caption = 'Success!';
                    label("Para5.1.1_aslabel")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Your data set has been successfully created!';
                    }
                    field(ODataUrl; oDataUrl)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'OData URL';
                        Editable = false;
                        ExtendedDatatype = URL;
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(AddFiltersAction)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Add Filters';
                Enabled = CurrentPage = 4;
                Image = "Filter";
                InFooterBar = true;
                Visible = true;

                trigger OnAction()
                begin
                    Clear(ChangeFields);
                    ChangeFields := CurrPage.ODataColSubForm.PAGE.IncludeIsChanged();
                    if ChangeFields then begin
                        Clear(TempTenantWebServiceFilter);
                        TempTenantWebServiceFilter.DeleteAll();
                    end;

                    Clear(TempTenantWebServiceColumns);
                    if TempTenantWebServiceColumns.FindFirst() then
                        TempTenantWebServiceColumns.DeleteAll();

                    CurrPage.ODataColSubForm.PAGE.GetColumns(TempTenantWebServiceColumns);
                    if not TempTenantWebServiceColumns.FindFirst() then
                        Error(MissingFieldsErr);
                    GetFilterText(TempTenantWebServiceColumns)
                end;
            }
            action(BackAction)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Back';
                Enabled = (CurrentPage > 1) and (CurrentPage < 5);
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    CurrentPage := CurrentPage - 1;
                    CurrPage.Update();
                end;
            }
            action(NextAction)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Next';
                Enabled = (CurrentPage >= 1) and (CurrentPage < 4);
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    case CurrentPage of
                        1, 2:
                            CurrentPage := CurrentPage + 1;
                        3:
                            begin
                                if (ActionType = ActionType::"Create a new data set") and (ServiceNameEdit = '') then
                                    Error(MissingServiceNameErr);
                                if (ActionType = ActionType::"Create a copy of an existing data set") and
                                   ((ServiceNameEdit = '') or (ServiceNameLookup = ''))
                                then
                                    Error(MissingServiceNameErr);
                                if (ActionType = ActionType::"Edit an existing data set") and (ServiceNameLookup = '') then
                                    Error(MissingServiceNameErr);
                                if Rec."Object ID" = 0 then
                                    Error(MissingObjectIDErr);

                                CurrPage.Update();
                                CurrPage.ODataColSubForm.PAGE.InitColumns(ObjectTypeLookup, Rec."Object ID", ActionType, ServiceNameLookup, ServiceNameEdit);
                                CurrentPage := CurrentPage + 1;
                            end;
                    end;

                    CurrPage.Update(false);
                end;
            }
            action(PublishAction)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Publish';
                Enabled = CurrentPage = 4;
                Image = Post;
                InFooterBar = true;

                trigger OnAction()
                var
                    GuidedExperience: Codeunit "Guided Experience";
                begin
                    if TempTenantWebServiceColumns.FindFirst() then
                        TempTenantWebServiceColumns.DeleteAll();
                    CurrPage.ODataColSubForm.PAGE.GetColumns(TempTenantWebServiceColumns);
                    if not TempTenantWebServiceColumns.FindFirst() then
                        Error(PublishWithoutFieldsErr);
                    CopyTempTableToConcreteTable();
                    oDataUrl := DisplayODataUrl();
                    GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"OData Setup Wizard");
                    PublishFlag := true;
                    CurrentPage := CurrentPage + 1;
                    CurrPage.Update(false);
                end;
            }
            action(FinishAction)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Finish';
                Enabled = CurrentPage = 5;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
            action(CreateExcelWorkBook)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Excel';
                Enabled = (CurrentPage = 5);
                InFooterBar = true;
                Visible = (ExcelVisible = true);

                trigger OnAction()
                var
                    TenantWebService: Record "Tenant Web Service";
                    EditinExcel: Codeunit "Edit in Excel";
                begin
                    if (ActionType = ActionType::"Create a new data set") or (ActionType = ActionType::"Create a copy of an existing data set") then begin
                        if not TenantWebService.Get(ObjectTypeLookup, ServiceNameEdit) then
                            Error(ServiceNotFoundErr);
                        EditinExcel.GenerateExcelWorkBook(TenantWebService, EditinExcelFilters);
                    end else begin
                        if not TenantWebService.Get(ObjectTypeLookup, ServiceNameLookup) then
                            Error(ServiceNotFoundErr);
                        EditinExcel.GenerateExcelWorkBook(TenantWebService, EditinExcelFilters);
                    end;
                end;
            }
        }
    }

    trigger OnInit()
    begin
        CheckPermissions();
        LoadTopBanners();
        CurrentPage := 1;
        ObjectTypeLookup := Rec."Object Type"::Page;
        Rec."Object Type" := Rec."Object Type"::Page;
        EditInExcelVisible();
    end;

    trigger OnOpenPage()
    begin
        Rec.Insert();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if not PublishFlag then
            if CloseAction = ACTION::OK then
                if not Confirm(NAVNotSetUpQst, false) then
                    exit(false);
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        TempTenantWebServiceColumns: Record "Tenant Web Service Columns" temporary;
        TempTenantWebServiceFilter: Record "Tenant Web Service Filter" temporary;
        EditinExcelFilters: Codeunit "Edit in Excel Filters";
        ClientTypeManagement: Codeunit "Client Type Management";
        CurrentPage: Integer;
        PublishFlag: Boolean;
        TopBannerVisible: Boolean;
        MissingServiceNameErr: Label 'Please enter a Name for the data set.';
        MissingObjectIDErr: Label 'Please enter a data source for the data set.';
        DuplicateServiceNameErr: Label 'This name already exists.';
        WebServiceNameNotValidErr: Label 'The service name is not valid. Please make sure name does not contain space(s).';
        ChangeFields: Boolean;
        ActionType: Option "Create a new data set","Create a copy of an existing data set","Edit an existing data set";
        ServiceNameLookup: Text[240];
        ServiceNameEdit: Text[240];
        ObjectTypeLookup: Option ,,,,,,,,"Page","Query";
        UseLookupErr: Label 'Use the lookup to select existing name.';
        oDataUrl: Text;
        MissingFieldsErr: Label 'Please select field(s) before adding a filter.';
        InvalidPageTypeErr: Label 'Invalid page Id. Only pages of type List are valid.';
        InvalidObjectTypeErr: Label 'Only objects of type page and query are allowed.';
        NAVNotSetUpQst: Label 'The data set has not been set up.\Are you sure you want to exit?';
        PublishWithoutFieldsErr: Label 'Please select field(s) before publishing the data set.';
        PermissionsErr: Label 'You do not have permissions to run this wizard.';
        ServiceNotFoundErr: Label 'The web service does not exist.';
        ExcelVisible: Boolean;

    local procedure GetFilterText(var TempTenantWebServiceColumns: Record "Tenant Web Service Columns" temporary): Boolean
    var
        AllObjWithCaption: Record AllObjWithCaption;
        ODataUtility: Codeunit ODataUtility;
        WebServiceManagement: Codeunit "Web Service Management";
        FieldRef: FieldRef;
        RecRef: RecordRef;
        FilterPage: FilterPageBuilder;
        DataItemDictionary: DotNet GenericDictionary2;
        keyValuePair: DotNet GenericKeyValuePair2;
        ColumnList: DotNet GenericList1;
        OldTableNo: Integer;
        FieldNo: Integer;
        FilterText: Text;
        FilterTextTemp: Text;
        FilterTextSource: Text;
    begin
        if TempTenantWebServiceColumns.FindFirst() then
            DataItemDictionary := DataItemDictionary.Dictionary();
        OldTableNo := 0;
        repeat
            if OldTableNo <> TempTenantWebServiceColumns."Data Item" then begin
                AllObjWithCaption.SetRange("Object ID", TempTenantWebServiceColumns."Data Item");
                AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
                if AllObjWithCaption.FindFirst() then begin
                    FilterPage.AddTable(AllObjWithCaption."Object Caption", TempTenantWebServiceColumns."Data Item");

                    if not DataItemDictionary.ContainsKey(AllObjWithCaption."Object ID") then
                        DataItemDictionary.Add(AllObjWithCaption."Object ID", AllObjWithCaption."Object Caption");
                end;
            end;

            OldTableNo := TempTenantWebServiceColumns."Data Item";
        until TempTenantWebServiceColumns.Next() = 0;

        foreach keyValuePair in DataItemDictionary do begin
            FilterText := '';
            FilterTextTemp := '';
            TempTenantWebServiceFilter.Init();
            TempTenantWebServiceFilter.SetRange(TenantWebServiceID, Rec.RecordId);
            TempTenantWebServiceFilter.SetRange("Data Item", keyValuePair.Key);

            if TempTenantWebServiceFilter.Find('-') then
                FilterTextTemp := WebServiceManagement.RetrieveTenantWebServiceFilter(TempTenantWebServiceFilter);

            if (ActionType = ActionType::"Create a copy of an existing data set") or
               (ActionType = ActionType::"Edit an existing data set")
            then
                GetSourceFilterText(keyValuePair.Key, FilterTextSource);

            if (FilterTextSource <> '') and (FilterTextTemp = '') and (not ChangeFields) then
                FilterPage.SetView(keyValuePair.Value, FilterTextSource)
            else
                if FilterTextTemp <> '' then
                    FilterPage.SetView(keyValuePair.Value, FilterTextTemp);
        end;

        OldTableNo := 0;
        if TempTenantWebServiceColumns.FindFirst() then
            repeat
                if OldTableNo <> TempTenantWebServiceColumns."Data Item" then begin
                    ColumnList := ColumnList.List();
                    TempTenantWebServiceFilter.Init();
                    TempTenantWebServiceFilter.SetRange("Data Item", TempTenantWebServiceColumns."Data Item");

                    if TempTenantWebServiceFilter.Find('-') then
                        FilterTextTemp := WebServiceManagement.RetrieveTenantWebServiceFilter(TempTenantWebServiceFilter);

                    if (ActionType = ActionType::"Create a copy of an existing data set") or
                       (ActionType = ActionType::"Edit an existing data set")
                    then
                        GetSourceFilterText(TempTenantWebServiceColumns."Data Item", FilterTextSource);

                    if (FilterTextSource <> '') and (FilterTextTemp = '') and (not ChangeFields) then
                        ODataUtility.GetColumnsFromFilter(Rec, FilterTextSource, ColumnList)
                    else
                        if FilterTextTemp <> '' then
                            ODataUtility.GetColumnsFromFilter(Rec, FilterTextTemp, ColumnList);
                end;
                OldTableNo := TempTenantWebServiceColumns."Data Item";

                FieldNo := TempTenantWebServiceColumns."Field Number";
                AllObjWithCaption.SetRange("Object ID", TempTenantWebServiceColumns."Data Item");
                AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
                if AllObjWithCaption.FindFirst() then begin
                    Clear(RecRef);
                    RecRef.Open(AllObjWithCaption."Object ID");
                    if RecRef.FieldExist(FieldNo) then begin
                        FieldRef := RecRef.Field(FieldNo);
                        if not ColumnList.Contains(FieldRef.Name) then
                            FilterPage.AddField(AllObjWithCaption."Object Caption", FieldRef);
                    end;
                end;
            until TempTenantWebServiceColumns.Next() = 0;

        if FilterPage.RunModal() then begin
            Clear(TempTenantWebServiceFilter);
            TempTenantWebServiceFilter.DeleteAll();
            foreach keyValuePair in DataItemDictionary do begin
                Clear(TempTenantWebServiceFilter);
                FilterText := FilterPage.GetView(keyValuePair.Value, false);
                TempTenantWebServiceFilter.Init();
                TempTenantWebServiceFilter."Data Item" := keyValuePair.Key;
                TempTenantWebServiceFilter.TenantWebServiceID := Rec.RecordId;
                WebServiceManagement.SetTenantWebServiceFilter(TempTenantWebServiceFilter, FilterText);

                UpdateEditInExcelFilters(AllObjWithCaption, FilterText);

                repeat
                    TempTenantWebServiceFilter."Entry ID" := TempTenantWebServiceFilter."Entry ID" + 1;
                until TempTenantWebServiceFilter.Insert(true);
            end;
            exit(true);
        end;
        exit(false);
    end;

    local procedure UpdateEditInExcelFilters(AllObjWithCaption: Record AllObjWithCaption; FilterText: Text)
    var
        ODataUtility: Codeunit ODataUtility;
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        FieldIndex: Integer;
        TotalFields: Integer;
        FilterValueEnglish: Text;
        FilterEDMValue: Text;
        FilterEDMType: Enum "Edit in Excel Edm Type";
        FieldName: Text;
        FilterType: Enum "Edit in Excel Filter Type";
        PreviousGlobalLanguage: Integer;
        EnglishLanguage: Integer;
    begin
        clear(EditinExcelFilters);
        RecordRef.Open(AllObjWithCaption."Object ID");
        RecordRef.SetView(FilterText);
        TotalFields := RecordRef.FIELDCOUNT;

        for FieldIndex := 1 to TotalFields do begin
            FieldRef := RecordRef.FieldIndex(FieldIndex);

            PreviousGlobalLanguage := GlobalLanguage();
            // Retrieve filters in English-US for ease of processing
            EnglishLanguage := 1033;
            GlobalLanguage(EnglishLanguage);
            FilterValueEnglish := FieldRef.GetFilter();
            GlobalLanguage(PreviousGlobalLanguage);

            if FilterValueEnglish <> '' then
                if IsFilterRange(FieldRef) then
                    if IsFilterRangeSingleValue(FieldRef) then begin
                        FieldName := ODataUtility.ExternalizeName(FieldRef.Name);
                        FilterEDMType := ConvertFieldTypeToEdmType(FieldRef.Type);
                        FilterType := Enum::"Edit in Excel Filter Type"::Equal;
                        FilterEDMValue := ConvertToEDMValue(FilterValueEnglish, FilterEDMType);
                        EditinExcelFilters.AddFieldV2(FieldName, FilterType, FilterEDMValue, FilterEDMType);
                    end
        end
    end;

    local procedure ConvertToEDMValue(FilterValue: Text; EDMType: Enum "Edit in Excel Edm Type"): Text
    var
        FilterEDMValue: Text;
    begin
        FilterEDMValue := FilterValue;
        case EDMType of
            Enum::"Edit in Excel Edm Type"::"Edm.Boolean":
                if FilterValue = 'Yes' then
                    FilterEDMValue := 'true'
                else
                    FilterEDMValue := 'false';
        end;
        exit(FilterEDMValue)
    end;

    [TryFunction]
    local procedure IsFilterRange(FieldRef: FieldRef)
    var
        TempRange: Text;
    begin
        TempRange := FieldRef.GetRangeMax();
    end;

    local procedure IsFilterRangeSingleValue(FieldRef: FieldRef): Boolean
    begin
        exit(FieldRef.GetRangeMin() = FieldRef.GetRangeMax())
    end;

    procedure ConvertFieldTypeToEdmType(FieldType: FieldType): Enum "Edit in Excel Edm Type";
    var
        EdmType: Enum "Edit in Excel Edm Type";
    begin
        case FieldType of
            FieldType::Text, FieldType::Code, FieldType::Guid, FieldType::Option:
                EdmType := Enum::"Edit in Excel Edm Type"::"Edm.String";
            FieldType::Integer:
                EdmType := Enum::"Edit in Excel Edm Type"::"Edm.Int32";
            FieldType::BigInteger:
                EdmType := Enum::"Edit in Excel Edm Type"::"Edm.Int64";
            FieldType::Decimal:
                EdmType := Enum::"Edit in Excel Edm Type"::"Edm.Decimal";
            FieldType::DateTime, FieldType::Date:
                EdmType := Enum::"Edit in Excel Edm Type"::"Edm.DateTimeOffset";
            FieldType::Boolean:
                EdmType := Enum::"Edit in Excel Edm Type"::"Edm.Boolean";
            else
                EdmType := Enum::"Edit in Excel Edm Type"::"Edm.String";
        end;

        exit(EdmType);
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType())) and
           MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType()))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
               MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesDone."Media Reference".HasValue;
    end;

    local procedure DisplayODataUrl(): Text
    var
        TenantWebService: Record "Tenant Web Service";
        ODataUtility: Codeunit ODataUtility;
        ODataServiceRootUrl: Text;
        ODataUrl: Text;
        ObjectTypeParam: Option ,,,,,,,,"Page","Query";
    begin
        Clear(TenantWebService);
        TenantWebService.Init();
        TenantWebService.Validate("Object Type", Rec."Object Type");
        TenantWebService.Validate("Object ID", Rec."Object ID");
        if (ActionType = ActionType::"Create a new data set") or (ActionType = ActionType::"Create a copy of an existing data set") then
            TenantWebService.Validate("Service Name", ServiceNameEdit)
        else
            TenantWebService.Validate("Service Name", ServiceNameLookup);

        TenantWebService.Validate(Published, true);
        if Rec."Object Type" = Rec."Object Type"::Query then begin
            ODataServiceRootUrl := GetUrl(CLIENTTYPE::ODataV4, CompanyName, OBJECTTYPE::Query, Rec."Object ID", TenantWebService);
            ODataUrl := ODataUtility.GenerateODataV4Url(ODataServiceRootUrl, TenantWebService."Service Name", ObjectTypeParam::Query);
            exit(ODataUrl);
        end;
        if Rec."Object Type" = Rec."Object Type"::Page then begin
            ODataServiceRootUrl := GetUrl(CLIENTTYPE::ODataV4, CompanyName, OBJECTTYPE::Page, Rec."Object ID", TenantWebService);
            ODataUrl := ODataUtility.GenerateODataV4Url(ODataServiceRootUrl, TenantWebService."Service Name", ObjectTypeParam::Page);
            exit(ODataUrl);
        end;
    end;

    local procedure CopyTempTableToConcreteTable()
    var
        TenantWebServiceColumns: Record "Tenant Web Service Columns";
        TenantWebServiceFilter: Record "Tenant Web Service Filter";
        TenantWebService: Record "Tenant Web Service";
        TenantWebServiceOData: Record "Tenant Web Service OData";
        SourceTenantWebServiceFilter: Record "Tenant Web Service Filter";
        SourceTenantWebService: Record "Tenant Web Service";
        WebServiceManagement: Codeunit "Web Service Management";
        ODataUtility: Codeunit ODataUtility;
        SelectText: Text;
        ODataV3FilterText: Text;
        ODataV4FilterText: Text;
    begin
        TenantWebService.Init();
        TenantWebService.Validate("Object Type", ObjectTypeLookup);
        TenantWebService.Validate("Object ID", Rec."Object ID");
        TenantWebService.Validate(Published, true);
        if (ActionType = ActionType::"Create a new data set") or
           (ActionType = ActionType::"Create a copy of an existing data set")
        then begin
            TenantWebService.Validate("Service Name", ServiceNameEdit);
            TenantWebService.Insert(true)
        end else begin
            TenantWebService.Validate("Service Name", ServiceNameLookup);
            TenantWebService.Modify(true);
        end;

        if TempTenantWebServiceColumns.FindFirst() then begin
            if ActionType = ActionType::"Edit an existing data set" then begin
                TenantWebServiceColumns.Init();
                TenantWebServiceColumns.SetRange(TenantWebServiceID, TenantWebService.RecordId);
                TenantWebServiceColumns.DeleteAll();
            end;

            repeat
                TenantWebServiceColumns.TransferFields(TempTenantWebServiceColumns, true);
                TenantWebServiceColumns."Entry ID" := 0;
                TenantWebServiceColumns.TenantWebServiceID := TenantWebService.RecordId;
                TenantWebServiceColumns.Insert(true);
            until TempTenantWebServiceColumns.Next() = 0;
        end;

        if TempTenantWebServiceFilter.Find('-') then begin
            if ActionType = ActionType::"Edit an existing data set" then begin
                TenantWebServiceFilter.Init();
                TenantWebServiceFilter.SetRange(TenantWebServiceID, TenantWebService.RecordId);
                TenantWebServiceFilter.DeleteAll();
            end;
            repeat
                TempTenantWebServiceFilter.CalcFields(Filter);
                TenantWebServiceFilter.TransferFields(TempTenantWebServiceFilter, true);
                TenantWebServiceFilter."Entry ID" := 0;

                TenantWebServiceFilter.TenantWebServiceID := TenantWebService.RecordId;

                TenantWebServiceFilter.Insert(true);
            until TempTenantWebServiceFilter.Next() = 0;
        end else
            if ActionType = ActionType::"Create a copy of an existing data set" then
                if SourceTenantWebService.Get(ObjectTypeLookup, ServiceNameLookup) then begin
                    SourceTenantWebServiceFilter.SetRange(TenantWebServiceID, SourceTenantWebService.RecordId);
                    if SourceTenantWebServiceFilter.FindSet() then
                        repeat
                            SourceTenantWebServiceFilter.CalcFields(Filter);
                            TenantWebServiceFilter.TransferFields(SourceTenantWebServiceFilter, true);
                            TenantWebServiceFilter."Entry ID" := 0;

                            TenantWebServiceFilter.TenantWebServiceID := TenantWebService.RecordId;

                            TenantWebServiceFilter.Insert(true);
                        until SourceTenantWebServiceFilter.Next() = 0;
                end;

        if (ActionType = ActionType::"Create a new data set") or
           (ActionType = ActionType::"Create a copy of an existing data set")
        then begin
            TenantWebServiceOData.Validate(TenantWebServiceID, TenantWebService.RecordId);
            ODataUtility.GenerateSelectText(ServiceNameEdit, ObjectTypeLookup, SelectText);
            ODataUtility.GenerateODataV3FilterText(ServiceNameEdit, ObjectTypeLookup, ODataV3FilterText);
            ODataUtility.GenerateODataV4FilterText(ServiceNameEdit, ObjectTypeLookup, ODataV4FilterText);
            WebServiceManagement.SetODataSelectClause(TenantWebServiceOData, SelectText);
            WebServiceManagement.SetODataFilterClause(TenantWebServiceOData, ODataV3FilterText);
            WebServiceManagement.SetODataV4FilterClause(TenantWebServiceOData, ODataV4FilterText);
            TenantWebServiceOData.Insert(true)
        end else begin
            TenantWebServiceOData.Validate(TenantWebServiceID, TenantWebService.RecordId);
            ODataUtility.GenerateSelectText(ServiceNameLookup, ObjectTypeLookup, SelectText);
            ODataUtility.GenerateODataV3FilterText(ServiceNameLookup, ObjectTypeLookup, ODataV3FilterText);
            ODataUtility.GenerateODataV4FilterText(ServiceNameLookup, ObjectTypeLookup, ODataV4FilterText);
            WebServiceManagement.SetODataSelectClause(TenantWebServiceOData, SelectText);
            WebServiceManagement.SetODataFilterClause(TenantWebServiceOData, ODataV3FilterText);
            WebServiceManagement.SetODataV4FilterClause(TenantWebServiceOData, ODataV4FilterText);
            TenantWebServiceOData.Modify(true);
        end;
    end;

    local procedure GetSourceFilterText(DataItem: Integer; var FilterTextParam: Text)
    var
        TenantWebService: Record "Tenant Web Service";
        TenantWebServiceFilter: Record "Tenant Web Service Filter";
        WebServiceManagement: Codeunit "Web Service Management";
    begin
        TenantWebService.Init();
        TenantWebService.SetRange("Object Type", Rec."Object Type");

        if ActionType = ActionType::"Create a copy of an existing data set" then
            TenantWebService.SetRange("Service Name", ServiceNameLookup)
        else
            TenantWebService.SetRange("Service Name", Rec."Service Name");

        if TenantWebService.FindFirst() then begin
            TenantWebServiceFilter.Init();
            TenantWebServiceFilter.SetRange(TenantWebServiceID, TenantWebService.RecordId);
            TenantWebServiceFilter.SetRange("Data Item", DataItem);
            if TenantWebServiceFilter.FindFirst() then
                FilterTextParam := WebServiceManagement.RetrieveTenantWebServiceFilter(TenantWebServiceFilter);
        end;
    end;

    local procedure ClearTables()
    begin
        CurrPage.ODataColSubForm.PAGE.DeleteColumns();
        TempTenantWebServiceColumns.DeleteAll();
        TempTenantWebServiceFilter.DeleteAll();
    end;

    local procedure ClearObjectType()
    begin
        Rec."Object Type" := Rec."Object Type"::Page;
        ObjectTypeLookup := ObjectTypeLookup::Page;
    end;

    local procedure ClearName()
    begin
        Rec."Service Name" := '';
        ServiceNameEdit := '';
        Clear(ServiceNameLookup);
    end;

    local procedure DisplayObjectName(): Text
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        AllObjWithCaption.SetRange("Object Type", Rec."Object Type");
        AllObjWithCaption.SetRange("Object ID", Rec."Object ID");
        if AllObjWithCaption.FindFirst() then
            exit(AllObjWithCaption."Object Name");
    end;

    local procedure CheckPermissions()
    var
        TenantWebService: Record "Tenant Web Service";
        TenantWebServiceOData: Record "Tenant Web Service OData";
        TenantWebServiceColumns: Record "Tenant Web Service Columns";
        TenantWebServiceFilter: Record "Tenant Web Service Filter";
    begin
        if not TenantWebService.WritePermission then
            Error(PermissionsErr);

        if not TenantWebService.ReadPermission then
            Error(PermissionsErr);

        if not TempTenantWebServiceColumns.WritePermission then
            Error(PermissionsErr);

        if not TenantWebServiceColumns.ReadPermission then
            Error(PermissionsErr);

        if not TenantWebServiceFilter.WritePermission then
            Error(PermissionsErr);

        if not TenantWebServiceFilter.ReadPermission then
            Error(PermissionsErr);

        if not TenantWebServiceOData.WritePermission then
            Error(PermissionsErr);

        if not TenantWebServiceOData.ReadPermission then
            Error(PermissionsErr);
    end;

    procedure EditInExcelVisible()
    begin
        if ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Web then
            ExcelVisible := true;
    end;
}

