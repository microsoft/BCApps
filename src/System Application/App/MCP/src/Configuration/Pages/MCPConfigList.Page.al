// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

#if not CLEAN28
using System.Environment.Configuration;
#endif

page 8350 "MCP Config List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "MCP Configuration";
    CardPageId = "MCP Config Card";
    Caption = 'MCP Configurations';
    Editable = false;
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field(Name; Rec.Name)
                {
                    ToolTip = 'Specifies the name of the MCP configuration.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the description of the MCP configuration.';
                }
                field(Active; Rec.Active)
                {
                    ToolTip = 'Specifies whether the MCP configuration is active.';
                }
            }
        }
    }

#if not CLEAN28
    trigger OnOpenPage()
    var
        MCPConfigImplementation: Codeunit "MCP Config Implementation";
        FeatureNotEnabledErrorInfo: ErrorInfo;
    begin
        if MCPConfigImplementation.IsFeatureEnabled() then
            exit;

        FeatureNotEnabledErrorInfo.Message := FeatureNotEnabledErr;
        FeatureNotEnabledErrorInfo.AddNavigationAction(GoToFeatureManagementLbl);
        FeatureNotEnabledErrorInfo.PageNo := Page::"Feature Management";
        Error(FeatureNotEnabledErrorInfo);
    end;

    var
        FeatureNotEnabledErr: Label 'MCP server feature is not enabled. Please contact your system administrator to enable the feature.';
        GoToFeatureManagementLbl: Label 'Go to Feature Management';
#endif
}