// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.Integration.Dataverse;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;

page 5348 "CRM Product List"
{
    ApplicationArea = Suite;
    Caption = 'Products - Microsoft Dynamics 365 Sales';
    Editable = false;
    PageType = List;
    SourceTable = "CRM Product";
    SourceTableView = sorting(ProductNumber);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(ProductNumber; Rec.ProductNumber)
                {
                    ApplicationArea = Suite;
                    Caption = 'Product Number';
                    StyleExpr = FirstColumnStyle;
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Suite;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the record.';
                }
                field(Price; Rec.Price)
                {
                    ApplicationArea = Suite;
                    Caption = 'Price';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(StandardCost; Rec.StandardCost)
                {
                    ApplicationArea = Suite;
                    Caption = 'Standard Cost';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(CurrentCost; Rec.CurrentCost)
                {
                    ApplicationArea = Suite;
                    Caption = 'Current Cost';
                    ToolTip = 'Specifies the item''s unit cost.';
                }
                field(Coupled; Coupled)
                {
                    ApplicationArea = Suite;
                    Caption = 'Coupled';
                    ToolTip = 'Specifies if the Dynamics 365 Sales record is coupled to Business Central.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ShowOnlyUncoupled)
            {
                ApplicationArea = Suite;
                Caption = 'Hide Coupled Products';
                Image = FilterLines;
                ToolTip = 'Do not show coupled products.';

                trigger OnAction()
                begin
                    Rec.MarkedOnly(true);
                end;
            }
            action(ShowAll)
            {
                ApplicationArea = Suite;
                Caption = 'Show Coupled Products';
                Image = ClearFilter;
                ToolTip = 'Show coupled products.';

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
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecordID: RecordID;
    begin
        if CRMIntegrationRecord.FindRecordIDFromID(Rec.ProductId, DATABASE::Item, RecordID) or
           CRMIntegrationRecord.FindRecordIDFromID(Rec.ProductId, DATABASE::Resource, RecordID)
        then
            if CurrentlyCoupledCRMProduct.ProductId = Rec.ProductId then begin
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
        CODEUNIT.Run(CODEUNIT::"CRM Integration Management");
    end;

    trigger OnOpenPage()
    var
        LookupCRMTables: Codeunit "Lookup CRM Tables";
    begin
        Rec.FilterGroup(4);
        Rec.SetView(LookupCRMTables.GetIntegrationTableMappingView(Database::"CRM Product"));
        Rec.FilterGroup(0);
    end;

    var
        CurrentlyCoupledCRMProduct: Record "CRM Product";
        Coupled: Text;
        FirstColumnStyle: Text;

    procedure SetCurrentlyCoupledCRMProduct(CRMProduct: Record "CRM Product")
    begin
        CurrentlyCoupledCRMProduct := CRMProduct;
    end;
}

