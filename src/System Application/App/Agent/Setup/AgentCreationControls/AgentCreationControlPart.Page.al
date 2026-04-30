// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Environment;
using System.Security.AccessControl;

page 4332 "Agent Creation Control Part"
{
    ApplicationArea = All;
    Caption = 'Agent configuration rights';
    DataCaptionExpression = '';
    InherentEntitlements = X;
    MultipleNewLines = false;
    PageType = ListPart;
    SourceTable = "Agent Creation Control";
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Repeater)
            {
                field(CompanyField; CompanyDisplayText)
                {
                    Caption = 'Company';
                    ToolTip = 'Specifies the company where this permission applies. Select "(All Companies)" to apply everywhere.';
                    Editable = false;

                    trigger OnAssistEdit()
                    begin
                        OnCompanyAssistEdit();
                    end;
                }
                field(AgentTypeField; AgentMetadataProviderDisplayText)
                {
                    Caption = 'Agent Type';
                    ToolTip = 'Specifies the agent type allowed to be created. Select "(All Agent Types)" to apply to all types.';
                    Editable = false;

                    trigger OnAssistEdit()
                    begin
                        OnAgentTypeAssistEdit();
                    end;
                }
                field(UserField; UserDisplayText)
                {
                    Caption = 'User';
                    ToolTip = 'Specifies the user allowed to create agents. Select "(All Users)" to apply to everyone.';
                    Editable = false;

                    trigger OnAssistEdit()
                    begin
                        OnUserAssistEdit();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ShowMandatory = true;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateDisplayTexts();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Agent Metadata Provider" := -1;
        ClearDisplayTexts();
    end;

    local procedure OnCompanyAssistEdit()
    var
        Company: Record Company;
        TempAgentCreationControlLookup: Record "Agent Creation Control Lookup" temporary;
        CreationControlLookup: Page "Agent Creation Control Lookup";
        SelectCompanyLbl: Label 'Select company';
        CompanyDisplayName: Text[250];
        AllCompaniesKeyTok: Label '', Locked = true;
    begin
        // Add "(All Companies)" as first option.
        CreationControlLookup.AddEntry(AllCompaniesKeyTok, AllCompaniesLbl);

        // Add all companies.
        if Company.FindSet() then
            repeat
                CompanyDisplayName := Company."Display Name" <> '' ? Company."Display Name" : Company.Name;
                CreationControlLookup.AddEntry(Company.Name, CompanyDisplayName);
            until Company.Next() = 0;

        // Run the lookup.
        CreationControlLookup.Initialize(SelectCompanyLbl, Rec.IsAllCompanies() ? AllCompaniesKeyTok : Rec."Company Name");
        CreationControlLookup.LookupMode := true;
        if CreationControlLookup.RunModal() = Action::LookupOK then begin
            CreationControlLookup.GetRecord(TempAgentCreationControlLookup);
            Rec.Validate(Rec."Company Name", CopyStr(TempAgentCreationControlLookup."Key", 1, MaxStrLen(Rec."Company Name")));
            UpdateDisplayTexts();
        end;
    end;

    local procedure OnAgentTypeAssistEdit()
    var
        TempAgentCreationControlLookup: Record "Agent Creation Control Lookup" temporary;
        AgentUtilities: Codeunit "Agent Utilities";
        CreationControlLookup: Page "Agent Creation Control Lookup";
        AgentMetadataProvider: Enum "Agent Metadata Provider";
        EnumIndex: Integer;
        AgentValue: Text[2048];
        AppPublisher, AppName : Text[250];
        AppId: Guid;
        AgentByPublisherLbl: Label '%1 from ''%2'' by ''%3''', Comment = '%1 = the agent type; %2 = the app name; %3 = the app publisher';
        SelectAgentTypeLbl: Label 'Select agent type';
        AllAgentsEntryKeyTok: Label '', Locked = true;
    begin
        // Add "(All Agent Types)" as first option.
        CreationControlLookup.AddEntry(AllAgentsEntryKeyTok, AllAgentMetadataProvidersLbl);

        // Add all agent types.
        foreach EnumIndex in Enum::"Agent Metadata Provider".Ordinals() do begin
            AgentMetadataProvider := Enum::"Agent Metadata Provider".FromInteger(EnumIndex);
            if AgentUtilities.TryGetAgentAppInfo(AgentMetadataProvider, AppPublisher, AppName, AppId) then begin
                AgentValue := StrSubstNo(AgentByPublisherLbl, Format(AgentMetadataProvider), AppName, AppPublisher);
                CreationControlLookup.AddEntry(Format(EnumIndex), AgentValue);
            end;
        end;

        // Run the lookup.
        CreationControlLookup.Initialize(SelectAgentTypeLbl, Rec.IsAllAgentTypes() ? AllAgentsEntryKeyTok : Format(Rec."Agent Metadata Provider"));
        CreationControlLookup.LookupMode := true;
        if CreationControlLookup.RunModal() = Action::LookupOK then begin
            CreationControlLookup.GetRecord(TempAgentCreationControlLookup);
            if TempAgentCreationControlLookup."Key" = '' then
                Rec.Validate(Rec."Agent Metadata Provider", -1)
            else begin
                Evaluate(EnumIndex, TempAgentCreationControlLookup."Key");
                Rec.Validate(Rec."Agent Metadata Provider", EnumIndex);
            end;
            UpdateDisplayTexts();
        end;
    end;

    local procedure OnUserAssistEdit()
    var
        User: Record User;
        TempAgentCreationControlLookup: Record "Agent Creation Control Lookup" temporary;
        CreationControlLookup: Page "Agent Creation Control Lookup";
        SelectUserLbl: Label 'Select user';
        EmptyGuid, UserSecurityId : Guid;
        AllUsersEntryKeyTok: Label '', Locked = true;
    begin
        // Add "(All Users)" as first option
        CreationControlLookup.AddEntry(AllUsersEntryKeyTok, AllUsersLbl);

        // Add all users
        if User.FindSet() then
            repeat
                if not (User."License Type" in [User."License Type"::Application, User."License Type"::"Windows Group", User."License Type"::Agent]) then
                    CreationControlLookup.AddEntry(User."User Security ID", User."User Name");
            until User.Next() = 0;

        // Run the lookup.
        CreationControlLookup.Initialize(SelectUserLbl, Rec.IsAllUsers() ? AllUsersEntryKeyTok : Rec."User Security ID");
        CreationControlLookup.LookupMode := true;
        if CreationControlLookup.RunModal() = Action::LookupOK then begin
            CreationControlLookup.GetRecord(TempAgentCreationControlLookup);
            if TempAgentCreationControlLookup."Key" = '' then
                Rec.Validate(Rec."User Security ID", EmptyGuid)
            else begin
                Evaluate(UserSecurityId, TempAgentCreationControlLookup."Key");
                Rec.Validate(Rec."User Security ID", UserSecurityId);
            end;
            UpdateDisplayTexts();
        end;
    end;

    local procedure ClearDisplayTexts()
    begin
        Clear(CompanyDisplayText);
        Clear(AgentMetadataProviderDisplayText);
        Clear(UserDisplayText);
    end;

    local procedure UpdateDisplayTexts()
    begin
        UserDisplayText := GetUserDisplayText();
        AgentMetadataProviderDisplayText := GetAgentMetadataProviderDisplayText();
        CompanyDisplayText := GetCompanyDisplayText();
    end;

    local procedure GetUserDisplayText(): Text
    begin
        if Rec.IsAllUsers() then
            exit(AllUsersLbl);

        Rec.CalcFields("User Name");
        if Rec."User Name" <> '' then
            exit(Rec."User Name");

        exit(Format(Rec."User Security ID"));
    end;

    local procedure GetCompanyDisplayText(): Text
    begin
        if Rec.IsAllCompanies() then
            exit(AllCompaniesLbl);

        exit(Rec."Company Name");
    end;

    local procedure GetAgentMetadataProviderDisplayText(): Text
    begin
        if Rec.IsAllAgentTypes() then
            exit(AllAgentMetadataProvidersLbl);

        exit(Format(Enum::"Agent Metadata Provider".FromInteger(Rec."Agent Metadata Provider")));
    end;

    var
        UserDisplayText, AgentMetadataProviderDisplayText, CompanyDisplayText : Text;
        AllUsersLbl: Label 'All users', MaxLength = 2048;
        AllCompaniesLbl: Label 'All companies', MaxLength = 2048;
        AllAgentMetadataProvidersLbl: Label 'All agent types', MaxLength = 2048;
}