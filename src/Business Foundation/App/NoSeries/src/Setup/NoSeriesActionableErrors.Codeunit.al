// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 323 "No. Series Actionable Errors"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        OpenNoSeriesLinesTxt: Label 'Open No. Series Lines';
        OpenNoSeriesTxt: Label 'Open No. Series';
        NoSeriesCodeTok: Label 'NoSeriesCode', Locked = true;

    procedure ThrowActionableErrorOpenNoSeries(ErrorMessage: Text; NoSeriesCode: Code[20])
    var
        ErrorInfo: ErrorInfo;
    begin
        ErrorInfo.Message := ErrorMessage;

        if UserCanEditNoSeries() then begin
            ErrorInfo.CustomDimensions.Add(NoSeriesCodeTok, NoSeriesCode);
            ErrorInfo.AddAction(OpenNoSeriesTxt, CodeUnit::"No. Series Actionable Errors", 'OpenNoSeries');
        end;

        Error(ErrorInfo);
    end;

    procedure ThrowActionableErrorOpenNoSeriesLinesError(ErrorMessage: Text; NoSeriesCode: Code[20]) ErrorInfo: ErrorInfo
    begin
        ErrorInfo.Message := ErrorMessage;

        if UserCanEditNoSeries() then begin
            ErrorInfo.CustomDimensions.Add(NoSeriesCodeTok, NoSeriesCode);
            ErrorInfo.AddAction(OpenNoSeriesLinesTxt, CodeUnit::"No. Series Actionable Errors", 'OpenNoSeriesLines');
        end;

        Error(ErrorInfo);
    end;

    procedure ThrowActionableErrorOpenNoSeriesRelationships(ErrorMessage: Text; NoSeriesCode: Code[20]) ErrorInfo: ErrorInfo
    begin
        ErrorInfo.Message := ErrorMessage;

        if UserCanEditNoSeries() then begin
            ErrorInfo.CustomDimensions.Add(NoSeriesCodeTok, NoSeriesCode);
            ErrorInfo.AddAction(OpenNoSeriesLinesTxt, CodeUnit::"No. Series Actionable Errors", 'OpenNoSeriesRelationships');
        end;

        Error(ErrorInfo);
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
        NoSeriesLines.SetRange("Series Code", ErrorInfo.CustomDimensions.Get(NoSeriesCodeTok));
        Page.Run(Page::"No. Series Lines", NoSeriesLines);
    end;

    local procedure UserCanEditNoSeries(): Boolean
    var
        NoSeries: Record "No. Series";
    begin
        exit(NoSeries.WritePermission());
    end;
}