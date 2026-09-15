// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Automation;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Utilities;
using System.Reflection;
using System.Security.AccessControl;
using System.Security.User;
using System.Text;

page 30443 "Approval Entry Overview"
{
    ApplicationArea = Suite;
    Caption = 'Approval Entry Overview';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Approval Entry Buffer";
    SourceTableView = sorting("Last Date-Time Modified") order(descending);
    UsageCategory = History;
    AboutTitle = 'About Approval Entry Overview';
    AboutText = 'Review all approval requests that are pending approval or already posted.';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';

                field(TableFilter; TableFilter)
                {
                    Caption = 'Table Filter';
                    ToolTip = 'Specifies the table that will be used to filter the Table ID field in the approval entries in the window.';
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        AllObjWithCaption: Record AllObjWithCaption;
                    begin
                        AllObjWithCaption.SetFilter("Object ID", '0|17|18|23|27|36|38|45|81|110|112|114|120|122|124|130|232|245|472|5900|6650|6660');
                        if Page.RunModal(Page::"Table Objects", AllObjWithCaption) = Action::LookupOK then begin
                            TableFilter := AllObjWithCaption."Object ID";
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    var
                        RecRef: RecordRef;
                        FieldRef: FieldRef;
                    begin
                        Clear(NoFilter);
                        Clear(RecordIDFilter);
                        Clear(DocumentNoFilter);
                        DocumentTypeFilter := DocumentTypeFilter::" ";

                        if TableFilter in [Database::"Sales Header", Database::"Purchase Header", Database::"Gen. Journal Line"] then begin
                            NoFilterEditable := false;
                            DocumentNoFilterEditable := true;
                            DocumentTypeFilterEditable := true;
                            exit;
                        end;

                        DocumentNoFilterEditable := false;
                        DocumentTypeFilterEditable := false;

                        RecRef.Open(TableFilter);
                        if FindNoField(RecRef, FieldRef) then
                            NoFilterEditable := true
                        else
                            NoFilterEditable := false;

                        IsFilterApplied := false;
                    end;
                }
                field(NoFilter; NoFilter)
                {
                    Caption = 'No. Filter';
                    ToolTip = 'Specifies the no. that will be used to filter the Record ID field in the approval entries in the window.';
                    Editable = NoFilterEditable;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        RecRef: RecordRef;
                        FieldRef: FieldRef;
                        RecordRefVariant: Variant;
                        PageID: Integer;
                    begin
                        if TableFilter = 0 then
                            exit(false);

                        RecRef.Open(TableFilter);
                        if not FindNoField(RecRef, FieldRef) then
                            exit;

                        PageID := GetDefaultLookupPageID();
                        RecordRefVariant := RecRef;
                        if Page.RunModal(PageID, RecordRefVariant) = Action::LookupOK then begin
                            RecRef := RecordRefVariant;
                            FieldRef := RecRef.Field(FieldRef.Number());
                            NoFilter := FieldRef.Value();
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        SetRecordIDFilter(NoFilter);
                        IsFilterApplied := false;
                    end;
                }

                field(DocumentTypeFilter; DocumentTypeFilter)
                {
                    Caption = 'Document Type Filter';
                    Editable = DocumentTypeFilterEditable;
                    ToolTip = 'Specifies the document type that will be used to filter the approval entries in the window.';

                    trigger OnValidate()
                    begin
                        if DocumentTypeFilter = DocumentTypeFilter::" " then
                            exit;

                        case true of
                            TableFilter = Database::"Sales Header":
                                EnumAssignmentMgt.GetSalesDocumentTypeFromApproval(DocumentTypeFilter);
                            TableFilter = Database::"Purchase Header":
                                EnumAssignmentMgt.GetPurchDocumentTypeFromApproval(DocumentTypeFilter);
                        end;
                        IsFilterApplied := false;
                    end;
                }
                field(DocumentNoFilter; DocumentNoFilter)
                {
                    Caption = 'Document No. Filter';
                    Editable = DocumentNoFilterEditable;
                    ToolTip = 'Specifies the document no. that will be used to filter the approval entries in the window.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        SalesHeader: Record "Sales Header";
                        PurchaseHeader: Record "Purchase Header";
                        PageID: Integer;
                    begin
                        case true of
                            TableFilter = Database::"Sales Header":
                                begin
                                    if DocumentTypeFilter <> DocumentTypeFilter::" " then
                                        SalesHeader.SetRange("Document Type", DocumentTypeFilter);
                                    PageID := PageManagement.GetListPageID(SalesHeader);
                                    if Page.RunModal(PageID, SalesHeader) = Action::LookupOK then begin
                                        DocumentNoFilter := SalesHeader."No.";
                                        exit(true);
                                    end;
                                end;
                            TableFilter = Database::"Purchase Header":
                                begin
                                    if DocumentTypeFilter <> DocumentTypeFilter::" " then
                                        PurchaseHeader.SetRange("Document Type", EnumAssignmentMgt.GetPurchDocumentTypeFromApproval(DocumentTypeFilter));
                                    PageID := PageManagement.GetListPageID(PurchaseHeader);
                                    if Page.RunModal(PageID, PurchaseHeader) = Action::LookupOK then begin
                                        DocumentNoFilter := PurchaseHeader."No.";
                                        exit(true);
                                    end;
                                end;
                            else
                                exit(false);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        IsFilterApplied := false;
                    end;
                }
                field(PostedFilter; PostedFilter)
                {
                    Caption = 'Posted Filter';
                    OptionCaption = 'All,Approval Entries,Posted Approval Entries';
                    ToolTip = 'Specifies the type of approval entry records that will be used to filter the approval entries in the window.';

                    trigger OnValidate()
                    begin
                        IsFilterApplied := false;
                    end;
                }
                field(SenderIDFilter; SenderIDFilter)
                {
                    Caption = 'Sender ID Filter';
                    ToolTip = 'Specifies the sender id that will be used to filter the approval entries in the window.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        User: Record User;
                        Users: Page "Users";
                    begin
                        Users.LookupMode := true;
                        if Users.RunModal() = Action::LookupOK then begin
                            Users.GetRecord(User);
                            Text := User."User Name";
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        IsFilterApplied := false;
                    end;
                }
                field(ApproverIDFilter; ApproverIDFilter)
                {
                    Caption = 'Approver ID Filter';
                    ToolTip = 'Specifies the approver id that will be used to filter the approval entries in the window.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        User: Record User;
                        Users: Page "Users";
                    begin
                        Users.LookupMode := true;
                        if Users.RunModal() = Action::LookupOK then begin
                            Users.GetRecord(User);
                            Text := User."User Name";
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        IsFilterApplied := false;
                    end;
                }
                field(DateFilter; DateFilter)
                {
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies the dates that will be used to filter the Last Date-Time Modified field in the approval entries in the window.';

                    trigger OnValidate()
                    var
                        FilterTokens: Codeunit "Filter Tokens";
                    begin
                        FilterTokens.MakeDateTimeFilter(DateFilter);
                        IsFilterApplied := false;
                    end;
                }
                field(FiltersApplied; IsFilterApplied)
                {
                    Caption = 'Filters Applied';
                    ToolTip = 'Specifies whether the filters have been applied to the window. The check box is selected after you choose the Filters Applied button.';
                    Editable = false;
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                Editable = false;
                field(Posted; Format(Rec.Posted))
                {
                    Caption = 'Posted';
                    ToolTip = 'Specifies that the approval request has been posted.';
                }
                field(RecordIDText; RecordIDText)
                {
                    Caption = 'Record ID';
                    ToolTip = 'Specifies the record id of the approval request.';
                }
                field("Table ID"; Rec."Table ID")
                {
                    ToolTip = 'Specifies the ID of the table where the record that is subject to approval is stored.';
                }
                field("Iteration No."; Rec."Iteration No.")
                {
                    ToolTip = 'Specifies the number of handling iterations that this approval request has reached.';
                }
                field("Sequence No."; Rec."Sequence No.")
                {
                    ToolTip = 'Specifies the order of approvers when an approval workflow involves more than one approver.';
                }
                field("Limit Type"; Rec."Limit Type")
                {
                    ToolTip = 'Specifies the type of limit that applies to the approval template:';
                }
                field("Approval Type"; Rec."Approval Type")
                {
                    ToolTip = 'Specifies which approvers apply to this approval template:';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ToolTip = 'Specifies the type of document that an approval entry has been created for. Approval entries can be created for six different types of sales or purchase documents:';
                }
                field("Document No."; Rec."Document No.")
                {
                    ToolTip = 'Specifies the document number copied from the relevant sales or purchase document, such as a purchase order or a sales quote.';
                }
                field("Sender ID"; Rec."Sender ID")
                {
                    ToolTip = 'Specifies the ID of the user who sent the approval request for the document to be approved.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."Sender ID");
                    end;
                }
                field("Sender Full Name"; Rec."Sender Full Name")
                {
                    ToolTip = 'Specifies the full name of the user who sent the approval request for the document to be approved.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."Sender ID");
                    end;
                }
                field("Salespers./Purch. Code"; Rec."Salespers./Purch. Code")
                {
                    ToolTip = 'Specifies the code for the salesperson or purchaser that was in the document to be approved. It is not a mandatory field, but is useful if a salesperson or a purchaser responsible for the customer/vendor needs to approve the document before it is sent.';
                }
                field("Salespers./Purch. Name"; Rec."Salespers./Purch. Name")
                {
                    ToolTip = 'Specifies the name for the salesperson or purchaser that was in the document to be approved. It is not a mandatory field, but is useful if a salesperson or a purchaser responsible for the customer/vendor needs to approve the document before it is sent.';
                    Visible = false;
                }
                field("Approver ID"; Rec."Approver ID")
                {
                    ToolTip = 'Specifies the ID of the user who must approve the document.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."Approver ID");
                    end;
                }
                field("Approver Full Name"; Rec."Approver Full Name")
                {
                    ToolTip = 'Specifies the full name of the user who must approve the document.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."Sender ID");
                    end;
                }
                field(Status; Rec.Status)
                {
                    ToolTip = 'Specifies the approval status for the entry:';
                }
                field("Date-Time Sent for Approval"; Rec."Date-Time Sent for Approval")
                {
                    ToolTip = 'Specifies the date and the time that the document was sent for approval.';
                }
                field("Last Date-Time Modified"; Rec."Last Date-Time Modified")
                {
                    ToolTip = 'Specifies the date when the approval entry was last modified. If, for example, the document approval is canceled, this field will be updated accordingly.';
                }
                field("Last Modified By ID"; Rec."Last Modified By ID")
                {
                    ToolTip = 'Specifies the ID of the person who last modified the approval entry. If, for example, the document approval is canceled, this field will be updated accordingly.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."Last Modified By ID");
                    end;
                }
                field(Comment; Rec.Comment)
                {
                    ToolTip = 'Specifies whether there are comments related to the approval of the document. If you want to read the comments, click the field to open the Comment Sheet window.';

                    trigger OnDrillDown()
                    begin
                        Rec.ShowComments();
                    end;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ToolTip = 'Specifies the date when the document is due for approval by the approver.';
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ToolTip = 'Specifies the total amount (excl. VAT) on the document waiting for approval. The amount is stated in the local currency.';
                }
                field("Available Credit Limit (LCY)"; Rec."Available Credit Limit (LCY)")
                {
                    ToolTip = 'Specifies the remaining credit (in LCY) that exists for the customer.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ToolTip = 'Specifies the code of the currency of the amounts on the sales or purchase lines.';
                }
                field("Delegation Date Formula"; Rec."Delegation Date Formula")
                {
                    ToolTip = 'Specifies for the posted approval entry when an overdue approval request was automatically delegated to the relevant substitute. The field is filled with the value in the Delegate After field in the Workflow Responses window, translated to a date formula. The date of automatic delegation is then calculated based on the Date-Time Sent for Approval field in the Approval Entries window.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ApplyFilters)
            {
                Caption = 'Apply Filters';
                Image = FilterLines;
                ToolTip = 'Update the window with the applied filters.';

                trigger OnAction()
                begin
                    LoadPage();
                end;
            }
        }
        area(navigation)
        {
            group("&Show")
            {
                Caption = '&Show';
                Image = View;
                action("Record")
                {
                    Caption = 'Record';
                    Image = Document;
                    ToolTip = 'Open the document, journal line, or card that the approval request is for.';

                    trigger OnAction()
                    begin
                        Rec.ShowRecord();
                    end;
                }
                action(Comments)
                {
                    Caption = 'Comments';
                    Image = ViewComments;
                    ToolTip = 'View or add comments for the record.';

                    trigger OnAction()
                    begin
                        Rec.ShowComments();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ApplyFilters_Promoted; ApplyFilters)
                {
                }
                actionref(Record_Promoted; Record)
                {
                }
                actionref(Comments_Promoted; Comments)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        RecordIDText := Format(Rec."Record ID", 0, 1);
    end;

    trigger OnAfterGetRecord()
    begin
        RecordIDText := Format(Rec."Record ID", 0, 1);
    end;

    trigger OnOpenPage()
    begin
        TableFilter := 0;
        DocumentTypeFilter := DocumentTypeFilter::" ";
    end;

    var
        EnumAssignmentMgt: Codeunit "Enum Assignment Management";
        PageManagement: Codeunit "Page Management";
        RecordIDText: Text;

    protected var
        RecordIDFilter: RecordID;
        TableFilter: Integer;
        NoFilter: Text;
        DocumentTypeFilter: Enum "Approval Document Type";
        DocumentNoFilter: Text;
        PostedFilter: Option All,"Approval Entries","Posted Approval Entries";
        SenderIDFilter: Text;
        ApproverIDFilter: Text;
        DateFilter: Text;
        IsFilterApplied: Boolean;
        NoFilterEditable: Boolean;
        DocumentNoFilterEditable: Boolean;
        DocumentTypeFilterEditable: Boolean;

    procedure LoadPage()
    var
        ApprovalEntry: Record "Approval Entry";
        PostedApprovalEntry: Record "Posted Approval Entry";
    begin
        Rec.Reset();
        Rec.DeleteAll();

        ApplyUserFilters(ApprovalEntry, PostedApprovalEntry);

        if PostedFilter in [PostedFilter::All, PostedFilter::"Approval Entries"] then
            Rec.FillBuffer(ApprovalEntry);

        if PostedFilter in [PostedFilter::All, PostedFilter::"Posted Approval Entries"] then
            Rec.FillBuffer(PostedApprovalEntry);

        Rec.Reset();
        Rec.SetCurrentKey("Last Date-Time Modified");
        Rec.Ascending(false);
        if Rec.FindFirst() then;

        IsFilterApplied := true;
        CurrPage.Update(false);
    end;

    local procedure SetRecordIDFilter(NoFilterText: Text)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        TableNameFilterErr: Label 'Please select Table Name Filter before adding No. Filter.';
        NoFieldErr: Label 'The %1 table does not have a No. field.', Comment = '%1 = Table Name';
        NoRecordErr: Label 'No record with No. %1 is found in %2 table.', Comment = '%1 = No., %2 = Table Name';
    begin
        Clear(RecordIDFilter);
        if NoFilterText = '' then
            exit;

        if TableFilter = 0 then
            Error(TableNameFilterErr);

        RecRef.Open(TableFilter);

        if not FindNoField(RecRef, FieldRef) then
            Error(NoFieldErr, Format(TableFilter));

        FieldRef := RecRef.Field(FieldRef.Number());
        FieldRef.SetRange(NoFilterText);
        if not RecRef.FindFirst() then
            Error(NoRecordErr, NoFilterText, Format(TableFilter));

        RecordIDFilter := RecRef.RecordId();
    end;

    procedure ApplyUserFilters(var ApprovalEntry: Record "Approval Entry"; var PostedApprovalEntry: Record "Posted Approval Entry")
    begin
        if TableFilter <> 0 then begin
            ApprovalEntry.SetRange("Table ID", TableFilter);
            PostedApprovalEntry.SetRange("Table ID", TableFilter);
        end;
        if NoFilter <> '' then begin
            ApprovalEntry.SetRange("Record ID to Approve", RecordIDFilter);
            PostedApprovalEntry.SetRange("Posted Record ID", RecordIDFilter);
        end;
        if DocumentTypeFilter <> DocumentTypeFilter::" " then
            ApprovalEntry.SetRange("Document Type", DocumentTypeFilter);
        if DocumentNoFilter <> '' then begin
            ApprovalEntry.SetFilter("Document No.", DocumentNoFilter);
            PostedApprovalEntry.SetFilter("Document No.", DocumentNoFilter);
        end;
        if SenderIDFilter <> '' then begin
            ApprovalEntry.SetFilter("Sender ID", SenderIDFilter);
            PostedApprovalEntry.SetFilter("Sender ID", SenderIDFilter);
        end;
        if ApproverIDFilter <> '' then begin
            ApprovalEntry.SetFilter("Approver ID", ApproverIDFilter);
            PostedApprovalEntry.SetFilter("Approver ID", ApproverIDFilter);
        end;
        if DateFilter <> '' then begin
            ApprovalEntry.SetFilter("Last Date-Time Modified", DateFilter);
            PostedApprovalEntry.SetFilter("Last Date-Time Modified", DateFilter);
        end;
    end;

    local procedure FindNoField(var RecRef: RecordRef; var FieldRef: FieldRef): Boolean
    var
        DataTypeManagement: Codeunit "Data Type Management";
    begin
        if DataTypeManagement.FindFieldByName(RecRef, FieldRef, 'No.') then
            exit(true);

        if DataTypeManagement.FindFieldByName(RecRef, FieldRef, 'Entry No.') then
            exit(true);

        if DataTypeManagement.FindFieldByName(RecRef, FieldRef, 'ID') then
            exit(true);

        exit(false);
    end;

    local procedure GetDefaultLookupPageID() PageID: Integer
    begin
        PageID := PageManagement.GetDefaultLookupPageID(TableFilter);
    end;
}