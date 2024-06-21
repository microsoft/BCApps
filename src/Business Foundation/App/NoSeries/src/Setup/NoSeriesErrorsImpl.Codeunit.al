// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 323 "No. Series - Errors Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        OpenNoSeriesRelationshipsTxt: Label 'Open No. Series Relationships';
        OpenNoSeriesLinesTxt: Label 'Open No. Series Lines';
        OpenNoSeriesTxt: Label 'Open No. Series';
        NoSeriesCodeTok: Label 'NoSeriesCode', Locked = true;

    procedure Throw(ErrorMessage: Text; NoSeriesLine: Record "No. Series Line"; ActionDictionary: Dictionary of [Text, Text])
    var
        ErrorInfo: ErrorInfo;
    begin
        if UserCanEditNoSeries() then
            AddAction(ErrorInfo, NoSeriesLine.RecordId(), ActionDictionary);

        ErrorInfo.Message := ErrorMessage;
        Error(ErrorInfo);
    end;

    procedure Throw(ErrorMessage: Text; NoSeriesCode: Code[20]; ActionDictionary: Dictionary of [Text, Text])
    var
        ErrorInfo: ErrorInfo;
    begin
        if UserCanEditNoSeries() then
            AddAction(ErrorInfo, NoSeriesCode, ActionDictionary);

        ErrorInfo.Message := ErrorMessage;
        Error(ErrorInfo);
    end;

    procedure OpenNoSeriesAction() ActionDictionary: Dictionary of [Text, Text]
    begin
        ActionDictionary.Add('Caption', OpenNoSeriesTxt);
        ActionDictionary.Add('Codeunit', format(Codeunit::"No. Series - Errors Impl."));
        ActionDictionary.Add('MethodName', 'OpenNoSeries');
    end;

    procedure OpenNoSeriesLinesAction() ActionDictionary: Dictionary of [Text, Text]
    begin
        ActionDictionary.Add('Caption', OpenNoSeriesLinesTxt);
        ActionDictionary.Add('Codeunit', format(Codeunit::"No. Series - Errors Impl."));
        ActionDictionary.Add('MethodName', 'OpenNoSeriesLines');
    end;

    procedure OpenNoSeriesRelationshipsAction() ActionDictionary: Dictionary of [Text, Text]
    begin
        ActionDictionary.Add('Caption', OpenNoSeriesRelationshipsTxt);
        ActionDictionary.Add('Codeunit', format(Codeunit::"No. Series - Errors Impl."));
        ActionDictionary.Add('MethodName', 'OpenNoSeriesRelationships');
    end;

    local procedure AddAction(var ErrorInfo: ErrorInfo; RecordId: RecordId; ActionDictionary: Dictionary of [Text, Text])
    var
        CodeunitId: Integer;
    begin
        ErrorInfo.RecordId := RecordId;
        Evaluate(CodeunitId, ActionDictionary.Get('Codeunit'));
        ErrorInfo.AddAction(ActionDictionary.Get('Caption'), CodeunitId, ActionDictionary.Get('MethodName'));
    end;

    local procedure AddAction(var ErrorInfo: ErrorInfo; NoSeriesCode: Code[20]; ActionDictionary: Dictionary of [Text, Text])
    var
        CodeunitId: Integer;
    begin
        ErrorInfo.CustomDimensions.Add(NoSeriesCodeTok, NoSeriesCode);
        Evaluate(CodeunitId, ActionDictionary.Get('Codeunit'));
        ErrorInfo.AddAction(ActionDictionary.Get('Caption'), CodeunitId, ActionDictionary.Get('MethodName'));
    end;

    procedure OpenNoSeriesRelationships(ErrorInfo: ErrorInfo)
    var
        NoSeriesLines: Record "No. Series Line";
    begin
        NoSeriesLines.SetRange("Series Code", ErrorInfo.CustomDimensions.Get(NoSeriesCodeTok));
        Page.Run(Page::"No. Series Relationships", NoSeriesLines);
    end;

    procedure OpenNoSeries(ErrorInfo: ErrorInfo)
    var
        NoSeries: Record "No. Series";
    begin
        if ErrorInfo.CustomDimensions.Get(NoSeriesCodeTok) <> '' then
            NoSeries.SetRange(Code, ErrorInfo.CustomDimensions.Get(NoSeriesCodeTok));
        Page.Run(Page::"No. Series", NoSeries);
    end;

    procedure OpenNoSeriesLines(ErrorInfo: ErrorInfo)
    var
        NoSeriesLines: Record "No. Series Line";
    begin
        if ErrorInfo.CustomDimensions.ContainsKey(NoSeriesCodeTok) then
            NoSeriesLines.SetRange("Series Code", ErrorInfo.CustomDimensions.Get(NoSeriesCodeTok))
        else
            if ErrorInfo.RecordId().TableNo = Database::"No. Series Line" then begin
                NoSeriesLines.Get(ErrorInfo.RecordId());
                NoSeriesLines.SetRange("Series Code", NoSeriesLines."Series Code");
            end;

        Page.Run(Page::"No. Series Lines", NoSeriesLines);
    end;

    local procedure UserCanEditNoSeries(): Boolean
    var
        [SecurityFiltering(SecurityFilter::Ignored)]
        NoSeries: Record "No. Series";
    begin
        exit(NoSeries.WritePermission());
    end;
}