// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.Integration.D365Sales;
using Microsoft.Integration.SyncEngine;
using Microsoft.Sales.Document;

page 5336 "CRM Coupling Record"
{
    Caption = 'Dataverse Coupling Record';
    PageType = StandardDialog;
    SourceTable = "Coupling Record Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Control11)
            {
                ShowCaption = false;
                grid(Coupling)
                {
                    Caption = 'Coupling';
                    GridLayout = Columns;
                    group("Business Central")
                    {
                        Caption = 'Business Central';
                        field(NAVName; Rec."NAV Name")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Business Central Name';
                            Editable = false;
                            ShowCaption = false;
                            ToolTip = 'Specifies the name of the record in Business Central to couple to an existing Dataverse record.';
                        }
                        group(Control13)
                        {
                            ShowCaption = false;
                            field(SyncActionControl; Rec."Sync Action")
                            {
                                ApplicationArea = Suite;
                                Caption = 'Synchronize After Coupling';
                                Enabled = not Rec."Create New";
                                OptionCaption = 'No,Yes - Use the Business Central data,Yes - Use the Dataverse data';
                                ToolTip = 'Specifies whether to synchronize the data in the record in Business Central and the record in Dataverse.';
                            }
                        }
                    }
                    group("Dynamics 365 Sales")
                    {
                        Caption = 'Dataverse';
                        field(CRMName; Rec."CRM Name")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Dataverse Name';
                            Enabled = not Rec."Create New" and not IsBidirectionalSalesOrderIntEnabled;
                            ShowCaption = false;
                            ToolTip = 'Specifies the name of the record in Dataverse that is coupled to the record in Business Central.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                Rec.LookUpCRMName();
                                RefreshFields();
                            end;

                            trigger OnValidate()
                            var
                                IntegrationTableMapping: Record "Integration Table Mapping";
                                IntegrationRecordRef: RecordRef;
                                IDFieldRef: FieldRef;
                                IntTableFilter: Text;
                            begin
                                IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
                                IntegrationTableMapping.SetRange("Synch. Codeunit ID", CODEUNIT::"CRM Integration Table Synch.");
                                IntegrationTableMapping.SetRange("Table ID", Rec."NAV Table ID");
                                IntegrationTableMapping.SetRange("Integration Table ID", Rec."CRM Table ID");
                                IntegrationTableMapping.SetRange("Delete After Synchronization", false);
                                if IntegrationTableMapping.FindFirst() then begin
                                    IntTableFilter := IntegrationTableMapping.GetIntegrationTableFilter();
                                    IntegrationRecordRef.Open(Rec."CRM Table ID");
                                    IntegrationRecordRef.SetView(IntTableFilter);
                                    IDFieldRef := IntegrationRecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.");
                                    IDFieldRef.SetFilter(Rec."CRM ID");
                                    if IntegrationRecordRef.IsEmpty() then
                                        Error(IntegrationRecordFilteredOutErr, CRMProductName.CDSServiceName(), Rec."CRM Name", IntegrationTableMapping.Name);
                                end;
                                RefreshFields();
                            end;
                        }
                        group(Control15)
                        {
                            ShowCaption = false;
                            field(CreateNewControl; Rec."Create New")
                            {
                                ApplicationArea = Suite;
                                Caption = 'Create New';
                                Enabled = EnableCreateNew;
                                Editable = not IsBidirectionalSalesOrderIntEnabled;
                                ToolTip = 'Specifies if a new record in Dataverse is automatically created and coupled to the related record in Business Central.';
                            }
                        }
                    }
                }
            }
            part(CouplingFields; "CRM Coupling Fields")
            {
                ApplicationArea = Suite;
                Caption = 'Fields';
                ShowFilter = false;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        RefreshFields();
    end;

    var
        CRMProductName: Codeunit "CRM Product Name";
        EnableCreateNew: Boolean;
        IsBidirectionalSalesOrderIntEnabled: Boolean;
        IntegrationRecordFilteredOutErr: Label 'The filters applied to table mapping %3 are preventing %1 record %2, from displaying.', Comment = '%1 = Dataverse service name, %2 = The record name entered by the user, %3 = Integration Table Mapping name';

    procedure GetCRMId(): Guid
    begin
        exit(Rec."CRM ID");
    end;

    local procedure RefreshFields()
    begin
        CurrPage.CouplingFields.PAGE.SetSourceRecord(Rec);
    end;

    procedure SetSourceRecordID(RecordID: RecordID; IsOption: Boolean)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        Rec.Initialize(RecordID, IsOption);

        if Rec."NAV Table ID" = Database::"Sales Header" then
            IsBidirectionalSalesOrderIntEnabled := CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled();
        if IsBidirectionalSalesOrderIntEnabled then
            Rec."Create New" := IsNullGuid(Rec."CRM ID");

        Rec.Insert();
        EnableCreateNew := (Rec."Sync Action" = Rec."Sync Action"::"To Integration Table") or IsBidirectionalSalesOrderIntEnabled;
    end;

    procedure SetSourceRecordID(RecordID: RecordID)
    begin
        SetSourceRecordID(RecordID, false);
    end;
}

