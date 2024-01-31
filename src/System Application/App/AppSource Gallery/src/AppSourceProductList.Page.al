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
    AdditionalSearchTerms = 'Extension,Extensions,Marketplace,Management,Customization,Personalization,Install,Publish,Extend,App,Add-In,Customize,Plug-In,AppSource', Locked = true;

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
                    ToolTip = 'Specifies the Display Name';

                    trigger OnDrillDown()
                    begin
                        AppSourceProductManager.OpenProductDetailsPage(Rec.UniqueProductID);
                    end;
                }
                field(UniqueProductID; Rec.UniqueProductID)
                {
                    Visible = false;
                    ToolTip = 'Specifies the Unique Product ID';
                }
                field(PublisherID; Rec.PublisherID)
                {
                    Visible = false;
                    ToolTip = 'Specifies the Publisher ID';
                }

                field(PublisherDisplayName; Rec.PublisherDisplayName)
                {
                    ToolTip = 'Specifies the Publisher Display Name';
                }
                field(Installed; CurrentRecordCanBeUninstalled)
                {
                    Caption = 'Installed';
                    ToolTip = 'Specifies if this app is installed';
                }
                field(RatingAverage; Rec.RatingAverage)
                {
                    ToolTip = 'Specifies the Rating Average';
                }
                field(Popularity; Rec.Popularity)
                {
                    ToolTip = 'Specifies the Popularity index';
                }
                field(RatingCount; Rec.RatingCount)
                {
                    ToolTip = 'Specifies the number of times this has been rated';
                    Visible = false;
                }
                field(LastModifiedDateTime; Rec.LastModifiedDateTime)
                {
                    ToolTip = 'Specifies the date and time this was last modified';
                }
                field(AppID; Rec.AppID)
                {
                    ToolTip = 'Specifies theappID';
                    Visible = false;
                }
                field(PublisherType; Rec.PublisherType)
                {
                    ToolTip = 'Specifies the Publisher Type';
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
                Scope = Repeater;
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
                var
                    SelectedRec: Record "AppSource Product";
                begin
                    CurrPage.SetSelectionFilter(SelectedRec);
                    SelectedRec.Next();

                    if (SelectedRec.Count() = 1) then
                        AppSourceProductManager.OpenInAppSource(SelectedRec.UniqueProductID)
                    else
                        Error(SelectOneRowErrLbl);
                end;
            }

            action(ShowSettings)
            {
                Caption = 'Edit User Settings';
                RunObject = Page "User Settings";
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
                    Rec.ReloadAllProducts();
                    CurrPage.Update();
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
        SelectOneRowErrLbl: Label 'Action requires exactly one row to be selected.';

    trigger OnOpenPage()
    begin
        rec.ReloadAllProducts();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrentRecordCanBeUninstalled := false;
        if (Rec.AppID <> '') then
            CurrentRecordCanBeUninstalled := ExtensionManagement.IsInstalledByAppID(rec.AppID);
    end;
}
