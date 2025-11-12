// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

using Microsoft.Utilities;
using System;
using System.Environment;
using System.Environment.Configuration;
using System.Integration;
using System.IO;
using System.Reflection;
using System.Xml;

page 1651 "Curr. Exch. Rate Service Card"
{
    Caption = 'Currency Exch. Rate Service';
    SourceTable = "Curr. Exch. Rate Update Setup";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Suite;
                    Editable = NotEnabledAndCurrPageEditable;
                    ToolTip = 'Specifies the setup of a service to update currency exchange rates.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    Editable = NotEnabledAndCurrPageEditable;
                    ToolTip = 'Specifies the setup of a service to update currency exchange rates.';
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if the currency exchange rate service is enabled.';

                    trigger OnValidate()
                    begin
                        NotEnabledAndCurrPageEditable := not Rec.Enabled and CurrPage.Editable;
                        EnabledAndCurrPageEditable := Rec.Enabled and CurrPage.Editable;
                        CurrPage.Update();
                    end;
                }
                field(ShowEnableWarning; ShowEnableWarning)
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ShowCaption = false;
                    Enabled = EnabledAndCurrPageEditable;

                    trigger OnDrillDown()
                    begin
                        DrilldownCode();
                    end;
                }
            }
            group(Service)
            {
                Caption = 'Service';
                field(ServiceURL; WebServiceURL)
                {
                    ApplicationArea = Suite;
                    Caption = 'Service URL';
                    Editable = NotEnabledAndCurrPageEditable;
                    MultiLine = true;
                    ToolTip = 'Specifies if the currency exchange rate service is enabled.';

                    trigger OnValidate()
                    begin
                        Rec.SetWebServiceURL(WebServiceURL);
                        GenerateXMLStructure();
                    end;
                }
                field("Service Provider"; Rec."Service Provider")
                {
                    ApplicationArea = Suite;
                    Editable = NotEnabledAndCurrPageEditable;
                    ToolTip = 'Specifies the name of the service provider.';
                }
                field("Terms of Service"; Rec."Terms of Service")
                {
                    ApplicationArea = Suite;
                    Editable = NotEnabledAndCurrPageEditable;
                    ToolTip = 'Specifies the URL of the service provider''s terms of service.';
                }
                field("Log Web Requests"; Rec."Log Web Requests")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = NotEnabledAndCurrPageEditable;
                    ToolTip = 'Specifies whether to log exceptions that occur when connecting to the service. The log is located in the server Temp folder.';
                    Visible = not IsSoftwareAsService;
                }
            }
            part(SimpleDataExchSetup; "Data Exch. Setup Subform")
            {
                ApplicationArea = Suite;
                Editable = NotEnabledAndCurrPageEditable;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Preview)
            {
                ApplicationArea = Suite;
                Caption = 'Preview';
                Image = ReviewWorksheet;
                ToolTip = 'Test the setup of the currency exchange rate service to make sure the service is working.';

                trigger OnAction()
                var
                    TempCurrencyExchangeRate: Record "Currency Exchange Rate" temporary;
                    UpdateCurrencyExchangeRates: Codeunit "Update Currency Exchange Rates";
                begin
                    Rec.TestField(Code);
                    Rec.VerifyServiceURL();
                    Rec.VerifyDataExchangeLineDefinition();
                    UpdateCurrencyExchangeRates.GenerateTempDataFromService(TempCurrencyExchangeRate, Rec);
                    PAGE.Run(PAGE::"Currency Exchange Rates", TempCurrencyExchangeRate);
                end;
            }
            action(JobQueueEntry)
            {
                ApplicationArea = Suite;
                Caption = 'Job Queue Entry';
                Enabled = Rec.Enabled;
                Image = JobListSetup;
                ToolTip = 'View or edit the job that updates the exchange rates from the service. For example, you can see the status or change how often rates are updated.';

                trigger OnAction()
                begin
                    Rec.ShowJobQueueEntry();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(Preview_Promoted; Preview)
                {
                }
                actionref(JobQueueEntry_Promoted; JobQueueEntry)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Setup', Comment = 'Generated from the PromotedActionCategories property index 3.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        if not MakeWebServiceURL() then
            exit;

        UpdateSimpleMappingsPart();
        UpdateBasedOnEnable();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        TempField: Record "Field" temporary;
        MapCurrencyExchangeRate: Codeunit "Map Currency Exchange Rate";
    begin
        MapCurrencyExchangeRate.GetSuggestedFields(TempField);
        CurrPage.SimpleDataExchSetup.PAGE.SetSuggestedField(TempField);
        UpdateSimpleMappingsPart();
    end;

    trigger OnOpenPage()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        ApplicationAreaMgmtFacade.CheckAppAreaOnlyBasic();

        UpdateBasedOnEnable();
        IsSoftwareAsService := EnvironmentInfo.IsSaaS();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if not Rec.Enabled then
            if not Confirm(StrSubstNo(EnableServiceQst, CurrPage.Caption), true) then
                exit(false);
    end;

    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        WebServiceURL: Text;
        EnabledWarningTok: Label 'You must disable the service before you can make changes.';
        DisableEnableQst: Label 'Do you want to disable currency exchange rate service?';
        TheXMLStructureCannotBeReadMsg: Label 'The XML structure cannot be read. Try to verify if the service is valid.';
        PreviousWebServiceURL: Text;
        IsSoftwareAsService: Boolean;
        ShowEnableWarning: Text;
        EnableServiceQst: Label 'The %1 is not enabled. Are you sure you want to exit?', Comment = '%1 = This Page Caption (Currency Exch. Rate Service)';
        XmlStructureIsNotSupportedErr: Label ' The provided url does not contain a supported structure.';

    protected var
        NotEnabledAndCurrPageEditable: Boolean;
        EnabledAndCurrPageEditable: Boolean;

    local procedure UpdateSimpleMappingsPart()
    begin
        CurrPage.SimpleDataExchSetup.PAGE.SetDataExchDefCode(Rec."Data Exch. Def Code");
        CurrPage.SimpleDataExchSetup.PAGE.UpdateData();
        CurrPage.SimpleDataExchSetup.PAGE.Update(false);
        CurrPage.SimpleDataExchSetup.PAGE.SetSourceToBeMandatory(Rec."Web Service URL".HasValue);
    end;

    local procedure MakeWebServiceURL() Result: Boolean
    var
        ServiceURL: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMakeWebServiceURL(Rec, Result, IsHandled, WebServiceURL);
        if IsHandled then
            exit(Result);

        WebServiceURL := Rec.GetWebServiceURL(ServiceURL);
        if WebServiceURL <> '' then
            if not GenerateXMLStructure() then begin
                if PreviousWebServiceURL <> ServiceUrl then
                    Message(TheXMLStructureCannotBeReadMsg);
                PreviousWebServiceURL := ServiceURL;
                ClearLastError();
                exit(false);
            end;

        exit(true);
    end;

    [TryFunction]
    local procedure GenerateXMLStructure()
    var
        ServiceURL: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGenerateXMLStructure(Rec, IsHandled);
        if IsHandled then
            exit;

        TempXMLBuffer.Reset();
        TempXMLBuffer.DeleteAll();
        Rec.GetWebServiceURL(ServiceURL);
        if Rec.GetXMLStructure(TempXMLBuffer, ServiceURL) then begin
            TempXMLBuffer.Reset();
            CurrPage.SimpleDataExchSetup.PAGE.SetXMLDefinition(TempXMLBuffer);
        end else
            ShowHttpError();
    end;

    local procedure UpdateBasedOnEnable()
    begin
        NotEnabledAndCurrPageEditable := not Rec.Enabled and CurrPage.Editable;
        EnabledAndCurrPageEditable := Rec.Enabled and CurrPage.Editable;
        ShowEnableWarning := '';
        OnUpdateBasedOnEnableOnBeforeSetShowEnableWarning(Rec);
        if CurrPage.Editable and Rec.Enabled then
            ShowEnableWarning := EnabledWarningTok;
    end;

    local procedure DrilldownCode()
    begin
        if Confirm(DisableEnableQst, true) then begin
            Rec.Enabled := false;
            UpdateBasedOnEnable();
            CurrPage.Update();
        end;
    end;

    local procedure ShowHttpError()
    var
        ActivityLog: Record "Activity Log";
        WebRequestHelper: Codeunit "Web Request Helper";
        XMLDOMMgt: Codeunit "XML DOM Management";
        WebException: DotNet WebException;
        XmlNode: DotNet XmlNode;
        ResponseInputStream: InStream;
        ErrorText: Text;
    begin
        ErrorText := WebRequestHelper.GetWebResponseError(WebException, WebServiceURL);

        ActivityLog.LogActivity(Rec, ActivityLog.Status::Failed, Rec."Service Provider", Rec.Description, ErrorText);

        if IsNull(WebException.Response) then
            Error(ErrorText);

        ResponseInputStream := WebException.Response.GetResponseStream();

        XMLDOMMgt.LoadXMLNodeFromInStream(ResponseInputStream, XmlNode);

        ErrorText := XmlStructureIsNotSupportedErr;

        Error(ErrorText);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMakeWebServiceURL(var CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup"; var Result: Boolean; var IsHandled: Boolean; var WebServiceURL: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenerateXMLStructure(var CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBasedOnEnableOnBeforeSetShowEnableWarning(var CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup")
    begin
    end;
}

