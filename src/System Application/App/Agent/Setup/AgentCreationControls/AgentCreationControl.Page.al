// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Environment;
using System.Security.AccessControl;

page 4326 "Agent Creation Control"
{
    AboutTitle = 'About agent configuration rights';
    AboutText = 'Use this page to control which users can create agents. If no rules exist, only agent administrators can create agents. On install, a default rule allowing everyone is added. Remove all rules to restrict creation to administrators only.';
    AdditionalSearchTerms = 'agent access,allow agent creation,block agent creation';
    AnalysisModeEnabled = false;
    ApplicationArea = All;
    Caption = 'Agent Configuration Rights';
    DataCaptionExpression = '';
    Extensible = false;
    InherentEntitlements = X;
    MultipleNewLines = false;
    PageType = List;
    SourceTable = "Agent Creation Control";
    SourceTableView = sorting("Company Name", "Agent Metadata Provider", "User Security ID") order(ascending);
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            label(Info)
            {
                Caption = 'Grant agent creation capability to non-administrator users. Users must also have the required permission sets for the agent type.';
            }
            repeater(Repeater)
            {
                Caption = 'Permission Rules';
                field(CompanyField; CompanyDisplayText)
                {
                    Caption = 'Company';
                    ToolTip = 'Specifies the company where this permission applies. Select "(All Companies)" to apply everywhere.';
                    Editable = false;
                    Width = 5;

                    trigger OnDrillDown()
                    var
                        Company: Record Company;
                        TempAgentCreationControlLookup: Record "Agent Creation Control Lookup" temporary;
                        CreationControlLookup: Page "Agent Creation Control Lookup";
                        SelectCompanyLbl: Label 'Select company';
                        CompanyDisplayName: Text[250];
                    begin
                        // Add "(All Companies)" as first option.
                        CreationControlLookup.AddItem('', AllCompaniesLbl);

                        // Add all companies.
                        if Company.FindSet() then
                            repeat
                                CompanyDisplayName := Company."Display Name" <> '' ? Company."Display Name" : Company.Name;
                                CreationControlLookup.AddItem(Company.Name, CompanyDisplayName);
                            until Company.Next() = 0;

                        // Run the lookup.
                        CreationControlLookup.SetCaption(SelectCompanyLbl);
                        CreationControlLookup.LookupMode := true;
                        if CreationControlLookup.RunModal() = Action::LookupOK then begin
                            CreationControlLookup.GetRecord(TempAgentCreationControlLookup);
                            Rec."Company Name" := CopyStr(TempAgentCreationControlLookup."Key", 1, MaxStrLen(Rec."Company Name"));
                            UpdateDisplayTexts();
                        end;
                    end;
                }
                field(AgentTypeField; AgentMetadataProviderDisplayText)
                {
                    Caption = 'Agent Type';
                    ToolTip = 'Specifies the agent type allowed to be created. Select "(All Agent Types)" to apply to all types.';
                    Editable = false;
                    Width = 5;

                    trigger OnDrillDown()
                    var
                        TempAgentCreationControlLookup: Record "Agent Creation Control Lookup" temporary;
                        AgentUtilities: Codeunit "Agent Utilities";
                        CreationControlLookup: Page "Agent Creation Control Lookup";
                        AgentMetadataProvider: Enum "Agent Metadata Provider";
                        PublisherType: Enum "Agent Publisher Type";
                        EnumIndex: Integer;
                        AgentValue: Text;
                        PublisherName: Text[250];
                        AgentByPublisherLbl: Label '%1 by ''%2''', Comment = '%1 = the agent type; %2 = the publisher name';
                        SelectAgentTypeLbl: Label 'Select agent type';
                    begin
                        // Add "(All Agent Types)" as first option.
                        CreationControlLookup.AddItem('', AllAgentMetadataProvidersLbl);

                        // Add all agent types.
                        foreach EnumIndex in Enum::"Agent Metadata Provider".Ordinals() do begin
                            AgentMetadataProvider := Enum::"Agent Metadata Provider".FromInteger(EnumIndex);
                            if AgentUtilities.TryGetAgentPublisherInfo(AgentMetadataProvider, PublisherName, PublisherType) then
                                AgentValue := StrSubstNo(AgentByPublisherLbl, Format(AgentMetadataProvider), PublisherName);
#pragma warning disable AA0139
                            CreationControlLookup.AddItem(Format(EnumIndex), AgentValue);
#pragma warning restore AA0139
                        end;

                        // Run the lookup.
                        CreationControlLookup.SetCaption(SelectAgentTypeLbl);
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
                }
                field(UserField; UserDisplayText)
                {
                    Caption = 'User';
                    ToolTip = 'Specifies the user allowed to create agents. Select "(All Users)" to apply to everyone.';
                    Editable = false;
                    Width = 5;

                    trigger OnDrillDown()
                    var
                        User: Record User;
                        TempAgentCreationControlLookup: Record "Agent Creation Control Lookup" temporary;
                        CreationControlLookup: Page "Agent Creation Control Lookup";
                        SelectUserLbl: Label 'Select user';
                        EmptyGuid, UserSecurityId : Guid;
                    begin
                        // Add "(All Users)" as first option
                        CreationControlLookup.AddItem('', AllUsersLbl);

                        // Add all users
                        if User.FindSet() then
                            repeat
                                if not (User."License Type" in [User."License Type"::Application, User."License Type"::"Windows Group", User."License Type"::Agent]) then
                                    CreationControlLookup.AddItem(User."User Security ID", User."User Name");
                            until User.Next() = 0;

                        // Run the lookup.
                        CreationControlLookup.SetCaption(SelectUserLbl);
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
                }
                field(Description; Rec.Description)
                {
                    Width = 30;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateDisplayTexts();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        EmptyGuid: Guid;
    begin
        Rec."Agent Metadata Provider" := -1;
        Rec."Company Name" := '';
        Rec."User Security ID" := EmptyGuid;
        UpdateDisplayTexts();
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

        exit(Format(Rec."Agent Metadata Provider"));
    end;

    var
        UserDisplayText, AgentMetadataProviderDisplayText, CompanyDisplayText : Text;
        AllUsersLbl: Label '(All Users)', MaxLength = 2048;
        AllCompaniesLbl: Label '(All Companies)', MaxLength = 2048;
        AllAgentMetadataProvidersLbl: Label '(All Agent Types)', MaxLength = 2048;
}