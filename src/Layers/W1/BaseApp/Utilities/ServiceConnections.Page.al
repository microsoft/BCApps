// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Integration.Dataverse;
using System.Environment.Configuration;

page 1279 "Service Connections"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Service Connections';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Service Connection";
    SourceTableTemporary = true;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the service. The description is based on the name of the setup page that opens when you choose the Setup.';
                }
                field("Host Name"; Rec."Host Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the web service. This is typically a URL.';
                    Visible = false;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleExpression;
                    ToolTip = 'Specifies if the service is enabled or disabled.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(Setup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Setup';
                Enabled = SetupActive;
                Image = Setup;
                Scope = Repeater;
                ShortCutKey = 'Return';
                ToolTip = 'Get a connection to a service up and running or manage an connection that is already working.';

                trigger OnAction()
                begin
                    CallSetup();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Setup_Promoted; Setup)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        RefreshPressed: Boolean;
    begin
        RefreshPressed := CurrRecordNo = Rec."No.";
        if RefreshPressed then
            Refresh()
        else
            CurrRecordNo := Rec."No.";
        SetupActive := Rec."Page ID" <> 0;
        SetStyle();
    end;

    trigger OnAfterGetRecord()
    begin
        SetStyle();
    end;

    trigger OnInit()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
    begin
        CRMIntegrationManagement.RegisterAssistedSetup();
        CDSIntegrationMgt.RegisterAssistedSetup();
    end;

    trigger OnOpenPage()
    begin
        ReloadServiceConnections();
    end;

    var
        SetupActive: Boolean;
        StyleExpression: Text;
        CurrRecordNo: Text;

    local procedure CallSetup()
    var
        GuidedExperience: Codeunit "Guided Experience";
        GuidedExperienceType: Enum "Guided Experience Type";
        RecordRef: RecordRef;
        RecordRefVariant: Variant;
        DummyRecordID: RecordID;
        CurrentRecordId: RecordID;
    begin
        if not SetupActive then
            exit;
        if ((Rec.Status = Rec.Status::Error) or (Rec.Status = Rec.Status::Disabled)) and
           (Rec."Assisted Setup Page ID" > 0) and
           (GuidedExperience.AssistedSetupExistsAndIsNotComplete(ObjectType::Page, Rec."Assisted Setup Page ID"))
        then
            GuidedExperience.Run(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Rec."Assisted Setup Page ID")
        else begin
            CurrentRecordId := Rec."Record ID";

            if CurrentRecordId = DummyRecordID then
                Page.RunModal(Rec."Page ID")
            else
                if not RecordRef.Get(Rec."Record ID") then
                    Page.RunModal(Rec."Page ID")
                else begin
                    RecordRefVariant := RecordRef;
                    Page.RunModal(Rec."Page ID", RecordRefVariant);
                end;
        end;
        ReloadServiceConnections();
        if Rec.Get(xRec."No.") then;
        CurrPage.Update(false);
    end;

    local procedure SetStyle()
    begin
        case Rec.Status of
            Rec.Status::Disabled:
                StyleExpression := 'Standard';
            Rec.Status::Connected, Rec.Status::Enabled:
                StyleExpression := 'Favorable';
            Rec.Status::Error:
                StyleExpression := 'Unfavorable';
        end
    end;

    local procedure Refresh()
    begin
        ReloadServiceConnections();
        CurrRecordNo := Format(CreateGuid());
        if Rec.Get(xRec."No.") then;
        CurrPage.Activate(true);
    end;

    local procedure ReloadServiceConnections()
    begin
        Rec.DeleteAll();
        Rec.OnRegisterServiceConnection(Rec);
    end;
}

