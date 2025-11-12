// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.SyncEngine;

using Microsoft.Integration.D365Sales;
using Microsoft.Integration.Dataverse;
using System.Reflection;

page 5339 "Integration Synch. Error List"
{
    ApplicationArea = Suite;
    Caption = 'Integration Synchronization Errors';
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Integration Synch. Job Errors";
    SourceTableView = sorting("Date/Time", "Integration Synch. Job ID")
                      order(descending);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Date/Time"; Rec."Date/Time")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date and time that the error in the integration synchronization job occurred.';
                }
                field(Message; ErrorMessage)
                {
                    ApplicationArea = Suite;
                    Caption = 'Error Message';
                    ToolTip = 'Specifies the error that occurred in the integration synchronization job.';
                    Width = 100;

                    trigger OnDrillDown()
                    var
                        TypeHelper: Codeunit "Type Helper";
                        CallStackInStream: InStream;
                        SyncErrorInfo: ErrorInfo;
                    begin
                        SyncErrorInfo.Message := ErrorMessage;
                        Rec.CalcFields("Exception Detail");
                        if Rec."Exception Detail".HasValue() then begin
                            Rec."Exception Detail".CreateInStream(CallStackInStream, TEXTENCODING::Windows);
                            SyncErrorInfo.CustomDimensions.Add('Call Stack', TypeHelper.ReadAsTextWithSeparator(CallStackInStream, TypeHelper.LFSeparator()));
                        end else
                            SyncErrorInfo.CustomDimensions.Add('Call Stack', NoCallStackMsg);

                        Error(SyncErrorInfo);
                    end;
                }
                field(HelpLink; HelpLink)
                {
                    ApplicationArea = Suite;
                    Caption = 'Help Link';
                    ToolTip = 'Specifies the link to the documentation page that could help to resolve the integration synchronization job failure.';

                    trigger OnDrillDown()
                    var
                        HelpLinkUrl: Text;
                    begin
                        HelpLinkUrl := GetHelpLink();
                        if HelpLinkUrl <> '' then
                            HyperLink(HelpLinkUrl);
                    end;
                }
                field("Exception Detail"; Rec."Exception Detail")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the exception that occurred in the integration synchronization job.';
                    Visible = false;
                }
                field(Source; OpenSourcePageTxt)
                {
                    ApplicationArea = Suite;
                    Caption = 'Source';
                    ToolTip = 'Specifies the record that supplied the data to destination record in integration synchronization job that failed.';

                    trigger OnDrillDown()
                    var
                        CRMSynchHelper: Codeunit "CRM Synch. Helper";
                        IsHandled: Boolean;
                    begin
                        OnOpenSourceRecord(Rec."Source Record ID", IsHandled);
                        if not IsHandled then
                            CRMSynchHelper.ShowPage(Rec."Source Record ID");
                    end;
                }
                field(Destination; OpenDestinationPageTxt)
                {
                    ApplicationArea = Suite;
                    Caption = 'Destination';
                    ToolTip = 'Specifies the record that received the data from the source record in integration synchronization job that failed.';

                    trigger OnDrillDown()
                    var
                        CRMSynchHelper: Codeunit "CRM Synch. Helper";
                        IsHandled: Boolean;
                    begin
                        OnOpenDestinationRecord(Rec."Destination Record ID", IsHandled);
                        if not IsHandled then
                            CRMSynchHelper.ShowPage(Rec."Destination Record ID");
                    end;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(Delete7days)
            {
                ApplicationArea = Suite;
                Caption = 'Delete Entries Older Than 7 Days';
                Enabled = HasRecords;
                Visible = false;
                Image = ClearLog;
                ToolTip = 'Delete error log information for job queue entries that are older than seven days.';

                trigger OnAction()
                begin
                    Rec.DeleteEntries(7);
                end;
            }
            action(Delete0days)
            {
                ApplicationArea = Suite;
                Caption = 'Delete All Entries';
                Enabled = HasRecords;
                Visible = false;
                Image = Delete;
                ToolTip = 'Delete all error log information for job queue entries.';

                trigger OnAction()
                begin
                    Rec.DeleteEntries(0);
                end;
            }
            group(ActionGroupDataIntegration)
            {
                Caption = 'Data Integration';
                Visible = ShowDataIntegrationActions;
                action(DataIntegrationSynchronizeNow)
                {
                    ApplicationArea = Suite;
                    Caption = 'Synchronize';
                    Enabled = HasRecords;
                    Image = Refresh;
                    ToolTip = 'Send or get updated data from integrated products or services.';
                    Visible = ShowDataIntegrationActions;

                    trigger OnAction()
                    var
                        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
                        LocalRecordID: RecordID;
                        SynchronizeHandled: Boolean;
                        RecordIdDictionary: Dictionary of [RecordId, Boolean];
                        RecordIdList: List of [RecordId];
                    begin
                        if Rec.IsEmpty() then
                            exit;

                        CurrPage.SetSelectionFilter(IntegrationSynchJobErrors);
                        IntegrationSynchJobErrors.Next();

                        if IntegrationSynchJobErrors.Count() = 1 then begin
                            GetRecordID(IntegrationSynchJobErrors, LocalRecordID);
                            Rec.ForceSynchronizeDataIntegration(LocalRecordID, SynchronizeHandled);
                            exit;
                        end;

                        if not IntegrationSynchJobErrors.FindSet() then
                            exit;

                        repeat
                            GetRecordID(IntegrationSynchJobErrors, LocalRecordID);
                            if not RecordIdDictionary.ContainsKey(LocalRecordID) then
                                RecordIdDictionary.Add(LocalRecordID, true);
                        until IntegrationSynchJobErrors.Next() = 0;

                        RecordIdList := RecordIdDictionary.Keys();
                        Rec.ForceSynchronizeDataIntegration(RecordIdList, SynchronizeHandled);
                    end;
                }
                action(DataIntegrationExceptionDetails)
                {
                    ApplicationArea = Suite;
                    Caption = 'Show Error Call Stack';
                    Enabled = HasRecords;
                    Image = StepInto;
                    ToolTip = 'Shows the call stack for the error.';
                    Visible = ShowDataIntegrationActions;

                    trigger OnAction()
                    var
                        TypeHelper: Codeunit "Type Helper";
                        CallStackInStream: InStream;
                    begin
                        if Rec.IsEmpty() then
                            exit;

                        Rec.CalcFields("Exception Detail");
                        if Rec."Exception Detail".HasValue() then begin
                            Rec."Exception Detail".CreateInStream(CallStackInStream, TEXTENCODING::Windows);
                            Message(TypeHelper.ReadAsTextWithSeparator(CallStackInStream, TypeHelper.LFSeparator()));
                        end else
                            Message(NoCallStackMsg);
                    end;
                }
                group(Coupling)
                {
                    Caption = 'Coupling', Comment = 'Coupling is a noun';
                    Image = LinkAccount;
                    ToolTip = 'Create, change, or delete a coupling between the Business Central record and a Dataverse record.';
                    Visible = ShowCDSIntegrationActions;
                    action(ManageCRMCoupling)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Set Up Coupling';
                        Enabled = HasRecords;
                        Image = LinkAccount;
                        ToolTip = 'Create or modify the coupling to a Dataverse entity.';
                        Visible = ShowCDSIntegrationActions;

                        trigger OnAction()
                        var
                            LocalRecordID: RecordID;
                        begin
                            if Rec.IsEmpty() then
                                exit;

                            GetRecordID(LocalRecordID);
                            CRMIntegrationManagement.DefineCoupling(LocalRecordID);
                        end;
                    }
                    action(DeleteCRMCoupling)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Delete Coupling';
                        Enabled = HasRecords;
                        Image = UnLinkAccount;
                        ToolTip = 'Delete the coupling to a Dataverse entity.';
                        Visible = ShowCDSIntegrationActions;

                        trigger OnAction()
                        var
                            IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
                        begin
                            CurrPage.SetSelectionFilter(IntegrationSynchJobErrors);
                            IntegrationSynchJobErrors.DeleteCouplings();
                        end;
                    }
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Delete0days_Promoted; Delete0days)
                {
                }
                actionref(Delete7days_Promoted; Delete7days)
                {
                }
                group(Category_Synchronize)
                {
                    Caption = 'Synchronize';

                    actionref(DataIntegrationSynchronizeNow_Promoted; DataIntegrationSynchronizeNow)
                    {
                    }
                    group(Category_Coupling)
                    {
                        Caption = 'Coupling';
                        ShowAs = SplitButton;

                        actionref(ManageCRMCoupling_Promoted; ManageCRMCoupling)
                        {
                        }
                        actionref(DeleteCRMCoupling_Promoted; DeleteCRMCoupling)
                        {
                        }
                    }
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        RecID: RecordID;
    begin
        RecID := Rec."Source Record ID";
        OpenSourcePageTxt := GetPageLink(RecID);

        RecID := Rec."Destination Record ID";
        OpenDestinationPageTxt := GetPageLink(RecID);

        ErrorMessage := GetErrorMessage();

        if GetHelpLink() <> '' then
            HelpLink := PermissionsHelpTitleTxt
        else
            helpLink := '';

        HasRecords := true;
    end;

    trigger OnOpenPage()
    var
        CRMIntegrationEnabled: Boolean;
        CDSIntegrationEnabled: Boolean;
    begin
        Rec.SetDataIntegrationUIElementsVisible(ShowDataIntegrationActions);
        CDSIntegrationEnabled := CRMIntegrationManagement.IsCDSIntegrationEnabled();
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled();
        ShowCDSIntegrationActions := CDSIntegrationEnabled or CRMIntegrationEnabled;
    end;

    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        InvalidOrMissingSourceErr: Label 'The source record was not found.';
        InvalidOrMissingDestinationErr: Label 'The destination record was not found.';
        OpenSourcePageTxt: Text;
        OpenDestinationPageTxt: Text;
        OpenPageTok: Label 'View';
        ErrorMessage: Text;
        HelpLink: Text;
        PermissionsTok: Label ' prv', Locked = true;
        PermissionsHelpTitleTxt: Label 'Insufficient permissions', Locked = true;
        FixPermissionsUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2206174', Locked = true;
        HasRecords: Boolean;
        ShowDataIntegrationActions: Boolean;
        ShowCDSIntegrationActions: Boolean;
        NoCallStackMsg: Label 'No call stack is available for this error.';

    local procedure GetRecordID(var LocalRecordID: RecordID)
    begin
        GetRecordID(Rec, LocalRecordID)
    end;

    local procedure GetRecordID(var IntegrationSynchJobErrors: Record "Integration Synch. Job Errors"; var LocalRecordID: RecordID)
    var
        TableMetadata: Record "Table Metadata";
    begin
        LocalRecordID := IntegrationSynchJobErrors."Source Record ID";
        if LocalRecordID.TableNo() = 0 then
            Error(InvalidOrMissingSourceErr);

        if not TableMetadata.Get(LocalRecordID.TableNo()) then
            Error(InvalidOrMissingSourceErr);

        if TableMetadata.TableType <> TableMetadata.TableType::CRM then
            exit;

        LocalRecordID := IntegrationSynchJobErrors."Destination Record ID";
        if LocalRecordID.TableNo() = 0 then
            Error(InvalidOrMissingDestinationErr);
    end;

    local procedure GetPageLink(var RecID: RecordID): Text
    var
        TableMetadata: Record "Table Metadata";
        CRMConnectionSetup: Record "CRM Connection Setup";
        ReferenceRecordRef: RecordRef;
    begin
        TableMetadata.SetRange(ID, RecID.TableNo);
        if TableMetadata.FindFirst() then begin
            if TableMetadata.TableType = TableMetadata.TableType::MicrosoftGraph then
                exit('');
            if (TableMetadata.TableType = TableMetadata.TableType::CRM) and not CRMConnectionSetup.IsEnabled() then
                exit('');
        end;

        if not ReferenceRecordRef.Get(RecID) then
            exit('');

        exit(OpenPageTok);
    end;

    local procedure GetHelpLink(): Text
    begin
        if GetErrorMessage().Contains(PermissionsTok) then
            exit(FixPermissionsUrlTxt);
        exit('');
    end;

    local procedure GetErrorMessage(): Text
    begin
        if Rec."Error Message" <> '' then
            exit(Rec."Error Message");
        exit(Rec.Message);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenSourceRecord(var RecordId: RecordId; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenDestinationRecord(var RecordId: RecordId; var IsHandled: Boolean)
    begin
    end;

}
