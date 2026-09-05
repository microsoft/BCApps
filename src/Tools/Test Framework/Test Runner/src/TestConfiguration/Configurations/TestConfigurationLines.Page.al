// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// Lists the providers that take part in a test configuration together with their JSON settings.
/// </summary>
page 130484 "Test Configuration Lines"
{
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "Test Configuration Line";
    Caption = 'Providers';
    DelayedInsert = true;
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Provider"; Rec."Provider")
                {
                    ToolTip = 'Specifies the provider that contributes to the configuration.';
                }
                field("Enabled"; Rec."Enabled")
                {
                    ToolTip = 'Specifies whether the provider is applied.';
                }
                field(SettingsText; SettingsText)
                {
                    Caption = 'Settings';
                    ToolTip = 'Specifies the provider settings as JSON, for example { "seed": 2 } or { "formula": "<1Y>" }.';

                    trigger OnValidate()
                    begin
                        Rec.SetSettingsText(SettingsText);
                    end;
                }
            }
        }
    }

    var
        SettingsText: Text;

    trigger OnAfterGetRecord()
    begin
        SettingsText := Rec.GetSettingsText();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(SettingsText);
    end;
}
