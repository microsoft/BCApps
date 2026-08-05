// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Apps;

/// <summary>
/// Installs the selected extension.
/// </summary>
page 2503 "Extension Installation"
{
    Extensible = false;
    PageType = Card;
    SourceTable = "Extension Installation";
    SourceTableTemporary = true;
    ContextSensitiveHelpPage = 'ui-extensions';

    trigger OnFindRecord(Which: Text): Boolean
    begin
        CurrPage.Close();
    end;

    trigger OnOpenPage()
    var
        ExtensionMarketplace: Codeunit "Extension Marketplace";
        MarketplaceExtnDeployment: Page "Marketplace Extn Deployment";
    begin
        MarketplaceExtnDeployment.SetAppID(Rec.ID);
        MarketplaceExtnDeployment.SetPreviewKey(Rec.PreviewKey);
        MarketplaceExtnDeployment.SetPublisherType(Rec.PublisherType);
        MarketplaceExtnDeployment.RunModal();
        if MarketplaceExtnDeployment.GetInstalledSelected() then
            if not IsNullGuid(Rec.ID) then begin
                ExtensionMarketplace.InstallAppsourceExtensionWithRefreshSession(
                    Rec.ID,
                    Rec.ResponseUrl,
                    Rec.PublisherType);
                MarketplaceExtnDeployment.Close();
            end;
        CurrPage.Close();
    end;

    procedure SetAppID(AppID: Guid)
    begin
        Rec.ID := AppID;
    end;

    procedure SetPreviewKey(PreviewKey: Text[2048])
    begin
        Rec.PreviewKey := PreviewKey;
    end;

    procedure SetPublisherType(PublisherType: Text)
    begin
        Rec.PublisherType := CopyStr(PublisherType, 1, MaxStrLen(Rec.PublisherType));
    end;

    procedure SetResponseUrl(ResponseUrl: Text)
    begin
        Rec.ResponseUrl := CopyStr(ResponseUrl, 1, MaxStrLen(Rec.ResponseUrl));
    end;
}
