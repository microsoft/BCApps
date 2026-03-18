// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
codeunit 1642 "Intelligent Info Manifest"
{

    trigger OnRun()
    begin
    end;

    var
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
        EnvironmentInfo: Codeunit "Environment Information";

        OpenPaneButtonTxt: Label 'Contact Insights', Comment = 'Shows more information about the contact';
        OpenPaneButtonTooltipTxt: Label 'Opens a more detailed view of the contact in %1.', Comment = '%1 = Application name';
        OpenPaneSuperTipTxt: Label 'Open %1 in Outlook', Comment = '%1 = Application name';
        OpenPaneSuperTipDescriptionTxt: Label 'Opens a more detailed view of the customer or vendor in %1.', Comment = '%1 = Application name';
        NewMenuButtonTxt: Label 'New';
        NewMenuButtonTooltipTxt: Label 'Creates a new document in %1.', Comment = '%1 = Application name';
        NewMenuSuperTipTxt: Label 'Create a new document in %1', Comment = '%1 = Application name';
        NewMenuSuperTipDescriptionTxt: Label 'Creates a new document for the selected customer or vendor in %1.', Comment = '%1 = Application name';
        NewDocButtonTooltipTxt: Label 'Creates a new %1 in %2.', Comment = '%1 = document type (sales quote, purchase credit memo, etc.); %2 = Application name';
        NewDocSuperTipTxt: Label 'Create new %1', Comment = '%1 = document type (sales quote, purchase credit memo, etc.)';
        NewDocSuperTipDescTxt: Label 'Creates a new %1 for this contact in %2.', Comment = '%1 = document type (sales quote, purchase credit memo, etc.); %2 = Application name';
        AddinNameTxt: Label 'Contact Insights';
        AddinDescriptionTxt: Label 'Provides customer and vendor information directly within Outlook messages.';
        AppIdTxt: Label 'cfca30bd-9846-4819-a6fc-56c89c5aae96', Locked = true;
        BrandingFolderTxt: Label 'ProjectMadeira/', Locked = true;

    local procedure GetManifestVersion(): Text
    begin
        exit('2.0.0.0');
    end;

    local procedure SetupUrl(var ManifestText: Text)
    var
        OfficeHostType: DotNet OfficeHostType;
        AddinURL: Text;
    begin
        AddinURL := AddinManifestManagement.ConstructURL(OfficeHostType.OutlookItemRead, '', GetManifestVersion());
        AddinManifestManagement.SetSourceLocationNodes(ManifestText, AddinURL, 0);

        AddinURL := AddinManifestManagement.ConstructURL(OfficeHostType.OutlookItemEdit, '', GetManifestVersion());
        AddinManifestManagement.SetSourceLocationNodes(ManifestText, AddinURL, 1);
    end;

    local procedure SetupResourceImages(var ManifestText: Text)
    begin
        if EnvironmentInfo.IsSaaS() then begin
            AddinManifestManagement.SetNodeResource(ManifestText, 'nav-icon-16', BrandingFolderTxt + 'OfficeAddin_16x.png', 0);
            AddinManifestManagement.SetNodeResource(ManifestText, 'nav-icon-32', BrandingFolderTxt + 'OfficeAddin_32x.png', 0);
            AddinManifestManagement.SetNodeResource(ManifestText, 'nav-icon-80', BrandingFolderTxt + 'OfficeAddin_80x.png', 0);
        end else begin
            AddinManifestManagement.SetNodeResource(ManifestText, 'nav-icon-16', 'OfficeAddin_16x.png', 0);
            AddinManifestManagement.SetNodeResource(ManifestText, 'nav-icon-32', 'OfficeAddin_32x.png', 0);
            AddinManifestManagement.SetNodeResource(ManifestText, 'nav-icon-80', 'OfficeAddin_80x.png', 0);
        end;
        AddinManifestManagement.SetNodeResource(ManifestText, 'new-document-16', 'NewDocument_16x16.png', 0);
        AddinManifestManagement.SetNodeResource(ManifestText, 'new-document-32', 'NewDocument_32x32.png', 0);
        AddinManifestManagement.SetNodeResource(ManifestText, 'new-document-80', 'NewDocument_80x80.png', 0);

        AddinManifestManagement.SetNodeResource(ManifestText, 'quote-16', 'Quote_16x16.png', 0);
        AddinManifestManagement.SetNodeResource(ManifestText, 'quote-32', 'Quote_32x32.png', 0);
        AddinManifestManagement.SetNodeResource(ManifestText, 'quote-80', 'Quote_80x80.png', 0);

        AddinManifestManagement.SetNodeResource(ManifestText, 'order-16', 'Order_16x16.png', 0);
        AddinManifestManagement.SetNodeResource(ManifestText, 'order-32', 'Order_32x32.png', 0);
        AddinManifestManagement.SetNodeResource(ManifestText, 'order-80', 'Order_80x80.png', 0);

        AddinManifestManagement.SetNodeResource(ManifestText, 'sales-invoice-16', 'SalesInvoice_16.png', 0);
        AddinManifestManagement.SetNodeResource(ManifestText, 'sales-invoice-32', 'SalesInvoice_32.png', 0);
        AddinManifestManagement.SetNodeResource(ManifestText, 'sales-invoice-80', 'SalesInvoice_80.png', 0);

        AddinManifestManagement.SetNodeResource(ManifestText, 'sales-credit-memo-16', 'SalesCreditMemo_16.png', 0);
        AddinManifestManagement.SetNodeResource(ManifestText, 'sales-credit-memo-32', 'SalesCreditMemo_32.png', 0);
        AddinManifestManagement.SetNodeResource(ManifestText, 'sales-credit-memo-80', 'SalesCreditMemo_80.png', 0);

        AddinManifestManagement.SetNodeResource(ManifestText, 'purchase-invoice-16', 'PurchaseInvoice_16.png', 0);
        AddinManifestManagement.SetNodeResource(ManifestText, 'purchase-invoice-32', 'PurchaseInvoice_32.png', 0);
        AddinManifestManagement.SetNodeResource(ManifestText, 'purchase-invoice-80', 'PurchaseInvoice_80.png', 0);

        AddinManifestManagement.SetNodeResource(ManifestText, 'purchase-credit-memo-16', 'PurchaseCreditMemo_16.png', 0);
        AddinManifestManagement.SetNodeResource(ManifestText, 'purchase-credit-memo-32', 'PurchaseCreditMemo_32.png', 0);
        AddinManifestManagement.SetNodeResource(ManifestText, 'purchase-credit-memo-80', 'PurchaseCreditMemo_80.png', 0);
    end;

    local procedure SetupResourceUrls(var ManifestText: Text)
    var
        Command: DotNet OutlookCommand;
        OfficeHostType: DotNet OfficeHostType;
        Url: Text;
    begin
        Url := AddinManifestManagement.ConstructURL(OfficeHostType.OutlookTaskPane, '', GetManifestVersion());
        AddinManifestManagement.SetNodeResource(ManifestText, 'taskPaneUrl', Url, 1);

        Url := AddinManifestManagement.ConstructURL(OfficeHostType.OutlookTaskPane, Command.NewSalesQuote, GetManifestVersion());
        AddinManifestManagement.SetNodeResource(ManifestText, 'newSalesQuoteUrl', Url, 1);

        Url := AddinManifestManagement.ConstructURL(OfficeHostType.OutlookTaskPane, Command.NewSalesOrder, GetManifestVersion());
        AddinManifestManagement.SetNodeResource(ManifestText, 'newSalesOrderUrl', Url, 1);

        Url := AddinManifestManagement.ConstructURL(OfficeHostType.OutlookTaskPane, Command.NewSalesInvoice, GetManifestVersion());
        AddinManifestManagement.SetNodeResource(ManifestText, 'newSalesInvoiceUrl', Url, 1);

        Url := AddinManifestManagement.ConstructURL(OfficeHostType.OutlookTaskPane, Command.NewSalesCreditMemo, GetManifestVersion());
        AddinManifestManagement.SetNodeResource(ManifestText, 'newSalesCreditMemoUrl', Url, 1);

        Url := AddinManifestManagement.ConstructURL(OfficeHostType.OutlookTaskPane, Command.NewPurchaseInvoice, GetManifestVersion());
        AddinManifestManagement.SetNodeResource(ManifestText, 'newPurchaseInvoiceUrl', Url, 1);

        Url := AddinManifestManagement.ConstructURL(OfficeHostType.OutlookTaskPane, Command.NewPurchaseCreditMemo, GetManifestVersion());
        AddinManifestManagement.SetNodeResource(ManifestText, 'newPurchaseCrMemoUrl', Url, 1);

        Url := AddinManifestManagement.ConstructURL(OfficeHostType.OutlookTaskPane, Command.NewPurchaseOrder, GetManifestVersion());
        AddinManifestManagement.SetNodeResource(ManifestText, 'newPurchaseOrderUrl', Url, 1);
    end;

    local procedure SetupResourceStrings(var ManifestText: Text)
    var
        TypeIndex: Integer;
    begin
        AddinManifestManagement.SetNodeResource(ManifestText, 'groupLabel', PRODUCTNAME.Short(), 2);
        AddinManifestManagement.SetNodeResource(ManifestText, 'groupTooltip', PRODUCTNAME.Full(), 3);
        AddinManifestManagement.SetNodeResource(ManifestText, 'openPaneButtonLabel', OpenPaneButtonTxt, 2);
        AddinManifestManagement.SetNodeResource(ManifestText, 'openPaneSuperTipTitle', StrSubstNo(OpenPaneSuperTipTxt, PRODUCTNAME.Short()), 2);
        AddinManifestManagement.SetNodeResource(ManifestText, 'openPaneButtonTooltip', StrSubstNo(OpenPaneButtonTooltipTxt, PRODUCTNAME.Full()), 3);
        AddinManifestManagement.SetNodeResource(ManifestText, 'openPaneSuperTipDesc', StrSubstNo(OpenPaneSuperTipDescriptionTxt, PRODUCTNAME.Full()), 3);

        AddinManifestManagement.SetNodeResource(ManifestText, 'newMenuButtonLabel', NewMenuButtonTxt, 2);
        AddinManifestManagement.SetNodeResource(ManifestText, 'newMenuSuperTipTitle', StrSubstNo(NewMenuSuperTipTxt, PRODUCTNAME.Short()), 2);
        AddinManifestManagement.SetNodeResource(ManifestText, 'newMenuButtonTooltip', StrSubstNo(NewMenuButtonTooltipTxt, PRODUCTNAME.Full()), 3);
        AddinManifestManagement.SetNodeResource(ManifestText, 'newMenuSuperTipDesc', StrSubstNo(NewMenuSuperTipDescriptionTxt, PRODUCTNAME.Full()), 3);

        for TypeIndex := 0 to 6 do begin
            AddinManifestManagement.SetNodeResource(ManifestText, ResourceId('new%1Label', TypeIndex), GetDocType(TypeIndex), 2);
            AddinManifestManagement.SetNodeResource(ManifestText, ResourceId('new%1SuperTipTitle', TypeIndex), ResourceValue(NewDocSuperTipTxt, TypeIndex), 2);
            AddinManifestManagement.SetNodeResource(ManifestText, ResourceId('new%1Tip', TypeIndex), ResourceValue(NewDocButtonTooltipTxt, TypeIndex), 3);
            AddinManifestManagement.SetNodeResource(ManifestText, ResourceId('new%1SuperTipDesc', TypeIndex), ResourceValue(NewDocSuperTipDescTxt, TypeIndex), 3);
        end;
    end;

    local procedure GetDocType(TypeIndex: Integer) DocType: Text
    var
        HyperlinkManifest: Codeunit "Hyperlink Manifest";
    begin
        case TypeIndex of
            0:
                DocType := HyperlinkManifest.GetNameForSalesQuote();
            1:
                DocType := HyperlinkManifest.GetNameForSalesOrder();
            2:
                DocType := HyperlinkManifest.GetNameForSalesInvoice();
            3:
                DocType := HyperlinkManifest.GetNameForSalesCrMemo();
            4:
                DocType := HyperlinkManifest.GetNameForPurchaseInvoice();
            5:
                DocType := HyperlinkManifest.GetNameForPurchaseCrMemo();
            6:
                DocType := HyperlinkManifest.GetNameForPurchaseOrder();
        end;
    end;

    local procedure ResourceId(BaseText: Text; TypeIndex: Integer) ResourceId: Text[32]
    var
        DocType: Text;
    begin
        case TypeIndex of
            0:
                DocType := 'SalesQuote';
            1:
                DocType := 'SalesOrder';
            2:
                DocType := 'SalesInvoice';
            3:
                DocType := 'SalesCreditMemo';
            4:
                DocType := 'PurchaseInvoice';
            5:
                DocType := 'PurchaseCrMemo';
            6:
                DocType := 'PurchaseOrder';
        end;

        ResourceId := CopyStr(StrSubstNo(BaseText, DocType), 1, 32);
    end;

    local procedure ResourceValue(BaseText: Text; TypeIndex: Integer) ResourceValue: Text
    var
        DocType: Text;
    begin
        DocType := GetDocType(TypeIndex);
        ResourceValue := StrSubstNo(BaseText, LowerCase(DocType), PRODUCTNAME.Short());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Add-in Manifest Management", 'CreateDefaultAddins', '', false, false)]
    local procedure OnCreateAddin(var OfficeAddin: Record "Office Add-in")
    begin
        if OfficeAddin.Get(AppIdTxt) then
            OfficeAddin.Delete();

        AddinManifestManagement.CreateAddin(OfficeAddin, DefaultManifestText(), AddinNameTxt, AddinDescriptionTxt, AppIdTxt, CODEUNIT::"Intelligent Info Manifest");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Add-in Manifest Management", 'OnGenerateManifest', '', false, false)]
    local procedure OnGenerateManifest(var OfficeAddin: Record "Office Add-in"; var ManifestText: Text; CodeunitID: Integer)
    begin
        if not CanHandle(CodeunitID) then
            exit;

        ManifestText := OfficeAddin.GetDefaultManifestText();
        AddinManifestManagement.SetCommonManifestItems(ManifestText);
        SetupUrl(ManifestText);
        SetupResourceImages(ManifestText);
        SetupResourceUrls(ManifestText);
        SetupResourceStrings(ManifestText);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Add-in Manifest Management", 'GetAddin', '', false, false)]
    local procedure OnGetAddin(var OfficeAddin: Record "Office Add-in"; CodeunitID: Integer)
    begin
        if CodeunitID = CODEUNIT::"Intelligent Info Manifest" then
            OfficeAddin.Get(AppIdTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Add-in Manifest Management", 'GetAddinID', '', false, false)]
    local procedure OnGetAddinID(var ID: Text; CodeunitID: Integer)
    begin
        if CodeunitID = CODEUNIT::"Intelligent Info Manifest" then
            ID := AppIdTxt;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Add-in Manifest Management", 'GetAddinVersion', '', false, false)]
    local procedure OnGetAddinVersion(var Version: Text; CodeunitID: Integer)
    begin
        if CodeunitID = CODEUNIT::"Intelligent Info Manifest" then
            Version := GetManifestVersion();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Add-in Manifest Management", 'GetManifestCodeunit', '', false, false)]
    local procedure OnGetCodeunitID(var CodeunitID: Integer; HostType: Text)
    var
        OfficeHostType: DotNet OfficeHostType;
    begin
        if HostType in [OfficeHostType.OutlookItemRead, OfficeHostType.OutlookItemEdit, OfficeHostType.OutlookTaskPane, OfficeHostType.OutlookMobileApp, OfficeHostType.OutlookPopOut] then
            CodeunitID := CODEUNIT::"Intelligent Info Manifest";
    end;

    local procedure CanHandle(CodeunitID: Integer): Boolean
    begin
        exit(CodeunitID = CODEUNIT::"Intelligent Info Manifest");
    end;

    local procedure DefaultManifestText() Value: Text
    begin
        Value :=
          '<?xml version="1.0" encoding="utf-8"?>' +
          '<OfficeApp' +
          '  xmlns="http://schemas.microsoft.com/office/appforoffice/1.1"' +
          '  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"' +
          '  xmlns:bt="http://schemas.microsoft.com/office/officeappbasictypes/1.0"' +
          '  xmlns:o10="http://schemas.microsoft.com/office/mailappversionoverrides"' +
          '  xmlns:o11="http://schemas.microsoft.com/office/mailappversionoverrides/1.1"' +
          '  xsi:type="MailApp">' +
          '  <Id>' + AppIdTxt + '</Id>' +
          '  <Version>' + GetManifestVersion() + '</Version>' +
          '  <ProviderName>Microsoft</ProviderName>' +
          '  <DefaultLocale>en-US</DefaultLocale>' +
          '  <DisplayName DefaultValue="' + AddinManifestManagement.XMLEncode(PRODUCTNAME.Short()) + '" />' +
          '  <Description DefaultValue="' + AddinDescriptionTxt + '" />' +
          '  <IconUrl DefaultValue="WEBCLIENTLOCATION/Resources/Images/OfficeAddinLogo.png"/>' +
          '  <HighResolutionIconUrl DefaultValue="WEBCLIENTLOCATION/Resources/Images/OfficeAddinLogoHigh.png"/>' +
          '  <AppDomains>' +
          '    <AppDomain>WEBCLIENTLOCATION</AppDomain>' +
          '  </AppDomains>' +
          '  <Hosts>' +
          '    <Host Name="Mailbox" />' +
          '  </Hosts>' +
          '  <Requirements>' +
          '    <Sets>' +
          '      <Set Name="MailBox" MinVersion="1.3" />' +
          '    </Sets>' +
          '  </Requirements>' +
          '  <FormSettings>' +
          '    <Form xsi:type="ItemRead">' +
          '      <DesktopSettings>' +
          '        <SourceLocation DefaultValue="" />' +
          '        <RequestedHeight>300</RequestedHeight>' +
          '      </DesktopSettings>' +
          '      <TabletSettings>' +
          '        <SourceLocation DefaultValue="" />' +
          '        <RequestedHeight>400</RequestedHeight>' +
          '      </TabletSettings>' +
          '      <PhoneSettings>' +
          '        <SourceLocation DefaultValue="" />' +
          '      </PhoneSettings>' +
          '    </Form>' +
          '    <Form xsi:type="ItemEdit">' +
          '      <DesktopSettings>' +
          '        <SourceLocation DefaultValue="" />' +
          '      </DesktopSettings>' +
          '      <TabletSettings>' +
          '        <SourceLocation DefaultValue="" />' +
          '      </TabletSettings>' +
          '      <PhoneSettings>' +
          '        <SourceLocation DefaultValue="" />' +
          '      </PhoneSettings>' +
          '    </Form>' +
          '  </FormSettings>' +
          '  <Permissions>ReadWriteMailbox</Permissions>' +
          '  <Rule xsi:type="RuleCollection" Mode="Or">' +
          '    <Rule xsi:type="ItemIs" ItemType="Message" FormType="Edit" />' +
          '    <Rule xsi:type="ItemIs" ItemType="Message" FormType="Read" />' +
          '    <Rule xsi:type="ItemIs" ItemType="Appointment" FormType="Edit" />' +
          '    <Rule xsi:type="ItemIs" ItemType="Appointment" FormType="Read" />' +
          '  </Rule>' +
          '' +
          '  <VersionOverrides xmlns="http://schemas.microsoft.com/office/mailappversionoverrides"' +
          ' xsi:type="VersionOverridesV1_0">' +
          '    <Requirements>' +
          '      <bt:Sets DefaultMinVersion="1.3">' +
          '        <bt:Set Name="Mailbox" />' +
          '      </bt:Sets>' +
          '    </Requirements>' +
          '    <Hosts>' +
          '      <Host xsi:type="MailHost">' +
          '        <DesktopFormFactor>' +
          '          <!-- Custom pane, only applies to read form -->' +
          '          <ExtensionPoint xsi:type="CustomPane">' +
          '            <RequestedHeight>300</RequestedHeight>' +
          '            <SourceLocation resid="taskPaneUrl"/>' +
          '            <!-- Change this Mode to Or to enable the custom pane -->' +
          '            <Rule xsi:type="RuleCollection" Mode="And">' +
          '              <Rule xsi:type="ItemIs" ItemType="Message"/>' +
          '              <Rule xsi:type="ItemIs" ItemType="AppointmentAttendee"/>' +
          '            </Rule>' +
          '          </ExtensionPoint>' +
          '' +
          '          <!-- Message read form -->' +
          '          <ExtensionPoint xsi:type="MessageReadCommandSurface">' +
          '            <OfficeTab id="TabDefault">' +
          '              <Group id="msgReadGroup">' +
          '                <Label resid="groupLabel" />' +
          '                <Tooltip resid="groupTooltip" />' +
          '' +
          '                <!-- Task pane button -->' +
          '                <Control xsi:type="Button" id="msgReadOpenPaneButton">' +
          '                  <Label resid="openPaneButtonLabel" />' +
          '                  <Tooltip resid="openPaneButtonTooltip" />' +
          '                  <Supertip>' +
          '                    <Title resid="openPaneSuperTipTitle" />' +
          '                    <Description resid="openPaneSuperTipDesc" />' +
          '                  </Supertip>' +
          '                  <Icon>' +
          '                    <bt:Image size="16" resid="nav-icon-16" />' +
          '                    <bt:Image size="32" resid="nav-icon-32" />' +
          '                    <bt:Image size="80" resid="nav-icon-80" />' +
          '                  </Icon>' +
          '                  <Action xsi:type="ShowTaskpane">' +
          '                    <SourceLocation resid="taskPaneUrl" />' +
          '                  </Action>' +
          '                </Control>' +
          '' +
          '                <!-- Menu (dropdown) button -->' +
          '                <Control xsi:type="Menu" id="newMenuReadButton">' +
          '                  <Label resid="newMenuButtonLabel" />' +
          '                  <Tooltip resid="newMenuButtonTooltip" />' +
          '                  <Supertip>' +
          '                    <Title resid="newMenuSuperTipTitle" />' +
          '                    <Description resid="newMenuSuperTipDesc" />' +
          '                  </Supertip>' +
          '                  <Icon>' +
          '                    <bt:Image size="16" resid="new-document-16" />' +
          '                    <bt:Image size="32" resid="new-document-32" />' +
          '                    <bt:Image size="80" resid="new-document-80" />' +
          '                  </Icon>' +
          '                  <Items>' +
          '                    <Item id="newMenuReadItem1">' +
          '                      <Label resid="newSalesQuoteLabel" />' +
          '                      <Tooltip resid="newSalesQuoteTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newSalesQuoteSuperTipTitle" />' +
          '                        <Description resid="newSalesQuoteSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="quote-16" />' +
          '                        <bt:Image size="32" resid="quote-32" />' +
          '                        <bt:Image size="80" resid="quote-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newSalesQuoteUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                    <Item id="newMenuReadItem2">' +
          '                      <Label resid="newSalesInvoiceLabel" />' +
          '                      <Tooltip resid="newSalesInvoiceTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newSalesInvoiceSuperTipTitle" />' +
          '                        <Description resid="newSalesInvoiceSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="sales-invoice-16" />' +
          '                        <bt:Image size="32" resid="sales-invoice-32" />' +
          '                        <bt:Image size="80" resid="sales-invoice-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newSalesInvoiceUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                    <Item id="newMenuReadItem3">' +
          '                      <Label resid="newSalesOrderLabel" />' +
          '                      <Tooltip resid="newSalesOrderTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newSalesOrderSuperTipTitle" />' +
          '                        <Description resid="newSalesOrderSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="order-16" />' +
          '                        <bt:Image size="32" resid="order-32" />' +
          '                        <bt:Image size="80" resid="order-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newSalesOrderUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                    <Item id="newMenuReadItem4">' +
          '                      <Label resid="newSalesCreditMemoLabel" />' +
          '                      <Tooltip resid="newSalesCreditMemoTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newSalesCreditMemoSuperTipTitle" />' +
          '                        <Description resid="newSalesCreditMemoSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="sales-credit-memo-16" />' +
          '                        <bt:Image size="32" resid="sales-credit-memo-32" />' +
          '                        <bt:Image size="80" resid="sales-credit-memo-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newSalesCreditMemoUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                    <Item id="newMenuReadItem5">' +
          '                      <Label resid="newPurchaseInvoiceLabel" />' +
          '                      <Tooltip resid="newPurchaseInvoiceTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newPurchaseInvoiceSuperTipTitle" />' +
          '                        <Description resid="newPurchaseInvoiceSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="purchase-invoice-16" />' +
          '                        <bt:Image size="32" resid="purchase-invoice-32" />' +
          '                        <bt:Image size="80" resid="purchase-invoice-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newPurchaseInvoiceUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                    <Item id="newMenuReadItem6">' +
          '                      <Label resid="newPurchaseCrMemoLabel" />' +
          '                      <Tooltip resid="newPurchaseCrMemoTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newPurchaseCrMemoSuperTipTitle" />' +
          '                        <Description resid="newPurchaseCrMemoSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="purchase-credit-memo-16" />' +
          '                        <bt:Image size="32" resid="purchase-credit-memo-32" />' +
          '                        <bt:Image size="80" resid="purchase-credit-memo-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newPurchaseCrMemoUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '' + GetPurchaseOrderMenuItem('newMenuReadItem7') +
          '                  </Items>' +
          '                </Control>' +
          '              </Group>' +
          '            </OfficeTab>' +
          '          </ExtensionPoint>' +
          '' +
          '          <!-- Message compose form -->' +
          '          <ExtensionPoint xsi:type="MessageComposeCommandSurface">' +
          '            <OfficeTab id="TabDefault">' +
          '              <Group id="msgComposeGroup">' +
          '                <Label resid="groupLabel" />' +
          '                <Tooltip resid="groupTooltip" />' +
          '' +
          '                <!-- Task pane button -->' +
          '                <Control xsi:type="Button" id="msgComposeOpenPaneButton">' +
          '                  <Label resid="openPaneButtonLabel" />' +
          '                  <Tooltip resid="openPaneButtonTooltip" />' +
          '                  <Supertip>' +
          '                    <Title resid="openPaneSuperTipTitle" />' +
          '                    <Description resid="openPaneSuperTipDesc" />' +
          '                  </Supertip>' +
          '                  <Icon>' +
          '                    <bt:Image size="16" resid="nav-icon-16" />' +
          '                    <bt:Image size="32" resid="nav-icon-32" />' +
          '                    <bt:Image size="80" resid="nav-icon-80" />' +
          '                  </Icon>' +
          '                  <Action xsi:type="ShowTaskpane">' +
          '                    <SourceLocation resid="taskPaneUrl" />' +
          '                  </Action>' +
          '                </Control>' +
          '' +
          '                <!-- Menu (dropdown) button -->' +
          '                <Control xsi:type="Menu" id="newMenuComposeButton">' +
          '                  <Label resid="newMenuButtonLabel" />' +
          '                  <Tooltip resid="newMenuButtonTooltip" />' +
          '                  <Supertip>' +
          '                    <Title resid="newMenuSuperTipTitle" />' +
          '                    <Description resid="newMenuSuperTipDesc" />' +
          '                  </Supertip>' +
          '                  <Icon>' +
          '                    <bt:Image size="16" resid="new-document-16" />' +
          '                    <bt:Image size="32" resid="new-document-32" />' +
          '                    <bt:Image size="80" resid="new-document-80" />' +
          '                  </Icon>' +
          '                  <Items>' +
          '                    <Item id="newMenuComposeItem1">' +
          '                      <Label resid="newSalesQuoteLabel" />' +
          '                      <Tooltip resid="newSalesQuoteTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newSalesQuoteSuperTipTitle" />' +
          '                        <Description resid="newSalesQuoteSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="quote-16" />' +
          '                        <bt:Image size="32" resid="quote-32" />' +
          '                        <bt:Image size="80" resid="quote-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newSalesQuoteUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                    <Item id="newMenuComposeItem2">' +
          '                      <Label resid="newSalesInvoiceLabel" />' +
          '                      <Tooltip resid="newSalesInvoiceTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newSalesInvoiceSuperTipTitle" />' +
          '                        <Description resid="newSalesInvoiceSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="sales-invoice-16" />' +
          '                        <bt:Image size="32" resid="sales-invoice-32" />' +
          '                        <bt:Image size="80" resid="sales-invoice-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newSalesInvoiceUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                    <Item id="newMenuComposeItem3">' +
          '                      <Label resid="newSalesOrderLabel" />' +
          '                      <Tooltip resid="newSalesOrderTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newSalesOrderSuperTipTitle" />' +
          '                        <Description resid="newSalesOrderSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="order-16" />' +
          '                        <bt:Image size="32" resid="order-32" />' +
          '                        <bt:Image size="80" resid="order-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newSalesOrderUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                    <Item id="newMenuComposeItem4">' +
          '                      <Label resid="newSalesCreditMemoLabel" />' +
          '                      <Tooltip resid="newSalesCreditMemoTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newSalesCreditMemoSuperTipTitle" />' +
          '                        <Description resid="newSalesCreditMemoSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="sales-credit-memo-16" />' +
          '                        <bt:Image size="32" resid="sales-credit-memo-32" />' +
          '                        <bt:Image size="80" resid="sales-credit-memo-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newSalesCreditMemoUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                    <Item id="newMenuComposeItem5">' +
          '                      <Label resid="newPurchaseInvoiceLabel" />' +
          '                      <Tooltip resid="newPurchaseInvoiceTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newPurchaseInvoiceSuperTipTitle" />' +
          '                        <Description resid="newPurchaseInvoiceSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="purchase-invoice-16" />' +
          '                        <bt:Image size="32" resid="purchase-invoice-32" />' +
          '                        <bt:Image size="80" resid="purchase-invoice-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newPurchaseInvoiceUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                    <Item id="newMenuComposeItem6">' +
          '                      <Label resid="newPurchaseCrMemoLabel" />' +
          '                      <Tooltip resid="newPurchaseCrMemoTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newPurchaseCrMemoSuperTipTitle" />' +
          '                        <Description resid="newPurchaseCrMemoSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="purchase-credit-memo-16" />' +
          '                        <bt:Image size="32" resid="purchase-credit-memo-32" />' +
          '                        <bt:Image size="80" resid="purchase-credit-memo-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newPurchaseCrMemoUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '' + GetPurchaseOrderMenuItem('newMenuComposeItem7') +
          '                  </Items>' +
          '                </Control>' +
          '              </Group>' +
          '            </OfficeTab>' +
          '          </ExtensionPoint>' +
          '' +
          '          <!-- Appointment organizer form -->' +
          '          <ExtensionPoint xsi:type="AppointmentOrganizerCommandSurface">' +
          '            <OfficeTab id="TabDefault">' +
          '              <Group id="apptOrganizerGroup">' +
          '                <Label resid="groupLabel" />' +
          '                <Tooltip resid="groupTooltip" />' +
          '                <!-- Task pane button -->' +
          '                <Control xsi:type="Button" id="apptOrganizerOpenPaneButton">' +
          '                  <Label resid="openPaneButtonLabel" />' +
          '                  <Tooltip resid="openPaneButtonTooltip" />' +
          '                  <Supertip>' +
          '                    <Title resid="openPaneSuperTipTitle" />' +
          '                    <Description resid="openPaneSuperTipDesc" />' +
          '                  </Supertip>' +
          '                  <Icon>' +
          '                    <bt:Image size="16" resid="nav-icon-16" />' +
          '                    <bt:Image size="32" resid="nav-icon-32" />' +
          '                    <bt:Image size="80" resid="nav-icon-80" />' +
          '                  </Icon>' +
          '                  <Action xsi:type="ShowTaskpane">' +
          '                    <SourceLocation resid="taskPaneUrl" />' +
          '                  </Action>' +
          '                </Control>' +
          '                <!-- Invoice (dropdown) button -->' +
          '                <Control xsi:type="Menu" id="newMenuOrganizerButton">' +
          '                  <Label resid="newMenuButtonLabel" />' +
          '                  <Tooltip resid="newMenuButtonTooltip" />' +
          '                  <Supertip>' +
          '                    <Title resid="newMenuSuperTipTitle" />' +
          '                    <Description resid="newMenuSuperTipDesc" />' +
          '                  </Supertip>' +
          '                  <Icon>' +
          '                    <bt:Image size="16" resid="new-document-16" />' +
          '                    <bt:Image size="32" resid="new-document-32" />' +
          '                    <bt:Image size="80" resid="new-document-80" />' +
          '                  </Icon>' +
          '                  <Items>' +
          '                    <Item id="newMenuOrganizerItem1">' +
          '                      <Label resid="newSalesQuoteLabel" />' +
          '                      <Tooltip resid="newSalesQuoteTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newSalesQuoteSuperTipTitle" />' +
          '                        <Description resid="newSalesQuoteSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="quote-16" />' +
          '                        <bt:Image size="32" resid="quote-32" />' +
          '                        <bt:Image size="80" resid="quote-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newSalesQuoteUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                    <Item id="newMenuOrganizerItem2">' +
          '                      <Label resid="newSalesInvoiceLabel" />' +
          '                      <Tooltip resid="newSalesInvoiceTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newSalesInvoiceSuperTipTitle" />' +
          '                        <Description resid="newSalesInvoiceSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="sales-invoice-16" />' +
          '                        <bt:Image size="32" resid="sales-invoice-32" />' +
          '                        <bt:Image size="80" resid="sales-invoice-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newSalesInvoiceUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                    <Item id="newMenuOrganizerItem3">' +
          '                      <Label resid="newSalesOrderLabel" />' +
          '                      <Tooltip resid="newSalesOrderTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newSalesOrderSuperTipTitle" />' +
          '                        <Description resid="newSalesOrderSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="order-16" />' +
          '                        <bt:Image size="32" resid="order-32" />' +
          '                        <bt:Image size="80" resid="order-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newSalesOrderUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                    <Item id="newMenuOrganizerItem4">' +
          '                      <Label resid="newSalesCreditMemoLabel" />' +
          '                      <Tooltip resid="newSalesCreditMemoTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newSalesCreditMemoSuperTipTitle" />' +
          '                        <Description resid="newSalesCreditMemoSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="sales-credit-memo-16" />' +
          '                        <bt:Image size="32" resid="sales-credit-memo-32" />' +
          '                        <bt:Image size="80" resid="sales-credit-memo-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newSalesCreditMemoUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                  </Items>' +
          '                </Control>' +
          '              </Group>' +
          '            </OfficeTab>' +
          '          </ExtensionPoint>' +
          '' +
          '          <!-- Appointment attendee form -->' +
          '          <ExtensionPoint xsi:type="AppointmentAttendeeCommandSurface">' +
          '            <OfficeTab id="TabDefault">' +
          '              <Group id="apptAttendeeGroup">' +
          '                <Label resid="groupLabel" />' +
          '                <Tooltip resid="groupTooltip" />' +
          '                <!-- Task pane button -->' +
          '                <Control xsi:type="Button" id="apptAttendeeOpenPaneButton">' +
          '                  <Label resid="openPaneButtonLabel" />' +
          '                  <Tooltip resid="openPaneButtonTooltip" />' +
          '                  <Supertip>' +
          '                    <Title resid="openPaneSuperTipTitle" />' +
          '                    <Description resid="openPaneSuperTipDesc" />' +
          '                  </Supertip>' +
          '                  <Icon>' +
          '                    <bt:Image size="16" resid="nav-icon-16" />' +
          '                    <bt:Image size="32" resid="nav-icon-32" />' +
          '                    <bt:Image size="80" resid="nav-icon-80" />' +
          '                  </Icon>' +
          '                  <Action xsi:type="ShowTaskpane">' +
          '                    <SourceLocation resid="taskPaneUrl" />' +
          '                  </Action>' +
          '                </Control>' +
          '                <!-- Invoice (dropdown) button -->' +
          '                <Control xsi:type="Menu" id="newMenuAttendeeButton">' +
          '                  <Label resid="newMenuButtonLabel" />' +
          '                  <Tooltip resid="newMenuButtonTooltip" />' +
          '                  <Supertip>' +
          '                    <Title resid="newMenuSuperTipTitle" />' +
          '                    <Description resid="newMenuSuperTipDesc" />' +
          '                  </Supertip>' +
          '                  <Icon>' +
          '                    <bt:Image size="16" resid="new-document-16" />' +
          '                    <bt:Image size="32" resid="new-document-32" />' +
          '                    <bt:Image size="80" resid="new-document-80" />' +
          '                  </Icon>' +
          '                  <Items>' +
          '                    <Item id="newMenuAttendeeItem1">' +
          '                      <Label resid="newSalesQuoteLabel" />' +
          '                      <Tooltip resid="newSalesQuoteTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newSalesQuoteSuperTipTitle" />' +
          '                        <Description resid="newSalesQuoteSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="quote-16" />' +
          '                        <bt:Image size="32" resid="quote-32" />' +
          '                        <bt:Image size="80" resid="quote-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newSalesQuoteUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                    <Item id="newMenuAttendeeItem2">' +
          '                      <Label resid="newSalesInvoiceLabel" />' +
          '                      <Tooltip resid="newSalesInvoiceTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newSalesInvoiceSuperTipTitle" />' +
          '                        <Description resid="newSalesInvoiceSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="sales-invoice-16" />' +
          '                        <bt:Image size="32" resid="sales-invoice-32" />' +
          '                        <bt:Image size="80" resid="sales-invoice-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newSalesInvoiceUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                    <Item id="newMenuAttendeeItem3">' +
          '                      <Label resid="newSalesOrderLabel" />' +
          '                      <Tooltip resid="newSalesOrderTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newSalesOrderSuperTipTitle" />' +
          '                        <Description resid="newSalesOrderSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="order-16" />' +
          '                        <bt:Image size="32" resid="order-32" />' +
          '                        <bt:Image size="80" resid="order-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newSalesOrderUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                    <Item id="newMenuAttendeeItem4">' +
          '                      <Label resid="newSalesCreditMemoLabel" />' +
          '                      <Tooltip resid="newSalesCreditMemoTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newSalesCreditMemoSuperTipTitle" />' +
          '                        <Description resid="newSalesCreditMemoSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="sales-credit-memo-16" />' +
          '                        <bt:Image size="32" resid="sales-credit-memo-32" />' +
          '                        <bt:Image size="80" resid="sales-credit-memo-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newSalesCreditMemoUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                  </Items>' +
          '                </Control>' +
          '              </Group>' +
          '            </OfficeTab>' +
          '          </ExtensionPoint>' +
          '        </DesktopFormFactor>' +
          '      </Host>' +
          '    </Hosts>' +
          '    <Resources>' +
          '      <bt:Images>' +
          '        <!-- NAV icon -->' +
          '        <bt:Image id="nav-icon-16" DefaultValue="WEBCLIENTLOCATION/Resources/Images/Dynamics-16x.png"/>' +
          '        <bt:Image id="nav-icon-32" DefaultValue="WEBCLIENTLOCATION/Resources/Images/Dynamics-32x.png"/>' +
          '        <bt:Image id="nav-icon-80" DefaultValue="WEBCLIENTLOCATION/Resources/Images/OfficeAddinLogo.png"/>' +
          '' +
          '        <!-- New document icon -->' +
          '        <bt:Image id="new-document-16" DefaultValue="WEBCLIENTLOCATION/Resources/Images/NewDocument_16x16.png"/>' +
          '        <bt:Image id="new-document-32" DefaultValue="WEBCLIENTLOCATION/Resources/Images/NewDocument_32x32.png"/>' +
          '        <bt:Image id="new-document-80" DefaultValue="WEBCLIENTLOCATION/Resources/Images/NewDocument_80x80.png"/>' +
          '' +
          '        <!-- Quote icon -->' +
          '        <bt:Image id="quote-16" DefaultValue="WEBCLIENTLOCATION/Resources/Images/Quote_16x16.png"/>' +
          '        <bt:Image id="quote-32" DefaultValue="WEBCLIENTLOCATION/Resources/Images/Quote_32x32.png"/>' +
          '        <bt:Image id="quote-80" DefaultValue="WEBCLIENTLOCATION/Resources/Images/Quote_80x80.png"/>' +
          '' +
          '        <!-- Order icon -->' +
          '        <bt:Image id="order-16" DefaultValue="WEBCLIENTLOCATION/Resources/Images/Order_16x16.png"/>' +
          '        <bt:Image id="order-32" DefaultValue="WEBCLIENTLOCATION/Resources/Images/Order_32x32.png"/>' +
          '        <bt:Image id="order-80" DefaultValue="WEBCLIENTLOCATION/Resources/Images/Order_80x80.png"/>' +
          '' +
          '        <!-- Sales Invoice icon -->' +
          '        <bt:Image id="sales-invoice-16" DefaultValue="WEBCLIENTLOCATION/Resources/Images/SalesInvoice_16.png"/>' +
          '        <bt:Image id="sales-invoice-32" DefaultValue="WEBCLIENTLOCATION/Resources/Images/SalesInvoice_32.png"/>' +
          '        <bt:Image id="sales-invoice-80" DefaultValue="WEBCLIENTLOCATION/Resources/Images/SalesInvoice_80.png"/>' +
          '' +
          '        <!-- Purchase Invoice icon -->' +
          '        <bt:Image id="purchase-invoice-16" DefaultValue="WEBCLIENTLOCATION/Resources/Images/PurchaseInvoice_16.png"/>' +
          '        <bt:Image id="purchase-invoice-32" DefaultValue="WEBCLIENTLOCATION/Resources/Images/PurchaseInvoice_32.png"/>' +
          '        <bt:Image id="purchase-invoice-80" DefaultValue="WEBCLIENTLOCATION/Resources/Images/PurchaseInvoice_80.png"/>' +
          '' +
          '        <!-- Credit memo icon -->' +
          '        <bt:Image id="sales-credit-memo-16" DefaultValue="WEBCLIENTLOCATION/Resources/Images/SalesCreditMemo_16.png"/>' +
          '        <bt:Image id="sales-credit-memo-32" DefaultValue="WEBCLIENTLOCATION/Resources/Images/SalesCreditMemo_32.png"/>' +
          '        <bt:Image id="sales-credit-memo-80" DefaultValue="WEBCLIENTLOCATION/Resources/Images/SalesCreditMemo_80.png"/>' +
          '      ' +
          '        <!-- Credit memo icon -->' +
          '        <bt:Image id="purchase-credit-memo-16" DefaultValue="/Resources/Images/PurchaseCreditMemo_16.png"/>' +
          '        <bt:Image id="purchase-credit-memo-32" DefaultValue="/Resources/Images/PurchaseCreditMemo_32.png"/>' +
          '        <bt:Image id="purchase-credit-memo-80" DefaultValue="/Resources/Images/PurchaseCreditMemo_80.png"/>' +
          '      </bt:Images>' +
          '      <bt:Urls>' +
          '        <bt:Url id="taskPaneUrl" DefaultValue=""/>' +
          '        <bt:Url id="newSalesQuoteUrl" DefaultValue=""/>' +
          '        <bt:Url id="newSalesOrderUrl" DefaultValue=""/>' +
          '        <bt:Url id="newSalesInvoiceUrl" DefaultValue=""/>' +
          '        <bt:Url id="newSalesCreditMemoUrl" DefaultValue=""/>' +
          '        <bt:Url id="newPurchaseInvoiceUrl" DefaultValue=""/>' +
          '        <bt:Url id="newPurchaseCrMemoUrl" DefaultValue=""/>' +
          '        <bt:Url id="newPurchaseOrderUrl" DefaultValue=""/>' +
          '      </bt:Urls>' +
          '      <bt:ShortStrings>' +
          '        <!-- Both modes -->' +
          '        <bt:String id="groupLabel" DefaultValue="' + AddinManifestManagement.XMLEncode(PRODUCTNAME.Short()) + '"/>' +
          '' +
          '        <bt:String id="openPaneButtonLabel" DefaultValue="Contact Insights"/>' +
          '        <bt:String id="openPaneSuperTipTitle" DefaultValue="Open ' +
          AddinManifestManagement.XMLEncode(PRODUCTNAME.Short()) + ' in Outlook"/>' +
          '' +
          '        <bt:String id="newMenuButtonLabel" DefaultValue="New"/>' +
          '        <bt:String id="newMenuSuperTipTitle" DefaultValue="Create a new document in ' +
          AddinManifestManagement.XMLEncode(PRODUCTNAME.Short()) + '"/>' +
          '' +
          '        <bt:String id="newSalesQuoteLabel" DefaultValue="Sales Quote"/>' +
          '        <bt:String id="newSalesQuoteSuperTipTitle" DefaultValue="Create new sales quote"/>' +
          '' +
          '        <bt:String id="newSalesOrderLabel" DefaultValue="Sales Order"/>' +
          '        <bt:String id="newSalesOrderSuperTipTitle" DefaultValue="Create new sales order"/>' +
          '' +
          '        <bt:String id="newSalesInvoiceLabel" DefaultValue="Sales Invoice"/>' +
          '        <bt:String id="newSalesInvoiceSuperTipTitle" DefaultValue="Create new sales invoice"/>' +
          '' +
          '        <bt:String id="newSalesCreditMemoLabel" DefaultValue="Sales Credit Memo"/>' +
          '        <bt:String id="newSalesCreditMemoSuperTipTitle" DefaultValue="Create new sales credit memo"/>' +
          '' +
          '        <bt:String id="newPurchaseInvoiceLabel" DefaultValue="Purchase Invoice"/>' +
          '        <bt:String id="newPurchaseInvoiceSuperTipTitle" DefaultValue="Create new purchase invoice"/>' +
          '' +
          '        <bt:String id="newPurchaseCrMemoLabel" DefaultValue="Purchase Credit Memo"/>' +
          '        <bt:String id="newPurchaseCrMemoSuperTipTitle" DefaultValue="Create new purchase credit memo"/>' +
          '' +
          '        <bt:String id="newPurchaseOrderLabel" DefaultValue="Purchase Order"/>' +
          '        <bt:String id="newPurchaseOrderSuperTipTitle" DefaultValue="Create new purchase order"/>' +
          '      </bt:ShortStrings>' +
          '      <bt:LongStrings>' +
          '        <bt:String id="groupTooltip" DefaultValue="' + AddinManifestManagement.XMLEncode(PRODUCTNAME.Short()) + ' Add-in"/>' +
          '' +
          '        <bt:String id="openPaneButtonTooltip" DefaultValue="Opens the contact in an embedded view"/>' +
          '        <bt:String id="openPaneSuperTipDesc" DefaultValue="Opens a pane to interact with the customer or vendor"/>' +
          '' +
          '        <bt:String id="newMenuButtonTooltip" DefaultValue="Creates a new document in ' +
          AddinManifestManagement.XMLEncode(PRODUCTNAME.Short()) + '"/>' +
          '        <bt:String id="newMenuSuperTipDesc" DefaultValue="Creates a new document for the selected customer or vendor"/>' +
          '' +
          '        <bt:String id="newSalesQuoteTip" DefaultValue="Creates a new sales quote in ' +
          AddinManifestManagement.XMLEncode(PRODUCTNAME.Short()) + '" />' +
          '        <bt:String id="newSalesQuoteSuperTipDesc" DefaultValue="Creates a new sales quote for the selected customer." />' +
          '' +
          '        <bt:String id="newSalesOrderTip" DefaultValue="Creates a new sales order in ' +
          AddinManifestManagement.XMLEncode(PRODUCTNAME.Short()) + '" />' +
          '        <bt:String id="newSalesOrderSuperTipDesc" DefaultValue="Creates a new sales order for the selected customer." />' +
          '' +
          '        <bt:String id="newSalesInvoiceTip" DefaultValue="Creates a new sales invoice" />' +
          '        <bt:String id="newSalesInvoiceSuperTipDesc" DefaultValue="Creates a new sales invoice for the customer" />' +
          '' +
          '        <bt:String id="newSalesCreditMemoTip" DefaultValue="Creates a new sales credit memo" />' +
          '        <bt:String id="newSalesCreditMemoSuperTipDesc" DefaultValue="Creates a new sales credit memo" />' +
          '' +
          '        <bt:String id="newPurchaseInvoiceTip" DefaultValue="Creates a new purchase invoice" />' +
          '        <bt:String id="newPurchaseInvoiceSuperTipDesc" DefaultValue="Creates a new purchase invoice" />' +
          '' +
          '        <bt:String id="newPurchaseCrMemoTip" DefaultValue="Creates a new purchase credit memo" />' +
          '        <bt:String id="newPurchaseCrMemoSuperTipDesc" DefaultValue="Creates a new purchase credit memo" />' +
          '' +
          '        <bt:String id="newPurchaseOrderTip" DefaultValue="Creates a new purchase order" />' +
          '        <bt:String id="newPurchaseOrderSuperTipDesc" DefaultValue="Creates a new purchase order" />' +
          '      </bt:LongStrings>' +
          '    </Resources>' +
          '  <VersionOverrides xmlns="http://schemas.microsoft.com/office/mailappversionoverrides/1.1"' +
          ' xsi:type="VersionOverridesV1_1">' +
          '    <Requirements>' +
          '      <bt:Sets DefaultMinVersion="1.5">' +
          '        <bt:Set Name="Mailbox" />' +
          '      </bt:Sets>' +
          '    </Requirements>' +
          '    <Hosts>' +
          '      <Host xsi:type="MailHost">' +
          '        <DesktopFormFactor>' +
          '          <!-- Custom pane, only applies to read form -->' +
          '          <ExtensionPoint xsi:type="CustomPane">' +
          '            <RequestedHeight>300</RequestedHeight>' +
          '            <SourceLocation resid="taskPaneUrl"/>' +
          '            <!-- Change this Mode to Or to enable the custom pane -->' +
          '            <Rule xsi:type="RuleCollection" Mode="And">' +
          '              <Rule xsi:type="ItemIs" ItemType="Message"/>' +
          '              <Rule xsi:type="ItemIs" ItemType="AppointmentAttendee"/>' +
          '            </Rule>' +
          '          </ExtensionPoint>' +
          '' +
          '          <!-- Message read form -->' +
          '          <ExtensionPoint xsi:type="MessageReadCommandSurface">' +
          '            <OfficeTab id="TabDefault">' +
          '              <Group id="msgReadGroup">' +
          '                <Label resid="groupLabel" />' +
          '                <Tooltip resid="groupTooltip" />' +
          '' +
          '                <!-- Task pane button -->' +
          '                <Control xsi:type="Button" id="msgReadOpenPaneButton">' +
          '                  <Label resid="openPaneButtonLabel" />' +
          '                  <Tooltip resid="openPaneButtonTooltip" />' +
          '                  <Supertip>' +
          '                    <Title resid="openPaneSuperTipTitle" />' +
          '                    <Description resid="openPaneSuperTipDesc" />' +
          '                  </Supertip>' +
          '                  <Icon>' +
          '                    <bt:Image size="16" resid="nav-icon-16" />' +
          '                    <bt:Image size="32" resid="nav-icon-32" />' +
          '                    <bt:Image size="80" resid="nav-icon-80" />' +
          '                  </Icon>' +
          '                  <Action xsi:type="ShowTaskpane">' +
          '                    <SourceLocation resid="taskPaneUrl" />' +
          '                    <SupportsPinning>true</SupportsPinning>' +
          '                  </Action>' +
          '                </Control>' +
          '' +
          '                <!-- Menu (dropdown) button -->' +
          '                <Control xsi:type="Menu" id="newMenuReadButton">' +
          '                  <Label resid="newMenuButtonLabel" />' +
          '                  <Tooltip resid="newMenuButtonTooltip" />' +
          '                  <Supertip>' +
          '                    <Title resid="newMenuSuperTipTitle" />' +
          '                    <Description resid="newMenuSuperTipDesc" />' +
          '                  </Supertip>' +
          '                  <Icon>' +
          '                    <bt:Image size="16" resid="new-document-16" />' +
          '                    <bt:Image size="32" resid="new-document-32" />' +
          '                    <bt:Image size="80" resid="new-document-80" />' +
          '                  </Icon>' +
          '                  <Items>' +
          '                    <Item id="newMenuReadItem1">' +
          '                      <Label resid="newSalesQuoteLabel" />' +
          '                      <Tooltip resid="newSalesQuoteTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newSalesQuoteSuperTipTitle" />' +
          '                        <Description resid="newSalesQuoteSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="quote-16" />' +
          '                        <bt:Image size="32" resid="quote-32" />' +
          '                        <bt:Image size="80" resid="quote-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newSalesQuoteUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                    <Item id="newMenuReadItem2">' +
          '                      <Label resid="newSalesInvoiceLabel" />' +
          '                      <Tooltip resid="newSalesInvoiceTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newSalesInvoiceSuperTipTitle" />' +
          '                        <Description resid="newSalesInvoiceSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="sales-invoice-16" />' +
          '                        <bt:Image size="32" resid="sales-invoice-32" />' +
          '                        <bt:Image size="80" resid="sales-invoice-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newSalesInvoiceUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                    <Item id="newMenuReadItem3">' +
          '                      <Label resid="newSalesOrderLabel" />' +
          '                      <Tooltip resid="newSalesOrderTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newSalesOrderSuperTipTitle" />' +
          '                        <Description resid="newSalesOrderSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="order-16" />' +
          '                        <bt:Image size="32" resid="order-32" />' +
          '                        <bt:Image size="80" resid="order-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newSalesOrderUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                    <Item id="newMenuReadItem4">' +
          '                      <Label resid="newSalesCreditMemoLabel" />' +
          '                      <Tooltip resid="newSalesCreditMemoTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newSalesCreditMemoSuperTipTitle" />' +
          '                        <Description resid="newSalesCreditMemoSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="sales-credit-memo-16" />' +
          '                        <bt:Image size="32" resid="sales-credit-memo-32" />' +
          '                        <bt:Image size="80" resid="sales-credit-memo-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newSalesCreditMemoUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                    <Item id="newMenuReadItem5">' +
          '                      <Label resid="newPurchaseInvoiceLabel" />' +
          '                      <Tooltip resid="newPurchaseInvoiceTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newPurchaseInvoiceSuperTipTitle" />' +
          '                        <Description resid="newPurchaseInvoiceSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="purchase-invoice-16" />' +
          '                        <bt:Image size="32" resid="purchase-invoice-32" />' +
          '                        <bt:Image size="80" resid="purchase-invoice-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newPurchaseInvoiceUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                    <Item id="newMenuReadItem6">' +
          '                      <Label resid="newPurchaseCrMemoLabel" />' +
          '                      <Tooltip resid="newPurchaseCrMemoTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newPurchaseCrMemoSuperTipTitle" />' +
          '                        <Description resid="newPurchaseCrMemoSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="purchase-credit-memo-16" />' +
          '                        <bt:Image size="32" resid="purchase-credit-memo-32" />' +
          '                        <bt:Image size="80" resid="purchase-credit-memo-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newPurchaseCrMemoUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '' + GetPurchaseOrderMenuItem('newMenuReadItem7') +
          '                  </Items>' +
          '                </Control>' +
          '              </Group>' +
          '            </OfficeTab>' +
          '          </ExtensionPoint>' +
          '' +
          '          <!-- Message compose form -->' +
          '          <ExtensionPoint xsi:type="MessageComposeCommandSurface">' +
          '            <OfficeTab id="TabDefault">' +
          '              <Group id="msgComposeGroup">' +
          '                <Label resid="groupLabel" />' +
          '                <Tooltip resid="groupTooltip" />' +
          '' +
          '                <!-- Task pane button -->' +
          '                <Control xsi:type="Button" id="msgComposeOpenPaneButton">' +
          '                  <Label resid="openPaneButtonLabel" />' +
          '                  <Tooltip resid="openPaneButtonTooltip" />' +
          '                  <Supertip>' +
          '                    <Title resid="openPaneSuperTipTitle" />' +
          '                    <Description resid="openPaneSuperTipDesc" />' +
          '                  </Supertip>' +
          '                  <Icon>' +
          '                    <bt:Image size="16" resid="nav-icon-16" />' +
          '                    <bt:Image size="32" resid="nav-icon-32" />' +
          '                    <bt:Image size="80" resid="nav-icon-80" />' +
          '                  </Icon>' +
          '                  <Action xsi:type="ShowTaskpane">' +
          '                    <SourceLocation resid="taskPaneUrl" />' +
          '                  </Action>' +
          '                </Control>' +
          '' +
          '                <!-- Menu (dropdown) button -->' +
          '                <Control xsi:type="Menu" id="newMenuComposeButton">' +
          '                  <Label resid="newMenuButtonLabel" />' +
          '                  <Tooltip resid="newMenuButtonTooltip" />' +
          '                  <Supertip>' +
          '                    <Title resid="newMenuSuperTipTitle" />' +
          '                    <Description resid="newMenuSuperTipDesc" />' +
          '                  </Supertip>' +
          '                  <Icon>' +
          '                    <bt:Image size="16" resid="new-document-16" />' +
          '                    <bt:Image size="32" resid="new-document-32" />' +
          '                    <bt:Image size="80" resid="new-document-80" />' +
          '                  </Icon>' +
          '                  <Items>' +
          '                    <Item id="newMenuComposeItem1">' +
          '                      <Label resid="newSalesQuoteLabel" />' +
          '                      <Tooltip resid="newSalesQuoteTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newSalesQuoteSuperTipTitle" />' +
          '                        <Description resid="newSalesQuoteSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="quote-16" />' +
          '                        <bt:Image size="32" resid="quote-32" />' +
          '                        <bt:Image size="80" resid="quote-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newSalesQuoteUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                    <Item id="newMenuComposeItem2">' +
          '                      <Label resid="newSalesInvoiceLabel" />' +
          '                      <Tooltip resid="newSalesInvoiceTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newSalesInvoiceSuperTipTitle" />' +
          '                        <Description resid="newSalesInvoiceSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="sales-invoice-16" />' +
          '                        <bt:Image size="32" resid="sales-invoice-32" />' +
          '                        <bt:Image size="80" resid="sales-invoice-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newSalesInvoiceUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                    <Item id="newMenuComposeItem3">' +
          '                      <Label resid="newSalesOrderLabel" />' +
          '                      <Tooltip resid="newSalesOrderTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newSalesOrderSuperTipTitle" />' +
          '                        <Description resid="newSalesOrderSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="order-16" />' +
          '                        <bt:Image size="32" resid="order-32" />' +
          '                        <bt:Image size="80" resid="order-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newSalesOrderUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                    <Item id="newMenuComposeItem4">' +
          '                      <Label resid="newSalesCreditMemoLabel" />' +
          '                      <Tooltip resid="newSalesCreditMemoTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newSalesCreditMemoSuperTipTitle" />' +
          '                        <Description resid="newSalesCreditMemoSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="sales-credit-memo-16" />' +
          '                        <bt:Image size="32" resid="sales-credit-memo-32" />' +
          '                        <bt:Image size="80" resid="sales-credit-memo-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newSalesCreditMemoUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                    <Item id="newMenuComposeItem5">' +
          '                      <Label resid="newPurchaseInvoiceLabel" />' +
          '                      <Tooltip resid="newPurchaseInvoiceTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newPurchaseInvoiceSuperTipTitle" />' +
          '                        <Description resid="newPurchaseInvoiceSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="purchase-invoice-16" />' +
          '                        <bt:Image size="32" resid="purchase-invoice-32" />' +
          '                        <bt:Image size="80" resid="purchase-invoice-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newPurchaseInvoiceUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                    <Item id="newMenuComposeItem6">' +
          '                      <Label resid="newPurchaseCrMemoLabel" />' +
          '                      <Tooltip resid="newPurchaseCrMemoTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newPurchaseCrMemoSuperTipTitle" />' +
          '                        <Description resid="newPurchaseCrMemoSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="purchase-credit-memo-16" />' +
          '                        <bt:Image size="32" resid="purchase-credit-memo-32" />' +
          '                        <bt:Image size="80" resid="purchase-credit-memo-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newPurchaseCrMemoUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '' + GetPurchaseOrderMenuItem('newMenuComposeItem7') +
          '                  </Items>' +
          '                </Control>' +
          '              </Group>' +
          '            </OfficeTab>' +
          '          </ExtensionPoint>' +
          '' +
          '          <!-- Appointment organizer form -->' +
          '          <ExtensionPoint xsi:type="AppointmentOrganizerCommandSurface">' +
          '            <OfficeTab id="TabDefault">' +
          '              <Group id="apptOrganizerGroup">' +
          '                <Label resid="groupLabel" />' +
          '                <Tooltip resid="groupTooltip" />' +
          '                <!-- Task pane button -->' +
          '                <Control xsi:type="Button" id="apptOrganizerOpenPaneButton">' +
          '                  <Label resid="openPaneButtonLabel" />' +
          '                  <Tooltip resid="openPaneButtonTooltip" />' +
          '                  <Supertip>' +
          '                    <Title resid="openPaneSuperTipTitle" />' +
          '                    <Description resid="openPaneSuperTipDesc" />' +
          '                  </Supertip>' +
          '                  <Icon>' +
          '                    <bt:Image size="16" resid="nav-icon-16" />' +
          '                    <bt:Image size="32" resid="nav-icon-32" />' +
          '                    <bt:Image size="80" resid="nav-icon-80" />' +
          '                  </Icon>' +
          '                  <Action xsi:type="ShowTaskpane">' +
          '                    <SourceLocation resid="taskPaneUrl" />' +
          '                  </Action>' +
          '                </Control>' +
          '                <!-- Invoice (dropdown) button -->' +
          '                <Control xsi:type="Menu" id="newMenuOrganizerButton">' +
          '                  <Label resid="newMenuButtonLabel" />' +
          '                  <Tooltip resid="newMenuButtonTooltip" />' +
          '                  <Supertip>' +
          '                    <Title resid="newMenuSuperTipTitle" />' +
          '                    <Description resid="newMenuSuperTipDesc" />' +
          '                  </Supertip>' +
          '                  <Icon>' +
          '                    <bt:Image size="16" resid="new-document-16" />' +
          '                    <bt:Image size="32" resid="new-document-32" />' +
          '                    <bt:Image size="80" resid="new-document-80" />' +
          '                  </Icon>' +
          '                  <Items>' +
          '                    <Item id="newMenuOrganizerItem1">' +
          '                      <Label resid="newSalesQuoteLabel" />' +
          '                      <Tooltip resid="newSalesQuoteTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newSalesQuoteSuperTipTitle" />' +
          '                        <Description resid="newSalesQuoteSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="quote-16" />' +
          '                        <bt:Image size="32" resid="quote-32" />' +
          '                        <bt:Image size="80" resid="quote-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newSalesQuoteUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                    <Item id="newMenuOrganizerItem2">' +
          '                      <Label resid="newSalesInvoiceLabel" />' +
          '                      <Tooltip resid="newSalesInvoiceTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newSalesInvoiceSuperTipTitle" />' +
          '                        <Description resid="newSalesInvoiceSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="sales-invoice-16" />' +
          '                        <bt:Image size="32" resid="sales-invoice-32" />' +
          '                        <bt:Image size="80" resid="sales-invoice-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newSalesInvoiceUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                    <Item id="newMenuOrganizerItem3">' +
          '                      <Label resid="newSalesOrderLabel" />' +
          '                      <Tooltip resid="newSalesOrderTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newSalesOrderSuperTipTitle" />' +
          '                        <Description resid="newSalesOrderSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="order-16" />' +
          '                        <bt:Image size="32" resid="order-32" />' +
          '                        <bt:Image size="80" resid="order-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newSalesOrderUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                    <Item id="newMenuOrganizerItem4">' +
          '                      <Label resid="newSalesCreditMemoLabel" />' +
          '                      <Tooltip resid="newSalesCreditMemoTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newSalesCreditMemoSuperTipTitle" />' +
          '                        <Description resid="newSalesCreditMemoSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="sales-credit-memo-16" />' +
          '                        <bt:Image size="32" resid="sales-credit-memo-32" />' +
          '                        <bt:Image size="80" resid="sales-credit-memo-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newSalesCreditMemoUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                  </Items>' +
          '                </Control>' +
          '              </Group>' +
          '            </OfficeTab>' +
          '          </ExtensionPoint>' +
          '' +
          '          <!-- Appointment attendee form -->' +
          '          <ExtensionPoint xsi:type="AppointmentAttendeeCommandSurface">' +
          '            <OfficeTab id="TabDefault">' +
          '              <Group id="apptAttendeeGroup">' +
          '                <Label resid="groupLabel" />' +
          '                <Tooltip resid="groupTooltip" />' +
          '                <!-- Task pane button -->' +
          '                <Control xsi:type="Button" id="apptAttendeeOpenPaneButton">' +
          '                  <Label resid="openPaneButtonLabel" />' +
          '                  <Tooltip resid="openPaneButtonTooltip" />' +
          '                  <Supertip>' +
          '                    <Title resid="openPaneSuperTipTitle" />' +
          '                    <Description resid="openPaneSuperTipDesc" />' +
          '                  </Supertip>' +
          '                  <Icon>' +
          '                    <bt:Image size="16" resid="nav-icon-16" />' +
          '                    <bt:Image size="32" resid="nav-icon-32" />' +
          '                    <bt:Image size="80" resid="nav-icon-80" />' +
          '                  </Icon>' +
          '                  <Action xsi:type="ShowTaskpane">' +
          '                    <SourceLocation resid="taskPaneUrl" />' +
          '                  </Action>' +
          '                </Control>' +
          '                <!-- Invoice (dropdown) button -->' +
          '                <Control xsi:type="Menu" id="newMenuAttendeeButton">' +
          '                  <Label resid="newMenuButtonLabel" />' +
          '                  <Tooltip resid="newMenuButtonTooltip" />' +
          '                  <Supertip>' +
          '                    <Title resid="newMenuSuperTipTitle" />' +
          '                    <Description resid="newMenuSuperTipDesc" />' +
          '                  </Supertip>' +
          '                  <Icon>' +
          '                    <bt:Image size="16" resid="new-document-16" />' +
          '                    <bt:Image size="32" resid="new-document-32" />' +
          '                    <bt:Image size="80" resid="new-document-80" />' +
          '                  </Icon>' +
          '                  <Items>' +
          '                    <Item id="newMenuAttendeeItem1">' +
          '                      <Label resid="newSalesQuoteLabel" />' +
          '                      <Tooltip resid="newSalesQuoteTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newSalesQuoteSuperTipTitle" />' +
          '                        <Description resid="newSalesQuoteSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="quote-16" />' +
          '                        <bt:Image size="32" resid="quote-32" />' +
          '                        <bt:Image size="80" resid="quote-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newSalesQuoteUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                    <Item id="newMenuAttendeeItem2">' +
          '                      <Label resid="newSalesInvoiceLabel" />' +
          '                      <Tooltip resid="newSalesInvoiceTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newSalesInvoiceSuperTipTitle" />' +
          '                        <Description resid="newSalesInvoiceSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="sales-invoice-16" />' +
          '                        <bt:Image size="32" resid="sales-invoice-32" />' +
          '                        <bt:Image size="80" resid="sales-invoice-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newSalesInvoiceUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                    <Item id="newMenuAttendeeItem3">' +
          '                      <Label resid="newSalesOrderLabel" />' +
          '                      <Tooltip resid="newSalesOrderTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newSalesOrderSuperTipTitle" />' +
          '                        <Description resid="newSalesOrderSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="order-16" />' +
          '                        <bt:Image size="32" resid="order-32" />' +
          '                        <bt:Image size="80" resid="order-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newSalesOrderUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                    <Item id="newMenuAttendeeItem4">' +
          '                      <Label resid="newSalesCreditMemoLabel" />' +
          '                      <Tooltip resid="newSalesCreditMemoTip" />' +
          '                      <Supertip>' +
          '                        <Title resid="newSalesCreditMemoSuperTipTitle" />' +
          '                        <Description resid="newSalesCreditMemoSuperTipDesc" />' +
          '                      </Supertip>' +
          '                      <Icon>' +
          '                        <bt:Image size="16" resid="sales-credit-memo-16" />' +
          '                        <bt:Image size="32" resid="sales-credit-memo-32" />' +
          '                        <bt:Image size="80" resid="sales-credit-memo-80" />' +
          '                      </Icon>' +
          '                      <Action xsi:type="ShowTaskpane">' +
          '                        <SourceLocation resid="newSalesCreditMemoUrl" />' +
          '                      </Action>' +
          '                    </Item>' +
          '                  </Items>' +
          '                </Control>' +
          '              </Group>' +
          '            </OfficeTab>' +
          '          </ExtensionPoint>' +
          '        </DesktopFormFactor>' +
          '      </Host>' +
          '    </Hosts>' +
          '    <Resources>' +
          '      <bt:Images>' +
          '        <!-- NAV icon -->' +
          '        <bt:Image id="nav-icon-16" DefaultValue="WEBCLIENTLOCATION/Resources/Images/Dynamics-16x.png"/>' +
          '        <bt:Image id="nav-icon-32" DefaultValue="WEBCLIENTLOCATION/Resources/Images/Dynamics-32x.png"/>' +
          '        <bt:Image id="nav-icon-80" DefaultValue="WEBCLIENTLOCATION/Resources/Images/OfficeAddinLogo.png"/>' +
          '' +
          '        <!-- New document icon -->' +
          '        <bt:Image id="new-document-16" DefaultValue="WEBCLIENTLOCATION/Resources/Images/NewDocument_16x16.png"/>' +
          '        <bt:Image id="new-document-32" DefaultValue="WEBCLIENTLOCATION/Resources/Images/NewDocument_32x32.png"/>' +
          '        <bt:Image id="new-document-80" DefaultValue="WEBCLIENTLOCATION/Resources/Images/NewDocument_80x80.png"/>' +
          '' +
          '        <!-- Quote icon -->' +
          '        <bt:Image id="quote-16" DefaultValue="WEBCLIENTLOCATION/Resources/Images/Quote_16x16.png"/>' +
          '        <bt:Image id="quote-32" DefaultValue="WEBCLIENTLOCATION/Resources/Images/Quote_32x32.png"/>' +
          '        <bt:Image id="quote-80" DefaultValue="WEBCLIENTLOCATION/Resources/Images/Quote_80x80.png"/>' +
          '' +
          '        <!-- Order icon -->' +
          '        <bt:Image id="order-16" DefaultValue="WEBCLIENTLOCATION/Resources/Images/Order_16x16.png"/>' +
          '        <bt:Image id="order-32" DefaultValue="WEBCLIENTLOCATION/Resources/Images/Order_32x32.png"/>' +
          '        <bt:Image id="order-80" DefaultValue="WEBCLIENTLOCATION/Resources/Images/Order_80x80.png"/>' +
          '' +
          '        <!-- Sales Invoice icon -->' +
          '        <bt:Image id="sales-invoice-16" DefaultValue="WEBCLIENTLOCATION/Resources/Images/SalesInvoice_16.png"/>' +
          '        <bt:Image id="sales-invoice-32" DefaultValue="WEBCLIENTLOCATION/Resources/Images/SalesInvoice_32.png"/>' +
          '        <bt:Image id="sales-invoice-80" DefaultValue="WEBCLIENTLOCATION/Resources/Images/SalesInvoice_80.png"/>' +
          '' +
          '        <!-- Purchase Invoice icon -->' +
          '        <bt:Image id="purchase-invoice-16" DefaultValue="WEBCLIENTLOCATION/Resources/Images/PurchaseInvoice_16.png"/>' +
          '        <bt:Image id="purchase-invoice-32" DefaultValue="WEBCLIENTLOCATION/Resources/Images/PurchaseInvoice_32.png"/>' +
          '        <bt:Image id="purchase-invoice-80" DefaultValue="WEBCLIENTLOCATION/Resources/Images/PurchaseInvoice_80.png"/>' +
          '' +
          '        <!-- Credit memo icon -->' +
          '        <bt:Image id="sales-credit-memo-16" DefaultValue="WEBCLIENTLOCATION/Resources/Images/SalesCreditMemo_16.png"/>' +
          '        <bt:Image id="sales-credit-memo-32" DefaultValue="WEBCLIENTLOCATION/Resources/Images/SalesCreditMemo_32.png"/>' +
          '        <bt:Image id="sales-credit-memo-80" DefaultValue="WEBCLIENTLOCATION/Resources/Images/SalesCreditMemo_80.png"/>' +
          '      ' +
          '        <!-- Credit memo icon -->' +
          '        <bt:Image id="purchase-credit-memo-16" DefaultValue="/Resources/Images/PurchaseCreditMemo_16.png"/>' +
          '        <bt:Image id="purchase-credit-memo-32" DefaultValue="/Resources/Images/PurchaseCreditMemo_32.png"/>' +
          '        <bt:Image id="purchase-credit-memo-80" DefaultValue="/Resources/Images/PurchaseCreditMemo_80.png"/>' +
          '      </bt:Images>' +
          '      <bt:Urls>' +
          '        <bt:Url id="taskPaneUrl" DefaultValue=""/>' +
          '        <bt:Url id="newSalesQuoteUrl" DefaultValue=""/>' +
          '        <bt:Url id="newSalesOrderUrl" DefaultValue=""/>' +
          '        <bt:Url id="newSalesInvoiceUrl" DefaultValue=""/>' +
          '        <bt:Url id="newSalesCreditMemoUrl" DefaultValue=""/>' +
          '        <bt:Url id="newPurchaseInvoiceUrl" DefaultValue=""/>' +
          '        <bt:Url id="newPurchaseCrMemoUrl" DefaultValue=""/>' +
          '        <bt:Url id="newPurchaseOrderUrl" DefaultValue=""/>' +
          '      </bt:Urls>' +
          '      <bt:ShortStrings>' +
          '        <!-- Both modes -->' +
          '        <bt:String id="groupLabel" DefaultValue="' + AddinManifestManagement.XMLEncode(PRODUCTNAME.Short()) + '"/>' +
          '' +
          '        <bt:String id="openPaneButtonLabel" DefaultValue="Contact Insights"/>' +
          '        <bt:String id="openPaneSuperTipTitle" DefaultValue="Open ' +
          AddinManifestManagement.XMLEncode(PRODUCTNAME.Short()) + ' in Outlook"/>' +
          '' +
          '        <bt:String id="newMenuButtonLabel" DefaultValue="New"/>' +
          '        <bt:String id="newMenuSuperTipTitle" DefaultValue="Create a new document in ' +
          AddinManifestManagement.XMLEncode(PRODUCTNAME.Short()) + '"/>' +
          '' +
          '        <bt:String id="newSalesQuoteLabel" DefaultValue="Sales Quote"/>' +
          '        <bt:String id="newSalesQuoteSuperTipTitle" DefaultValue="Create new sales quote"/>' +
          '' +
          '        <bt:String id="newSalesOrderLabel" DefaultValue="Sales Order"/>' +
          '        <bt:String id="newSalesOrderSuperTipTitle" DefaultValue="Create new sales order"/>' +
          '' +
          '        <bt:String id="newSalesInvoiceLabel" DefaultValue="Sales Invoice"/>' +
          '        <bt:String id="newSalesInvoiceSuperTipTitle" DefaultValue="Create new sales invoice"/>' +
          '' +
          '        <bt:String id="newSalesCreditMemoLabel" DefaultValue="Sales Credit Memo"/>' +
          '        <bt:String id="newSalesCreditMemoSuperTipTitle" DefaultValue="Create new sales credit memo"/>' +
          '' +
          '        <bt:String id="newPurchaseInvoiceLabel" DefaultValue="Purchase Invoice"/>' +
          '        <bt:String id="newPurchaseInvoiceSuperTipTitle" DefaultValue="Create new purchase invoice"/>' +
          '' +
          '        <bt:String id="newPurchaseCrMemoLabel" DefaultValue="Purchase Credit Memo"/>' +
          '        <bt:String id="newPurchaseCrMemoSuperTipTitle" DefaultValue="Create new purchase credit memo"/>' +
          '' +
          '        <bt:String id="newPurchaseOrderLabel" DefaultValue="Purchase Order"/>' +
          '        <bt:String id="newPurchaseOrderSuperTipTitle" DefaultValue="Create new purchase order"/>' +
          '      </bt:ShortStrings>' +
          '      <bt:LongStrings>' +
          '        <bt:String id="groupTooltip" DefaultValue="' + AddinManifestManagement.XMLEncode(PRODUCTNAME.Short()) + ' Add-in"/>' +
          '' +
          '        <bt:String id="openPaneButtonTooltip" DefaultValue="Opens the contact in an embedded view"/>' +
          '        <bt:String id="openPaneSuperTipDesc" DefaultValue="Opens a pane to interact with the customer or vendor"/>' +
          '' +
          '        <bt:String id="newMenuButtonTooltip" DefaultValue="Creates a new document in ' +
          AddinManifestManagement.XMLEncode(PRODUCTNAME.Short()) + '"/>' +
          '        <bt:String id="newMenuSuperTipDesc" DefaultValue="Creates a new document for the selected customer or vendor"/>' +
          '' +
          '        <bt:String id="newSalesQuoteTip" DefaultValue="Creates a new sales quote in ' +
          AddinManifestManagement.XMLEncode(PRODUCTNAME.Short()) + '" />' +
          '        <bt:String id="newSalesQuoteSuperTipDesc" DefaultValue="Creates a new sales quote for the selected customer." />' +
          '' +
          '        <bt:String id="newSalesOrderTip" DefaultValue="Creates a new sales order in ' +
          AddinManifestManagement.XMLEncode(PRODUCTNAME.Short()) + '" />' +
          '        <bt:String id="newSalesOrderSuperTipDesc" DefaultValue="Creates a new sales order for the selected customer." />' +
          '' +
          '        <bt:String id="newSalesInvoiceTip" DefaultValue="Creates a new sales invoice" />' +
          '        <bt:String id="newSalesInvoiceSuperTipDesc" DefaultValue="Creates a new sales invoice for the customer" />' +
          '' +
          '        <bt:String id="newSalesCreditMemoTip" DefaultValue="Creates a new sales credit memo" />' +
          '        <bt:String id="newSalesCreditMemoSuperTipDesc" DefaultValue="Creates a new sales credit memo" />' +
          '' +
          '        <bt:String id="newPurchaseInvoiceTip" DefaultValue="Creates a new purchase invoice" />' +
          '        <bt:String id="newPurchaseInvoiceSuperTipDesc" DefaultValue="Creates a new purchase invoice" />' +
          '' +
          '        <bt:String id="newPurchaseCrMemoTip" DefaultValue="Creates a new purchase credit memo" />' +
          '        <bt:String id="newPurchaseCrMemoSuperTipDesc" DefaultValue="Creates a new purchase credit memo" />' +
          '' +
          '        <bt:String id="newPurchaseOrderTip" DefaultValue="Creates a new purchase order" />' +
          '        <bt:String id="newPurchaseOrderSuperTipDesc" DefaultValue="Creates a new purchase order" />' +
          '      </bt:LongStrings>' +
          '    </Resources>' +
          '  </VersionOverrides>' +
          '  </VersionOverrides>' +
          '</OfficeApp>';
    end;

    local procedure GetPurchaseOrderMenuItem(ItemId: Text[32]) ItemText: Text
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        if ApplicationAreaMgmtFacade.IsSuiteEnabled() then
            ItemText :=
              '                    <Item id="' + ItemId + '">' +
              '                      <Label resid="newPurchaseOrderLabel" />' +
              '                      <Tooltip resid="newPurchaseOrderTip" />' +
              '                      <Supertip>' +
              '                        <Title resid="newPurchaseOrderSuperTipTitle" />' +
              '                        <Description resid="newPurchaseOrderSuperTipDesc" />' +
              '                      </Supertip>' +
              '                      <Icon>' +
              '                        <bt:Image size="16" resid="order-16" />' +
              '                        <bt:Image size="32" resid="order-32" />' +
              '                        <bt:Image size="80" resid="order-80" />' +
              '                      </Icon>' +
              '                      <Action xsi:type="ShowTaskpane">' +
              '                        <SourceLocation resid="newPurchaseOrderUrl" />' +
              '                      </Action>' +
              '                    </Item>';
    end;
}

