// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Privacy;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Team;
using Microsoft.HumanResources.Employee;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;
using System.Environment;
using System.IO;
using System.Security.AccessControl;
using System.Security.User;
using System.Utilities;

page 1180 "Data Privacy Wizard"
{
    Caption = 'Data Privacy Utility';
    PageType = NavigatePage;
    SourceTable = "Data Privacy Entities";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(TopBanner1)
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
            group(TopBanner2)
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
            group(WelcomePage)
            {
                InstructionalText = '';
                Visible = CurrentPage = 1;
                group("Para1.1")
                {
                    Caption = 'Welcome to Data Privacy Utility';
                    InstructionalText = '';
                    group("Para1.1.1")
                    {
                        Caption = '';
                        InstructionalText = 'You can export data for a person to Excel or to a RapidStart configuration package.';
                        group("Para1.1.1.1")
                        {
                            Caption = '';
                            InstructionalText = 'Up to date information on privacy requests can be found at the link below.';
                            Visible = CurrentPage = 1;
                            field(PrivacyURL; PrivacyURL)
                            {
                                ApplicationArea = Basic, Suite;
                                Editable = false;
                                ExtendedDatatype = URL;
                                Visible = CurrentPage = 1;
                            }
                        }
                    }
                }
                group("Para1.2")
                {
                    Caption = 'Let''s go!';
                    group("Para1.2.1")
                    {
                        Caption = '';
                        InstructionalText = 'Choose Next to start the process.';
                    }
                }
            }
            group(SelectExportOptionPage)
            {
                Caption = '';
                Visible = CurrentPage = 2;
                group("Para2.1")
                {
                    Caption = 'I want to...';
                    field(ActionType; ActionType)
                    {
                        ApplicationArea = Basic, Suite;
                        OptionCaption = 'Export a data subject''s data,Create a data privacy configuration package', Comment = 'Note to translators.  These options must be translated based on being prefixed with "I want to" text.';
                        ShowCaption = false;
                    }
                    field(AvailableOptionsDescription; AvailableOptionsDescription)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        MultiLine = true;
                        ShowCaption = false;
                    }
                }
            }
            group(SelectDataToExportPage)
            {
                Caption = '';
                Visible = CurrentPage = 3;
                group("Para3.1")
                {
                    Caption = 'Specify the data that you want to export.';
                    field(EntityType; EntityType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Data Subject';
                        TableRelation = "Data Privacy Entities"."Table Caption";

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            Rec.Reset();
                            Rec.DeleteAll();
                            if PAGE.RunModal(PAGE::"Data Subject", Rec) = ACTION::LookupOK then begin
                                EntityType := CopyStr(Rec."Table Caption", 1, MaxStrLen(EntityType));
                                EntityTypeTableNo := Rec."Table No.";
                                if EntityType <> EntityTypeGlobal then
                                    EntityNo := '';
                                EntityTypeGlobal := EntityType;
                            end;
                        end;
                    }
                    field(EntityTypeTableNo; EntityTypeTableNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Visible = false;
                    }
                    field(EntityNo; EntityNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Data Subject Identifier';

                        trigger OnDrillDown()
                        var
                            Customer: Record Customer;
                            Vendor: Record Vendor;
                            Contact: Record Contact;
                            Resource: Record Resource;
                            Employee: Record Employee;
                            SalespersonPurchaser: Record "Salesperson/Purchaser";
                            TempDataPrivacyEntities: Record "Data Privacy Entities" temporary;
                            User: Record User;
                            DataClassificationMgt: Codeunit "Data Classification Mgt.";
                            CustomerList: Page "Customer List";
                            VendorList: Page "Vendor List";
                            ContactList: Page "Contact List";
                            ResourceList: Page "Resource List";
                            EmployeeList: Page "Employee List";
                            SalespersonsPurchasers: Page "Salespersons/Purchasers";
                            Users: Page Users;
                            Instream: InStream;
                            FilterAsText: Text;
                        begin
                            DataClassificationMgt.RaiseOnGetDataPrivacyEntities(TempDataPrivacyEntities);
                            if EntityTypeTableNo = DATABASE::Customer then begin
                                if TempDataPrivacyEntities.Get(DATABASE::Customer) then begin
                                    TempDataPrivacyEntities.CalcFields("Entity Filter");
                                    TempDataPrivacyEntities."Entity Filter".CreateInStream(Instream);
                                    Instream.ReadText(FilterAsText);
                                end;
                                CustomerList.LookupMode := true;
                                Customer.SetView(FilterAsText);
                                CustomerList.SetTableView(Customer);
                                if CustomerList.RunModal() = ACTION::LookupOK then begin
                                    CustomerList.GetRecord(Customer);
                                    if Customer."Privacy Blocked" then
                                        Message(DataSubjectBlockedMsg);
                                    EntityNo := Customer."No.";
                                end;
                            end else
                                if EntityTypeTableNo = DATABASE::Vendor then begin
                                    if TempDataPrivacyEntities.Get(DATABASE::Vendor) then begin
                                        TempDataPrivacyEntities.CalcFields("Entity Filter");
                                        TempDataPrivacyEntities."Entity Filter".CreateInStream(Instream);
                                        Instream.ReadText(FilterAsText);
                                    end;
                                    VendorList.LookupMode := true;
                                    Vendor.SetView(FilterAsText);
                                    VendorList.SetTableView(Vendor);
                                    if VendorList.RunModal() = ACTION::LookupOK then begin
                                        VendorList.GetRecord(Vendor);
                                        if Vendor."Privacy Blocked" then
                                            Message(DataSubjectBlockedMsg);
                                        EntityNo := Vendor."No.";
                                    end;
                                end else
                                    if EntityTypeTableNo = DATABASE::Contact then begin
                                        if TempDataPrivacyEntities.Get(DATABASE::Contact) then begin
                                            TempDataPrivacyEntities.CalcFields("Entity Filter");
                                            TempDataPrivacyEntities."Entity Filter".CreateInStream(Instream);
                                            Instream.ReadText(FilterAsText);
                                        end;
                                        ContactList.LookupMode := true;
                                        Contact.SetView(FilterAsText);
                                        ContactList.SetTableView(Contact);
                                        if ContactList.RunModal() = ACTION::LookupOK then begin
                                            ContactList.GetRecord(Contact);
                                            if Contact."Privacy Blocked" then
                                                Message(DataSubjectBlockedMsg);
                                            EntityNo := Contact."No.";
                                        end;
                                    end else
                                        if EntityTypeTableNo = DATABASE::Resource then begin
                                            if TempDataPrivacyEntities.Get(DATABASE::Resource) then begin
                                                TempDataPrivacyEntities.CalcFields("Entity Filter");
                                                TempDataPrivacyEntities."Entity Filter".CreateInStream(Instream);
                                                Instream.ReadText(FilterAsText);
                                            end;
                                            ResourceList.LookupMode := true;
                                            Resource.SetView(FilterAsText);
                                            ResourceList.SetTableView(Resource);
                                            if ResourceList.RunModal() = ACTION::LookupOK then begin
                                                ResourceList.GetRecord(Resource);
                                                if Resource."Privacy Blocked" then
                                                    Message(DataSubjectBlockedMsg);
                                                EntityNo := Resource."No.";
                                            end;
                                        end else
                                            if EntityTypeTableNo = DATABASE::Employee then begin
                                                EmployeeList.LookupMode := true;
                                                if EmployeeList.RunModal() = ACTION::LookupOK then begin
                                                    EmployeeList.GetRecord(Employee);
                                                    if Employee."Privacy Blocked" then
                                                        Message(DataSubjectBlockedMsg);
                                                    EntityNo := Employee."No.";
                                                end;
                                            end else
                                                if EntityTypeTableNo = DATABASE::"Salesperson/Purchaser" then begin
                                                    SalespersonsPurchasers.LookupMode := true;
                                                    if SalespersonsPurchasers.RunModal() = ACTION::LookupOK then begin
                                                        SalespersonsPurchasers.GetRecord(SalespersonPurchaser);
                                                        if SalespersonPurchaser."Privacy Blocked" then
                                                            Message(DataSubjectBlockedMsg);
                                                        EntityNo := SalespersonPurchaser.Code;
                                                    end;
                                                end else
                                                    if EntityTypeTableNo = DATABASE::User then begin
                                                        Users.LookupMode := true;
                                                        if Users.RunModal() = ACTION::LookupOK then begin
                                                            Users.GetRecord(User);
                                                            EntityNo := User."User Name";
                                                        end;
                                                    end;

                            OnDrillDownForEntityNumber(EntityTypeTableNo, EntityNo); // Integration point to external devs

                            NextActionEnabled := EntityNo <> '';
                            PreviewActionEnabled := EntityNo <> '';
                        end;

                        trigger OnValidate()
                        var
                            TempDataPrivacyEntities: Record "Data Privacy Entities" temporary;
                            DataClassificationMgt: Codeunit "Data Classification Mgt.";
                            RecRef: RecordRef;
                        begin
                            if EntityNo <> '' then begin
                                DataClassificationMgt.RaiseOnGetDataPrivacyEntities(TempDataPrivacyEntities);

                                if EntityTypeTableNo in [DATABASE::Customer, DATABASE::Vendor] then begin
                                    RecRef.Open(EntityTypeTableNo);

                                    EnsureEntityExists(TempDataPrivacyEntities, RecRef, EntityNo);
                                    EnsurePartnerPersonExists(TempDataPrivacyEntities, RecRef, NoPartnerPeopleErr, EntityNo);
                                    EnsureEntityIsNotPrivacyBlocked(TempDataPrivacyEntities, RecRef);

                                    RecRef.Close();
                                end else
                                    if EntityTypeTableNo in [DATABASE::Contact, DATABASE::Resource] then begin
                                        RecRef.Open(EntityTypeTableNo);

                                        EnsureEntityExists(TempDataPrivacyEntities, RecRef, EntityNo);
                                        EnsurePartnerPersonExists(TempDataPrivacyEntities, RecRef, NoPersonErr, EntityNo);
                                        EnsureEntityIsNotPrivacyBlocked(TempDataPrivacyEntities, RecRef);

                                        RecRef.Close();
                                    end else
                                        if EntityTypeTableNo in [DATABASE::Employee, DATABASE::"Salesperson/Purchaser"] then begin
                                            RecRef.Open(EntityTypeTableNo);

                                            EnsureEntityExists(TempDataPrivacyEntities, RecRef, EntityNo);
                                            EnsureEntityIsNotPrivacyBlocked(TempDataPrivacyEntities, RecRef);

                                            RecRef.Close();
                                        end else
                                            if EntityTypeTableNo = DATABASE::User then begin
                                                RecRef.Open(EntityTypeTableNo);

                                                EnsureEntityExists(TempDataPrivacyEntities, RecRef, EntityNo);

                                                RecRef.Close();
                                            end;
                            end;

                            OnEntityNoValidate(EntityTypeTableNo, EntityNo); // Integration point to external devs

                            NextActionEnabled := EntityNo <> '';
                            PreviewActionEnabled := EntityNo <> '';
                        end;
                    }
                    field(DataSensitivity; DataSensitivity)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Data Sensitivity';
                    }
                }
                group("Para3.05")
                {
                    Caption = '';
                    InstructionalText = 'Choose to generate and preview the data that will be exported. Note that this can take a while, depending on the size of the dataset.';
                    Visible = (CurrentPage = 3) and (ActionType < 1);
                }
                group("Para3.2")
                {
                    Caption = '';
                    InstructionalText = 'Choose Next to export the data.';
                    Visible = (CurrentPage = 3) and (ActionType = 0);
                }
                group("Para3.4")
                {
                    Caption = '';
                    InstructionalText = 'Choose Next to create the configuration package';
                    Visible = ActionType = 1;
                }
            }
            group(PreviewDataPage)
            {
                Caption = '';
                Visible = CurrentPage = 4;
                group("Para4.1")
                {
                    Caption = 'Preview the data that will be exported';
                    part(DataPrivacySubPage; "Data Privacy ListPage")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = ' ';
                    }
                }
                group("Para4.2")
                {
                    Caption = '';
                    InstructionalText = 'Choose Next to export the data.';
                    Visible = (CurrentPage = 4) and (ActionType = 0);
                }
            }
            group(SuccessPage)
            {
                Caption = '<Step5>';
                InstructionalText = '';
                Visible = CurrentPage = 5;
                group("Para5.1")
                {
                    Caption = 'Success!';
                    InstructionalText = '';
                    group("Para5.1.1")
                    {
                        Caption = '';
                        InstructionalText = 'The data is being exported. The Excel workbook will show up in the Report Inbox on your home page.';
                        Visible = (CurrentPage = 5) and (ActionType = 0);
                        group("Para5.1.1.1")
                        {
                            Caption = '';
                            InstructionalText = 'We recommend that you verify the data that is exported to Excel. Please also verify the filters in the configuration package to make sure that you are getting the data that you want.';
                            Visible = (CurrentPage = 5) and (ActionType = 0);
                        }
                    }
                    group("Para5.1.3")
                    {
                        Caption = '';
                        InstructionalText = 'Your configuration package has been successfully created.';
                        Visible = (CurrentPage = 5) and (ActionType = 1);
                        field(EditConfigPackage; EditConfigPackage)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Edit Configuration Package';
                        }
                        group("Para5.1.4.1")
                        {
                            Caption = '';
                            InstructionalText = 'Please verify the filters in the configuration package to make sure that you will get the data that you want.';
                            Visible = (CurrentPage = 5) and (ActionType = 1);
                        }
                    }
                }
            }
            group(FinishPage)
            {
                Caption = '<Step5>';
                InstructionalText = '';
                Visible = CurrentPage = 6;
                group("Para6.1")
                {
                    Caption = 'Process finished.';
                    InstructionalText = '';
                    group("Para6.1.1")
                    {
                        Caption = '';
                        InstructionalText = 'No data was found that could be generated, so no export file was created.';
                        Visible = (CurrentPage = 6) and (ActionType = 0);
                    }
                    group("Para6.1.2")
                    {
                        Caption = '';
                        InstructionalText = 'No data was found that could be generated, so no configuration package was created.';
                        Visible = (CurrentPage = 6) and (ActionType = 1);
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(PreviewData)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Generate and Preview Data';
                Enabled = PreviewActionEnabled;
                InFooterBar = true;
                Visible = CurrentPage = 3;

                trigger OnAction()
                begin
                    CurrPage.Update();
                    DataPrivacyMgmt.CreateData(EntityTypeTableNo, EntityNo, PackageCode, ActionType, DataSensitivity);
                    CurrPage.DataPrivacySubPage.PAGE.GeneratePreviewData(PackageCode);
                    CurrentPage := CurrentPage + 1;
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
                var
                    PreviousPage: Integer;
                begin
                    PreviousPage := CurrentPage;
                    CurrentPage := CurrentPage - 1;

                    NextActionEnabled := true;
                    PreviewActionEnabled := true;
                    if CurrentPage = 3 then begin
                        if PreviousPage = 4 then // Don't clear the entity number if coming back from the preview page
                            exit;
                        if PackageCode <> '' then
                            if StrPos(PackageCode, '*') > 0 then
                                DataPrivacyMgmt.DeletePackage(PackageCode);
                        NextActionEnabled := false;
                        PreviewActionEnabled := false;
                    end;

                    CurrPage.Update();
                end;
            }
            action(NextAction)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Next';
                Enabled = NextActionEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                var
                    ActivityLog: Record "Activity Log";
                    Company: Record Company;
                    ConfigPackageTable: Record "Config. Package Table";
                    ConfigPackage: Record "Config. Package";
                    SessionId: Integer;
                    IsHandled: Boolean;
                begin
                    NextActionEnabled := true;
                    PreviewActionEnabled := true;

                    CurrentPage := CurrentPage + 1;

                    if CurrentPage = 3 then begin
                        EntityNo := '';
                        NextActionEnabled := false;
                        PreviewActionEnabled := false;
                    end;

                    if CurrentPage = 4 then begin
                        DataPrivacyMgmt.CreateData(EntityTypeTableNo, EntityNo, PackageCode, ActionType, DataSensitivity);
                        if ActionType = ActionType::"Create a data privacy configuration package" then
                            if ConfigPackage.Get(PackageCode) then begin
                                Company.Get(CompanyName);
                                NextActionEnabled := false;
                                PreviewActionEnabled := false;
                                EditConfigPackage := true;
                                CurrentPage := 5; // Move to the end
                                ActivityLog.LogActivity(
                                  Company.RecordId, ActivityLog.Status::Success, ActivityContextTxt, ActivityDescriptionConfigTxt,
                                  StrSubstNo(ActivityMessageConfigTxt, EntityType, EntityNo));
                            end else begin // No data generated, so no config package created.
                                CurrentPage := 6; // Move to the end
                                ActivityLog.LogActivity(
                                  Company.RecordId, ActivityLog.Status::Failed, ActivityContextTxt, ActivityDescriptionConfigTxt,
                                  StrSubstNo(ActivityMessageConfigTxt, EntityType, EntityNo));
                                NextActionEnabled := false;
                                PreviewActionEnabled := false;
                                EditConfigPackage := false;
                                exit;
                            end;
                        CurrentPage := 5;
                    end;

                    if CurrentPage = 5 then begin
                        NextActionEnabled := false;
                        PreviewActionEnabled := false;

                        Company.Get(CompanyName);
                        if ActionType = ActionType::"Export a data subject's data" then
                            if ConfigPackage.Get(PackageCode) then begin
                                DataPrivacyMgmt.SetPrivacyBlocked(EntityTypeTableNo, EntityNo);
                                ConfigPackageTable.SetRange("Package Code", PackageCode);
                                IsHandled := false;
                                OnNextActionOnBeforeStartSession(IsHandled, ConfigPackageTable, SessionId, DataSensitivity, EntityType, EntityNo);
                                if not IsHandled then
                                    if StartSession(SessionId, CODEUNIT::"Prvacy Data Mgmt Excel", CompanyName, ConfigPackageTable) then
                                        ActivityLog.LogActivity(
                                          Company.RecordId, ActivityLog.Status::Success, ActivityContextTxt, ActivityDescriptionExportTxt,
                                          StrSubstNo(ActivityMessageExportTxt, LowerCase(Format(DataSensitivity)), EntityType, EntityNo))
                                    else
                                        ActivityLog.LogActivity(
                                          Company.RecordId, ActivityLog.Status::Failed, ActivityContextTxt, ActivityDescriptionExportTxt,
                                          StrSubstNo(ActivityMessageExportTxt, LowerCase(Format(DataSensitivity)), EntityType, EntityNo));
                            end else begin // No data generated, so no config package created.
                                CurrentPage := 6; // Move to the end
                                ActivityLog.LogActivity(
                                  Company.RecordId, ActivityLog.Status::Failed, ActivityContextTxt, ActivityDescriptionExportTxt,
                                  StrSubstNo(ActivityMessageExportTxt, LowerCase(Format(DataSensitivity)), EntityType, EntityNo));
                            end;
                        NextActionEnabled := false;
                        PreviewActionEnabled := false;
                    end;

                    CurrPage.Update(false);
                end;
            }
            action(FinishAction)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Finish';
                Enabled = CurrentPage >= 5;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                var
                    ConfigPackage: Record "Config. Package";
                    ConfigPackages: Page "Config. Packages";
                begin
                    if EditConfigPackage and (ActionType = ActionType::"Create a data privacy configuration package") then begin
                        ConfigPackage.FilterGroup(2);
                        ConfigPackage.SetFilter(Code, PackageCode);
                        ConfigPackage.FilterGroup(0);

                        ConfigPackages.SetTableView(ConfigPackage);
                        ConfigPackages.Editable := true;
                        ConfigPackages.Run();
                    end;
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnInit()
    begin
        LoadTopBanners();
        CurrentPage := 1;
        PrivacyURL := PrivacyUrlTxt;
    end;

    trigger OnOpenPage()
    var
        TempDataPrivacyEntities: Record "Data Privacy Entities" temporary;
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
    begin
        EnableControls();
        DataClassificationMgt.RaiseOnGetDataPrivacyEntities(TempDataPrivacyEntities);
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        ClientTypeManagement: Codeunit "Client Type Management";
        DataPrivacyMgmt: Codeunit "Data Privacy Mgmt";
        CurrentPage: Integer;
        TopBannerVisible: Boolean;
        ActionType: Option "Export a data subject's data","Create a data privacy configuration package";
        EntityType: Text[80];
        EntityTypeTableNo: Integer;
        EntityNo: Code[50];
        DataSensitivity: Option Sensitive,Personal,"Company Confidential",Normal,Unclassified;
        EntityTypeGlobal: Text[80];
        NextActionEnabled: Boolean;
        ActivityContextTxt: Label 'Privacy Activity';
        ActivityMessageExportTxt: Label 'Exporting %1 information for %2 %3', Comment = '%1=The type of information being exported. %2=The type of entity. %3=The entity''s control number.';
        ActivityDescriptionExportTxt: Label 'Exporting data subject data';
        PreviewActionEnabled: Boolean;
        PackageCode: Code[20];
        ActivityMessageConfigTxt: Label 'Creating data privacy configuration package for %1 %2', Comment = '%1=The type of entity. %2=The entity''s control number.';
        ActivityDescriptionConfigTxt: Label 'Creating the data privacy configuration package';
        EditConfigPackage: Boolean;
        OptionsDescriptionTxt: Label '\Choose what you want to do with the privacy data.\\You can export data for a specific data subject, such as a customer.\You can also create a configuration package so that you can view and edit the fields and tables that the data will be exported from.';
        AvailableOptionsDescription: Text;
        PrivacyURL: Text;
        PrivacyUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2206516', Locked = true;
        DataSubjectBlockedMsg: Label 'This data subject is already marked as blocked due to privacy. You can export the related data.';
        NoPartnerPeopleErr: Label 'No records of Partner Type of ''Person'' were found.';
        NoPersonErr: Label 'No records of type ''Person'' were found.';
        RecordNotFoundErr: Label 'Record not found.';

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

    local procedure ResetControls()
    begin
        NextActionEnabled := true;
        PreviewActionEnabled := true;
        EditConfigPackage := true;
    end;

    local procedure EnableControls()
    begin
        ResetControls();
        AvailableOptionsDescription := OptionsDescriptionTxt;
    end;

    [Scope('OnPrem')]
    procedure SetEntitityType(var DataPrivacyEntities: Record "Data Privacy Entities"; EntityTypeText: Text[80])
    begin
        EntityType := EntityTypeText;

        DataPrivacyEntities.SetRange("Table Caption", EntityTypeText);
        if DataPrivacyEntities.FindFirst() then
            EntityTypeTableNo := DataPrivacyEntities."Table No.";
        Clear(DataPrivacyEntities);
    end;

    local procedure EnsureEntityExists(var TempDataPrivacyEntities: Record "Data Privacy Entities" temporary; var RecRef: RecordRef; EntityNo: Code[50])
    begin
        if TempDataPrivacyEntities.Get(RecRef.Number) then begin
            RecRefFilter(RecRef, TempDataPrivacyEntities."Key Field No.", Format(EntityNo, 20));
            if not RecRef.FindFirst() then
                Error(RecordNotFoundErr);
        end;
    end;

    local procedure EnsurePartnerPersonExists(var TempDataPrivacyEntities: Record "Data Privacy Entities" temporary; var RecRef: RecordRef; ErrorMessage: Text; EntityNo: Code[50])
    var
        FilterAsText: Text;
    begin
        if TempDataPrivacyEntities.Get(RecRef.Number) then begin
            SetEntityFilter(TempDataPrivacyEntities, RecRef.Number, FilterAsText);
            RecRef.SetView(FilterAsText);
            RecRefFilter(RecRef, TempDataPrivacyEntities."Key Field No.", Format(EntityNo, 20));
            if not RecRef.FindFirst() then
                Error(ErrorMessage);
        end;
    end;

    local procedure SetEntityFilter(var TempDataPrivacyEntities: Record "Data Privacy Entities" temporary; TableId: Integer; var FilterAsText: Text)
    var
        Instream: InStream;
    begin
        if TempDataPrivacyEntities.Get(TableId) then begin
            TempDataPrivacyEntities.CalcFields("Entity Filter");
            TempDataPrivacyEntities."Entity Filter".CreateInStream(Instream);
            Instream.ReadText(FilterAsText);
        end;
    end;

    local procedure EnsureEntityIsNotPrivacyBlocked(var TempDataPrivacyEntities: Record "Data Privacy Entities" temporary; var RecRef: RecordRef)
    var
        FieldRef: FieldRef;
    begin
        if TempDataPrivacyEntities.Get(RecRef.Number) then begin
            FieldRef := RecRef.Field(TempDataPrivacyEntities."Privacy Blocked Field No.");
            if Format(FieldRef) = Format(true) then
                Message(DataSubjectBlockedMsg);
        end;
    end;

    local procedure RecRefFilter(var RecRef: RecordRef; FieldNo: Integer; "Filter": Text)
    var
        FieldRef: FieldRef;
    begin
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.SetRange(Filter);
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    internal procedure OnDrillDownForEntityNumber(EntityTypeTableNo: Integer; var EntityNo: Code[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    internal procedure OnEntityNoValidate(EntityTypeTableNo: Integer; var EntityNo: Code[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNextActionOnBeforeStartSession(var IsHandled: Boolean; var ConfigPackageTable: Record "Config. Package Table"; var SessionId: Integer; var DataSensitivity: Option Sensitive,Personal,"Company Confidential",Normal,Unclassified; var EntityType: Text[80]; var EntityNo: Code[50])
    begin
    end;
}

