// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.Integration.D365Sales;
using System;

page 5329 "CRM Redirect"
{
    Caption = 'Dataverse Redirect';
    SourceTable = "CRM Redirect";
    PageType = List;

    layout
    {
        area(content)
        {
        }
    }

    actions
    {
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CRMInfo: Text;
        CRMID: Guid;
        CRMEntityTypeName: Text;
    begin
        CRMInfo := ExtractCRMInfoFromFilters();
        ExtractPartsFromCRMInfo(CRMInfo, CRMID, CRMEntityTypeName);

        // Open the page of the coupled NAV record, or if it is not coupled, offer to create
        if not CRMIntegrationManagement.OpenCoupledNavRecordPage(CRMID, CRMEntityTypeName) then
            // TODO: Give the user the option to couple to an existing NAV entity or create one from CRM
            // For now just do nothing
            Error(NoCoupledEntityErr);
        ;

        CurrPage.Close();
    end;

    trigger OnOpenPage()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        if not CRMIntegrationManagement.IsCRMIntegrationEnabled() and not CRMIntegrationManagement.IsCDSIntegrationEnabled() then
            Error(CRMIntegrationNotEnabledErr, CRMProductName.SHORT(), CRMProductName.CDSServiceName());
    end;

    var
        CRMProductName: Codeunit "CRM Product Name";

        FilterRegexTok: Label '%1: ([A-Za-z0-9\-].+)', Locked = true;
        CRMInfoRegexTok: Label 'CRMID:(\{[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\});CRMType:([a-z0-9_ \/]*)\z', Locked = true;
        InvalidFilterErr: Label 'The URL contains an incorrectly formatted filter string and cannot be processed.';
        InvalidCRMIDErr: Label 'The %2 ID in the URL is not correctly formatted: %1.', Comment = '%1 = Whatever was passed as Dataverse ID in the filter, but clearly not an actual Dataverse ID. %2 = Dataverse service name';
        CRMIntegrationNotEnabledErr: Label 'Integration with %1 or %2 is not enabled.', Comment = '%1 = CRM product name. %2 = Dataverse product name';
        NoCoupledEntityErr: Label 'Coupled record not found. Check integration synchronization errors if you have turned Synch. Only Coupled Records off.';

    procedure ExtractCRMInfoFromFilters() CRMInfo: Text
    var
        RegexHelper: DotNet Regex;
        MatchHelper: DotNet Match;
        GroupCollectionHelper: DotNet GroupCollection;
        GroupHelper: DotNet Group;
        FilterText: Text;
    begin
        FilterText := Rec.GetFilters();
        RegexHelper := RegexHelper.Regex(StrSubstNo(FilterRegexTok, Rec.FieldCaption(Filter)));
        MatchHelper := RegexHelper.Match(FilterText);
        if not MatchHelper.Success then
            Error(InvalidFilterErr);
        GroupCollectionHelper := MatchHelper.Groups;
        GroupHelper := GroupCollectionHelper.Item(1);
        CRMInfo := GroupHelper.Value();
    end;

    procedure ExtractPartsFromCRMInfo(CRMInfo: Text; var CRMID: Guid; var CRMEntityTypeName: Text)
    var
        RegexHelper: DotNet Regex;
        RegexOptionsHelper: DotNet RegexOptions;
        MatchHelper: DotNet Match;
        GroupCollectionHelper: DotNet GroupCollection;
        GroupHelper: DotNet Group;
    begin
        // Extract the CRM ID and CRM entity type name from the CRM info string
        RegexOptionsHelper := RegexOptionsHelper.IgnoreCase;
        RegexHelper := RegexHelper.Regex(CRMInfoRegexTok, RegexOptionsHelper);
        MatchHelper := RegexHelper.Match(CRMInfo);
        if not MatchHelper.Success then
            Error(InvalidFilterErr);
        GroupCollectionHelper := MatchHelper.Groups;
        GroupHelper := GroupCollectionHelper.Item(1);
        if not Evaluate(CRMID, GroupHelper.Value) then
            Error(InvalidCRMIDErr, CRMProductName.CDSServiceName());
        GroupHelper := GroupCollectionHelper.Item(2);
        CRMEntityTypeName := GroupHelper.Value();
    end;
}

