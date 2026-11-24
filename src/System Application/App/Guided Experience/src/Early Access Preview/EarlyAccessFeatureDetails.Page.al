// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Environment.Configuration;

page 1999 "Early Access Feature Details"
{
    PageType = CardPart;
    Caption = 'Feature details';
    Editable = false;
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            field(FeatureName; FeatureName)
            {
                ApplicationArea = All;
                Caption = 'Feature';
                ToolTip = 'Specifies the currently selected feature.';
                MultiLine = true;
            }
            field(Overview; Overview)
            {
                ApplicationArea = All;
                Caption = 'Overview';
                ToolTip = 'Specifies what the selected feature does and how it can help you.';
                MultiLine = true;
            }
            group(GettingStartedGroup)
            {
                Caption = 'Getting started';
                Visible = HasGettingStarted;

                field(GettingStarted; GettingStarted)
                {
                    ApplicationArea = All;
                    Caption = 'Getting started';
                    ShowCaption = false;
                    ToolTip = 'Specifies the steps to get started with the selected feature, in order.';
                    MultiLine = true;
                }
            }
        }
    }

    procedure SetFeature(NewFeatureName: Text; NewOverview: Text; NewGettingStarted: Text)
    begin
        FeatureName := NewFeatureName;
        Overview := NewOverview;
        GettingStarted := NewGettingStarted;
        HasGettingStarted := GettingStarted <> '';
        CurrPage.Update(false);
    end;

    var
        FeatureName: Text;
        Overview: Text;
        GettingStarted: Text;
        HasGettingStarted: Boolean;
}
