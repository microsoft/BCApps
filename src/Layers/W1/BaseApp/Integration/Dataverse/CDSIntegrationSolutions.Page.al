// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.Integration.Dataverse;

page 7204 "CDS Integration Solutions"
{
    Caption = 'Dataverse Integration Solutions', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';
    DeleteAllowed = false;
    ModifyAllowed = false;
    InsertAllowed = false;
    Editable = false;
    PageType = List;
    SourceTable = "CDS Solution";
    SourceTableTemporary = true;
    SourceTableView = sorting(FriendlyName);

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;

                field(UniqueName; Rec.UniqueName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Unique Name';
                    Editable = false;
                    StyleExpr = StyleExpression;
                }
                field(Name; Rec.FriendlyName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Friendly Name';
                    Editable = false;
                    StyleExpr = StyleExpression;
                }
                field(Version; Rec.Version)
                {
                    ApplicationArea = Suite;
                    Caption = 'Version';
                    Editable = false;
                    StyleExpr = StyleExpression;
                }
                field(InstalledOn; Rec.InstalledOn)
                {
                    ApplicationArea = Suite;
                    Caption = 'Installed On';
                    Editable = false;
                    StyleExpr = StyleExpression;
                }
                field(IsManaged; Rec.IsManaged)
                {
                    ApplicationArea = Suite;
                    Caption = 'Managed';
                    Editable = false;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Rec.InstalledOn <> 0DT then
            StyleExpression := 'Favorable'
        else
            StyleExpression := 'Unfavorable';
    end;

    trigger OnInit()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSSolution: Record "CDS Solution";
        SolutionUniqueNameList: List of [Text];
        SolutionUniqueName: Text[50];
        TempConnectionName: Text;
    begin
        CDSConnectionSetup.Get();
        CDSIntegrationImpl.CheckConnectionRequiredFields(CDSConnectionSetup, false);

        CDSIntegrationImpl.GetIntegrationSolutions(SolutionUniqueNameList);
        if SolutionUniqueNameList.Count() = 0 then
            exit;

        TempConnectionName := CDSIntegrationImpl.GetTempConnectionName();
        CDSIntegrationImpl.RegisterConnection(CDSConnectionSetup, TempConnectionName);
        SetDefaultTableConnection(TABLECONNECTIONTYPE::CRM, TempConnectionName, true);

        foreach SolutionUniqueName in SolutionUniqueNameList do begin
            Rec.Init();
            CDSSolution.SetRange(UniqueName, SolutionUniqueName);
            if CDSSolution.FindFirst() then
                Rec.TransferFields(CDSSolution)
            else
                Rec.UniqueName := SolutionUniqueName;
            Rec.Insert();
        end;

        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, TempConnectionName);
    end;

    var
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        StyleExpression: Text;
}

