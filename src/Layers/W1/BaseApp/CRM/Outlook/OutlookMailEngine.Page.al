// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

using System;

page 1600 "Outlook Mail Engine"
{
    Caption = 'Outlook Mail Engine';
    DelayedInsert = false;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SourceTable = "Office Add-in Context";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Email; Rec.Email)
                {
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the email address of the Outlook contact.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the display name of the Outlook contact.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type that the involved document belongs to.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved document.';
                }
                field(Company; Rec.Company)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Contact No."; Rec."Contact No.")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
        }
    }

    trigger OnOpenPage()
    var
        [RunOnClient]
        OfficeHost: DotNet OfficeHost;
    begin
        if OfficeHost.IsAvailable() then begin
            OfficeHost := OfficeHost.Create();
            OfficeMgt.InitializeHost(OfficeHost, OfficeHost.HostType);
        end;

        GetDetailsFromFilters();
        SendTelemetryOnAddinStarted();

        if Rec.Email = 'donotreply@contoso.com' then
            Page.Run(Page::"Office Welcome Dlg")
        else
            OfficeMgt.InitializeContext(Rec);

        CurrPage.Close();
        OfficeMgt.CloseEnginePage();
    end;

    var
        OfficeMgt: Codeunit "Office Management";
        OfficeAddinStartedTelemetryMsg: Label 'Office add-in is being started with filters: %1. Resulting fields are: %2. ', Locked = true;

    local procedure GetDetailsFromFilters()
    var
        RecRef: RecordRef;
        i: Integer;
    begin
        RecRef.GetTable(Rec);
        for i := 1 to RecRef.FieldCount do
            ParseFilter(RecRef.FieldIndex(i));
        RecRef.SetTable(Rec);
    end;

    local procedure ParseFilter(FieldRef: FieldRef)
    var
        FilterPrefixRegEx: DotNet Regex;
        SingleQuoteRegEx: DotNet Regex;
        "Filter": Text;
        OptionValue: Integer;
    begin
        FilterPrefixRegEx := FilterPrefixRegEx.Regex('^@\*([^\\]+)\*$');
        SingleQuoteRegEx := SingleQuoteRegEx.Regex('^''([^\\]+)''$');

        Filter := FieldRef.GetFilter;
        Filter := FilterPrefixRegEx.Replace(Filter, '$1');
        Filter := SingleQuoteRegEx.Replace(Filter, '$1');
        if Filter <> '' then
            if FieldRef.Type = FieldType::Option then
                while true do begin
                    OptionValue += 1;
                    if UpperCase(Filter) = UpperCase(SelectStr(OptionValue, FieldRef.OptionCaption)) then begin
                        FieldRef.Value := OptionValue - 1;
                        exit;
                    end;
                end
            else
                FieldRef.Value(Filter);
    end;

    local procedure SendTelemetryOnAddinStarted()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        i: Integer;
        FieldValuesText: Text;
    begin
        RecRef.GetTable(Rec);
        for i := 1 to RecRef.FieldCount do begin
            FldRef := RecRef.FieldIndex(i);
            FieldValuesText += FldRef.Name + '=' + Format(FldRef.Value, 9) + ',';
        end;
        FieldValuesText := DelChr(FieldValuesText, '>', ',');

        Session.LogMessage('0000BOY', StrSubstNo(OfficeAddinStartedTelemetryMsg, Rec.GetFilters(), FieldValuesText), Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', OfficeMgt.GetOfficeAddinTelemetryCategory());
    end;
}

