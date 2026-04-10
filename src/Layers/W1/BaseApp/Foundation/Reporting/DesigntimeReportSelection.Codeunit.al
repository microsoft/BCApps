// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

codeunit 9654 "Design-time Report Selection"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        SelectedCustomLayoutCode: Code[20];
        SelectedPlatformLayoutName: Text[250];
        SelectedPlatformLayoutAppID: Guid;
        EmptyGuid: Guid;

    // This method allows us to select layouts stored in the App Table "Custom Report Layout" table. 
    procedure SetSelectedCustomLayout(NewCustomLayoutCode: Code[20])
    begin
        SelectedCustomLayoutCode := NewCustomLayoutCode;
    end;

    procedure GetSelectedCustomLayout(): Code[20]
    begin
        exit(SelectedCustomLayoutCode);
    end;

    // This method allow us to select layouts stored in "Tenant Report Layout" platform table
    // by their "Name" and also allows selecting layouts from the "Custom Report Layout" table.
    procedure SetSelectedLayout(LayoutName: Text[250])
    begin
        SelectedPlatformLayoutName := LayoutName;
    end;

    // This method allows us to select layouts stored both in "Tenant Report Layout" and  "Report Layouts Definition"
    // table (Or their aggregate table "Report Layouts List"). 
    procedure SetSelectedLayout(LayoutName: Text[250]; AppID: Guid)
    begin
        SelectedPlatformLayoutName := LayoutName;
        SelectedPlatformLayoutAppID := AppID;
    end;

    procedure GetSelectedLayout(): Text[250]
    begin
        if SelectedPlatformLayoutName = '' then
            exit(SelectedCustomLayoutCode);

        exit(SelectedPlatformLayoutName);
    end;

    procedure GetSelectedAppID(): Guid
    begin
        exit(SelectedPlatformLayoutAppID);
    end;

    procedure ClearLayoutSelection()
    begin
        SelectedPlatformLayoutName := '';
        SelectedCustomLayoutCode := '';
        SelectedPlatformLayoutAppID := EmptyGuid;
    end;
}
