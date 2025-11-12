namespace System.Integration.PowerBI;

using System.Utilities;

codeunit 6324 "Power BI Url Mgt"
{
    SingleInstance = true;

    var
        UrlHelper: Codeunit "Url Helper";
        BaseApiUrlOverride: Text;
        PowerBIHomePageUrlProdTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2150161', Locked = true;
        PowerBIHomePageUrlPpeTxt: Label 'https://powerbi-df.analysis-df.windows.net/', Locked = true;

    /// <summary>
    /// Returns the AAD resource URL for Power BI.
    /// </summary>
    [Scope('OnPrem')]
    procedure GetPowerBIResourceUrl(): Text
    begin
        if UrlHelper.IsPPE() then
            exit('https://analysis.windows-int.net/powerbi/api');

        exit('https://api.fabric.microsoft.com');
    end;

    /// <summary>
    /// Returns the URL to be used for Power BI report upload.
    /// </summary>
    [Scope('OnPrem')]
    procedure GetPowerBIApiUrl(): Text
    begin
        exit(GetBaseApiUrl());
    end;

    /// <summary>
    /// Returns the URL to retrieve the Power BI reports in the user's personal workspace.
    /// </summary>
    [Scope('OnPrem')]
    procedure GetPowerBIReportsUrl(): Text
    begin
        exit(GetBaseApiUrl() + 'v1.0/myorg/reports');
    end;

    /// <summary>
    /// Returns the URL to retrieve the Power BI reports in one of the user's shared workspaces.
    /// </summary>
    [Scope('OnPrem')]
    procedure GetPowerBISharedReportsUrl(WorkspaceID: Guid): Text
    var
        WorkspaceText: Text;
    begin
        WorkspaceText := LowerCase(Format(WorkspaceID, 0, 4)); // Lowercase without brackets

        exit(GetBaseApiUrl() + 'v1.0/myorg/groups/' + WorkspaceText + '/reports');
    end;

    /// <summary>
    /// Returns the URL to retrieve the Power BI workspaces shared with the user.
    /// </summary>
    [Scope('OnPrem')]
    procedure GetPowerBIWorkspacesUrl(): Text
    begin
        exit(GetBaseApiUrl() + 'v1.0/myorg/groups');
    end;

    /// <summary>
    /// Returns the URL where the user can get a Power BI license.
    /// </summary>
    [Scope('OnPrem')]
    procedure GetLicenseUrl(): Text
    begin
        if UrlHelper.IsPPE() then
            exit(PowerBIHomePageUrlPpeTxt);

        exit(PowerBIHomePageUrlProdTxt);
    end;

    /// <summary>
    /// Returns the base URL to embed a Power BI report in Business Central.
    /// </summary>
    [Scope('OnPrem')]
    procedure GetPowerBIEmbedReportsUrl(): Text
    begin
        if UrlHelper.IsPPE() then
            exit('https://powerbi-df.analysis-df.windows.net/reportEmbed');

        exit('https://app.powerbi.com/reportEmbed');
    end;

    local procedure GetBaseApiUrl(): Text
    begin
        if BaseApiUrlOverride <> '' then
            exit(BaseApiUrlOverride);

        if UrlHelper.IsPPE() then
            exit('https://powerbiapi.analysis-df.windows.net/')
        else
            exit('https://api.powerbi.com/');
    end;

    [Scope('OnPrem')]
    internal procedure SetBaseApiUrl(NewBaseApiUrl: Text)
    begin
        BaseApiUrlOverride := NewBaseApiUrl;
    end;
}