// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

/// <summary>
/// Lists of all scenarios assigned to an account.
/// </summary>
page 9453 "File Scenarios FactBox"
{
    PageType = ListPart;
    ApplicationArea = All;
    Extensible = false;
    SourceTable = "File Scenario";
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = false;
    ShowFilter = false;
    LinksAllowed = false;
    Permissions = tabledata "File Scenario" = r;
    InherentPermissions = X;
    InherentEntitlements = X;

    layout
    {
        area(Content)
        {
            repeater(ScenariosByFile)
            {
                field(Name; Format(Rec.Scenario))
                {
                    ToolTip = 'Specifies the name of the file scenario.';
                    Caption = 'File scenario';
                    Editable = false;
                }
            }
        }
    }
}