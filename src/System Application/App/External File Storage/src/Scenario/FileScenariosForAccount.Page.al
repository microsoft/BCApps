// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

/// <summary>
/// Displays the scenarios that could be linked to a provided file account.
/// </summary>
page 9454 "File Scenarios for Account"
{
    PageType = List;
    ApplicationArea = All;
    Extensible = false;
    SourceTable = "File Account Scenario";
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = false;
    ShowFilter = false;
    LinksAllowed = false;
    InherentPermissions = X;
    InherentEntitlements = X;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(ScenariosByFile)
            {
                field(Name; Rec."Display Name")
                {
                    ToolTip = 'Specifies the name of the file scenario.';
                    Caption = 'File scenario';
                    Editable = false;
                }
            }
        }
    }

    internal procedure GetSelectedScenarios(var TempResultFileAccountScenario: Record "File Account Scenario" temporary)
    begin
        TempResultFileAccountScenario.Reset();
        TempResultFileAccountScenario.DeleteAll();

        CurrPage.SetSelectionFilter(Rec);

        if not Rec.FindSet() then
            exit;

        repeat
            TempResultFileAccountScenario.Copy(Rec);
            TempResultFileAccountScenario.Insert();
        until Rec.Next() = 0;
    end;

    trigger OnOpenPage()
    begin
        FileScenarioImpl.GetAvailableScenariosForAccount(Rec, Rec);
        Rec.SetCurrentKey("Display Name");
        if Rec.FindFirst() then; // Set the selection to the first record
    end;

    var
        FileScenarioImpl: Codeunit "File Scenario Impl.";
}