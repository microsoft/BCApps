// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.Integration.Dataverse;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

page 5341 "CRM Account List"
{
    ApplicationArea = Suite;
    Caption = 'Accounts - Dataverse';
    AdditionalSearchTerms = 'Accounts CDS, Accounts Common Data Service';
    Editable = false;
    PageType = List;
    SourceTable = "CRM Account";
    SourceTableView = sorting(Name);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Suite;
                    Caption = 'Name';
                    StyleExpr = FirstColumnStyle;
                    ToolTip = 'Specifies data from a corresponding field in a Dataverse entity. For more information about Dataverse, see Dataverse Help Center.';
                }
                field(Address1_PrimaryContactName; Rec.Address1_PrimaryContactName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Primary Contact Name';
                    ToolTip = 'Specifies data from a corresponding field in a Dataverse entity. For more information about Dataverse, see Dataverse Help Center.';
                }
                field(CustomerTypeCode; Rec.CustomerTypeCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'Relationship Type';
                    ToolTip = 'Specifies data from a corresponding field in a Dataverse entity. For more information about Dataverse, see Dataverse Help Center.';
                }
                field(Address1_Line1; Rec.Address1_Line1)
                {
                    ApplicationArea = Suite;
                    Caption = 'Street 1';
                    ToolTip = 'Specifies data from a corresponding field in a Dataverse entity. For more information about Dataverse, see Dataverse Help Center.';
                }
                field(Address1_Line2; Rec.Address1_Line2)
                {
                    ApplicationArea = Suite;
                    Caption = 'Street 2';
                    ToolTip = 'Specifies data from a corresponding field in a Dataverse entity. For more information about Dataverse, see Dataverse Help Center.';
                }
                field(Address1_PostalCode; Rec.Address1_PostalCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'ZIP/Postal Code';
                    ToolTip = 'Specifies data from a corresponding field in a Dataverse entity. For more information about Dataverse, see Dataverse Help Center.';
                }
                field(Address1_City; Rec.Address1_City)
                {
                    ApplicationArea = Suite;
                    Caption = 'City';
                    ToolTip = 'Specifies data from a corresponding field in a Dataverse entity. For more information about Dataverse, see Dataverse Help Center.';
                }
                field(Address1_Country; Rec.Address1_Country)
                {
                    ApplicationArea = Suite;
                    Caption = 'Country/Region';
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
                ToolTip = 'Generate the entity from the coupled Dataverse account.';

                trigger OnAction()
                var
                    CRMAccount: Record "CRM Account";
                    CRMIntegrationManagement: Codeunit "CRM Integration Management";
                begin
                    CurrPage.SetSelectionFilter(CRMAccount);
                    CRMIntegrationManagement.CreateNewRecordsFromSelectedCRMRecords(CRMAccount);
                end;
            }
            action(ShowOnlyUncoupled)
            {
                ApplicationArea = Suite;
                Caption = 'Hide Coupled Accounts';
                Image = FilterLines;
                ToolTip = 'Do not show coupled accounts.';

                trigger OnAction()
                begin
                    Rec.MarkedOnly(true);
                end;
            }
            action(ShowAll)
            {
                ApplicationArea = Suite;
                Caption = 'Show Coupled Accounts';
                Image = ClearFilter;
                ToolTip = 'Show coupled accounts.';

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
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecordID: RecordID;
        EmptyRecordID: RecordID;
    begin
        if CRMIntegrationRecord.FindRecordIDFromID(Rec.AccountId, DATABASE::Customer, RecordID) then
            if CurrentlyCoupledCRMAccount.AccountId = Rec.AccountId then begin
                Coupled := 'Current';
                FirstColumnStyle := 'Strong';
                Rec.Mark(true);
            end else begin
                Coupled := 'Yes';
                FirstColumnStyle := 'Subordinate';
                Rec.Mark(false);
            end;

        if RecordID = EmptyRecordID then
            if CRMIntegrationRecord.FindRecordIDFromID(Rec.AccountId, DATABASE::Vendor, RecordID) then
                if CurrentlyCoupledCRMAccount.AccountId = Rec.AccountId then begin
                    Coupled := 'Current';
                    FirstColumnStyle := 'Strong';
                    Rec.Mark(true);
                end else begin
                    Coupled := 'Yes';
                    FirstColumnStyle := 'Subordinate';
                    Rec.Mark(false);
                end;

        if RecordID = EmptyRecordID then begin
            Coupled := 'No';
            FirstColumnStyle := 'None';
            Rec.Mark(true);
        end;
    end;

    trigger OnInit()
    begin
        CODEUNIT.Run(CODEUNIT::"CRM Integration Management");
        Commit();
    end;

    trigger OnOpenPage()
    var
        LookupCRMTables: Codeunit "Lookup CRM Tables";
    begin
        Rec.FilterGroup(4);
        Rec.SetView(LookupCRMTables.GetIntegrationTableMappingView(DATABASE::"CRM Account"));
        Rec.FilterGroup(0);
    end;

    var
        CurrentlyCoupledCRMAccount: Record "CRM Account";
        Coupled: Text;
        FirstColumnStyle: Text;

    procedure SetCurrentlyCoupledCRMAccount(CRMAccount: Record "CRM Account")
    begin
        CurrentlyCoupledCRMAccount := CRMAccount;
    end;
}