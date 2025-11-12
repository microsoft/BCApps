// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.Integration.Dataverse;

page 7211 "CRM Freight Terms List"
{
    ApplicationArea = Suite;
    Caption = 'Freight Terms - Dataverse';
    AdditionalSearchTerms = 'Freight Terms CDS, Freight Terms Common Data Service, Shipment Methods CDS, Shipment Methods Common Data Service, Shipment Methods Dataverse';
    Editable = false;
    PageType = List;
    SourceTable = "CRM Freight Terms";
    SourceTableView = sorting("Code");
    SourceTableTemporary = true;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field("Code"; Rec."Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Code';
                    StyleExpr = FirstColumnStyle;
                    ToolTip = 'Specifies data from a corresponding field in a Dataverse entity. For more information about Dataverse, see Dataverse Help Center.';
                }
                field(Coupled; Coupled)
                {
                    ApplicationArea = Suite;
                    Caption = 'Coupled';
                    ToolTip = 'Specifies if the Dataverse record is coupled to Business Central.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(CreateFromCRM)
            {
                ApplicationArea = Suite;
                Caption = 'Create in Business Central';
                Image = NewCustomer;
                ToolTip = 'Generate the entity from the coupled Dataverse Freight terms.';

                trigger OnAction()
                var
                    CRMFreightTerms: Record "CRM Freight Terms";
                    CRMIntegrationManagement: Codeunit "CRM Integration Management";
                begin
                    CRMFreightTerms.Copy(Rec, true);
                    CurrPage.SetSelectionFilter(CRMFreightTerms);
                    CRMIntegrationManagement.CreateNewRecordsFromSelectedCRMOptions(CRMFreightTerms);
                end;
            }
            action(ShowOnlyUncoupled)
            {
                ApplicationArea = Suite;
                Caption = 'Hide Coupled Freight Terms';
                Image = FilterLines;
                ToolTip = 'Do not show coupled Freight terms.';

                trigger OnAction()
                begin
                    Rec.MarkedOnly(true);
                end;
            }
            action(ShowAll)
            {
                ApplicationArea = Suite;
                Caption = 'Show Coupled Freight Terms';
                Image = ClearFilter;
                ToolTip = 'Show coupled Freight terms.';

                trigger OnAction()
                begin
                    Rec.MarkedOnly(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(CreateFromCRM_Promoted; CreateFromCRM)
                {
                }
                actionref(ShowOnlyUncoupled_Promoted; ShowOnlyUncoupled)
                {
                }
                actionref(ShowAll_Promoted; ShowAll)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        CRMOptionMapping: Record "CRM Option Mapping";
        CRMAccount: Record "CRM Account";
    begin
        if CRMOptionMapping.FindRecordID(Database::"CRM Account", CRMAccount.FieldNo(Address1_FreightTermsCodeEnum), Rec."Option Id") then
            if CurrentlyMappedCRMFreightTermOptionId = Rec."Option Id" then begin
                Coupled := 'Current';
                FirstColumnStyle := 'Strong';
                Rec.Mark(true);
            end else begin
                Coupled := 'Yes';
                FirstColumnStyle := 'Subordinate';
                Rec.Mark(false);
            end
        else begin
            Coupled := 'No';
            FirstColumnStyle := 'None';
            Rec.Mark(true);
        end;
    end;

    trigger OnInit()
    begin
        Codeunit.Run(Codeunit::"CRM Integration Management");
        Commit();
    end;

    trigger OnOpenPage()
    begin
        LoadRecords();
    end;

    var
        CurrentlyMappedCRMFreightTermOptionId: Integer;
        Coupled: Text;
        FirstColumnStyle: Text;
        LinesLoaded: Boolean;

    procedure SetCurrentlyMappedCRMFreightTermOptionId(OptionId: Integer)
    begin
        CurrentlyMappedCRMFreightTermOptionId := OptionId;
    end;

    internal procedure GetRec(OptionId: Integer): Record "CRM Freight Terms"
    begin
        if Rec.Get(OptionId) then
            exit(Rec);
    end;

    procedure LoadRecords()
    begin
        if LinesLoaded then
            exit;

        LinesLoaded := Rec.Load();
    end;
}