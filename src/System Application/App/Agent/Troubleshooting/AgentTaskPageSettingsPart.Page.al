// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents.Troubleshooting;

page 4328 "Agent Task Page Settings Part"
{
    PageType = CardPart;
    ApplicationArea = All;
    Caption = 'Page Settings';
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CurrencyCode; CurrencyCode)
                {
                    Caption = 'Currency code';
                    ToolTip = 'Specifies the currency code used by the agent.';
                }
                field(CurrencySymbol; CurrencySymbol)
                {
                    Caption = 'Currency symbol';
                    ToolTip = 'Specifies the currency symbol used by the agent.';
                }
            }
            group(Communication)
            {
                Caption = 'Message settings';

                field(CommunicationLanguage; CommunicationLanguage)
                {
                    Caption = 'Language';
                    ToolTip = 'Specifies the language used by the agent when sending messages.';
                }
                field(CommunicationDateFormat; CommunicationDateFormat)
                {
                    Caption = 'Date format';
                    ToolTip = 'Specifies the date format used by the agent when sending messages.';
                }
                field(CommunicationTimeFormat; CommunicationTimeFormat)
                {
                    Caption = 'Time format';
                    ToolTip = 'Specifies the time format used by the agent when sending messages.';
                }
                field(CommunicationFormattedNumberExample; CommunicationFormattedNumberExample)
                {
                    Caption = 'Formatted number example';
                    ToolTip = 'Specifies an example of the number format used by the agent when sending messages.';
                }
            }
        }
    }

    internal procedure SetData(TaskPageContext: JsonObject)
    var
        communicationCultureObj: JsonObject;
    begin
        CurrencyCode := TaskPageContext.GetText(CurrencyCodeLbl, true);
        CurrencySymbol := TaskPageContext.GetText(CurrencySymbolLbl, true);
        if TaskPageContext.Contains(OutgoingCommunicationCultureLbl) then begin
            communicationCultureObj := TaskPageContext.GetObject(OutgoingCommunicationCultureLbl, true);
            CommunicationLanguage := communicationCultureObj.GetText(CommunicationLanguageLbl, true);
            CommunicationDateFormat := communicationCultureObj.GetText(CommunicationDateFormatLbl, true);
            CommunicationFormattedNumberExample := communicationCultureObj.GetText(CommunicationFormattedNumberExampleLbl, true);
            CommunicationTimeFormat := communicationCultureObj.GetText(CommunicationTimeFormatLbl, true);
        end;
    end;

    internal procedure ClearData()
    begin
        CurrencyCode := '';
        CurrencySymbol := '';
        CommunicationLanguage := '';
        CommunicationDateFormat := '';
        CommunicationFormattedNumberExample := '';
        CommunicationTimeFormat := '';
    end;

    var
        CurrencyCode: text;
        CurrencySymbol: text;
        CommunicationLanguage: text;
        CommunicationDateFormat: Text;
        CommunicationFormattedNumberExample: text;
        CommunicationTimeFormat: text;
        CurrencyCodeLbl: label 'currencyCode', Locked = true;
        CurrencySymbolLbl: label 'currencySymbol', Locked = true;
        CommunicationLanguageLbl: label 'language', Locked = true;
        CommunicationDateFormatLbl: label 'dateFormat', Locked = true;
        CommunicationFormattedNumberExampleLbl: label 'formattedNumberExample', Locked = true;
        CommunicationTimeFormatLbl: label 'timeFormat', Locked = true;
        OutgoingCommunicationCultureLbl: label 'outgoingCommunicationCulture', Locked = true;

}