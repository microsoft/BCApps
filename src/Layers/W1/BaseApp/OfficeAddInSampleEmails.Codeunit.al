// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
codeunit 1655 "Office Add-In Sample Emails"
{

    trigger OnRun()
    begin
    end;

    var
        WelcomeTxt: Label 'We are all set up. Welcome to Your business inbox in Outlook!';
        FirstHeaderTxt: Label 'Get business done without leaving Outlook';
        FirstParagraph_Part1Txt: Label 'With %1, your business comes to you directly in Microsoft Outlook. Getting started in Outlook is easy: use the steps below to see how quickly you can create and send documents for your business contacts.', Comment = '%1 = Application Name';
        GetStartedTxt: Label 'Get started with contact insights';
        OutlookHeaderTxt: Label 'In Outlook:';
        OutlookParagraphTxt: Label 'Find %1 in the ribbon, and choose Contact Insights.', Comment = '%1 = Application Name';
        OWAHeaderTxt: Label 'In Outlook on the web:', Comment = 'Outlook on the web is a product name';
        OWAParagraph1Txt: Label 'Choose ''More actions'' ', Comment = 'Trailing space is required. More actions is the text used in OWA - it''s not clear how this would be translated.';
        OWAParagraph2Txt: Label ' in the upper-right corner of the email and choose %1.', Comment = '%1 = Application Name; Opening space is required.';
        SalesQuoteHdrTxt: Label 'Create a sales quote';
        SalesQuoteIntroTxt: Label 'Business Central helps you author email responses by suggesting items and quantities that you can include in an attached document.';
        SalesQuoteInst1Txt: Label 'On the app bar, choose Sales Quote from the New menu';
        SalesQuoteInst2Txt: Label 'Review the items and quantities in Suggested Items list and select those you want to add to the sales quote. You can adjust these directly on the quote.';
        SalesQuoteInst3Txt: Label 'On the document''s action menu, choose Send by Email.';
        SalesQuoteInst4Txt: Label 'Review the mail and attached file before you send it.';
        SalesQuoteInst5Txt: Label 'In the add-in pane, choose the back arrow to return to the customer dashboard.';
        SalesQuoteFirstItemNameTxt: Label 'London Swivel Chair', Comment = 'Special characters such as hyphen, brackets, parentheses and commas are not allowed.';
        SalesQuoteFirstItemQtyTxt: Label '7';
        SalesQuoteSecondItemNameTxt: Label 'Antwerp Conference Table', Comment = 'Special characters such as hyphen, brackets, parentheses and commas are not allowed.';
        SalesQuoteSecondItemQtyTxt: Label '2';
        LineNo1Txt: Label '1.';
        LineNo2Txt: Label '2.';
        LineNo3Txt: Label '3.';
        LineNo4Txt: Label '4.';
        LineNo5Txt: Label '5.';
        OpenParenTxt: Label '(';
        CloseParenTxt: Label ')';
        BrandingFolderTxt: Label 'ProjectMadeira/', Locked = true;
        ResourceNotFoundErr: Label 'Something went wrong while preparing the email template. Please contact your administrator.';
        ResourceNotFoundTelemetryMsg: Label 'The HTML resource ''%1'' was not found.', Locked = true;
        TelemetryCategoryTxt: Label 'OfficeAddIn', Locked = true;

    local procedure LoadHtmlResource(HtmlFile: Text): Text
    var
        Result: Text;
    begin
        Result := NavApp.GetResourceAsText(HtmlFile, TextEncoding::UTF8);
        if Result = '' then begin
            Session.LogMessage('0000SLI', StrSubstNo(ResourceNotFoundTelemetryMsg, HtmlFile),
             Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTxt);
            Error(ResourceNotFoundErr);
        end;
        exit(Result);
    end;

    local procedure SubstituteHtml(Html: Text): Text
    var
        ItemRec: Record Item;
        SalesLineRec: Record "Sales Line";
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
        Replacements: Dictionary of [Text, Text];
        KeyVar: Text;
    begin
        // Keys are added in descending length order so longest placeholders are replaced first
        Replacements.Add('{{OutlookDesktopIconDiscovery.png}}',
            AddinManifestManagement.GetImageUrl(
                BrandingFolderTxt + 'OutlookDesktopIconDiscovery.png'));

        Replacements.Add('{{SalesQuoteSecondItemNameTxt}}', SalesQuoteSecondItemNameTxt);
        Replacements.Add('{{OutlookWebIconDiscovery.png}}',
            AddinManifestManagement.GetImageUrl(
                BrandingFolderTxt + 'OutlookWebIconDiscovery.png'));

        Replacements.Add('{{SalesQuoteSecondItemQtyTxt}}', SalesQuoteSecondItemQtyTxt);
        Replacements.Add('{{SalesQuoteFirstItemNameTxt}}', SalesQuoteFirstItemNameTxt);

        Replacements.Add('{{SalesQuoteFirstItemQtyTxt}}', SalesQuoteFirstItemQtyTxt);

        Replacements.Add('{{SalesLineQuantityCaption}}',
            SalesLineRec.FieldCaption(Quantity));
        Replacements.Add('{{OutlookWelcomeBanner.png}}',
            AddinManifestManagement.GetImageUrl(
                BrandingFolderTxt + 'OutlookWelcomeBanner.png'));

        Replacements.Add('{{FirstParagraph_Part1Txt}}',
            StrSubstNo(FirstParagraph_Part1Txt, PRODUCTNAME.Short()));

        Replacements.Add('{{OutlookNewDocument.png}}',
            AddinManifestManagement.GetImageUrl(
                BrandingFolderTxt + 'OutlookNewDocument.png'));

        Replacements.Add('{{OutlookParagraphTxt}}',
            StrSubstNo(OutlookParagraphTxt, PRODUCTNAME.Short()));

        Replacements.Add('{{SalesQuoteIntroTxt}}', SalesQuoteIntroTxt);
        Replacements.Add('{{SalesQuoteInst1Txt}}', SalesQuoteInst1Txt);
        Replacements.Add('{{SalesQuoteInst2Txt}}', SalesQuoteInst2Txt);
        Replacements.Add('{{SalesQuoteInst3Txt}}', SalesQuoteInst3Txt);
        Replacements.Add('{{SalesQuoteInst4Txt}}', SalesQuoteInst4Txt);
        Replacements.Add('{{SalesQuoteInst5Txt}}', SalesQuoteInst5Txt);
        Replacements.Add('{{OutlookEllipse.png}}',
            AddinManifestManagement.GetImageUrl(
                BrandingFolderTxt + 'OutlookEllipse.png'));

        Replacements.Add('{{OutlookHeaderTxt}}', OutlookHeaderTxt);
        Replacements.Add('{{ItemTableCaption}}', ItemRec.TableCaption);
        Replacements.Add('{{SalesQuoteHdrTxt}}', SalesQuoteHdrTxt);
        Replacements.Add('{{OWAParagraph1Txt}}', OWAParagraph1Txt);
        Replacements.Add('{{OWAParagraph2Txt}}',
            StrSubstNo(OWAParagraph2Txt, PRODUCTNAME.Short()));

        Replacements.Add('{{FirstHeaderTxt}}', FirstHeaderTxt);

        Replacements.Add('{{GetStartedTxt}}', GetStartedTxt);
        Replacements.Add('{{CloseParenTxt}}', CloseParenTxt);

        Replacements.Add('{{OpenParenTxt}}', OpenParenTxt);
        Replacements.Add('{{OWAHeaderTxt}}', OWAHeaderTxt);

        Replacements.Add('{{MS_Logo.png}}',
            AddinManifestManagement.GetImageUrl(
                BrandingFolderTxt + 'MS_Logo.png'));

        Replacements.Add('{{WelcomeTxt}}', WelcomeTxt);
        Replacements.Add('{{LineNo1Txt}}', LineNo1Txt);
        Replacements.Add('{{LineNo2Txt}}', LineNo2Txt);
        Replacements.Add('{{LineNo3Txt}}', LineNo3Txt);
        Replacements.Add('{{LineNo4Txt}}', LineNo4Txt);
        Replacements.Add('{{LineNo5Txt}}', LineNo5Txt);

        foreach KeyVar in Replacements.Keys do
            Html := Html.Replace(KeyVar, Replacements.Get(KeyVar));

        exit(Html);
    end;

    procedure GetHTMLSampleMsg() HTMLBody: Text
    var
        HtmlTemplate: Text;
    begin
        HtmlTemplate := LoadHtmlResource('HtmlTemplates/OfficeAddInSampleEmailResource.html');
        HTMLBody := SubstituteHtml(HtmlTemplate);
    end;


    procedure GetHTMLSampleMsgNonEvalCompany() HTMLBody: Text
    var
        HtmlTemplate: Text;
    begin
        HtmlTemplate := LoadHtmlResource('HtmlTemplates/OfficeAddInSampleEmailNonEvalCompany.html');
        HTMLBody := SubstituteHtml(HtmlTemplate);
    end;
}

