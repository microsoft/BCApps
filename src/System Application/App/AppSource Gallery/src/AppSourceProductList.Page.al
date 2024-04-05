// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Apps.AppSource;

using System.Apps;
using System.Environment.Configuration;

/// <summary>
/// List of Products retrieved from AppSource
/// </summary>
page 2515 "AppSource Product List"
{
    PageType = List;
    Caption = 'Microsoft AppSource Apps';
    ApplicationArea = All;
    UsageCategory = Administration;
    Editable = false;
    AdditionalSearchTerms = 'Extension,Extensions,Marketplace,Management,Customization,Personalization,Install,Publish,Extend,App,Add-In,Customize,Plug-In,AppSource,Customize,Plug-In', Locked = true;

    SourceTable = "AppSource Product";
    SourceTableView = sorting(DisplayName);
    SourceTableTemporary = true;

    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            repeater(Repeater)
            {
                field(DisplayName; Rec.DisplayName)
                {
                    DrillDown = true;
                    ToolTip = 'Specifies the display name of the offer.';

                    trigger OnDrillDown()
                    begin
                        AppSourceProductManager.OpenProductDetailsPage(Rec.UniqueProductID);
                    end;
                }
                field(UniqueProductID; Rec.UniqueProductID)
                {
                    Visible = false;
                    ToolTip = 'Specifies the unique product identifier.';
                }
                field(PublisherID; Rec.PublisherID)
                {
                    Visible = false;
                    ToolTip = 'Specifies the ID of the publisher.';
                }

                field(PublisherDisplayName; Rec.PublisherDisplayName)
                {
                    ToolTip = 'Specifies the display name of the publisher.';
                }
                field(Installed; CurrentRecordCanBeUninstalled)
                {
                    Caption = 'Installed';
                    ToolTip = 'Specifies whether this app is installed.';
                }
                field(Popularity; Rec.Popularity)
                {
                    ToolTip = 'Specifies a value from 0-10 indicating the popularity of the offer.';
                }
                field(RatingAverage; Rec.RatingAverage)
                {
                    ToolTip = 'Specifies a value from 0-5 indicating the average user rating.';
                }
                field(RatingCount; Rec.RatingCount)
                {
                    ToolTip = 'Specifies the number of users that have rated the offer.';
                }
                field(LastModifiedDateTime; Rec.LastModifiedDateTime)
                {
                    ToolTip = 'Specifies the date and time this was last modified';
                }
                field(AppID; Rec.AppID)
                {
                    ToolTip = 'Specifies the app ID.';
                    Visible = false;
                }
                field(PublisherType; Rec.PublisherType)
                {
                    ToolTip = 'Specifies whether the offer is a Microsoft or third party product.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(Promoted)
        {
            actionref(AppSource_Promoted; OpenAppSource) { }
            actionref(Open_Promoted; OpenInAppSource) { }
            actionref(Refresh_Promoted; UpdateProducts) { }
            actionref(ShowSettings_Promoted; ShowSettings) { }
        }

        area(Processing)
        {
            action(OpenAppSource)
            {
                Caption = 'View AppSource';
                Scope = Page;
                Image = OpenWorksheet;
                ToolTip = 'View all apps in AppSource';

                trigger OnAction()
                begin
                    AppSourceProductManager.OpenAppSource();
                end;
            }

            action(OpenInAppSource)
            {
                Caption = 'View in AppSource';
                Scope = Repeater;
                Image = Open;
                ToolTip = 'View selected app in AppSource';

                trigger OnAction()
                begin
                    AppSourceProductManager.OpenAppInAppSource(Rec.UniqueProductID)
                end;
            }

            action(ShowSettings)
            {
                Caption = 'Edit User Settings';
                RunObject = page "User Settings";
                Image = UserSetup;
                ToolTip = 'Locale will be used to determine the market and language will be used to determine the language of the app details listed here.';
            }
        }

        area(Navigation)
        {
            action(UpdateProducts)
            {
                Caption = 'Refresh list from Microsoft AppSource';
                Scope = Page;
                ToolTip = 'Refreshes the list by downloading the latest apps from Microsoft AppSource';
                Image = Refresh;

                trigger OnAction()
                begin
                    ReloadAllProducts();
                end;

            }
        }
    }

    views
    {
        view("TopRated")
        {
            Caption = 'Top rated apps';
            Filters = where(RatingAverage = filter(>= 4));
            OrderBy = descending(RatingAverage);
        }

        view("Popular")
        {
            Caption = 'Popular apps';
            OrderBy = descending(Popularity);
        }

        view("Resent Updates")
        {
            Caption = 'Recently changed apps';
            OrderBy = descending(LastModifiedDateTime);
        }
    }

    var
        ExtensionManagement: Codeunit "Extension Management";
        AppSourceProductManager: Codeunit "AppSource Product Manager";
        CurrentRecordCanBeUninstalled: Boolean;

    trigger OnOpenPage()
    begin
        Rec.SetCurrentKey(DisplayName);
        ReloadAllProducts();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrentRecordCanBeUninstalled := false;
        if (not IsNullGuid(Rec.AppID)) then
            CurrentRecordCanBeUninstalled := ExtensionManagement.IsInstalledByAppID(Rec.AppID);
    end;

    local procedure ReloadAllProducts()
    var
        AppSourceProductTemp: Record "AppSource Product";
    begin
        AppSourceProductTemp.Copy(Rec);
        AppSourceProductManager.GetProductsAndPopulateRecord(AppSourceProductTemp);
        Rec.Copy(AppSourceProductTemp, true);
        Rec.FindFirst();
    end;
}
