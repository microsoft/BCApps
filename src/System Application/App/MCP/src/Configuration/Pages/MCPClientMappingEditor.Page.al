// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

page 8381 "MCP Client Mapping Editor"
{
    Caption = 'Client Mappings';
    PageType = ListPlus;
    ApplicationArea = All;
    SourceTable = "MCP Configuration";
    DataCaptionFields = Name;
    InsertAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Configuration';
                Editable = false;

                field(Name; Rec.Name) { }
                field(Description; Rec.Description) { }
            }
            part(Mappings; "MCP Client Config. Mappings")
            {
                ApplicationArea = All;
                SubPageLink = "Configuration ID" = field(SystemId);
            }
        }
    }

    trigger OnOpenPage()
    begin
        if IsNullGuid(ConfigurationId) then
            Error(ConfigurationRequiredErr);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.Mappings.Page.SetConfiguration(Rec.SystemId);
    end;

    var
        ConfigurationId: Guid;
        ConfigurationRequiredErr: Label 'Open client mappings from an MCP configuration.';

    internal procedure SetConfiguration(ConfigSystemId: Guid)
    begin
        Rec.GetBySystemId(ConfigSystemId);
        ConfigurationId := ConfigSystemId;
        Rec.FilterGroup(2);
        Rec.SetRange(SystemId, ConfigSystemId);
        Rec.FilterGroup(0);
    end;
}
