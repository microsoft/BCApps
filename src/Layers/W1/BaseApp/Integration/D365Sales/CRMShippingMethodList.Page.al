// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.Integration.Dataverse;

page 7212 "CRM Shipping Method List"
{
    ApplicationArea = Suite;
    Caption = 'Shipping Method - Dataverse';
    AdditionalSearchTerms = 'Shipping Method CDS, Shipping Method Common Data Service';
    Editable = false;
    PageType = List;
    SourceTable = "CRM Shipping Method";
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
                ToolTip = 'Generate the entity from the coupled Dataverse Shipping Method.';

                trigger OnAction()
                var
                    CRMShippingMethod: Record "CRM Shipping Method";
                    CRMIntegrationManagement: Codeunit "CRM Integration Management";
                begin
                    CRMShippingMethod.Copy(Rec, true);
                    CurrPage.SetSelectionFilter(CRMShippingMethod);
                    CRMIntegrationManagement.CreateNewRecordsFromSelectedCRMOptions(CRMShippingMethod);
                end;
            }
            action(ShowOnlyUncoupled)
            {
                ApplicationArea = Suite;
                Caption = 'Hide Coupled Shipping Method';
                Image = FilterLines;
                ToolTip = 'Do not show coupled Shipping Method.';

                trigger OnAction()
                begin
                    Rec.MarkedOnly(true);
                end;
            }
            action(ShowAll)
            {
                ApplicationArea = Suite;
                Caption = 'Show Coupled Shipping Method';
                Image = ClearFilter;
                ToolTip = 'Show coupled Shipping Method.';

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
        if CRMOptionMapping.FindRecordID(Database::"CRM Account", CRMAccount.FieldNo(Address1_ShippingMethodCodeEnum), Rec."Option Id") then
            if CurrentlyMappedCRMPShippingMethodOptionId = Rec."Option Id" then begin
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
        CurrentlyMappedCRMPShippingMethodOptionId: Integer;
        Coupled: Text;
        FirstColumnStyle: Text;
        LinesLoaded: Boolean;

    procedure SetCurrentlyMappedCRMPShippingMethodOptionId(OptionId: Integer)
    begin
        CurrentlyMappedCRMPShippingMethodOptionId := OptionId;
    end;

    internal procedure GetRec(OptionId: Integer): Record "CRM Shipping Method"
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